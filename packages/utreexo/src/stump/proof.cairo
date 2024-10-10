use core::fmt::{Display, Formatter, Error};
use crate::parent_hash;
use utils::bit_shifts::{shl, shr};

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
        let total_rows: u8 = if (num_leaves == 0) {
            0
        } else {
            64 - leading_zeros((num_leaves - 1))
        };
        let mut calculated_root_hashes: Array<felt252> = array![];
        let proof_positions: Span<u64> = get_proof_positions(*self.targets, num_leaves, total_rows);

        let mut nodes: Array<(u64, felt252)> = array![];

        // Append targets with their hashes
        let mut i = 0;
        while i != (*self.targets).len() {
            let pos = *self.targets[i];
            nodes.append((pos, *del_hashes[i]));
            i += 1;
        };

        // Append proof positions with their hashes
        while i != proof_positions.len() {
            let pos = *proof_positions[i];
            nodes.append((pos, *self.proof[i]));
            i += 1;
        };

        // Sort nodes for sibling computation
        // Cant find a way to sort an array of tuple for now
        // I would need a custom PartialOrd for tuples, should I do that? How such a sorting would
        // work?
        // nodes = sort(nodes.span());

        let mut computed: Array<(u64, felt252)> = array![];
        let mut computed_index = 0;
        let mut provided_index = 0;

        let mut result: Result<Span<felt252>, ByteArray> = Result::Ok((array![].span()));

        loop {
            // Get the next node or hash
            let (next_pos, next_hash) =
                match get_next(@computed, @nodes, ref computed_index, ref provided_index) {
                Option::Some(x) => x,
                Option::None => { break; },
            };

            // Check if this is a root position
            if is_root_position(next_pos, num_leaves, total_rows) {
                calculated_root_hashes.append(next_hash);
                continue;
            }

            // Find the sibling
            let sibling = next_pos | 1;
            let (sibling_pos, sibling_hash) =
                match get_next(@computed, @nodes, ref computed_index, ref provided_index) {
                Option::Some(x) => x,
                Option::None => (0, 0),
            };

            if sibling_pos == 0 && sibling_hash == 0 {
                break result = Result::Err("Missing sibling");
            }

            if sibling_pos != sibling {
                break result = Result::Err("Mismatch in sibling position");
            }

            // Compute parent hash
            let parent_hash = parent_hash(next_hash, sibling_hash);
            let parent = parent(next_pos, total_rows);
            computed.append((parent, parent_hash));
        };

        // Filter out proof positions from nodes
        let mut filtered_nodes = array![];
        let mut i = 0;
        while i < nodes.len() {
            let (pos, hash) = *nodes[i];
            if binary_search(proof_positions, pos).is_some() {
                filtered_nodes.append((pos, hash));
            }

            i += 1;
        };

        // Are we supposed to return only the list of roots? Because rustreexo impl also returns all
        // the nodes that are not part of the proof, but its not required in `verify` function
        // Maybe we can skip some code (filter out above, etc)

        if !result.is_err() {
            return Result::Ok((calculated_root_hashes.span()));
        } else {
            return result;
        }
    }
}

/// Returns the number of leading zeros in a u64 variable.
fn leading_zeros(x: u64) -> u8 {
    if x == 0 {
        return 64_u8;
    }

    let mut count: u8 = 0;
    let mut bit: u64 = shl(1_u64, 63_u64);

    loop {
        if x & bit == 0 {
            count += 1;
        } else {
            break;
        }
        if bit == 1 {
            break;
        }
        bit = shr(bit, 1_u64);
    };

    count
}

fn get_proof_positions(targets: Span<u64>, num_leaves: u64, forest_rows: u8) -> Span<u64> {
    let mut targets_arr: Array<u64> = array![];
    targets_arr.append_span(targets);
    // No need to sort targets_arr here as we make the assumption that targets is already sorted.

    let mut proof_positions: Array<u64> = array![];

    for row in 0
        ..(forest_rows
            + 1) {
                let mut computed_index = 0;

                while computed_index != targets_arr.len() {
                    let node = *targets_arr[computed_index];
                    if detect_row(node, forest_rows) == row {
                        let is_last_in_row = computed_index
                            + 1 >= targets.len()
                                || detect_row(*targets_arr[computed_index + 1], forest_rows) != row;

                        if !is_root_position(node, num_leaves, forest_rows) {
                            let next_node = if !is_last_in_row {
                                *targets_arr[computed_index + 1]
                            } else {
                                0
                            };

                            if !is_last_in_row && is_sibling(node, next_node) {
                                computed_index += 2;
                            } else {
                                proof_positions.append(node ^ 1);
                                computed_index += 1;
                            };

                            targets_arr.append(parent(node, forest_rows));
                        } else {
                            computed_index += 1;
                        }
                    } else {
                        computed_index += 1;
                    }
                };

                targets_arr = sort(targets_arr.span());
            };

    proof_positions.span()
}

