use core::fmt::{Display, Formatter, Error};

/// Utreexo inclusion proof for multiple outputs.
/// Compatible with https://github.com/utreexo/utreexo
#[derive(Drop, Copy)]
pub struct UtreexoBatchProof {
    /// List of sibling nodes required to calculate the roots.
    pub proof: Span<felt252>,
    /// Indices of leaves to be deleted (ordered starting from 0, left to right).
    pub targets: Span<u64>,
}

impl UtreexoBatchProofDisplay of Display<UtreexoBatchProof> {
    fn fmt(self: @UtreexoBatchProof, ref f: Formatter) -> Result<(), Error> {
        let mut targets: ByteArray = Default::default();
        let mut proofs: ByteArray = Default::default();
        for proof in *self.proof {
            proofs.append(@format!("{},", proof));
        };
        for target in *self.targets {
            targets.append(@format!("{},", target));
        };
        let str: ByteArray = format!(
            "UtreexoBatchProof {{ proof: [{}], leaf_index: [{}] }}", @targets, @proofs
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[generate_trait]
pub impl UtreexoBatchProofImpl of UtreexoBatchProofTrait {
    /// Computes a set of roots given a proof and leaves hashes.
    fn compute_roots(
        self: @UtreexoBatchProof, outpoints_hashes: Span<felt252>, num_leaves: u64,
    ) -> Result<Span<felt252>, ByteArray> {
        // TODO
        Result::Ok(array![].span())
    }
}

