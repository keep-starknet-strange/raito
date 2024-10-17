use utils::bits::bit_len;
use utils::sort::bubble_sort;
use utils::bit_shifts::{shl, shr};
use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::{UtreexoBatchProof, UtreexoBatchProofTrait};

#[generate_trait]
pub impl StumpUtreexoAccumulatorImpl of StumpUtreexoAccumulator {
    /// Adds multiple items to the accumulator.
    fn add(self: @UtreexoStumpState, hashes: Span<felt252>) -> UtreexoStumpState {
        // TODO: check if vanilla implementation is compatible with rustreexo, add tests
        // https://github.com/mit-dci/rustreexo/blob/6a8fe53fa545df8f1a30733fa6ca9f7b0077d051/src/accumulator/stump.rs#L252
        *self
    }

    /// Verifies that one or multiple leaves hashes are part of the utreexo forest given a proof.
    fn verify(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, del_hashes: Span<felt252>
    ) -> Result<(), ByteArray> {
        let computed_roots: Span<felt252> = proof.compute_roots(del_hashes, *self.num_leaves)?;
        let mut number_matched_roots: u32 = 0;

        for i in 0
            ..computed_roots
                .len() {
                    for root in *self
                        .roots {
                            match root {
                                Option::Some(root) => {
                                    if (computed_roots[i] == root) {
                                        number_matched_roots += 1;
                                    };
                                },
                                Option::None => {},
                            };
                        };
                };

        let computed_roots_len = computed_roots.len();

        if (computed_roots_len != number_matched_roots && computed_roots_len != 0) {
            return Result::Err("Proof verification failed");
        }

        Result::Ok(())
    }

    fn delete(
        self: @UtreexoStumpState, leaves: Span<felt252>, proof: @UtreexoBatchProof
    ) -> UtreexoStumpState {
        if leaves.len() == 0 {
            return *self;
        }

        // Extra check that can be removed later.
        assert(leaves.len() == (*proof.targets).len(), 'leaves do not match targets');

        let updated_roots = empty_and_reroot(leaves, proof, *self.num_leaves)
            .expect('failed to empty and reroot');

        let mut roots = array![];
        let mut cnt = 0;
        for root in *self
            .roots {
                if let Option::Some(new_root) = find_root(updated_roots.span(), *root) {
                    roots.append(new_root);
                    cnt += 1;
                } else {
                    roots.append(*root);
                }
            };

        assert(cnt == updated_roots.len(), 'invalid proof');

        UtreexoStumpState { roots: roots.span(), num_leaves: *self.num_leaves }
    }
}

impl PositionPartialOrd<T, +Drop<T>> of PartialOrd<(u64, T)> {
    fn lt(lhs: (u64, T), rhs: (u64, T)) -> bool {
        let (l, _) = lhs;
        let (r, _) = rhs;
        l < r
    }
}

/// Sets leaves to None and recalculates parent roots.
fn empty_and_reroot(
    leaves: Span<felt252>, proof: @UtreexoBatchProof, total_leaves: u64,
) -> Result<Array<(Option<felt252>, Option<felt252>)>, ByteArray> {
    let mut roots: Array<(Option<felt252>, Option<felt252>)> = array![];

    let total_rows = bit_len(total_leaves - 1);
    let proof_positions = get_proof_positions(*proof.targets, total_leaves, total_rows);

    let mut provided_nodes = array![]; // tuples (position, (old_hash, new_hash))
    let mut i = 0;
    while i < leaves.len() {
        provided_nodes.append((*proof.targets[i], (Option::Some(*leaves[i]), Option::None)));
        i += 1;
    };

    let mut i = 0;
    while i < proof_positions.len() {
        provided_nodes.append((*proof_positions[i], (*proof.proof[i], *proof.proof[i])));
        i += 1;
    };

    provided_nodes = bubble_sort(provided_nodes.span());

    let mut computed_nodes = array![];
    let mut computed_index = 0;
    let mut provided_index = 0;
    let mut error = Option::None;
    loop {
        if let Option::Some((pos, (old_hash, new_hash))) =
            get_next(
                ref computed_nodes, ref provided_nodes, ref computed_index, ref provided_index
            ) {
            if is_root_position(pos, total_leaves, total_rows) {
                roots.append((old_hash, new_hash));
                continue;
            }

            if let Option::Some((sibling_pos, (sibling_old_hash, sibling_new_hash))) =
                get_next(
                    ref computed_nodes, ref provided_nodes, ref computed_index, ref provided_index
                ) {
                if sibling_pos != pos ^ 1 {
                    error = Option::Some(format!("Missing sibling for {}", pos));
                    break;
                }

                let parent_pos = get_parent_position(pos, total_rows);
                let old_parent_hash = get_parent_hash(old_hash, sibling_old_hash);
                let new_parent_hash = get_parent_hash(new_hash, sibling_new_hash);

                computed_nodes.append((parent_pos, (old_parent_hash, new_parent_hash)));
            } else {
                error = Option::Some(format!("Missing sibling for {}", pos));
                break;
            }
        } else {
            break;
        };
    };

    if error.is_some() {
        return Result::Err(error.unwrap());
    }

    Result::Ok(roots)
}

