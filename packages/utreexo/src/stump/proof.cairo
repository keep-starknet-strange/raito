use core::fmt::{Display, Formatter, Error};
use core::num::traits::Bounded;
use crate::parent_hash;
use utils::{numeric::u64_next_power_of_two, sort::bubble_sort};

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
    /// Computes leaves' roots.
    fn compute_roots(
        self: @UtreexoBatchProof, leaves: Span<felt252>, num_leaves: u64,
    ) -> Result<Array<felt252>, ByteArray> {
        // hashes of leaves in the proof
        let mut hashes = leaves;
        // positions of leaves in the proof (must exactly match hashes)
        let mut positions = *self.targets;
        // siblings, needed to compute the roots
        let mut proof = *self.proof;

        if hashes.len() != positions.len() {
            return Result::Err("Leaves do not match proof targets");
        }

        // we pair positions with hashes into a single array
        let mut targets = array![];
        while let Option::Some(hash) = hashes.pop_front() {
            targets.append((*positions.pop_front().unwrap(), *hash));
        };
        // and sort them by position to align with the proof
        targets = bubble_sort(targets.span());

        // then we take the very first row of the forest:
        // length of the row in the actual forest
        let mut row_len = num_leaves;
        // length of the row in the "perfect forest"
        // (a forest extrapolated intoa single perfect tree)
        let mut row_cap = u64_next_power_of_two(num_leaves);
        // first absolute position in the row ("absolute" means within the perfect forest)
        let mut row_start = 0;
        // last absolute position in the row + 1
        let mut row_end = row_cap;
        // we take all the targets with absolute positions in [row_start; row_end)
        // and put them into a row, also converting positions to relative, i.e. in [0; row_len)
        let mut row = extract_row(ref targets, row_start, row_end);

        // here we accumulate the result
        let mut roots = array![];
        let mut inner_result: Result<Array<felt252>, ByteArray> = Result::Ok(array![]);

        // we process the whole forest row by row from the bottom leaves to the top root
        while row_len != 0 {
            // last relative position in the current row
            let last = row_len - 1;
            // here we accumulate computed parents that will go to the next row.
            let mut next_row_computed = array![];
            // if there are targets on the current row, we take one
            while let Option::Some((pos, hash)) = row.pop_front() {
                // if its relative position is even
                if pos % 2 == 0 {
                    // and if we have at least one more target after it on the current row
                    if let Option::Some(box) = row.get(0) {
                        let (next_pos, next_hash) = box.unbox();
                        // and if that target is exactly on the next position
                        if *next_pos == pos + 1 {
                            // then they are siblings and we are able to compute their parent
                            // directly. Also, since we use relative positions, we can easily
                            // calculate position of the parent on the upper row
                            row.pop_front().unwrap();
                            next_row_computed.append((pos / 2, parent_hash(hash, *next_hash)));
                        } else { // or if the next target is not a sibling
                            // then the sibling must be in the proof, so we take it from there
                            if let Option::Some(proof_hash) = proof.pop_front() {
                                // and compute the parent node
                                next_row_computed.append((pos / 2, parent_hash(hash, *proof_hash)));
                            } else {
                                inner_result = Result::Err("Invalid proof");
                                break;
                            }
                        }
                    } else if pos != last { // or if there are no more targets on the current row, and we are not at the end
                        // of the row, there must be a sibling in the proof
                        // so we get the sibling from the proof
                        if let Option::Some(proof_hash) = proof.pop_front() {
                            // and compute the parent node
                            next_row_computed.append((pos / 2, parent_hash(hash, *proof_hash)));
                        } else {
                            inner_result = Result::Err("Invalid proof");
                            break;
                        }
                    } else { // or if we are at the end of the row, and the relative position is even,
                        // there cannot be siblings, which means it's a root
                        // so we save the root
                        roots.append(hash);
                    }
                } else { // otherwise, if the relative position is odd, then we know for sure that
                    // there must be a sibling, moreover it must be in the proof
                    // so we take the sibling from the proof
                    if let Option::Some(proof_hash) = proof.pop_front() {
                        // and compute the parent node
                        next_row_computed.append((pos / 2, parent_hash(*proof_hash, hash)));
                    } else {
                        inner_result = Result::Err("Invalid proof");
                        break;
                    }
                }
            };

            // after we processed all the targets in the current row and computed their parents,
            // we move the parents (and pending targets from the proof) to the next row and
            // continue, till we reach the top root

            // here we calculate the next row props
            row_len /= 2;
            row_cap /= 2;
            row_start = row_end;
            row_end += row_cap;

            // here we move all computed parents and pending targets to the next row
            if targets.is_empty() {
                row = next_row_computed;
            } else {
                let mut next_row_targets = extract_row(ref targets, row_start, row_end);
                row =
                    if next_row_targets.is_empty() {
                        next_row_computed
                    } else if next_row_computed.is_empty() {
                        next_row_targets
                    } else {
                        // if both arrays are not empty, we merge them into a single sorted array
                        merge_sorted(ref next_row_targets, ref next_row_computed)
                    }
            }
        };

        // after we processed all rows of the forest, computed roots are all settled in the `roots`
        // array, which is automatically ordered, btw

        inner_result?;
        Result::Ok(roots)
    }

    /// Computes leaves' roots before and after deletion and returns pairs (old_root, new_root).
    fn compute_roots_with_deletion(
        self: @UtreexoBatchProof, leaves: Span<felt252>, num_leaves: u64,
    ) -> Result<Array<(felt252, Option<felt252>)>, ByteArray> {
        // the algorithm is practically the same as in the `compute_roots`, with the only difference
        // - we convert the targets into pairs (target, None), meaning (old_value, new_value), and
        // compute parent pairs accordingly, so in the end we have an array of pairs of roots
        // (old_root, new_root), where old_root can be used to verify inclusion and new_root can be
        // used to update utreexo state

        // hashes of leaves in the proof
        let mut hashes = leaves;
        // positions of leaves in the proof (must exactly match hashes)
        let mut positions = *self.targets;
        // siblings, needed to compute the roots
        let mut proof = *self.proof;

        if hashes.len() != positions.len() {
            return Result::Err("Leaves do not match proof targets");
        }

        // we pair positions with hashes into a single array
        let mut targets = array![];
        while let Option::Some(hash) = hashes.pop_front() {
            targets.append((*positions.pop_front().unwrap(), (*hash, Option::None)));
        };
        // and sort them by position to align with the proof
        targets = bubble_sort(targets.span());

        // then we take the very first row of the forest:
        // length of the row in the actual forest
        let mut row_len = num_leaves;
        // length of the row in the "perfect forest"
        // (a forest extrapolated into a single perfect tree)
        let mut row_cap = u64_next_power_of_two(num_leaves);
        // first absolute position in the row ("absolute" means within the perfect forest)
        let mut row_start = 0;
        // last absolute position in the row + 1
        let mut row_end = row_cap;
        // we take all the targets with absolute positions in [row_start; row_end)
        // and put them into a row, also converting positions to relative, i.e. in [0; row_len)
        let mut row = extract_row(ref targets, row_start, row_end);

        // here we accumulate the result
        let mut roots = array![];
        let mut inner_result: Result<Array<(felt252, Option<felt252>)>, ByteArray> = Result::Ok(
            array![]
        );

        // we process the whole forest row by row from the bottom leaves to the top root
        while row_len != 0 {
            // last relative position in the current row
            let last = row_len - 1;
            // here we accumulate computed parents that will go to the next row.
            let mut next_row_computed = array![];
            // if there are targets on the current row, we take one
            while let Option::Some((pos, hash)) = row.pop_front() {
                // if its relative position is even
                if pos % 2 == 0 {
                    // and if we have at least one more target after it on the current row
                    if let Option::Some(box) = row.get(0) {
                        let (next_pos, next_hash) = box.unbox();
                        // and if that target is exactly on the next position
                        if *next_pos == pos + 1 {
                            // then they are siblings and we are able to compute their parent
                            // directly. Also, since we use relative positions, we can easily
                            // calculate position of the parent on the upper row
                            row.pop_front().unwrap();
                            next_row_computed.append((pos / 2, parent_hash_pair(hash, *next_hash)));
                        } else { // or if the next target is not a sibling
                            // then the sibling must be in the proof, so we take it from there
                            if let Option::Some(proof_hash) = proof.pop_front() {
                                // and compute the parent node
                                next_row_computed
                                    .append(
                                        (
                                            pos / 2,
                                            parent_hash_pair(
                                                hash, (*proof_hash, Option::Some(*proof_hash))
                                            )
                                        )
                                    );
                            } else {
                                inner_result = Result::Err("Invalid proof");
                                break;
                            }
                        }
                    } else if pos != last { // or if there are no more targets on the current row, and we are not at the end
                        // of the row, there must be a sibling in the proof
                        // so we get the sibling from the proof
                        if let Option::Some(proof_hash) = proof.pop_front() {
                            // and compute the parent node
                            next_row_computed
                                .append(
                                    (
                                        pos / 2,
                                        parent_hash_pair(
                                            hash, (*proof_hash, Option::Some(*proof_hash))
                                        )
                                    )
                                );
                        } else {
                            inner_result = Result::Err("Invalid proof");
                            break;
                        }
                    } else { // or if we are at the end of the row, and the relative position is even,
                        // there cannot be siblings, which means it's a root
                        // so we save the root
                        roots.append(hash);
                    }
                } else { // otherwise, if the relative position is odd, then we know for sure that
                    // there must be a sibling, moreover it must be in the proof
                    // so we take the sibling from the proof
                    if let Option::Some(proof_hash) = proof.pop_front() {
                        // and compute the parent node
                        next_row_computed
                            .append(
                                (
                                    pos / 2,
                                    parent_hash_pair((*proof_hash, Option::Some(*proof_hash)), hash)
                                )
                            );
                    } else {
                        inner_result = Result::Err("Invalid proof");
                        break;
                    }
                }
            };

            // after we processed all the targets in the current row and computed their parents,
            // we move the parents (and pending targets from the proof) to the next row and
            // continue, till we reach the top root

            // here we calculate the next row props
            row_len /= 2;
            row_cap /= 2;
            row_start = row_end;
            row_end += row_cap;

            // here we move all computed parents and pending targets to the next row
            if targets.is_empty() {
                row = next_row_computed;
            } else {
                let mut next_row_targets = extract_row(ref targets, row_start, row_end);
                row =
                    if next_row_targets.is_empty() {
                        next_row_computed
                    } else if next_row_computed.is_empty() {
                        next_row_targets
                    } else {
                        // if both arrays are not empty, we merge them into a single sorted array
                        merge_sorted(ref next_row_targets, ref next_row_computed)
                    }
            }
        };

        // after we processed all rows of the forest, computed roots are all settled in the `roots`
        // array, which is automatically ordered, btw

        inner_result?;
        Result::Ok(roots)
    }

    /// Legacy implementation of leaves' roots computation.
    fn compute_roots_legacy(
        self: @UtreexoBatchProof, mut del_hashes: Span<felt252>, num_leaves: u64,
    ) -> Result<Span<felt252>, ByteArray> {
        // Where all the parent hashes we've calculated in a given row will go to.
        let mut calculated_root_hashes: Array<felt252> = array![];
        // Target leaves
        let mut leaf_nodes: Array<(u64, felt252)> = array![];

        let mut inner_result = Result::Ok((array![].span()));

        // Append targets with their hashes.
        let mut positions = *self.targets;
        while let Option::Some(rhs) = del_hashes.pop_front() {
            if let Option::Some(lhs) = positions.pop_front() {
                leaf_nodes.append((*lhs, *rhs));
            } else {
                inner_result = Result::Err("Not enough targets in the proof.");
            }
        };

        let mut leaf_nodes: Array<(u64, felt252)> = bubble_sort(leaf_nodes.span());

        // Proof nodes.
        let mut sibling_nodes: Array<felt252> = (*self.proof).into();
        // Queue of computed intermediate nodes.
        let mut computed_nodes: Array<(u64, felt252)> = array![];
        // Actual length of the current row.
        let mut actual_row_len: u64 = num_leaves;
        // Length of the "padded" row which is always power of two.
        let mut row_len: u64 = u64_next_power_of_two(num_leaves);
        // Total padded length of processed rows (excluding the current one).
        let mut row_len_acc: u64 = 0;
        // Next position of the target leaf and the leaf itself.
        let (mut next_leaf_pos, mut next_leaf) = leaf_nodes.pop_front().unwrap();
        // Next computed node.
        let mut next_computed: felt252 = 0;
        // Position of the next computed node.
        let mut next_computed_pos: u64 = Bounded::<u64>::MAX;

        while row_len != 0 {
            let (pos, node) = if next_leaf_pos < next_computed_pos {
                let res = (next_leaf_pos, next_leaf);
                let (a, b) = leaf_nodes.pop_front().unwrap_or((Bounded::<u64>::MAX, 0));
                next_leaf_pos = a;
                next_leaf = b;
                res
            } else if next_computed_pos != Bounded::<u64>::MAX {
                let res = (next_computed_pos, next_computed);
                let (a, b) = computed_nodes.pop_front().unwrap_or((Bounded::<u64>::MAX, 0));
                next_computed_pos = a;
                next_computed = b;
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

                if row_len == 0 {
                    inner_result =
                        Result::Err(
                            format!("Position {pos} is out of the forest range {row_len_acc}.")
                        );
                    break;
                }
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
                    let (a, b) = leaf_nodes.pop_front().unwrap_or((Bounded::<u64>::MAX, 0));
                    next_leaf_pos = a;
                    next_leaf = b;
                    res
                } else if next_computed_pos == pos + 1 {
                    let res = next_computed;
                    let (a, b) = computed_nodes.pop_front().unwrap_or((Bounded::<u64>::MAX, 0));
                    next_computed_pos = a;
                    next_computed = b;
                    res
                } else {
                    if sibling_nodes.is_empty() {
                        inner_result = Result::Err("Proof is empty.");
                        break;
                    };
                    sibling_nodes.pop_front().unwrap()
                };
                parent_hash(node, right_sibling)
            } else {
                // Left sibling always from proof.
                if let Option::Some(left_sibling) = sibling_nodes.pop_front() {
                    parent_hash(left_sibling, node)
                } else {
                    inner_result = Result::Err("Proof is empty.");
                    break;
                }
            };

            let parent_pos = row_len_acc + row_len + (pos - row_len_acc) / 2;

            if next_computed_pos == Bounded::<u64>::MAX {
                next_computed_pos = parent_pos;
                next_computed = parent_node;
            } else {
                computed_nodes.append((parent_pos, parent_node));
            }
        };

        if !sibling_nodes.is_empty() {
            return Result::Err("Proof should be empty");
        }

        if inner_result != Result::Ok((array![].span())) {
            inner_result
        } else {
            Result::Ok((calculated_root_hashes.span()))
        }
    }
}

