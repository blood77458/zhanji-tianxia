# -*- coding: utf-8 -*-
"""摸底 ② 需要的三张配置表 + 数据库里已有的神兽/套装数据。"""
import json
import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, r'E:\deepseek_projects\app_server\server')

import luaconf  # noqa: E402


def first(tab):
    if isinstance(tab, dict):
        k = next(iter(tab))
        return k, tab[k]
    if isinstance(tab, list):
        return 0, tab[0]
    return None, None


def main():
    for name in ('special_group_skill', 'equip_suit', 'beast_meta'):
        tab = luaconf.load(name)
        k, row = first(tab)
        n = len(tab) if isinstance(tab, (dict, list)) else 0
        print('%s: %d 条, 样例 key=%s' % (name, n, k))
        print('   ', json.dumps(row, ensure_ascii=False)[:420])
        print()

    db = sqlite3.connect(r'E:\deepseek_projects\app_server\server\canon.db')
    rows = [r[0] for r in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND "
        "(name LIKE '%beast%' OR name LIKE '%suit%' OR name LIKE '%equip%')")]
    print('相关表:', rows)
    for t in rows:
        try:
            c = db.execute('SELECT COUNT(*) FROM ' + t).fetchone()[0]
        except Exception as e:
            c = 'ERR %s' % e
        print('   %-24s %s' % (t, c))
    for t in rows:
        if 'beast' in t:
            cur = db.execute('SELECT * FROM ' + t + ' LIMIT 3')
            cols = [d[0] for d in cur.description]
            print('\n%s 列: %s' % (t, cols))
            for r in cur.fetchall():
                print('   ', r)
    return 0


if __name__ == '__main__':
    sys.exit(main())
