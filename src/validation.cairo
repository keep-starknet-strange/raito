use super::utils::{shl, shr};
use super::state::{Block, ChainState, Transaction, UtreexoState};

const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;

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

#[cfg(test)]
mod tests {
    use super::{validate_target, validate_timestamp, validate_proof_of_work};
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
}
