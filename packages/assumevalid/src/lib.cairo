use consensus::types::block::Block;
use consensus::types::chain_state::{ChainState, ChainStateHashTrait};
use consensus::validation::header::validate_block_header;
use stwo_cairo_air::{CairoProof, VerificationOutput, get_verification_output, verify_cairo};
use utils::hash::Digest;

#[derive(Drop, Serde)]
struct Args {
    /// Current (initial) chain state.
    chain_state: ChainState,
    /// Batch of blocks that have to be applied to the current chain state.
    blocks: Array<Block>,
}

#[derive(Drop, Serde)]
struct Result {
    /// Initial chain state hash.
    initial_hash: Digest,
    /// Final chain state hash.
    final_hash: Digest,
}

#[executable]
fn agg(proof: CairoProof) -> VerificationOutput {
    let verification_output = get_verification_output(proof: @proof);

    if let Err(err) = verify_cairo(proof) {
        panic!("Verification failed: {:?}", err);
    }

    verification_output
}

#[executable]
fn main(args: Args) -> Result {
    let Args { chain_state, blocks } = args;
    let mut current_chain_state = chain_state;

    for block in blocks {
        match validate_block_header(current_chain_state, block) {
            Ok(new_chain_state) => { current_chain_state = new_chain_state; },
            Err(err) => panic!("Error: '{}'", err),
        }
    }

    Result { initial_hash: chain_state.hash(), final_hash: current_chain_state.hash() }
}
