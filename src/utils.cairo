use core::traits::Into;
use core::traits::TryInto;

// Bitwise shift left for u256
pub fn shl(value: u256, shift: u32) -> u256 {
    value * fast_pow(2.into(), shift.into())
}

// Bitwise shift right for u256
pub fn shr(value: u256, shift: u32) -> u256 {
    value / fast_pow(2.into(), shift.into())
}

// Fast exponentiation using the square-and-multiply algorithm
// Reference: https://github.com/keep-starknet-strange/alexandria/blob/bcdca70afdf59c9976148e95cebad5cf63d75a7f/packages/math/src/fast_power.cairo#L12
pub fn fast_pow(base: u256, exp: u256) -> u256 {
    if exp == 0.into() {
        return 1.into();
    }

    let mut res: u256 = 1.into();
    let mut base: u256 = base;
    let mut exp: u256 = exp;

    loop {
        if exp % 2.into() == 1.into() {
            res = res * base;
        }
        exp = exp / 2.into();
        if exp == 0.into() {
            break res;
        }
        base = base * base;
    }
}