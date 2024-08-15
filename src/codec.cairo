//! Bitcoin binary codec traits, implementations, and helpers.

pub trait Encode<T> {
    /// Convert into bytes and append to the buffer
    fn encode_to(self: T, ref dest: ByteArray);

    /// Convert into bytes and return
    fn encode(
        self: T
    ) -> ByteArray {
        let mut dest: ByteArray = Default::default();
        Self::encode_to(self, ref dest);
        dest
    }
}

pub impl EncodeSpanImpl<T, +Encode<@T>> of Encode<Span<T>> {
    fn encode_to(self: Span<T>, ref dest: ByteArray) {
        encode_compact_size(self.len(), ref dest);
        for item in self {
            item.encode_to(ref dest);
        }
    }
}

pub impl EncodeByteArrayImpl of Encode<@ByteArray> {
    fn encode_to(self: @ByteArray, ref dest: ByteArray) {
        encode_compact_size(self.len(), ref dest);
        dest.append(self);
    }
}

/// Variable size codec.
/// Coverts value into bytes and appends to the buffer.
///
/// https://learnmeabitcoin.com/technical/general/compact-size/
pub fn encode_compact_size(value: usize, ref dest: ByteArray) { // TODO:
}
// TODO: implement Encode for Transaction, TxIn, TxOut, OutPoint


