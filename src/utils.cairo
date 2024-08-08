use core::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};

// Bitwise shift left for u256
pub fn shl(value: u256, shift: u32) -> u256 {
    value * fast_pow(2.into(), shift.into())
}

// Bitwise shift right for u256
pub fn shr(value: u256, shift: u32) -> u256 {
    value / fast_pow(2.into(), shift.into())
}

// Fast exponentiation using the square-and-multiply algorithm
// Reference:
// https://github.com/keep-starknet-strange/alexandria/blob/bcdca70afdf59c9976148e95cebad5cf63d75a7f/packages/math/src/fast_power.cairo#L12
pub fn fast_pow(base: u256, exp: u32) -> u256 {
    if exp == 0 {
        return 1_u256;
    }

    let mut res: u256 = 1_u256;
    let mut base: u256 = base;
    let mut exp: u32 = exp;

    loop {
        if exp % 2 == 1 {
            res = res * base;
        }
        exp = exp / 2;
        if exp == 0 {
            break res;
        }
        base = base * base;
    }
}

const TWO_POW_32: u128 = 0x100000000;
const TWO_POW_64: u128 = 0x10000000000000000;
const TWO_POW_96: u128 = 0x1000000000000000000000000;

pub fn double_sha256(a: u256, b: u256) -> u256 {
    let mut ba = Default::default();

    ba.append_word(a.high.into(), 16);
    ba.append_word(a.low.into(), 16);
    ba.append_word(b.high.into(), 16);
    ba.append_word(b.low.into(), 16);

    let mut input1 = Default::default();
    input1.append_span(compute_sha256_byte_array(@ba).span());

    let [x0, x1, x2, x3, x4, x5, x6, x7] = compute_sha256_u32_array(input1, 0, 0);

    u256 {
        high: x0.into() * TWO_POW_96 + x1.into() * TWO_POW_64 + x2.into() * TWO_POW_32 + x3.into(),
        low: x4.into() * TWO_POW_96 + x5.into() * TWO_POW_64 + x6.into() * TWO_POW_32 + x7.into(),
    }
}
