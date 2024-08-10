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
                0x806c0d57_u32,
                0xe2f14d31_u32,
                0x11291846_u32,
                0xf237ab63_u32,
                0x05d90606_u32,
                0x822493fe_u32,
                0xa8345d57_u32,
                0x539da95a_u32
            ],
            array![
                0x1089e783_u32,
                0xa2b275e3_u32,
                0x68c9f7d0_u32,
                0x2ee18160_u32,
                0x4bd98a44_u32,
                0x18813fc8_u32,
                0x9caa7519_u32,
                0x0d946793_u32
            ],
            array![
                0x6f23a5e1_u32,
                0x667ed4a0_u32,
                0xabd07228_u32,
                0x8994b2ed_u32,
                0x593298b0_u32,
                0x6e97bb87_u32,
                0xacc698d0_u32,
                0xb369f9b5_u32
            ]
        ];

        let expected_merkle_root =
            0x1350862240c0eaf2fd0bf02e122fe16609d7c5c4f4538f45c0651fdb6ae82a22_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_04() {
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
                0x1192180b_u32,
                0x5a71150b_u32,
                0x35fcf96a_u32
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

    #[test]
    #[available_gas(100000000)]
    fn test_merkle_root_05() {
        let mut txids = array![
            // 0x d47e0335 1ee65f73 321b6848 32edc4c8 40a1fe4b bd04bdb6 6a8328e5 c7796e21
            array![
                0xd47e0335_u32,
                0x1ee65f73_u32,
                0x321b6848_u32,
                0x32edc4c8_u32,
                0x40a1fe4b_u32,
                0xbd04bdb6_u32,
                0x6a8328e5_u32,
                0xc7796e21_u32
            ],
            // 0x bf304002 ea77842b 32dc91f1 efe681a5 a7909f42 00e658e2 ef2beb2a 821101b9
            array![
                0xbf304002_u32,
                0xea77842b_u32,
                0x32dc91f1_u32,
                0xefe681a5_u32,
                0xa7909f42_u32,
                0x00e658e2_u32,
                0xef2beb2a_u32,
                0x821101b9_u32
            ],
            array![
                0x397bdf0b_u32,
                0xf5a8798f_u32,
                0x5b10bd95_u32,
                0xc70bb4a3_u32,
                0xf42ca14a_u32,
                0x9a837a4a_u32,
                0x54cd7de5_u32,
                0x25dc0225_u32
            ],
            array![
                0xd6ce1481_u32,
                0x17a1cd09_u32,
                0x4cdd5303_u32,
                0xae0896ca_u32,
                0xe1b29ad0_u32,
                0x10b6cb0f_u32,
                0x3d43fa99_u32,
                0xb5e2c2f7_u32
            ],
            array![
                0x7d5ad03e_u32,
                0xbf001acb_u32,
                0x47aafdf4_u32,
                0x915e86b7_u32,
                0x368ed318_u32,
                0x3c1e95f4_u32,
                0x7280d81b_u32,
                0xb4ef91f8_u32,
            ],
            array![
                0x69cf63b2_u32,
                0x66ebc862_u32,
                0xbd4d1a01_u32,
                0x473703c1_u32,
                0x4bdd3a62_u32,
                0x0f93ec32_u32,
                0x3144c7d2_u32,
                0xc54529a0_u32
            ],
            array![
                0x155be8f9_u32,
                0x59b0187d_u32,
                0x7528a1ff_u32,
                0x11b34506_u32,
                0x90047aa9_u32,
                0x6dbbb29a_u32,
                0x1ae3832b_u32,
                0x237c8179_u32
            ],
            array![
                0x727d5fbe_u32,
                0xd290d645_u32,
                0xced8776c_u32,
                0x9031d7c3_u32,
                0x438454b5_u32,
                0xfaf1f5dc_u32,
                0x0200dbe8_u32,
                0x4f8e6035_u32
            ],
            array![
                0xc6056c60_u32,
                0x21081150_u32,
                0xa86c092f_u32,
                0x6785955f_u32,
                0x757024f4_u32,
                0x1472ad4b_u32,
                0x0cfd9dd3_u32,
                0x9db8b4a2_u32
            ],
            array![
                0x83f26f37_u32,
                0xbb715ec3_u32,
                0x25f25544_u32,
                0xb6d7ae92_u32,
                0x0fcc073c_u32,
                0x146c8dd1_u32,
                0x2fbbde31_u32,
                0xa7ae1d2f_u32
            ],
            array![
                0xd39bc02e_u32,
                0xf2b2c5af_u32,
                0xdb7807b0_u32,
                0x162b5736_u32,
                0x48d9264d_u32,
                0x5e9872db_u32,
                0xf26a7d48_u32,
                0x0de301cd_u32
            ],
            array![
                0x3dc087cb_u32,
                0x9e9d66c4_u32,
                0xd3e2cf29_u32,
                0xd23949e7_u32,
                0xb914db4c_u32,
                0x3f2114d3_u32,
                0x4f34e97a_u32,
                0x2a44a169_u32
            ],
            array![
                0x497d1b0b_u32,
                0xf7b0c502_u32,
                0x043fe720_u32,
                0x1a9696c4_u32,
                0x66f514de_u32,
                0x3190097e_u32,
                0xf3b7d066_u32,
                0x4fc3d0bf_u32
            ],
            array![
                0xa43dbef6_u32,
                0x75b637c5_u32,
                0x54987e8a_u32,
                0x1b98be3f_u32,
                0xaf8850f8_u32,
                0x8fa1bdf5_u32,
                0x9b124c23_u32,
                0x56135a33_u32
            ],
            array![
                0x4f9cf2c3_u32,
                0x86b34b01_u32,
                0xd48a01ea_u32,
                0x31b5c795_u32,
                0xd1e869b4_u32,
                0x2de78410_u32,
                0xb3ea1adf_u32,
                0x658f62a2_u32
            ],
            array![
                0x46ef4071_u32,
                0xd3ddfd94_u32,
                0x43361ef2_u32,
                0xf4b2d5da_u32,
                0x7c57eaf5_u32,
                0x97855647_u32,
                0x82d0d9b9_u32,
                0x5280cb9b_u32
            ],
            array![
                0xa48c60d6_u32,
                0xb27fd5c6_u32,
                0x62d7dcd2_u32,
                0x48b52847_u32,
                0x4fd2598d_u32,
                0x26d51525_u32,
                0xdeea3d22_u32,
                0x5d7260e0_u32
            ],
            array![
                0x5bb6e103_u32,
                0x78329bf6_u32,
                0xe78ce3e0_u32,
                0xf3abae1f_u32,
                0xb1c4bc40_u32,
                0xe1ce1b0e_u32,
                0x1a5f5db8_u32,
                0xa7fb1897_u32
            ]
        ];

        let expected_merkle_root =
            0xe1455aa624aa92fa8b52766199033d66e4d100b39029e69906ae594397d977af_u256;

        assert_eq!(merkle_root(ref txids), expected_merkle_root);
    }
}

