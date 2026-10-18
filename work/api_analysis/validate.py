#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""随机抽样校验：把抽到的接口的「解析结果」与「源码原文」并排打印，人工核对。"""
import json, os, io, sys, random, re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.abspath(os.path.join(HERE, '..', 'apk_luasrc'))
recs = json.load(open(os.path.join(HERE, 'records.json'), encoding='utf-8'))
by = {r['method']: r for r in recs}

n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
seed = int(sys.argv[2]) if len(sys.argv) > 2 else 7
random.seed(seed)
pool = [r for r in recs if r['params'] and len(r['callsites']) and r['method'] not in
        ('login', 'loginServer')]
for r in random.sample(pool, min(n, len(pool))):
    print('=' * 100)
    print('### %s   (%s)' % (r['method'], r['desc'][:50]))
    print('  解析参数: ' + ', '.join('%s=%s' % (k, (v['values'] or [''])[0])
                                 for k, v in sorted(r['params'].items())))
    cs = r['callsites'][0]
    p = os.path.join(D, cs['file'])
    L = open(p, encoding='utf-8', errors='replace').read().split('\n')
    ln = cs['line']
    print('  调用点 %s:%d' % (cs['file'], ln))
    for i in range(max(0, ln - 14), min(len(L), ln + 1)):
        mark = '>>' if i + 1 == ln else '  '
        print('   %s %5d| %s' % (mark, i + 1, L[i].rstrip()[:150]))
    print()