fn detect_row(pos: u64, forest_rows: u8) -> u8 {
    let mut marker: u64 = 1;
    let forest_rows_u64: u64 = forest_rows.into();
    marker = shl(marker, forest_rows_u64);
    let mut h: u8 = 0;

    while pos & marker != 0 {
        marker = shr(marker, 1_u64);
        h += 1;
    };

    h
}

fn parent(pos: u64, forest_rows: u8) -> u64 {
    let forest_row_u64: u64 = forest_rows.into();

    shr(pos, 1_u64) | shl(1_u64, forest_row_u64)
}

fn is_root_position(position: u64, num_leaves: u64, forest_rows: u8) -> bool {
    let row = detect_row(position, forest_rows);
    let row_u64: u64 = row.into();

    let root_present = (num_leaves & (shl(1_u64, row_u64))) != 0;
    let root_pos = root_position(num_leaves, row, forest_rows);

    root_present && root_pos == position
}

fn root_position(num_leaves: u64, row: u8, forest_rows: u8) -> u64 {
    let row_u64: u64 = row.into();
    let forest_rows_u64: u64 = forest_rows.into();
    let mask = (shl(2_u64, forest_rows_u64) - 1) & 18446744073709551615;

    let before = num_leaves & shl(mask, (row_u64 + 1));

    let shifted = shr(before, row_u64) | shl(mask, (forest_rows_u64 + 1 - row_u64));

    shifted & mask
}

/// Returns whether a and b are sibling or not
fn is_sibling(a: u64, b: u64) -> bool {
    a ^ 1 == b
}

fn get_next<T, +Copy<T>, +Drop<T>>(
    computed: @Array<(u64, T)>,
    provided: @Array<(u64, T)>,
    ref computed_pos: usize,
    ref provided_pos: usize
) -> Option<(u64, T)> {
    let (last_computed_index, last_computed_value) = if computed_pos < computed.len() {
        *computed[computed_pos]
    } else {
        return Option::None;
    };

    let (last_provided_index, last_provided_value) = if provided_pos < provided.len() {
        *provided[provided_pos]
    } else {
        return Option::Some((last_computed_index, last_computed_value));
    };

    if last_computed_index < last_provided_index {
        computed_pos += 1;
        return Option::Some((last_computed_index, last_computed_value));
    } else {
        provided_pos += 1;
        return Option::Some((last_provided_index, last_provided_value));
    }
}

// Merge sorting, see
// https://github.com/keep-starknet-strange/alexandria/blob/82088715b454d8cf197b9c54c31525ca0cb57a05/packages/sorting/src/merge_sort.cairo#
// I suppose this can be moved to utils package?
fn sort<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(mut array: Span<T>) -> Array<T> {
    let len = array.len();
    if len == 0 {
        return array![];
    }
    if len == 1 {
        return array![*array[0]];
    }

    // Create left and right arrays
    let middle = len / 2;
    let left_arr = array.slice(0, middle);
    let right_arr = array.slice(middle, len - middle);

    // Recursively sort the left and right arrays
    let sorted_left = sort(left_arr);
    let sorted_right = sort(right_arr);

    let mut result_arr = array![];
    merge_recursive(sorted_left, sorted_right, ref result_arr, 0, 0);
    result_arr
}

fn merge_recursive<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(
    mut left_arr: Array<T>,
    mut right_arr: Array<T>,
    ref result_arr: Array<T>,
    left_arr_ix: usize,
    right_arr_ix: usize
) {
    if result_arr.len() == left_arr.len() + right_arr.len() {
        return;
    }

    if left_arr_ix == left_arr.len() {
        result_arr.append(*right_arr[right_arr_ix]);
        return merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix, right_arr_ix + 1);
    }

    if right_arr_ix == right_arr.len() {
        result_arr.append(*left_arr[left_arr_ix]);
        return merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix + 1, right_arr_ix);
    }

    if *left_arr[left_arr_ix] < *right_arr[right_arr_ix] {
        result_arr.append(*left_arr[left_arr_ix]);
        merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix + 1, right_arr_ix)
    } else {
        result_arr.append(*right_arr[right_arr_ix]);
        merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix, right_arr_ix + 1)
    }
}

// Binary search algorithm
// See
// https://github.com/keep-starknet-strange/alexandria/blob/82088715b454d8cf197b9c54c31525ca0cb57a05/packages/searching/src/binary_search.cairo#
pub fn binary_search<T, +Copy<T>, +Drop<T>, +PartialEq<T>, +PartialOrd<T>>(
    span: Span<T>, val: T
) -> Option<u32> {
    // Initial check
    if span.len() == 0 {
        return Option::None;
    }
    let middle = span.len() / 2;
    if *span[middle] == val {
        return Option::Some(middle);
    }
    if span.len() == 1 {
        return Option::None;
    }
    if *span[middle] > val {
        return binary_search(span.slice(0, middle), val);
    }

    let mut len = middle;
    if span.len() % 2 == 1 {
        len += 1;
    }
    let val = binary_search(span.slice(middle, len), val);
    match val {
        Option::Some(v) => Option::Some(v + middle),
        Option::None => Option::None
    }
}
