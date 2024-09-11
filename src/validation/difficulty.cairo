//! Difficulty target validation helpers.
//!
//! Read more:
//!   - https://learnmeabitcoin.com/technical/mining/target/
//!   - https://learnmeabitcoin.com/technical/block/bits/

use crate::utils::bit_shifts::{shl, shr};

/// Maximum difficulty target allowed
const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;
/// Number of blocks per epoch
const BLOCKS_PER_EPOCH: u32 = 2016;
/// Duration in seconds of an expected epoch of 2 weeks
const EXPECTED_EPOCH_TIMESPAN: u32 = 60 * 60 * 24 * 14;

/// Check if the given bits match the target difficulty.
pub fn validate_bits(target: u256, bits: u32) -> Result<(), ByteArray> {
    if bits == target_to_bits(target)? {
        Result::Ok(())
    } else {
        Result::Err(format!("Block header bits {} do not match target {}", bits, target))
    }
}

/// Adjusts difficulty target given the block height and timestamp.
/// Previous block time is needed to calculate the time span.
/// Actual block time is needed to calculate the new epoch start time.
/// Returns new difficulty target and new epoch start time.
pub fn adjust_difficulty(
    /// TODO: Split this function into smaller functions
    current_target: u256,
    epoch_start_time: u32,
    block_height: u32,
    prev_block_time: u32,
    block_time: u32
) -> (u256, u32) {
    if block_height % BLOCKS_PER_EPOCH == BLOCKS_PER_EPOCH - 1 {
        let mut time_span = prev_block_time - epoch_start_time;

        // Limit adjustment step
        if (time_span < EXPECTED_EPOCH_TIMESPAN / 4) {
            time_span = EXPECTED_EPOCH_TIMESPAN / 4;
        }
        if (time_span > EXPECTED_EPOCH_TIMESPAN * 4) {
            time_span = EXPECTED_EPOCH_TIMESPAN * 4;
        }

        // Retarget calculation
        let mut bn_new: u256 = current_target;
        bn_new *= time_span.into();
        bn_new /= EXPECTED_EPOCH_TIMESPAN.into();

        if bn_new < MAX_TARGET {
            // bits_to_target(target_to_bits(x)) to reduce difficulty precision
            return (bits_to_target(target_to_bits(bn_new).unwrap()).unwrap(), block_time);
        } else {
            return (MAX_TARGET, block_time);
        }
    } else { // No adjustment needed, return current target and epoch start time
        (current_target, epoch_start_time)
    }
}

/// Convert target value to the compact form (bits)
fn target_to_bits(target: u256) -> Result<u32, ByteArray> {
    if target == 0 {
        return Result::Err("Target is zero");
    }

    if target > MAX_TARGET {
        return Result::Err("Exceeds max value");
    }

    let mut divider = MAX_TARGET;
    let mut tmp = target;
    let mut padding = 3;
    let mut last_coef = 0;

    // Get bytes from most to least significant byte
    for _ in 0
        ..31_u8 {
            let (q, r) = core::traits::DivRem::div_rem(tmp, divider.try_into().unwrap());
            divider /= 0x100;
            last_coef = tmp;
            tmp = r;
            if (q != 0) {
                // Normalize
                if (q > 0x80) {
                    padding -= 1;
                }
                break;
            }
            padding += 1;
        };

    // 29 = 32 - 3(coefficient bytes)
    for _ in 0..(29 - padding) {
        last_coef /= 0x100;
    };

    // Combine exponent and coefficient
    let result: u32 = (32 - padding) * 0x1000000 + last_coef.try_into().unwrap();

    Result::Ok(result)
}

