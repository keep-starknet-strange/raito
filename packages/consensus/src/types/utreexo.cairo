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
use super::utxo_set::UtxoSet;
use utils::hash::{DigestImpl, DigestIntoU256};
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};
use core::fmt::{Display, Formatter, Error};

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

#[generate_trait]
pub impl UtreexoStateImpl of UtreexoStateTrait {
    fn validate_and_apply(ref self: UtreexoState, ref utxo_set: UtxoSet) -> Result<(), ByteArray> {
        while let Option::Some(leave) = utxo_set.leaves_to_add.pop_front() {
            self.add(leave);
        };
        // TODO: delete leaves from utreexo
        // while let Option::Some(leave) = utxo_set.leaves_to_delete.pop_front() {
        // };
        Result::Ok(())
    }
}

/// Accumulator interface
pub trait UtreexoAccumulator {
    /// Adds single output to the accumulator.
    /// The order *is important*: adding A,B and B,A would result in different states.
    ///
    /// Note that this call also pushes old UTXOs "to the left", to a larger subtree.
    /// This mechanism ensures that short-lived outputs have small inclusion proofs.
    fn add(ref self: UtreexoState, outpoint_hash: felt252);

    /// Removes single output from the accumulator (order is important).
    ///
    /// Note that once verified, the output itself is not required for deletion,
    /// the leaf index plus inclusion proof is enough.
    fn delete(ref self: UtreexoState, proof: @UtreexoProof);

    /// Removes multiple outputs from the accumulator.
    fn delete_batch(ref self: UtreexoState, proof: @UtreexoBatchProof);

    /// Verifies inclusion proof for a single output.
    fn verify(
        self: @UtreexoState, outpoint_hash: felt252, proof: @UtreexoProof
    ) -> Result<(), UtreexoError>;

    /// Verifies batch proof for multiple outputs (e.g. all outputs in a block).
    fn verify_batch(
        self: @UtreexoState, outputs: Span<OutPoint>, proof: @UtreexoBatchProof
    ) -> Result<(), UtreexoError>;
}

/// https://eprint.iacr.org/2019/611.pdf page 6 - Adding and removing elements.
fn parent_hash(left: felt252, right: felt252) -> felt252 {
    return PoseidonTrait::new().update_with(left).update_with(right).finalize();
}

pub impl UtreexoAccumulatorImpl of UtreexoAccumulator {
    /// Adds an output from the accumulator.
    /// https://eprint.iacr.org/2019/611.pdf Algorithm 1 AddOne
    fn add(ref self: UtreexoState, outpoint_hash: felt252) {
        let mut new_roots: Array<Option<felt252>> = Default::default();
        let mut n: felt252 = outpoint_hash;
        let mut first_none_found: bool = false;

        for root in self
            .roots {
                if (!first_none_found) {
                    if (root.is_none()) {
                        first_none_found = true;
                        new_roots.append(Option::Some(n));
                    } else {
                        n = PoseidonTrait::new().update_with(((*root).unwrap(), n)).finalize();
                        new_roots.append(Option::None);
                    }
                } else {
                    new_roots.append(*root);
                }
            };

        // Checks if end with Option::None
        if (new_roots[new_roots.len() - 1].is_some()) {
            new_roots.append(Option::None);
        }

        self.roots = new_roots.span();
        self.num_leaves += 1_u64;
    }

    /// Removes an output from the accumulator.
    /// https://eprint.iacr.org/2019/611.pdf Algorithm 2 DeleteOne
    fn delete(ref self: UtreexoState, proof: @UtreexoProof) {
        let mut roots: Array<Option<felt252>> = array![];
        let mut n: Option<felt252> = Option::None;

        let num_roots: u32 = self.roots.len();
        let proof = *proof.proof;
        let mut h: usize = 0;

        for sibling in proof {
            if n != Option::None {
                n = Option::Some(parent_hash(*sibling, n.unwrap()));
                if h < num_roots {
                    roots.append(*self.roots[h]);
                } else {
                    roots.append(Option::None);
                }
            } else if h < num_roots && self.roots[h].is_some() {
                n = Option::Some(parent_hash(*sibling, (*self.roots[h]).unwrap()));
                roots.append(Option::None);
            } else {
                roots.append(Option::Some(*sibling));
            }

            h += 1;
        };

        roots.append(n);
        h += 1;
        while h != num_roots {
            roots.append(*self.roots[h]);
            h += 1;
        };

        self.roots = roots.span();
        self.num_leaves -= 1;
    }

    /// Removes multiple outputs from the accumulator.
    fn delete_batch(ref self: UtreexoState, proof: @UtreexoBatchProof) {}

