#!/usr/bin/env python

import sys
import os
import json
import requests
from pathlib import Path

BITCOIN_RPC = os.getenv("BITCOIN_RPC")
USERPWD = os.getenv("USERPWD")
DEFAULT_URL = "https://bitcoin-mainnet.public.blastapi.io"


def request_rpc(method: str, params: list):
    """Makes a JSON-RPC call to a Bitcoin API endpoint.
    Uses environment variables BITCOIN_RPC and USERPWD 
    or the default public endpoint if those variables are not set.

    :return: parsed JSON result as Python object
    """
    url = BITCOIN_RPC or DEFAULT_URL
    auth = tuple(USERPWD.split(":")) if USERPWD else None
    headers = {'content-type': 'application/json'}
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 0,
    }
    res = requests.post(url, auth=auth, headers=headers, json=payload)
    try:
        return res.json()['result']
    except Exception:
        raise ConnectionError(f"Unexpected RPC response:\n{res.text}")


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
    prev_timestamps = [head['time']]
    for _ in range(10):
        if prev_header['height'] == 0:
            prev_timestamps.insert(0, 0)
        else:
            prev_header = request_rpc("getblockheader", [prev_header['previousblockhash']])
            prev_timestamps.insert(0, prev_header['time'])
    head['prev_timestamps'] = prev_timestamps

    # In order to init epoch start we need to query block header at epoch start
    if block_height < 2016:
        head['epoch_start_time'] = 1231006505
    else:
        head['epoch_start_time'] = get_epoch_start_time(block_height)

    return head


def next_chain_state(head: dict, blocks: list):
    """Computes resulting chain state given the initial chain state
    and all blocks that were applied to it.
    """
    block_height = head['height'] + len(blocks)
    next_head = blocks[-1]

    # We need to recalculate the prev_timestamps field given the previous chain state
    # and all the blocks we applied to it
    prev_timestamps = head['prev_timestamps'] + list(map(lambda x: x['time'], blocks))
    next_head['prev_timestamps'] = prev_timestamps[-11:]

    # Update epoch start time if neccesary
    if head['height'] // 2016 != block_height // 2016:
        next_head['epoch_start_time'] = get_epoch_start_time(block_height)
    else:
        next_head['epoch_start_time'] = head['epoch_start_time']
    return next_head


