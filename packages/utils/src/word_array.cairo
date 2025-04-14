//! Word array is an alternative to byte array, using a different
//! internal buffer representation, namely Array<u32> instead of
//! Array<byte31>.
//! It allows to avoid costly conversions when preparing inputs for
//! SHA256 hash function which operates on 4-byte words.

use core::traits::DivRem;
use utils::bit_shifts::pow256;

/// Array of 4-byte words where the last word can be partial.
#[derive(Drop, Debug, Default, PartialEq)]
pub struct WordArray {
    input: Array<u32>,
    last_input_word: u32,
    last_input_num_bytes: u32,
}

/// Span of a [WordArray]
#[derive(Copy, Drop, Debug, PartialEq)]
pub struct WordSpan {
    input: Span<u32>,
    last_input_word: u32,
    last_input_num_bytes: u32,
}

#[generate_trait]
pub impl WordSpanImpl of WordSpanTrait {
    /// Remove one item from the beginning of the [WordSpan] and return
    /// a pair (word, num_bytes) where num_bytes is in range [0; 4].
    /// Returns `Option::None` if the span is empty.
    fn pop_front(ref self: WordSpan) -> Option<(u32, u32)> {
        if let Option::Some(word) = self.input.pop_front() {
            Option::Some((*word, 4))
        } else if self.last_input_num_bytes != 0 {
            let res = (self.last_input_word, self.last_input_num_bytes);
            self.last_input_word = 0;
            self.last_input_num_bytes = 0;
            Option::Some(res)
        } else {
            Option::None
        }
    }

    /// Remove one item from the end of the [WordSpan] and return
    /// a pair (word, num_bytes) where num_bytes is in range [0; 4].
    /// Returns `Option::None` if the span is empty.
    fn pop_back(ref self: WordSpan) -> Option<(u32, u32)> {
        if let Option::Some(word) = self.input.pop_back() {
            if self.last_input_num_bytes == 0 {
                Option::Some((*word, 4))
            } else {
                let (div, mul) = match self.last_input_num_bytes {
                    0 => (1, 1),
                    1 => (0x1000000, 0x100),
                    2 => (0x10000, 0x10000),
                    3 => (0x100, 0x1000000),
                    _ => panic!("out of bounds `last_input_num_bytes`"),
                };
                let (q, r) = DivRem::div_rem(*word, div);
                let res = r * mul + self.last_input_word;
                self.last_input_word = q;
                Option::Some((res, 4))
            }
        } else if self.last_input_num_bytes != 0 {
            let res = (self.last_input_word, self.last_input_num_bytes);
            self.last_input_word = 0;
            self.last_input_num_bytes = 0;
            Option::Some(res)
        } else {
            Option::None
        }
    }
}

#[generate_trait]
pub impl WordArrayImpl of WordArrayTrait {
    /// Append full or partial word to the array.
    /// The array will be filled taking into account its last input word,
    /// so that there are no gaps.
    fn append_word(ref self: WordArray, word: u32, num_bytes: u32) {
        assert!(num_bytes <= 4, "Out of bounds `num_bytes`: {}", num_bytes);
        let (num_full_words, last_input_num_bytes) = DivRem::div_rem(
            self.last_input_num_bytes + num_bytes, 4,
        );

        if num_full_words == 1 {
            let (q, r) = if last_input_num_bytes == 0 {
                (word, 0)
            } else if last_input_num_bytes == 1 {
                DivRem::div_rem(word, 0x100)
            } else if last_input_num_bytes == 2 {
                DivRem::div_rem(word, 0x10000)
            } else {
                DivRem::div_rem(word, 0x1000000)
            };

            if self.last_input_num_bytes == 0 {
                // num_bytes == 4
                self.input.append(q);
            } else if self.last_input_num_bytes == 1 {
                // num_bytes >= 3
                self.input.append(self.last_input_word * 0x1000000 + q);
            } else if self.last_input_num_bytes == 2 {
                // num_bytes >= 2
                self.input.append(self.last_input_word * 0x10000 + q);
            } else {
                // num_bytes >= 1
                self.input.append(self.last_input_word * 0x100 + q);
            }

            self.last_input_word = r;
        } else {
            if num_bytes == 0 {
                return;
            } else if num_bytes == 1 {
                // self.last_input_num_bytes <= 2
                self.last_input_word = self.last_input_word * 0x100 + word;
            } else if num_bytes == 2 {
                // self.last_input_num_bytes <= 1
                self.last_input_word = self.last_input_word * 0x10000 + word;
            } else {
                // self.last_input_num_bytes == 0
                self.last_input_word = word;
            }
        }

        self.last_input_num_bytes = last_input_num_bytes;
    }

