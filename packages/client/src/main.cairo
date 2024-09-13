use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, BlockValidator};

/// Raito program arguments.
#[derive(Serde)]
struct Args {
    /// Current (initial) chain state
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state
    blocks: Array<Block>,
}

/// Raito program entrypoint.
///
/// Receives current chain state and pending blocks,
/// then validates and applies them one by one.
/// Returns new chain state in case of succes, otherwise raises an error.
fn main(mut arguments: Span<felt252>) -> ChainState {
    let Args { mut chain_state, blocks, } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    for block in blocks {
        chain_state = chain_state.validate_and_apply(block).expect('Validation failed');
    };
    chain_state
}
