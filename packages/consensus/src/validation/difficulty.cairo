//! Difficulty target validation helpers.
//!
//! Read more:
//!   - https://learnmeabitcoin.com/technical/mining/target/
//!   - https://learnmeabitcoin.com/technical/block/bits/

use utils::bit_shifts::fast_pow;

/// Maximum difficulty target allowed
const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;
/// Number of blocks per epoch
const BLOCKS_PER_EPOCH: u32 = 2016;
/// Duration in seconds of an expected epoch of 2 weeks
const EXPECTED_EPOCH_TIMESPAN: u32 = 1209600;
/// EXPECTED_EPOCH_TIMESPAN * 0.25
const MIN_EPOCH_TIMESPAN: u32 = 302400;
/// EXPECTED_EPOCH_TIMESPAN * 4
const MAX_EPOCH_TIMESPAN: u32 = 4838400;

/// Check if the given bits match the target difficulty.
pub fn validate_bits(target: u256, bits: u32) -> Result<(), ByteArray> {
    if bits_to_target(bits)? == target {
        Result::Ok(())
    } else {
        Result::Err(format!("Block header bits {} do not match target {}", bits, target))
    }
}

/// Adjusts difficulty target given the block height and timestamp.
///
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
    if block_height % BLOCKS_PER_EPOCH == 0 {
        let mut time_span = prev_block_time - epoch_start_time;

        // Limit adjustment step
        if (time_span < MIN_EPOCH_TIMESPAN) {
            time_span = MIN_EPOCH_TIMESPAN;
        } else if (time_span > MAX_EPOCH_TIMESPAN) {
            time_span = MAX_EPOCH_TIMESPAN;
        }

        // Retarget calculation
        let new_target: u256 = current_target * time_span.into() / EXPECTED_EPOCH_TIMESPAN.into();
        if new_target < MAX_TARGET {
            return (reduce_target_precision(new_target), block_time);
        } else {
            return (MAX_TARGET, block_time);
        }
    } else { // No adjustment needed, return current target and epoch start time
        (current_target, epoch_start_time)
    }
}

/// Reduces target precision leaving just 3 most significant bytes.
///
/// Note that the most significant byte might be ZERO in case the following
/// one is >= 0x80 (see "caution" section on https://learnmeabitcoin.com/technical/block/bits/).
/// This helper assumes the given target is strictly less than MAX_TARGET.
fn reduce_target_precision(target: u256) -> u256 {
    // Determine the byte size of the target
    let mut size: u32 = 0;
    let mut num = target;
    while num != 0 {
        num /= 256;
        size += 1;
    };
    // Extract 3 most significant bytes and round down
    if size > 2 {
        let factor = fast_pow(256, size - 3);
        let msb = target / factor;
        if msb > 0x7fffff {
            // If the most significant BIT is 1 then we need to prepend 0x00
            (msb / 256) * factor * 256
        } else {
            msb * factor
        }
    } else {
        target
    }
}

