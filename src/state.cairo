//! Bitcoin data type objects extended with validation context.
//!
//! The data is expected to be prepared in advance and passed as program arguments.
//! The extended set of fields allows to recursively validate entities in a stateless manner,
//! and to avoid repetitive computations.

use raito::utils::{
    hash::{Hash, HashTrait}, hex::{print_bytearray_hex}, sha256::double_sha256_byte_array
};
use super::codec::encode_transaction;
pub use super::utreexo::UtreexoState;

/// Represents the state of the blockchain.
#[derive(Drop, Copy)]
pub struct ChainState {
    /// Height of the current block.
    pub block_height: Option<u32>,
    /// Total work done.
    pub total_work: u256,
    /// Best block.
    pub best_block_hash: Hash,
    /// Current target.
    pub current_target: u256,
    /// Start of the current epoch.
    pub epoch_start_time: u32,
    /// List of 11 most recent block timestamps (from oldest to newest).
    /// It is expected that this list always has length = 11
    ///
    /// Note that timestamps *do not* influence the order of blocks, i.e.
    /// it's possible that one block could have an earlier timestamp
    /// than a block that came before it in the chain.
    pub prev_timestamps: Span<u32>,
    /// Utreexo state.
    pub utreexo_state: UtreexoState,
}

/// Represents the initial state before genesis block.
/// https://github.com/bitcoin/bitcoin/blob/ee367170cb2acf82b6ff8e0ccdbc1cce09730662/src/kernel/chainparams.cpp#L99
impl ChainStateDefault of Default<ChainState> {
    fn default() -> ChainState {
        ChainState {
            block_height: Default::default(),
            total_work: 0,
            best_block_hash: 0_u256.into(),
            current_target: 26959535291011309493156476344723991336010898738574164086137773096960,
            epoch_start_time: 1231006505,
            prev_timestamps: [
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ].span(), utreexo_state: Default::default(),
        }
    }
}

/// Represents a block in the blockchain.
#[derive(Drop, Copy)]
pub struct Block {
    /// Block header.
    pub header: Header,
    /// Transactions.
    pub txs: Span<Transaction>,
}

/// Represents a block header.
/// https://learnmeabitcoin.com/technical/block/
#[derive(Drop, Copy)]
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

/// Represents a transaction.
/// https://learnmeabitcoin.com/technical/transaction/
#[derive(Drop, Copy)]
pub struct Transaction {
    /// The version of the transaction.
    pub version: u32,
    /// Flag which indicates the presence of witness data.
    /// It combines `marker` and `flag` fields for now but in the future
    /// we might need to separate them if transaction structure changes.
    /// Segwit marker and flag do not contribute to TXID (transaction hash),
    /// but do contribute to wTXID.
    pub is_segwit: bool,
    /// The inputs of the transaction.
    pub inputs: Span<TxIn>,
    /// The outputs of the transaction.
    pub outputs: Span<TxOut>,
    /// Block height / time after which this transaction can be mined.
    /// Locktime feature is enabled if at least one input has sequence <= 0xfffffffe.
    pub lock_time: u32,
}

/// Input of a transaction.
/// https://learnmeabitcoin.com/technical/transaction/input/
#[derive(Drop, Copy)]
pub struct TxIn {
    /// The signature script which satisfies the conditions placed in the txo pubkey script
    /// or coinbase script that contains block height (since 227,836) and miner nonce (optional).
    pub script: @ByteArray,
    /// This field enables absolute or relative locktime feature, basically how much time or how
    /// many blocks must pass (since genesis or since the referenced output was mined) before this
    /// transaction can be mined.
    pub sequence: u32,
    /// The reference to the previous output that is being spent by this input.
    pub previous_output: OutPoint,
    /// The witness data for transactions.
    /// A list of items (of different size) pushed onto stack before sig script execution.
    pub witness: Span<ByteArray>,
}

/// A reference to a transaction output.
///
/// NOTE that `data` and `block_height` meta fields are not serialized with the rest of
/// the transaction and hence are not constrained with the transaction hash.
///
/// There are four possible cases:
///   1. Coinbase input that does not spend any outputs (zero txid)
///   2. Input that spends an output created within the same block (cached)
///   3. Input that spends a coinbase output
///   4. Input that spends an output from a past block
///
/// For (1) we don't need to add extra constraints, because meta fields are not used.
/// For (2) we need to check that the referenced output is indeed cached:
///     * Calculate cache key by hashing (txid, vout, data)
///     * Check if the key is present in the cache
///     * Remove item from the cache
/// For (3) we need to check that the referenced output is in the utreexo accumulator:
///     * Calculate utreexo leaf hash from (txid, vout, data, block_height)
///     * Verify inclusion proof (either individual or batched) against the roots
///     * Delete the leaf from the accumulator
/// For (4) we need to additionally check if the coinbase output is older than 100 blocks
///
/// IMPORTANT:
///     * Utreexo proofs can be verified at any point of block validation because accumulator
///       is not changing until the end of the block;
///     * Cache lookups MUST be done in a sequential order, i.e. transactions are validated
///       one by one, first inputs then outputs. Output validation might put something to the
///       cache while input validation might remove an item, thus it's important to maintain
///       the order.
#[derive(Drop, Copy)]
pub struct OutPoint {
    /// The hash of the referenced transaction.
    pub txid: Hash,
    /// The index of the specific output in the transaction.
    pub vout: u32,
    /// Referenced output data (meta field).
    /// Must be set to default for coinbase inputs.
    pub data: TxOut,
    /// The height of the block that contains this output (meta field).
    /// Used to validate coinbase tx spending (not sooner than 100 blocks) and relative timelocks
    /// (it has been more than X block since the transaction containing this output was mined).
    /// Can be set to default for non-coinbase outputs & if locktime feature (height relative) is
    /// disabled.
    pub block_height: u32,
    /// The time of the block that contains this output (meta field).
    /// Used to validate relative timelocks (it has been more than X seconds since the transaction
    /// containing this output was mined).
    /// Can be set to default if locktime feature (time relative) is disabled.
    pub block_time: u32,
}

