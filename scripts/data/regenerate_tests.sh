#!/usr/bin/env bash

set -e;
set -o pipefail;

if [ -f .env ]
then
  export $(cat .env | xargs)
fi

force=0
data_dir="tests/data"

if [[ "$1" == "--force" ]]; then
  force=1
fi

light_test_cases=(
    169     # Block containing first P2P tx to Hal Finney (170)
    2015    # First new epoch (2016)
    24834   # Block containing first off ramp tx from Martti Malmi (24835)
    32255   # First target adjustment (32256)
    57042   # Block containing pizza tx (57043)
    72575   # Difficulty adjustment
    116927  # Difficulty adjustment
    150012  # Small Block (150013)
    209999  # First halving block (210000)
    403199  # Difficulty adjustment
    478557  # Bitcoin Cash hard fork block (478558)
    481823  # Segwit soft fork block (481824)
    489888  # Special target bits case https://learnmeabitcoin.com/explorer/489888#blockchain
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
    2015    # First new epoch (2016)
    24834   # Block containing first off ramp tx from Martti Malmi (24835)
    32255   # First target adjustment (32256)
    57042   # Block containing pizza tx (57043)
    72575   # Difficulty adjustment
    116927  # Difficulty adjustment
    150012  # Small Block (150013)
    209999  # First halving block (210000)
    403199  # Difficulty adjustment
    478557  # Bitcoin Cash hard fork block (478558)
    481823  # Segwit soft fork block (481824)
    489888  # Special target bits case https://learnmeabitcoin.com/explorer/489888#blockchain
    491406  # Bitcoin Gold hard fork block (491407)
    629999  # Third halving block (630000)
    709631  # Taproot soft fort block (709632)
    757738  # Block with witness (757739)
    757752  # Block with witnesses, 81txs (757753)
    774627  # Biggest block in Bitcoin history - Taproot Wizards (774628)
    839999  # Fourth halving block (840000)
)

utreexo_test_cases=(
    169      # Block containing first P2P tx to Hal Finney (170)
)

mkdir $data_dir || true

# Generate test file if it does not exist yet or if "force" flag is set
generate_test() {
  local mode=$1
  local height=$2
  local num_blocks=${3:-1}
  test_file="${data_dir}/${mode}_${test_case}.json"
  if [[ ! -f "$test_file" || $force -eq 1 ]]; then
    python ../../scripts/data/generate_data.py --fast --mode $mode --height $height --num_blocks $num_blocks --output_file $test_file
  fi
}

for test_case in "${light_test_cases[@]}"; do
    echo -e "\nGenerating test data: light mode, chain state @ $test_case, single block"
    generate_test "light" $test_case
done

for test_case in "${full_test_cases[@]}"; do
    echo -e "\nGenerating test data: full mode, chain state @ $test_case, single block"
    generate_test "full" $test_case
done

for test_case in "${utreexo_test_cases[@]}"; do
    echo -e "\nGenerating test data: utreexo mode, chain state @ $test_case, single block"
    generate_test "utreexo" 0 $(($test_case+1))
done
