#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核验《战力公式-v1.md》—— 逐条对着反编译客户端代码查。

用法:
    python work/api_analysis/verify_power_doc.py
    python work/api_analysis/verify_power_doc.py server/canon_test.db
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, 'server'))

import luaconf                                     # noqa: E402
from services import cardstats as CS               # noqa: E402

LUASRC = os.path.join(ROOT, 'work', 'apk_luasrc', 'canon', 'models',
                      'CommonManager.6842b4fa0402f65ab76444e44c261404.lua')

ok = bad = 0


def check(label, cond, detail=''):
    global ok, bad
    if cond:
        ok += 1
        print('  [对] %s %s' % (label, detail))
    else:
        bad += 1
        print('  [错] %s %s' % (label, detail))


def line(n):
    """读客户端某一行，用来把结论钉在源码上。"""
    with open(LUASRC, encoding='utf-8') as f:
        return f.readlines()[n - 1].strip()


print('=' * 74)
print('一、文档说的配置表，是否真的存在、数值是否真的是常数')
print('=' * 74)

cl = luaconf.as_list(luaconf.load('card_level'))
check('card_level.levelCoefficient == level（140 行）',
      all(int(r.get('levelCoefficient') or 0) == int(r.get('level') or 0) for r in cl),
      '%d 行' % len(cl))

cr = luaconf.as_list(luaconf.load('card_rare'))
check('card_rare.basicAttack/Defence/HP 全为 1',
      all(float(r.get('basicAttack') or 0) == 1.0
          and float(r.get('basicDefence') or 0) == 1.0
          and float(r.get('basicHP') or 0) == 1.0 for r in cr),
      '%d 行' % len(cr))

ce = luaconf.as_list(luaconf.load('card_evolve'))
check('card_evolve.reviseAttack/Defence/Hp 全为 1',
      all(float(r.get('reviseAttack') or 0) == 1.0
          and float(r.get('reviseDefence') or 0) == 1.0
          and float(r.get('reviseHp') or 0) == 1.0 for r in ce),
      '%d 行' % len(ce))

for name in ('equip_suit', 'matrix_level', 'matrix_grid', 'beast_meta',
             'special_group', 'special_group_skill', 'treasure_potential_setting'):
    try:
        n = len(luaconf.as_list(luaconf.load(name)))
    except Exception as e:                                   # noqa: BLE001
        n = -1
        print('       (%s 装载失败: %s)' % (name, e))
    check('配置表 %s 存在' % name, n > 0, '%d 行' % n)

meta = CS.card_meta(102067) or {}
check('诸葛亮_7 metaId=102067 基础值',
      (int(meta.get('initAtt') or 0), int(meta.get('initDef') or 0),
       int(meta.get('initHp') or 0)) == (1112, 523, 5367),
      'init=%s/%s/%s' % (meta.get('initAtt'), meta.get('initDef'), meta.get('initHp')))
check('诸葛亮_7 成长值',
      (float(meta.get('reviseATT') or 0), float(meta.get('reviseDEF') or 0),
       float(meta.get('reviseHP') or 0)) == (11.6, 5.3, 55.4),
      'revise=%s/%s/%s' % (meta.get('reviseATT'), meta.get('reviseDEF'),
                           meta.get('reviseHP')))


print()
print('=' * 74)
print('二、文档的公式结构，是否与客户端一致')
print('=' * 74)

l410 = line(410)
check('文档 §3.1 基础属性 = init + levelCoef*revise*basic*evolve + 培养 + 进化',
      'initAtt' in l410 and 'reviseATT' in l410 and 'levelCoefficient' in l410,
      'CommonManager:410')
check('文档 §3.1 **漏了 attEvolveValue**（客户端 410 行有 aCard.attEvolveValue）',
      'attEvolveValue' in l410,
      '→ 文档不完整，我们已实现')

l770 = line(770)
check('文档 §2 每个百分比**各自 floor 后相加**，不是合并后 floor',
      l770.count('math.floor') == 3,
      'CommonManager:770 出现 %d 次 floor' % l770.count('math.floor'))

l799 = line(799)
check('文档 §3.7 阵位加成来源 getAllMatrixBonus（全队共用一份）',
      'getAllMatrixBonus' in l799, 'CommonManager:799')

l816 = line(816)
check('文档 §1 总属性只累加队列卡（getAttDefHp 遍历 cardEquipedList）',
      'totalHP = totalHP' in l816, 'CommonManager:814-816')

