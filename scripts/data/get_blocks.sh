#!/usr/bin/env bash
set -e;
set -o pipefail;

get_single_block() {
    local block_hash=$1
    ./scripts/data/get_block.sh "$block_hash"
}

main() {
    local block_hashes=(
        "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"  # Genesis block
        "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"  # Block containing first P2P tx to Hal Finney
    )

    # Loop through the block hashes and call get_block.sh for each
    for block_hash in "${block_hashes[@]}"; do
        echo "Getting block: $block_hash"
        get_single_block "$block_hash"
    done

    echo "All blocks retrieved successfully."
}

main