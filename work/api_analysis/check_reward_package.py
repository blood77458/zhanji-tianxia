#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""验证 reward_package 能否解析各活动配置引用的奖励 id。"""
import io
import os
import sys
import collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server')))
import luaconf                                       # noqa: E402

RP = luaconf.load('reward_package')
IDX = {}
for row in luaconf.as_list(RP):
    IDX[int(row['id'])] = row

nonempty = [r for r in luaconf.as_list(RP)
            if any(int(r.get('content%dType' % i) or 0) for i in range(1, 11))]
print('reward_package: 共 %d 条，非空 %d 条，id 范围 %d..%d'
      % (len(IDX), len(nonempty), min(IDX), max(IDX)))
print()

# 各活动配置引用的奖励字段
REFS = [
    ('sky_tower_reward', 'rewardId'),
    ('countdown_reward', 'rewardPackage'),
    ('consecutive_login_reward', 'rewardId'),
    ('consecutive_login_reward_new', 'rewardId'),
    ('activity_gem_consume', 'rewardPackageId'),
    ('arena_rank_reward', 'itemMetaId'),
    ('arena_score_exchange', 'itemMetaId'),
    ('atlas_Reward', None),
    ('achievement_task', None),
    ('cross_server_reward', None),
    ('charge_money_reward', None),
    ('union_shop_normal', None),
    ('union_shop_special', None),
    ('treasure_strengthen', None),
]

for name, field in REFS:
    v = luaconf.load(name)
    lst = luaconf.as_list(v)
    if not lst:
        print('%-32s (空)' % name)
        continue
    if not isinstance(lst[0], dict):
        print('%-32s %d 项，非表结构: %s' % (name, len(lst), lst[:6]))
        continue
    keys = sorted(lst[0].keys())
    # 找所有像 reward id 的字段
    cand = [k for k in keys if 'reward' in k.lower() or k.lower().endswith('id')]
    print('%-32s %3d 条  候选字段: %s' % (name, len(lst), ', '.join(cand)))
    for k in cand:
        ids = [int(r[k]) for r in lst if str(r.get(k, '')).lstrip('-').isdigit() and int(r[k]) > 0]
        if not ids:
            continue
        hit = sum(1 for i in ids if i in IDX)
        extra = ''
        if 'package' in k.lower() or 'rewardid' in k.lower() or k == 'rewardPackage':
            extra = '   <-- 应为 reward_package id，命中 %d/%d' % (hit, len(ids))
        print('     %-20s 样例 %s%s' % (k, ids[:6], extra))
    print()
