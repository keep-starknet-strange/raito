use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::UtreexoBatchProof;
use crate::stump::accumulator::StumpUtreexoAccumulator;
use core::testing::get_available_gas;

#[derive(Drop, Serde, Debug)]
struct Args {
    state: UtreexoStumpState,
    proof: UtreexoBatchProof,
    leaves_to_del: Array<felt252>,
    leaves_to_add: Array<felt252>,
    expected_state: UtreexoStumpState,
}

fn main(mut arguments: Span<felt252>, _flags: felt252) {
    let mut gas_before = get_available_gas();

    let Args { mut state, proof, leaves_to_del, leaves_to_add: _, expected_state } =
        Serde::deserialize(
        ref arguments
    )
        .expect('Failed to deserialize');

    match state.verify_and_delete(@proof, leaves_to_del.span()) {
        Result::Ok(new_state) => { state = new_state; },
        Result::Err(err) => {
            println!("FAIL: gas_spent={} error='{:?}'", gas_before - get_available_gas(), err);
            panic!();
        }
    }

    if state != expected_state {
        println!(
            "FAIL: gas_spent={} error='expected state {:?}, actual {:?}'",
            gas_before - get_available_gas(),
            expected_state,
            state
        );
        panic!();
    }

    println!("OK: gas_spent={}", gas_before - get_available_gas());
}
