#!/usr/bin/env bash
set -e;
set -o pipefail;

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
	PREV_BLOCK_HEADER=$(curl -X POST -s --user $USERPWD -H 'Content-Type: application/json' -d '{"method": "getblockheader","params": ["'$(echo $RAW_TX | jq -r '.blockhash')'"],"jsonrpc": "1.0"}' $BITCOIN_RPC | jq -r '.result')

	VOUT=$(echo $TX_INPUT | jq -r ".vout")
	PREV_INPUT=$(echo $RAW_TX |jq -r ".vout.[${VOUT}]")
	TXO_INDEX=$(echo $RAW_TX | jq -r ".vout[$VOUT].n")
	BLOCK_HEIGHT=$(echo $PREV_BLOCK_HEADER | jq -r '.height')
	BLOCK_TIME=$(echo $PREV_BLOCK_HEADER | jq -r '.time')
	VALUE_PREV_INPUT=$(echo $PREV_INPUT | jq -r '.value | tonumber * 10000000 | round')
	PKSCRIPT_PREV_INPUT=$(echo $PREV_INPUT | jq -r '.scriptPubKey.hex')
	OUTPOINT_DATA="OutPoint {\n\
		txid: 0x${TX_INPUT_ID}_u256.into(),\n\
		vout: ${VOUT}_u32,\n\
		block_height: ${BLOCK_HEIGHT}_u32,\n\
		block_time: ${BLOCK_TIME}_u32,\n\
		data: TxOut {\n\
		\tvalue: ${VALUE_PREV_INPUT}_u64,\n\
		\tpk_script: @from_hex(\"${PKSCRIPT_PREV_INPUT}\"),\n\
		\tcached: false\n\
		}\n\
	}"
	sed -i "0,/OUTPOINT_KEY/{s/OUTPOINT_KEY/$OUTPOINT_DATA/}" "tests/blocks/block_${HEIGHT}.cairo"
	J=$(($J + 1))
done
