#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""游戏静态配置的统一入口。

过渡期说明
----------
配置解析逻辑（读 `work/luasrc/canon/configs/*.lua`）原本写在 `canon_server.py`
和 `features.py` 里，已经过大量实测校正，这里**不再重复实现**，而是包装成
一个稳定的门面：

  * `features`   —— 卡牌/技能/等级/进化/道具/商店 元数据（无模块级副作用）
  * `canon_server` —— 玩法设置 / 战斗表 / 抽卡池 / 充值档位

`canon_server` 的导入会构造一次旧的 JSON State（无害），
等新栈完全接管后应把这些构建器搬进来，届时本文件改成一个薄 re-export 即可。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import features as _feat                     # noqa: E402
import canon_server as _cs                   # noqa: E402

CONFIGS_DIR = _feat._CONFIGS

# ---------------------------------------------------------------- 资源类型
# 客户端 RewardManager.lua 的 ResourceEnum（权威定义）
RE_COIN = 1             # 金币 / 银币        -> player.gold
RE_GEMS = 2             # 钻石              -> player.gem
RE_ENERGY = 3           # 体力              -> player.energy
RE_EXP = 4              # 主角经验          -> player.exp
RE_CARD = 5             # 卡牌              -> player_card
RE_EQUIP = 6            # 装备              -> player_equip
RE_PROP = 7             # 道具              -> player_prop
RE_FRIEND_POINT = 8     # 邀请点数          -> player.friend_point
RE_GRID = 9             # 背包格            -> player_extend.bought_grid_num
RE_SKILL_POINTS = 10
RE_EVENT_POINT = 11     # 精力              -> player.event_point
RE_ARENA_SCORE = 12     # 竞技场积分        -> arena_rank.score
RE_BEAST = 13
RE_BEAST_FRAGMENT = 14
RE_GACHA_POINT = 16
RE_CARD_FRAGMENT = 17   # 将魂              -> player_fragment(kind=1)
RE_EQUIP_FRAGMENT = 18  # 器魂              -> player_fragment(kind=2)
RE_RP_VALUE = 19        # 人品值
RE_UNION_CONTRIBUTION = 20
RE_GENERAL_EXP = 21     # 武将经验          -> player.general_exp
RE_ASTRAL_ESSENCE = 22  # 星灵              -> player.astral_essence
RE_VIP_EXP = 23         # VIP 经验          -> player.vip_exp
RE_SPIRIT = 24          # 元神              -> player_spirit
RE_ENCHANT_POINT = 26   # 装备灵值
RE_TREASURE = 27        # 宝物              -> player_treasure
RE_TREASURE_FRAGMENT = 28
RE_MEDAL = 29           # 勋章              -> player.medal_num
RE_MYSTERIOUS_COINS = 30  # 秘境货币        -> player_mysterious_coin

# 碎片 kind（player_fragment.kind）
FRAG_CARD = 1
FRAG_EQUIP = 2
FRAG_TREASURE = 3


# ---------------------------------------------------------------- 卡牌
def card_meta(meta_id):
    _feat._load_card_meta()
    return _feat._CARD_META.get(int(meta_id))


def card_meta_exists(meta_id):
    return _feat.card_meta_exists(meta_id)


def card_group_id(meta_id):
    return _feat.card_group_id(meta_id)


def build_card_skills(meta_id):
    """按配置生成 cardSkills[]。

    ⚠️ 必须生成：cardSkills 为空但 card_meta.skill ~= 0 时，
    QueueCardPanel 会索引 nil skill_meta 直接 SIGKILL。
    """
    return _feat.build_card_skills(meta_id)


def card_all_ids():
    _feat._load_card_meta()
    return sorted(_feat._CARD_META.keys())


def card_rare(meta_id):
    return _cs._CARD_RARE.get(int(meta_id))


def card_max_level(meta_id):
    return _feat._card_max_level(int(meta_id))


def card_level_row(level):
    _feat._load_card_level()
    return _feat._CARD_LEVEL.get(int(level))


def apply_card_total_exp(card, total_exp):
    """把累计经验灌进卡牌 dict（会改 level/exp 并返回剩余经验）。"""
    return _feat._apply_card_total_exp(card, int(total_exp))


def matter_provide_exp(card):
    """材料卡能提供的经验。"""
    return _feat._matter_provide_exp(card)


def equip_level_cap(player_level):
    return max(1, min(99, int(player_level or 1)))


def evolve_equip_meta(equip):
    """装备进化：同族 metaId +1（…x1 → …x2，最高 x5）。"""
    return _feat._evolve_equip_meta(equip)


