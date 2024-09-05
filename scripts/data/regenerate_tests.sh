#!/usr/bin/env bash

set -e;
set -o pipefail;

if [ -f .env ]
then
  export $(cat .env | xargs)
fi

test_cases=(
    169     # Block containing first P2P tx to Hal Finney (170)
    24834   # Block containing first off ramp tx from Martti Malmi (24835)
    57042   # Block containing pizza tx (57043)
    150012  # Small Block (150013)
    209999  # First halving block (210000)
    478557  # Bitcoin Cash hard fork block (478558)
    481823  # Segwit soft fork block (481824)
    491406  # Bitcoin Gold hard fork block (491407)
    629999  # Third halving block (630000)
    709631  # Taproot soft fort block (709632)
    757738  # Block with witness (757739)
    757752  # Block with witnesses, 81txs (757753)
    774627  # Biggest block in Bitcoin history - Taproot Wizards (774628)
    839999  # Fourth halving block (840000)
)

mkdir tests/data || true

# Loop through the test cases and generate data
for test_case in "${test_cases[@]}"; do
    echo "Generating test data: light mode, chain state @ $test_case, single block"
    python scripts/data/generate_data.py "light" $test_case 1 true tests/data/light_${test_case}.json
done

# TODO: generate more full blocks
python scripts/data/generate_data.py "full" $test_case 1 true tests/data/full_169.json