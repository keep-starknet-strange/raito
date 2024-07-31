use raito::engine::EngineTrait;
use raito::engine::EngineTraitImpl;

fn main() {
    println!("Running Raito Bitcoin ZK client");
    let mut engine = EngineTraitImpl::new();
    let res = engine.check_consensus_rules();
    if res.is_ok() {
        println!("Execution successful");
    } else {
        println!("Execution failed");
    }
}
