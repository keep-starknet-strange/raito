//! State is a top level struct containing the chain state and the utxo set

use super::chain_state::ChainState;
use super::utxo_set::UtxoSet;

#[derive(Default, Destruct)]
pub struct State {
    chain_state: ChainState,
    utxo_set: UtxoSet
}
