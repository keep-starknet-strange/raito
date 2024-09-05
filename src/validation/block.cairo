//! Block validation helpers.

use crate::types::transaction::{Transaction};
use crate::codec::{Encode};
use crate::utils::{hash::Hash, merkle_tree::merkle_root, sha256::double_sha256_byte_array};
// use crate::codec::TransactionWeight;
use super::transaction::validate_transaction;

const MAX_BLOCK_WEIGHT_LEGACY: usize = 1_000_000;
const MAX_BLOCK_WEIGHT: usize = 4_000_000;
const BLOCK_SEGWIT: usize = 481_824;

/// Validate block size and weight.
/// Blocks before Segwit upgrade have a limit of 1,000,000 bytes.
/// Blocks after Segwit upgrade have a limit of 4,000,000 weight units.
pub fn validate_block_size(block_height: usize, size: u32, weight: usize) -> Result<(), ByteArray> {
    if block_height < BLOCK_SEGWIT {
        if (size > MAX_BLOCK_WEIGHT_LEGACY) {
            return Result::Err(
                format!(
                    "[validate_weight] block weight {weight} exceeds the limit {MAX_BLOCK_WEIGHT_LEGACY} for legacy blocks"
                )
            );
        }
    } else {
        if (weight > MAX_BLOCK_WEIGHT) {
            return Result::Err(
                format!(
                    "[validate_weight] block weight {weight} exceeds the limit {MAX_BLOCK_WEIGHT} for segwit blocks"
                )
            );
        }
    }
    Result::Ok(())
}

/// Validates transactions and aggregates:
///  - Total fee
///  - TXID merkle root
///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)
pub fn compute_validate_tx_data(
    txs: Span<Transaction>, block_height: u32, block_time: u32
) -> Result<(u64, Hash, Hash), ByteArray> {
    let mut txids: Array<Hash> = array![];
    let mut wtxids: Array<Hash> = array![];
    let mut total_fee = 0;
    let mut total_size: u32 = 0;
    let mut total_weight: u32 = 0;
    let mut i = 0;

    let validate_transactions: Result<(), ByteArray> = loop {
        if i >= txs.len() {
            break Result::Ok(());
        }
        let tx = txs[i];

        // Initiate data encoded
        let (version_encoded, version_size) = tx.version.encode();
        let (inputs_encoded, inputs_size) = tx.inputs.encode();
        let (outputs_encoded, outputs_size) = tx.outputs.encode();
        let (lock_time_encoded, lock_time_size) = tx.lock_time.encode();
        let mut witness_encoded: ByteArray = Default::default();
        let mut witness_size: usize = 0;
        if (*tx.is_segwit) {
            for txin in *tx
                .inputs {
                    let (witness, witness_txin_size) = txin.witness.encode();
                    witness_size += witness_txin_size;
                    witness_encoded.append(@witness);
                };
        }

        /// Compute transaction TXID
        /// https://learnmeabitcoin.com/technical/transaction/input/txid/
        ///
        /// NOTE: marker, flag, and witness fields in segwit transactions are not included
        /// this means txid computation is the same for legacy and segwit tx
        let mut txid_data: ByteArray = Default::default();
        txid_data.append(@version_encoded);
        txid_data.append(@inputs_encoded);
        txid_data.append(@outputs_encoded);
        txid_data.append(@lock_time_encoded);
        let txid = double_sha256_byte_array(@(txid_data));
        txids.append(txid);

        // TODO: only do that for blocks after Segwit upgrade
        /// Compute transaction wTXID
        ///
        /// https://learnmeabitcoin.com/technical/transaction/wtxid/
        let mut wtxid_data: ByteArray = Default::default();
        wtxid_data.append(@version_encoded);
        if (*tx.is_segwit) {
            wtxid_data.append_byte(0);
            wtxid_data.append_byte(1);
        }
        wtxid_data.append(@inputs_encoded);
        wtxid_data.append(@outputs_encoded);
        if (*tx.is_segwit) {
            wtxid_data.append(@witness_encoded);
        }
        wtxid_data.append(@lock_time_encoded);
        let wtxid = double_sha256_byte_array(@(wtxid_data));
        wtxids.append(wtxid);

        // Compute transaction weight
        // let base_size: u32 = version_size + inputs_size + outputs_size + lock_time_size;
        // if (*tx.is_segwit) {
        //     // 2 = marker +flag byte size
        //     witness_size += 2;
        // }
        // let total_size = base_size + witness_size;
        // let total_weight = base_size * 4 + witness_size;

        /// Compute transaction weight
        ///
        /// https://learnmeabitcoin.com/technical/transaction/size/
        let base_size: u32 = version_size + inputs_size + outputs_size + lock_time_size;
        // total_size += base_size;

        if (*tx.is_segwit) {
            // 2 = marker +flag byte size
            witness_size += 2;
        }
        total_size += base_size + witness_size;
        total_weight += base_size * 4 + witness_size;

        // skipping the coinbase transaction
        if (i != 0) {
            let fee = match validate_transaction(tx, block_height, block_time) {
                Result::Ok(fee) => fee,
                Result::Err(err) => { break Result::Err(err); }
            };
            total_fee += fee;
        }
        i += 1;
    };
    validate_transactions?;
    validate_block_size(block_height, total_size, total_weight)?;

    Result::Ok((total_fee, merkle_root(ref txids), merkle_root(ref wtxids)))
}

