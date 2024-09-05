#!/usr/bin/env bash

set -e;
set -o pipefail;

batch_size=50

mkdir .light_client || true

for (( height=0; height<=1000; height+=batch_size )); do
  echo "Validating blocks $height — $((height+batch_size))"
  batch_file=.light_client/${height}_${batch_size}.json
  if [ ! -f "$batch_file" ]; then
    echo "Downloading blocks"
    python scripts/data/generate_data.py "light" $height $batch_size false $batch_file
  fi
  echo "Running client"
  arguments=$(python scripts/data/format_args.py $batch_file)
  scarb cairo-run --no-build "$arguments"
done
