//! Proof-of-work validation helpers.

use raito::utils::hash::{Hash, HashTrait};

/// Check if the work done (by calculating the block hash) satisfies the difficulty target.
pub fn validate_proof_of_work(target: u256, block_hash: Hash) -> Result<(), ByteArray> {
    let hash_to_reverse_order: Hash = HashTrait::reverse_bytes_order(block_hash);
    if hash_to_reverse_order.into() <= target {
        Result::Ok(())
    } else {
        Result::Err(
            "Insufficient proof of work. Expected block hash {chain_state.best_block_hash} to be less than or equal to {target}."
        )
    }
}

/// Compute total chain work based on the previous value and current difficulty target.
pub fn compute_total_work(current_total_work: u256, target: u256) -> u256 {
    current_total_work + compute_work_from_target(target)
}

// Need to compute 2**256 / (target+1), but we can't represent 2**256
// as it's too large for an u256. However, as 2**256 is at least as large
// as target+1, it is equal to ((2**256 - target - 1) / (target+1)) + 1,
// or ~target / (target+1) + 1.
fn compute_work_from_target(target: u256) -> u256 {
    (~target / (target + 1_u256)) + 1_u256
}

#[cfg(test)]
mod tests {
    use super::{validate_proof_of_work, compute_work_from_target};

    #[test]
    fn test_validate_proof_of_work() {
        // target is less than prev block hash
        let result = validate_proof_of_work(
            0, 0x0100000000000000000000000000000000000000000000000000000000000000_u256.into()
        );
        assert!(result.is_err(), "Expect target less than prev block hash");

        // target is greater than prev block hash
        let result = validate_proof_of_work(
            2, 0x0100000000000000000000000000000000000000000000000000000000000000_u256.into()
        );
        assert!(result.is_ok(), "Expect target gt prev block hash");

        // target is equal to prev block hash
        let result = validate_proof_of_work(
            1, 0x0100000000000000000000000000000000000000000000000000000000000000_u256.into()
        );
        assert!(result.is_ok(), "Expect target equal to prev block hash");

        // block prev block hash is greater than target
        let result = validate_proof_of_work(
            1, 0x0200000000000000000000000000000000000000000000000000000000000000_u256.into()
        );
        assert!(result.is_err(), "Expect prev block hash gt target");

        // block prev block hash is less than target
        let result = validate_proof_of_work(
            10, 0x0900000000000000000000000000000000000000000000000000000000000000_u256.into()
        );
        assert!(result.is_ok(), "Expect prev block hash lt target");
    }

    #[test]
    fn test_compute_work_from_target1() {
        let expected_work = 0x0100010001;
        let target: u256 = 0x00000000ffff0000000000000000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target2() {
        let expected_work = 0x26d946e509ac00026d;
        let target: u256 = 0x00000000000000000696f4000000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target3() {
        let expected_work = 0xe10005c64415f04ef3e387b97db388404db9fdfaab2b1918f6783471d;
        let target: u256 = 0x12345600;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target4() {
        let expected_work = 0x1c040c95a099201bcaf85db4e7f2e21e18707c8d55a887643b95afb2f;
        let target: u256 = 0x92340000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }

    #[test]
    fn test_compute_work_from_target5() {
        let expected_work = 0x21809b468faa88dbe34f;
        let target: u256 = 0x00000000000000000007a4290000000000000000000000000000000000000000;
        let work = compute_work_from_target(target);
        assert(expected_work == work, 'Failed to compute target');
    }
}
