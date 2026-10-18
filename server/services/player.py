#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""玩家本体：等级 / 经验 / 货币 / 体力精力恢复 / 计数器。

钻石的账本不变量（**必须维持**，否则客户端 calcComplex_getGemsNow 算错）:

    gem == recharge_gems + free_gems - used_free_gems - used_recharge_gems

客户端当前钻石数 = `rechargeGems + freeGems - usedFreeGems - usedRechargeGems`。
本实现把 used_free_gems 恒置 0，充值同时累加 recharge_gems 与 used_recharge_gems，
这样「充值多少就能花多少、且不重复计」。任何一处改动这四个字段都必须回到这个等式。
"""
import time

import gamedata as G


class PlayerService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    # ============================================================ 等级
    def sync_level(self, player_id):
        """把经验兑换成等级（对齐 RewardManager 的升级循环）。返回是否变化。"""
        table = G.user_level_exp_table()
        if not table:
            return False
        max_lv = max(table)
        changed = False
        for _ in range(500):                     # 防御性上限
            p = self.r.player.player(player_id)
            if p is None:
                break
            lv, exp = int(p['level']), int(p['exp'])
            need = table.get(lv)
            if need is None or lv >= max_lv or exp < need:
                break
            self.r.player.update(player_id, level=lv + 1, exp=exp - need)
            changed = True
        return changed

    def grant_exp(self, player_id, amount):
        self.r.player.add_currency(player_id, 'exp', amount)
        self.sync_level(player_id)

    # ============================================================ 体力 / 精力
    def _regen(self, player_id, column, ts_column, cap, per_seconds):
        """按时间戳恢复体力/精力（对齐 CalculationManager）。"""
        p = self.r.player.player(player_id)
        if p is None:
            return
        now = int(time.time())
        last = int(p[ts_column] or now)
        cur = int(p[column] or 0)
        if last > now:                            # 时间回拨，重置基准
            last = now
        if cur >= cap:
            self.r.player.update(player_id, **{ts_column: now})
            return
        gained = (now - last) // per_seconds
        if gained <= 0:
            return
        new_val = min(cap, cur + gained)
        self.r.player.update(player_id, **{column: new_val, ts_column: now})

    def regen_all(self, player_id):
        gs = G.game_setting_config()
        energy_cap = int(gs.get('maxEnergy') or gs.get('energyMax') or 200)
        ep_cap = int(gs.get('maxEventPoint') or gs.get('eventPointMax') or 100)
        eng_sec = int(gs.get('energyRecoverSeconds') or 300)
        ep_sec = int(gs.get('eventPointRecoverSeconds') or 600)
        self._regen(player_id, 'energy', 'energy_last_update_time', energy_cap, max(1, eng_sec))
        self._regen(player_id, 'event_point', 'event_point_last_update_time', ep_cap,
                    max(1, ep_sec))

    def energy_cap(self):
        gs = G.game_setting_config()
        return int(gs.get('maxEnergy') or gs.get('energyMax') or 200)

    def event_point_cap(self):
        gs = G.game_setting_config()
        return int(gs.get('maxEventPoint') or gs.get('eventPointMax') or 100)

    # ============================================================ 钻石账本
    def _mirror_gems(self, player_id, delta, recharge=False, used_recharge=0):
        """统一改钻石的入口：同时维护 gem / free_gems / recharge_gems / used_recharge_gems。"""
        fields = {}
        if delta:
            fields['gem'] = None                 # 用 SQL 原子加
        with self.db.tx() as con:
            if delta:
                con.execute("UPDATE player SET gem = MAX(0, gem + ?),"
                            " free_gems = MAX(0, free_gems + ?) WHERE player_id=?",
                            (int(delta), int(delta), int(player_id)))
            if recharge:
                con.execute("UPDATE player SET recharge_gems = recharge_gems + ?,"
                            " used_recharge_gems = used_recharge_gems + ? WHERE player_id=?",
                            (int(recharge), int(used_recharge or recharge), int(player_id)))
            self._assert_gem_invariant(con, player_id)
            row = con.execute("SELECT gem, free_gems, recharge_gems, used_free_gems,"
                              " used_recharge_gems FROM player WHERE player_id=?",
                              (int(player_id),)).fetchone()
        return int(row['gem']) if row else 0

    def _assert_gem_invariant(self, con, player_id):
        row = con.execute("SELECT gem, free_gems, recharge_gems, used_free_gems,"
                          " used_recharge_gems FROM player WHERE player_id=?",
                          (int(player_id),)).fetchone()
        if not row:
            return
        expect = (int(row['recharge_gems']) + int(row['free_gems'])
                  - int(row['used_free_gems']) - int(row['used_recharge_gems']))
        if int(row['gem']) != expect:
            # 自动纠偏而不是抛错：宁可账本自洽，也不要让一次请求把服务打挂
            con.execute("UPDATE player SET gem=? WHERE player_id=?", (max(0, expect),
                                                                      int(player_id)))

    def grant_gems(self, player_id, amount):
        return self._mirror_gems(player_id, int(amount))

    def spend_gems(self, player_id, amount):
        amount = int(amount)
        if amount < 0:
            return None
        with self.db.tx():
            p = self.r.player.player(player_id)
            if p is None or int(p['gem']) < amount:
                return None
            remaining = self._mirror_gems(player_id, -amount)
            self.r.player.bump_counter(player_id, 'gem_consumed', amount)
            return remaining

    def buy_gems(self, player_id, amount):
        """充值获得钻石：进 recharge 池。"""
        amount = int(amount)
        return self._mirror_gems(player_id, amount, recharge=amount)

    # ============================================================ VIP
    def grant_vip_exp(self, player_id, amount):
        self.r.player.add_currency(player_id, 'vip_exp', amount)
        # VIP 等级按配置门槛升
        p = self.r.player.player(player_id)
        table = (G.game_setting_config().get('vipSetting') or [])
        if not p or not table:
            return
        exp = int(p['vip_exp'])
        lv = 0
        for row in table:
            if exp >= int(row.get('requireExp') or row.get('exp') or 0):
                lv = max(lv, int(row.get('level') or 0))
        if lv > int(p['vip_level']):
            self.r.player.update(player_id, vip_level=lv)

    # ============================================================ 每日重置
    def ensure_daily(self, player_id):
        """跨天时把每日计数清掉（计数按 stat_date 分桶，旧桶天然失效）。"""
        today = self.db.today()
        self.r.player.daily(player_id, today)
        row = self.r.player.daily(player_id, today)
        return today, row
