#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""判断每个活动配置到底从哪来：客户端本地 configs/，还是服务端 getMeta。

对每个 game_meta 键，找 MetaManager 里怎么赋值、以及客户端有没有同名本地表。
"""
import io
import os
import re
import sys
import collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))
CONFIGS = os.path.join(D, 'canon', 'configs')

# MetaManager 里 game_meta 是从服务端来的；activity_* 等本地表是 require 出来的
TEXT = {}
for r, _, fs in os.walk(D):
    for f in fs:
        if f.endswith('.lua'):
            p = os.path.join(r, f)
            TEXT[os.path.relpath(p, D)] = open(p, encoding='utf-8', errors='replace').read()

LOCAL_TABLES = {}
for f in os.listdir(CONFIGS):
    if not f.endswith('.lua'):
        continue
    base = f.split('.')[0]
    t = open(os.path.join(CONFIGS, f), encoding='utf-8', errors='replace').read()
    # 表名 = 文件里的全局赋值，例如 activity_gold_god = { ... }
    m = re.search(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=', t, re.M)
    # 粗算条目数
    n = len(re.findall(r'\bid\s*=\s*\d+', t)) or len(re.findall(r'\[(\d+)\]\s*=\s*\{', t)) or t.count('=')
    LOCAL_TABLES[base] = (m.group(1) if m else base, n, len(t))

KEYS = ['activityGoldGodConfig', 'activityTreasureboxPointsConfig', 'activityDiceConfig',
        'activityFortuneNowConfig', 'activityBalloonConfig', 'activityWantedConfig',
        'activitySeckillConfig', 'activityNewYearConfig', 'activityWorldBossConfig',
        'activitySwornBrothersConfig', 'activityGemConsumeConfig', 'activityDayRewardConfig',
        'activityCardExchangeConfig', 'eventMysteriousConfig', 'skyTowerSettingConfig',
        'spiritSettingConfig', 'prayConfig', 'crossArenaRewardConfig',
        'destinyBattleConfig', 'activityFountainWishConfig', 'activityPraiseConfig',
        'activityMultiplayerBossConfig', 'activityEventChristmasConfig',
        'activityMysteriousExchangeConfig', 'exchangeDailyConfig',
        'multiplicityRewardConfig', 'countdownRewardConfig', 'enchantTotalConfig']

print('%-38s %-9s %s' % ('game_meta 键', '本地有?', '客户端读取方式 / 相关本地表'))
print('-' * 108)
for k in KEYS:
    # 1) 客户端哪里引用这个键
    refs = [rel for rel, t in TEXT.items() if k in t]
    # 2) 有没有同名的本地配置表
    short = re.sub(r'Config$', '', k).replace('activity', 'activity_').lower()
    cands = []
    for base, (tbl, n, sz) in LOCAL_TABLES.items():
        key_part = k.lower().replace('config', '')
        if re.sub(r'[^a-z]', '', base) and re.sub(r'[^a-z]', '', base) in re.sub(r'[^a-z]', '', k.lower()):
            cands.append('%s(%d项)' % (base, n))
    way = 'MetaManager.game_meta.%s' % k
    print('%-38s %-9s %s' % (k, 'YES' if cands else 'no',
                             (', '.join(cands[:3]) if cands else way)
                             + ('   [引用 %d 处]' % len(refs) if refs else '')))

print()
print('本地 configs 里所有 talk 表（前 40）:')
for base, (tbl, n, sz) in sorted(LOCAL_TABLES.items()):
    if any(x in base for x in ('activity', 'act', 'gold', 'dice', 'fortune', 'balloon',
                               'wanted', 'seckill', 'newyear', 'pray', 'sworn', 'consume',
                               'countdown', 'treasure', 'gem', 'question', 'fountain')):
        print('   %-46s 表名=%-34s %d B' % (base, tbl, sz))
