# -*- coding: utf-8 -*-
"""查会话表结构，并给指定玩家造一个有效会话 key（给 gen_proto_snapshot 用）。"""
import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')
DB = r'E:\deepseek_projects\app_server\server\canon.db'
PLAYER = int(sys.argv[1]) if len(sys.argv) > 1 else 100000

db = sqlite3.connect(DB)
db.row_factory = sqlite3.Row
tables = [r[0] for r in db.execute(
    "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%session%'")]
print('会话相关表:', tables)
for t in tables:
    cols = [r[1] for r in db.execute('PRAGMA table_info(%s)' % t)]
    n = db.execute('SELECT COUNT(*) FROM %s' % t).fetchone()[0]
    print('--- %s (%d 行) %s' % (t, n, cols))
    for r in db.execute('SELECT * FROM %s LIMIT 3' % t):
        print('    ', dict(r))

print('\n玩家 100000 的账号:')
for r in db.execute('PRAGMA table_info(player)'):
    pass
try:
    row = db.execute('SELECT * FROM player WHERE player_id=?', (PLAYER,)).fetchone()
    print('   ', dict(row) if row else None)
except Exception as e:
    print('   player 表读取失败', e)
