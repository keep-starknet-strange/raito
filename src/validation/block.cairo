//! Block validation helpers.

use crate::types::transaction::{Transaction, TransactionTrait};
use crate::utils::{hash::Digest, merkle_tree::merkle_root};
use super::transaction::validate_transaction;

/// Validates transactions and aggregates:
///  - Total fee
///  - TXID merkle root
///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)
pub fn fee_and_merkle_roots(
    txs: Span<Transaction>, block_height: u32, block_time: u32
) -> Result<(u64, Digest, Digest), ByteArray> {
    let mut txids: Array<Digest> = array![];
    let mut wtxids: Array<Digest> = array![];
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
