use super::blocks::block_0::block_0;
use raito::state::{ChainState, UtreexoState};
use raito::validation::{BlockValidatorImpl};
use raito::state::{Block, Header, Transaction, OutPoint, TxIn, TxOut};
use raito::test_utils::from_hex;

#[test]
fn test_block0() {
    let block = block_0();
    let prev_chain_state: ChainState = Default::default();

    let next_chain_state = BlockValidatorImpl::validate_and_apply(prev_chain_state, block);
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height.unwrap(), 0);
    assert_eq!(result.total_work, 4295032833);
    assert_eq!(result.prev_timestamps, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1231006505].span());
    //to impl
// assert_eq!(result.best_block_hash, 0_u256.into());
// assert_eq!(result.current_target, 0_u256);
// assert_eq!(result.epoch_start_time, 0);
// assert_eq!(result.utreexo_state.roots, [...]);

}

#[test]
fn test_block170() {
    let block170 = block_170_patched();
    let prev_chain_state_block169 = ChainState {
        block_height: Option::Some(169),
        total_work: 0,
        best_block_hash: 0_u256.into(),
        current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
        epoch_start_time: 0,
        prev_timestamps: [
            1231702618,
            1231703466,
            1231704197,
            1231704464,
            1231714917,
            1231715347,
            1231716245,
            1231716329,
            1231716711,
            1231717181,
            1231730523
        ].span(), utreexo_state: Default::default(),
        // program_hash: 71842f64de1268cdd1669c87640845003a9f15787bbcaf8eb371f6762f93eec
    };

    let next_chain_state = BlockValidatorImpl::validate_and_apply(
        prev_chain_state_block169, block170
    );
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height.unwrap(), 170);
    // assert_eq!(result.total_work, ?);
    assert_eq!(
        result.prev_timestamps,
        [
            1231703466,
            1231704197,
            1231704464,
            1231714917,
            1231715347,
            1231716245,
            1231716329,
            1231716711,
            1231717181,
            1231730523,
            1231731025
        ].span()
    );
    // //to impl
// assert_eq!(result.best_block_hash, 0_u256.into());
// assert_eq!(result.current_target, 0_u256);
// assert_eq!(result.epoch_start_time, 0);
// assert_eq!(result.utreexo_state.roots, [...]);
}

// Use this patched version with non-default OutPoint
pub fn block_170_patched() -> Block {
    // block hash: 00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee
    Block {
        header: Header {
            version: 1_u32, time: 1231731025_u32, bits: 0x1d00ffff_u32, nonce: 1889418792_u32
        },
        txs: array![
            Transaction {
                version: 1,
                is_segwit: false,
                inputs: array![
                    TxIn {
                        script: @from_hex("04ffff001d0102"),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0_u256.into(),
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
                        value: 5000000000_u64,
                        pk_script: @from_hex(
                            "4104d46c4968bde02899d2aa0963367c7a6ce34eec332b32e42e5f3407e052d64ac625da6f0718e7b302140434bd725706957c092db53805b821a85b23a7ac61725bac"
                        ),
                        cached: false,
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
                        script: @from_hex(
                            "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901"
                        ),
                        sequence: 4294967295,
                        previous_output: OutPoint {
                            txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                                .into(),
                            vout: 0,
                            data: TxOut { value: 5000000000_u64, ..Default::default(), },
                            block_height: Default::default(),
                            block_time: Default::default(),
                        },
                        witness: array![].span()
                    }
                ]
                    .span(),
                outputs: array![
                    TxOut {
                        value: 1000000000_u64,
                        pk_script: @from_hex(
                            "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac"
                        ),
                        cached: false,
                    },
                    TxOut {
                        value: 4000000000_u64,
                        pk_script: @from_hex(
                            "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
                        ),
                        cached: false,
                    }
                ]
                    .span(),
                lock_time: 0
            }
        ]
            .span()
    }
}
