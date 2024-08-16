use super::codec::Encode;
use super::merkle_tree::merkle_root;
use super::utils::{double_sha256_byte_array, shl, shr, Hash};
use super::state::{Block, ChainState, Transaction, UtreexoState, UtreexoSet, TxIn, TxOut, OutPoint};

const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;

#[generate_trait]
pub impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        validate_timestamp(@self, @block)?;
        let (total_fees, merkle_root) = fee_and_merkle_root(@block)?;
        validate_coinbase(@block, total_fees, self.block_height)?;

        let prev_timestamps = next_prev_timestamps(@self, @block);
        let (current_target, epoch_start_time) = adjust_difficulty(@self, @block);
        let total_work = compute_total_work(self.total_work, current_target);
        let block_height = self.block_height + 1;
        let best_block_hash = block_hash(@self, @block, merkle_root)?;

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(@block, current_target)?;

        let utreexo_state = UtreexoState { roots: [].span() };

        Result::Ok(
            ChainState {
                block_height,
                total_work,
                best_block_hash,
                current_target,
                epoch_start_time,
                prev_timestamps,
                utreexo_state
            }
        )
    }
}

#[generate_trait]
pub impl TransactionValidatorImpl of TransactionValidator {
    // marker, flag, and witness fields in segwit transactions are not included
    // this means txid computation is the same for legacy and segwit tx
    fn txid(self: @Transaction) -> Hash {
        // append version (4 bytes)
        let mut hash256_input: ByteArray = "";
        hash256_input.append_word_rev((*self.version).into(), 4);

        // append inputs count (1 byte in our example) - TODO : use Encode<Span<TxIn>> once
        // implemented
        hash256_input.append_word_rev((*self.inputs).len().into(), 1);

        // append inputs - TODO : this is also included in Encode<Span<TxIn>>
        let mut inputs: Span<TxIn> = *self.inputs;
        while let Option::Some(txin) = inputs.pop_front() {
            // append txid (32 bytes)
            let txid: u256 = (*(txin.previous_output.txid)).into();
            hash256_input.append_word_rev(txid.low.into(), 16);
            hash256_input.append_word_rev(txid.high.into(), 16);

            // append VOUT (4 bytes)
            hash256_input.append_word_rev((*txin.previous_output.vout).into(), 4);

            // append ScriptSig size (1 byte in our example)
            hash256_input.append_word_rev((*txin.script).len().into(), 1);

            // append ScriptSig (variable size)
            let rev_script = (*txin.script).rev();
            hash256_input.append(@rev_script);

            // append Sequence (4 bytes)
            hash256_input.append_word_rev((*txin.sequence).into(), 4);
        };

        // append outputs count (1 byte in our example) - TODO : use Encode<Span<TxOut>> once
        // implemented
        hash256_input.append_word_rev((*self.outputs).len().into(), 1);

        // append outputs -  TODO this is also included in Encode<Span<TxOut>>
        let mut outputs: Span<TxOut> = *self.outputs;
        while let Option::Some(txout) = outputs.pop_front() {
            // append amount (8 bytes)
            hash256_input.append_word_rev((*txout.value).into(), 8);

            // append ScriptPubKey size (1 byte in our exmaple)
            hash256_input.append_word_rev((*txout.pk_script).len().into(), 1);

            // append ScriptPubKey (variable size)
            let rev_pk_script = (*txout.pk_script).rev();
            hash256_input.append(@rev_pk_script);
        };

        // append locktime (4 bytes)
        hash256_input.append_word_rev((*self.lock_time).into(), 4);

        // Compute double sha256 and return the Hash result
        double_sha256_byte_array(@hash256_input)
    }

    fn fee(self: @Transaction) -> u64 {
        let mut total_input_amount = 0;
        let mut total_output_amount = 0;
        // Inputs of a transaction
        let inputs = *self.inputs;
        // Outputs of a transaction
        let outputs = *self.outputs;

        for input in inputs {
            let amount = *input.previous_output.amount;
            total_input_amount += amount;
        };

        for output in outputs {
            let value = *output.value;
            total_output_amount += value;
        };

        let tx_fee = total_input_amount - total_output_amount;
        tx_fee
    }
}

