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

#[cfg(test)]
mod tests {
    use super::{fast_pow, shl, shr};

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
