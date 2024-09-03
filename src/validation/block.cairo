//! Block validation helpers.

use crate::types::transaction::{Transaction, TransactionTrait};
use crate::utils::{hash::Hash, merkle_tree::merkle_root};
use super::transaction::validate_transaction;
use crate::codec::Encode;

const SEGWIT_ACTIVATION_HEIGHT: u32 = 481_824;

/// Validate block size
/// If block height is greater than Segwit activation height, block weight must be less than 4MB
/// Otherwise, block size must be less than 1MB
/// https://github.com/bitcoin/bitcoin/blob/a74bdeea1b8e27b2335f0f7da78006e87ecfb235/src/consensus/consensus.h#L14
pub fn validate_block_size(block_size: u32, block_height: u32) -> Result<(), ByteArray> {
    if (block_height >= SEGWIT_ACTIVATION_HEIGHT && block_size > 4_000_000) {
        Result::Err(format!("Block weight is too high: {block_size} > 4M"))
    } else if (block_height < SEGWIT_ACTIVATION_HEIGHT && block_size > 1_000_000) {
        Result::Err(format!("Block size is too high: {block_size} > 1M"))
    } else {
        Result::Ok(())
    }
}

/// Validates transactions and aggregates:
///  - Total fee
///  - TXID merkle root
///  - wTXID commitment (only for blocks after Segwit upgrade, otherwise return zero hash)
///  - Block size
pub fn fee_and_merkle_roots(
    txs: Span<Transaction>, block_height: u32, block_time: u32
) -> Result<(u64, Hash, Option<Hash>), ByteArray> {
    let mut txids: Array<Hash> = array![];
    let mut wtxids: Array<Hash> = array![];
    let mut total_fee = 0;
    let mut block_size = 0;
    let mut i = 0;

    let validate_transactions: Result<(), ByteArray> = loop {
        if i >= txs.len() {
            break Result::Ok(());
        }

        let tx = txs[i];
        txids.append(tx.txid());

        if (block_height >= SEGWIT_ACTIVATION_HEIGHT) {
            wtxids.append(tx.wtxid());
            block_size += tx.weight();
        } else {
            block_size += tx.encode().len();
        }

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
    validate_block_size(block_size, block_height)?;

    if (block_height >= SEGWIT_ACTIVATION_HEIGHT) {
        Result::Ok((total_fee, merkle_root(ref txids), Option::Some(merkle_root(ref wtxids))))
    } else {
        Result::Ok((total_fee, merkle_root(ref txids), Option::None))
    }
}


#[cfg(test)]
mod tests {
    use super::{validate_block_size};

    #[test]
    fn test_block_size() {
        let block_size = 1_000_000;
        let block_height = 481_823;
        assert_eq!(validate_block_size(block_size, block_height), Result::Ok(()));

        let block_size = 1_000_001;
        let block_height = 481_823;
        assert_eq!(
            validate_block_size(block_size, block_height),
            Result::Err("Block size is too high: 1000001 > 1M")
        );

        let block_size = 4_000_000;
        let block_height = 481_824;
        assert_eq!(validate_block_size(block_size, block_height), Result::Ok(()));

        let block_size = 4_000_001;
        let block_height = 481_824;
        assert_eq!(
            validate_block_size(block_size, block_height),
            Result::Err("Block weight is too high: 4000001 > 4M")
        );
    }
    //TODO: test size block < segwit activation height
//TODO: test size block > segwit activation height
}
