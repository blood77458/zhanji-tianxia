#!/usr/bin/env python3
"""Find exactly what the headercvt md5 covers."""
import json, zlib, hashlib, itertools

C16 = bytes.fromhex("255e262a4051306a6533356937717039")
C17 = bytes.fromhex("255e262a4051306a653335693771703900")

body = bytes.fromhex(
    [json.loads(l) for l in open(r"E:\deepseek_projects\app_server\server\rpc_payloads.jsonl",
                                 encoding="utf-8")
     if "/protocol" in json.loads(l)["path"]][0]["body_hex"])
hdr, enc = body[:18], body[18:]
xored = bytes(c ^ 0xC3 for c in enc)
want = hdr[2:].hex()

print("header md5 wanted:", want)
print()

cands = {
    "C16+xored": C16 + xored,
    "xored+C16": xored + C16,
    "C16+enc": C16 + enc,
    "enc+C16": enc + C16,
    "xored": xored,
    "enc": enc,
    "C17+xored": C17 + xored,
    "xored+C17": xored + C17,
    "C16[:16]+xored[0:0]": C16,
    "body": body,
    "body[2:]": body[2:],
    "body[18:]+magic": enc + hdr[:2],
    "magic+xored": hdr[:2] + xored,
    "magic+C16+xored": hdr[:2] + C16 + xored,
    "C16+magic+xored": C16 + hdr[:2] + xored,
}
for name, data in cands.items():
    h = hashlib.md5(data).hexdigest()
    flag = "  <<<<< MATCH" if h == want else ""
    print(f"  md5({name:22}) = {h}{flag}")

# maybe the "C16" bytes are not a literal but a formatted/rotated value; try
# every 16-byte window of the .so around the literal plus the xored data
print()
print("scanning for a 16-byte constant such that md5(K16+xored)==header md5 (cheap sanity: skip)")
