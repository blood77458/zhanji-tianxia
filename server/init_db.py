#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""建库 + 灌种子数据。

    python init_db.py                 # 库不存在则建，存在则只补种子
    python init_db.py --force         # 删库重建
    python init_db.py --path x.db     # 指定库文件

种子数据只包含「服务端自己需要的运营数据」：分服表、公告、维护项、
系统邮件模板、充值档位。**玩家数据一概不灌** —— 那是 createUser 的事。
"""
import argparse
import os
import sqlite3
import sys
import time

from db import Database, SCHEMA_PATH

ROOT = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.join(ROOT, "canon.db")

# 客户端登录页显示的服务器列表（serverPartitionConfig）
SERVERS = [
    # (server_id, name, status, recommend, sort)
    (1, "本地测试服", 0, 1, 1),
]

# 系统邮件模板（getUserEmails 会随 sysEmails 一起下发 sysEmailMeta[]）
# ⚠️ content_text 缺失会让客户端 gsub(nil) 直接崩，所以不能为空串。
SYS_EMAIL_META = [
    (1, "新手礼包", "欢迎来到战姬天下，这是给你的见面礼。", 1,
     '[{"itemType":1,"amount":1000}]', 30),
    (2, "维护补偿", "因维护给您带来的不便，敬请谅解。", 1,
     '[{"itemType":2,"amount":200}]', 30),
    (3, "系统通知", "系统通知模板。", 0, '[]', 30),
]


def seed(cur, force=False):
    now = int(time.time())

    for sid, name, status, rec, sort in SERVERS:
        cur.execute(
            "INSERT INTO server_partition(server_id, server_name, status, recommend,"
            " open_time, sort_order) VALUES (?,?,?,?,?,?)"
            " ON CONFLICT(server_id) DO UPDATE SET server_name=excluded.server_name,"
            " status=excluded.status, recommend=excluded.recommend,"
            " sort_order=excluded.sort_order",
            (sid, name, status, rec, now, sort))

    for mid, title, content, contain, reward, days in SYS_EMAIL_META:
        cur.execute(
            "INSERT INTO sys_email_meta(meta_id, title_text, content_text, contain_reward,"
            " reward_json, expire_days, enabled) VALUES (?,?,?,?,?,?,1)"
            " ON CONFLICT(meta_id) DO UPDATE SET title_text=excluded.title_text,"
            " content_text=excluded.content_text, contain_reward=excluded.contain_reward,"
            " reward_json=excluded.reward_json",
            (mid, title, content, contain, reward, days))

    cur.execute(
        "INSERT INTO announcement(server_id, title, content, start_time, end_time,"
        " sort_order, enabled) VALUES (0,?,?,?,?,1,1)",
        ("欢迎回到战姬天下", "本服为私人复现服务端，仅供学习使用。", now, 0))

    cur.execute(
        "INSERT INTO maintenance_item(item_type, title, content, start_time, end_time, enabled)"
        " VALUES (1,?,?,?,?,1)",
        ("例行维护", "每日 05:00 例行维护，预计 5 分钟。", now, 0))

    # 各 id 序列兜底（schema.sql 里已 INSERT，这里防手工删过）
    for name, start in (("card", 1000), ("equip", 100), ("spirit", 1), ("treasure", 1),
                        ("mail", 1), ("union", 1), ("order", 1)):
        cur.execute("INSERT OR IGNORE INTO id_alloc(name, next_val) VALUES (?,?)",
                    (name, start))

    # ⚠️ player_id 必须从 100000 起，**不能碰 1**。
    # 客户端 LoginScene.lua:349 用 `uid == "1"` 判定「新玩家」，
    # 如果真实角色 id 恰好是 1，客户端会把老号当新号，跳去创角界面。
    # sqlite_sequence 没有唯一约束，不能用 ON CONFLICT，只能先删后插。
    cur.execute("DELETE FROM sqlite_sequence WHERE name='player'")
    cur.execute("INSERT INTO sqlite_sequence(name, seq) VALUES ('player', 99999)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--path", default=DEFAULT_DB)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    if args.force:
        for suffix in ("", "-wal", "-shm"):
            p = args.path + suffix
            if os.path.exists(p):
                os.remove(p)
        print("已删除旧库 %s" % args.path)

    fresh = not os.path.exists(args.path)
    db = Database(args.path)
    created = db.init_schema(force=args.force)
    print("%s schema.sql -> %s" % ("建库:  " if created else "已存在，跳过建表:", args.path))

    with db.tx() as con:
        seed(con, force=args.force)

    tabs = [r[0] for r in db.all(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        " ORDER BY name")]
    views = [r[0] for r in db.all(
        "SELECT name FROM sqlite_master WHERE type='view' ORDER BY name")]
    ncol = sum(len(list(db.q("PRAGMA table_info(%s)" % t))) for t in tabs)
    idx = [r[0] for r in db.all(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'")]

    print()
    print("表 %d 张 / 视图 %d 个 / 索引 %d 个 / 列合计 %d"
          % (len(tabs), len(views), len(idx), ncol))
    print("分服表   : %s" % ', '.join(
        '%d=%s' % (r['server_id'], r['server_name'])
        for r in db.all("SELECT * FROM server_partition ORDER BY sort_order")))
    print("邮件模板 : %d 条" % db.one("SELECT COUNT(*) c FROM sys_email_meta")['c'])
    print("id 序列  : %s" % ', '.join(
        '%s=%d' % (r['name'], r['next_val'])
        for r in db.all("SELECT * FROM id_alloc ORDER BY name")))
    print()
    print("库已就绪: %s" % os.path.abspath(args.path))
    db.close()


if __name__ == '__main__':
    sys.exit(main())
