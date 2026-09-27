#!/usr/bin/env python3
"""Try TEA decrypt of HQCE card heads with MD5(path)-derived keys."""
import hashlib, struct, zlib, os

HEAD = r"E:\deepseek_projects\app_server\work\decoded\assets\resource\card\head\zhugeliang_1_head.c0f59b61c1efaa6e4ee1828e9b1daccc.png"
DELTA = 0x9E3779B9
SUM0 = 0xC6EF3720


def tea_decrypt_block(v0, v1, k):
    """Match HeMemDataHolder::decrypt (32 rounds, sum starts 0xC6EF3720)."""
    s = SUM0
    k0, k1, k2, k3 = k
    for _ in range(32):
        v1 = (v1 - (((v0 << 4) + k2) ^ (v0 + s) ^ ((v0 >> 5) + k3))) & 0xFFFFFFFF
        v0 = (v0 - (((v1 << 4) + k0) ^ (v1 + s) ^ ((v1 >> 5) + k1))) & 0xFFFFFFFF
        s = (s + 0x61C88647) & 0xFFFFFFFF  # -= DELTA
    return v0, v1


def tea_decrypt(data: bytes, key16: bytes) -> bytes:
    k = struct.unpack("<4I", key16)
    out = bytearray()
    n = len(data) - (len(data) % 8)
    for i in range(0, n, 8):
        v0, v1 = struct.unpack_from("<II", data, i)
        v0, v1 = tea_decrypt_block(v0, v1, k)
        out += struct.pack("<II", v0, v1)
    return bytes(out)


def try_key(label, key16, blob):
    # blob candidates: skip 0/4/8/16 header bytes
    for skip in (0, 4, 8, 12, 16, 20):
        pt = tea_decrypt(blob[skip:], key16)
        if b"\x89PNG" in pt[:16] or pt[:4] == b"\x89PNG":
            print("HIT PNG", label, "skip", skip)
            return pt
        if pt[:2] == b"\x1f\x8b":
            print("HIT GZIP", label, "skip", skip)
            return pt
        for off in range(0, 16):
            try:
                d = zlib.decompress(pt[off:])
                if d[:4] == b"\x89PNG" or d[:2] == b"\x1f\x8b":
                    print("HIT ZLIB->", label, "skip", skip, "off", off, d[:8])
                    return d
            except Exception:
                pass
        # CCZ / pvr?
        if pt[:3] == b"CCZ" or pt[:4] == b"PVR\x03":
            print("HIT", pt[:4], label, skip)
            return pt
    return None


blob = open(HEAD, "rb").read()
print("file len", len(blob), "head", blob[:8])

basename = "zhugeliang_1_head.c0f59b61c1efaa6e4ee1828e9b1daccc.png"
candidates = [
    basename,
    "zhugeliang_1_head.png",
    "card/head/" + basename,
    "card/head/zhugeliang_1_head.png",
    "assets/resource/card/head/" + basename,
    "resource/card/head/" + basename,
    "resource/card/head/zhugeliang_1_head.png",
    "/card/head/zhugeliang_1_head.png",
    "zhugeliang_1_head",
    "zhugeliang_1",
]

for path in candidates:
    for how in ("md5_16", "md5_raw"):
        h = hashlib.md5(path.encode()).digest()
        key = h if how == "md5_16" else h  # same
        # also try as big-endian words
        for endian_label, key16 in (
            ("le", h),
            ("be_words", struct.pack(">4I", *struct.unpack("<4I", h))),
        ):
            r = try_key(f"{path!r}/{endian_label}", key16, blob)
            if r:
                open(r"E:\deepseek_projects\app_server\work\hqce_out.png", "wb").write(
                    r if r[:4] == b"\x89PNG" else r[r.find(b"\x89PNG"):]
                )
                raise SystemExit("done")

# Also try MD5 of path without null, and SHA1 first 16
print("no hit with simple MD5 paths")

# Try key = first 16 bytes after HQCE as IV nonsense / key from header itself
hdr = blob[4:20]
r = try_key("hdr[4:20]", hdr, blob)
print("hdr key", "hit" if r else "miss")

# Bruteforce: key from MD5 of every string containing zhugeliang in so? skip

# Check if plaintext size at [4:8]
print("u32[1]", struct.unpack_from("<I", blob, 4)[0], struct.unpack_from(">I", blob, 4)[0])