/// Output of a transaction.
/// https://learnmeabitcoin.com/technical/transaction/output/
///
/// Upon processing (validating) an output one of three actions must be taken:
///     - Add output with some extra info (see [OutPoint]) to the Utreexo accumulator
///     - Add output to the cache in case it is going to be spent in the same block
///     - Do nothing in case of a provably unspendable output
///
/// Read more: https://en.bitcoin.it/wiki/Script#Provably_Unspendable/Prunable_Outputs
#[derive(Drop, Copy)]
pub struct TxOut {
    /// The value of the output in satoshis.
    /// Can be in range [0, 21_000_000] BTC (including both ends).
    pub value: u64,
    /// The spending script (aka locking code) for this output.
    pub pk_script: @ByteArray,
    /// Meta flag indicating that this output will be spent within the current block(s).
    /// This output won't be added to the utreexo accumulator.
    /// Note that coinbase outputs cannot be spent sooner than 100 blocks after inclusion.
    pub cached: bool,
}

impl TxOutDefault of Default<TxOut> {
    fn default() -> TxOut {
        TxOut { value: 0, pk_script: @"", cached: false, }
    }
}

#[generate_trait]
pub impl TransactionImpl of TransactionTrait {
    /// Compute transaction TXID
    /// https://learnmeabitcoin.com/technical/transaction/input/txid/
    ///
    /// NOTE: marker, flag, and witness fields in segwit transactions are not included
    /// this means txid computation is the same for legacy and segwit tx
    fn txid(self: @Transaction) -> Hash {
        double_sha256_byte_array(@encode_transaction(self, false))
    }

    /// Compute transaction wTXID
    /// https://learnmeabitcoin.com/technical/transaction/wtxid/
    fn wtxid(self: @Transaction) -> Hash {
        double_sha256_byte_array(@encode_transaction(self, true))
    }
}

#[generate_trait]
pub impl HeaderImpl of HeaderTrait {
    /// Compute hash of the block header given the missing fields.
    fn hash(self: @Header, _prev_block_hash: Hash, _merkle_root: Hash) -> Hash {
        let mut header_data_bytes: ByteArray = Default::default();

        header_data_bytes.append_word_rev((*self.version).into(), 4);
        let best_block_hash: ByteArray = _prev_block_hash.into();
        header_data_bytes.append(@best_block_hash);
        let merkle_root: ByteArray = _merkle_root.into();
        header_data_bytes.append(@merkle_root);
        header_data_bytes.append_word_rev((*self.time).into(), 4);
        header_data_bytes.append_word_rev((*self.bits).into(), 4);
        header_data_bytes.append_word_rev((*self.nonce).into(), 4);

        double_sha256_byte_array(@header_data_bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::{
        Transaction, TransactionTrait, TxIn, TxOut, OutPoint, ChainState, Block, Header, HeaderTrait
    };
    use raito::utils::{hex::from_hex, hash::Hash};

    #[test]
    fn test_block_hash() {
        let mut chain_state: ChainState = Default::default();
        chain_state
            .best_block_hash =
                0x55bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000_u256
            .into();
        // block 170
        let block = Block {
            header: Header {
                version: 1_u32, time: 1231731025_u32, bits: 0x1d00ffff_u32, nonce: 1889418792_u32
            },
            txs: ArrayTrait::new().span(),
        };
        let merkle_root: Hash =
            0xff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d_u256
            .into();

        let block_hash_result: Hash = block.header.hash(chain_state.best_block_hash, merkle_root);

        //0x00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee
        let expected_block_hash: Hash =
            0xeea2d48d2fced4346842835c659e493d323f06d4034469a8905714d100000000_u256
            .into();

        assert_eq!(expected_block_hash, block_hash_result);
    }

    #[test]
    fn test_txid() {
        let tx: Transaction = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "01091d8d76a82122082246acbb6cc51c839d9012ddaca46048de07ca8eec221518200241cdb85fab4815c6c624d6e932774f3fdf5fa2a1d3a1614951afb83269e1454e2002443047"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                            .into(),
                        vout: 0x00000000,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0x000000003b9aca00,
                    pk_script: @from_hex(
                        "ac4cd86c7e4f702ac7d5debaf126068a3b30b7c1212c145fdfa754f59773b3aae71484a22f30718d37cd74f325229b15f7a2996bf0075f90131bf5c509fe621aae0441"
                    ),
                    cached: false,
                },
                TxOut {
                    value: 0x00000000ee6b2800,
                    pk_script: @from_hex(
                        "aca312b456f643869b993fc0d4f9648b9bfa0b162ef8644474f9cc84fbddeae0b25c9a90a648b1d7ca2e48b1972e388ab61ebc538c0f84496b018adbdce193db110441"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };
        // assert_eq!(
    //     tx.txid(),
    //     0x169e1e83e930853391bc6f35f605c6754cfead57cf8387639d3b4096c54f18f4_u256.into()
    // );
    }
}
