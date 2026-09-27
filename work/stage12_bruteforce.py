#!/usr/bin/env python3
"""
Exhaustive sliding-window AES key search against the known-plaintext oracle.

Oracle: an empty Lua file encrypts to exactly one block:
    C1 = AES_enc(K, IV XOR 0x10*16)
We know IV and C1, so for every candidate key we can test with ONE block encrypt.

Scans every byte offset of libhegame.so (and classes.dex) as a candidate
16/24/32-byte key. Decisive test for "the key is a contiguous constant".
"""
import sys, time, struct
from Crypto.Cipher import AES

ORACLES = [
    # (iv, ciphertext-block) for two empty Lua files
    (bytes.fromhex("d41d8cd98f00b204e9800998ecf8427e"), bytes.fromhex("4fba9e63120fd484881c31003c5c7e61")),
    (bytes.fromhex("81051bcc2cf1bedf378224b0a93e2877"), bytes.fromhex("e564a590961f04595ede2be9039ad0ca")),
]
TARGETS = [(bytes(a ^ b for a, b in zip(iv, b"\x10" * 16)), ct) for iv, ct in ORACLES]

FILES = [
    r"E:\deepseek_projects\app_server\work\extract\libhegame.so",
    r"E:\deepseek_projects\app_server\work\extract\classes.dex",
]

def check(key):
    try:
        c = AES.new(key, AES.MODE_ECB)
    except Exception:
        return False
    for tgt, ct in TARGETS:
        if c.encrypt(tgt) != ct:
            return False
    return True

grand = 0
for path in FILES:
    data = open(path, "rb").read()
    print(f"\n### {path}  ({len(data)} bytes)", flush=True)
    for klen in (16, 24, 32):
        t0 = time.time()
        hits = []
        n = len(data) - klen
        for i in range(n):
            if check(data[i:i + klen]):
                hits.append((i, data[i:i + klen]))
                print(f"  *** HIT klen={klen} offset=0x{i:x} key={data[i:i+klen].hex()}", flush=True)
        dt = time.time() - t0
        print(f"  klen={klen}: scanned {n} offsets in {dt:.1f}s ({n/max(dt,1e-9):,.0f}/s)  hits={len(hits)}", flush=True)
        grand += len(hits)
        if hits:
            for off, k in hits:
                print(f"     offset 0x{off:x}  key  {k.hex()}")
print(f"\nTOTAL HITS = {grand}")
