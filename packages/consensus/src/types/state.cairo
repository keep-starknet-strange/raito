//! State is a top level struct containing the chain state and the utxo set

use super::chain_state::ChainState;
use super::utreexo::UtreexoState;

#[derive(Default, Drop, Copy, Debug)]
pub struct State {
    chain_state: ChainState,
    utreexo_state: UtreexoState
}
