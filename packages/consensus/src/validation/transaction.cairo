//! Transaction validation helpers.

use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;
use crate::types::transaction::{OutPoint, Transaction, TxOut};
use crate::types::utxo_set::UtxoSet;
use crate::validation::locktime::{
    is_input_final, validate_absolute_locktime, validate_relative_locktime
};
use utils::hash::Digest;

/// Validate transaction and return transaction fee.
///
/// This does not include script checks and outpoint inclusion verification.
pub fn validate_transaction(
    tx: @Transaction, block_height: u32, block_time: u32, txid: Digest, ref utxo_set: UtxoSet
) -> Result<u64, ByteArray> {
    if (*tx.inputs).is_empty() {
        return Result::Err("transaction inputs are empty");
    };

    if (*tx.outputs).is_empty() {
        return Result::Err("transaction outputs are empty");
    };

    let mut inner_result: Result<(), ByteArray> = Result::Ok(());

    // Validate and process transaction inputs
    let mut total_input_amount = 0;
    let mut is_tx_final = true;

    // TODO: BIP68 enabled for tx with version >= 2 (is it critical?)

    for input in *tx
        .inputs {
            // Removes the outpoint hash of a transaction input if it was in the cache.
            let outpoint = input.previous_output;
            let outpoint_hash = PoseidonTrait::new().update_with(*outpoint).finalize();
            if (utxo_set.cache.get(outpoint_hash) == true) {
                utxo_set.cache.insert(outpoint_hash, false);
            }

            if *input.previous_output.is_coinbase {
                inner_result =
                    validate_coinbase_maturity(*input.previous_output.block_height, block_height);
                if inner_result.is_err() {
                    break;
                }
            }

            if !is_input_final(*input.sequence) {
                inner_result = validate_relative_locktime(input, block_height, block_time);
                if inner_result.is_err() {
                    break;
                }
                is_tx_final = false;
            }

            total_input_amount += *input.previous_output.data.value;
        };

    if let Result::Err(err) = inner_result {
        return Result::Err(err);
    }

    if !is_tx_final {
        // If at least one input is not final
        validate_absolute_locktime(*tx.lock_time, block_height, block_time)?;
    }

    // Validate and process transaction outputs
    let mut total_output_amount = 0;

    let mut vout = 1;
    for output in *tx
        .outputs {
            // Adds outpoint hash in the cache if the corresponding transaction output will be used
            // as a transaction input in the same block(s).
            if (*output.cached) {
                let outpoint = OutPoint {
                    txid: txid,
                    vout: vout,
                    data: TxOut {
                        value: *output.value, pk_script: *output.pk_script, cached: true
                    },
                    block_height: block_height,
                    block_time: block_time,
                    is_coinbase: false,
                };

                let outpoint_hash = PoseidonTrait::new().update_with(outpoint).finalize();
                utxo_set.cache.insert(outpoint_hash, true);
            }

            total_output_amount += *output.value;
            vout += 1;
        };

    return compute_transaction_fee(total_input_amount, total_output_amount);
}

/// Ensure transaction fee is not negative.
fn compute_transaction_fee(
    total_input_amount: u64, total_output_amount: u64
) -> Result<u64, ByteArray> {
    if total_output_amount > total_input_amount {
        return Result::Err(
            format!("Negative fee (output {total_output_amount} > input {total_input_amount})")
        );
    }
    return Result::Ok(total_input_amount - total_output_amount);
}

/// Ensure than coinbase output is old enough to be spent.
fn validate_coinbase_maturity(output_height: u32, block_height: u32) -> Result<(), ByteArray> {
    if block_height <= output_height + 100 {
        return Result::Err(
            format!(
                "Output is not mature (output height: {}, current block height: {})",
                output_height,
                block_height,
            )
        );
    } else {
        return Result::Ok(());
    }
}

#[cfg(test)]
mod tests {
    use crate::codec::Encode;
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
    use crate::types::utxo_set::UtxoSet;
    use utils::{hex::{from_hex, hex_to_hash_rev}, sha256::double_sha256_byte_array};
    use super::validate_transaction;

