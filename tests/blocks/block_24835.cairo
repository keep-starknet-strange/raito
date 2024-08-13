use raito::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};
use super::super::utils::from_base16;

pub fn block_24835() -> Block {
    // block hash: 00000000132fbe8314fc571c0be60b31ccd461c9ee85f42bde8c6d160a9dacc0
    Block {
        header: Header {
            version: 1_u32, time: 1255321278_u32, bits: 0, // TODO
             nonce: 2784354844_u32
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                inputs: array![
                    TxIn {
                        script: from_base16("04ffff001d024c08"),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0_u256, vout: 0xffffffff_u32, txo_index: 0, amount: 0
                        },
                        witness: @""
                    }
                ]
                    .span(),
                outputs: array![
                    TxOut {
                        value: 5000000000_u64,
                        pk_script: from_base16(
                            "41040e1a9b4cb47d8f93579f006f5c7c74fbc6a6700a0eba74ba447296c8fab9a38f376403904d599a8ef1b871b91e06df3121a78e787671a43f50127b2e2acb3a10ac"
                        ),
                    }
                ]
                    .span(),
                lock_time: 0
            },
            Transaction {
                version: 1,
                is_segwit: false,
                inputs: array![
                    TxIn {
                        script: from_base16(
                            "483045022100ab43e9076aa976fb89aa66f38b261e9a2720cd4bfadc0ed3f4237c88288c597b02205e16e0f2100a6c30cde079d339b2ac47ce8ae325deba1ef759f667728c7cab580141045b34a80569593950e7e1ea8f88a3ac419dff208205dadf095c31fe7ca36fc401b004dc7c03610c074584b852bb2b6479e30213cecf4917a10440fdd10de6b267"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x311518ff986d423a6ea1d1f33fb5bcbbf52a45da078b4d359588bea7e0e8dc9c,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220102bb8f16d5c4137a2cbc17a1168c46d4902753be8f3174fd7ed7145c362383b02204a730be3e1cf4bd324268a1f1a7f823ef74f10b0e9ff58e2e7979e0889a684ac01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xf1e1a4ea1b1c0f213f112d6ced2bc455bdd44d969f945e509e3cb3bce8a764ca,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502204214361dd4ea508c844ab96b3f0b3c45110bc8b6eb323d8ed6def93e187059cb022100c7c5854e4186acfda190c6e37efe6c9d9d99b3fb60b15bd13f3ae3e87bfc60b901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0cf8e3045db0ac2c9cb74b2b9e691301b9b6c2d5007e2fd183eb8bf74cde85ca,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100f0f7893d97d1a1b2203327f1f2fbb4d60053f6524507794650cb49efacdd80cf0221008bbc2290342b0c9094bbf09510ab9480abd890efcc52d5e9b4fdb8bab8a70de701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x3435c47921743c686ab901963f4d39dffb9bae8e9af2b60bb47cb1803ad102cb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100f74f151343dc055b58f28c3d574ce95abf6f0cf1b8b8c76c7dd4aeedf90078f4022077ad5f7c6433104b2f39d67447d902d621c0cb5c8ea42370895faa9693463ebe01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa57ba08fc61402fe4ccc3b64cbb262d876447f70706eb047be6d82d38c8538cb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502201434b28594b7a54e0375234e326225628fbb0499992c9423a7ef4730b64793a3022100e67579beddd0097e727c740b47695d2248fd00f189403f17ce086fd105a3b5db01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x34c8fc278a3e23dea617a9b5c1e8cdc339acd3ecabf47b1cb7304de8583085cb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100ff72f3be59f709becc1fa1ff4514c3c5d61b1867d46cb6d881c4c53928380a1a0221009d7a6f88eedf871ffcb0fa20f5436840c776cace5a5ea212283fb3f44d6b3a4d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x7856a709df5dadcf3fa7eb08e71ad4f51190bc75d1ca6fd57c9034f7380df8cc,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402201e67d5161a135f5c2c461813ddec46d2e1c7ba0f8c1e05574e6e11a4b3a812f50220756e3f7c4f690145b39e5985bdd0fd8c0f0c21c9e0ea4b567689476e1707a7c201"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x483eb83f521702470279f53e64ab9dccfc0cae5575d18d9eb485b9da7befaecf,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100cf0549adecc556455ab5bf61d7a65d1e7d71e44ce0adf9f2bbed946c61e7ec60022100bcde91aee7262dd5ec50d9c5dd82a82dbaca03a29b6d2d197a575dccba38e94801"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x06986d4f0f7e45f60b92f36d9f2a5dacbe39601f9eaa04867b15be28d0dce2cf,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4930460221009a50ee3f526bcf34817a85c202b236c14185ea82f3dc2828fa5f65223680a708022100c9acba8620a9d57d88bc7dbfa8a121b5542d92b63e12b197a571f1802eb1530601"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x3de058d7ebb9786a559132a8a9a4dfc4f83613179c2ca58dd6e313ff3371fccf,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100807e9d48150fe08dc518e75155bb3b8f04d2fbd1f59012389ae2b3878b82a8ae022078f9df6bd876148141b3d7b82b38b4b2cdef094c8ab162e5fe2dc177bcfca64d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xe1b1501273f4848dab128873af1b208e79885cf59e9a4c9b865b406c6f5dc8d1,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "473044022018fcb0b12987bbf3ff40dc29e729f9e6a842ff512fced47e1e95b482b5a2c4ed0220727810e0ee1764a05a9828018b3909c44252e0eddf5895a9ba22e06febbe2afa01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xdf34174373127152bde8f07fc4b31f8c7d6cd914e8048ac7b2a19b91203187d2,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100eff124e99fb9d39272f3d47f3d4ac28cddd2e927c102bd1034fbea9cd58f42e6022100e45c388d72b58dad9f1cb5e86787824b37ddf5cff8701b419c4a9583415b1eac0141045b34a80569593950e7e1ea8f88a3ac419dff208205dadf095c31fe7ca36fc401b004dc7c03610c074584b852bb2b6479e30213cecf4917a10440fdd10de6b267"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x11e5b0bbf5a4f567525721f45d89bd30a2888c829b333a4a50710148777200d3,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100f1ee8e4635471c9bb94557e3a7db5b7635bcab47108c7c0eed30500f2ea7cdf80220678b111c852e23fb0c096487098b40ec08bbaf887380042845a2338c7535b92001"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xee102532f039f1f23f03a82c0566c52992f4519ccaa52f5c54fd45c36f1ebbd5,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100f85681bdee6f0bc373f229964997a3f9461158ee9c9b3d3ca886a893ab7a3a99022100971cae746339647306ad3e1020e200ac642f56996b634e14a4bbf81e0981127001"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xfcefb3dca3f1269d1b584cea5f43035a1ea573a409776fe423972a0035af70d7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100f06164baf12930f53e49f3541377502071f40cc6e5f04b7784241c6323a2da81022008b18f104351f2104df81023df651a12c645688226fcd68a7c1a2ad95756d00a01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xde5539fc61f35d777a9b939ccb74651d71f3c3024b8262772d06e3c1465797d7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402201b65434b05e4e654ed25f4fbf852294649ef4dacff6b07cee0d40deaa753e0e502205c7fabd2480449127dcb6a4a25b24e843c3c636edef7fd9a05e6d1a2e37ef9b501"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x97a310f6928e41091fbc0dc1a3a92738a99accc1ee0b97e5ecfe9291003dbdd7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220768519abe4d029eb1df8c4a3904299aa1890a52dc65ff17977f617f370e55bee02202d92ff6ce7de48dec50a7904106fb31f33ab1f5d019c7940c5ed1ab0df8f665101"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x630cb2941dbfd117facd8a2a9e7597c23c02a089788db100fe79b992527209d8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502205d55c41059fb7a56828eb2a54285e310e6cc904ca07896d3113764c596ea34ef022100bcdfeea94ea15cf44fdcb0d824d80f52793c0915f3673e989fc28ea86b414c1401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa7b92da966ff1d0041cf6ed1b3d6410766594ef712dec910b23ec9914c9084d8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100835ae082e3e1d5d4f3fb1d7f45fe2d27a0706e81baf2e5ba44d12a2890752b5b022100e05a652770598dccb3de04620349a708cc3acbec3c83c168adb02dd7801c28eb01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xaddf48dd7aa118346ea88e023c4d83bb43e754d0be4dd69fc863b2000956f1d8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100f72374764265658eab57b6b6b6680cfbc31fdb72930fec37f41139d01a28955f022100a66549edc1a75aac7afc0eff6f93a9ecb6497d8f732b536ab71c02584a78c8af01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x1619c6f1ad84d7e7956bb45e6438305afe7b6991e80c18ea08aab1ce46090bdb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022017fab63a25641b6beb4239bf52bbda8be2ba1c090cc075a1332a9458b37eefdd022100b034601631ef555859fe3a842ccfe59273dab0494361f35d1cd641a0455f2f6701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x065960fbe75deb05f8e322001d200c847bff4cc1d9430bf3d4e5fd18aa8f19db,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100d384857c752fda11ec47726cd1d414979991e8f5f6a21dfbba04bd895f658a3102202d2ac7e22240cc4a94c0eff3d900c800680ef92ae556499288be24aaf870518e01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x20f565ce967fa02bb9949c6634d45703226d5e1913be99a927111ee700e330db,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100f961a53bcc28adecacd2b500747a8df6bdc6864dcfa9e83b18af19c904d5b5f1022100a477e051ee9b4aba7a2c23f9ad05cb230c213491fe9129d2a496139d0efbc49201"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xe62b3408c5ba2ce1753fbac751f73c9acb26716b17729cc6388e353617df4edc,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4830450221008ece9b49580ba4e1f274c8a9e1b11b73b13b51644d49bd02afdbc95ce157b141022071ca0fef8a61d26f3c5d64cd2e5a38c8fc62050aa234aef8f5b120352e80b25101"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x4a03897b4779be06b21b1acc5d69c49d46f759b8f1b6b73abb77d14039d0d0dc,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100b11d5ed42a83b6bef7fab193897aa1104cc656398246fd1548798d9ca6d7d95c0221008dedc2ee4f9042549734c3d3bb0b745231cdd02d323151fb5ef3c69eb96789b901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x2c6b470d99c34ee64d0b1936ddf8e90897b8acbd8aea7b7ed48a746df0d854dd,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4830450220111db279383219491f648c6a59260f00966e3d2fb84b4e6ac6e85d272dcbffb5022100e32d9a475371ce94b98b6a5b3fdc4cca5cc840ab1dc137bfe800c74176c7c40c01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x39aa30043aa448ebcd5398d95ab4bae5d497998afeef4983e94813719e1d62dd,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402205b3db2ac3d6a10bed97f3f3ef3c83ad1421009120b456597670b94bf1a4a181702207905c50cdc12a82338781f5b093f0f95a5a495b01035fcedb414345128da702401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x1d4790c0b35d2d5c9e66f7bd5acc70641e9ab0598cebcd68d3d186ad78ce8edd,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "49304602210095ec3ba7088fa8222803b85672ecfea666a7e851af49cf420aa19775b8ff331a022100a9139da820b69498ed7bf083c1a516e24ed780d5ac8efb6f35332a0b43dacf0301"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x9306bdce3f6f6e617770b78bfd6656f202da261d08ca80ce3787090b2373afdd,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100fb515756a05e5651a5b2e597158cd2bf0f81a759c15b38fa798f92a197decb7502202cc50cb2073a1ff448586ded01c3bdad34b5dbb1a4a9eee6c02ad80de047de6701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xdd7282eb80be46364c2470eb9259b3add135b4b43e681a5e177f717dc11dc1dd,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100b28324e9031c3fe397a505d03c4adbe6461f5c5aa58e2de691545551f8b24183022070d565349df87b34e9cbb628244a278d044162dbfb9c9f8746d1448634bf561401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xf57ad846d53060a5b222650c04ef718a6a3a6e8bccfbed918ff93df1c6be34df,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "49304602210080690306b4c5b37ce3497d71a49334a46184508aef5f7ec26d1ed2c6a81e94c9022100b7dc2b03c16a1139687795deb73b257764531d5d60ccdd1fc18aca54f0909b8d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xe43a802cf13eeabe8998183f748b5026a3c4a4bc050bb972d69ee703d6d45adf,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100ea97e7c111acd32d7ee497a227e32985d0482673760a6d9d477f38ab06b0b96f022100ac2b692e4b83acbd12cc192cbf802a76bc6fe541dddabb3de34c38b90ce946ed01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa3ad4b55976bcf6bd93416bfb3f2aa7374be874dbc454faf398ed8e8eff653e2,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502205a2a6f5f8641b99b64f60e6820b62a0ebb92e715f6735784f3c8f62356133b3502210081788972d45aa1cdf198236bb8c50c0720ffd448029f0fae769249e184fca3d701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xe6beafb2e9c27e7de79ec82ad19dda812a0fdba5a642bd702f9fb377735ea9e2,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "473044022044ee0785af4965813db1c10c7ec553bfa437e8724a62172becf06c3c6bae442a0220165d6c9681e9dd711146e1a24982ca0f1a3f7b4f75eed475377be531f1d08fe701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x59df3a869c742ebd49b0fe5c9b0434965511ba364e03943d9aa76450aa52d2e4,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100f31fa08d9bc223b82e8913425249e42e6a8a319a418f3f4a6173e0e4da23b30402207b31d68597bf0807a4cbe74781e799be0598c418f59d4e8c8bd2b8d5279fcb0a01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x783860b2be1c4f2693f3f3550cda85290d02bf384dcf1af42fdeb655e4f3e6e4,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402200da8a460a3201abac60a7f075c866fab087eba23bea4e0ccacc57b06fc349e4202203f6577f8bd7e1bd551ef86e961d84d46f16a1e0b1d4c4210484df0cb09f3cc4b01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x44902104842aa573f891d2192ab32aec82ae2b214aff2b8edd920ff6ed9ce7e4,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100a28c32de6ec4068592a2b41c05e12fa1bfaac4d9a646e6512c820bc0a89eb0d402206fff73aa7d11b65899a63022d44804cece1a0669e033cf509523731c1cfd6d8c01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xd4239da37ccadf315a941053905b0c81cfc0f9e2f68d5d96dee03ae731f0f3e5,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100e7be1d671816a7a444203a35fc7f742f0805ec5d84b206a2276a4988089ce435022100a75a1cfac94f6c62da9982913fa1d733c8ed0cb5eeff1fca7048240c615e152d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x93e6672f34678b7c17a3bb79cbe1ba22657b29a6b68ad962af8f1ff6a053f9e5,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220241e6aed01b510d1803b502574b826bccfed1615a31fe31a287b310a7c234a17022033ce89b10b33c0055892b855dfa4b50a1c6022587794fff8850b9ff61fc0db6901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xd2a05c061b0afa7031f90169120c601f3eeb994884e904e74f1a21cd9362cce6,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220445e33890c552d1d6191b4d686711b32e2316f51e44b210c87b232cd0574689b0220029d92fb60b2710973e097cc7ba52cebf78635b2a24d3c6da9bee9bc24de649401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x84fc3cc5def8a9aab4b0c24b6373b6fb9c31eb581e122740cf741fabb618ffe6,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100959a01ce70461f18cc04bd1cf95b8af540ab2e908c5257b099207308cf0118a2022100e38017660993fdd65ad7caac3cbcbca95359e00b6ab261783e847efcc1d8b5ed01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa81d0929eb263d57ddc42e051431dea8e0ded3da151f0ddeacfa593881ba2fe7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4830450221008d7458efbec4331253d5357950a180a0bd983de0b308242111bb148188c027cd022005c8e9012032d68df232d899768063d0ac6636205a881657a35371917d7d708701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x71b6f3f5501b982acc5eaa687dae5441f1bb72a5cb067ca0d831ab264bb34ee7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100cbeeabc774479aeba630a72f334a98d228bbad919a34d1cd01df707afbfb911702204e2d8e0c6ba60580a93b4846a1dfdff0dc3023e26310672ca85af4c4641400f401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x6526597d7e7293fc3201057569c79a88b1b357aafa1d93503c74b3e350600dea,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022049f0c2b73c239a39ef7153a10b89efdd343d47810209d83a42756161e8d193d4022100e71ced0887b71be9fb375692517d31a5ba42547f9c4e883f635e4f132f23208501"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xc9d5a6b939edaeda6bd0b9e3c08614644f2ef4f3afe7e4eb68bc4d7c88809dea,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "473044022078a9fc630e59da0bbde83b2b5e60668a68eb23dd12670a4a3a91dd626d98aed802203462875836df62e038d8df2dd1560e15979f07d806852cf4b5b2fdc93b42327e01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x4b4037c615cd2faa213679a5c83d5f5c338f5cfe00ac9944a4fac30543dd97eb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100ff55d0343060b2875cb34a26dd10621873e56952e3c45769b1b815e785734a2f02205d6e5f6a0309b93f670a32534cccc9ad4d28bc1005ca8d49712194e59a69e7f701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0a28db164ae746a2bd7d7d234044d341e66a1196b71c307c49e127165fd7a9eb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100e26f18173150bb2bf0e5b2130b84c0bf0fc92706ae979b6f4552d3b1f74d6907022003c3e8aadfb4bd61d9bcd987b8aef8773038a5112985aae93786f9be5149887501"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa7d5f7e26ec4c3aacd42dbf83ffba4848ab9af1212a7d799b27fba4ca17ef0eb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022054fe96102c590c71ed72ba884d5566dc19d05fd0f4c4b2356a2727ca8f70bc35022100ffb9ec17344ab8658021b9c5d1e9764008d61c5ff5d4f08778a33417f1a2de8d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xaa7b5e1d47d4d2f434dd34f7ee779afae0237399df1055fd80d8f1e2535bdcec,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220244b3a33967c8b633c73f8be5796b27976723c15fb61a5d44d527fd581e7df3d0220637b4c32434ac41bb7a72cf8cf604b463e55d624b3dacfcb46c20be2179d3fb701"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0f6ad89fec32bfeb710b988762c4a74175aeb857f1f050c5a60fa1a87c9ee5ec,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100ff43c2ef0e270630f6c7fa230fa067c195867c3e13bc7ef825d041c0c8d55b7c022100edae02bea39f69d643805ab8bee2af3e84450edce29a76f66225c67a2476c4f401"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x9e02bdc12407ec7dbf90a10ef3daac80004e73c26cedfe9e61a64956879520ed,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100bff29ac87ff41dbcb9cc8264927fb3e6fb075b7f275199ee1461540093a3bf32022066be4dc056b1db891a33bfd8f93ef656096ce9a5ff2fbf0e188541c13141ee1d01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x9239353d5886c83f5dda6eb875a7f999a0b7b5fb21be272836013547a027fbed,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100a589c67af00412fc707d332ef654e2181c2acdbc3c305e1f199b098a25c5a2270220776c1d75e9eba7ed3d5eb8f4f1defa84a6229800ac19b4bb6245d313bed1b26a01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x405a3b936a213ddf72b84b7efadb05b6922a488f3a4dd8fab6a6fff053ce57ee,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402203a453e89fcbe52a4d5137a6daccc9880ff160b76844f80bbe5bb7c8ea6472fb7022070fb6a06497f93ef73fcd83c641fb1b18b4343f4a4f91ca039e5fd6c50e33fcd01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xa0cf8f3bfd71c460bf6346ff9270f30e90fb7b9d91f3f3d1166959c90887b5ef,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4730440220769ba8b826bb12c3e321911186f01706d43b4a769fa6bfe1a115d216fe494a890220164c8da13f48345afe37e0867975155c83646276c6fac6b66ce30324f87b087501"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x7d338350a0ba8e3c9b91dd733439474509828ed73e81bb44a860953190c4f2ef,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4830450221009c876b9421e0ea9193dad73308799f7e958325198e577679cb27fb321d895bc60220571f8bb1773579915df05991b6be586fd18763b2ca1437d01ccf2704443f455e01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xd1d93d08900473bfcf5986d7752b724bf343a0195bacba4acc0b1cd559fe81f2,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100ea78e3d438ae9bfd930d3c7d08d3b9fb5622774983d0d1e927c23edd251807cb022100add43833d586eda7a2bbe1d8d8cd39170276aac9ee28a4790f66a36fe5d8690b01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x467ba8e7d5a10f820441b2f4f403d4bf24876e9365c1724e9ca95114b6adc6f2,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100dffb11f832c6bc5ce87ca237e0798a1a990fd69dea0d91c36987aedb9e31c9f30220571f8ec38d26a9775273dccd7cc71b53cb819f8de538c51eaaa805b16714caaa01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x4626bd7c085ffe44e12c0bc2045072c6e21dc25f177c3d07e840030d3986e0f4,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100cc57aee9bc1d7eeb9d2bf0648036883816d9a837372f35c15a6aed1d81e353c20221009a0d3c2a242487aa3e81baea830c4e401daa8a293346f0d0e8d0880b4a657afa01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x8a5c68c640ebb398249c73211447a986d641144eb9c95025521a47ec2785eaf4,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502206111b04ff00d86769b13a4f1cfcc2bb97f1922967b167dc76c42bf9821759db7022100ef2b80a7c586a7bf2aed91cd1e57c828f85b9e56c8da0fda6c5afc336f84e3d101"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x840802b95a5d4389c35632a0168668177663c3a4398bc974208f49444c06f4f6,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402202f45c00324df41cfffc0f72baf31b97f9f8a5461bb046f9fa41bd3a5d9d5f72d02201cadfa9cfa1d7265793020906e4cb716ec352bd9bed87df75e7172900a4a13d201"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xeb65a60f45258791c9362dd5834cf470294001f54ecf0d7437e566829bdf1df7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100e9b2ff943eabafba5c4621faa5e2cde760fbcd365f58f46f1cffa3d399ff43c0022100b8d4145e99a97fcbdf604ef6318fc211c8bab5357697128e3afb35b86db5696301"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xce29b2407f6c0aa5b637b4e8e1cd05c8b63cae89f9ace7b39d8f5b1b49fe72f7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100eca9759fbc7be7806aec3e7a76786707c9ca9c6233f72d61b36ebcea6a171c4f022100a8ab735a26a5669e95b3317e3eb055f84b141b936afa8ec98b8e4ceaa03914c901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xf8d5b3fb3980f9465619cbd11429e3379acc8274f4bcf190652c788f92efd0f7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502200a65ae91810e89499d5ede10f02ce32b17f1bd7a73e8b4598535ffe5755874a4022100969ba2337cc7569aae0add2a4e01386a4f9303388a483e40c669b5961846fded01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xc9bc40d1ad51d87280ea756f6527790cae3d786b2dbeae6e383154530dbf24f8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "4830450220371fc2a7115d4cb6a565b4e5c9f2adfef0d1a86c9e4882d02d633a954632aebd022100e9e00146b6f11b36835c7ae29549e43570804b59ff5efbcc637308b045b47bcd01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x56514822f54b5451da8d4044a18686a60228b6b9c630f1aea51782b2316a6df8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "47304402205c3845ffe0c94bd687bf4d7b1cda768c8cec950ffe6a2b490afc57a222022d9c022025144819035815d9304b95865a21cb272def88f6779706ce193a64aee276aa9c01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x695765e0ea83fd8e65f12464677ca0899a2e1995334d2065e27b20f218d69cf8,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100f8e1b186a0da0a7e6512810cf52209baa2e52642e749b4a5b366abd18666b018022100e67621a713064ceca95cb501d00a07e529e9be469f482fc03828c65a30de16cb01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xdcb93d52f006454f6b79c46e68ca49f21fda26f8470cf5d62552129296a0c9f9,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100fa42041b5d73c8b299773c5006ade152acf2e67c1892a2a53325b442724c42e10220246780cee7e8d121897e9f09c8222d37c0c26c9b032b41b7386890e526d694cf01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x571072067ed202d35c6fc74bb9431f374db8be1448a5660c98ab43766cb7d8f9,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "48304502203f41c1036dc1265a641039ad4914c4fa99d385e8dc8bad222bc84dcdafb418aa022100bd9611921120886fe3f2955e0dcfe88ca58934336fb54c70da678a82775f356f01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xec06aaa81f014977739c231d23726c14d5acf1631e67b27117fd5dbd0f4128fa,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "473044022054eae691dab6edfab71583b69375121548ef6e994e0a1d385ca429a5633fa5c9022021cfc06d223864110d119a90da3b11fec09881c9255e7d06ed8c9b37a0bb739e01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0xb24c85639bdd86e7f3d94d8189e0f1b1527ddceca98004837e450f150c977efb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100a7c042ded948e6079b2cc6d98db02bbc79c2410d80e8ce712c880a7bed1de71d02207cbc291daae75134204a10d8a12bfd4548d97acce0efab0ad3967ad57bef87fc01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x132d390b89c6d82d4e944273c26b0720f8b10def87aadd07a0e64a59d896c5fb,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100ef00e4121f13f8b3d6eddcc94ae1a9bf1c9ad2ac72d08f599f68d0c36036e1d702207b8fae05518b7782659c35f9932ea114995e809cc07e39f4b1ec6526af73d9ef01"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x23be0784486f8783ace6947b136cb1e43b0bba926a12ee1be8f0221b8e9a1efe,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "493046022100ade700ca5d93559df5a4986e8d9c43c33d6a4e204ecf785921279bb5419f62c7022100d101a7a5488f955e90efd41e5293a6c87bb955edfa94eafe30796f8d2d95a76601"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x1c73a79fee897f957a5dcd292060043b627b8e53d7228af64dae6d394e0816d3,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    },
                    TxIn {
                        script: from_base16(
                            "483045022100c7ed449f532f5bd236196c5075092c3c0e7307877ac4e8b446de17f623412881022002ef45165a8bd0306ad24d080bab804095c67c91da2c48f8b3af9f8e3170a8f801"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x92e4e20e902ce28aa5d207d9ab8e8a446d2bd1b87e2a3ea2020689ef47bd9ab7,
                            vout: 0,
                            txo_index: 0, // TODO: implement
                            amount: 0 // TODO: implement
                        },
                        witness: @""
                    }
                ]
                    .span(),
                outputs: array![
                    TxOut {
                        value: 505000000000_u64,
                        pk_script: from_base16(
                            "76a9147aa6dc533bc3d2ba2245643115c77eb3eac121ab88ac"
                        ),
                    }
                ]
                    .span(),
                lock_time: 0
            }
        ]
            .span()
    }
}
