use super::blocks::{block_0::block_0, block_170::block_170};
use raito::state::{ChainState, UtreexoState};
use raito::validation::{BlockValidatorImpl};

#[test]
fn test_block0() {
    let block = block_0();
    let prev_chain_state = ChainState {
        block_height: 0, // cannot set to -1 or u32_max
        total_work: 0,
        best_block_hash: 0_u256.into(),
        current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
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
    assert_eq!(result.prev_timestamps, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1231006505].span());
    //to impl
// assert_eq!(result.best_block_hash, 0_u256.into());
// assert_eq!(result.current_target, 0_u256);
// assert_eq!(result.epoch_start_time, 0);
// assert_eq!(result.utreexo_state.roots, [...]);

}
// need impl of TransactionValidator::txid() for UtreexoState
// #[test]
// fn test_block170() {
//     let block170 = block_170();
//     let prev_chain_state_block169 = ChainState {
//         block_height: 169,
//         total_work: 0,
//         best_block_hash: 0_u256.into(),
//         current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
//         epoch_start_time: 0,
//         prev_timestamps: [
//             1231702618,
//             1231703466,
//             1231704197,
//             1231704464,
//             1231714917,
//             1231715347,
//             1231716245,
//             1231716329,
//             1231716711,
//             1231717181,
//             1231730523
//         ].span(),
//         utreexo_state: UtreexoState {
//             roots: [
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0',
//                 '0'
//             ].span(),
//         },
//         // program_hash: 71842f64de1268cdd1669c87640845003a9f15787bbcaf8eb371f6762f93eec
//     };

//     let next_chain_state = BlockValidatorImpl::validate_and_apply(
//         prev_chain_state_block169, block170
//     );
//     assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());

//     let result = next_chain_state.unwrap();
//     assert_eq!(result.block_height, 170);
//     // assert_eq!(result.total_work, ?);
//     assert_eq!(
//         result.prev_timestamps,
//         [
//             1231703466,
//             1231704197,
//             1231704464,
//             1231714917,
//             1231715347,
//             1231716245,
//             1231716329,
//             1231716711,
//             1231717181,
//             1231730523,
//             1231731025
//         ].span()
//     );
//     // //to impl
// // assert_eq!(result.best_block_hash, 0_u256.into());
// // assert_eq!(result.current_target, 0_u256);
// // assert_eq!(result.epoch_start_time, 0);
// // assert_eq!(result.utreexo_state.roots, [...]);
// }


