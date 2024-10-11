//! Transaction validation helpers.

use crate::types::transaction::{OutPoint, Transaction};
use crate::types::utxo_set::{UtxoSet, UtxoSetTrait};
use crate::validation::locktime::{
    is_input_final, validate_absolute_locktime, validate_relative_locktime
};
use utils::hash::Digest;

const OP_RETURN: u8 = 0x6a;
const MAX_SCRIPT_SIZE: u32 = 10000;

/// Validate transaction and return transaction fee.
///
/// This does not include script checks and outpoint inclusion verification.
pub fn validate_transaction(
    tx: @Transaction,
    block_height: u32,
    median_time_past: u32,
    txid: Digest,
    ref utxo_set: UtxoSet
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
            // Ensures that the output is not yet spent and spends it
            inner_result = utxo_set.spend(input.previous_output);
            if inner_result.is_err() {
                break;
            }

            if *input.previous_output.is_coinbase {
                inner_result =
                    validate_coinbase_maturity(*input.previous_output.block_height, block_height);
                if inner_result.is_err() {
                    break;
                }
            }

            if !is_input_final(*input.sequence) {
                inner_result = validate_relative_locktime(input, block_height, median_time_past);
                if inner_result.is_err() {
                    break;
                }
                is_tx_final = false;
            }

            total_input_amount += *input.previous_output.data.value;
        };

    if inner_result.is_err() {
        return Result::Err(inner_result.unwrap_err());
    }

    if !is_tx_final {
        // If at least one input is not final
        validate_absolute_locktime(*tx.lock_time, block_height, median_time_past)?;
    }

    // Validate and process transaction outputs
    let mut total_output_amount = 0;

    let mut vout = 0;
    for output in *tx
        .outputs {
            // Adds outpoint to the cache if the corresponding transaction output will be used
            // as a transaction input in the same block(s), or adds it to the utreexo otherwise.
            let outpoint = OutPoint {
                txid,
                vout,
                data: *output,
                block_hash,
                block_height,
                median_time_past,
                is_coinbase: false,
            };

            inner_result = utxo_set.add(outpoint);
            if inner_result.is_err() {
                break;
            }

            total_output_amount += *output.value;
            vout += 1;
        };

    inner_result?;
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

/// Checks if a public key script (pubscript) is provably unspendable.
///
/// A pubscript is considered unspendable if:
/// - It starts with `OP_RETURN`.
/// - Its size exceeds the maximum allowed script size.
pub fn is_pubscript_unspendable(pubscript: @ByteArray) -> bool {
    pubscript[0].into() == OP_RETURN || pubscript.len() > MAX_SCRIPT_SIZE
}

#[cfg(test)]
mod tests {
    use core::dict::Felt252Dict;
    use crate::codec::Encode;
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint, OutPointTrait};
    use crate::types::utxo_set::{UtxoSet, TX_OUTPUT_STATUS_UNSPENT};
    use utils::{hex::{from_hex, hex_to_hash_rev}, double_sha256::double_sha256_byte_array};
    use super::{validate_transaction, is_pubscript_unspendable, MAX_SCRIPT_SIZE};

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
                        median_time_past: Default::default(),
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

        utxo_set = Default::default();

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
                        median_time_past: Default::default(),
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
                        median_time_past: Default::default(),
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

        utxo_set = Default::default();

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
                        median_time_past: Default::default(),
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

        utxo_set = Default::default();

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
                        median_time_past: Default::default(),
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

        utxo_set = Default::default();

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
                        median_time_past: Default::default(),
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

        utxo_set = Default::default();

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
                        median_time_past: Default::default(),
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
                        median_time_past: Default::default(),
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

    #[test]
    #[should_panic(expected: 'cached output was not cached')]
    fn test_missed_cached_utxo() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: true },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        validate_transaction(@tx, block_height, 0, txid, ref utxo_set).unwrap();
    }

    #[test]
    #[should_panic(expected: 'non-cached output was cached')]
    fn test_wrongly_cached_utxo() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: false },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        let mut cache: Felt252Dict<u8> = Default::default();
        let outpoint_hash = (*tx.inputs[0]).previous_output.hash();
        cache.insert(outpoint_hash, TX_OUTPUT_STATUS_UNSPENT);
        let mut utxo_set = UtxoSet { cache, ..Default::default() };

        validate_transaction(@tx, block_height, 0, txid, ref utxo_set).unwrap();
    }

    #[test]
    fn test_cached_utxo_spending_attempt() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: true },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
            lock_time: 0
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        let mut cache: Felt252Dict<u8> = Default::default();
        let outpoint_hash = (*tx.inputs[0]).previous_output.hash();
        cache.insert(outpoint_hash, TX_OUTPUT_STATUS_UNSPENT);
        let mut utxo_set = UtxoSet { cache, ..Default::default() };

        validate_transaction(@tx, block_height, 0, txid, ref utxo_set).unwrap();
    }

    #[test]
    fn test_cached_utxo_duplicates() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: false },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
                    cached: true,
                }
            ]
                .span(),
            lock_time: 0,
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        let mut cache: Felt252Dict<u8> = Default::default();
        let outpoint = OutPoint {
            txid,
            vout: 0,
            data: *tx.outputs[0],
            block_height,
            median_time_past: Default::default(),
            is_coinbase: false,
        };
        let outpoint_hash = outpoint.hash();
        cache.insert(outpoint_hash, TX_OUTPUT_STATUS_UNSPENT);
        let mut utxo_set = UtxoSet { cache, ..Default::default() };

        let result = validate_transaction(@tx, block_height, 0, txid, ref utxo_set);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "The output has already been added");
    }

    #[test]
    fn test_cached_utxo_double_spending() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: true },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                },
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: true },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
            lock_time: 0,
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        let mut cache: Felt252Dict<u8> = Default::default();
        let outpoint_hash = (*tx.inputs[0]).previous_output.hash();
        cache.insert(outpoint_hash, TX_OUTPUT_STATUS_UNSPENT);
        let mut utxo_set = UtxoSet { cache, ..Default::default() };

        let result = validate_transaction(@tx, block_height, 0, txid, ref utxo_set);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "The output has already been spent");
    }

    #[test]
    fn test_noncached_utxo_double_spending() {
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
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: false },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                },
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffe,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0000000000000000000000000000000000000000000000000000000000000000"
                        ),
                        vout: 0,
                        data: TxOut { value: 100, pk_script: @from_hex(""), cached: false },
                        block_height: Default::default(),
                        median_time_past: Default::default(),
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
            lock_time: 0,
        };

        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let mut utxo_set: UtxoSet = Default::default();

        let result = validate_transaction(@tx, block_height, 0, txid, ref utxo_set);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "The output has already been spent");
    }

    #[test]
    fn test_pubscript_starts_with_op_return() {
        let op_return_script = from_hex("6a146f6e65207069656365206f6620646174612068657265");
        assert!(is_pubscript_unspendable(@op_return_script));
    }

    #[test]
    fn test_pubscript_within_size_limit() {
        let normal_script = from_hex("76a91489abcdefabbaabbaabbaabbaabbaabbaabbaabba88ac");
        assert!(!is_pubscript_unspendable(@normal_script));
    }

    #[test]
    fn test_pubscript_exceeds_max_size() {
        let mut large_script: ByteArray = Default::default();
        for _ in 0..(MAX_SCRIPT_SIZE + 1) {
            large_script.append_byte(0x00);
        };
        assert!(is_pubscript_unspendable(@large_script));
    }
}
