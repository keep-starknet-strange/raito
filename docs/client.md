# Raito client

In the world of L2s it is a common pattern when a certain computation (e.g. state transition function) is executed twice:
- First time to get the result and return it to the user (fast execution backend)
- Second time to generate a validity proof (slow execution backend)

The primary reason for compute things twice is that we want to serve users as fast as possible, while a proper verifiable run can be run in the background for a longer time period. On top of that, sometimes we need to look ahead into the future to reduce the complexity of the verifiable program. In practice that means we pass the result of the first (fast) run as arguments of the second (slow) run.

## What is Raito

Having this dual-run model in mind we can now define what Raito is.

Raito is a verifiable program that in its turn validates that a given Bitcoin block is valid (full consensus validation).  
So it does the very same checks as a Bitcoin Core node but in such a way that its possible to generate a succinct proof of a fact that a particular Bitcoin block is valid.

## How to use

In order to validate a specific Bitcoin block Raito needs the following data:
- Block header and all transactions in that block — fetched via RPC
- 11 previous timestamps for that block — pre-fetched, expected at `scripts/data/.timestamps_data`
- All UTXOs referenced in that block — pre-indexed, expected at `scripts/data/.utxo_data`
- Utreexo roots and batch inclusion proof for spent UTXOs — pre-indexed, expected at `scripts/data/.utreexo_data`

Read more about how to get all this information in the [data section](data.md).

Once you are all set, run:

```sh
python ./scripts/data/client.py --start $INITIAL_CHAIN_HEIGHT --mode utreexo
```

Raito will check that the block at level `$INITIAL_CHAIN_HEIGHT + 1` is valid and fail otherwise.

## How to generate test case

In the following example we will create an integration test for applying block 630000 with all validations and Utreexo accumulator enabled:

```sh
python ./scripts/data/generate_data.py --mode utreexo --height 629999 --num_blocks 1 --output_file packages/client/tests/data/utreexo_629999.json --fast
```
