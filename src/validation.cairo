use super::state::{Block, ChainState};
use alexandria_math::i257::{i257, I257Impl};
use alexandria_math::pow;


const ONE_256: u256 = 1_u256;
const ALL_ONES_U128: u128 = 340282366920938463463374607431768211455;

#[generate_trait]
impl BlockValidatorImpl of BlockValidator {
    fn validate_and_apply(self: ChainState, block: Block) -> Result<ChainState, ByteArray> {
        validate_prev_block_hash(@self, @block)?;
        validate_proof_of_work(@self, @block)?;
        validate_target(@self, @block)?;
        validate_timestamp(@self, @block)?;

        validate_merkle_root(@self, @block)?;
        // validate_and_apply_transactions

        let prev_timestamps = next_prev_timestamps(@self, @block);
        let total_work = compute_total_work(@self, @block);
        let (current_target, epoch_start_time) = adjust_difficulty(@self, @block);

        Result::Ok(
            ChainState { total_work, current_target, epoch_start_time, prev_timestamps, ..self, }
        )
    }
}

fn validate_prev_block_hash(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    if self.best_block_hash == block.header.prev_block_hash {
        Result::Ok(())
    } else {
        Result::Err("Invalid `prev_block_hash`. This block does not extend the current chain.")
    }
}

fn validate_proof_of_work(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    // TODO: implement
    Result::Ok(())
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
    let block_target: u256 = convert_u32_to_u256(*block.header.bits);
    let work_in_block: u256 = compute_work_from_target(block_target);
    let new_total_work: u256 = *self.total_work + work_in_block;
    new_total_work
}

fn convert_u32_to_u256(val: u32) -> u256 {
    let felt_val: felt252 = val.into();
    let mut val_u256: u256 = 1;
    let low: u128 = felt_val.try_into().unwrap();
    let high: u128 = 0;
    val_u256.low = low;
    val_u256.high = high;
    val_u256
    
}

fn compute_bitwise_not_for_u256(val: u256) -> u256 {
    let mut not_val: u256 = 0;
    not_val.low = ALL_ONES_U128 - val.low - 1_u128;
    not_val.high = ALL_ONES_U128 - val.high - 1_u128;
    not_val
}

fn compute_work_from_target(target: u256) -> u256 {
    let one_i257: i257 = I257Impl::new(ONE_256, false);
    let target_i257: i257 = target.into();
    print!("converted target is {}", target_i257.abs());
    let not_target: i257 = compute_bitwise_not_for_u256(target).into();
    print!("not target is {}", not_target.abs());
    let div_i257: i257 = not_target / (target_i257 + one_i257);
    print!("div target is {}", div_i257.abs());
    let result_i257: i257 = div_i257 + one_i257;
    print!("result is {}", result_i257.abs());
    result_i257.abs()
}

fn adjust_difficulty(self: @ChainState, block: @Block) -> (u32, u32) {
    // TODO: implement
    (*self.current_target, *self.epoch_start_time)
}

fn validate_merkle_root(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    // TODO: implement
    Result::Ok(())
}

#[cfg(test)]
mod tests {
    use super::{validate_target, validate_timestamp, compute_work_from_target, compute_total_work};
    use super::{Block, ChainState};
    use super::super::state::{Header, Transaction, TxIn, TxOut};
    use alexandria_math::i257::{i257, I257Impl};
    use cairo_lib::utils::math::pow;
    const ONE_256: u256 = 1_u256;

    #[test]
    fn test_validate_target() {
        let mut chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1,
            current_target: 1,
            epoch_start_time: 1,
            prev_timestamps: array![1, 2, 3, 4, 5].span(),
        };
        let mut block = Block {
            header: Header {
                version: 1, prev_block_hash: 1, merkle_root_hash: 1, time: 1, bits: 1, nonce: 1,
            },
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
        };
        let mut block = Block {
            header: Header {
                version: 1, prev_block_hash: 1, merkle_root_hash: 1, time: 12, bits: 1, nonce: 1,
            },
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
    fn test_compute_total_work() {
        let mut chain_state = ChainState {
            block_height: 1,
            total_work: 1,
            best_block_hash: 1,
            current_target: 1,
            epoch_start_time: 1,
            prev_timestamps: array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].span(),
        };
        let mut block = Block {
            header: Header {
                version: 1, prev_block_hash: 1, merkle_root_hash: 1, time: 12, bits: 1, nonce: 1,
            },
            txs: ArrayTrait::new().span(),
        };
        let expected_work = compute_work_from_target(ONE_256) + chain_state.total_work;
        let total_work: u256 = compute_total_work(@chain_state, @block);
        assert(total_work == expected_work, 'failed to compute target');
    }

    #[test] 
    fn test_compute_work_from_target() {
        let expected_work = 0x0100010001;
        let target: u256 = 0x00000000ffff0000000000000000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'failed to compute target');
    }
}
