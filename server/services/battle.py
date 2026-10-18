"""副本战斗模拟。

分三层，来源严格区分：

1. **卡牌属性**（`services/cardstats.py`）
   公式逐字来自客户端 `CommonManager:getCardPropertiesWithSharkCard`，已验证。

2. **技能 = 属性增减状态**（本文件 `_skill_status_effects`）
   客户端 `skill_meta.statusIdList` → `skill_status[statusId]`，其中：
       prob        触发概率
       impactAttr  1=攻 2=防 3=血
       valueType   2=绝对值 1=百分比
       effectValue 增减量
   实测校验：技能 32000101 → 状态 630501 → effectValue=57，与真实抓包里
   `skillId=32000101, effectId=1, changedValue=57` 完全一致。
   → 事件流里的 `changedValue` 对技能事件来说是**属性增减**，不是伤害。

3. **伤害判定**（本文件 `_resolve_attack`）
   ⚠️ [自拟] 原版伤害在服务端算，客户端拿不到公式，抓包只有 2 个可用样本：
        att=366(309+57), def=0 → 359   (0.98×)
        att=266(209+57), def=0 → 282   (1.06×)
   即「伤害 ≈ 有效攻击 × 0.9~1.1 的随机」，def=0 时看不出防御怎么减伤。
   于是防御用递减式减伤（见 `_mitigation`），并把二级属性接进来：
       命中/闪避、暴击/韧性、招架、穿透 都按比例折算成概率或减伤。
   这些曲线是按常见卡牌游戏量级拟的，不保证与原版数值逐点一致，但量级、克制
   关系和事件类型（EVENTTYPE）都能对上客户端演出。
"""
import os
import random

import gamedata as G
import luaconf
from . import cardstats as CS

# 二级属性：元神/装备给的 crt(暴击) tou(韧性) hit(命中) eva(闪避) par(招架) prc(穿透)
SEC_KEYS = ('crt', 'tou', 'hit', 'eva', 'par', 'prc')

# [自拟] 伤害/判定曲线参数，集中放这里方便调
CURVE = {
    'damage_rand': (0.90, 1.10),   # 伤害浮动
    'crit_base': 0.05,             # 基础暴击率
    'crit_mul': 1.60,              # 暴击倍率
    'block_mul': 0.50,             # 招架后伤害倍率
    'counter_rate': 0.03,          # 反击概率
    'counter_mul': 0.30,           # 反击伤害占本次伤害比例
    'max_block': 0.15,
    'max_dodge': 0.25,
    'max_crit': 0.50,
    'max_mitigation': 0.70,
}

_skill_status = {}


def _debug_enemy_meta():
    """仅测试用：work/battle_debug_enemy.txt 写一个 card_meta id 就把敌方换成它。"""
    p = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__)))), 'work', 'battle_debug_enemy.txt')
    try:
        with open(p, 'r', encoding='utf-8') as f:
            return int(f.read().strip() or 0)
    except Exception:
        return 0


def _debug_enemy_x():
    """仅测试用：work/battle_debug_x.txt 写一个数，把敌方属性整体放大多少倍。"""
    p = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__)))), 'work', 'battle_debug_x.txt')
    try:
        with open(p, 'r', encoding='utf-8') as f:
            return float(f.read().strip() or 1.0)
    except Exception:
        return 1.0


def _statuses():
    if not _skill_status:
        tab = luaconf.load('skill_status') or {}
        for k, v in tab.items():
            if isinstance(v, dict):
                try:
                    _skill_status[int(v.get('statusId') or k)] = v
                except (TypeError, ValueError):
                    continue
    return _skill_status


def _skill_meta(skill_id):
    tab = luaconf.load('skill_meta') or {}
    if isinstance(tab, dict):
        return tab.get(int(skill_id)) or tab.get(str(skill_id)) or {}
    for row in tab:
        if isinstance(row, dict) and int(row.get('id') or 0) == int(skill_id):
            return row
    return {}


SKILL_TYPE_ACTIVE = (1, 2)     # 1=普通技 2=主技；3 是被动/连协，交给面板层


def _skill_status_effects(meta_id):
    """卡牌 → [(skillId, prob, impactAttr, valueType, effectValue)]"""
    out = []
    try:
        skills = G.build_card_skills(meta_id) or []
    except Exception:
        return out
    st_tab = _statuses()
    for sk in skills:
        if int(sk.get('skillType') or 0) not in SKILL_TYPE_ACTIVE:
            continue
        sm = _skill_meta(sk.get('skillId'))
        for sid in str(sm.get('statusIdList') or '').split('|'):
            try:
                sid = int(sid)
            except (TypeError, ValueError):
                continue
            st = st_tab.get(sid)
            if not st:
                continue
            out.append((int(sk.get('skillId') or 0),
                        float(st.get('prob') or 0),
                        int(st.get('impactAttr') or 0),
                        int(st.get('valueType') or 2),
                        float(st.get('effectValue') or 0)))
    return out


