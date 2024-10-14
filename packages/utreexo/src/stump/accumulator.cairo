use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::{UtreexoBatchProof, UtreexoBatchProofTrait};

#[generate_trait]
pub impl StumpUtreexoAccumulatorImpl of StumpUtreexoAccumulator {
    /// Adds multiple items to the accumulator
    fn add(self: @UtreexoStumpState, hashes: Span<felt252>) -> UtreexoStumpState {
        // TODO: check if vanilla implementation is compatible with rustreexo, add tests
        // https://github.com/mit-dci/rustreexo/blob/6a8fe53fa545df8f1a30733fa6ca9f7b0077d051/src/accumulator/stump.rs#L252
        *self
    }

    fn verify(
        self: @UtreexoStumpState, proof: @UtreexoBatchProof, del_hashes: Span<felt252>
    ) -> Result<(), ByteArray> {
        if (*proof.targets).is_empty() {
            return Result::Ok(());
        };

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

    fn delete(self: @UtreexoStumpState, proof: @UtreexoBatchProof) -> UtreexoStumpState {
        // TODO
        *self
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
                Option::Some(0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6),
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7),
                Option::Some(0x22d481b177090ea8db58ceece7d8493e746d690a1708d438c6c4e51b23c81ee)
            ]
                .span(),
            num_leaves: 5
        };
        let batch_proof = UtreexoBatchProof {
            targets: array![0].span(),
            proof: array![0x2, 0x22d481b177090ea8db58ceece7d8493e746d690a1708d438c6c4e51b23c81ee]
                .span()
        };
        let del_hashes = array![1];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_3() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6),
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7),
                Option::Some(0x22d481b177090ea8db58ceece7d8493e746d690a1708d438c6c4e51b23c81ee)
            ]
                .span(),
            num_leaves: 5
        };
        let batch_proof = UtreexoBatchProof {
            targets: array![1, 3].span(), proof: array![0x1, 0x3].span()
        };
        let del_hashes = array![2, 4];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_verification_4() {
        let state = UtreexoStumpState {
            roots: array![
                Option::Some(0x1702d734e291ad551b886a70b96446b99e19e405511e71fb5edfc4d2d83ce92),
                Option::Some(0x79b32f615bbd57783700ae5f8e7b1ef79677c3545c4c69dc31b3aecce1d8fa6),
                Option::Some(0x371cb6995ea5e7effcd2e174de264b5b407027a75a231a70c2c8d196107f0e7),
                Option::Some(0x22d481b177090ea8db58ceece7d8493e746d690a1708d438c6c4e51b23c81ee),
                Option::Some(0xdc9cc50aff0bdadd82a05bbab54015a07fccf2a4e30fa528fdca5a35d5423f),
                Option::Some(0x1160145b02735dc081307a4f20392a8139739275ad49d5c9c32190ba5fbd054),
                Option::Some(0x2797a40dbb8ea4b69a4e3bb4a9ccaa21a9585fcc71f3e5bb053ccae27910f90),
                Option::Some(0x770ad1be69d195e821c8c35051b32492e71592e230b950a99ebf87e98967ca),
                Option::Some(0x436e91732c0a83fa238d71460463f4b1fe0dc0b1ebcbc10967a84cec9d13154),
                Option::Some(0x7877cc14d4c8e76cc51aa4c49aa7aadaade0cf475ad63bb37c27c324e145393),
                Option::Some(0x2392042cbfda7371c81c9d7b456563533c2d6998b9e690a0d97421e6ae51a98),
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
}
