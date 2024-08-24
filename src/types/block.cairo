//! Bitcoin block and its components.
//!
//! The data is expected to be prepared in advance and passed as program arguments.

use raito::utils::hash::Hash;
use super::transaction::Transaction;

/// Represents a block in the blockchain.
#[derive(Drop, Copy)]
pub struct Block {
    /// Block header.
    pub header: Header,
    /// Transactions.
    pub txs: Span<Transaction>,
}

/// Represents a block header.
/// https://learnmeabitcoin.com/technical/block/
///
/// NOTE that some of the fields are missing, that's intended.
/// The point of the client is to calculate next chain state from the previous
/// chain state and block data in a provable way.
/// The proof can be later used to verify that the chain state is valid.
/// In order to do the calculation we just need data about the block that is strictly necessary,
/// but not the data we can calculate like merkle root or data that we already have
/// like previous_block_hash (in the previous chain state).
#[derive(Drop, Copy)]
pub struct Header {
    /// The version of the block.
    pub version: u32,
    /// The timestamp of the block.
    pub time: u32,
    /// The difficulty target for mining the block.
    /// Not strictly necessary since it can be computed from target,
    /// but it is cheaper to validate than compute.
    pub bits: u32,
    /// The nonce used in mining the block.
    pub nonce: u32,
}

#[generate_trait]
pub impl BlockHashImpl of BlockHash {
    /// Compute hash of the block header given the missing fields.
    fn hash(self: @Header, _prev_block_hash: Hash, _merkle_root: Hash) -> Hash {
        Default::default()
    }
}
