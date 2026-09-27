#!/usr/bin/env python3
"""Find where SystemConfig (server-provided) is parsed, and the staticVersion flow."""
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


PAT = re.compile(r"SystemConfig|ProtocolUrl|SessionKeyUrl|staticVersion|StaticSettings|"
                 r"StaticConfig|make_static|StaticVersion|loadResSettings", re.I)

for root, _, fns in os.walk(D):
    for fn in fns:
        p = os.path.join(root, fn)
        t = rd(p)
        rel = os.path.relpath(p, D)
        lines = t.split("\n")
        match_idx = [i for i, l in enumerate(lines) if PAT.search(l)]
        if not match_idx:
            continue
        print("=" * 78)
        print("FILE:", rel, f"({len(match_idx)} hits)")
        print("=" * 78)
        shown = set()
        for i in match_idx:
            lo, hi = max(0, i - 3), min(len(lines), i + 4)
            if any(x in shown for x in range(lo, hi)):
                continue
            for j in range(lo, hi):
                shown.add(j)
                mark = ">>" if j == i else "  "
                print("%s%5d| %s" % (mark, j + 1, lines[j].rstrip()[:140]))
            print("   ---")
