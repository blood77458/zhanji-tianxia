#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""数据访问层。

规矩：**只认数据库，不认识客户端字段名**。行 → 客户端 JSON 的映射全部由
`assembler.py` 负责。任何一处在这里写 camelCase 都是 bug。

每个 Repo 都持有 `db`（Database 实例），方法要么返回 sqlite3.Row，要么返回
dict/list。写操作不自己开事务 —— 由 service 层用 `with db.tx() as con:` 划定
事务边界，避免「扣道具 + 发卡」这类复合操作半途生效。
"""
from .player import PlayerRepo
from .asset import AssetRepo
from .progress import ProgressRepo
from .social import SocialRepo
from .guild import GuildRepo

__all__ = ['PlayerRepo', 'AssetRepo', 'ProgressRepo', 'SocialRepo', 'GuildRepo',
           'Repositories']


class Repositories:
    """把各域 repo 绑在一起，方便 service 层只接一个对象。"""

    def __init__(self, db):
        self.db = db
        self.player = PlayerRepo(db)
        self.asset = AssetRepo(db)
        self.progress = ProgressRepo(db)
        self.social = SocialRepo(db)
        self.guild = GuildRepo(db)
