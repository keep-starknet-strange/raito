use crate::parent_hash;
use core::fmt::{Display, Formatter, Error};

/// Utreexo inclusion proof for a single transaction output.
#[derive(Drop, Copy, Serde)]
pub struct UtreexoProof {
    /// List of sibling nodes required to calculate the root.
    pub proof: Span<felt252>,
    /// Index of the leaf in the forest, but also an encoded binary path,
    /// specifying which sibling node is left and which is right.
    pub leaf_index: u64,
}

/// `Display` trait implementation for `UtreexoProof`.
impl UtreexoProofDisplay of Display<UtreexoProof> {
    fn fmt(self: @UtreexoProof, ref f: Formatter) -> Result<(), Error> {
        let mut proofs: ByteArray = Default::default();
        for proof in *self.proof {
            proofs.append(@format!("{},", proof));
        };
        let str: ByteArray = format!(
            "UtreexoProof {{ proof: {}, leaf_index: {} }}", *self.leaf_index, @proofs,
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[generate_trait]
pub impl UtreexoProofImpl of UtreexoProofTrait {
    /// Computes the root given a proof and leaf hash.
    ///
    /// Traverses the tree from leaf to root, hashing paired nodes.
    /// Proof order is bottom-up. Returns the computed root.
    fn compute_root(self: @UtreexoProof, leaf_hash: felt252) -> felt252 {
        let mut curr_node = leaf_hash;
        let mut node_index = *self.leaf_index;

        for sibling in *self.proof {
            let (next_node_index, is_right) = DivRem::div_rem(node_index, 2);

            let (left, right) = if is_right == 0 {
                (curr_node, *sibling)
            } else {
                (*sibling, curr_node)
            };
            curr_node = parent_hash(left, right);
            node_index = next_node_index;
        };
        // Return the computed root (or the node itself if the proof is empty).
        curr_node
    }
}
