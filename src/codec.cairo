//! Bitcoin binary codec traits, implementations, and helpers.
use core::traits::Into;
use super::state::{Block, ChainState, Transaction, UtreexoState, UtreexoSet, TxIn, TxOut, OutPoint};
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
pub fn encode_compact_size(value: usize, ref dest: ByteArray) 
{ 
    // first covert the value into the felt252 
    let val : felt252 = value.try_into().unwrap(); 
    // then append as the reverse word is this correct i think 
    if (value  < 253 ) { 
        dest.append_word_rev(val,1);
    } else if (value < 65536 ) {
        dest = from_hex("fd"); 
        dest.append_word_rev(val,2);
    }  else  {
        dest = from_hex("fe"); 
        dest.append_word_rev(val,4);
    }
}



pub fn encode_txout (txout : TxOut , ref dest: ByteArray){
    encode_compact_size(txout.value.try_into().unwrap() , ref dest);
    encode_compact_size(txout.pk_script.len(), ref dest);
    dest.append(txout.pk_script);
}
pub fn encode_outpoint(op : OutPoint , ref dest: ByteArray) {
    //  i think we have to do the reverse is this correct or not 
    dest.append(@op.txid.into());
    encode_compact_size(op.vout , ref dest);
    encode_compact_size(op.txo_index.try_into().unwrap() , ref dest);
    encode_compact_size(op.amount.try_into().unwrap() , ref dest);
}

pub fn encode_txin (txin : TxIn , ref dest: ByteArray) {
    encode_compact_size(txin.script.len() , ref dest);
    dest.append(txin.script);
    encode_compact_size(txin.sequence , ref dest);
    encode_outpoint(txin.previous_output , ref dest);
    encode_compact_size(txin.witness.len() , ref dest);
    dest.append(txin.witness);
}
pub fn encode_tx (tx :Transaction , ref dest: ByteArray) {
    encode_compact_size(tx.version, ref dest);
    // if we have to find the wxtid then we have to serilaize according to the segeit transaction    
    encode_compact_size(tx.inputs.len(), ref dest);
    let inputs : Span<TxIn> = tx.inputs;
    for txin in inputs {
        let txinn : @TxIn = txin ; 
        encode_txin(*txin, ref dest);
    };
    encode_compact_size(tx.outputs.len(), ref dest);
    let outputs : Span<TxOut> = tx.outputs;
    for txout in outputs {
        let txoutt : @TxOut = txout ; 
        encode_txout(*txout, ref dest);
    };
    encode_compact_size(tx.lock_time, ref dest);
}

pub fn encode_test( ) {
  let mut bytes: ByteArray = Default::default(); 
//   encode_compact_size(253 , ref bytes);
  let txout = TxOut {
      value : 1000,
      pk_script : @from_hex("76a914ff1a978dd905cf676b2ee8870ba47728294e609588ac")
  };
  
  encode_txout(txout , ref bytes);
  print!("{:?}", bytes);  
  
}



// implment the encode for the transaction , txin , txout and outpoint 
// first i would try to enocde the txout is it ok . 
// serialize the ssytem 
// txout  
//serializination 
// we have to initialize the txout 
// pub struct TxOut {
//     /// The value of the output in satoshis.
//     pub value: u64,
//     /// The spending script (aka locking code) for this output.
//     pub pk_script: @ByteArray,
// }
// pub struct TxOut {
//     /// The value of the output in satoshis.
//     pub value: 100000000,
//     /// The spending script (aka locking code) for this output.
//     pub pk_script: @ByteArray,
// }
// txout { 
//     vlaue 
//     script 
// }
//seriliaze the txout -- would be the 
//value into the little edian 
// script - > serialize the script
// serialize the script , how it would be done we have to devlop that is that ok i want to develop that is ok or not 
// serialize = encode_variant(length) +raw_serialise(script). 
// how the raw serialization 
// result in the byte is correct
// TODO: implement Encode for Transaction, TxIn, TxOut, OutPoint
// encode the transaction 
// ecode the txin 
// enocde txout 
// encode outpoint
// bitcoin bip and what ever i want i can do that is it ok . 
// 00e1f5050000000
// little endian
// 4 bytes  encode_variant ______________________serialize txin______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________  enocde_variant  __________________________TxOUT_serialization________________________________  little edian 
// version  input_count   txid                                                              vout    scriptsigsize       scriptsig                                                                                                                                                                                                            sequence  output_count      amount       scriptsize   script                                             locktime
// 01000000 01            1fde77dd3bc6640714747f158e88260efe7f40236ee0446aca1a0808aec2caab 01000000 6b               483045022100f2c45824f970775daa1264f7b0779ee5df86359fab9ef47a0fee85ec97d46c0502201e1efe643c6c2bc56cced92a25c74158b01a5bfd06197a77851795a59fe5d80c0121034fb95ed3287f94561aa26df5ad19bb24762808ba278f7b26d1c85848f86a7ec4  ffffffff  01            00e1f50500000000 19           76a914ff1a978dd905cf676b2ee8870ba47728294e609588ac 00000000
// 01000000 01            1fde77dd3bc6640714747f158e88260efe7f40236ee0446aca1a0808aec2caab 01000000 6b               483045022100f2c45824f970775daa1264f7b0779ee5df86359fab9ef47a0fee85ec97d46c0502201e1efe643c6c2bc56cced92a25c74158b01a5bfd06197a77851795a59fe5d80c0121034fb95ed3287f94561aa26df5ad19bb24762808ba278f7b26d1c85848f86a7ec4  ffffffff  01            00e1f50500000000 19           76a914299da5537e8b65bf45c70a9ece75988ebfca86b588ac 00000000

// script size must be in the enocde vairant which is also called the compact size is this correct 


// littel edian to develop make the library to develop the littel edian system that is done for now 

// append_word_rev();  
