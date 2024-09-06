//! Bitcoin block and its components.
//!
//! The data is expected to be prepared in advance and passed as program arguments.

use crate::utils::hash::Hash;
use crate::utils::sha256::double_sha256_u32_array;
use crate::utils::numeric::u32_byte_reverse;
use super::transaction::Transaction;

/// Represents a block in the blockchain.
#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct Block {
    /// Block header.
    pub header: Header,
    /// Transaction data: either merkle root or list of transactions.
    pub data: TransactionData,
}

/// Represents block contents.
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
pub enum TransactionData {
    /// Merkle root of all transactions in the block.
    /// This variant is used for header-only validation mode (light client).
    MerkleRoot: Hash,
    /// List of all transactions included in the block.
    /// This variant is used for the full consensus validation mode.
    Transactions: Span<Transaction>,
}

/// Represents a block header.
/// https://learnmeabitcoin.com/technical/block/
///
/// NOTE that some of the fields are missing, that's intended.
/// The point of the client is to calculate next chain state from the previous
/// chain state and block data in a provable way.
/// The proof can be later used to verify that the chain state is valid.
/// In order to do the calculation we just need data about the block that is strictly necessary,
/// but not the data we can calculate like merkle root or data that we already have
/// like previous_block_hash (in the previous chain state).
#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct Header {
    /// The version of the block.
    pub version: u32,
    /// The timestamp of the block.
    pub time: u32,
    /// The difficulty target for mining the block.
    /// Not strictly necessary since it can be computed from target,
    /// but it is cheaper to validate than compute.
    pub bits: u32,
    /// The nonce used in mining the block.
    pub nonce: u32,
}

#[generate_trait]
pub impl BlockHashImpl of BlockHash {
    /// Compute hash of the block header given the missing fields.
    fn hash(self: @Header, prev_block_hash: Hash, merkle_root: Hash) -> Hash {
        let mut header_data_u32: Array<u32> = array![];

        header_data_u32.append(u32_byte_reverse(*self.version));
        header_data_u32.append_span(prev_block_hash.value.span());
        header_data_u32.append_span(merkle_root.value.span());

        header_data_u32.append(u32_byte_reverse(*self.time));
        header_data_u32.append(u32_byte_reverse(*self.bits));
        header_data_u32.append(u32_byte_reverse(*self.nonce));

        double_sha256_u32_array(header_data_u32)
    }
}

/// Empty transaction data
pub impl TransactionDataDefault of Default<TransactionData> {
    fn default() -> TransactionData {
        TransactionData::Transactions(array![].span())
    }
}

#[cfg(test)]
mod tests {
    use super::{Header, BlockHash};
    use raito::types::chain_state::ChainState;
    use raito::utils::hash::Hash;

    #[test]
    fn test_block_hash() {
        let mut chain_state: ChainState = Default::default();
        chain_state
            .best_block_hash =
                0x000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55_u256
            .into();
        // block 170
        let header = Header {
            version: 1_u32, time: 1231731025_u32, bits: 0x1d00ffff_u32, nonce: 1889418792_u32
        };
        let merkle_root: Hash =
            0x7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff_u256
            .into();

        let block_hash_result: Hash = header.hash(chain_state.best_block_hash, merkle_root);

        //0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee
        let expected_block_hash: Hash =
            0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee_u256
            .into();

        assert_eq!(expected_block_hash, block_hash_result);
    }

    #[test]
    fn test_merkle_root_diff() {
        let mut chain_state: ChainState = Default::default();
        chain_state
            .best_block_hash =
                0x000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55_u256
            .into();
        // block 170
        let header = Header {
            version: 1_u32, time: 1231731025_u32, bits: 0x1d00ffff_u32, nonce: 1889418792_u32
        };
        let merkle_root: Hash =
            0x6dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff_u256
            .into();

        let block_hash_result: Hash = header.hash(chain_state.best_block_hash, merkle_root);

        let expected_block_hash: Hash =
            0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee_u256
            .into();

        assert_ne!(expected_block_hash, block_hash_result);
    }

    #[test]
    fn test_best_block_hash_diff() {
        let mut chain_state: ChainState = Default::default();
        chain_state
            .best_block_hash =
                0x000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd56_u256
            .into();
        // block 170
        let header = Header {
            version: 1_u32, time: 1231731025_u32, bits: 0x1d00ffff_u32, nonce: 1889418792_u32
        };
        let merkle_root: Hash =
            0x7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff_u256
            .into();

        let block_hash_result: Hash = header.hash(chain_state.best_block_hash, merkle_root);

        let expected_block_hash: Hash =
            0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee_u256
            .into();

        assert_ne!(expected_block_hash, block_hash_result);
    }
}
