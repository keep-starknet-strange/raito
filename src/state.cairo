/// Represents the state of the blockchain.
#[derive(Drop, Copy)]
pub struct ChainState {
    /// Height of the current block.
    pub block_height: u32, // not u256?
    
    /// Total work done.
    pub total_work: u256,
    
    /// Best block.
    pub best_block_hash: u256,

    /// Current block.
    pub current_target: u32,
    
    /// Start of the current epoch.
    pub epoch_start_time: u32,
    
    /// Previous timestamps.
    pub prev_timestamps: Span<u32>,
    
    // TODO: utreexo_roots?
}

/// Represents a block in the blockchain.
///
#[derive(Drop, Copy)]
pub struct Block {
    /// block header
    pub header: Header,
    // TODO: how to handle coinbase transactions?

    /// Transactions
    pub txs: Span<Transaction>,
}

/// Block header
/// https://developer.bitcoin.org/reference/block_chain.html#block-headers
#[derive(Drop, Copy)]
struct Header {
    /// The version of the block.
    pub version: u32,
    
    /// The hash of the previous block in the blockchain.
    pub prev_block_hash: u256,
    
    /// The Merkle root hash of the transactions in the block.
    pub merkle_root_hash: u256,
    
    /// The timestamp of the block.
    pub time: u32,
    
    /// The difficulty target for mining the block.
    pub bits: u32,
    
    /// The nonce used in mining the block.
    pub nonce: u32,
}

/// Transaction
/// https://developer.bitcoin.org/reference/transactions.html#raw-transaction-format
#[derive(Drop, Copy)]
pub struct Transaction {
    /// The version of the transaction.
    pub version: i32,

    /// The inputs of the transaction.
    pub inputs: Span<TxIn>,
    
    /// The outputs of the transaction.
    pub outputs: Span<TxOut>,
    
    /// The lock time of the transaction.
    pub lock_time: u32,
}

/// Output of a transaction.
/// https://developer.bitcoin.org/reference/transactions.html#txout-a-transaction-output
#[derive(Drop, Copy)]
pub struct TxOut {
    /// The value of the output.
    value: i64,

    /// The public key script of the output.
    pk_script: @ByteArray,
}

/// Input of a transaction.
/// https://developer.bitcoin.org/reference/transactions.html#txin-a-transaction-input-non-coinbase
#[derive(Drop, Copy)]
pub struct TxIn {
    /// The transaction ID of the input.
    txid: u256,

    /// The index of the input.
    index: u32,
    
    /// The script of the input.
    script: @ByteArray,
    
    /// The sequence of the input.
    sequence: u32,
}

