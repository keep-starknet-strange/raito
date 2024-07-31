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
    let chain_state = ChainState {
        block_height: 0,
        total_work: 0,
        best_block_hash: "",
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
