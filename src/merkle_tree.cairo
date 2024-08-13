use super::utils::{double_sha256, Hash};

pub fn merkle_root(ref hashes: Array<Hash>) -> Hash {
    let len = hashes.len();

    if len == 1 {
        return *hashes[0];
    }

    if len % 2 == 1 {
        hashes.append(*hashes[len - 1]);
    } else {
        // CVE-2012-2459 bug fix
        assert!(*hashes[len - 1] != *hashes[len - 2], "unexpected node duplication in merkle tree");
    }

    let mut next_hashes: Array<Hash> = array![];
    let mut i = 0;
    while i < len {
        next_hashes.append(double_sha256(hashes[i], hashes[i + 1]));
        i += 2;
    };

    merkle_root(ref next_hashes)
}

#[cfg(test)]
mod tests {
    use super::{merkle_root};
    use super::super::utils::{Hash, HashTrait, U256IntoHash};

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_01() {
        let mut txids: Array<Hash> = array![
            0xacd9825be8bece7782ec746a80b52f44d6a8af41c63dbab59b03e29558469682_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0xacd9825be8bece7782ec746a80b52f44d6a8af41c63dbab59b03e29558469682_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_02() {
        let mut txids: Array<Hash> = array![
            0x8710b2819a369672a2bce3d5270e7ae0ea59be2f7ce7f9078341b389098953e0_u256.into(),
            0x64efde3a3f3531569cdab031bb31cfeb5c2d8cba62ae1ca5b2913b4ef643fd49_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0x20dadaf81170decafec4b025366b75284dbe31dd42c8da5d25ff62fc4bff5d03_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_03() {
        let mut txids: Array<Hash> = array![
            0x806c0d57e2f14d3111291846f237ab6305d90606822493fea8345d57539da95a_u256.into(),
            0x1089e783a2b275e368c9f7d02ee181604bd98a4418813fc89caa75190d946793_u256.into(),
            0x6f23a5e1667ed4a0abd072288994b2ed593298b06e97bb87acc698d0b369f9b5_u256.into()
        ];

        let expected_merkle_root: Hash =
            0x1350862240c0eaf2fd0bf02e122fe16609d7c5c4f4538f45c0651fdb6ae82a22_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_04() {
        let mut txids = array![
            0xe914f16685930f0430a6fa687b4b17f98f988fe83f0ee26dc162b4cd3f6ea432_u256.into(),
            0x7dd21e3798f3ac7016203db204b0436b8dfb23051192180b5a71150b35fcf96a_u256.into(),
            0x65d02549bb947d23341b39516b4684e8e30f8eca5ba71d7a574d8c57bc8ecf4b_u256.into(),
            0x3d455f551097838265bc64109907b97b6b8a60aae04aed39969047b4ad8a2993_u256.into()
        ];

        let expected_merkle_root =
            0x5545be569eb578bb9498bbc114867edb6259c894370e14f5361988fe07d48b96_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_05() {
        let mut txids = array![
            0xd47e03351ee65f73321b684832edc4c840a1fe4bbd04bdb66a8328e5c7796e21_u256.into(),
            0xbf304002ea77842b32dc91f1efe681a5a7909f4200e658e2ef2beb2a821101b9_u256.into(),
            0x397bdf0bf5a8798f5b10bd95c70bb4a3f42ca14a9a837a4a54cd7de525dc0225_u256.into(),
            0xd6ce148117a1cd094cdd5303ae0896cae1b29ad010b6cb0f3d43fa99b5e2c2f7_u256.into(),
            0x7d5ad03ebf001acb47aafdf4915e86b7368ed3183c1e95f47280d81bb4ef91f8_u256.into(),
            0x69cf63b266ebc862bd4d1a01473703c14bdd3a620f93ec323144c7d2c54529a0_u256.into(),
            0x155be8f959b0187d7528a1ff11b3450690047aa96dbbb29a1ae3832b237c8179_u256.into(),
            0x727d5fbed290d645ced8776c9031d7c3438454b5faf1f5dc0200dbe84f8e6035_u256.into(),
            0xc6056c6021081150a86c092f6785955f757024f41472ad4b0cfd9dd39db8b4a2_u256.into(),
            0x83f26f37bb715ec325f25544b6d7ae920fcc073c146c8dd12fbbde31a7ae1d2f_u256.into(),
            0xd39bc02ef2b2c5afdb7807b0162b573648d9264d5e9872dbf26a7d480de301cd_u256.into(),
            0x3dc087cb9e9d66c4d3e2cf29d23949e7b914db4c3f2114d34f34e97a2a44a169_u256.into(),
            0x497d1b0bf7b0c502043fe7201a9696c466f514de3190097ef3b7d0664fc3d0bf_u256.into(),
            0xa43dbef675b637c554987e8a1b98be3faf8850f88fa1bdf59b124c2356135a33_u256.into(),
            0x4f9cf2c386b34b01d48a01ea31b5c795d1e869b42de78410b3ea1adf658f62a2_u256.into(),
            0x46ef4071d3ddfd9443361ef2f4b2d5da7c57eaf59785564782d0d9b95280cb9b_u256.into(),
            0xa48c60d6b27fd5c662d7dcd248b528474fd2598d26d51525deea3d225d7260e0_u256.into(),
            0x5bb6e10378329bf6e78ce3e0f3abae1fb1c4bc40e1ce1b0e1a5f5db8a7fb1897_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0xe1455aa624aa92fa8b52766199033d66e4d100b39029e69906ae594397d977af_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_05_bis() {
        let mut txids = array![
            HashTrait::to_hash(
                [
                    0xd47e0335,
                    0x1ee65f73,
                    0x321b6848,
                    0x32edc4c8,
                    0x40a1fe4b,
                    0xbd04bdb6,
                    0x6a8328e5,
                    0xc7796e21
                ]
            ),
            HashTrait::to_hash(
                [
                    0xbf304002,
                    0xea77842b,
                    0x32dc91f1,
                    0xefe681a5,
                    0xa7909f42,
                    0x00e658e2,
                    0xef2beb2a,
                    0x821101b9
                ]
            ),
            HashTrait::to_hash(
                [
                    0x397bdf0b,
                    0xf5a8798f,
                    0x5b10bd95,
                    0xc70bb4a3,
                    0xf42ca14a,
                    0x9a837a4a,
                    0x54cd7de5,
                    0x25dc0225
                ]
            ),
            HashTrait::to_hash(
                [
                    0xd6ce1481,
                    0x17a1cd09,
                    0x4cdd5303,
                    0xae0896ca,
                    0xe1b29ad0,
                    0x10b6cb0f,
                    0x3d43fa99,
                    0xb5e2c2f7
                ]
            ),
            HashTrait::to_hash(
                [
                    0x7d5ad03e,
                    0xbf001acb,
                    0x47aafdf4,
                    0x915e86b7,
                    0x368ed318,
                    0x3c1e95f4,
                    0x7280d81b,
                    0xb4ef91f8
                ]
            ),
            HashTrait::to_hash(
                [
                    0x69cf63b2,
                    0x66ebc862,
                    0xbd4d1a01,
                    0x473703c1,
                    0x4bdd3a62,
                    0x0f93ec32,
                    0x3144c7d2,
                    0xc54529a0
                ]
            ),
            HashTrait::to_hash(
                [
                    0x155be8f9,
                    0x59b0187d,
                    0x7528a1ff,
                    0x11b34506,
                    0x90047aa9,
                    0x6dbbb29a,
                    0x1ae3832b,
                    0x237c8179
                ]
            ),
            HashTrait::to_hash(
                [
                    0x727d5fbe,
                    0xd290d645,
                    0xced8776c,
                    0x9031d7c3,
                    0x438454b5,
                    0xfaf1f5dc,
                    0x0200dbe8,
                    0x4f8e6035
                ]
            ),
            HashTrait::to_hash(
                [
                    0xc6056c60,
                    0x21081150,
                    0xa86c092f,
                    0x6785955f,
                    0x757024f4,
                    0x1472ad4b,
                    0x0cfd9dd3,
                    0x9db8b4a2
                ]
            ),
            HashTrait::to_hash(
                [
                    0x83f26f37,
                    0xbb715ec3,
                    0x25f25544,
                    0xb6d7ae92,
                    0x0fcc073c,
                    0x146c8dd1,
                    0x2fbbde31,
                    0xa7ae1d2f
                ]
            ),
            HashTrait::to_hash(
                [
                    0xd39bc02e,
                    0xf2b2c5af,
                    0xdb7807b0,
                    0x162b5736,
                    0x48d9264d,
                    0x5e9872db,
                    0xf26a7d48,
                    0x0de301cd
                ]
            ),
            HashTrait::to_hash(
                [
                    0x3dc087cb,
                    0x9e9d66c4,
                    0xd3e2cf29,
                    0xd23949e7,
                    0xb914db4c,
                    0x3f2114d3,
                    0x4f34e97a,
                    0x2a44a169
                ]
            ),
            HashTrait::to_hash(
                [
                    0x497d1b0b,
                    0xf7b0c502,
                    0x043fe720,
                    0x1a9696c4,
                    0x66f514de,
                    0x3190097e,
                    0xf3b7d066,
                    0x4fc3d0bf
                ]
            ),
            HashTrait::to_hash(
                [
                    0xa43dbef6,
                    0x75b637c5,
                    0x54987e8a,
                    0x1b98be3f,
                    0xaf8850f8,
                    0x8fa1bdf5,
                    0x9b124c23,
                    0x56135a33
                ]
            ),
            HashTrait::to_hash(
                [
                    0x4f9cf2c3,
                    0x86b34b01,
                    0xd48a01ea,
                    0x31b5c795,
                    0xd1e869b4,
                    0x2de78410,
                    0xb3ea1adf,
                    0x658f62a2
                ]
            ),
            HashTrait::to_hash(
                [
                    0x46ef4071,
                    0xd3ddfd94,
                    0x43361ef2,
                    0xf4b2d5da,
                    0x7c57eaf5,
                    0x97855647,
                    0x82d0d9b9,
                    0x5280cb9b
                ]
            ),
            HashTrait::to_hash(
                [
                    0xa48c60d6,
                    0xb27fd5c6,
                    0x62d7dcd2,
                    0x48b52847,
                    0x4fd2598d,
                    0x26d51525,
                    0xdeea3d22,
                    0x5d7260e0
                ]
            ),
            HashTrait::to_hash(
                [
                    0x5bb6e103,
                    0x78329bf6,
                    0xe78ce3e0,
                    0xf3abae1f,
                    0xb1c4bc40,
                    0xe1ce1b0e,
                    0x1a5f5db8,
                    0xa7fb1897
                ]
            ),
        ];

        let expected_merkle_root: Hash =
            0xe1455aa624aa92fa8b52766199033d66e4d100b39029e69906ae594397d977af_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(1000000000)]
    fn test_big_merkle_root() {
        let mut txids = array![
            0xd3ce909f176b756d6136e1e96cd5fb592f9bc6af165fd21029defe6f40cc6e49_u256.into(),
            0x0872460c56d5d1f00eb040c4aaeb9daa69e7e9d608dc422e7380cfaf421904a9_u256.into(),
            0x36da737a76e97a4e327405838195ab11698dd37a6466c006cfcdad0c210f3e2c_u256.into(),
            0xa579440f07d1dca8e8b51af6a0f40f2db38aa835cc6e190551d84db33d5677e2_u256.into(),
            0xe4dd9f9f9ae242796706f8016e67e1ca626d7708813f80f3b875a392ae993b65_u256.into(),
            0x0603c5c111f9037ee0d7a741a9d4a956f007a33ae470d5ab71f96f924a9491e0_u256.into(),
            0x8a2d4295765330d59f4528b6678966fb0820013e804cb4ea435471bb0fd37529_u256.into(),
            0xd18280eff3912ea56a369021fd2833806b7fd1e31744bf61231fd1e833787a38_u256.into(),
            0x06efc90c5f2f9c6705f77ac365d133164265f9c5bf2956c9662e6b84cac4e437_u256.into(),
            0x55a9db2b5686ae3245cc035c8ce291332fb6e679811da93d966241ea2adf64bc_u256.into(),
            0x54315dcaa54eca4bbfdf150fb9e7a7fcfdd41b304d2768befaf0284dcfa0224e_u256.into(),
            0x6121b2cc5156f0b11aee6a112878dcd528c809b69cea16a1fb24b782fefec761_u256.into(),
            0x8e66ed463fe4d8e1aafb4aa131a0af0a115884d89e1bde77b430b8efeb7fc076_u256.into(),
            0x19f7ec64e6fdcb22a60394b5080bdc399796640674d9b7aa87b987c93f00e806_u256.into(),
            0x4b7ccd1377c11ca2aba1649ed38a2a66f2c5c5a8053c520a681dd9cf72ccbc59_u256.into(),
            0xc7d0305340b7bb724a7239e7f1994762992c034007867d874ce0e8a33097b197_u256.into(),
            0x2c0142e40f1956aa955d98ef46cec42e1a75458be1a442a82d098006f875c0d8_u256.into(),
            0xbe621864dce65a9b9654d86f986de47912df0f57d33c2f91a91abbb933ab2819_u256.into(),
            0x4809f595d61905f7687d9810c29068dd59aa502e88b0c20bd9e5a80e7966dae2_u256.into(),
            0x99819d5a8efb57aade2e4c6f830e53f48ee595724b1a4bbdeaeceafb78f307e5_u256.into(),
            0xd76e41b26675149582b612a8a1187bf108922ee4115e008ac38703230abe4059_u256.into(),
            0xf961ef26e0b88f903d7ea0bf8f6a58b82b50463bd841646a3cabdf038553e4d1_u256.into(),
            0x536df55730e6d8bdbfaffe50c43cb1ad0a1c44a0667f883f8fd57e5844cf5b89_u256.into(),
            0xf3ab107f583f42f18948598717a10898c405377d18f77e99975eb15752457d5e_u256.into(),
            0xd03b1bd1abd123ef55f60ff150c168f88569ecf1098f4ef88b173652c7cb69dc_u256.into(),
            0x26f86461da9723736589d49d6296c6e192b105c56f9da6c0eb228a92e1405dbe_u256.into(),
            0xe63a1912b23bb6137dfcfc83f35c56a37ff52352816fc561a373321d657f85da_u256.into(),
            0x9ed6d853f74e93e13f6bf45e8aa8b98c4117c75e87ef37cb88317a2bc40ec903_u256.into(),
            0x6dfd409e44683c59912b3f2c6672db48346896cac938bb6f7889cdd39ba81411_u256.into(),
            0xdd3f7a41d60cf9923cb701a4ac876ee73829ed25e897bc83699504b469263997_u256.into(),
            0xf10097f6fdffdec54aa740d63bc8cfcb1e5540dd81584555e42945eab8ad733e_u256.into(),
            0x81f6450d463ae354bda14024575900d1cf3e75aadc03a44e4398f1a909b0f3f6_u256.into(),
            0x35a528cbd2f60e075753d27ac6a5e7bc21f91ad15469873225ce4453ee96ca45_u256.into(),
            0x5952df4983f6eacfc9a94953d28452192a79635107cf8bd85d00f56b0d974360_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0x2c458dc50ef600a409781f76922657995098e944ddf52fa3cd8e90b85c338ec7_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }
}
