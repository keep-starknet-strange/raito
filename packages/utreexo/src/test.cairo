use core::testing::get_available_gas;
use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::UtreexoBatchProof;
use crate::stump::accumulator::StumpUtreexoAccumulator;

#[derive(Drop, Serde, Debug)]
struct Args {
    state: UtreexoStumpState,
    proof: UtreexoBatchProof,
    leaves_to_del: Array<felt252>,
    leaves_to_add: Array<felt252>,
    expected_state: UtreexoStumpState,
    _unused: felt252,
}

fn main(args: Array<felt252>) -> Array<felt252> {
    let mut gas_before = get_available_gas();
    let mut arguments = args.span();

    let Args { mut state, proof, leaves_to_del, leaves_to_add, expected_state, _unused: _ } =
        Serde::deserialize(
        ref arguments
    )
        .expect('Failed to deserialize');

    match state.verify(@proof, leaves_to_del.span()) {
        Result::Ok(_) => {},
        Result::Err(err) => {
            println!("FAIL: gas_spent={} error='{:?}'", gas_before - get_available_gas(), err);
            panic!();
        }
    }

    match state.verify_and_delete(@proof, leaves_to_del.span()) {
        Result::Ok(new_state) => { state = new_state; },
        Result::Err(err) => {
            println!("FAIL: gas_spent={} error='{:?}'", gas_before - get_available_gas(), err);
            panic!();
        }
    }

    state = state.add(leaves_to_add.span());

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
    array![]
}