/// Extracts all nodes with absolute positions in [row_start; row_end)
/// and transforms their positions to relative
fn extract_row<T, +Copy<T>, +Drop<T>>(
    ref nodes: Array<(u64, T)>, row_start: u64, row_end: u64
) -> Array<(u64, T)> {
    let mut row = array![];
    while let Option::Some(box) = nodes.get(0) {
        let (pos, value) = box.unbox();
        if *pos >= row_end {
            break;
        }
        nodes.pop_front().unwrap();
        row.append((*pos - row_start, *value));
    };
    row
}

/// Merges two sorted arrays into a single sorted array
fn merge_sorted<T, +Drop<T>>(
    ref arr1: Array<(u64, T)>, ref arr2: Array<(u64, T)>
) -> Array<(u64, T)> {
    let mut res = array![];
    while let Option::Some((p1, v1)) = arr1.pop_front() {
        while let Option::Some(box) = arr2.get(0) {
            let (p2, _) = box.unbox();
            if *p2 > p1 {
                break;
            }
            res.append(arr2.pop_front().unwrap());
        };
        res.append((p1, v1));
    };
    while let Option::Some(node) = arr2.pop_front() {
        res.append(node);
    };
    res
}

/// Takes two nodes containing two values each: (L1, L2) and (R1, R2), and calculates
/// a parent node, that also contains two values (P1 = h(L1, R1), P2 = h(L2, R2))
fn parent_hash_pair(
    left: (felt252, Option<felt252>), right: (felt252, Option<felt252>)
) -> (felt252, Option<felt252>) {
    let (old_left, new_left) = left;
    let (old_right, new_right) = right;
    let old_parent = parent_hash(old_left, old_right);
    let new_parent = match (new_left.is_some(), new_right.is_some()) {
        (true, true) => Option::Some(parent_hash(new_left.unwrap(), new_right.unwrap())),
        (true, false) => new_left,
        (false, true) => new_right,
        (false, false) => Option::None,
    };
    (old_parent, new_parent)
}

/// PartialOrd implementation for tuple (u64, T).
impl PositionPartialOrd<T, +Drop<T>> of PartialOrd<(u64, T)> {
    fn lt(lhs: (u64, T), rhs: (u64, T)) -> bool {
        let (l, _) = lhs;
        let (r, _) = rhs;
        l < r
    }
}
