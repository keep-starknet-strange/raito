use raito::state::{Block, Header, Transaction, TxIn, TxOut, OutPoint};
use raito::test_utils::from_hex;
use raito::utils::Hash;

// block_hash: 000000000000188cc1d8c256e867dc0a65d778896485559e9ed80879e51d894d
pub fn block_100017() -> Block {
    Block {
        header: Header {
                version: 1_u32,
                time: 1293630246_u32,
                bits: 453281356_u32,
                nonce: 1455412408_u32,
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                    TxIn {
                        script: @from_hex("044c86041b0140"),
                        sequence: 4294967295,
                        witness: @from_hex("0"),
                        previous_output: OutPoint {
                            txid: 0_u256.into(),
                            vout: 0xffffffff_u32,
                            txo_index: 0,
                            amount: 0_u64,
                        },
                    }].span(),
                outputs: array![
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("41045951453d9001c58cdee32785f708a5349bbee5fd59f78c9e9e0b77a67b6eda2b2dbc7b0cee0be690d8a5e0804f8324b9eb572bcc6d000954463a29a941bc1b39ac"),
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("493046022100e5a677278760a3f3fc6eadc6ee61666e2c213f50a85f450f259d1de5b03268cf022100d95c63f960bdb022989fb8cb5d5204c4a651c83f33fd51ced2f34b853c0326cc01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xcc440e2e7dab0b54bd1c482177ddd1e64aba7d95cbcb43ef54f71ee8689be646_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("473044022057f3e5c880a679d7a6869213da8db6364f7a369812a9f4df4b5b9b20880849bb022062dc367d064629f851a7953bec1d76ef1c7389fba3e62be8487a85c552beee8a01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x70a44167d2a28ceaeaaeb688d2dee78b3247c9daa6bd6d984ad43ded7915652c_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100a3231e9f9a21b532b45b4fb19c3f16585501b5b7389e2d1b35541dfa250d57d4022100df641c089581771422234345da96345ae22635106769591c3ad8a729d61b4b4901410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x470e7fd59fc81b6476528581418ae85a38738afb325ee5d1eecfd02d36f16c57_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 15000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4730440220430c315908011267c286934489018b307fabfe50905038e726c405b89f36c48b02204512b25a358264b61b27c1a1d31d309f84c1dff332dad7a8ad6d50bd98eb1f7f01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x303277a1577ddc6e7a2159c0432a3ff9bd477766432890e62deb2538096f6e5a_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("483045022078f040e10ca3931bc990171c7536d69ddf3c975d12406e3ba9aaf62b03e7fa310221009ec0b3686b1620bcdb8e8124c497fdd867ec8f0f64bb99bbf10c8462e7af9b9701410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xf6b17bc6a03c058d4cf7315900770911ebaac998a0a171ced32872eaad910e5f_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100a3f843e66f7346c8ad257d22d66b2ab215582030ecf8200e24da5112efb8eb05022100facd0c2c9ce4df471da916d0d7f952898b02436f2e19af25e453c8dcfa17277901410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x130b424a35ccf3ea2cfcedd1ccec26695e26303fecfb470c88062a3f2cc44e6e_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("483045022100a4afc308a63aed18f96d31306c3c2ea5317282d71eb9d6b4e916cffc1f5fec5802201f2fac741a101b1dbd3210fc8757839c4c23b17e917a90158748eb4e3aa3f49a01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x85f44f6ae5a4250b94bd6e18d68cdf310b443c918949b5de2904ed6acf7f927a_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4930460221009f08ba05c0732e70d206b5d9c10dc0180dead4d56898c2f9f0a54a4d047814c9022100b66bef157182fe5d8091733a2d52fe1c4f94d820b2969aeacb5edb4691df60c301410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xd3e1142ae61392136bc5c14b5e9af2ff2899c1fa142a7613dee77a3c7514c08d_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("47304402203e8fc5eb3e4af5e71d1756b9d5b47f858c72a333dc2a78d5ba39f8830c2b8620022037578f883a50dfa18fca9f94383dd83813280a756279773a22ff7eb466144ede01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xee9a2ce098501103579e7127647b9602d4462aaa85e0affd5962d7027abc8a94_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5001000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("48304502205708778e49da49f2de90891b4ab5451ab54f68d11e8625e6f4cf14e6c2c0ecfa022100dd3ff2ed1074ab4bbd50104538848b7953a0fc98bd925e705919f4ebf577f6be01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x18f83eece1fe12d23688d2a24004bf5d8d0fe2c9260ea37f3ebafe87cf951fa1_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("47304402200c24d3421dd43497f111a74beed124c6ab80e0dcde0452b7f53bb2c77a843159022017c61e11120f7f20b8439828bae4cde4efbb4e48266ed9bab035b261e3737cba01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x1663c010d9f47177e0e46c167fe8b320364e7ff961a59ba7ee928d9958f59cb2_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("48304502210080f822413ad28a969f5b82829ef8b92da377bc186594b2f351736a284f5a0c0a02207b3e54b1cab422685267a56eb8dcdd431fb85c94ecf6818be530744231521fce01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xc590759066292633f8882808c2d5f0974a770233577ad8420f7b5ead424e20b7_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100cd8e164fd609a43acbf31685559d480a6e066598118a82ed742b8ea7b1924ae3022100de463071bad5e3c0f844c8e296b5837012e8215d011bcdefdf939094e6bccfad01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x08fa0442d47ec1ba02f2b077114ba136b90cb9f4bb81ccc85861229ff6abfbbc_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5001000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100aa6dbbe3110f9903ebc103fe451a48d28659c8c70feab7019f873656683c1abd02210089b7753b80ca76227505760377cb1163e07c870434a243c9d28a4bbd5d91155801410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x30d2ccc9491740d1d77f6fc93f99b4959b15f8861ad077b5f847f8728da773c0_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4830450220502f34f950011a49592743ac3c24efee291b8d326f840a370753de56c4991dcd02210086ae149ddab41c8d5afe9ff4a22b7f85e7d12eb9c50dc77f05627ece38f1dbff01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x9381692f3054b1313ea090b3aa2064516d0933cfd238dc92aeaaffd71f9226c5_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 20000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("47304402200159147d4f77768a47b1995f166c36d3c3a136157e6e9791ff56bfe7981182eb0220579fbdf9f10cb435a5b213ca41a684bdff33c0f3b3954a93b15a85d40aff3b7801410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x415cfd86022d15a2e443c76f7cfa9ef1eb9541ecd884ee912af29496145ff1c5_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4830450221008a52eb460567dd4ab08704fbbcfddd3fc99f3009dab1f73231b901b298cac4f0022061bb15baf67e80eac12692587a4dad6a57468d4a73c93ec9dace6c6aae8a6a6f01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xa0856d68d50f1785d987afba573c670b6473938e37ac5bcff6d38627ee21b2d4_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100b6c9a83e1c95421eb8dfcb25b2b8ad91b4f9ed6fda8b41f482fc9f0f23ec8ff9022100c2262bc711d0845f4c9331a27ceec92ecf4e6465482d4fbcee356246d270351501410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x6b31a378253d9c52a07e78f489b528b92628d1245fd9d573e5e76dc8fca11ed7_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("483045022100adcf9bf161bec5c230b26ba107e6b5ae18886bbb6a17c31bea3639389b06d8250220563caeea1835c539dc4dd93066a9abb36513f5f717ca3451e88f8ddd15ad4ccc01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xe9911cedfe77aab7a8a9e5707d3f0eff7a9c5b6f380114afe63d0664a46b36da_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100c0891d84e6e4be76a1784129db5612275b6c48b479aa4cf898d79abfb78503aa022100fbca6f6c7ff5c74504ca7888e76b101ba33b977ff04c9fd3604057e0e27f527a01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xbd1d57b8676682ef3733e27998b4f07f69d95514a48bc934559ac5ea23ab28e4_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("483045022058ea4d7169afc55a85a4495c8f9460ae26425a4fb8fafbc6f2dc5c2f6fbbbe92022100826daeeb95b1529747b91a7c6fd92ee36c5f89feb5b53572cf7f60ad79c51d7f01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x5023120e1574a2b70e489cff85fbd870ce6284efc7c1ae0ff2da6a45f91e34e8_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100e10a4dc34adb9a1c8e15bc1e18e7d6737b63dc38f25659f58eb1d67dcaa1b2eb022100c727463d336a884fd0e60b7f3232b702c6656f65cfbf74f834362d0e344aff6e01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xe968e5d0d9373e975dbb9f22732673ee7391da7f39a1207abcf354faf61189f9_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("483045022100fe2574a479b3d437fc5bc35d161a0eafc219a0e164a76d2c201249299afcb0f102205146ef2c9ba5a086d88b69c1040f00513b9756b711054a30b048bb72ae1aa30301410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xf022fdaa7a9fc50d625f0ae78e8e28429c73f1eab7a1604640019bc3d861e094_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("48304502206def30a2e896398f4af175247fc557a7bfbdac4c43bd677151c4d5ee4f7e8c3a022100a375c9ac50a5fe5b4dd2015443cbaeb88489e47e6a69a07ee2d6393c25d34a6e01410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xd7575c0310f83309b0a7e15b63d72f087549e0482382f20cc4536ce715b33d8d_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4730440220763bf700882c193eddc8d49034a0b5f00320e6ca9ad7ca7da4cb5ff7eb500ae5022017ab391a0578a5bbc35c3cae3167cde08ac2d2c86cf27a8501b70701ba4f961601410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x6fd39ef334ac1922da3599dfe43a19445db62f74732474997842412c1834313f_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("493046022100b2fcc74c86f6e74a8fc0401ca542efc984efdece00d2d1c30f052c3689f806dd022100d2730a583040dc718503415d25198365cc458d1c274bb3846babd1a80071485901410461ddee3d9566cb4af650c2cb4d2dc1af3bfb015cc8526097e9b4846378e146f99a5304272243ddfca40579b7cfacdda613a00ca2b52459919d9b4efc9e9adff9"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x42127f57e490d1ad352e22f268f3833123a9ab2efc41740a64d9ddeca8113b2e_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 5000000000_u64,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 155002000000_64,
                        pk_script: @from_hex("76a914bc99ec48f3c0048294bc390c2e1a34d9a16b8f8b88ac"),
                    },
                    ].span(),
                },
                ].span(),
    }
}