#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""业务层容器。

    ctx = Services(db)
    ctx.player.grant_exp(pid, 100)
    ctx.reward.grant(pid, [ctx.reward.coin(500)])
    ctx.asset.upgrade_card(pid, card_id)

分层（见 SERVER_DATA_MODEL.md §9）：
    repository  只认数据库，不认识客户端字段名
    service     业务规则；用 ctx.repos 读写，用 with db.tx() 划事务
    assembler   只认客户端契约，不写 SQL
    api         路由：读 service → 喂 assembler → 返回 dict
"""
from repository import Repositories
from .player import PlayerService
from .reward import RewardService
from .account import AccountService
from .asset import AssetService
from .gacha import GachaService
from .mission import MissionService
from .activity import ActivityService
from .activities import ActivitiesService
from .arena import ArenaService
from .union_ext import UnionService

__all__ = ['Services']


class Services:
    def __init__(self, db):
        self.db = db
        self.repos = Repositories(db)
        self.player = PlayerService(self)
        self.reward = RewardService(self)
        self.account = AccountService(self)
        self.asset = AssetService(self)
        self.gacha = GachaService(self)
        self.mission = MissionService(self)
        self.activity = ActivityService(self)
        self.activities = ActivitiesService(self)
        self.arena = ArenaService(self)
        self.union = UnionService(self)

    # ---------------------------------------------------------------- getMeta
    def meta_payload(self):
        """getMeta 响应。

        载荷来自 `meta_payload.py`（从旧服务端抽取，含全部踩坑字段），
        只有 serverPartitionConfig 改成从库里读，方便换服务器名/多服。
        """
        from meta_payload import get_meta_payload
        m = get_meta_payload()
        rows = self.db.all("SELECT * FROM server_partition ORDER BY sort_order, server_id")
        if rows:
            m['serverPartitionConfig'] = {
                'runningServers': [{
                    'serverId': int(r['server_id']),
                    'serverName': r['server_name'],
                    'enable': int(r['status']) == 0,
                    'beginTime': str(int(r['open_time'])),
                    'serverBusy': 100000,
                    'serverNormal': 50000,
                    'newServer': bool(r['recommend']),
                    'whiteAccountIds': '',
                } for r in rows],
                'preparedServers': [],
            }
        return m