/// Converts difficulty target the compact form (bits) to a big integer.
fn bits_to_target(bits: u32) -> Result<u256, ByteArray> {
    // Extract exponent and mantissa
    let (exponent, mantissa) = core::traits::DivRem::div_rem(bits, 0x1000000);

    // Check if mantissa is valid (most significant byte has to be < 0x80)
    // https://bitcoin.stackexchange.com/questions/113535/why-1d00ffff-and-not-1cffffff-as-target-in-genesis-block
    if mantissa > 0x7FFFFF && exponent != 0 {
        return Result::Err("Target cannot have most significant bit set");
    }

    let target = match exponent {
        0 => { return Result::Ok(u256 { low: (mantissa / 0x1000000).into(), high: 0 }); },
        1 => { return Result::Ok(u256 { low: (mantissa / 0x10000).into(), high: 0 }); },
        2 => { return Result::Ok(u256 { low: (mantissa / 0x100).into(), high: 0 }); },
        3 => { return Result::Ok(u256 { low: mantissa.into(), high: 0 }); },
        // because mantissa is on 3 bytes, if we shift by less than 2^(128-24), it's a low
        4 => { return Result::Ok(u256 { low: (mantissa.into() * 0x100), high: 0 }); },
        5 => { return Result::Ok(u256 { low: (mantissa.into() * 0x10000), high: 0 }); },
        6 => { return Result::Ok(u256 { low: (mantissa.into() * 0x1000000), high: 0 }); },
        7 => { return Result::Ok(u256 { low: (mantissa.into() * 0x100000000), high: 0 }); },
        8 => { return Result::Ok(u256 { low: (mantissa.into() * 0x10000000000), high: 0 }); },
        9 => { return Result::Ok(u256 { low: (mantissa.into() * 0x1000000000000), high: 0 }); },
        10 => { return Result::Ok(u256 { low: (mantissa.into() * 0x100000000000000), high: 0 }); },
        11 => {
            return Result::Ok(u256 { low: (mantissa.into() * 0x10000000000000000), high: 0 });
        },
        12 => {
            return Result::Ok(u256 { low: (mantissa.into() * 0x1000000000000000000), high: 0 });
        },
        13 => {
            return Result::Ok(u256 { low: (mantissa.into() * 0x100000000000000000000), high: 0 });
        },
        14 => {
            return Result::Ok(u256 { low: (mantissa.into() * 0x10000000000000000000000), high: 0 });
        },
        15 => {
            return Result::Ok(
                u256 { low: (mantissa.into() * 0x1000000000000000000000000), high: 0 }
            );
        },
        16 => {
            return Result::Ok(
                u256 { low: (mantissa.into() * 0x100000000000000000000000000), high: 0 }
            );
        },
        // here we don't know
        17 => { return Result::Ok(mantissa.into() * 0x10000000000000000000000000000); },
        18 => { return Result::Ok(mantissa.into() * 0x1000000000000000000000000000000); },
        19 => { return Result::Ok(mantissa.into() * 0x100000000000000000000000000000000); },
        // here it's only a high
        20 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x100 }); },
        21 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x10000 }); },
        22 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x1000000 }); },
        23 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x100000000 }); },
        24 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x10000000000 }); },
        25 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x1000000000000 }); },
        26 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x100000000000000 }); },
        27 => { return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x10000000000000000 }); },
        28 => {
            return Result::Ok(u256 { low: 0, high: mantissa.into() * 0x1000000000000000000 });
        },
        // because 0x7FFFFF * 2**(8 * (28 - 3)) < MAX_TARGET, for these two elements we have to
        // check the target
        29 => u256 { low: 0, high: mantissa.into() * 0x100000000000000000000 },
        30 => u256 { low: 0, high: mantissa.into() * 0x10000000000000000000000 },
        // because 2^(8 * (31 - 3)) > MAX_TARGET
        31 => { return Result::Err("Target exceeds maximum value"); },
        32 => { return Result::Err("Target exceeds maximum value"); },
        _ => { return Result::Err("Target size cannot exceed 32 bytes"); },
    };

    if target > MAX_TARGET {
        Result::Err("Target exceeds maximum value")
    } else {
        Result::Ok(target)
    }
}

#[cfg(test)]
mod tests {
    use super::{bits_to_target, adjust_difficulty, reduce_target_precision};

    #[test]
    fn test_adjust_difficulty_block_2016_no_retargeting() {
        // chainstate before block 2016
        let current_target: u256 =
            0x00000000ffff0000000000000000000000000000000000000000000000000000_u256;
        let epoch_start_time: u32 = 1231006505;
        let prev_block_time: u32 = 1233061996;

        // block 2016
        let block_time: u32 = 1233063531;
        let block_height: u32 = 2016;

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
        let prev_block_time: u32 = 1233063531;

        // block 2017
        let block_time: u32 = 1233064909;
        let block_height: u32 = 2017;

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
        let prev_block_time: u32 = 1262152739;

        // block 32256
        let block_time: u32 = 1262153464;
        let block_height: u32 = 32256;

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
        let prev_block_time: u32 = 1274278387;

        // block 56448
        let block_time: u32 = 1274278435;
        let block_height: u32 = 56448;

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
    fn test_bits_to_target_bounds() {
        // MSB is 0x80
        assert_eq!(
            bits_to_target(0x03800000).unwrap_err(), "Target cannot have most significant bit set"
        );
        // Exponent is 33
        assert_eq!(bits_to_target(0x2100aa00).unwrap_err(), "Target size cannot exceed 32 bytes");
        // Max target exceeded
        assert_eq!(bits_to_target(0x20010000).unwrap_err(), "Target exceeds maximum value");
    }

    #[test]
    fn test_reduce_target_precision() {
        assert_eq!(reduce_target_precision(0x00), 0x00);
        assert_eq!(reduce_target_precision(0x01), 0x01);
        assert_eq!(reduce_target_precision(0x80), 0x80);
        assert_eq!(reduce_target_precision(0x8001), 0x8001);
        assert_eq!(reduce_target_precision(0x0102), 0x0102);
        assert_eq!(reduce_target_precision(0x7f0001), 0x7f0001);
        assert_eq!(reduce_target_precision(0x800001), 0x800000);
        assert_eq!(reduce_target_precision(0x800001), 0x800000);
        assert_eq!(
            reduce_target_precision(
                0x00000000FFFF0000000000000000000000000000000000000000000000000000
            ),
            0x00000000FFFF0000000000000000000000000000000000000000000000000000
        );
        assert_eq!(
            reduce_target_precision(
                0x00000000FFFF0100000000000000000000000000000000000000000000000000
            ),
            0x00000000FFFF0000000000000000000000000000000000000000000000000000
        );
        assert_eq!(
            reduce_target_precision(
                0x00000001FFFF0100000000000000000000000000000000000000000000000000
            ),
            0x00000001FFFF0000000000000000000000000000000000000000000000000000
        );
    }
}
