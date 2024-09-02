use raito::types::chain_state::{ChainState, BlockValidator};
use super::blocks::{block_0::block_0, block_170::block_170};

#[test]
fn test_block0() {
    let block = block_0();
    let prev_chain_state: ChainState = Default::default();

    let next_chain_state = prev_chain_state.validate_and_apply(block);
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height.unwrap(), 0);
    assert_eq!(result.total_work, 4295032833);
    assert_eq!(result.prev_timestamps, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1231006505].span());
    assert_eq!(
        result.current_target, 0x00000000ffff0000000000000000000000000000000000000000000000000000
    );
    assert_eq!(result.epoch_start_time, 1231006505);
    //to impl
// assert_eq!(result.best_block_hash, 0_u256.into());
// assert_eq!(result.utreexo_state.roots, [...]);

}

#[test]
fn test_block170() {
    let block170 = block_170();
    let prev_chain_state_block169 = ChainState {
        block_height: Option::Some(169),
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
    assert_eq!(
        result.current_target, 0x00000000ffff0000000000000000000000000000000000000000000000000000
    );
    assert_eq!(result.epoch_start_time, 1231006505);
    //to impl
// assert_eq!(result.best_block_hash, 0_u256.into());
// assert_eq!(result.utreexo_state.roots, [...]);
}
