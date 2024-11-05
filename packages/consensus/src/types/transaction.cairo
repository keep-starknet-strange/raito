//! Bitcoin transaction and its components.
//!
//! Types are extended with extra information required for validation.
//! The data is expected to be prepared in advance and passed as program arguments.

use core::fmt::{Display, Formatter, Error};
use core::hash::{HashStateTrait, HashStateExTrait, Hash};
use core::poseidon::PoseidonTrait;
use utils::{hash::Digest, bytearray::{ByteArraySnapHash, ByteArraySnapSerde}};

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
    /// Can be empty if this particular input spends a non-segwit output.
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
    /// (it has been more than X blocks since the transaction containing this output was mined).
    pub block_height: u32,
    /// The median time past of the block that contains this output (meta field).
    /// This is the median timestamp of the previous 11 blocks.
    /// Used to validate relative timelocks based on time (BIP 68 and BIP 112).
    /// It ensures that the transaction containing this output has been mined for more than X
    /// seconds.
    pub median_time_past: u32,
    /// Determines if the outpoint is a coinbase transaction.
    pub is_coinbase: bool
}


/// Output of a transaction.
/// https://learnmeabitcoin.com/technical/transaction/output/
///
/// NOTE: that `cached` meta field is not serialized with the rest of the output data,
/// so it's not constrained by the transaction hash when UTXO hash is computed.
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

/// Custom implementation of the `Hash` trait for `TxOut`, excluding `cached` field.
impl TxOutHash<S, +HashStateTrait<S>, +Drop<S>> of Hash<TxOut, S> {
    fn update_state(state: S, value: TxOut) -> S {
        let state = state.update(value.value.into());
        let state = state.update_with(value.pk_script.into());
        state
    }
}

/// `Outpoint` Poseidon hash implementation.
#[generate_trait]
pub impl OutPointHashImpl of OutPointHashTrait {
    fn hash(self: @OutPoint) -> felt252 {
        PoseidonTrait::new().update_with(*self).finalize()
    }
}

/// `Default` trait implementation for `TxOut`.
impl TxOutDefault of Default<TxOut> {
    fn default() -> TxOut {
        TxOut { value: 0, pk_script: @"", cached: false, }
    }
}

