use crate::parent_hash;
use crate::vanilla::proof::{UtreexoProof, UtreexoProofTrait};
use crate::vanilla::state::UtreexoState;

#[generate_trait]
pub impl VanillaUtreexoAccumulatorImpl of VanillaUtreexoAccumulator {
    /// Adds an element to the accumulator.
    /// https://eprint.iacr.org/2019/611.pdf Algorithm 1 AddOne
    fn add(self: @UtreexoState, hash: felt252) -> UtreexoState {
        let mut new_roots: Array<Option<felt252>> = Default::default();
        let mut first_none_found: bool = false;
        let mut node = hash;

        for root in *self.roots {
            if !first_none_found {
                if let Option::Some(root) = root {
                    node = parent_hash(*root, node);
                    new_roots.append(Option::None);
                } else {
                    first_none_found = true;
                    new_roots.append(Option::Some(node));
                }
            } else {
                new_roots.append(*root);
            }
        }

        // Check if terminates with `Option::None`
        if (new_roots[new_roots.len() - 1].is_some()) {
            new_roots.append(Option::None);
        }

        UtreexoState { roots: new_roots.span() }
    }

    /// Removes an element from the accumulator.
    /// https://eprint.iacr.org/2019/611.pdf Algorithm 2 DeleteOne
    fn delete(self: @UtreexoState, proof: @UtreexoProof) -> UtreexoState {
        let mut new_roots: Array<Option<felt252>> = array![];
        let mut node: Option<felt252> = Option::None;

        let num_roots: u32 = (*self.roots).len();
        let proof = *proof.proof;
        let mut height: usize = 0;

        for sibling in proof {
            if node.is_some() {
                node = Option::Some(parent_hash(*sibling, node.unwrap()));
                if height < num_roots {
                    new_roots.append(*self.roots[height]);
                } else {
                    new_roots.append(Option::None);
                }
            } else if height < num_roots && self.roots[height].is_some() {
                node = Option::Some(parent_hash(*sibling, (*self.roots[height]).unwrap()));
                new_roots.append(Option::None);
            } else {
                new_roots.append(Option::Some(*sibling));
            }

            height += 1;
        }

        new_roots.append(node);
        height += 1;
        while height != num_roots {
            new_roots.append(*self.roots[height]);
            height += 1;
        }

        UtreexoState { roots: new_roots.span() }
    }

    /// Verifies inclusion proof for a single element.
    fn verify(self: @UtreexoState, hash: felt252, proof: @UtreexoProof) -> Result<(), ByteArray> {
        let proof_root = proof.compute_root(hash);

        // Get the expected root
        let root_index = (*proof.proof).len();
        if root_index >= (*self.roots).len() {
            return Result::Err(format!("Root index is out of bounds"));
        }

        if let Option::Some(expected_root) = self.roots[root_index] {
            if *expected_root == proof_root {
                return Result::Ok(());
            }
            Result::Err(format!("Expected root {}, but computed {}", expected_root, proof_root))
        } else {
            Result::Err(format!("Target root is empty"))
        }
    }
}
