pub mod vanilla {
    pub mod state;
    pub mod proof;
    pub mod accumulator;
    #[cfg(test)]
    mod accumulator_tests;
}
pub mod stump {
    pub mod state;
    pub mod proof;
    pub mod accumulator;
    #[cfg(test)]
    mod accumulator_tests;
}
pub mod test;

use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

/// Parent hash of two Utreexo nodes
fn parent_hash(left: felt252, right: felt252) -> felt252 {
    return PoseidonTrait::new().update_with(left).update_with(right).finalize();
}
