#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""数据库连接与通用辅助。

用法：
    from db import Database
    db = Database("canon.db")
    db.init_schema()
    with db.tx() as con:
        ...

设计要点
--------
* WAL 模式 + busy_timeout：ThreadingHTTPServer 下多线程共用一个连接池，
  没有 WAL 会频繁 database is locked。
* `tx()` 是真事务上下文：异常回滚。原服务端靠一把 RLock + 全量 JSON 覆写，
  换成关系库后必须显式用事务，否则「扣道具 + 发卡」这类复合操作会半途生效。
* id 分配走 `next_id()`，内部用 `UPDATE ... RETURNING`（SQLite 3.35+）保证原子。
"""
import os
import sqlite3
import threading
import time

SCHEMA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'schema.sql')


class Database:
    def __init__(self, path="canon.db"):
        self.path = path
        self._local = threading.local()
        self._write_lock = threading.RLock()

    # ---------------------------------------------------------------- 连接
    def connect(self):
        con = sqlite3.connect(self.path, timeout=15, isolation_level=None)
        con.row_factory = sqlite3.Row
        con.execute("PRAGMA journal_mode=WAL")
        con.execute("PRAGMA synchronous=NORMAL")
        con.execute("PRAGMA foreign_keys=ON")
        con.execute("PRAGMA busy_timeout=15000")
        return con

    @property
    def con(self):
        """每线程一个连接（sqlite3 连接不可跨线程共享）。"""
        c = getattr(self._local, 'con', None)
        if c is None:
            c = self.connect()
            self._local.con = c
        return c

    def close(self):
        c = getattr(self._local, 'con', None)
        if c is not None:
            c.close()
            self._local.con = None

    def is_initialized(self):
        """库是否已经建过表（用于让 init_schema 幂等）。"""
        try:
            row = self.one("SELECT COUNT(*) AS c FROM sqlite_master"
                           " WHERE type='table' AND name='player'")
        except sqlite3.Error:
            return False
        return bool(row and row['c'])

    def init_schema(self, force=False):
        """执行 schema.sql。已建过表时默认跳过（幂等）。返回是否真的执行了。"""
        if not force and self.is_initialized():
            return False
        with open(SCHEMA_PATH, encoding='utf-8') as f:
            self.con.executescript(f.read())
        return True

    # ------------------------------------------------------------- 迁移
    # (表, 列, 列定义)。老库缺列时补上；SQLite 的 ADD COLUMN 是 O(1)。
    MIGRATIONS = [
        ('player_mission_complete', 'complete_count', "INTEGER NOT NULL DEFAULT 1"),
        # 客户端 canonUtils.IsGuideExecuted 读 tutorialSteps[i].funcName，
        # 旧库只有 step -> 回包是数字数组 -> 客户端 SIGKILL。
        ('player_tutorial_step', 'func_name', "TEXT NOT NULL DEFAULT ''"),
    ]

    def migrate(self):
        """幂等补列，返回实际执行的迁移列表。"""
        done = []
        if not self.is_initialized():
            return done
        for table, col, decl in self.MIGRATIONS:
            try:
                have = {r['name'] for r in self.all("PRAGMA table_info(%s)" % table)}
            except sqlite3.Error:
                continue
            if not have or col in have:
                continue
            try:
                with self.tx() as con:
                    con.execute("ALTER TABLE %s ADD COLUMN %s %s" % (table, col, decl))
                done.append('%s.%s' % (table, col))
            except sqlite3.Error:
                pass
        with self.tx() as con:
            con.execute("CREATE TABLE IF NOT EXISTS player_guide_progress ("
                        "player_id INTEGER NOT NULL REFERENCES player(player_id) ON DELETE CASCADE, "
                        "func_name TEXT NOT NULL, step INTEGER NOT NULL, done_time INTEGER NOT NULL, "
                        "PRIMARY KEY(player_id,func_name))")
            con.execute("INSERT OR IGNORE INTO player_guide_progress(player_id,func_name,step,done_time) "
                        "SELECT player_id,func_name,step,done_time FROM player_tutorial_step "
                        "WHERE func_name IS NOT NULL AND func_name!=''")
        return done

    # ---------------------------------------------------------------- 事务
    class _Tx:
        """可重入事务。

        嵌套调用时（例如 `upgrade_card` 的 tx 里又调了 `add_currency` 的 tx）
        内层用 SAVEPOINT，不会报 "cannot start a transaction within a transaction"，
        而且内层抛错只回滚内层。
        """

        def __init__(self, db):
            self.db = db
            self.depth = 0
            self.outermost = True

        def __enter__(self):
            self.db._write_lock.acquire()
            loc = self.db._local
            self.depth = getattr(loc, 'tx_depth', 0)
            self.outermost = (self.depth == 0)
            loc.tx_depth = self.depth + 1
            if self.outermost:
                # 多个进程同时写同一个库时，BEGIN IMMEDIATE 可能在 busy_timeout
                # 生效前就抛 SQLITE_BUSY（快照冲突），所以这里再自己重试几次。
                last = None
                for attempt in range(5):
                    try:
                        self.db.con.execute("BEGIN IMMEDIATE")
                        last = None
                        break
                    except sqlite3.OperationalError as e:
                        last = e
                        if 'locked' not in str(e).lower() and 'busy' not in str(e).lower():
                            break
                        time.sleep(0.05 * (attempt + 1))
                if last is not None:
                    self.db._local.tx_depth = self.depth
                    self.db._write_lock.release()
                    raise last
            else:
                self.db.con.execute("SAVEPOINT sp_%d" % self.depth)
            return self.db.con

        def __exit__(self, exc_type, exc, tb):
            try:
                if self.outermost:
                    self.db.con.execute("ROLLBACK" if exc_type else "COMMIT")
                else:
                    if exc_type:
                        self.db.con.execute("ROLLBACK TO SAVEPOINT sp_%d" % self.depth)
                        self.db.con.execute("RELEASE SAVEPOINT sp_%d" % self.depth)
                    else:
                        self.db.con.execute("RELEASE SAVEPOINT sp_%d" % self.depth)
            finally:
                self.db._local.tx_depth = self.depth
                self.db._write_lock.release()
            return False

    def tx(self):
        """写事务。可重入；串行化写，读仍可并发。"""
        return Database._Tx(self)


    def q(self, sql, args=()):
        return self.con.execute(sql, args)

    def one(self, sql, args=()):
        return self.con.execute(sql, args).fetchone()

    def all(self, sql, args=()):
        return self.con.execute(sql, args).fetchall()

    # ---------------------------------------------------------------- id 分配
    def next_id(self, name, count=1):
        """原子取号。返回第一个可用 id（连续 count 个）。

        必须在 tx() 里调用——外层没开事务时这里会自己补一个。
        """
        cur = self.con.execute(
            "UPDATE id_alloc SET next_val = next_val + ? WHERE name = ? RETURNING next_val",
            (count, name))
        row = cur.fetchone()
        if row is None:
            raise KeyError("id_alloc 里没有名为 %r 的序列" % name)
        start = int(row[0]) - count
        return start

    # ---------------------------------------------------------------- 计数器
    def bump_daily(self, player_id, stat_date, key, delta=1):
        self.con.execute(
            "INSERT INTO player_daily_counter(player_id, stat_date, counter_key, value)"
            " VALUES (?,?,?,?)"
            " ON CONFLICT(player_id, stat_date, counter_key)"
            " DO UPDATE SET value = value + excluded.value",
            (player_id, stat_date, key, delta))
        return self.get_daily(player_id, stat_date, key)

    def get_daily(self, player_id, stat_date, key, default=0):
        row = self.one("SELECT value FROM player_daily_counter"
                       " WHERE player_id=? AND stat_date=? AND counter_key=?",
                       (player_id, stat_date, key))
        return int(row[0]) if row else default

    def bump_counter(self, player_id, key, delta=1):
        self.con.execute(
            "INSERT INTO player_counter(player_id, counter_key, value, update_time)"
            " VALUES (?,?,?,?)"
            " ON CONFLICT(player_id, counter_key)"
            " DO UPDATE SET value = value + excluded.value, update_time = excluded.update_time",
            (player_id, key, delta, int(time.time())))
        return self.get_counter(player_id, key)

    def get_counter(self, player_id, key, default=0):
        row = self.one("SELECT value FROM player_counter WHERE player_id=? AND counter_key=?",
                       (player_id, key))
        return int(row[0]) if row else default

    # ---------------------------------------------------------------- 道具
    def add_prop(self, player_id, meta_id, amount):
        """加道具（amount 可为负）。减到 <=0 时删除该行。

        ⚠️ 客户端 sharkProps[] 里 amount<=0 的条目会导致数量显示异常，
        所以这里直接删行而不是留 0。
        """
        meta_id, amount = int(meta_id), int(amount)
        self.con.execute(
            "INSERT INTO player_prop(player_id, meta_id, amount, update_time)"
            " VALUES (?,?,?,?)"
            " ON CONFLICT(player_id, meta_id)"
            " DO UPDATE SET amount = amount + excluded.amount, update_time = excluded.update_time",
            (player_id, meta_id, amount, int(time.time())))
        self.con.execute("DELETE FROM player_prop WHERE player_id=? AND meta_id=? AND amount<=0",
                         (player_id, meta_id))

    def get_prop(self, player_id, meta_id):
        row = self.one("SELECT amount FROM player_prop WHERE player_id=? AND meta_id=?",
                       (player_id, meta_id))
        return int(row[0]) if row else 0

    # ---------------------------------------------------------------- 常用查询
    def today(self):
        """当日零点（本地）。player_daily.stat_date 用它做桶键。"""
        lt = time.localtime()
        return int(time.mktime((lt.tm_year, lt.tm_mon, lt.tm_mday, 0, 0, 0, 0, 0, -1)))


if __name__ == '__main__':
    import sys
    db = Database(sys.argv[1] if len(sys.argv) > 1 else 'canon.db')
    db.init_schema()
    print('schema 已初始化 ->', db.path)
