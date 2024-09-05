use crate::types::block::Block;
use crate::types::chain_state::{ChainState, BlockValidator};
use core::testing::get_available_gas;

/// Integration testing program entrypoint.
///
/// Receives current chain state, pending blocks, and expected result.
/// Validates and applies blocks one by one, exits on first failure.
fn test(
    mut chain_state: ChainState, mut blocks: Array<Block>, mut expected_chain_state: ChainState
) {
    let mut gas_before = get_available_gas();
    while let Option::Some(block) = blocks.pop_front() {
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
