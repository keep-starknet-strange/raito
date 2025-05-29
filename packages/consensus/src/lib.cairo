pub mod codec;
pub mod types {
    pub mod block;
    pub mod chain_state;
    pub mod transaction;
    pub mod utxo_set;
}
pub mod validation {
    pub mod block;
    pub mod coinbase;
    pub mod difficulty;
    pub mod header;
    pub mod locktime;

    // TODO: once Scarb supports feature propagation, pass it from the client
    #[cfg(feature: "shinigami")]
    pub mod script;

    #[cfg(not(feature: "shinigami"))]
    pub mod script {
        use crate::types::block::Header;
        use crate::types::transaction::Transaction;

        pub fn validate_scripts(header: @Header, txs: Span<Transaction>) -> Result<(), ByteArray> {
            Result::Ok(())
        }
    }

    pub mod timestamp;
    pub mod transaction;
    pub mod work;
}
