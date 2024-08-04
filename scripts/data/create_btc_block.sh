#! /usr/bin/env bash

path="./"
blockHash=""
api="https://mempool.space/api/block/"

if $1; then
	blockHash=$1
else
	read -p "Enter bitcoin block hash: " blockHash
fi
blockHash="000000000000000019006062b88e3e5a3b99bd98aa149eb143d6335d382cd91f"

fileName="block_$blockHash.cairo"


# Recive informations
btcBlock=$(curl -sSL "$api$blockHash")
btcBlockTxs=$(curl -sSL "$api$blockHash/txs")

#total transactions of the block
tx_count=$(echo $btcBlock | jq -r ".tx_count")
echo "Total of transactions: " $tx_count

#Put the header block in file
echo $btcBlock | jq -r -f ./block.jq > $fileName
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
		echo "$total / $tx_count transactions recives"
	fi
	tx=$(echo $btcBlockTxs | jq -r ".[$idx]")
	echo "			Transaction {" >> $fileName
	echo "				version: $(echo $tx | jq -r ".version")," >> $fileName
	echo "				lock_time: $(echo $tx | jq -r ".locktime")," >> $fileName
	echo "				inputs: array![" >> $fileName
	echo $tx |  jq -r ".vin[]" | jq -r -f tx_in.jq >> $fileName
	echo "				].span()," >> $fileName
	echo "				outputs: array![" >> $fileName
	echo $tx |  jq -r ".vout[]" | jq -r -f tx_out.jq >> $fileName
	echo "			].span()," >> $fileName
	echo "			}," >> $fileName
	((idx++))
	((total++))
done

#end file
echo "		].span()" >> $fileName
echo "	}" >> $fileName
echo "}" >> $fileName
mv $fileName $path
echo "Finish, file created in $path$fileName"
