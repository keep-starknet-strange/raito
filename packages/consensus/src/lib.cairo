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
    pub mod locktime;
    pub mod script;
    pub mod timestamp;
    pub mod transaction;
    pub mod work;
}
