use consensus::types::block::Block;
use consensus::types::chain_state::{BlockValidatorImpl, ChainState, ChainStateHashTrait};
use consensus::types::utxo_set::UtxoSet;

#[derive(Drop, Serde)]
struct Args {
    /// Current (initial) chain state.
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state.
    blocks: Array<Block>,
}

#[derive(Drop, Serde)]
struct Result {
    /// Hash of the initial chain state.
    initial_hash: felt252,
    /// Hash of the final chain state.
    final_hash: felt252,
}

#[executable]
fn main(args: Args) -> Result {
    core::internal::require_implicit::<core::circuit::RangeCheck96>();
    core::internal::require_implicit::<core::circuit::AddMod>();
    core::internal::require_implicit::<core::circuit::MulMod>();
    core::internal::require_implicit::<core::RangeCheck>();
    core::internal::require_implicit::<core::pedersen::Pedersen>();
    core::internal::require_implicit::<core::integer::Bitwise>();
    core::internal::require_implicit::<core::ec::EcOp>();
    core::internal::require_implicit::<core::poseidon::Poseidon>();

    let Args { mut chain_state, blocks } = args;
    let mut utxo_set: UtxoSet = Default::default();

    for block in blocks {
        match chain_state.validate_and_apply(block, ref utxo_set) {
            Ok(new_chain_state) => { chain_state = new_chain_state; },
            Err(err) => panic!("Error: '{}'", err),
        }
    }

    Result { initial_hash: chain_state.hash(), final_hash: chain_state.hash() }
}
