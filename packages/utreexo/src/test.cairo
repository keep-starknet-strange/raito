use crate::stump::accumulator::StumpUtreexoAccumulator;
use crate::stump::proof::UtreexoBatchProof;
use crate::stump::state::UtreexoStumpState;

#[derive(Drop, Serde, Debug)]
struct Args {
    state: UtreexoStumpState,
    proof: UtreexoBatchProof,
    leaves_to_del: Array<felt252>,
    leaves_to_add: Array<felt252>,
    expected_state: UtreexoStumpState,
}

#[executable]
fn main(args: Args) {
    let Args { mut state, proof, leaves_to_del, leaves_to_add, expected_state } = args;

    match state.verify(@proof, leaves_to_del.span()) {
        Result::Ok(_) => {},
        Result::Err(err) => {
            println!("FAIL: error='{:?}'", err);
            panic!();
        },
    }

    match state.verify_and_delete(@proof, leaves_to_del.span()) {
        Result::Ok(new_state) => { state = new_state; },
        Result::Err(err) => {
            println!("FAIL: error='{:?}'", err);
            panic!();
        },
    }

    state = state.add(leaves_to_add.span());

    if state != expected_state {
        println!("FAIL: error='expected state {:?}, actual {:?}'", expected_state, state);
        panic!();
    }

    println!("OK");
}
