#! /usr/bin/env bash
set -e;
set -o pipefail;

HEIGHT=$(curl -s --user $USERPWD -s -d '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockheader", "params": ["'${1}'"] }' -H 'content-type: text/plain;' $BITCOIN_RPC | jq -r '.result.height')

curl \
 -s \
 --user $USERPWD \
 -d '{
    "jsonrpc": "1.0", 
    "id": "curltest", 
    "method": "getblock", 
    "params": ["'${1}'", 2]
    }' \
 -H 'content-type: text/plain;' $BITCOIN_RPC \
 | jq -r -f scripts/data/block_filter.jq > tests/blocks/block_${HEIGHT}.cairo