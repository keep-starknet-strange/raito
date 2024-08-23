//! Bitcoin binary codec traits, implementations, and helpers.

use super::state::{Transaction, TxIn, TxOut};

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
/// Converts value into bytes and appends to the buffer.
///
/// https://learnmeabitcoin.com/technical/general/compact-size/
pub fn encode_compact_size(value: usize, ref dest: ByteArray) { // TODO:
}
// TODO: implement Encode for Transaction, TxIn, TxOut, OutPoint

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
        let rev_script = (*txin.script).rev();
        hash256_input.append(@rev_script);

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
        let rev_pk_script = (*txout.pk_script).rev();
        hash256_input.append(@rev_pk_script);
    };

    // append locktime (4 bytes)
    hash256_input.append_word_rev((*tx.lock_time).into(), 4);
    hash256_input
}
