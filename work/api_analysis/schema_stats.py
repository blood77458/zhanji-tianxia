#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""统计 schema.sql 的规模，用于核对文档里的数字。"""
import sqlite3, io, sys, os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
p = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server', 'schema.sql'))
con = sqlite3.connect(':memory:')
con.executescript(open(p, encoding='utf-8').read())

tabs = [r[0] for r in con.execute(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
real = [t for t in tabs if not t.startswith('sqlite_')]
views = [r[0] for r in con.execute(
    "SELECT name FROM sqlite_master WHERE type='view' ORDER BY name")]
idxs = [r[0] for r in con.execute(
    "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'")]
ncol = sum(len(list(con.execute('PRAGMA table_info(%s)' % t))) for t in real)

json_tabs = []
for t in real:
    cols = [c[1] for c in con.execute('PRAGMA table_info(%s)' % t)]
    if any('json' in c for c in cols):
        json_tabs.append(t)

print('实际表数(不含 sqlite_sequence) : %d' % len(real))
print('视图                          : %d' % len(views))
print('索引                          : %d' % len(idxs))
print('列合计                        : %d' % ncol)
print('含 JSON 列的表                : %d' % len(json_tabs))
print('  ' + ', '.join(json_tabs))
print()
print('全部表名:')
print('  ' + ', '.join(real))
