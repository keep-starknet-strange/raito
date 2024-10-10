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
fn test(mut arguments: Span<felt252>, execute_script: bool) {
    let Args { mut chain_state, blocks, expected_chain_state, utreexo_args } = Serde::deserialize(
        ref arguments
    )
        .expect('Failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();
    let mut gas_before = get_available_gas();

    for block in blocks {
        let height = chain_state.block_height + 1;
        match chain_state.validate_and_apply(block, ref utxo_set, execute_script) {
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
            "FAIL: block={} error='expected chain state {:?}, actual {:?}'",
            chain_state.block_height,
            expected_chain_state,
            chain_state
        );
        panic!();
    }

    if let Result::Err(err) = utxo_set.finalize() {
        println!("FAIL: error='{}'", err);
        panic!();
    }

    if let Option::Some(UtreexoArgs { mut state, proofs, expected_state }) = utreexo_args {
        match state
            .validate_and_apply(
                utxo_set.leaves_to_add.span(), utxo_set.leaves_to_delete.span(), proofs.span(),
            ) {
            Result::Ok(new_state) => {
                state = new_state;
                let gas_after = get_available_gas();
                println!("OK: gas_spent={}", gas_before - gas_after);
            },
            Result::Err(err) => {
                let gas_after = get_available_gas();
                println!("FAIL: gas_spent={} error='{:?}'", gas_before - gas_after, err);
                panic!();
            }
        }

        if state != expected_state {
            println!(
                "FAIL: error='expected utreexo state {:?}, actual {:?}'", expected_state, state
            );
            panic!();
        }
    }
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
