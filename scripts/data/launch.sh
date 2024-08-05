#! /usr/bin/env bash

destPath="./src/"
tx_inJqPath="./scripts/data/tx_in.jq"
tx_outJqPath="./scripts/data/tx_out.jq"
blockJqPath="./scripts/data/block.jq"
blockHash=""
api="https://mempool.space/api/block/"

if [ ! -z "$1" ]; then
	blockHash="$1"
else
	read -p "Enter bitcoin block hash: " blockHash
fi

fileName="${destPath}block_$blockHash.cairo"


# Recive informations
btcBlock=$(curl -sSL "$api$blockHash")
btcBlockTxs=$(curl -sSL "$api$blockHash/txs")

#total transactions of the block
tx_count=$(echo $btcBlock | jq -r ".tx_count")
echo "Total of transactions: " $tx_count

#Put the header block in file
echo $btcBlock | jq -r -f $blockJqPath > $fileName
echo "		txs: array![" >> $fileName

tx_count=50
#declare at 1 for skipping the coinbase transaction
idx=1
total=1

#Put transactions in file
while (( $total < $tx_count )); do
	if (( $idx % 25 == 0)) then
		btcBlockTxs=$(curl -sSL "$api$blockHash/txs/$total")
		idx=0
		echo "$total / $tx_count transactions recived"
	fi
	tx=$(echo $btcBlockTxs | jq -r ".[$idx]")
	echo "			Transaction {" >> $fileName
	echo "				version: $(echo $tx | jq -r ".version")," >> $fileName
	echo "				lock_time: $(echo $tx | jq -r ".locktime")," >> $fileName
	echo "				inputs: array![" >> $fileName
	echo $tx |  jq -r ".vin[]" | jq -r -f $tx_inJqPath >> $fileName
	echo "				].span()," >> $fileName
	echo "				outputs: array![" >> $fileName
	echo $tx |  jq -r ".vout[]" | jq -r -f $tx_outJqPath >> $fileName
	echo "			].span()," >> $fileName
	echo "			}," >> $fileName
	((idx++))
	((total++))
done
if (( $total == $tx_count)) then
	echo "$total / $tx_count transactions recived"
echo "Execution successful, file created in $fileName"
fi

#end file
echo "		].span()" >> $fileName
echo "	}" >> $fileName
echo "}" >> $fileName
echo ""
echo -e "${green}add: \"pub mod block_$blockHash;\" in lib.cairo${reset}"
echo -e "${green}add: \"use raito::block_$blockHash::test_data_block;\" in your file${reset}"
