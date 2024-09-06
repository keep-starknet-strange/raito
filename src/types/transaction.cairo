//! Bitcoin transaction and its components.
//!
//! Types are extended with extra information required for validation.
//! The data is expected to be prepared in advance and passed as program arguments.

use crate::utils::{hash::Hash, sha256::double_sha256_byte_array};
use crate::codec::{Encode, TransactionCodec};

/// Represents a transaction.
/// https://learnmeabitcoin.com/technical/transaction/
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
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
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
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
    /// Can be empty if this particular inputs spends a non-segwit output.
    /// NOTE that this field actually belongs to the transaction, but we store it in the input for
    /// convenience.
    pub witness: Span<ByteArray>,
}

/// A reference to an unspent transaction output (UTXO).
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
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
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
    // Determine if the outpoint is a coinbase transaction
    // Has 100 or more block confirmation,
    // is added when block are queried
    pub is_coinbase: bool
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
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
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

impl ByteArraySnapSerde of Serde<@ByteArray> {
    fn serialize(self: @@ByteArray, ref output: Array<felt252>) {
        (*self).serialize(ref output);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<@ByteArray> {
        match Serde::deserialize(ref serialized) {
            Option::Some(res) => Option::Some(@res),
            Option::None => Option::None,
        }
    }
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
        double_sha256_byte_array(@(self.encode()))
    }

    /// Compute transaction wTXID
    /// https://learnmeabitcoin.com/technical/transaction/wtxid/
    fn wtxid(self: @Transaction) -> Hash {
        double_sha256_byte_array(@(self.encode_with_witness()))
    }
}

// TODO: implement Hash trait for OutPoint (for creating hash digests to use in utreexo/utxo cache)
// Maybe we need to rename utils::hash::Hash (e.g. to Digest) to avoid confusion

#[cfg(test)]
mod tests {
    use crate::utils::hex::{from_hex, hex_to_hash_rev};
    use super::{Transaction, TransactionTrait, TxIn, TxOut, OutPoint};

    #[test]
    fn test_txid() {
        let tx: Transaction = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "47304402204e45e16932b8af514961a1d3a1a25fdf3f4f7732e9d624c6c61548ab5fb8cd410220181522ec8eca07de4860a4acdd12909d831cc56cbbac4622082221a8768d1d0901"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9"
                        ),
                        vout: 0x00000000,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                        is_coinbase: false,
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 0x000000003b9aca00,
                    pk_script: @from_hex(
                        "4104ae1a62fe09c5f51b13905f07f06b99a2f7159b2225f374cd378d71302fa28414e7aab37397f554a7df5f142c21c1b7303b8a0626f1baded5c72a704f7e6cd84cac"
                    ),
                    cached: false,
                },
                TxOut {
                    value: 0x00000000ee6b2800,
                    pk_script: @from_hex(
                        "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        assert_eq!(
            tx.txid(),
            hex_to_hash_rev("f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16")
        );
    }
}
