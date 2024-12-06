//! Bit shifts and pow helpers.

use core::num::traits::{Zero, One};

/// Performs a bitwise right shift on a `u64` value by a specified number of bits.
/// This specialized version offers optimal performance for `u64` types.
///
/// # Arguments
/// * `self` - The `u64` value to be shifted
/// * `shift` - The number of bits to shift right
///
/// # Returns
/// * The result of the right shift operation
///
/// # Panics
/// * If `shift` is greater than 63 (via pow2's range check on the lookup table)
#[inline(always)]
pub fn shr_u64(self: u64, shift: u32) -> u64 {
    self / pow2(shift)
}

// Fast exponentiation using the square-and-multiply algorithm.
// Reference:
// https://github.com/keep-starknet-strange/alexandria/blob/bcdca70afdf59c9976148e95cebad5cf63d75a7f/packages/math/src/fast_power.cairo#L12
pub fn fast_pow<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<U>,
    +Mul<T>,
    +Rem<U>,
    +Div<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialEq<U>,
>(
    base: T, exp: U,
) -> T {
    if exp == Zero::zero() {
        return One::one();
    }

    let mut res: T = One::one();
    let mut base: T = base;
    let mut exp: U = exp;

    let two: U = One::one() + One::one();

    loop {
        if exp % two == One::one() {
            res = res * base;
        }
        exp = exp / two;
        if exp == Zero::zero() {
            break res;
        }
        base = base * base;
    }
}

/// Fast power of 2 using lookup tables.
/// Reference: https://github.com/keep-starknet-strange/alexandria/pull/336
///
/// # Arguments
/// * `exponent` - The exponent to raise 2 to
///
/// # Returns
/// * `u64` - The result of 2^exponent
///
/// # Panics
/// * If `exponent` is greater than 63 (out of the supported range)
pub fn pow2(exponent: u32) -> u64 {
    let hardcoded_results: [u64; 64] = [
        0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000,
        0x4000, 0x8000, 0x10000, 0x20000, 0x40000, 0x80000, 0x100000, 0x200000, 0x400000, 0x800000,
        0x1000000, 0x2000000, 0x4000000, 0x8000000, 0x10000000, 0x20000000, 0x40000000, 0x80000000,
        0x100000000, 0x200000000, 0x400000000, 0x800000000, 0x1000000000, 0x2000000000,
        0x4000000000, 0x8000000000, 0x10000000000, 0x20000000000, 0x40000000000, 0x80000000000,
        0x100000000000, 0x200000000000, 0x400000000000, 0x800000000000, 0x1000000000000,
        0x2000000000000, 0x4000000000000, 0x8000000000000, 0x10000000000000, 0x20000000000000,
        0x40000000000000, 0x80000000000000, 0x100000000000000, 0x200000000000000, 0x400000000000000,
        0x800000000000000, 0x1000000000000000, 0x2000000000000000, 0x4000000000000000,
        0x8000000000000000,
    ];
    *hardcoded_results.span()[exponent]
}

pub fn pow256(exponent: u32) -> NonZero<u256> {
    let hardcoded_results: [u256; 32] = [
        0x1, 0x100, 0x10000, 0x1000000, 0x100000000, 0x10000000000, 0x1000000000000,
        0x100000000000000, 0x10000000000000000, 0x1000000000000000000, 0x100000000000000000000,
        0x10000000000000000000000, 0x1000000000000000000000000, 0x100000000000000000000000000,
        0x10000000000000000000000000000, 0x1000000000000000000000000000000,
        0x100000000000000000000000000000000, 0x10000000000000000000000000000000000,
        0x1000000000000000000000000000000000000, 0x100000000000000000000000000000000000000,
        0x10000000000000000000000000000000000000000, 0x1000000000000000000000000000000000000000000,
        0x100000000000000000000000000000000000000000000,
        0x10000000000000000000000000000000000000000000000,
        0x1000000000000000000000000000000000000000000000000,
        0x100000000000000000000000000000000000000000000000000,
        0x10000000000000000000000000000000000000000000000000000,
        0x1000000000000000000000000000000000000000000000000000000,
        0x100000000000000000000000000000000000000000000000000000000,
        0x10000000000000000000000000000000000000000000000000000000000,
        0x1000000000000000000000000000000000000000000000000000000000000,
        0x100000000000000000000000000000000000000000000000000000000000000,
    ];
    (*hardcoded_results.span()[exponent]).try_into().unwrap()
}

#[cfg(test)]
mod tests {
    use super::{fast_pow, pow2, shr_u64};

    #[test]
    #[available_gas(1000000000)]
    fn test_fast_pow() {
        assert_eq!(fast_pow(2_u128, 3_u128), 8, "invalid result");
        assert_eq!(fast_pow(3_u128, 4_u128), 81, "invalid result");

        // Test with larger exponents
        assert_eq!(fast_pow(2_u128, 10_u128), 1024, "invalid result");
        assert_eq!(fast_pow(10_u128, 5_u128), 100000, "invalid result");
    }

    #[test]
    #[available_gas(1000000000)]
    fn test_pow2() {
        assert_eq!(pow2(0), 1, "2^0 should be 1");
        assert_eq!(pow2(1), 2, "2^1 should be 2");
        assert_eq!(pow2(2), 4, "2^2 should be 4");
        assert_eq!(pow2(3), 8, "2^3 should be 8");
        assert_eq!(pow2(10), 1024, "2^10 should be 1024");
        assert_eq!(pow2(63), 0x8000000000000000, "2^63 should be 0x8000000000000000");
        assert_eq!(pow2(63), 0x8000000000000000, "2^64 should be 0x8000000000000000");
    }

    #[test]
    fn test_shr_u64() {
        // Expect about 15% steps reduction over previous test,
        // should be much higher for bigger shifts
        let x: u64 = 32;
        let shift: u32 = 2;
        let result = shr_u64(x, shift);
        assert_eq!(result, 8);

        let shift: u32 = 32;
        let result = shr_u64(x, shift);
        assert_eq!(result, 0);

        let shift: u32 = 0;
        let result = shr_u64(x, shift);
        assert_eq!(result, 32);
    }
}
