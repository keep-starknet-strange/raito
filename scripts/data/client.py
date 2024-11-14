#!/usr/bin/env python3
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
import signal
import sys
from generate_data import generate_data
from format_args import format_args
from logging.handlers import TimedRotatingFileHandler

# Initialize logger
logger = logging.getLogger(__name__)

# Constants
MAX_WEIGHT_LIMIT = 8000  # Total weight limit for all jobs
THREAD_POOL_SIZE = os.cpu_count()  # Number of threads for processing
QUEUE_MAX_SIZE = THREAD_POOL_SIZE * 2  # Maximum size of the job queue
BASE_DIR = Path(__file__).resolve().parent / ".client_cache"  # Use absolute path

# Shared state variables
current_weight = 0
weight_lock = threading.Condition()
job_queue = queue.Queue(maxsize=QUEUE_MAX_SIZE)
shutdown_event = threading.Event()
executor = None  # Global executor reference for shutdown


def handle_sigterm(signum, frame):
    """Handle SIGTERM by initiating immediate shutdown."""
    logger.info("Received SIGTERM signal. Initiating immediate shutdown...")
    shutdown_event.set()

    # If executor exists, wait for current tasks to complete
    if executor:
        logger.info("Shutting down thread pool...")
        executor.shutdown(wait=True)

    logger.info("Shutdown complete")
    sys.exit(0)


# Register the SIGTERM handler
signal.signal(signal.SIGTERM, handle_sigterm)


@dataclass
class Job:
    height: int
    step: int
    mode: str
    weight: int
    batch_file: Path
    execute_scripts: bool

    def __str__(self):
        return f"Job(height='{self.height}', step={self.step}, weight='{self.weight}')"

def calculate_batch_weight(block_data, mode):
    if mode == "light":
        return len(block_data["blocks"])
    else:
        return sum(
            len(tx["inputs"]) + len(tx["outputs"])
            for block in block_data["blocks"]
            for tx in block["data"]["transactions"]
        )


def job_generator(start, blocks, step, mode, strategy):
# Generator function to create jobs
def job_generator(start, blocks, step, mode, strategy, execute_scripts):
    BASE_DIR.mkdir(exist_ok=True)
    end = start + blocks
    height_range, step = (
        ([random.randint(start, end) for _ in range(start, end)], 1)
        if strategy == "random"
        else (range(start, end, step), step)
    )
    for height in height_range:
        try:
            batch_file = BASE_DIR / f"{mode}{height}_{step}.json"
            batch_data = generate_data(
                mode=mode, initial_height=height, num_blocks=step, fast=True
            )
            batch_file.write_text(json.dumps(batch_data, indent=2))
            batch_weight = calculate_batch_weight(batch_data, mode)
            yield Job(
                height, step, mode, batch_weight, batch_file, execute_scripts
            ), batch_weight
        except Exception as e:
            logger.error(f"Error while generating data for: {height}:\n{e}")


