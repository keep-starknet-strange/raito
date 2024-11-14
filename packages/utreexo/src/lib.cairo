pub mod stump {
    pub mod accumulator;
    pub mod proof;
    pub mod state;
    #[cfg(test)]
    mod accumulator_tests;
}
pub mod vanilla {
    pub mod accumulator;
    pub mod proof;
    pub mod state;
    #[cfg(test)]
    mod accumulator_tests;
}
pub mod test;

use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;

/// Parent hash of two Utreexo nodes.
fn parent_hash(left: felt252, right: felt252) -> felt252 {
    return PoseidonTrait::new().update_with(left).update_with(right).finalize();
}