def get_epoch_start_time(block_height: int) -> int:
    """Computes the corresponding epoch start time given the current block height.
    """
    epoch_start_block_height = (block_height // 2016) * 2016
    epoch_start_block_hash = request_rpc("getblockhash", [epoch_start_block_height])
    epoch_start_header = request_rpc("getblockheader", [epoch_start_block_hash])
    return epoch_start_header['time']


def format_chain_state(head: dict):
    """Formats chain state according to the respective Cairo type.
    """
    return {
        "block_height": head['height'],
        "total_work": str(int.from_bytes(bytes.fromhex(head['chainwork']), 'big')),
        "best_block_hash": head['hash'],
        "current_target": str(bits_to_target(head['bits'])),
        "epoch_start_time": head['epoch_start_time'],
        "prev_timestamps": head['prev_timestamps'],
    }


def bits_to_target(bits: str) -> int:
    """Convert difficulty bits (compact target representation) to target.

    :param bits: bits as a hex string (without 0x prefix)
    :return: target as integer
    """
    exponent = int.from_bytes(bytes.fromhex(bits[:2]), 'big')
    mantissa = int.from_bytes(bytes.fromhex(bits[2:]), 'big')
    if exponent == 0:
        return mantissa
    elif exponent <=3:
        return mantissa >> (8 * (3 - exponent))
    else:
        return mantissa << (8 * (exponent - 3))


def fetch_block(block_hash: str):
    """Downloads block with transactions (and referred UTXOs) from RPC given the block hash.
    """
    block = request_rpc("getblock", [block_hash, 2])
    block['data'] = [resolve_transaction(tx) for tx in block['tx']]
    return block


def resolve_transaction(transaction: dict):
    """Resolves transaction inputs and formats the content according to the Cairo type.
    """
    return {
        "version": transaction['version'],
        # Skip the first 4 bytes (version) and take the next 4 bytes (marker + flag)
        "is_segwit": transaction["hex"][8:12] == "0001",
        "inputs": [resolve_input(input) for input in transaction['vin']],
        "outputs": [format_output(output) for output in transaction['vout']],
        "lock_time": transaction['locktime'],
    }


def resolve_input(input: dict):
    """Resolves referenced UTXO and formats the transaction inputs according to the Cairo type.
    """
    if input.get('coinbase'):
        return format_coinbase_input(input)
    else:
        return {
            "script": f'0x{input["scriptSig"]["hex"]}',
            "sequence": input['sequence'],
            "previous_output": resolve_outpoint(input),
            "witness": [f'0x{item}' for item in input.get('txinwitness', [])],
        }


def resolve_outpoint(input: dict):
    """Fetches transaction and block header for the referenced output,
    formats resulting outpoint according to the Cairo type.
    """
    tx = request_rpc("getrawtransaction", [input['txid'], True])
    block = request_rpc("getblockheader", [tx['blockhash']])
    return {
        "txid": input['txid'],
        "vout": input['vout'],
        "data": format_output(tx['vout'][input['vout']]),
        "block_height": block['height'],
        "block_time": block['time'],
        "is_coinbase": tx['vin'][0].get('coinbase') is not None
    }


def format_coinbase_input(input: dict):
    """Formats coinbase input according to the Cairo type.
    """
    return {
        "script": f'0x{input["coinbase"]}',
        "sequence": input["sequence"],
        "previous_output": {
            "txid": "0" * 64,
            "vout": 0xffffffff,
            "data": {
                "value": 0,
                "pk_script": '0x',
                "cached": False,
            },
            "block_height": 0,
            "block_time": 0,
            "is_coinbase": False,
        },
        "witness": []
    }


def format_output(output: dict):
    """Formats transaction output according to the Cairo type.
    """
    return {
        "value": int(output["value"] * 100000000),
        "pk_script": f'0x{output["scriptPubKey"]["hex"]}',
        "cached": False,
    }


def format_block_with_transactions(block: dict):
    """Formats block with transactions according to the respective Cairo type.
    """
    return {
        "header": format_header(block),
        "data": {
            "variant_id": 1,
            "transactions": block['data'],  # already formatted
        }
    }


def fetch_block_header(block_hash: str):
    """Downloads block header (without trasnasction) from RPC given the block hash.
    """
    return request_rpc("getblockheader", [block_hash])


def format_block(header: dict):
    """Formats block (without transactions) according to the respective Cairo type.
    Note that transaction data uses a verbose format to include information
    about the particular enum variant.

    :param header: block header obtained from RPC
    """
    return {
        "header": format_header(header),
        "data": {
            "variant_id": 0,
            "merkle_root": header['merkleroot']
        }
    }


def format_header(header: dict):
    """Formats header according to the respective Cairo type.

    :param header: block header obtained from RPC
    """
    return {
        "version": header['version'],
        "time": header['time'],
        "bits": int.from_bytes(bytes.fromhex(header['bits']), 'big'),
        "nonce": header['nonce']
    }


def generate_data(mode: str, initial_height: int, num_blocks: int, include_expected: bool):
    """Generates arguments for Raito program in a human readable form and the expected result.

    :param mode: Validation mode: 
        "light" — generate block headers with Merkle root only
        "full" — generate full blocks with transactions (and referenced UTXOs)
    :param initial_height: The block height of the initial chain state (0 means the state after genesis)
    :param num_blocks: The number of blocks to apply on top of it (has to be at least 1)
    :return: tuple (arguments, expected output)
    """
    chain_state = fetch_chain_state(initial_height)
    next_block_hash = chain_state['nextblockhash']
    blocks = []

    for _ in range(num_blocks):
        if mode == 'light':
            block = fetch_block_header(next_block_hash)
        elif mode == 'full':
            block = fetch_block(next_block_hash)
        else:
            raise NotImplementedError(mode)
        next_block_hash = block['nextblockhash']
        blocks.append(block)

    block_formatter = format_block if mode == 'light' else format_block_with_transactions
    result = {
        "chain_state": format_chain_state(chain_state),
        "blocks": list(map(block_formatter, blocks)),
    }

    if include_expected:
        result['expected'] = format_chain_state(next_chain_state(chain_state, blocks))

    return result


# Usage: generate_data.py MODE INITIAL_HEIGHT NUM_BLOCKS INCLUDE_EXPECTED OUTPUT_FILE
# Example: generate_data.py 'light' 0 10 false light_0_10.json
if __name__ == '__main__':
    if (len(sys.argv) != 6):
        raise TypeError("Expected five arguments")

    data = generate_data(
        mode=sys.argv[1],
        initial_height=int(sys.argv[2]),
        num_blocks=int(sys.argv[3]),
        include_expected=sys.argv[4].lower() == "true",
    )

    Path(sys.argv[5]).write_text(json.dumps(data, indent=2))
