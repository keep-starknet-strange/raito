use raito::engine::bits_to_target;

#[test]
fn test_bits_to_target_mantissa_zero() {
    let result = bits_to_target(0x04000000);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0_u256, "Target should be zero");
}

#[test]
fn test_bits_to_target_invalid_mantissa() {
    let result = bits_to_target(0x04800000);
    assert!(result.is_err(), "Should be invalid due to mantissa");
}

#[test]
fn test_bits_to_target_exponent_equal_3() {
    let result = bits_to_target(0x03123456);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x0000000000000000000000000000000000000000000000000000000000123456_u256,
        "Incorrect target for exp = 3"
    );
}

#[test]
fn test_bits_to_target_exponent_greater_than_3() {
    let result = bits_to_target(0x05012345);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x0000000000000000000000000000000000000000000000000000012345000000_u256,
        "Incorrect target for exp = 5"
    );
}

#[test]
fn test_bits_to_target_exponent_too_large() {
    let result = bits_to_target(0x20123456);
    assert!(result.is_err(), "Should be invalid due to large exponent");
}

#[test]
fn test_bits_to_target_max_target() {
    let result = bits_to_target(0x1d00ffff);
    assert!(result.is_err(), "Should be invalid due to exceeding MAX_TARGET");
}

#[test]
fn test_bits_to_target_overflow_target() {
    let result = bits_to_target(0x1e00ffff);
    assert!(result.is_err(), "Should be invalid due to overflow");
}

#[test]
fn test_bits_to_target_exponent_zero() {
    let result = bits_to_target(0x00012345);
    assert!(result.is_ok(), "Should be valid for exponent zero");
    assert!(
        result.unwrap() == 0x0000000000000000000000000000000000000000000000000000000000012345_u256,
        "Incorrect target for exp = 0"
    );
}

#[test]
fn test_bits_to_target_large_mantissa() {
    let result = bits_to_target(0x050FFFFF);
    assert!(result.is_ok(), "Should be valid for large mantissa");
    assert!(
        result.unwrap() == 0x00000000000000000000000000000000000000000000000000000FFFFF000000_u256,
        "Incorrect target for large mantissa"
    );
}