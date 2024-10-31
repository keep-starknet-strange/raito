//! Transaction locktime validation helpers.

use crate::types::transaction::TxIn;

/// Setting sequence to this value for every input in a transaction
/// fully disables the locktime feature.
const SEQUENCE_FINAL: u32 = 0xffffffff;

/// If this bit is set the relative locktime is disabled
const SEQUENCE_LOCKTIME_DISABLE_FLAG: u32 = 0x80000000;

/// If this bit is set the relative locktime is time-based,
/// otherwise block-based
const SEQUENCE_LOCKTIME_TYPE_FLAG: u32 = 0x00400000;

/// Relative locktime value is stored in the lowest two bytes
const SEQUENCE_LOCKTIME_MASK: u32 = 0x0000ffff;

/// Threshold for lock_time: below this value it is interpreted as block number,
/// otherwise as UNIX timestamp.
const LOCKTIME_THRESHOLD: u32 = 500000000; // Tue Nov  5 00:53:20 1985 UTC

/// Checks if the transaction input is final given its sequence
pub fn is_input_final(sequence: u32) -> bool {
    return sequence == SEQUENCE_FINAL;
}

/// Validate transaction absolute locktime given that it is enabled.
///
/// https://learnmeabitcoin.com/technical/transaction/locktime/
pub fn validate_absolute_locktime(
    lock_time: u32, block_height: u32, block_time: u32
) -> Result<(), ByteArray> {
    if lock_time < LOCKTIME_THRESHOLD {
        if lock_time < block_height {
            return Result::Ok(());
        } else {
            return Result::Err(
                format!(
                    "Transaction locktime {} is not lesser than current block height {}",
                    lock_time,
                    block_height
                )
            );
        }
    } else if lock_time < block_time {
        return Result::Ok(());
    } else {
        return Result::Err(
            format!(
                "Transaction locktime {} is not lesser than current block time {}",
                lock_time,
                block_time
            )
        );
    }
}

