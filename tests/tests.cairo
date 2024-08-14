use super::blocks::block_0::block_0;
use raito::state::{ChainState, UtreexoState};
use raito::validation::{BlockValidatorImpl};

#[test]
fn test_block0() {
    let block = block_0();
    let prev_chain_state = ChainState {
        block_height: 4294967295, // max u32 for overflow to 0
        total_work: 0,
        best_block_hash: 0,
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
    };
    // let prev_chain_state = initial chain state;
    // initial state from ZeroSync
    // {
    //     "block_height" : -1,
    //     "total_work" : 0,
    //     "best_block_hash" : "0000000000000000000000000000000000000000000000000000000000000000",
    //     "current_target" : 486604799,
    //     "epoch_start_time" : 1231006505,
    //     "prev_timestamps" : [ 0,0,0,0,0, 0,0,0,0,0, 0 ],
    //     "utreexo_roots" : [
    //         "0", "0", "0", "0", "0",
    //         "0", "0", "0", "0", "0",
    //         "0", "0", "0", "0", "0",
    //         "0", "0", "0", "0", "0",
    //         "0", "0", "0", "0", "0",
    //         "0", "0"
    //     ],
    //     "program_hash": "71842f64de1268cdd1669c87640845003a9f15787bbcaf8eb371f6762f93eec"
    // }

    println!("hash: {}", block.header.time);
    let result: Result<ChainState, ByteArray> = BlockValidatorImpl::validate_and_apply(
        prev_chain_state, block
    );
    // let next_chain_state = chain_state.validate_and_apply(block);

    // assertions
}

