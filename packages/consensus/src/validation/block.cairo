//! Block validation helpers.
use core::hash::{HashStateTrait, HashStateExTrait};
use core::poseidon::PoseidonTrait;
use crate::types::utxo_set::UtxoSet;
use crate::types::transaction::{Transaction, OutPoint, TxOut};
use crate::codec::{Encode, TransactionCodec};
use utils::{hash::Digest, merkle_tree::merkle_root, sha256::double_sha256_byte_array};
use super::transaction::validate_transaction;

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
        ///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)

        let tx = txs[i];

        let tx_bytes_legacy = @tx.encode();
        let tx_bytes_segwit = @tx.encode_with_witness(tx_bytes_legacy);

        let txid = double_sha256_byte_array(tx_bytes_legacy);

        // Removes transactions inputs from the cache if needed.
        let inputs = *tx.inputs;
        let mut j = 0;
        while j != inputs.len() {
            let outpoint = (*inputs[j]).previous_output;
            let outpoint_hash = PoseidonTrait::new().update_with(outpoint).finalize();

            if (utxo_set.cache.get(outpoint_hash) == true) {
                utxo_set.cache.insert(outpoint_hash, false);
            }

            j += 1;
        };

        // Adds transactions outputs in the cache if needed.
        let outputs = *tx.outputs;
        let mut j = 0;
        while j != outputs.len() {
            if (*outputs[j]).cached {
                let is_coinbase: bool = if (i == 0) {
                    true
                } else {
                    false
                };

                let outpoint = OutPoint {
                    txid: txid,
                    vout: j,
                    data: TxOut {
                        value: (*outputs[j]).value, pk_script: (*outputs[j]).pk_script, cached: true
                    },
                    block_height: block_height,
                    block_time: block_time,
                    is_coinbase: is_coinbase
                };

                let outpoint_hash = PoseidonTrait::new().update_with(outpoint).finalize();
                utxo_set.cache.insert(outpoint_hash, true);
            }

            j += 1;
        };

        /// The wTXID for the coinbase transaction must be set to all zeros. This is because it's
        /// eventually going to contain the commitment inside it
        /// see https://learnmeabitcoin.com/technical/transaction/wtxid/#commitment
        let mut wtxid = Default::default();
        if i != 0 {
            wtxid = double_sha256_byte_array(tx_bytes_segwit);
        }

        // tx_byte_segwit represents all the bytes in the transaction, so the bytes in the segwit
        // fields are tx_byte_segwit - tx_byte_legacy.
        // 4 * tx_size_legacy + (tx_size_segwit - tx_size_legacy)
        total_weight += 3 * tx_bytes_legacy.len() + tx_bytes_segwit.len();

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
    validate_transactions?;
    validate_block_weight(total_weight)?;

    Result::Ok((total_fee, merkle_root(ref txids), merkle_root(ref wtxids)))
}
