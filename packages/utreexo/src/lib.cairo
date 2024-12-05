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

use core::poseidon::hades_permutation;

/// Parent hash of two Utreexo nodes.
#[inline]
fn parent_hash(left: felt252, right: felt252) -> felt252 {
    let (res, _, _) = hades_permutation(left, right, 2);
    return res;
}