    /// Verifies inclusion proof for a single output.
    fn verify(
        self: @UtreexoState, outpoint_hash: felt252, proof: @UtreexoProof
    ) -> Result<(), UtreexoError> {
        let proof_root = compute_root(*proof.proof, *proof.leaf_index, outpoint_hash);

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

    /// Verifies inclusion proof for multiple outputs.
    fn verify_batch(
        self: @UtreexoState, outputs: Span<OutPoint>, proof: @UtreexoBatchProof
    ) -> Result<(), UtreexoError> {
        Result::Ok(())
    }
}

/// Computes the root given a leaf, its index, and a proof.
///
/// Traverses the tree from leaf to root, hashing paired nodes.
/// Proof order is bottom-up. Returns the computed root.
fn compute_root(proof: Span<felt252>, mut leaf_index: u64, mut curr_node: felt252) -> felt252 {
    for sibling in proof {
        let (next_left_index, is_right) = DivRem::div_rem(leaf_index, 2);

        let (left, right) = if is_right == 0 {
            (curr_node, *sibling)
        } else {
            (*sibling, curr_node)
        };
        curr_node = parent_hash(left, right);
        leaf_index = next_left_index;
    };
    // Returns the computed root (or the node itself if the proof is empty).
    curr_node
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
        UtreexoState { roots: array![Option::None].span(), num_leaves: 0, }
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
    use super::{UtreexoState, UtreexoAccumulator, UtreexoProof};

    /// Test the basic functionality of the Utreexo accumulator
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
    fn test_verify_inclusion() {
        // Add the first leaf (0x111111111111111111111111)
        let leaf1 = 0x111111111111111111111111;

        let mut utxo_state = UtreexoState {
            roots: array![Option::Some(0x111111111111111111111111)].into(), num_leaves: 1
        };
        let proof = UtreexoProof { leaf_index: 0, proof: array![].span(), };
        let result = utxo_state.verify(leaf1, @proof);
        assert!(result.is_ok(), "Root at index 0 should be 0x111111111111111111111111");

        // Add the second leaf (0x222222222222222222222222)
        let leaf2 = 0x222222222222222222222222;

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
        let result = utxo_state.verify(leaf2, @proof);
        assert!(
            result.is_ok(),
            "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
        );

        // Add the third leaf (0x333333333333333333333333)
        let leaf3 = 0x333333333333333333333333;
        utxo_state =
            UtreexoState {
                roots: array![
                    Option::Some(leaf3),
                    Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a)
                ]
                    .into(),
                num_leaves: 1
            };

        let proof = UtreexoProof {
            leaf_index: 1, proof: array![0x111111111111111111111111].span(),
        };
        let result = utxo_state.verify(leaf2, @proof);
        assert!(
            result.is_ok(),
            "Root at index 1 should be 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a"
        );

        // Add the fourth leaf (0x444444444444444444444444)

        let leaf4 = 0x444444444444444444444444;

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
        let result = utxo_state.verify(leaf1, @proof);
        assert!(result.is_ok(), "verify leaf index 0 failed");
        // Create the UtreexoProof for leaf 2
        let proof = UtreexoProof {
            leaf_index: 1,
            proof: array![leaf1, 0x02a6b2ae998d30e1ac356c32b2750c3126cd6b3ecf02e6918a93021d17b2b026]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(leaf2, @proof);
        assert!(result.is_ok(), "verify leaf index 1 failed");

        // Create the UtreexoProof for leaf 3
        let proof = UtreexoProof {
            leaf_index: 2,
            proof: array![leaf4, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(leaf3, @proof);
        assert!(result.is_ok(), "verify leaf index 2 failed");

        // Create the UtreexoProof for leaf 4
        let proof = UtreexoProof {
            leaf_index: 3,
            proof: array![leaf3, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(leaf4, @proof);
        assert!(result.is_ok(), "verify leaf index 3 failed");

        // Create the UtreexoProof for leaf 4
        let proof = UtreexoProof {
            leaf_index: 3,
            proof: array![leaf2, 0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a]
                .span(),
        };
        // Call the verify function
        let result = utxo_state.verify(leaf4, @proof);
        assert!(result.is_err(), "verify leaf index 3 should fail");
    }

    #[test]
    fn test_utreexo_add() {
        // Test data is generated using scripts/data/utreexo.py

        let mut utreexo_state: UtreexoState = Default::default();
        let outpoint: felt252 = 0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C;

        // add first leave to empty utreexo
        utreexo_state.add(outpoint);

        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add first leave");
        assert_eq!(utreexo_state.num_leaves, 1);

        // add second leave
        utreexo_state.add(outpoint);

        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add second leave");
        assert_eq!(utreexo_state.num_leaves, 2);

        // add thirdth leave
        utreexo_state.add(outpoint);

        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add thirdth leave");
        assert_eq!(utreexo_state.num_leaves, 3);

        // add fourth leave
        utreexo_state.add(outpoint);

        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::None,
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add fourth leave");
        assert_eq!(utreexo_state.num_leaves, 4);

        // add fifth leave
        utreexo_state.add(outpoint);

        let expected: Span<Option<felt252>> = array![
            Option::Some(0x291F8F5FC449D42C715B529E542F24A80136D18F4A85DE28829CD3DCAAC1B9C),
            Option::None,
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add fifth leave");
        assert_eq!(utreexo_state.num_leaves, 5);

        // add 3 leaves
        for _ in 1..4_u8 {
            utreexo_state.add(outpoint);
        };

        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::None,
            Option::None,
            Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
            Option::None
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add 3 leaves");
        assert_eq!(utreexo_state.num_leaves, 8);

        // add 22 leaves
        for _ in 1..23_u8 {
            utreexo_state.add(outpoint);
        };

        let expected: Span<Option<felt252>> = [
            Option::None(()),
            Option::Some(0x738A7C495E564574993BBCB6A62D65C3C570BB81C63801066AF8934649F66F6),
            Option::Some(0x25D0DE35DD446E3D35504866FD7A04D4245E01B5908E19EAA70ABA84DD5A1F1),
            Option::Some(0x708EB39E30B035376EC871F8F17CD3BADAE6A68406B13C3BB671009D56F5AD),
            Option::Some(0x58D6BEF6CFC28638FB4C8271355961F50922BCC1577DD2B6D04E11B7A911702),
            Option::None(())
        ].span();
        assert_eq!(utreexo_state.roots, expected, "cannot add 22 leaves");
        assert_eq!(utreexo_state.num_leaves, 30);
    }

    #[test]
    fn test_utreexo_delete() {
        // Test data is generated using scripts/data/utreexo.py

        let mut utreexo_state: UtreexoState = Default::default();

        // adds 16 leaves to empty utreexo
        utreexo_state.add(0x111111111111111111111111);
        utreexo_state.add(0x222222222222222222222222);
        utreexo_state.add(0x333333333333333333333333);
        utreexo_state.add(0x444444444444444444444444);
        utreexo_state.add(0x555555555555555555555555);
        utreexo_state.add(0x666666666666666666666666);
        utreexo_state.add(0x777777777777777777777777);
        utreexo_state.add(0x888888888888888888888888);
        utreexo_state.add(0x999999999999999999999999);
        utreexo_state.add(0xAAAAAAAAAAAAAAAAAAAAAAAA);
        utreexo_state.add(0xBBBBBBBBBBBBBBBBBBBBBBBB);
        utreexo_state.add(0xCCCCCCCCCCCCCCCCCCCCCCCC);
        utreexo_state.add(0xEEEEEEEEEEEEEEEEEEEEEEEE);
        utreexo_state.add(0xFFFFFFFFFFFFFFFFFFFFFFFF);
        utreexo_state.add(0xFFFFFFFFFFFFFFFFFFFFFFF0);
        utreexo_state.add(0xFFFFFFFFFFFFFFFFFFFFFFF1);

        let expected: Span<Option<felt252>> = array![
            Option::None,
            Option::None,
            Option::None,
            Option::None,
            Option::Some(0x03467aa210cc0b108229d9a7fc554f9175af4ee27ee08b128b96862f7beca2ea),
            Option::None,
        ]
            .span();
        assert_eq!(utreexo_state.roots, expected, "cannot add second leave");
        assert_eq!(utreexo_state.num_leaves, 16);

        let proof_for_3rd_leaf: UtreexoProof = UtreexoProof {
            leaf_index: 2,
            proof: array![
                0x0000000000000000000000000000000000000000444444444444444444444444,
                0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a,
                0x01670d29719eae8deaa34a1d75752368d180a2c3e53f08d344ad784f1a034be7,
                0x04448e395061d8b58524c81978a17837c66c7f3286ea3c1773c7fafd77d29f69
            ]
                .span()
        };

        // deletes the 3rd leaf
        utreexo_state.delete(@proof_for_3rd_leaf);

        let expected: Span<Option<felt252>> = array![
            Option::Some(0x0000000000000000000000000000000000000000444444444444444444444444),
            Option::Some(0x05fb342b44641ae6d67310cf9da5566e1a398fd6b0121d40e2c5acd16e1ddb4a),
            Option::Some(0x01670d29719eae8deaa34a1d75752368d180a2c3e53f08d344ad784f1a034be7),
            Option::Some(0x04448e395061d8b58524c81978a17837c66c7f3286ea3c1773c7fafd77d29f69),
            Option::None,
            Option::None,
        ]
            .span();

        assert_eq!(utreexo_state.roots, expected, "cannot remove leave");
        assert_eq!(utreexo_state.num_leaves, 15);
    }
}
