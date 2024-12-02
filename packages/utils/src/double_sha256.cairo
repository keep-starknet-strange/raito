use super::word_array::WordArrayTrait;
//! Helpers for calculating double SHA256 hash digest.

use super::hash::{Digest, DigestTrait};
use super::sha256::compute_sha256_u32_array;
use super::word_array::WordArray;

/// Calculates double sha256 digest of a concatenation of two hashes.
pub fn double_sha256_parent(a: @Digest, b: @Digest) -> Digest {
    let mut input1: Array<u32> = array![];
    input1.append_span(a.value.span());
    input1.append_span(b.value.span());

    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(input1, 0, 0).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

pub fn double_sha256_word_array(words: WordArray) -> Digest {
    let (input, last_input_word, last_input_num_bytes) = words.into_components();

    let mut input2: Array<u32> = array![];
    input2
        .append_span(compute_sha256_u32_array(input, last_input_word, last_input_num_bytes).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

#[cfg(test)]
mod tests {
    use crate::{hex::from_hex, hash::Digest, word_array::hex::words_from_hex};
    use super::{double_sha256_word_array, double_sha256_parent};

    #[test]
    fn test_double_sha256_word_array() {
        // hashlib.sha256(sha256(b"bitcoin").digest()).hexdigest()
        assert_eq!(
            double_sha256_word_array(words_from_hex("626974636f696e")).into(),
            from_hex("f1ef1bf105d788352c052453b15a913403be59b90ddf9f7c1f937edee8938dc5"),
        );

        // hashlib.sha256(sha256(bytes.fromhex("00000001000000020000000300000004000000050000000600000007")).digest()).hexdigest()
        assert_eq!(
            double_sha256_word_array(
                words_from_hex("00000001000000020000000300000004000000050000000600000007"),
            )
                .into(),
            from_hex("489b8eeb4024cb77ab057616ebf7f8d4405aa0bd3ad5f42e6b4c20580e011ac4"),
        );
    }

    #[test]
    fn test_double_sha256_parent() {
        // hashlib.sha256(sha256(bytes.fromhex("00000001" * 8 + "00000002" *
        // 8)).digest()).hexdigest()
        assert_eq!(
            double_sha256_parent(@Digest { value: [1; 8] }, @Digest { value: [2; 8] }).into(),
            from_hex("14a6e4a4caef969126944266724d11866b39b3390cee070b0aa4c9390cd77f47"),
        )
    }
}
