import json
import os
import requests
from google.cloud import storage


GCS_BASE_URL = "https://storage.cloud.google.com/shinigami-consensus/previous_outputs/"
BASE_DIR = "previous_outputs"
bucket_name = "shinigami-consensus"
folder_prefix = "previous_outputs/"


def download_timestamp(file_name: str):
    """Download a file from GCS and save it locally."""
    os.makedirs(BASE_DIR, exist_ok=True)
    file_path = os.path.join(BASE_DIR, file_name)
    if os.path.exists(file_path):
        print(f"{file_name} already exists, skipping download.")
        return

    url = f"{GCS_BASE_URL}{file_name}"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to download {file_name}")

    with open(file_path, "wb") as f:
        f.write(response.content)


def create_index(folder_path):
    index = {}
    for filename in os.listdir(folder_path):
        if filename.endswith(".json"):
            with open(os.path.join(folder_path, filename), "r") as file:
                data = [json.loads(line.rstrip()) for line in file]
                for entry in data:
                    block_number = entry["block_number"]
                    index[block_number] = {
                        "previous_timestamps": entry["previous_timestamps"],
                        "median_timestamp": entry["median_timestamp"],
                    }
    return index


def list_files_in_gcs(bucket_name: str, prefix: str):
    """List all files in a GCS bucket under a specific folder (prefix)."""
    client = storage.Client()
    bucket = client.get_bucket(bucket_name)
    blobs = bucket.list_blobs(prefix=prefix)
    return [blob.name for blob in blobs if blob.name.endswith(".json")]


if __name__ == "__main__":

    bucket_name = "shinigami-consensus"
    folder_prefix = "previous_outputs/"
    file_names = list_files_in_gcs(bucket_name, folder_prefix)
    for file_name in file_names:
        download_timestamp(file_name)

    index = create_index(BASE_DIR)
    with open("timestamp_data.json", "w") as outfile:
        json.dump(index, outfile, indent=4)
