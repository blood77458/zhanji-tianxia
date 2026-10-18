#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""端点注册表与分发。

用注册表替代原服务端的两条 if/elif 长链：新增一个接口 = 加一个
`@endpoint("method")` 函数，不用再往 600 行的分支里塞。

处理函数签名统一为 `fn(api, params) -> dict | int | (int, dict)`：
    dict             → 合并进响应，retCode=200
    int              → 直接当 retCode（业务错误码）
    (code, dict)     → code 作 retCode；code==200 时合并 dict
"""
import json
import time

from services import Services


class ApiError(Exception):
    def __init__(self, code, msg=""):
        super().__init__(msg or str(code))
        self.code = int(code)
        self.msg = msg


REGISTRY = {}
UNKNOWN = []
#: 导入失败的补充模块名（handlers_xxx.py 写坏时会记在这里，服务端照常起来）
BROKEN_MODULES = []


def to_list(v):
    """把 AMF3 解码出来的「Lua 数组」还原成 Python list。

    ⚠️ 这是本项目最容易踩的坑之一：AMF3 的密集数组解码回来是
    `{1: a, 2: b, 3: c}` 这种**以整数为键的 dict**（Lua 表），
    直接 `for x in v` 拿到的是下标 1/2/3 而不是元素。

    客户端所有「列表参数」——`slaveIds` / `equipIds` / `cardIds` /
    `friendUids` / `sysEmailIds` —— 都必须过这个函数。
    """
    if v is None:
        return []
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        if not v:
            return []
        if all(isinstance(k, int) for k in v):
            return [v[k] for k in sorted(v)]
        return [v]          # 关联表当单个元素
    if isinstance(v, tuple):
        return list(v)
    return [v]


def to_int_list(v):
    out = []
    for x in to_list(v):
        try:
            out.append(int(x))
        except (TypeError, ValueError):
            continue
    return out


def endpoint(name):
    def deco(fn):
        REGISTRY[name] = fn
        return fn
    return deco


# ---------------------------------------------------------------------------
# 别名表：客户端 Lua 里 `endpoint = "X"` 的**实际拼写** -> 服务端当前的注册名。
#
# 这些是「同一个接口、两边写得不一样」的情况。不加别名时服务端永远匹配不到，
# 表现就是界面上点了报错 / 没反应。对照脚本：scripts/cmp_endpoint_fuzzy.py
# （客户端请求类文件名 -> endpoint 串见 scripts/list_client_endpoints.py）
# ---------------------------------------------------------------------------
ALIASES = {
    'skipSkyTowerBattle':     'skyTowerSkipBattle',
    'gainSkipBattleAddition': 'skyTowerSkipGainAdd',
    'gainSkipBattleRewards':  'skyTowerSkipGainRewards',
    'readRewardEmail':        'EmailReadRewardEmail',
    'batchDeleteRewardEmail': 'EmailBatchDeleteRewardEmail',
    'batchDeleteSysEmail':    'EmailBatchDeleteSysEmail',
    'batchDeleteSysNotice':   'EmailBatchDeleteSysNotice',
    'batchDeleteUserEmail':   'EmailBatchDeleteUserEmail',
    'gainRewardEmailReward':  'EmailGainRewardEmailReward',
    'getUnionNewsList':       'getUnionNews',
    'modifyUnionDeclaration': 'changeUnionDeclaration',
    'modifyUnionNotice':      'changeUnionNotice',
    'buyTreasureGrid':        'buyGrid',
}


def apply_aliases():
    """把别名指到已注册的实现上。只补不覆盖，避免踩掉同名真实处理器。"""
    added = []
    for alias, real in ALIASES.items():
        fn = REGISTRY.get(real)
        if fn is None or alias in REGISTRY:
            continue
        REGISTRY[alias] = fn
        added.append(alias)
    return added


def load_handlers():
    """导入处理器模块，触发 @endpoint 注册。

    顺序即覆盖顺序：后导入的会覆盖同名 endpoint，所以活动/竞技场放在最后，
    让它们盖掉 handlers_more.py 里的占位实现。

    之后再**自动发现**同包里其余的 `handlers_*.py`（补齐用的新模块，
    比如 handlers_mail.py / handlers_cross.py），这样新增模块不用改本文件。
    """
    from . import handlers          # noqa: F401
    from . import handlers_more     # noqa: F401
    from . import handlers_activity  # noqa: F401
    from . import handlers_union     # noqa: F401
    from . import handlers_activity_online  # noqa: F401

    import importlib
    import pkgutil
    import traceback
    base = {'handlers', 'handlers_more', 'handlers_activity', 'handlers_union',
            'handlers_activity_online'}
    for m in pkgutil.iter_modules(__path__):
        if m.name.startswith('handlers_') and m.name not in base:
            try:
                importlib.import_module('.' + m.name, __name__)
            except Exception:
                # 一个补充模块写坏了不能拖垮整个服务端 —— 记下来，继续加载其它模块。
                # 起服务时看得到这条，`python scripts/final_check.py` 也会因此报出
                # 对应接口 MISSING，不会被静默忽略。
                print('[api] !! 跳过 %s.py（导入失败）:' % m.name)
                traceback.print_exc()
                BROKEN_MODULES.append(m.name)

    apply_aliases()
    return REGISTRY


class Api:
    """一次 RPC 请求的上下文。"""

    def __init__(self, ctx, session_key=None, player_id=None, header=None):
        self.ctx = ctx
        self.sk = session_key
        self.player_id = int(player_id) if player_id else None
        self.header = header or {}
        self.repos = ctx.repos
        self.db = ctx.db

    # ---- 便捷访问 ----
    @property
    def player(self):
        return self.repos.player.player(self.player_id)

    def require_player(self):
        p = self.player
        if p is None:
            raise ApiError(710070)          # USER_NOT_EXIST
        return p

    def param(self, params, key, default=None):
        v = (params or {}).get(key, default)
        return default if v is None else v

    def list_param(self, params, key, default=None):
        """读一个「列表型」参数，自动把 AMF3 的 Lua 表还原成 list。"""
        v = (params or {}).get(key)
        if v is None:
            return list(default or [])
        return to_list(v)

    def int_list_param(self, params, key, default=None):
        return to_int_list((params or {}).get(key) or default or [])


def dispatch(ctx, session_key, method, params, header=None):
    """执行一个 endpoint，返回响应 dict（**不含** method 字段，由调用方补）。"""
    fn = REGISTRY.get(method)
    if fn is None:
        UNKNOWN.append((method, params))
        _record_unknown(ctx, method, params)
        return {'retCode': 200}             # 空壳：与原服务端行为一致

    player_id = None
    if session_key:
        s = ctx.repos.player.session(session_key)
        if s and not int(s['revoked']):
            player_id = int(s['player_id']) if s['player_id'] else None
    api = Api(ctx, session_key, player_id, header)

    try:
        res = fn(api, params or {})
    except ApiError as e:
        return {'retCode': e.code}
    except Exception as e:                   # 兜底：绝不让单接口异常打断整条响应
        import traceback
        traceback.print_exc()
        # 带上异常类型：sqlite3.Row 取不存在的列会抛 `IndexError: No item with that key`，
        # 光看消息根本不知道是哪个字段。
        return {'retCode': 500,
                'extraMsg': '%s: %s' % (type(e).__name__, str(e)[:110])}

    if res is None:
        return {'retCode': 200}
    if isinstance(res, int):
        return {'retCode': int(res)}
    if isinstance(res, tuple) and len(res) == 2:
        code, payload = res
        out = {'retCode': int(code)}
        if int(code) == 200 and isinstance(payload, dict):
            out.update(payload)
        return out
    if isinstance(res, dict):
        out = {'retCode': 200}
        out.update(res)
        return out
    return {'retCode': 200}


def _record_unknown(ctx, method, params):
    try:
        ctx.db.con.execute(
            "INSERT INTO unknown_rpc(player_id, method, params_json, create_time)"
            " VALUES (0,?,?,?)",
            (method, json.dumps(params, ensure_ascii=False, default=str)[:4000],
             int(time.time())))
    except Exception:
        pass
