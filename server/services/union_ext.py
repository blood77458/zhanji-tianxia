#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""军团玩法补充：商店 / 建筑 / 斗兽场 / 申请审批 / 城池。

配置齐全：union_shop_normal(21) / union_shop_special(76) / union_building_hall /
bank / shop / colosseum / union_boss_meta / union_career。
"""
import time

import gamedata as G
import luaconf

OK = 200
E_NOT_ENOUGH = 710513
E_NO_UNION = 716301
E_ALREADY = 716300
E_NOT_APPLY = 710001
E_PARAM = 710003            # 参数错误（uid 不存在等）


def rows(name):
    return [r for r in luaconf.as_list(luaconf.load(name)) if isinstance(r, dict)]


class UnionService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos
        self.g = ctx.repos.guild
        self.act = ctx.activity

    # ---------------------------------------------------------------- 前置
    def my(self, pid):
        return self.g.guild_of(int(pid))

    def require(self, pid):
        g = self.my(pid)
        if not g:
            raise _No('E_NO_UNION')
        return g

    # ---------------------------------------------------------------- 商店
    SHOP_NORMAL = 1
    SHOP_SPECIAL = 2

    def _shop_rows(self, shop_type):
        name = 'union_shop_special' if int(shop_type) == self.SHOP_SPECIAL else 'union_shop_normal'
        return rows(name)

    def building_shop_info(self, pid):
        g = self.my(pid)
        if not g:
            return {'sharkUnionBuildingWrapper': None, 'specialProps': [],
                    'specialShopRecord': [], 'donateAnnouncement': []}
        gid = int(g['guild_id'])
        records = {(int(r['shop_type']), int(r['prop_id'])): int(r['bought_num'])
                   for r in self.db.all("SELECT * FROM guild_shop_record WHERE guild_id=?",
                                        (gid,))}
        special = []
        for r in self._shop_rows(self.SHOP_SPECIAL):
            pid_ = int(r.get('id') or 0)
            limit = int(r.get('dailyPurchaseLimit') or r.get('limit') or 1)
            bought = records.get((self.SHOP_SPECIAL, pid_), 0)
            special.append({
                'id': pid_,
                'itemType': int(r.get('itemType') or G.RE_PROP),
                'metaId': int(r.get('metaId') or 0),
                'amount': int(r.get('amount') or 1),
                'price': int(r.get('price') or r.get('cost') or 0),
                'moneyType': int(r.get('moneyType') or G.RE_GEMS),
                # leftNum 是算出来的，不落库
                'leftNum': max(0, limit - bought),
                'specialShopRecord': bought,
            })
        normal = [{
            'id': int(r.get('id') or 0),
            'itemType': int(r.get('itemType') or G.RE_PROP),
            'metaId': int(r.get('metaId') or 0),
            'amount': int(r.get('amount') or 1),
            'price': int(r.get('price') or 0),
            'moneyType': int(r.get('moneyType') or G.RE_GEMS),
        } for r in self._shop_rows(self.SHOP_NORMAL)]
        b = self.g.building(gid, 2)     # 2 = 商城
        donate = [{'nickname': r['nickname'], 'donateNum': int(r['donate_num'])}
                  for r in self.db.all("SELECT * FROM guild_donate_log WHERE guild_id=?"
                                       " ORDER BY create_time DESC LIMIT 10", (gid,))]
        return {
            'sharkUnionBuildingWrapper': _building_payload(b),
            'specialProps': special,
            'normalProps': normal,
            'specialShopRecord': [{'propId': k[1], 'boughtNum': v}
                                  for k, v in records.items() if k[0] == self.SHOP_SPECIAL],
            'donateAnnouncement': donate,
        }

    def buy_union_prop(self, pid, prop_id, shop_type=SHOP_SPECIAL):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        pid_ = int(prop_id or 0)
        row = next((r for r in self._shop_rows(shop_type)
                    if int(r.get('id') or 0) == pid_), None)
        if not row:
            return OK, {'rewards': []}
        limit = int(row.get('dailyPurchaseLimit') or row.get('limit') or 1)
        rec = self.db.one("SELECT * FROM guild_shop_record WHERE guild_id=? AND shop_type=?"
                          " AND prop_id=?", (gid, int(shop_type), pid_))
        bought = int(rec['bought_num']) if rec else 0
        if bought >= limit:
            return E_NOT_ENOUGH, None
        price = int(row.get('price') or row.get('cost') or 0)
        money = int(row.get('moneyType') or G.RE_GEMS)
        if money == G.RE_GEMS:
            if self.ctx.player.spend_gems(pid, price) is None:
                return E_NOT_ENOUGH, None
        else:
            if int(self.r.player.player(pid)['gold']) < price:
                return E_NOT_ENOUGH, None
            self.r.player.add_currency(pid, 'gold', -price)
        with self.db.tx() as con:
            con.execute("INSERT INTO guild_shop_record(guild_id, shop_type, prop_id, bought_num)"
                        " VALUES (?,?,?,1) ON CONFLICT(guild_id, shop_type, prop_id)"
                        " DO UPDATE SET bought_num = bought_num + 1",
                        (gid, int(shop_type), pid_))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(int(row.get('itemType') or G.RE_PROP),
                                int(row.get('metaId') or 0),
                                int(row.get('amount') or 1))],
            record=True, reason='unionShop')
        return OK, {'rewards': applied}

    # ---------------------------------------------------------------- 建筑
    def _building_conf(self, building_id):
        name = {1: 'union_building_hall', 2: 'union_building_shop',
                3: 'union_building_bank', 4: 'union_building_colosseum'}.get(int(building_id))
        if not name:
            return []
        return rows(name)

    def building_info(self, pid, building_id):
        g = self.my(pid)
        if not g:
            return {'sharkUnionBuildingWrapper': None, 'donateAnnouncement': []}
        gid = int(g['guild_id'])
        b = self.g.building(gid, int(building_id))
        out = {
            'sharkUnionBuildingWrapper': _building_payload(b),
            'donateAnnouncement': [
                {'nickname': r['nickname'], 'donateNum': int(r['donate_num'])}
                for r in self.db.all("SELECT * FROM guild_donate_log WHERE guild_id=?"
                                     " ORDER BY create_time DESC LIMIT 10", (gid,))],
            'constructTimesToday': int(b['construct_times_today']),
            'lastestConstructSeconds': int(b['last_construct_seconds']),
        }
        if int(building_id) == 4:       # 斗兽场
            m = self.g.monster(gid)
            out['sharkUnionMonster'] = _monster_payload(m)
            out['summonTimes'] = int(m['summon_times'])
        return out

    def construct(self, pid, building_id=1, construct_type=1, coin_type=0, amount=0):
        """建设：消耗货币换财富+贡献。"""
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        b = self.g.building(gid, int(building_id))
        conf = self._building_conf(building_id)
        lv = int(b['level'])
        row = next((r for r in conf if int(r.get('level') or 0) == lv), None) or \
            (conf[0] if conf else {})
        cost = int(row.get('cost') or row.get('silverCost') or 1000)
        wealth = int(row.get('wealth') or row.get('addWealth') or cost)
        contrib = int(row.get('contribution') or row.get('addContribution') or 10)
        if int(coin_type) == G.RE_GEMS:
            if self.ctx.player.spend_gems(pid, cost) is None:
                return E_NOT_ENOUGH, None
        else:
            if int(self.r.player.player(pid)['gold']) < cost:
                return E_NOT_ENOUGH, None
            self.r.player.add_currency(pid, 'gold', -cost)
        self.g.add_contribution(gid, pid, contrib)
        now = int(time.time())
        with self.db.tx() as con:
            con.execute("UPDATE guild_building SET construct_times_today ="
                        " construct_times_today + 1, last_construct_seconds=?"
                        " WHERE guild_id=? AND building_id=?", (now, gid, int(building_id)))
        self.g.update_member(gid, pid, last_construct_time=now,
                             last_construct_type=int(construct_type or 1))
        with self.db.tx() as con:
            con.execute("INSERT INTO guild_donate_log(guild_id, building_id, player_id,"
                        " nickname, donate_num, create_time) VALUES (?,?,?,?,?,?)",
                        (gid, int(building_id), int(pid),
                         self.r.player.player(pid)['nickname'] or '', wealth, now))
        self.g.update_guild(gid, wealth=int(g['wealth']) + wealth)
        return OK, self.building_info(pid, building_id)

    def upgrade_building(self, pid, building_id=1):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        if int(g['member_title'] or 0) < 90:      # 只有团长/副团能升
            return E_NOT_ENOUGH, None
        gid = int(g['guild_id'])
        cost = 5000
        if int(g['wealth']) < cost:
            return E_NOT_ENOUGH, None
        self.g.update_guild(gid, wealth=int(g['wealth']) - cost)
        with self.db.tx() as con:
            con.execute("UPDATE guild_building SET level = level + 1"
                        " WHERE guild_id=? AND building_id=?", (gid, int(building_id)))
        if int(building_id) == 1:                 # 大厅等级同步到 guild.level
            self.g.update_guild(gid, level=int(g['level']) + 1)
        return OK, self.building_info(pid, building_id)

    # 职务 → 日工资。title 是**枚举**（99团长/90副团/10精英/0成员），
    # 不是倍数 —— 早期版本拿它当乘数，算出来的工资根本领不起。
    WAGE_BY_TITLE = [(90, 2000), (10, 1500), (0, 1000)]

    def receive_wage(self, pid):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        g = dict(g)                     # sqlite3.Row 没有 .get()
        gid = int(g['guild_id'])
        title = int(g.get('member_title') or 0)
        wage = 1000
        for min_title, amount in self.WAGE_BY_TITLE:
            if title >= min_title:
                wage = amount
                break
        today = self.ctx.db.today()
        if int(g.get('last_wage_time') or 0) >= today:
            return E_NOT_ENOUGH, None   # 今天已经领过
        if int(g['wealth']) < wage:
            return E_NOT_ENOUGH, None
        self.g.update_guild(gid, wealth=int(g['wealth']) - wage)
        self.g.update_member(gid, pid, last_wage_time=int(time.time()))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, wage)], record=True, reason='unionWage')
        return OK, {'rewards': applied}

    # ---------------------------------------------------------------- 斗兽场
    def summon_monster(self, pid, monster_meta_id=0, summon_type=0):
        """⚠️ 响应里必须带 sharkUnionMonster（客户端 summonUnionMonster 无 nil 保护）。"""
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        meta = rows('union_boss_meta')
        hp = int((meta[0] if meta else {}).get('hp') or 1000000)
        now = int(time.time())
        self.g.update_monster(gid, monster_id=int(monster_meta_id or (meta[0].get('id') if meta else 1)),
                              monster_left_hp=hp,
                              escape_seconds=now + 3600,
                              summon_times=int(self.g.monster(gid)['summon_times']) + 1,
                              summon_user_uid=int(pid),
                              summon_user_nickname=self.r.player.player(pid)['nickname'] or '',
                              reward_distributed=0, refresh_time=now)
        m = self.g.monster(gid)
        return OK, {'sharkUnionMonster': _monster_payload(m),
                    'summonTimes': int(m['summon_times'])}

    def challenge_union_monster(self, pid, params=None):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        m = self.g.monster(gid)
        if int(m['monster_left_hp']) <= 0:
            return OK, {'win': False, 'bossHp': 0}
        dmg = 50000
        left = max(0, int(m['monster_left_hp']) - dmg)
        self.g.update_monster(gid, monster_left_hp=left)
        with self.db.tx() as con:
            con.execute("INSERT INTO guild_monster_damage(guild_id, monster_id, player_id,"
                        " nick_name, total_damage) VALUES (?,?,?,?,?)"
                        " ON CONFLICT(guild_id, monster_id, player_id)"
                        " DO UPDATE SET total_damage = total_damage + excluded.total_damage",
                        (gid, int(m['monster_id']), int(pid),
                         self.r.player.player(pid)['nickname'] or '', dmg))
        pack = G.build_battle_response(100101, 1)
        pack.update({'win': True, 'bossHp': left, 'bossHpMax': left + dmg,
                     'sharkUnionMonster': _monster_payload(self.g.monster(gid))})
        return OK, pack

    def monster_rank(self, pid):
        g = self.my(pid)
        if not g:
            return OK, {'rankList': []}
        rows_ = self.db.all("SELECT * FROM guild_monster_damage WHERE guild_id=?"
                            " ORDER BY total_damage DESC LIMIT 20", (int(g['guild_id']),))
        return OK, {'rankList': [
            {'uid': int(r['player_id']), 'nickName': r['nick_name'],
             'damage': int(r['total_damage']), 'rank': i}
            for i, r in enumerate(rows_, 1)]}

    def monster_reward_distribute(self, pid, begin=True):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        if int(g['member_title'] or 0) < 90:
            return E_NOT_ENOUGH, None
        if begin:
            self.g.update_monster(gid, distributing_uid=int(pid), reward_distributed=0)
        else:
            self.g.update_monster(gid, distributing_uid=0, reward_distributed=1)
        m = self.g.monster(gid)
        return OK, {'sharkUnionMonster': _monster_payload(m),
                    'canDistributeMonsterReward': True,
                    'currMonsterRewards': []}

    # ---------------------------------------------------------------- 申请 / 审批
    def apply(self, pid, union_id):
        if self.g.is_in_guild(pid):
            return E_ALREADY, None
        g = self.g.guild(union_id)
        if not g:
            return E_NO_UNION, None
        self.g.apply(int(union_id), int(pid))
        return OK, {}

    def cancel_apply(self, pid, union_id):
        self.g.set_apply_status(int(union_id), int(pid), 3)
        return OK, {}

    def applier_list(self, pid):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        out = []
        for r in self.g.appliers(int(g['guild_id'])):
            card = self.db.one("SELECT meta_id FROM player_card WHERE card_id=?",
                               (int(r['main_card_id'] or 0),))
            out.append({
                'uid': int(r['player_id']),
                'nickName': r['nickname'] or '',
                'level': int(r['level'] or 1),
                'mainCardMetaId': int(card['meta_id']) if card else 0,
                'fightCapacity': int(r['fight_capacity'] or 0),
                'arenaRank': 0,
            })
        return OK, {'sharkUnionAppliers': out}

    def accept(self, pid, applier_uid):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        if int(g['member_title'] or 0) < 90:
            return E_NOT_ENOUGH, None
        gid = int(g['guild_id'])
        uid = int(applier_uid or 0)
        # ⚠️ uid 不存在时直接 add_member 会撞 FOREIGN KEY 约束抛异常 → 客户端
        #    看到「点同意就报错」。先校验，走业务错误码。
        if uid <= 0 or self.r.player.player(uid) is None:
            return E_PARAM, None
        self.g.set_apply_status(gid, uid, 1)
        self.g.add_member(gid, uid, title=0)
        self.g.add_news(gid, 1, 2, actor_uid=uid,
                        actor_name=(self.r.player.player(uid) or {}).get('nickname') or '')
        return OK, {}

    def reject(self, pid, applier_uid):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        self.g.set_apply_status(int(g['guild_id']), int(applier_uid), 2)
        return OK, {}

    def quit(self, pid):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        gid = int(g['guild_id'])
        if int(g['leader_uid']) == int(pid):
            return E_NOT_ENOUGH, None       # 团长不能直接退，要先转让
        self.g.set_member_status(gid, pid, 1)
        return OK, {}

    def modify(self, pid, declaration=None, notice=None):
        g = self.my(pid)
        if not g:
            return E_NO_UNION, None
        if int(g['member_title'] or 0) < 90:
            return E_NOT_ENOUGH, None
        kw = {}
        if declaration is not None:
            kw['declaration'] = str(declaration)
        if notice is not None:
            kw['notice'] = str(notice)
        if kw:
            self.g.update_guild(int(g['guild_id']), **kw)
        return OK, {}

    def search(self, pid, keyword):
        p = self.r.player.player(pid)
        return OK, {'sharkUnionWrappers': [
            {'unionId': int(r['guild_id']), 'name': r['name'], 'level': int(r['level']),
             'memberNum': int(r['member_num']), 'wealth': int(r['wealth']),
             'rank': int(r['rank']), 'declaration': r['declaration'] or ''}
            for r in self.g.search_guilds(int(p['server_id']), str(keyword or ''))]}


class _No(Exception):
    pass


def _building_payload(b):
    return {'buildingId': int(b['building_id']), 'level': int(b['level']),
            'constructTimesToday': int(b['construct_times_today']),
            'lastestConstructSeconds': int(b['last_construct_seconds'])}


def _monster_payload(m):
    """⚠️ reward 必须是**对象**且含 amount（客户端取 .reward.amount 做减法）。"""
    return {
        'monsterId': int(m['monster_id']),
        'monsterLeftHp': int(m['monster_left_hp']),
        'escapeSeconds': int(m['escape_seconds']),
        'summonUserNickname': m['summon_user_nickname'] or '',
        'rewardDouble': bool(m['reward_double']),
        'distributingUid': int(m['distributing_uid']),
        'rewardDistributed': bool(m['reward_distributed']),
        'reward': {'amount': int(m['reward_amount'])},
    }
