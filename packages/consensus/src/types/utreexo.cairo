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
use utils::hash::{DigestImpl, DigestIntoU256, Digest};
use core::fmt::{Display, Formatter, Error};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateExTrait, HashStateTrait};
const TWO: NonZero<u64> = 2;

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

// https://eprint.iacr.org/2019/611.pdf Algorithm 1 AddOne
// p18
// To prevent such an attack, we require that the data inserted into the
// accumulator be not just the hash of a TXO, which is controllable by the
// attacker, but instead the concatenation of the TXO data with the block
// hash in which the TXO is confirmed. The attacker does not know the block
// hash before the TXO is confirmed, and it is not alterable by the attacker
// after confirmation (without significant cost). Verifiers, when inserting into
// the accumulator, perform this concatenation themselves after checking the
// proof of work of the block. Inclusion proofs contain this block hash data so
// that the leaf hash value can be correctly computed.
fn parent_hash(left: felt252, right: felt252, _block_hash: Digest) -> felt252 {
    return PoseidonTrait::new().update_with(left).update_with(right).finalize();
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
        let txid_u256: u256 = output.txid.deref().into();
        let proof_root = compute_root(
            *proof.proof, *proof.leaf_index, txid_u256.try_into().expect('value too large')
        );

        // Get the expected root
        let root_index = (*proof.proof).len();
        if root_index >= self.roots.deref().len() {
            return Result::Err(UtreexoError::RootIndexOutOfBound);
        }
        let expected_root = self.roots[root_index];

        match expected_root {
            Option::Some(root) => {
                if root.deref().into() == proof_root {
                    return Result::Ok(());
                };
                Result::Err(UtreexoError::ProofVerificationFailed)
            },
            _ => Result::Err(UtreexoError::ProofVerificationFailed)
        }
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

/// Computes the root given a leaf, its index, and a proof.
///
/// Traverses the tree from leaf to root, hashing paired nodes.
/// Proof order is bottom-up. Returns the computed root.
fn compute_root(proof: Span<felt252>, mut leaf_index: u64, mut curr_node: felt252) -> felt252 {
    let mut proof = proof.clone();
    let proof_length = proof.len();

    if proof_length == 0 {
        return curr_node;
    }

    for sibling in proof {
        let (next_left_index, is_right) = DivRem::div_rem(leaf_index, TWO);

        let (left, right) = if is_right == 0 {
            (curr_node, *sibling)
        } else {
            (*sibling, curr_node)
        };

        // TODO: refactor
        curr_node = parent_hash(left, right, 0x0_u256.into());
        leaf_index = next_left_index;
        let _ = proof.pop_front();
    };

    curr_node // Return the computed root
}

#[derive(Drop, Copy, PartialEq, Debug)]
pub enum UtreexoError {
    ProofVerificationFailed,
    RootIndexOutOfBound
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

#[cfg(test)]
mod tests {
    use super::{UtreexoState, UtreexoAccumulator, UtreexoProof, OutPoint};
    use crate::types::transaction::{TxOut};


    // Test the basic functionality of the Utreexo accumulator
    ///
    /// This test covers the following scenarios:
    /// 1. Adding a single leaf and verifying it
    /// 2. Adding a second leaf and verifying both leaves
    /// 3. Adding a third leaf and verifying previous leaves
    /// 4. Adding a fourth leaf and verifying all leaves
    ///
    /// For each scenario, the test:
    /// - Initializes the UtreexoState with the appropriate roots and number of leaves
    /// - Creates an OutPoint representing the leaf
    /// - Constructs a UtreexoProof for the leaf
    /// - Calls the verify function and asserts that it succeeds
    ///
    /// The test uses predefined txid values (0x111111..., 0x222222..., etc.) for simplicity.
    /// It checks the correct root values at each stage of the Utreexo tree's growth.
    #[test]
    fn test_utreexo_basics() {
        // Add the first leaf (0x111111111111111111111111)
        let leaf1_txid = 0x111111111111111111111111;
        let leaf1_txid_u256: u256 = leaf1_txid.into();

        let leaf1 = OutPoint {
            txid: leaf1_txid_u256.into(),
            vout: 0_u32,
            data: TxOut { value: 0, pk_script: @"", cached: false, },
            block_height: 0,
            block_time: 0,
            is_coinbase: false,
        };
        let mut utxo_state = UtreexoState {
            roots: array![Option::Some(0x111111111111111111111111)].into(), num_leaves: 1
        };
        let proof = UtreexoProof { leaf_index: 0, proof: array![].span(), };
        let result = utxo_state.verify(@leaf1, @proof);
        assert!(result.is_ok(), "Root at index 0 should be 0x111111111111111111111111");

        // Add the second leaf (0x222222222222222222222222)
        let leaf2_txid = 0x222222222222222222222222;
        let leaf2_txid_u256: u256 = leaf2_txid.into();
        // Add the second leaf (0x222222222222222222222222)
        let leaf2 = OutPoint {
            txid: leaf2_txid_u256.into(),
            vout: 0_u32,
            data: TxOut { value: 0, pk_script: @"", cached: false, },
            block_height: 0,
            block_time: 0,
            is_coinbase: false,
        };
        utxo_state =
            UtreexoState {
                roots: array![
                    Option::None,
                    Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a)
                ]
                    .into(),
                num_leaves: 1
            };

        let proof = UtreexoProof {
            leaf_index: 1, proof: array![0x111111111111111111111111].span(),
        };
        let result = utxo_state.verify(@leaf2, @proof);
        assert!(
            result.is_ok(),
            "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
        );

        // Add the third leaf (0x333333333333333333333333)
        let leaf3_txid = 0x333333333333333333333333;
        let leaf3_txid_u256: u256 = leaf3_txid.into();
        // Add the second leaf (0x222222222222222222222222)
        let leaf3 = OutPoint {
            txid: leaf3_txid_u256.into(),
            vout: 0_u32,
            data: TxOut { value: 0, pk_script: @"", cached: false, },
            block_height: 0,
            block_time: 0,
            is_coinbase: false,
        };
        utxo_state =
            UtreexoState {
                roots: array![
                    Option::Some(leaf3_txid),
                    Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a)
                ]
                    .into(),
                num_leaves: 1
            };

        let proof = UtreexoProof {
            leaf_index: 1, proof: array![0x111111111111111111111111].span(),
        };
        let result = utxo_state.verify(@leaf2, @proof);
        assert!(
            result.is_ok(),
            "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
        );

        // Add the fourth leaf (0x444444444444444444444444)

        let leaf4_txid = 0x444444444444444444444444;
        let leaf4_txid_u256: u256 = leaf4_txid.into();
        // Add the second leaf (0x222222222222222222222222)
        let leaf4 = OutPoint {
            txid: leaf4_txid_u256.into(),
            vout: 0_u32,
            data: TxOut { value: 0, pk_script: @"", cached: false, },
            block_height: 0,
            block_time: 0,
            is_coinbase: false,
        };

        utxo_state =
            UtreexoState {
                roots: array![
                    Option::None,
                    Option::None,
                    Option::Some(0x018674e0c40577cb5ba4728d6ac7bedfd9548f4020161223261941b2a8ae84b2)
                ]
                    .into(),
                num_leaves: 1
            };

        // Create the UtreexoProof for leaf 1
        let proof = UtreexoProof {
            leaf_index: 0,
            proof: array![
                0x222222222222222222222222,
                0x02a6b2ae998d30e1ac356c32b2750c3126cd6b3ecf02e6918a93021d17b2b026
            ]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(@leaf1, @proof);
        assert!(result.is_ok(), "verify leaf index 0 failed");
        // Create the UtreexoProof for leaf 2
        let proof = UtreexoProof {
            leaf_index: 1,
            proof: array![
                0x111111111111111111111111,
                0x02a6b2ae998d30e1ac356c32b2750c3126cd6b3ecf02e6918a93021d17b2b026
            ]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(@leaf2, @proof);
        assert!(result.is_ok(), "verify leaf index 1 failed");

        // Create the UtreexoProof for leaf 3
        let proof = UtreexoProof {
            leaf_index: 2,
            proof: array![
                0x444444444444444444444444,
                0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a
            ]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(@leaf3, @proof);
        assert!(result.is_ok(), "verify leaf index 2 failed");

        // Create the UtreexoProof for leaf 4
        let proof = UtreexoProof {
            leaf_index: 3,
            proof: array![
                0x333333333333333333333333,
                0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a
            ]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(@leaf4, @proof);
        assert!(result.is_ok(), "verify leaf index 3 failed");
    }
    // #[test]
// fn test_verify_inclusion() {
//     // Manually construct the Utreexo roots
//     let roots: Span<Option<felt252>> = array![
//         Option::None, // Note: Zero values can be represented as Some(0) or None
//         Option::Some(0x060eca2f5761f335018c8349e3009266cecb15ca0aafebf16fff82294b58a927),
//         Option::None,
//         Option::Some(0x02da545c9e563a98924b88674350c101473dfc830cfc8294149009482e692d38),
//         Option::None,
//         Option::Some(0x00b821cae677cb979640f3174d902df305e43801f1341dc4d6e688b38d582f63),
//         Option::None,
//         Option::Some(0x079165659241d0f009f93ba979fdcbdf392d608a2e312df19f225725ab48a03d),
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None,
//         Option::None
//     ]
//         .span();

    //     // Manually construct the UtreexoState
//     let utxo_state = UtreexoState {
//         roots: roots, num_leaves: 10_u64,
//     };

    //     // Define the leaf (OutPoint)
//     let leaf_txid: u256 = 0x017da72c9147f43a3491e2f378f3d62f626136ca5d5c77d61f7cee2f76d595ea;
//     let leaf = OutPoint {
//         txid: leaf_txid.into(),
//         vout: 0_u32, //
//         data: TxOut { value: 0, pk_script: @"", cached: false, },
//         block_height: 0,
//         block_time: 0,
//         is_coinbase: false
//     };

    //     // Define the leaf index
//     let leaf_index = 9_u64;

    //     // Manually construct the inclusion proof
//     let proof_elements: Span<felt252> = array![
//         0x04ce2e86eb35ce480db8e78be4a8ce0ef6b954f1fa2a6f212292a80945561af0,
//         0x01562e0628478c3f51de8fa35997bbd88a6f88de01ef5e4173cec5c7d0467515,
//         0x0488e519ce1f3792fd89ce87c976d19ce67b1a27a7f5a8cab92b39be10a853b7,
//         0x05fc2a2790b3dabe66f73b5f850b630ff986cdaacf1561a7aa1dd30c47aab9a4,
//         0x05234b6e55ded0e42e4733293f6da7e934d1912507bf1832815d98a4b9c05b07,
//         0x06aa8b88954fbac89b8b792b1ab5503736b4bea9a6f29b81f4f807b63a0ed4d5,
//         0x018a171f75918e2721982736cd51d849ef640a1d544b847330c56ba98f589d94
//     ]
//         .span();

    //     // Create the UtreexoProof
//     let proof = UtreexoProof { leaf_index: leaf_index, proof: proof_elements, };

    //     // Call the verify function
//     let result = utxo_state.verify(@leaf, @proof);

    //     // Assert that the verification is successful
//     match result {
//         Result::Ok(()) => {// Verification succeeded
//         },
//         Result::Err(error) => {
//             panic!("Utreexo inclusion proof verification failed: {:?}", error);
//         },
//     }
// }

}
