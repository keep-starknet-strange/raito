//! Merkle tree helpers.

use super::{sha256::double_sha256_parent, hash::Hash};

/// Calculate Merkle tree root given the array of leaves.
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
        next_hashes.append(double_sha256_parent(hashes[i], hashes[i + 1]));
        i += 2;
    };

    merkle_root(ref next_hashes)
}

#[cfg(test)]
mod tests {
    use super::{merkle_root};
    use raito::utils::hash::{Hash, HashTrait, U256IntoHash};

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
    fn test_merkle_root_block170() {
        let mut txids: Array<Hash> = array![
            0xb1fea52486ce0c62bb442b530a3f0132b826c74e473d1f2c220bfa78111c5082_u256.into(),
            0xf4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0x7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_02() {
        let mut txids: Array<Hash> = array![
            0xe053890989b3418307f9e77c2fbe59eae07a0e27d5e3bca27296369a81b21087_u256.into(),
            0x49fd43f64e3b91b2a51cae62ba8c2d5cebcf31bb31b0da9c5631353f3adeef64_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0x035dff4bfc62ff255ddac842dd31be4d28756b3625b0c4fecade7011f8dada20_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_03() {
        let mut txids: Array<Hash> = array![
            0x5aa99d53575d34a8fe9324820606d90563ab37f246182911314df1e2570d6c80_u256.into(),
            0x9367940d1975aa9cc83f8118448ad94b6081e12ed0f7c968e375b2a283e78910_u256.into(),
            0xb5f969b3d098c6ac87bb976eb0983259edb294892872d0aba0d47e66e1a5236f_u256.into()
        ];

        let expected_merkle_root: Hash =
            0x222ae86adb1f65c0458f53f4c4c5d70966e12f122ef00bfdf2eac04022865013_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_04() {
        let mut txids = array![
            0x32a46e3fcdb462c16de20e3fe88f988ff9174b7b68faa630040f938566f114e9_u256.into(),
            0x6af9fc350b15715a0b1892110523fb8d6b43b004b23d201670acf398371ed27d_u256.into(),
            0x4bcf8ebc578c4d577a1da75bca8e0fe3e884466b51391b34237d94bb4925d065_u256.into(),
            0x93298aadb447909639ed4ae0aa608a6b7bb907991064bc6582839710555f453d_u256.into()
        ];

        let expected_merkle_root =
            0x968bd407fe881936f5140e3794c85962db7e8614c1bb9894bb78b59e56be4555_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_05() {
        let mut txids = array![
            0x216e79c7e528836ab6bd04bd4bfea140c8c4ed3248681b32735fe61e35037ed4_u256.into(),
            0xb90111822aeb2befe258e600429f90a7a581e6eff191dc322b8477ea024030bf_u256.into(),
            0x2502dc25e57dcd544a7a839a4aa12cf4a3b40bc795bd105b8f79a8f50bdf7b39_u256.into(),
            0xf7c2e2b599fa433d0fcbb610d09ab2e1ca9608ae0353dd4c09cda1178114ced6_u256.into(),
            0xf891efb41bd88072f4951e3c18d38e36b7865e91f4fdaa47cb1a00bf3ed05a7d_u256.into(),
            0xa02945c5d2c7443132ec930f623add4bc1033747011a4dbd62c8eb66b263cf69_u256.into(),
            0x79817c232b83e31a9ab2bb6da97a04900645b311ffa128757d18b059f9e85b15_u256.into(),
            0x35608e4fe8db0002dcf5f1fab5548443c3d731906c77d8ce45d690d2be5f7d72_u256.into(),
            0xa2b4b89dd39dfd0c4bad7214f42470755f9585672f096ca850110821606c05c6_u256.into(),
            0x2f1daea731debb2fd18d6c143c07cc0f92aed7b64455f225c35e71bb376ff283_u256.into(),
            0xcd01e30d487d6af2db72985e4d26d94836572b16b00778dbafc5b2f22ec09bd3_u256.into(),
            0x69a1442a7ae9344fd314213f4cdb14b9e74939d229cfe2d3c4669d9ecb87c03d_u256.into(),
            0xbfd0c34f66d0b7f37e099031de14f566c496961a20e73f0402c5b0f70b1b7d49_u256.into(),
            0x335a1356234c129bf5bda18ff85088af3fbe981b8a7e9854c537b675f6be3da4_u256.into(),
            0xa2628f65df1aeab31084e72db469e8d195c7b531ea018ad4014bb386c3f29c4f_u256.into(),
            0x9bcb8052b9d9d08247568597f5ea577cdad5b2f4f21e364394fdddd37140ef46_u256.into(),
            0xe060725d223deade2515d5268d59d24f4728b548d2dcd762c6d57fb2d6608ca4_u256.into(),
            0x9718fba7b85d5f1a0e1bcee140bcc4b11faeabf3e0e38ce7f69b327803e1b65b_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0xaf77d9974359ae0699e62990b300d1e4663d03996176528bfa92aa24a65a45e1_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(1000000000)]
    fn test_big_merkle_root() {
        let mut txids = array![
            0x496ecc406ffede2910d25f16afc69b2f59fbd56ce9e136616d756b179f90ced3_u256.into(),
            0xa9041942afcf80732e42dc08d6e9e769aa9debaac440b00ef0d1d5560c467208_u256.into(),
            0x2c3e0f210cadcdcf06c066647ad38d6911ab9581830574324e7ae9767a73da36_u256.into(),
            0xe277563db34dd85105196ecc35a88ab32d0ff4a0f61ab5e8a8dcd1070f4479a5_u256.into(),
            0x653b99ae92a375b8f3803f8108776d62cae1676e01f806677942e29a9f9fdde4_u256.into(),
            0xe091944a926ff971abd570e43aa307f056a9d4a941a7d7e07e03f911c1c50306_u256.into(),
            0x2975d30fbb715443eab44c803e012008fb668967b628459fd530537695422d8a_u256.into(),
            0x387a7833e8d11f2361bf4417e3d17f6b803328fd2190366aa52e91f3ef8082d1_u256.into(),
            0x37e4c4ca846b2e66c95629bfc5f965421633d165c37af705679c2f5f0cc9ef06_u256.into(),
            0xbc64df2aea4162963da91d8179e6b62f3391e28c5c03cc4532ae86562bdba955_u256.into(),
            0x4e22a0cf4d28f0fabe68274d301bd4fdfca7e7b90f15dfbf4bca4ea5ca5d3154_u256.into(),
            0x61c7fefe82b724fba116ea9cb609c828d5dc7828116aee1ab1f05651ccb22161_u256.into(),
            0x76c07febefb830b477de1b9ed88458110aafa031a14afbaae1d8e43f46ed668e_u256.into(),
            0x06e8003fc987b987aab7d9740664969739dc0b08b59403a622cbfde664ecf719_u256.into(),
            0x59bccc72cfd91d680a523c05a8c5c5f2662a8ad39e64a1aba21cc17713cd7c4b_u256.into(),
            0x97b19730a3e8e04c877d860740032c99624799f1e739724a72bbb7405330d0c7_u256.into(),
            0xd8c075f80680092da842a4e18b45751a2ec4ce46ef985d95aa56190fe442012c_u256.into(),
            0x1928ab33b9bb1aa9912f3cd3570fdf1279e46d986fd854969b5ae6dc641862be_u256.into(),
            0xe2da66790ea8e5d90bc2b0882e50aa59dd6890c210987d68f70519d695f50948_u256.into(),
            0xe507f378fbeaeceabd4b1a4b7295e58ef4530e836f4c2edeaa57fb8e5a9d8199_u256.into(),
            0x5940be0a230387c38a005e11e42e9208f17b18a1a812b68295147566b2416ed7_u256.into(),
            0xd1e4538503dfab3c6a6441d83b46502bb8586a8fbfa07e3d908fb8e026ef61f9_u256.into(),
            0x895bcf44587ed58f3f887f66a0441c0aadb13cc450feafbfbdd8e63057f56d53_u256.into(),
            0x5e7d455257b15e97997ef7187d3705c49808a11787594889f1423f587f10abf3_u256.into(),
            0xdc69cbc75236178bf84e8f09f1ec6985f868c150f10ff655ef23d1abd11b3bd0_u256.into(),
            0xbe5d40e1928a22ebc0a69d6fc505b192e1c696629dd48965732397da6164f826_u256.into(),
            0xda857f651d3273a361c56f815223f57fa3565cf383fcfc7d13b63bb212193ae6_u256.into(),
            0x03c90ec42b7a3188cb37ef875ec717418cb9a88a5ef46b3fe1934ef753d8d69e_u256.into(),
            0x1114a89bd3cd89786fbb38c9ca96683448db72662c3f2b91593c68449e40fd6d_u256.into(),
            0x97392669b404956983bc97e825ed2938e76e87aca401b73c92f90cd6417a3fdd_u256.into(),
            0x3e73adb8ea4529e455455881dd40551ecbcfc83bd640a74ac5defffdf69700f1_u256.into(),
            0xf6f3b009a9f198434ea403dcaa753ecfd10059572440a1bd54e33a460d45f681_u256.into(),
            0x45ca96ee5344ce2532876954d11af921bce7a5c67ad25357070ef6d2cb28a535_u256.into(),
            0x6043970d6bf5005dd88bcf075163792a195284d25349a9c9cfeaf68349df5259_u256.into(),
        ];

        let expected_merkle_root: Hash =
            0xc78e335cb8908ecda32ff5dd44e9985099572692761f7809a400f60ec58d452c_u256
            .into();

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }
}
