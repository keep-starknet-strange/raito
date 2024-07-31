use raito::engine::BlockHeaderEngineTrait;
use raito::engine::BlockHeaderEngineImpl;
use raito::engine::BlockHeaderValidationContextTrait;
use raito::engine::BlockHeaderValidationContextImpl;
use raito::engine::BlockHeaderTrait;
use raito::engine::BlockHeaderImpl;
use raito::engine::ChainStateTrait;
use raito::engine::ChainStateImpl;
use raito::engine::ChainState;

fn main() {
    println!("Running Raito Bitcoin ZK client");
    let block_header = BlockHeaderImpl::new(0, "", "", 0, 0, 0);

    // The Times 03/Jan/2009 Chancellor on brink of second bailout for banks
    let GENESIS = "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";

    let chain_state = ChainState {
        block_height: 0,
        total_work: 0,
        best_block_hash: GENESIS,
        current_target: 0,
        epoch_start_time: 0,
        prev_timestamps: ArrayTrait::new()
    };

    let mut context = BlockHeaderValidationContextImpl::new(block_header, "", 0, chain_state, 0);
    let mut engine = BlockHeaderEngineImpl::new(context);

    let res = engine.validate_and_apply_block_header();
    if res.is_ok() {
        println!("Execution successful");
    } else {
        println!("Execution failed");
    }
}
