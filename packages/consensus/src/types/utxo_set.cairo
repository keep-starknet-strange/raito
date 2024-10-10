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
use super::transaction::{OutPoint, OutPointTrait};
use consensus::validation::transaction::is_pubscript_unspendable;

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
    fn add(ref self: UtxoSet, outpoint: OutPoint) -> Result<(), ByteArray> {
        let hash = outpoint.hash();

        if self.cache.get(hash) == TX_OUTPUT_STATUS_NONE {
            if (!is_pubscript_unspendable(outpoint.data.pk_script)) {
                if outpoint.data.cached {
                    self.num_cached += 1;
                } else {
                    self.leaves_to_add.append(hash);
                }
                self.cache.insert(hash, TX_OUTPUT_STATUS_UNSPENT);
            }
            Result::Ok(())
        } else {
            Result::Err("The output has already been added")
        }
    }

    fn spend(ref self: UtxoSet, outpoint: @OutPoint) -> Result<(), ByteArray> {
        let hash = outpoint.hash();
        let status = self.cache.get(hash);
        if status == TX_OUTPUT_STATUS_NONE {
            // Extra check that can be removed later.
            assert(!*outpoint.data.cached, 'cached output was not cached');

            self.cache.insert(hash, TX_OUTPUT_STATUS_SPENT);
            self.leaves_to_delete.append(hash);
            Result::Ok(())
        } else if status == TX_OUTPUT_STATUS_UNSPENT {
            // Extra check that can be removed later.
            assert(*outpoint.data.cached, 'non-cached output was cached');

            self.cache.insert(hash, TX_OUTPUT_STATUS_SPENT);
            self.num_cached -= 1;
            Result::Ok(())
        } else {
            Result::Err("The output has already been spent")
        }
    }

    fn finalize(ref self: UtxoSet) -> Result<(), ByteArray> {
        if self.num_cached != 0 {
            Result::Err("There are unprocessed cached outputs")
        } // TODO: uncomment when utreexo is enabled
        // else if self.leaves_to_add.len() != 0 {
        //     Result::Err("There are unprocessed leaves to add")
        // } else if self.leaves_to_delete.len() != 0 {
        //     Result::Err("There are unprocessed leaves to delete")
        // }
        else {
            Result::Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{TxOut, OutPoint};
    use crate::types::utxo_set::{UtxoSet, UtxoSetTrait};
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
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

    #[test]
    fn test_not_include_unspendable_utxo() {
        let mut utxo_set: UtxoSet = Default::default();
        utxo_set.add(dummy_outpoint(0, false)).unwrap();
        utxo_set.add(dummy_unspendable_outpoint(0, false));
        utxo_set.add(dummy_outpoint(1, true)).unwrap();
        utxo_set.add(dummy_unspendable_outpoint(1, true));
        utxo_set.add(dummy_outpoint(2, false)).unwrap();
        utxo_set.add(dummy_unspendable_outpoint(2, false));

        assert_eq!(utxo_set.leaves_to_add.len(), 2);
        assert_eq!(utxo_set.leaves_to_delete.len(), 0);
        assert_eq!(utxo_set.num_cached, 1);
    }

    fn dummy_unspendable_outpoint(vout: u32, cached: bool) -> OutPoint {
        OutPoint {
            txid: hex_to_hash_rev(
                "0000000000000000000000000000000000000000000000000000000000000000"
            ),
            vout,
            data: TxOut {
                value: 50,
                pk_script: @from_hex("6a4c54000000000000000000000000000000000000000088ac"),
                cached,
            },
            block_hash: Default::default(),
            block_height: Default::default(),
            block_time: Default::default(),
            is_coinbase: false,
        }
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
            block_hash: Default::default(),
            block_height: Default::default(),
            median_time_past: Default::default(),
            is_coinbase: false,
        }
    }

    /// block 170 tx1 v0 -> block9 tx coinbase v0
    fn get_outpoint() -> OutPoint {
        OutPoint {
            txid: hex_to_hash_rev(
                "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9"
            ),
            vout: 0,
            data: TxOut {
                value: 5000000000,
                pk_script: @from_hex(
                    "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
                ),
                cached: false
            },
            block_height: 9,
            block_time: 1231473279,
            block_hash: hex_to_hash_rev(
                "000000008d9dc510f23c2657fc4f67bea30078cc05a90eb89e84cc475c080805"
            ),
            is_coinbase: true
        }
    }

    /// outpoint hash of first output spent block 170
    #[test]
    fn test_poseidon1() {
        let outpoint: OutPoint = get_outpoint();
        let outpoint_hash = PoseidonTrait::new().update_with(outpoint).finalize();
        let expected: felt252 = 0x58AFF693254F7B140285AD614EE509E8336496EE259AC890B9B03B3C2E4B9AE;
        assert_eq!(outpoint_hash, expected);
    }
}
