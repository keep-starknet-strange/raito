// SPDX-FileCopyrightText: 2024 StarkWare Industries <contact@starkware.co>
//
// SPDX-License-Identifier: Apache-2.0

//! Helpers for calculating double SHA256 hash digest.

use core::num::traits::{Bounded, OverflowingAdd};

/// Cairo implementation of the corelib `compute_sha256_byte_array` function.
pub fn compute_sha256_byte_array(arr: @ByteArray) -> [u32; 8] {
    let mut word_arr = array![];
    let len = arr.len();
    let rem = len % 4;
    let mut index = 0;
    let rounded_len = len - rem;
    while index != rounded_len {
        let word = arr.at(index + 3).unwrap().into()
            + arr.at(index + 2).unwrap().into() * 0x100
            + arr.at(index + 1).unwrap().into() * 0x10000
            + arr.at(index).unwrap().into() * 0x1000000;
        word_arr.append(word);
        index = index + 4;
    };
    let last = match rem {
        0 => 0,
        1 => arr.at(len - 1).unwrap().into(),
        2 => arr.at(len - 1).unwrap().into() + arr.at(len - 2).unwrap().into() * 0x100,
        _ => arr.at(len - 1).unwrap().into()
            + arr.at(len - 2).unwrap().into() * 0x100
            + arr.at(len - 3).unwrap().into() * 0x10000,
    };

    compute_sha256_u32_array(word_arr, last, rem.into())
}

/// Cairo implementation of the corelib `compute_sha256_u32_array` function.
pub fn compute_sha256_u32_array(
    mut input: Array<u32>, last_input_word: u32, last_input_num_bytes: u32
    ) -> [
    u32
; 8] {
    add_sha256_padding(ref input, last_input_word, last_input_num_bytes);

    let result = sha256_inner(input.span(), 0, k.span(), h.span());

    [*result[0], *result[1], *result[2], *result[3], *result[4], *result[5], *result[6], *result[7]]
}

/// Adds padding to the input array for SHA-256. The padding is defined as follows:
/// 1. Append a single bit with value 1 to the end of the array.
/// 2. Append zeros until the length of the array is 448 mod 512.
/// 3. Append the length of the array in bits as a 64-bit number.
/// use last_input_word when the number of bytes in the last input word is less than 4.
fn add_sha256_padding(ref arr: Array<u32>, last_input_word: u32, last_input_num_bytes: u32) {
    let len = arr.len();
    if last_input_num_bytes == 0 {
        arr.append(0x80000000);
    } else {
        let (q, m, pad) = if last_input_num_bytes == 1 {
            (0x100, 0x1000000, 0x800000)
        } else if last_input_num_bytes == 2 {
            (0x10000, 0x10000, 0x8000)
        } else {
            (0x1000000, 0x100, 0x80)
        };
        let (_, r) = core::integer::u32_safe_divmod(last_input_word, q);
        arr.append(r * m + pad);
    }

    let mut remaining: felt252 = 16 - ((arr.len() + 1) % 16).into();

    append_zeros(ref arr, remaining);

    arr.append(len * 32 + last_input_num_bytes * 8);
}

/// Appends `count` zeros to the array.
fn append_zeros(ref arr: Array<u32>, count: felt252) {
    if count == 0 {
        return;
    }
    arr.append(0);
    if count == 1 {
        return;
    }
    arr.append(0);
    if count == 2 {
        return;
    }
    arr.append(0);
    if count == 3 {
        return;
    }
    arr.append(0);
    if count == 4 {
        return;
    }
    arr.append(0);
    if count == 5 {
        return;
    }
    arr.append(0);
    if count == 6 {
        return;
    }
    arr.append(0);
    if count == 7 {
        return;
    }
    arr.append(0);
    if count == 8 {
        return;
    }
    arr.append(0);
    if count == 9 {
        return;
    }
    arr.append(0);
    if count == 10 {
        return;
    }
    arr.append(0);
    if count == 11 {
        return;
    }
    arr.append(0);
    if count == 12 {
        return;
    }
    arr.append(0);
    if count == 13 {
        return;
    }
    arr.append(0);
    if count == 14 {
        return;
    }
    arr.append(0);
    if count == 15 {
        return;
    }
    arr.append(0);
}

