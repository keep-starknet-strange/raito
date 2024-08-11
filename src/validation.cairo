use core::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};
use super::state::{Block, ChainState, Transaction, UtreexoState, TxIn, TxOut, OutPoint};
use super::merkle_tree::merkle_root;
use super::utils::{shl, shr};

const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;

#[generate_trait]
impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        validate_timestamp(@self, @block)?;

        let (total_fees, merkle_root) = fee_and_merkle_root(@block)?;

        validate_coinbase(@block, total_fees)?;

        let prev_timestamps = next_prev_timestamps(@self, @block);
        let (current_target, epoch_start_time) = adjust_difficulty(@self, @block);
        let total_work = compute_total_work(self.total_work, current_target);
        let block_height = self.block_height + 1;

        let best_block_hash = block_hash(@self, @block, merkle_root)?;

        validate_proof_of_work(current_target, best_block_hash)?;
        validate_bits(@block, current_target)?;

        Result::Ok(
            ChainState {
                block_height,
                total_work,
                best_block_hash,
                current_target,
                epoch_start_time,
                prev_timestamps,
                ..self,
            }
        )
    }
}

#[generate_trait]
pub impl TransactionValidatorImpl of TransactionValidator {
    // marker, flag, and witness fields in segwit transactions are not included
    // this means txid computation is the same for legacy and segwit tx
    fn txid(self: @Transaction) -> u256 {
        let version: felt252 = (*self.version).into();
        let inputs_count: felt252 = (*self.inputs).len().into();
        let inputs: Span<TxIn> = *self.inputs;
        let outputs_count: felt252 = (*self.outputs).len().into();
        let outputs: Span<TxOut> = *self.outputs;
        let locktime: felt252 = (*self.lock_time).into();

        // append version (1 byte)
        let mut sha256_input: ByteArray = "";
        sha256_input.append_word(version, 1);

        // append padding (3 bytes)
        let padding: felt252 = 0;
        sha256_input.append_word(padding, 3);

        // append inputs count
        sha256_input.append_word(inputs_count, 1);

        // append inputs
        let mut i = 0;
        // != instead of < to avoid range check builtin usage for comparison
        while i != inputs.len() {
            // append txid
            let txid: u256 = (*inputs[i]).previous_output.txid.into();
            let txid_high: felt252 = txid.high.into();
            let txid_low: felt252 = txid.low.into();
            sha256_input.append_word(txid_high, 16);
            sha256_input.append_word(txid_low, 16);

            // append VOUT
            let vout: felt252 = (*inputs[i]).previous_output.vout.into();
            sha256_input.append_word(vout, 4);

            // append ScriptSig size
            let scriptsig_size: felt252 = (*inputs[i]).script.len().into();
            sha256_input.append_word(scriptsig_size, 4);

            // append ScriptSig
            let script_sig: @ByteArray = (*inputs[i]).script;
            sha256_input.append(script_sig);

            // append Sequence
            let sequence: felt252 = (*inputs.at(i)).sequence.into();
            sha256_input.append_word(sequence, 4);

            i += 1;
        };

        // append outputs count
        sha256_input.append_word(outputs_count, 1);

        // append outputs
        let mut i = 0;
        while i != outputs.len() {
            // append amount
            let amount: felt252 = (*outputs.at(i).value).into();
            sha256_input.append_word(amount, 8);

            // append ScriptPubKey size
            let script_size: felt252 = (*outputs.at(i).pk_script).len().into();
            sha256_input.append_word(script_size, 1);

            // append ScriptPubKey
            let script: @ByteArray = *outputs.at(i).pk_script;
            sha256_input.append(script);

            i += 1;
        };

        // append locktime
        sha256_input.append_word(locktime, 4);

        // Compute double sha256
        let firstHash = compute_sha256_byte_array(@sha256_input).span();
        let secondHash = compute_sha256_u32_array(firstHash.into(), 0, 0).span();

        let mut txid: u256 = 0;
        let mut i: u32 = 0;
        while i != 8 {
            let element: u256 = (*secondHash[i]).into();
            txid += shl(element, (32 * (7 - i)));

            i += 1;
        };

        txid
    }