def normalize_additional_card_ids(raw):
    return _feat.normalize_additional_card_ids(raw)


def apply_team_formation(player, main_card_id, additional_card_ids):
    return _feat.apply_team_formation(player, main_card_id, additional_card_ids)


def make_card(card_id, meta_id, level=1, exp=0):
    return _feat.make_card(card_id, meta_id, level, exp)


def make_equip(equip_id, meta_id, level=1, exp=0, card_id=0):
    return _feat.make_equip(equip_id, meta_id, level, exp, card_id)


# ---------------------------------------------------------------- 道具 / 商店
def prop_meta(meta_id):
    _feat._load_prop_meta()
    return _feat._PROP_META.get(int(meta_id))


def shop_meta(goods_id):
    _feat._load_shop_meta()
    return _feat._SHOP_META.get(int(goods_id))


def shop_all():
    _feat._load_shop_meta()
    return _feat._SHOP_META


# ---------------------------------------------------------------- 玩法设置
def game_setting_config():
    return _cs._game_setting_config()


def battle_setting_config():
    return _cs._battle_setting_config()


def payment_exchanges():
    return _cs._payment_exchanges()


def maintenance_items():
    return _cs._all_maintenance_items()


def secret_shop_payload():
    return _cs._secret_shop_payload()


# ---------------------------------------------------------------- 抽卡
def init_gacha():
    _cs._init_gacha()
    return _cs._GACHA_CFG


def gacha_cfg(gacha_id):
    _cs._init_gacha()
    return _cs._GACHA_CFG.get(int(gacha_id))


def roll_gacha(gacha_id, times=1, min_pack_id=0, pulled=0):
    """Pure reward specifications; account pity counters live in SQLite."""
    import random
    cfg = gacha_cfg(gacha_id) or {}
    out=[]
    for index in range(max(1,int(times))):
        force = int(min_pack_id or 0)
        if times>=10 and index==0: force=max(force,int(cfg.get('firstTenDrawMin') or 0))
        elif pulled==0 and index==0: force=max(force,int(cfg.get('firstDrawMin') or 0))
        packs=[p for p in cfg.get('packs',[]) if p['weight']>0]
        filtered=[p for p in packs if p['id']>=force]
        if force and filtered: packs=filtered
        if not packs: raise ValueError('empty gacha pool')
        pack=random.choices(packs,weights=[p['weight'] for p in packs],k=1)[0]
        pool=_cs._CARDS_BY_RARE.get(pack['rare']) or pack['metas']
        out.append({'itemType':RE_CARD,'metaId':int(random.choice(pool)),
                    'amount':1,'level':1,'exp':0})
    return out


# ---------------------------------------------------------------- 战斗 / 关卡
def init_battle_meta():
    _cs._init_battle_meta()


def battle_event(mission_id):
    _cs._init_battle_meta()
    return _cs._BATTLE_EVENT.get(int(mission_id))


def build_battle_response(mission_id, battle_type=1):
    return _cs._build_battle_response(int(mission_id), int(battle_type))


def drop_packs():
    return _cs._DROP_PACKS


def roll_drop_packs(packs):
    import random
    out = []
    for pack_id, probability in packs or []:
        if random.random() > float(probability): continue
        pool = _cs._DROP_PACKS.get(int(pack_id)) or []
        if pool:
            out.append({'itemType': RE_EQUIP, 'metaId': int(random.choice(pool)),
                        'level': 1, 'exp': 0, 'amount': 1})
    return out


def map_event_rewards(kind="coin", chapter_id=None):
    return _cs._map_event_rewards(kind, chapter_id)


# ---------------------------------------------------------------- 等级 / VIP
def user_level_exp_table():
    _cs._init_user_level()
    return _cs._USER_LEVEL_EXP


VIP_MAX_LEVEL = _cs.VIP_MAX_LEVEL


def charge_money_rewards():
    """累充档位配置：{id: {requireGold, rewards:[...]}}"""
    _cs._init_charge_money_reward()
    return _cs._CHARGE_MONEY_REWARD


STARTER_CARD_META = _cs.STARTER_CARD_META
STARTER_CARD_ID = _cs.STARTER_CARD_ID
STARTER_PROPS = list(_feat._STARTER_PROPS)
STARTER_EQUIP_METAS = list(_feat._STARTER_EQUIP_METAS)


# ---------------------------------------------------------------- 背包容量
def bag_total_grid(player):
    """背包总格数 = 基础 + 已购买。客户端 BagCalcManager 用的是同一套算法。"""
    gs = game_setting_config()
    base = int(gs.get("initGridNum") or gs.get("gridInitNum") or 100)
    return base + int(player["bought_grid_num"] or 0)


