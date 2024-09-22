import json
import os
import requests

GCS_BASE_URL = "https://storage.cloud.google.com/shinigami-consensus/previous_outputs/"
BASE_DIR = "previous_outputs"


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


def mapped_data(folder_path):
    formatted_data = {}
    for filename in os.listdir(folder_path):
        if filename.endswith(".json"):
            with open(os.path.join(folder_path, filename), "r") as file:
                data = [json.loads(line.rstrip()) for line in file]
                for entry in data:
                    block_number = entry["block_number"]
                    formatted_data[block_number] = {
                        "previous_timestamps": entry["previous_timestamps"],
                        "median_timestamp": entry["median_timestamp"],
                    }
    return formatted_data


if __name__ == "__main__":

    for i in range(100):
        file_name = f"{i:012}.json"
        download_timestamp(file_name)

    formatted_data = mapped_data(BASE_DIR)
    with open("timestamp_data.json", "w") as outfile:
        json.dump(formatted_data, outfile, indent=4)
