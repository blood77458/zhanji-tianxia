#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""在客户端 Lua 里找某个变量/结构的所有字段访问路径。

用法: python struct_probe.py <root_pattern> [depth]
例如: python struct_probe.py sharkSpirit
      python struct_probe.py "spirit"        (会匹配 spirit. 开头)
"""
import os, re, io, sys, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))
root = sys.argv[1]
depth = int(sys.argv[2]) if len(sys.argv) > 2 else 2

pat = re.compile(r'\b' + root + r'((?:\.[A-Za-z_][A-Za-z0-9_]*){1,%d})' % depth)
hits = collections.Counter()
ev = collections.defaultdict(list)
for r, _, fs in os.walk(D):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        rel = os.path.relpath(p, D)
        for m in pat.finditer(t):
            path = m.group(1)[1:]
            hits[path] += 1
            if len(ev[path]) < 3:
                ev[path].append('%s:%d' % (rel, t[:m.start()].count('\n') + 1))
for k, v in hits.most_common(60):
    print('%-46s %3d   %s' % (k, v, ev[k][0]))