def spirit_pool_total_grid(player):
    sp = game_setting_config().get("spiritSettingConfig") or {}
    return (int(sp.get("spiritPoolInitSize") or 50)
            + int(player["bought_spirit_pool_num"] or 0)
            * int(sp.get("spiritPoolExtraSizePerPurchase") or 5))


# ================================================================ 通用奖励解析
# 原厂配置里奖励有两种约定，别混：
#   1) 包 id：字段名含 package / rewardId / achieveReward 等，值是 reward_package.id
#      （范围 10001..19322）
#   2) 直接表征：rewardType + rewardId/rewardID + rewardAmount/rewardNum
#      rewardType 就是 ResourceEnum（1金币 2钻石 4经验 5卡牌 6装备 7道具 …）
# 本模块提供统一的解析入口，两种都能吃。

import luaconf as _lc                                # noqa: E402

_REWARD_PKG = None


def _reward_index():
    global _REWARD_PKG
    if _REWARD_PKG is None:
        _REWARD_PKG = {}
        for row in _lc.as_list(_lc.load('reward_package')):
            try:
                _REWARD_PKG[int(row['id'])] = row
            except (KeyError, TypeError, ValueError):
                continue
    return _REWARD_PKG


def reward_package(pkg_id):
    """取一个奖励包定义（原始行）。"""
    return _reward_index().get(int(pkg_id))


def reward_from_package(pkg_id):
    """把奖励包展开成客户端 reward 列表：[{itemType, metaId, amount}, ...]"""
    row = reward_package(pkg_id)
    if not row:
        return []
    out = []
    for i in range(1, 11):
        t = int(row.get('content%dType' % i) or 0)
        if not t:
            continue
        out.append({'itemType': t,
                    'metaId': int(row.get('content%dId' % i) or 0),
                    'amount': int(row.get('content%dAmount' % i) or 0)})
    return out


def reward_package_exists(pkg_id):
    return int(pkg_id) in _reward_index()


def reward_from_spec(item_type, meta_id=0, amount=1):
    """直接表征 → reward。"""
    return {'itemType': int(item_type or 0), 'metaId': int(meta_id or 0),
            'amount': int(amount or 0)}


def resolve_reward_ids(ids):
    """一串「可能是包 id，也可能是道具 metaId」的值 → reward 列表。

    优先当包 id 解；解不出来就退回「当成道具」。
    """
    out = []
    for i in ids:
        i = int(i or 0)
        if not i:
            continue
        if reward_package_exists(i):
            out += reward_from_package(i)
        else:
            out.append(reward_from_spec(RE_PROP, i, 1))
    return out


# ================================================================ 活动时间窗
# 客户端 MaintenanceManager:getStartAndEndTime(featureName) 读的是服务器下发的
# maintenanceItem[]。这里从本地 maintenance 配置生成，服务端可覆盖。
_MAINT = None


def _maintenance_table():
    global _MAINT
    if _MAINT is None:
        _MAINT = {}
        rows = _lc.as_list(_lc.load('maintenance'))
        for row in rows:
            items = row.get('feature') if isinstance(row, dict) else None
            if items is None:
                continue
            for f in (items if isinstance(items, list) else [items]):
                if isinstance(f, dict) and f.get('name'):
                    _MAINT[f['name']] = f
    return _MAINT


def feature_config(name):
    return _maintenance_table().get(name)


def feature_names():
    return sorted(_maintenance_table().keys())


# ---------------------------------------------------------------- VIP
_VIP_ROWS = []


def vip_setting_rows():
    if not _VIP_ROWS:
        _VIP_ROWS.extend(r for r in _lc.as_list(_lc.load('vip_setting'))
                         if isinstance(r, dict))
    return _VIP_ROWS


def vip_level_of(player):
    """按 vipExp 推导 VIP 等级（和客户端一致）。

    ⚠️ `player.vip_level` 这一列在历史数据里经常是 0（从没同步过），
       而客户端是根据 `vipExp` 查 `vip_setting[].requireGold` 自己算的 ——
       两边不一致时就会出现「界面显示 VIP 7、服务端按 VIP 0 判定」，
       表现是迎财神这类有 VIP 门槛的玩法一直报「道具不足(712301)」。
       凡是需要 VIP 的地方都用这个函数，不要直接读列。
    """
    if not isinstance(player, dict):
        player = dict(player)
    exp = int(player.get('vip_exp') or 0)
    level = 0
    for row in vip_setting_rows():
        if exp >= int(row.get('requireGold') or 0):
            level = max(level, int(row.get('level') or 0))
    return level
