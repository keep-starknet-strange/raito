//! Hash digest struct and trait implementations.

use core::fmt::{Display, Formatter, Error};
use core::to_byte_array::AppendFormattedToByteArray;
use super::bit_shifts::{shl, shr};

/// 256-bit hash digest.
/// Represented as an array of 4-byte words.
#[derive(Copy, Drop, Debug, Default)]
pub struct Hash {
    pub value: [u32; 8]
}

#[generate_trait]
pub impl HashImpl of HashTrait {
    #[inline(always)]
    fn new(array: [u32; 8]) -> Hash {
        Hash { value: array }
    }
}

/// Formats a `Hash` value for display.
impl HashDisplay of Display<Hash> {
    fn fmt(self: @Hash, ref f: Formatter) -> Result<(), Error> {
        let hash: u256 = (*self).into();
        hash.append_formatted_to_byte_array(ref f.buffer, 16);
        Result::Ok(())
    }
}

/// Compares two `Hash` values for equality.
impl HashPartialEq of PartialEq<Hash> {
    fn eq(lhs: @Hash, rhs: @Hash) -> bool {
        lhs.value == rhs.value
    }
}

/// Converts a `Hash` value into a `ByteArray`.
pub impl HashIntoByteArray of Into<Hash, ByteArray> {
    fn into(self: Hash) -> ByteArray {
        let mut bytes: ByteArray = Default::default();
        for word in self.value.span() {
            bytes.append_word((*word).into(), 4);
        };
        bytes
    }
}

/// Converts a `u256` value into a `Hash` type.
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

/// Converts a `Hash` value into a `u256` type and reverse bytes order.
/// Hash is little-endian order, while u256 is big-endian like in explorer.
pub impl HashIntoU256 of Into<Hash, u256> {
    fn into(self: Hash) -> u256 {
        let [mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut h] = self.value;

        let mut low: u128 = 0;
        let mut high: u128 = 0;

        helper_hash_into_u256(ref h, ref high, false);
        helper_hash_into_u256(ref g, ref high, false);
        helper_hash_into_u256(ref f, ref high, false);
        helper_hash_into_u256(ref e, ref high, true);

        helper_hash_into_u256(ref d, ref low, false);
        helper_hash_into_u256(ref c, ref low, false);
        helper_hash_into_u256(ref b, ref low, false);
        helper_hash_into_u256(ref a, ref low, true);

        u256 { high, low }
    }
}

fn helper_hash_into_u256(ref value: u32, ref result: u128, is_last: bool) {
    let mut i: u8 = 0;
    while (i < 4) {
        result += (value & 0x000000ff).into();
        if (!is_last || i != 3) {
            result = shl(result, 8_u128);
            value = shr(value, 8_u32);
        }
        i += 1;
    };
}

#[cfg(test)]
mod tests {
    use super::Hash;
    use raito::utils::hex::from_hex;

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
            high: 0xefcdab9078563412efcdab9078563412_u128,
            low: 0x2143658709badcfe2143658709badcfe_u128,
        };

        assert_eq!(result_u256, expected_u256, "invalid results");
    }

    #[test]
    fn test_hash_into_bytearray() {
        let hash = Hash {
            value: [
                0x12345678_u32,
                0x9abcdef0_u32,
                0x11223344_u32,
                0x55667788_u32,
                0xaabbccdd_u32,
                0xeeff0011_u32,
                0x22334455_u32,
                0x66778899_u32
            ]
        };

        let byte_array: ByteArray = hash.into();

        let expected_byte_array = from_hex(
            "123456789abcdef01122334455667788aabbccddeeff00112233445566778899"
        );

        assert_eq!(byte_array, expected_byte_array, "invalid results");
    }
}
