#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""账号与会话：登录链路的服务端一侧。

对应客户端流程（API.md §0.1）：
    /loginAccount/hasVisitorAccount  → 有没有游客账号
    /check/<platform>?               → {code:1, loginAccountId}
    /mappingAccount                  → {code:1, accountId, token}
    /sessionKey/init                 → 纯文本 "uid,uuid,sessionKey"
    RPC login / loginServer / createUser

身份区分（很重要）：
    account_id  —— 登录级身份（= initSession 的 uid、mappingAccount 的 accountId）
    player_id   —— 角色身份（= sharkUser.uid、loginServer.uid）
    一个 account 在每个 serverId 上最多一个 player。
"""
import hashlib
import os
import time
import uuid as _uuid

import gamedata as G

# 新玩家的标识：客户端 LoginScene.lua:349 `uid == "1"` 即新号
NEW_PLAYER_UID = "1"


class AccountService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    # ============================================================ 账号
    def find_or_create_by_platform(self, platform_id, platform_uid, device_id=None):
        """`/check/*` 与 `/mappingAccount` 共用：拿平台身份找账号，没有就建。"""
        b = self.r.player.binding(platform_id, platform_uid)
        if b:
            return int(b['account_id'])
        acc = self.r.player.create_account(device_id=device_id)
        self.r.player.bind(acc, platform_id, platform_uid, device_id=device_id)
        return acc

    def find_or_create_by_device(self, device_id):
        """游客登录：设备号就是身份。"""
        acc = self.r.player.account_by_device(device_id)
        if acc:
            return int(acc['account_id'])
        return self.find_or_create_by_platform('guest', device_id, device_id=device_id)

    def register(self, account_name, password_md5, email=None):
        """注册账号。返回 (code, account_id, msg)。"""
        if self.r.player.account_by_name(account_name):
            return -5, None, 'already exists'
        salt = os.urandom(8).hex()
        h = hashlib.sha256((salt + (password_md5 or '')).encode()).hexdigest()
        acc = self.r.player.create_account(account_name=account_name, password_hash=h,
                                           password_salt=salt, email=email)
        return 1, acc, 'ok'

    def check_password(self, account_name, password_md5):
        acc = self.r.player.account_by_name(account_name)
        if not acc:
            return None
        h = hashlib.sha256(((acc['password_salt'] or '') + (password_md5 or '')).encode()).hexdigest()
        return acc if h == acc['password_hash'] else None

    # ============================================================ 会话
    def init_session(self, account_id, uuid=None, udid=None, ip=None):
        """建会话，返回 (uid, uuid, session_key)。"""
        uuid = uuid or _uuid.uuid4().hex
        sk = hashlib.md5(("%s|%s|%s" % (account_id, uuid, time.time())).encode()).hexdigest()
        self.r.player.create_session(account_id, sk, uuid, uk=None, udid=udid, ip=ip)
        return str(account_id), uuid, sk

    def player_by_session(self, session_key):
        s = self.r.player.session(session_key)
        if not s or int(s['revoked']):
            return None
        return self.r.player.player(s['player_id']) if s['player_id'] else None

    def account_by_session(self, session_key):
        s = self.r.player.session(session_key)
        if not s or int(s['revoked']):
            return None
        return self.r.player.account(int(s['account_id']))

    def bind_session_player(self, session_key, player_id):
        self.r.player.touch_session(session_key, player_id)

    # ============================================================ 选服 / 创角
    def resolve_player(self, account_id, server_id=1):
        """loginServer 用：返回 player 行，None 表示该服还没角色。"""
        return self.r.player.player_by_account(account_id, server_id)

    def create_player(self, account_id, server_id, nickname, avatar_id=0, invite_code=None):
        """createUser。返回 player_id。

        ⚠️ 昵称必须非空 —— 客户端会把它 setString，为空会显示异常。
        """
        nickname = (nickname or '').strip() or '无名主公'
        if self.r.player.set_nickname_taken(nickname, 0):
            # 重名时加后缀，而不是失败（客户端对失败的处理很粗暴）
            nickname = nickname + str(int(time.time()) % 10000)
        pid = self.r.player.create_player(account_id, server_id, nickname)
        self._bootstrap_new_player(pid, avatar_id)
        if invite_code:
            self._apply_invite(pid, invite_code)
        return pid

    def _bootstrap_new_player(self, player_id, avatar_id=0):
        """新号初始资产。这一段必须「完整」——缺字段会让 gameInit 崩。"""
        r = self.r
        # 初始货币（数值取自原服务端验证过的量级）
        r.player.update(player_id, gold=100000, gem=10000, free_gems=10000,
                        energy=100, event_point=100, action_power=100,
                        main_card_id=0, additional_card_ids='')
        # 初始武将（关平）
        cid = r.asset.create_card(player_id, G.STARTER_CARD_META, level=1, exp=0)
        # CreateUser.avatarId is a character-selection option (the client sends
        # 1), not a card_meta ID. Only real card IDs can override card artwork.
        if avatar_id and G.card_meta_exists(int(avatar_id)):
            r.asset.update_card(player_id, cid, avatar_meta_id=int(avatar_id))
        # 初始阵容
        r.asset.ensure_battle_arrays(player_id, 1)
        r.asset.set_battle_queue(player_id, 1, [cid])
        r.asset.set_active_array(player_id, 1)
        # 初始道具 + 装备
        for p in G.STARTER_PROPS:
            r.asset.add_prop(player_id, int(p['metaId']), int(p['amount']))
        for mid in G.STARTER_EQUIP_METAS:
            r.asset.create_equip(player_id, int(mid), level=1)
        # 祝福邮件
        r.social.create_mail(player_id, 1, meta_id=1, title='新手礼包',
                             content='欢迎来到战姬天下，这是给你的见面礼。',
                             attachments=[{'itemType': G.RE_COIN, 'metaId': 0, 'amount': 1000}])
        return player_id

    def _apply_invite(self, player_id, invite_code):
        row = self.r.social.player_by_invite_code(invite_code)
        if row and int(row['player_id']) != int(player_id):
            with self.db.tx() as con:
                con.execute("UPDATE player_invite_code SET invited_count = invited_count + 1,"
                            " has_invited = 1 WHERE player_id=?", (int(row['player_id']),))
                con.execute("UPDATE player_invite_code SET invited_by=? WHERE player_id=?",
                            (int(row['player_id']), int(player_id)))

    # ============================================================ 展示信息
    def server_list(self):
        return self.db.all("SELECT * FROM server_partition ORDER BY sort_order, server_id")

    def logined_servers(self, account_id):
        return ','.join(str(int(p['server_id']))
                        for p in self.r.player.players_of_account(account_id))
