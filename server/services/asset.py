#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""资产操作：卡牌养成 / 装备强化 / 道具使用 / 商店购买 / 编队。

每个方法返回 (retCode, payload)：
    retCode == 200 表示成功（客户端 pickResponseMeta 只在 200 时才走 onSuccess）
    否则 payload 是业务错误码（int），由 api 层塞进 retCode
"""
import random
import time

import gamedata as G
import luaconf

OK = 200

_FRAG_ROWS = []
_REL_ROWS = []


def _prop_relation_rows():
    """prop_relation：宝箱 id -> 对应钥匙 id（铜/银/金 三对）。"""
    if not _REL_ROWS:
        try:
            _REL_ROWS.extend(r for r in luaconf.as_list(luaconf.load('prop_relation'))
                             if isinstance(r, dict))
        except Exception:
            return []
    return _REL_ROWS


def _card_fragment_rows():
    """碎片配置（惰性加载一次）。结构：{id=碎片道具id, cardId, amount, readName}"""
    if not _FRAG_ROWS:
        try:
            _FRAG_ROWS.extend(r for r in luaconf.as_list(luaconf.load('card_fragment_meta'))
                              if isinstance(r, dict))
        except Exception:
            return []
    return _FRAG_ROWS


def card_fragment(meta_id):
    """由 card_meta 的 id 反查 (碎片道具 id, 需要数量)。

    ⚠️ `card_meta` 里**没有** fragmentId/fragmentNum 这两个字段（别照着写），
       映射在 `card_fragment_meta`：{id=碎片 id, cardId=卡 id, amount=合成需要数}。
       查不到就返回 (0, 30)。
    """
    cid = int(meta_id or 0)
    for row in _card_fragment_rows():
        if int(row.get('cardId') or 0) == cid:
            return int(row.get('id') or 0), int(row.get('amount') or 30)
    return 0, 30

# 常用业务错误码（来自客户端 CommErrorCodes.lua）
E_USER_NOT_EXIST = 710070
E_GRID_NOT_ENOUGH = 710516
E_GEM_NOT_ENOUGH = 710513
E_CARD_NOT_EXIST = 712401
E_EQUIP_NOT_EXIST = 712501
E_EQUIP_MAX_LEVEL = 712509
E_EQUIP_EVOLVE_MAX = 712510
E_PROP_NOT_ENOUGH = 712301
E_LEVEL_NOT_ENOUGH = 710512


class AssetService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    # ============================================================ 卡牌
    def upgrade_card(self, player_id, card_id, matter_card_ids=None, use_gold=True):
        """升级卡牌：吃掉材料卡换经验。

        **逐字对应客户端 `CardComposeScene:getComposeExp`（第 71-113 行）**：
            getTotalExp = card_meta[matter.metaId].basicExp
                          + (card_level[matter.level].totalExp + matter.exp)
                            * card_level[matter.level].expConvertCoefficient
            resultExp   = card_level[main.level].totalExp + main.exp + Σ getTotalExp
            goldCost    = floor(Σ getTotalExp * cardUpgradeCoinRevise)
            newLevel    = max{L : card_level[L].totalExp <= resultExp}
                          ，上限 card_evolve[meta.evolutionLevel].maxCardLevel
        """
        from . import cardstats as CS
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return E_CARD_NOT_EXIST, None
        matter = []
        for mid in (matter_card_ids or []):
            m = self.r.asset.card(player_id, mid)
            if m and int(m['card_id']) != int(card_id):
                matter.append(dict(m))

        if not matter:
            # 没有材料卡：按同样曲线给一点经验，但不动金币
            gain = 50
            new_level, new_exp, _ = CS.add_exp(dict(card), gain)
            self.r.asset.update_card(player_id, card_id, level=new_level, exp=new_exp)
            return OK, self._card_resp(player_id, card_id)

        new_level, gold_cost, _result, _overflow = CS.compose_exp(dict(card), matter)
        p = self.r.player.player(player_id)
        if use_gold and gold_cost and int(p['gold']) < gold_cost:
            return E_GEM_NOT_ENOUGH, None

        with self.db.tx() as con:
            if use_gold and gold_cost:
                self.r.player.add_currency(player_id, 'gold', -gold_cost)
            for m in matter:
                self.r.asset.delete_card(player_id, int(m['card_id']))

        # 新等级下剩余经验 = resultExp - card_level[newLevel].totalExp
        lv_cfg = CS.card_level_cfg(new_level)
        rest = max(0, int(_result - float(lv_cfg.get('totalExp') or 0)))
        self.r.asset.update_card(player_id, card_id, level=new_level, exp=rest)
        return OK, self._card_resp(player_id, card_id)

    def upgrade_card_by_general_exp(self, player_id, card_id, target_level):
        """用通用经验直接推到目标等级（消耗 = 两个等级 totalExp 的差）。"""
        from . import cardstats as CS
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return E_CARD_NOT_EXIST, None
        need, target = CS.general_exp_needed(dict(card), target_level)
        if need <= 0:
            return OK, self._card_resp(player_id, card_id)
        p = self.r.player.player(player_id)
        if int(p['general_exp']) < need:
            return E_PROP_NOT_ENOUGH, None
        with self.db.tx() as con:
            self.r.player.add_currency(player_id, 'general_exp', -need)
        lv_cfg = CS.card_level_cfg(target)
        cur_total = float(CS.card_level_cfg(card['level']).get('totalExp') or 0) + float(
            card['exp'] or 0)
        rest = max(0, int(cur_total + need - float(lv_cfg.get('totalExp') or 0)))
        self.r.asset.update_card(player_id, card_id, level=target, exp=rest)
        return OK, self._card_resp(player_id, card_id)

    def evolve_card(self, player_id, card_id):
        """进化：按配置升阶，并校验 evolveNeedLevel / maxCardLevel。"""
        from . import cardstats as CS
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return E_CARD_NOT_EXIST, None
        meta = G.card_meta(int(card['meta_id'])) or {}
        cur_evo = int(meta.get('evolutionLevel') or 1)
        ev = CS.card_evolve_cfg(cur_evo)
        need_lv = int(ev.get('evolveNeedLevel') or 0)
        if need_lv and int(card['level']) < need_lv:
            return E_LEVEL_NOT_ENOUGH, None
        price = int(ev.get('evolvePrice') or 0)
        if price:
            p = self.r.player.player(player_id)
            if int(p['gold']) < price:
                return E_GEM_NOT_ENOUGH, None
            self.r.player.add_currency(player_id, 'gold', -price)
        nxt = int(meta.get('evolutionCardId') or 0)
        if nxt and G.card_meta_exists(nxt):
            self.r.asset.update_card(player_id, card_id, meta_id=nxt,
                                     card_group_id=G.card_group_id(nxt))
            # 换 meta 后技能要重建，否则 skillId 对不上配置 → SIGKILL
            self.r.asset.replace_card_skills(card_id, G.build_card_skills(nxt))
        return OK, self._card_resp(player_id, card_id)

    def train_card(self, player_id, card_id, use_gold=False, item_meta_id=0, train_times=1):
        """Persist a pending roll; only saveCardTrain commits its deltas."""
        from . import cardstats as CS
        card = self.r.asset.card(player_id, card_id)
        if card is None: return E_CARD_NOT_EXIST, None
        if int(self.r.player.player(player_id)['level']) < 19: return E_LEVEL_NOT_ENOUGH, None
        count = int(train_times or 1)
        if count not in (1, 10): return E_PROP_NOT_ENOUGH, None
        cfg = G.game_setting_config().get('cardTrainConfig') or {}
        special = bool(use_gold)
        cost_meta = int(cfg.get('pydMetaId') or 400010)
        stones = int(cfg.get('pydCost') or 1)*count
        cost = int(cfg.get('ybCost') or 10)*count if special else 0
        with self.db.tx():
            if CS.total_potential(card) <= int(card['used_potential']): return E_LEVEL_NOT_ENOUGH, None
            if self.r.asset.prop(player_id, cost_meta) < stones: return E_PROP_NOT_ENOUGH, None
            if special and self.ctx.player.spend_gems(player_id, cost) is None: return E_GEM_NOT_ENOUGH, None
            self.r.asset.add_prop(player_id, cost_meta, -stones)
            prefix = 'special' if special else 'normal'
            lo = int(cfg.get(prefix+'TrainFloor') or (3 if special else 1))
            hi = int(cfg.get(prefix+'TrainCeil') or (10 if special else 5))
            remaining = max(0, CS.total_potential(card)-int(card['used_potential']))
            gains = [0,0,0]
            # Floor/Ceil describes total potential distributed per roll.
            for _ in range(count):
                value = max(0,min(remaining,random.randint(lo,max(lo,hi))))
                for _ in range(value): gains[random.randrange(3)] += 1
                remaining -= value
            pending = dict(zip(('attTrainValue','defTrainValue','hpTrainValue'),gains))
            self.ctx.activity.save_state(player_id,'card_train_%d'%int(card_id),pending)
            return OK, pending

    def save_card_train(self, player_id, card_id, att=None, deff=None, hp=None):
        card = self.r.asset.card(player_id, card_id)
        if card is None: return E_CARD_NOT_EXIST, None
        with self.db.tx():
            key = 'card_train_%d'%int(card_id)
            st = self.ctx.activity.state(player_id,key)
            if not st: return OK, self._card_resp(player_id,card_id)
            gains = [int(st.get(k) or 0) for k in ('attTrainValue','defTrainValue','hpTrainValue')]
            self.r.asset.update_card(player_id,card_id,
                att_train_value=int(card['att_train_value'])+gains[0],
                def_train_value=int(card['def_train_value'])+gains[1],
                hp_train_value=int(card['hp_train_value'])+gains[2],
                used_potential=int(card['used_potential'])+sum(gains))
            self.ctx.activity.save_state(player_id,key,{})
            return OK, self._card_resp(player_id,card_id)

    def give_up_card_train(self, player_id, card_id):
        if self.r.asset.card(player_id,card_id) is None: return E_CARD_NOT_EXIST, None
        with self.db.tx():
            self.ctx.activity.save_state(player_id,'card_train_%d'%int(card_id),{})
            return OK, self._card_resp(player_id,card_id)

    def lock_card(self, player_id, card_id, method_type=1):
        """methodType: 1 上锁 / 2 解锁（客户端 CardInfoNewPanel 传的就是这个语义）。"""
        self.r.asset.update_card(player_id, card_id, is_locked=1 if int(method_type) == 1 else 0)
        return OK, {'cardId': int(card_id), 'lock': int(method_type) == 1}

    def adjust_card_avatar(self, player_id, card_id, avatar_meta_id):
        if self.r.asset.card(player_id, card_id) is None:
            return E_CARD_NOT_EXIST, None
        if int(avatar_meta_id) and not G.card_meta_exists(int(avatar_meta_id)):
            return E_CARD_NOT_EXIST, None
        self.r.asset.update_card(player_id, card_id, avatar_meta_id=int(avatar_meta_id))
        return OK, {'cardId': int(card_id), 'avatarMetaId': int(avatar_meta_id)}

    def split_card(self, player_id, card_id):
        """拆解：返还碎片（将魂）。"""
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return E_CARD_NOT_EXIST, None
        protected = self.r.asset.card_holder_ids(player_id)
        if int(card_id) in protected:
            return E_GRID_NOT_ENOUGH, None
        meta = G.card_meta(int(card['meta_id'])) or {}
        frag, _need = card_fragment(int(card['meta_id']))       # 见 card_fragment() 注释
        amount = max(1, int(meta.get('rare') or 1) * 5)
        rewards = []
        if frag:
            rewards.append({'itemType': G.RE_CARD_FRAGMENT, 'metaId': frag, 'amount': amount})
        self.r.asset.delete_card(player_id, card_id)
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True, reason='splitCard')
        return OK, {'rewards': applied}

    def sell_cards(self, player_id, card_ids):
        """卖卡返金币。主将与上阵卡受保护。"""
        protected = self.r.asset.card_holder_ids(player_id)
        total = 0
        sold = []
        for cid in card_ids or []:
            if int(cid) in protected:
                continue
            card = self.r.asset.card(player_id, cid)
            if not card:
                continue
            meta = G.card_meta(int(card['meta_id'])) or {}
            total += int(meta.get('sellPrice') or meta.get('price') or 100)
            sold.append(int(cid))
        for cid in sold:
            self.r.asset.delete_card(player_id, cid)
        rewards = []
        if total:
            rewards.append({'itemType': G.RE_COIN, 'amount': total})
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True, reason='sellCards')
        return OK, {'rewards': applied}

    def pray_card_fragment(self, player_id, meta_id):
        """碎片祈祷/合成：碎片够了就合成一张卡。

        ⚠️ 碎片映射在 `card_fragment_meta`，不在 card_meta（见 card_fragment() 注释）。
           原实现读 `meta['fragmentId']` / `meta['fragmentNum']` —— 这两个字段不存在，
           于是永远走「道具不足」分支，这个接口等于死的。
        """
        frag, need = card_fragment(int(meta_id))
        if not frag:
            return E_PROP_NOT_ENOUGH, None
        have = self.r.asset.prop(player_id, frag)
        if have < need:
            return E_PROP_NOT_ENOUGH, None
        self.r.asset.add_fragment(player_id, G.FRAG_CARD, frag, -need)
        cid = self.r.asset.create_card(player_id, int(meta_id))
        return OK, {'sharkCard': self._card_payload(player_id, cid), 'rewards': []}

    def _card_resp(self, player_id, card_id):
        """卡牌操作接口的响应：客户端读的是 `sharkCard` 这个键。"""
        return {'sharkCard': self._card_payload(player_id, card_id)}

    def _card_payload(self, player_id, card_id):
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return {}
        skills = self.r.asset.card_skills(card_id)
        eqs = [dict(x) for x in self.r.asset.equips_of_card(player_id, card_id)]
        sps = self.r.asset.spirits_of_card(player_id, card_id)
        tro = self.r.asset.treasure_of_card(player_id, card_id)
        from assembler import build_card
        return build_card(card, skills, eqs, sps,
                          int(tro['treasure_id']) if tro else 0,
                          treasure=dict(tro) if tro else None)

    # ============================================================ 装备
    def upgrade_equip(self, player_id, equip_id, use_gold=True):
        e = self.r.asset.equip(player_id, equip_id)
        if e is None:
            return E_EQUIP_NOT_EXIST, None
        p = self.r.player.player(player_id)
        cap = G.equip_level_cap(int(p['level']))
        if int(e['level']) >= cap:
            return E_EQUIP_MAX_LEVEL, None
        cost = int(e['level']) * 100
        if use_gold and int(p['gold']) < cost:
            return E_GEM_NOT_ENOUGH, None
        if use_gold:
            self.r.player.add_currency(player_id, 'gold', -cost)
        self.r.asset.update_equip(player_id, equip_id, level=int(e['level']) + 1)
        return OK, {'sharkEquip': self._equip_payload(player_id, equip_id)}

    def quick_upgrade_equip(self, player_id, equip_id):
        """一键强化到金币允许的上限。"""
        e = self.r.asset.equip(player_id, equip_id)
        if e is None:
            return E_EQUIP_NOT_EXIST, None
        p = self.r.player.player(player_id)
        cap = G.equip_level_cap(int(p['level']))
        gold = int(p['gold'])
        lv = int(e['level'])
        spent = 0
        while lv < cap:
            cost = lv * 100
            if spent + cost > gold:
                break
            spent += cost
            lv += 1
        if lv == int(e['level']):
            return E_EQUIP_MAX_LEVEL, None
        self.r.player.add_currency(player_id, 'gold', -spent)
        self.r.asset.update_equip(player_id, equip_id, level=lv)
        return OK, {'sharkEquip': self._equip_payload(player_id, equip_id)}

    def evolve_equip(self, player_id, equip_id):
        e = self.r.asset.equip(player_id, equip_id)
        if e is None:
            return E_EQUIP_NOT_EXIST, None
        d = dict(e)
        G.evolve_equip_meta(d)
        if int(d['meta_id']) == int(e['meta_id']):
            return E_EQUIP_EVOLVE_MAX, None
        self.r.asset.update_equip(player_id, equip_id, meta_id=int(d['meta_id']))
        return OK, {'sharkEquip': self._equip_payload(player_id, equip_id)}

    def equip_enchant(self, player_id, equip_id, prop_meta_id=0):
        """附灵：吃灵值道具提升 enchantLevel。"""
        e = self.r.asset.equip(player_id, equip_id)
        if e is None:
            return E_EQUIP_NOT_EXIST, None
        if prop_meta_id and self.r.asset.prop(player_id, prop_meta_id) <= 0:
            return E_PROP_NOT_ENOUGH, None
        if prop_meta_id:
            self.r.asset.add_prop(player_id, prop_meta_id, -1)
        self.r.asset.update_equip(player_id, equip_id,
                                  enchant_level=int(e['enchant_level']) + 1,
                                  enchant_num=int(e['enchant_num']) + 10)
        return OK, {'sharkEquip': self._equip_payload(player_id, equip_id)}

    def setup_equip(self, player_id, card_id, equip_id):
        """穿装备。校验：卡牌存在、装备存在；一件装备只能在一个卡上。"""
        card = self.r.asset.card(player_id, card_id)
        if card is None:
            return E_CARD_NOT_EXIST, None
        eq = self.r.asset.equip(player_id, equip_id)
        if eq is None:
            return E_EQUIP_NOT_EXIST, None
        with self.db.tx() as con:
            con.execute("UPDATE player_equip SET card_id=? WHERE player_id=? AND equip_id=?",
                        (int(card_id), int(player_id), int(equip_id)))
        return OK, {'sharkEquip': self._equip_payload(player_id, equip_id)}

    def sell_equips(self, player_id, equip_ids):
        total, sold = 0, []
        for eid in equip_ids or []:
            e = self.r.asset.equip(player_id, eid)
            if not e:
                continue
            total += int(e['level']) * 50 + 100
            sold.append(int(eid))
        for eid in sold:
            self.r.asset.delete_equip(player_id, eid)
        rewards = [{'itemType': G.RE_COIN, 'amount': total}] if total else []
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True, reason='sellEquips')
        return OK, {'rewards': applied}

    def upgrade_equip_for_one_card(self, player_id, card_id, equip_ids=None):
        """批量强化某张卡身上的装备。"""
        ids = equip_ids or [int(r['equip_id'])
                            for r in self.r.asset.equips_of_card(player_id, card_id)]
        out = []
        for eid in ids:
            code, _ = self.quick_upgrade_equip(player_id, eid)
            e = self.r.asset.equip(player_id, eid)
            if e:
                out.append(self._equip_payload(player_id, eid))
        return OK, {'sharkEquips': out}

    def _equip_payload(self, player_id, equip_id):
        e = self.r.asset.equip(player_id, equip_id)
        from assembler import build_equip
        return build_equip(e) if e else {}

    # ============================================================ 道具 / 商店
    # prop_meta.effectType 的真实语义（按 prop_meta 的 readName 逐类核对出来的，
    # 原来的实现把 1/3/4 全部映射错了 —— 体力药水被当成金币、礼包被当成经验、
    # 宝箱被当成体力，所以「开宝箱没有东西出来」）：
    #   0 = 经验球 / 魂石        effectValue = 经验值
    #   1 = 体力药水             effectValue = 体力
    #   2 = 精力药水             effectValue = 精力
    #   3 = 礼包                 effectValue = reward_package 的 id
    #   4 = 宝箱                 effectValue = 档位(1铜/2银/3金)，要配 prop_relation 的钥匙
    #   5 = 钥匙                 effectValue = 档位
    #   6 = 免战牌               effectValue = 秒数
    #   7 = VIP礼包/宝箱三       effectValue = 另一套礼包 id（reward_package 里没有）
    #   8/9/10/11/12 = 手记 / 次数礼包 / 改名卡 / 红包
    EFF_EXP, EFF_ENERGY, EFF_VIGOUR, EFF_GIFT, EFF_BOX, EFF_KEY = 0, 1, 2, 3, 4, 5
    EFF_VIPGIFT = 7

    # 宝箱档位 -> 开箱奖励包。⚠️ [自编]：原厂把开箱掉落放在服务端、没随包下发，
    # 客户端配置里也没有对应表（reward_package 只有 10001-19322）。
    # 这里按档位给一套温和的产出，改这一张表就能调整。
    BOX_DROPS = {
        1: [{'itemType': G.RE_COIN, 'amount': 20000},
            {'itemType': G.RE_CARD_FRAGMENT, 'metaId': 800101, 'amount': 2}],
        2: [{'itemType': G.RE_COIN, 'amount': 50000},
            {'itemType': G.RE_GEMS, 'amount': 100},
            {'itemType': G.RE_CARD_FRAGMENT, 'metaId': 800101, 'amount': 5}],
        3: [{'itemType': G.RE_COIN, 'amount': 100000},
            {'itemType': G.RE_GEMS, 'amount': 300},
            {'itemType': G.RE_CARD_FRAGMENT, 'metaId': 800101, 'amount': 10}],
    }

    def _prop_related(self, prop_id):
        """prop_relation：宝箱 -> 对应钥匙。"""
        for row in _prop_relation_rows():
            if int(row.get('id') or 0) == int(prop_id):
                return int(row.get('relatedPropId') or 0)
        return 0

    def use_prop(self, player_id, prop_id, amount=1):
        prop_id, amount = int(prop_id), max(1, int(amount or 1))
        have = self.r.asset.prop(player_id, prop_id)
        if have < amount:
            return E_PROP_NOT_ENOUGH, None
        meta = G.prop_meta(prop_id) or {}
        eff = int(meta.get('effectType') or 0)
        val = int(meta.get('effectValue') or 0)

        # ---- 宝箱：必须连钥匙一起消耗，否则「开箱什么也没有」
        if eff == self.EFF_BOX:
            key_id = self._prop_related(prop_id)
            if key_id and self.r.asset.prop(player_id, key_id) < amount:
                return E_PROP_NOT_ENOUGH, None      # 没钥匙，客户端会提示去买
            drops = []
            for _ in range(amount):
                drops.extend(self.BOX_DROPS.get(val) or [])
            with self.db.tx():
                self.r.asset.add_prop(player_id, prop_id, -amount)
                if key_id:
                    self.r.asset.add_prop(player_id, key_id, -amount)
            applied, _ = self.ctx.reward.grant(player_id, drops, record=True,
                                               reason='openBox')
            return OK, {'rewards': applied}

        # ---- 礼包：按 reward_package 展开
        if eff in (self.EFF_GIFT, self.EFF_VIPGIFT) and val:
            pkgs = []
            for _ in range(amount):
                pkgs.extend(G.reward_from_package(val) or [])
            with self.db.tx():
                self.r.asset.add_prop(player_id, prop_id, -amount)
            applied, _ = self.ctx.reward.grant(player_id, pkgs, record=True,
                                               reason='openGift')
            return OK, {'rewards': applied}

        # ---- 钥匙单独使用没有意义，返还（不要凭空吃掉玩家的道具）
        if eff == self.EFF_KEY:
            return E_PROP_NOT_ENOUGH, None

        rewards = []
        if eff == self.EFF_ENERGY and val:
            rewards.append({'itemType': G.RE_ENERGY, 'amount': val * amount})
        elif eff == self.EFF_VIGOUR and val:
            rewards.append({'itemType': G.RE_EVENT_POINT, 'amount': val * amount})
        elif eff == self.EFF_EXP and val:
            rewards.append({'itemType': G.RE_EXP, 'amount': val * amount})
        with self.db.tx():
            self.r.asset.add_prop(player_id, prop_id, -amount)
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True, reason='useProp')
        return OK, {'rewards': applied}

    def buy_goods(self, player_id, goods_id, count=1):
        """按 shop_meta 扣钱发货。"""
        goods = G.shop_meta(int(goods_id))
        if not goods:
            return E_PROP_NOT_ENOUGH, None
        count = max(1, int(count or 1))
        price = int(goods.get('discountPrice') or goods.get('price') or 0) * count
        money = int(goods.get('moneyType') or G.RE_COIN)
        if money == G.RE_GEMS:
            if self.ctx.player.spend_gems(player_id, price) is None:
                return E_GEM_NOT_ENOUGH, None
        else:
            p = self.r.player.player(player_id)
            if int(p['gold']) < price:
                return E_GEM_NOT_ENOUGH, None
            self.r.player.add_currency(player_id, 'gold', -price)
        reward = {'itemType': int(goods.get('itemType') or 0),
                  'metaId': int(goods.get('metaId') or 0),
                  'amount': int(goods.get('amount') or 1) * count}
        applied, _ = self.ctx.reward.grant(player_id, [reward], record=True, reason='buyGoods')
        # ⚠️ `reward` 必须是**数组**，不是单个对象：
        #   客户端 ShopScene:1225 `RewardManager:getReward(evt.data.reward)`，
        #   而 getReward 第一行是 `if #rewardData <= 0 then return end`。
        #   发单个对象时 `#` 取到 0（Lua 的 # 对字典是 0）→ 直接 return，
        #   界面既不弹「购买成功」也不刷新数量 —— 表现为「买完东西不增加」
        #   （其实服务端已经发到背包了，只是客户端本地没同步）。
        return OK, {'reward': applied}

    def buy_grid(self, player_id, grid_num=1):
        """买背包格。"""
        grid_num = max(1, int(grid_num or 1))
        ext = self.r.player.extend(player_id)
        p = self.r.player.player(player_id)
        cost = 50 * (int(ext['bought_grid_times']) + 1)
        if self.ctx.player.spend_gems(player_id, cost) is None:
            return E_GEM_NOT_ENOUGH, None
        self.r.player.update_extend(
            player_id,
            bought_grid_num=int(ext['bought_grid_num']) + grid_num,
            bought_grid_times=int(ext['bought_grid_times']) + 1)
        return OK, {'rewards': [], 'requisite': {'itemType': G.RE_GEMS, 'amount': cost}}

    # ============================================================ 编队
    def adjust_team(self, player_id, main_card_id, additional_card_ids):
        """调整上阵阵容（主将 + 副将）。

        ⚠️ 主将 id 为 0 / 不存在时**必须拒绝**，不能放过去：
           下面 `if c and ...` 对 0 是跳过的，会一路执行到 set_battle_queue([0])，
           把玩家的主将清空 —— 之后客户端 `MainMenuScene:681`
           `CommonManager.changeAvatarByCardInfo(nil)` 直接 Lua 报错 → 引擎杀进程。
        """
        main_id = int(main_card_id or 0)
        if not main_id:
            return E_CARD_NOT_EXIST, None
        add = G.normalize_additional_card_ids(additional_card_ids)
        cards = [main_id] + [int(c) for c in add]
        for c in cards:
            if c and self.r.asset.card(player_id, c) is None:
                return E_CARD_NOT_EXIST, None
        self.r.asset.ensure_battle_arrays(player_id, 3)
        ext = self.r.player.extend(player_id)
        active = int(ext['battle_array_id'] or 1)
        self.r.asset.set_battle_queue(player_id, active, cards)
        self.r.asset.set_active_array(player_id, active)
        p = self.r.player.player(player_id)
        return OK, {'mainCardId': int(p['main_card_id']),
                    'additionalCardIds': p['additional_card_ids']}

    def set_card_group_interworking(self, player_id, groups):
        """缘分互通：整块存进 player_extend.extend_json。"""
        import json as _json
        ext = self.r.player.extend(player_id)
        blob = _json.loads(ext['extend_json'] or '{}')
        blob['cardGroupInterworking'] = groups or []
        self.r.player.update_extend(player_id, extend_json=blob)
        return OK, {}
