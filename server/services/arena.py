#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""竞技场 / PK。

配置数据完整：arena_rank_reward(11档名次奖励) / arena_rank_score / arena_score_exchange(3档兑换)。
名次用真实排行（arena_rank 表按 score 排序）而不是打桩。
"""
import random
import time

import gamedata as G
import luaconf

OK = 200
E_NOT_ENOUGH = 710513


def rows(name):
    return [r for r in luaconf.as_list(luaconf.load(name)) if isinstance(r, dict)]


class ArenaService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos
        self.act = ctx.activity

    # ---------------------------------------------------------------- 排行
    def ensure_row(self, pid, server_id=1):
        with self.db.tx() as con:
            con.execute("INSERT INTO arena_rank(player_id, server_id, score) VALUES (?,?,0)"
                        " ON CONFLICT(player_id) DO NOTHING", (int(pid), int(server_id)))
        return self.db.one("SELECT * FROM arena_rank WHERE player_id=?", (int(pid),))

    def rank_of(self, pid):
        row = self.ensure_row(pid)
        c = self.db.one("SELECT COUNT(*) AS c FROM arena_rank WHERE server_id=? AND (score > ? OR (score = ? AND player_id < ?))",
                        (int(row['server_id']), int(row['score']), int(row['score']), int(pid)))
        return int(c['c']) + 1

    def top(self, server_id=1, limit=20):
        return self.db.all(
            "SELECT a.*, p.nickname, p.level, p.fight_capacity, p.main_card_id"
            " FROM arena_rank a JOIN player p ON p.player_id = a.player_id"
            " WHERE a.server_id=? ORDER BY a.score DESC LIMIT ?",
            (int(server_id), int(limit)))

    # ---------------------------------------------------------------- 匹配
    def matched_players(self, pid):
        """getArenaMatchedPlayers → pkUserInfos[]。

        客户端读 userinfo1/userinfo2 之类字段，给结构完整的空列表也不会崩，
        但给真实对手体验更好：取分数附近的玩家，凑不满就用 NPC 补。
        """
        row = self.ensure_row(pid)
        score = int(row['score'])
        others = self.db.all(
            "SELECT a.player_id, a.score, p.nickname, p.level, p.fight_capacity,"
            " p.main_card_id FROM arena_rank a JOIN player p ON p.player_id=a.player_id"
            " WHERE a.server_id=? AND a.player_id<>? ORDER BY ABS(a.score-?) LIMIT 4",
            (int(row['server_id']), int(pid), score))
        out = []
        for i, o in enumerate(others, 1):
            out.append({
                'uid': int(o['player_id']),
                'nickName': o['nickname'] or '',
                'level': int(o['level'] or 1),
                'fightCapacity': int(o['fight_capacity'] or 0),
                'mainCardId': int(o['main_card_id'] or 0),
                'arenaScore': int(o['score']),
                'rank': self.rank_of(int(o['player_id'])),
            })
        # 补 NPC
        while len(out) < 4:
            n = len(out) + 1
            out.append({
                'uid': -n,
                'nickName': '竞技场守卫%d' % n,
                'level': max(1, int(self.r.player.player(pid)['level']) + n - 1),
                'fightCapacity': 0,
                'mainCardId': 0,
                'arenaScore': max(0, score - n * 20),
                'rank': 0,
            })
        me = self.r.player.player(pid)
        my_rank = self.rank_of(pid)
        for i, item in enumerate(out, 1):
            card = self.r.asset.card(item['uid'], item['mainCardId']) if item['uid'] > 0 else None
            item['mainCardMetaId'] = int(card['meta_id']) if card else G.STARTER_CARD_META
            if item['rank'] <= 0:
                item['rank'] = my_rank + i
        card = self.r.asset.card(pid, me['main_card_id'])
        players = out + [{'uid': str(pid), 'nickName': me['nickname'],
            'level': int(me['level']), 'rank': my_rank, 'mainCardMetaId': int(card['meta_id']) if card else G.STARTER_CARD_META}]
        for item in players:
            item['uid'] = str(item['uid'])
        today = self.db.today()
        return OK, {'pkUserInfos': out, 'myRank': my_rank, 'myScore': score,
            'sharkArenaPlayers': players, 'sharkArenaReports': [], 'foes': [],
            'sharkArenaRankReward': [{'rank': int(r['reward_id'])} for r in self.db.all("SELECT reward_id FROM player_activity_reward_claim WHERE player_id=? AND scope='arena_first_rank'", (pid,))], 'sharkArenaRank': {'rank': my_rank, 'score': score, 'bestRank': my_rank},
            'arenaChallengeNum': self.r.player.daily_counter(pid, today, 'arena_challenge_num'),
            'arenaBoughtNum': self.r.player.daily_counter(pid, today, 'arena_buy_num')}

    # ---------------------------------------------------------------- 挑战
    def challenge(self, pid, target_uid=None, revenge=False):
        """打一场。赢则加分、输则减分（下限 0）。"""
        row = self.ensure_row(pid)
        win = True                      # 打桩：与原服务端一致，玩家必胜
        delta = 10
        new_score = max(0, int(row['score']) + (delta if win else -delta // 2))
        with self.db.tx() as con:
            con.execute("UPDATE arena_rank SET score=?, win_count=win_count+?,"
                        " lose_count=lose_count+? WHERE player_id=?",
                        (new_score, 1 if win else 0, 0 if win else 1, int(pid)))
            con.execute("INSERT INTO pk_record(server_id, attacker_uid, defender_uid, win,"
                        " create_time) VALUES (?,?,?,?,?)",
                        (int(row['server_id']), int(pid), int(target_uid or 0),
                         1 if win else 0, int(time.time())))
        pack = G.build_battle_response(100101, 3)
        pack.update({
            'win': win,
            'whetherWin': win,
            'arenaScore': new_score,
            'addScore': delta if win else 0,
            'myRank': self.rank_of(pid),
            'reward': {'itemType': G.RE_GEMS, 'amount': 10},
            'rewards': [{'itemType': G.RE_GEMS, 'amount': 10}],
            'itemType': G.RE_GEMS,
            'metaId': 0,
            'amount': 10,
            'retCode': 200,
        })
        return OK, pack

    # ---------------------------------------------------------------- 奖励
    def _rank_reward_rows(self):
        if not hasattr(self, '_rr'):
            self._rr = sorted(rows('arena_rank_reward'), key=lambda r: -int(r.get('rank') or 0))
        return self._rr

    def gain_score_by_rank(self, pid):
        """按名次领奖。arena_rank_reward 是「rank=门槛名次」的升档表。"""
        my_rank = self.rank_of(pid)
        cfg = next((r for r in rows('arena_rank_score')
            if int(r['startRank']) <= my_rank and
            (int(r['endRank']) == -1 or my_rank <= int(r['endRank']))), None)
        amount = int(cfg['score']) if cfg else 0
        got, applied = self.act.claim_once(pid, 'arena_daily_score', int(self.db.today()),
            [self.act.spec(G.RE_ARENA_SCORE, 0, amount)], reason='arenaDailyScore')
        reward = applied[0] if got and applied else {'itemType': G.RE_ARENA_SCORE, 'metaId': 0, 'amount': 0}
        return OK, {'reward': reward, 'rewards': applied}

    def score_exchange(self, pid):
        return OK, {'exchangeItems': [
            {'id': int(r['id']), 'score': int(r.get('score') or 0),
             'itemType': int(r.get('itemType') or G.RE_PROP),
             'metaId': int(r.get('itemMetaId') or 0),
             'amount': int(r.get('amount') or 0),
             'gained': self.act.has_claimed(pid, 'arena_exchange', int(r['id']))}
            for r in rows('arena_score_exchange')]}

    def exchange_train_dan(self, pid, exchange_type=0):
        row = self.ensure_row(pid)
        items = rows('arena_score_exchange')
        if not items:
            return OK, {'rewards': []}
        it = items[min(max(int(exchange_type or 1) - 1, 0), len(items) - 1)]
        need = int(it.get('score') or 0)
        if int(row['score']) < need:
            return E_NOT_ENOUGH, None
        with self.db.tx() as con:
            con.execute("UPDATE arena_rank SET score = score - ? WHERE player_id=?",
                        (need, int(pid)))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(int(it.get('itemType') or G.RE_PROP),
                                int(it.get('itemMetaId') or 0),
                                int(it.get('amount') or 0))],
            record=True, reason='arenaExchange')
        return OK, {'rewards': applied, 'requisite': self.act.spec(G.RE_ARENA_SCORE, 0, need)}

    def buy_challenge_num(self, pid):
        cost = 50
        if self.ctx.player.spend_gems(pid, cost) is None:
            return E_NOT_ENOUGH, None
        today = self.db.today()
        n = self.r.player.bump_daily(pid, today, 'arena_buy_num')
        return OK, {'challengeNum': 5 + n,
                    'requisite': self.act.spec(G.RE_GEMS, 0, cost)}

    # ---------------------------------------------------------------- PK（跨服竞技）
    def pk_info(self, pid):
        row = self.ensure_row(pid)
        return OK, {'pkScore': int(row['score']), 'pkRank': self.rank_of(pid),
                    'pkFoes': [], 'buffId': 0}

    def pk_foes(self, pid):
        code, payload = self.matched_players(pid)
        return OK, {'pkFoes': payload.get('pkUserInfos') or []}

    def pk_top_rank(self, pid):
        out = []
        for i, r in enumerate(self.top(limit=10), 1):
            out.append({'uid': int(r['player_id']), 'nickName': r['nickname'] or '',
                        'level': int(r['level'] or 1), 'score': int(r['score']),
                        'rank': i, 'unionName': ''})
        return OK, {'pkTopRankUsers': out}

    def gain_pk_buff(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, 'pk_buff', int(self.db.today()),
            [self.act.spec(G.RE_GEMS, 0, 30)], reason='pkBuff')
        return OK, {'rewards': applied}

    def gain_pk_rewards(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, 'pk_reward', int(self.db.today()),
            [self.act.spec(G.RE_GEMS, 0, 50)], reason='pkReward')
        return OK, {'rewards': applied}
