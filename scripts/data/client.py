import os
import subprocess
import random
import sys
from pathlib import Path

BASE_DIR = ".client_cache"
DEFAULT_START = 0
DEFAULT_NO_OF_BLOCKS = 100
DEFAULT_STEP = 1
DEFAULT_MODE = "light"
DEFAULT_STRATEGY = "sequential"

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.returncode, result.stdout

Path(BASE_DIR).mkdir(parents=True, exist_ok=True)

start = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_START
no_of_blocks = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_NO_OF_BLOCKS
end = start + no_of_blocks
step = int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_STEP
mode = sys.argv[4] if len(sys.argv) > 4 else DEFAULT_MODE
strategy = sys.argv[5] if len(sys.argv) > 5 else DEFAULT_STRATEGY

def run_client(initial_height, num_blocks):
    first = initial_height + 1
    second = initial_height + num_blocks

    batch_file = f"{BASE_DIR}/{mode}_{initial_height}_{num_blocks}.json"
    arguments_file = f"{BASE_DIR}/arguments-{mode}_{initial_height}_{num_blocks}.json"

    if not Path(batch_file).is_file():
        command = f"python scripts/data/generate_data.py --fast --mode {mode} --height {initial_height} --num_blocks {num_blocks} --output_file {batch_file}"
        returncode, _ = run_command(command)
        if returncode != 0:
            print(f"Error generating data for blocks {first}-{second}")
            sys.exit(1)

    print(f"Running {mode} client on blocks {first} - {second} ", end="")

    command = f"python scripts/data/format_args.py {batch_file} > {arguments_file}"
    returncode, _ = run_command(command)
    if returncode != 0:
        print(f"Error formatting arguments for blocks {first}-{second}")
        sys.exit(1)

    command = f"scarb cairo-run --no-build --package client --function test --arguments-file {arguments_file}"
    returncode, output = run_command(command)

    if returncode != 0 or "FAIL" in output or "error" in output or "panicked" in output:
        print("fail")
        print(output)
        sys.exit(1)
    else:
        print("ok")
        print(output)

for height in range(start, end, step):
    if strategy == "sequential":
        run_client(height, step)
    elif strategy == "random":
        random_height = random.randint(0, 24) * 25 + random.randint(0, 24)
        run_client(random_height, 1)
    else:
        print("Unsupported strategy")
        sys.exit(1)