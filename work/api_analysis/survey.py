#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Survey how Request classes are instantiated / how endpoints are declared."""
import os, re, collections, sys

D = os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc')
D = os.path.abspath(D)


def read(p):
    with open(p, 'rb') as f:
        b = f.read()
    for enc in ('utf-8', 'gb18030', 'latin-1'):
        try:
            return b.decode(enc)
        except Exception:
            pass
    return b.decode('latin-1')


pat_new = re.compile(r'([A-Za-z_][A-Za-z0-9_]*Request)\s*[.:]\s*(new|sendRequest|send)\s*\(')
pat_ep = re.compile(r'self\.endpoint\s*=\s*([^\n]+)')
pat_method = re.compile(r'^\s*(METHOD_[A-Z0-9_]+)\s*=\s*"([^"]+)"', re.M)

c = collections.Counter()
ctx = collections.defaultdict(list)
endpoints = {}
methods = {}

for r, _, fs in os.walk(D):
    for f in fs:
        p = os.path.join(r, f)
        t = read(p)
        rel = os.path.relpath(p, D)
        base = f.split('.')[0]
        for m in pat_method.finditer(t):
            methods[m.group(1)] = m.group(2)
        if os.sep + 'request' + os.sep in p and base.endswith('Request'):
            m = pat_ep.search(t)
            if m:
                endpoints.setdefault(base, set()).add(m.group(1).strip())
        for m in pat_new.finditer(t):
            c[(m.group(1), m.group(2))] += 1
            if len(ctx[m.group(1)]) < 3:
                ln = t[:m.start()].count('\n') + 1
                ctx[m.group(1)].append((rel, ln, t.split('\n')[ln - 1].strip()[:150]))

print('=== endpoint declarations: %d classes ===' % len(endpoints))
unresolved = [k for k, v in endpoints.items() if not any(x.startswith('"') for x in v)]
print('  with non-literal endpoint expr: %d' % len(unresolved))
for k in unresolved[:20]:
    print('    %-45s %s' % (k, endpoints[k]))

print('\n=== METHOD_* constants: %d ===' % len(methods))

print('\n=== call-site verbs ===')
verbs = collections.Counter()
for (cls, verb), n in c.items():
    verbs[verb] += n
for v, n in verbs.most_common():
    print('  %-14s %d' % (v, n))

print('\n=== top 20 classes by call sites ===')
per_cls = collections.Counter()
for (cls, verb), n in c.items():
    per_cls[cls] += n
for k, v in per_cls.most_common(20):
    print('  %-45s %d' % (k, v))

print('\n=== sample contexts ===')
for k in ['ClearMissionRequest', 'GachaCardRequest', 'UsePropRequest', 'BuyGoodsRequest', 'GetHomeInfoRequest']:
    print('--- %s' % k)
    for rel, ln, line in ctx.get(k, []):
        print('   %s:%d  %s' % (rel, ln, line))
