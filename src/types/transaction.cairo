//! Bitcoin transaction and its components.
//!
//! Types are extended with extra information required for validation.
//! The data is expected to be prepared in advance and passed as program arguments.

use crate::utils::{hash::Hash, sha256::double_sha256_byte_array};
use crate::codec::{Encode};

/// Represents a transaction.
/// https://learnmeabitcoin.com/technical/transaction/
#[derive(Drop, Copy, Debug, PartialEq)]
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
#[derive(Drop, Copy, Debug, PartialEq)]
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
#[derive(Drop, Copy, Debug, PartialEq)]
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
#[derive(Drop, Copy, Debug, PartialEq)]
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

#[derive(Drop)]
pub struct TransactionData {
    pub version_encoded: ByteArray,
    pub version_size: usize,
    pub inputs_encoded: ByteArray,
    pub inputs_size: usize,
    pub outputs_encoded: ByteArray,
    pub outputs_size: usize,
    pub lock_time_encoded: ByteArray,
    pub lock_time_size: usize,
    pub witness_encoded: ByteArray,
    pub witness_size: usize,
}

#[generate_trait]
pub impl TransactionImpl of TransactionTrait {
    fn init_encode(self: @Transaction) -> TransactionData {
        let (version_encoded, version_size) = self.version.encode();
        let (inputs_encoded, inputs_size) = self.inputs.encode();
        let (outputs_encoded, outputs_size) = self.outputs.encode();
        let (lock_time_encoded, lock_time_size) = self.lock_time.encode();

        let mut witness_encoded: ByteArray = Default::default();
        let mut witness_size: usize = 0;
        if (*self.is_segwit) {
            for txin in *self
                .inputs {
                    let (witness, witness_txin_size) = txin.witness.encode();
                    witness_size += witness_txin_size;
                    witness_encoded.append(@witness);
                };
        }

        TransactionData {
            version_encoded,
            version_size,
            inputs_encoded,
            inputs_size,
            outputs_encoded,
            outputs_size,
            lock_time_encoded,
            lock_time_size,
            witness_encoded,
            witness_size
        }
    }

    /// Compute transaction TXID
    /// https://learnmeabitcoin.com/technical/transaction/input/txid/
    ///
    /// NOTE: marker, flag, and witness fields in segwit transactions are not included
    /// this means txid computation is the same for legacy and segwit tx
    fn txid(self: @Transaction, data: @TransactionData) -> Hash {
        let mut txid_data: ByteArray = Default::default();
        txid_data.append(data.version_encoded);
        txid_data.append(data.inputs_encoded);
        txid_data.append(data.outputs_encoded);
        txid_data.append(data.lock_time_encoded);
        double_sha256_byte_array(@(txid_data))
    }

    /// Compute transaction wTXID
    /// https://learnmeabitcoin.com/technical/transaction/wtxid/
    fn wtxid(self: @Transaction, data: @TransactionData) -> Hash {
        let mut wtxid_data: ByteArray = Default::default();
        wtxid_data.append(data.version_encoded);
        if (*self.is_segwit) {
            wtxid_data.append_byte(0);
            wtxid_data.append_byte(1);
        }
        wtxid_data.append(data.inputs_encoded);
        wtxid_data.append(data.outputs_encoded);
        if (*self.is_segwit) {
            wtxid_data.append(data.witness_encoded);
        }
        wtxid_data.append(data.lock_time_encoded);
        double_sha256_byte_array(@(wtxid_data))
    }

    /// Compute transaction weight
    /// https://learnmeabitcoin.com/technical/transaction/size/
    fn weight(self: @Transaction, data: TransactionData) -> usize {
        let base_size: u32 = data.version_size
            + data.inputs_size
            + data.outputs_size
            + data.lock_time_size;

        let mut witness_size: u32 = 0;
        if (*self.is_segwit) {
            witness_size = data.witness_size + 2;
        }

        let total_size = base_size * 4 + witness_size;
        total_size
    }
}
// TODO: implement Hash trait for OutPoint (for creating hash digests to use in utreexo/utxo cache)
// Maybe we need to rename utils::hash::Hash (e.g. to Digest) to avoid confusion

#[cfg(test)]
mod tests {
    use crate::utils::hex::{from_hex, hex_to_hash_rev};
    use super::{Transaction, TransactionTrait, TxIn, TxOut, OutPoint};

