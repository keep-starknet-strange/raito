#!/usr/bin/env bash
set -e
set -o pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <block_hash>"
	exit 1
fi

BITCOIN_RPC="${BITCOIN_RPC}"
USERPWD="${USERPWD}"
BLOCK_HASH=$1

BLOCK=$(curl -s --user $USERPWD -d '{"jsonrpc": "1.0", "method": "getblock", "params": ["'${BLOCK_HASH}'", 2]}' -H 'content-type: application/json;' $BITCOIN_RPC | jq -r '.result')
HEIGHT=$(echo $BLOCK | jq -r '.height')

echo $BLOCK | jq -r -f ./scripts/data/block_filter.jq > "tests/blocks/block_${HEIGHT}.cairo"

N_TXS=$(echo $BLOCK | jq -r '.nTx | tonumber')
I=0
J=0
while (( $I < $N_TXS )); do
	TX=$(echo $BLOCK | jq -r ".tx[$I]")
	TX_INPUT=$(echo $TX | jq -r ".vin[$J]")
	if [[ "$TX_INPUT" == "null" ]]; then
		I=$(($I + 1))
		J=0
		echo "$I / $N_TXS Txs collected"
		continue
	fi
	IS_COINBASE=$(echo $TX_INPUT | jq -r '.coinbase')
	if [[ "$IS_COINBASE" != "null" ]]; then
		J=$(($J + 1))
		continue
	fi

	TX_INPUT_ID=$(echo $TX_INPUT | jq -r '.txid')
	RAW_TX=$(curl -X POST -s --user $USERPWD -H 'Content-Type: application/json' -d '{"method": "getrawtransaction","params": ["'$TX_INPUT_ID'", true],"jsonrpc": "1.0"}' $BITCOIN_RPC | jq -r '.result')
	VOUT=$(echo $TX_INPUT | jq -r ".vout")
	AMOUNT=$(echo $RAW_TX | jq -r ".vout[$VOUT].value | tonumber * 10000000 | round")
	TXO_INDEX=$(echo $RAW_TX | jq -r ".vout[$VOUT].n")

	OUTPOINT_DATA="OutPoint {\n\
		txid: 0x${TX_INPUT_ID}_u256.into(),\n\
		vout: ${VOUT}_u32,\n\
		txo_index: ${TXO_INDEX},\n\
		amount: ${AMOUNT}\n\
	}"
	sed -i "0,/OUTPOINT_KEY/{s/OUTPOINT_KEY/$OUTPOINT_DATA/}" "tests/blocks/block_${HEIGHT}.cairo"
	J=$(($J + 1))
done
