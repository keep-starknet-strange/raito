use super::blocks::block_0::block_0;
use raito::state::{ChainState, UtreexoState};
use raito::validation::{BlockValidatorImpl};

#[test]
fn test_block0() {
    let block = block_0();
    let prev_chain_state = ChainState {
        block_height: 0,
        total_work: 0,
        best_block_hash: 0_u256.into(),
        current_target: 26959535291011309493156476344723991336010898738574164086137773096960_u256,
        epoch_start_time: 1231006505,
        prev_timestamps: [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ].span(),
        utreexo_state: UtreexoState {
            roots: [
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0',
                '0'
            ].span(),
        },
        // program_hash: 71842f64de1268cdd1669c87640845003a9f15787bbcaf8eb371f6762f93eec

    };

    let next_chain_state = BlockValidatorImpl::validate_and_apply(prev_chain_state, block);
    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

    let result = next_chain_state.unwrap();
    assert_eq!(result.block_height, prev_chain_state.block_height + 1);
    assert_eq!(result.total_work, 4295032833);
    assert_eq!(result.prev_timestamps, [1231006505, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].span());
    //to impl
// assert_eq!(
//     result.best_block_hash,
//     0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f_u256.into()
// );
// assert_eq!(
//     result.current_target,
//     26959535291011309493156476344723991336010898738574164086137773096960_u256
// );
// assert_eq!(result.epoch_start_time, 1231006505);
// assert_eq!(result.utreexo_state.roots, [...]);

}

