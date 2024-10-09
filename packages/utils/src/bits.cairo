use crate::bit_shifts::shr;

pub fn bit_len(n: u64) -> u64 {
    let mut x = n | shr(n, 1_u64);
    x = x | shr(x, 2_u64);
    x = x | shr(x, 4_u64);
    x = x | shr(x, 8_u64);
    x = x | shr(x, 16_u64);
    x = x | shr(x, 32_u64);
    x -= shr(x, 1_u64) & 0x5555555555555555_u64;
    x = (shr(x, 2_u64) & 0x3333333333333333_u64) + (x & 0x3333333333333333_u64);
    x = (shr(x, 4_u64) + x) & 0x0f0f0f0f0f0f0f0f_u64;
    x += shr(x, 8_u64);
    x += shr(x, 16_u64);
    x += shr(x, 32_u64);
    x & 0x7f_u64
}

#[cfg(test)]
mod tests {
    use super::bit_len;

    #[test]
    fn test_bit_len() {
        assert_eq!(bit_len(0), 0);
        assert_eq!(bit_len(1), 1);
        assert_eq!(bit_len(2), 2);
        assert_eq!(bit_len(3), 2);
        assert_eq!(bit_len(4), 3);
        assert_eq!(bit_len(7), 3);
        assert_eq!(bit_len(8), 4);
        assert_eq!(bit_len(9), 4);
        assert_eq!(bit_len(0x4000000000000000), 63);
        assert_eq!(bit_len(0x8000000000000000), 64);
        assert_eq!(bit_len(0xffffffffffffffff), 64);
    }
}
