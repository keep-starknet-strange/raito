pub mod utils {
    pub mod bytearray;
    pub mod sha256;
    pub mod hash;
    pub mod bit_shifts;
    pub mod merkle_tree;
    pub mod numeric;

    #[cfg(target: 'test')]
    pub mod hex;
}
pub mod validation {
    pub mod difficulty;
    pub mod coinbase;
    pub mod locktime;
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
    pub mod state;
}

mod main;

// TODO: move this module to a separate package
// Scarb does not support features when using cairo-run
// neither it allows to run function from the "tests" folder
mod test;
