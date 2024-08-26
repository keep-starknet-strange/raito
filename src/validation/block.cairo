//! Block validation helpers.

use raito::types::transaction::{Transaction, TransactionTrait, TxIn, TxOut, OutPoint};
use raito::types::block::{Block, BlockHash};
use raito::types::chain_state::ChainState;
use raito::utils::{hash::Hash, merkle_tree::merkle_root};
use super::transaction::validate_transaction;

/// Returns the next block height
/// If the block height is None (Genesis block), it returns 0
pub fn next_block_height(block_height: Option<u32>) -> u32 {
    match block_height {
        Option::Some(height) => height + 1,
        Option::None => 0,
    }
}

/// Validates transactions and aggregates:
///  - Total fee
///  - TXID merkle root
///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)
pub fn fee_and_merkle_roots(
    txs: Span<Transaction>, block_height: u32, block_time: u32
) -> Result<(u64, Hash, Hash), ByteArray> {
    let mut txids: Array<Hash> = array![];
    let mut wtxids: Array<Hash> = array![];
    let mut total_fee = 0;
    let mut i = 0;

    let loop_result: Result<(), ByteArray> = loop {
        if i >= txs.len() {
            break Result::Ok(());
        }

        let tx = txs[i];
        txids.append(tx.txid());
        // TODO: only do that for blocks after Segwit upgrade
        wtxids.append(tx.wtxid());

        // skipping the coinbase transaction
        if (i != 0) {
            let fee = match validate_transaction(tx, block_height, block_time) {
                Result::Ok(fee) => fee,
                Result::Err(err) => { break Result::Err(err); }
            };
            total_fee += fee;
        }
        i += 1;
    };
    loop_result?;

    Result::Ok((total_fee, merkle_root(ref txids), merkle_root(ref wtxids)))
}
