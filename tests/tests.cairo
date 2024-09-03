use raito::utils::hex::from_hex;
use raito::types::{
    chain_state::{ChainState, BlockValidator}, block::{Block, Header, TransactionData},
    transaction::{Transaction, TxIn, TxOut, OutPoint},
};
use super::blocks::{block_170::block_170};

#[test]
fn test_block1() {
    let block = Block {
        header: Header {
            version: 1_u32, time: 1231469665_u32, bits: 486604799_u32, nonce: 2573394689_u32,
        },
        data: TransactionData::Transactions(
            array![
                Transaction {
                    version: 1,
                    is_segwit: false,
                    lock_time: 0,
                    inputs: array![
                        TxIn {
                            script: @from_hex("04ffff001d0104"),
                            sequence: 0xffffffff,
                            witness: array![].span(),
                            previous_output: OutPoint {
                                txid: 0_u256.into(),
                                vout: 4294967295_u32,
                                data: Default::default(),
                                block_height: Default::default(),
                                block_time: Default::default(),
                            },
                        }
                    ]
                        .span(),
                    outputs: array![
                        TxOut {
                            value: 5000000000_u64,
                            pk_script: @from_hex(
                                "410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac"
                            ),
                            cached: false,
                        },
                    ]
                        .span(),
                },
            ]
                .span()
        )
    };
    let prev_chain_state: ChainState = Default::default();

    let next_chain_state = prev_chain_state.validate_and_apply(block);
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height, 1);
    assert_eq!(result.total_work, 8590065666);
    assert_eq!(result.prev_timestamps, [0, 0, 0, 0, 0, 0, 0, 0, 0, 1231006505, 1231469665].span());
    assert_eq!(
        result.current_target,
        0x00000000ffff0000000000000000000000000000000000000000000000000000_u256
    );
    assert_eq!(result.epoch_start_time, 1231006505);
    assert_eq!(
        result.best_block_hash,
        0x00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048_u256.into()
    );
    //to impl
// assert_eq!(result.utreexo_state.roots, [...]);

}

#[test]
fn test_block170() {
    let block170 = block_170();
    let prev_chain_state_block169 = ChainState {
        block_height: 169,
        total_work: 734450614443_u256,
        best_block_hash: 0x000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55_u256
            .into(),
        current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
        epoch_start_time: 1231006505,
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
        ].span(),
    };

    let next_chain_state = prev_chain_state_block169.validate_and_apply(block170);
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height, 170);
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
    assert_eq!(
        result.current_target, 0x00000000ffff0000000000000000000000000000000000000000000000000000
    );
    assert_eq!(result.epoch_start_time, 1231006505);
    assert_eq!(
        result.best_block_hash,
        0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee_u256.into()
    );
    //to impl
// assert_eq!(result.utreexo_state.roots, [...]);
}
