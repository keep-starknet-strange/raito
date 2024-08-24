//! Bitcoin binary codec traits, implementations, and helpers.

use super::state::{Block, ChainState, Transaction, UtreexoState, TxIn, TxOut, OutPoint};
use raito::utils::hash::Hash;
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
// impl for the type which has non copy traits
pub impl EncodeSpanNcopyImpl<T, +Encode<@T>> of Encode<Span<T>> {
    fn encode_to(self: Span<T>, ref dest: ByteArray) {
        encode_compact_size(self.len(), ref dest);
        for item in self {
            item.encode_to(ref dest);
        }
    }
}

pub impl EncodeSpanImpl<T, +Encode<T>, +Copy<T>> of Encode<Span<T>> {
    fn encode_to(self: Span<T>, ref dest: ByteArray) {
        encode_compact_size(self.len(), ref dest);
        for item in self {
            (*item).encode_to(ref dest);
        }
    }
}

pub impl EncodeByteArrayImpl of Encode<@ByteArray> {
    fn encode_to(self: @ByteArray, ref dest: ByteArray) {
        encode_compact_size(self.len(), ref dest);
        dest.append(self);
    }
}

pub impl Encodeu32 of Encode<u32> {
    fn encode_to(self: u32, ref dest: ByteArray) {
        dest.append_word_rev(self.into(), 4);
    }
}

pub impl Encodeu64 of Encode<u64> {
    fn encode_to(self: u64, ref dest: ByteArray) {
        dest.append_word_rev(self.into(), 8);
    }
}

pub impl EncodeHash of Encode<Hash> {
    fn encode_to(self: Hash, ref dest: ByteArray) {
        dest.append(@self.into());
    }
}

pub impl EncodeTxIn of Encode<TxIn> {
    fn encode_to(self: TxIn, ref dest: ByteArray) {
        self.script.encode_to(ref dest);
        dest.append_word_rev(self.sequence.into(), 4);
        self.previous_output.encode_to(ref dest);
    }
}

pub impl EncodeTxOut of Encode<TxOut> {
    fn encode_to(self: TxOut, ref dest: ByteArray) {
        dest.append_word_rev(self.value.into(), 8);
        self.pk_script.encode_to(ref dest);
    }
}


pub impl EncodeOutpoint of Encode<OutPoint> {
    fn encode_to(self: OutPoint, ref dest: ByteArray) {
        self.txid.encode_to(ref dest);
        self.vout.encode_to(ref dest);
    }
}


pub impl EncodeTx of Encode<Transaction> {
    fn encode_to(self: Transaction, ref dest: ByteArray) {
        self.version.encode_to(ref dest);
        self.inputs.encode_to(ref dest);
        self.outputs.encode_to(ref dest);
        self.lock_time.encode_to(ref dest);
    }
}


/// Variable size codec.
/// Converts value into bytes and appends to the buffer.
///
/// https://learnmeabitcoin.com/technical/general/compact-size/
pub fn encode_compact_size(value: usize, ref dest: ByteArray) {
    // first covert the value into the felt252
    let val: felt252 = value.try_into().unwrap();
    // then append as the reverse word is this correct i think
    if (value < 253) {
        dest.append_word_rev(val, 1);
    } else if (value < 65536) {
        dest.append_byte(253);
        dest.append_word_rev(val, 2);
    } else {
        dest.append_byte(254);
        dest.append_word_rev(val, 4);
    }
    // Note: `usize` is a `u32` alias, so values >= 4,294,967,296 are not handled.
}
