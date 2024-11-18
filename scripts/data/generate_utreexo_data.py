#!/usr/bin/env python3

import os
import json

BASE_DIR = f"{os.path.dirname(os.path.realpath(__file__))}/.utreexo_data"
BUCKET_SIZE = 10000


def get_utreexo_data(block_height):
    utreexo_data = {}

    if block_height > 1:
        bucket_number = block_height - 1 - ((block_height - 1) % BUCKET_SIZE)
        with open(f"{BASE_DIR}/{bucket_number}/{block_height - 1}.json") as f:
            data = json.loads(f.read())
            utreexo_data["state"] = convert_state(data["utreexo_state"])
    else:
        utreexo_data["state"] = {
            "roots": [],
            "num_leaves": 0,
        }

    bucket_number = block_height - (block_height % BUCKET_SIZE)
    with open(f"{BASE_DIR}/{bucket_number}/{block_height}.json") as f:
        data = json.loads(f.read())
        utreexo_data["proof"] = convert_proof(data["inclusion_proof"])
        utreexo_data["expected_state"] = convert_state(data["utreexo_state"])

    return utreexo_data


def convert_proof(proof):
    return {
        "proof": list(map(convert_felt, proof["hashes"])),
        "targets": proof["targets"],
    }


def convert_state(state):
    return {
        "roots": list(map(convert_root, state["roots"])),
        "num_leaves": state["num_leaves"],
    }


def convert_root(root: str) -> int:
    if root is None:
        return None
    else:
        return {"variant_id": 0, "value": convert_felt(root)}


def convert_felt(felt: str) -> int:
    return int.from_bytes(bytes.fromhex(felt[2:]), "big")


if __name__ == "__main__":
    # TODO: download ~/.bridge/blocks folder bucket by bucket from a remote server
    raise NotImplementedError