# ------------------------------------------------------------------ 伤害判定
def _mitigation(att, dfn):
    """[自拟] 递减式减伤：高防打低攻最多减 CURVE['max_mitigation']。"""
    if dfn <= 0:
        return 0.0
    rate = dfn / (dfn + att * 2.0 + 200.0)
    return min(CURVE['max_mitigation'], rate)


def _rate(value, scale):
    return value / (value + scale) if value > 0 else 0.0


def _clamp(v, lo, hi):
    return max(lo, min(hi, v))


def _resolve_attack(actor, target, eff_att, eff_def):
    """返回 (eventType, damage, counter_damage)。

    eventType 用客户端的 EVENTTYPE：
        0=普通 1=暴击 2=未命中 3=反击 4=格挡
    """
    rnd = random.random
    sec_a = actor.get('sec') or {}
    sec_t = target.get('sec') or {}

    # 命中判定：命中 - 闪避
    dodge = _rate(sec_t.get('eva', 0), 1500) - _rate(sec_a.get('hit', 0), 2000)
    if rnd() < _clamp(dodge, 0.0, CURVE['max_dodge']):
        return 2, 0, 0

    # 穿透削弱防御
    eff_def = eff_def * (1.0 - _clamp(_rate(sec_a.get('prc', 0), 2000), 0, 0.5))

    dmg = eff_att * random.uniform(*CURVE['damage_rand'])
    dmg *= (1.0 - _mitigation(eff_att, eff_def))

    # 暴击（韧性抵扣）
    crit = (CURVE['crit_base'] + _rate(sec_a.get('crt', 0), 2000)
            - _rate(sec_t.get('tou', 0), 3000))
    crit = _clamp(crit, 0.02, CURVE['max_crit'])
    if rnd() < crit:
        dmg *= CURVE['crit_mul']
        dmg = max(1.0, dmg)
        return 1, int(dmg), 0

    # 招架
    block = _clamp(_rate(sec_t.get('par', 0), 3000), 0.0, CURVE['max_block'])
    if rnd() < block:
        return 4, max(1, int(dmg * CURVE['block_mul'])), 0

    # 反击
    if rnd() < CURVE['counter_rate']:
        return 3, max(1, int(dmg)), max(1, int(dmg * CURVE['counter_mul']))

    return 0, max(1, int(dmg)), 0


