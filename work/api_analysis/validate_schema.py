#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用 SQLite 校验 schema.sql 能否执行，并打印表清单。"""
import sqlite3, io, sys, os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'server', 'schema.sql')
sql = open(os.path.abspath(p), encoding='utf-8').read()
con = sqlite3.connect(':memory:')
try:
    con.executescript(sql)
except Exception as e:
    print('DDL FAIL: %s' % e)
    raise SystemExit(1)

tabs = [r[0] for r in con.execute("select name from sqlite_master where type='table' order by name")]
views = [r[0] for r in con.execute("select name from sqlite_master where type='view' order by name")]
idxs = [r[0] for r in con.execute("select name from sqlite_master where type='index' and name like 'idx_%' order by name")]
ncol = 0
for t in tabs:
    ncol += len(list(con.execute('pragma table_info(%s)' % t)))
print('DDL OK')
print('表 %d 张 / 视图 %d 个 / 索引 %d 个 / 列合计 %d' % (len(tabs), len(views), len(idxs), ncol))
print()
for t in tabs:
    cols = list(con.execute('pragma table_info(%s)' % t))
    print('  %-28s %2d 列' % (t, len(cols)))
