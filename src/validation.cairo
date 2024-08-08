use super::state::{Block, ChainState, Transaction, UtreexoState};
use super::utils::{shl, shr};

const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;
pub const REWARD_INITIAL: u256 = 50; // 50 BTC in satoshis =>  5000000000 SATS
pub const POW_SATS_AMOUNT: u256 = 8; // Pow to convert in SATS

#[generate_trait]
impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        validate_prev_block_hash(@self, @block)?;
        validate_proof_of_work(@0_u256, @block)?;
        validate_target(@self, @block)?;
        validate_timestamp(@self, @block)?;

        let (total_fees, merkle_root) = fee_and_merkle_root(@self, @block)?;

        validate_coinbase(@block, total_fees)?;

        let best_block_hash = block_hash(@block, merkle_root)?;
        let prev_timestamps = next_prev_timestamps(@self, @block);
        let total_work = compute_total_work(@self, @block);
        let (current_target, epoch_start_time) = adjust_difficulty(@self, @block);
        let block_height = self.block_height + 1;

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
impl TransactionValidatorImpl of TransactionValidator {
    fn txid(self: @Transaction) -> u256 {
        // TODO: implement
        0
    }
    fn fee(self: @Transaction) -> u256 {
        // TODO: implement
        0
    }
}

fn block_hash(block: @Block, merkle_root: u256) -> Result<u256, ByteArray> {
    // TODO: implement
    Result::Ok(0)
}

fn validate_prev_block_hash(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    if self.best_block_hash == block.header.prev_block_hash {
        Result::Ok(())
    } else {
        Result::Err("Invalid `prev_block_hash`. This block does not extend the current chain.")
    }
}

fn validate_proof_of_work(target: @u256, block: @Block) -> Result<(), ByteArray> {
    if block.header.prev_block_hash <= target {
        Result::Ok(())
    } else {
        Result::Err(
            "Insufficient proof of work. Expected block hash {block.header.prev_block_hash} to be less than or equal to {target}."
        )
    }
}

