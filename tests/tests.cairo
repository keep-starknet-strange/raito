use raito::validation::bits_to_target;

#[test]
fn test_bits_to_target_01003456() {
    let result = bits_to_target(0x01003456);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0x00_u256, "Incorrect target for 0x01003456");
}

#[test]
fn test_bits_to_target_01123456() {
    let result = bits_to_target(0x01123456);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0x12_u256, "Incorrect target for 0x01123456");
}

#[test]
fn test_bits_to_target_02008000() {
    let result = bits_to_target(0x02008000);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0x80_u256, "Incorrect target for 0x02008000");
}

#[test]
fn test_bits_to_target_181bc330() {
    let result = bits_to_target(0x181bc330);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x1bc330000000000000000000000000000000000000000000_u256,
        "Incorrect target for 0x181bc330"
    );
}

#[test]
fn test_bits_to_target_05009234() {
    let result = bits_to_target(0x05009234);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0x92340000_u256, "Incorrect target for 0x05009234");
}

#[test]
fn test_bits_to_target_04123456() {
    let result = bits_to_target(0x04123456);
    assert!(result.is_ok(), "Should be valid");
    assert!(result.unwrap() == 0x12345600_u256, "Incorrect target for 0x04123456");
}

#[test]
fn test_bits_to_target_1d00ffff() {
    let result = bits_to_target(0x1d00ffff);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x00000000ffff0000000000000000000000000000000000000000000000000000_u256,
        "Incorrect target for 0x1d00ffff"
    );
}

#[test]
fn test_bits_to_target_1c0d3142() {
    let result = bits_to_target(0x1c0d3142);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x000000000d314200000000000000000000000000000000000000000000000000_u256,
        "Incorrect target for 0x1c0d3142"
    );
}

#[test]
fn test_bits_to_target_1707a429() {
    let result = bits_to_target(0x1707a429);
    assert!(result.is_ok(), "Should be valid");
    assert!(
        result.unwrap() == 0x00000000000000000007a4290000000000000000000000000000000000000000_u256,
        "Incorrect target for 0x1707a429"
    );
}
