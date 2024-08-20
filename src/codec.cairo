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


pub fn encode_txout(txout: TxOut, ref dest: ByteArray) {
    encode_compact_size(txout.value.try_into().unwrap(), ref dest);
    encode_compact_size(txout.pk_script.len(), ref dest);
    dest.append(txout.pk_script);
}

pub fn encode_outpoint(op: OutPoint, ref dest: ByteArray) {
    let txids: ByteArray = op.txid.into();
    let txids_rev = txids.rev();
    dest.append(@txids_rev);
    encode_compact_size(op.vout, ref dest);
    encode_compact_size(op.block_time, ref dest);
}
pub fn encode_txin(txin: TxIn, ref dest: ByteArray) {
    encode_compact_size(txin.script.len(), ref dest);
    dest.append(txin.script);
    encode_compact_size(txin.sequence, ref dest);
    encode_outpoint(txin.previous_output, ref dest);
    encode_compact_size(txin.witness.len(), ref dest);
    // now we have to serialize the witness
}

pub fn encode_tx(tx: Transaction, ref dest: ByteArray) {
    encode_compact_size(tx.version, ref dest);
    // if we have to find the wxtid then we have to serilaize according to the segeit transaction
    encode_compact_size(tx.inputs.len(), ref dest);
    let inputs: Span<TxIn> = tx.inputs;
    for txin in inputs {
        let txinn: @TxIn = txin;
        encode_txin(*txin, ref dest);
    };
    encode_compact_size(tx.outputs.len(), ref dest);
    let outputs: Span<TxOut> = tx.outputs;
    for txout in outputs {
        let txoutt: @TxOut = txout;
        encode_txout(*txout, ref dest);
    };
    encode_compact_size(tx.lock_time, ref dest);
}

pub fn encode_test() {
    let mut bytes: ByteArray = Default::default();
    //   encode_compact_size(253 , ref bytes);
    let txout = TxOut {
        value: 1000,
        pk_script: @from_hex("76a914ff1a978dd905cf676b2ee8870ba47728294e609588ac"),
        cached: false
    };

    encode_txout(txout, ref bytes);
    print!("{:?}", bytes);
}
