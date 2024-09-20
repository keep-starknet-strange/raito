import sys
import json
from pathlib import Path

def calculate_median_timestamps(data):
    result = {} 
    block_height = data['chain_state']['block_height']
    blocks = data['blocks']
    timestamps = data['chain_state']['prev_timestamps']
    results = {} 
    for block_number, block in enumerate(blocks, start=block_height):
        # maintain the list 
        prev_timestamp = timestamps[-1]
        median_timestamp = sorted(timestamps)[len(timestamps) // 2]
        results[block_number] = {
            "prev_timestamp": prev_timestamp,
            "median_timestamp": median_timestamp
        }
        timestamps.pop(0)
        timestamps.append(block['header']['time'])
    
    return results



if __name__ == "__main__":

    # example useage python3 generate_timestamp_data.py light_20_30.json timestamp_20_30.json 
    # light_20_30.json data dump file from the generate data file 
    if len(sys.argv) != 3:
        raise TypeError("Expected two arguments: input_file_path output_file_path")
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    with open(input_file, 'r') as file:
        data = json.load(file)
    results = calculate_median_timestamps(data)
    with open(output_file, 'w') as file:
       json.dump(results, file, indent=2)
