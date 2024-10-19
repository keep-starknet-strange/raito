from dataclasses import dataclass
import json
import re
import os
import threading
import queue
import argparse
import subprocess
import logging
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import random
from generate_data import generate_data
from format_args import format_args

logger = logging.getLogger(__name__)

# Constants
MAX_WEIGHT_LIMIT = 1000  # Total weight limit for all jobs
THREAD_POOL_SIZE = os.cpu_count()  # Number of threads for processing
QUEUE_MAX_SIZE = THREAD_POOL_SIZE * 2  # Maximum size of the job queue

BASE_DIR = Path(".client_cache")

# Shared state variables
current_weight = 0
weight_lock = threading.Condition()
job_queue = queue.Queue(maxsize=QUEUE_MAX_SIZE)


# Function to calculate weight of a block
def calculate_batch_weight(block_data, mode):
    if mode == "light":
        return len(block_data["blocks"])
    else:
        return sum(
            len(tx["inputs"]) + len(tx["outputs"])
            for block in block_data["blocks"]
            for tx in block["data"]["transactions"]
        )


@dataclass
class Job:
    height: int
    step: int
    mode: str
    weight: int
    batch_file: Path

    def __str__(self):
        return f"Job(height='{self.height}', step={self.step}, weight='{self.weight}')"


# Generator function to create jobs
def job_generator(start, blocks, step, mode, strategy):
    BASE_DIR.mkdir(exist_ok=True)
    end = start + blocks

    height_range, step = (
        (random.randrange(start, end), 1)
        if strategy == "random"
        else (range(start, end, step), step)
    )

    for height in height_range:
        try: 
            batch_file = BASE_DIR / f"{mode}_{height}_{step}.json"

            batch_data = generate_data(
                mode=mode, initial_height=height, num_blocks=step, fast=True
            )

            Path(batch_file).write_text(json.dumps(batch_data, indent=2))

            batch_weight = calculate_batch_weight(batch_data, mode)
            yield Job(height, step, mode, batch_weight, batch_file), batch_weight
        except Exception as e:
            logger.error(f"Error while generating data for: {height}:\n{e}")

# Function to process a batch
def process_batch(job):
    logger.debug(f"Running client on: {job}")

    arguments_file = job.batch_file.as_posix().replace(".json", "-arguments.json")

    with open(arguments_file, "w") as af:
        af.write(str(format_args(job.batch_file, False, False)))

    result = subprocess.run(
        [
            "scarb",
            "cairo-run",
            "--no-build",
            "--package",
            "client",
            "--function",
            "main",
            "--arguments-file",
            str(arguments_file),
        ],
        capture_output=True,
        text=True,
    )

    if (
        result.returncode != 0
        or "FAIL" in result.stdout
        or "error" in result.stdout
        or "panicked" in result.stdout
    ):
        logger.error(
            f"Error while processing: {job}:\n{result.stdout or result.stderr}"
        )
    else:
        match = re.search(r"gas_spent=(\d+)", result.stdout)
        if not match:
            logger.warning(f"While processing: {job}: not gas info found")
        else:
            logger.info(f"{job} processed, gas spent: {int(match.group(1))}")


# Producer function: Generates data and adds jobs to the queue
def job_producer(job_gen):
    global current_weight

    try: 
        for job, weight in job_gen:
            # Wait until there is enough weight capacity to add the new block
            with weight_lock:
                while (
                    current_weight + weight > MAX_WEIGHT_LIMIT or job_queue.full()
                ):  # or not (job_queue.empty() and weight > MAX_WEIGHT_LIMIT):
                    logger.debug("Producer is waiting for weight to be released.")
                    weight_lock.wait()  # Wait for the condition to be met

                # Add the job to the queue and update the weight
                job_queue.put((job, weight))
                current_weight += weight
                logger.debug(
                    f"Produced job: {job} with weight {weight}, current total weight: {current_weight}"
                )

                # Notify consumers that a new job is available
                weight_lock.notify_all()
    finally:
        for _ in range(THREAD_POOL_SIZE):
            job_queue.put(None)

        with weight_lock:
            weight_lock.notify_all()

        logger.debug("Producer is exiting.")

# Consumer function: Processes blocks from the queue
def job_consumer(process_job):
    global current_weight

    while True:
        try:
            logger.debug(f"Consumer is waiting for a job.")
            # Get a job from the queue
            work_to_do = job_queue.get(block=True)

            if work_to_do is None:
                logger.debug("No more work to do, consumer is exiting.")
                break
            
            (job, weight) = work_to_do

            # Process the block
            try:
                process_job(job)
            except Exception as e:
                logger.error(f"Error while processing job: {job}:\n{e}")

            with weight_lock:
                current_weight -= weight
                logger.debug(
                    f"Finished processing job, released weight: {weight}, current total weight: {current_weight}"
                )
                weight_lock.notify_all()  # Notify producer to add more jobs

            # Mark job as done
            job_queue.task_done()

        except Exception as e:
            logger.error("Error in the consumer: %s", e)    
            break


def main(start, blocks, step, mode, strategy):

    logger.warning(
        "Starting client, initial height: %d, blocks: %d, step: %d, mode: %s, strategy: %s",
        start,
        blocks,
        step,
        mode,
        strategy,
    )
    logger.warning(
        "Max weight limit: %d, Thread pool size: %d, Queue max size: %d",
        MAX_WEIGHT_LIMIT,
        THREAD_POOL_SIZE,
        QUEUE_MAX_SIZE,
    )

    # Create the job generator
    job_gen = job_generator(start, blocks, step, mode, strategy)

    # Start the job producer thread
    producer_thread = threading.Thread(target=job_producer, args=(job_gen,))
    producer_thread.start()

    # Start the consumer threads using ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=THREAD_POOL_SIZE) as executor:
        futures = [
            executor.submit(job_consumer, process_batch)
            for _ in range(THREAD_POOL_SIZE)
        ]

    # Wait for producer to finish
    producer_thread.join()

    # Wait for all items in the queue to be processed
    job_queue.join()

    print("All jobs have been processed.")


if __name__ == "__main__":

    file_handler = logging.FileHandler("client.log")
    file_handler.setLevel(logging.WARNING)
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s - %(name)-10.10s - %(levelname)s - %(message)s")
    )

    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.DEBUG)
    console_handler.setFormatter(
        logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    )
    root_logger = logging.getLogger()
    root_logger.addHandler(console_handler)
    root_logger.addHandler(file_handler)
    root_logger.setLevel(logging.INFO)

    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("generate_data").setLevel(logging.WARNING)

    parser = argparse.ArgumentParser(description="Run client script")
    parser.add_argument("--start", type=int, required=True, help="Start block height")
    parser.add_argument(
        "--blocks",
        type=int,
        default=1,
        help="Number of blocks to process",
    )
    parser.add_argument(
        "--step", type=int, default=1, help="Step size for block processing"
    )
    parser.add_argument(
        "--mode", default="light", choices=["light", "full"], help="Client mode"
    )
    parser.add_argument(
        "--strategy",
        default="sequential",
        choices=["sequential", "random"],
        help="Processing strategy",
    )

    args = parser.parse_args()

    main(args.start, args.blocks, args.step, args.mode, args.strategy)
