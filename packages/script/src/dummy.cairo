use crate::types::{
    EngineTransactionInput, EngineTransactionOutput, EngineTransaction, HashCache, Engine
};

#[derive(Drop)]
struct HashCacheDummy {}

impl HashCacheDummyImpl<
    I,
    O,
    T,
    +Drop<T>,
    +EngineTransactionInput<I>,
    +EngineTransactionOutput<O>,
    +EngineTransaction<T, I, O>,
> of HashCache<HashCacheDummy, I, O, T> {
    fn new(transaction: T) -> HashCacheDummy {
        HashCacheDummy {}
    }

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
    O,
    T,
    +Drop<T>,
    +EngineTransactionInput<I>,
    +EngineTransactionOutput<O>,
    +EngineTransaction<T, I, O>,
> of Engine<EngineDummy, I, O, T, HashCacheDummy> {
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
