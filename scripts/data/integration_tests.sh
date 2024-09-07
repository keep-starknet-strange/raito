#!/usr/bin/env bash

set -e;

GREEN='\033[0;32m'
RED='\033[1;31m'
RESET='\033[0m' # No Color

num_ok=0
num_fail=0
num_ignored=0
failures=()
test_files="tests/data"/*

ignored_files=(
    "tests/data/light_2015.json"
    "tests/data/light_481823.json"
    "tests/data/light_709631.json"
    "tests/data/full_757738.json"
)
ignored="${ignored_files[@]}"

if [ $# -gt 0 ]; then
    args=("$@")
    test_files="${args[@]}"
fi

for test_file in $test_files; do
    if [ -f "$test_file" ]; then
        echo -n "test e2e:$test_file ..."

        if [[ "$ignored" =~ "$test_file" ]]; then
            echo " ignored"
            num_ignored=$((num_ignored + 1))
        else
            arguments=$(python scripts/data/format_args.py ${test_file})
            output=$(scarb cairo-run --no-build --function test "$arguments")
            gas_spent=$(echo $output | grep -o 'gas_spent=[0-9]*' | sed 's/gas_spent=//')

            if [[ "$output" == *"FAIL"* ]]; then
                echo -e "${RED} fail ${RESET}(gas usage est.: $gas_spent)"
                num_fail=$((num_fail + 1))
                error=$(echo $output | grep -o "error='[^']*'" | sed "s/error=//")
                failures+="\te2e:$test_file — Panicked with $error\n"
            elif [[ "$output" == *"OK"* ]]; then
                echo -e "${GREEN} ok ${RESET}(gas usage est.: $gas_spent)"
                num_ok=$((num_ok + 1))
            else
                echo -e "${RED} fail ${RESET}(gas usage est.: 0)"
                num_fail=$((num_fail + 1))
                error=$(echo "$output" | sed '1d')
                failures+="\te2e:$test_file — $error\n"
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