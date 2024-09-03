//! Block time validation helpers.
//!
//! Read more: https://learnmeabitcoin.com/technical/block/time/
use core::dict::Felt252Dict;

/// Check that the block time is greater than the median of the 11 most recent timestamps.
pub fn validate_timestamp(prev_timestamps: Span<u32>, block_time: u32) -> Result<(), ByteArray> {
    // FIXME: it's possible that one block could have an earlier timestamp
    // than a block that came before it in the chain. Example:
    //   - Block 156,114 = 05 Dec 2011, 06:17 (1 hour 59 minutes "before" the previous block)
    //   - Block 156,113 = 05 Dec 2011, 08:16
    //
    // So we cannot assume the list of previous timestamps is sorted.
    // We still want to preserve the "queue" semantics, so we cannot do sorted insert.
    // Thus we need to sort the items in the prev_timestamps before picking a median.
    // sort the prev_timestamps
    let mut sorted_prev_timestamps: Array<u32> = array![];
    let mut visited: Felt252Dict<bool> = Default::default();
    while sorted_prev_timestamps.len() != prev_timestamps.len() {
        let mut min_idx: Option<u32> = Option::None;
        for i in 0..prev_timestamps.len() {
            if !visited.get(i.into()) {
                if min_idx.is_none() || prev_timestamps[i] < prev_timestamps[min_idx.unwrap()] {
                    min_idx = Option::Some(i);
                }
            }
        };
        if let Option::Some(idx) = min_idx {
            sorted_prev_timestamps.append(*prev_timestamps[idx]);
            visited.insert(idx.into(), bool::True);
        } else {
            break;
        }
    };
    
    if block_time > *sorted_prev_timestamps.at(sorted_prev_timestamps.len() - 6) {
        Result::Ok(())
    } else {
        Result::Err("Median time is greater than or equal to block's timestamp")
    }
}

/// Update the list of the recent timestamps, removing the oldest and appending the most recent one.
pub fn next_prev_timestamps(prev_timestamps: Span<u32>, block_time: u32) -> Span<u32> {
    let mut timestamps: Array<u32> = prev_timestamps.into();
    timestamps.pop_front().unwrap(); // remove the oldest timestamp (not necessarily the min)
    timestamps.append(block_time); //  append the most recent timestamp (not necessarily the max)
    timestamps.span()
}

#[cfg(test)]
mod tests {
    use super::{validate_timestamp, next_prev_timestamps};

    #[test]
    fn test_validate_timestamp() {
        let prev_timestamps = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].span();
        let mut block_time = 12_u32;

        // new timestamp is greater than the last timestamp
        let result = validate_timestamp(prev_timestamps, block_time);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is strictly greater than the median of the last 11 timestamps
        block_time = 7;
        let result = validate_timestamp(prev_timestamps, block_time);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is equal to the median of the last 11 timestamps
        block_time = 6;
        let result = validate_timestamp(prev_timestamps, block_time);
        assert!(result.is_err(), "Median time is greater than block's timestamp");
    }

    #[test]
    fn test_next_prev_timstamps() {
        let prev_timestamps = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].span();
        let mut block_time = 12_u32;

        let next_prev_timestamps = next_prev_timestamps(prev_timestamps, block_time);
        assert_eq!(next_prev_timestamps.len(), 11);
        assert_eq!(next_prev_timestamps, array![2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].span());
    }

    #[test]
    fn test_validate_timestamp_unchronological(){
        let prev_timestamps = array![1,2,3,4,5,7,6,8,9,10,11].span();
        let mut block_time = 12_u32;


        // new timestamp is greater than the last timestamp
        let result = validate_timestamp(prev_timestamps, block_time);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is strictly greater than the median of the last 11 timestamps(sorted)
        block_time = 7;
        let result = validate_timestamp(prev_timestamps, block_time);
        assert(result.is_ok(), 'Expected target to be valid');

        // new timestamp is equal to the median of the last 11 timestamps(sorted)
        block_time = 6;
        let result = validate_timestamp(prev_timestamps, block_time);
        assert!(result.is_err(), "Median time is greater than block's timestamp");
    }
}