    /// Append a span of words to the array, one by one.
    fn append_span(ref self: WordArray, words: Span<u32>) {
        for word in words {
            self.append_word(*word, 4);
        }
    }

    /// Append a u32 number, reversing the byte order (little endian).
    fn append_u32_le(ref self: WordArray, value: u32) {
        // Split into bytes [r0 r1 r2 q2] in LE
        let (q0, r0) = DivRem::div_rem(value, 0x100);
        let (q1, r1) = DivRem::div_rem(q0, 0x100);
        let (q2, r2) = DivRem::div_rem(q1, 0x100);
        // Append in BE minding the last word
        if self.last_input_num_bytes == 0 {
            self.input.append(r0 * 0x1000000 + r1 * 0x10000 + r2 * 0x100 + q2)
        } else if self.last_input_num_bytes == 1 {
            self.input.append(self.last_input_word * 0x1000000 + r0 * 0x10000 + r1 * 0x100 + r2);
            self.last_input_word = q2;
        } else if self.last_input_num_bytes == 2 {
            self.input.append(self.last_input_word * 0x10000 + r0 * 0x100 + r1);
            self.last_input_word = r2 * 0x100 + q2;
        } else {
            self.input.append(self.last_input_word * 0x100 + r0);
            self.last_input_word = r1 * 0x10000 + r2 * 0x100 + q2;
        }
    }

    /// Append a u64 number, reversing the byte order (little endian).
    fn append_u64_le(ref self: WordArray, value: u64) {
        let (hi, lo) = DivRem::div_rem(value, 0x100000000);
        self.append_u32_le(lo.try_into().unwrap());
        self.append_u32_le(hi.try_into().unwrap());
    }

    /// Append a byte.
    fn append_u8(ref self: WordArray, value: u8) {
        if self.last_input_num_bytes == 0 {
            self.last_input_word = value.into();
            self.last_input_num_bytes = 1;
        } else if self.last_input_num_bytes == 1 {
            self.last_input_word = self.last_input_word * 0x100 + value.into();
            self.last_input_num_bytes = 2;
        } else if self.last_input_num_bytes == 2 {
            self.last_input_word = self.last_input_word * 0x100 + value.into();
            self.last_input_num_bytes = 3;
        } else {
            self.input.append(self.last_input_word * 0x100 + value.into());
            self.last_input_word = 0;
            self.last_input_num_bytes = 0;
        }
    }

    /// Append 31 bytes (max number of full bytes that single field element can store)
    fn append_bytes31(ref self: WordArray, value: felt252) {
        let bytes31: u256 = value.into(); // DivRem is not implemented for felt252
        let bytes28 = if self.last_input_num_bytes == 0 {
            let (bytes28, last_word) = DivRem::div_rem(bytes31, 0x1000000);
            self.last_input_word = last_word.try_into().expect('append_bytes31/1');
            self.last_input_num_bytes = 3;
            bytes28
        } else if self.last_input_num_bytes == 1 {
            let (first_word, bytes28) = DivRem::div_rem(
                bytes31, 0x100000000000000000000000000000000000000000000000000000000,
            );
            self.append_word(first_word.try_into().expect('append_bytes31/2'), 3);
            bytes28
        } else if self.last_input_num_bytes == 2 {
            let (bytes29, last_word) = DivRem::div_rem(bytes31, 0x100);
            let (first_word, bytes28) = DivRem::div_rem(
                bytes29, 0x100000000000000000000000000000000000000000000000000000000,
            );
            self.append_word(first_word.try_into().expect('append_bytes31/3'), 2);
            self.last_input_word = last_word.try_into().expect('4');
            self.last_input_num_bytes = 1;
            bytes28
        } else {
            let (bytes30, last_word) = DivRem::div_rem(bytes31, 0x10000);
            let (first_word, bytes28) = DivRem::div_rem(
                bytes30, 0x100000000000000000000000000000000000000000000000000000000,
            );
            self.append_word(first_word.try_into().expect('append_bytes31/5'), 1);
            self.last_input_word = last_word.try_into().expect('append_bytes31/6');
            self.last_input_num_bytes = 2;
            bytes28
        };

        let (q0, r0) = DivRem::div_rem(bytes28, 0x100000000);
        let (q1, r1) = DivRem::div_rem(q0, 0x100000000);
        let (q2, r2) = DivRem::div_rem(q1, 0x100000000);
        let (q3, r3) = DivRem::div_rem(q2, 0x100000000);
        let (q4, r4) = DivRem::div_rem(q3, 0x100000000);
        let (q5, r5) = DivRem::div_rem(q4, 0x100000000);
        self.input.append(q5.try_into().expect('append_bytes31/7'));
        self.input.append(r5.try_into().expect('append_bytes31/8'));
        self.input.append(r4.try_into().expect('append_bytes31/9'));
        self.input.append(r3.try_into().expect('append_bytes31/10'));
        self.input.append(r2.try_into().expect('append_bytes31/11'));
        self.input.append(r1.try_into().expect('append_bytes31/12'));
        self.input.append(r0.try_into().expect('append_bytes31/13'));
    }

