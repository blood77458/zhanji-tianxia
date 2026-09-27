#!/usr/bin/env python3
"""Drill into the anomalies: the 0x1b files, the pure-ASCII files, smallest files."""
import os, re, collections, hashlib

SRC = r"E:\deepseek_projects\app_server\work\extract\assets\src"
files = []
for root, _, fns in os.walk(SRC):
    for fn in fns:
        files.append(os.path.join(root, fn))
luas = sorted([f for f in files if f.endswith(".lua")])

def rel(p): return os.path.relpath(p, SRC)

print("=" * 78)
print("A) FILES STARTING WITH 0x1b")
print("=" * 78)
for f in luas:
    b = open(f, "rb").read()
    if b[:1] == b"\x1b":
        print(f"  {rel(f)}")
        print(f"     size={len(b)}  head={b[:24].hex()}")

print()
print("=" * 78)
print("B) FILES THAT ARE >=90% PRINTABLE (candidate plaintext)")
print("=" * 78)
n = 0
for f in luas:
    b = open(f, "rb").read()
    pr = sum(1 for x in b if 9 <= x <= 13 or 32 <= x < 127)
    if len(b) and pr / len(b) >= 0.90:
        n += 1
        print(f"  {rel(f)}  size={len(b)}")
        print(f"     content: {b[:200]!r}")
print(f"  total printable files: {n}")

print()
print("=" * 78)
print("C) 12 SMALLEST FILES (full content)")
print("=" * 78)
for f in sorted(luas, key=os.path.getsize)[:12]:
    b = open(f, "rb").read()
    print(f"  {rel(f)}  size={len(b)}")
    print(f"     {b[:120]!r}")

print()
print("=" * 78)
print("D) SANITY: is the md5-in-filename the md5 of the RAW file?")
print("=" * 78)
ok = bad = 0
for f in luas[:50]:
    b = open(f, "rb").read()
    m = re.search(r"\.([0-9a-f]{32})\.lua$", os.path.basename(f))
    if m and hashlib.md5(b).hexdigest() == m.group(1):
        ok += 1
    else:
        bad += 1
print(f"  match={ok} mismatch={bad} (of first 50)")

print()
print("=" * 78)
print("E) DO ANY TWO FILES SHARE LONG COMMON SUBSTRINGS? (weak-encryption probe)")
print("=" * 78)
# If it were a fixed-key stream cipher without IV, identical plaintext prefixes
# give identical ciphertext prefixes. Check first-16-byte collisions among files.
h = collections.Counter()
for f in luas:
    b = open(f, "rb").read()
    if len(b) >= 16:
        h[b[:16]] += 1
dups = [(k, v) for k, v in h.items() if v > 1]
print(f"  duplicate first-16-byte blocks: {len(dups)}")
for k, v in dups[:5]:
    print(f"     {k.hex()} x{v}")

# Also: for files with identical size, compare
bysize = collections.defaultdict(list)
for f in luas:
    bysize[os.path.getsize(f)].append(f)
print("\n  size groups with >2 members (showing 5):")
shown = 0
for s, fs in sorted(bysize.items()):
    if len(fs) > 2 and s >= 64:
        print(f"     size={s} count={len(fs)}  e.g. {rel(fs[0])}")
        shown += 1
        if shown >= 5: break
