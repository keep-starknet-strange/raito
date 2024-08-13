use raito::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};
use super::super::utils::from_base16;

pub fn block_0() -> Block {
    // block hash: 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
    Block {
        header: Header {
            version: 1_u32, time: 1231006505_u32, bits: 0, // TODO
             nonce: 2083236893_u32
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                inputs: array![
                    TxIn {
                        script: from_base16(
                            "04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73"
                        ),
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
                            "4104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac"
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