    #[test]
    fn test_encode_tx1() {
        // tx 4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33
        let tx = @Transaction {
            version: 1_u32,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "493046022100838b5bd094d57898d359569af330312e2dd99f8a1db7add92dc1704808625dbf022100978160771ea1e3ffe014e1fa7559f0bb5ffd32f6b63f19225bf3be110c2f2d65014104c273b18442afb2263698a09da205bb7a18f23037f9c285fc789874fe012ac32b40a18f12191a0015f2506b5a395d9845005b90a34a813715e9cc5dbf8024ca18"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "b8a75476112bb2322af0331646100fe44f26fee85f452001589f6d9672b763a7"
                        ),
                        vout: 0_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                },
                TxIn {
                    script: @from_hex(
                        "48304502200b2ff9ed1689c9403b4bf0aca89fa4a53004c2c6ad66b4df25ae8361eef172cc022100c8f5fcd4eeb02762d9b40de1013ad7283042585caec8e60be873689de8e29a4a014104cdadb5199b0d9d356ae03fbf891f28d761547d79a0c5dae24998fa84a147e39f27ce03cd8efd8bd27e9dffc78744d66b2942b76801f79ae4028028e7122a3bb1"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "a7ed5e908fa1951c912fd39cd72a37410ca78fc75de65180b8568a622f4e3a97"
                        ),
                        vout: 1_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                },
                TxIn {
                    script: @from_hex(
                        "493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "66ce602f26ae00d128ea83e5afddf8c1cd226b7148322bb090779199f63f9ff5"
                        ),
                        vout: 1_u32,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span()
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 1050000_u64,
                    pk_script: @from_hex("76a914bafe7b8f25824ff18f698d2878d50c6fc43dd1d088ac"),
                    cached: false,
                },
                TxOut {
                    value: 111950000_u64,
                    pk_script: @from_hex("76a914ef48d8584b96d95992a664d524e52007b036754188ac"),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let data = tx.init_encode();
        let txid = tx.txid(@data);
        let wtxid = tx.wtxid(@data);
        let weight = tx.weight(data);

        let txid_expected = hex_to_hash_rev(
            "4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33"
        );
        let wtxid_expected = hex_to_hash_rev(
            "4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33"
        );
        assert_eq!(txid, txid_expected);
        assert_eq!(wtxid, wtxid_expected);
        assert_eq!(weight, 2480);
    }

    #[test]
    fn test_encode_tx_witness1() {
        // tx 65d8bd45f01bd6209d8695d126ba6bb4f2936501c12b9a1ddc9e38600d35aaa2
        let tx = Transaction {
            version: 2,
            is_segwit: true,
            inputs: array![
                TxIn {
                    script: @from_hex(""),
                    sequence: 0xfffffffd,
                    previous_output: OutPoint {
                        txid: hex_to_hash_rev(
                            "39cc1562b197182429bc1ea312c9e30f1257be6d5159fcd7b375139d3c3fe63c"
                        ),
                        vout: 0x0,
                        data: Default::default(),
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![
                        from_hex(
                            "30440220537f470c1a18dc1a9d233c0b6af1d2ce18a07f3b244e4d9d54e0e60c34c55e67022058169cd11ac42374cda217d6e28143abd0e79549f7b84acc6542817466dc9b3001"
                        ),
                        from_hex(
                            "0301c1768b48843933bd7f0e8782716e8439fc44723d3745feefde2d57b761f503"
                        )
                    ]
                        .span(),
                },
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 102415_u64,
                    pk_script: @from_hex("76a914998db5e1126bc3a5e04109fbf253a7900462410e88ac"),
                    cached: false,
                },
                TxOut {
                    value: 1424857_u64,
                    pk_script: @from_hex("0014579bf4f06510c8683f2451262b6685b00012e46f"),
                    cached: false,
                },
            ]
                .span(),
            lock_time: 679999,
        };

        let data = tx.init_encode();
        let txid = tx.txid(@data);
        let wtxid = tx.wtxid(@data);
        let weight = tx.weight(data);

        let txid_expected = hex_to_hash_rev(
            "65d8bd45f01bd6209d8695d126ba6bb4f2936501c12b9a1ddc9e38600d35aaa2"
        );
        let wtxid_expected = hex_to_hash_rev(
            "f419d5dd07705789da288842de182e63fc0d2ef66f88c4af089d8d055524e470"
        );
        assert_eq!(txid, txid_expected);
        assert_eq!(wtxid, wtxid_expected);
        assert_eq!(weight, 573);
    }
}

