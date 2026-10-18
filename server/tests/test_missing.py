#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""全接口冒烟测试：把「客户端会调、服务端没实现」的接口逐个打一遍。

判定三档：
  OK    retCode==200 且有实质字段（不是空壳）
  BUSY  retCode!=200 但是**业务错误码**（缺元宝/未开启等，属正常，不算崩）
  SHELL retCode==200 但只有一个 retCode —— 说明服务端压根没这个 endpoint，
        客户端拿到空表后去 index 字段就会 Lua 报错（「点了就报错」的根源）
  CRASH retCode==500 或异常

跑法（需先起服务端）：
    python server/gameserver.py
    python server/tests/test_missing.py --port 80
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from test_client import Client, check, PASS, FAIL        # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUASRC = os.path.join(ROOT, 'work', 'luasrc')
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')

# 单机端特有、我们不跟的功能（用户明确说不学）
SKIP_SOLO_ONLY = {
    'createPayOrder', 'queryPayOrder', 'exchangeCdk', 'getGoldGodHistory',
    'getQuizBattleInfo', 'quizBattleSignup', 'quizBattleBet', 'quizBattleWatch',
    'getTeamBattleAttrs', 'getUnionBankWage', 'getHomeMessageConfig',
    'gmAddCoins', 'registerUser',
}

# 需要真实 id 的接口，这里给「能被业务层接受的最小参数」。
# 没列到的先用空参数打，看它能不能自己兜住。
PARAMS = {
    # ---- 背包装备
    'exchangeItem': {'exchangeId': 1, 'times': 1},
    'sellProps': {'items': [{'itemType': 7, 'metaId': 400010, 'amount': 1}]},
    'rebirthItem': {'itemId': 0, 'amount': 1},
    'sacrificeItem': {'cardId': 0, 'itemList': []},
    'synthetizeCard': {'cardId': 0},
    'synthetizeEquip': {'equipId': 0},
    'upgradeSkill': {'cardId': 0, 'skillId': 0},
    'gachaCardByBox': {'gachaId': 1, 'times': 1},
    # ---- 宝物
    'upgradeTreasure': {'treasureId': 0},
    'evolveTreasure': {'treasureId': 0},
    'splitTreasure': {'treasureId': 0},
    'sellTreasures': {'treasureIds': []},
    'potentialTreasure': {'treasureId': 0},
    'resetTreasurePotential': {'treasureId': 0},
    'setupTreasure': {'treasureId': 0, 'cardId': 0},
    # ---- 邮件
    'modifyEmail': {'emailId': 0, 'title': 't', 'content': 'c'},
    'pickUpReward': {'emailId': 0},
    'pickUpAllReward': {},
    'getSysEmailMeta': {},
    'getLimitReward': {},
    'getCountdownReward': {},
    'getChargeFeedbackReward': {},
    'getEnchantStepReward': {},
    'gainTutorialFinishReward': {},
    'gainDailyAchieveReward': {'id': 1},
    'getDailyAchieveInfo': {},
    'gainChapterFinishReward': {'chapterId': 1},
    'gainInviteReward': {},
    'gainInvitedReward': {},
    'gainMondayReward': {},
    'gainNewYearRewards': {'id': 1},
    # ---- 活动/商店
    'buyEnergy': {'buyNum': 1},
    'buyEventPoint': {'buyNum': 1},
    'buyMissionCompleteCount': {'buyNum': 1},
    'exchangeSecretShop': {'index': 1},
    'refreshSecretShop': {},
    'exchangeMedalShop': {'id': 1},
    'refreshMedalShop': {},
    'exchangeGiftBag': {'giftBagId': 1},
    'rechargeCalls': {},
    'challengeChrist': {'battleType': 1},
    'challengeContend': {'uid': 0},
    'challengeMysterious': {'nodeId': 1},
    'challengeFriendList': {'uid': 0},
    'testEvent': {'eventType': 1},
    # ---- 军团
    'getOwnUnionInfo': {},
    'getApplyUnions': {},
    'appointUnion': {'uid': 1, 'position': 1},
    'impeachUnionManager': {},
    'distributeBonus': {'bonusId': 1, 'uid': 1},
    'getBonusAccepterList': {},
    'rejectUnionAllApplies': {},
    'inspireUnionBattle': {},
    'getUnionBattlefieldReport': {},
    'getUnionBattlefieldReportList': {},
    'gainUnionBattleReward': {},
    'getUnionCityInfo': {},
    'userApplyUnionCity': {'cityId': 1},
    'applyUnionCity': {'cityId': 1},
    'getUnionWarCityMembersList': {'cityId': 1},
    'getGvgKnockoutInfo': {},
    'gainGvgKnockoutReward': {},
    'getGvgBattleResultDetail': {'reportId': 1},
    'getCrossGVGKnockoutStauts': {},
    'getCrossGVGBlessInfo': {},
    'blessForCrossGVG': {'blessType': 1},
    'inspireCrossGvg': {},
    'applyCrossGvg': {},
    'crossGvgCanMindApply': {},
    'crossGVGGroupBattle': {},
    'exchangeGvgFormation': {'formation': {}},
    'exchangeUnionFormation': {'formation': {}},
    'uploadCrossGvgTeamMirror': {'mirror': {}},
    'cancelTransferUnion': {},
    'getFiredUnionMemberStatus': {},
    # ---- 跨服
    'getCrossBossInfo': {},
    'challengeCrossBoss': {'battleType': 1},
    'gainCrossBossReward': {},
    'getCrossBossRankInfo': {},
    'inspireCrossBossTeam': {},
    'refreshCrossBossBattlePhase': {},
    'getCrossPkInfo': {},
    'getCrossPkCapacity': {},
    'getCrossPkReport': {},
    'challengeCrossUser': {'uid': 0},
    'buyCrossPvpChallengeTime': {},
    'gainCrossPvpActiveReward': {},
    'gainCrossPvpBattleReward': {},
    'gainCrossPkGuessReward': {},
    'gainCrossPkRankReward': {},
    'gainCrossPkServerReward': {},
    'gainCrossGachaRankAndMysteriousReward': {},
    'guessCrossPkRank': {'uid': 1},
    'refreshMatch': {},
    # ---- 其他
    'bindAccount': {'accountName': 'a', 'password': 'p'},
    'defaultPhoneNum': {},
    'clearElite': {},
    'getRobUserList': {},
    'inviteFbFriends': {},
    'robBeastFragment': {'uid': 0},
}