/// Convert target bits to the normal form
fn bits_to_target(bits: u32) -> Result<u256, ByteArray> {
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

#[cfg(test)]
mod tests {
    use super::{bits_to_target, target_to_bits, adjust_difficulty};

    #[test]
    fn test_adjust_difficulty_block_2016_no_retargeting() {
        // chainstate before block 2016
        let current_target: u256 =
            0x00000000ffff0000000000000000000000000000000000000000000000000000_u256;
        let epoch_start_time: u32 = 1231006505;
        let block_height: u32 = 2015;
        let prev_block_time: u32 = 1233061996;

        // block 2016
        let block_time: u32 = 1233063531;

        let (new_target, new_epoch_start_time) = adjust_difficulty(
            current_target, epoch_start_time, block_height, prev_block_time, block_time
        );

        assert_eq!(
            new_target, 0x00000000ffff0000000000000000000000000000000000000000000000000000_u256
        );
        assert_eq!(new_epoch_start_time, 1233063531);
    }

    #[test]
    fn test_adjust_difficulty_block_2017_no_retargeting_no_new_epoch() {
        // chainstate before block 2017
        let current_target: u256 =
            0x00000000ffff0000000000000000000000000000000000000000000000000000_u256;
        let epoch_start_time: u32 = 1233063531;
        let block_height: u32 = 2016;
        let prev_block_time: u32 = 1233063531;

        // block 2017
        let block_time: u32 = 1233064909;

        let (new_target, new_epoch_start_time) = adjust_difficulty(
            current_target, epoch_start_time, block_height, prev_block_time, block_time
        );

        assert_eq!(
            new_target, 0x00000000ffff0000000000000000000000000000000000000000000000000000_u256
        );
        assert_eq!(new_epoch_start_time, 1233063531);
    }

    #[test]
    fn test_adjust_difficulty_block_32256_decrease() {
        // chainstate before block 32256
        let current_target: u256 =
            0x00000000ffff0000000000000000000000000000000000000000000000000000_u256;
        let epoch_start_time: u32 = 1261130161;
        let block_height: u32 = 32255;
        let prev_block_time: u32 = 1262152739;

        // block 32256
        let block_time: u32 = 1262153464;

        let (new_target, new_epoch_start_time) = adjust_difficulty(
            current_target, epoch_start_time, block_height, prev_block_time, block_time
        );

        assert_eq!(
            new_target, 0x00000000d86a0000000000000000000000000000000000000000000000000000_u256
        );
        assert_eq!(new_epoch_start_time, 1262153464);
    }

    #[test]
    fn test_adjust_difficulty_block_56448_increase() {
        // chainstate before block 56448
        let current_target: u256 =
            0x0000000013ec5300000000000000000000000000000000000000000000000000_u256;
        let epoch_start_time: u32 = 1272966376;
        let block_height: u32 = 56447;
        let prev_block_time: u32 = 1274278387;

        // block 56448
        let block_time: u32 = 1274278435;

        let (new_target, new_epoch_start_time) = adjust_difficulty(
            current_target, epoch_start_time, block_height, prev_block_time, block_time
        );

        assert_eq!(
            new_target, 0x00000000159c2400000000000000000000000000000000000000000000000000_u256
        );
        assert_eq!(new_epoch_start_time, 1274278435);
    }

    #[test]
    fn test_bits_to_target_01003456() {
        let result = bits_to_target(0x01003456);
        assert!(result.is_ok(), "Should be valid");
        assert!(result.unwrap() == 0x00_u256, "Incorrect target for 0x01003456");
    }

    #[test]
    fn test_bits_to_target_01123456() {
        let result = bits_to_target(0x01123456);
        assert!(result.is_ok(), "Should be valid");
        assert!(result.unwrap() == 0x12_u256, "Incorrect target for 0x01123456");
    }

    #[test]
    fn test_bits_to_target_02008000() {
        let result = bits_to_target(0x02008000);
        assert!(result.is_ok(), "Should be valid");
        assert!(result.unwrap() == 0x80_u256, "Incorrect target for 0x02008000");
    }

    #[test]
    fn test_bits_to_target_181bc330() {
        let result = bits_to_target(0x181bc330);
        assert!(result.is_ok(), "Should be valid");
        assert!(
            result.unwrap() == 0x1bc330000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x181bc330"
        );
    }

    #[test]
    fn test_bits_to_target_05009234() {
        let result = bits_to_target(0x05009234);
        assert!(result.is_ok(), "Should be valid");
        assert!(result.unwrap() == 0x92340000_u256, "Incorrect target for 0x05009234");
    }

    #[test]
    fn test_bits_to_target_04123456() {
        let result = bits_to_target(0x04123456);
        assert!(result.is_ok(), "Should be valid");
        assert!(result.unwrap() == 0x12345600_u256, "Incorrect target for 0x04123456");
    }

    #[test]
    fn test_bits_to_target_1d00ffff() {
        let result = bits_to_target(0x1d00ffff);
        assert!(result.is_ok(), "Should be valid");
        assert!(
            result
                .unwrap() == 0x00000000ffff0000000000000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1d00ffff"
        );
    }

    #[test]
    fn test_bits_to_target_1c0d3142() {
        let result = bits_to_target(0x1c0d3142);
        assert!(result.is_ok(), "Should be valid");
        assert!(
            result
                .unwrap() == 0x000000000d314200000000000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1c0d3142"
        );
    }

    #[test]
    fn test_bits_to_target_1707a429() {
        let result = bits_to_target(0x1707a429);
        assert!(result.is_ok(), "Should be valid");
        assert!(
            result
                .unwrap() == 0x00000000000000000007a4290000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1707a429"
        );
    }

    #[test]
    fn test_target_to_bits_large_target() {
        let target: u256 = 0x1bc330000000000000000000000000000000000000000000;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x181bc330, "Incorrect bits for large target");
    }

    #[test]
    fn test_target_to_bits_small_target() {
        let target: u256 = 0x92340000;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x05009234, "Incorrect bits for small target");
    }

    #[test]
    fn test_target_to_bits_medium_target() {
        let target: u256 = 0x12345600;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x04123456, "Incorrect bits for medium target");
    }

    #[test]
    fn test_target_to_bits_max_target() {
        let max_target: u256 = 0x00000000ffff0000000000000000000000000000000000000000000000000000;
        let result = target_to_bits(max_target).unwrap();
        assert!(result == 0x1d00ffff, "Incorrect bits for max target");
    }

    #[test]
    fn test_target_to_bits_high_precision_target() {
        let target: u256 = 0x000000000d314200000000000000000000000000000000000000000000000000;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x1c0d3142, "Incorrect bits for high precision target");
    }

    #[test]
    fn test_target_to_bits_low_precision_target() {
        let target: u256 = 0x00000000000000000007a4290000000000000000000000000000000000000000;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x1707a429, "Incorrect bits for low precision target");
    }

    #[test]
    fn test_target_to_bits_full_mantissa() {
        let target: u256 = 0xd86a528bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8bc8b;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x1d00d86a, "Incorrect bits for full mantissa target");
    }

    #[test]
    fn test_target_to_bits_zero_target() {
        let result = target_to_bits(0.into());
        assert!(result.is_err(), "Should error on zero target");
    }

    #[test]
    fn test_target_to_bits_overflow_target() {
        let target: u256 = 0x01000000000000000000000000000000000000000000000000000000000000000;
        let result = target_to_bits(target);
        assert!(result.is_err(), "Should error on overflow target");
    }

    #[test]
    fn test_target_to_bits_first_significant_byte_below_0x80() {
        let target: u256 = 0x000000000000000000eb304f6a76a77000000000000000000000000000000000_u256;
        let result = target_to_bits(target).unwrap();
        assert!(result == 0x1800eb30, "Incorrect bits for target below 0x80");
    }
}
