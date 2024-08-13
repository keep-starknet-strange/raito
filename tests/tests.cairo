use super::blocks::block_0::block_0;

#[test]
fn test_block0() {
    let block = block_0();
    // let chain_state = initial chain state;
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

    // let next_chain_state = chain_state.validate_and_apply(block);
    // assertions

}