//! Coinbase validation helpers.
//!
//! https://learnmeabitcoin.com/technical/mining/coinbase-transaction/

use crate::types::transaction::{Transaction, TxIn};
use crate::utils::{bit_shifts::shr, hash::Digest};

const BIP_34_BLOCK_HEIGHT: u32 = 227_836;
const BIP_141_BLOCK_HEIGHT: u32 = 481_824;

/// Validates coinbase transaction.
pub fn validate_coinbase(
    tx: @Transaction, total_fees: u64, block_height: u32, _wtxid_commitment: Digest,
) -> Result<(), ByteArray> {
    // Ensure there is exactly one coinbase input
    if (*tx.inputs).len() != 1 {
        return Result::Err("Input count must be 1");
    }

    validate_coinbase_input(tx.inputs[0], block_height)?;

    // Validate the outputs' amounts
    // Sum up the total amount of all outputs of the coinbase transaction
    let mut total_output_amount = 0;
    for output in *tx.outputs {
        total_output_amount += *output.value;
    };

    // Ensure the total output amount is at most the block reward + TX fees
    let block_reward = compute_block_reward(block_height);
    assert(total_output_amount <= total_fees + block_reward, 'total output > block rwd + fees');

    // TODO: validate BIP-141 segwit output

    Result::Ok(())
}

/// Validates first and the only coinbase input
fn validate_coinbase_input(input: @TxIn, block_height: u32) -> Result<(), ByteArray> {
    // Ensure the input's vout is 0xFFFFFFFF
    if *input.previous_output.vout != 0xFFFFFFFF {
        return Result::Err("Previous vout must be 0xFFFFFFFF");
    }

    // Ensure the input's TXID is zero
    if *input.previous_output.txid != Default::default() {
        return Result::Err("Previous txid must be zero");
    }

    // validate BIP-34 sig script
    if block_height >= BIP_34_BLOCK_HEIGHT {
        validate_coinbase_sig_script(*input.script, block_height)?;
    }

    // validate BIP-141 witness field
    if block_height >= BIP_141_BLOCK_HEIGHT {
        validate_coinbase_witness(*input.witness)?;
    }

    Result::Ok(())
}

#[inline]
/// Validate coinbase sig script (BIP-34)
fn validate_coinbase_sig_script(script: @ByteArray, block_height: u32) -> Result<(), ByteArray> {
    let script_len = script.len();

    // Ensure byte length greater than 2 and less 100
    if script_len < 2 || script_len > 100 {
        return Result::Err("Bad sig script length");
    }

    // Ensure script starts with the current block height
    //
    // First byte is number of bytes in the number (will be 0x03 on mainnet for the next
    // 150 or so years with 223-1 blocks), following bytes are little-endian representation
    // of the number
    if script[0] != 3 {
        return Result::Err("Invalid number of bytes");
    }

    let result = script[1].into() + script[2].into() * 256_u32 + script[3].into() * 65536_u32;
    if result != block_height.into() {
        return Result::Err("Wrong block height");
    }

    Result::Ok(())
}

#[inline]
/// Validate coinbase witness
fn validate_coinbase_witness(witness: Span<ByteArray>) -> Result<(), ByteArray> {
    if witness.len() != 1 {
        return Result::Err("Expected single witness item");
    }

    // check witness value
    if witness[0] != @"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0" {
        return Result::Err("Wrong coinbase witness");
    }

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
    use super::{
        compute_block_reward, validate_coinbase, validate_coinbase_input,
        validate_coinbase_sig_script, validate_coinbase_witness
    };

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

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_with_wrong_vout() {
        let input = TxIn {
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
        };
        validate_coinbase_input(@input, 1).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_with_txid_not_zero() {
        let input = TxIn {
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
        };
        validate_coinbase_input(@input, 1).unwrap_err();
    }

    #[test]
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

        validate_coinbase(@tx, total_fees, block_height, Default::default()).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "03f3110d04e202bb667c204d41524120506f6f6c207c204d61646520696e2055534120f09f87baf09f87b8207c2028763033313932342976649b3c094f135bf4b83108c14ea85f129c98e20e0000000000ffffffff"
                    ),
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
    fn test_validate_coinbase_BIP_34_sig_script_less_than_2() {
        let script = from_hex("");
        validate_coinbase_sig_script(@script, 856563).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_BIP_34_sig_script_greater_than_100() {
        let script = from_hex(
            "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
        );
        validate_coinbase_sig_script(@script, 856563).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_BIP_34_sig_script_with_wrong_block_height() {
        let script = from_hex(
            "03aa68060004c345815704451c591c0c60ef5b577b690000000000000a2020202020200a2f72657365727665642f"
        );
        validate_coinbase_sig_script(@script, 856563).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_BIP_34_sig_script_with_Invalid_number_of_bytes() {
        let script = from_hex(
            "04aa68060004c345815704451c591c0c60ef5b577b690000000000000a2020202020200a2f72657365727665642f"
        );
        validate_coinbase_sig_script(@script, 856563).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_BIP_34_sig_script() {
        let script = from_hex(
            "03aa68060004c345815704451c591c0c60ef5b577b690000000000000a2020202020200a2f72657365727665642f"
        );
        validate_coinbase_sig_script(@script, 420_010).unwrap();
    }

    #[test]
    fn test_validate_coinbase_witness_with_less_than_32_bytes() {
        let witness = array![from_hex("")].span();
        validate_coinbase_witness(witness).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_witness_with_more_than_one_element() {
        let witness = array![
            from_hex("0000000000000000000000000000000000000000000000000000000000000000"),
            from_hex("0000000000000000000000000000000000000000000000000000000000000000")
        ]
            .span();
        validate_coinbase_witness(witness).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_witness_with_wrong_witness() {
        let witness = array![
            from_hex("400d00000000e000000000000000000000000e00000000000000000000000000")
        ]
            .span();
        validate_coinbase_witness(witness).unwrap_err();
    }

    #[test]
    fn test_validate_coinbase_witness() {
        let witness = array![
            from_hex("0000000000000000000000000000000000000000000000000000000000000000")
        ]
            .span();
        validate_coinbase_witness(witness).unwrap();
    }
}
