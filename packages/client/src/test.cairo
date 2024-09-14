use consensus::types::block::Block;
use consensus::types::state::{State, BlockValidatorImpl};
use core::testing::get_available_gas;

/// Integration testing program arguments.
#[derive(Serde)]
struct Args {
    /// Current (initial) chain state
    state: State,
    /// Batch of blocks that have to be applied to the current chain state
    blocks: Array<Block>,
    /// Expected chain state (that we want to compare the result with)
    expected_state: State,
}

/// Integration testing program entrypoint.
///
/// Receives arguments in a serialized format (Cairo serde).
/// Panics in case of a validation error or chain state mismatch.
/// Prints result to the stdout.
fn test(mut arguments: Span<felt252>) {
    let Args { mut state, blocks, expected_state } = Serde::deserialize(ref arguments)
        .expect('Failed to deserialize');

    let mut gas_before = get_available_gas();

    for block in blocks {
        let height = state.chain_state.block_height + 1;
        match state.validate_and_apply(block) {
            Result::Ok(new_state) => {
                state = new_state;
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

    if state.chain_state != expected_state.chain_state {
        println!(
            "FAIL: block={} error='expected state {:?}, actual {:?}'",
            state.chain_state.block_height,
            expected_state.chain_state,
            state.chain_state
        );
        panic!();
    }
}
