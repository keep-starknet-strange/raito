//! Block time validation helpers.
//!
//! Read more: https://learnmeabitcoin.com/technical/block/time/
/// Check that the block time is greater than the median of the 11 most recent timestamps.
pub fn validate_timestamp(prev_timestamps: Span<u32>, block_time: u32) -> Result<(), ByteArray> {
    // Sort the last 11 timestamps
    // adapted from :
    // https://github.com/keep-starknet-strange/alexandria/blob/main/packages/sorting/src/bubble_sort.cairo
    let mut idx1 = 0;
    let mut idx2 = 1;
    let mut sorted_iteration = true;
    let mut prev_timestamps: Span<u32> = prev_timestamps.clone();
    let mut sorted_prev_timestamps: Array<u32> = array![];

    loop {
        if idx2 == prev_timestamps.len() {
            sorted_prev_timestamps.append(*prev_timestamps[idx1]);
            if sorted_iteration {
                break;
            }
            prev_timestamps = sorted_prev_timestamps.span();
            sorted_prev_timestamps = array![];
            idx1 = 0;
            idx2 = 1;
            sorted_iteration = true;
        } else {
            if *prev_timestamps[idx1] <= *prev_timestamps[idx2] {
                sorted_prev_timestamps.append(*prev_timestamps[idx1]);
                idx1 = idx2;
                idx2 += 1;
            } else {
                sorted_prev_timestamps.append(*prev_timestamps[idx2]);
                idx2 += 1;
                sorted_iteration = false;
            }
        };
    };

    if block_time > *sorted_prev_timestamps.at(sorted_prev_timestamps.len() - 6) {
        Result::Ok(())
    } else {
        Result::Err("Median time is greater than or equal to block's timestamp")
    }
}

#[cfg(feature: 'log_level_debug')]
fn macro_test() {
    let txid = 1000;
    log!("DEBUG", "validating tx: {}", txid);
}

#[cfg(feature: 'log_level_trace', feature: 'log_level_debug')]
fn log(log_level: ByteArray, format_array: ByteArray,) {
    let txid = 1000;
    log!("DEBUG", "validating tx: {}", txid);
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
    fn test_validate_timestamp_single_unchronological() {
        let prev_timestamps = array![1, 2, 3, 4, 5, 7, 6, 8, 9, 10, 11].span();
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

    #[test]
    fn test_validate_timestamp_unsorted() {
        let prev_timestamps = array![1, 3, 2, 5, 4, 6, 8, 7, 9, 10, 11].span();
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
