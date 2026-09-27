#!/usr/bin/env python3
"""Brute-force the headercvt framing around the captured /protocol body."""
import json, hashlib, zlib, struct, itertools

BODIES = []
for line in open(r"E:\deepseek_projects\app_server\server\rpc_payloads.jsonl", encoding="utf-8"):
    r = json.loads(line)
    if "/protocol" in r["path"]:
        BODIES.append(bytes.fromhex(r["body_hex"]))

print(f"captured /protocol bodies: {len(BODIES)}")
for bi, b in enumerate(BODIES):
    print("=" * 74)
    print(f"body #{bi} len={len(b)}")
    print("  head:", b[:24].hex())

    # where are zlib magic bytes?
    zl = [i for i in range(len(b)) if b[i] == 0x78]
    print("  0x78 offsets:", zl[:10])
    for off in zl:
        try:
            d = zlib.decompress(b[off:])
            print(f"  ** FULL zlib stream at +{off} -> {len(d)} bytes: {d[:40].hex()}")
        except Exception:
            try:
                do = zlib.decompressobj()
                d = do.decompress(b[off:])
                print(f"  ** PARTIAL zlib at +{off} -> {len(d)} bytes (unused {len(do.unused_data)})")
            except Exception:
                pass

    # try common header layouts:  find an offset H such that md5(b[H:]) appears
    # somewhere in b[:H]
    for H in range(2, 40):
        rest = b[H:]
        if len(rest) < 8:
            break
        m5 = hashlib.md5(rest).digest()
        if m5 in b[:H]:
            print(f"  ** md5(payload) found at header offset {H}: md5 at {b[:H].index(m5)}")
        m5h = hashlib.md5(rest).hexdigest().encode()
        if m5h in b[:H]:
            print(f"  ** hex md5(payload) found in header, H={H}")

    # is the first 2 bytes a length of anything?
    for endian in (">H", "<H"):
        v = struct.unpack(endian, b[:2])[0]
        print(f"  u16{endian} = {v}   (len={len(b)} , len-2={len(b)-2} , len-18={len(b)-18})")

    # try: header 18 bytes, then zlib
    for H in (2, 4, 16, 18, 20):
        for off in range(H, min(H + 8, len(b))):
            try:
                d = zlib.decompress(b[off:])
                print(f"  zlib works at +{off} with header {H}")
            except Exception:
                pass
