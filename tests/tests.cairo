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
        current_target: 486604799,
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

    // println!("hash: {}", block.header.time);
    let next_chain_state = BlockValidatorImpl::validate_and_apply(prev_chain_state, block);

    assert!(next_chain_state.is_ok(), "Error: {:?}", next_chain_state.err());
    // match BlockValidatorImpl::validate_and_apply(prev_chain_state, block) {
//     Result::Ok(next_chain_state) => {
//         println!("result block height: {:?}", next_chain_state.block_height);
//         println!("result total work: {:?}", next_chain_state.total_work);
//     },
//     Result::Err(e) => println!("Error: {}", e),
// }
// println!("result: {:?}", next_chain_state);
// let next_chain_state = chain_state.validate_and_apply(block);

    // assertions
}

