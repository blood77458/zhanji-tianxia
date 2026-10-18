#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""军团域。客户端字段级契约见 work/api_analysis/struct_union.md。

⚠️ 这一块有 4 组同名不同义的字段，组装层要逐字照抄：
   mainCardMeataId（阵型成员，原厂拼写）
     ≠ mainCardMetaId（跨服 signs / 申请者）
     ≠ mainCardId（成员 / 动态）
   userName（阵型/signs）≠ nickName（成员/申请者）≠ nickname（帝王/动态）
"""
import time


class GuildRepo:
    def __init__(self, db):
        self.db = db

    # ============================================================ 查询
    def guild(self, guild_id):
        return self.db.one("SELECT * FROM guild WHERE guild_id=?", (int(guild_id),))

    def guild_by_name(self, server_id, name):
        return self.db.one("SELECT * FROM guild WHERE server_id=? AND name=?",
                           (int(server_id), name))

    def guild_of(self, player_id):
        """当前玩家的军团行（成员字段 + 军团字段合在一起）。

        ⚠️ `guild` 表和 `guild_member` 表**都有** `cross_gvg_applied` 列，
           `g.*` 先出现，sqlite3.Row 遇到重名列会取先来的那个 —— 也就是军团的、
           不是成员的。所以这里额外给成员那份起了别名 `member_cross_gvg_applied`，
           需要成员报名状态的地方请读别名。
        """
        return self.db.one(
            "SELECT g.*, m.title AS member_title, m.contrib_total, m.contrib_week,"
            " m.contrib_day, m.status AS member_status, m.join_time, m.reactive_time,"
            " m.dissolved_time, m.last_construct_time, m.last_construct_type,"
            " m.last_active_time, m.challenge_city_id, m.coin_inspire_num,"
            " m.strive_inspire_num, m.gem_inspire_num, m.gain_war_play, m.gain_war_occupy,"
            " m.gain_war_in_battle, m.cross_gvg_applied, m.cross_gvg_quit, m.gvg_position,"
            " m.cross_gvg_applied AS member_cross_gvg_applied,"
            " m.last_wage_time"
            " FROM guild_member m JOIN guild g ON g.guild_id = m.guild_id"
            " WHERE m.player_id=? AND m.status=0", (int(player_id),))

    def guild_list(self, server_id, offset=0, limit=20):
        return self.db.all("SELECT * FROM guild WHERE server_id=? AND status=0"
                           " ORDER BY wealth DESC LIMIT ? OFFSET ?",
                           (int(server_id), int(limit), int(offset)))

    def search_guilds(self, server_id, keyword):
        return self.db.all("SELECT * FROM guild WHERE server_id=? AND status=0"
                           " AND name LIKE ? ORDER BY wealth DESC LIMIT 20",
                           (int(server_id), '%' + keyword + '%'))

    def members(self, guild_id, include_left=False):
        sql = ("SELECT m.*, p.nickname, p.level, p.fight_capacity, p.main_card_id"
               " FROM guild_member m JOIN player p ON p.player_id = m.player_id"
               " WHERE m.guild_id=?")
        if not include_left:
            sql += " AND m.status=0"
        return self.db.all(sql + " ORDER BY m.title DESC, m.contrib_total DESC", (int(guild_id),))

    def member(self, guild_id, player_id):
        return self.db.one("SELECT * FROM guild_member WHERE guild_id=? AND player_id=?",
                           (int(guild_id), int(player_id)))

    def is_in_guild(self, player_id):
        return self.db.one("SELECT 1 FROM guild_member WHERE player_id=? AND status=0",
                           (int(player_id),)) is not None

    def member_count(self, guild_id):
        row = self.db.one("SELECT COUNT(*) AS c FROM guild_member WHERE guild_id=? AND status=0",
                          (int(guild_id),))
        return int(row['c']) if row else 0

    # ============================================================ 写
    def create_guild(self, server_id, name, leader_uid, declaration="", notice="",
                     coin_type=0):
        gid = self.db.next_id('union')
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO guild(guild_id, server_id, name, declaration, notice, level,"
                " member_num, leader_uid, create_time, status) VALUES (?,?,?,?,?,1,1,?,?,0)",
                (gid, int(server_id), name, declaration, notice, int(leader_uid), now))
            con.execute(
                "INSERT INTO guild_member(guild_id, player_id, title, status, join_time)"
                " VALUES (?,?,99,0,?)", (gid, int(leader_uid), now))
        return gid

    def update_guild(self, guild_id, **fields):
        self._update('guild', 'guild_id', guild_id, fields)

    def refresh_member_num(self, guild_id):
        n = self.member_count(guild_id)
        with self.db.tx() as con:
            con.execute("UPDATE guild SET member_num=? WHERE guild_id=?", (n, int(guild_id)))
        return n

    def add_member(self, guild_id, player_id, title=0):
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO guild_member(guild_id, player_id, title, status, join_time,"
                " reactive_time) VALUES (?,?,?,0,?,0)"
                " ON CONFLICT(guild_id, player_id) DO UPDATE SET status=0, title=excluded.title,"
                " join_time=excluded.join_time",
                (int(guild_id), int(player_id), int(title), now))
        self.refresh_member_num(guild_id)

    def set_member_status(self, guild_id, player_id, status):
        with self.db.tx() as con:
            con.execute("UPDATE guild_member SET status=?, dissolved_time=? WHERE guild_id=?"
                        " AND player_id=?",
                        (int(status), int(time.time()), int(guild_id), int(player_id)))
        self.refresh_member_num(guild_id)

    def update_member(self, guild_id, player_id, **fields):
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(guild_member)")]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("guild_member 表没有列 %r" % k)
            sets.append("%s=?" % k)
            args.append(int(v) if isinstance(v, bool) else v)
        args += [int(guild_id), int(player_id)]
        with self.db.tx() as con:
            con.execute("UPDATE guild_member SET %s WHERE guild_id=? AND player_id=?"
                        % ', '.join(sets), args)

    def add_contribution(self, guild_id, player_id, amount):
        with self.db.tx() as con:
            con.execute("UPDATE guild_member SET contrib_total = contrib_total + ?,"
                        " contrib_week = contrib_week + ?, contrib_day = contrib_day + ?"
                        " WHERE guild_id=? AND player_id=?",
                        (int(amount), int(amount), int(amount), int(guild_id), int(player_id)))
            con.execute("UPDATE guild SET wealth = MAX(0, wealth + ?) WHERE guild_id=?",
                        (int(amount), int(guild_id)))

    # ---- 申请 ----
    def appliers(self, guild_id):
        return self.db.all(
            "SELECT a.*, p.nickname, p.level, p.fight_capacity, p.main_card_id"
            " FROM guild_apply a JOIN player p ON p.player_id = a.player_id"
            " WHERE a.guild_id=? AND a.status=0 ORDER BY a.apply_time", (int(guild_id),))

    def apply(self, guild_id, player_id):
        with self.db.tx() as con:
            con.execute("INSERT INTO guild_apply(guild_id, player_id, status, apply_time)"
                        " VALUES (?,?,0,?) ON CONFLICT(guild_id, player_id)"
                        " DO UPDATE SET status=0, apply_time=excluded.apply_time",
                        (int(guild_id), int(player_id), int(time.time())))

    def set_apply_status(self, guild_id, player_id, status):
        with self.db.tx() as con:
            con.execute("UPDATE guild_apply SET status=?, handle_time=? WHERE guild_id=?"
                        " AND player_id=?",
                        (int(status), int(time.time()), int(guild_id), int(player_id)))

    def my_applies(self, player_id):
        return self.db.all(
            "SELECT a.*, g.name, g.level, g.member_num FROM guild_apply a"
            " JOIN guild g ON g.guild_id = a.guild_id"
            " WHERE a.player_id=? AND a.status=0 ORDER BY a.apply_time DESC", (int(player_id),))

    # ---- 建筑 / 动态 / 斗兽 ----
    def buildings(self, guild_id):
        return self.db.all("SELECT * FROM guild_building WHERE guild_id=?", (int(guild_id),))

    def building(self, guild_id, building_id):
        row = self.db.one("SELECT * FROM guild_building WHERE guild_id=? AND building_id=?",
                          (int(guild_id), int(building_id)))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO guild_building(guild_id, building_id, level)"
                            " VALUES (?,?,1)", (int(guild_id), int(building_id)))
            row = self.db.one("SELECT * FROM guild_building WHERE guild_id=? AND building_id=?",
                              (int(guild_id), int(building_id)))
        return row

    def news(self, guild_id, news_type=None, limit=20):
        if news_type is None:
            return self.db.all("SELECT * FROM guild_news WHERE guild_id=?"
                               " ORDER BY create_time DESC LIMIT ?", (int(guild_id), int(limit)))
        return self.db.all("SELECT * FROM guild_news WHERE guild_id=? AND news_type=?"
                           " ORDER BY create_time DESC LIMIT ?",
                           (int(guild_id), int(news_type), int(limit)))

    def add_news(self, guild_id, news_type, event_type, actor_uid=0, actor_name="",
                 actor_level=0, actor_main_card_id=0, content="{}"):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO guild_news(guild_id, news_type, event_type, actor_uid, actor_name,"
                " actor_level, actor_main_card_id, content, create_time)"
                " VALUES (?,?,?,?,?,?,?,?,?)",
                (int(guild_id), int(news_type), int(event_type), int(actor_uid), actor_name,
                 int(actor_level), int(actor_main_card_id), content, int(time.time())))

    def monster(self, guild_id):
        row = self.db.one("SELECT * FROM guild_monster WHERE guild_id=?", (int(guild_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO guild_monster(guild_id) VALUES (?)", (int(guild_id),))
            row = self.db.one("SELECT * FROM guild_monster WHERE guild_id=?", (int(guild_id),))
        return row

    def update_monster(self, guild_id, **fields):
        self.monster(guild_id)
        self._update('guild_monster', 'guild_id', guild_id, fields)

    # ---- 军团战 ----
    def cities(self, server_id):
        return self.db.all("SELECT * FROM guild_city WHERE server_id=?", (int(server_id),))

    def city(self, city_id):
        return self.db.one("SELECT * FROM guild_city WHERE city_id=?", (int(city_id),))

    def city_applies(self, city_id):
        return self.db.all(
            "SELECT a.*, g.name AS union_name, g.level AS union_level FROM guild_city_apply a"
            " JOIN guild g ON g.guild_id = a.guild_id WHERE a.city_id=?"
            " ORDER BY a.bid_wealth DESC", (int(city_id),))

    def apply_city(self, city_id, guild_id, bid_wealth=0, apply_type=0):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO guild_city_apply(city_id, guild_id, apply_type, bid_wealth,"
                " apply_time) VALUES (?,?,?,?,?)"
                " ON CONFLICT(city_id, guild_id) DO UPDATE SET"
                " bid_wealth=excluded.bid_wealth, apply_time=excluded.apply_time",
                (int(city_id), int(guild_id), int(apply_type), int(bid_wealth),
                 int(time.time())))

    def add_score(self, guild_id, score_type, round_no, delta):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO guild_score(guild_id, score_type, round, score, update_time)"
                " VALUES (?,?,?,?,?) ON CONFLICT(guild_id, score_type, round)"
                " DO UPDATE SET score = score + excluded.score, update_time=excluded.update_time",
                (int(guild_id), score_type, int(round_no), int(delta), int(time.time())))

    # ---- 内部 ----
    def _update(self, table, key, where_val, fields):
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(%s)" % table)]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("%s 表没有列 %r" % (table, k))
            sets.append("%s=?" % k)
            args.append(int(v) if isinstance(v, bool) else v)
        args.append(int(where_val))
        with self.db.tx() as con:
            con.execute("UPDATE %s SET %s WHERE %s=?" % (table, ', '.join(sets), key), args)
