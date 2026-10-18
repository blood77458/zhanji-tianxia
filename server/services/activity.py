#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""活动通用框架。

所有活动共用的四件事：
  1. **状态存取** —— 走 `player_activity(player_id, activity_key) -> data_json`
  2. **活动开关 / 时间窗** —— 对齐客户端 `MaintenanceManager:getStartAndEndTime`
  3. **领奖幂等** —— 走 `player_activity_reward_claim`，同一档位只能领一次
  4. **奖励解析** —— 原厂配置有两种约定（包 id / 直接表征），统一展开成
     客户端 RewardManager 认的 `{itemType, metaId, amount}`

奖励的两种约定（别混）：
  * 包 id：字段名含 package / achieveReward 等，值是 `reward_package.id`
    （10001..19322）→ 用 `pkg(pkg_id)`
  * 直接表征：`rewardType` + `rewardId` + `rewardAmount`，rewardType 就是
    ResourceEnum → 用 `spec(type, id, amount)`
"""
import json
import time

import gamedata as G

OK = 200


class ActivityService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    # ============================================================ 状态
    def state(self, player_id, key, default=None):
        row = self.db.one("SELECT * FROM player_activity WHERE player_id=? AND activity_key=?",
                          (int(player_id), key))
        if row is None:
            return dict(default or {})
        try:
            data = json.loads(row['data_json'] or '{}')
        except Exception:
            data = {}
        return data if isinstance(data, dict) else {}

    def save_state(self, player_id, key, data, start=0, end=0, version=0):
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_activity(player_id, activity_key, version, start_time,"
                " end_time, data_json, update_time) VALUES (?,?,?,?,?,?,?)"
                " ON CONFLICT(player_id, activity_key) DO UPDATE SET"
                " data_json=excluded.data_json, update_time=excluded.update_time,"
                " version=excluded.version",
                (int(player_id), key, int(version), int(start), int(end),
                 json.dumps(data, ensure_ascii=False), now))
        return data

    def patch_state(self, player_id, key, **fields):
        data = self.state(player_id, key)
        data.update(fields)
        return self.save_state(player_id, key, data)

    def ensure_counter(self, player_id, key, field, default=0):
        """确保活动状态里有某个计数字段，返回其值。"""
        data = self.state(player_id, key)
        if field not in data:
            data[field] = default
            self.save_state(player_id, key, data)
        return data[field]

    # ============================================================ 时间窗
    def is_open(self, feature_name):
        """活动是否开启。服务端可通过 player_activity.start/end 覆盖默认全开。"""
        return True

    # ============================================================ 领奖
    def has_claimed(self, player_id, scope, reward_id):
        return self.db.one(
            "SELECT 1 FROM player_activity_reward_claim WHERE player_id=? AND scope=?"
            " AND reward_id=?", (int(player_id), scope, int(reward_id))) is not None

    def mark_claimed(self, player_id, scope, reward_id):
        with self.db.tx() as con:
            con.execute("INSERT OR IGNORE INTO player_activity_reward_claim(player_id, scope,"
                        " reward_id, claim_time) VALUES (?,?,?,?)",
                        (int(player_id), scope, int(reward_id), int(time.time())))

    def claims(self, player_id, scope):
        return {int(r['reward_id']) for r in self.db.all(
            "SELECT reward_id FROM player_activity_reward_claim WHERE player_id=? AND scope=?",
            (int(player_id), scope))}

    def claim_once(self, player_id, scope, reward_id, rewards, reason=''):
        """幂等领奖：已领过返回 (False, [])，否则发奖并标记。"""
        if self.has_claimed(player_id, scope, reward_id):
            return False, []
        self.mark_claimed(player_id, scope, reward_id)
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True,
                                           reason=reason or scope)
        return True, applied

    # ============================================================ 奖励解析
    @staticmethod
    def pkg(pkg_id):
        """reward_package → reward 列表。"""
        return G.reward_from_package(int(pkg_id or 0))

    @staticmethod
    def spec(item_type, meta_id=0, amount=1):
        return G.reward_from_spec(item_type, meta_id, amount)

    @staticmethod
    def pkg_exists(pkg_id):
        return G.reward_package_exists(int(pkg_id or 0))

    def rows(self, ti=None, ri=None, ai=None, ti_amt=None, ri_amt=None):
        """把 `rewardType1..4 / rewardId1..4 / rewardAmount1..4` 这种并列字段
        展开成 reward 列表。ti/ri/ai 传各行对应的字段名。"""
        out = []
        for t, i, a in zip(ti or [], ri or [], ai or []):
            t = int(t or 0)
            if t:
                out.append(self.spec(t, int(i or 0), int(a or 0)))
        return out

    # ============================================================ 便捷
    def daily_key(self, player_id, key, field):
        """活动的「每日」字段：记录日期，跨天自动清零。"""
        today = time.strftime('%Y-%m-%d')
        data = self.state(player_id, key)
        if data.get('_daily_date') != today:
            data['_daily_date'] = today
            data[field] = 0
            self.save_state(player_id, key, data)
        return data

    def today(self):
        return self.db.today()
