//! Bit shifts.

use core::num::traits::{Zero, One, BitSize};

/// Performs a bitwise left shift on the given value by a specified number of bits.
pub fn shl<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<T>,
    +Add<U>,
    +Sub<U>,
    +Mul<T>,
    +Div<U>,
    +Rem<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialOrd<U>,
    +PartialEq<U>,
    +BitSize<T>,
    +Into<usize, U>
>(
    self: T, shift: U,
) -> T {
    if shift > BitSize::<T>::bits().into() - One::one() {
        return Zero::zero();
    }
    let two = One::one() + One::one();
    self * fast_pow(two, shift)
}

/// Performs a bitwise right shift on the given value by a specified number of bits.
pub fn shr<
    T,
    U,
    +Zero<T>,
    +Zero<U>,
    +One<T>,
    +One<U>,
    +Add<T>,
    +Add<U>,
    +Sub<U>,
    +Div<T>,
    +Mul<T>,
    +Div<U>,
    +Rem<U>,
    +Copy<T>,
    +Copy<U>,
    +Drop<T>,
    +Drop<U>,
    +PartialOrd<U>,
    +PartialEq<U>,
    +BitSize<T>,
    +Into<usize, U>
>(
    self: T, shift: U
) -> T {
    if shift > BitSize::<T>::bits().try_into().unwrap() - One::one() {
        return Zero::zero();
    }

    let two = One::one() + One::one();
    self / fast_pow(two, shift)
}


// Fast exponentiation using the square-and-multiply algorithm
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
    base: T, exp: U
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


/// Fast power of 2 using lookup tables
/// Reference: https://github.com/keep-starknet-strange/alexandria/pull/336
///
/// # Arguments
/// * `exponent` - The exponent to raise 2 to
/// # Returns
/// * `u128` - The result of 2^exponent
/// # Panics
/// * If `exponent` is greater than 127 (out of the supported range)
pub fn pow2(exponent: u32) -> u128 {
    let hardcoded_results: [u128; 128] = [
        0x1,
        0x2,
        0x4,
        0x8,
        0x10,
        0x20,
        0x40,
        0x80,
        0x100,
        0x200,
        0x400,
        0x800,
        0x1000,
        0x2000,
        0x4000,
        0x8000,
        0x10000,
        0x20000,
        0x40000,
        0x80000,
        0x100000,
        0x200000,
        0x400000,
        0x800000,
        0x1000000,
        0x2000000,
        0x4000000,
        0x8000000,
        0x10000000,
        0x20000000,
        0x40000000,
        0x80000000,
        0x100000000,
        0x200000000,
        0x400000000,
        0x800000000,
        0x1000000000,
        0x2000000000,
        0x4000000000,
        0x8000000000,
        0x10000000000,
        0x20000000000,
        0x40000000000,
        0x80000000000,
        0x100000000000,
        0x200000000000,
        0x400000000000,
        0x800000000000,
        0x1000000000000,
        0x2000000000000,
        0x4000000000000,
        0x8000000000000,
        0x10000000000000,
        0x20000000000000,
        0x40000000000000,
        0x80000000000000,
        0x100000000000000,
        0x200000000000000,
        0x400000000000000,
        0x800000000000000,
        0x1000000000000000,
        0x2000000000000000,
        0x4000000000000000,
        0x8000000000000000,
        0x10000000000000000,
        0x20000000000000000,
        0x40000000000000000,
        0x80000000000000000,
        0x100000000000000000,
        0x200000000000000000,
        0x400000000000000000,
        0x800000000000000000,
        0x1000000000000000000,
        0x2000000000000000000,
        0x4000000000000000000,
        0x8000000000000000000,
        0x10000000000000000000,
        0x20000000000000000000,
        0x40000000000000000000,
        0x80000000000000000000,
        0x100000000000000000000,
        0x200000000000000000000,
        0x400000000000000000000,
        0x800000000000000000000,
        0x1000000000000000000000,
        0x2000000000000000000000,
        0x4000000000000000000000,
        0x8000000000000000000000,
        0x10000000000000000000000,
        0x20000000000000000000000,
        0x40000000000000000000000,
        0x80000000000000000000000,
        0x100000000000000000000000,
        0x200000000000000000000000,
        0x400000000000000000000000,
        0x800000000000000000000000,
        0x1000000000000000000000000,
        0x2000000000000000000000000,
        0x4000000000000000000000000,
        0x8000000000000000000000000,
        0x10000000000000000000000000,
        0x20000000000000000000000000,
        0x40000000000000000000000000,
        0x80000000000000000000000000,
        0x100000000000000000000000000,
        0x200000000000000000000000000,
        0x400000000000000000000000000,
        0x800000000000000000000000000,
        0x1000000000000000000000000000,
        0x2000000000000000000000000000,
        0x4000000000000000000000000000,
        0x8000000000000000000000000000,
        0x10000000000000000000000000000,
        0x20000000000000000000000000000,
        0x40000000000000000000000000000,
        0x80000000000000000000000000000,
        0x100000000000000000000000000000,
        0x200000000000000000000000000000,
        0x400000000000000000000000000000,
        0x800000000000000000000000000000,
        0x1000000000000000000000000000000,
        0x2000000000000000000000000000000,
        0x4000000000000000000000000000000,
        0x8000000000000000000000000000000,
        0x10000000000000000000000000000000,
        0x20000000000000000000000000000000,
        0x40000000000000000000000000000000,
        0x80000000000000000000000000000000
    ];
    *hardcoded_results.span()[exponent]
}

#[cfg(test)]
mod tests {
    use super::{fast_pow, pow2, shl, shr};

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
        assert_eq!(
            pow2(127),
            0x80000000000000000000000000000000,
            "2^127 should be 0x80000000000000000000000000000000"
        );
    }

    #[test]
    fn test_shl() {
        let value1: u32 = 3;
        let shift1: u32 = 2;
        let result = shl(value1, shift1);
        assert_eq!(result, 12, "invalid result");

        let value2: u32 = 5;
        let shift2: u32 = 0;
        let result = shl(value2, shift2);
        assert_eq!(result, 5);
    }

    #[test]
    fn test_shr() {
        // Assuming T and U are u32 for simplicity
        let x: u32 = 32;
        let shift: u32 = 2;
        let result = shr(x, shift);
        assert_eq!(result, 8);

        let shift: u32 = 32;
        let result = shr(x, shift);
        assert_eq!(result, 0);

        let shift: u32 = 0;
        let result = shr(x, shift);
        assert_eq!(result, 32);
    }
}
