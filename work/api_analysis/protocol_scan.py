#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""统计并抽取客户端 Lua 注释里的 <protocol> 协议 DSL。"""
import os, re, io, sys, json, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))

RE_PROTO = re.compile(r'<protocol\b([^>]*)>', re.I)
RE_TAG = re.compile(r'<([A-Za-z_][A-Za-z0-9_]*)\b([^>]*?)(/?)>', re.S)
RE_ATTR = re.compile(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"')

files = 0
blocks = 0
tags = collections.Counter()
refs = collections.Counter()
types = collections.Counter()
samples = []

for r, _, fs in os.walk(D):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(r, f)
        t = open(p, encoding='utf-8', errors='replace').read()
        if '<protocol' not in t and '<type' not in t and '<struct' not in t:
            continue
        files += 1
        blocks += len(RE_PROTO.findall(t))
        for m in RE_TAG.finditer(t):
            tags[m.group(1).lower()] += 1
            a = dict(RE_ATTR.findall(m.group(2)))
            if 'ref' in a:
                refs[a['ref']] += 1
            if 'type' in a:
                types[a['type']] += 1
        if len(samples) < 3:
            samples.append((os.path.relpath(p, D), t[:0]))

print('files containing protocol DSL : %d' % files)
print('protocol blocks               : %d' % blocks)
print('\ntags:')
for k, v in tags.most_common(40):
    print('   %-16s %d' % (k, v))
print('\nvalue types used:')
for k, v in types.most_common(40):
    print('   %-20s %d' % (k, v))
print('\nrefs (distinct %d):' % len(refs))
for k, v in refs.most_common(60):
    print('   %-28s %d' % (k, v))
