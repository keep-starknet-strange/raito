import json
import threading
import queue
import argparse
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import random
from generate_data import generate_data
from format_args import format_args

# Constants
MAX_WEIGHT_LIMIT = 50  # Total weight limit for all jobs
THREAD_POOL_SIZE = 4  # Number of threads for processing
QUEUE_MAX_SIZE = THREAD_POOL_SIZE * 2  # Maximum size of the job queue

BASE_DIR = Path(".client_cache")
DEFAULT_NO_OF_BLOCKS = 1

# Shared state variables
current_weight = 0
weight_lock = threading.Condition()
job_queue = queue.Queue(maxsize=QUEUE_MAX_SIZE)


# Function to calculate weight of a block
def calculate_job_weight(block_data):
    return sum(
        len(tx["inputs"]) + len(tx["outputs"])
        for block in block_data["blocks"]
        for tx in block["transactions"]
    )


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
        batch_file = BASE_DIR / f"{mode}_{height}_{step}.json"

        generate_data(
            fast=True,
            mode=mode,
            height=height,
            num_blocks=step,
            output_file=str(batch_file),
        )

        # Placeholder: Assuming generated data can be loaded from the batch_file
        with open(batch_file, "r") as f:
            block_data = json.load(f)

        batch_weight = calculate_job_weight(block_data)
        yield batch_file, batch_weight


# Function to process a batch
def process_batch(batch_file):
    print(f"Running client on blocks from {batch_file}")
    arguments_file = batch_file.replace(".json", "-arguments.json")
    with open(batch_file, "r") as bf, open(arguments_file, "w") as af:
        formatted_args = format_args(bf)
        af.write(formatted_args)

    result = subprocess.run(
        [
            "scarb",
            "cairo-run",
            "--no-build",
            "--package",
            "client",
            "--function",
            "test",
            "--arguments-file",
            str(arguments_file),
        ],
        capture_output=True,
        text=True,
    )

    if (
        result.returncode != 0
        or "FAIL" in result.stdout
        or "error" in result.stderr
        or "panicked" in result.stderr
    ):
        print("fail")
        print(result.stdout)
        print(result.stderr)
    else:
        print("ok")
        print(result.stdout)


# Producer function: Generates data and adds jobs to the queue
def job_producer(job_gen):
    global current_weight

    for job, weight in job_gen:
        # Wait until there is enough weight capacity to add the new block
        with weight_lock:
            while current_weight + weight > MAX_WEIGHT_LIMIT:
                weight_lock.wait()  # Wait for the condition to be met

            # Add the job to the queue and update the weight
            job_queue.put((job, weight))
            current_weight += weight
            print(
                f"Produced job with weight {weight}, current total weight: {current_weight}"
            )

            # Notify consumers that a new job is available
            weight_lock.notify_all()


# Consumer function: Processes blocks from the queue
def job_consumer(process_job):
    global current_weight

    while True:
        try:
            # Get a job from the queue
            (job, weight) = job_queue.get(
                timeout=5
            )  # Timeout to exit if no jobs are available

            # Process the block
            process_job(job)

            with weight_lock:
                current_weight -= weight
                print(
                    f"Finished processing job, released weight: {weight}, current total weight: {current_weight}"
                )
                weight_lock.notify_all()  # Notify producer to add more jobs

            # Mark job as done
            job_queue.task_done()

        except queue.Empty:
            # If queue is empty for too long, exit the consumer thread
            print("Queue is empty, consumer is exiting.")
            break


def main(start, blocks, step, mode, strategy):
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
    parser = argparse.ArgumentParser(description="Run client script")
    parser.add_argument("--start", type=int, default=1, help="Start block height")
    parser.add_argument(
        "--blocks",
        type=int,
        default=DEFAULT_NO_OF_BLOCKS,
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
