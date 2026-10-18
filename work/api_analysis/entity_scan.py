#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""汇总所有接口的响应字段/请求参数，按「数据实体」聚合，用于表结构设计。"""
import json, os, io, sys, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
REC = json.load(open(os.path.join(HERE, 'records.json'), encoding='utf-8'))

mode = sys.argv[1] if len(sys.argv) > 1 else 'groups'

# 关注的数据域 -> 匹配的 method 关键字
GROUPS = {
    '账号/会话': r'login|account|server|socket|nickname|rename|ban|tutorial|addict|bind',
    '玩家/货币': r'^getHomeInfo|upgradeUser|getAccumulateGems|charge|recharge|vip|monthGem',
    '卡牌': r'card|Card|gacha|synthes|compose|split|evolve|train|pray|fragment|avatar|lock',
    '装备': r'equip|Equip',
    '道具/背包': r'prop|grid|bag|sellProps|useProp|buyGoods|shop|medal|seckill|exchange(Gift|Medal|Secret)|item',
    '元神': r'spirit|Spirit|subAttribute',
    '宝物': r'reasure',
    '关卡/战斗': r'mission|Mission|chapter|battle|elite|clear|route|wharf|trigger|event|destiny|contend|babel|skyTower|tower|cowStage',
    '邮件': r'mail|Mail|notice|Notice',
    '好友/社交': r'friend|Friend|invitation|Invitation|gift|Gift|praise|Praise|chat|Chat|bonus|Bonus|facebook|Facebook',
    '军团': r'union|Union',
    '竞技/PK': r'arena|Arena|pk|Pk|PK|match|Match',
    '活动': r'activity|Activity|Active|balloon|Balloon|dice|Dice|firework|Firework|question|Question|christmas|Christmas|newYear|NewYear|monday|Monday|fortune|Fortune|goldGod|GoldGod|levelRace|LevelRace|sworn|Sworn|festival|Festival|wish|Wish|peach|Peach',
    '任务/成就/奖励': r'task|Task|achieve|Achieve|signIn|SignIn|reward|Reward|countdown|Countdown|daily|Daily|week|Week|consume|Consume',
    '充值/订单': r'payment|Payment|order|Order|phoneCharge|PhoneCharge',
}


def fields_of(rs):
    resp = collections.Counter()
    pars = collections.Counter()
    for r in rs:
        for k, v in r['response_fields'].items():
            resp[k] += v
        for k in r['params']:
            if k not in ('*dynamic*', 'serverId'):
                pars[k] += 1
    return resp, pars


if mode == 'groups':
    for g, pat in GROUPS.items():
        rs = [r for r in REC if __import__('re').search(pat, r['method'])]
        resp, pars = fields_of(rs)
        print('=' * 90)
        print('## %s   (%d 个接口)' % (g, len(rs)))
        print('  响应字段(%d): %s' % (len(resp), ', '.join(k for k, _ in resp.most_common())))
        print('  请求参数(%d): %s' % (len(pars), ', '.join(k for k, _ in pars.most_common())))
elif mode == 'endpoint':
    for m in sys.argv[2:]:
        r = next((x for x in REC if x['method'] == m), None)
        if not r:
            print('!! %s' % m)
            continue
        print('== %-26s params=%s' % (m, sorted(k for k in r['params'] if k != '*dynamic*')))
        print('   resp=%s' % sorted(r['response_fields']))
elif mode == 'all':
    resp, pars = fields_of(REC)
    print('响应字段总数 %d' % len(resp))
    print(', '.join(k for k, _ in resp.most_common()))
    print()
    print('请求参数总数 %d' % len(pars))
    print(', '.join(k for k, _ in pars.most_common()))