    // TODO: tests for coinbase maturity

    #[test]
    fn test_tx_fee() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "01091d8d76a82122082246acbb6cc51c839d9012ddaca46048de07ca8eec221518200241cdb85fab4815c6c624d6e932774f3fdf5fa2a1d3a1614951afb83269e1454e2002443047"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9"
                        ),
                        vout: 0x00000000,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: true,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 90,
                    pk_script: @from_hex(
                        "ac4cd86c7e4f702ac7d5debaf126068a3b30b7c1212c145fdfa754f59773b3aae71484a22f30718d37cd74f325229b15f7a2996bf0075f90131bf5c509fe621aae0441"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        assert!(validate_transaction(@tx, 0, 0, txid, ref utxo_set).is_err());

        let fee = validate_transaction(@tx, 101, 0, txid, ref utxo_set).unwrap();
        assert_eq!(fee, 10);
    }

    #[test]
    fn test_empty_input() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![].span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        let result = validate_transaction(@tx, 0, 0, txid, ref utxo_set);
        assert!(result.is_err());
        // assert_eq!(result.unwrap_err(), "transaction inputs are empty");
    }

    #[test]
    fn test_empty_output() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![].span(),
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        let result = validate_transaction(@tx, 0, 0, txid, ref utxo_set);
        assert!(result.is_err());
        // assert_eq!(result.unwrap_err(), "transaction outputs are empty");
    }

    #[test]
    fn test_absolute_locktime_block_height() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe, // absolute locktime
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 500000 // Block height locktime
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        // Transaction should be invalid when current block height is less than locktime
        let result = validate_transaction(@tx, 500000, 0, txid, ref utxo_set);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().into(),
            "Transaction locktime 500000 is not lesser than current block height 500000"
        );

        // Transaction should be valid when current block height is equal to or greater than
        // locktime
        let result = validate_transaction(@tx, 500001, 0, txid, ref utxo_set);
        assert!(result.is_ok());
    }

    #[test]
    fn test_absolute_locktime_block_time() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe, // Not final
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 1600000000 // UNIX timestamp locktime
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        // Transaction should be invalid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 0, 1600000000, txid, ref utxo_set);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().into(),
            "Transaction locktime 1600000000 is not lesser than current block time 1600000000"
        );

        // Transaction should be valid when current block time is equal to or greater than locktime
        let result = validate_transaction(@tx, 0, 1600000001, txid, ref utxo_set);
        assert!(result.is_ok());
    }

    #[test]
    fn test_blocktime_ignored_when_locktime_disabled() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff, // final
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 1600000000 // UNIX timestamp locktime
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        // Transaction should still valid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 0, 1600000000, txid, ref utxo_set);
        assert!(result.is_ok());

        // Transaction should be valid when current block time is greater than locktime
        let result = validate_transaction(@tx, 0, 1600000001, txid, ref utxo_set);
        assert!(result.is_ok());
    }

    #[test]
    fn test_blockheight_ignored_when_locktime_disabled() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff, // final
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 500000 // Block height locktime
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        // Transaction should still valid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 500000, 0, txid, ref utxo_set);
        assert!(result.is_ok());

        // Transaction should be valid when current block time is greater than locktime
        let result = validate_transaction(@tx, 500001, 0, txid, ref utxo_set);
        assert!(result.is_ok());
    }

    #[test]
    fn test_immature_coinbase_transaction() {
        let block_height = 50;

        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: true,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        validate_transaction(@tx, block_height, 0, txid, ref utxo_set).unwrap_err();
    }

    #[test]
    fn test_mature_coinbase_transaction() {
        let block_height = 150;

        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: true,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 50,
                    pk_script: @from_hex("76a914000000000000000000000000000000000000000088ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        validate_transaction(@tx, block_height, 0, txid, ref utxo_set).unwrap();
    }
}
