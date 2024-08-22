use raito::state::{Block, Header, Transaction, TxIn, TxOut, OutPoint};
use raito::utils::hex::from_hex;
use raito::utils::hash::Hash;

// block_hash: 000000000003eaeb80590d76856f7f9d6c2aeb691a6c0cba747d5b523d20b0f2
pub fn block_100010() -> Block {
    Block {
        header: Header {
                version: 1_u32,
                time: 1293628047_u32,
                bits: 453281356_u32,
                nonce: 3161077260_u32,
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                    TxIn {
                        script: @from_hex("044c86041b0153"),
                        sequence: 4294967295,
                        witness: .span(),
                        previous_output: OutPoint {
                            txid: 0_u256.into(),
                            vout: 0xffffffff_u32,
                            data: Default::default(),
                            block_height: Default::default(),
                            block_time: Default::default(),
                        },
                    }].span(),
                outputs: array![
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("4104426c5ddf1b27378d447fec54024ce016eb5986308b0fdd0312677b803516d42c179a7b3bf0aa3e37f71408644e5c57ec0e205f8e57b1f394700ed9ef87938c48ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("47304402205a55055ca5f9aded9682e4cd565ae03019e95049dea29730476515702f7bdb29022051bb6b894d82efbb9c702540004c008abdc3ef6ebd742fc88dcea30a1a737cae0141041a3b9a56332e31b594b51d2e396e26e86399b6f61d0ba780737885636c50953de4d4fb241f0c9d4acbfbc395c030f73dab95ed985fc2fbd3f38fd7bc8ffee01f"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x3a9938daea99688083ef1286af39a9f4a4f706ceeb368890507ccba9632863a3_u256.into(),
                                    vout: 1_u32,
                                    data: 
                    TxOut {
                        value: 2400000000_64,
                        pk_script: @from_hex("76a914ff8593466883ac2728634a9aff2a36eec691d42b88ac"),
                        cached: false,
                    },
                    
                                    block_height: 91013_u32,
                                    block_time: 1289435804_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 400000000_64,
                        pk_script: @from_hex("76a9145d838fc62251408cc5318457bb0faa9e5f003dd188ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 2000000000_64,
                        pk_script: @from_hex("76a914dda4521a9cd99e92323ae4762467dab928b65f4588ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("47304402202c5ef02f79d30286c0447b7dbd93875958f0f9f300f990f825afb3382a629eb0022052f6547a7893cf84736fcff895af4f7b9ec342167969e33a1cf28f00a091315701410499b7eae893a22c5c166f8b484f1cdc6ef81ae169c6eba48c2dcea623e23289b79c889162f172f572a6be945aa927a0755295d313e077dd105d115356d6adf020"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x3894e46f7260097a8819f0a758252520107fc8f68d0ddd50335d80038ba7dd7a_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 4989000000_64,
                        pk_script: @from_hex("76a914f01fa64a52382f8932872949e2e8ec0e89538f0888ac"),
                        cached: false,
                    },
                    
                                    block_height: 97371_u32,
                                    block_time: 1292257061_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 989000000_64,
                        pk_script: @from_hex("76a914f5c09ea34a01c87fd3179259c28785f8230ae0c088ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 4000000000_64,
                        pk_script: @from_hex("76a914cf2b8648492fbe8c90ad09e59ac1a3257655fb7988ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("473044022003dec166eae3b62035f0f71f11944e43f8cc6cd9b37c74bbff9021268992350402201c0c3a0a9b5c14e35300d7ecd04fd2e0ca20250cd1053540b9e82e12eafa10df01"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xef2382b49a2003f915cc07a4bb75bab40aae8c68a519b804bdbbb66e1a8a484b_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("41043acd33bd7b3e11aac178e06d7fbb9727ac929d6dd458c60652a3555416aa7b04a5ad23f495fe042a0f6ca464c5bdfa9374a4bf7bb9a799b1a263c7e345a7edb2ac"),
                        cached: false,
                    },
                    
                                    block_height: 99888_u32,
                                    block_time: 1293568724_u32,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4730440220058be3bb2b646e449948cd5f960582cd93b56b3a5619fce35f04924f739f5c5a02201c59260e167852877233ef93e741a077d3432df2fd0a12241626ca2ced7e36f801"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x9c584915ce4d7e702125aaaed4e9fddd0bb83b5557a48d585a161ec2a05a5e81_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("41042a66658ec3b1bb384479bd4cbe0ff9670c59c4a3a62be6c245681b30395a8dec34f5eb13f59a67dc65bd6b4d80d3fe6a2b36fbf0d5508d2848ba048e1eb7018dac"),
                        cached: false,
                    },
                    
                                    block_height: 99885_u32,
                                    block_time: 1293568111_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 10000000000_64,
                        pk_script: @from_hex("76a91408903a156dd0cd5c96b07568cefda2217a18a85988ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("47304402201e9426784151b17d79b59447018bda4ddd6b538438b3f61e0cbcf5ef81db706c022013ea1097f5246f5d4eadec9828c8e5f84f289f1f918a81765959e6560c2c385501410409e6a3ea80a7fb33b0af03c483a214e8052af698f3517f4282074a21aec943b05317e29e468a4e6e947944a95261041dc26adc55fcffd99fb40aca2f16842015"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xa83fde0122e1db5f4f92f9af92fb5651f914693c2910ebfd75786b0807db046c_u256.into(),
                                    vout: 1_u32,
                                    data: 
                    TxOut {
                        value: 34425000000_64,
                        pk_script: @from_hex("76a914fcc4490b0418e34faf99ce2a352d3a923c8e8be688ac"),
                        cached: false,
                    },
                    
                                    block_height: 99978_u32,
                                    block_time: 1293614551_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 34420000000_64,
                        pk_script: @from_hex("76a9145c8966b718b4c2cc3ec4cf6c4c82e77b5ff5aba188ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 5000000_64,
                        pk_script: @from_hex("76a91493bef1d692752a9849c28679634ef16b894e383e88ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("48304502207760fb7ab3ddd439377823f80717073949042259f5505763727e815c94366a29022100a37b0996ffd95f8dfd93936eda588bdccb842df7f0d33669fe1d6a2b7ea8247e01"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xef18daabe2dd811f028ae9e674a482fb59174b786b298aaead32a6c14cf7be4d_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("41042a2b21f7e66010046bc219a78da66ddb346baee3b074eb006286092c3fad8dd735e53df8c503b04bd76c0f40812193aabdd713a4c6ff2d18d4c13350713cc71aac"),
                        cached: false,
                    },
                    
                                    block_height: 99882_u32,
                                    block_time: 1293566823_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("76a914cbc740c25281db1a118096ca172ea0f5f714673488ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("493046022100f2d278f48956619292655d3bd39641a2e187ff3231c8bc5c2ae3c68bb048978d022100fb5d38e152965f3b6d188bddaa743f6c173f8b8d9a280dd4a505539a4a60611601"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x9f0846638ff870074a31a7975c18e1659a9ec668a573cd8336283ae9fd8da460_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 5000000000_64,
                        pk_script: @from_hex("41043eff1e9230d4c79d067db9b6db2187687f74fa1a62c469b597e6f1160d66b537998befa8d6f4c6261e495c42f5e759910c09b464b347b614a036127120364a8bac"),
                        cached: false,
                    },
                    
                                    block_height: 99890_u32,
                                    block_time: 1293569878_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 4840000000_64,
                        pk_script: @from_hex("76a9149e5d9b13984a1562813a4a98b934952ae5fb5dcd88ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 160000000_64,
                        pk_script: @from_hex("76a91471930f7b53595b8e1b35628bc39425f4d531ecac88ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("47304402201f22da6a95b0767fb319a8584f233fa6ff50e59482a33230b5d29710fbec305a02205f9c080082b560ebff3e712fc4b78501385f2643479efe45d41aa2350f7b354a0141048eea0d9fd108349173f63539ac5330798de851b293b319a4e850daeb1832544461c75d3747217e3b3fb38c48efadead1274d83263f5bdf59007776986c3db538"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xce29e5407f5e4c9ad581c337a639f3041b24220d5aa60370d96a39335538810b_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 4893000000_64,
                        pk_script: @from_hex("76a914955f70ac8792b48b7bd52b15413bd8500ecf32c888ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 4714000000_64,
                        pk_script: @from_hex("76a9149cc3ea6852b8fcd2d77b902e22375a8a34a7b61588ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 179000000_64,
                        pk_script: @from_hex("76a91440b1fbec7c319fe74e6783d8275a4ce085d35e9388ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("493046022100a4ba651240dcaa33914f671186fa9cedf5e518548bbc93e627182e22095d219e022100c50ac5bb86be9b761f677d516a76f38a4ad32357b0982a795b7181ff7bf5ed6e014104502d191a9d961f58970a9da1c2427d289d2f27302b1940ea3a45589505ea74271617593fb923929c08036ac9a3b37f41475e7720534ee0d738bdcce2532b5595"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xd6c7cb254aa7a5fd446e8b48c307890a2d4e426da8ad2e1191cc1d8bbe0677d7_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 4881000000_64,
                        pk_script: @from_hex("76a914d28f9cefb58c1f7a5f97aa6b79047585f58fbd4388ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 333000000_64,
                        pk_script: @from_hex("76a91437f691b3e8ee5dcb56c2e31af4c80caa2df3b09b88ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 4548000000_64,
                        pk_script: @from_hex("76a9141b53e645ce5301ee68441b456c9166e3495c833088ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("493046022100aa1b3286180b20b7e836743032f470173fdd089151b97936559227d4a6b8966d022100cdd5584bf968ff22229fe97a6a0d92f3a8f80833a22903de0a00e017b19bd6cb0141047220a1b6873426498dbfdc4fb55abcc47382c0f0b19cfbd649d900074949fb244d674a43c7ba5cde60fa97a6023e6c46bb651223f0fca9dd7d4ec4fdf7f80e46"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x45a38677e1be28bd38b51bc1a1c0280055375cdf54472e04c590a989ead82515_u256.into(),
                                    vout: 1_u32,
                                    data: 
                    TxOut {
                        value: 4736000000_64,
                        pk_script: @from_hex("76a91465746bef92511df7b34abf71c162efb7ae353de388ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 4253000000_64,
                        pk_script: @from_hex("76a9144264b33f9bca55f66c31cd7f9ee2c882e4c996d288ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 483000000_64,
                        pk_script: @from_hex("76a914ada27ca87bbaa1ee6fb1cb61bb0a29baaf6da2c988ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("483045022045d85c2f7ad9369972af8efed8c0435ec88d3958b50f6666a637ae373e190e12022100fcafac4ec2a20502f971088fdf8a366052e7b3f486fa5302417c390684d24bcd014104b2f30018908a59e829c1534bfa5010d7ef7f79994159bba0f534d863ef9e4e973af6a8de20dc41dbea50bc622263ec8a770b2c9406599d39e4c9afe61f8b1613"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xc5abc61566dbb1c4bce5e1fda7b66bed22eb2130cea4b721690bc1488465abc9_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 4583000000_64,
                        pk_script: @from_hex("76a914b73e9e01933351ca076faf8e0d94dd58079d0b1f88ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 618000000_64,
                        pk_script: @from_hex("76a914fd41120690aa6a996c06eedb0fdf86c722ce213b88ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 3965000000_64,
                        pk_script: @from_hex("76a9143b46c2a48dae855aeb07dd1f5834bfeef35dbd2988ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("4830450221009433a5d382bf917da4fecbae5135aac840b2d003ff4f9c5a411d71be8f74482902205a5396d8b44da98a84db4df599b2f1dab2a767240009394f55cc7f2fe993acfa01410470b09cd5582cbb0fe58b64b3f54bdcfdb473e0475f7f34d2b8864bff841b46b18c91fd3b2b448cdf5a43493904c9d50ad0c8107dcf0c2f0059d0eb5e686be0a7"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xa71f74ab78b564004fffedb2357fb4059ddfc629cb29ceeb449fafbf272104ca_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 4359000000_64,
                        pk_script: @from_hex("76a914ef7f5d9e1bc6ed68cfe0b1db9d8f09cef0f3ba4a88ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 1512000000_64,
                        pk_script: @from_hex("76a91497501cfed223e441656cb5277ce5659ec502ef8a88ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 2847000000_64,
                        pk_script: @from_hex("76a914753ef5eccdb8e00f9d92012b2455b2b2f9a19c9488ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("493046022100bf93cc74fe6afe9f3c2f451eda6414bb986749987b61d7b29abd34427aa4c51d022100a03fe0c0091bf2b6a8b6b97d48e6e98a82dc8ea795d6f8a9e2c9c40f8d917962014104b7f95be129bc8e092ffdac2fac4d6a3c477f3087b01d62658deea65d80f988b91fc5aa2cdbbd7d09b3b799f813aa9ebf11bf28730f2acf4017dab3c4ce287496"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xd3cd1ee6655097146bdae1c177eb251de92aed9045a0959edc6b91d7d8c1f158_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 3084000000_64,
                        pk_script: @from_hex("76a9141b11c6acaa5223013f3a3240fdb024ecd9f8135488ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 2244000000_64,
                        pk_script: @from_hex("76a91489fdd57403904c6ab1f66e39a112d1f45b5d0ed488ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 840000000_64,
                        pk_script: @from_hex("76a91419db911c3f619e8915ed2866b9a2d11c022978f488ac"),
                        cached: false,
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("483045022100d59165629cedd370e7ddff083b5345534ce918a3334463781ebeb9df8a3714c102202591bafbb64c0021635271d9dd8c476e60bf92aff018331336430790e90d4f4c014104333715a66e6bb80c41edd593ace9b73073c6a1784a2188785cfe34b890817699a8106c0481c8a9d24db54318bc548a37d752d218576b8a7fbf949ab2f3dbf860"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0xfda204502a3345e08afd6af27377c052e77f1fefeaeb31bdd45f1e1237ca5470_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 3790999999_64,
                        pk_script: @from_hex("76a91490fac83c9adde91d670dde8755f8b475ab9e427d88ac"),
                        cached: false,
                    },
                    
                                    block_height: 100001_u32,
                                    block_time: 1293624404_u32,
                                },
                        },
                        
                        TxIn {
                            script: @from_hex("4730440220639078b309b05be2694352c3348925a2af6fa3621a4bb5ca508615c98f9d9928022071d4c87c19d758dc7725ca5e025d5532d07e3fc2556222a525b274c6919e89d9014104ac23934853dea2b2b2e06aa92358c5d0afbc1b55ddabf2006bde9c2a84b087ef28111f10acdd4f5e97d1fec5ef34b0dbb26cf08b7fdfb735f3ae355f3084037f"),
                            sequence: 4294967295,
                            witness: .span(),
                            previous_output: 
                                OutPoint {
                                    txid: 0x149a098d6261b7f9359a572d797c4a41b62378836a14093912618b15644ba402_u256.into(),
                                    vout: 0_u32,
                                    data: 
                    TxOut {
                        value: 1623000000_64,
                        pk_script: @from_hex("76a9142fb71ee16dd498ac19f9edb3a349cd743dd3110e88ac"),
                        cached: false,
                    },
                    
                                    block_height: 100004_u32,
                                    block_time: 1293625358_u32,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 5222000000_64,
                        pk_script: @from_hex("76a9140b9f6a81b31439a0e92213582183017252afaf8588ac"),
                        cached: false,
                    },
                    
                    TxOut {
                        value: 192000000_64,
                        pk_script: @from_hex("76a914bbaf37062f4cc9925d8b07ec98e4d8a94f5032b988ac"),
                        cached: false,
                    },
                    ].span(),
                },
                ].span(),
    }
}
