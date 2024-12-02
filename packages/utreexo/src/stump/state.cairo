use core::fmt::{Display, Formatter, Error};

/// Accumulator representation of the state aka "Compact State Node".
#[derive(Drop, Copy, PartialEq, Serde, Debug)]
pub struct UtreexoStumpState {
    /// Roots of the Merkle tree forest.
    /// Index is the root height, None means a gap.
    pub roots: Span<Option<felt252>>,
    /// Total number of leaves (in the bottom-most row).
    /// Required to calculate the number of nodes in a particular row.
    /// Can be reconstructed from the roots, but cached for convenience.
    pub num_leaves: u64,
}

/// `Default` trait implementation for `UtreexoStumpState`.
pub impl UtreexoStumpStateDefault of Default<UtreexoStumpState> {
    fn default() -> UtreexoStumpState {
        UtreexoStumpState { roots: array![Option::None].span(), num_leaves: 0 }
    }
}

/// `Display` trait implementation for `UtreexoStumpState`.
impl UtreexoStumpStateDisplay of Display<UtreexoStumpState> {
    fn fmt(self: @UtreexoStumpState, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "UtreexoStumpState {{ roots: {}, num_leaves: {} }}",
            (*self.roots).len(),
            *self.num_leaves,
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}
