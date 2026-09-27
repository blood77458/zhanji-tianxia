#!/usr/bin/env python3
"""Inventory of RPC endpoints/methods, URL scheme, and socket framing."""
import os, re, sys, json

D = r"E:\deepseek_projects\app_server\work\luasrc"


def rd(p):
    b = open(p, "rb").read()
    for enc in ("utf-8", "gb18030"):
        try:
            return b.decode(enc)
        except Exception:
            continue
    return b.decode("latin-1")


def walk():
    for root, _, fns in os.walk(D):
        for fn in fns:
            yield os.path.join(root, fn)


eps = set()
reqfiles = []
for p in walk():
    t = rd(p)
    rel = os.path.relpath(p, D)
    for m in re.finditer(r'self\.endpoint\s*=\s*["\']([A-Za-z0-9_]+)["\']', t):
        eps.add(m.group(1))
        reqfiles.append((rel, m.group(1)))
    for m in re.finditer(r'METHOD_[A-Z0-9_]+\s*=\s*["\']([A-Za-z0-9_]+)["\']', t):
        eps.add(m.group(1))

eps = sorted(eps)
print("TOTAL distinct endpoints/methods:", len(eps))
for i in range(0, len(eps), 3):
    print("   " + "  ".join("%-30s" % e for e in eps[i:i + 3]))
with open("endpoints.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(eps))

# ---- URL construction in Communication.lua ----
print("\n" + "=" * 76)
print("Communication.lua  (URL / channel setup)")
print("=" * 76)
for p in walk():
    if os.sep + "request" + os.sep in p and os.path.basename(p).startswith("Communication"):
        t = rd(p)
        for i, l in enumerate(t.split("\n")):
            if re.search(r"url|Url|URL|http|domain|Domain|port|method|endpoint|createPost|getDomain",
                         l) and len(l.strip()) > 3:
                print("%4d| %s" % (i + 1, l.strip()[:130]))
        break
