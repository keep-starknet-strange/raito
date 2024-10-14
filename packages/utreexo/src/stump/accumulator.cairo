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