fn block_hash(self: @ChainState, block: @Block, merkle_root: Hash) -> Result<Hash, ByteArray> {
    // TODO: implement
    Result::Ok(Default::default())
}

fn validate_proof_of_work(target: u256, block_hash: Hash) -> Result<(), ByteArray> {
    if block_hash.into() <= target {
        Result::Ok(())
    } else {
        Result::Err(
            "Insufficient proof of work. Expected block hash {chain_state.best_block_hash} to be less than or equal to {target}."
        )
    }
}

fn validate_timestamp(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    if block.header.time > (*self.prev_timestamps).at((*self.prev_timestamps).len() - 6) {
        Result::Ok(())
    } else {
        Result::Err("Median time is greater than or equal to block's timestamp")
    }
}

fn next_prev_timestamps(self: @ChainState, block: @Block) -> Span<u32> {
    let mut prev_timestamps = *self.prev_timestamps;
    prev_timestamps.pop_front().unwrap(); //keep only 10 most recent previous timestamps
    let mut timestamps: Array<u32> = array![];
    timestamps.append_span(prev_timestamps);
    timestamps.append(*block.header.time);
    timestamps.span()
}

fn compute_total_work(current_total_work: u256, target: u256) -> u256 {
    current_total_work + compute_work_from_target(target)
}

// Need to compute 2**256 / (target+1), but we can't represent 2**256
// as it's too large for an u256. However, as 2**256 is at least as large
// as target+1, it is equal to ((2**256 - target - 1) / (target+1)) + 1,
// or ~target / (target+1) + 1.
fn compute_work_from_target(target: u256) -> u256 {
    (~target / (target + 1_u256)) + 1_u256
}

fn adjust_difficulty(self: @ChainState, block: @Block) -> (u256, u32) {
    // TODO: implement
    (*self.current_target, *self.epoch_start_time)
}

// Helper functions
pub fn bits_to_target(bits: u32) -> Result<u256, ByteArray> {
    // Extract exponent and mantissa
    let exponent: u32 = (bits / 0x1000000);
    let mantissa: u32 = bits & 0x00FFFFFF;

    // Check if mantissa is valid (should be less than 0x1000000)
    if mantissa > 0x7FFFFF && exponent != 0 {
        return Result::Err("Invalid mantissa");
    }

    // Calculate the full target value
    let mut target: u256 = mantissa.into();

    if exponent == 0 {
        // Special case: exponent 0 means we use the mantissa as-is
        return Result::Ok(target);
    } else if exponent <= 3 {
        // For exponents 1, 2, and 3, divide by 256^(3 - exponent) i.e right shift
        let shift = 8 * (3 - exponent);
        target = shr(target, shift);
    } else {
        let shift = 8 * (exponent - 3);
        target = shl(target, shift);
    }

    // Ensure the target doesn't exceed the maximum allowed value
    if target > MAX_TARGET {
        return Result::Err("Target exceeds maximum");
    }

    Result::Ok(target)
}

// TODO: potentially not necessary?
pub fn target_to_bits(target: u256) -> Result<u32, ByteArray> {
    if target == 0 {
        return Result::Err("Target is zero");
    }

    if target > MAX_TARGET {
        return Result::Err("Exceeds max value");
    }

    // Find the most significant byte
    let mut size: u32 = 32;
    let mut compact = target;

    // Count leading zero bytes by finding the first non-zero byte
    while size > 1 && shr(compact, (size - 1) * 8) == 0 {
        size -= 1;
    };

    // Extract mantissa (most significant 3 bytes)
    let mut mantissa: u32 = shr(compact, (size - 3) * 8).try_into().unwrap();

    // Normalize
    if mantissa > 0x7fffff {
        mantissa = (mantissa + 0x80) / 0x100;
        size += 1;
    }

    // Ensure the mantissa is only 3 bytes
    mantissa = mantissa & 0xffffff;

    // Check size doesn't exceed maximum
    if size > 34 {
        return Result::Err("Overflow");
    }

    // Convert size to u256
    let size_u256: u256 = size.into();

    // Combine size and mantissa
    let result: u32 = (shl(size_u256, 24_u32) + mantissa.into()).try_into().unwrap();

    Result::Ok(result)
}

