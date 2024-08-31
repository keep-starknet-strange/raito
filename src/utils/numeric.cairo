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


#[cfg(test)]
mod tests {
    use super::u32_byte_reverse;

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
}