fn get_proof_positions(targets: Span<u64>, total_leaves: u64, total_rows: u64,) -> Array<u64> {
    let mut proof_positions: Array<u64> = array![];
    let mut computed_positions: Array<u64> = targets.into();

    let mut row = 0;
    while row <= total_rows {
        computed_positions = bubble_sort(computed_positions.span());
        let mut row_positions = get_row_positions(row, computed_positions.span(), total_rows);

        while let Option::Some(node) = row_positions.pop_front() {
            if is_root_position(node, total_leaves, total_rows) {
                continue;
            }

            if let Option::Some(next) = row_positions.get(0) {
                if is_sibling(node, *(next.unbox())) {
                    row_positions.pop_front().unwrap();
                } else {
                    proof_positions.append(node ^ 1);
                }
            } else {
                proof_positions.append(node ^ 1);
            }

            computed_positions.append(get_parent_position(node, total_rows));
        };

        row += 1;
    };

    proof_positions
}

fn get_next<T, +Copy<T>, +Drop<T>>(
    ref computed: Array<(u64, T)>,
    ref provided: Array<(u64, T)>,
    ref computed_pos: u32,
    ref provided_pos: u32,
) -> Option<(u64, T)> {
    let last_computed = computed.get(computed_pos);
    let last_provided = provided.get(provided_pos);

    match (last_computed, last_provided) {
        (
            Option::Some(node1), Option::Some(node2)
        ) => {
            let (pos1, hashes1) = *(node1.unbox());
            let (pos2, hashes2) = *(node2.unbox());
            if pos1 < pos2 {
                computed_pos += 1;
                Option::Some((pos1, hashes1))
            } else {
                provided_pos += 1;
                Option::Some((pos2, hashes2))
            }
        },
        (Option::Some(node), Option::None) => {
            computed_pos += 1;
            Option::Some(*(node.unbox()))
        },
        (Option::None, Option::Some(node)) => {
            provided_pos += 1;
            Option::Some(*(node.unbox()))
        },
        (Option::None, Option::None) => Option::None,
    }
}

fn get_row_positions(row: u64, computed_positions: Span<u64>, total_rows: u64) -> Array<u64> {
    let mut res = array![];
    for x in computed_positions {
        if detect_row(*x, total_rows) == row {
            res.append(*x);
        }
    };
    res
}

fn get_parent_position(pos: u64, total_rows: u64) -> u64 {
    shr(pos, 1_u64) | shl(1_u64, total_rows)
}

fn get_parent_hash(left: Option<felt252>, right: Option<felt252>) -> Option<felt252> {
    match (left.is_none(), right.is_none()) {
        (true, true) => Option::None,
        (true, false) => right,
        (false, true) => left,
        (false, false) => Option::Some(parent_hash(left.unwrap(), right.unwrap())),
    }
}

fn is_sibling(a: u64, b: u64) -> bool {
    a ^ 1 == b
}

fn detect_row(pos: u64, total_rows: u64) -> u64 {
    let mut marker: u64 = shl(1_u64, total_rows);
    let mut h: u64 = 0;

    while pos & marker != 0 {
        marker = shr(marker, 1_u64);
        h += 1;
    };

    h
}

fn is_root_position(position: u64, total_leaves: u64, total_rows: u64) -> bool {
    let row = detect_row(position, total_rows);

    let root_present = total_leaves & shl(1, row) != 0;
    let root_pos = root_position(total_leaves, row, total_rows);

    root_present && root_pos == position
}

// TODO: undefined behavior if the given row doesn't have a root
fn root_position(total_leaves: u64, row: u64, total_rows: u64) -> u64 {
    let mask = shl(2, total_rows) - 1;
    let before = total_leaves & shl(mask, (row + 1));

    let shifted = shr(before, row) | shl(mask, (total_rows + 1 - row));
    shifted & mask
}

fn find_root(
    roots: Span<(Option<felt252>, Option<felt252>)>, root: Option<felt252>
) -> Option<Option<felt252>> {
    let mut res = Option::None;
    for (_old, _new) in roots {
        if *_old == root {
            res = Option::Some(*_new);
            break;
        }
    };
    res
}


