import os
import json
import requests
import subprocess
from typing import Dict, Any
import argparse
from tqdm import tqdm

# Constants
GCS_BASE_URL = "https://storage.cloud.google.com/shinigami-consensus/utxos/"
BASE_DIR = "utxo_data"
CHUNK_SIZE = 10000
INDEX_FILE = "utxo_index.json"


def download_and_split(file_name: str):
    """Download a file from GCS and split it into chunks."""
    os.makedirs(BASE_DIR, exist_ok=True)
    file_dir = os.path.join(BASE_DIR, file_name.split(".")[0])
    os.makedirs(file_dir, exist_ok=True)

    url = f"{GCS_BASE_URL}{file_name}"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to download {file_name}")

    file_path = os.path.join(BASE_DIR, file_name)
    with open(file_path, "wb") as f:
        f.write(response.content)

    # Split file
    split_cmd = f"split -l {CHUNK_SIZE} {file_path} {file_dir}/chunk_"
    subprocess.run(split_cmd, shell=True, check=True)

    # Remove original file
    os.remove(file_path)


def create_index():
    """Create an index mapping block numbers to chunk files."""
    index: Dict[int, str] = {}

    for dir_name in os.listdir(BASE_DIR):
        dir_path = os.path.join(BASE_DIR, dir_name)
        if not os.path.isdir(dir_path):
            continue

        for chunk_file in os.listdir(dir_path):
            chunk_path = os.path.join(dir_path, chunk_file)
            with open(chunk_path, "r") as f:
                for line_num, line in enumerate(f, 1):
                    try:
                        data = json.loads(line.strip())
                        block_number = data["block_number"]
                        if block_number in index:
                            print(f"Warning: Duplicate block number {block_number}")
                        index[block_number] = chunk_path
                    except json.JSONDecodeError as e:
                        print(
                            f"Error decoding JSON in file {chunk_path}, line {line_num}: {e}"
                        )
                        print(f"Problematic line: {line.strip()}")
                    except KeyError as e:
                        print(f"KeyError in file {chunk_path}, line {line_num}: {e}")
                        print(f"Data: {data}")

    with open(INDEX_FILE, "w") as f:
        json.dump(index, f)

    print(f"Index created with {len(index)} entries")


def get_utxo_set(block_number: int) -> Dict[str, Any]:
    """Get the UTXO set for a given block number."""
    # Load index
    if not os.path.exists(INDEX_FILE):
        create_index()

    with open(INDEX_FILE, "r") as f:
        index = json.load(f)

    # Find chunk file
    chunk_file = index.get(str(block_number))
    if not chunk_file:
        raise Exception(f"Block number {block_number} not found in index")

    # If chunk file doesn't exist, download and split
    if not os.path.exists(chunk_file):
        file_name = os.path.basename(os.path.dirname(chunk_file)) + ".json"
        download_and_split(file_name)

    # Find and return data for the block
    with open(chunk_file, "r") as f:
        for line in f:
            data = json.loads(line.strip())
            if data["block_number"] == block_number:
                return data

    raise Exception(f"Block {block_number} not found in chunk file {chunk_file}")


def process_file_range(start_file: str, end_file: str):
    """Process a range of files from start_file to end_file."""
    start_num = int(start_file.split(".")[0])
    end_num = int(end_file.split(".")[0])

    for file_num in tqdm(range(start_num, end_num + 1), desc="Processing files"):
        file_name = f"{file_num:012d}.json"
        print(f"\nProcessing file: {file_name}")
        download_and_split(file_name)

    print("\nCreating index...")
    create_index()
    print("Index creation completed.")


# usage
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process UTXO files.")
    parser.add_argument(
        "--from",
        dest="start_file",
        required=True,
        help="Starting file number (e.g., 000000000001)",
    )
    parser.add_argument(
        "--to",
        dest="end_file",
        required=True,
        help="Ending file number (e.g., 000000000050)",
    )

    args = parser.parse_args()

    process_file_range(args.start_file, args.end_file)

    print("All files processed successfully.")
