# This module provides helpers for serializing Python objects into Cairo runner arguments (felts and arrays).
# 
# Supported types:
#   int (unsigned) -> felt252
#   [0-9] str -> u256 which is (felt252, felt252)
#   0x str (reversed) -> Hash which is [u32; 8] which is a tuple of felt252
#   bytes -> ByteArray which is (Array<felt252>, felt252, felt252)
#   list<int> -> Array<felt252>
#   dict<str, V> -> (V, V, ...)
import sys
import os
import json
from pathlib import Path

def serialize(obj):
    if isinstance(obj, int):
        # This covers u8, u16, u32, u64, u128, felt252
        assert(obj >= 0 and obj < 2 ** 252)
        return obj
    elif isinstance(obj, str):
        if obj.startswith('0x') and len(obj) == 66:
            # Hex string into 4-byte words then into BE u32
            rev = list(reversed(bytes.fromhex(obj[2:])))
            return tuple(int.from_bytes(rev[i:i+4], 'big') for i in range(0, 32, 4))
        else:
            # Try to cast to int and then to a pair of felts
            num = int(obj)
            assert(num >= 0 and num < 2 ** 256)
            lo = num % 2 ** 128
            hi = num // 2 ** 128
            return (lo, hi)
    elif isinstance(obj, bytes):
        # Split into 31-byte chunks and save the remainder
        num_chunks = len(obj) // 31
        main_len = num_chunks * 31
        rem_len = len(obj) - main_len
        main = [int.from_bytes(obj[i:i+31], 'big') for i in range(0, main_len, 31)]
        # TODO: check if this is correct
        rem = int.from_bytes(obj[main_len:].rjust(31, b'\x00'), 'big')
        return (main, rem, rem_len)
    elif isinstance(obj, list):
        return list(map(serialize, obj))
    elif isinstance(obj, dict):
        return tuple(map(serialize, obj.values()))
    elif isinstance(obj, tuple):
        return obj
    else:
        raise NotImplementedError(obj)

def flatten_tuples(src):
    res = []
    def iter_obj(obj):
        if isinstance(obj, int):
            res.append(obj)
        elif isinstance(obj, list):
            res.append(obj)
        elif isinstance(obj, tuple):
            for item in obj:
                iter_obj(item)
        else:
            raise NotImplementedError(obj)
    iter_obj(src)
    return res

def main():
    try:
        if (len(sys.argv) != 2):
            raise TypeError("Error: bad arguments")
        args = json.loads(Path(sys.argv[1]).read_text())
        res = flatten_tuples(serialize(args))
        print(res)
    except Exception as error:
        print(error)

main()