# ------------------------------------------------------------------ 主流程
def chapter_battle(db, pid, mission_id, battle_type=1, event_override=None):
    G.init_battle_meta()
    source = G._cs
    ev = event_override or (source._BATTLE_EVENT.get((mission_id, battle_type))
                            or source._BATTLE_EVENT.get((mission_id, 1))
                            or source._BATTLE_EVENT.get(mission_id))
    if not ev:
        raise ValueError('unknown mission %s' % mission_id)

    slots = db.all('SELECT s.* FROM player_battle_slot s JOIN player_battle_array a '
                   'ON a.player_id=s.player_id AND a.array_id=s.array_id '
                   'WHERE s.player_id=? AND a.is_active=1 ORDER BY s.slot', (pid,))
    cards = []
    for slot in slots:
        card = db.one('SELECT * FROM player_card WHERE player_id=? AND card_id=?',
                      (pid, slot['card_id']))
        if card:
            cards.append(card)
    # 连协要按队伍国家分布判定，先算
    nums = CS.country_nums(cards)
    units = []
    for card in cards:
        equips = db.all('SELECT * FROM player_equip WHERE player_id=? AND card_id=?',
                        (pid, card['card_id']))
        treasure = db.one('SELECT * FROM player_treasure WHERE player_id=? AND card_id=?',
                          (pid, card['card_id']))
        spirits = db.all('SELECT * FROM player_spirit WHERE player_id=? AND card_id=?',
                         (pid, card['card_id']))
        # 面板口径与客户端卡片详情一致：基础+装备+宝物+元神+连协+套装+神兽
        stats = CS.panel(card, equips, treasure, spirits,
                         country_nums_map=nums)
        sec = {k: 0 for k in SEC_KEYS}
        for s in spirits:
            for k, v in (CS.spirit_attributes(s) or {}).items():
                if k in SEC_KEYS:
                    sec[k] += int(v or 0)
        units.append({'posId': len(units) + 1, 'cardId': int(card['card_id']),
                      'metaId': int(card['meta_id']), 'level': int(card['level']),
                      'exp': int(card['exp']), 'hp': max(1, int(stats['hp'])),
                      'att': max(1, int(stats['att'])), 'def': max(0, int(stats['def'])),
                      'sec': sec})
    if not units:
        raise ValueError('empty active formation')
    allies = list(units)

    group = source._BATTLE_MONSTER_GROUP.get(ev['monsterGroupId']) or []
    for i, mid in enumerate(group[:5]):
        mon = source._BATTLE_MONSTER.get(mid)
        if not mon:
            continue
        revise = float(ev.get('monsterRevise') or 1)
        try:
            revise *= _debug_enemy_x()
        except Exception:
            pass
        units.append({'posId': 10001 + i, 'cardId': 90000 + i,
                      'metaId': int(mon['cardId']),
                      'level': int(ev.get('monsterLevel') or 1), 'exp': 0,
                      'hp': max(1, int(mon['reviseHP'] * revise)),
                      'att': max(1, int(mon['reviseATT'] * revise)),
                      'def': max(0, int(mon['reviseDEF'] * revise)),
                      'sec': {k: 0 for k in SEC_KEYS}})
    if not allies:
        raise ValueError('empty configured monster group')
    enemies = [u for u in units if u['posId'] >= 10000]
    if not enemies:
        raise ValueError('empty configured monster group')

    dbg_meta = _debug_enemy_meta()
    if dbg_meta:
        for i, u in enumerate(enemies):
            u['metaId'] = dbg_meta
            u['cardId'] = 90000 + i

    health = {u['posId']: u['hp'] for u in units}
    # 技能叠加出来的属性增减：{posId: {'att': +x, 'def': -y, 'hp': +z}}
    bonus = {u['posId']: {'att': 0.0, 'def': 0.0, 'hp': 0.0} for u in units}
    events = []

    def eff(u):
        b = bonus[u['posId']]
        return (max(1.0, u['att'] + b['att']),
                max(0.0, u['def'] + b['def']))

    def living(team):
        return [u for u in team if health[u['posId']] > 0]

    # 技能表：只有我方有配置好的技能，敌方怪物没有 skill_meta 关联
    skills = {u['posId']: _skill_status_effects(u['metaId']) for u in allies}

    ATTR_TO_EFFECT = {1: 1, 2: 2, 3: 3}       # ATK/DEF/HP INC
    ATTR_NAME = {1: 'att', 2: 'def', 3: 'hp'}

    def fire_skills(round_no):
        """每回合按 prob 掷技能；命中就发 eventType=102 的属性增减事件。"""
        for u in living(allies):
            for skill_id, prob, attr, vtype, value in skills.get(u['posId'], []):
                if prob <= 0 or random.random() >= prob:
                    continue
                if attr not in ATTR_NAME:
                    continue
                base = {'att': u['att'], 'def': u['def'], 'hp': u['hp']}[ATTR_NAME[attr]]
                # valueType 2 = 绝对值，1 = 百分比（按基础值的百分比取整）
                delta = value if vtype == 2 else round(base * value / 100.0)
                if not delta:
                    continue
                bonus[u['posId']][ATTR_NAME[attr]] += delta
                eid = ATTR_TO_EFFECT[attr] if delta > 0 else ATTR_TO_EFFECT[attr] + 9
                events.append({'eventType': 102, 'round': round_no, 'actionType': 0,
                               'battleCardActs': [{'posId': u['posId'],
                                                  'skillId': skill_id,
                                                  'effectId': eid,
                                                  'changedValue': int(abs(delta))}]})

    # 回合模型与真实抓包一致：一回合内双方交替单人出手（E1, A1, E2, A2 …）
    max_rounds = 20          # 对齐客户端 BattleScene 的 totalRoundNum = 20
    round_no = 0
    while round_no < max_rounds:
        fire_skills(round_no)
        acted = False
        for turn in range(max(len(allies), len(enemies))):
            for action in (0, 1):
                actors = living(allies if action == 0 else enemies)
                targets = living(enemies if action == 0 else allies)
                if not actors or not targets:
                    continue
                actor = actors[turn % len(actors)]
                target = targets[turn % len(targets)]
                tpos = target['posId']
                att, dfn = eff(actor)
                _, tdfn = eff(target)
                etype, dmg, counter = _resolve_attack(actor, target, att, tdfn)
                if dmg > 0:
                    health[tpos] -= min(dmg, health[tpos])
                events.append({'eventType': etype, 'round': round_no,
                               'actionType': action,
                               'battleCardActs': [{'posId': tpos, 'skillId': 0,
                                                   'effectId': 6,
                                                   'changedValue': int(dmg)}]})
                # 反击：把伤害打回出手方
                if counter > 0 and health.get(actor['posId'], 0) > 0:
                    apos = actor['posId']
                    health[apos] -= min(counter, health[apos])
                    events.append({'eventType': 0, 'round': round_no,
                                   'actionType': 1 - action,
                                   'battleCardActs': [{'posId': apos, 'skillId': 0,
                                                       'effectId': 6,
                                                       'changedValue': int(counter)}]})
                acted = True
        if not living(allies) or not living(enemies):
            break
        if not acted:
            break
        round_no += 1

    win = bool(living(allies)) and not living(enemies)
    left = int(100 * sum(health[u['posId']] for u in allies)
               / max(1, sum(u['hp'] for u in allies)))
    # ⚠️ qte 必须为 True：BattleScene:1931 靠它加载 card/crush/<角色>_0.png
    return {'win': win, 'leftHpRate': left, 'qte': True, 'rewards': [],
            'cardInitDatas': units, 'eventFlow': events,
            'encounterMultiPlayerBoss': False}
