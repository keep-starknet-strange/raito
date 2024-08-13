use raito::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};
use super::super::utils::from_base16;

pub fn block_170() -> Block {
    // block hash: 00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee
    Block {
        header: Header {
            version: 1_u32, time: 1231731025_u32, bits: 0, // TODO
             nonce: 1889418792_u32
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                inputs: array![
                    TxIn {
                        script: from_base16("04ffff001d0102"),
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
                            "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
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
                            "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9,
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
                        value: 1000000000_u64,
                        pk_script: from_base16(
                            "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac"
                        ),
                    },
                    TxOut {
                        value: 4000000000_u64,
                        pk_script: from_base16(
                            "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
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
