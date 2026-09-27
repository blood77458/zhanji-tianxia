#!/usr/bin/env python3
"""Enumerate the top-level keys of the getMeta response (DataManager.GameMetaData)."""
import os, re, collections

D = r"E:\deepseek_projects\app_server\work\luasrc"


def rd(p):
    b = open(p, "rb").read()
    for e in ("utf-8", "gb18030"):
        try:
            return b.decode(e)
        except Exception:
            continue
    return b.decode("latin-1")


keys = collections.Counter()
files = collections.defaultdict(set)
for root, _, fns in os.walk(D):
    for fn in fns:
        p = os.path.join(root, fn)
        t = rd(p)
        rel = os.path.relpath(p, D)
        for m in re.finditer(r"(?:GameMetaData|game_meta|getGameMetaData\(\)|GameMeta)\.([A-Za-z_][A-Za-z0-9_]*)", t):
            keys[m.group(1)] += 1
            files[m.group(1)].add(rel)

print("=== top-level keys referenced on GameMetaData ===")
for k, n in keys.most_common(80):
    print("  %-42s %4d   e.g. %s" % (k, n, sorted(files[k])[0]))

# also look at how the client loads local configs (require canon.configs.X)
print()
print("=== local config modules required ===")
reqs = collections.Counter()
for root, _, fns in os.walk(D):
    for fn in fns:
        t = rd(os.path.join(root, fn))
        for m in re.finditer(r'require\s*\(?\s*"canon\.configs\.([A-Za-z0-9_]+)"', t):
            reqs[m.group(1)] += 1
for k, n in reqs.most_common(60):
    print("  %-42s %d" % (k, n))

print()
print("=== local configs present on disk ===")
cfgdir = os.path.join(D, "canon", "configs")
cfgs = sorted({f.split(".")[0] for f in os.listdir(cfgdir)}) if os.path.isdir(cfgdir) else []
print(f"  {len(cfgs)} files")
for c in cfgs:
    print("   ", c)
