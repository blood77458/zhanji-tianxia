#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""角色域：player / player_extend / 计数器 / 每日 / 引导步骤 / 会话与账号。"""
import json
import time


class PlayerRepo:
    def __init__(self, db):
        self.db = db

    # ============================================================ 账号
    def create_account(self, account_name=None, password_hash=None, password_salt=None,
                       email=None, device_id=None):
        now = int(time.time())
        with self.db.tx() as con:
            cur = con.execute(
                "INSERT INTO account(account_name, password_hash, password_salt, email,"
                " device_id, status, create_time, last_login_time) VALUES (?,?,?,?,?,1,?,?)",
                (account_name, password_hash, password_salt, email, device_id, now, now))
            return cur.lastrowid

    def account(self, account_id):
        return self.db.one("SELECT * FROM account WHERE account_id=?", (int(account_id),))

    def account_by_name(self, name):
        return self.db.one("SELECT * FROM account WHERE account_name=?", (name,))

    def account_by_device(self, device_id):
        return self.db.one("SELECT * FROM account WHERE device_id=?", (device_id,))

    def touch_account_login(self, account_id, ip=None):
        with self.db.tx() as con:
            con.execute("UPDATE account SET last_login_time=?, last_login_ip=? WHERE account_id=?",
                        (int(time.time()), ip, int(account_id)))

    # ---- 平台/设备绑定 ----
    def binding(self, platform_id, platform_uid):
        return self.db.one(
            "SELECT * FROM account_binding WHERE platform_id=? AND platform_uid=?",
            (platform_id, str(platform_uid)))

    def bind(self, account_id, platform_id, platform_uid, device_id=None, sid=None):
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO account_binding(account_id, platform_id, platform_uid, device_id,"
                " sid, bind_time) VALUES (?,?,?,?,?,?)"
                " ON CONFLICT(platform_id, platform_uid) DO UPDATE SET"
                " account_id=excluded.account_id, device_id=excluded.device_id,"
                " sid=excluded.sid",
                (int(account_id), platform_id, str(platform_uid), device_id, sid, now))

    def set_binding_sid(self, platform_id, platform_uid, sid):
        with self.db.tx() as con:
            con.execute("UPDATE account_binding SET sid=? WHERE platform_id=? AND platform_uid=?",
                        (sid, platform_id, str(platform_uid)))

    # ---- 会话 ----
    def create_session(self, account_id, session_key, uuid, uk, udid=None, ip=None,
                       ttl=86400 * 7):
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO auth_session(session_key, account_id, uuid, uk, udid, client_ip,"
                " create_time, expire_time, revoked) VALUES (?,?,?,?,?,?,?,?,0)",
                (session_key, int(account_id), uuid, uk, udid, ip, now, now + ttl))
        return session_key

    def session(self, session_key):
        return self.db.one("SELECT * FROM auth_session WHERE session_key=?", (session_key,))

    def revoke_session(self, session_key):
        with self.db.tx() as con:
            con.execute("UPDATE auth_session SET revoked=1 WHERE session_key=?", (session_key,))

    def touch_session(self, session_key, player_id=None):
        with self.db.tx() as con:
            if player_id is None:
                con.execute("UPDATE auth_session SET expire_time=? WHERE session_key=?",
                            (int(time.time()) + 86400 * 7, session_key))
            else:
                con.execute("UPDATE auth_session SET player_id=?, expire_time=?"
                            " WHERE session_key=?",
                            (int(player_id), int(time.time()) + 86400 * 7, session_key))

    # ============================================================ 角色
    def player(self, player_id):
        return self.db.one("SELECT * FROM player WHERE player_id=?", (int(player_id),))

    def player_by_account(self, account_id, server_id=1):
        return self.db.one("SELECT * FROM player WHERE account_id=? AND server_id=?",
                           (int(account_id), int(server_id)))

    def players_of_account(self, account_id):
        return self.db.all("SELECT * FROM player WHERE account_id=? ORDER BY server_id",
                           (int(account_id),))

    def set_nickname_taken(self, nickname, player_id):
        """昵称唯一性由 `player.nickname` 直接约束（见下），这里只是查询辅助。"""
        return self.db.one("SELECT player_id FROM player WHERE nickname=?", (nickname,))

    def create_player(self, account_id, server_id, nickname):
        now = int(time.time())
        with self.db.tx() as con:
            cur = con.execute(
                "INSERT INTO player(account_id, server_id, nickname, create_time,"
                " last_login_time, level, exp, gold, gem, free_gems, energy,"
                " energy_last_update_time, event_point, event_point_last_update_time,"
                " action_power, action_power_last_update_time, vip_level)"
                " VALUES (?,?,?,?,?,1,0,0,0,0,100,?,100,?,100,?,0)",
                (int(account_id), int(server_id), nickname, now, now, now, now, now))
            pid = cur.lastrowid
            con.execute("INSERT INTO player_extend(player_id) VALUES (?)", (pid,))
            con.execute("INSERT INTO player_mission_context(player_id) VALUES (?)", (pid,))
            con.execute("INSERT INTO player_scene_process(player_id) VALUES (?)", (pid,))
            con.execute("INSERT INTO player_secret_shop(player_id, free_times,"
                        " last_refresh_second) VALUES (?,5,?)", (pid, now))
        return pid

    def update(self, player_id, **fields):
        """按列名更新 player。只允许 schema 里真实存在的列。"""
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(player)")]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("player 表没有列 %r" % k)
            sets.append("%s=?" % k)
            args.append(v)
        args.append(int(player_id))
        with self.db.tx() as con:
            con.execute("UPDATE player SET %s WHERE player_id=?" % ', '.join(sets), args)

    def add_currency(self, player_id, column, delta):
        """原子增减一个货币列（下限 0）。返回新值。

        ⚠️ 不要在 Python 里读出来加完再写回 —— ThreadingHTTPServer 下会丢更新。
        """
        cols = {'gold', 'gem', 'free_gems', 'used_free_gems', 'recharge_gems',
                'used_recharge_gems', 'silver', 'medal_num', 'astral_essence',
                'friend_point', 'general_exp', 'vip_exp', 'energy', 'event_point',
                'action_power', 'exp', 'fight_capacity'}
        if column not in cols:
            raise KeyError("不是可增减的货币列: %r" % column)
        delta = int(delta)
        with self.db.tx() as con:
            con.execute(
                "UPDATE player SET %s = MAX(0, COALESCE(%s,0) + ?) WHERE player_id=?"
                % (column, column), (delta, int(player_id)))
            row = con.execute("SELECT %s FROM player WHERE player_id=?" % column,
                              (int(player_id),)).fetchone()
        return int(row[0]) if row else 0

    # ============================================================ 扩展
    def extend(self, player_id):
        row = self.db.one("SELECT * FROM player_extend WHERE player_id=?", (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_extend(player_id) VALUES (?)", (int(player_id),))
            row = self.db.one("SELECT * FROM player_extend WHERE player_id=?", (int(player_id),))
        return row

    def update_extend(self, player_id, **fields):
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(player_extend)")]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("player_extend 表没有列 %r" % k)
            sets.append("%s=?" % k)
            args.append(json.dumps(v, ensure_ascii=False) if isinstance(v, (dict, list)) else v)
        sets.append("updated_at=?")
        args.append(int(time.time()))
        args.append(int(player_id))
        with self.db.tx() as con:
            con.execute("UPDATE player_extend SET %s WHERE player_id=?" % ', '.join(sets), args)

    # ============================================================ 引导步骤
    def tutorial_steps(self, player_id):
        return [int(r['step']) for r in self.db.all(
            "SELECT step FROM player_tutorial_step WHERE player_id=? ORDER BY step",
            (int(player_id),))]

    def add_tutorial_step(self, player_id, step, func_name='', done=False):
        with self.db.tx() as con:
            if func_name:
                con.execute("INSERT INTO player_guide_progress(player_id,func_name,step,done_time) "
                            "VALUES (?,?,?,?) ON CONFLICT(player_id,func_name) DO UPDATE SET "
                            "step=MAX(step,excluded.step),done_time=excluded.done_time",
                            (int(player_id),str(func_name),int(step),int(time.time())))
            else:
                con.execute("INSERT OR IGNORE INTO player_tutorial_step"
                            "(player_id,step,func_name,done_time) VALUES (?,?,?,?)",
                            (int(player_id),int(step),'',int(time.time())))
            if done:
                con.execute("UPDATE player_extend SET enchant_step_reward=1 WHERE player_id=?",(int(player_id),))

    # ============================================================ 计数器
    def daily_counter(self, player_id, stat_date, key, default=0):
        return self.db.get_daily(int(player_id), int(stat_date), key, default)

    def bump_daily(self, player_id, stat_date, key, delta=1):
        return self.db.bump_daily(int(player_id), int(stat_date), key, delta)

    def counter(self, player_id, key, default=0):
        return self.db.get_counter(int(player_id), key, default)

    def bump_counter(self, player_id, key, delta=1):
        return self.db.bump_counter(int(player_id), key, delta)

    # ============================================================ 每日桶
    def daily(self, player_id, stat_date=None):
        stat_date = int(stat_date if stat_date is not None else self.db.today())
        row = self.db.one("SELECT * FROM player_daily WHERE player_id=? AND stat_date=?",
                          (int(player_id), stat_date))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT OR IGNORE INTO player_daily(player_id, stat_date)"
                            " VALUES (?,?)", (int(player_id), stat_date))
            row = self.db.one("SELECT * FROM player_daily WHERE player_id=? AND stat_date=?",
                              (int(player_id), stat_date))
        return row

    def patch_daily(self, player_id, stat_date, key, value):
        """改 player_daily.data_json / extend_json 里的一个键。"""
        row = self.daily(player_id, stat_date)
        for col in ('data_json', 'extend_json'):
            blob = json.loads(row[col] or '{}')
            if key in blob:
                blob[key] = value
                with self.db.tx() as con:
                    con.execute("UPDATE player_daily SET %s=? WHERE player_id=? AND stat_date=?"
                                % col, (json.dumps(blob, ensure_ascii=False),
                                        int(player_id), int(stat_date)))
                return True
        # 不在已知键里就塞进 data_json
        blob = json.loads(row['data_json'] or '{}')
        blob[key] = value
        with self.db.tx() as con:
            con.execute("UPDATE player_daily SET data_json=? WHERE player_id=? AND stat_date=?",
                        (json.dumps(blob, ensure_ascii=False), int(player_id), int(stat_date)))
        return True

    # ============================================================ 在线状态
    def is_online(self, player_id, window=300):
        row = self.db.one(
            "SELECT COUNT(*) AS c FROM auth_session WHERE player_id=? AND revoked=0"
            " AND expire_time > ?", (int(player_id), int(time.time()) - int(window)))
        return bool(row and row['c'])

    def last_offline_seconds(self, player_id):
        row = self.db.one("SELECT last_logout_time, last_login_time FROM player"
                          " WHERE player_id=?", (int(player_id),))
        if not row:
            return 0
        last = int(row['last_logout_time'] or row['last_login_time'] or 0)
        return max(0, int(time.time()) - last) if last else 0
