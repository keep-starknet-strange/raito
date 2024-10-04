#!/usr/bin/env python

import argparse
import json
import os
import sys
import time
from decimal import Decimal, getcontext
from pathlib import Path

import requests
from tqdm import tqdm

from generate_timestamp_data import get_timestamp_data
from generate_utreexo_data import UtreexoData
from generate_utxo_data import get_utxo_set

getcontext().prec = 16

BITCOIN_RPC = os.getenv("BITCOIN_RPC")
USERPWD = os.getenv("USERPWD")
DEFAULT_URL = "https://bitcoin-mainnet.public.blastapi.io"

FAST = False

RETRIES = 3
DELAY = 2


def request_rpc(method: str, params: list):
    """Makes a JSON-RPC call to a Bitcoin API endpoint.
    Retries the request a specified number of times before failing.

    :param retries: Number of retry attempts before raising an exception.
    :param delay: Delay between retries in seconds.
    :return: parsed JSON result as Python object
    """
    url = BITCOIN_RPC or DEFAULT_URL
    auth = tuple(USERPWD.split(":")) if USERPWD else None
    headers = {"content-type": "application/json"}
    payload = {"jsonrpc": "2.0", "method": method, "params": params, "id": 0}

    for attempt in range(RETRIES):
        try:
            res = requests.post(url, auth=auth, headers=headers, json=payload)
            return res.json()["result"]
        except Exception:
            if attempt < RETRIES - 1:
                f"Connection error: {res.text}, will retry in {DELAY}s"
                time.sleep(DELAY)  # Wait before retrying
            else:
                raise ConnectionError(
                    f"Unexpected RPC response after {RETRIES} attempts:\n{res.text}"
                )


def fetch_chain_state_fast(block_height: int):
    """Fetches chain state at the end of a specific block with given height.
    Chain state is a just a block header extended with extra fields:
        - prev_timestamps
        - epoch_start_time
    """
    # Chain state at height H is the state after applying block H
    block_hash = request_rpc("getblockhash", [block_height])
    head = request_rpc("getblockheader", [block_hash])

    # If block is downloaded take it locally
    data = get_timestamp_data(block_height)[str(block_height)]
    head["prev_timestamps"] = [int(t) for t in data["previous_timestamps"]]
    if block_height < 2016:
        head["epoch_start_time"] = 1231006505
    else:
        head["epoch_start_time"] = int(data["epoch_start_time"])
    return head


def fetch_chain_state(block_height: int):
    """Fetches chain state at the end of a specific block with given height.
    Chain state is a just a block header extended with extra fields:
        - prev_timestamps
        - epoch_start_time
    """
    # Chain state at height H is the state after applying block H
    block_hash = request_rpc("getblockhash", [block_height])
    head = request_rpc("getblockheader", [block_hash])

    # In order to init prev_timestamps we need to query 10 previous headers
    prev_header = head
    prev_timestamps = [int(head["time"])]
    for _ in range(10):
        if prev_header["height"] == 0:
            prev_timestamps.insert(0, 0)
        else:
            prev_header = request_rpc(
                "getblockheader", [prev_header["previousblockhash"]]
            )
            prev_timestamps.insert(0, int(prev_header["time"]))
    head["prev_timestamps"] = prev_timestamps

    # In order to init epoch start we need to query block header at epoch start
    if block_height < 2016:
        head["epoch_start_time"] = 1231006505
    else:
        head["epoch_start_time"] = get_epoch_start_time(block_height)

    return head


def next_chain_state(head: dict, blocks: list):
    """Computes resulting chain state given the initial chain state
    and all blocks that were applied to it.
    """
    block_height = head["height"] + len(blocks)
    next_head = blocks[-1]

    # We need to recalculate the prev_timestamps field given the previous chain state
    # and all the blocks we applied to it
    prev_timestamps = head["prev_timestamps"] + list(map(lambda x: x["time"], blocks))
    next_head["prev_timestamps"] = prev_timestamps[-11:]

    # Update epoch start time if necessary
    if head["height"] // 2016 != block_height // 2016:
        next_head["epoch_start_time"] = get_epoch_start_time(block_height)
    else:
        next_head["epoch_start_time"] = head["epoch_start_time"]
    return next_head


