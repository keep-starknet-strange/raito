use core::serde::Serde;
use consensus::types::chain_state::BlockValidatorImpl;
use consensus::types::utxo_set::UtxoSet;
use client::test::Args;
use super::block_24834;

fn verify(args: Span<felt252>) {

    let mut args = args;

    let args: Args = Serde::deserialize(ref args).expect('failed to deserialize');

    let mut utxo_set: UtxoSet = Default::default();

    for block in args.blocks {
        args
            .chain_state
            .validate_and_apply(block, ref utxo_set, args.execute_script)
            .expect('Failed to apply block');
    };
}

#[test]
fn test_24839_full() {
    verify(block_24834::full.span());
}


