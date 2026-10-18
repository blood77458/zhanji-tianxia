#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""自动判定每个活动能拿到哪些本地配置表。

做法：把本地 configs 里的**全局表名**全收集起来，然后扫每个活动相关的
lua 文件，看它引用了哪些本地表名 —— 引用了就说明这份数据客户端自带。
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

# 1) 本地配置表名
LOCAL = {}
for f in os.listdir(CONFIGS):
    if not f.endswith('.lua'):
        continue
    t = open(os.path.join(CONFIGS, f), encoding='utf-8', errors='replace').read()
    m = re.search(r'^\s*(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{', t, re.M)
    if m:
        LOCAL[m.group(1)] = (f.split('.')[0], len(t))

# 2) 活动面板
PANEL = None
for f in os.listdir(CONFIGS):
    if f.startswith('activity_panel.'):
        PANEL = open(os.path.join(CONFIGS, f), encoding='utf-8', errors='replace').read()
ROWS = re.findall(r'\{panelName="([^"]+)",featureName="([^"]+)"([^}]*)\}', PANEL)
ACTS = [(pn, fn, (re.search(r'desc="([^"]*)"', r) or [None, ''])[1]) for pn, fn, r in ROWS]

# 3) 所有 lua 文本
TEXT = {}
for r, _, fs in os.walk(APK):
    for f in fs:
        if f.endswith('.lua'):
            p = os.path.join(r, f)
            TEXT[os.path.relpath(p, APK)] = open(p, encoding='utf-8', errors='replace').read()

# 4) MetaManager 里本地表是怎么暴露的（MetaManager.xxx = 本地表）
MM = next((t for k, t in TEXT.items() if k.startswith('canon\\data\\MetaManager')
           or k.startswith('canon/data/MetaManager')), '')
LOCAL_ALIAS = set(re.findall(r'MetaManager\.([A-Za-z_][A-Za-z0-9_]*)\s*=', MM))
LOCAL_NAMES = set(LOCAL) | LOCAL_ALIAS

# 服务端 getMeta 的键
from meta_payload import get_meta_payload            # noqa: E402
META = get_meta_payload()
META_KEYS = set(META)


def act_files(panel_name, feature_name, desc):
    """找该活动对应的客户端文件。

    坑：panelName 和文件名经常对不上（Activity_goldGod -> Activity_WealthGodLayer），
    所以按 3 个线索找：panelName 字符串引用、featureName 引用、文件名字段。
    """
    out = set()
    key = panel_name.replace('Activity_', '')
    for rel, t in TEXT.items():
        base = os.path.basename(rel)
        if panel_name in t or panel_name in base:
            out.add(rel)
        elif feature_name and ('"%s"' % feature_name) in t:
            out.add(rel)
        elif key and len(key) > 4 and key.lower() in base.lower():
            out.add(rel)
    # 排除明显不相干的（活动面板本身、本地配置文件）
    return [r for r in out
            if 'canon\\configs\\' not in r and 'canon/configs/' not in r
            and 'activity_panel' not in os.path.basename(r)]


print('%-28s %-6s %s' % ('活动', '中文', '客户端引用的数据源（本地配置 / 服务端 getMeta）'))
print('-' * 116)
summary = {'local': 0, 'both': 0, 'meta': 0, 'none': 0}
detail = {}
for pn, fn, desc in ACTS:
    files = act_files(pn, fn, desc)
    local_hits, meta_hits = set(), set()
    for rel in files:
        t = TEXT[rel]
        for nm in LOCAL_NAMES:
            if re.search(r'\b' + re.escape(nm) + r'\b', t):
                local_hits.add(nm)
        for mk in META_KEYS:
            if re.search(r'\b' + re.escape(mk) + r'\b', t):
                meta_hits.add(mk)
    # 只保留活动相关的（过滤掉 card_meta 这种通用表）
    generic = {'card_meta', 'equip_meta', 'skill_meta', 'prop_meta', 'shop_meta',
               'card_level', 'equip_level', 'user_level', 'vip_setting', 'gacha_card',
               'battle_mission', 'treasure_meta', 'maintenance', 'system_help',
               'activity_panel', 'mission_remind', 'random_number', 'effect'}
    lh = sorted(x for x in local_hits if x not in generic)
    mh = sorted(meta_hits)
    if lh and mh:
        kind = 'both'
    elif lh:
        kind = 'local'
    elif mh:
        kind = 'meta'
    else:
        kind = 'none'
    summary[kind] += 1
    detail[pn] = (desc, lh, mh, files)
    print('%-28s %-6s %s' % (pn, desc[:5],
                             (('本地: ' + ','.join(lh)) if lh else '')
                             + (('  |  getMeta: ' + ','.join(mh)) if mh else '')))

print()
print('统计: 有本地数据 %d / 本地+getMeta %d / 只有 getMeta %d / 两个都没有 %d'
      % (summary['local'], summary['both'], summary['meta'], summary['none']))
print()
print('=== 两个数据源都没有的活动（这些才是真做不出来的）===')
for pn, (desc, lh, mh, files) in detail.items():
    if not lh and not mh:
        print('   %-28s %s   (文件: %s)' % (pn, desc, ', '.join(os.path.basename(f)[:28]
                                                          for f in files[:2]) or '未找到'))
