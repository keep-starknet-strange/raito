//! Chain state is a minimal subset of data required to unambiguosly
//! define a particular block chain starting at the genesis.
//!
//! Chain state alone is not enough to do full block validation, however
//! it is sufficient to validate block headers.

use raito::utils::hash::Hash;
use super::block::{BlockHash, Block};
use raito::validation::{
    difficulty::{validate_bits, adjust_difficulty}, coinbase::validate_coinbase,
    timestamp::{validate_timestamp, next_prev_timestamps},
    work::{validate_proof_of_work, compute_total_work},
    block::{next_block_height, fee_and_merkle_roots},
};

/// Represents the state of the blockchain.
#[derive(Drop, Copy)]
pub struct ChainState {
    /// Height of the current block.
    pub block_height: Option<u32>,
    /// Total work done.
    pub total_work: u256,
    /// Best block.
    pub best_block_hash: Hash,
    /// Current target.
    pub current_target: u256,
    /// Start of the current epoch.
    pub epoch_start_time: u32,
    /// List of 11 most recent block timestamps (from oldest to newest).
    /// It is expected that this list always has length = 11
    ///
    /// Note that timestamps *do not* influence the order of blocks, i.e.
    /// it's possible that one block could have an earlier timestamp
    /// than a block that came before it in the chain.
    pub prev_timestamps: Span<u32>,
}

/// Represents the initial state before genesis block.
/// https://github.com/bitcoin/bitcoin/blob/ee367170cb2acf82b6ff8e0ccdbc1cce09730662/src/kernel/chainparams.cpp#L99
///
/// TODO: use the chain state AFTER genesis block instead, that would make the block validation
/// simpler since we no longer need to handle special genesis case.
impl ChainStateDefault of Default<ChainState> {
    fn default() -> ChainState {
        ChainState {
            block_height: Default::default(),
            total_work: 0,
            best_block_hash: 0_u256.into(),
            current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
            epoch_start_time: 1231006505,
            prev_timestamps: [
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ].span(),
        }
    }
}

/// Full block validator (w/o bitcoin script checks and utxo inclusion verification for now).
#[generate_trait]
pub impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        let block_height = next_block_height(self.block_height);

        validate_timestamp(self.prev_timestamps, block.header.time)?;
        let prev_block_time = *self.prev_timestamps[self.prev_timestamps.len() - 1];
        let prev_timestamps = next_prev_timestamps(self.prev_timestamps, block.header.time);

        let (total_fees, txid_root, wtxid_root) = fee_and_merkle_roots(
            block.txs, block_height, block.header.time
        )?;
        validate_coinbase(block.txs[0], total_fees, block_height, wtxid_root)?;

        let (current_target, epoch_start_time) = adjust_difficulty(
            self.current_target,
            self.epoch_start_time,
            block_height,
            prev_block_time,
            block.header.time
        );
        let total_work = compute_total_work(self.total_work, current_target);
        let best_block_hash = block.header.hash(self.best_block_hash, txid_root);

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(current_target, block.header.bits)?;

        Result::Ok(
            ChainState {
                block_height: Option::Some(block_height),
                total_work,
                best_block_hash,
                current_target,
                epoch_start_time,
                prev_timestamps,
            }
        )
    }
}

/// Block header validator
#[generate_trait]
pub impl BlockHeaderValidatorImpl of BlockHeaderValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        let block_height = next_block_height(self.block_height);

        validate_timestamp(self.prev_timestamps, block.header.time)?;
        let prev_block_time = *self.prev_timestamps[self.prev_timestamps.len() - 1];
        let prev_timestamps = next_prev_timestamps(self.prev_timestamps, block.header.time);

        let txid_root = Default::default(); // TODO: create a function that just computes tx root

        let (current_target, epoch_start_time) = adjust_difficulty(
            self.current_target,
            self.epoch_start_time,
            block_height,
            prev_block_time,
            block.header.time
        );
        let total_work = compute_total_work(self.total_work, current_target);
        let best_block_hash = block.header.hash(self.best_block_hash, txid_root);

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(current_target, block.header.bits)?;

        Result::Ok(
            ChainState {
                block_height: Option::Some(block_height),
                total_work,
                best_block_hash,
                current_target,
                epoch_start_time,
                prev_timestamps,
            }
        )
    }
}
// TODO: implement Hash trait for ChainState