/// Validate a transaction input relative locktime given that the input is not final.
///
/// If relative locktime is enabled, ensure the input's locktime is respected.
/// https://learnmeabitcoin.com/technical/transaction/input/sequence/
pub fn validate_relative_locktime(
    input: @TxIn, block_height: u32, median_time_past: u32
) -> Result<(), ByteArray> {
    let sequence = *input.sequence;
    if sequence & SEQUENCE_LOCKTIME_DISABLE_FLAG != 0 {
        return Result::Ok(());
    }

    let value = sequence & SEQUENCE_LOCKTIME_MASK;

    if (sequence & SEQUENCE_LOCKTIME_TYPE_FLAG) != 0 {
        // Time-based relative lock-times are measured from the
        // smallest allowed timestamp of the block containing the
        // txout being spent, which is the median time past of the
        // block prior.
        //
        // https://github.com/bitcoin/bitcoin/blob/712a2b5453cdf2568fece94b969d6e0923b6ba16/src/consensus/tx_verify.cpp#L74
        let lock_time = value * 512;
        let absolute_lock_time = *input.previous_output.median_time_past + lock_time;
        if absolute_lock_time > median_time_past {
            println!("{:?}", input.previous_output);
            return Result::Err(
                format!(
                    "Relative time-based lock time is not respected: current MTP: {}, outpoint MTP: {}, lock time: {} seconds",
                    median_time_past,
                    *input.previous_output.median_time_past,
                    lock_time
                )
            );
        }
    } else {
        let absolute_lock_time = *input.previous_output.block_height + value;
        if absolute_lock_time > block_height {
            return Result::Err(
                format!(
                    "Relative block-based lock time is not respected: current height: {}, outpoint height: {}, lock time: {} blocks",
                    block_height,
                    *input.previous_output.block_height,
                    value
                )
            );
        }
    }

    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{TxIn, OutPoint, TxOut};
    use utils::hex::{from_hex, hex_to_hash_rev};
    use super::{validate_absolute_locktime, validate_relative_locktime};

    // TODO: tests for invalid relative locktime

    #[test]
    fn test_relative_locktime_disabled() {
        let input = TxIn {
            script: @from_hex(""),
            sequence: 0xffffffff, // Final, relative locktime disabled
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 100, ..Default::default() },
                block_height: 100,
                median_time_past: 1600000000,
                is_coinbase: false,
            },
            witness: array![].span(),
        };
        validate_relative_locktime(@input, 100, 1600000000).unwrap();
    }

    #[test]
    fn test_relative_locktime_enabled_block_height() {
        // txid 62fb5ecd3f022a2f09b73723b56410db0545923516b611013aed5218e4979322
        // input 0
        // note: only relevant fields are initialized
        let input = TxIn {
            script: @from_hex(""),
            sequence: 144,
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 188442, ..Default::default() },
                block_height: 603018,
                median_time_past: 1573324462,
                is_coinbase: false,
            },
            witness: array![].span(),
        };
        validate_relative_locktime(@input, 603164, 1573401225).unwrap();
    }

    #[test]
    fn test_relative_locktime_enabled_block_time() {
        // txid 12fa403cb22bf08c4c5542cc00673495a0c54c9cc8181bea850a12d40d7593a2
        // input 0
        // note: only relevant fields are initialized
        let input = TxIn {
            script: @from_hex(""),
            sequence: 4194311,
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 13671, ..Default::default() },
                block_height: 603434,
                median_time_past: 1573549241,
                is_coinbase: false,
            },
            witness: array![].span(),
        };
        validate_relative_locktime(@input, 603450, 1573555667).unwrap();
    }

    #[test]
    fn test_relative_locktime_block_height_lt_relative_locktime() {
        let input = TxIn {
            script: @from_hex(""),
            sequence: 144, // Lower sequence number with locktime enabled (block-based locktime)
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 188442, ..Default::default() },
                block_height: 603018, // Initial block height
                median_time_past: 1573324462,
                is_coinbase: false,
            },
            witness: array![].span(),
        };

        // Pass a lower block height than required by the relative locktime
        let block_height = 603019;
        let block_time = 1573401225;
        let result = validate_relative_locktime(@input, block_height, block_time);
        result.unwrap_err();
    }

    #[test]
    fn test_relative_locktime_block_time_lt_relative_locktime() {
        // txid 12fa403cb22bf08c4c5542cc00673495a0c54c9cc8181bea850a12d40d7593a2
        // input 0
        // note: only relevant fields are initialized
        let input = TxIn {
            script: @from_hex(""),
            sequence: 4194311, // Time-based relative locktime (0x400007 = SEQUENCE_LOCKTIME_TYPE_FLAG + value)
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 13671, ..Default::default() },
                block_height: 603434,
                median_time_past: 1573549241, // Initial block time
                is_coinbase: false,
            },
            witness: array![].span(),
        };

        // Pass a lower block_time than required by the relative locktime
        let block_height = 603450;
        let block_time = 1573549250;

        // This should fail because the current block time does not satisfy the relative locktime
        let result = validate_relative_locktime(@input, block_height, block_time);
        result.unwrap_err();
    }

    #[test]
    fn test_relative_locktime_enabled_lt_relative_locktime() {
        let input = TxIn {
            script: @from_hex(""),
            sequence: 144, // Relative locktime enabled (no SEQUENCE_LOCKTIME_DISABLE_FLAG)
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 0,
                data: TxOut { value: 100, ..Default::default() },
                block_height: 100, // Previous block height
                median_time_past: 1600000000, // Previous block time
                is_coinbase: false,
            },
            witness: array![].span(),
        };

        let current_block_height = 100;
        let current_block_time = 1600000000;

        // This should fail because relative locktime is enabled and the conditions do not satisfy
        let result = validate_relative_locktime(@input, current_block_height, current_block_time);
        result.unwrap_err();
    }


    #[test]
    fn test_absolute_locktime_block_height() {
        // Absolute locktime: block height
        // Transaction should be invalid when current block height is less than locktime
        validate_absolute_locktime(500000, 500000, 0).unwrap_err();

        // Transaction should be valid when current block height is equal to or greater than
        // locktime
        validate_absolute_locktime(500000, 500001, 0).unwrap();
    }

    #[test]
    fn test_absolute_locktime_block_time() {
        // Transaction should be invalid when current block time is not greater than locktime
        validate_absolute_locktime(1600000000, 0, 1600000000).unwrap_err();

        // Transaction should be valid when current block time is equal to or greater than locktime
        validate_absolute_locktime(1600000000, 0, 1600000001).unwrap();
    }
}
