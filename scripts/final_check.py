#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""全量校验：进程内把客户端会调的每个 endpoint 都打一遍，给出体检报告。

不依赖 HTTP 服务端，也不用重启（新写的 handlers_*.py 会被自动发现），
所以可以边写边跑。

    python scripts/final_check.py              # 全部客户端接口
    python scripts/final_check.py --missing    # 只看还没实现的
    python scripts/final_check.py --only Union # 名字包含 Union 的

退出码：0 = 没有 CRASH 且没有「未实现」；1 = 还有问题
"""
import argparse
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.path.insert(0, os.path.join(ROOT, 'server', 'tests'))
os.chdir(os.path.join(ROOT, 'server'))
sys.stdout.reconfigure(encoding='utf-8')

# 需要真实 id 才好测的接口给一份最小参数（和 tests/test_missing.py 保持同步）
from test_missing import PARAMS, SKIP_SOLO_ONLY, client_endpoints   # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--missing', action='store_true')
    ap.add_argument('--only', default='')
    ap.add_argument('--busy', action='store_true')
    ap.add_argument('--player', type=int, default=None)
    a = ap.parse_args()

    from db import Database
    from services import Services
    from api import Api, ApiError, REGISTRY, load_handlers

    load_handlers()
    reg = set(REGISTRY)
    want = sorted(client_endpoints() - SKIP_SOLO_ONLY)
    if a.missing:
        want = [w for w in want if w not in reg]
    if a.only:
        want = [w for w in want if a.only in w]

    db = Database(os.path.join(ROOT, 'server', 'canon.db'))
    db.connect()
    ctx = Services(db)
    pid = a.player
    if pid is None:
        row = db.one("SELECT player_id FROM player ORDER BY player_id LIMIT 1")
        pid = int(row['player_id']) if row else 100000

    rows = []
    for m in want:
        fn = REGISTRY.get(m)
        if fn is None:
            rows.append(('MISSING', m, '', ''))
            continue
        api = Api(ctx, None, int(pid), {})
        try:
            r = fn(api, PARAMS.get(m, {}))
            if isinstance(r, tuple) and len(r) == 2:
                code, payload = r
                code = int(code)
                keys = sorted(payload) if isinstance(payload, dict) else []
            elif isinstance(r, dict):
                code, keys = 200, sorted(r)
            elif isinstance(r, int):
                code, keys = int(r), []
            else:
                code, keys = 200, []
        except ApiError as e:
            rows.append(('BUSY', m, str(e.code), ''))
            continue
        except Exception as e:
            tb = traceback.format_exc().strip().split('\n')
            rows.append(('CRASH', m, '%s: %s' % (type(e).__name__, str(e)[:80]),
                         tb[-2].strip() if len(tb) > 1 else ''))
            continue
        if code != 200:
            rows.append(('BUSY', m, str(code), ''))
        elif not keys:
            rows.append(('SHELL', m, '', ''))
        else:
            rows.append(('OK', m, '', ','.join(keys[:6])))

    db.close()

    counts = {}
    for st, *_ in rows:
        counts[st] = counts.get(st, 0) + 1
    print('\n================ 体检报告 (%d 个接口) ================' % len(rows))
    for k in ('OK', 'BUSY', 'SHELL', 'MISSING', 'CRASH'):
        print('  %-8s %d' % (k, counts.get(k, 0)))

    for want_st in (('CRASH', 'MISSING', 'SHELL', 'BUSY') if a.busy
                    else ('CRASH', 'MISSING', 'SHELL')):
        items = [r for r in rows if r[0] == want_st]
        if not items:
            continue
        print('\n--- %s (%d) ---' % (want_st, len(items)))
        for st, m, info, extra in items:
            line = '   %-42s %s' % (m, info)
            if extra:
                line += '  @ ' + extra
            print(line)

    bad = counts.get('CRASH', 0) + counts.get('MISSING', 0)
    print('\n结论: %s' % ('还有 %d 个接口要处理' % bad if bad else '客户端接口全部有实现，无崩溃'))
    return 0 if bad == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