def get_epoch_start_time(block_height: int) -> int:
    """Computes the corresponding epoch start time given the current block height."""
    epoch_start_block_height = (block_height // 2016) * 2016
    epoch_start_block_hash = request_rpc("getblockhash", [epoch_start_block_height])
    epoch_start_header = request_rpc("getblockheader", [epoch_start_block_hash])
    return epoch_start_header["time"]


def format_chain_state(head: dict):
    """Formats chain state according to the respective Cairo type."""
    return {
        "block_height": head["height"],
        "total_work": str(int.from_bytes(bytes.fromhex(head["chainwork"]), "big")),
        "best_block_hash": head["hash"],
        "current_target": str(bits_to_target(head["bits"])),
        "epoch_start_time": head["epoch_start_time"],
        "prev_timestamps": head["prev_timestamps"],
    }


def bits_to_target(bits: str) -> int:
    """Convert difficulty bits (compact target representation) to target.

    :param bits: bits as a hex string (without 0x prefix)
    :return: target as integer
    """
    exponent = int.from_bytes(bytes.fromhex(bits[:2]), "big")
    mantissa = int.from_bytes(bytes.fromhex(bits[2:]), "big")
    if exponent == 0:
        return mantissa
    elif exponent <= 3:
        return mantissa >> (8 * (3 - exponent))
    else:
        return mantissa << (8 * (exponent - 3))


def fetch_block(block_hash: str, fast: bool):
    """Downloads block with transactions (and referred UTXOs) from RPC given the block hash."""
    block = request_rpc("getblock", [block_hash, 2])

    previous_outputs = (
        {(o["txid"], int(o["vout"])): o for o in get_utxo_set(block["height"] + 1)}
        if fast
        else None
    )

    block["data"] = {
        tx["txid"]: resolve_transaction(tx, previous_outputs)
        for tx in tqdm(block["tx"], "Resolving transactions")
    }
    return block


def resolve_transaction(transaction: dict, previous_outputs: dict):
    """Resolves transaction inputs and formats the content according to the Cairo type."""
    return {
        "version": transaction["version"],
        # Skip the first 4 bytes (version) and take the next 4 bytes (marker + flag)
        "is_segwit": transaction["hex"][8:12] == "0001",
        "inputs": [
            resolve_input(input, previous_outputs) for input in transaction["vin"]
        ],
        "outputs": [format_output(output) for output in transaction["vout"]],
        "lock_time": transaction["locktime"],
    }


def resolve_input(input: dict, previous_outputs: dict):
    """Resolves referenced UTXO and formats the transaction inputs according to the Cairo type."""
    if input.get("coinbase"):
        return format_coinbase_input(input)
    else:
        if previous_outputs:
            previous_output = format_outpoint(
                previous_outputs[(input["txid"], input["vout"])]
            )
        else:
            previous_output = resolve_outpoint(input)
        return {
            "script": f'0x{input["scriptSig"]["hex"]}',
            "sequence": input["sequence"],
            "previous_output": previous_output,
            "witness": [f"0x{item}" for item in input.get("txinwitness", [])],
        }


def format_outpoint(previous_output):
    """Formats output according to the Cairo type."""

    return {
        "txid": previous_output["txid"],
        "vout": int(previous_output["vout"]),
        "data": {
            "value": int(previous_output["value"]),
            "pk_script": f'0x{previous_output["pk_script"]}',
            "cached": False,
        },
        "block_hash": previous_output["block_hash"],
        "block_height": int(previous_output["block_height"]),
        "block_time": int(previous_output["block_time"]),
        "is_coinbase": previous_output["is_coinbase"],
    }


def resolve_outpoint(input: dict):
    """Fetches transaction and block header for the referenced output,
    formats resulting outpoint according to the Cairo type.
    """
    tx = request_rpc("getrawtransaction", [input["txid"], True])
    block = request_rpc("getblockheader", [tx["blockhash"]])
    return {
        "txid": input["txid"],
        "vout": input["vout"],
        "data": format_output(tx["vout"][input["vout"]]),
        "block_hash": tx["blockhash"],
        "block_height": block["height"],
        "block_time": block["time"],
        "is_coinbase": tx["vin"][0].get("coinbase") is not None,
    }


def format_coinbase_input(input: dict):
    """Formats coinbase input according to the Cairo type."""
    return {
        "script": f'0x{input["coinbase"]}',
        "sequence": input["sequence"],
        "previous_output": {
            "txid": "0" * 64,
            "vout": 0xFFFFFFFF,
            "data": {"value": 0, "pk_script": "0x", "cached": False},
            "block_hash": "0" * 64,
            "block_height": 0,
            "block_time": 0,
            "is_coinbase": False,
        },
        "witness": [
            "0x0000000000000000000000000000000000000000000000000000000000000000"
        ],
    }


def format_output(output: dict):
    """Formats transaction output according to the Cairo type."""
    value = (Decimal(str(output["value"])) * Decimal("100000000")).to_integral_value()
    return {
        "value": int(value),
        "pk_script": f'0x{output["scriptPubKey"]["hex"]}',
        "cached": False,
    }


def format_block_with_transactions(block: dict):
    """Formats block with transactions according to the respective Cairo type."""
    return {
        "header": format_header(block),
        "data": {"variant_id": 1, "transactions": list(block["data"].values())},
    }


def fetch_block_header(block_hash: str):
    """Downloads block header (without transaction) from RPC given the block hash."""
    return request_rpc("getblockheader", [block_hash])


def format_block(header: dict):
    """Formats block (without transactions) according to the respective Cairo type.
    Note that transaction data uses a verbose format to include information
    about the particular enum variant.

    :param header: block header obtained from RPC
    """
    return {
        "header": format_header(header),
        "data": {"variant_id": 0, "merkle_root": header["merkleroot"]},
    }


def format_header(header: dict):
    """Formats header according to the respective Cairo type.

    :param header: block header obtained from RPC
    """
    return {
        "hash": header["hash"],
        "version": header["version"],
        "time": header["time"],
        "bits": int.from_bytes(bytes.fromhex(header["bits"]), "big"),
        "nonce": header["nonce"],
    }


def generate_data(
    mode: str,
    initial_height: int,
    num_blocks: int,
    fast: bool,
):
    """Generates arguments for Raito program in a human readable form and the expected result.

    :param mode: Validation mode:
        "light" — generate block headers with Merkle root only
        "full" — generate full blocks with transactions (and referenced UTXOs)
        "utreexo" — only last block from the batch is included, but it is extended with Utreexo state/proofs
    :param initial_height: The block height of the initial chain state (0 means the state after genesis)
    :param num_blocks: The number of blocks to apply on top of it (has to be at least 1)
    :return: tuple (arguments, expected output)
    """

    if fast:
        print("Fetching chain state (fast)...")
    else:
        print("Fetching chain state...")

    print(f"blocks: {initial_height} - {initial_height + num_blocks - 1}")

    chain_state = (
        fetch_chain_state_fast(initial_height)
        if fast
        else fetch_chain_state(initial_height)
    )

    next_block_hash = chain_state["nextblockhash"]
    blocks = []
    utreexo_data = {}

    for i in range(num_blocks):
        # Interblock cache
        tmp_utxo_set = {}
        if mode == "light":
            block = fetch_block_header(next_block_hash)
        elif mode in ["full", "utreexo"]:
            print(
                f"\rFetching block {initial_height + i}/{initial_height + num_blocks}",
                end="",
                flush=True,
            )
            block = fetch_block(next_block_hash, fast)

            # Build UTXO set and mark outputs spent within the same block (span).
            # Also set "cached" flag for the inputs that spend those UTXOs.
            for txid, tx in block["data"].items():
                for tx_input in tx["inputs"]:
                    outpoint = (
                        tx_input["previous_output"]["txid"],
                        tx_input["previous_output"]["vout"],
                    )
                    if outpoint in tmp_utxo_set:
                        tx_input["previous_output"]["data"]["cached"] = True
                        tmp_utxo_set[outpoint]["cached"] = True

                for idx, output in enumerate(tx["outputs"]):
                    outpoint = (txid, idx)
                    tmp_utxo_set[outpoint] = output

            # Do another pass to mark UTXOs spent within the same block (span) with "cached" flag.
            for txid, tx in block["data"].items():
                for idx, output in enumerate(tx["outputs"]):
                    outpoint = (txid, idx)
                    if outpoint in tmp_utxo_set and tmp_utxo_set[outpoint]["cached"]:
                        tx["outputs"][idx]["cached"] = True
        else:
            raise NotImplementedError(mode)

        next_block_hash = block["nextblockhash"]
        blocks.append(block)

    block_formatter = (
        format_block if mode == "light" else format_block_with_transactions
    )
    result = {
        "chain_state": format_chain_state(chain_state),
        "blocks": list(map(block_formatter, blocks)),
        "expected": format_chain_state(next_chain_state(chain_state, blocks)),
    }

    if mode == "utreexo":
        utreexo_data = UtreexoData()
        result["utreexo"] = utreexo_data.apply_blocks(blocks)
        result["blocks"] = [result["blocks"][-1]]
        if num_blocks > 1:
            result["chain_state"] = format_chain_state(
                fetch_chain_state(blocks[-2]["height"])
            )

    return result


def str2bool(value):
    if isinstance(value, bool):
        return value
    if value.lower() in ("yes", "true", "t", "y", "1"):
        return True
    elif value.lower() in ("no", "false", "f", "n", "0"):
        return False
    else:
        raise argparse.ArgumentTypeError("Boolean value expected.")


# Example: generate_data.py --mode 'light' --height 0 --num_blocks 10 --output_file light_0_10.json
# Example: generate_data.py --mode 'full' --height 0 --num_blocks 10 --output_file full_0_10.json --fast
# Example: generate_data.py --mode 'utreexo' --height 0 --num_blocks 10 --output_file utreexo_0_10.json --fast
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Process UTXO files.")
    parser.add_argument(
        "--mode",
        dest="mode",
        default="full",
        choices=["light", "full", "utreexo"],
        help="Mode",
    )

    parser.add_argument(
        "--height",
        dest="height",
        required=True,
        type=int,
        help="The block height of the initial chain state",
    )

    parser.add_argument(
        "--num_blocks",
        dest="num_blocks",
        required=True,
        type=int,
        help="The number of blocks",
    )

    parser.add_argument(
        "--output_file",
        dest="output_file",
        required=True,
        type=str,
        help="Output file",
    )

    parser.add_argument(
        "--fast",
        dest="fast",
        action="store_true",
        help="Fast mode",
    )

    args = parser.parse_args()

    data = generate_data(
        mode=args.mode,
        initial_height=args.height,
        num_blocks=args.num_blocks,
        fast=args.fast,
    )

    Path(args.output_file).write_text(json.dumps(data, indent=2))
