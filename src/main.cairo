use crate::types::block::Block;
use crate::types::chain_state::{ChainState, BlockValidator};

/// Raito program entrypoint.
///
/// Receives current chain state and pending blocks,
/// then validates and applies them one by one.
/// Returns new chain state in case of succes, otherwise raises an error.
fn main(mut chain_state: ChainState, mut blocks: Array<Block>) -> ChainState {
    while let Option::Some(block) = blocks.pop_front() {
        chain_state = chain_state.validate_and_apply(block).expect('Validation failed');
    };
    chain_state
}
