use core::fmt::{Display, Formatter, Error};
use core::num::traits::Bounded;
use crate::parent_hash;
use utils::{bit_shifts::shr, sort::bubble_sort, partial_ord::PartialOrdTupleU64Felt252};

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
        self: @UtreexoBatchProof, del_hashes: Span<felt252>, num_leaves: u64,
    ) -> Result<Span<felt252>, ByteArray> {
        // Where all the parent hashes we've calculated in a given row will go to.
        let mut calculated_root_hashes: Array<felt252> = array![];
        // Target leaves
        let mut leaf_nodes: Array<(u64, felt252)> = array![];

        // Append targets with their hashes.
        let mut i = 0;
        while i != (*self.targets).len() {
            let pos = *self.targets[i];
            leaf_nodes.append((pos, *del_hashes[i]));
            i += 1;
        };

        let mut leaf_nodes: Array<(u64, felt252)> = bubble_sort(leaf_nodes.span());

        // Proof nodes.
        let mut sibling_nodes: Array<felt252> = (*self.proof).into();
        // Queue of computed intermediate nodes.
        let mut computed_nodes: Array<(u64, felt252)> = array![];
        // Actual length of the current row
        let mut actual_row_len: u64 = num_leaves;
        // Length of the "padded" row which is always power of two.
        let mut row_len: u64 = next_power_of_two(num_leaves);
        // Total padded length of processed rows (excluding the current one)
        let mut row_len_acc: u64 = 0;
        // Next position of the target leaf and the leaf itself.
        let (mut next_leaf_pos, mut next_leaf) = leaf_nodes.pop_front().unwrap();
        // Next computed node
        let mut next_computed: felt252 = 0;
        // Position of the next computed node
        let mut next_computed_pos: u64 = Bounded::<u64>::MAX;

        while row_len != 0 {
            let (pos, node) = if next_leaf_pos < next_computed_pos {
                let res = (next_leaf_pos, next_leaf);
                if leaf_nodes.is_empty() {
                    next_leaf_pos = Bounded::<u64>::MAX;
                } else {
                    let (a, b) = leaf_nodes.pop_front().unwrap();
                    next_leaf_pos = a;
                    next_leaf = b;
                }
                res
            } else if next_computed_pos != Bounded::<u64>::MAX {
                let res = (next_computed_pos, next_computed);
                if computed_nodes.is_empty() {
                    next_computed_pos = Bounded::<u64>::MAX;
                } else {
                    let (a, b) = computed_nodes.pop_front().unwrap();
                    next_computed_pos = a;
                    next_computed = b;
                }
                res
            } else {
                // Out of nodes, terminating here.
                break;
            };

            // If we are beyond current row, level up.
            while pos >= row_len_acc + row_len {
                row_len_acc += row_len;
                row_len /= 2;
                actual_row_len /= 2;
            };

            // If row length is odd and we are at the edge this is a root.
            if pos == row_len_acc + actual_row_len - 1 && actual_row_len % 2 == 1 {
                calculated_root_hashes.append(node);
                row_len_acc += row_len;
                row_len /= 2;
                actual_row_len /= 2;
                continue;
            };

            let parent_node = if (pos - row_len_acc) % 2 == 0 {
                // Right sibling can be both leaf/computed or proof.
                let right_sibling = if next_leaf_pos == pos + 1 {
                    let res = next_leaf;
                    if leaf_nodes.is_empty() {
                        next_leaf_pos = Bounded::<u64>::MAX;
                    } else {
                        let (a, b) = leaf_nodes.pop_front().unwrap();
                        next_leaf_pos = a;
                        next_leaf = b;
                    }
                    res
                } else if next_computed_pos == pos + 1 {
                    let res = next_computed;
                    if computed_nodes.is_empty() {
                        next_computed_pos = Bounded::<u64>::MAX;
                    } else {
                        let (a, b) = computed_nodes.pop_front().unwrap();
                        next_computed_pos = a;
                        next_computed = b;
                    }
                    res
                } else {
                    sibling_nodes.pop_front().unwrap()
                };
                parent_hash(node, right_sibling)
            } else {
                // Left sibling always from proof.
                let left_sibling = sibling_nodes.pop_front().unwrap();
                parent_hash(left_sibling, node)
            };

            let parent_pos = row_len_acc + row_len + (pos - row_len_acc) / 2;

            if next_computed_pos == Bounded::<u64>::MAX {
                next_computed_pos = parent_pos;
                next_computed = parent_node;
            } else {
                computed_nodes.append((parent_pos, parent_node));
            }
        };

        assert(sibling_nodes.is_empty(), '');
        assert(computed_nodes.is_empty(), '');
        assert(leaf_nodes.is_empty(), '');

        Result::Ok((calculated_root_hashes.span()))
    }
}

/// Computes the next power of two of a u64 variable.
fn next_power_of_two(mut n: u64) -> u64 {
    if n == 0 {
        return 1;
    }

    n -= 1;
    n = n | shr(n, 1_u64);
    n = n | shr(n, 2_u64);
    n = n | shr(n, 4_u64);
    n = n | shr(n, 8_u64);
    n = n | shr(n, 16_u64);
    n = n | shr(n, 32_u64);

    n + 1
}
