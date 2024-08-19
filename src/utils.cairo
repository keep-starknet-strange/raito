use core::fmt::{Display, Formatter, Error};
use core::num::traits::{Zero, One, BitSize};
use core::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};
use core::to_byte_array::AppendFormattedToByteArray;

#[derive(Copy, Drop, Debug, Default)]
// pub is required here as we define Hash in utils and we need to import Hash in merkle_tree.cairo
// for arguments to merkle_root function
pub struct Hash {
    pub value: [u32; 8]
}

#[generate_trait]
pub impl HashImpl of HashTrait {
    #[inline(always)]
    fn to_hash(array: [u32; 8]) -> Hash {
        Hash { value: array }
    }
}

impl HashDisplay of Display<Hash> {
    fn fmt(self: @Hash, ref f: Formatter) -> Result<(), Error> {
        let hash: u256 = (*self).into();
        hash.append_formatted_to_byte_array(ref f.buffer, 16);
        Result::Ok(())
    }
}

impl HashPartialEq of PartialEq<Hash> {
    fn eq(lhs: @Hash, rhs: @Hash) -> bool {
        lhs.value == rhs.value
    }
}

pub impl HashIntoByteArray of Into<Hash, ByteArray> {
    fn into(self: Hash) -> ByteArray {
        let mut bytes: ByteArray = Default::default();
        for word in self.value.span() {
            bytes.append_word((*word).into(), 4);
        };
        bytes
    }
}

pub impl U256IntoHash of Into<u256, Hash> {
    fn into(self: u256) -> Hash {
        let mut result: Array<u32> = array![];
        let mut low: u128 = self.low;
        let mut high: u128 = self.high;

        let mut i = 0;
        loop {
            if i == 4 {
                break;
            }
            result.append((low & 0xffffffff).try_into().unwrap());
            low = shr(low, 32_u32);
            i += 1;
        };

        let mut i = 0;
        loop {
            if i == 4 {
                break;
            }
            result.append((high & 0xffffffff).try_into().unwrap());
            high = shr(high, 32_u32);
            i += 1;
        };

        Hash {
            value: [
                *result[7],
                *result[6],
                *result[5],
                *result[4],
                *result[3],
                *result[2],
                *result[1],
                *result[0],
            ]
        }
    }
}

pub impl HashIntoU256 of Into<Hash, u256> {
    fn into(self: Hash) -> u256 {
        let [a, b, c, d, e, f, g, h] = self.value;

        let mut low: u128 = 0;
        let mut high: u128 = 0;

        low += (h.into());
        low += shl((g.into()), 32_u32);
        low += shl((f.into()), 64_u32);
        low += shl((e.into()), 96_u32);

        high += (d.into());
        high += shl((c.into()), 32_u32);
        high += shl((b.into()), 64_u32);
        high += shl((a.into()), 96_u32);

        u256 { low, high }
    }
}

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

/// Calculate double sha256 digest of a concatenation of two hashes
pub fn double_sha256_parent(a: @Hash, b: @Hash) -> Hash {
    let mut input1: Array<u32> = array![];
    input1.append_span(a.value.span());
    input1.append_span(b.value.span());

    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(input1, 0, 0).span());

    HashTrait::to_hash(compute_sha256_u32_array(input2, 0, 0))
}

/// Calculate double sha256 digest of bytes
pub fn double_sha256_byte_array(bytes: @ByteArray) -> Hash {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_byte_array(bytes).span());

    HashTrait::to_hash(compute_sha256_u32_array(input2, 0, 0))
}

/// Calculate double sha256 digest of an array of full 4 byte words
///
/// It's important that there are no trailing bytes, otherwise the
/// data will be truncated.
pub fn double_sha256_u32_array(words: Array<u32>) -> Hash {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(words, 0, 0).span());

    HashTrait::to_hash(compute_sha256_u32_array(input2, 0, 0))
}

#[cfg(test)]
mod tests {
    use super::{
        double_sha256_byte_array, double_sha256_u32_array, double_sha256_parent, Hash, fast_pow,
        shl, shr
    };
    use super::super::test_utils::from_hex;

    #[test]
    fn test_double_sha256_byte_array() {
        // hashlib.sha256(sha256(b"bitcoin").digest()).hexdigest()
        assert_eq!(
            double_sha256_byte_array(@"bitcoin").into(),
            from_hex("f1ef1bf105d788352c052453b15a913403be59b90ddf9f7c1f937edee8938dc5")
        )
    }

    #[test]
    fn test_double_sha256_u32_array() {
        // hashlib.sha256(sha256(bytes.fromhex("00000001000000020000000300000004000000050000000600000007")).digest()).hexdigest()
        assert_eq!(
            double_sha256_u32_array(array![1, 2, 3, 4, 5, 6, 7]).into(),
            from_hex("489b8eeb4024cb77ab057616ebf7f8d4405aa0bd3ad5f42e6b4c20580e011ac4")
        )
    }

    #[test]
    fn test_double_sha256_parent() {
        // hashlib.sha256(sha256(bytes.fromhex("00000001" * 8 + "00000002" *
        // 8)).digest()).hexdigest()
        assert_eq!(
            double_sha256_parent(@Hash { value: [1; 8] }, @Hash { value: [2; 8] }).into(),
            from_hex("14a6e4a4caef969126944266724d11866b39b3390cee070b0aa4c9390cd77f47")
        )
    }

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
    fn test_u256_into_hash() {
        let u256_value = u256 {
            low: 0x1234567890abcdef1234567890abcdef_u128,
            high: 0xfedcba0987654321fedcba0987654321_u128,
        };

        let result_hash = u256_value.into();

        let expected_hash = Hash {
            value: [
                0xfedcba09,
                0x87654321,
                0xfedcba09,
                0x87654321,
                0x12345678,
                0x90abcdef,
                0x12345678,
                0x90abcdef,
            ],
        };

        assert_eq!(result_hash, expected_hash, "invalid results");
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

    fn test_hash_to_u256() {
        let hash_value = Hash {
            value: [
                0xfedcba09,
                0x87654321,
                0xfedcba09,
                0x87654321,
                0x12345678,
                0x90abcdef,
                0x12345678,
                0x90abcdef,
            ],
        };

        let result_u256 = hash_value.into();

        let expected_u256 = u256 {
            high: 0xfedcba0987654321fedcba0987654321_u128,
            low: 0x1234567890abcdef1234567890abcdef_u128,
        };

        assert_eq!(result_u256, expected_u256, "invalid results");
    }
}
