use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, BlockValidator};
use consensus::types::utxo_set::UtxoSet;

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
/// Receives current state (chain state + utreexo state) and pending blocks,
/// then validates and applies them one by one.
/// Returns new state in case of success, otherwise raises an error.
fn main(mut arguments: Span<felt252>) -> ChainState {
    let Args { mut chain_state, blocks, } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();

    // Validate and apply block, accumulating UTXO updates in utxo_set
    for block in blocks {
        chain_state = chain_state
            .validate_and_apply(block, ref utxo_set, false)
            .expect('Block validation failed');
    };

    chain_state
}
