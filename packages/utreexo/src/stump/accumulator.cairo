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
        let state = UtreexoStumpState { roots: array![].span(), num_leaves: 0 };
        let batch_proof = UtreexoBatchProof { targets: array![].span(), proof: array![].span() };
        let del_hashes = array![];

        let result = state.verify(@batch_proof, del_hashes.span(),);
        assert_eq!(result, Result::Ok(()));
    }
}
