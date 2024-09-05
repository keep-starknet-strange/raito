//! Bitcoin binary codec traits, implementations, and helpers.

use super::types::transaction::{TxIn, TxOut, OutPoint};
use raito::utils::hash::Hash;

pub trait Encode<T> {
    /// Encode using Bitcoin codec, append to the buffer and retour byte size.
    fn encode_to(self: @T, ref dest: ByteArray) -> usize;

    /// Encode using Bitcoin codec and return (byte array, size).
    fn encode(
        self: @T
    ) -> (
        ByteArray, usize
    ) {
        let mut dest: ByteArray = Default::default();
        let mut size: usize = 0;
        size += Self::encode_to(self, ref dest);
        (dest, size)
    }
}

pub impl EncodeSpan<T, +Encode<T>> of Encode<Span<T>> {
    fn encode_to(self: @Span<T>, ref dest: ByteArray) -> usize {
        let items = *self;
        let mut size = encode_compact_size(items.len(), ref dest);
        for item in items {
            size += item.encode_to(ref dest);
        };
        size
    }
}

pub impl EncodeByteArray of Encode<ByteArray> {
    fn encode_to(self: @ByteArray, ref dest: ByteArray) -> usize {
        let mut size = encode_compact_size(self.len(), ref dest);
        dest.append(self);
        size + self.len()
    }
}

pub impl EncodeU32 of Encode<u32> {
    fn encode_to(self: @u32, ref dest: ByteArray) -> usize {
        dest.append_word_rev((*self).into(), 4);
        4
    }
}

pub impl EncodeU64 of Encode<u64> {
    fn encode_to(self: @u64, ref dest: ByteArray) -> usize {
        dest.append_word_rev((*self).into(), 8);
        8
    }
}

pub impl EncodeHash of Encode<Hash> {
    fn encode_to(self: @Hash, ref dest: ByteArray) -> usize {
        dest.append(@(*self).into());
        32
    }
}

pub impl EncodeTxIn of Encode<TxIn> {
    fn encode_to(self: @TxIn, ref dest: ByteArray) -> usize {
        self.previous_output.encode_to(ref dest)
            + (*self.script).encode_to(ref dest)
            + self.sequence.encode_to(ref dest)
    }
}

pub impl EncodeTxOut of Encode<TxOut> {
    fn encode_to(self: @TxOut, ref dest: ByteArray) -> usize {
        self.value.encode_to(ref dest) + (*self.pk_script).encode_to(ref dest)
    }
}

pub impl EncodeOutpoint of Encode<OutPoint> {
    fn encode_to(self: @OutPoint, ref dest: ByteArray) -> usize {
        self.txid.encode_to(ref dest) + self.vout.encode_to(ref dest)
    }
}

/// Variable size codec.
/// Converts lenght value into Compact Size bytes and appends to the buffer.
///
/// https://learnmeabitcoin.com/technical/general/compact-size/
pub fn encode_compact_size(len: usize, ref dest: ByteArray) -> usize {
    // first covert the len into the felt252
    let val: felt252 = len.try_into().unwrap();
    // then append as the reverse word is this correct i think
    if (len < 253) {
        dest.append_word_rev(val, 1);
        1
    } else if (len < 65536) {
        dest.append_byte(253);
        dest.append_word_rev(val, 2);
        3
    } else {
        dest.append_byte(254);
        dest.append_word_rev(val, 4);
        5
    }
    // Note: `usize` is a `u32` alias, so lens >= 4,294,967,296 are not handled.
}

#[cfg(test)]
mod tests {
    use raito::types::transaction::{TxIn, TxOut, OutPoint};
    use raito::utils::hex::{from_hex, hex_to_hash_rev};
    use super::{Encode, encode_compact_size};

    #[test]
    fn test_encode_compact_size1() {
        let mut bytes = Default::default();
        let size = encode_compact_size(1, ref bytes);
        assert_eq!(bytes, from_hex("01"));
        assert_eq!(size, 1);
    }

    #[test]
    fn test_encode_compact_size2() {
        let mut bytes = Default::default();
        let size = encode_compact_size(252, ref bytes);
        assert_eq!(bytes, from_hex("fc"));
        assert_eq!(size, 1);
    }