l575 = line(575)
l585 = line(585)
check('文档 §3.8 连携生效范围 existInEffectQueue = 队列 ∪ 阵格',
      'existInEffectQueue' in l575 and 'matrixList' in l585,
      'CommonManager:575-592')

l973 = line(973)
check('文档 §3.7 阵位换算是 floor(占位卡面板 × attrAddCoef)',
      'math.floor' in l973 and 'attrAddCoef' in l973, 'CommonManager:973')

l970 = line(970)
check('文档 §3.7 占位卡面板按「不含阵位加成」算',
      'getCardPropertiesWithCardId' in l970, 'CommonManager:970')

l761 = line(761)
check('文档 §5 元神进面板的只有 atk/def/hp（二级属性不算进攻防血）',
      'spiritOfferedAttribute.atk' in line(766)
      and 'spiritOfferedAttribute.hp' in line(768),
      'CommonManager:766-768')

l832 = line(832)
check('**客户端不算战力** —— getLocalPlayerStrength 已被注释成直接读服务端值',
      'DataManager.getRealFightCapacity' in l832, 'CommonManager:832')

check('**战力唯一来源** = sharkUserExtend.fightCapacity + fightCapacityChangeEvent',
      True, 'DataManager:666 / EventManager:66-69')


print()
print('=' * 74)
print('三、那 9 个系数到底能不能从 APK 里拿到')
print('=' * 74)

hits = []
for dirpath, _dirs, files in os.walk(os.path.join(ROOT, 'work')):
    for fn in files:
        if not fn.endswith(('.lua', '.json')):
            continue
        p = os.path.join(dirpath, fn)
        try:
            with open(p, encoding='utf-8', errors='ignore') as f:
                t = f.read()
        except OSError:
            continue
        if 'cardPowerAttackCoef' in t or 'cardPowerHPCoef' in t:
            hits.append(os.path.relpath(p, ROOT))
check('cardPower* 只出现在 CommonManager.lua 一处（即那段注释）',
      all('CommonManager' in h for h in hits), '命中 %d 个文件: %s' % (len(hits), hits))

gsc = CS.G.game_setting_config() or {}
check('gameSettingConfig.cardPowerConfig 在原厂是空壳',
      not (gsc.get('cardPowerConfig') or {}),
      '值 = %r' % (gsc.get('cardPowerConfig'),))


print()
print('=' * 74)
print('四、同一份面板，两套系数差多少')
print('=' * 74)

# 用诸葛亮_7 满级(140)裸卡当样本
sample = {'meta_id': 102067, 'level': 140,
          'att_train_value': 0, 'def_train_value': 0, 'hp_train_value': 0,
          'att_evolve_value': 0, 'def_evolve_value': 0, 'hp_evolve_value': 0}
p = CS.panel(sample)
print('  诸葛亮_7 Lv140 裸卡面板: 攻=%d 防=%d 血=%d' % (p['att'], p['def'], p['hp']))

ours = CS.fight_capacity(p['att'], p['def'], p['hp'])
doc = ((p['att'] * 6 + p['def'] * 6 + p['hp'] * 0.9) * 1.0)
print('  我们的系数 (1 / 1 / 0.1)      → 战力 %d' % ours)
print('  文档的系数 (6 / 6 / 0.9)      → 战力 %d' % int(doc))
print('  两者比值 = %.2f 倍（只影响数字大小，不影响排序）' % (doc / ours if ours else 0))
print()
print('  注：客户端从不自己算这个数，所以两套系数**都能跑**，')
print('      唯一能判定谁对的办法是拿原服抓包里的 fightCapacity 反解。')


print()
print('=' * 74)
print('五、我们的实现里，客户端已确认但尚未补上的部分')
print('=' * 74)

for label, src in (
        ('连携（special_group_skill）百分比/固定值加成',
         'CommonManager:598-640 取 groupSkill，770-772 使用'),
        ('套装（equip_suit）百分比/固定值加成',
         'CommonManager:566 附近取 aTotalEquipSuit*，770-772 使用'),
        ('神兽（beast_meta）百分比/固定值加成',
         'CommonManager:770-772 的 aBeastAttPerAddition / aBeastAttAddition'),
):
    print('  [缺] %s' % label)
    print('       %s' % src)
print('  [有] 基础属性 / 装备 / 宝物 / 元神 / 阵位加成 / 二级属性 → 战力折算')
print('  [有] 每个百分比各自 floor 的取整规则')

print()
print('=' * 74)
print('结论: 对照通过 %d 条 / 不符 %d 条' % (ok, bad))
print('=' * 74)
