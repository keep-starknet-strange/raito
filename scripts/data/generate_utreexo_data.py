import json
import sys
from utreexo import Utreexo
from poseidon_py.poseidon_hash import poseidon_hash_many


class TxOut:
    def __init__(self, value, pk_script, cached):
        self.value = value
        self.pk_script = pk_script
        self.cached = cached

    def serealize(self):
        res = []
        res.append(self.value)

        data = []
        sub_data = []
        pending_word = 0
        pending_word_len = 0

        # Convert `pk_script` to bytes
        if self.pk_script.startswith("0x") or self.pk_script.startswith("0X"):
            hex_str = self.pk_script[2:]
            byte_data = bytes.fromhex(hex_str)
        else:
            byte_data = self.pk_script.encode("utf-8")

        for byte in byte_data:
            if not (0 <= byte <= 255):
                raise ValueError("Not between 0 and 255.")

            if pending_word_len == 0:
                pending_word = byte
                pending_word_len = 1
                continue

            new_pending = pending_word * 0x100 + byte
            if pending_word_len < 31 - 1:
                pending_word = new_pending
                pending_word_len += 1
                continue

            # Convert new_pending to 31 bytes (big endian)
            new_pending_bytes = new_pending.to_bytes(31, byteorder="big")
            word_int = int.from_bytes(new_pending_bytes, "big")
            sub_data.append(word_int)

            pending_word = 0
            pending_word_len = 0

        data.append(len(sub_data))
        data.extend(sub_data)

        # Check if there's still a word pending
        if pending_word_len > 0:
            data.append(pending_word)
        data.append(pending_word_len)

        # Add pk_script serialized
        res.extend(data)
        res.append(1 if self.cached else 0)

        return res

    def __repr__(self):
        return f"TxOut(\n\
                    value={self.value}\n\
                    pk_script={self.pk_script}\n\
                    cached={self.cached})"


class OutPoint:
    def __init__(
        self, txid, vout, data, block_height, block_time, block_hash, is_coinbase
    ):
        self.txid = txid
        self.vout = vout
        self.data = data  # Instance de TxOut
        self.block_height = block_height
        self.block_time = block_time
        self.block_hash = block_hash
        self.is_coinbase = is_coinbase

    def hash(self):
        tab = []

        # txid
        txid_bytes = bytes.fromhex(self.txid)
        tab.append(int.from_bytes(txid_bytes[16:], "big"))
        tab.append(int.from_bytes(txid_bytes[:16], "big"))

        # vout
        tab.append(self.vout)

        # prev output
        for e in self.data.serealize():
            tab.append(e)

        # block hash
        txid_bytes = bytes.fromhex(self.block_hash)
        tab.append(int.from_bytes(txid_bytes[16:], "big"))
        tab.append(int.from_bytes(txid_bytes[:16], "big"))

        tab.append(self.block_height)
        tab.append(self.block_time)

        tab.append(int(self.is_coinbase))

        hash = poseidon_hash_many(tab)
        # print(f"OutPoint hash: {hahs}")
        return hash

    def __repr__(self):
        return f"OutPoint(\n\
                txid={self.txid}\n\
                vout={self.vout}\n\
                tx_out={self.data}\n\
                block_height={self.block_height}\n\
                block_time={self.block_time}\n\
                block_hash={self.block_hash}\n\
                is_coinbase={self.is_coinbase})"


def handle_txin(inputs: list, utreexo_proofs: list, utreexo: Utreexo):
    for i in range(len(inputs)):
        outpoint = inputs[i].get("previous_output", {})
        outpoint = OutPoint(
            outpoint.get("txid"),
            outpoint.get("vout", 0),
            TxOut(
                value=outpoint.get("data").get("value"),
                pk_script=outpoint.get("data").get("pk_script"),
                # cached=outpoint.get("data").get("cached")
                cached=False,
            ),
            outpoint.get("block_height"),
            outpoint.get("block_time"),
            outpoint.get("block_hash"),
            outpoint.get("is_coinbase"),
        )
        outpoint_hash = outpoint.hash()

        # Must match hash of utreexo::test_poseidon1
        # first output spent block 170
        # print(f"Outpoint: {outpoint}")
        # print(f"Outpoint hash: {outpoint_hash}")

        # Remove OutPoint from accumulator
        [proof, leaf_index] = utreexo.delete(outpoint_hash)
        utreexo_proofs.append({"proof": proof, "leaf_index": leaf_index})


def handle_txout(
    outputs: list,
    utreexo: Utreexo,
    block: dict,
    block_height: int,
    txid: str,
    tx_index: int,
):
    for i in range(len(outputs)):
        new_outpoint = OutPoint(
            txid,
            i,
            TxOut(
                value=outputs[i].get("value"),
                pk_script=outputs[i].get("pk_script"),
                # cached=outputs[i].get("cached")
                cached=False,
            ),
            block_height,
            block.get("header").get("time", 0),
            block.get("header").get("hash", 0),
            True if tx_index == 0 else False,
        )

        # Add OutPoint to accumulator
        utreexo.add(new_outpoint.hash())


def main():
    if len(sys.argv) != 3:
        print("Usage: script.py input.json output.json")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, "r") as f:
        data = json.load(f)

    # Initialize output data
    output_data = {
        "state": {"chain_state": data.get("chain_state", {}), "utreexo_state": {}},
        "updates": [],
        "expected": {"chain_state": data.get("expected", {}), "utreexo_state": {}},
    }

    utreexo = Utreexo()
    block_height = data.get("chain_state", {}).get("block_height", 0) + 1

    for block in data.get("blocks", []):
        utreexo_proofs = []
        transactions = block.get("data", {}).get("transactions", [])
        for i in range(len(transactions)):
            # Skip coinbase?
            if i != 0:
                inputs = transactions[i].get("inputs", [])
                handle_txin(inputs, utreexo_proofs, utreexo)

            outputs = transactions[i].get("outputs", [])
            txid = transactions[i].get("txid", "")
            handle_txout(outputs, utreexo, block, block_height, txid, i)

        # Update output_data
        output_data["updates"].append(
            {"block": block, "utreexo_proofs": utreexo_proofs}
        )
        block_height += 1

    output_data["expected"]["utreexo_state"] = utreexo.get_state()

    with open(output_file, "w") as f:
        json.dump(output_data, f, indent=2)

    # utreexo.print_state()
    # utreexo.print_tree()


if __name__ == "__main__":
    main()
