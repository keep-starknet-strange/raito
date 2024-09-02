//! Block validation helpers.

use crate::types::transaction::{Transaction, TransactionTrait};
use crate::utils::{hash::Hash, merkle_tree::merkle_root};
use super::transaction::validate_transaction;
use crate::codec::Encode;

/// Validate the weight of the block
/// https://github.com/bitcoin/bitcoin/blob/a74bdeea1b8e27b2335f0f7da78006e87ecfb235/src/consensus/consensus.h#L14
pub fn validate_weight_block(weight_block: u32) -> Result<(), ByteArray> {
    if weight_block > 4_000_000 {
        return Result::Err("Block weight is too high");
    }
    Result::Ok(())
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
    let mut block_weight = 0;
    let mut i = 0;

    let validate_transactions: Result<(), ByteArray> = loop {
        if i >= txs.len() {
            break Result::Ok(());
        }

        let tx = txs[i];
        txids.append(tx.txid());
        // TODO: only do that for blocks after Segwit upgrade
        wtxids.append(tx.wtxid());
        block_weight += tx.weight();

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

    validate_transactions?;
    validate_weight_block(block_weight)?;

    Result::Ok((total_fee, merkle_root(ref txids), merkle_root(ref wtxids)))
}
