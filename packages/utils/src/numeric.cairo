//! Numeric helpers.

use crate::bit_shifts::shr_u64;

/// Computes the next power of two of a `u64` variable.
/// Returns 2^x, where x is the smallest integer such that 2^x >= n.
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

/// Converts a u128 number into an array of 4 u32 numbers (big endian).
pub fn u128_to_u32_array(value: u128) -> Array<u32> {
    let (abc, d) = DivRem::div_rem(value, 0x100000000);
    let (ab, c) = DivRem::div_rem(abc, 0x100000000);
    let (a, b) = DivRem::div_rem(ab, 0x100000000);
    let a: u32 = a.try_into().unwrap();
    let b: u32 = b.try_into().unwrap();
    let c: u32 = c.try_into().unwrap();
    let d: u32 = d.try_into().unwrap();
    array![a, b, c, d]
}

#[cfg(test)]
mod tests {
    use super::u64_next_power_of_two;

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
