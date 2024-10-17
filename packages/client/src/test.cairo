use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, BlockValidatorImpl};
use consensus::types::utxo_set::{UtxoSet, UtxoSetTrait};
use utreexo::vanilla::state::{UtreexoState, UtreexoStateTrait};
use utreexo::vanilla::proof::UtreexoProof;
use core::testing::get_available_gas;
use core::serde::Serde;

/// Integration testing program arguments.
#[derive(Drop)]
struct Args {
    /// Current (initial) chain state
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state
    blocks: Array<Block>,
    /// Expected chain state (that we want to compare the result with)
    expected_chain_state: ChainState,
    /// Optional Utreexo arguments
    utreexo_args: Option<UtreexoArgs>,
}

/// Utreexo arguments necessary for constraining the UTXO set
#[derive(Drop, Serde)]
struct UtreexoArgs {
    /// Current (initial) accumulator state
    state: UtreexoState,
    /// Inclusion proofs for TXOs spent during program run
    proofs: Array<UtreexoProof>,
    /// Expected accumulator state at the end of the execution
    expected_state: UtreexoState,
}

/// Integration testing program entrypoint.
///
/// Receives arguments in a serialized format (Cairo serde).
/// Panics in case of a validation error or chain state mismatch.
/// Prints result to the stdout.
pub(crate) fn main(mut arguments: Span<felt252>, execute_script: bool) {
    println!("Running integration test... ");
    let mut gas_before = get_available_gas();

    let Args { mut chain_state, blocks, expected_chain_state, utreexo_args } = Serde::deserialize(
        ref arguments
    )
        .expect('Failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();

    for block in blocks {
        match chain_state.validate_and_apply(block, ref utxo_set, execute_script) {
            Result::Ok(new_chain_state) => { chain_state = new_chain_state; },
            Result::Err(err) => {
                println!("FAIL: gas_spent={} error='{}'", gas_before - get_available_gas(), err);
                panic!();
            }
        }
    };

    if chain_state != expected_chain_state {
        println!(
            "FAIL: gas_spent={} error='expected chain state {:?}, actual {:?}'",
            gas_before - get_available_gas(),
            expected_chain_state,
            chain_state
        );
        panic!();
    }

    if let Result::Err(err) = utxo_set.finalize() {
        println!("FAIL: gas_spent={} error='{}'", gas_before - get_available_gas(), err);
        panic!();
    }

    if let Option::Some(UtreexoArgs { mut state, proofs, expected_state }) = utreexo_args {
        match state
            .validate_and_apply(
                utxo_set.leaves_to_add.span(), utxo_set.leaves_to_delete.span(), proofs.span(),
            ) {
            Result::Ok(new_state) => { state = new_state; },
            Result::Err(err) => {
                println!("FAIL: gas_spent={} error='{:?}'", gas_before - get_available_gas(), err);
                panic!();
            }
        }

        if state != expected_state {
            println!(
                "FAIL: gas_spent={} error='expected utreexo state {:?}, actual {:?}'",
                gas_before - get_available_gas(),
                expected_state,
                state
            );
            panic!();
        }
    }

    println!("OK: gas_spent={}", gas_before - get_available_gas());
}

/// Workaround for handling missing `utreexo_args` field.
/// Rough analogue of `#[serde(default)]`
impl ArgsSerde of Serde<Args> {
    fn serialize(self: @Args, ref output: Array<felt252>) {
        panic!("not implemented");
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Args> {
        let chain_state: ChainState = Serde::deserialize(ref serialized).expect('chain_state');
        let blocks: Array<Block> = Serde::deserialize(ref serialized).expect('blocks');
        let expected_chain_state: ChainState = Serde::deserialize(ref serialized)
            .expect('expected_chain_state');
        let utreexo_args: Option<UtreexoArgs> = if serialized.len() > 0 {
            Option::Some(Serde::deserialize(ref serialized).expect('utreexo_args'))
        } else {
            Option::None
        };
        Option::Some(Args { chain_state, blocks, expected_chain_state, utreexo_args, })
    }
}
