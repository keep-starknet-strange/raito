//! Coinbase validation helpers.
//!
//! https://learnmeabitcoin.com/technical/mining/coinbase-transaction/

use crate::types::transaction::Transaction;
use crate::utils::{bit_shifts::shr, hash::Hash, hex::from_hex};

const BIP_141_BLOCK_HEIGHT: u32 = 481_824;

/// Validates coinbase transaction.
pub fn validate_coinbase(
    tx: @Transaction, total_fees: u64, block_height: u32, _wtxid_commitment: Hash,
) -> Result<(), ByteArray> {
    // Validate the coinbase input
    // Ensure there is exactly one coinbase input
    assert((*tx.inputs).len() == 1, 'Input count should be 1');

    // Ensure the input's vout is 0xFFFFFFFF
    assert(*tx.inputs[0].previous_output.vout == 0xFFFFFFFF, 'vout should be 0xFFFFFFFF');

    // Ensure the input's TXID is zero
    assert(*tx.inputs[0].previous_output.txid == Default::default(), 'txid should be 0');

    // Validate the outputs' amounts
    // Sum up the total amount of all outputs of the coinbase transaction
    let mut total_output_amount = 0;
    for output in *tx.outputs {
        total_output_amount += *output.value;
    };

    // Ensure the total output amount is at most the block reward + TX fees
    let block_reward = compute_block_reward(block_height);
    assert(total_output_amount <= total_fees + block_reward, 'total output > block rwd + fees');

    // TODO: validate BIP-34 sig script

    // validate BIP-141 witness field
    if block_height >= BIP_141_BLOCK_HEIGHT {
        let witness_reserved_value: ByteArray =
            "0000000000000000000000000000000000000000000000000000000000000000";
        let witness = *tx.inputs[0].witness;

        assert(witness[0].len() == 32, 'Wrong witness length');
        assert(witness[0] == @from_hex(witness_reserved_value), 'Wrong coinbase witness');
    }

    // TODO: validate BIP-141 segwit output

    Result::Ok(())
}

/// Return BTC reward in SATS
fn compute_block_reward(block_height: u32) -> u64 {
    shr(5000000000_u64, (block_height / 210000_u32))
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{TxIn, TxOut, Transaction, OutPoint};
    use crate::utils::hex::from_hex;
    use super::{compute_block_reward, validate_coinbase};

    // Ref implementation here:
    // https://github.com/bitcoin/bitcoin/blob/0f68a05c084bef3e53e3f549c403bc90b1db319c/src/test/validation_tests.cpp#L24
    #[test]
    fn test_compute_block_reward() {
        let max_halvings: u32 = 64;
        let reward_initial: u256 = 5000000000;
        let mut block_height: u32 = 210_000; // halving every 210 000 blocks
        // Before first halving
        let genesis_halving_reward = compute_block_reward(0);
        assert_eq!(genesis_halving_reward, reward_initial.try_into().unwrap());

        // Before first halving
        assert_eq!(compute_block_reward(209999), reward_initial.try_into().unwrap());

        // First halving
        let first_halving_reward = compute_block_reward(block_height);
        assert_eq!(first_halving_reward, reward_initial.try_into().unwrap() / 2);

        // Second halving
        assert_eq!(compute_block_reward(420000), 1250000000); // 12.5 BTC

        // Third halving
        assert_eq!(compute_block_reward(630000), 625000000); // 6.25

        // Just after fourth halving
        assert_eq!(compute_block_reward(840001), 312500000); // 3.125

        // Fight halving
        assert_eq!(compute_block_reward(1050000), 156250000); // 1.5625

        // Seventh halving
        assert_eq!(compute_block_reward(1470000), 39062500); // 0.390625

        // Ninth halving
        assert_eq!(compute_block_reward(1890000), 9765625); // 0.09765625

        // Tenth halving
        let tenth_reward = compute_block_reward(10 * block_height);
        assert_eq!(tenth_reward, 4882812); // 0.048828125

        let last_reward = compute_block_reward(max_halvings * block_height);
        assert_eq!(last_reward, 0);
    }


    #[test]
    #[should_panic(expected: ('Input count should be 1',))]
    fn test_validate_coinbase_with_multiple_input() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                },
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut { value: 5000000000_u64, pk_script: @from_hex(""), cached: false, }
            ]
                .span(),
            lock_time: 0
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }

    #[test]
    #[should_panic(expected: ('vout should be 0xFFFFFFFF',))]
    fn test_validate_coinbase_with_wrong_vout() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0_u256.into(),
                        vout: 0x1_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut { value: 5000000000_u64, pk_script: @from_hex(""), cached: false, }
            ]
                .span(),
            lock_time: 0
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }

    #[test]
    #[should_panic(expected: ('txid should be 0',))]
    fn test_validate_coinbase_with_txid_not_zero() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0x2_u256.into(),
                        vout: 0xFFFFFFFF_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut { value: 5000000000_u64, pk_script: @from_hex(""), cached: false, }
            ]
                .span(),
            lock_time: 0
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@tx, total_fees.into(), block_height, Default::default()).unwrap();
    }
    #[test]
    #[should_panic(expected: ('total output > block rwd + fees',))]
    fn test_validate_coinbase_outputs_amount() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut { value: 5000000000_u64, pk_script: @from_hex(""), cached: false, }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 0_u64;
        let block_height = 856_563;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }

    #[test]
    fn test_validate_coinbase() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: TxOut { value: 0_64, ..Default::default(), },
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![
                        from_hex("0000000000000000000000000000000000000000000000000000000000000000")
                    ]
                        .span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut { value: 5000000000_u64, pk_script: @from_hex(""), cached: false, }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 5000000000_u64;
        let block_height = 856_563;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }

    #[test]
    fn test_validate_coinbase_block170() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex("04ffff001d0102"),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0x0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: Default::default(),
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
                    value: 5000000000_u64,
                    pk_script: @from_hex(
                        "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 0_u64;
        let block_height = 170;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }

    #[test]
    #[should_panic(expected: ('Wrong witness length',))]
    fn test_validate_coinbase_witness_with_less_than_32_bytes() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex("04ffff001d0102"),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0x0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![from_hex("")].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0_u64,
                    pk_script: @from_hex(
                        "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 0_u64;
        let block_height = 500_000;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }
    #[test]
    #[should_panic(expected: ('Wrong coinbase witness',))]
    fn test_validate_coinbase_witness_with_wrong_witness() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex("04ffff001d0102"),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0x0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![
                        from_hex("400d00000000e000000000000000000000000e00000000000000000000000000")
                    ]
                        .span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0_u64,
                    pk_script: @from_hex(
                        "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 0_u64;
        let block_height = 500_000;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }
    #[test]
    fn test_validate_coinbase_witness() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex("04ffff001d0102"),
                    sequence: 4294967295,
                    previous_output: OutPoint {
                        txid: 0x0_u256.into(),
                        vout: 0xffffffff_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![
                        from_hex("0000000000000000000000000000000000000000000000000000000000000000")
                    ]
                        .span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0_u64,
                    pk_script: @from_hex(
                        "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let total_fees = 0_u64;
        let block_height = 500_000;

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap();
    }
}