fn validate_bits(block: @Block, target: u256) -> Result<(), ByteArray> {
    if *block.header.bits == target_to_bits(target)? {
        Result::Ok(())
    } else {
        Result::Err("Block header bits do not match target")
    }
}

fn fee_and_merkle_root(block: @Block) -> Result<(u64, Hash), ByteArray> {
    let mut txids: Array<Hash> = array![];
    let mut total_fee = 0;

    let mut i = 0;
    while (i < (*block.txs).len()) {
        let tx = block.txs[i];
        txids.append(tx.txid());
        // skipping the coinbase transaction
        if (i != 0) {
            total_fee += tx.fee();
        }
        i += 1;
    };

    Result::Ok((total_fee, merkle_root(ref txids)))
}

fn validate_coinbase(block: @Block, total_fees: u64, block_height: i32) -> Result<(), ByteArray> {
    let tx = block.txs[0];

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

    Result::Ok(())
}

// Return BTC reward in SATS
fn compute_block_reward(block_height: i32) -> u64 {
    let block_height_unsigned: u32 = if (block_height < 0) {
        0
    } else {
        block_height.try_into().unwrap()
    };
    shr(5000000000_u64, (block_height_unsigned / 210000_u32))
}


#[cfg(test)]
mod tests {
    use raito::state::{Header, Transaction, TxIn, TxOut, OutPoint};
    use raito::utils::Hash;
    use raito::test_utils::from_hex;
    use super::{
        validate_timestamp, validate_proof_of_work, compute_block_reward, compute_total_work,
        compute_work_from_target, shr, shl, Block, ChainState, UtreexoState, next_prev_timestamps,
        TransactionValidatorImpl, validate_coinbase, bits_to_target, target_to_bits
    };