#[cfg(test)]
mod tests {
    use crate::utils::hex::{from_hex, hex_to_hash_rev};
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
    use super::{Encode,};

    fn mock_compute_txdata(tx: @Transaction) -> (ByteArray, ByteArray, u32, u32) {
        // Initiate data encoded
        let (version_encoded, version_size) = tx.version.encode();
        let (inputs_encoded, inputs_size) = tx.inputs.encode();
        let (outputs_encoded, outputs_size) = tx.outputs.encode();
        let (lock_time_encoded, lock_time_size) = tx.lock_time.encode();
        let mut witness_encoded: ByteArray = Default::default();
        let mut witness_size: usize = 0;
        if (*tx.is_segwit) {
            for txin in *tx
                .inputs {
                    let (witness, witness_txin_size) = txin.witness.encode();
                    witness_size += witness_txin_size;
                    witness_encoded.append(@witness);
                };
        }

        /// Compute transaction TXID
        let mut txid_data: ByteArray = Default::default();
        txid_data.append(@version_encoded);
        txid_data.append(@inputs_encoded);
        txid_data.append(@outputs_encoded);
        txid_data.append(@lock_time_encoded);

        /// Compute transaction wTXID
        let mut wtxid_data: ByteArray = Default::default();
        wtxid_data.append(@version_encoded);
        if (*tx.is_segwit) {
            wtxid_data.append_byte(0);
            wtxid_data.append_byte(1);
        }
        wtxid_data.append(@inputs_encoded);
        wtxid_data.append(@outputs_encoded);
        if (*tx.is_segwit) {
            wtxid_data.append(@witness_encoded);
        }
        wtxid_data.append(@lock_time_encoded);

        /// Compute transaction weight
        let base_size: u32 = version_size + inputs_size + outputs_size + lock_time_size;
        if (*tx.is_segwit) {
            // 2 = marker +flag byte size
            witness_size += 2;
        }
        let total_size = base_size + witness_size;
        let total_weight = base_size * 4 + witness_size;

        (txid_data, wtxid_data, total_size, total_weight)
    }

