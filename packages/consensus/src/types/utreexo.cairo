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
use utils::hash::{DigestImpl, DigestIntoU256};
use core::fmt::{Display, Formatter, Error};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateExTrait, HashStateTrait};
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

pub impl UtreexoStateImpl of UtreexoAccumulator {
    /// Adds single output to the accumulator.
    /// The order *is important*: adding A,B and B,A would result in different states.
    ///
    /// Note that this call also pushes old UTXOs "to the left", to a larger subtree.
    /// This mechanism ensures that short-lived outputs have small inclusion proofs.
    fn add(ref self: UtreexoState, output: OutPoint) {}

    /// Verifies inclusion proof for a single output.
    fn verify(
        self: @UtreexoState, output: @OutPoint, proof: @UtreexoProof
    ) -> Result<(), UtreexoError> {
        let proof_root = verify_helper(*proof.proof, *proof.leaf_index, (*output.txid).into());

        // last node in the proof path.
        let expected_proof_root: u256 = (*(*proof.proof).at((*proof.proof).len() - 1)).into();
        if  expected_proof_root == proof_root {
            return Result::Ok(());
        }
        Result::Err(UtreexoError::VerifyFailure)
    }

    /// Removes single output from the accumlator (order is important).
    ///
    /// Note that once verified, the output itself is not required for deletion,
    /// the leaf index plus inclusion proof is enough.
    fn delete(ref self: UtreexoState, proof: @UtreexoProof) {}

    /// Verifies batch proof for multiple outputs (e.g. all outputs in a block).
    fn verify_batch(
        self: @UtreexoState, outputs: Span<OutPoint>, proof: @UtreexoBatchProof
    ) -> Result<(), UtreexoError> {
        Result::Ok(())
    }

    /// Removes multiple outputs from the accumulator.
    fn delete_batch(ref self: UtreexoState, proof: @UtreexoBatchProof) {}
}

fn verify_helper(mut proof: Span<felt252>, leaf_index: u64, curr_node: u256) -> u256 {
    if proof.len() == 0 {
        return curr_node;
    }
    let next_index = (leaf_index - leaf_index % 2) / 2;

    let mut next_node = PoseidonTrait::new();
    if leaf_index % 2 == 0 {
        next_node = next_node.update_with(curr_node).update_with(*proof[0]);
    } else {
        next_node = next_node.update_with(*proof[0]).update_with(curr_node);
    }

    let next_node = next_node.finalize().into();

    // move to parent node, shorten the proof
    let mut next_proof = proof.clone();
    let _ = next_proof.pop_front();

    return verify_helper(next_proof, next_index, next_node);
}

#[derive(Drop, Copy, PartialEq)]
pub enum UtreexoError {
    VerifyFailure
}

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

impl UtreexoStateDisplay of Display<UtreexoState> {
    fn fmt(self: @UtreexoState, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "UtreexoState {{ roots: {}, num_leaves: {}, }}", (*self.roots).len(), *self.num_leaves
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

impl UtreexoProofDisplay of Display<UtreexoProof> {
    fn fmt(self: @UtreexoProof, ref f: Formatter) -> Result<(), Error> {
        let mut proofs: ByteArray = Default::default();
        for proof in *self.proof {
            proofs.append(@format!("{},", proof));
        };
        let str: ByteArray = format!(
            "UtreexoProof {{ leaf_index: {}, proof: {}, }}", *self.leaf_index, @proofs
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

impl UtreexoBatchProofDisplay of Display<UtreexoBatchProof> {
    fn fmt(self: @UtreexoBatchProof, ref f: Formatter) -> Result<(), Error> {
        let mut targets: ByteArray = Default::default();
        let mut proofs: ByteArray = Default::default();
        for target in *self.targets {
            targets.append(@format!("{},", target));
        };
        for proof in *self.proof {
            proofs.append(@format!("{},", proof));
        };
        let str: ByteArray = format!(
            "UtreexoBatchProof {{ leaf_index: [{}], proof: [{}] }}", @targets, @proofs
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}
