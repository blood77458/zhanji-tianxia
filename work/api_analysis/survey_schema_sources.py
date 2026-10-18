#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""调查客户端里可用的“响应结构”线索来源。"""
import os, re, io, sys, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))

pats = {
    'debug/fake data builder': re.compile(r'function\s+[A-Za-z0-9_.:]*\.?(getDebug[A-Za-z]*|getTest[A-Za-z]*|getFake[A-Za-z]*|buildDebug[A-Za-z]*)\s*\('),
    'onSucceedDefault': re.compile(r'function\s+([A-Za-z0-9_.]+)\.onSucceedDefault\s*\('),
    'protocol DSL': re.compile(r'<protocol\b'),
    'bean DSL': re.compile(r'<bean\b'),
    'request comment spec': re.compile(r'--\s*(请求参数|返回|响应|参数说明)'),
    'code= attr': re.compile(r'code\s*=\s*"'),
}
cnt = collections.Counter()
hits = collections.defaultdict(list)
for r, _, fs in os.walk(D):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        rel = os.path.relpath(p, D)
        for k, pat in pats.items():
            n = len(pat.findall(t))
            if n:
                cnt[k] += n
                if len(hits[k]) < 12:
                    hits[k].append('%s (%d)' % (rel, n))
for k in pats:
    print('%-24s %5d   e.g. %s' % (k, cnt[k], '; '.join(hits[k][:6])))
