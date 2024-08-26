/// Raito program entrypoint.
///
/// Terminates with success only if:
///     - The initial chain state is legit (it is genesis or a valid recursive proof provided)
///     - Block(s) has been validated without errors
///
/// Returns the resulting state hash.
fn main() {
    println!("Running Raito Bitcoin ZK client");
    // TODO: create ProgramInput type contaning:
//     - chain state
//     - utreexo state
//     - proof of chain state (recursive STARK) if not genesis
//     - block(s) extended with UTXOs
//     - utreexo inclusion proof(s) for those UTXOs
//     - validation mode (header only, full blocks, full consensus)
//
// Program output would consist of:
//     - chain state
//     - utreexo state
//
// To keep the output concise we can just return hash(chain_state, utreexo_state)

    // TODO: run BlockHeaderValidator for a span of blocks
}
