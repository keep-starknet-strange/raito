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
use super::utreexo::UtreexoState;
use super::transaction::OutPoint;

pub const TX_OUTPUT_STATUS_NONE: u8 = 0;
pub const TX_OUTPUT_STATUS_UNSPENT: u8 = 1;
pub const TX_OUTPUT_STATUS_SPENT: u8 = 2;

#[derive(Default, Destruct)]
pub struct UtxoSet {
    /// Utreexo state.
    pub utreexo_state: UtreexoState,
    /// Hashes and statuses of tx outputs created or spent within the current block(s).
    /// Note that to preserve the ordering, cache has to be updated right after a
    /// particular output is created or spent.
    pub cache: Felt252Dict<u8>,
}

#[generate_trait]
pub impl UtxoSetImpl of UtxoSetTrait {
    fn new(utreexo_state: UtreexoState) -> UtxoSet {
        UtxoSet { utreexo_state, ..Default::default() }
    }

    fn add(ref self: UtxoSet, output: OutPoint) -> Result<(), ByteArray> {
        if output.data.cached {
            let hash = PoseidonTrait::new().update_with(output).finalize();
            if self.cache.get(hash) != TX_OUTPUT_STATUS_NONE {
                return Result::Err("The output has already been added");
            }
            self.cache.insert(hash, TX_OUTPUT_STATUS_UNSPENT);
        } else { // TODO: update utreexo roots
        }
        Result::Ok(())
    }

    fn spend(ref self: UtxoSet, output: @OutPoint) -> Result<(), ByteArray> {
        let hash = PoseidonTrait::new().update_with(*output).finalize();
        let status = self.cache.get(hash);
        if status == TX_OUTPUT_STATUS_NONE {
            // Extra check that can be removed later.
            assert(!*output.data.cached, 'output is not cached');
            // TODO: verify inclusion and update utreexo roots
        } else if status == TX_OUTPUT_STATUS_SPENT {
            return Result::Err("The output has already been spent");
        }
        self.cache.insert(hash, TX_OUTPUT_STATUS_SPENT);
        Result::Ok(())
    }
}
