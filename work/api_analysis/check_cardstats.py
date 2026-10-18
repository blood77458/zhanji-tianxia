#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""验证卡牌成长曲线与战斗力：同一张卡在不同等级/进化阶段的属性与战力。"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'server')))
# cardstats 在 services 包里，用相对导入
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
from server.services import cardstats as CS          # noqa: E402

CARD = {'meta_id': 101011, 'level': 1, 'exp': 0,
        'att_train_value': 0, 'def_train_value': 0, 'hp_train_value': 0,
        'att_evolve_value': 0, 'def_evolve_value': 0, 'hp_evolve_value': 0}

meta = CS.card_meta(101011)
print('卡牌:', meta.get('readName'), ' rare=%s evolutionLevel=%s'
      % (meta.get('rare'), meta.get('evolutionLevel')))
print('等级上限:', CS.card_max_level(101011))
print()
print('%-6s %-8s %-8s %-8s %-10s %-10s' % ('等级', '攻击', '防御', '血量', '战力', '升级所需经验'))
print('-' * 64)
for lv in (1, 2, 5, 10, 20, 30, 40, 50, 60, 70):
    c = dict(CARD, level=lv)
    a = CS.card_attributes(c)
    lvcfg = CS.card_level_cfg(lv)
    print('%-6d %-8d %-8d %-8d %-10d %-10s'
          % (lv, a['att'], a['def'], a['hp'],
             CS.fight_capacity(a['att'], a['def'], a['hp']),
             lvcfg.get('exp')))

print()
print('--- 进化阶段（同等级 50，不同 evolutionLevel）---')
print('%-10s %-8s %-8s %-8s %-10s %-8s' % ('进化阶', '攻击', '防御', '血量', '战力', '等级上限'))
print('-' * 64)
for evo in (1, 2, 3, 4, 5, 6, 7):
    ev = CS.card_evolve_cfg(evo)
    m2 = dict(meta, evolutionLevel=evo)
    # 直接用该阶的修正系数算（模拟换 meta 后的效果）
    c = dict(CARD, level=min(50, int(ev.get('maxCardLevel') or 70)))
    lv = CS.card_level_cfg(c['level'])
    ra = CS.card_rare_cfg(meta.get('rare'))
    def n(v, d=0.0):
        try:
            return float(v)
        except (TypeError, ValueError):
            return d
    att = (n(m2.get('initAtt')) + n(lv.get('levelCoefficient')) * n(m2.get('reviseATT'))
           * n(ra.get('basicAttack'), 1) * n(ev.get('reviseAttack'), 1))
    df = (n(m2.get('initDef')) + n(lv.get('levelCoefficient')) * n(m2.get('reviseDEF'))
          * n(ra.get('basicDefence'), 1) * n(ev.get('reviseDefence'), 1))
    hp = (n(m2.get('initHp')) + n(lv.get('levelCoefficient')) * n(m2.get('reviseHP'))
          * n(ra.get('basicHP'), 1) * n(ev.get('reviseHp'), 1))
    print('%-10d %-8d %-8d %-8d %-10d %-8s'
          % (evo, att, df, hp, CS.fight_capacity(att, df, hp), ev.get('maxCardLevel')))

print()
print('--- 升一级要吃多少经验 / 花多少金币（用 3 张 103001 当材料）---')
mat = [{'card_id': 9001, 'meta_id': 103001, 'level': 1, 'exp': 0},
       {'card_id': 9002, 'meta_id': 103001, 'level': 1, 'exp': 0},
       {'card_id': 9003, 'meta_id': 103001, 'level': 1, 'exp': 0}]
for base_lv in (1, 10, 30, 50):
    c = dict(CARD, level=base_lv)
    nl, coin, res, ovf = CS.compose_exp(c, mat)
    print('  L%-3d + 3材料 -> L%-3d   金币 %-8d  累计经验 %-8d  %s'
          % (base_lv, nl, coin, res, '（超上限截断）' if ovf else ''))

print()
print('--- 战斗力系数（[自编]，原厂 cardPowerConfig 是空壳）---')
for k, v in sorted(CS.power_config().items()):
    print('  %-26s %s' % (k, v))
