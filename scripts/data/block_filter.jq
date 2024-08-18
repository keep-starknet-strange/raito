def txin_coinbase:
    "TxIn {
        script: @from_hex(\"\(.coinbase)\"),
        sequence: \(.sequence),
        previous_output: OutPoint {
            txid: 0x0_u256.into(),
            vout: 0xffffffff_u32,
            txo_index: 0_u64,
            amount: 0_u64
        },
        witness: @from_hex(\"\(if has("txinwitness") then .txinwitness|join("") else "0" end)\")
    }"
;

def txin_regular:
    "TxIn {
        script: @from_hex(\"\(.scriptSig.hex)\"),
        sequence: \(.sequence),
        previous_output: OUTPOINT_KEY,
        witness: @from_hex(\"\(if has("txinwitness") then .txinwitness|join("") else "0" end)\")
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
        value: \((.value*100000000) | floor)_u64,
        pk_script: @from_hex(\"\(.scriptPubKey.hex)\")
    }"
;

def tx:
    "Transaction {
        version: \(.version),
        is_segwit: \((if (.version % 2 == 0) then "true" else "false" end)),
        inputs: array![\(.vin | map(txin) | join(",\n"))].span(),
        outputs: array![\(.vout | map(txout) | join(",\n"))].span(),
        lock_time: \(.locktime)
    }"
;

def block:
    "Block {
        header: Header {
            version: \(.version)_u32,
            time: \(.time)_u32,
            bits: \(.bits|explode|map(. - 48)|map(if . > 9 then . - 39 else . end)|reduce .[] as $n (0; . * 16 + $n))_u32,
            nonce: \(.nonce)_u32
        },
        txs: array![\(.tx | map(tx) | join(",\n"))].span()
    }"
;

def fixture:
    "use raito::state::{Block, Header, Transaction, TxIn, TxOut, OutPoint};
use raito::test_utils::from_hex;
use raito::utils::Hash;

// block_hash: \(.hash)
pub fn block_\(.height)() -> Block {
     \( . | block )
}"
;

. | fixture

