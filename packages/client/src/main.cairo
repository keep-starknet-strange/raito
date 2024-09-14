use consensus::types::block::Block;
use consensus::types::state::{State, BlockValidator};

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
/// Receives current chain state and pending blocks,
/// then validates and applies them one by one.
/// Returns new chain state in case of succes, otherwise raises an error.
fn main(mut arguments: Span<felt252>) -> State {
    let Args { mut state, blocks, } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    for block in blocks {
        state = state.validate_and_apply(block).expect('Validation failed');
    };
    
    state
}
