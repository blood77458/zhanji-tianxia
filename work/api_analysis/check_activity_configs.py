#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查 getMeta 里各活动配置到底是「有数据」还是「空壳」。"""
import io
import json
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server')))

from meta_payload import get_meta_payload          # noqa: E402

m = get_meta_payload()

CONFIG_KEYS = [k for k in m if k.startswith('activity') or k in (
    'exchangeDailyConfig', 'multiplicityRewardConfig', 'prayConfig', 'fbShareConfig',
    'activitySettingConfig', 'eventMysteriousConfig', 'countdownRewardConfig',
    'crossArenaRewardConfig', 'destinyBattleConfig', 'spiritConcentrateCostConfig',
    'enchantTotalConfig', 'cardPictureConfig', 'adPictureConfig', 'skyTowerSettingConfig',
    'spiritSettingConfig', 'paymentExchangeConfig', 'gameSettingConfig',
    'battleSettingConfig')]


def summarize(v):
    """返回 (元素个数, 是否有内容, 样例键)。"""
    if isinstance(v, dict):
        # 形如 {xxxConfig: {...}} 或 {xxxList: [...]}
        inner = None
        for k2, v2 in v.items():
            if isinstance(v2, (list, dict)) and len(v2) > 0:
                inner = (k2, v2)
                break
        if inner:
            return (len(inner[1]), True, '%s(%d)' % (inner[0], len(inner[1])))
        lists = [k2 for k2, v2 in v.items() if isinstance(v2, (list, dict))]
        return (len(v), False, ','.join(lists[:4]))
    return (0, False, type(v).__name__)


print('%-38s %-6s %-8s %s' % ('config key', 'items', '有内容', '子结构'))
print('-' * 90)
empty, filled = [], []
for k in CONFIG_KEYS:
    n, has, sub = summarize(m[k])
    (filled if has else empty).append(k)
    print('%-38s %-6d %-8s %s' % (k, n, 'YES' if has else 'no', sub))

print()
print('有真实内容的: %d 个 -> %s' % (len(filled), ', '.join(filled)))
print()
print('空壳的      : %d 个 -> %s' % (len(empty), ', '.join(empty)))
