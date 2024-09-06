#!/usr/bin/env bash

set -e;
set -o pipefail;

if [ -f .env ]
then
  export $(cat .env | xargs)
fi

force=0

if [[ "$1" == "--force" ]]; then
  force=1
fi

light_test_cases=(
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

full_test_cases=(
    169     # Block containing first P2P tx to Hal Finney (170)
    757738  # Block with witness (757739)
)

mkdir tests/data || true

# Generate test file if it does not exist yet or if "force" flag is set
generate_test() {
  local mode=$1
  local height=$2
  test_file="tests/data/${mode}_${test_case}.json"
  if [[ ! -f "$test_file" || $force -eq 1 ]]; then
    python scripts/data/generate_data.py $mode $height 1 true $test_file
  fi
}

for test_case in "${light_test_cases[@]}"; do
    echo "Generating test data: light mode, chain state @ $test_case, single block"
    generate_test "light" $test_case
done

for test_case in "${full_test_cases[@]}"; do
    echo "Generating test data: full mode, chain state @ $test_case, single block"
    generate_test "full" $test_case
done