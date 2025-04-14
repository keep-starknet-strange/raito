//! Block header validation.

use consensus::types::block::{Block, BlockHash, TransactionData};
use consensus::types::chain_state::ChainState;
use consensus::validation::difficulty::{adjust_difficulty, validate_bits};
use consensus::validation::timestamp::{
    compute_median_time_past, next_prev_timestamps, validate_timestamp,
};
use consensus::validation::work::{compute_total_work, validate_proof_of_work};
use utils::hash::Digest;

/// Validates block header given the [Block] and the initial [ChainState].
/// Assumes that the block data is a Merkle root rather than a list of transactions.
pub fn validate_block_header(state: ChainState, block: Block) -> Result<ChainState, ByteArray> {
    let txid_root = match block.data {
        TransactionData::MerkleRoot(root) => root,
        TransactionData::Transactions(_) => panic!("Expected Merkle root"),
    };

    let median_time_past = compute_median_time_past(state.prev_timestamps);
    validate_header(state, block, txid_root, median_time_past)
}

/// Validates block header given the [Block], initial [ChainState], and auxiliary data (to avoid
/// recomputing it):
/// - Transaction (Merkle) root
/// - MTP (median time past) of the previous block
///
/// Returns the new chain state.
pub fn validate_header(
    state: ChainState, block: Block, txid_root: Digest, prev_mtp: u32,
) -> Result<ChainState, ByteArray> {
    let block_height = state.block_height + 1;

    let prev_block_time = *state.prev_timestamps[state.prev_timestamps.len() - 1];
    let prev_timestamps = next_prev_timestamps(state.prev_timestamps, block.header.time);

    validate_timestamp(prev_mtp, block.header.time)?;

    let (current_target, epoch_start_time) = adjust_difficulty(
        state.current_target,
        state.epoch_start_time,
        block_height,
        prev_block_time,
        block.header.time,
    );
    let total_work = compute_total_work(state.total_work, current_target);
    let best_block_hash = block.header.hash(state.best_block_hash, txid_root);

    validate_proof_of_work(current_target, best_block_hash)?;
    validate_bits(current_target, block.header.bits)?;

    Ok(
        ChainState {
            block_height,
            total_work,
            best_block_hash,
            current_target,
            epoch_start_time,
            prev_timestamps,
        },
    )
}