    #[test]
    fn test_validate_timestamp() {
        let mut chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1_u256.into(),
            current_target: 1,
            epoch_start_time: 1,
            prev_timestamps: array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].span(),
            utreexo_state: UtreexoState { roots: array![].span() },
        };
        let mut block = Block {
            header: Header { version: 1, time: 12, nonce: 1, bits: 1 },
            txs: ArrayTrait::new().span(),
        };

        // new timestamp is greater than the last timestamp
        let result = validate_timestamp(@chain_state, @block);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is strictly greater than the median of the last 11 timestamps
        block.header.time = 7;
        let result = validate_timestamp(@chain_state, @block);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is equal to the median of the last 11 timestamps
        block.header.time = 6;
        let result = validate_timestamp(@chain_state, @block);
        assert!(result.is_err(), "Median time is greater than block's timestamp");
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
                        txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                            .into(),
                        vout: 0x00000000,
                        txo_index: 0,
                        amount: 100
                    },
                    witness: @from_hex("")
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 90,
                    pk_script: @from_hex(
                        "ac4cd86c7e4f702ac7d5debaf126068a3b30b7c1212c145fdfa754f59773b3aae71484a22f30718d37cd74f325229b15f7a2996bf0075f90131bf5c509fe621aae0441"
                    ),
                }
            ]
                .span(),
            lock_time: 0
        };

        let fee = TransactionValidatorImpl::fee(@tx);
        assert_eq!(fee, 10);
    }

    #[test]
    fn test_compute_work_from_target1() {
        let expected_work = 0x0100010001;
        let target: u256 = 0x00000000ffff0000000000000000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target2() {
        let expected_work = 0x26d946e509ac00026d;
        let target: u256 = 0x00000000000000000696f4000000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target3() {
        let expected_work = 0xe10005c64415f04ef3e387b97db388404db9fdfaab2b1918f6783471d;
        let target: u256 = 0x12345600;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target4() {
        let expected_work = 0x1c040c95a099201bcaf85db4e7f2e21e18707c8d55a887643b95afb2f;
        let target: u256 = 0x92340000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target5() {
        let expected_work = 0x21809b468faa88dbe34f;
        let target: u256 = 0x00000000000000000007a4290000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_validate_proof_of_work() {
        // target is less than prev block hash
        let result = validate_proof_of_work(0, 1_u256.into());
        assert!(result.is_err(), "Expect target less than prev block hash");

        // target is greater than prev block hash
        let result = validate_proof_of_work(2, 1_u256.into());
        assert!(result.is_ok(), "Expect target gt prev block hash");

        // target is equal to prev block hash
        let result = validate_proof_of_work(1, 1_u256.into());
        assert!(result.is_ok(), "Expect target equal to prev block hash");

        // block prev block hash is greater than target
        let result = validate_proof_of_work(1, 2_u256.into());
        assert!(result.is_err(), "Expect prev block hash gt target");

        // block prev block hash is less than target
        let result = validate_proof_of_work(10, 9_u256.into());
        assert!(result.is_ok(), "Expect prev block hash lt target");
    }

    // Ref implementation here:
    // https://github.com/bitcoin/bitcoin/blob/0f68a05c084bef3e53e3f549c403bc90b1db319c/src/test/validation_tests.cpp#L24
    #[test]
    fn test_compute_block_reward() {
        let max_halvings: i32 = 64;
        let reward_initial: u256 = 5000000000;
        let mut block_height: i32 = 210_000; // halving every 210 000 blocks
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
    fn test_next_prev_timstamps() {
        let chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1_u256.into(),
            current_target: 1,
            epoch_start_time: 1,
            prev_timestamps: array![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].span(),
            utreexo_state: UtreexoState { roots: array![].span() },
        };
        let block = Block {
            header: Header { version: 1, time: 12, nonce: 1, bits: 1 },
            txs: ArrayTrait::new().span(),
        };
        let next_prev_timestamps = next_prev_timestamps(@chain_state, @block);
        assert_eq!(next_prev_timestamps.len(), 11);
        assert_eq!(*next_prev_timestamps[0], 1);
        assert_eq!(*next_prev_timestamps[1], 2);
        assert_eq!(*next_prev_timestamps[2], 3);
        assert_eq!(*next_prev_timestamps[3], 4);
        assert_eq!(*next_prev_timestamps[4], 5);
        assert_eq!(*next_prev_timestamps[5], 6);
        assert_eq!(*next_prev_timestamps[6], 7);
        assert_eq!(*next_prev_timestamps[7], 8);
        assert_eq!(*next_prev_timestamps[8], 9);
        assert_eq!(*next_prev_timestamps[9], 10);
        assert_eq!(*next_prev_timestamps[10], 12);
    }

    #[test]
    fn test_target_to_bits() {
        let target = 486604799_u256;
        let bits = target_to_bits(target).unwrap();
        assert_eq!(bits, 69009663);
    }

    #[test]
    #[should_panic(expected: ('Input count should be 1',))]
    fn test_validate_coinbase_with_multiple_input() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231006505_u32, bits: 1, nonce: 2083236893_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0_u256.into(),
                                vout: 0xffffffff_u32,
                                txo_index: 0,
                                amount: 0_64
                            },
                            witness: @from_hex("")
                        },
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0_u256.into(),
                                vout: 0xffffffff_u32,
                                txo_index: 0,
                                amount: 0_64
                            },
                            witness: @from_hex("")
                        }
                    ]
                        .span(),
                    outputs: array![TxOut { value: 5000000000_u64, pk_script: @from_hex(""), }]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@block, total_fees, block_height).unwrap();
    }

    #[test]
    #[should_panic(expected: ('vout should be 0xFFFFFFFF',))]
    fn test_validate_coinbase_with_wrong_vout() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231006505_u32, bits: 1, nonce: 2083236893_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0_u256.into(), vout: 0x1_u32, txo_index: 0, amount: 0_64
                            },
                            witness: @from_hex("")
                        }
                    ]
                        .span(),
                    outputs: array![TxOut { value: 5000000000_u64, pk_script: @from_hex(""), }]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@block, total_fees, block_height).unwrap();
    }

    #[test]
    #[should_panic(expected: ('txid should be 0',))]
    fn test_validate_coinbase_with_txid_not_zero() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231006505_u32, bits: 1, nonce: 2083236893_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0x2_u256.into(),
                                vout: 0xFFFFFFFF_u32,
                                txo_index: 0,
                                amount: 0_64
                            },
                            witness: @from_hex("")
                        }
                    ]
                        .span(),
                    outputs: array![TxOut { value: 5000000000_u64, pk_script: @from_hex(""), }]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };
        let total_fees = 5000000000_u64;
        let block_height = 1;

        validate_coinbase(@block, total_fees.into(), block_height).unwrap();
    }
    #[test]
    #[should_panic(expected: ('total output > block rwd + fees',))]
    fn test_validate_coinbase_outputs_amount() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231006505_u32, bits: 1, nonce: 2083236893_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0_u256.into(),
                                vout: 0xffffffff_u32,
                                txo_index: 0,
                                amount: 0_64
                            },
                            witness: @from_hex("")
                        }
                    ]
                        .span(),
                    outputs: array![TxOut { value: 5000000000_u64, pk_script: @from_hex(""), }]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };

        let total_fees = 0_u64;
        let block_height = 856_563;

        validate_coinbase(@block, total_fees, block_height).unwrap();
    }

    #[test]
    fn test_validate_coinbase() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231006505_u32, bits: 1, nonce: 2083236893_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(""),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0_u256.into(),
                                vout: 0xffffffff_u32,
                                txo_index: 0,
                                amount: 0_64
                            },
                            witness: @from_hex("")
                        }
                    ]
                        .span(),
                    outputs: array![TxOut { value: 5000000000_u64, pk_script: @from_hex(""), }]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };

        let total_fees = 5000000000_u64;
        let block_height = 856_563;

        validate_coinbase(@block, total_fees, block_height).unwrap();
    }

    #[test]
    fn test_validate_coinbase_block170() {
        let block = Block {
            header: Header { version: 1_u32, time: 1231731025_u32, bits: 0, nonce: 1889418792_u32 },
            txs: array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex("04ffff001d0102"),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0x0_u256.into(), vout: 0xffffffff_u32, txo_index: 0, amount: 0
                            },
                            witness: @""
                        }
                    ]
                        .span(),
                    outputs: array![
                        TxOut {
                            value: 5000000000_u64,
                            pk_script: @from_hex(
                                "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                            ),
                        }
                    ]
                        .span(),
                    lock_time: 0
                },
                Transaction {
                    version: 1,
                    is_segwit: false,
                    inputs: array![
                        TxIn {
                            script: @from_hex(
                                "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901"
                            ),
                            sequence: 4294967295,
                            previous_output: OutPoint {
                                txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                                    .into(),
                                vout: 0,
                                txo_index: 0,
                                amount: 5000000000_u64
                            },
                            witness: @""
                        }
                    ]
                        .span(),
                    outputs: array![
                        TxOut {
                            value: 1000000000_u64,
                            pk_script: @from_hex(
                                "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac"
                            ),
                        },
                        TxOut {
                            value: 4000000000_u64,
                            pk_script: @from_hex(
                                "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
                            ),
                        }
                    ]
                        .span(),
                    lock_time: 0
                }
            ]
                .span()
        };

        let total_fees = 0_u64;
        let block_height = 170;

        validate_coinbase(@block, total_fees, block_height).unwrap();
    }

    #[test]
    fn test_txid() {
        let tx: Transaction = Transaction {
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
                        txo_index: 0,
                        amount: 0_64 // set to 0 for the test
                    },
                    witness: @from_hex("")
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0x000000003b9aca00,
                    pk_script: @from_hex(
                        "ac4cd86c7e4f702ac7d5debaf126068a3b30b7c1212c145fdfa754f59773b3aae71484a22f30718d37cd74f325229b15f7a2996bf0075f90131bf5c509fe621aae0441"
                    ),
                },
                TxOut {
                    value: 0x00000000ee6b2800,
                    pk_script: @from_hex(
                        "aca312b456f643869b993fc0d4f9648b9bfa0b162ef8644474f9cc84fbddeae0b25c9a90a648b1d7ca2e48b1972e388ab61ebc538c0f84496b018adbdce193db110441"
                    ),
                }
            ]
                .span(),
            lock_time: 0
        };

        let txid: Hash = TransactionValidatorImpl::txid(@tx);
        assert_eq!(
            txid, 0x169e1e83e930853391bc6f35f605c6754cfead57cf8387639d3b4096c54f18f4_u256.into()
        );
    }
}
