def txin_coinbase:
    "TxIn {
        script: from_base16(\"\(.coinbase)\"),
        sequence: \(.sequence),
        previous_output: OutPoint {
            txid: 0_u256,
            vout: 0xffffffff_u32,
            txo_index: 0,
        },
    }"
;

def txin_regular:
    "TxIn {
        script: from_base16(\"\(.scriptSig.hex)\"),
        sequence: \(.sequence),
        previous_output: OutPoint {
            txid: 0x\(.txid),
            vout: \(.vout),
            txo_index: 0,
        },
    }"
;

def txin:
    if .coinbase then
        txin_coinbase
    else
        txin_regular
    end
;

def txout:
    "TxOut {
        value: \(.value*100000000)_u64,
        pk_script: from_base16(\"\(.scriptPubKey.hex)\"),
    }"
;

def tx:
    "Transaction {
        version: \(.version),
        is_segwit: false,
        inputs: array![\(.vin | map(txin) | join(",\n"))].span(),
        outputs: array![\(.vout | map(txout) | join(",\n"))].span(),
        lock_time: \(.locktime)
    }"
;


def block:
    "Block {
        header : Header {	
            version: \(.version)_u32,
            time: \(.time)_u32,
            nonce: \(.nonce)_u32
        },
		txs: array![\(.tx | map(tx) | join(",\n"))].span()
   };"
;

def fixture:
"use super::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};

pub fn block_\(.height)() -> Block {
    // block hash: \(.hash)
     \( . | block )
}"
;

.result | fixture

