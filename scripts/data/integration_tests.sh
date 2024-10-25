#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[1;31m'
RESET='\033[0m' # No Color

num_ok=0
num_fail=0
num_ignored=0
failures=()
test_files=()
nocapture=0
execute_scripts=0
forceall=0
fullonly=0

# Process arguments
for arg in "$@"; do
  if [[ "$arg" == "--nocapture" ]]; then
    nocapture=1
  elif [[ "$arg" == "--fullonly" ]]; then
    fullonly=1
  elif [[ "$arg" == "--forceall" ]]; then
    forceall=1
  elif [[ "$arg" == "--execute_scripts" ]]; then
    execute_scripts=1
  else
    test_files+=("$arg")  # Add only non-flag arguments as test files
  fi
done

ignored_files=(
    "tests/data/full_209999.json", #cairo-run dies, to be investigated
    "tests/data/full_403199.json", #cairo-run dies, to be investigated
    "tests/data/full_481823.json", #cairo-run dies, to be investigated
    "tests/data/full_489888.json", #cairo-run dies, to be investigated
    "tests/data/full_491406.json", #cairo-run dies, to be investigated
    "tests/data/full_629999.json", #cairo-run dies, to be investigated
    "tests/data/full_709631.json", #cairo-run dies, to be investigated
    "tests/data/full_774627.json", # Couldn't compute operand op1. Unknown value for memory cell 1:131082
    "tests/data/full_839999.json", # Couldn't compute operand op1. Unknown value for memory cell 1:262154
    "tests/data/full_116927.json", # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_150012.json", # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_2015.json",   # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_24834.json",  # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_32255.json",  # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_478557.json", # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_57042.json",  # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_72575.json",  # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/full_757752.json", # Run panicked with [108217864776563 ('blocks'), ]. 
    "tests/data/utreexo_169.json", # Unexpected root (TODO: create issue)
    # "tests/data/full_478557.json", #runs on server
)
ignored="${ignored_files[@]}"

# If no test files are explicitly specified, default to tests/data/*
if [[ $fullonly -eq 1 && ${#test_files[@]} -eq 0 ]]; then
  test_files=("tests/data"/full*)
elif [[ ${#test_files[@]} -eq 0 ]]; then
  test_files=("tests/data"/*)
fi

if [[ $execute_scripts -eq 1 ]]; then
    echo "running integration tests (with scripts) ..."
else
    echo "running integration tests ..."
fi

for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        echo -n "test $test_file ..."
        if [[ $forceall -ne 1 && "$ignored" =~ "$test_file" ]]; then
            echo " ignored"
            num_ignored=$((num_ignored + 1))
        else
            arguments_file="$(dirname "$test_file")/.arguments-$(basename "$test_file")"
            python ../../scripts/data/format_args.py --input_file ${test_file} $([[ $execute_scripts -eq 1 ]] && echo "--execute_script") > $arguments_file
            output=$(scarb cairo-run --no-build --function main --arguments-file $arguments_file)
            gas_spent=$(echo $output | grep -o 'gas_spent=[0-9]*' | sed 's/gas_spent=//')

            if [[ "$nocapture" -eq 1 ]]; then
                echo -e "\n$output"
            fi

            if [[ "$output" == *"FAIL"* ]]; then
                echo -e "${RED} fail ${RESET}(gas usage est.: $gas_spent)"
                num_fail=$((num_fail + 1))
                error=$(echo $output | grep -o "error='[^']*'" | sed "s/error=//")
                failures+="\t$test_file — Panicked with $error\n"
            elif [[ "$output" == *"OK"* ]]; then
                echo -e "${GREEN} ok ${RESET}(gas usage est.: $gas_spent)"
                num_ok=$((num_ok + 1))
                rm $arguments_file
            else
                echo -e "${RED} fail ${RESET}(gas usage est.: 0)"
                num_fail=$((num_fail + 1))
                error=$(echo "$output" | sed '1d' | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g') #spellchecker:disable-line
                failures+="\t$test_file — $error\n"
            fi
        fi
    fi
done

if [[ $num_fail == 0 ]]; then
    echo -e "test result: ${GREEN}ok${RESET}. ${num_ok} passed; 0 failed; ${num_ignored} ignored"
else
    echo -e "failures:\n$failures"
    echo -e "test result: ${RED}FAILED${RESET}. ${num_ok} passed; ${num_fail} failed; ${num_ignored} ignored"
    false
fi