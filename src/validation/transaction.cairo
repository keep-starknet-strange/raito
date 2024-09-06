//! Transaction validation helpers.

use crate::types::transaction::{Transaction};

// Setting sequence to this value for every input in a transaction
// disables the locktime feature
const SEQUENCE_FINAL: u32 = 0xffffffff;

// Threshold for lock_time: below this value it is interpreted as block number,
// otherwise as UNIX timestamp.
const LOCKTIME_THRESHOLD: u32 = 500000000; // Tue Nov  5 00:53:20 1985 UTC
// 0x80000000 mask is used to determine if it is time-based (bit 31)
const LOCKTIME_MASK: u32 = 0x80000000;

/// Validate transaction and return transaction fee.
///
/// This does not include script checks and outpoint inclusion verification.
pub fn validate_transaction(
    tx: @Transaction, block_height: u32, block_time: u32
) -> Result<u64, ByteArray> {
    // TODO: validate that
    //      - Inputs array is not empty
    //      - Outputs array is not empty
    //      - Output values are within the range [0, 21M]
    //      - Total output value is within the range [0, 21M]
    //      - Transaction fee is in the range [0, 21M]
    //      - Transaction is final (check timelock and input sequences)
    //      - Coinbase is mature (if some input spends coinbase tx from the past)
    //
    //  Skipped checks:
    //      - There are no duplicate inputs - this should be actually done during the Utreexo proof
    //      verification - Maybe we don't need to check the upper money range (21M)
    //
    // References:
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_check.cpp
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_verify.cpp
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/validation.cpp

    if (*tx.inputs).len() == 0 {
        return Result::Err("transaction inputs are empty");
    };
    if (*tx.outputs).len() == 0 {
        return Result::Err("transaction outputs are empty");
    };

    // check if transaction is finalized
    // https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_verify.cpp#L17
    validate_absolute_locktime(tx, block_height, block_time)?;

    let mut maturity_result = Option::None;

    // Coinbase maturity test
    for input in *tx
        .inputs {
            if *input.previous_output.is_coinbase {
                let coinbase_block_height = *input.previous_output.block_height;
                if block_height <= coinbase_block_height + 100 {
                    maturity_result =
                        Option::Some(
                            format!(
                                "[validate_transaction] coinbase input: ({}, {}) not mature (current height: {}, coinbase height: {})",
                                *input.previous_output.txid,
                                *input.previous_output.vout,
                                block_height,
                                coinbase_block_height
                            )
                        );
                    break;
                }
            }
        };

    if let Option::Some(result) = maturity_result {
        return Result::Err(result);
    }

    let mut total_input_amount = 0;
    for input in *tx.inputs {
        total_input_amount += *input.previous_output.data.value;
    };

    let mut total_output_amount = 0;
    for output in *tx.outputs {
        total_output_amount += *output.value;
    };

    if total_output_amount > total_input_amount {
        return Result::Err(
            format!(
                "[validate_transaction] negative fee (output {total_output_amount} > input {total_input_amount})"
            )
        );
    }
    let tx_fee = total_input_amount - total_output_amount;

    Result::Ok(tx_fee)
}

pub fn validate_absolute_locktime(
    tx: @Transaction, block_height: u32, block_time: u32
) -> Result<(), ByteArray> {
    if *tx.lock_time < LOCKTIME_THRESHOLD && *tx.lock_time < block_height {
        return Result::Ok(());
    };

    if *tx.lock_time >= LOCKTIME_THRESHOLD && *tx.lock_time < block_time {
        return Result::Ok(());
    };

    let mut check_threshold_result: Result<(), ByteArray> = Result::Ok(());
    for input in *tx
        .inputs {
            if *input.sequence != SEQUENCE_FINAL {
                check_threshold_result =
                    Result::Err(
                        if *tx.lock_time >= LOCKTIME_THRESHOLD {
                            format!(
                                "transaction is not final: transaction locktime {} is not lesser than current block time {}",
                                *tx.lock_time,
                                block_time
                            )
                        } else {
                            format!(
                                "transaction is not final: transaction locktime {} is not lesser than current block height {}",
                                *tx.lock_time,
                                block_height
                            )
                        }
                    );
                break;
            };
        };
    check_threshold_result
}