/// `Display` trait implementation for `Transaction`.
impl TransactionDisplay of Display<Transaction> {
    fn fmt(self: @Transaction, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "Transaction {{ version: {}, is_segwit: {}, inputs: {}, outputs: {}, lock_time: {} }}",
            *self.version,
            *self.is_segwit,
            (*self.inputs).len(),
            (*self.outputs).len(),
            *self.lock_time
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

/// `Display` trait implementation for `TxIn`.
impl TxInDisplay of Display<TxIn> {
    fn fmt(self: @TxIn, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "TxIn {{ script: {}, sequence: {}, previous_output: {}, witness: {} }}",
            *self.script,
            *self.sequence,
            *self.previous_output.txid,
            (*self.witness).len()
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

/// `Display` trait implementation for `OutPoint`.
impl OutPointDisplay of Display<OutPoint> {
    fn fmt(self: @OutPoint, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "OutPoint {{
		txid: {},
		vout: {},
		data: {},
		block_height: {},
		median_time_past: {},
		is_coinbase: {},
	}}",
            *self.txid,
            *self.vout,
            *self.data,
            *self.block_height,
            *self.median_time_past,
            *self.is_coinbase
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

/// `Display` trait implementation for `TxOut`.
impl TxOutDisplay of Display<TxOut> {
    fn fmt(self: @TxOut, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!(
            "TxOut {{ value: {}, pk_script: {}, cached: {} }}",
            *self.value,
            *self.pk_script,
            *self.cached
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}

#[cfg(test)]
mod tests {
    use core::poseidon::PoseidonTrait;
    use utils::hex::{hex_to_hash_rev, from_hex};
    use super::{OutPoint, TxOut, HashStateTrait, HashStateExTrait, OutPointHashTrait};

    fn hash(tx: @TxOut) -> felt252 {
        PoseidonTrait::new().update_with(*tx).finalize()
    }

    #[test]
    pub fn test_txout_cached_flag_does_not_influence_hash() {
        let mut tx1 = TxOut {
            value: 50_u64,
            pk_script: @"410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
            cached: false,
        };
        let mut tx_with_cached_changed = TxOut {
            value: 50_u64,
            pk_script: @"410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
            cached: true,
        };
        let mut tx_with_value_changed = TxOut {
            value: 55_u64,
            pk_script: @"410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
            cached: false,
        };
        let mut tx_with_pk_script_changed = TxOut {
            value: 50_u64,
            pk_script: @"510411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac",
            cached: false,
        };
        assert_eq!(hash(@tx1), hash(@tx_with_cached_changed));
        assert_ne!(hash(@tx1), hash(@tx_with_pk_script_changed));
        assert_ne!(hash(@tx1), hash(@tx_with_value_changed));
    }

    #[derive(Debug, Drop, Default)]
    pub struct HashState {
        pub value: Array<felt252>
    }

    impl HashStateImpl of HashStateTrait<HashState> {
        fn update(self: HashState, value: felt252) -> HashState {
            let mut new_value = self.value;
            new_value.append(value);
            HashState { value: new_value }
        }

        fn finalize(self: HashState) -> felt252 {
            0
        }
    }

    #[test]
    pub fn test_outpoint_poseidon_hash_cb9() {
        let mut coinbase_9_utxo = OutPoint {
            txid: hex_to_hash_rev(
                "0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9"
            ),
            vout: 0,
            data: TxOut {
                value: 5000000000,
                pk_script: @from_hex(
                    "410411db93e1dcdb8a016b49840f8c53bc1eb68a382e97b1482ecad7b148a6909a5cb2e0eaddfb84ccf9744464f82e160bfa9b8b64f9d4c03f999b8643f656b412a3ac"
                ),
                cached: false,
            },
            block_height: 9,
            median_time_past: 1231470988,
            is_coinbase: true,
        };

        let mut state: HashState = Default::default();
        state = state.update_with(coinbase_9_utxo);

        let expected: Array<felt252> = array![
            5606656307511680658662848977137541728,
            9103019671783490751638296454939121609,
            0,
            5000000000,
            2,
            114873147639302600539941532864842037771792291166958548649371950632810924198,
            255491345418700057264349667014908841246825595399329019948869966327385048054,
            372388307884,
            5,
            9,
            1231470988,
            1
        ];
        assert_eq!(expected, state.value);

        let hash = coinbase_9_utxo.hash();
        assert_eq!(
            761592244424273723796345514960638980240531938129162865626185984897576522513, hash
        );
    }

    #[test]
    pub fn test_outpoint_poseidon_hash_cb1() {
        let mut coinbase_9_utxo = OutPoint {
            txid: hex_to_hash_rev(
                "0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098"
            ),
            vout: 0,
            data: TxOut {
                value: 5000000000,
                pk_script: @from_hex(
                    "410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac"
                ),
                cached: false,
            },
            block_height: 1,
            median_time_past: 1231006505,
            is_coinbase: true,
        };

        let mut state: HashState = Default::default();
        state = state.update_with(coinbase_9_utxo);

        let expected: Array<felt252> = array![
            18931831195212887181660290436187791739,
            137019159177035157628276746705882390680,
            0,
            5000000000,
            2,
            114876729272917404712191936498804624660105992100397383656070609774475449467,
            406791163401893627439198994794895943141891052128672824792182596804809637667,
            286829113004,
            5,
            1,
            1231006505,
            1
        ];
        assert_eq!(expected, state.value);

        let hash = coinbase_9_utxo.hash();
        assert_eq!(
            49459078824306138476779209834441505868925737545954320330266544605873965565, hash
        );
    }
}
