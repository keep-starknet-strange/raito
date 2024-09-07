//! Bitcoin transaction and its components.
//!
//! Types are extended with extra information required for validation.
//! The data is expected to be prepared in advance and passed as program arguments.

use crate::utils::{hash::Digest};
use core::hash::{Hash, HashStateTrait};

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
#[derive(Drop, Copy, Debug, PartialEq, Serde, Hash)]
pub struct OutPoint {
    /// The hash of the referenced transaction.
    pub txid: Digest,
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
#[derive(Drop, Copy, Debug, PartialEq, Serde, Hash)]
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


impl ByteArraySnapHash<S, +HashStateTrait<S>, +Drop<S>> of Hash<@ByteArray, S> {
    #[inline]
    fn update_state(mut state: S, value: @ByteArray) -> S {
        let mut serialized_bytearray: Array<felt252> = array![];
        value.serialize(ref serialized_bytearray);

        for felt in serialized_bytearray {
            state = state.update(felt);
        };
        state
    }
}

impl TxOutDefault of Default<TxOut> {
    fn default() -> TxOut {
        TxOut { value: 0, pk_script: @"", cached: false, }
    }
}

#[cfg(test)]
mod tests {
    use super::HashStateTrait;
    use core::hash::HashStateExTrait;
    use core::poseidon::PoseidonTrait;
    use super::{OutPoint, TxOut};
    use crate::utils::{hash::{DigestTrait}};

    #[test]
    pub fn test_outpoint_poseidon_hash() {
        let test_outpoint = OutPoint {
            txid: DigestTrait::new([1, 2, 3, 4, 5, 6, 7, 8]),
            vout: 2,
            // https://learnmeabitcoin.com/explorer/tx/0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9#output-0
            data: TxOut {
                value: 50_u64,
                pk_script: @"410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
                cached: false,
            },
            block_height: 9,
            block_time: 1650000000,
            is_coinbase: false,
        };
        let hash = PoseidonTrait::new().update_with(test_outpoint).finalize();
        assert_eq!(
            hash, 2066345132208626685244560166700396327660679738257525753112003865133004328681
        );
    }
}
