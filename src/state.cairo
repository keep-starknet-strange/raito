//! Bitcoin data type objects extended with validation context.
//!
//! The data is expected to be prepared in advance and passed as program arguments.
//! The extended set of fields allows to recursively validate entities in a stateless manner,
//! and to avoid repetitive computations.

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
    // Utreexo roots (for checking [TxIn] inclusion proofs)
    pub utreexo_roots: Span<felt252>
}

/// Represents a block in the blockchain.
#[derive(Drop, Copy)]
pub struct Block {
    /// block header
    pub header: Header,
    /// Transactions
    pub txs: Span<Transaction>,
}

/// Block header
/// https://learnmeabitcoin.com/technical/block/
#[derive(Drop, Copy)]
pub struct Header {
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

/// Extended transaction.
/// https://learnmeabitcoin.com/technical/transaction/
///
/// Contains additional "meta" fields required for validation.
#[derive(Drop, Copy)]
pub struct Transaction {
    /// The version of the transaction.
    pub version: i32,
    /// Flag which indicates the presence of witness data.
    /// Segwit marker and flag do not contribute to TXID (transaction hash),
    /// but do contribute to wTXID.
    pub is_segwit: bool,
    /// The inputs of the transaction.
    pub inputs: Span<TxIn>,
    /// The outputs of the transaction.
    pub outputs: Span<TxOut>,
    /// The list of witnesses, one for each input.
    /// Each witness is a list of elements that are to be pushed onto stack.
    /// Witnesses do not contribute to TXID but do contribute to wTXID.
    pub witnesses: Span<Span<ByteArray>>,
    /// The lock time of the transaction.
    pub lock_time: u32,
    /// Transaction fee which is diff between total input and output amounts (meta field)
    pub fee: i64,
}

/// Output of a transaction.
/// https://learnmeabitcoin.com/technical/transaction/output/
#[derive(Drop, Copy)]
pub struct TxOut {
    /// The value of the output.
    pub value: i64,
    /// The public key script of the output.
    pub pk_script: @ByteArray,
}

/// Extended input of a transaction.
/// https://learnmeabitcoin.com/technical/transaction/input/
///
/// Contains additional "meta" fields required for validation.
#[derive(Drop, Copy)]
pub struct TxIn {
    /// The previous TXID this input spends.
    pub txid: u256,
    /// The previous transaction output index this input spends.
    pub vout: u32,
    /// The signature script which satisfies the conditions placed in the txo pubkey script
    /// or coinbase script that contains block height (since 227,836) and miner nonce (optional).
    pub script: @ByteArray,
    /// The sequence number of the input ().
    pub sequence: u32,
    /// The previous transaction output this input spends (meta field)
    pub txo: @TxOut,
    /// Utreexo inclusion proof of the spent output (meta field)
    pub txo_proof: Span<felt252>,
}
