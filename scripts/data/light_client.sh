#!/usr/bin/env bash
set -e;
set -o pipefail;

INPUT_FILE="./scripts/data/light_client_args_170.json"
ARGUMENTS=$(python ./scripts/data/felt_writer.py "$INPUT_FILE")

scarb cairo-run "$ARGUMENTS"