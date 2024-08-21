//! Difficulty target validation helpers.
//!
//! Read more:
//!   - https://learnmeabitcoin.com/technical/mining/target/
//!   - https://learnmeabitcoin.com/technical/block/bits/

use raito::utils::{hash::Hash, bit_shifts::{shl, shr}};

/// Maximum difficulty target allowed
const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;

/// Check if the given bits match the target difficulty.
pub fn validate_bits(target: u256, bits: u32) -> Result<(), ByteArray> {
    if bits == target_to_bits(target)? {
        Result::Ok(())
    } else {
        Result::Err("Block header bits do not match target")
    }
}

/// Adjusts difficulty target given the block height and timestamp.
/// Returns new difficulty target and new epoch start time.
pub fn adjust_difficulty(
    current_target: u256, epoch_start_time: u32, block_height: u32, block_time: u32
) -> (u256, u32) {
    // TODO: implement
    (current_target, epoch_start_time)
}

/// Convert target value to the compact form (bits)
fn target_to_bits(target: u256) -> Result<u32, ByteArray> {
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
    use super::{bits_to_target, target_to_bits};

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
}
