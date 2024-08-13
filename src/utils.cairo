use core::fmt::{Display, Formatter, Error};
use core::num::traits::{Zero, One, BitSize};
use core::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};
use core::to_byte_array::AppendFormattedToByteArray;

#[derive(Copy, Drop, Debug)]
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

        low += (a.into());
        low += shl((b.into()), 32_u32);
        low += shl((c.into()), 64_u32);
        low += shl((d.into()), 96_u32);

        high += (e.into());
        high += shl((f.into()), 32_u32);
        high += shl((g.into()), 64_u32);
        high += shl((h.into()), 96_u32);

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

pub fn double_sha256(a: @Hash, b: @Hash) -> Hash {
    let mut input1: Array<u32> = array![];
    input1.append_span(a.value.span());
    input1.append_span(b.value.span());

    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(input1, 0, 0).span());

    HashTrait::to_hash(compute_sha256_u32_array(input2, 0, 0))
}

fn hex_to_byte(h: u8) -> u8 {
    if h >= 48 && h <= 57 {
        return h - 48;
    } else if h >= 65 && h <= 70 {
        return h - 55;
    } else if h >= 97 && h <= 102 {
        return h - 87;
    }
    panic!("Wrong hex character: {h}");
    0
}

pub fn from_base16(hexs: ByteArray) -> @ByteArray {
    let mut result: ByteArray = Default::default();
    let mut i = 0;
    let len = hexs.len();
    while i < len {
        result.append_word(hex_to_byte(hexs.at(i).unwrap()).into(), 4);
        i += 1;
    };

    @result
}
