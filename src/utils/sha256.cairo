//! Helpers for calculating double SHA256 hash digest.

use core::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};
use super::hash::{Digest, DigestTrait};

/// Calculate double sha256 digest of a concatenation of two hashes
pub fn double_sha256_parent(a: @Digest, b: @Digest) -> Digest {
    let mut input1: Array<u32> = array![];
    input1.append_span(a.value.span());
    input1.append_span(b.value.span());

    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(input1, 0, 0).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

/// Calculate double sha256 digest of bytes
pub fn double_sha256_byte_array(bytes: @ByteArray) -> Digest {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_byte_array(bytes).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

/// Calculate double sha256 digest of an array of full 4 byte words
///
/// It's important that there are no trailing bytes, otherwise the
/// data will be truncated.
pub fn double_sha256_u32_array(words: Array<u32>) -> Digest {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(words, 0, 0).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

#[cfg(test)]
mod tests {
    use crate::utils::{hex::from_hex, hash::Digest};
    use super::{double_sha256_byte_array, double_sha256_u32_array, double_sha256_parent};

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
            double_sha256_parent(@Digest { value: [1; 8] }, @Digest { value: [2; 8] }).into(),
            from_hex("14a6e4a4caef969126944266724d11866b39b3390cee070b0aa4c9390cd77f47")
        )
    }
}
