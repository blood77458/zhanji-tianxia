#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""在**进程内**直接调一个 endpoint，不需要起 HTTP 服务端、不需要模拟器。

实现接口时用它自测（避免多人抢同一个 80 端口）。

用法：
    python scripts/call_endpoint.py getOwnUnionInfo
    python scripts/call_endpoint.py exchangeItem '{"exchangeId":1}'
    python scripts/call_endpoint.py --list            # 列出还没实现的接口

退出码：0 = retCode 200 且有实质字段；1 = 空壳 / 500 / 业务错误
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.path.insert(0, os.path.join(ROOT, 'server', 'tests'))
os.chdir(os.path.join(ROOT, 'server'))
sys.stdout.reconfigure(encoding='utf-8')


def parse_params(raw):
    """参数两种写法：

        '{"unionName":"x","num":1}'     标准 JSON
        'unionName=x,num=1'             简易写法（PowerShell 里不用转义引号）
                                        数字会自动转成 int，true/false 转 bool
    """
    raw = (raw or '').strip()
    if not raw:
        return {}
    if raw.startswith('{'):
        return json.loads(raw)
    out = {}
    for part in raw.split(','):
        if '=' not in part:
            continue
        k, v = part.split('=', 1)
        k, v = k.strip(), v.strip()
        if v.lower() in ('true', 'false'):
            out[k] = v.lower() == 'true'
            continue
        try:
            out[k] = int(v)
        except ValueError:
            out[k] = v
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('method', nargs='?')
    ap.add_argument('params', nargs='?', default='{}')
    ap.add_argument('--player', type=int, default=None)
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()

    from db import Database
    from services import Services
    from api import Api, ApiError, REGISTRY, load_handlers

    load_handlers()

    if a.list:
        from test_missing import client_endpoints, SKIP_SOLO_ONLY
        miss = sorted(client_endpoints() - set(REGISTRY) - SKIP_SOLO_ONLY)
        print('还没实现 %d 个:' % len(miss))
        for i in range(0, len(miss), 3):
            print('   ' + '  '.join('%-38s' % x for x in miss[i:i + 3]))
        return 0

    if not a.method:
        ap.print_help()
        return 1

    db = Database(os.path.join(ROOT, 'server', 'canon.db'))
    db.connect()
    ctx = Services(db)
    pid = a.player
    if pid is None:
        row = db.one("SELECT player_id FROM player ORDER BY player_id LIMIT 1")
        pid = int(row['player_id']) if row else 100000

    fn = REGISTRY.get(a.method)
    if fn is None:
        print('!! endpoint 未注册: %s' % a.method)
        db.close()
        return 1

    params = parse_params(a.params)
    api = Api(ctx, None, int(pid), {})
    try:
        r = fn(api, params)
        if isinstance(r, tuple) and len(r) == 2:
            code, payload = r
            res = {'retCode': int(code)}
            if isinstance(payload, dict):
                res.update(payload)
        elif isinstance(r, dict):
            res = {'retCode': 200}
            res.update(r)
        elif isinstance(r, int):
            res = {'retCode': int(r)}
        else:
            res = {'retCode': 200}
    except ApiError as e:
        res = {'retCode': e.code, 'extraMsg': 'ApiError'}
    except Exception as e:
        import traceback
        traceback.print_exc()
        res = {'retCode': 500, 'extraMsg': '%s: %s' % (type(e).__name__, e)}

    if not a.quiet:
        print(json.dumps(res, ensure_ascii=False, indent=1, default=str)[:4000])
    keys = [k for k in res if k not in ('method', 'retCode')]
    code = res.get('retCode')
    db.close()
    if code == 200 and keys:
        print('\n=> OK  字段: %s' % ', '.join(sorted(keys)[:24]))
        return 0
    if code != 200:
        print('\n=> retCode=%s  %s' % (code, res.get('extraMsg', '')))
        return 1
    print('\n=> SHELL(空壳)')
    return 1


if __name__ == '__main__':
    sys.exit(main())
