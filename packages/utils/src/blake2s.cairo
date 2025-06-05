//! Blake2s helpers.

use core::blake::{blake2s_finalize, blake2s_compress};
use core::box::BoxImpl;
use crate::hash::{Digest, DigestTrait};

const BLAKE2S_256_IV: [u32; 8] = [
    0x6B08E647, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
];

/// Compute the 32-byte digest of a message using Blake2s hash function.
/// Message is expected to be a sequence of 4-byte words, padded with zeros if needed.
pub fn blake2s_32(mut data: Span<u32>) -> Digest {
    let mut state = BoxImpl::new(BLAKE2S_256_IV);
    let mut buffer: Array<u32> = array![];
    let mut byte_count: u32 = 0;

    while let Some(word) = data.pop_front() {
        buffer.append(*word);
        byte_count += 4;

        if buffer.len() == 16 {
            let msg = buffer.span().try_into().expect('Cast to @Blake2sInput (1)');
            blake2s_compress(state, byte_count, *msg);
            buffer = array![];
        }
    }

    for _ in buffer.len()..16 {
        buffer.append(0);
    }

    let msg = buffer.span().try_into().expect('Cast to @Blake2sInput (2)');
    let res = blake2s_finalize(state, byte_count, *msg);

    DigestTrait::new(res.unbox())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_blake2s_32() {
        let data = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
        let digest: u256 = blake2s_32(data.span()).into();
        assert_eq!(digest, 15974411367510466476151912386582936359743734459170386606263259213710529591061);
    }
}
