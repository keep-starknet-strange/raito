pub mod difficulty;
pub mod coinbase;
pub mod timestamp;
pub mod transaction;
pub mod work;
pub mod block;

use super::state::{ChainState, HeaderTrait, Block};
use difficulty::{validate_bits, adjust_difficulty};
use coinbase::validate_coinbase;
use timestamp::{validate_timestamp, next_prev_timestamps};
use work::{validate_proof_of_work, compute_total_work};
use transaction::{validate_transaction};
use block::{next_block_height, fee_and_merkle_roots};

#[generate_trait]
pub impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        let block_height = next_block_height(self.block_height);

        validate_timestamp(self.prev_timestamps, block.header.time)?;
        let prev_timestamps = next_prev_timestamps(self.prev_timestamps, block.header.time);

        let (total_fees, txid_root, wtxid_root) = fee_and_merkle_roots(
            block.txs, block_height, block.header.time
        )?;
        validate_coinbase(block.txs[0], total_fees, block_height, wtxid_root)?;

        let (current_target, epoch_start_time) = adjust_difficulty(
            self.current_target,
            self.epoch_start_time,
            self.block_height.unwrap_or(0),
            *self.prev_timestamps[self.prev_timestamps.len() - 1],
            block.header.time
        );
        let total_work = compute_total_work(self.total_work, current_target);
        let best_block_hash = block.header.hash(self.best_block_hash, txid_root);

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(current_target, block.header.bits)?;

        let utreexo_state = Default::default();

        Result::Ok(
            ChainState {
                block_height: Option::Some(block_height),
                total_work,
                best_block_hash,
                current_target,
                epoch_start_time,
                prev_timestamps,
                utreexo_state
            }
        )
    }
}
