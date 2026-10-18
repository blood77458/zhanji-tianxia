#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""奖励引擎：把客户端 `{itemType, metaId?, id?, amount, level?, exp?}` 落到各张表。

`itemType` 取值见 gamedata.ResourceEnum（从客户端 RewardManager.lua 抄的权威表）。
服务端几乎所有「产出」都要经过这里：抽卡、通关、邮件领附件、活动发奖、充值发货。

返回结构同时给客户端和调用方用：
    {'itemType':.., 'metaId':.., 'amount':.., 'level':.., 'id':..}
客户端 RewardManager 认的字段就是这些。
"""
import gamedata as G


class RewardService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    # ---------------------------------------------------------------- 入口
    def grant(self, player_id, rewards, record=False, reason=''):
        """发奖。返回 (applied, changed) —— applied 是回给客户端的 reward 列表，
        changed 是本次实际动过的表名集合（用于决定要不要刷缓存的组装结果）。"""
        out, changed = [], set()
        for rw in rewards or []:
            instance = int(rw.get('itemType') or 0) in (G.RE_CARD, G.RE_EQUIP, G.RE_SPIRIT, G.RE_TREASURE)
            count = int(rw.get('amount') or 0) if instance else 1
            if instance and count < 0:
                raise ValueError('Instance rewards cannot consume owned objects')
            for _ in range(count):
                item = dict(rw, amount=1) if instance else rw
                one, ch = self.grant_one(player_id, item, reason=reason, record=record)
                if one:
                    out.append(one)
                    changed |= ch
        return out, changed

    def grant_one(self, player_id, rw, reason='', record=False):
        item_type = int(rw.get('itemType') or 0)
        amount = int(rw.get('amount') or 0)
        meta_id = int(rw.get('metaId') or 0)
        if item_type <= 0:
            return None, set()
        changed = set()
        applied = {'itemType': item_type, 'metaId': meta_id, 'amount': amount}

        if item_type == G.RE_COIN:
            self.r.player.add_currency(player_id, 'gold', amount)
            changed.add('player')

        elif item_type == G.RE_GEMS:
            if amount >= 0:
                self.ctx.player.grant_gems(player_id, amount)
            else:
                self.ctx.player.spend_gems(player_id, -amount)
            changed.add('player')

        elif item_type == G.RE_ENERGY:
            self.r.player.add_currency(player_id, 'energy', amount)
            changed.add('player')

        elif item_type == G.RE_EVENT_POINT:
            self.r.player.add_currency(player_id, 'event_point', amount)
            changed.add('player')

        elif item_type == G.RE_EXP:
            self.ctx.player.grant_exp(player_id, amount)
            changed.add('player')

        elif item_type == G.RE_FRIEND_POINT:
            self.r.player.add_currency(player_id, 'friend_point', amount)
            changed.add('player')

        elif item_type == G.RE_GENERAL_EXP:
            self.r.player.add_currency(player_id, 'general_exp', amount)
            changed.add('player')

        elif item_type == G.RE_ASTRAL_ESSENCE:
            self.r.player.add_currency(player_id, 'astral_essence', amount)
            changed.add('player')

        elif item_type == G.RE_MEDAL:
            self.r.player.add_currency(player_id, 'medal_num', amount)
            changed.add('player')

        elif item_type == G.RE_VIP_EXP:
            self.ctx.player.grant_vip_exp(player_id, amount)
            changed.add('player')

        elif item_type == G.RE_GRID:
            ext = self.r.player.extend(player_id)
            self.r.player.update_extend(
                player_id, bought_grid_num=max(0, int(ext['bought_grid_num']) + amount))
            changed.add('extend')

        elif item_type == G.RE_CARD:
            cid = self.r.asset.create_card(player_id, meta_id,
                                           level=int(rw.get('level') or 1),
                                           exp=int(rw.get('exp') or 0))
            applied['metaId'] = meta_id
            applied['id'] = cid
            applied['level'] = int(rw.get('level') or 1)
            applied['exp'] = int(rw.get('exp') or 0)
            changed.add('card')

        elif item_type == G.RE_EQUIP:
            eid = self.r.asset.create_equip(player_id, meta_id,
                                            level=int(rw.get('level') or 1),
                                            exp=int(rw.get('exp') or 0))
            applied['metaId'] = meta_id
            applied['id'] = eid
            applied['level'] = int(rw.get('level') or 1)
            applied['exp'] = int(rw.get('exp') or 0)
            applied['enchantLevel'] = 0
            applied['enchantNum'] = 0
            changed.add('equip')

        elif item_type == G.RE_SPIRIT:
            sid = self.r.asset.create_spirit(player_id, meta_id,
                                             level=int(rw.get('level') or 1), exp=int(rw.get('exp') or 0))
            applied['metaId'] = meta_id
            applied['id'] = sid
            applied['level'] = int(rw.get('level') or 1)
            applied['exp'] = int(rw.get('exp') or 0)
            changed.add('spirit')

        elif item_type == G.RE_TREASURE:
            tid = self.r.asset.create_treasure(player_id, meta_id,
                                               level=int(rw.get('level') or 1))
            applied['metaId'] = meta_id
            applied['id'] = tid
            applied['level'] = int(rw.get('level') or 1)
            changed.add('treasure')

        elif item_type == G.RE_PROP:
            self.r.asset.add_prop(player_id, meta_id, amount)
            applied['metaId'] = meta_id
            changed.add('prop')

        elif item_type == G.RE_MYSTERIOUS_COINS:
            self.r.asset.add_mysterious_coin(player_id, meta_id, amount)
            applied['metaId'] = meta_id
            changed.add('prop')

        elif item_type == G.RE_CARD_FRAGMENT:
            self.r.asset.add_fragment(player_id, G.FRAG_CARD, meta_id, amount)
            applied['metaId'] = meta_id
            changed.add('fragment')

        elif item_type == G.RE_EQUIP_FRAGMENT:
            self.r.asset.add_fragment(player_id, G.FRAG_EQUIP, meta_id, amount)
            applied['metaId'] = meta_id
            changed.add('fragment')

        elif item_type == G.RE_TREASURE_FRAGMENT:
            self.r.asset.add_fragment(player_id, G.FRAG_TREASURE, meta_id, amount)
            applied['metaId'] = meta_id
            changed.add('fragment')

        elif item_type == G.RE_ARENA_SCORE:
            self.r.db.con.execute(
                "INSERT INTO arena_rank(player_id, server_id, score) VALUES (?,1,?)"
                " ON CONFLICT(player_id) DO UPDATE SET score = MAX(0, score + ?)",
                (int(player_id), amount, amount))
            changed.add('arena')

        elif item_type == G.RE_ENCHANT_POINT:
            # 装备灵值：给指定装备加（rw['id'] 是 equipId），没有指定就忽略
            eid = int(rw.get('id') or 0)
            if eid:
                self.r.asset.update_equip(
                    player_id, eid,
                    enchant_num=max(0, int((self.r.asset.equip(player_id, eid) or
                                            {'enchant_num': 0})['enchant_num']) + amount))
                changed.add('equip')

        else:
            # 未支持的资源类型：记一条日志但不发，避免静默吞掉
            self.db.con.execute(
                "INSERT INTO reward_log(player_id, reason, item_type, meta_id, amount,"
                " create_time) VALUES (?,?,?,?,?,strftime('%s','now'))",
                (int(player_id), (reason or '') + ':unsupported', item_type, meta_id, amount))
            return None, set()

        if record:
            self.db.con.execute(
                "INSERT INTO reward_log(player_id, reason, item_type, meta_id, amount,"
                " create_time) VALUES (?,?,?,?,?,strftime('%s','now'))",
                (int(player_id), reason or '', item_type, meta_id, amount))
        return applied, changed

    # ---------------------------------------------------------------- 消耗
    def can_afford(self, player_id, costs):
        for c in costs or []:
            t = int(c.get('itemType') or 0)
            need = int(c.get('amount') or 0)
            p = self.r.player.player(player_id)
            if t == G.RE_COIN and int(p['gold']) < need:
                return False
            if t == G.RE_GEMS and int(p['gem']) < need:
                return False
            if t == G.RE_ENERGY and int(p['energy']) < need:
                return False
            if t == G.RE_EVENT_POINT and int(p['event_point']) < need:
                return False
            if t == G.RE_PROP and self.r.asset.prop(player_id, int(c.get('metaId') or 0)) < need:
                return False
        return True

    def consume(self, player_id, costs):
        """扣消耗。不足则**不扣**并返回 False（先检查后扣，避免半途扣掉）。"""
        if not self.can_afford(player_id, costs):
            return False
        for c in costs or []:
            t = int(c.get('itemType') or 0)
            need = int(c.get('amount') or 0)
            if t == G.RE_COIN:
                self.r.player.add_currency(player_id, 'gold', -need)
            elif t == G.RE_GEMS:
                self.ctx.player.spend_gems(player_id, need)
            elif t == G.RE_ENERGY:
                self.r.player.add_currency(player_id, 'energy', -need)
            elif t == G.RE_EVENT_POINT:
                self.r.player.add_currency(player_id, 'event_point', -need)
            elif t == G.RE_GENERAL_EXP:
                self.r.player.add_currency(player_id, 'general_exp', -need)
            elif t == G.RE_PROP:
                self.r.asset.add_prop(player_id, int(c.get('metaId') or 0), -need)
        return True

    # ---------------------------------------------------------------- 便捷构造
    @staticmethod
    def coin(n):
        return {'itemType': G.RE_COIN, 'amount': int(n)}

    @staticmethod
    def gems(n):
        return {'itemType': G.RE_GEMS, 'amount': int(n)}

    @staticmethod
    def prop(meta_id, n):
        return {'itemType': G.RE_PROP, 'metaId': int(meta_id), 'amount': int(n)}

    @staticmethod
    def card(meta_id, level=1, exp=0):
        return {'itemType': G.RE_CARD, 'metaId': int(meta_id), 'amount': 1,
                'level': int(level), 'exp': int(exp)}

    @staticmethod
    def equip(meta_id, level=1, exp=0):
        return {'itemType': G.RE_EQUIP, 'metaId': int(meta_id), 'amount': 1,
                'level': int(level), 'exp': int(exp)}