fn sha256_inner(mut data: Span<u32>, i: usize, k: Span<u32>, mut h: Span<u32>) -> Span<u32> {
    if 16 * i >= data.len() {
        return h;
    }
    let w = create_message_schedule(data, i);
    let h2 = compression(w, 0, k, h);

    let mut t = array![];
    let (tmp, _) = (*h[0]).overflowing_add(*h2[0]);
    t.append(tmp);
    let (tmp, _) = (*h[1]).overflowing_add(*h2[1]);
    t.append(tmp);
    let (tmp, _) = (*h[2]).overflowing_add(*h2[2]);
    t.append(tmp);
    let (tmp, _) = (*h[3]).overflowing_add(*h2[3]);
    t.append(tmp);
    let (tmp, _) = (*h[4]).overflowing_add(*h2[4]);
    t.append(tmp);
    let (tmp, _) = (*h[5]).overflowing_add(*h2[5]);
    t.append(tmp);
    let (tmp, _) = (*h[6]).overflowing_add(*h2[6]);
    t.append(tmp);
    let (tmp, _) = (*h[7]).overflowing_add(*h2[7]);
    t.append(tmp);
    h = t.span();
    sha256_inner(data, i + 1, k, h)
}

fn compression(w: Span<u32>, i: usize, k: Span<u32>, mut h: Span<u32>) -> Span<u32> {
    if i >= 64 {
        return h;
    }
    let s1 = bsig1(*h[4]);
    let ch = ch(*h[4], *h[5], *h[6]);
    let (tmp, _) = (*h[7]).overflowing_add(s1);
    let (tmp, _) = tmp.overflowing_add(ch);
    let (tmp, _) = tmp.overflowing_add(*k[i]);
    let (temp1, _) = tmp.overflowing_add(*w[i]);
    let s0 = bsig0(*h[0]);
    let maj = maj(*h[0], *h[1], *h[2]);
    let (temp2, _) = s0.overflowing_add(maj);
    let mut t = array![];
    let (temp3, _) = temp1.overflowing_add(temp2);
    t.append(temp3);
    t.append(*h[0]);
    t.append(*h[1]);
    t.append(*h[2]);
    let (temp3, _) = (*h[3]).overflowing_add(temp1);
    t.append(temp3);
    t.append(*h[4]);
    t.append(*h[5]);
    t.append(*h[6]);
    h = t.span();
    compression(w, i + 1, k, h)
}

fn create_message_schedule(data: Span<u32>, i: usize) -> Span<u32> {
    let mut j = 0;
    let mut result = array![];
    while (j < 16) {
        result.append(*data[i * 16 + j]);
        j += 1;
    };
    let mut i = 16;
    while (i < 64) {
        let s0 = ssig0(*result[i - 15]);
        let s1 = ssig1(*result[i - 2]);

        let (tmp, _) = (*result[i - 16]).overflowing_add(s0);
        let (tmp, _) = tmp.overflowing_add(*result[i - 7]);
        let (res, _) = tmp.overflowing_add(s1);
        result.append(res);
        i += 1;
    };
    result.span()
}

fn ch(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ ((x ^ Bounded::<u32>::MAX.into()) & z)
}

fn maj(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (x & z) ^ (y & z)
}

fn bsig0(x: u32) -> u32 {
    let x: u128 = x.into();
    let x1 = (x / 0x4) | (x * 0x40000000);
    let x2 = (x / 0x2000) | (x * 0x80000);
    let x3 = (x / 0x400000) | (x * 0x400);
    let result = (x1 ^ x2 ^ x3) & Bounded::<u32>::MAX.into();

    result.try_into().unwrap()
}

fn bsig1(x: u32) -> u32 {
    let x: u128 = x.into();
    let x1 = (x / 0x40) | (x * 0x4000000);
    let x2 = (x / 0x800) | (x * 0x200000);
    let x3 = (x / 0x2000000) | (x * 0x80);
    let result = (x1 ^ x2 ^ x3) & Bounded::<u32>::MAX.into();

    result.try_into().unwrap()
}

fn ssig0(x: u32) -> u32 {
    let x: u128 = x.into();
    let x1 = (x / 0x80) | (x * 0x2000000);
    let x2 = (x / 0x40000) | (x * 0x4000);
    let x3 = (x / 0x8);
    let result = (x1 ^ x2 ^ x3) & Bounded::<u32>::MAX.into();

    result.try_into().unwrap()
}