    #[test]
    fn test_encode_tx1() {
        // tx 4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33
        let tx = @Transaction {
            version: 1_u32,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "493046022100838b5bd094d57898d359569af330312e2dd99f8a1db7add92dc1704808625dbf022100978160771ea1e3ffe014e1fa7559f0bb5ffd32f6b63f19225bf3be110c2f2d65014104c273b18442afb2263698a09da205bb7a18f23037f9c285fc789874fe012ac32b40a18f12191a0015f2506b5a395d9845005b90a34a813715e9cc5dbf8024ca18"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "b8a75476112bb2322af0331646100fe44f26fee85f452001589f6d9672b763a7"
                        ),
                        vout: 0_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                },
                TxIn {
                    script: @from_hex(
                        "48304502200b2ff9ed1689c9403b4bf0aca89fa4a53004c2c6ad66b4df25ae8361eef172cc022100c8f5fcd4eeb02762d9b40de1013ad7283042585caec8e60be873689de8e29a4a014104cdadb5199b0d9d356ae03fbf891f28d761547d79a0c5dae24998fa84a147e39f27ce03cd8efd8bd27e9dffc78744d66b2942b76801f79ae4028028e7122a3bb1"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "a7ed5e908fa1951c912fd39cd72a37410ca78fc75de65180b8568a622f4e3a97"
                        ),
                        vout: 1_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                },
                TxIn {
                    script: @from_hex(
                        "493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "66ce602f26ae00d128ea83e5afddf8c1cd226b7148322bb090779199f63f9ff5"
                        ),
                        vout: 1_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 1050000_u64,
                    pk_script: @from_hex("76a914bafe7b8f25824ff18f698d2878d50c6fc43dd1d088ac"),
                    cached: false,
                },
                TxOut {
                    value: 111950000_u64,
                    pk_script: @from_hex("76a914ef48d8584b96d95992a664d524e52007b036754188ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(tx);
        let tx_encoded_expect = from_hex(
            "0100000003a763b772966d9f580120455fe8fe264fe40f10461633f02a32b22b117654a7b8000000008c493046022100838b5bd094d57898d359569af330312e2dd99f8a1db7add92dc1704808625dbf022100978160771ea1e3ffe014e1fa7559f0bb5ffd32f6b63f19225bf3be110c2f2d65014104c273b18442afb2263698a09da205bb7a18f23037f9c285fc789874fe012ac32b40a18f12191a0015f2506b5a395d9845005b90a34a813715e9cc5dbf8024ca18ffffffff973a4e2f628a56b88051e65dc78fa70c41372ad79cd32f911c95a18f905eeda7010000008b48304502200b2ff9ed1689c9403b4bf0aca89fa4a53004c2c6ad66b4df25ae8361eef172cc022100c8f5fcd4eeb02762d9b40de1013ad7283042585caec8e60be873689de8e29a4a014104cdadb5199b0d9d356ae03fbf891f28d761547d79a0c5dae24998fa84a147e39f27ce03cd8efd8bd27e9dffc78744d66b2942b76801f79ae4028028e7122a3bb1fffffffff59f3ff699917790b02b3248716b22cdc1f8ddafe583ea28d100ae262f60ce66010000008c493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028ffffffff0290051000000000001976a914bafe7b8f25824ff18f698d2878d50c6fc43dd1d088acb038ac06000000001976a914ef48d8584b96d95992a664d524e52007b036754188ac00000000"
        );
        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, tx_encoded_expect);
        assert_eq!(size, 620);
        assert_eq!(weight, 2480);
    }

