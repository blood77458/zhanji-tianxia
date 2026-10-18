#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对指定活动，列出客户端读取其配置的全部位置（含上下文），
用来判断：真实数据在服务端配置里，还是在本地 configs 里。"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))

KEYS = sys.argv[1:] or ['activityGoldGodConfig']
CTX = 2

for key in KEYS:
    print('=' * 100)
    print('## %s' % key)
    n = 0
    for r, _, fs in os.walk(D):
        for f in fs:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(r, f)
            t = open(p, encoding='utf-8', errors='replace').read()
            if key not in t:
                continue
            rel = os.path.relpath(p, D)
            lines = t.split('\n')
            for i, l in enumerate(lines):
                if key in l:
                    n += 1
                    if n > 12:
                        break
                    print('  --- %s:%d' % (rel, i + 1))
                    for j in range(max(0, i - CTX), min(len(lines), i + CTX + 1)):
                        mark = '>>' if j == i else '  '
                        print('   %s %s' % (mark, lines[j].strip()[:120]))
            if n > 12:
                break
        if n > 12:
            break
    if n == 0:
        print('  (无引用)')
    print()
