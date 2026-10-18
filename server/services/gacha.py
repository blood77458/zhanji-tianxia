#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""抽卡。保底计数走 player_counter，出货记 gacha_log。"""
import time

import gamedata as G

OK = 200
E_GEM_NOT_ENOUGH = 710513
E_GACHA_NOT_EXIST = 710071


class GachaService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos

    def _counter_key(self, gacha_id):
        return 'gacha_%d_count' % int(gacha_id)

    def _since_rare_key(self, gacha_id):
        return 'gacha_%d_since_rare' % int(gacha_id)

    def gacha(self, player_id, gacha_id, times=1, free=False):
        """抽 times 次。free=True 时走免费次数（gachaCardFree）。"""
        gacha_id = int(gacha_id)
        times = max(1, int(times or 1))
        cfg = G.gacha_cfg(gacha_id)
        if cfg is None:
            return E_GACHA_NOT_EXIST, None

        import luaconf
        rule = next((r for r in luaconf.as_list(luaconf.load('gacha_card'))
                     if int(r.get('id') or 0)==gacha_id), {})
        times = min(times,int(cfg.get('maxNum') or 10))
        if not free:
            requisite = (rule.get('requisites') or {}).get('requisite') or {}
            cost = int(requisite.get('amount') or 0)*times
            kind = int(requisite.get('itemType') or G.RE_GEMS)
            if kind==G.RE_GEMS:
                if self.ctx.player.spend_gems(player_id,cost) is None: return E_GEM_NOT_ENOUGH,None
            elif kind==G.RE_FRIEND_POINT:
                p=self.r.player.player(player_id)
                if int(p['friend_point'])<cost: return E_GEM_NOT_ENOUGH,None
                self.r.player.add_currency(player_id,'friend_point',-cost)
            elif kind==G.RE_GACHA_POINT:
                points=self.r.player.counter(player_id,'gacha_points')
                if points<cost: return E_GEM_NOT_ENOUGH,None
                self.r.player.bump_counter(player_id,'gacha_points',-cost)
        pulled=self.r.player.counter(player_id,self._counter_key(gacha_id))
        rewards = G.roll_gacha(gacha_id,times,pulled=pulled)
        applied, _ = self.ctx.reward.grant(player_id, rewards, record=True,
                                           reason='gachaCard:%d' % gacha_id)
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO gacha_log(player_id, gacha_id, gacha_type, times, results_json,"
                " create_time) VALUES (?,?,?,?,?,?)",
                (int(player_id), gacha_id, 'free' if free else 'normal', times,
                 __import__('json').dumps(applied, ensure_ascii=False), int(time.time())))
        self.r.player.bump_counter(player_id, self._counter_key(gacha_id), times)
        self.r.player.bump_counter(player_id, 'gacha_points', int(rule.get('pointReward') or 0)*times)

        from meta_payload import get_meta_payload
        activity = get_meta_payload().get('activityGachaXiaoyuConfig', {})
        point_key = {1: 'commonGachaPoints', 2: 'advancedGachaPoints',
                     3: 'ultimatedGachaPoints', 4: 'activityGachaPoints'}.get(gacha_id)
        points = int(activity.get(point_key) or 0)*times if point_key and not free else 0
        if not free and times == 10:
            ten_key = {1: 'commonTenPoints', 3: 'ultimatedTenPoints'}.get(gacha_id)
            if ten_key: points = int(activity.get(ten_key) or points)
        if points:
            st = self.ctx.activity.state(player_id, 'cross_gacha')
            st['point'] = int(st.get('point') or 0)+points
            self.ctx.activity.save_state(player_id, 'cross_gacha', st)


        return OK, {
            'rewards': applied,
            'free': bool(free),
            'countdownFreeGachaInfos': self.free_info(player_id, gacha_id),
        }

    def free_info(self, player_id, gacha_id=None):
        import json
        ext=self.r.player.extend(player_id)
        blob=json.loads(ext['extend_json'] or '{}')
        infos=blob.get('countdownFreeGachaInfos') or []
        return infos if isinstance(infos,list) else []

    def free_gacha(self, player_id, gacha_id):
        import json, luaconf
        rule=next((r for r in luaconf.as_list(luaconf.load('gacha_card'))
                   if int(r.get('id') or 0)==int(gacha_id)),{})
        now=int(time.time())
        infos=self.free_info(player_id)
        last=next((int(i.get('latestFreeGachaTime') or 0) for i in infos
                   if int(i.get('gachaNodeId') or 0)==int(gacha_id)),0)
        if not rule.get('countdownFree') or (last and now-last<int(rule.get('countdownDuration') or 0)):
            return 710071,None
        code,payload=self.gacha(player_id,gacha_id,times=1,free=True)
        if code==OK:
            self.r.player.update(player_id,last_free_gacha_seconds=now)
            infos=[i for i in infos if int(i.get('gachaNodeId') or 0)!=int(gacha_id)]
            infos.append({'gachaNodeId':int(gacha_id),'latestFreeGachaTime':now})
            ext=self.r.player.extend(player_id); blob=json.loads(ext['extend_json'] or '{}')
            blob['countdownFreeGachaInfos']=infos
            self.r.player.update_extend(player_id,extend_json=blob)
            payload['countdownFreeGachaInfos']=infos
        return code,payload

    def broadcasts(self, limit=10):
        """全服广播（getGachaBroadcast）。当前只回空列表，字段必须存在。"""
        return []
