use crate::bit_shifts::{shr_u64, shr};

/// Reverses the byte order of a `u32`.
///
/// This function takes a 32-bit unsigned integer and reverses the order of its bytes.
/// It is useful for converting between big-endian and little-endian formats.
pub fn u32_byte_reverse(word: u32) -> u32 {
    let byte0 = (word & 0x000000FF) * 0x1000000_u32;
    let byte1 = (word & 0x0000FF00) * 0x00000100_u32;
    let byte2 = (word & 0x00FF0000) / 0x00000100_u32;
    let byte3 = (word & 0xFF000000) / 0x1000000_u32;
    return byte0 + byte1 + byte2 + byte3;
}

/// Computes the next power of two of a u64 variable.
pub fn u64_next_power_of_two(mut n: u64) -> u64 {
    if n == 0 {
        return 1;
    }

    n -= 1;
    n = n | shr_u64(n, 1_u32);
    n = n | shr_u64(n, 2_u32);
    n = n | shr_u64(n, 4_u32);
    n = n | shr_u64(n, 8_u32);
    n = n | shr_u64(n, 16_u32);
    n = n | shr_u64(n, 32_u32);

    n + 1
}

#[cfg(test)]
mod tests {
    use super::{u32_byte_reverse, u64_next_power_of_two};

    #[test]
    fn test_u32_byte_reverse() {
        let input: u32 = 0x12345678;
        let expected_output: u32 = 0x78563412;
        let result = u32_byte_reverse(input);
        assert_eq!(result, expected_output);

        let input: u32 = 0xAABBCCDD;
        let expected_output: u32 = 0xDDCCBBAA;
        let result = u32_byte_reverse(input);
        assert_eq!(result, expected_output);

        let input: u32 = 0x000000FF;
        let expected_output: u32 = 0xFF000000;
        let result = u32_byte_reverse(input);
        assert_eq!(result, expected_output);

        let input: u32 = 0x00FF00FF;
        let expected_output: u32 = 0xFF00FF00;
        let result = u32_byte_reverse(input);
        assert_eq!(result, expected_output);

        let input: u32 = 0x00000000;
        let expected_output: u32 = 0x00000000;
        let result = u32_byte_reverse(input);
        assert_eq!(result, expected_output);
    }

    #[test]
    fn test_u64_next_power_of_two() {
        let input: u64 = 3;
        let expected_output: u64 = 4;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 5;
        let expected_output: u64 = 8;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 11;
        let expected_output: u64 = 16;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 20;
        let expected_output: u64 = 32;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 61;
        let expected_output: u64 = 64;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 100;
        let expected_output: u64 = 128;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 189;
        let expected_output: u64 = 256;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 480;
        let expected_output: u64 = 512;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 777;
        let expected_output: u64 = 1024;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 1025;
        let expected_output: u64 = 2048;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 4095;
        let expected_output: u64 = 4096;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);

        let input: u64 = 1500000000000000000;
        let expected_output: u64 = 2305843009213693952;
        let result = u64_next_power_of_two(input);
        assert_eq!(result, expected_output);
    }
}
