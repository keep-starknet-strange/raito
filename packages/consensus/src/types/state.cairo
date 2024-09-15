//! State is a top level struct containing the chain state and the utxo set

use crate::types::utreexo::{UtreexoState, UtreexoStateDefault};
use crate::types::utxo_set::UtxoSet;
use crate::validation::{
    difficulty::{validate_bits, adjust_difficulty}, coinbase::validate_coinbase,
    timestamp::{validate_timestamp, next_prev_timestamps},
    work::{validate_proof_of_work, compute_total_work}, block::{compute_and_validate_tx_data},
};
use super::block::{BlockHash, Block, TransactionData};
use super::chain_state::ChainState;

#[derive(Default, Drop, Copy, Debug, Serde)]
pub struct State {
    pub chain_state: ChainState,
    pub utreexo_state: UtreexoState
}

/// Full block validator (w/o bitcoin script checks and utxo inclusion verification for now).
#[generate_trait]
pub impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: State, block: Block) -> Result<State, ByteArray> {
        let mut utxo_set = UtxoSet {
            utreexo_state: self.utreexo_state, cache: Default::default(),
        };

        let block_height = self.chain_state.block_height + 1;

        validate_timestamp(self.chain_state.prev_timestamps, block.header.time)?;
        let prev_block_time = *self
            .chain_state
            .prev_timestamps[self
            .chain_state
            .prev_timestamps
            .len()
            - 1];
        let prev_timestamps = next_prev_timestamps(
            self.chain_state.prev_timestamps, block.header.time
        );

        let txid_root = match block.data {
            TransactionData::MerkleRoot(root) => root,
            TransactionData::Transactions(txs) => {
                let (total_fees, txid_root, wtxid_root) = compute_and_validate_tx_data(
                    txs, block_height, block.header.time, ref utxo_set
                )?;
                validate_coinbase(txs[0], total_fees, block_height, wtxid_root)?;
                txid_root
            }
        };

        let (current_target, epoch_start_time) = adjust_difficulty(
            self.chain_state.current_target,
            self.chain_state.epoch_start_time,
            self.chain_state.block_height,
            prev_block_time,
            block.header.time
        );
        let total_work = compute_total_work(self.chain_state.total_work, current_target);
        let best_block_hash = block.header.hash(self.chain_state.best_block_hash, txid_root);

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(current_target, block.header.bits)?;

        Result::Ok(
            State {
                chain_state: ChainState {
                    block_height,
                    total_work,
                    best_block_hash,
                    current_target,
                    epoch_start_time,
                    prev_timestamps,
                },
                utreexo_state: self.utreexo_state
            }
        )
    }
}
