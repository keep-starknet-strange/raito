//! Unspent transaction output set contains outputs from the previous blocks
//! that can be referenced in the transaction inputs.
//!
//! UTXO set is very large hence it is infeasible to pass it entirely as a program input.
//! Instead we provide only a subset of outputs that are:
//!   - going to be spent in the validated blocks
//!   - created in the previous blocks (i.e. are not spent in the same block)
//!
//! In order to prove that the UTXOs provided actually belong to the set we use either
//! Utreexo accumulator or local cache.

use core::dict::Felt252Dict;
use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;
use super::transaction::OutPoint;
use super::utreexo::{UtreexoState, UtreexoAccumulator};

#[derive(Default, Destruct)]
pub struct UtxoSet {
    /// Utreexo state.
    pub utreexo_state: UtreexoState,
    /// The leaves represent the poseidon hashes of a block's outpoints, i.e. utxos
    pub leaves_to_add: Array<felt252>,
    /// Hashes of UTXOs created within the current block(s).
    /// Note that to preserve the ordering, cache has to be updated right after a
    /// particular output is created or spent.
    pub cache: Felt252Dict<bool>,
}

#[generate_trait]
pub impl UtxoSetImpl of UtxoSetTrait {
    fn new(utreexo_state: UtreexoState) -> UtxoSet {
        UtxoSet { utreexo_state, ..Default::default() }
    }

    fn add(ref self: UtxoSet, output: OutPoint) {
        let outpoint_hash = PoseidonTrait::new().update_with(output).finalize();
        if output.data.cached {
            self.cache.insert(outpoint_hash, true);
        } else {
            self.leaves_to_add.append(outpoint_hash);
        }
    }

    fn utreexo_add(ref self: UtxoSet) {
        for leave in self.leaves_to_add.clone() {
            self.utreexo_state.add(leave);
        }
    }

    fn delete(ref self: UtxoSet, output: @OutPoint) {
        if *output.data.cached {
            let outpoint_hash = PoseidonTrait::new().update_with(*output).finalize();
            // Extra check that can be removed later.
            assert(self.cache.get(outpoint_hash), 'output is not cached');
            self.cache.insert(outpoint_hash, false);
        } else { // TODO: update utreexo roots (+ verify inclusion)
        // If batched proofs are used then do nothing.
        }
    }
}
