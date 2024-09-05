pub mod utils {
    pub mod sha256;
    pub mod hash;
    pub mod bit_shifts;
    pub mod merkle_tree;
    pub mod numeric;
    pub mod hex;
}
pub mod validation {
    pub mod difficulty;
    pub mod coinbase;
    pub mod timestamp;
    pub mod transaction;
    pub mod work;
    pub mod block;
}
pub mod codec;
pub mod types {
    pub mod utreexo;
    pub mod chain_state;
    pub mod block;
    pub mod transaction;
    pub mod utxo_set;
}

mod main;
