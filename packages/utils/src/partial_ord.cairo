/// PartialOrd implementation for tuple (u32, felt252).
/// Required to sort leaf nodes in proof verification.
pub impl PartialOrdTupleU64Felt252 of PartialOrd<(u64, felt252)> {
    fn le(lhs: (u64, felt252), rhs: (u64, felt252)) -> bool {
        let (a, _) = lhs;
        let (b, _) = rhs;

        if a <= b {
            true
        } else {
            false
        }
    }

    fn ge(lhs: (u64, felt252), rhs: (u64, felt252)) -> bool {
        let (a, _) = lhs;
        let (b, _) = rhs;

        if a >= b {
            true
        } else {
            false
        }
    }

    fn lt(lhs: (u64, felt252), rhs: (u64, felt252)) -> bool {
        let (a, _) = lhs;
        let (b, _) = rhs;

        if a < b {
            true
        } else {
            false
        }
    }

    fn gt(lhs: (u64, felt252), rhs: (u64, felt252)) -> bool {
        let (a, _) = lhs;
        let (b, _) = rhs;

        if a > b {
            true
        } else {
            false
        }
    }
}
