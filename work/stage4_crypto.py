#!/usr/bin/env python3
"""Analyze the .lua payloads: encrypted? compressed? all of them? header structure?"""
import os, collections, math, hashlib, re

SRC = r"E:\deepseek_projects\app_server\work\extract\assets\src"

def entropy(b):
    if not b: return 0.0
    c = collections.Counter(b)
    n = len(b)
    return -sum((v/n) * math.log2(v/n) for v in c.values())

files = []
for root, _, fns in os.walk(SRC):
    for fn in fns:
        files.append(os.path.join(root, fn))
luas = [f for f in files if f.endswith(".lua")]
print(f"total .lua files: {len(luas)}")

# size distribution
sizes = sorted(os.path.getsize(f) for f in luas)
print(f"size min/median/max: {sizes[0]} / {sizes[len(sizes)//2]} / {sizes[-1]}")

# entropy + header census
ents = []
hdr1 = collections.Counter()   # first byte
hdr4 = collections.Counter()   # first 4 bytes
plaintext_like = []
matches_md5 = 0
checked_md5 = 0

for f in luas:
    b = open(f, "rb").read()
    ents.append(entropy(b))
    hdr1[b[0]] += 1
    hdr4[b[:4]] += 1
    # does the filename's md5 match the file content md5?
    m = re.search(r"\.([0-9a-f]{32})\.lua$", os.path.basename(f))
    if m:
        checked_md5 += 1
        if hashlib.md5(b).hexdigest() == m.group(1):
            matches_md5 += 1
    # heuristic: plaintext lua would be mostly printable ascii
    printable = sum(1 for x in b[:200] if 9 <= x <= 13 or 32 <= x < 127)
    if len(b) >= 20 and printable / min(len(b), 200) > 0.9:
        plaintext_like.append(f)

print(f"\nentropy: min={min(ents):.2f} avg={sum(ents)/len(ents):.2f} max={max(ents):.2f}")
print(f"  (8.0 = indistinguishable from random/encrypted; <6 suggests compressible/plaintext)")
print(f"\nfilename-md5 == content-md5 : {matches_md5} / {checked_md5}")
print(f"plaintext-like files        : {len(plaintext_like)}")
for p in plaintext_like[:10]:
    print("   ", os.path.basename(p))

print(f"\nfirst-byte distribution (top 12 of {len(hdr1)} distinct):")
for v, n in hdr1.most_common(12):
    print(f"   0x{v:02x}  {n}")

print(f"\nfirst-4-byte collisions (top 8 of {len(hdr4)} distinct):")
for v, n in hdr4.most_common(8):
    print(f"   {v.hex()}  {n}")

# Look for a repeated header / magic across files of same size
print("\n=== sample raw heads (files sorted by size) ===")
for f in sorted(luas, key=os.path.getsize)[:6]:
    b = open(f, "rb").read(48)
    print(f"  {os.path.getsize(f):>6}  {b.hex()}")

# Check: is there any file that is NOT encrypted?
print("\n=== files whose first byte suggests known container formats ===")
known = {b"\x1b": "Lua bytecode", b"\x1f\x8b": "gzip", b"PK": "zip",
         b"\x78\x01": "zlib", b"\x78\x9c": "zlib", b"\x78\xda": "zlib",
         b"BZh": "bzip2", b"\xfd7zXZ": "xz", b"\x28\xb5\x2f\xfd": "zstd"}
hits = collections.Counter()
for f in luas:
    h = open(f, "rb").read(6)
    for k, v in known.items():
        if h.startswith(k):
            hits[v] += 1
print(dict(hits) if hits else "  none")
