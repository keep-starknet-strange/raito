#!/usr/bin/env python3
import os
import subprocess
import random
import argparse
from pathlib import Path
from generate_data import generate_data
from format_args import format_args

BASE_DIR = Path(".client_cache")
DEFAULT_NO_OF_BLOCKS = 1

def run_client(initial_height, num_blocks, mode):
    first = initial_height + 1
    second = initial_height + num_blocks
    batch_file = BASE_DIR / f"{mode}_{initial_height}_{num_blocks}.json"
    arguments_file = BASE_DIR / f"arguments-{mode}_{initial_height}_{num_blocks}.json"

    if not batch_file.exists():
        generate_data(
            fast=True,
            mode=mode,
            height=initial_height,
            num_blocks=num_blocks,
            output_file=str(batch_file),
        )

    print(f"Running {mode} client on blocks {first} - {second}", end=" ", flush=True)

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
        return False
    else:
        print("ok")
        print(result.stdout)
        return True

def process_blocks(args):
    BASE_DIR.mkdir(exist_ok=True)
    end = args.start + args.blocks

    for height in range(args.start, end, args.step):
        if args.strategy == "sequential":
            if not run_client(height, args.step, args.mode):
                return
        elif args.strategy == "random":
            random_height = random.randint(0, 49)
            if not run_client(random_height, 1, args.mode):
                return
        else:
            print("Unsupported strategy")
            return

def main():
    parser = argparse.ArgumentParser(description="Run client script")
    parser.add_argument("--start", type=int, default=1, help="Start block height")
    parser.add_argument(
        "--blocks", type=int, default=DEFAULT_NO_OF_BLOCKS, help="Number of blocks to process"
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
    process_blocks(args)

if __name__ == "__main__":
    main()