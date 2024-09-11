//! Utreexo is an accumulator for the Bitcoin unspent transaction set.
//!
//! It allows to verify that a certain transaction output exists
//! and still unspent at a particular block while maintaining only
//! a very compact state.
//!
//! It is also useful for transaction validation (our case) since it
//! allows to "fetch" the output spent by a particular input in the
//! validated transaction. This is typically required to calculate
//! transaction fee and also to check that script execution succeeds.
//!
//! The expected workflow is the following:
//!   - For coinbase and inputs spending TXOs created in the same block
//!     utreexo accumulator is not updated (local cache is used instead);
//!   - For all other inputs we provide respective TXOs (extended) plus
//!     plus inclusion proof (can be individual, batched, or hybrid);
//!   - The client has to verify the inclusion proof and then remove all
//!     the TXOs from the utreexo set, that way updating the state;
//!   - For every output that is not spent in the same block we add the
//!     extended (additionally contains txid and output index aka vout) output
//!     to the accumulator (i.e. update the utreexo state).
//!
//! Note that utreexo data and proofs are provided via program input so
//! it is not part of prover/verifier arguments. Utreexo state (which
//! is part of the chain state) is what allows us to constrain
//! these inputs and ensure integrity.
//!
//! Read more about utreexo: https://eprint.iacr.org/2019/611.pdf

use super::transaction::OutPoint;

/// Accumulator representation of the state aka "Compact State Node".
/// Part of the chain state.
#[derive(Drop, Copy, PartialEq, Serde, Debug)]
pub struct UtreexoState {
    /// Roots of the Merkle tree forest.
    /// Index is the root height, None means a gap.
    pub roots: Span<Option<felt252>>,
    /// Total number of leaves (in the bottom-most row).
    /// Required to calculate the number of nodes in a particular row.
    /// Can be reconstructed from the roots, but cached for convenience.
    pub num_leaves: u64,
}

/// Accumulator interface
pub trait UtreexoAccumulator {
    /// Adds single output to the accumulator.
    /// The order *is important*: adding A,B and B,A would result in different states.
    ///
    /// Note that this call also pushes old UTXOs "to the left", to a larger subtree.
    /// This mechanism ensures that short-lived outputs have small inclusion proofs.
    fn add(ref self: UtreexoState, output: OutPoint);

    /// Verifies inclusion proof for a single output.
    fn verify(
        self: @UtreexoState, output: @OutPoint, proof: @UtreexoProof
    ) -> Result<(), UtreexoError>;

    /// Removes single output from the accumlator (order is important).
    ///
    /// Note that once verified, the output itself is not required for deletion,
    /// the leaf index plus inclusion proof is enough.
    fn delete(ref self: UtreexoState, proof: @UtreexoProof);

    /// Verifies batch proof for multiple outputs (e.g. all outputs in a block).
    fn verify_batch(
        self: @UtreexoState, outputs: Span<OutPoint>, proof: @UtreexoBatchProof
    ) -> Result<(), UtreexoError>;

    /// Removes multiple outputs from the accumulator.
    fn delete_batch(ref self: UtreexoState, proof: @UtreexoBatchProof);
}

#[derive(Drop, Copy, PartialEq)]
pub enum UtreexoError {}

/// Utreexo inclusion proof for a single transaction output.
#[derive(Drop, Copy)]
pub struct UtreexoProof {
    /// Index of the leaf in the forest, but also an encoded binary path,
    /// specifying which sibling node is left and which is right.
    pub leaf_index: u64,
    /// List of sibling nodes required to calculate the root.
    pub proof: Span<felt252>,
}

/// Utreexo inclusion proof for multiple outputs.
/// Compatible with https://github.com/utreexo/utreexo
#[derive(Drop, Copy)]
pub struct UtreexoBatchProof {
    /// Indices of leaves to be deleted (ordered starting from 0, left to right).
    pub targets: Span<u64>,
    /// List of sibling nodes required to calculate the root.
    pub proof: Span<felt252>,
}

pub impl UtreexoStateDefault of Default<UtreexoState> {
    fn default() -> UtreexoState {
        UtreexoState { roots: array![].span(), num_leaves: 0, }
    }
}
