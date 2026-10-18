#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 cardstats.py 里对「卡牌/装备/宝物/元神行」的 .get() 换成 _g()。

这些行对象可能是 sqlite3.Row，没有 .get()。只替换明确的行变量名，
不动配置字典（那些是真 dict，用 .get() 没问题）。
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
P = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server',
                                 'services', 'cardstats.py'))
t = open(P, encoding='utf-8').read()
# 行变量名前缀
VARS = ('card', 'equip', 'treasure', 'spirit')
n = 0
for v in VARS:
    pat = re.compile(r'\b%s\.get\(([^()]*)\)' % re.escape(v))
    t, k = pat.subn(lambda m: "_g(%s, %s)" % (v, m.group(1)), t)
    n += k
open(P, 'w', encoding='utf-8').write(t)
print('替换 %d 处 .get() -> _g()' % n)
print('剩余可疑:', re.findall(r'\b(card|equip|treasure|spirit)\.get\(', t))
