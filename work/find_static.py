#!/usr/bin/env python3
"""Find how the client consumes static settings / resource version (staticVersion)."""
import os, re, sys

D = r"E:\deepseek_projects\app_server\work\luasrc"


def rd(p):
    b = open(p, "rb").read()
    for enc in ("utf-8", "gb18030"):
        try:
            return b.decode(enc)
        except Exception:
            continue
    return b.decode("latin-1")


PAT = re.compile(r"staticVersion|StaticSettings|static_settings|LoadResSettings|loadResSettings|"
                 r"resVersion|ResVersion|updateUrl|UpdateUrl|patchUrl|catalog|manifest", re.I)

for root, _, fns in os.walk(D):
    for fn in fns:
        p = os.path.join(root, fn)
        t = rd(p)
        rel = os.path.relpath(p, D)
        lines = t.split("\n")
        idx = [i for i, l in enumerate(lines) if PAT.search(l)]
        if not idx:
            continue
        print("=" * 78)
        print("FILE:", rel)
        print("=" * 78)
        shown = set()
        for i in idx[:8]:
            lo, hi = max(0, i - 2), min(len(lines), i + 3)
            if any(x in shown for x in range(lo, hi)):
                continue
            for j in range(lo, hi):
                shown.add(j)
                print("%s%5d| %s" % (">>" if j == i else "  ", j + 1, lines[j].rstrip()[:140]))
            print("   ---")
