use shinigami_engine::engine::EngineTrait;
use shinigami_engine::engine::EngineImpl;
use shinigami_engine::hash_cache::HashCacheImpl;
use shinigami_engine::flags::ScriptFlags;
use shinigami_engine::transaction::{
    EngineTransactionInputTrait, EngineTransactionOutputTrait, EngineTransactionTrait
};
use crate::types::transaction::{Transaction, TxIn, TxOut};
use crate::types::block::Header;

const BIP_16_BLOCK_HEIGHT: u32 = 173805; // Pay-to-Script-Hash (P2SH) 
const BIP_66_BLOCK_HEIGHT: u32 = 363725; // DER Signatures 
const BIP_65_BLOCK_HEIGHT: u32 = 388381; // CHECKLOCKTIMEVERIFY (CLTV) 
const BIP_112_BLOCK_HEIGHT: u32 = 419328; // CHECKSEQUENCEVERIFY - CSV
const BIP_141_BLOCK_HEIGHT: u32 = 481824; // Segregated Witness - SegWit
const BIP_341_BLOCK_HEIGHT: u32 = 709632; // Taproot

const POW_2_32: u128 = 0x100000000;
const POW_2_64: u128 = 0x10000000000000000;
const POW_2_96: u128 = 0x1000000000000000000000000;

impl EngineTransactionInputImpl of EngineTransactionInputTrait<TxIn> {
    fn get_prevout_txid(self: @TxIn) -> u256 {
        // TODO: hash type in Shinigami
        let [a, b, c, d, e, f, g, h] = *self.previous_output.txid.value;

        let low: u128 = h.into() + g.into() * POW_2_32 + f.into() * POW_2_64 + e.into() * POW_2_96;
        let high: u128 = d.into() + c.into() * POW_2_32 + b.into() * POW_2_64 + a.into() * POW_2_96;

        u256 { low, high }
    }

    fn get_prevout_vout(self: @TxIn) -> u32 {
        *self.previous_output.vout
    }

    fn get_signature_script(self: @TxIn) -> @ByteArray {
        *self.script
    }

    fn get_witness(self: @TxIn) -> Span<ByteArray> {
        *self.witness
    }

    fn get_sequence(self: @TxIn) -> u32 {
        *self.sequence
    }
}

impl EngineTransactionOutputDummyImpl of EngineTransactionOutputTrait<TxOut> {
    fn get_publickey_script(self: @TxOut) -> @ByteArray {
        *self.pk_script
    }

    fn get_value(self: @TxOut) -> i64 {
        Into::<u64, i128>::into(*self.value).try_into().unwrap()
    }
}

impl EngineTransactionDummyImpl of EngineTransactionTrait<Transaction, TxIn, TxOut,> {
    fn get_version(self: @Transaction) -> i32 {
        Into::<u32, i64>::into(*self.version).try_into().unwrap()
    }

    fn get_transaction_inputs(self: @Transaction) -> Span<TxIn> {
        *self.inputs
    }

    fn get_transaction_outputs(self: @Transaction) -> Span<TxOut> {
        *self.outputs
    }

    fn get_locktime(self: @Transaction) -> u32 {
        *self.lock_time
    }
}

fn script_flags(header: @Header, tx: @Transaction) -> u32 {
    let mut script_flags = 0_u32;
    let block_height = tx.inputs[0].previous_output.block_height;

    // Blocks created after the BIP0016 activation time need to have the
    // pay-to-script-hash checks enabled.
    if block_height >= @BIP_16_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptBip16.into();
    }

    // Enforce DER signatures for block versions 3+
    // This is part of BIP0066.
    if header.version >= @3_u32 && block_height >= @BIP_66_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptVerifyDERSignatures.into();
    }

    // Enforce CHECKLOCKTIMEVERIFY for block versions 4+
    // This is part of BIP0065.
    if header.version >= @4_u32 && block_height >= @BIP_65_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptVerifyCheckLockTimeVerify.into();
    }

    // Enforce CHECKSEQUENCEVERIFY if the CSV soft-fork is now active
    //  This is part of BIP0112.
    if block_height >= @BIP_112_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptVerifyCheckSequenceVerify.into();
    }

    // Enforce the segwit soft-fork
    // This is part of BIP0141.
    if block_height >= @BIP_141_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptVerifyWitness.into();
        script_flags += ScriptFlags::ScriptStrictMultiSig.into();
    }

    // Enforce the taproot soft-fork
    // This is part of BIP0341.
    if block_height >= @BIP_341_BLOCK_HEIGHT {
        script_flags += ScriptFlags::ScriptVerifyTaproot.into();
    }

    script_flags
}

fn parse_short_string(short: felt252) -> ByteArray {
    let mut f: u256 = short.into();
    let mut l = 0;
    while f != 0 {
        f = f / 256;
        l += 1;
    };
    let mut parsed: ByteArray = Default::default();
    parsed.append_word(short, l);
    parsed
}

/// Validates script for a given input
fn validate_script(header: @Header, tx: @Transaction, tx_idx: u32) -> Result<(), ByteArray> {
    let cache = HashCacheImpl::new(tx);
    let mut result: Option<ByteArray> = Option::None;
    for input_idx in 0
        ..(*tx.inputs)
            .len() {
                let previous_output = *tx.inputs[input_idx].previous_output;
                let mut engine = EngineImpl::new(
                    previous_output.data.pk_script,
                    tx,
                    input_idx,
                    script_flags(header, tx),
                    Into::<u64, i128>::into(previous_output.data.value).try_into().unwrap(),
                    @cache
                )
                    .unwrap(); //TODO: handle error

                match engine.execute() {
                    Result::Ok(_) => { break; }, // TODO: verify this is correct
                    Result::Err(err) => {
                        result =
                            Option::Some(
                                format!(
                                    "Script validation failed on tx_idx: {}, input_idx: {}: {}",
                                    tx_idx,
                                    input_idx,
                                    parse_short_string(err)
                                )
                            );
                        break;
                    }
                }
            };

    match result {
        Option::Some(err) => Result::Err(err),
        Option::None => Result::Ok(())
    }
}

pub fn validate_scripts(header: @Header, txs: Span<Transaction>) -> Result<(), ByteArray> {
    let mut r = Result::Ok(());
    let mut i = 1;
    for tx in txs {
        r = validate_script(header, tx, i);
        if r.is_err() {
            break;
        }
        i += 1;
    };
    r
}
