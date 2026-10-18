#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量展开若干根变量的字段路径，用于表结构设计。"""
import os, re, io, sys, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'apk_luasrc'))

ROOTS = ['sharkUser', 'sharkUserExtend', 'sharkUserExtendMore', 'sharkDailyData',
         'sharkActivity', 'sharkActivityExtend', 'sharkMatrices', 'sharkCrossPkUser',
         'sharkChristInfo', 'sharkDice', 'sharkSkyTower', 'sharkBeasts',
         'sharkMysteriousCoins', 'sharkShop', 'sharkDestinyInfo', 'sharkGachaInfo',
         'sharkElite', 'sharkGemCards', 'sharkDailyDataExtend', 'sharkUserSecretShop',
         'sharkSceneProcess', 'sharkMissionContext', 'sharkUserBattleArray',
         'sharkCardFragments', 'sharkEquipFragments', 'sharkMultiplayerBossInfo']

texts = []
for r, _, fs in os.walk(D):
    for f in fs:
        if f.endswith('.lua'):
            p = os.path.join(r, f)
            texts.append((os.path.relpath(p, D),
                          open(p, encoding='utf-8', errors='replace').read()))

for root in ROOTS:
    pat = re.compile(r'\b' + root + r'((?:\.[A-Za-z_][A-Za-z0-9_]*){1,2})')
    hits = collections.Counter()
    ev = {}
    for rel, t in texts:
        for m in pat.finditer(t):
            path = m.group(1)[1:]
            hits[path] += 1
            ev.setdefault(path, '%s:%d' % (rel, t[:m.start()].count('\n') + 1))
    print('## %s  (%d 个字段路径)' % (root, len(hits)))
    for k, v in hits.most_common(30):
        print('    %-52s %3d  %s' % (k, v, ev[k]))
    print()
