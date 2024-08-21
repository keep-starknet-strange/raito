//! Bitcoin binary codec traits, implementations, and helpers.

use super::state::{Block, ChainState, Transaction, UtreexoState, TxIn, TxOut, OutPoint};
use super::test_utils::from_hex;
use super::utils::{Hash};
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
pub impl EncodeTxIn of Encode<TxIn> {
    fn encode_to(self: TxIn, ref dest: ByteArray) {
        self.script.encode_to(ref dest);
        encode_compact_size(self.sequence, ref dest);
        self.previous_output.encode_to(ref dest);
        self.witness.encode_to(ref dest);
    }
}

pub impl EncodeTxOut of Encode<TxOut> {
    fn encode_to(self: TxOut, ref dest: ByteArray) {
        encode_compact_size(self.value.try_into().unwrap(), ref dest);
        self.pk_script.encode_to(ref dest);
    }
}

pub impl EncodeOutpoint of Encode<OutPoint> {
    fn encode_to(self: OutPoint, ref dest: ByteArray) {
        let txids: ByteArray = self.txid.into();
        let txids_rev = txids.rev();
        dest.append(@txids_rev);
        encode_compact_size(self.vout, ref dest);
    }
}


pub impl EncodeTx of Encode<Transaction> {
    fn encode_to(self: Transaction, ref dest: ByteArray) {
        encode_compact_size(self.version, ref dest);
        // if we have to find the wxtid then we have to serilaize according to the segeit
        // transaction
        encode_compact_size(self.inputs.len(), ref dest);
        let inputs: Span<TxIn> = self.inputs;
        for txin in inputs {
            txin.clone().encode_to(ref dest);
        };
        encode_compact_size(self.outputs.len(), ref dest);
        let outputs: Span<TxOut> = self.outputs;
        for txout in outputs {
            txout.clone().encode_to(ref dest);
        };
        encode_compact_size(self.lock_time, ref dest);
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
        dest = from_hex("fd");
        dest.append_word_rev(val, 2);
    } else {
        dest = from_hex("fe");
        dest.append_word_rev(val, 4);
    }
}