    /// Append up to 31 bytes (byte length provided), packed in a single field element.
    fn append_bytes(ref self: WordArray, value: felt252, num_bytes: u32) {
        let bytes: u256 = value.into(); // DivRem is not implemented for felt252
        let (num_full_words, last_input_num_bytes) = DivRem::div_rem(
            self.last_input_num_bytes + num_bytes, 4,
        );

        if num_full_words != 0 {
            let (head, last_word) = if last_input_num_bytes == 0 {
                (bytes, 0)
            } else {
                DivRem::div_rem(bytes, pow256(last_input_num_bytes))
            };

            let (mut full_words, mut full_words_num_bytes) = if self.last_input_num_bytes == 0 {
                (head, num_bytes - last_input_num_bytes)
            } else {
                let first_word_num_bytes = 4 - self.last_input_num_bytes;
                let full_words_num_bytes = num_bytes - last_input_num_bytes - first_word_num_bytes;
                let (first_word, full_words) = DivRem::div_rem(head, pow256(full_words_num_bytes));
                self
                    .append_word(
                        first_word.try_into().expect('append_bytes/0'), first_word_num_bytes,
                    );
                (full_words, full_words_num_bytes)
            };

            if full_words_num_bytes != 0 {
                full_words_num_bytes -= 4;
                while full_words_num_bytes != 0 {
                    let (word, r) = DivRem::div_rem(full_words, pow256(full_words_num_bytes));
                    self.input.append(word.try_into().expect('append_bytes/1'));
                    full_words = r;
                    full_words_num_bytes -= 4;
                }
                self.input.append(full_words.try_into().expect('append_bytes/2'));
            }

            self.last_input_word = last_word.try_into().expect('append_bytes/3');
            self.last_input_num_bytes = last_input_num_bytes;
        } else {
            self.append_word(bytes.try_into().expect('append_bytes/3'), num_bytes);
        }
    }

    /// Split word array into components:
    /// (array of full 4-byte words, last word, number of bytes in the last word)
    fn into_components(self: WordArray) -> (Array<u32>, u32, u32) {
        (self.input, self.last_input_word, self.last_input_num_bytes)
    }

    /// Create a [WordSpan] out of the array snapshot.
    fn span(self: @WordArray) -> WordSpan {
        WordSpan {
            input: self.input.span(),
            last_input_word: *self.last_input_word,
            last_input_num_bytes: *self.last_input_num_bytes,
        }
    }

    /// Calculate array length in bytes
    fn byte_len(self: @WordArray) -> usize {
        self.input.len() * 4 + *self.last_input_num_bytes
    }
}

impl WordSpanIntoArray of Into<WordSpan, WordArray> {
    fn into(self: WordSpan) -> WordArray {
        WordArray {
            input: self.input.into(),
            last_input_word: self.last_input_word,
            last_input_num_bytes: self.last_input_num_bytes,
        }
    }
}

#[cfg(target: 'test')]
pub mod hex {
    use core::traits::DivRem;
    use crate::hex::hex_char_to_nibble;
    use super::{WordArray, WordArrayTrait, WordSpan, WordSpanTrait};

    /// Gets words from hex (base16).
    pub fn words_from_hex(hex_string: ByteArray) -> WordArray {
        let num_characters = hex_string.len();
        assert!(num_characters % 2 == 0, "Invalid hex string length");

        let mut words: WordArray = Default::default();
        let mut i = 0;

        while i != num_characters {
            let hi = hex_char_to_nibble(hex_string[i]);
            let lo = hex_char_to_nibble(hex_string[i + 1]);
            words.append_u8(hi * 16 + lo);
            i += 2;
        }

        words
    }