    #[test]
    fn test_encode_tx_many_inputs() {
        // tx 23d5c86600b72cd512aecebd68a7274f611cd96eb9106125f4ef2502f54effa5
        let tx = @Transaction {
            version: 1,
            is_segwit: false,
            lock_time: 0,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "493046022100ebbd4f6b412cafa26c6484ec9a16704177964f2570f0867de633cb3f3b48f3520221008211917fee214c506686a7bba3414b9cbbc33769c06ce49f29197ac863c8bee1014104b13bab6066a13e3d672a0b11447659f1986888c9e5cbf9ee6c57283ccf5662c5eeeefc02ad3c38141b6872ab46429f784802892dea1306c909754b3fcb1f1d0c"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "cf37895a05d18f4f3fa0a7fb1b4e74763fc9d287d929b5ae1a7cec789f28fd07"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 62000000_u64,
                            pk_script: @from_hex(
                                "76a9142ae88d06a952e6acc52310dcb59e55fd1686862088ac"
                            ),
                            cached: false,
                        },
                        block_height: 149994_u32,
                        block_time: 1319114701_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "483045022100b61a58bc0a99fe55445a44f9a77b2a97a946283f34db3b26fcae24ea8750b6cc02204faf7572c8504b129a699250fdb90f9524a875052a49fb464bcc381f9a1a31af0141045327413c7cec34e5b3cee5e186221ffaab3e808bc9564cf8f110ee9bf4c270a6df410d98705867220e4cbfdde4a42e27288171416935655667c48a3acba08c25"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "e69026f2413fffc021cd3e3018f7eaeda4db0ad11c8b80c61f4fd77df0265bde"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 26900000_u64,
                            pk_script: @from_hex(
                                "76a9143f29bb456435e26b45b195e865d102ee90301ace88ac"
                            ),
                            cached: false,
                        },
                        block_height: 150006_u32,
                        block_time: 1319124571_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "483045022100f3fe3bb13a02d226c7876f5f20618e4752e65fdb52fed9558bc280f1196dc6d202205c8bae389dd40524bbd6b890c989b32f476ba8a555ff052c00e469fcf18100730141041dd42c00f540555c3785748f9acacff422ec8c403f080f16a12b69681a8cf3d4ddd0f7b767b60a9ce2809c52b7f2e3100cf82857eb597226a4281ebd99fec983"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "116ffc273e21fa84f92738b059aa2f895fc34963724decdee8600d4d49b2ea75"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 501999999_u64,
                            pk_script: @from_hex(
                                "76a91424ae3a8e9b07f92f0eeb8fc47809b20c3cca41d388ac"
                            ),
                            cached: false,
                        },
                        block_height: 150005_u32,
                        block_time: 1319122014_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "48304502203edc1344854875d946fa88991249e043e112e2a4716c6758658e4053d96d13d5022100c6388938893200b95c6f0ff718cb875df01b25aead54e6bcaf15ecc4f22bfdd10141047ce313f56017f2b0bf12619a4b3d06ea3926b68b005c6f4b77d05711bc750bc423f22c5bd639265a699f24483d56566efdf86941fda31f741da8e73aa75674a6"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "a6f7299d3b1412921b3a2335b345c96462421b37b4c0d519c66a591027d4b44c"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 1226409352_u64,
                            pk_script: @from_hex(
                                "76a9142ac56f52fa8217b501e471db987140da7534509d88ac"
                            ),
                            cached: false,
                        },
                        block_height: 149935_u32,
                        block_time: 1319066844_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "483045022031e8a1071c3ffb7642156ef6b23db33f8fb74034ed365f161f87721e2267bdc3022100b3b64ecba04459f7b378ad569315e3750eee1debe9520e54b4cd84c49115e586014104ee1a3b5815a9b2f641f013e6ad0b45b297093ef2e61754f6513cb9d565fe90f57488452cf8d467ce429344b53177d53903d9cd20ac56c7bb94b9932c0fc44873"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "9e5a36dc05bbe1f0c8006293b73d983cdcc24e84d4d88dd1d91cb5bb93fefa0f"
                        ),
                        vout: 0_u32,
                        data: TxOut {
                            value: 2507265606_u64,
                            pk_script: @from_hex(
                                "76a914685dd14a99d59e85413a7786b55574de0aca508b88ac"
                            ),
                            cached: false,
                        },
                        block_height: 149940_u32,
                        block_time: 1319069371_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "49304602210097542b50d8c59dc36103409bbe8a3b127b71ef54cde7cc6b86dfb347b5fc2593022100b0feb2951ea9bd21e70d382513bb5230ea598ba1ad27b16ace79731e286aef42014104190af8345785f062b8f91730c5f1aa0527a540859c2d5bbf8b0e15553c6c596308fb02a4c617baaa81ef970bbb6b5267ecdac860a89a5c84f55c6cc0c242b197"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "10ee2df74adce2d1727194e0cc1c0006978a38225d9068ea86dae6603cbdc26a"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 568878428_u64,
                            pk_script: @from_hex(
                                "76a9146dc21dd3563ce54c0da31174d05f3492af934c1e88ac"
                            ),
                            cached: false,
                        },
                        block_height: 149895_u32,
                        block_time: 1319035283_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "4830450220788dfeb9abbbee831f80fa96421e215ee1d7cf173492fd064756fc881f6b9a2d022100a20ce16d007ca199674cadff4b29c0da7c644efb3e8238045d37848e9d45d7c3014104afdd6ae6cc3df689e7e9bced930cdac7fc7099da002d0fe6ad376dc69159664bb2ef4de657b1f96eeb4f5bd80a0b2f01fcd7fe8dd0eb8d7539c2e985d87ef18f"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "ce8f4c5729351528ee52ee56d4bc85269cbc173b40ee04882e8fc66ce15fd80b"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 497295999_u64,
                            pk_script: @from_hex(
                                "76a91430abfd2f1003084643240c3fa453886db43ea59888ac"
                            ),
                            cached: false,
                        },
                        block_height: 149814_u32,
                        block_time: 1318990721_u32,
                    },
                },
                TxIn {
                    script: @from_hex(
                        "483045022100d08ff8ae18a308718e58955525e57f5482409769b72366c04657c5687a15947802206c77aa5472d324921a3bc58821dd0debc1fb41674fe45ae19bd655be6e6b867a0141042825c68ba0a68b07c64afd202f5eefd7cf587ded6a1b80b16606d27157634642e01ecc67e6f072e5feadfd23a9a4222407e3a10068f8745b1296fa905e80c091"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "5d22c46efffbba9d1e0e8b2e94b0933a4e71e2e2ed3ab642ea8eba957cb036c9"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 4756000000_u64,
                            pk_script: @from_hex(
                                "76a91419b159563b79c8b0bf041de7b04d56bc099c3aa288ac"
                            ),
                            cached: false,
                        },
                        block_height: 149984_u32,
                        block_time: 1319104909_u32,
                    },
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 10000000000_u64,
                    pk_script: @from_hex("76a914552362dca64805372f3a1c1bfbe190bd148569a188ac"),
                    cached: false,
                },
                TxOut {
                    value: 146749386_u64,
                    pk_script: @from_hex("76a9140b0a49a0f4db52c7aa4cc913cebc49b26500d78288ac"),
                    cached: false,
                },
            ]
                .span(),
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(tx);
        let tx_encoded_expect = from_hex(
            "010000000807fd289f78ec7c1aaeb529d987d2c93f76744e1bfba7a03f4f8fd1055a8937cf010000008c493046022100ebbd4f6b412cafa26c6484ec9a16704177964f2570f0867de633cb3f3b48f3520221008211917fee214c506686a7bba3414b9cbbc33769c06ce49f29197ac863c8bee1014104b13bab6066a13e3d672a0b11447659f1986888c9e5cbf9ee6c57283ccf5662c5eeeefc02ad3c38141b6872ab46429f784802892dea1306c909754b3fcb1f1d0cffffffffde5b26f07dd74f1fc6808b1cd10adba4edeaf718303ecd21c0ff3f41f22690e6010000008b483045022100b61a58bc0a99fe55445a44f9a77b2a97a946283f34db3b26fcae24ea8750b6cc02204faf7572c8504b129a699250fdb90f9524a875052a49fb464bcc381f9a1a31af0141045327413c7cec34e5b3cee5e186221ffaab3e808bc9564cf8f110ee9bf4c270a6df410d98705867220e4cbfdde4a42e27288171416935655667c48a3acba08c25ffffffff75eab2494d0d60e8deec4d726349c35f892faa59b03827f984fa213e27fc6f11010000008b483045022100f3fe3bb13a02d226c7876f5f20618e4752e65fdb52fed9558bc280f1196dc6d202205c8bae389dd40524bbd6b890c989b32f476ba8a555ff052c00e469fcf18100730141041dd42c00f540555c3785748f9acacff422ec8c403f080f16a12b69681a8cf3d4ddd0f7b767b60a9ce2809c52b7f2e3100cf82857eb597226a4281ebd99fec983ffffffff4cb4d42710596ac619d5c0b4371b426264c945b335233a1b9212143b9d29f7a6010000008b48304502203edc1344854875d946fa88991249e043e112e2a4716c6758658e4053d96d13d5022100c6388938893200b95c6f0ff718cb875df01b25aead54e6bcaf15ecc4f22bfdd10141047ce313f56017f2b0bf12619a4b3d06ea3926b68b005c6f4b77d05711bc750bc423f22c5bd639265a699f24483d56566efdf86941fda31f741da8e73aa75674a6ffffffff0ffafe93bbb51cd9d18dd8d4844ec2dc3c983db7936200c8f0e1bb05dc365a9e000000008b483045022031e8a1071c3ffb7642156ef6b23db33f8fb74034ed365f161f87721e2267bdc3022100b3b64ecba04459f7b378ad569315e3750eee1debe9520e54b4cd84c49115e586014104ee1a3b5815a9b2f641f013e6ad0b45b297093ef2e61754f6513cb9d565fe90f57488452cf8d467ce429344b53177d53903d9cd20ac56c7bb94b9932c0fc44873ffffffff6ac2bd3c60e6da86ea68905d22388a9706001ccce0947172d1e2dc4af72dee10010000008c49304602210097542b50d8c59dc36103409bbe8a3b127b71ef54cde7cc6b86dfb347b5fc2593022100b0feb2951ea9bd21e70d382513bb5230ea598ba1ad27b16ace79731e286aef42014104190af8345785f062b8f91730c5f1aa0527a540859c2d5bbf8b0e15553c6c596308fb02a4c617baaa81ef970bbb6b5267ecdac860a89a5c84f55c6cc0c242b197ffffffff0bd85fe16cc68f2e8804ee403b17bc9c2685bcd456ee52ee28153529574c8fce010000008b4830450220788dfeb9abbbee831f80fa96421e215ee1d7cf173492fd064756fc881f6b9a2d022100a20ce16d007ca199674cadff4b29c0da7c644efb3e8238045d37848e9d45d7c3014104afdd6ae6cc3df689e7e9bced930cdac7fc7099da002d0fe6ad376dc69159664bb2ef4de657b1f96eeb4f5bd80a0b2f01fcd7fe8dd0eb8d7539c2e985d87ef18fffffffffc936b07c95ba8eea42b63aede2e2714e3a93b0942e8b0e1e9dbafbff6ec4225d010000008b483045022100d08ff8ae18a308718e58955525e57f5482409769b72366c04657c5687a15947802206c77aa5472d324921a3bc58821dd0debc1fb41674fe45ae19bd655be6e6b867a0141042825c68ba0a68b07c64afd202f5eefd7cf587ded6a1b80b16606d27157634642e01ecc67e6f072e5feadfd23a9a4222407e3a10068f8745b1296fa905e80c091ffffffff0200e40b54020000001976a914552362dca64805372f3a1c1bfbe190bd148569a188acca37bf08000000001976a9140b0a49a0f4db52c7aa4cc913cebc49b26500d78288ac00000000"
        );

        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, tx_encoded_expect);
        assert_eq!(size, 1520);
        assert_eq!(weight, 6080);
    }

    #[test]
    fn test_encode_tx_many_outputs() {
        // tx 3e6cc776f588a464c98e8f701cdcde651c7b3620c44c65099fb3d2f4d8ea260e
        let tx = @Transaction {
            version: 1,
            is_segwit: false,
            lock_time: 0,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "47304402203c31af8b4ad8e035aac5a7b2bcda81c26a5a2ce791df00bbf207aabceff246410220545e269decc8c777beccda949118028a9fa3a2a5452414ee3ff21068db18fcab0141047a38fd20560d9e258b11bf6d71fec9f049a4786d0374bc858317848ad32970337ab61ae3bd3c0296d7dce49d7ad0fb46ba0f0743960ea3324a57699a997e5ad9"
                    ),
                    sequence: 4294967295,
                    witness: array![].span(),
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "027f3d5cda9b0e8c45654d603d1ce2babbbbeb1198378804de654f253ea7531d"
                        ),
                        vout: 1_u32,
                        data: TxOut {
                            value: 8010539842_u64,
                            pk_script: @from_hex(
                                "76a9146e9470910291611d311ab76b89a878fead10594788ac"
                            ),
                            cached: false,
                        },
                        block_height: 206120_u32,
                        block_time: 1351856022_u32,
                    },
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b6716309948fa3b07b0a6b66804fdfd6873188ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b670791f9256bffc898f474271c22f4bb94988ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b6703d3f56427bfcfd372f952d50d04b64bd88ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66ffe49df7fce684df16c62f59dc9adbd3f88ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66fc9e59a7b4554cf2e6094032cd9ee45c488ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66fd59a34755c37a8f701f43e937cdbeb1388ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66fb6c0e253f24c74d3ed972ff447ca285c88ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66f8567c6e527fc89b4d664069d20b0969388ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66f6d8af8b3e984e5d807c0e1dd6964796288ac"),
                    cached: false,
                },
                TxOut {
                    value: 100000000_u64,
                    pk_script: @from_hex("76a91406f1b66f5a691ff3169702d615b77d0af1451e7788ac"),
                    cached: false,
                },
                TxOut {
                    value: 5000000_u64,
                    pk_script: @from_hex("76a91406f1b66e25393fabd2b23a237e4bdfd4c2c35fac88ac"),
                    cached: false,
                },
                TxOut {
                    value: 7005439842_u64,
                    pk_script: @from_hex("76a9146e9470910291611d311ab76b89a878fead10594788ac"),
                    cached: false,
                },
            ]
                .span(),
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(tx);
        let tx_encoded_expect = from_hex(
            "01000000011d53a73e254f65de0488379811ebbbbbbae21c3d604d65458c0e9bda5c3d7f02010000008a47304402203c31af8b4ad8e035aac5a7b2bcda81c26a5a2ce791df00bbf207aabceff246410220545e269decc8c777beccda949118028a9fa3a2a5452414ee3ff21068db18fcab0141047a38fd20560d9e258b11bf6d71fec9f049a4786d0374bc858317848ad32970337ab61ae3bd3c0296d7dce49d7ad0fb46ba0f0743960ea3324a57699a997e5ad9ffffffff0c00e1f505000000001976a91406f1b6716309948fa3b07b0a6b66804fdfd6873188ac00e1f505000000001976a91406f1b670791f9256bffc898f474271c22f4bb94988ac00e1f505000000001976a91406f1b6703d3f56427bfcfd372f952d50d04b64bd88ac00e1f505000000001976a91406f1b66ffe49df7fce684df16c62f59dc9adbd3f88ac00e1f505000000001976a91406f1b66fc9e59a7b4554cf2e6094032cd9ee45c488ac00e1f505000000001976a91406f1b66fd59a34755c37a8f701f43e937cdbeb1388ac00e1f505000000001976a91406f1b66fb6c0e253f24c74d3ed972ff447ca285c88ac00e1f505000000001976a91406f1b66f8567c6e527fc89b4d664069d20b0969388ac00e1f505000000001976a91406f1b66f6d8af8b3e984e5d807c0e1dd6964796288ac00e1f505000000001976a91406f1b66f5a691ff3169702d615b77d0af1451e7788ac404b4c00000000001976a91406f1b66e25393fabd2b23a237e4bdfd4c2c35fac88ac62878ea1010000001976a9146e9470910291611d311ab76b89a878fead10594788ac00000000"
        );

        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, tx_encoded_expect);
        assert_eq!(size, 597);
        assert_eq!(weight, 2388);
    }

    #[test]
    fn test_encode_tx_witness1() {
        // tx 65d8bd45f01bd6209d8695d126ba6bb4f2936501c12b9a1ddc9e38600d35aaa2
        let tx = Transaction {
            version: 2,
            is_segwit: true,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffd,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "39cc1562b197182429bc1ea312c9e30f1257be6d5159fcd7b375139d3c3fe63c"
                        ),
                        vout: 0x0,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![
                        from_hex(
                            "30440220537f470c1a18dc1a9d233c0b6af1d2ce18a07f3b244e4d9d54e0e60c34c55e67022058169cd11ac42374cda217d6e28143abd0e79549f7b84acc6542817466dc9b3001"
                        ),
                        from_hex(
                            "0301c1768b48843933bd7f0e8782716e8439fc44723d3745feefde2d57b761f503"
                        )
                    ]
                        .span(),
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 102415_u64,
                    pk_script: @from_hex("76a914998db5e1126bc3a5e04109fbf253a7900462410e88ac"),
                    cached: false,
                },
                TxOut {
                    value: 1424857_u64,
                    pk_script: @from_hex("0014579bf4f06510c8683f2451262b6685b00012e46f"),
                    cached: false,
                },
            ]
                .span(),
            lock_time: 679999,
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(@tx);
        let tx_encoded_expect = from_hex(
            "02000000013ce63f3c9d1375b3d7fc59516dbe57120fe3c912a31ebc29241897b16215cc390000000000fdffffff020f900100000000001976a914998db5e1126bc3a5e04109fbf253a7900462410e88acd9bd150000000000160014579bf4f06510c8683f2451262b6685b00012e46f3f600a00"
        );
        let wtx_encoded_expect = from_hex(
            "020000000001013ce63f3c9d1375b3d7fc59516dbe57120fe3c912a31ebc29241897b16215cc390000000000fdffffff020f900100000000001976a914998db5e1126bc3a5e04109fbf253a7900462410e88acd9bd150000000000160014579bf4f06510c8683f2451262b6685b00012e46f024730440220537f470c1a18dc1a9d233c0b6af1d2ce18a07f3b244e4d9d54e0e60c34c55e67022058169cd11ac42374cda217d6e28143abd0e79549f7b84acc6542817466dc9b3001210301c1768b48843933bd7f0e8782716e8439fc44723d3745feefde2d57b761f5033f600a00"
        );

        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, wtx_encoded_expect);
        assert_eq!(size, 225);
        assert_eq!(weight, 573);
    }

    #[test]
    fn test_encode_tx_witness2() {
        // tx 7ee8997b455d8231c162277943a9a2d2d98800faa51da79c17eeb5156739a628,
        let tx = Transaction {
            version: 2,
            is_segwit: true,
            lock_time: 0,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "db2448ca5ab8fa4243cb0b3256fb0a629d8e42f9be1056bf1177c9d1be9f996f"
                        ),
                        vout: 0_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![
                        from_hex(
                            "3045022100e79c80ee315b6ef4e29f9bd5776b14d50c2c23a378cde2407b8adc907352ecf902200a4b2d2b5db31883e78e84f5d81f0fcc7e5fa54c5a0dc98335cd58efed3c4f1901"
                        ),
                        from_hex(
                            "03e5d541eed7ccea6f94324bdcce27427c0e20b626bb9f2d2cbe2e81f22ae4aafa"
                        ),
                    ]
                        .span(),
                },
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "1c3f37e7b248c24e17c69202c22f78f027be62e0bcea1a91c664df467c4d2d7b"
                        ),
                        vout: 1_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![
                        from_hex(
                            "3044022065bb4676eb5bebb69241ebdd121dbef5d8e468e7b0af96576d62a38be7af83b70220604dacc80a67fd0511da9cfaeeb72b0ab58c255e712a209325902f50e60ad0bb01"
                        ),
                        from_hex(
                            "03e5d541eed7ccea6f94324bdcce27427c0e20b626bb9f2d2cbe2e81f22ae4aafa"
                        ),
                    ]
                        .span(),
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 326268_u64,
                    pk_script: @from_hex("00148812478461956e68872e7f3e8782d5ecb58b9ec1"),
                    cached: false,
                },
                TxOut {
                    value: 86868_u64,
                    pk_script: @from_hex("0014857f3f59abc3998e771f07d8f06d3ec6eb5d2da2"),
                    cached: false,
                },
            ]
                .span(),
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(@tx);
        let tx_encoded_expect = from_hex(
            "02000000026f999fbed1c97711bf5610bef9428e9d620afb56320bcb4342fab85aca4824db0000000000ffffffff7b2d4d7c46df64c6911aeabce062be27f0782fc20292c6174ec248b2e7373f1c0100000000ffffffff027cfa0400000000001600148812478461956e68872e7f3e8782d5ecb58b9ec15453010000000000160014857f3f59abc3998e771f07d8f06d3ec6eb5d2da200000000"
        );
        let wtx_encoded_expect = from_hex(
            "020000000001026f999fbed1c97711bf5610bef9428e9d620afb56320bcb4342fab85aca4824db0000000000ffffffff7b2d4d7c46df64c6911aeabce062be27f0782fc20292c6174ec248b2e7373f1c0100000000ffffffff027cfa0400000000001600148812478461956e68872e7f3e8782d5ecb58b9ec15453010000000000160014857f3f59abc3998e771f07d8f06d3ec6eb5d2da202483045022100e79c80ee315b6ef4e29f9bd5776b14d50c2c23a378cde2407b8adc907352ecf902200a4b2d2b5db31883e78e84f5d81f0fcc7e5fa54c5a0dc98335cd58efed3c4f19012103e5d541eed7ccea6f94324bdcce27427c0e20b626bb9f2d2cbe2e81f22ae4aafa02473044022065bb4676eb5bebb69241ebdd121dbef5d8e468e7b0af96576d62a38be7af83b70220604dacc80a67fd0511da9cfaeeb72b0ab58c255e712a209325902f50e60ad0bb012103e5d541eed7ccea6f94324bdcce27427c0e20b626bb9f2d2cbe2e81f22ae4aafa00000000"
        );

        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, wtx_encoded_expect);
        assert_eq!(size, 371);
        assert_eq!(weight, 833);
    }
    #[test]
    fn test_encode_tx_witness3() {
        /// tx c06aaaa2753dc4e74dd4fe817522dc3c126fd71792dd9acfefdaff11f8ff954d
        /// data from example https://learnmeabitcoin.com/technical/transaction/wtxid/
        let tx = Transaction {
            version: 1,
            is_segwit: true,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffd,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "89d8ddef7821789e8ea407ebfe3dd290be403d5fa9174acc544d414eb2fd8a43"
                        ),
                        vout: 1,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![
                        from_hex(
                            "30440220200254b765f25126334b8de16ee4badf57315c047243942340c16cffd9b11196022074a9476633f093f229456ad904a9d97e26c271fc4f01d0501dec008e4aae71c201"
                        ),
                        from_hex(
                            "02c37a3c5b21a5991d3d7b1e203be195be07104a1a19e5c2ed82329a56b4312130"
                        )
                    ]
                        .span(),
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 10926349_u64,
                    pk_script: @from_hex("0014b549d227c9edd758288112fe3573c1f852401668"),
                    cached: false,
                },
                TxOut {
                    value: 18000000_u64,
                    pk_script: @from_hex("76a914ae28f233464e6da03c052155119a413d13f3380188ac"),
                    cached: false,
                },
            ]
                .span(),
            lock_time: 0,
        };

        let (tx_encoded, wtx_encoded, size, weight) = mock_compute_txdata(@tx);
        let tx_encoded_expect = from_hex(
            "0100000001438afdb24e414d54cc4a17a95f3d40be90d23dfeeb07a48e9e782178efddd8890100000000fdffffff020db9a60000000000160014b549d227c9edd758288112fe3573c1f85240166880a81201000000001976a914ae28f233464e6da03c052155119a413d13f3380188ac00000000"
        );
        let wtx_encoded_expect = from_hex(
            "01000000000101438afdb24e414d54cc4a17a95f3d40be90d23dfeeb07a48e9e782178efddd8890100000000fdffffff020db9a60000000000160014b549d227c9edd758288112fe3573c1f85240166880a81201000000001976a914ae28f233464e6da03c052155119a413d13f3380188ac024730440220200254b765f25126334b8de16ee4badf57315c047243942340c16cffd9b11196022074a9476633f093f229456ad904a9d97e26c271fc4f01d0501dec008e4aae71c2012102c37a3c5b21a5991d3d7b1e203be195be07104a1a19e5c2ed82329a56b431213000000000"
        );

        assert_eq!(tx_encoded, tx_encoded_expect);
        assert_eq!(wtx_encoded, wtx_encoded_expect);
        assert_eq!(size, 225);
        assert_eq!(weight, 573);
    }
}
