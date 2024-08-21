use raito::state::{Block, Header, Transaction, TxIn, TxOut, OutPoint};
use raito::test_utils::from_hex;
use raito::utils::Hash;

// block_hash: 000000000000ca5e71b18c40edbf3543d52d4cbb55b942282531b978d9d08138
pub fn block_100009() -> Block {
    Block {
        header: Header {
                version: 1_u32,
                time: 1293626630_u32,
                bits: 453281356_u32,
                nonce: 2378972240_u32,
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                    TxIn {
                        script: @from_hex("044c86041b014a"),
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
                        pk_script: @from_hex("4104785e94ee05480f6aeb5b55955cc7e8e99da1e29ce73e7becf27c6976c36613ae148206e191b645eb49667feed26ec1c86877679583f98bc808098a1041e0f681ac"),
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("48304502204872f54f3f0eeb1e7fc1aa0e117df0bc94255d6042dc3f5fd899c9ce23cfbf080221009515b5764d2874d90445b2bc92791bccd166ededcd95ae065ccf09b389e46d070141040555f89aae042d0d6bd56a0e6b6dbea694d2f3e62d996bbfbb03357ef2d2e21c05ed725dbe73c0327bfb621ca2a1d1e7af65c022c1fad40f0033b27c30ff3bda"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0x05d07bb2de2bda1115409f99bf6b626d23ecb6bed810d8be263352988e4548cb_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 13826000000_u64,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 5000000_64,
                        pk_script: @from_hex("76a9145e31299838d56390e79548fb34c20c0f0e97e3d888ac"),
                    },
                    
                    TxOut {
                        value: 13821000000_64,
                        pk_script: @from_hex("76a9141083c63b6e3d9fb9d6019b85a9ae1c29209e4b5588ac"),
                    },
                    ].span(),
                },
                ].span(),
    }
}