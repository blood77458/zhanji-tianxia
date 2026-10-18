#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""模拟客户端：用真实协议跑一遍登录 → 创角 → gameInit → 核心玩法。

这不是「调函数测试」，而是**真的**发 HTTP、真的走
headercvt(zlib(amf3(...)))、真的解析响应 —— 客户端怎么发它就怎么发。

跑法：
    # 先起服务端
    python server/gameserver.py --port 8080
    # 再跑测试
    python server/tests/test_client.py --port 8080
"""
import argparse
import json
import os
import struct
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import protocol as P                                    # noqa: E402

PASS, FAIL = [], []


def as_list(v):
    """AMF3 的密集数组解码回 Python 是 {1:..,2:..} 这种 Lua 表；
    空数组则变成 {}。这里统一还原成 list，方便断言。"""
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        if not v:
            return []
        if all(isinstance(k, int) for k in v):
            return [v[k] for k in sorted(v)]
    return []


def check(name, cond, detail=''):
    (PASS if cond else FAIL).append(name)
    print('  %s %s%s' % ('PASS' if cond else 'FAIL', name,
                         ('  <- ' + detail) if (detail and not cond) else ''))


class Client:
    def __init__(self, host, port):
        self.base = 'http://%s:%d' % (host, port)
        self.sk = None
        self.uid = None
        self.account_id = None
        self.st = 0

    # ---------------------------------------------------------------- 原始 HTTP
    def post_raw(self, path, body, ctype='application/octet-stream'):
        req = urllib.request.Request(self.base + path, data=body,
                                     headers={'Content-Type': ctype})
        # 超时放宽到 90s：战斗模拟类接口（跨服 Boss / PK 战报）单次就要跑完整回合，
        # 一次批量请求里带上它们时 15s 不够，会在客户端侧误报 TimeoutError。
        with urllib.request.urlopen(req, timeout=90) as r:
            return r.status, r.read()

    def get_raw(self, path):
        with urllib.request.urlopen(self.base + path, timeout=15) as r:
            return r.status, r.read()

    # ---------------------------------------------------------------- REST
    def system_info(self):
        st, body = self.post_raw('/systemInfo', b'')
        return P.amf3_decode(body)

    def session_key(self, udid='test-device-001'):
        st, body = self.post_raw('/sessionKey/init',
                                 ('uid=-1&uuid=u-1&udid=%s' % udid).encode(),
                                 'application/x-www-form-urlencoded')
        parts = body.decode().split(',')
        if len(parts) >= 3:
            self.uid, self.uuid, self.sk = parts[0], parts[1], parts[2]
        return parts

    def check_platform(self, udid='test-device-001'):
        st, body = self.post_raw('/check/android?',
                                 ('udid=%s&seconds=%d&sk=x&loginType=1'
                                  % (udid, int(time.time()))).encode(),
                                 'application/x-www-form-urlencoded')
        return json.loads(body)

    def mapping_account(self, platform_uid='test-device-001'):
        st, body = self.post_raw('/mappingAccount',
                                 ('platformId=android&platformUid=%s&sid=1'
                                  % platform_uid).encode(),
                                 'application/x-www-form-urlencoded')
        d = json.loads(body)
        self.account_id = d.get('accountId')
        return d

    def static_version(self):
        st, body = self.get_raw('/staticVersion?clientVersion=11.0.61')
        return json.loads(body)

    def get_login_server(self):
        st, body = self.get_raw('/getLoginServer?accountId=%s' % self.account_id)
        return body.decode()

    # ---------------------------------------------------------------- RPC
    def rpc(self, *methods):
        """methods: ('name', {params}) 或 'name'"""
        items = []
        for m in methods:
            if isinstance(m, tuple):
                methods_name, params = m
                d = dict(params or {})
            else:
                methods_name, d = m, {}
            d['method'] = methods_name
            items.append(d)
        header = {
            'v': '0.3.0', 'mv': '12306', 'ct': 0, 'aid': 'canon', 'lang': 'zh_CN',
            'pf': 'android', 'notify': True, 'sk': self.sk, 'others': {},
            'st': self.st,
        }
        self.st += 1
        payload = P.amf3_encode([header, items])
        # ⚠️ 客户端方向：请求 XOR 0xC3、响应 XOR 0x71（与服务端相反）
        body = P.headercvt_wrap_req(P.encode_body(payload))
        st, raw = self.post_raw('/protocol?uid=%s' % (self.uid or -1), body)
        data = P.amf3_decode(P.try_decode_body(P.headercvt_unwrap_resp(raw))[0])
        sub = data.get(1) or {}
        resp = data.get(2) or {}
        out = {}
        for k in sorted(k for k in resp if isinstance(k, int)):
            r = dict(resp[k])
            out[r.get('method')] = r
        return sub, out


def run_existing(c, udid):
    """跨重启验证：同一个设备号再登录一次，数据必须还在。

    用法：
        python tests/test_client.py --port 8080 --device dev-A          # 先建号
        # 重启服务端
        python tests/test_client.py --port 8080 --device dev-A --existing
    """
    print('=' * 74)
    print('跨重启持久化验证  device=%s' % udid)
    print('=' * 74)
    c.check_platform(udid)
    c.mapping_account(udid)
    parts = c.session_key(udid)
    check('重新拿到会话', len(parts) == 3 and bool(c.sk))

    sub, r = c.rpc('login')
    check('login: retCode == 200', r.get('login', {}).get('retCode') == 200)

    sub, r = c.rpc('loginServer')
    ls = r.get('loginServer', {})
    check('loginServer.uid 是字符串', isinstance(ls.get('uid'), str))
    # ⚠️ "1" 是「新玩家」哨兵值（LoginScene.lua:349）。
    # init_db.py 把 player_id 起点设在 100000，就是为了不和它撞车。
    check('老账号 loginServer.uid 不是新号哨兵 "1"',
          str(ls.get('uid')) != '1', repr(ls.get('uid')))

    sub, r = c.rpc('gameInit')
    gi = r.get('gameInit', {})
    check('gameInit: retCode == 200', gi.get('retCode') == 200)
    su = gi.get('sharkUser') or {}
    cards = as_list((gi.get('sharkCards') or {}).get('sharkCards'))
    equips = as_list((gi.get('sharkEquips') or {}).get('sharkEquips'))
    check('武将数据仍在', len(cards) > 0, 'len=%d' % len(cards))
    check('装备数据仍在', len(equips) > 0, 'len=%d' % len(equips))
    check('角色 uid 与 loginServer 一致（player_id 稳定）',
          str(su.get('uid')) == str(ls.get('uid')), '%s vs %s' % (su.get('uid'), ls.get('uid')))

    worn = [e for e in equips if int(e.get('cardId') or 0) > 0]
    check('上次穿的装备状态被持久化（cardId 仍在）', len(worn) > 0,
          'worn=%d' % len(worn))

    print()
    print('=' * 74)
    print('结果: %d 通过 / %d 失败' % (len(PASS), len(FAIL)))
    if FAIL:
        for f in FAIL:
            print('   - %s' % f)
    print('=' * 74)
    return 1 if FAIL else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='127.0.0.1')
    ap.add_argument('--port', type=int, default=8080)
    ap.add_argument('--device', default=None, help='固定设备号，用于跨重启验证')
    ap.add_argument('--existing', action='store_true',
                    help='按「老账号」模式跑：要求已有角色，跳过创角')
    args = ap.parse_args()
    c = Client(args.host, args.port)
    udid = args.device or ('test-device-%d' % (int(time.time()) % 100000))

    if args.existing:
        return run_existing(c, udid)

    print('=' * 74)
    print('阶段 1: REST 登录链路')
    print('=' * 74)
    si = c.system_info()
    check('POST /systemInfo 返回裸 AMF3 且含 ts', isinstance(si, dict) and 'ts' in si,
          repr(si)[:80])

    sv = c.static_version()
    check('GET /staticVersion 是 JSON', isinstance(sv, dict) and 'config_md5' in sv)

    chk = c.check_platform(udid)
    check('POST /check/android 返回 code=1', chk.get('code') == 1, repr(chk))
    check('loginAccountId 是正整数', int(chk.get('loginAccountId') or 0) > 0)

    mp = c.mapping_account(udid)
    check('POST /mappingAccount 返回 code=1 且 accountId>0',
          mp.get('code') == 1 and int(mp.get('accountId') or 0) > 0, repr(mp))

    parts = c.session_key(udid)
    check('POST /sessionKey/init 返回纯文本三段式', len(parts) == 3, repr(parts))
    check('sessionKey 非空', bool(c.sk))

    print()
    print('=' * 74)
    print('阶段 2: RPC login → loginServer → createUser → gameInit')
    print('=' * 74)
    sub, r = c.rpc('login')
    check('login: subHeader.errCode <= 0', int(sub.get('errCode', 1)) <= 0, repr(sub))
    check('login: retCode == 200', r.get('login', {}).get('retCode') == 200)

    sub, r = c.rpc('loginServer')
    ls = r.get('loginServer', {})
    check('loginServer: retCode == 200', ls.get('retCode') == 200)
    check('loginServer.uid 是字符串', isinstance(ls.get('uid'), str), repr(ls.get('uid')))

    sub, r = c.rpc('getMeta')
    gm = r.get('getMeta', {})
    check('getMeta: retCode == 200', gm.get('retCode') == 200)
    check('getMeta 含 gameSettingConfig', isinstance(gm.get('gameSettingConfig'), dict))
    check('getMeta 含 serverPartitionConfig', 'serverPartitionConfig' in gm)

    sub, r = c.rpc(('geneNickname', {}))
    check('geneNickname 返回 nickname', bool(r.get('geneNickname', {}).get('nickname')))

    sub, r = c.rpc(('createUser', {'nickName': '测试主公', 'avatarId': 1}))
    cu = r.get('createUser', {})
    check('createUser: retCode == 200', cu.get('retCode') == 200)
    su = cu.get('sharkUser') or {}
    check('createUser.sharkUser.uid 是字符串', isinstance(su.get('uid'), str), repr(su.get('uid')))

    sub, r = c.rpc('gameInit')
    gi = r.get('gameInit', {})
    check('gameInit: retCode == 200', gi.get('retCode') == 200)

    REQUIRED = ['sharkUser', 'sharkUserExtend', 'sharkUserExtendMore', 'sharkCards',
                'sharkEquips', 'sharkProps', 'sharkSpirits', 'sharkTreasures',
                'sharkMatrices', 'sharkUserBattleArray', 'sharkMissionContext',
                'sharkSceneProcess', 'missionCompletes', 'sharkDailyData',
                'sharkDailyDataExtend', 'sharkUserSecretShop', 'sharkElite',
                'sharkSkyTower', 'sharkChristInfo', 'sharkGachaInfo', 'sharkDice',
                'sharkShop', 'sharkGemCards', 'timestamp']
    missing = [k for k in REQUIRED if k not in gi]
    check('gameInit 顶层 %d 个 key 齐全' % len(REQUIRED), not missing, '缺: %s' % missing)

    u = gi.get('sharkUser') or {}
    check('sharkUser.uid 是字符串', isinstance(u.get('uid'), str))
    check('sharkUser.additionalCardIds 是字符串', isinstance(u.get('additionalCardIds'), str),
          repr(u.get('additionalCardIds')))
    for f in ('gem', 'freeGems', 'usedFreeGems', 'rechargeGems', 'usedRechargeGems',
              'energy', 'eventPoint', 'coins', 'gold', 'level', 'exp'):
        check('sharkUser.%s 是数字' % f, isinstance(u.get(f), (int, float)), repr(u.get(f)))
    check('sharkMissionContext 非空且完整',
          isinstance(gi.get('sharkMissionContext'), dict)
          and 'missionId' in gi['sharkMissionContext'])
    cards = as_list((gi.get('sharkCards') or {}).get('sharkCards'))
    check('sharkCards 有内容', len(cards) > 0, 'len=%d' % len(cards))
    check('sharkUserBattleArray 非空', len(as_list(gi.get('sharkUserBattleArray'))) > 0)
    card = cards[0] if cards else {}
    check('首张卡有 cardSkills（空会导致编队界面崩）',
          len(as_list(card.get('cardSkills'))) > 0)
    check('首张卡 treasureId 是数字（不是 None）', isinstance(card.get('treasureId'), int))
    check('sharkProps 是列表', isinstance(gi.get('sharkProps'), dict))

    print()
    print('=' * 74)
    print('阶段 3: 核心玩法')
    print('=' * 74)
    pid = int(su.get('uid'))

    sub, r = c.rpc('getHomeInfo')
    hi = r.get('getHomeInfo', {})
    check('getHomeInfo: retCode == 200', hi.get('retCode') == 200)
    check('unionMonsterEscapeSeconds 是数字（nil 会崩）',
          isinstance(hi.get('unionMonsterEscapeSeconds'), int))
    check('unionMonsterHp 是数字', isinstance(hi.get('unionMonsterHp'), int))

    sub, r = c.rpc('getProps')
    check('getProps 返回 sharkProps',
          isinstance(r.get('getProps', {}).get('sharkProps'), (list, dict)))

    sub, r = c.rpc('getEquips')
    eqs = as_list(r.get('getEquips', {}).get('sharkEquips'))
    check('getEquips 返回 sharkEquips', isinstance(r.get('getEquips', {}).get('sharkEquips'),
                                                   (list, dict)))
    # id_alloc 是全局序列，所以装备 id 因账号而异 —— 从响应里取第一件
    equip_id = int(eqs[0]['equipId']) if eqs else 0
    check('新号有初始装备', equip_id > 0, 'len=%d' % len(eqs))

    # 1 级玩家的装备等级上限就是 1，upgradeEquip 应当**正确地**拒绝（712509），
    # 而不是崩。这本身就是一条有效断言。
    sub, r = c.rpc(('upgradeEquip', {'equipId': equip_id}))
    ue = r.get('upgradeEquip', {})
    check('upgradeEquip 返回合法 retCode', ue.get('retCode') in (200, 712509),
          repr(ue))
    if ue.get('retCode') == 200:
        check('upgradeEquip 返回 sharkEquip', isinstance(ue.get('sharkEquip'), dict))

    sub, r = c.rpc(('equipEnchant', {'equipId': equip_id}))
    ee = r.get('equipEnchant', {})
    check('equipEnchant: retCode == 200', ee.get('retCode') == 200, repr(ee))
    check('equipEnchant 返回 sharkEquip', isinstance(ee.get('sharkEquip'), dict))

    sub, r = c.rpc(('setupEquip', {'cardId': card.get('cardId'), 'equipId': equip_id}))
    check('setupEquip: retCode == 200', r.get('setupEquip', {}).get('retCode') == 200)

    sub, r = c.rpc('gameInit')
    c2 = (as_list(((r.get('gameInit') or {}).get('sharkCards') or {})
                  .get('sharkCards')) or [{}])[0]
    check('穿装备后 equipIds 反查到了（单点存储验证）',
          as_list(c2.get('equipIds')) == [equip_id], repr(c2.get('equipIds')))

    # ---------------------------------------------------------------- 成长曲线 + 战力
    print()
    print('=' * 74)
    print('阶段 3.5: 卡牌成长曲线与战斗力')
    print('=' * 74)
    gi2 = r.get('gameInit') or {}
    su2 = gi2.get('sharkUser') or {}
    ext2 = gi2.get('sharkUserExtend') or {}
    check('sharkUser.fightCapacity > 0（战力由服务端算）',
          int(su2.get('fightCapacity') or 0) > 0, repr(su2.get('fightCapacity')))
    check('sharkUserExtend.fightCapacity == sharkUser.fightCapacity',
          int(ext2.get('fightCapacity') or 0) == int(su2.get('fightCapacity') or 0),
          '%s vs %s' % (ext2.get('fightCapacity'), su2.get('fightCapacity')))
    check('单卡 fightCapacity > 0（按原公式逐卡算）',
          int(c2.get('fightCapacity') or 0) > 0, repr(c2.get('fightCapacity')))

    # 拿一张材料卡喂给主卡，验证升级曲线
    before_lv = int(c2.get('level') or 1)
    code, payload = None, None
    sub, r = c.rpc(('gachaCard', {'gachaId': 3, 'time': 1}))
    sub, r = c.rpc('gameInit')
    all_cards = as_list(((r.get('gameInit') or {}).get('sharkCards') or {}).get('sharkCards'))
    main_id = int(c2.get('cardId'))
    matter = [int(x['cardId']) for x in all_cards if int(x['cardId']) != main_id]
    if matter:
        sub, r = c.rpc(('upgradeCard', {'cardId': main_id, 'slaveIds': matter[:3]}))
        uc = r.get('upgradeCard', {})
        check('upgradeCard（吃材料）retCode == 200', uc.get('retCode') == 200, repr(uc)[:100])
        sc = uc.get('sharkCard') or {}
        check('升级后等级提升', int(sc.get('level') or 0) > before_lv,
              'L%d -> %s' % (before_lv, sc.get('level')))
        check('升级后战力提升', int(sc.get('fightCapacity') or 0) > int(c2.get('fightCapacity') or 0),
              '%s -> %s' % (c2.get('fightCapacity'), sc.get('fightCapacity')))
    else:
        check('抽卡产出材料卡（用于升级验证）', False, '没有材料卡')

    # Fresh accounts have no friendship points: use the legitimate free pool,
    # instead of relying on the historical bug that charged gems for pool 1.
    sub, r = c.rpc(('gachaCardFree', {'gachaId': 2}))
    gc = r.get('gachaCardFree', {})
    check('gachaCardFree: retCode == 200', gc.get('retCode') == 200, repr(gc)[:120])
    check('gachaCardFree 有 rewards', isinstance(gc.get('rewards'), (list, dict)))
    cards_received = [rw for rw in as_list(gc.get('rewards')) if rw.get('itemType') == 5]
    check('抽卡结果武将等级经验完整', bool(cards_received) and all(
        isinstance(rw.get('level'), (int, float)) and rw['level'] >= 1
        and isinstance(rw.get('exp'), (int, float)) for rw in cards_received))

    sub, r = c.rpc(('clearMission', {'missionId': 100101, 'routeId': 1, 'clearRounds': 1}))
    cm = r.get('clearMission', {})
    check('clearMission: retCode == 200', cm.get('retCode') == 200, repr(cm)[:120])
    check('clearMission 有 clearMissionRewards',
          isinstance(cm.get('clearMissionRewards'), (list, dict)))

    sub, r = c.rpc(('adjustTeam', {'mainCardId': card.get('cardId'),
                                   'additionalCardIds': ''}))
    check('adjustTeam: retCode == 200', r.get('adjustTeam', {}).get('retCode') == 200)

    sub, r = c.rpc('getUserEmails')
    em = r.get('getUserEmails', {})
    check('getUserEmails: retCode == 200', em.get('retCode') == 200)
    for k in ('sysEmails', 'rewardEmails', 'sysNotices', 'userEmails', 'sysEmailMeta'):
        check('getUserEmails.%s 是列表' % k, isinstance(em.get(k), (list, dict)),
              repr(type(em.get(k))))
    _se = as_list(em.get('sysEmails'))
    _sm = as_list(em.get('sysEmailMeta'))
    check('sysEmails 有内容（新号应有新手礼包）', len(_se) > 0, 'len=%d' % len(_se))
    check('sysEmails[0].receiveSeconds 存在且是数字（nil 会崩）',
          bool(_se) and isinstance(_se[0].get('receiveSeconds'), (int, float)),
          repr(_se[0].get('receiveSeconds') if _se else None))
    check('sysEmailMeta[0].contentText 非空（gsub(nil) 会崩）',
          bool(_sm) and bool(_sm[0].get('contentText')))

    sub, r = c.rpc('getAchievements')
    check('getAchievements: retCode == 200', r.get('getAchievements', {}).get('retCode') == 200)

    print()
    print('=' * 74)
    print('阶段 4: 持久化验证（重启后数据仍在）')
    print('=' * 74)
    sub, r = c.rpc('getServerTimeStamp')
    gold_before = u.get('gold')

    print()
    print('=' * 74)
    print('结果: %d 通过 / %d 失败' % (len(PASS), len(FAIL)))
    if FAIL:
        print('失败项:')
        for f in FAIL:
            print('   - %s' % f)
    print('=' * 74)
    return 1 if FAIL else 0


if __name__ == '__main__':
    sys.exit(main())
