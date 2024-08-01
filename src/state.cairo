

// https://developer.bitcoin.org/reference/block_chain.html#block-headers
#[derive(Drop, Clone)]
struct Header {
    pub version: u32,
    pub prev_block_hash: u256,
    pub merkle_root_hash: u256,
    pub time: u32,
    pub bits: u32,
    pub nonce: u32
}

// https://developer.bitcoin.org/reference/transactions.html#txin-a-transaction-input-non-coinbase
#[derive(Drop, Clone)]
pub struct TxIn {
    txid: u256,
    index: u32,
    script: ByteArray,
    sequence: u32,
}

// https://developer.bitcoin.org/reference/transactions.html#txout-a-transaction-output
#[derive(Drop, Clone)]
pub struct TxOut {
    value: i64, // TODO: why signed?
    pk_script: ByteArray
}

// https://developer.bitcoin.org/reference/transactions.html#raw-transaction-format
#[derive(Drop, Clone)]
pub struct Transaction {
    pub version: i32,
    pub inputs: Span<TxIn>,
    pub outputs: Span<TxOut>,
    pub lock_time: u32,
}

#[derive(Drop, Clone)]
pub struct Block {
    pub header: Header,
    // TODO: how to handle coinbase transactions?
    pub txs: Span<Transaction>
}

#[derive(Drop, Clone)]
pub struct ChainState {
    pub block_height: u32, // not u256?
    pub total_work: u256,
    pub best_block_hash: u256,
    pub current_target: u32,
    pub epoch_start_time: u32,
    pub prev_timestamps: Span<u32>,
    // TODO: utreexo_roots?
}

trait BlockValidator {
    fn validate_and_apply(block: Block) -> Result<ChainState, ByteArray>;
}