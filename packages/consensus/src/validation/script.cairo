use shinigami_engine::engine::EngineImpl;
use shinigami_engine::scriptflags::ScriptFlags;
use shinigami_engine::transaction::{
    EngineTransactionInputTrait, EngineTransactionOutputTrait, EngineTransactionTrait
};
use script::dummy::{HashCacheDummy, HashCacheDummyImpl};
use crate::types::transaction::{Transaction, TxIn, TxOut};
use crate::types::block::Header;

const BIP_16_BLOCK_HEIGHT: u32 = 173805; // Pay-to-Script-Hash (P2SH) 
const BIP_66_BLOCK_HEIGHT: u32 = 363725; // DER Signatures 
const BIP_65_BLOCK_HEIGHT: u32 = 388381; // CHECKLOCKTIMEVERIFY (CLTV) 
const BIP_112_BLOCK_HEIGHT: u32 = 419328; // CHECKSEQUENCEVERIFY - CSV
const BIP_141_BLOCK_HEIGHT: u32 = 481824; // Segregated Witness - SegWit
const BIP_341_BLOCK_HEIGHT: u32 = 709632; // Taproot

impl EngineTransactionInputImpl of EngineTransactionInputTrait<TxIn> {
    fn get_prevout_txid(self: @TxIn) -> u256 {
        0
    }

    fn get_prevout_vout(self: @TxIn) -> u32 {
        0
    }

    fn get_signature_script(self: @TxIn) -> @ByteArray {
        @""
    }

    fn get_witness(self: @TxIn) -> Span<ByteArray> {
        array![].span()
    }

    fn get_sequence(self: @TxIn) -> u32 {
        0
    }
}

impl EngineTransactionOutputDummyImpl of EngineTransactionOutputTrait<TxOut> {
    fn get_publickey_script(self: @TxOut) -> @ByteArray {
        @""
    }

    fn get_value(self: @TxOut) -> i64 {
        0
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
        script_flags += ScriptFlags::ScriptVerifyDERSignatures.into();
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

pub fn validate_authorization(header: @Header, tx: @Transaction) -> Result<(), ByteArray> {
    let cache: HashCacheDummy = HashCacheDummyImpl::new(tx);

    let mut result: Option<ByteArray> = Option::None;
    for i in 0
        ..(*tx.inputs)
            .len() {
                let previous_output = *tx.inputs[i].previous_output;
                let mut engine = EngineImpl::<
                    TxIn, TxOut, Transaction
                >::new(
                    previous_output.data.pk_script,
                    tx,
                    i,
                    script_flags(header, tx),
                    Into::<u64, i128>::into(previous_output.data.value).try_into().unwrap(),
                    @cache
                )
                    .unwrap(); //TODO: handle error

                match EngineImpl::<TxIn, TxOut, Transaction, HashCacheDummy>::execute(ref engine) {
                    Result::Ok(stack) => if stack.len() != 0 {
                        result =
                            Option::Some(format!("Script returned with nonempty stack: {}", stack));
                        break;
                    },
                    Result::Err(err) => {
                        result = Option::Some(format!("Error executing script: {}", err));
                        break;
                    }
                }
            };

    match result {
        Option::Some(err) => Result::Err(err),
        Option::None => Result::Ok(())
    }
}