    #[test]
    fn test_encode_compact_size3() {
        let mut bytes = Default::default();
        let size = encode_compact_size(253, ref bytes);
        assert_eq!(bytes, from_hex("fdfd00"));
        assert_eq!(size, 3);
    }

    #[test]
    fn test_encode_compact_size4() {
        let mut bytes = Default::default();
        let size = encode_compact_size(65535, ref bytes);
        assert_eq!(bytes, from_hex("fdffff"));
        assert_eq!(size, 3);
    }

    #[test]
    fn test_encode_compact_size5() {
        let mut bytes = Default::default();
        let size = encode_compact_size(65536, ref bytes);
        assert_eq!(bytes, from_hex("fe00000100"));
        assert_eq!(size, 5);
    }

    #[test]
    fn test_encode_compact_size6() {
        // u32 max
        let mut bytes = Default::default();
        let size = encode_compact_size(4294967295, ref bytes);
        assert_eq!(bytes, from_hex("feffffffff"));
        assert_eq!(size, 5);
    }

    #[test]
    fn test_encode_txout() {
        // block 170 coinbase tx
        let txout = @TxOut {
            value: 5000000000_u64,
            pk_script: @from_hex(
                "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
            ),
            cached: false,
        };

        let (bytes, _size) = txout.encode();

        let expected: ByteArray = from_hex(
            "00f2052a01000000434104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
        );
        assert_eq!(bytes, expected);
    }

    #[test]
    fn test_encode_outpoint() {
        // block 170 coinbase tx b1fea52486ce0c62bb442b530a3f0132b826c74e473d1f2c220bfa78111c5082
        let outpoint = OutPoint {
            txid: hex_to_hash_rev(
                "0000000000000000000000000000000000000000000000000000000000000000"
            ),
            vout: 4294967295_u32,
            data: Default::default(),
            block_height: Default::default(),
            block_time: Default::default(),
        };
        let (bytes, _size) = outpoint.encode();

        let expected = from_hex(
            "0000000000000000000000000000000000000000000000000000000000000000ffffffff"
        );
        assert_eq!(bytes, expected);
    }

    #[test]
    fn test_encode_outpoint2() {
        //block 170 tx f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16
        let outpoint = OutPoint {
            txid: hex_to_hash_rev(
                "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9"
            ),
            vout: 0_u32,
            data: Default::default(),
            block_height: Default::default(),
            block_time: Default::default(),
        };
        let (bytes, _size) = outpoint.encode();

        let expected = from_hex(
            "c997a5e56e104102fa209c6a852dd90660a20b2d9c352423edce25857fcd370400000000"
        );
        assert_eq!(bytes, expected);
    }

    #[test]
    fn test_encode_txin1() {
        // tx b1fea52486ce0c62bb442b530a3f0132b826c74e473d1f2c220bfa78111c5082
        let txin = @TxIn {
            script: @from_hex("04ffff001d0102"),
            sequence: 0xffffffff,
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "0000000000000000000000000000000000000000000000000000000000000000"
                ),
                vout: 4294967295,
                data: Default::default(),
                block_height: Default::default(),
                block_time: Default::default(),
            },
            witness: array![].span()
        };
        let (bytes, _size) = txin.encode();

        let expected = from_hex(
            "0000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0102ffffffff"
        );
        assert_eq!(bytes, expected);
    }

    #[test]
    fn test_encode_txin2() {
        // tx 4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33,
        // input 2
        let txin = @TxIn {
            script: @from_hex(
                "493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028"
            ),
            sequence: 0xffffffff,
            previous_output: OutPoint {
                txid: hex_to_hash_rev(
                    "66ce602f26ae00d128ea83e5afddf8c1cd226b7148322bb090779199f63f9ff5"
                ),
                vout: 1_u32,
                data: Default::default(),
                block_height: Default::default(),
                block_time: Default::default(),
            },
            witness: array![].span()
        };
        let (bytes, _size) = txin.encode();

        let expected = from_hex(
            "f59f3ff699917790b02b3248716b22cdc1f8ddafe583ea28d100ae262f60ce66010000008c493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028ffffffff"
        );
        assert_eq!(bytes, expected);
    }
}

