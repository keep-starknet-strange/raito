use crate::types::{
    EngineTransactionInputTrait, EngineTransactionOutputTrait, EngineTransactionTrait,
    HashCacheTrait, EngineTrait
};

struct HashCacheDummy {}

impl HashCacheDummyImpl of HashCacheTrait<HashCacheDummy> {
    fn get_hash_prevouts_v0(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_sequence_v0(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_outputs_v0(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_prevouts_v1(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_sequence_v1(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_outputs_v1(self: HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_input_scripts_v1(self: HashCacheDummy) -> u256 {
        0
    }
}

#[derive(Drop)]
struct EngineDummy {}


impl EngineDummyImpl<
    I,
    impl IEngineTransactionInput: EngineTransactionInputTrait<I>,
    O,
    impl IEngineTransactionOutput: EngineTransactionOutputTrait<O>,
    T,
    impl IEngineTransaction: EngineTransactionTrait<
        T, I, IEngineTransactionInput, O, IEngineTransactionOutput
    >,
    HashCacheDummy,
    impl IHashCache: HashCacheTrait<
        HashCacheDummy, I, IEngineTransactionInput, O, IEngineTransactionOutput, T
    >
> of EngineTrait<
    EngineDummy,
    I,
    IEngineTransactionInput,
    O,
    IEngineTransactionOutput,
    T,
    IEngineTransaction,
    HashCacheDummy,
    IHashCache
> {
    fn new(
        script_pubkey: @ByteArray,
        transaction: T,
        tx_idx: u32,
        flags: u32,
        amount: i64,
        hash_cache: HashCacheDummy
    ) -> Result<EngineDummy, felt252> {
        Result::Ok(EngineDummy {})
    }

    fn execute(ref self: EngineDummy) -> Result<ByteArray, felt252> {
        Result::Ok("")
    }
}
