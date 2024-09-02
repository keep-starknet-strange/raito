use raito::types::block::Block;
use raito::types::chain_state::{ChainState, BlockValidator};

/// Raito light client program entrypoint.
///
/// Receives current chain state and a pending block header.
/// Returns (true, new chain state) if validation was successfull.
/// Returns (false, default) otherwise.
fn main(chain_state: ChainState, block: Block) -> (bool, ChainState) {
    match chain_state.validate_and_apply(block) {
        Result::Ok(res) => (true, res),
        Result::Err(err) => {
            println!("{}", err);
            (false, Default::default())
        }
    }
}
