use crate::types::block::Block;
use crate::types::chain_state::{ChainState, BlockValidator};
use core::testing::get_available_gas;

/// Integration testing program arguments.
#[derive(Serde)]
struct Args {
    /// Current (initial) chain state
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state
    blocks: Array<Block>,
    /// Expected chain state (that we want to compare the result with)
    expected_chain_state: ChainState,
}

/// Integration testing program entrypoint.
///
/// Receives arguments in a serialized format (Cairo serde).
/// Panics in case of a validation error or chain state mismatch.
/// Prints result to the stdout.
fn test(mut arguments: Span<felt252>) {
    let Args { mut chain_state, blocks, expected_chain_state } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    let mut gas_before = get_available_gas();

    for block in blocks {
        let height = chain_state.block_height + 1;
        match chain_state.validate_and_apply(block) {
            Result::Ok(new_chain_state) => {
                chain_state = new_chain_state;
                let gas_after = get_available_gas();
                println!("OK: block={} gas_spent={}", height, gas_before - gas_after);
                gas_before = gas_after;
            },
            Result::Err(err) => {
                let gas_after = get_available_gas();
                println!(
                    "FAIL: block={} gas_spent={} error='{}'", height, gas_before - gas_after, err
                );
                panic!();
            }
        }
    };

    if chain_state != expected_chain_state {
        println!(
            "FAIL: block={} error='expected state {:?}, actual {:?}'",
            chain_state.block_height,
            expected_chain_state,
            chain_state
        );
        panic!();
    }
}