def run_process(arguments_file):
    """Run the process and return stdout, stderr, and return code."""
    process = subprocess.Popen(
# Function to process a batch
def process_batch(job):
    arguments_file = job.batch_file.as_posix().replace(".json", "-arguments.json")

    with open(arguments_file, "w") as af:
        af.write(str(format_args(job.batch_file, job.execute_scripts, False)))

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
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    while process.poll() is None:
        if shutdown_event.is_set():
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
            return None, None, -1

    stdout, stderr = process.communicate()
    return stdout, stderr, process.returncode


def process_batch(job):
    if shutdown_event.is_set():
        logger.info(f"Shutdown detected, skipping job: {job}")
        return

    arguments_file = job.batch_file.as_posix().replace(".json", "-arguments.json")
    try:
        with open(arguments_file, "w") as af:
            af.write(str(format_args(job.batch_file, False, False)))

        stdout, stderr, returncode = run_process(arguments_file)

        if stdout is None:  # Process was terminated due to shutdown
            return

        if (
            returncode != 0
            or "FAIL" in stdout
            or "error" in stdout
            or "panicked" in stdout
        ):
            error = stdout or stderr
            if returncode == -9:
                match = re.search(r"gas_spent=(\d+)", stdout)
                gas_info = (
                    f", gas spent: {int(match.group(1))}"
                    if match
                    else ", no gas info found"
                )
                error = f"Return code -9, killed by OOM?{gas_info}"
                message = error
            else:
                error_match = re.search(r"error='([^']*)'", error)
                message = error_match.group(1) if error_match else ""
            logger.error(f"{job} error: {message}")
            logger.debug(f"Full error while processing: {job}:\n{error}")
        else:
            match = re.search(r"gas_spent=(\d+)", stdout)
            gas_info = (
                f"gas spent: {int(match.group(1))}" if match else "no gas info found"
            )
            logger.info(f"{job} done, {gas_info}")
            if not match:
                logger.warning(f"{job}: no gas info found")
            error = f"Return code -9, killed by OOM?{gas_info}"
            message = error
        else:
            error_match = re.search(r"error='([^']*)'", error)
            if error_match:
                message = error_match.group(1)
            else:
                error_match = re.search(r"error: (.*)", error, re.DOTALL)

                if error_match:
                    message = error_match.group(1)
                else:
                    message = error

        message = re.sub(r"\s+", " ", message)

    except Exception as e:
        logger.error(f"Error processing batch {job}: {e}")


def job_producer(job_gen):
    global current_weight

    try:
        for job, weight in job_gen:
            with weight_lock:
                logger.debug(
                    f"Adding job: {job}, current total weight: {current_weight}..."
                )
                while (
                    current_weight + weight > MAX_WEIGHT_LIMIT and current_weight != 0
                ) or job_queue.full():
                    if shutdown_event.is_set():
                        return
                    logger.debug("Producer is waiting for weight to be released.")
                    weight_lock.wait(timeout=1)

                if current_weight + weight > MAX_WEIGHT_LIMIT and current_weight == 0:
                    logger.warning(f"{job} over the weight limit: {MAX_WEIGHT_LIMIT}")

                job_queue.put((job, weight))
                current_weight += weight
                weight_lock.notify_all()
    finally:
        logger.debug("Producer is exiting...")
        # Signal end of work to consumers
        for _ in range(THREAD_POOL_SIZE):
            job_queue.put(None)
        with weight_lock:
            weight_lock.notify_all()


def job_consumer(process_job):
    global current_weight

    while True:
        try:
            work_to_do = job_queue.get()

            if work_to_do is None:
                job_queue.task_done()
                break

            job, weight = work_to_do
            try:
                process_job(job)
            finally:
                with weight_lock:
                    current_weight -= weight
                    weight_lock.notify_all()
                job_queue.task_done()

        except Exception as e:
            logger.error("Error in the consumer: %s", e)
            break


def main(start, blocks, step, mode, strategy):
    global executor
def main(start, blocks, step, mode, strategy, execute_scripts):

    logger.info(
        "Starting client, initial height: %d, blocks: %d, step: %d, mode: %s, strategy: %s, execute_scripts: %s",
        start,
        blocks,
        step,
        mode,
        strategy,
        execute_scripts,
    )

    job_gen = job_generator(start, blocks, step, mode, strategy)
    # Create the job generator
    job_gen = job_generator(start, blocks, step, mode, strategy, execute_scripts)

    # Start the job producer thread
    producer_thread = threading.Thread(target=job_producer, args=(job_gen,))
    producer_thread.start()

    executor = ThreadPoolExecutor(max_workers=THREAD_POOL_SIZE)
    try:
        futures = [
            executor.submit(job_consumer, process_batch)
            for _ in range(THREAD_POOL_SIZE)
        ]
        producer_thread.join()
        job_queue.join()
    except KeyboardInterrupt:
        logger.info("Received KeyboardInterrupt, initiating shutdown...")
        handle_sigterm(signal.SIGTERM, None)
    finally:
        if not shutdown_event.is_set():
            logger.info("All jobs have been processed.")
            executor.shutdown(wait=True)


if __name__ == "__main__":
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
    parser.add_argument(
        "--maxweight", type=int, default=MAX_WEIGHT_LIMIT, help="Max weight limit"
    )

    parser.add_argument(
        "--execute-scripts", action="store_true", help="Execute scripts"
    )

    parser.add_argument("--verbose", action="store_true", help="Verbose")
    args = parser.parse_args()

    MAX_WEIGHT_LIMIT = args.maxweight

    file_handler = TimedRotatingFileHandler(
        filename="client.log",
        when="midnight",
        interval=1,
        backupCount=14,
        encoding="utf8",
    )
    file_handler.setLevel(logging.INFO)
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

    if args.verbose:
        root_logger.setLevel(logging.DEBUG)
    else:
        root_logger.setLevel(logging.INFO)

    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("generate_data").setLevel(logging.WARNING)

    main(
        args.start,
        args.blocks,
        args.step,
        args.mode,
        args.strategy,
        args.execute_scripts,
    )
