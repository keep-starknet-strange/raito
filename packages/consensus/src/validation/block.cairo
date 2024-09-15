//! Block validation helpers.
use crate::types::utxo_set::UtxoSet;
use crate::types::transaction::Transaction;
use crate::codec::{Encode, TransactionCodec};
use utils::{hash::Digest, merkle_tree::merkle_root, sha256::double_sha256_byte_array};
use super::transaction::validate_transaction;
use core::num::traits::zero::Zero;

const MAX_BLOCK_WEIGHT_LEGACY: usize = 1_000_000;
const MAX_BLOCK_WEIGHT: usize = 4_000_000;
const SEGWIT_BLOCK: usize = 481_824;

/// Validate block weight.
/// Blocks after Segwit upgrade have a limit of 4,000,000 weight units.
pub fn validate_block_weight(weight: usize) -> Result<(), ByteArray> {
    if (weight > MAX_BLOCK_WEIGHT) {
        return Result::Err(
            format!(
                "[validate_weight] block weight {weight} exceeds the limit {MAX_BLOCK_WEIGHT} for segwit blocks"
            )
        );
    }
    Result::Ok(())
}

/// Validates transactions and aggregates:
///  - Total fee
///  - TXID merkle root
///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)
///  - Block weight
pub fn compute_and_validate_tx_data(
    txs: Span<Transaction>, block_height: u32, block_time: u32, ref utxo_set: UtxoSet
) -> Result<(u64, Digest, Digest), ByteArray> {
    let mut txids: Array<Digest> = array![];
    let mut wtxids: Array<Digest> = array![];
    let mut total_fee = 0;
    let mut total_weight: u32 = 0;
    let mut i = 0;

    let validate_transactions: Result<(), ByteArray> = loop {
        if i >= txs.len() {
            break Result::Ok(());
        }

        let tx = txs[i];
        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        if block_height >= SEGWIT_BLOCK {
            let tx_bytes_segwit = @tx
                .encode_with_witness(tx_bytes_legacy); // SegWit transaction encoding

            /// The wTXID for the coinbase transaction must be set to all zeros. This is because
            /// it's eventually going to contain the commitment inside it
            /// see https://learnmeabitcoin.com/technical/transaction/wtxid/#commitment
            let wtxid = if i != 0 {
                double_sha256_byte_array(tx_bytes_segwit)
            } else {
                Zero::zero()
            };

            total_weight += 3 * tx_bytes_legacy.len()
                + tx_bytes_segwit.len(); // Calculate block weight with SegWit

            wtxids.append(wtxid); // Append wtxid to array
        } else {
            // For blocks before SegWit, only legacy tx weight is considered
            total_weight += 4 * tx_bytes_legacy.len(); // Calculate block weight without SegWit
        }

        txids.append(txid);

        // skipping the coinbase transaction
        if i != 0 {
            let fee = match validate_transaction(tx, block_height, block_time, txid, ref utxo_set) {
                Result::Ok(fee) => fee,
                Result::Err(err) => { break Result::Err(err); }
            };
            total_fee += fee;
        }

        i += 1;
    };

    validate_transactions?;
    validate_block_weight(total_weight)?;

    let wtxid_root = if block_height >= SEGWIT_BLOCK {
        merkle_root(ref wtxids)
    } else {
        Zero::zero()
    };

    Result::Ok((total_fee, merkle_root(ref txids), wtxid_root))
}
