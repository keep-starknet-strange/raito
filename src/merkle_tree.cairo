use super::utils::{shl, double_sha256};

pub fn merkle_root(ref txids: Array<Array<u32>>) -> u256 {
    let len: u32 = txids.len();

    if len == 1 {
        let txid: @Array<u32> = txids[0];
        let mut root: u256 = 0;
        let mut i: u32 = 0;
        while i != 8 {
            let element: u256 = (*txid[i]).into();
            root += shl(element, (32 * (7 - i)));

            i += 1;
        };

        return root;
    }

    if len % 2 == 1 {
        let last_leaf: @Array<u32> = txids[len - 1];
        txids.append(last_leaf.clone());
    } else {
        // CVE-2012-2459 bug fix
        assert!(
            txids.at(len - 1) != txids.at(len - 2), "unexpected node duplication in merkle tree"
        );
    }

    let mut next_txids: Array<Array<u32>> = array![];
    let mut i = 0;
    while i < len {
        next_txids.append(double_sha256((txids[i]), txids[i + 1]));
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
            array![
                0xacd9825b_u32,
                0xe8bece77_u32,
                0x82ec746a_u32,
                0x80b52f44_u32,
                0xd6a8af41_u32,
                0xc63dbab5_u32,
                0x9b03e295_u32,
                0x58469682_u32
            ]
        ];

        let expected_merkle_root =
            0xacd9825be8bece7782ec746a80b52f44d6a8af41c63dbab59b03e29558469682_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_02() {
        let mut txids = array![
            array![
                0x8710b281_u32,
                0x9a369672_u32,
                0xa2bce3d5_u32,
                0x270e7ae0_u32,
                0xea59be2f_u32,
                0x7ce7f907_u32,
                0x8341b389_u32,
                0x098953e0_u32
            ],
            array![
                0x64efde3a_u32,
                0x3f353156_u32,
                0x9cdab031_u32,
                0xbb31cfeb_u32,
                0x5c2d8cba_u32,
                0x62ae1ca5_u32,
                0xb2913b4e_u32,
                0xf643fd49_u32
            ]
        ];

        let expected_merkle_root =
            0x20dadaf81170decafec4b025366b75284dbe31dd42c8da5d25ff62fc4bff5d03_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_03() {
        let mut txids = array![
            array![
                0xe914f166_u32,
                0x85930f04_u32,
                0x30a6fa68_u32,
                0x7b4b17f9_u32,
                0x8f988fe8_u32,
                0x3f0ee26d_u32,
                0xc162b4cd_u32,
                0x3f6ea432_u32
            ],
            array![
                0x7dd21e37_u32,
                0x98f3ac70_u32,
                0x16203db2_u32,
                0x04b0436b_u32,
                0x8dfb2305_u32,
                0x11921921_u32,
                0x80b5a711_u32,
                0x50b35fcf_u32
            ],
            array![
                0x65d02549_u32,
                0xbb947d23_u32,
                0x341b3951_u32,
                0x6b4684e8_u32,
                0xe30f8eca_u32,
                0x5ba71d7a_u32,
                0x574d8c57_u32,
                0xbc8ecf4b_u32
            ],
            array![
                0x3d455f55_u32,
                0x10978382_u32,
                0x65bc6410_u32,
                0x9907b97b_u32,
                0x6b8a60aa_u32,
                0xe04aed39_u32,
                0x969047b4_u32,
                0xad8a2993_u32
            ]
        ];

        let expected_merkle_root =
            0x5545be569eb578bb9498bbc114867edb6259c894370e14f5361988fe07d48b96_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }
    // #[test]
// #[available_gas(100000000)]
// fn test_merkle_root_04() {
//     let mut txids = array![
//         array![
//             0xf50b7435_u32,
//             0x9467dd8a_u32,
//             0x3a4309b2_u32,
//             0x09fb270b_u32,
//             0x9fdd63ef_u32,
//             0x638118bc_u32,
//             0x42fe1d92_u32,
//             0xca54c74e_u32
//         ],
//         array![
//             0x7883ed76_u32,
//             0x1b66a6fe_u32,
//             0x0b1810a2_u32,
//             0x0b4b3cbb_u32,
//             0xca333356_u32,
//             0x8728d072_u32,
//             0x661bc45e_u32,
//             0x4e82112e_u32
//         ],
//         array![
//             0x529a1d89_u32,
//             0xbc7330a6_u32,
//             0xd9386c7b_u32,
//             0x59801d35_u32,
//             0xaba46d88_u32,
//             0x3333f974_u32,
//             0xc2fe85b8_u32,
//             0x91bc1a9e_u32
//         ]
//     ];

    //     let expected_merkle_root =
//         0x69a17a9beb8a590fd92382d9f471dc1fdc15f2f3c410678156f08d202fd41c4d_u256;

    //     assert_eq!(merkle_root(ref txids), expected_merkle_root);
// }
}

