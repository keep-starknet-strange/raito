use core::traits::DivRem;
use crate::parent_hash;
use crate::stump::proof::{UtreexoBatchProof, UtreexoBatchProofTrait};
use crate::stump::state::UtreexoStumpState;

#[generate_trait]
pub impl StumpUtreexoAccumulatorImpl of StumpUtreexoAccumulator {
    /// Adds multiple items to the accumulator.
    fn add(self: @UtreexoStumpState, hashes: Span<felt252>) -> UtreexoStumpState {
        let mut leaves = *self.num_leaves;

        // This array will hold state of roots after adding new hashes
        // IMPORTANT: This line copies all roots from the current state
        // to the new array
        let mut new_roots: Array<Option<felt252>> = (*self.roots).into();

        for add in hashes {
            // We will use new_roots_span to iterate over the roots that we
            // will merge (thus remove from the state) with the new hash.
            let mut new_roots_span = new_roots.span();
            let mut to_add = *add;

            // This is similar to the vanilla algorithm
            let (mut next_row_len, mut has_root) = DivRem::div_rem(leaves, 2);
            while has_root == 1 {
                // Checks that new_roots_span is not empty
                if let Option::Some(root) = new_roots_span.pop_back() {
                    // Checks that root has value
                    if let Option::Some(root) = root {
                        // Merging with the hash
                        to_add = parent_hash(*root, to_add);
                    }
                }

                let (q, r) = DivRem::div_rem(next_row_len, 2);
                next_row_len = q;
                has_root = r;
            }

            new_roots = new_roots_span.into();
            new_roots.append(Option::Some(to_add));
            leaves += 1;
        }

        UtreexoStumpState { roots: new_roots.span(), num_leaves: leaves }
    }

    /// Verifies that specified leaves are part of the utreexo forest given a proof.
    fn verify(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, leaves: Span<felt252>,
    ) -> Result<(), ByteArray> {
        let computed_roots = proof.compute_roots(leaves, *self.num_leaves)?;
        let num_computed = computed_roots.len();
        let mut their_roots = computed_roots.span();
        let mut our_roots = *self.roots;
        let mut num_matched: usize = 0;

        while let Option::Some(their_root) = their_roots.pop_back() {
            while let Option::Some(maybe_our_root) = our_roots.pop_front() {
                if let Option::Some(our_root) = maybe_our_root {
                    if our_root == their_root {
                        num_matched += 1;
                        break;
                    }
                }
            }
        }

        if num_matched != num_computed {
            return Result::Err(
                format!(
                    "Proof verification failed: computed {} roots, but only {} matched\nComputed: {:?}\nActual: {:?}",
                    num_computed,
                    num_matched,
                    computed_roots,
                    self.roots,
                ),
            );
        }

        Result::Ok(())
    }

    /// Verifies that the specified leaves are part of the utreexo forest given the proof,
    /// deletes them and returns an updated state.
    fn verify_and_delete(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, leaves: Span<felt252>,
    ) -> Result<UtreexoStumpState, ByteArray> {
        let mut computed_roots = proof
            .compute_roots_with_deletion(leaves, *self.num_leaves)?
            .span();
        let mut new_roots = array![];

        // Note that roots are sorted top down
        for maybe_root in *self.roots {
            if let Option::Some(our_root) = maybe_root {
                let computed_len = computed_roots.len();
                if computed_len != 0 {
                    // Computed roots are in reversed order (sorted bottom up)
                    let (their_root, new_root) = computed_roots[computed_len - 1];
                    if our_root == their_root {
                        computed_roots.pop_back().unwrap();
                        new_roots.append(*new_root);
                        continue;
                    }
                }
            }
            new_roots.append(*maybe_root);
        }

        if !computed_roots.is_empty() {
            return Result::Err("Proof verification / leaf deletion failed");
        }

        Result::Ok(UtreexoStumpState { roots: new_roots.span(), num_leaves: *self.num_leaves })
    }
}
