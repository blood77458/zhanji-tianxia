#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核查「解析为 0 参数」的接口是否真的没有参数：打印其调用点上下文。"""
import json, os, io, sys, random

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.abspath(os.path.join(HERE, '..', 'apk_luasrc'))
recs = json.load(open(os.path.join(HERE, 'records.json'), encoding='utf-8'))
pool = [r for r in recs if not r['params'] and r['callsites']]
random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 3)
print('零参数接口数: %d' % len(pool))
for r in random.sample(pool, min(8, len(pool))):
    cs = r['callsites'][0]
    L = open(os.path.join(D, cs['file']), encoding='utf-8', errors='replace').read().split('\n')
    ln = cs['line']
    print('=' * 96)
    print('### %s   %s:%d' % (r['method'], os.path.basename(cs['file'])[:40], ln))
    for i in range(max(0, ln - 7), min(len(L), ln + 1)):
        print('   %s %5d| %s' % ('>>' if i + 1 == ln else '  ', i + 1, L[i].rstrip()[:140]))