/// Validate a transaction input. If relative locktime is enabled,
/// ensure the input's locktime is respected.
pub fn validate_relative_locktime(
    tx: @Transaction, input_index: usize, block_height: u32, block_time: u32
) -> Result<(), ByteArray> {
    // Get the input we are validating
    let tx_input = *tx.inputs[input_index];

    // If nSequence is set to 0xFFFFFFFF, it is not subject to relative locktime
    if tx_input.sequence == SEQUENCE_FINAL {
        return Result::Ok(());
    }

    // BIP-68 relative locktime calculation
    let sequence = tx_input.sequence;
    // 0x80000000 mask is used to determine if it is time-based (bit 31)
    //  let locktime_mask = 0x80000000;
    let relative_locktime = sequence & 0xFFFF;

    //  If bit 22 (0x00400000) is set, relative locktime is in seconds (time-based), else
    //  block-based
    let is_time_based = (sequence & LOCKTIME_MASK) != 0;
    if is_time_based {
        // Time-based relative locktime (512 seconds per unit)
        let locktime_in_seconds = relative_locktime * 512;
        if block_time < locktime_in_seconds {
            return Result::Err(
                format!(
                    "[validate_input] Transaction is not yet valid due to relative time-based locktime. Current time: {}, Required: {} seconds",
                    block_time,
                    locktime_in_seconds
                )
            );
        }
    } else {
        // Block-based relative locktime
        let locktime_in_blocks = relative_locktime;
        if block_height < locktime_in_blocks {
            return Result::Err(
                format!(
                    "[validate_input] Transaction is not yet valid due to relative block-based locktime. Current block: {}, Required: {}",
                    block_height,
                    locktime_in_blocks
                )
            );
        }
    }

    // Return success if all validations passed
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
    use crate::utils::hex::{from_hex, hex_to_hash_rev};
    use super::{validate_transaction, validate_relative_locktime};

    #[test]
    fn test_relative_locktime_disabled() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff, // final, relative locktime disabled
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

        // Relative locktime should be ignored when sequence is 0xFFFFFFFF
        // Case 1: Current block time less than locktime, but it should be valid
        let result = validate_relative_locktime(@tx, 0, 0, 1600000000);
        assert!(result.is_ok());

        // Case 2: Current block time greater than locktime, still valid
        let result = validate_relative_locktime(@tx, 0, 0, 1600000001);
        assert!(result.is_ok());
    }


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
        assert!(validate_transaction(@tx, 0, 0).is_err());

        let fee = validate_transaction(@tx, 101, 0).unwrap();
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

        let result = validate_transaction(@tx, 0, 0);
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

        let result = validate_transaction(@tx, 0, 0);
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

        // Transaction should be invalid when current block height is less than locktime
        let result = validate_transaction(@tx, 500000, 0);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().into(),
            "transaction is not final: transaction locktime 500000 is not lesser than current block height 500000"
        );

        // Transaction should be valid when current block height is equal to or greater than
        // locktime
        let result = validate_transaction(@tx, 500001, 0);
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

        // Transaction should be invalid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 0, 1600000000);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().into(),
            "transaction is not final: transaction locktime 1600000000 is not lesser than current block time 1600000000"
        );

        // Transaction should be valid when current block time is equal to or greater than locktime
        let result = validate_transaction(@tx, 0, 1600000001);
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

        // Transaction should still valid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 0, 1600000000);
        assert!(result.is_ok());

        // Transaction should be valid when current block time is greater than locktime
        let result = validate_transaction(@tx, 0, 1600000001);
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

        // Transaction should still valid when current block time is not greater than locktime
        let result = validate_transaction(@tx, 500000, 0);
        assert!(result.is_ok());

        // Transaction should be valid when current block time is greater than locktime
        let result = validate_transaction(@tx, 500001, 0);
        assert!(result.is_ok());
    }
}
