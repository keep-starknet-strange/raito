use core::fmt::{Display, Error, Formatter};
use crate::vanilla::accumulator::VanillaUtreexoAccumulator;
use crate::vanilla::proof::UtreexoProof;

/// Accumulator representation of the state aka "Compact State Node".
#[derive(Drop, Copy, PartialEq, Serde, Debug)]
pub struct UtreexoState {
    /// Roots of the Merkle tree forest.
    /// Index is the root height, None means a gap.
    pub roots: Span<Option<felt252>>,
}

/// `Default` trait implement for `UtreexoState`.
pub impl UtreexoStateDefault of Default<UtreexoState> {
    fn default() -> UtreexoState {
        UtreexoState { roots: array![Option::None].span() }
    }
}

/// `Display` trait implement for `UtreexoState`.
impl UtreexoStateDisplay of Display<UtreexoState> {
    fn fmt(self: @UtreexoState, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("UtreexoState {{ roots: {} }}", (*self.roots).len());
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[generate_trait]
pub impl UtreexoStateImpl of UtreexoStateTrait {
    /// Applies updates to the accumulator and returns the new state.
    fn validate_and_apply(
        self: @UtreexoState,
        hashes_to_add: Span<felt252>,
        hashes_to_delete: Span<felt252>,
        mut proofs: Span<UtreexoProof>,
    ) -> Result<UtreexoState, ByteArray> {
        let mut inner_result = Result::Ok(());
        let mut state = *self;

        for hash in hashes_to_delete {
            if let Option::Some(proof) = proofs.pop_front() {
                inner_result = self.verify(*hash, proof);
                if inner_result.is_err() {
                    break;
                }
                state = state.delete(proof);
            } else {
                inner_result = Result::Err(format!("Missing proof for leaf {}", hash));
                break;
            }
        }
        inner_result?;

        for hash in hashes_to_add {
            state = state.add(*hash);
        }

        Result::Ok(state)
    }
}