fn ssig1(x: u32) -> u32 {
    let x: u128 = x.into();
    let x1 = (x / 0x20000) | (x * 0x8000);
    let x2 = (x / 0x80000) | (x * 0x2000);
    let x3 = (x / 0x400);
    let result = (x1 ^ x2 ^ x3) & Bounded::<u32>::MAX.into();

    result.try_into().unwrap()
}

const h: [
    u32
    ; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
];

const k: [
    u32
    ; 64] = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2
];
// #[cfg(test)]
// mod tests {
//     use super::sha256;

//     #[test]
//     fn test_cairo_sha256() {
//         let mut input: Array<u8> = array![];
//         let result = sha256(input);

//         // 0xE3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
//         assert_eq!(result.len(), 32);
//         assert_eq!(*result[0], 0xE3);
//         assert_eq!(*result[1], 0xB0);
//         assert_eq!(*result[2], 0xC4);
//         assert_eq!(*result[3], 0x42);
//         assert_eq!(*result[4], 0x98);
//         assert_eq!(*result[5], 0xFC);
//         assert_eq!(*result[6], 0x1C);
//         assert_eq!(*result[7], 0x14);
//         assert_eq!(*result[8], 0x9A);
//         assert_eq!(*result[9], 0xFB);
//         assert_eq!(*result[10], 0xF4);
//         assert_eq!(*result[11], 0xC8);
//         assert_eq!(*result[12], 0x99);
//         assert_eq!(*result[13], 0x6F);
//         assert_eq!(*result[14], 0xB9);
//         assert_eq!(*result[15], 0x24);
//         assert_eq!(*result[16], 0x27);
//         assert_eq!(*result[17], 0xAE);
//         assert_eq!(*result[18], 0x41);
//         assert_eq!(*result[19], 0xE4);
//         assert_eq!(*result[20], 0x64);
//         assert_eq!(*result[21], 0x9B);
//         assert_eq!(*result[22], 0x93);
//         assert_eq!(*result[23], 0x4C);
//         assert_eq!(*result[24], 0xA4);
//         assert_eq!(*result[25], 0x95);
//         assert_eq!(*result[26], 0x99);
//         assert_eq!(*result[27], 0x1B);
//         assert_eq!(*result[28], 0x78);
//         assert_eq!(*result[29], 0x52);
//         assert_eq!(*result[30], 0xB8);
//         assert_eq!(*result[31], 0x55);

//         let input: Array<u8> = array!['a', 'b', 'c'];
//         let result = sha256(input);

//         // 0xba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
//         assert_eq!(result.len(), 32);
//         assert_eq!(*result[0], 0xba);
//         assert_eq!(*result[1], 0x78);
//         assert_eq!(*result[2], 0x16);
//         assert_eq!(*result[3], 0xbf);
//         assert_eq!(*result[4], 0x8f);
//         assert_eq!(*result[5], 0x01);
//         assert_eq!(*result[6], 0xcf);
//         assert_eq!(*result[7], 0xea);
//         assert_eq!(*result[8], 0x41);
//         assert_eq!(*result[9], 0x41);
//         assert_eq!(*result[10], 0x40);
//         assert_eq!(*result[11], 0xde);
//         assert_eq!(*result[12], 0x5d);
//         assert_eq!(*result[13], 0xae);
//         assert_eq!(*result[14], 0x22);
//         assert_eq!(*result[15], 0x23);
//         assert_eq!(*result[16], 0xb0);
//         assert_eq!(*result[17], 0x03);
//         assert_eq!(*result[18], 0x61);
//         assert_eq!(*result[19], 0xa3);
//         assert_eq!(*result[20], 0x96);
//         assert_eq!(*result[21], 0x17);
//         assert_eq!(*result[22], 0x7a);
//         assert_eq!(*result[23], 0x9c);
//         assert_eq!(*result[24], 0xb4);
//         assert_eq!(*result[25], 0x10);
//         assert_eq!(*result[26], 0xff);
//         assert_eq!(*result[27], 0x61);
//         assert_eq!(*result[28], 0xf2);
//         assert_eq!(*result[29], 0x00);
//         assert_eq!(*result[30], 0x15);
//         assert_eq!(*result[31], 0xad);
//     }
// }


