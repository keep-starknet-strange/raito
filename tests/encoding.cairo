use raito::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};
use raito::state::{ChainState, UtreexoState};
use raito::utils::hex::from_hex;
use raito::codec::Encode;

#[test]
fn test_txout() {
    let txout = TxOut {
        value: 100000000_u64,
        pk_script: @from_hex("76a914299da5537e8b65bf45c70a9ece75988ebfca86b588ac"),
        cached: false,
    };
    let mut bytess = Default::default();
    txout.encode_to(ref bytess);
    assert_eq!(
        bytess, from_hex("00e1f505000000001976a914299da5537e8b65bf45c70a9ece75988ebfca86b588ac")
    );
}


#[test]
fn test_outpoint() {
    let outpoint = OutPoint {
        txid: 0x9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678_u256.into(),
        vout: 0xffffffff_u32,
        data: Default::default(),
        block_height: Default::default(),
        block_time: Default::default(),
    };
    let mut bytess = Default::default();
    outpoint.encode_to(ref bytess);
    assert_eq!(
        bytess, from_hex("9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678ffffffff")
    );
}


#[test]
fn test_txin() {
    let txin = TxIn {
        script: @from_hex(
            "473044022031b6a6b79c666d5568a9ac7c116cacf277e11521aebc6794e2b415ef8c87c899022001fe272499ea32e6e1f6e45eb656973fbb55252f7acc64e1e1ac70837d5b7d9f0121023dec241e4851d1ec1513a48800552bae7be155c6542629636bcaa672eee971dc"
        ),
        sequence: 4294967295,
        previous_output: OutPoint {
            txid: 0x9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678_u256.into(),
            vout: 0xffffffff_u32,
            data: Default::default(),
            block_height: Default::default(),
            block_time: Default::default(),
        },
        witness: array![].span()
    };
    let mut bytess = Default::default();
    txin.encode_to(ref bytess);
    assert_eq!(
        bytess,
        from_hex(
            "6a473044022031b6a6b79c666d5568a9ac7c116cacf277e11521aebc6794e2b415ef8c87c899022001fe272499ea32e6e1f6e45eb656973fbb55252f7acc64e1e1ac70837d5b7d9f0121023dec241e4851d1ec1513a48800552bae7be155c6542629636bcaa672eee971dcffffffff9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678ffffffff"
        )
    );
}


#[test]
fn test_txn() {
    let tx = Transaction {
        version: 2_u32,
        is_segwit: false,
        inputs: array![
            TxIn {
                script: @from_hex(
                    "473044022031b6a6b79c666d5568a9ac7c116cacf277e11521aebc6794e2b415ef8c87c899022001fe272499ea32e6e1f6e45eb656973fbb55252f7acc64e1e1ac70837d5b7d9f0121023dec241e4851d1ec1513a48800552bae7be155c6542629636bcaa672eee971dc"
                ),
                sequence: 4294967295,
                previous_output: OutPoint {
                    txid: 0x9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678_u256
                        .into(),
                    vout: 0xffffffff_u32,
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
                value: 100000000_u64,
                pk_script: @from_hex("76a914299da5537e8b65bf45c70a9ece75988ebfca86b588ac"),
                cached: false,
            }
        ]
            .span(),
        lock_time: 0
    };
    let mut bytess = Default::default();
    tx.encode_to(ref bytess);
    assert_eq!(
        bytess,
        from_hex(
            "02000000016a473044022031b6a6b79c666d5568a9ac7c116cacf277e11521aebc6794e2b415ef8c87c899022001fe272499ea32e6e1f6e45eb656973fbb55252f7acc64e1e1ac70837d5b7d9f0121023dec241e4851d1ec1513a48800552bae7be155c6542629636bcaa672eee971dcffffffff9945a5a440f2d3712ff095cb1efefada1cc52e139defedb92a313daed49d5678ffffffff0100e1f505000000001976a914299da5537e8b65bf45c70a9ece75988ebfca86b588ac00000000"
        )
    );
}
