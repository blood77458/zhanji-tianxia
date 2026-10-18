#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""活动还原可行性评估。

对 activity_panel 里的每个活动，判断：
  1. 客户端从哪读配置（本地 configs / 服务端 getMeta）
  2. 本地是否有对应数据表
  3. 服务端当前是否已下发真实数据
  4. 结论：能完整还原 / 能还原但缺数值 / 缺关键数据
"""
import io
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
APK = os.path.join(ROOT, 'work', 'apk_luasrc')
CONFIGS = os.path.join(APK, 'canon', 'configs')
sys.path.insert(0, os.path.join(ROOT, 'server'))

PANEL = None
for f in os.listdir(CONFIGS):
    if f.startswith('activity_panel.'):
        PANEL = open(os.path.join(CONFIGS, f), encoding='utf-8', errors='replace').read()
        break

ROWS = re.findall(r'\{panelName="([^"]+)",featureName="([^"]+)"([^}]*)\}', PANEL)
ACTIVITIES = []
for pn, fn, rest in ROWS:
    m = re.search(r'desc="([^"]*)"', rest)
    ACTIVITIES.append((pn, fn, m.group(1) if m else ''))

LOCAL = {}
for f in os.listdir(CONFIGS):
    if f.endswith('.lua'):
        LOCAL[f.split('.')[0]] = os.path.getsize(os.path.join(CONFIGS, f))

TEXT = {}
for r, _, fs in os.walk(APK):
    for f in fs:
        if f.endswith('.lua'):
            p = os.path.join(r, f)
            TEXT[os.path.relpath(p, APK)] = open(p, encoding='utf-8', errors='replace').read()

from meta_payload import get_meta_payload          # noqa: E402
META = get_meta_payload()

# 活动 → 可能用到的本地数据表（手工核对过的映射）
LOCAL_MAP = {
    'Activity_EatPeach': ['activity_panel'],
    'Activity_WorldBoss': ['world_boss_level', 'activity_panel'],
    'Activity_FountainWish': ['activity_fountainwish_gold', 'activity_fountainwish_fountainmax'],
    'Activity_mysterious': ['event_mysterious', 'activity_panel'],
    'Activity_mysteriousShop': ['activity_panel'],
    'Activity_CrossBoss': ['world_boss_level', 'activity_panel'],
    'Activity_CowStage': ['cow_stage'],
    'Activity_goldGod': [],
    'Activity_NewChargeReward': ['charge_money_reward'],
    'Activity_LimitReward': [],
    'Activity_GachaXiaoyu': ['gacha_card'],
    'Activity_GachaPoints': [],
    'Activity_Treasurebox': ['treasure_meta', 'treasure_strengthen'],
    'Activity_GemConsume': ['activity_gem_consume'],
    'Activity_BlowBalloon': [],
    'Activity_MerryChristmas': ['event_conversation_christmas'],
    'Activity_Question': ['activity_question_bank'],
    'Activity_InvitationCode': [],
    'Activity_Contend': ['activity_contend_fragment'],
}

# 服务端 getMeta 里对应的配置键
META_MAP = {
    'Activity_CowStage': 'activityCowStageConfig',
    'Activity_goldGod': 'activityGoldGodConfig',
    'Activity_Treasurebox': 'activityTreasureboxPointsConfig',
    'Activity_BlowBalloon': 'activityBalloonConfig',
    'Activity_MerryChristmas': 'activityEventChristmasConfig',
    'Activity_WorldBoss': 'activityWorldBossConfig',
    'Activity_CrossBoss': 'activityWorldBossConfig',
    'Activity_FountainWish': 'activityFountainWishConfig',
    'Activity_GemConsume': 'activityGemConsumeConfig',
    'Activity_LimitReward': 'activityLimitRewardConfig',
    'Activity_NewChargeReward': 'activityNewYearConfig',
    'Activity_GachaXiaoyu': 'activityGachaXiaoyuConfig',
    'Activity_GachaPoints': 'activityGachaPointsConfig',
    'Activity_Contend': 'activityContendConfig',
}


def meta_filled(key):
    if not key or key not in META:
        return None
    v = META[key]
    if not isinstance(v, dict):
        return False
    for v2 in v.values():
        if isinstance(v2, (list, dict)) and len(v2) > 0:
            return True
    return False


print('活动面板共 %d 项' % len(ACTIVITIES))
print()
print('%-30s %-8s %-26s %-9s %s' % ('活动', '中文', '本地数据表', '服务端配置', '结论'))
print('-' * 118)
stat = {'ok': 0, 'partial': 0, 'blank': 0}
for pn, fn, desc in ACTIVITIES:
    locals_ = [x for x in LOCAL_MAP.get(pn, []) if x in LOCAL]
    mk = META_MAP.get(pn)
    filled = meta_filled(mk)
    if locals_ and (filled is not False):
        verdict, k = '可完整还原', 'ok'
    elif locals_:
        verdict, k = '可还原+需自编数值', 'partial'
    elif filled is True:
        verdict, k = '服务端已有数据', 'ok'
    else:
        verdict, k = '缺关键配置', 'blank'
    stat[k] += 1
    print('%-30s %-8s %-26s %-9s %s' % (
        pn, desc[:6],
        ','.join(locals_)[:24] or '—',
        (mk or '—')[:8] + ('(有)' if filled else '(空)' if filled is False else ''),
        verdict))

print()
print('统计: 可完整还原 %d / 可还原但需自编数值 %d / 缺关键配置 %d'
      % (stat['ok'], stat['partial'], stat['blank']))
print()
print('本地 configs 里可用的活动相关数据表:')
for k in sorted(LOCAL):
    if any(x in k for x in ('activity', 'world_boss', 'multiplayer', 'sky_tower', 'babel',
                            'cow', 'red_bag', 'charge', 'consecutive', 'countdown', 'arena',
                            'union_', 'enchant', 'beast', 'atlas', 'cross_server', 'daily_shop',
                            'achievement', 'item_synthetize', 'equipment_number')):
        print('   %-42s %7d B' % (k, LOCAL[k]))
