use script::types::{
    EngineTransactionInput, EngineTransactionOutput, EngineTransaction
};

use crate::types::transaction::{Transaction, TxIn, TxOut};


impl EngineTransactionInputImpl of EngineTransactionInput<TxIn> {
    fn get_prevout_txid(self: TxIn) -> u256 {
        0
    }

    fn get_prevout_vout(self: TxIn) -> u32 {
        0
    }

    fn get_signature_script(self: TxIn) -> ByteArray {
        ""
    }

    fn get_witness(self: TxIn) -> Span<ByteArray> {
        array![].span()
    }

    fn get_sequence(self: TxIn) -> u32 {
        0
    }
}

impl EngineTransactionOutputDummyImpl of EngineTransactionOutput<TxOut> {
    fn get_publickey_script(self: TxOut) -> ByteArray {
        ""
    }

    fn get_value(self: TxOut) -> i64 {
        0
    }
}

impl EngineTransactionDummyImpl of EngineTransaction<Transaction, TxIn, TxOut,> {
    fn get_version(self: Transaction) -> i32 {
        0
    }

    fn get_transaction_inputs(self: Transaction) -> Span<TxIn> {
        array![].span()
    }

    fn get_transaction_outputs(self: Transaction) -> Span<TxOut> {
        array![].span()
    }

    fn get_locktime(self: Transaction) -> u32 {
        0
    }
}