#[cfg(test)]
mod tests {
    use super::{UtreexoStumpState, StumpUtreexoAccumulator, UtreexoBatchProof};

    #[test]
    fn test_deletion_1_1() {
        let state = UtreexoStumpState { roots: array![Option::Some('a')].span(), num_leaves: 1 };

        let batch_proof = UtreexoBatchProof { targets: array![].span(), proof: array![].span() };

        let target_hashes = array![];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 1);
        assert_eq!(new_state.roots, array![Option::Some('a')].span());
    }

    #[test]
    fn test_deletion_1_2() {
        let state = UtreexoStumpState { roots: array![Option::Some('a')].span(), num_leaves: 1 };

        let batch_proof = UtreexoBatchProof { targets: array![0].span(), proof: array![].span() };

        let target_hashes = array!['a'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 1);
        assert_eq!(new_state.roots, array![Option::None].span());
    }

    #[test]
    fn test_deletion_8_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                Option::Some('b'),
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                ),
                Option::Some(
                    1970675917964935639615849678644334216784892342767290630432190461589093258001
                ),
            ]
                .span()
        };

        let target_hashes = array!['a'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    3345421944025286217980549018138297349958141750618054570424649972274280624201
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 1].span(),
            proof: array![
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                ),
                Option::Some(
                    1970675917964935639615849678644334216784892342767290630432190461589093258001
                ),
            ]
                .span()
        };

        let target_hashes = array!['a', 'b'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    2850064462912342803614938379907776937447719434508740518644801944855647065404
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 1, 2].span(),
            proof: array![
                Option::Some('d'),
                Option::Some(
                    1970675917964935639615849678644334216784892342767290630432190461589093258001
                ),
            ]
                .span()
        };

        let target_hashes = array!['a', 'b', 'c'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    3021045430882547327596950725247172779074256595054900316875788021760349090257
                ),
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_8_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6].span(), proof: array![Option::Some('h')].span()
        };

        let target_hashes = array!['a', 'b', 'c', 'd', 'e', 'f', 'g'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots,
            array![Option::None, Option::None, Option::None, Option::Some('h')].span()
        );
    }

    #[test]
    fn test_deletion_8_5() {
        let state = UtreexoStumpState {
            roots: array![
                Option::None,
                Option::None,
                Option::None,
                Option::Some(
                    555370024363052154426534073187628105642230667669796211052131558433241164031
                )
            ]
                .span(),
            num_leaves: 8
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6, 7].span(), proof: array![].span()
        };

        let target_hashes = array!['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 8);
        assert_eq!(
            new_state.roots, array![Option::None, Option::None, Option::None, Option::None].span()
        );
    }

    #[test]
    fn test_deletion_7_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                Option::Some('b'),
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                )
            ]
                .span()
        };

        let target_hashes = array!['a'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::Some('g'),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    1229642933490472299984329107953625663040621781839429280809499005981139964854
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 2, 4, 6].span(),
            proof: array![Option::Some('b'), Option::Some('d'), Option::Some('f')].span()
        };

        let target_hashes = array!['a', 'c', 'e', 'g'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::Some('f'),
                Option::Some(
                    1012329657042087226062405582801477394059887655150284803644932492275110107160
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![1, 3, 5].span(),
            proof: array![Option::Some('a'), Option::Some('c'), Option::Some('e')].span()
        };

        let target_hashes = array!['b', 'd', 'f'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::Some('g'),
                Option::Some('e'),
                Option::Some(
                    1442415957443312626722273931205158047965396421097404482753913691074484308909
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 6].span(),
            proof: array![
                Option::Some('b'),
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                )
            ]
                .span()
        };

        let target_hashes = array!['a', 'g'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    1229642933490472299984329107953625663040621781839429280809499005981139964854
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_5() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![4, 5, 6].span(), proof: array![].span()
        };

        let target_hashes = array!['e', 'f', 'g'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(
            new_state.roots,
            array![
                Option::None,
                Option::None,
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span()
        );
    }

    #[test]
    fn test_deletion_7_6() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        let batch_proof = UtreexoBatchProof {
            targets: array![0, 1, 2, 3, 4, 5, 6].span(), proof: array![].span()
        };

        let target_hashes = array!['a', 'b', 'c', 'd', 'e', 'f', 'g'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(new_state.roots, array![Option::None, Option::None, Option::None].span());
    }

    #[test]
    fn test_deletion_7_7() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(103),
                Option::Some(
                    411226027934254579827031836427260754155547814753354544773152242745331653508
                ),
                Option::Some(
                    2858081605429646247202638041541950020464262679066089136848920825648707910133
                )
            ]
                .span(),
            num_leaves: 7
        };

        // Remove 0

        let batch_proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![
                Option::Some('b'),
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                )
            ]
                .span()
        };

        let target_hashes = array!['a'];

        let new_state = state.delete(target_hashes.span(), @batch_proof);

        // Remove 1

        let batch_proof = UtreexoBatchProof {
            targets: array![1].span(),
            proof: array![
                Option::None,
                Option::Some(
                    1702961261074558847535372708423978610134065667337563473891781271138689292959
                )
            ]
                .span()
        };

        let target_hashes = array!['b'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        // Remove 2

        let batch_proof = UtreexoBatchProof {
            targets: array![2].span(), proof: array![Option::Some('d'), Option::None].span()
        };

        let target_hashes = array!['c'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        // Remove 3

        let batch_proof = UtreexoBatchProof {
            targets: array![3].span(), proof: array![Option::None, Option::None].span()
        };

        let target_hashes = array!['d'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        // Remove 4

        let batch_proof = UtreexoBatchProof {
            targets: array![4].span(), proof: array![Option::Some('f')].span()
        };

        let target_hashes = array!['e'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        // Remove 5

        let batch_proof = UtreexoBatchProof {
            targets: array![5].span(), proof: array![Option::None].span()
        };

        let target_hashes = array!['f'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        // Remove 6

        let batch_proof = UtreexoBatchProof { targets: array![6].span(), proof: array![].span() };

        let target_hashes = array!['g'];

        let new_state = new_state.delete(target_hashes.span(), @batch_proof);

        assert_eq!(new_state.num_leaves, 7);
        assert_eq!(new_state.roots, array![Option::None, Option::None, Option::None].span());
    }
}

#[cfg(test)]
mod tests {
    use super::{UtreexoStumpState, StumpUtreexoAccumulator, UtreexoBatchProof};

    #[test]
    fn test_verification_1() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7)
            ]
                .span(),
            num_leaves: 2
        };
        let batch_proof = UtreexoBatchProof { targets: array![0].span(), proof: array![2].span() };
        let del_hashes = array![1];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_2() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x1702d734e291ad551b886a70b96446b99e19e405511e71fb5edfc4d2d83ce92),
                Option::Some(0x770ad1be69d195e821c8c35051b32492e71592e230b950a99ebf87e98967ca),
                Option::Some(0x2392042cbfda7371c81c9d7b456563533c2d6998b9e690a0d97421e6ae51a98),
                Option::Some(0xf),
            ]
                .span(),
            num_leaves: 15
        };
        let batch_proof = UtreexoBatchProof {
            targets: array![1, 3, 10, 13].span(),
            proof: array![
                0x1,
                0x3,
                0xC,
                0xD,
                0x436e91732c0a83fa238d71460463f4b1fe0dc0b1ebcbc10967a84cec9d13154,
                0xdc9cc50aff0bdadd82a05bbab54015a07fccf2a4e30fa528fdca5a35d5423f
            ]
                .span()
        };
        let del_hashes = array![2, 4, 11, 14];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x519631921e4905a63203f0cca7f6e6917082f30cef0930aa05bdc4323f6a398),
                Option::Some(0x5198dcd61c969dfa8396dd27439ab776d120c2d67294fbcded0aa5f658f9150),
                Option::Some(0x21d7ab8efac0146b5b47c8ad5431c3d14d9210319b0be7428fb2382ef115671),
                Option::Some(0x74f794e653e00357d8a8ed45fcb74659841190c0821aa4e20bc4e30b2f3dd20),
            ]
                .span(),
            num_leaves: 30
        };
        let batch_proof = UtreexoBatchProof {
            targets: array![4, 8, 12, 16, 20, 24, 28].span(),
            proof: array![
                0x6,
                0xA,
                0xE,
                0x12,
                0x16,
                0x1A,
                0x1E,
                0x2797a40dbb8ea4b69a4e3bb4a9ccaa21a9585fcc71f3e5bb053ccae27910f90,
                0x7877cc14d4c8e76cc51aa4c49aa7aadaade0cf475ad63bb37c27c324e145393,
                0x556ea8bad1db13c6bdc3150a8289cd12044fb7e03cf201f35924a8afd4265a6,
                0x41a4ec75a27497daa51261588a60f0956d3fd61e521634bbf36bba6343c3a1b,
                0x3ba731d3734536d7cd5382cb4004ca4c24f1325b6fbeae27bcd6b4f9c0ed714,
                0x117ed04a65093683f13c16cf73d2855f1f099a96581d1dad74eaf34c9a343c8,
                0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6
            ]
                .span()
        };

        let del_hashes = array![5, 9, 13, 17, 21, 25, 29];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }
}
