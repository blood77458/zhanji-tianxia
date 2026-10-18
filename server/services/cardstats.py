#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""卡牌属性 / 成长曲线 / 战斗力。

**公式全部来自客户端，不是自创的**：

属性（`CommonManager:getCardPropertiesWithSharkCard` 第 410-412 行逐字对应）
--------------------------------------------------------------------------
    att = initAtt + levelCoefficient * reviseATT * card_rare.basicAttack * card_evolve.reviseAttack
          + attTrainValue + attEvolveValue
    def = initDef + levelCoefficient * reviseDEF * card_rare.basicDefence * card_evolve.reviseDefence
          + defTrainValue + defEvolveValue
    hp  = initHp  + levelCoefficient * reviseHP  * card_rare.basicHP    * card_evolve.reviseHp
          + hpTrainValue + hpEvolveValue

    其中 levelCoefficient 取 `card_level[card.level]`，
    card_rare / card_evolve 按 `card_meta.evolutionLevel` / `.rare` 查表。

成长曲线（`CardComposeScene:getComposeExp` 第 71-113 行）
--------------------------------------------------------
    mainExp       = card_level[main.level].totalExp + main.exp
    getTotalExp   = card_meta[matter.metaId].basicExp
                    + (card_level[matter.level].totalExp + matter.exp)
                      * card_level[matter.level].expConvertCoefficient
    resultExp     = mainExp + Σ getTotalExp
    upgradeCoin   = floor(Σ getTotalExp * gameSettingConfig.cardUpgradeCoinRevise)
    newLevel      = max{ L : card_level[L].totalExp <= resultExp }，上限
                    card_evolve[card_meta.evolutionLevel].maxCardLevel

战斗力（客户端注释里保留的原公式，`CommonManager:getLocalPlayerStrength` 第 850-864 行）
--------------------------------------------------------------------------------------
    result = (totalAttack * cardPowerAttackCoef
            + totalDefence * cardPowerDefenseCoef
            + totalHP     * cardPowerHPCoef) * cardPowerTotalCoef
           + (crt*criticalCoef + eva*evadeCoef + par*parryCoef
              + tou*toughnessCoef + hit*hitCoef + prc*pierceCoef) * cardPowerTotalCoef
    上限 cardPowerMax

    ⚠️ `gameSettingConfig.cardPowerConfig` 在原厂就是**空壳**，本地 configs 里
       也没有对应表 → 那 9 个系数是 [自编] 的。公式结构是真的，数值可以调。
