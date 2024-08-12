import os
import requests
import json

# Set environment variables
BITCOIN_RPC = os.getenv('BITCOIN_RPC')
USERPWD = os.getenv('USERPWD')

def get_block_height(block_hash):
    payload = {
        "jsonrpc": "1.0",
        "id": "curltest",
        "method": "getblockheader",
        "params": [block_hash]
    }
    headers = {'content-type': 'text/plain;'}
    response = requests.post(BITCOIN_RPC, auth=tuple(USERPWD.split(':')), headers=headers, data=json.dumps(payload))
    response_json = response.json()
    return response_json['result']['height']

def get_raw_transaction(txid, verbose=True, blockhash=None):
    params = [txid, verbose]
    if blockhash:
        params.append(blockhash)
    
    payload = {
        "jsonrpc": "1.0",
        "id": "curltest",
        "method": "getrawtransaction",
        "params": params
    }
    headers = {'content-type': 'text/plain;'}
    response = requests.post(BITCOIN_RPC, auth=tuple(USERPWD.split(':')), headers=headers, data=json.dumps(payload))
    response_json = response.json()
    return response_json['result']

def generate_txin_regular(vin):
    raw_tx = get_raw_transaction(vin["txid"], verbose=True)
    vout = raw_tx["vout"][vin["vout"]]
    value = vout["value"]

    return f'''TxIn {{
        script: from_base16("{vin["scriptSig"]["hex"]}"),
        sequence: {vin["sequence"]},
        previous_output: OutPoint {{
            txid: 0x{vin["txid"]},
            vout: {vin["vout"]},
            txo_index: 0, // TODO: implement
            value: {int((value if value else 0) * 100000000)}_u64  
        }},
        witness: @""  // Placeholder for witness
    }}'''

def generate_txin(vin):
    if 'coinbase' in vin:
        return f'''TxIn {{
        script: from_base16("{vin["coinbase"]}"),
        sequence: {vin["sequence"]},
        previous_output: OutPoint {{
            txid: 0_u256,
            vout: 0xffffffff_u32,
            txo_index: 0, // TODO: implement
        }},
        witness: @""  // Placeholder for witness
    }}'''
    else:
        return generate_txin_regular(vin)

def generate_txout(vout):
    # TODO: make sure it is not a floating point multiplication
    return f'''TxOut {{
        value: {int(vout["value"] * 100000000)}_u64, 
        pk_script: from_base16("{vout["scriptPubKey"]["hex"]}"),
    }}'''

def generate_tx(transaction):
    inputs = ",\n".join([generate_txin(vin) for vin in transaction['vin']])
    outputs = ",\n".join([generate_txout(vout) for vout in transaction['vout']])
    return f'''Transaction {{
        version: {transaction["version"]},
        is_segwit: false,
        inputs: array![{inputs}].span(),
        outputs: array![{outputs}].span(),
        lock_time: {transaction["locktime"]}
    }}'''

def generate_block(block_data):
    transactions = ",\n".join([generate_tx(tx) for tx in block_data['tx']])
    return f'''Block {{
        header: Header {{
            version: {block_data["version"]}_u32,
            time: {block_data["time"]}_u32,
            bits: 0, // TODO
            nonce: {block_data["nonce"]}_u32
        }},
        txs: array![{transactions}].span()
    }}'''

def generate_fixture(block_data):
    return f'''use raito::state::{{Block, Header, Transaction, OutPoint, TxIn, TxOut}};
use super::super::utils::from_base16;

pub fn block_{block_data["height"]}() -> Block {{
    // block hash: {block_data["hash"]}
    {generate_block(block_data)}
}}'''

def get_block(block_hash):
    height = get_block_height(block_hash)
    payload = {
        "jsonrpc": "1.0",
        "id": "curltest",
        "method": "getblock",
        "params": [block_hash, 2]
    }
    headers = {'content-type': 'text/plain;'}
    response = requests.post(BITCOIN_RPC, auth=tuple(USERPWD.split(':')), headers=headers, data=json.dumps(payload))
    block_data = response.json()['result']
    
    # Generate the fixture content
    fixture_content = generate_fixture(block_data)
    
    # Write the output to the file
    file_path = f'tests/blocks/block_{height}.cairo'
    with open(file_path, 'w') as f:
        f.write(fixture_content)

    # Replace LITERAL_AT_QUOTES with @"" in the generated file
    with open(file_path, 'r') as file:
        content = file.read()

    content = content.replace('LITERAL_AT_QUOTES', '@""')

    with open(file_path, 'w') as file:
        file.write(content)

    print(f"Block data written to {file_path}")

if __name__ == "__main__":
    block_hash = "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"  # Replace with actual block hash
    get_block(block_hash)