    fn fee(self: @Transaction) -> u256 {
        // TODO: implement
        0
    }
}

fn block_hash(self: @ChainState, block: @Block, merkle_root: u256) -> Result<u256, ByteArray> {
    // TODO: implement
    Result::Ok(0)
}

fn validate_proof_of_work(target: u256, block_hash: u256) -> Result<(), ByteArray> {
    if block_hash <= target {
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
    // TODO: implement
    *self.prev_timestamps
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

fn fee_and_merkle_root(block: @Block) -> Result<(u256, u256), ByteArray> {
    let mut txids = ArrayTrait::new();
    let mut total_fee = 0;

    for tx in *block.txs {
        txids.append(tx.txid());
        total_fee += tx.fee();
    };

    Result::Ok((total_fee, merkle_root(ref txids)))
}

fn validate_coinbase(block: @Block, total_fees: u256) -> Result<(), ByteArray> {
    //TODO implement
    Result::Ok(())
}

// Return BTC reward in SATS
fn compute_block_reward(block_height: u32) -> u64 {
    shr(5000000000_u64, (block_height / 210000_u32))
}


#[cfg(test)]
mod tests {
    use raito::state::{Header, Transaction, TxIn, TxOut};
    use raito::utils::from_base16;
    use super::{
        validate_timestamp, validate_proof_of_work, compute_block_reward, compute_total_work,
        compute_work_from_target, shr, shl, TransactionValidatorImpl, Block, ChainState,
        UtreexoState, OutPoint
    };

    #[test]
    fn test_validate_timestamp() {
        let mut chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1,
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
        let result = validate_proof_of_work(0, 1);
        assert!(result.is_err(), "Expect target less than prev block hash");

        // target is greater than prev block hash
        let result = validate_proof_of_work(2, 1);
        assert!(result.is_ok(), "Expect target gt prev block hash");

        // target is equal to prev block hash
        let result = validate_proof_of_work(1, 1);
        assert!(result.is_ok(), "Expect target equal to prev block hash");

        // block prev block hash is greater than target
        let result = validate_proof_of_work(1, 2);
        assert!(result.is_err(), "Expect prev block hash gt target");

        // block prev block hash is less than target
        let result = validate_proof_of_work(10, 9);
        assert!(result.is_ok(), "Expect prev block hash lt target");
    }

    // Ref implementation here:
    // https://github.com/bitcoin/bitcoin/blob/0f68a05c084bef3e53e3f549c403bc90b1db319c/src/test/validation_tests.cpp#L24
    #[test]
    fn test_compute_block_reward() {
        let max_halvings: u32 = 64;
        let reward_initial: u256 = 5000000000;
        let mut block_height = 210_000; // halving every 210 000 blocks
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
    // #[test]
// fn test_txid() {
//     let tx: Transaction = Transaction {
//         version: 1,
//         is_segwit: false,
//         inputs: array![
//             TxIn {
//                 script: from_base16(
//                     "4730440220758f18952b4ebe859b91bdfc86d67478e85511f9fe949c30ab9ea12c78ddf9be0220146e88b5a89ca14a3505c17a13c9f6654014ecce1ca2910db525f6b2b23e680a012102d13c14dfd083b9b19b50ad6f6209902179f98a1acda715633b5622267e067676"
//                 ),
//                 sequence: 0xffffffff,
//                 previous_output: OutPoint {
//                     txid:
//                     0x183e7d7146f1fe51a79417dce4c7b0b6f848f844ff56c12d2242f86d52fae8cb_u256,
//                     vout: 0x01000000_u32, txo_index: 0,
//                 },
//                 witness: from_base16("")
//             }
//         ]
//             .span(),
//         outputs: array![
//             TxOut {
//                 value: 0x04bdcd0200000000,
//                 pk_script: from_base16("76a9142bd74c02779861ee95f9dc61c870d31e15a29c3a88ac"),
//             }
//         ]
//             .span(),
//         lock_time: 0
//     };

    //     let txid: u256 = TransactionValidatorImpl::txid(@tx);
//     assert_eq!(
//         txid, 31117111977866514605580122280379099880855664600995121277970332180238727346730
//     );
// }
}