fn validate_target(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    if self.current_target == block.header.bits {
        Result::Ok(())
    } else {
        Result::Err("Target is {block.header.bits}. Expected {self.current_target}")
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

fn compute_total_work(self: @ChainState, block: @Block) -> u256 {
    // TODO: implement
    *self.total_work
}

fn adjust_difficulty(self: @ChainState, block: @Block) -> (u32, u32) {
    // TODO: implement
    (*self.current_target, *self.epoch_start_time)
}

fn validate_merkle_root(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    // TODO: implement
    Result::Ok(())
}

// Helper functions
pub fn bits_to_target(bits: u32) -> Result<u256, felt252> {
    // Extract exponent and mantissa
    let exponent: u32 = (bits / 0x1000000);
    let mantissa: u32 = bits & 0x00FFFFFF;

    // Check if mantissa is valid (should be less than 0x1000000)
    if mantissa > 0x7FFFFF && exponent != 0 {
        return Result::Err('Invalid mantissa');
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
        return Result::Err('Target exceeds maximum');
    }

    Result::Ok(target)
}

pub fn target_to_bits(target: u256) -> Result<u32, felt252> {
    if target == 0 {
        return Result::Err('Target is zero');
    }

    if target > MAX_TARGET {
        return Result::Err('Exceeds max value');
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
        return Result::Err('Overflow');
    }

    // Convert size to u256
    let size_u256: u256 = size.into();

    // Combine size and mantissa
    let result: u32 = (shl(size_u256, 24) + mantissa.into()).try_into().unwrap();

    Result::Ok(result)
}

fn fee_and_merkle_root(self: @ChainState, block: @Block) -> Result<(u256, u256), ByteArray> {
    let mut txids = ArrayTrait::new();
    let mut total_fee = 0;

    for tx in *block.txs {
        txids.append(tx.txid());
        total_fee += tx.fee();
    };

    Result::Ok((total_fee, merkle_root(txids)))
}

fn merkle_root(txids: Array<u256>) -> u256 {
    // TODO: implement
    0
}

fn validate_coinbase(block: @Block, total_fees: u256) -> Result<(), ByteArray> {
    //TODO implement
    Result::Ok(())
}

// Return BTC reward in SATS
fn compute_block_reward(block_height: u32) -> u64 {
    let number_halvings = block_height / 210_000;
    match number_halvings {
        0 => {
            return shl(REWARD_INITIAL, POW_SATS_AMOUNT.try_into().unwrap()).try_into().unwrap();
        }, // return REWARD_INITAL
        _ => {}
    }
    // Calculate BTC to SATS amount
    let sats_init_amount = shl(REWARD_INITIAL, POW_SATS_AMOUNT.try_into().unwrap());
    // Shift right to divide by number_halvings
    let current_reward = shr(sats_init_amount, number_halvings);
    // Convert into a u64
    (current_reward).try_into().unwrap()
}
#[cfg(test)]
mod tests {
    use super::{
        validate_target, validate_timestamp, validate_proof_of_work, compute_block_reward, shr, shl,
        REWARD_INITIAL, POW_SATS_AMOUNT
    };
    use super::{Block, ChainState, UtreexoState};
    use super::super::state::{Header, Transaction, TxIn, TxOut};

    #[test]
    fn test_validate_target() {
        let mut chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1,
            current_target: 1,
            epoch_start_time: 1,
            prev_timestamps: array![1, 2, 3, 4, 5].span(),
            utreexo_state: UtreexoState { roots: array![].span() },
        };
        let mut block = Block {
            header: Header { version: 1, prev_block_hash: 1, time: 1, bits: 1, nonce: 1, },
            txs: ArrayTrait::new().span(),
        };

        let result = validate_target(@chain_state, @block);
        assert(result.is_ok(), 'Expected target to be valid');

        chain_state.current_target = 2;
        block.header.bits = 1;
        let result = validate_target(@chain_state, @block);
        assert(result.is_err(), 'Expected target to be invalid');

        chain_state.current_target = 1;
        block.header.bits = 2;
        let result = validate_target(@chain_state, @block);
        assert(result.is_err(), 'Expected target to be invalid');
    }

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
            header: Header { version: 1, prev_block_hash: 1, time: 12, bits: 1, nonce: 1, },
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
    fn test_validate_proof_of_work() {
        let mut block = Block {
            header: Header { version: 1, prev_block_hash: 1, time: 12, bits: 1, nonce: 1, },
            txs: ArrayTrait::new().span(),
        };

        // target is less than prev block hash
        let result = validate_proof_of_work(@0_u256, @block);
        assert!(result.is_err(), "Expect target less than prev block hash");

        // target is greater than prev block hash
        let result = validate_proof_of_work(@2_u256, @block);
        assert!(result.is_ok(), "Expect target gt prev block hash");

        // target is equal to prev block hash
        let result = validate_proof_of_work(@1_u256, @block);
        assert!(result.is_ok(), "Expect target equal to prev block hash");

        // block prev block hash is greater than target
        block.header.prev_block_hash = 2;
        let result = validate_proof_of_work(@1_u256, @block);
        assert!(result.is_err(), "Expect prev block hash gt target");

        // block prev block hash is less than target
        block.header.prev_block_hash = 9;
        let result = validate_proof_of_work(@10_u256, @block);
        assert!(result.is_ok(), "Expect prev block hash lt target");
    }

    // Ref implementation here:
    // https://github.com/bitcoin/bitcoin/blob/0f68a05c084bef3e53e3f549c403bc90b1db319c/src/test/validation_tests.cpp#L24
    #[test]
    fn test_compute_block_reward() {
        let max_halvings: u32 = 64;
        let reward_initial: u256 = shl(
            REWARD_INITIAL.try_into().unwrap(), POW_SATS_AMOUNT.try_into().unwrap()
        );
        let halving_block_range = 210_000; // every 210 000 blocks
        let mut nprevious_subsidy: u256 = shl(
            REWARD_INITIAL.try_into().unwrap() * 2, POW_SATS_AMOUNT.try_into().unwrap()
        );
        let mut halving_index: u32 = 0;
        assert_eq!(nprevious_subsidy.try_into().unwrap(), reward_initial * 2);

        // First halving block reward : initial supply in SATS
        let first_halving_reward = compute_block_reward(halving_index * halving_block_range);
        assert_eq!(first_halving_reward, reward_initial.try_into().unwrap());

        // Second halving block reward : initial supply in SATS
        let second_halving_reward = compute_block_reward((halving_index + 1) * halving_block_range);
        assert_eq!(second_halving_reward, reward_initial.try_into().unwrap() / 2);

        // Test the reward when we have 5 halvings
        let five_halving_reward = compute_block_reward((halving_index + 5) * halving_block_range);
        let five_reward_amount = shr(reward_initial.try_into().unwrap(), halving_index + 5)
            .try_into()
            .unwrap();
        assert_eq!(five_halving_reward, five_reward_amount);

        // Last halving block reward = 0
        let last_reward = compute_block_reward(max_halvings * halving_block_range);
        assert_eq!(last_reward, 0);

        // Testing all halvings rewards possible
        loop {
            if halving_index == max_halvings {
                break;
            }
            let block_height: u32 = halving_index * halving_block_range;
            // Compute reward
            let reward = compute_block_reward(block_height);
            assert!(reward <= reward_initial.try_into().unwrap());
            let cast_nprevious_subsidy: u64 = nprevious_subsidy.try_into().unwrap();
            assert_eq!(reward, cast_nprevious_subsidy / 2);
            nprevious_subsidy = reward.try_into().unwrap();
            halving_index = halving_index + 1;
        };
    }
}
