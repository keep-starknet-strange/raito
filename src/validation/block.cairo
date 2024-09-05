//! Block validation helpers.

use crate::types::transaction::{Transaction, TransactionTrait};
use crate::utils::{hash::Hash, merkle_tree::merkle_root};
use super::transaction::validate_transaction;

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
        let tx_bytes_legacy = tx.encode();
        let tx_bytes_segwit = tx.encode_with_witness(tx_bytes_legacy);
        let txid = double_sha256_byte_array(tx_bytes_legacy);
        let wtxid = double_sha256_byte_array(tx_bytes_segwit);
        let weight = 3 * tx_bytes_legacy.len() + tx_bytes_segwit.len();  // 4 * tx_size_legacy + (tx_size_segwit - tx_size_legacy)

        txids.append(txid);
        // TODO: only do that for blocks after Segwit upgrade
        wtxids.append(wtxid);

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
