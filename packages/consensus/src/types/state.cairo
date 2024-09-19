//! State is a top level struct containing the chain state and the utxo set

use crate::types::utreexo::{UtreexoState, UtreexoStateDefault};
use super::chain_state::ChainState;

#[derive(Default, Drop, Copy, Debug, Serde)]
pub struct State {
    pub chain_state: ChainState,
    pub utreexo_state: UtreexoState
}
