use consensus::types::block::Block;
use consensus::types::state::State;
use consensus::types::chain_state::BlockValidator;
use consensus::types::utreexo::UtreexoStateTrait;
use consensus::types::utxo_set::{UtxoSet, UtxoSetTrait};

/// Raito program arguments.
#[derive(Serde)]
struct Args {
    /// Current (initial) state
    state: State,
    /// Batch of blocks that have to be applied to the current chain state
    blocks: Array<Block>,
}

/// Raito program entrypoint.
///
/// Receives current state (chain state + utreexo state) and pending blocks,
/// then validates and applies them one by one.
/// Returns new state in case of succes, otherwise raises an error.
fn main(mut arguments: Span<felt252>) -> State {
    let Args { mut state, blocks, } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();

    // Validate and apply block, accumulating UTXO updates in utxo_set
    for block in blocks {
        state
            .chain_state = state
            .chain_state
            .validate_and_apply(block, ref utxo_set)
            .expect('Block validation failed');
    };

    // Validate and apply UTXO updates
    state.utreexo_state.validate_and_apply(ref utxo_set).expect('Utreexo validation failed');

    // Ensure all UTXOs have been processed
    utxo_set.finalize().expect('UtxoSet finalization failed');

    state
}
