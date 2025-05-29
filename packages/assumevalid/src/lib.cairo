use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, ChainStateHashTrait};
use consensus::validation::header::validate_block_header;

#[derive(Drop, Serde)]
struct Args {
    /// Current (initial) chain state.
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state.
    blocks: Array<Block>,
}

#[derive(Drop, Serde)]
struct Result {
    /// Hash of the initial chain state.
    initial_hash: felt252,
    /// Hash of the final chain state.
    final_hash: felt252,
}

#[executable]
fn main(args: Args) -> Result {
    let Args { mut chain_state, blocks } = args;

    for block in blocks {
        match validate_block_header(chain_state, block) {
            Ok(new_chain_state) => { chain_state = new_chain_state; },
            Err(err) => panic!("Error: '{}'", err),
        }
    }

    Result { initial_hash: chain_state.hash(), final_hash: chain_state.hash() }
}
