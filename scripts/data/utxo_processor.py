import os
import json
import requests
import subprocess
from typing import Dict, Any

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
                for line in f:
                    data = json.loads(line)
                    block_number = data["block_number"]
                    if block_number in index:
                        raise Exception(f"Duplicate block number {block_number}")
                    index[block_number] = chunk_path

    with open(INDEX_FILE, "w") as f:
        json.dump(index, f)


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
            data = json.loads(line)
            if data["block_number"] == block_number:
                return data

    raise Exception(f"Block {block_number} not found in chunk file {chunk_file}")


# Example usage
if __name__ == "__main__":
    # Download and split a couple of files
    download_and_split("000000000000.json")
    download_and_split("000000000001.json")

    # Create index
    create_index()

    # Get UTXO set for a specific block
    utxo_set = get_utxo_set(100000)
    print(json.dumps(utxo_set, indent=2))