"""
import gamedata as G
import luaconf

# ---------------------------------------------------------------- 配置装载
_cache = {}


def _tbl(name):
    if name not in _cache:
        _cache[name] = luaconf.load(name)
    return _cache[name]


def _by_key(name, key='id'):
    """把配置表索引成 {key: row}。"""
    idx_name = '__idx_%s_%s' % (name, key)
    if idx_name in _cache:
        return _cache[idx_name]
    idx = {}
    for row in luaconf.as_list(_tbl(name)):
        if not isinstance(row, dict):
            continue
        try:
            idx[int(row[key])] = row
        except (KeyError, TypeError, ValueError):
            continue
    _cache[idx_name] = idx
    return idx


def card_meta(meta_id):
    return _by_key('card_meta').get(int(meta_id))


def card_level_cfg(level):
    """card_level 是 1-based 数组，[level] = 该等级配置。"""
    lst = luaconf.as_list(_tbl('card_level'))
    level = int(level or 1)
    if level < 1:
        level = 1
    if level > len(lst):
        level = len(lst)
    return lst[level - 1] if lst else {}


def card_evolve_cfg(evolution_level):
    return _by_key('card_evolve', 'evolutionLevel').get(int(evolution_level or 1)) or {}


def card_rare_cfg(rare):
    return _by_key('card_rare', 'rare').get(int(rare or 1)) or {}


def card_max_level(meta_id):
    """卡牌等级上限 = card_evolve[meta.evolutionLevel].maxCardLevel。"""
    meta = card_meta(meta_id) or {}
    ev = card_evolve_cfg(meta.get('evolutionLevel') or 1)
    return int(ev.get('maxCardLevel') or len(luaconf.as_list(_tbl('card_level'))) or 140)


def _num(v, default=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _g(row, key, default=None):
    """兼容 dict 与 sqlite3.Row 的取值。

    这个模块既被 assembler（拿到的是 Row）调用，也被测试（dict）调用，
    所以不能直接用 `.get()` —— sqlite3.Row 没有这个方法。
    """
    if row is None:
        return default
    if isinstance(row, dict):
        return row.get(key, default)
    try:
        v = row[key]
    except (KeyError, IndexError, TypeError):
        return default
    return default if v is None else v


# ---------------------------------------------------------------- 属性
def card_attributes(card, meta=None):
    """按客户端公式算一张卡的 att/def/hp（**不含**装备/宝物/阵法/元神加成）。"""
    meta = meta if meta is not None else (card_meta(card['meta_id']) or {})
    if not meta:
        return {'att': 0, 'def': 0, 'hp': 0}
    lv = card_level_cfg(card['level'])
    ev = card_evolve_cfg(meta.get('evolutionLevel') or 1)
    ra = card_rare_cfg(meta.get('rare') or 1)
    coeff = _num(lv.get('levelCoefficient'), 0)
    att = (_num(meta.get('initAtt')) + coeff * _num(meta.get('reviseATT'))
           * _num(ra.get('basicAttack'), 1) * _num(ev.get('reviseAttack'), 1)
           + _num(_g(card, 'att_train_value')) + _num(_g(card, 'att_evolve_value')))
    deff = (_num(meta.get('initDef')) + coeff * _num(meta.get('reviseDEF'))
            * _num(ra.get('basicDefence'), 1) * _num(ev.get('reviseDefence'), 1)
            + _num(_g(card, 'def_train_value')) + _num(_g(card, 'def_evolve_value')))
    hp = (_num(meta.get('initHp')) + coeff * _num(meta.get('reviseHP'))
          * _num(ra.get('basicHP'), 1) * _num(ev.get('reviseHp'), 1)
          + _num(_g(card, 'hp_train_value')) + _num(_g(card, 'hp_evolve_value')))
    return {'att': int(att), 'def': int(deff), 'hp': int(hp)}


def total_potential(card, meta=None):
    """客户端 CommonManager 第 823 行：card_rare[rare].addPotential * level。"""
    meta = meta if meta is not None else (card_meta(card['meta_id']) or {})
    ra = card_rare_cfg(meta.get('rare') or 1)
    return int(_num(ra.get('addPotential')) * int(_g(card, 'level') or 1))


def result_exp(card):
    """客户端结果经验（CardInfoNewPanel 的 resultExp 字段）。"""
    meta = card_meta(card['meta_id']) or {}
    lv = card_level_cfg(card['level'])
    return int(_num(meta.get('basicExp'))
               + (_num(lv.get('totalExp')) + _num(_g(card, 'exp')))
               * _num(lv.get('expConvertCoefficient'), 1))


# ---------------------------------------------------------------- 成长曲线
def compose_exp(main_card, matter_cards, meta_of=None):
    """吃材料卡升级。返回 (new_level, gold_cost, result_exp, overflow)。

    逐字对应 CardComposeScene:getComposeExp。
    """
    meta_of = meta_of or (lambda cid, mid: card_meta(mid))
    lv_cfg = card_level_cfg(main_card['level'])
    result = _num(lv_cfg.get('totalExp')) + _num(main_card.get('exp'))
    coin = 0.0
    for m in matter_cards:
        mlv = card_level_cfg(m['level'])
        meta = meta_of(m.get('card_id'), m.get('meta_id')) or {}
        matter_exp = _num(mlv.get('totalExp')) + _num(m.get('exp'))
        get_total = _num(meta.get('basicExp')) + matter_exp * _num(
            mlv.get('expConvertCoefficient'), 1)
        result += get_total
        coin += get_total * _num(G.game_setting_config().get('cardUpgradeCoinRevise'), 1)

    levels = luaconf.as_list(_tbl('card_level'))
    new_level = 1
    for row in levels:
        if result >= _num(row.get('totalExp')):
            new_level = int(row.get('level') or 1)
        else:
            break
    cap = card_max_level(main_card['meta_id'])
    overflow = new_level > cap
    if overflow:
        new_level = cap
    return new_level, int(coin), int(result), overflow


def add_exp(main_card, gain_exp):
    """纯加经验（没有材料卡时用，例如通用经验）。返回 (new_level, 溢出经验)。"""
    lv_cfg = card_level_cfg(main_card['level'])
    result = _num(lv_cfg.get('totalExp')) + _num(main_card.get('exp')) + _num(gain_exp)
    levels = luaconf.as_list(_tbl('card_level'))
    new_level, base = 1, 0.0
    for row in levels:
        if result >= _num(row.get('totalExp')):
            new_level = int(row.get('level') or 1)
            base = _num(row.get('totalExp'))
        else:
            break
    cap = card_max_level(main_card['meta_id'])
    overflow = new_level > cap
    if overflow:
        new_level = cap
        base = _num(card_level_cfg(cap).get('totalExp'))
    return new_level, int(result - base), overflow


def general_exp_needed(card, target_level):
    """从当前等级升到 target_level 需要的总经验（用于 upgradeCardByGeneralExp）。"""
    levels = luaconf.as_list(_tbl('card_level'))
    target_level = max(1, min(int(target_level or 1), card_max_level(card['meta_id'])))
    cur_total = _num(card_level_cfg(card['level']).get('totalExp')) + _num(_g(card, 'exp'))
    tgt_total = _num(card_level_cfg(target_level).get('totalExp'))
    return max(0, int(tgt_total - cur_total)), target_level


# ---------------------------------------------------------------- 战斗力
# ⚠️ 原厂 `cardPowerConfig` 是空壳，客户端那段公式被整段注释掉，
#    `CommonManager:getLocalPlayerStrength` 直接 `return DataManager.getRealFightCapacity()`，
#    而那个值只由服务端下发 —— 也就是说**原版系数拿不到，抓包账号战力还是 0**。
#    所以这一组系数是 [自拟] 的，用的是「量级校准」而不是拟合：
#
#      一张满级（Lv70）五星卡：攻≈1100 防≈500 血≈5200
#        → 1100*1 + 500*1 + 5200*0.1 = 2120/张
#      五张满级 ≈ 1.06 万；新手期（本存档 4 张 1~43 级）≈ 2800
#      和界面上显示的 2809 同量级，成长曲线单调、不跳变。
#
#    二级属性（暴击/闪避/招架/韧性/命中/穿透）在元神里通常只有几十点，
#    权重给 5 才有一点点存在感；给 2 基本等于没有。
#    以后若拿到真实战力数据，只需要改这张表，公式不用动。
CARD_POWER = {
    'cardPowerAttackCoef': 1.0,
    'cardPowerDefenseCoef': 1.0,
    'cardPowerHPCoef': 0.1,
    'cardPowerCriticalCoef': 5.0,
    'cardPowerEvadeCoef': 5.0,
    'cardPowerParryCoef': 5.0,
    'cardPowerToughnessCoef': 4.0,
    'cardPowerHitCoef': 4.0,
    'cardPowerPierceCoef': 4.0,
    'cardPowerTotalCoef': 1.0,
    'cardPowerMax': 999999999,
}


def power_config():
    """优先用服务端下发的 cardPowerConfig；为空就用自编默认值。"""
    cfg = (G.game_setting_config() or {}).get('cardPowerConfig') or {}
    merged = dict(CARD_POWER)
    for k, v in cfg.items():
        try:
            merged[k] = float(v)
        except (TypeError, ValueError):
            pass
    return merged


def fight_capacity(att, deff, hp, extra=None):
    """按客户端原公式算战斗力。

    extra 可带 crt/eva/par/tou/hit/prc（暴击/闪避/招架/韧性/命中/穿透），
    这些来自元神等附加属性；没有就按 0 算。
    """
    c = power_config()
    total = (att * c['cardPowerAttackCoef']
             + deff * c['cardPowerDefenseCoef']
             + hp * c['cardPowerHPCoef']) * c['cardPowerTotalCoef']
    e = extra or {}
    spirit = (e.get('crt', 0) * c['cardPowerCriticalCoef']
              + e.get('eva', 0) * c['cardPowerEvadeCoef']
              + e.get('par', 0) * c['cardPowerParryCoef']
              + e.get('tou', 0) * c['cardPowerToughnessCoef']
              + e.get('hit', 0) * c['cardPowerHitCoef']
              + e.get('prc', 0) * c['cardPowerPierceCoef']) * c['cardPowerTotalCoef']
    return int(min(total + spirit, c['cardPowerMax']))


# ---------------------------------------------------------------- 装备
def equip_level_cfg(level):
    lst = luaconf.as_list(_tbl('equip_level'))
    level = max(1, int(level or 1))
    if level > len(lst):
        level = len(lst)
    return lst[level - 1] if lst else {}


def equip_attributes(equip):
    """`EquipUtils` 第 19 行：value = basicXxx + xxxSCoe * equip_level[level].xxx"""
    meta = _by_key('equip_meta').get(int(_g(equip, 'meta_id') or 0))
    if not meta:
        return {'att': 0, 'def': 0, 'hp': 0}
    lv = equip_level_cfg(_g(equip, 'level'))
    return {
        'att': int(_num(meta.get('basicAtk')) + _num(meta.get('atkSCoe')) * _num(lv.get('atk'))),
        'def': int(_num(meta.get('basicDefence'))
                   + _num(meta.get('defSCoe')) * _num(lv.get('def'))),
        'hp': int(_num(meta.get('basicHp')) + _num(meta.get('hpSCoe')) * _num(lv.get('hp'))),
    }


# ---------------------------------------------------------------- 宝物
def treasure_attributes(treasure):
    """逐字对应 `TreasureSystemUtils.CountAttandDefandHp`（第 10-30 行）。

    注意 hp 那一行原厂写的是 `treasureMate.initDEF * treasurePotentialMate.reviseHP`
    —— DEF 而不是 HP。这里**照抄原样**，否则数值与客户端显示对不上。
    """
    meta = _by_key('treasure_meta', 'treasureID').get(int(_g(treasure, 'meta_id') or 0))
    if not meta:
        return {'att': 0, 'def': 0, 'hp': 0}
    rare = int(meta.get('rare') or 1)
    pot = _by_key('treasure_potential_setting', 'rare').get(rare) or {}
    star = _by_key('treasure_star', 'rare').get(rare) or {}
    setting = luaconf.as_list(_tbl('treasure_potential_setting'))
    # TreasureSystemConfig.getTreasureSettingConfig() —— 没有独立配置文件时按 1 处理
    up = 1.0
    lv = _num(_g(treasure, 'level'), 1)
    star_lv = _num(star.get('starUpLevel'))
    add_pot = _num(_g(treasure, 'add_potential'))
    add_gem = _num(_g(treasure, 'add_gem_potential'))
    i_att = _num(pot.get('reviseATT'), 1) * _num(meta.get('initATT'))
    i_def = _num(pot.get('reviseDEF'), 1) * _num(meta.get('initDEF'))
    i_hp = _num(pot.get('reviseHP'), 1) * _num(meta.get('initHP'))
    att = (_num(meta.get('reviseATT')) * (lv + star_lv) + _num(meta.get('initATT'))
           + (_num(meta.get('initATT')) * _num(pot.get('reviseATT'), 1) * add_pot)
           + (i_att * (up * 0.01) * add_gem))
    deff = (_num(meta.get('reviseDEF')) * (lv + star_lv) + _num(meta.get('initDEF'))
            + (_num(meta.get('initDEF')) * _num(pot.get('reviseDEF'), 1) * add_pot)
            + (i_def * (up * 0.01) * add_gem))
    hp = (_num(meta.get('reviseHP')) * (lv + star_lv) + _num(meta.get('initHP'))
          + (_num(meta.get('initDEF')) * _num(pot.get('reviseHP'), 1) * add_pot)
          + (i_hp * (up * 0.01) * add_gem))
    return {'att': int(att), 'def': int(deff), 'hp': int(hp)}


# ---------------------------------------------------------------- 元神
# `SpiritManager` 第 338-348 行 / 第 445-455 行的属性类型表。
# 100 = 经验型（主属性出现时表示"不提供战斗属性"），要跳过。
SPIRIT_ATTR_TYPE = {
    1: 'att', 2: 'def', 3: 'hp',
    6: 'crt', 7: 'tou', 8: 'hit', 9: 'eva', 10: 'par', 11: 'prc',
}


def spirit_attributes(spirit):
    """元神属性，**9 维全给**：主属性 = mainAttributeGrowth * level，副属性逐条累加。

    对应 `SpiritManager.getPlayerAllSpiritOfferedAttribute`（第 326-390 行）。

    注意：攻防血那三维会被 `getCardSpiritOfferedCardStrength` 计入卡牌面板，
    二级属性（crt/tou/hit/eva/par/prc）**不进面板**，只在算战斗力时用
    —— 所以这里一次性给全，由调用方各取所需。

    主属性类型 100 是经验型，跳过。
    """
    meta = _by_key('spirit_meta').get(int(_g(spirit, 'meta_id') or 0))
    if not meta:
        return {}
    lv = _num(_g(spirit, 'level'), 1)
    out = dict.fromkeys(SPIRIT_ATTR_TYPE.values(), 0.0)
    mtype = int(meta.get('mainAttributeType') or 0)
    if mtype != 100:
        k = SPIRIT_ATTR_TYPE.get(mtype)
        if k:
            out[k] += _num(meta.get('mainAttributeGrowth')) * lv
    for a in (_g(spirit, 'attributes') or []):
        t = int(_g(a, 'attributeType') or 0)
        if t == 100:
            continue
        k = SPIRIT_ATTR_TYPE.get(t)
        if k:
            out[k] += _num(_g(a, 'attributeGrowing')) * lv
    return {k: int(v) for k, v in out.items() if v}


def spirit_slots_for(card, meta=None):
    """一张卡能带几个元神 = card_rare[rare].spiritNum + card_level[level].spiritNum。

    `SpiritManager` 第 362、369 行：只有 `index <= cardSpiritNum` 的元神才生效，
    多出来的（换将后残留）不参与任何计算。
    """
    meta = meta if meta is not None else (card_meta(_g(card, 'meta_id')) or {})
    ra = card_rare_cfg(meta.get('rare') or 1)
    lv = card_level_cfg(_g(card, 'level'))
    return int(_num(ra.get('spiritNum')) + _num(lv.get('spiritNum')))


# ---------------------------------------------------------------- 总战力
def sum_attributes(*groups):
    """按 key 求和。key 不限于攻防血 —— 元神会带出 6 个二级属性。"""
    out = {'att': 0, 'def': 0, 'hp': 0}
    for g in groups:
        if not g:
            continue
        for k, v in g.items():
            out[k] = out.get(k, 0) + int(v or 0)
    return out


# ---------------------------------------------------------------- 阵位（阵法）
def matrix_level_cfg(matrix_id, mlevel):
    """按 (matrixObtain=阵法id, matrixLevel=等级) 找 matrix_level 行。

    客户端 `CommonManager:getMatrixBonus` 第 937-944 行就是这么查的
    —— 不是按行下标查。
    """
    for row in luaconf.as_list(_tbl('matrix_level')):
        if not isinstance(row, dict):
            continue
        if (int(row.get('matrixObtain') or 0) == int(matrix_id)
                and int(row.get('matrixLevel') or 0) == int(mlevel)):
            return row
    return None


def matrix_grid_type(grid_id):
    """阵格维度：1=攻 2=防 3=血（`matrix_grid[gridId].type`）。"""
    row = _by_key('matrix_grid').get(int(grid_id or 0)) or {}
    return int(row.get('type') or 3)


def matrix_bonus(grids, panel_of):
    """阵位加成：**全队共用一份**，算完加到队列里每一张卡上。

    逐字对应客户端 `getMatrixGridBonus`（第 965-980 行）：

        bonus[维度] += floor(占位卡面板[维度] * matrix_level.attrAddCoef)
        维度由 matrix_grid[gridId].type 决定（1攻 2防 3血）

    两条容易踩的坑：
      1. 占位卡的面板要按「**不含阵位加成、不含连携**」算，
         否则会自己套自己 —— 客户端传的是 `getCardPropertiesWithCardId(cardId, {}, ...)`，
         空列表就等价于「不在队列里」，连携和阵位都被跳过。
      2. 阵格里的卡**不单独计入战力**，它只通过这份加成影响全队。
         客户端 `getAttDefHp` 只遍历 `getQueueData()`，不碰阵格。

    grids:    [(matrix_id, matrix_level, grid_id, card_id), ...]
    panel_of: callable(card_id) -> {'att','def','hp'}
    """
    total = {'att': 0, 'def': 0, 'hp': 0}
    for matrix_id, mlevel, grid_id, card_id in grids:
        card_id = int(card_id or 0)
        if card_id <= 0:
            continue
        lv = matrix_level_cfg(matrix_id, mlevel)
        coef = _num((lv or {}).get('attrAddCoef'))
        if not coef:
            continue
        p = panel_of(card_id) or {}
        key = {1: 'att', 2: 'def', 3: 'hp'}.get(matrix_grid_type(grid_id), 'hp')
        total[key] += int(_num(p.get(key)) * coef)
    return total


# ---------------------------------------------------------------- 连协 / 套装 / 神兽
# 三者最终都汇成「百分比 + 绝对值」两组数，客户端 `getCardPropertiesWithSharkCard`
# 第 766-772 行统一这样用：
#     temp = floor(基础) + 装备 + 元神 + 宝物
#     面板 = temp + floor(temp*连协%) + floor(temp*套装%) + floor(temp*神兽%)
#            + 连协绝对值 + 套装绝对值 + 神兽绝对值 + 阵位加成
# 注意是**每一项各自 floor 再相加**，不是合并百分比后取整。

def _acc(pct, flat, attr, vtype, value):
    key = {1: 'att', 2: 'def', 3: 'hp'}.get(int(attr or 0))
    if not key:
        return
    if int(vtype or 2) == 1:          # 1 = 百分比（配置里是 0.24 这种小数）
        pct[key] += float(value or 0)
    else:                             # 2 = 绝对值
        flat[key] += int(float(value or 0))


def _new_bonus():
    return ({'att': 0.0, 'def': 0.0, 'hp': 0.0}, {'att': 0, 'def': 0, 'hp': 0})


def skill_status_rows(skill_id, only_feedback=None):
    """技能 → 它挂的状态行（skill_meta.statusIdList → skill_status）。"""
    if not skill_id:
        return []
    sm = (_tbl('skill_meta') or {}).get(int(skill_id)) or {}
    st = _tbl('skill_status') or {}
    out = []
    for sid in str(sm.get('statusIdList') or '').split('|'):
        try:
            sid = int(sid)
        except (TypeError, ValueError):
            continue
        row = st.get(sid)
        if not row:
            continue
        if only_feedback is not None:
            try:
                if int(row.get('feedback') or 0) != int(only_feedback):
                    continue
            except (TypeError, ValueError):
                continue
        out.append(row)
    return out


def country_nums(cards):
    """队伍里每个国家的卡数（连协激活条件要用）。"""
    out = {}
    for c in cards or []:
        meta = card_meta(_g(c, 'meta_id') or _g(c, 'metaId')) or {}
        cid = int(meta.get('country') or 0)
        if cid:
            out[cid] = out.get(cid, 0) + 1
    return out


def group_skill_bonus(meta, nums):
    """连协（special_group_skill）。

    逐字对应 `CommonManager:checkSpecialGroupIsActive`（第 1337 行）：
        本国卡：该国卡数 >= groupNum + 1
        他国卡：该国卡数 >= groupNum
    """
    pct, flat = _new_bonus()
    if not meta:
        return pct, flat
    gid = int(_num(_g(meta, 'cardGroupId')))
    gs = (_tbl('special_group_skill') or {}).get(gid)
    if not gs:
        return pct, flat
    country = int(_num(_g(meta, 'country')))
    for i in (1, 2, 3, 4):
        sid = int(_num(_g(gs, 'groupSkill%d' % i)))
        if sid <= 0:
            break
        grp = int(_num(_g(gs, 'group%d' % i)))
        need = int(_num(_g(gs, 'groupNum%d' % i)))
        have = int((nums or {}).get(grp, 0))
        active = have >= need + (1 if country == grp else 0)
        if not active:
            continue
        for row in skill_status_rows(sid, only_feedback=1):
            _acc(pct, flat, row.get('impactAttr'), row.get('valueType'),
                 row.get('effectValue'))
    return pct, flat


def equip_suit_bonus(meta, equips):
    """套装：装备的 `equip_meta.prefixId` 命中 equip_suit.equipId，
    且该套装的 cardGroupId 与本卡一致（第 521-548 行）。"""
    pct, flat = _new_bonus()
    if not meta or not equips:
        return pct, flat
    gid = int(_num(_g(meta, 'cardGroupId')))
    suits = _tbl('equip_suit') or {}
    rows = list(suits.values()) if isinstance(suits, dict) else list(suits)
    for e in equips:
        if e is None:
            continue
        em = (_tbl('equip_meta') or {}).get(int(_num(_g(e, 'meta_id')))) or {}
        if isinstance(em, dict) and not _g(em, 'prefixId'):
            em = _by_key('equip_meta').get(int(_num(_g(e, 'meta_id')))) or em
        prefix = int(_num(_g(em, 'prefixId')))
        if not prefix:
            continue
        for row in rows:
            if not isinstance(row, dict):
                continue
            if int(_num(row.get('equipId'))) != prefix:
                continue
            if int(_num(row.get('cardGroupId'))) != gid:
                continue
            _acc(pct, flat, row.get('activeAttr'), row.get('valueType'),
                 row.get('effectValue'))
    return pct, flat


def beast_bonus(meta, beasts):
    """神兽：`beast_meta[metaId].attrs.beastSkillCountry == 卡的国家` 时生效，
    技能等级取该神兽当前 level 对应的 `items[level].beastSkillId`（第 679-730 行）。
    """
    pct, flat = _new_bonus()
    if not meta or not beasts:
        return pct, flat
    country = int(_num(_g(meta, 'country')))
    metas = _tbl('beast_meta') or {}
    for b in beasts:
        if b is None:
            continue
        bm = metas.get(int(_num(_g(b, 'meta_id')))) or {}
        attrs = _g(bm, 'attrs') or {}
        if int(_num(_g(attrs, 'beastSkillCountry'))) != country:
            continue
        lv = int(_num(_g(b, 'level')) or 1)
        skill_id = 0
        for it in (_g(bm, 'items') or []):
            if int(_num(_g(it, 'level'))) == lv:
                skill_id = int(_num(_g(it, 'beastSkillId')))
                break
        for row in skill_status_rows(skill_id):
            _acc(pct, flat, row.get('impactAttr'), row.get('valueType'),
                 row.get('effectValue'))
    return pct, flat


# ---------------------------------------------------------------- 完整面板
def panel(card, equips=None, treasure=None, spirits=None, extra=None,
          country_nums_map=None, beasts=None):
    """一张卡的完整 att/def/hp —— 逐字对应客户端
    `getCardPropertiesWithSharkCard`（第 766-772 行）。

        temp = 基础 + 装备 + 宝物 + 元神
        面板 = temp + floor(temp*连协%) + floor(temp*套装%) + floor(temp*神兽%)
               + 连协值 + 套装值 + 神兽值 + 阵位加成
               + （额外的百分比 / 固定值加成，给调用方用）

    ⚠️ 每个百分比**各自取整**后相加，不是先合并再取整：
       ⌊0.24x⌋ + ⌊0.27x⌋ ≠ ⌊0.51x⌋。

    country_nums_map: {国家id: 队伍里该国的卡数}，缺省就认为连协不满足条件。
    beasts: [{'meta_id','level'}]，服务端目前没有神兽归属表，通常传 None。
    """
    meta = card_meta(_g(card, 'meta_id')) or {}
    base = card_attributes(card, meta)
    temp = {'att': int(base['att']), 'def': int(base['def']), 'hp': int(base['hp'])}
    for e in (equips or []):
        if e is None:
            continue
        temp = sum_attributes(temp, equip_attributes(e))
    if treasure is not None:
        temp = sum_attributes(temp, treasure_attributes(treasure))
    for s in (spirits or []):
        if s is None:
            continue
        temp = sum_attributes(temp, spirit_attributes(s))

    gp, gf = group_skill_bonus(meta, country_nums_map)
    sp, sf = equip_suit_bonus(meta, equips)
    bp, bf = beast_bonus(meta, beasts)

    e = extra or {}
    pct = e.get('pct') or {}
    flat = e.get('flat') or {}
    matrix = e.get('matrix') or {}
    out = {}
    for k in ('att', 'def', 'hp'):
        v = temp[k]
        v += int(v * gp[k]) + int(v * sp[k]) + int(v * bp[k])
        v += gf[k] + sf[k] + bf[k]
        v += int(_num(matrix.get(k)))
        v += sum(int(v * _num(x)) for x in (pct.get(k) or []))
        v += sum(int(_num(x)) for x in (flat.get(k) or []))
        out[k] = int(v)
    return out
