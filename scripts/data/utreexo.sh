#!/usr/bin/env bash

#set -e;
#set -o pipefail;

base_dir=".client_cache"

start=${1:-0}
end=${2:-200}
step=${3:-200}
mode=${4:-"full"}

mkdir $base_dir || true

run_client() {
  local initial_height=$1
  local num_blocks=$2
  
  first=$((initial_height+1))
  second=$((initial_height+num_blocks))
  echo "Running $mode utreexo on blocks $first — $second ..."

  batch_file=${base_dir}/${mode}_${initial_height}_${num_blocks}.json
  if [ ! -f "$batch_file" ]; then
    python ../../scripts/data/generate_data.py $mode $initial_height $num_blocks true true $batch_file
  fi
}

for (( height=start; height<end; height+=step )); do
  run_client $height $step
  python ../../scripts/data/generate_utreexo_data.py \
  ../../packages/client/.client_cache/full_${height}_${step}.json \
  ../../packages/client/tests/utreexo/utreexo_state_${height}_${step}.json
done
