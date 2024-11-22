//! Word array is an alternative to byte array, using a different
//! internal buffer representation, namely Array<u32> instead of
//! Array<byte31>.
//! It allows to avoid costly conversions when preparing inputs for
//! SHA256 hash function which operates on 4-byte words.

use core::traits::DivRem;

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
            self.last_input_num_bytes + num_bytes, 4
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
            last_input_num_bytes: *self.last_input_num_bytes
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
        assert!(num_characters & 1 == 0, "Invalid hex string length");

        let mut words: WordArray = Default::default();
        let mut i = 0;

        while i != num_characters {
            let hi = hex_char_to_nibble(hex_string[i]);
            let lo = hex_char_to_nibble(hex_string[i + 1]);
            words.append_u8(hi * 16 + lo);
            i += 2;
        };

        words
    }

    /// Converts words to hex (base16).
    pub fn words_to_hex(mut words: WordSpan) -> ByteArray {
        let alphabet: @ByteArray = @"0123456789abcdef";
        let mut result: ByteArray = Default::default();

        while let Option::Some((word, num_bytes)) = words.pop_front() {
            for i in 0
                ..num_bytes {
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
        };

        result
    }
}

#[cfg(test)]
mod tests {
    use super::WordSpanTrait;
    use super::hex::words_to_hex;
    use super::{WordArray, WordArrayTrait};

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
}
