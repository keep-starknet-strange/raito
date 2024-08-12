use super::utils::{double_sha256};

pub fn merkle_root(ref txids: Array<u256>) -> u256 {
    let len = txids.len();

    if len == 1 {
        return *txids.at(0);
    }

    if len % 2 == 1 {
        txids.append(*txids.at(len - 1));
    } else {
        // CVE-2012-2459 bug fix
        assert!(
            txids.at(len - 1) != txids.at(len - 2), "unexpected node duplication in merkle tree"
        );
    }

    let mut next_txids = ArrayTrait::new();
    let mut i = 0;
    while i < len {
        next_txids.append(double_sha256(*txids.at(i), *txids.at(i + 1)));
        i += 2;
    };

    merkle_root(ref next_txids)
}

#[cfg(test)]
mod tests {
    use super::{merkle_root};

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_01() {
        let mut txids = array![
            0xacd9825be8bece7782ec746a80b52f44d6a8af41c63dbab59b03e29558469682_u256,
        ];

        let expected_merkle_root =
            0xacd9825be8bece7782ec746a80b52f44d6a8af41c63dbab59b03e29558469682_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_02() {
        let mut txids = array![
            0x8710b2819a369672a2bce3d5270e7ae0ea59be2f7ce7f9078341b389098953e0_u256,
            0x64efde3a3f3531569cdab031bb31cfeb5c2d8cba62ae1ca5b2913b4ef643fd49_u256
        ];

        let expected_merkle_root =
            0x20dadaf81170decafec4b025366b75284dbe31dd42c8da5d25ff62fc4bff5d03_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_03() {
        let mut txids = array![
            0xd47e03351ee65f73321b684832edc4c840a1fe4bbd04bdb66a8328e5c7796e21_u256,
            0xbf304002ea77842b32dc91f1efe681a5a7909f4200e658e2ef2beb2a821101b9_u256,
            0x397bdf0bf5a8798f5b10bd95c70bb4a3f42ca14a9a837a4a54cd7de525dc0225_u256,
            0xd6ce148117a1cd094cdd5303ae0896cae1b29ad010b6cb0f3d43fa99b5e2c2f7_u256,
            0x7d5ad03ebf001acb47aafdf4915e86b7368ed3183c1e95f47280d81bb4ef91f8_u256,
            0x69cf63b266ebc862bd4d1a01473703c14bdd3a620f93ec323144c7d2c54529a0_u256,
            0x155be8f959b0187d7528a1ff11b3450690047aa96dbbb29a1ae3832b237c8179_u256,
            0x727d5fbed290d645ced8776c9031d7c3438454b5faf1f5dc0200dbe84f8e6035_u256,
            0xc6056c6021081150a86c092f6785955f757024f41472ad4b0cfd9dd39db8b4a2_u256,
            0x83f26f37bb715ec325f25544b6d7ae920fcc073c146c8dd12fbbde31a7ae1d2f_u256,
            0xd39bc02ef2b2c5afdb7807b0162b573648d9264d5e9872dbf26a7d480de301cd_u256,
            0x3dc087cb9e9d66c4d3e2cf29d23949e7b914db4c3f2114d34f34e97a2a44a169_u256,
            0x497d1b0bf7b0c502043fe7201a9696c466f514de3190097ef3b7d0664fc3d0bf_u256,
            0xa43dbef675b637c554987e8a1b98be3faf8850f88fa1bdf59b124c2356135a33_u256,
            0x4f9cf2c386b34b01d48a01ea31b5c795d1e869b42de78410b3ea1adf658f62a2_u256,
            0x46ef4071d3ddfd9443361ef2f4b2d5da7c57eaf59785564782d0d9b95280cb9b_u256,
            0xa48c60d6b27fd5c662d7dcd248b528474fd2598d26d51525deea3d225d7260e0_u256,
            0x5bb6e10378329bf6e78ce3e0f3abae1fb1c4bc40e1ce1b0e1a5f5db8a7fb1897_u256
        ];

        let expected_merkle_root =
            0xe1455aa624aa92fa8b52766199033d66e4d100b39029e69906ae594397d977af_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }
}

