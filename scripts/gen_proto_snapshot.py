# -*- coding: utf-8 -*-
"""不用客户端，直接在服务端合成「登录 + 主界面」所需的 /protocol 快照。

单机版 S1 的做法是「冻结快照」：把某个角色登录时客户端会拿到的响应冻结下来，
在 APK 里按方法名原样返回。这样就不用在 Lua 里重写 397 个 handler。

本脚本直接调 `api.dispatch(...)`（和 gameserver.rpc 里完全一样的入口），
把一批方法的结果写到 `work/proto_capture/<method>.json`。

用法:
    python scripts/gen_proto_snapshot.py            # 用默认方法清单
    python scripts/gen_proto_snapshot.py login getHomeInfo
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))
os.chdir(os.path.join(ROOT, 'server'))

import gameserver as GS          # noqa: E402
import api                       # noqa: E402
from api import dispatch         # noqa: E402

api.load_handlers()              # 不调用 main() 时 REGISTRY 是空的，必须手动载入

PLAYER_ID = int(os.environ.get('CANON_PID', '100000'))

# 客户端登录到主界面会用到的第一批方法（按我们日志里出现过的顺序）
DEFAULT_METHODS = [
    'login', 'loginServer', 'gameInit',
    'getMeta', 'getMaintenanceMeta',
    'getHomeInfo', 'getAchievements', 'getUserBanInfo', 'getSocketServer',
    'getAnnouncementInfo', 'getMultiplayserBossInfo', 'getUserUnionInfo',
    'getHomeInfo', 'getServerTimeStamp', 'recordTutorialStep',
]


def main():
    methods = list(sys.argv[1:]) or list(DEFAULT_METHODS)
    # 迭代器（scripts/single_iter.py）把新发现的方法追加在这里
    extra = os.path.join(ROOT, 'work', 'proto_methods.txt')
    if os.path.exists(extra):
        for line in open(extra, encoding='utf-8'):
            line = line.strip()
            if line and not line.startswith('#') and line not in methods:
                methods.append(line)
    out = os.path.join(ROOT, 'work', 'proto_capture')
    os.makedirs(out, exist_ok=True)

    db = GS.open_db() if hasattr(GS, 'open_db') else None
    if db is None:
        # 和 gameserver.main 一样：直接建库连接 + Services
        from db import Database
        db = Database(os.path.join(ROOT, 'server', 'canon.db'))
        db.connect()
    ctx = GS.Services(db)

    # 找一个该玩家的有效会话；没有就造一个
    sess = db.one("SELECT * FROM auth_session WHERE player_id=? AND revoked=0"
                 " ORDER BY create_time DESC", (PLAYER_ID,))
    sk = sess['session_key'] if sess is not None else None
    print('session_key =', sk)

    header = {'sk': sk, 'uk': str(PLAYER_ID), 'v': '11.0.61', 'aid': 'canon',
              'lang': 'zh_CN', 'pf': 'game', 'others': {'serverId': 1}}
    if sk:
        try:
            ctx.repos.player.touch_session(sk, PLAYER_ID)
        except Exception as e:
            print('touch_session 失败:', e)

    ok = 0
    for m in methods:
        params = {'serverId': 1}
        try:
            resp = dispatch(ctx, sk, m, params, header)
        except Exception as e:
            print('  %-26s ERR %r' % (m, e))
            continue
        resp.pop('method', None)
        fn = os.path.join(out, m + '.json')
        with open(fn, 'w', encoding='utf-8') as f:
            json.dump(resp, f, ensure_ascii=False)
        size = os.path.getsize(fn)
        keys = len(resp) if isinstance(resp, dict) else -1
        print('  %-26s %7d 字节  %d 个字段  retCode=%s'
              % (m, size, keys, (resp or {}).get('retCode')))
        ok += 1
    print('完成 %d/%d -> %s' % (ok, len(methods), out))
    return 0


if __name__ == '__main__':
    sys.exit(main())
