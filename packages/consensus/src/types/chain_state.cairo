//! Chain state is a minimal subset of data required to unambiguously
//! define a particular blockchain starting at the genesis.
//!
//! Chain state alone is not enough to do full block validation, however
//! it is sufficient to validate block headers.

use core::fmt::{Display, Error, Formatter};
use utils::blake2s::blake2s_32;
use utils::hash::{Digest, DigestTrait};
use utils::numeric::u128_to_u32_array;

/// Represents the state of the blockchain.
#[derive(Drop, Copy, Debug, PartialEq, Serde)]
pub struct ChainState {
    /// Height of the current block.
    pub block_height: u32,
    /// Total work done.
    pub total_work: u256,
    /// Best block.
    pub best_block_hash: Digest,
    /// Current target.
    pub current_target: u256,
    /// Start of the current epoch.
    pub epoch_start_time: u32,
    /// List of 11 most recent block timestamps (from oldest to newest).
    ///
    /// Note that timestamps *do not* influence the order of blocks, i.e.
    /// it's possible that one block could have an earlier timestamp
    /// than a block that came before it in the chain.
    pub prev_timestamps: Span<u32>,
}

/// `ChainState` Poseidon hash implementation.
#[generate_trait]
pub impl ChainStateHashImpl of ChainStateHashTrait {
    /// Serialize the chain state into a sequence of u32 numbers.
    fn to_u32_array(self: @ChainState) -> Array<u32> {
        let mut dest: Array<u32> = array![];
        dest.append(*self.block_height);
        dest.append_span(u128_to_u32_array(*self.total_work.high).span());
        dest.append_span(u128_to_u32_array(*self.total_work.low).span());
        dest.append_span((*self.best_block_hash).span());
        dest.append_span(u128_to_u32_array(*self.current_target.high).span());
        dest.append_span(u128_to_u32_array(*self.current_target.low).span());
        dest.append(*self.epoch_start_time);
        dest.append_span(*self.prev_timestamps);
        dest
    }

    /// Hash the chain state using Blake2s.
    fn hash(self: @ChainState) -> Digest {
        blake2s_32(self.to_u32_array().span())
    }
}

/// `Default` implementation of `ChainState` representing the initial state after genesis block.
/// https://github.com/bitcoin/bitcoin/blob/ee367170cb2acf82b6ff8e0ccdbc1cce09730662/src/kernel/chainparams.cpp#L99
impl ChainStateDefault of Default<ChainState> {
    fn default() -> ChainState {
        ChainState {
            block_height: 0,
            total_work: 4295032833,
            best_block_hash: 0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f_u256
                .into(),
            current_target: 0x00000000ffff0000000000000000000000000000000000000000000000000000_u256,
            epoch_start_time: 1231006505,
            prev_timestamps: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1231006505].span(),
        }
    }
}

/// `Display` trait implementation for `ChainState`.
impl ChainStateDisplay of Display<ChainState> {
    fn fmt(self: @ChainState, ref f: Formatter) -> Result<(), Error> {
        let mut prev_ts: ByteArray = Default::default();
        for ts in *self.prev_timestamps {
            prev_ts.append(@format!("{},", ts));
        }
        let str: ByteArray = format!(
            "
	block_height: {}
	total_work: {}
	best_block_hash: {}
	current_target: {}
	epoch_start_time: {}
	prev_timestamps: [{}]
}}",
            *self.block_height,
            *self.total_work,
            *self.best_block_hash,
            *self.current_target,
            *self.epoch_start_time,
            @prev_ts,
        );
        f.buffer.append(@str);
        Result::Ok(())
    }
}
