//! Bitcoin binary codec traits, implementations, and helpers.

use super::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
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

/// Impl for the type which has non copy traits
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
        self.sequence.encode_to(ref dest);
        self.previous_output.encode_to(ref dest);
    }
}

pub impl EncodeTxOut of Encode<TxOut> {
    fn encode_to(self: TxOut, ref dest: ByteArray) {
        self.value.encode_to(ref dest);
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

/// Encodes transaction (TODO: remove me, use Encode instead)
pub fn encode_transaction(tx: @Transaction, _segwit: bool) -> ByteArray {
    // append version (4 bytes)
    let mut hash256_input: ByteArray = "";
    hash256_input.append_word_rev((*tx.version).into(), 4);

    // append inputs count (1 byte in our example) - TODO : use Encode<Span<TxIn>> once
    // implemented
    hash256_input.append_word_rev((*tx.inputs).len().into(), 1);

    // append inputs - TODO : this is also included in Encode<Span<TxIn>>
    let mut inputs: Span<TxIn> = *tx.inputs;
    while let Option::Some(txin) = inputs.pop_front() {
        // append txid (32 bytes)
        let txid: u256 = (*(txin.previous_output.txid)).into();
        hash256_input.append_word_rev(txid.low.into(), 16);
        hash256_input.append_word_rev(txid.high.into(), 16);

        // append VOUT (4 bytes)
        hash256_input.append_word_rev((*txin.previous_output.vout).into(), 4);

        // append ScriptSig size (1 byte in our example)
        hash256_input.append_word_rev((*txin.script).len().into(), 1);

        // append ScriptSig (variable size)
        hash256_input.append(*txin.script);

        // append Sequence (4 bytes)
        hash256_input.append_word_rev((*txin.sequence).into(), 4);
    };

    // append outputs count (1 byte in our example) - TODO : use Encode<Span<TxOut>> once
    // implemented
    hash256_input.append_word_rev((*tx.outputs).len().into(), 1);

    // append outputs -  TODO this is also included in Encode<Span<TxOut>>
    let mut outputs: Span<TxOut> = *tx.outputs;
    while let Option::Some(txout) = outputs.pop_front() {
        // append amount (8 bytes)
        hash256_input.append_word_rev((*txout.value).into(), 8);

        // append ScriptPubKey size (1 byte in our exmaple)
        hash256_input.append_word_rev((*txout.pk_script).len().into(), 1);

        // append ScriptPubKey (variable size)
        hash256_input.append(*txout.pk_script);
    };

    // append locktime (4 bytes)
    hash256_input.append_word_rev((*tx.lock_time).into(), 4);
    hash256_input
}
