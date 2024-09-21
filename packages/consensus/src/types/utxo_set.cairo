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

pub const TX_OUTPUT_STATUS_NONE: u8 = 0;
pub const TX_OUTPUT_STATUS_UNSPENT: u8 = 1;
pub const TX_OUTPUT_STATUS_SPENT: u8 = 2;

#[derive(Default, Destruct)]
pub struct UtxoSet {
    /// Hashes of created UTXOs.
    pub leaves_to_add: Array<felt252>,
    /// Hashes of spent (i.e. deleted) UTXOs.
    pub leaves_to_delete: Array<felt252>,
    /// Number of pending cached UTXOs that must be spent within the current block(s).
    pub num_cached: i32,
    /// Statuses of UTXOs created or spent within the current block(s).
    /// Note that to preserve the ordering, statuses has to be updated right after a
    /// particular output is created or spent.
    pub cache: Felt252Dict<u8>,
}

#[generate_trait]
pub impl UtxoSetImpl of UtxoSetTrait {
    fn add(ref self: UtxoSet, output: OutPoint) -> Result<(), ByteArray> {
        let hash = PoseidonTrait::new().update_with(output).finalize();
        if self.cache.get(hash) == TX_OUTPUT_STATUS_NONE {
            if output.data.cached {
                self.num_cached += 1;
            } else {
                self.leaves_to_add.append(hash);
            }
            self.cache.insert(hash, TX_OUTPUT_STATUS_UNSPENT);
            Result::Ok(())
        } else {
            Result::Err("The output has already been added")
        }
    }

    fn spend(ref self: UtxoSet, output: @OutPoint) -> Result<(), ByteArray> {
        let hash = PoseidonTrait::new().update_with(*output).finalize();
        let status = self.cache.get(hash);
        if status == TX_OUTPUT_STATUS_NONE {
            // Extra check that can be removed later.
            assert(!*output.data.cached, 'cached output was not cached');

            self.cache.insert(hash, TX_OUTPUT_STATUS_SPENT);
            self.leaves_to_delete.append(hash);
            Result::Ok(())
        } else if status == TX_OUTPUT_STATUS_UNSPENT {
            // Extra check that can be removed later.
            assert(*output.data.cached, 'non-cached output was cached');

            self.cache.insert(hash, TX_OUTPUT_STATUS_SPENT);
            self.num_cached -= 1;
            Result::Ok(())
        } else {
            Result::Err("The output has already been spent")
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{TxOut, OutPoint};
    use crate::types::utxo_set::{UtxoSet, UtxoSetTrait};
    use utils::hex::{from_hex, hex_to_hash_rev};

    #[test]
    fn test_utxo_set_add() {
        let mut utxo_set: UtxoSet = Default::default();

        // Test normal flow
        utxo_set.add(dummy_outpoint(0, false)).unwrap();
        utxo_set.add(dummy_outpoint(1, true)).unwrap();
        utxo_set.add(dummy_outpoint(2, false)).unwrap();

        assert_eq!(utxo_set.leaves_to_add.len(), 2);
        assert_eq!(utxo_set.leaves_to_delete.len(), 0);
        assert_eq!(utxo_set.num_cached, 1);

        // Test cached duplicates
        let result = utxo_set.add(dummy_outpoint(1, true));
        assert_eq!(result.unwrap_err(), "The output has already been added");

        // Test non-cached duplicates
        let result = utxo_set.add(dummy_outpoint(0, false));
        assert_eq!(result.unwrap_err(), "The output has already been added");
    }

    #[test]
    fn test_utxo_set_spend() {
        let mut utxo_set: UtxoSet = Default::default();

        // Test normal flow
        utxo_set.add(dummy_outpoint(0, true)).unwrap();
        utxo_set.add(dummy_outpoint(1, false)).unwrap();
        utxo_set.add(dummy_outpoint(2, true)).unwrap();

        utxo_set.spend(@dummy_outpoint(0, true)).unwrap();
        utxo_set.spend(@dummy_outpoint(3, false)).unwrap();
        utxo_set.spend(@dummy_outpoint(2, true)).unwrap();
        utxo_set.spend(@dummy_outpoint(4, false)).unwrap();

        assert_eq!(utxo_set.leaves_to_add.len(), 1);
        assert_eq!(utxo_set.leaves_to_delete.len(), 2);
        assert_eq!(utxo_set.num_cached, 0);

        // Test cached double spending
        let result = utxo_set.spend(@dummy_outpoint(0, true));
        assert_eq!(result.unwrap_err(), "The output has already been spent");

        // Test non-cached double spending
        let result = utxo_set.spend(@dummy_outpoint(3, false));
        assert_eq!(result.unwrap_err(), "The output has already been spent");
    }

    fn dummy_outpoint(vout: u32, cached: bool) -> OutPoint {
        OutPoint {
            txid: hex_to_hash_rev(
                "0000000000000000000000000000000000000000000000000000000000000000"
            ),
            vout,
            data: TxOut {
                value: 50,
                pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                cached,
            },
            block_height: 1234,
            block_time: Default::default(),
            is_coinbase: false,
        }
    }
}
