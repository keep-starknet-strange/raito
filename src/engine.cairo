use core::result::Result;
use core::option::OptionTrait;
use core::traits::Into;
use core::byte_array::ByteArray;

// Constants
const BLOCK_HEADER_SIZE: u32 = 80;
const MAX_BITS: u32 = 0x1d00FFFF;
const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;
const EXPECTED_EPOCH_TIMESPAN: u32 = 60 * 60 * 24 * 14; // 2 weeks in seconds
const BLOCKS_PER_EPOCH: u32 = 2016;

#[derive(Drop, Clone)]
struct BlockHeader {
    version: u32,
    prev_block_hash: ByteArray,
    merkle_root_hash: ByteArray,
    time: u32,
    bits: u32,
    nonce: u32
}

#[derive(Drop, Clone)]
pub struct ChainState {
    pub block_height: u32,
    pub total_work: u256,
    pub best_block_hash: ByteArray,
    pub current_target: u32,
    pub epoch_start_time: u32,
    pub prev_timestamps: Array<u32>
}

#[derive(Drop)]
struct BlockHeaderValidationContext {
    block_header: BlockHeader,
    block_hash: ByteArray,
    target: u256,
    prev_chain_state: ChainState,
    block_height: u32
}

#[generate_trait]
pub impl BlockHeaderImpl of BlockHeaderTrait {
    fn new(
        version: u32,
        prev_block_hash: ByteArray,
        merkle_root_hash: ByteArray,
        time: u32,
        bits: u32,
        nonce: u32
    ) -> BlockHeader {
        BlockHeader { version, prev_block_hash, merkle_root_hash, time, bits, nonce }
    }
}

#[generate_trait]
pub impl ChainStateImpl of ChainStateTrait {
    fn new(
        block_height: u32,
        total_work: u256,
        best_block_hash: ByteArray,
        current_target: u32,
        epoch_start_time: u32,
        prev_timestamps: Array<u32>
    ) -> ChainState {
        ChainState {
            block_height,
            total_work,
            best_block_hash,
            current_target,
            epoch_start_time,
            prev_timestamps
        }
    }
}

#[generate_trait]
pub impl BlockHeaderValidationContextImpl of BlockHeaderValidationContextTrait {
    fn new(
        block_header: BlockHeader,
        block_hash: ByteArray,
        target: u256,
        prev_chain_state: ChainState,
        block_height: u32
    ) -> BlockHeaderValidationContext {
        BlockHeaderValidationContext {
            block_header, block_hash, target, prev_chain_state, block_height
        }
    }
}

// The main engine for block header validation
#[derive(Drop)]
struct BlockHeaderEngine {
    context: BlockHeaderValidationContext
}

#[generate_trait]
pub impl BlockHeaderEngineImpl of BlockHeaderEngineTrait {
    fn new(context: BlockHeaderValidationContext) -> BlockHeaderEngine {
        BlockHeaderEngine { context }
    }

    fn validate_and_apply_block_header(ref self: BlockHeaderEngine) -> Result<ChainState, felt252> {
        self.validate_prev_block_hash()?;
        self.validate_proof_of_work()?;
        self.validate_target()?;
        self.validate_timestamp()?;

        let next_state = self.apply_block_header();
        Result::Ok(next_state)
    }

    fn validate_prev_block_hash(ref self: BlockHeaderEngine) -> Result<(), felt252> {
        if self
            .context
            .block_header
            .prev_block_hash != self
            .context
            .prev_chain_state
            .best_block_hash {
            return Result::Err('Invalid prev_block_hash');
        }
        Result::Ok(())
    }

    fn validate_proof_of_work(ref self: BlockHeaderEngine) -> Result<(), felt252> {
        Result::Ok(())
    }

    fn validate_target(ref self: BlockHeaderEngine) -> Result<(), felt252> {
        let target = bits_to_target(self.context.block_header.bits)?;
        if self.context.target != target {
            return Result::Err('Invalid target');
        }
        Result::Ok(())
    }

    fn validate_timestamp(ref self: BlockHeaderEngine) -> Result<(), felt252> {
        Result::Ok(())
    }

    fn apply_block_header(ref self: BlockHeaderEngine) -> ChainState {
        ChainState {
            block_height: 0,
            total_work: 0,
            best_block_hash: "",
            current_target: 0,
            epoch_start_time: 0,
            prev_timestamps: ArrayTrait::new()
        }
    }

    fn next_prev_timestamps(ref self: BlockHeaderEngine) -> Array<u32> {
        let mut timestamps = ArrayTrait::new();

        timestamps
    }

    fn compute_total_work(ref self: BlockHeaderEngine) -> u256 {
        let work_in_block = compute_work_from_target(self.context.target);
        self.context.prev_chain_state.total_work + work_in_block
    }

    fn adjust_difficulty(ref self: BlockHeaderEngine) -> (u32, u32) {
        (0, 0)
    }
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
        let divisor = u256_pow(256.into(), 3 - exponent);
        target = target / divisor;
    } else {
        // Check for potential overflow
        let shift = exponent - 3;
        if shift >= 29 {
            return Result::Err('Exponent too large');
        }
        // left shift
        let mut multiplier: u256 = 256.into();
        let mut i: u32 = 3;
        while i < exponent {
            multiplier = checked_mul(multiplier, 256.into()).expect('u256_mul Overflow');
            i += 1;
        };
        target = checked_mul(target, multiplier).expect('u256_mul Overflow');
    }

    // Ensure the target doesn't exceed the maximum allowed value
    if target > MAX_TARGET {
        return Result::Err('Target exceeds maximum');
    }

    Result::Ok(target)
}

fn target_to_bits(target: u256) -> u32 {
    0
}

fn compute_work_from_target(target: u256) -> u256 {
    0
}

fn compute_timestamps_median(timestamps: Span<u32>) -> u32 {
    0
}

// Helper function to calculate power of 256
fn u256_pow(base: u256, exp: u32) -> u256 {
    if exp == 0 {
        return 1.into();
    }
    let mut result: u256 = 1.into();
    let mut i = 0;
    while i < exp {
        result = checked_mul(result, base).expect('u256_mul Overflow');
        i += 1;
    };
    result
}

fn checked_mul(a: u256, b: u256) -> Option<u256> {
    // If either number is zero, return zero immediately
    if a == 0.into() || b == 0.into() {
        return Option::Some(0.into());
    }

    // Perform multiplication and check for overflow
    let product = a * b;

    // Check if the product divided by either of the operands does not yield the other operand,
    // which would indicate an overflow.
    if product / a != b || product / b != a {
        return Option::None;
    }

    Option::Some(product)
}
