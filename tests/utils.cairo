fn hex_to_byte(h: u8) -> u8 {
    if h >= 48 && h <= 57 {
        return h - 48;
    } else if h >= 65 && h <= 70 {
        return h - 55;
    } else if h >= 97 && h <= 102 {
        return h - 87;
    }
    panic!("Wrong hex character: {h}");
    0
}

pub fn from_base16(hexs: @ByteArray) -> ByteArray {
    let mut result: ByteArray = Default::default();
    let mut i = 0;
    let len = hexs.len();
    while i < len {
        result.append_word(hex_to_byte(hexs.at(i).unwrap()).into(), 4);
        i += 1;
    };
    result
}
