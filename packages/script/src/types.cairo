// HashCache caches the midstate of segwit v0 and v1 sighashes
pub trait HashCache<
    C,
    I,
    O,
    T,
    +EngineTransactionInput<I>,
    +EngineTransactionOutput<O>,
    +EngineTransaction<T, I, O>,
> {
    fn new(transaction: T) -> C;

    // v0 represents sighash midstate used in the base segwit signatures BIP-143
    fn get_hash_prevouts_v0(self: C) -> u256;
    fn get_hash_sequence_v0(self: C) -> u256;
    fn get_hash_outputs_v0(self: C) -> u256;

    // v1 represents sighash midstate used to compute taproot signatures BIP-341
    fn get_hash_prevouts_v1(self: C) -> u256;
    fn get_hash_sequence_v1(self: C) -> u256;
    fn get_hash_outputs_v1(self: C) -> u256;
    fn get_hash_input_scripts_v1(self: C) -> u256;
}

pub trait EngineTransactionInput<I> {
    fn get_prevout_txid(self: I) -> u256;
    fn get_prevout_vout(self: I) -> u32;
    fn get_signature_script(self: I) -> ByteArray;
    fn get_witness(self: I) -> Span<ByteArray>;
    fn get_sequence(self: I) -> u32;
}

pub trait EngineTransactionOutput<O> {
    fn get_publickey_script(self: O) -> ByteArray;
    fn get_value(self: O) -> i64;
}

pub trait EngineTransaction<T, I, O, +EngineTransactionInput<I>, +EngineTransactionOutput<O>> {
    fn get_version(self: T) -> i32;
    fn get_transaction_inputs(self: T) -> Span<I>;
    fn get_transaction_outputs(self: T) -> Span<O>;
    fn get_locktime(self: T) -> u32;
}

pub trait Engine<
    E,
    I,
    O,
    T,
    C,
    +EngineTransactionInput<I>,
    +EngineTransactionOutput<O>,
    +EngineTransaction<T, I, O>,
    +HashCache<C, I, O, T>
> {
    // Create a new Engine with the given script
    fn new(
        script_pubkey: @ByteArray,
        transaction: T,
        tx_idx: u32,
        flags: u32,
        amount: i64,
        hash_cache: C
    ) -> Result<E, felt252>;
    // Executes the entire script and returns top of stack or error if script fails
    fn execute(ref self: E) -> Result<ByteArray, felt252>;
}
