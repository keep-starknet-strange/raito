#!/usr/bin/env bash
set -e;
set -o pipefail;

get_single_block() {
    local block_hash=$1
    ./scripts/data/get_block.sh "$block_hash"
}

main() {
    local block_hashes=(
        "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"  # Genesis block (0)
        "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"  # Block containing first P2P tx to Hal Finney (170)
        "00000000132fbe8314fc571c0be60b31ccd461c9ee85f42bde8c6d160a9dacc0"  # Bloc containing first off ramp tx from Martti Malmi (24835)
        "00000000152340ca42227603908689183edc47355204e7aca59383b0aaac1fd8"  # Block containing pizza tx (57043)
        "000000000000048b95347e83192f69cf0366076336c639f9b7228e9ba171342e"  # First halving block (210000)
        # "000000000000000002cce816c0ab2c5c269cb081896b7dcb34b8422d6b74ffa1"  # Second halving block (420000)
        # "0000000000000000011865af4122fe3b144e2cbeea86142e8ff2fb4107352d43"  # Bitcoin Cash hard fork block (478558)
        # "0000000000000000001c8018d9cb3b742ef25114f27563e3fc4a1902167f9893"  # Segwit soft fork block (481824)
        # "000000000000000000e5438564434edaf41e63829a637521a96235adf4653e1b"  # Bitcoin Gold hard fork block (491407)
        # "000000000000000000024bead8df69990852c202db0e0097c1a12ea637d7e96d"  # Third halving block (630000)
        # "0000000000000000000687bca986194dc2c1f949318629b44bb54ec0a94d8244"  # Taproot soft fort block (709632)
        # "0000000000000000000515e202c8ae73c8155fc472422d7593af87aa74f2cf3d"  # Biggest block in Bitcoin history - Taproot Wizards (774628)
        # "0000000000000000000320283a032748cef8227873ff4872689bf23f1cda83a5"  # Fourth halving block (840000)
    )

    # Loop through the block hashes and call get_block.sh for each
    for block_hash in "${block_hashes[@]}"; do
        echo "Getting block: $block_hash"
        get_single_block "$block_hash"
    done

    echo "All blocks retrieved successfully."
}

main