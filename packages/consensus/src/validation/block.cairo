//! Block validation helpers.
use crate::types::utxo_set::{UtxoSet, UtxoSetTrait};
use crate::types::transaction::{OutPoint, Transaction};
use crate::codec::{Encode, TransactionCodec};
use utils::{
    hash::{Digest, DigestTrait}, merkle_tree::merkle_root, double_sha256::double_sha256_byte_array,
};
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
    txs: Span<Transaction>,
    block_hash: Digest,
    block_height: u32,
    block_time: u32,
    ref utxo_set: UtxoSet
) -> Result<(u64, Digest, Digest), ByteArray> {
    let mut txids: Array<Digest> = array![];
    let mut wtxids: Array<Digest> = array![];
    let mut total_fee = 0;
    let mut total_weight: u32 = 0;
    let mut inner_result = Result::Ok(());
    let mut is_coinbase = true;

    for tx in txs {
        let tx_bytes_legacy = @tx.encode();
        let txid = double_sha256_byte_array(tx_bytes_legacy);

        if block_height >= SEGWIT_BLOCK {
            let tx_bytes_segwit = @tx
                .encode_with_witness(tx_bytes_legacy); // SegWit transaction encoding

            /// The wTXID for the coinbase transaction must be set to all zeros. This is because
            /// it's eventually going to contain the commitment inside it
            /// see https://learnmeabitcoin.com/technical/transaction/wtxid/#commitment
            let wtxid = if is_coinbase {
                Zero::zero()
            } else {
                double_sha256_byte_array(tx_bytes_segwit)
            };

            total_weight += 3 * tx_bytes_legacy.len()
                + tx_bytes_segwit.len(); // Calculate block weight with SegWit

            wtxids.append(wtxid); // Append wtxid to array
        } else {
            // For blocks before SegWit, only legacy tx weight is considered
            total_weight += 4 * tx_bytes_legacy.len(); // Calculate block weight without SegWit
        }

        txids.append(txid);

        if (is_coinbase) {
            let mut vout = 0;
            for output in *tx
                .outputs {
                    let outpoint = OutPoint {
                        txid,
                        vout,
                        data: *output,
                        block_hash,
                        block_height,
                        block_time,
                        is_coinbase: true,
                    };
                    inner_result = utxo_set.add(outpoint);
                    if inner_result.is_err() {
                        break;
                    }
                    vout += 1;
                };
            is_coinbase = false;
        } else {
            let fee =
                match validate_transaction(
                    tx, block_hash, block_height, block_time, txid, ref utxo_set
                ) {
                Result::Ok(fee) => fee,
                Result::Err(err) => {
                    inner_result = Result::Err(err);
                    break;
                }
            };
            total_fee += fee;
        }
    };

    inner_result?;
    validate_block_weight(total_weight)?;

    let wtxid_root = if block_height >= SEGWIT_BLOCK {
        merkle_root(wtxids.span())
    } else {
        Zero::zero()
    };

    Result::Ok((total_fee, merkle_root(txids.span()), wtxid_root))
}

/// Validates that the block hash at certain heights matches the expected hash according to BIP-30.
///
/// This function ensures that for the two exceptional blocks affected by BIP-30 (heights 91722 and
/// 91812), the block hash matches the known hash for those heights. This prevents accepting
/// incorrect blocks at these critical heights, which could lead to security issues.
///
/// BIP-30 - Reject duplicate (https://github.com/bitcoin/bips/blob/master/bip-0030.mediawiki)
pub fn validate_bip30_block_hash(block_height: u32, block_hash: @Digest,) -> Result<(), ByteArray> {
    if block_height == 91722 {
        let expected_hash = DigestTrait::new(
            [
                0x8ed04d57,
                0xf2f3cd6c,
                0xa6e55569,
                0xdc1654e1,
                0xf219847f,
                0x66e726dc,
                0xa2710200,
                0x00000000,
            ]
        );
        if *block_hash != expected_hash {
            return Result::Err("Block hash mismatch for BIP-30 exception at height 91722");
        }
        Result::Ok(())
    } else if block_height == 91812 {
        let expected_hash = DigestTrait::new(
            [
                0x2f6f306f,
                0xd683deb8,
                0x5d9314ef,
                0xfdcf36af,
                0x66d9e3ac,
                0xaceb79d4,
                0xaed00a00,
                0x00000000,
            ]
        );
        if *block_hash != expected_hash {
            return Result::Err("Block hash mismatch for BIP-30 exception at height 91812");
        }
        Result::Ok(())
    } else {
        Result::Ok(())
    }
}


#[cfg(test)]
mod tests {
    use super::{validate_bip30_block_hash};
    use utils::hash::{DigestTrait};

    #[test]
    fn test_bip30_block_hash() {
        // Expected hash for block at height 91722
        let expected_hash = DigestTrait::new(
            [
                0x8ed04d57,
                0xf2f3cd6c,
                0xa6e55569,
                0xdc1654e1,
                0xf219847f,
                0x66e726dc,
                0xa2710200,
                0x00000000,
            ]
        );
        let result = validate_bip30_block_hash(91722, @expected_hash);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_bip30_block_hash_wrong_hash() {
        // Expected hash for block at height 91722
        let expected_hash = DigestTrait::new(
            [
                0x8ed04d56,
                0xf2f3cd6c,
                0xa6e55569,
                0xdc1654e1,
                0xf219847f,
                0x66e726dc,
                0xa2710200,
                0x00000000,
            ]
        );
        let result = validate_bip30_block_hash(91722, @expected_hash);
        assert_eq!(result, Result::Err("Block hash mismatch for BIP-30 exception at height 91722"));
    }

    #[test]
    fn test_bip30_block_hash_height_91812() {
        // Expected hash for block at height 91812
        let expected_hash = DigestTrait::new(
            [
                0x2f6f306f,
                0xd683deb8,
                0x5d9314ef,
                0xfdcf36af,
                0x66d9e3ac,
                0xaceb79d4,
                0xaed00a00,
                0x00000000,
            ]
        );
        let result = validate_bip30_block_hash(91812, @expected_hash);
        assert_eq!(result, Result::Ok(()));
    }

    #[test]
    fn test_bip30_block_hash_wrong_hash_91812() {
        // Expected hash for block at height 91812
        let expected_hash = DigestTrait::new(
            [
                0x9ed04d56,
                0xf2f3cd6c,
                0xa6e55569,
                0xdc1654e1,
                0xf219847f,
                0x66e726dc,
                0xa2710200,
                0x00000000,
            ]
        );
        let result = validate_bip30_block_hash(91812, @expected_hash);
        assert_eq!(result, Result::Err("Block hash mismatch for BIP-30 exception at height 91812"));
    }
}
