use crate::types::transaction::Transaction;

/// Validate a transaction input. If relative locktime is enabled,
/// ensure the input's locktime is respected.
pub fn validate_input(
    tx: @Transaction, input_index: usize, block_height: u32, block_time: u32
) -> Result<(), ByteArray> {
    // Get the input we are validating
    let tx_input = *tx.inputs[input_index];

    // Check if the input has a relative locktime set (sequence number < 0xFFFFFFFF).
    // In Bitcoin, 0xFFFFFFFF sequence means the input is not subject to locktime.
    if tx_input.sequence < 0xFFFFFFFF {
        // Check if the locktime is based on block height or block time.
        // If the transaction lock_time is below 500 million, it's a block height lock,
        // otherwise it's a block time lock.
        let locktime_threshold = 500_000_000;
        let locktime = *tx.lock_time;

        // Check if locktime is based on block height
        if locktime < locktime_threshold {
            if block_height < locktime {
                return Result::Err(
                    format!(
                        "[validate_input] Transaction is not yet valid due to block height. Current: {}, Required: {}",
                        block_height,
                        locktime
                    )
                );
            }
        } else {
            // Check if locktime is based on block time
            if block_time < locktime {
                return Result::Err(
                    format!(
                        "[validate_input] Transaction is not yet valid due to block time. Current: {}, Required: {}",
                        block_time,
                        locktime
                    )
                );
            }
        }
    }

    // Return success if all validations passed
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
    use crate::utils::hex::from_hex;
    use super::{validate_input};


    #[test]
    fn test_validate_input() {
        // Setup transaction with one input and one output
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
                        txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                            .into(),
                        vout: 0x00000000,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
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
            lock_time: 100, // Set lock_time to a value to be tested against block height/time
        };

        // Set block height and block time
        let block_height = 101;
        let block_time = 1_600_000_000;

        // Validate the transaction input at index 0
        let result = validate_input(@tx, 0, block_height, block_time);

        // Ensure the validation passes (no locktime constraints violated)
        assert!(result.is_ok());
    }
}

