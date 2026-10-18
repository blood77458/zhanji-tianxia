#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""活动接口冒烟测试：把「活动类」接口全打一遍，看有没有崩（retCode 500）。"""
import argparse
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from test_client import Client, as_list, PASS, FAIL, check   # noqa: E402


# (method, params) —— 无参的传 {}
CALLS = [
    # 每日答题
    ('getQuestionInfo', {}), ('getQuestionDailyReward', {}), ('getQuestionWeekReward', {}),
    ('answerQuestion', {'answer': 1, 'questionMetaId': 0}),
    # 通天塔
    ('getSkyTowerInfo', {}), ('challengeSkyTower', {'floor': 1, 'type': 0, 'version': 0}),
    ('gainFloorAddition', {'type': 1}), ('gainYesterdayAddition', {}),
    ('gainRankRewards', {}), ('skyTowerSkipBattle', {}),
    ('resetClimbData', {'type': 1}), ('startAutoClimbBabel', {}),
    ('gainAutoClimbReward', {'speedUp': False}),
    ('challengeBabel', {}), ('resetBabel', {}),
    # 竞技场
    ('getArenaMatchedPlayers', {}), ('challengeArena', {'matchedUid': 0}),
    ('gainArenaScoreByRank', {}), ('getPkInfo', {}), ('getPkFoes', {}),
    ('getPkTopRankUsers', {}), ('gainPkBuff', {}), ('gainPkRewards', {}),
    # Boss
    ('getWorldBossInfo', {}), ('challengeWorldBoss', {'battleType': 1}),
    ('gainWorldBossRewards', {}), ('inspireInWorldBoss', {}),
    ('setAutoWorldBoss', {'autoChallenge': True}),
    ('getMultiplayserBossInfo', {}), ('getMultiplayerBossRank', {}),
    ('getMultiplayerBossDamage', {}), ('getMultiplayerBossLeftHp', {}),
    ('gainMultiplayerBossRankReward', {}),
    ('gainMultiplayerBossParticipationReward', {}),
    # 消费 / 充值
    ('getGemConsumeInfo', {}), ('gainGemConsumeRewards', {'rewardId': 1}),
    ('getRechargeInfo', {}), ('gainChargeMoneyReward', {'rewardId': 1}),
    ('getAccumulateGems', {}),
    # 连登 / 签到
    ('getContinuousLoginReward', {}), ('gainContinuousLoginRewardV2', {}),
    ('getSignInReward', {}), ('getLoginReward', {}),
    # 气球 / 骰子 / 通缉 / 秒杀
    ('getActivityBalloonInfo', {}), ('chargeBalloon', {'ensureSuccess': True}),
    ('gainBalloonPoint', {}), ('gainBalloonPointReward', {'id': 1}),
    ('gainBalloonRankReward', {}),
    ('throwDice', {}), ('gainDiceReward', {}), ('changeDiceLuck', {}),
    ('getWantedInfo', {}), ('refreshWanted', {'minimum': 0}),
    ('challengeWanted', {}),
    ('getSeckillInfo', {}), ('buySeckillItem', {'id': 1}),
    # 神兵谱 / 扭蛋
    ('getTreasureboxPointsInfo', {}), ('gainTreasureboxPointsReward', {'id': 1}),
    ('gainTreasureboxPointsRankReward', {}),
    ('getGachaPointsInfo', {}), ('gainGachaPointsRewards', {}),
    ('getCrossGachaInfo', {}),
    # 杂项活动
    ('getConsumeRewardInfo', {}), ('gainConsumeReward', {'id': 1}),
    ('gainDayReward', {'dayRewardId': 1}), ('gainSwornReward', {'swornRewardId': 1}),
    ('recordPraiseId', {'praiseId': 1}), ('gainPraiseReward', {'praiseId': 1}),
    ('setoffFireworks', {}), ('gainFortuneRewards', {}),
    ('getLevelRaceInfo', {}), ('gainLevelRaceRewards', {}),
    ('getTaskInfo', {}), ('getDailyActiveInfo', {}),
    ('getUserUnionInfo', {}), ('getUnionList', {}),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--host', default='127.0.0.1')
    ap.add_argument('--port', type=int, default=8080)
    ap.add_argument('--device', default=None)
    args = ap.parse_args()
    c = Client(args.host, args.port)
    udid = args.device or ('act-dev-%d' % (int(__import__('time').time()) % 100000))

    # 建号
    c.check_platform(udid)
    c.mapping_account(udid)
    c.session_key(udid)
    c.rpc('login')
    c.rpc('loginServer')
    c.rpc(('createUser', {'nickName': '活动测试', 'avatarId': 1}))
    sub, r = c.rpc('gameInit')
    check('建号 + gameInit 成功', r.get('gameInit', {}).get('retCode') == 200)

    # 先充一笔，让累充类活动有门槛可过。
    # ⚠️ 订单号必须唯一：服务端按 order_id 做主键防重复发货，
    #    固定订单号在第二次跑时会被正确地拦下（不发钻石）。
    c.rpc(('validatePaymentOrder', {'orderId': 'act-test-%s' % udid,
                                    'productId': 'he_gold_6480'}))
    sub, r = c.rpc('getAccumulateGems')
    check('充值后 accumulateGems > 0',
          int(r.get('getAccumulateGems', {}).get('accumulateGems') or 0) > 0,
          repr(r.get('getAccumulateGems')))

    print()
    print('=' * 74)
    print('活动接口冒烟（%d 个）' % len(CALLS))
    print('=' * 74)
    bad = []
    for method, params in CALLS:
        try:
            sub, r = c.rpc((method, params))
            rr = r.get(method, {})
            code = rr.get('retCode')
            if code == 200:
                keys = [k for k in rr.keys() if k not in ('method', 'retCode')]
                print('  OK   %-38s %s' % (method, ', '.join(keys[:5])))
            else:
                print('  !!   %-38s retCode=%s %s'
                      % (method, code, rr.get('extraMsg', '')[:50]))
                bad.append((method, code, rr.get('extraMsg', '')))
        except Exception as e:
            print('  EXC  %-38s %s' % (method, e))
            bad.append((method, 'exc', str(e)))

    print()
    print('=' * 74)
    print('军团系（建团 → 商店 → 建设 → 斗兽 → 审批）')
    print('=' * 74)
    # ⚠️ 军团名在同一 server 内唯一（服务端按 UNIQUE(server_id,name) 约束），
    #    固定名字在第二次跑时会被正确地拒绝（716302）。
    guild_name = ('测试军团%s' % udid[-6:])[:16]
    sub, r = c.rpc(('createUnion', {'unionName': guild_name, 'declaration': '测试用',
                                    'notice': '欢迎'}))
    cu = r.get('createUnion', {})
    check('createUnion 成功', cu.get('retCode') == 200, repr(cu)[:100])
    gid = cu.get('unionId')

    for method, params in [
        ('getUserUnionInfo', {}), ('getUnionInfo', {}),
        ('getUnionMembersList', {}), ('getUnionNews', {}),
        ('getUnionBuildingHallInfo', {'unionBuildingId': 1}),
        ('getUnionBuildingBankInfo', {'unionBuildingId': 3}),
        ('getUnionBuildingShopInfo', {'unionBuildingId': 2}),
        ('getUnionBuildingColosseumInfo', {'unionBuildingId': 4}),
        ('getUnionAppliers', {}),
        ('searchUnion', {'keyword': '测试'}),
        ('constructUnion', {'unionBuildingId': 1, 'constructType': 1, 'coinType': 1}),
        ('constructUnion', {'unionBuildingId': 3, 'constructType': 1, 'coinType': 1}),
        ('receiveUnionWage', {}),
        ('summonUnionMonster', {'monsterMetaId': 0, 'summonType': 0}),
        ('getUnionMonsterRank', {}),
        ('buyUnionProp', {'unionPropId': 1, 'unionPropType': 2}),
    ]:
        try:
            sub, r = c.rpc((method, params))
            rr = r.get(method, {})
            code = rr.get('retCode')
            if code == 200:
                keys = [k for k in rr.keys() if k not in ('method', 'retCode')]
                print('  OK   %-38s %s' % (method, ', '.join(keys[:5])))
            else:
                print('  !!   %-38s retCode=%s %s'
                      % (method, code, rr.get('extraMsg', '')[:50]))
                bad.append((method, code, rr.get('extraMsg', '')))
        except Exception as e:
            print('  EXC  %-38s %s' % (method, e))
            bad.append((method, 'exc', str(e)))

    print()
    print('=' * 74)
    print('结果: %d 个接口，异常/失败 %d 个' % (len(CALLS) + 16, len(bad)))
    for m, code, msg in bad:
        print('   - %-38s %s %s' % (m, code, msg[:60]))
    print('=' * 74)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