    /// Converts words to hex (base16).
    pub fn words_to_hex(mut words: WordSpan) -> ByteArray {
        let alphabet: @ByteArray = @"0123456789abcdef";
        let mut result: ByteArray = Default::default();

        while let Option::Some((word, num_bytes)) = words.pop_front() {
            for i in 0..num_bytes {
                let div: NonZero<u32> = match (num_bytes - 1 - i) {
                    0 => 1,
                    1 => 0x100,
                    2 => 0x10000,
                    3 => 0x1000000,
                    _ => panic!("num_bytes out of bounds"),
                };
                let (value, _) = DivRem::div_rem(word, div);
                let (_, value) = DivRem::div_rem(value, 0x100);
                let (l, r) = DivRem::div_rem(value, 16);
                result.append_byte(alphabet.at(l).expect('l'));
                result.append_byte(alphabet.at(r).expect('r'));
            }
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::hex::words_to_hex;
    use super::{WordArray, WordArrayTrait, WordSpanTrait};

    #[test]
    fn test_append_u8() {
        let mut words: WordArray = Default::default();
        words.append_u8(1);
        words.append_u8(2);
        words.append_u8(3);
        words.append_u8(4);
        words.append_u8(5);
        assert_eq!("0102030405", words_to_hex(words.span()));
    }

    #[test]
    fn test_append_u32_le() {
        let mut words: WordArray = Default::default();
        words.append_u32_le(1);
        assert_eq!("01000000", words_to_hex(words.span()));
        words.append_u32_le(0x01000000);
        assert_eq!("0100000000000001", words_to_hex(words.span()));

        let mut words: WordArray = Default::default();
        words.append_u8(0xff);
        words.append_u32_le(0x01020304);
        assert_eq!("ff04030201", words_to_hex(words.span()));
        words.append_u8(0xff);
        words.append_u32_le(0x04030201);
        assert_eq!("ff04030201ff01020304", words_to_hex(words.span()));
        words.append_u8(0xff);
        words.append_u32_le(1);
        assert_eq!("ff04030201ff01020304ff01000000", words_to_hex(words.span()));
    }

    #[test]
    fn test_append_u64_le() {
        let mut words: WordArray = Default::default();
        words.append_u64_le(0x0102030405060708);
        assert_eq!("0807060504030201", words_to_hex(words.span()));
    }

    #[test]
    fn test_append_word() {
        let mut words: WordArray = Default::default();
        words.append_word(1, 4);
        words.append_word(2, 1);
        words.append_word(3, 2);
        words.append_word(4, 3);
        assert_eq!("00000001020003000004", words_to_hex(words.span()));
    }

    #[test]
    fn test_append_span() {
        let mut words: WordArray = Default::default();
        words.append_span(array![1, 2, 3].span());
        assert_eq!("000000010000000200000003", words_to_hex(words.span()));
    }

    #[test]
    fn test_pop_front() {
        let mut words: WordArray = Default::default();
        words.append_word(1, 4);
        words.append_word(2, 1);
        let mut span = words.span();
        assert_eq!((1, 4), span.pop_front().unwrap());
        assert_eq!((2, 1), span.pop_front().unwrap());
        assert_eq!(Option::None, span.pop_front());
    }

    #[test]
    fn test_pop_back() {
        let mut words: WordArray = Default::default();
        words.append_word(1, 4);
        words.append_word(2, 1);
        let mut span = words.span();
        assert_eq!((0x00000102, 4), span.pop_back().unwrap());
        assert_eq!((0, 1), span.pop_back().unwrap());
        assert_eq!(Option::None, span.pop_back());
    }

    #[test]
    fn append_bytes31() {
        let mut words: WordArray = Default::default();
        words.append_bytes31(0x01020304050607080910111213141516171819202122232425262728293031);
        assert_eq!(
            "01020304050607080910111213141516171819202122232425262728293031",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xff, 1);
        words.append_bytes31(0x01020304050607080910111213141516171819202122232425262728293031);
        assert_eq!(
            "ff01020304050607080910111213141516171819202122232425262728293031",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xfffe, 2);
        words.append_bytes31(0x01020304050607080910111213141516171819202122232425262728293031);
        assert_eq!(
            "fffe01020304050607080910111213141516171819202122232425262728293031",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xfffefd, 3);
        words.append_bytes31(0x01020304050607080910111213141516171819202122232425262728293031);
        assert_eq!(
            "fffefd01020304050607080910111213141516171819202122232425262728293031",
            words_to_hex(words.span()),
        );
    }

    #[test]
    fn append_bytes() {
        let mut words: WordArray = Default::default();
        words.append_bytes(0x010203040506070809101112131415161718192021222324252627282930, 30);
        assert_eq!(
            "010203040506070809101112131415161718192021222324252627282930",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xff, 1);
        words.append_bytes(0x01020304050607080910111213141516171819202122232425262728, 28);
        assert_eq!(
            "ff01020304050607080910111213141516171819202122232425262728",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xfffe, 2);
        words.append_bytes(0x010203040506070809101112131415161718192021222324252627, 27);
        assert_eq!(
            "fffe010203040506070809101112131415161718192021222324252627",
            words_to_hex(words.span()),
        );

        let mut words: WordArray = Default::default();
        words.append_word(0xfffefd, 3);
        words.append_bytes(0x01, 1);
        assert_eq!("fffefd01", words_to_hex(words.span()));

        let mut words: WordArray = Default::default();
        words.append_word(0xfffefd, 3);
        words.append_bytes(0x0102, 2);
        assert_eq!("fffefd0102", words_to_hex(words.span()));
    }
}
