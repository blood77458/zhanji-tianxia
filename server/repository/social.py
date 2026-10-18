#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""社交域：邮件 / 好友 / 邀请 / 礼物 / 红包 / 点赞 / 邀请码 / 系统邮件模板。

邮件四类共用 `mail` 表，用 mail_type 区分：
  1 sysEmails   系统邮件
  2 rewardEmails 奖励邮件
  3 sysNotices  系统公告（detail 必须是合法 JSON 文本）
  4 userEmails  玩家邮件
客户端会自己 table.union(sysEmails, rewardEmails)，所以**必须分别查询**。
"""
import json
import time

MAIL_SYS = 1
MAIL_REWARD = 2
MAIL_NOTICE = 3
MAIL_USER = 4


class SocialRepo:
    def __init__(self, db):
        self.db = db

    # ============================================================ 邮件
    def mails(self, player_id, mail_type, include_deleted=False):
        sql = ("SELECT * FROM mail WHERE player_id=? AND mail_type=?"
               + ("" if include_deleted else " AND is_deleted=0")
               + " ORDER BY create_time DESC, mail_id DESC")
        return self.db.all(sql, (int(player_id), int(mail_type)))

    def mail(self, player_id, mail_id):
        return self.db.one("SELECT * FROM mail WHERE player_id=? AND mail_id=?",
                           (int(player_id), int(mail_id)))

    def mail_attachments(self, mail_id):
        return self.db.all("SELECT * FROM mail_attachment WHERE mail_id=? ORDER BY slot",
                           (int(mail_id),))

    def create_mail(self, player_id, mail_type, title="", content="", meta_id=0,
                    sender_uid=0, sender_name="", detail=None, attachments=None,
                    expire_days=30):
        mid = self.db.next_id('mail')
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO mail(mail_id, player_id, mail_type, meta_id, sender_uid,"
                " sender_name, title, content, detail, is_read, is_deleted, is_gained,"
                " create_time, expire_time) VALUES (?,?,?,?,?,?,?,?,?,0,0,0,?,?)",
                (mid, int(player_id), int(mail_type), int(meta_id), int(sender_uid),
                 sender_name, title, content,
                 json.dumps(detail or {}, ensure_ascii=False), now,
                 now + int(expire_days) * 86400))
            for i, a in enumerate(attachments or [], 1):
                con.execute("INSERT INTO mail_attachment(mail_id, slot, item_type, meta_id,"
                            " amount) VALUES (?,?,?,?,?)",
                            (mid, i, int(a.get('itemType') or 0), int(a.get('metaId') or 0),
                             int(a.get('amount') or 0)))
        return mid

    def mark_mail(self, player_id, mail_id, **fields):
        cols = {'is_read', 'is_deleted', 'is_gained'}
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("mail 不可改 %r" % k)
            sets.append("%s=?" % k)
            args.append(1 if v else 0)
        if not sets:
            return
        args += [int(player_id), int(mail_id)]
        with self.db.tx() as con:
            con.execute("UPDATE mail SET %s WHERE player_id=? AND mail_id=?" % ', '.join(sets),
                        args)

    def delete_mails(self, player_id, mail_type, mail_ids):
        ids = [int(x) for x in mail_ids]
        if not ids:
            return 0
        q = ','.join('?' * len(ids))
        with self.db.tx() as con:
            cur = con.execute("UPDATE mail SET is_deleted=1 WHERE player_id=? AND mail_type=?"
                              " AND mail_id IN (%s)" % q,
                              [int(player_id), int(mail_type)] + ids)
            return cur.rowcount

    def sys_email_meta(self):
        return self.db.all("SELECT * FROM sys_email_meta WHERE enabled=1 ORDER BY meta_id")

    def unread_count(self, player_id):
        row = self.db.one("SELECT COUNT(*) AS c FROM mail WHERE player_id=? AND is_deleted=0"
                          " AND is_read=0", (int(player_id),))
        return int(row['c']) if row else 0

    # ============================================================ 好友
    def friends(self, player_id):
        return self.db.all("SELECT * FROM friend WHERE player_id=? ORDER BY create_time DESC",
                           (int(player_id),))

    def friend_ids(self, player_id):
        return [int(r['friend_uid']) for r in self.friends(player_id)]

    def is_friend(self, player_id, other):
        return self.db.one("SELECT 1 FROM friend WHERE player_id=? AND friend_uid=?",
                           (int(player_id), int(other))) is not None

    def add_friend(self, player_id, other, mutual=True):
        now = int(time.time())
        with self.db.tx() as con:
            con.execute("INSERT OR IGNORE INTO friend(player_id, friend_uid, create_time)"
                        " VALUES (?,?,?)", (int(player_id), int(other), now))
            if mutual:
                con.execute("INSERT OR IGNORE INTO friend(player_id, friend_uid, create_time)"
                            " VALUES (?,?,?)", (int(other), int(player_id), now))

    def remove_friend(self, player_id, other):
        with self.db.tx() as con:
            con.execute("DELETE FROM friend WHERE player_id=? AND friend_uid=?",
                        (int(player_id), int(other)))

    def set_gift_flag(self, player_id, other, sent=None, taken=None):
        sets, args = [], []
        if sent is not None:
            sets.append("gift_sent_date=?")
            args.append(sent)
        if taken is not None:
            sets.append("gift_taken_date=?")
            args.append(taken)
        if not sets:
            return
        args += [int(player_id), int(other)]
        with self.db.tx() as con:
            con.execute("UPDATE friend SET %s WHERE player_id=? AND friend_uid=?"
                        % ', '.join(sets), args)

    # ---- 邀请 ----
    def invitations(self, to_uid=None, from_uid=None, status=None):
        sql = "SELECT * FROM friend_invitation WHERE 1=1"
        args = []
        if to_uid is not None:
            sql += " AND to_uid=?"
            args.append(int(to_uid))
        if from_uid is not None:
            sql += " AND from_uid=?"
            args.append(int(from_uid))
        if status is not None:
            sql += " AND status=?"
            args.append(int(status))
        return self.db.all(sql + " ORDER BY create_time DESC", args)

    def add_invitation(self, from_uid, to_uid):
        with self.db.tx() as con:
            cur = con.execute(
                "INSERT INTO friend_invitation(from_uid, to_uid, status, create_time)"
                " VALUES (?,?,0,?)", (int(from_uid), int(to_uid), int(time.time())))
            return cur.lastrowid

    def set_invitation_status(self, invitation_id, status):
        with self.db.tx() as con:
            con.execute("UPDATE friend_invitation SET status=?, handle_time=?"
                        " WHERE invitation_id=?",
                        (int(status), int(time.time()), int(invitation_id)))

    # ---- 点赞 ----
    def praises(self, player_id, date_str):
        return self.db.all("SELECT * FROM player_praise WHERE player_id=? AND praise_date=?",
                           (int(player_id), date_str))

    def add_praise(self, player_id, target_uid, date_str):
        with self.db.tx() as con:
            con.execute("INSERT OR IGNORE INTO player_praise(player_id, target_uid,"
                        " praise_date, create_time) VALUES (?,?,?,?)",
                        (int(player_id), int(target_uid), date_str, int(time.time())))

    # ---- 邀请码 ----
    def invite_code(self, player_id):
        row = self.db.one("SELECT * FROM player_invite_code WHERE player_id=?", (int(player_id),))
        if row is None:
            code = "%08X" % (int(player_id) * 2654435761 % 0xFFFFFFFF)
            with self.db.tx() as con:
                con.execute("INSERT INTO player_invite_code(player_id, invite_code,"
                            " create_time) VALUES (?,?,?)",
                            (int(player_id), code, int(time.time())))
            row = self.db.one("SELECT * FROM player_invite_code WHERE player_id=?",
                              (int(player_id),))
        return row

    def player_by_invite_code(self, code):
        return self.db.one("SELECT * FROM player_invite_code WHERE invite_code=?", (code,))

    # ---- 红包 ----
    def red_packet(self, packet_id):
        return self.db.one("SELECT * FROM red_packet WHERE packet_id=?", (int(packet_id),))

    def claim_red_packet(self, packet_id, player_id, amount):
        with self.db.tx() as con:
            con.execute("INSERT INTO red_packet_claim(packet_id, player_id, amount, claim_time)"
                        " VALUES (?,?,?,?)",
                        (int(packet_id), int(player_id), int(amount), int(time.time())))
            con.execute("UPDATE red_packet SET left_amount = MAX(0, left_amount - ?),"
                        " left_count = MAX(0, left_count - 1) WHERE packet_id=?",
                        (int(amount), int(packet_id)))

    # ---- 玩家搜索（好友添加用）----
    def search_players(self, nickname, limit=20, exclude=None):
        sql = "SELECT player_id, nickname, level FROM player WHERE nickname LIKE ?"
        args = ['%' + nickname + '%']
        if exclude:
            sql += " AND player_id<>?"
            args.append(int(exclude))
        return self.db.all(sql + " LIMIT %d" % int(limit), args)
