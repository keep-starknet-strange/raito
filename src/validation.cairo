use super::state::{Block, ChainState};

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
    // TODO: implement
    Result::Ok(())
}

fn validate_timestamp(self: @ChainState, block: @Block) -> Result<(), ByteArray> {
    // TODO: implement
    Result::Ok(())
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