use raito::state::{Block, Header, Transaction, TxIn, TxOut, OutPoint};
use raito::test_utils::from_hex;
use raito::utils::Hash;

// block_hash: 000000000002dfb177c4acd494b3dd73b9abece24df11c62bb614a8c6c5665e2
pub fn block_100008() -> Block {
    Block {
        header: Header {
                version: 1_u32,
                time: 1293626246_u32,
                bits: 453281356_u32,
                nonce: 1682744067_u32,
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                    TxIn {
                        script: @from_hex("044c86041b0147"),
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
                        pk_script: @from_hex("4104ad3b4c6ee28cb0c438c87b4efe1c36e1e54c10efc690f24c2c02446def863c50e9bf482647727b415aa81b45d0f7aa42c2cb445e4d08f18b49c027b58b6b4041ac"),
                    },
                    ].span(),
                },
                
            Transaction {
                version: 1,
                is_segwit: false,
                lock_time: 0,
                inputs: array![
                        TxIn {
                            script: @from_hex("483045022100a1f2df66d173e668849694bd2c0dc77162278f34902483d55fb16631e39e37f10220157636faa19568e04f82dd477e9e6a10fefe99492a70ec23b338c633a6f28f5d014104a34f5f40605dd7d2b11a0ef3c9ab32be64318c2aa34b3a924f16ee8a9a0eabd8b7183bd8e1acb0569f3a6b4cfc912c575d0d83bc2ba7035fc59991205432479c"),
                            sequence: 4294967295,
                            witness: @from_hex("0"),
                            previous_output: 
                                OutPoint {
                                    txid: 0xcb91e3d8ea2aa0775afcc1974aaecfa8a4744cde601123b29a69f5157d3606bd_u256.into(),
                                    vout: 0_u32,
                                    txo_index: 0_u64,
                                    amount: 1000000_u64,
                                },
                        },
                        ].span(),
                outputs: array![
                    TxOut {
                        value: 1000000_64,
                        pk_script: @from_hex("76a9147d878427c2cffbbb117200ca85689269f73e7fcb88ac"),
                    },
                    ].span(),
                },
                ].span(),
    }
}