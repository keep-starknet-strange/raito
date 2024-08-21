import requests
import sys
import os
import json
import progressbar


BTC_RPC = os.getenv("BITCOIN_RPC")
USR = os.getenv("USERPWD")


def request_rpc(method, params):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params
    }
    headers = {'content-type': 'application/json'}
    data = requests.post(BTC_RPC, auth=tuple(USR.split(':')), headers=headers, data=json.dumps(payload)).json()
    if data['result'] is None:
        raise ConnectionError("Error recieving data")
    return data['result']


def header(block):
    return f'''Header {{
                version: {block["version"]}_u32,
                time: {block["time"]}_u32,
                bits: {int(block["bits"], 16)}_u32,
                nonce: {block["nonce"]}_u32,
        }}'''


def tx_output(tx):
    payload = ""
    for txoutput in tx:
        payload += f'''
                    TxOut {{
                        value: {int(txoutput["value"] * 100000000)}_64,
                        pk_script: @from_hex(\"{txoutput["scriptPubKey"]["hex"]}\"),
                    }},
                    '''
    return payload


def outpoint(tx_in):
    # full_tx = request_rpc("gettxout", [tx_in["txid"], tx_in["vout"]])
    full_tx = request_rpc("getrawtransaction", [tx_in['txid'], True])
    vout = full_tx['vout'][tx_in['vout']]
    return f'''
                                OutPoint {{
                                    txid: 0x{full_tx['txid']}_u256.into(),
                                    vout: {tx_in['vout']}_u32,
                                    txo_index: {vout['n']}_u64,
                                    amount: {int(vout['value'] * 100000000)}_u64,
                                }}'''


def tx_input_coinbase(tx_in):
    witness = "0"
    if 'txinwitness' in tx_in:
        witness = "".join(tx_in["txinwitness"])
    return f'''
                    TxIn {{
                        script: @from_hex(\"{tx_in["coinbase"]}\"),
                        sequence: {tx_in["sequence"]},
                        witness: @from_hex(\"{witness}\"),
                        previous_output: OutPoint {{
                            txid: 0_u256.into(),
                            vout: 0xffffffff_u32,
                            txo_index: 0,
                            amount: 0_u64,
                        }},
                    }}'''


def tx_input_regular(tx_in, full_tx):
    witness = "0"
    if 'txinwitness' in tx_in:
        witness = "".join(tx_input["txinwitness"])
    return f'''
                        TxIn {{
                            script: @from_hex(\"{tx_in["scriptSig"]['hex']}\"),
                            sequence: {tx_in["sequence"]},
                            witness: @from_hex(\"{witness}\"),
                            previous_output: {outpoint(tx_in)},
                        }},
                        '''


def tx_input(tx):
    payload = ""
    for txinput in tx['vin']:
        if 'coinbase' in txinput:
            payload += tx_input_coinbase(txinput)
        else:
            payload += tx_input_regular(txinput, tx)
    return payload


def check_segwit(tx):
    if not int(tx["version"]) % 2:
        return "true"
    return "false"


def txs_process(txsraw, ntx):
    payload = ''
    bar = progressbar.ProgressBar(max_value=ntx)
    bar.update(0)
    for i, tx in enumerate(txsraw):
        payload += f'''
            Transaction {{
                version: {tx["version"]},
                is_segwit: {check_segwit(tx)},
                lock_time: {tx["locktime"]},
                inputs: array![{tx_input(tx)}].span(),
                outputs: array![{tx_output(tx["vout"])}].span(),
                }},
                '''
        bar.update(i + 1)
    return payload


def main():
    try:
        if (len(sys.argv) != 2):
            raise TypeError("Error: bad arguments")
        block_hash = sys.argv[1]

        block = request_rpc("getblock", [block_hash, 2])
        txsraw = block["tx"]

        file_payload = f'''use raito::state::{{Block, Header, Transaction, TxIn, TxOut, OutPoint}};
use raito::test_utils::from_hex;
use raito::utils::Hash;

// block_hash: {block_hash}
pub fn block_{block["height"]}() -> Block {{
    Block {{
        header: {header(block)},
        txs: array![{txs_process(txsraw, block["nTx"])}].span(),
    }}
}}'''

        path = f'tests/blocks/block_{block["height"]}.cairo'
        file = open(path, "w")
        file.write(file_payload)
        file.close()
    except Exception as error:
        print(error)


main()
