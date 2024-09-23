use consensus::types::block::Block;
use consensus::types::state::State;
use consensus::types::chain_state::BlockValidator;
use consensus::types::utxo_set::UtxoSet;

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
/// Returns new state in case of success, otherwise raises an error.
fn main(mut arguments: Span<felt252>) -> State {
    let Args { mut state, blocks, } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    let mut utxo_set = UtxoSet {
        utreexo_state: state.utreexo_state,
        leaves_to_add: Default::default(),
        cache: Default::default(),
    };

    for block in blocks {
        state
            .chain_state = state
            .chain_state
            .validate_and_apply(block, ref utxo_set)
            .expect('Validation failed');
    };

    state.utreexo_state = utxo_set.utreexo_state;
    state
}
