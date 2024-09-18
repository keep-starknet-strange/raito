use shinigami_engine::transaction::{
    EngineTransactionInputTrait, EngineTransactionOutputTrait, EngineTransactionTrait
};
use shinigami_engine::engine::{HashCacheTrait, EngineTrait};

#[derive(Drop)]
pub struct HashCacheDummy {}

pub impl HashCacheDummyImpl<
    I,
    O,
    T,
    +Drop<T>,
    +EngineTransactionInputTrait<I>,
    +EngineTransactionOutputTrait<O>,
    +EngineTransactionTrait<T, I, O>,
> of HashCacheTrait<HashCacheDummy, I, O, T> {
    fn new(transaction: @T) -> HashCacheDummy {
        HashCacheDummy {}
    }

    fn get_hash_prevouts_v0(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_sequence_v0(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_outputs_v0(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_prevouts_v1(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_sequence_v1(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_outputs_v1(self: @HashCacheDummy) -> u256 {
        0
    }

    fn get_hash_input_scripts_v1(self: @HashCacheDummy) -> u256 {
        0
    }
}

#[derive(Drop)]
pub struct EngineDummy {}

pub impl EngineDummyImpl<
    I,
    O,
    T,
    +Drop<T>,
    +EngineTransactionInputTrait<I>,
    +EngineTransactionOutputTrait<O>,
    +EngineTransactionTrait<T, I, O>,
> of EngineTrait<EngineDummy, I, O, T, HashCacheDummy> {
    fn new(
        script_pubkey: @ByteArray,
        transaction: @T,
        tx_idx: u32,
        flags: u32,
        amount: i64,
        hash_cache: @HashCacheDummy
    ) -> Result<EngineDummy, felt252> {
        Result::Ok(EngineDummy {})
    }

    fn execute(ref self: EngineDummy) -> Result<ByteArray, felt252> {
        Result::Ok("")
    }
}
