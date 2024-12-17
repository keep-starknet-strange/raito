use core::serde::Serde;
use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, BlockValidatorImpl};
use consensus::types::utxo_set::{UtxoSet, UtxoSetTrait};
use utreexo::stump::accumulator::StumpUtreexoAccumulator;
use utreexo::stump::state::UtreexoStumpState;
use utreexo::stump::proof::UtreexoBatchProof;

/// Integration testing program arguments.
#[derive(Drop)]
struct Args {
    /// Current (initial) chain state.
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state.
    blocks: Array<Block>,
    /// Expected chain state (that we want to compare the result with).
    expected_chain_state: ChainState,
    /// Optional Utreexo arguments.
    utreexo_args: Option<UtreexoArgs>,
    /// If this flag is set, locking scripts will be executed
    execute_script: bool,
}

/// Utreexo arguments necessary for constraining the UTXO set.
#[derive(Drop, Serde)]
struct UtreexoArgs {
    /// Current (initial) accumulator state.
    state: UtreexoStumpState,
    /// Batch inclusion proof for TXOs spent during the current block.
    /// Note that it doesn't support flow with multiple blocks applied
    /// in a single program run.
    proof: UtreexoBatchProof,
    /// Expected accumulator state at the end of the execution.
    expected_state: UtreexoStumpState,
}

/// Integration testing program entrypoint.
///
/// Receives arguments in a serialized format (Cairo serde).
/// Panics in case of a validation error or chain state mismatch.
/// Prints result to the stdout.
fn main(arguments: Array<felt252>) -> Array<felt252> {
    println!("Running integration test... ");
    let mut args = arguments.span();

    let Args {
        mut chain_state, blocks, expected_chain_state, utreexo_args, execute_script,
    } = Serde::deserialize(ref args).expect('Failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();

    for block in blocks {
        match chain_state.validate_and_apply(block, ref utxo_set, execute_script) {
            Result::Ok(new_chain_state) => { chain_state = new_chain_state; },
            Result::Err(err) => {
                println!("FAIL: error='{}'", err);
                panic!();
            },
        }
    };

    if chain_state != expected_chain_state {
        println!(
            "FAIL: error='expected chain state {:?}, actual {:?}'",
            expected_chain_state,
            chain_state,
        );
        panic!();
    }

    if let Result::Err(err) = utxo_set.finalize() {
        println!("FAIL: error='{}'", err);
        panic!();
    }

    if let Option::Some(UtreexoArgs { mut state, proof, expected_state }) = utreexo_args {
        match state.verify_and_delete(@proof, utxo_set.leaves_to_delete.span()) {
            Result::Ok(new_state) => { state = new_state; },
            Result::Err(err) => {
                println!("FAIL: error='{:?}'", err);
                panic!();
            },
        }

        state = state.add(utxo_set.leaves_to_add.span());

        if state != expected_state {
            println!(
                "FAIL: error='expected utreexo state {:?}, actual {:?}'", expected_state, state,
            );
            panic!();
        }
    }

    println!("OK");
    array![]
}

/// Workaround for handling missing `utreexo_args` field.
/// Rough analogue of `#[serde(default)]`.
impl ArgsSerde of Serde<Args> {
    fn serialize(self: @Args, ref output: Array<felt252>) {
        panic!("not implemented");
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Args> {
        let chain_state: ChainState = Serde::deserialize(ref serialized).expect('chain_state');
        let blocks: Array<Block> = Serde::deserialize(ref serialized).expect('blocks');
        let expected_chain_state: ChainState = Serde::deserialize(ref serialized)
            .expect('expected_chain_state');
        let utreexo_args: Option<UtreexoArgs> = if serialized.len() > 1 {
            Option::Some(Serde::deserialize(ref serialized).expect('utreexo_args'))
        } else {
            Option::None
        };
        let execute_script: bool = Serde::deserialize(ref serialized).expect('execute_script');
        Option::Some(
            Args { chain_state, blocks, expected_chain_state, utreexo_args, execute_script },
        )
    }
}