def client_endpoints():
    s = set()
    for dp, _, fs in os.walk(LUASRC):
        for f in fs:
            if not f.endswith('.lua'):
                continue
            try:
                txt = open(os.path.join(dp, f), 'rb').read().decode('utf-8', 'replace')
            except Exception:
                continue
            s |= set(EP.findall(txt))
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=80)
    ap.add_argument('--host', default='127.0.0.1')
    ap.add_argument('--device', default='smoke-device-001')
    ap.add_argument('--only', default='')
    ap.add_argument('--all', action='store_true',
                    help='测客户端会调的全部接口（含已实现的），用来找潜伏的空壳/崩溃')
    a = ap.parse_args()

    sys.path.insert(0, os.path.join(ROOT, 'server'))
    from api import load_handlers                     # noqa: E402
    reg = set(load_handlers())

    if a.all:
        want = sorted(client_endpoints() - SKIP_SOLO_ONLY)
    else:
        want = sorted(client_endpoints() - reg - SKIP_SOLO_ONLY)
    if a.only:
        want = [w for w in want if a.only in w]
    print('目标接口: %d 个%s\n' % (len(want), '（全部）' if a.all else '（未实现）'))

    c = Client(a.host, a.port)
    c.check_platform(a.device)
    c.mapping_account(a.device)
    c.session_key(a.device)
    c.rpc('login')
    c.rpc('loginServer')
    c.rpc('getMeta')
    sub, r = c.rpc('gameInit')
    if (r.get('gameInit') or {}).get('retCode') != 200:
        # 新设备没有角色，先创角再进
        print('  (gameInit 失败，尝试创角后再进)')
        sub, r = c.rpc('geneNickname')
        nick = (r.get('geneNickname') or {}).get('nickname') or 'Smoke'
        c.rpc(('createUser', {'nickName': nick, 'avatarId': 1, 'serverId': 1}))
        sub, r = c.rpc('gameInit')
    if (r.get('gameInit') or {}).get('retCode') != 200:
        print('!! 登录失败，先修登录: %s' % (r.get('gameInit') or {}))
        return 1

    results = []
    # 战斗模拟类接口（challengeCrossBoss / getCrossPkReport 等）单次要跑完整回合，
    # 批量太大会顶到 urllib 的超时，所以一批只发 8 个，并把超时放宽。
    BATCH = 8
    for i in range(0, len(want), BATCH):
        chunk = want[i:i + BATCH]
        calls = [(m, PARAMS.get(m, {})) for m in chunk]
        try:
            sub, resp = c.rpc(*calls)
        except Exception as e:
            print('!! 批量请求异常 @%d (%s): %s' % (i, ','.join(chunk[:2]), e))
            for m in chunk:
                results.append(('CRASH', m, 'BATCH_TIMEOUT', 0, str(e)[:80]))
            continue
        for m in chunk:
            d = resp.get(m) or {}
            code = d.get('retCode')
            extra = len([k for k in d if k not in ('method', 'retCode')])
            if code == 500:
                st = 'CRASH'
            elif code != 200:
                st = 'BUSY'
            elif extra == 0:
                st = 'SHELL'
            else:
                st = 'OK'
            results.append((st, m, code, extra, str(d.get('extraMsg', ''))[:90]))

    order = {'CRASH': 0, 'SHELL': 1, 'BUSY': 2, 'OK': 3}
    results.sort(key=lambda x: (order[x[0]], x[1]))
    counts = {}
    for st, *_ in results:
        counts[st] = counts.get(st, 0) + 1
    print('\n================ 汇总 ================')
    for k in ('OK', 'BUSY', 'SHELL', 'CRASH'):
        print('  %-6s %d' % (k, counts.get(k, 0)))
    for st, m, code, extra, msg in results:
        if st != 'OK':
            print('  [%s] %-40s code=%-6s %s' % (st, m, code, msg if st == 'CRASH' else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
