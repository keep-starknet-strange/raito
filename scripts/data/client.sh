#!/usr/bin/env bash

#set -e;
#set -o pipefail;

base_dir=".client_cache"

start=${1:-0}
end=${2:-100}
step=${3:-1}
mode=${4:-"light"}
strategy=${5:-"sequential"}

mkdir $base_dir || true

run_client() {
  local initial_height=$1
  local num_blocks=$2
  
  first=$((initial_height+1))
  second=$((initial_height+num_blocks))
  echo -n "Running $mode client on blocks $first — $second ..."

  batch_file=${base_dir}/${mode}_${initial_height}_${num_blocks}.json
  if [ ! -f "$batch_file" ]; then
    python ../../scripts/data/generate_data.py $mode $initial_height $num_blocks true $batch_file
  fi
  
  arguments=$(python ../../scripts/data/format_args.py $batch_file)
  output=$(scarb cairo-run --no-build --package client --function test "$arguments")
  if [[ "$output" == *"FAIL"* ]]; then
    echo " fail"
    echo $output
    exit 1
  else
    echo " ok"
  fi
}

for (( height=start; height<end; height+=step )); do
  if [[ "$strategy" == "sequential" ]]; then
    run_client $height $step
  elif [[ "$strategy" == "random" ]]; then
    random_height=$(( RANDOM * 25 + RANDOM % 25 ))
    run_client $random_height 1
  else
    echo "Unsupported strategy"
    exit 1
  fi
done
