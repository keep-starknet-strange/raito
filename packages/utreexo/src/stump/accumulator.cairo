use crate::stump::state::UtreexoStumpState;
use crate::stump::proof::UtreexoBatchProof;

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
        // TODO
        Result::Ok(())
    }

    fn delete(self: @UtreexoStumpState, proof: @UtreexoBatchProof) -> UtreexoStumpState {
        // TODO
        *self
    }
}
