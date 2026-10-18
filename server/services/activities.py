#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""各活动/玩法的具体实现。

每个方法返回 `(retCode, payload)` 或直接返回 payload dict。
配置一律来自本地 `canon/configs/*.lua`（见 luaconf.py），
只有原厂配置是空壳时才自编，并在注释里标明 `[自编]`。

接口契约（请求参数 / 客户端读取的响应字段）来自 work/api_analysis/records.json，
用 `python work/api_analysis/contract.py <关键字>` 可以随时复查。
"""
import json
import random
import time

import gamedata as G
import luaconf

OK = 200
E_NOT_OPEN = 714001
E_NOT_ENOUGH = 710513
E_ALREADY = 710001
E_PARAM = 710071


def cfg(name):
    return luaconf.load(name)


def rows(name):
    return [r for r in luaconf.as_list(cfg(name)) if isinstance(r, dict)]


class ActivitiesService:
    def __init__(self, ctx):
        self.ctx = ctx
        self.db = ctx.db
        self.r = ctx.repos
        self.act = ctx.activity

    # ============================================================ 每日答题
    # 题库 487 题在本地（activity_question_bank），是少数**数据完整**的活动之一。
    KEY_Q = 'question'

    def _q_bank(self):
        if not hasattr(self, '_qbank'):
            self._qbank = {int(r['id']): r for r in rows('activity_question_bank')}
        return self._qbank

    def _q_state(self, pid):
        st = self.act.state(pid, self.KEY_Q)
        today = time.strftime('%Y-%m-%d')
        week = time.strftime('%G-%V')
        if 'pool' not in st or st.get('_daily_date') != today:
            ids = sorted(k for k, q in self._q_bank().items() if q.get('enable', True))
            random.shuffle(ids)
            old = st
            same_week = old.get('week') == week
            st = {'pool': ids[:10], 'idx': 0, 'correct': 0, 'wrong': 0,
                  'wrongIds': [], 'dailyGained': False,
                  '_daily_date': today, 'week': week,
                  'thisWeekNum': int(old.get('thisWeekNum') or 0) if same_week else 0,
                  'lastWeekNum': int(old.get('lastWeekNum') or 0) if same_week else int(old.get('thisWeekNum') or 0),
                  'weekGained': bool(old.get('weekGained')) if same_week else False}
            self.act.save_state(pid, self.KEY_Q, st)
        elif len(st.get('pool') or []) > 10:
            # Migrate unfinished rounds from the old entire-bank implementation.
            st['pool'] = st['pool'][:10]
            st['idx'] = min(int(st.get('idx') or 0), 10)
            st['correct'] = min(int(st.get('correct') or 0), st['idx'])
            self.act.save_state(pid, self.KEY_Q, st)
        if 'week' not in st:
            st.update(week=week, thisWeekNum=int(st.get('correct') or 0), lastWeekNum=0, weekGained=False)
            self.act.save_state(pid, self.KEY_Q, st)
        return st

    def _q_payload(self, pid, st=None, extra=None):
        st = st or self._q_state(pid)
        bank = self._q_bank()
        pool = st.get('pool') or []
        idx = int(st.get('idx') or 0)
        out = {
            'questionNum': min(idx + 1, len(pool)),
            'dailyNum': int(st.get('correct') or 0),
            'questionId': 0,
            'wrongAnswer1Key': '',
            'wrongAnswer2Key': '',
            'wrongAnswer3Key': '',
        }
        if idx < len(pool):
            q = bank.get(int(pool[idx]))
            if q:
                out['questionId'] = int(q['id'])
                # 客户端要三个「错误答案」的文案 key
                wrongs = [q.get('wrongAnswer%dKey' % i) for i in range(1, 4)]
                if int(q.get('type', 1)) == 0:
                    candidates = sorted({r.get('correctAnswerKey') for r in bank.values()
                                         if int(r.get('type', 1)) == 0 and r.get('correctAnswerKey')
                                         and r.get('correctAnswerKey') != q.get('correctAnswerKey')})
                    wrongs = random.sample(candidates, min(3, len(candidates)))
                for n, w in enumerate(wrongs[:3], 1):
                    out['wrongAnswer%dKey' % n] = w
        out.update(extra or {})
        return out

    def question_info(self, pid):
        return OK, self._q_payload(pid)

    def question_daily_reward(self, pid):
        st = self._q_state(pid)
        today = time.strftime('%Y-%m-%d')
        if st.get('_daily_date') != today:
            st['_daily_date'] = today
            st['dailyGained'] = False
            self.act.save_state(pid, self.KEY_Q, st)
        if st.get('dailyGained'):
            return OK, self._q_payload(pid)
        if int(st.get('idx') or 0) < len(st.get('pool') or []):
            return 716924, {}
        st['dailyGained'] = True
        self.act.save_state(pid, self.KEY_Q, st)
        rewards = self.act.pkg(19030) or [self.act.spec(G.RE_COIN, 0, 5000)]
        applied, _ = self.ctx.reward.grant(pid, rewards, record=True, reason='questionDaily')
        return OK, self._q_payload(pid, st, {'rewards': applied})

    def question_week_reward(self, pid):
        from meta_payload import get_meta_payload
        st = self._q_state(pid)
        if st.get('weekGained'):
            return OK, {'rewards': []}
        configs = get_meta_payload()['activityQuestionSettingConfig'].get('questionWeekRewards', [])
        tier = next((r for r in configs if int(r['correctMin']) <= int(st.get('lastWeekNum') or 0) <= int(r['correctMax'])), None)
        if not tier:
            return OK, {'rewards': []}
        st['weekGained'] = True
        self.act.save_state(pid, self.KEY_Q, st)
        rewards = self.act.pkg(tier['rewardPackageId'])
        applied, _ = self.ctx.reward.grant(pid, rewards, record=True, reason='questionWeek')
        return OK, {'rewards': applied}

    def answer_question(self, pid, answer, question_meta_id):
        st = self._q_state(pid)
        pool = st.get('pool') or []
        idx = int(st.get('idx') or 0)
        bank = self._q_bank()
        qid = int(question_meta_id or 0)
        if idx >= len(pool):
            return OK, {'result': False, 'over': True, 'nextQuestionMetaId': 0}
        expect_id = int(pool[idx])
        if qid and qid != expect_id:
            return E_PARAM, {}
        q = bank.get(expect_id) or {}
        ok_answer = str(answer or '') == str(q.get('correctAnswerKey') or '')
        if ok_answer:
            st['correct'] = int(st.get('correct') or 0) + 1
            st['thisWeekNum'] = int(st.get('thisWeekNum') or 0) + 1
        else:
            st['wrong'] = int(st.get('wrong') or 0) + 1
            wl = st.setdefault('wrongIds', [])
            if expect_id not in wl:
                wl.append(expect_id)
        st['idx'] = idx + 1
        self.act.save_state(pid, self.KEY_Q, st)
        over = st['idx'] >= len(pool)
        nxt = int(pool[st['idx']]) if not over else 0
        payload = self._q_payload(pid, st)
        payload['result'] = bool(ok_answer)
        payload['over'] = over
        payload['nextQuestionMetaId'] = nxt
        return OK, payload

    # ============================================================ 消费送好礼
    # 本地 activity_gem_consume 数据完整
    KEY_GEMCONSUME = 'gem_consume'

    def _gemconsume_items(self):
        from meta_payload import get_meta_payload
        v = get_meta_payload()['activityGemConsumeConfig']['gemConsumeRewards']
        items = []
        def walk(x):
            if isinstance(x, dict):
                if 'item' in x:
                    walk(x['item'])
                elif 'id' in x and 'requireGold' in x:
                    items.append(x)
                else:
                    for vv in x.values():
                        walk(vv)
            elif isinstance(x, list):
                for vv in x:
                    walk(vv)
        walk(v)
        return {int(i['id']): i for i in items}

    def get_gem_consume_info(self, pid):
        items = self._gemconsume_items()
        claimed = self.act.claims(pid, self.KEY_GEMCONSUME)
        return OK, {'consumeGems': self.r.player.counter(pid, 'gem_consumed'),
                    'gainedRewards': sorted(claimed),
                    'gainedGemConsumeRewards': sorted(claimed),
                    'items': [{'id': i, 'requireGold': int(v.get('requireGold') or 0),
                               'gained': i in claimed}
                              for i, v in sorted(items.items())]}

    def gain_gem_consume_rewards(self, pid, reward_id):
        items = self._gemconsume_items()
        it = items.get(int(reward_id or 0))
        if not it:
            return OK, {'rewards': []}
        # requireGold 语义：累计消费钻石门槛
        if self.r.player.counter(pid, 'gem_consumed') < int(it.get('requireGold') or 0):
            return E_NOT_ENOUGH, None
        got, applied = self.act.claim_once(
            pid, self.KEY_GEMCONSUME, int(reward_id),
            self.act.pkg(it.get('rewardPackageId')), reason='gemConsume')
        return OK, {'rewards': applied}

    # ============================================================ 累充 / 限时充值
    KEY_CHARGE = 'charge'
    KEY_LIMIT = 'limit_reward'

    def _charge_rows(self):
        if not hasattr(self, '_chargerows'):
            self._chargerows = rows('charge_money_reward')
        return self._chargerows

    def recharge_info(self, pid):
        p = self.r.player.player(pid)
        claimed = self.act.claims(pid, self.KEY_CHARGE)
        out = []
        for r in self._charge_rows():
            rid = int(r.get('id') or 0)
            out.append({
                'id': rid,
                'requireGold': int(r.get('requireGold') or r.get('requireGem') or 0),
                'gained': rid in claimed,
            })
        return OK, {'recharges': out, 'dailyRecharge': 0,
                    'accumulateGems': int(p['recharge_gems'])}

    def gain_charge_money_reward(self, pid, reward_id):
        rid = int(reward_id or 0)
        row = next((r for r in self._charge_rows() if int(r.get('id') or 0) == rid), None)
        if not row:
            return OK, {'rewards': []}
        need = int(row.get('requireGold') or row.get('requireGem') or 0)
        if int(self.r.player.player(pid)['recharge_gems']) < need:
            return E_NOT_ENOUGH, None
        # charge_money_reward 用「直接表征」：rewardTypeN/rewardIdN/rewardAmountN
        rewards = []
        for i in range(1, 5):
            t = int(row.get('rewardType%d' % i) or 0)
            if t:
                rewards.append(self.act.spec(t, int(row.get('rewardId%d' % i) or 0),
                                             int(row.get('rewardAmount%d' % i) or 0)))
        got, applied = self.act.claim_once(pid, self.KEY_CHARGE, rid, rewards,
                                           reason='chargeMoneyReward')
        return OK, {'rewards': applied}

    def gain_limit_reward(self, pid, step_id):
        """限时充值（Activity_rechargeLayer）。服务端 activityLimitRewardConfig 已有 3 档。"""
        items = (G.game_setting_config() or {})
        cfg_rows = None
        for k in ('activityLimitRewardConfig',):
            pass
        from meta_payload import get_meta_payload
        cfg_rows = (get_meta_payload().get('activityLimitRewardConfig') or {}).get('limitRewards') or []
        row = next((r for r in cfg_rows if int(r.get('id') or 0) == int(step_id or 0)), None)
        if not row:
            return OK, {'rewards': []}
        rewards = []
        for i in range(1, 6):
            t = int(row.get('rewardType%d' % i) or 0)
            if t:
                rewards.append(self.act.spec(t, int(row.get('rewardId%d' % i) or 0),
                                             int(row.get('rewardAmount%d' % i) or 0)))
        got, applied = self.act.claim_once(pid, self.KEY_LIMIT, int(step_id), rewards,
                                           reason='limitReward')
        return OK, {'rewards': applied}

    # ============================================================ 连登 / 观星
    KEY_CONT = 'continuous'

    def _cont_rows(self, new=False):
        name = 'consecutive_login_reward_new' if new else 'consecutive_login_reward'
        if not hasattr(self, '_controws'):
            self._controws = {}
        if name not in self._controws:
            self._controws[name] = rows(name)
        return self._controws[name]

    def continuous_info(self, pid, new=False):
        st = self.act.state(pid, self.KEY_CONT)
        return OK, {'continuousLoginInfo': {
            'firstGetRewardTime': int(st.get('firstTime') or 0),
            'latestGetRewardTime': int(st.get('latestTime') or 0),
            'gainRewards': st.get('gained') or [],
            'gainRewardInOrder': int(st.get('inOrder') or 0),
            'getBigReward': int(st.get('bigReward') or 0),
        }}

    def gain_continuous(self, pid, day_id, new=False):
        """领第 day_id 天（1-based）的连登奖励。"""
        rs = self._cont_rows(new)
        day = int(day_id or 0)
        row = next((r for r in rs if int(r.get('id') or 0) == day), None)
        if row is None and 1 <= day <= len(rs):
            row = rs[day - 1]
        if not row:
            return OK, {'rewards': []}
        st = self.act.state(pid, self.KEY_CONT)
        gained = st.setdefault('gained', [])
        if day in gained:
            return OK, {'rewards': []}
        gained.append(day)
        st['latestTime'] = int(time.time())
        if not st.get('firstTime'):
            st['firstTime'] = int(time.time())
        st['inOrder'] = len(gained)
        self.act.save_state(pid, self.KEY_CONT, st)
        # consecutive_login_reward 用直接表征
        rewards = []
        t = int(row.get('rewardType') or 0)
        if t:
            rewards.append(self.act.spec(t, int(row.get('rewardId') or 0),
                                         int(row.get('rewardAmount') or 0)))
        applied, _ = self.ctx.reward.grant(pid, rewards, record=True, reason='continuousLogin')
        return OK, {'rewards': applied}

    # ============================================================ 通天塔（新）
    # 配置：sky_tower_level(300层) / sky_tower_monster / sky_tower_buff / sky_tower_reward
    # 服务端配置 skyTowerSettingConfig 是空壳 → 5 个值 [自编]
    KEY_TOWER = 'sky_tower'

    def _tower_levels(self):
        if not hasattr(self, '_tlevels'):
            self._tlevels = {int(r['floor']): r for r in rows('sky_tower_level')}
        return self._tlevels

    def _tower_state(self, pid):
        st = self.act.state(pid, self.KEY_TOWER)
        if 'currFloor' not in st:
            st = {'currFloor': 1, 'maxBigWinFloor': 1, 'currTotalStars': 0,
                  'currUsedStars': 0, 'climbTimes': 0, 'selectDifficult': 0,
                  'beginSkipFloor': 1, 'gainFloorBuff': [], 'dead': False,
                  'skipBattle': False, 'gainYesterdayReward': False,
                  'enemyAtkDebuff': 0, 'enemyDefDebuff': 0,
                  'selfAtkBuff': 0, 'selfDefBuff': 0, 'selfHpBuff': 0,
                  '_daily_date': time.strftime('%Y-%m-%d')}
            self.act.save_state(pid, self.KEY_TOWER, st)
        return st

    def _tower_settings(self):
        """[自编] 客户端要 5 个字段，原厂配置是空壳。数值取自 sky_tower_setting
        本地数组的合理位置 + 常见设计值。"""
        v = luaconf.as_list(cfg('sky_tower_setting')) or []
        return {
            'unlockLevel': int(v[0]) if len(v) > 0 else 25,
            'challengeChance': int(v[2]) if len(v) > 2 else 3,
            'startBuffMin': int(v[12]) if len(v) > 12 else 1,
            'startBuffMax': int(v[14]) if len(v) > 14 else 3,
            'startBuffConvertCoef': float(v[18]) if len(v) > 18 else 0.005,
        }

    def _tower_payload(self, pid, st=None):
        import assembler as A
        self._tower_state(pid)
        return A.build_sky_tower(self.db, pid)

    def sky_tower_info(self, pid):
        return OK, self._tower_payload(pid)

    def challenge_sky_tower(self, pid, floor, type_=0, version=0, win=True):
        """打一层。客户端读 win/monsterGroupId/currFloor/currTotalStars/... 决定演出。"""
        st = self._tower_state(pid)
        cur = int(floor or st.get('currFloor') or 1)
        sel = int(type_ or 0)
        settings = self._tower_settings()
        st['climbTimes'] = int(st.get('climbTimes') or 0) + 1
        st['selectDifficult'] = sel

        lv = self._tower_levels().get(cur, {})
        first_big_win = (cur == int(st.get('maxBigWinFloor') or 0) + 1 and sel == 0)
        stars = 3 if sel == 0 else (2 if sel == 1 else 1)
        clear_new = False

        if win:
            if cur >= int(st.get('maxBigWinFloor') or 1):
                st['maxBigWinFloor'] = cur + 1
            if first_big_win:
                st['currTotalStars'] = int(st.get('currTotalStars') or 0) + stars
            if int(lv.get('haveBuff') or 0):
                fb = st.setdefault('gainFloorBuff', [])
                if cur + 1 not in fb:
                    fb.append(cur + 1)
            st['dead'] = False
            levels = self._tower_levels()
            clear_new = cur >= (max(levels.keys()) if levels else 300)
            st['currFloor'] = cur + 1 if not clear_new else cur

        self.act.save_state(pid, self.KEY_TOWER, st)
        pack = G.build_battle_response(100101, 1)
        pack['win'] = bool(win)
        pack['monsterGroupId'] = self._tower_monster_group(cur)
        payload = dict(pack)
        settings_ok = int(st['climbTimes']) < int(settings['challengeChance'])
        payload.update({
            'currFloor': int(st['currFloor']),
            'currTotalStars': int(st.get('currTotalStars') or 0),
            'firstTimeBigWin': first_big_win,
            'clearNewBabel': clear_new,
            'forbidSkip': not first_big_win,
            'haveTimesLeft': settings_ok,
            'selectDifficult': sel,
            'haveReward': int(lv.get('haveReward') or 0) == 1,
        })
        return OK, payload

    def _tower_monster_group(self, floor):
        for r in rows('sky_tower_monster'):
            if int(r.get('startFloor') or 0) <= floor <= int(r.get('endFloor') or 0):
                idx = random.randint(0, 9)
                return int(r.get('randomMonsterGroup%d' % idx) or 0)
        return 0

    def reset_climb_data(self, pid, type_=0):
        st = self._tower_state(pid)
        st['climbTimes'] = 0
        st['dead'] = False
        self.act.save_state(pid, self.KEY_TOWER, st)
        return OK, {}

    def gain_floor_addition(self, pid, floor=None):
        """层数奖励（haveBuff 层给的加成）。"""
        st = self._tower_state(pid)
        f = int(floor or st.get('beginSkipFloor') or 1)
        got, applied = self.act.claim_once(
            pid, 'tower_floor', f, [self.act.spec(G.RE_GEMS, 0, 20)], reason='towerFloor')
        return OK, {'rewards': applied}

    def gain_yesterday_addition(self, pid):
        st = self._tower_state(pid)
        if st.get('gainYesterdayReward'):
            return OK, {'rewards': []}
        st['gainYesterdayReward'] = True
        self.act.save_state(pid, self.KEY_TOWER, st)
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, 20000)], record=True, reason='towerYesterday')
        return OK, {'rewards': applied}

    def gain_tower_rank_rewards(self, pid):
        """排名奖励：按 sky_tower_reward 的 rank→rewardId 映射。客户端读 rewards。"""
        rs = rows('sky_tower_reward')
        rank = self._tower_rank(pid)
        row = next((r for r in rs if int(r.get('rank') or 0) == rank), None)
        if not row:
            row = rs[-1] if rs else None
        if not row:
            return OK, {'rewards': []}
        got, applied = self.act.claim_once(pid, 'tower_rank', int(row['rank']),
                                           self.act.pkg(row.get('rewardId')),
                                           reason='towerRank')
        return OK, {'rewards': applied}

    def _tower_rank(self, pid):
        st = self._tower_state(pid)
        floor = int(st.get('maxBigWinFloor') or 1)
        # [自编] 没有跨玩家排行时按层数折算名次
        return max(1, min(20, 21 - (floor // 15) if floor else 20))

    def tower_skip_battle(self, pid, floor=None):
        """天关扫荡。

        ⚠️ 客户端天关界面（SkyTowerSkipBattleRequest 的回调）会读 `data.rewards`
           弹奖励展示；返回 `{}` 会崩。这里按当前层数折算一笔金币真发下去。
        """
        st = self._tower_state(pid)
        st['skipBattle'] = True
        if floor:
            st['beginSkipFloor'] = int(floor)
        self.act.save_state(pid, self.KEY_TOWER, st)
        cur = max(1, int(st.get('currFloor') or 1))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, cur * 100)],
            record=True, reason='towerSkipBattle')
        return OK, {'rewards': applied}

    def tower_skip_gain_add(self, pid):
        return self.gain_floor_addition(pid)

    def tower_skip_gain_rewards(self, pid):
        return self.gain_tower_rank_rewards(pid)

    # ============================================================ 旧通天塔（babel）
    KEY_BABEL = 'babel'

    def babel_info(self, pid):
        st = self.act.state(pid, self.KEY_BABEL)
        return OK, {'babelInfo': {'floor': int(st.get('floor') or 1),
                                  'maxFloor': int(st.get('maxFloor') or 1)}}

    def challenge_babel(self, pid, params=None):
        st = self.act.state(pid, self.KEY_BABEL)
        f = int((params or {}).get('floor') or st.get('floor') or 1)
        st['floor'] = f + 1
        st['maxFloor'] = max(int(st.get('maxFloor') or 1), f)
        self.act.save_state(pid, self.KEY_BABEL, st)
        pack = G.build_battle_response(100101, 1)
        pack['win'] = True
        pack['selectId'] = int((params or {}).get('selectId') or 0)
        return OK, pack

    def reset_babel(self, pid):
        self.act.save_state(pid, self.KEY_BABEL, {'floor': 1, 'maxFloor': 1})
        return OK, {}

    def gain_auto_climb_reward(self, pid, speed_up=False):
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, 10000)], record=True, reason='autoClimb')
        return OK, {'rewards': applied}

    def start_auto_climb(self, pid):
        """一键天关开始。

        ⚠️ 客户端回调会读 `data.currFloor` 和 `data.rewards`，返回 `{}` 会崩。
        """
        st = self._tower_state(pid)
        cur = max(1, int(st.get('currFloor') or 1))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, cur * 50)],
            record=True, reason='autoClimbStart')
        return OK, {'currFloor': cur, 'rewards': applied}

    # ============================================================ 世界 Boss / 抢亲战
    KEY_WB = 'world_boss'

    def _wb_levels(self):
        if not hasattr(self, '_wblevels'):
            self._wblevels = rows('world_boss_level')
        return self._wblevels

    def world_boss_info(self, pid):
        st = self.act.state(pid, self.KEY_WB)
        levels = self._wb_levels()
        level = int(st.get('level') or 1)
        row = next((r for r in levels if int(r.get('level') or r.get('id') or 0) == level), levels[0] if levels else {})
        maxhp = int(row.get('hp') or 18596000)
        hp = int(st.get('hp') if st.get('hp') is not None else maxhp)
        damage = int(st.get('damage') or 0)
        return OK, {
            'worldBossMonster': {'level': level, 'totalHp': maxhp, 'leftHp': hp,
                'challengeTime': int(st.get('bossChallengeTime') or 0),
                'normalTextKey': 'worldBoss_normalReward', 'gainAutoReward': bool(st.get('gainAutoReward'))},
            'worldBossUserStatus': {'inspireAddition': float(st.get('inspireTimes') or 0) * 0.05,
                'totalDamage': damage, 'challengeTime': int(st.get('challengeTime') or 0),
                'gainChallengeReward': bool(self.act.claims(pid, self.KEY_WB))},
            'worldBossUser': {'autoChallenge': bool(st.get('autoChallenge'))},
            'worldBossRanks': [], 'worldBossRecords': [], 'rank': 1 if damage else -1,
            'worldBossHp': hp, 'worldBossMaxHp': maxhp,
            'inspireTimes': int(st.get('inspireTimes') or 0), 'damage': damage,
            'autoChallenge': bool(st.get('autoChallenge')), 'rewards': [],
        }

    def challenge_world_boss(self, pid, params=None):
        # Keep the existing simulation for now, but persist one consistent HP pool.
        with self.db.tx():
            st = self.act.state(pid, self.KEY_WB)
            _, info = self.world_boss_info(pid)
            maxhp = info['worldBossMaxHp']; hp = info['worldBossHp']
            if hp <= 0: return 714310, None
            dmg = min(hp, random.randint(10000, 50000))
            st['damage'] = int(st.get('damage') or 0) + dmg
            st['hp'] = hp - dmg
            st['challengeTime'] = int(time.time())
            self.act.save_state(pid, self.KEY_WB, st)
            pack = G.build_battle_response(100101, 1)
            pack['win'] = st['hp'] == 0
            pack.update(bossHp=st['hp'], bossHpMax=maxhp, damage=dmg)
            return OK, pack

    def gain_world_boss_rewards(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, 'world_boss', int(self.db.today()),
            [self.act.spec(G.RE_GEMS, 0, 100)], reason='worldBossReward')
        return OK, {'rewards': applied, 'succ': bool(applied)}

    def inspire_world_boss(self, pid, params=None):
        st = self.act.state(pid, self.KEY_WB)
        st['inspireTimes'] = int(st.get('inspireTimes') or 0) + 1
        self.act.save_state(pid, self.KEY_WB, st)
        return OK, {'rewards': [], 'succ': True}

    def set_auto_world_boss(self, pid, params=None):
        st = self.act.state(pid, self.KEY_WB)
        st['autoChallenge'] = bool((params or {}).get('autoChallenge', True))
        self.act.save_state(pid, self.KEY_WB, st)
        return OK, {'rewards': [], 'succ': True}

    # ============================================================ 多人 Boss / 年兽
    KEY_MB = 'multiplayer_boss'

    def _mb_levels(self):
        if not hasattr(self, '_mblevels'):
            self._mblevels = rows('multiplayer_boss_level')
        return self._mblevels

    def _mb_state(self, pid):
        st = self.act.state(pid, self.KEY_MB)
        if 'bossHp' not in st:
            lv = self._mb_levels()
            st = {'bossHp': int((lv[-1] if lv else {}).get('hp') or 500000),
                  'bossHpMax': int((lv[-1] if lv else {}).get('hp') or 500000),
                  'damage': 0, 'rank': 0, 'battleType': 0,
                  '_daily_date': time.strftime('%Y-%m-%d')}
            self.act.save_state(pid, self.KEY_MB, st)
        return st

    def multiplayer_boss_info(self, pid):
        st = self._mb_state(pid)
        rows_ = self._mb_levels()
        # MultiplayerBossScene / getTipInfo expect top-level activeBossInfo +
        # bossChallengeRecord (not a nested bossInfo-only shell).
        return OK, {
            'activeBossInfo': [],
            'bossChallengeRecord': [],
            'rank': int(st.get('rank') or 0),
            'gainedRankReward': True,
            'bossInfo': {
                'bossId': int((rows_[-1] if rows_ else {}).get('id') or 1),
                'bossHp': int(st['bossHp']),
                'bossHpMax': int(st['bossHpMax']),
                'level': 1,
                'round': 1,
            },
            'rankList': [],
            'actionPower': int(self.r.player.player(pid)['action_power']),
            'actionPowerLastUpdateTime': int(
                self.r.player.player(pid)['action_power_last_update_time'] or 0),
            'battleType': int(st.get('battleType') or 0),
            'globalReturnScene': False,
        }

    def challenge_multiplayer_boss(self, pid, params=None):
        p = self.r.player.player(pid)
        if int(p['action_power']) < 10:
            return E_NOT_ENOUGH, None
        self.r.player.add_currency(pid, 'action_power', -10)
        st = self._mb_state(pid)
        dmg = random.randint(20000, 80000)
        st['damage'] = int(st.get('damage') or 0) + dmg
        st['bossHp'] = max(0, int(st['bossHp']) - dmg)
        st['battleType'] = int((params or {}).get('battleType') or 0)
        self.act.save_state(pid, self.KEY_MB, st)
        pack = G.build_battle_response(100101, 1)
        pack.update({'win': True, 'bossHp': int(st['bossHp']),
                     'bossHpMax': int(st['bossHpMax']), 'damage': dmg,
                     'bossInfo': {'bossId': 1, 'bossHp': int(st['bossHp']),
                                  'bossHpMax': int(st['bossHpMax'])},
                     'rankList': []})
        return OK, pack

    def multiplayer_boss_rank(self, pid):
        st = self._mb_state(pid)
        return OK, {'rankList': [], 'myRank': int(st.get('rank') or 0),
                    'myDamage': int(st.get('damage') or 0)}

    def multiplayer_boss_damage(self, pid):
        st = self._mb_state(pid)
        return OK, {'damage': int(st.get('damage') or 0)}

    def multiplayer_boss_left_hp(self, pid):
        st = self._mb_state(pid)
        return OK, {'bossHp': int(st['bossHp']), 'bossHpMax': int(st['bossHpMax'])}

    def gain_multiplayer_boss_rank_reward(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, 'mp_boss_rank', int(self.db.today()),
            [self.act.spec(G.RE_GEMS, 0, 200)], reason='mpBossRank')
        return OK, {'rewards': applied}

    def gain_multiplayer_boss_participation_reward(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, 'mp_boss_part', int(self.db.today()),
            [self.act.spec(G.RE_COIN, 0, 50000)], reason='mpBossPart')
        return OK, {'rewards': applied}

    def buy_action_power(self, pid, params=None):
        p = self.r.player.player(pid)
        cost = 50
        if self.ctx.player.spend_gems(pid, cost) is None:
            return E_NOT_ENOUGH, None
        self.r.player.add_currency(pid, 'action_power', 100)
        return OK, {'rewards': [], 'requisite': self.act.spec(G.RE_GEMS, 0, cost)}

    # ============================================================ 银币骰子（六马奔腾）
    # 客户端读 gameInit.sharkDice + 这些接口的响应
    KEY_DICE = 'dice'

    def _dice_state(self, pid):
        st = self.act.state(pid, self.KEY_DICE)
        if 'diceStates' not in st:
            st = {'diceStates': [0, 0, 0, 0, 0, 0], 'coins': 0, 'gainedReward': False,
                  'throwDiceCount': 0, 'changeDiceLuckCount': 0,
                  'changeLuckCountPerThrow': 0}
            self.act.save_state(pid, self.KEY_DICE, st)
        return st

    def _dice_payload(self, st):
        return {'diceStates': st.get('diceStates') or [0] * 6,
                'coins': int(st.get('coins') or 0),
                'gainedCoin': int(st.get('coins') or 0),
                'diceNewRewards': st.get('diceNewRewards') or [],
                'throwDiceCount': int(st.get('throwDiceCount') or 0),
                'changeDiceLuckCount': int(st.get('changeDiceLuckCount') or 0),
                'changeLuckCountPerThrow': int(st.get('changeLuckCountPerThrow') or 0)}

    def throw_dice(self, pid, params=None):
        st = self._dice_state(pid)
        faces = st.get('diceStates') or [0] * 6
        # 掷一个还没被翻开的格子
        closed = [i for i, v in enumerate(faces) if not v]
        if closed:
            i = random.choice(closed)
            faces[i] = random.randint(1, 6)
            st['coins'] = int(st.get('coins') or 0) + faces[i] * 100
        st['diceStates'] = faces
        st['throwDiceCount'] = int(st.get('throwDiceCount') or 0) + 1
        self.act.save_state(pid, self.KEY_DICE, st)
        return OK, self._dice_payload(st)

    def gain_dice_reward(self, pid, params=None):
        st = self._dice_state(pid)
        coins = int(st.get('coins') or 0)
        if coins and not st.get('gainedReward'):
            st['gainedReward'] = True
            self.act.save_state(pid, self.KEY_DICE, st)
            applied, _ = self.ctx.reward.grant(
                pid, [self.act.spec(G.RE_COIN, 0, coins)], record=True, reason='diceReward')
            return OK, self._dice_payload(st)
        return OK, self._dice_payload(st)

    def change_dice_luck(self, pid, params=None):
        st = self._dice_state(pid)
        st['changeDiceLuckCount'] = int(st.get('changeDiceLuckCount') or 0) + 1
        st['changeLuckCountPerThrow'] = int(st.get('changeLuckCountPerThrow') or 0) + 1
        faces = st.get('diceStates') or [0] * 6
        closed = [i for i, v in enumerate(faces) if not v]
        if closed:
            i = random.choice(closed)
            faces[i] = 6
        st['diceStates'] = faces
        self.act.save_state(pid, self.KEY_DICE, st)
        return OK, self._dice_payload(st)

    # ============================================================ 吹气球
    KEY_BALLOON = 'balloon'

    def _balloon_state(self, pid):
        st = self.act.state(pid, self.KEY_BALLOON)
        day = time.strftime('%Y-%m-%d')
        if st.get('_daily_date') != day:
            st = {'point': 0, 'gainedPointIds': [], 'gainedRank': False,
                  'balloonLevel': 0, 'receiveTimes': 0, '_daily_date': day,
                  'gainYesterdayPointReward': False}
            self.act.save_state(pid,self.KEY_BALLOON,st)
        return st

    def _balloon_payload(self, st):
        return {'currPoint': int(st.get('point') or 0), 'balloonRanks': [],
                'balloonLevel': int(st.get('balloonLevel') or 0),
                'receiveTimes': int(st.get('receiveTimes') or 0),
                'gainYesterdayPointReward': bool(st.get('gainYesterdayPointReward'))}

    def get_balloon_info(self, pid):
        return OK,self._balloon_payload(self._balloon_state(pid))

    def charge_balloon(self, pid, params=None):
        from meta_payload import get_meta_payload
        cfg = get_meta_payload()['activityBalloonConfig']
        with self.db.tx():
            st = self._balloon_state(pid)
            level = int(st.get('balloonLevel') or 0)
            levels = cfg['balloonLevelMetas']
            if level >= len(levels)-1 or int(st.get('receiveTimes') or 0) >= int(cfg['gainsChance']):
                return E_NOT_ENOUGH,None
            if (params or {}).get('ensureSuccess'):
                if self.ctx.player.spend_gems(pid,int(levels[level]['money'])) is None: return E_NOT_ENOUGH,None
            else:
                meta = int(cfg['propId']);cost = int(cfg['cost'])
                if self.r.asset.prop(pid,meta)<cost: return E_NOT_ENOUGH,None
                self.r.asset.add_prop(pid,meta,-cost)
            # Original stone success probability is unavailable; local mode guarantees a level.
            st['balloonLevel'] = level+1
            self.act.save_state(pid,self.KEY_BALLOON,st)
            return OK,self._balloon_payload(st)

    def gain_balloon_point(self, pid, params=None):
        from meta_payload import get_meta_payload
        cfg = get_meta_payload()['activityBalloonConfig']
        with self.db.tx():
            st=self._balloon_state(pid);level=int(st.get('balloonLevel') or 0)
            if level<=0 or int(st.get('receiveTimes') or 0)>=int(cfg['gainsChance']): return E_NOT_ENOUGH,None
            st['point']=int(st.get('point') or 0)+int(cfg['balloonLevelMetas'][level]['point'])
            st['balloonLevel']=0;st['receiveTimes']=int(st.get('receiveTimes') or 0)+1
            self.act.save_state(pid,self.KEY_BALLOON,st)
            return OK,self._balloon_payload(st)

    def gain_balloon_point_reward(self, pid, reward_id):
        from meta_payload import get_meta_payload
        rid=int(reward_id or 0)
        cfg=get_meta_payload()['activityBalloonConfig']
        if rid == 0:
            with self.db.tx():
                st=self._balloon_state(pid)
                ids=[int(r['id']) for r in cfg['balloonPointRewardMetas']
                     if int(r['pointSection'])<=int(st.get('point') or 0)
                     and int(r['id']) not in st.get('gainedPointIds',[])]
                if not ids: return E_NOT_ENOUGH,None
                applied=[]
                for reward_id in ids:
                    code,payload=self.gain_balloon_point_reward(pid,reward_id)
                    if code != OK: raise ValueError('balloon claim changed inside transaction')
                    applied.extend(payload['rewards'])
                return OK,{'balloonRanks':[],'rewards':applied}
        row=next((r for r in cfg['balloonPointRewardMetas'] if int(r['id'])==rid),None)
        if not row: return E_NOT_ENOUGH,None
        with self.db.tx():
            st=self._balloon_state(pid)
            if int(st.get('point') or 0)<int(row['pointSection']) or rid in st.get('gainedPointIds',[]):
                return E_NOT_ENOUGH,None
            specs=[self.act.spec(int(row['rewardType%d'%i]),int(row.get('rewardId%d'%i) or 0),int(row.get('rewardNum%d'%i) or 0))
                   for i in range(1,5) if int(row.get('rewardType%d'%i) or 0)]
            applied,_=self.ctx.reward.grant(pid,specs,record=True,reason='balloonPoint')
            st.setdefault('gainedPointIds',[]).append(rid)
            self.act.save_state(pid,self.KEY_BALLOON,st)
            return OK,{'balloonRanks':[],'rewards':applied}

    def gain_balloon_rank_reward(self, pid, params=None):
        # No completed local ranking snapshot; do not invent a rank payout.
        return E_NOT_ENOUGH,None

    # ============================================================ 通缉令
    KEY_WANTED = 'wanted'

    def _wanted_state(self, pid):
        st = self.act.state(pid, self.KEY_WANTED)
        today = time.strftime('%Y-%m-%d')
        if st.get('_daily_date') != today:
            st = {'wantedId': 1, 'level': 1, 'wanteds': 0, 'refresh': False, '_daily_date': today}
            self.act.save_state(pid, self.KEY_WANTED, st)
        return st

    def get_wanted_info(self, pid):
        st = self._wanted_state(pid)
        # Activity_WantedLayer reads wantedInfo.wantedConfigId / .wanteds
        wid = int(st.get('wantedId') or st.get('wantedConfigId') or 1)
        return OK, {
            'wantedInfo': {
                'wantedConfigId': wid,
                'wanteds': int(st.get('wanteds') or 0),
                'refresh': bool(st.get('refresh')),
                'level': int(st.get('level') or 1),
                'finished': False,
            },
            'wantedInfos': [],
            'wantedTasks': [],
            'refreshTimes': int(st.get('refreshTimes') or 5),
        }

    def refresh_wanted(self, pid, minimum=0):
        cfg = self.ctx.meta_payload()['activityWantedConfig']
        with self.db.tx():
            st = self._wanted_state(pid)
            if int(st.get('wanteds') or 0) >= int(cfg['completeNum']): return E_NOT_ENOUGH, None
            if int(st.get('wantedId') or 1) >= len(cfg['questRewards']): return E_NOT_ENOUGH, None
            cost = int(cfg['refreshPrice']) if st.get('refresh') else 0
            if cost and self.ctx.player.spend_gems(pid, cost) is None: return E_NOT_ENOUGH, None
            # Local fallback: deterministic upgrade; original star probabilities unavailable.
            st['wantedId'] = min(len(cfg['questRewards']), int(st.get('wantedId') or 1) + 1)
            st['refresh'] = True
            self.act.save_state(pid, self.KEY_WANTED, st)
            return OK, {'wantedId': st['wantedId'], 'wantedInfo': {'wantedConfigId': st['wantedId'],
                'wanteds': int(st.get('wanteds') or 0), 'refresh': True}}

    def challenge_wanted(self, pid, params=None):
        from .battle import chapter_battle
        cfg = self.ctx.meta_payload()['activityWantedConfig']
        with self.db.tx():
            st = self._wanted_state(pid)
            if int(st.get('wanteds') or 0) >= int(cfg['completeNum']): return E_NOT_ENOUGH, None
            # Original wanted enemy table is missing; use the known first chapter encounter.
            try: pack = chapter_battle(self.db, pid, 100101, 1)
            except ValueError: return E_NOT_ENOUGH, None
            if pack['win']:
                tier = cfg['questRewards'][int(st.get('wantedId') or 1) - 1]
                rewards = [self.act.spec(G.RE_PROP, int(tier['contentID1']), int(tier['contentNum1'])),
                           self.act.spec(G.RE_COIN, 0, int(tier['contentNum2']))]
                pack['rewards'], _ = self.ctx.reward.grant(pid, rewards, record=True, reason='wanted')
                st['wanteds'] = int(st.get('wanteds') or 0) + 1
                st['wantedId'] = 1; st['refresh'] = False
                self.act.save_state(pid, self.KEY_WANTED, st)
            pack['wantedId'] = int(st.get('wantedId') or 1)
            return OK, pack

    # ============================================================ 秒杀
    KEY_SECKILL = 'seckill'

    def get_seckill_info(self, pid):
        p = self.r.player.player(pid)
        gs = G.game_setting_config()
        items = []
        for r in rows('daily_shop')[:8]:
            items.append({'id': int(r.get('id') or 0),
                          'itemType': int(r.get('itemType') or G.RE_PROP),
                          'metaId': int(r.get('metaId') or 0),
                          'amount': int(r.get('amount') or 1),
                          'price': int(r.get('price') or 100),
                          'moneyType': int(r.get('moneyType') or G.RE_GEMS),
                          'leftNum': 99})
        return OK, {'seckillItems': items}

    def buy_seckill_item(self, pid, item_id):
        info_code, info = self.get_seckill_info(pid)
        it = next((x for x in info['seckillItems'] if x['id'] == int(item_id or 0)), None)
        if not it:
            return OK, {'rewards': []}
        if int(it['moneyType']) == G.RE_GEMS:
            if self.ctx.player.spend_gems(pid, int(it['price'])) is None:
                return E_NOT_ENOUGH, None
        else:
            p = self.r.player.player(pid)
            if int(p['gold']) < int(it['price']):
                return E_NOT_ENOUGH, None
            self.r.player.add_currency(pid, 'gold', -int(it['price']))
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(it['itemType'], it['metaId'], it['amount'])],
            record=True, reason='seckill')
        return OK, {'rewards': applied}

    # ============================================================ 神兵谱
    KEY_TB = 'treasurebox'

    def _tb_state(self, pid):
        st = self.act.state(pid, self.KEY_TB)
        if 'point' not in st:
            st = {'point': 0, 'gainedPointIds': [], 'gainedRank': False,
                  'featureBeginSeconds': int(time.time())}
            self.act.save_state(pid, self.KEY_TB, st)
        return st

    def treasurebox_info(self, pid):
        st = self._tb_state(pid)
        return OK, {'myPoints': int(st.get('point') or 0), 'treasureboxPointsInfo': {
            'point': int(st.get('point') or 0),
            'featureBeginSeconds': int(st.get('featureBeginSeconds') or 0),
            'gainedPointRewards': st.get('gainedPointIds') or [],
            'gainedRankReward': bool(st.get('gainedRank')),
        }, 'treasureboxPointsRanks': []}

    def gain_treasurebox_point_reward(self, pid, reward_id):
        st = self._tb_state(pid)
        rid = int(reward_id or 0)
        gained = st.setdefault('gainedPointIds', [])
        if rid in gained:
            return OK, {'rewards': []}
        gained.append(rid)
        self.act.save_state(pid, self.KEY_TB, st)
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_COIN, 0, rid * 2000)], record=True, reason='tbPoint')
        return OK, {'rewards': applied}

    def gain_treasurebox_rank_reward(self, pid, params=None):
        st = self._tb_state(pid)
        if st.get('gainedRank'):
            return OK, {'rewards': []}
        st['gainedRank'] = True
        self.act.save_state(pid, self.KEY_TB, st)
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_GEMS, 0, 150)], record=True, reason='tbRank')
        return OK, {'rewards': applied}

    # ============================================================ 扭蛋积分 / 小玉嫁到
    KEY_GP = 'gacha_points'
    KEY_CROSS_GACHA = 'cross_gacha'

    def gacha_points_info(self, pid):
        st = self.act.state(pid, self.KEY_GP)
        points = self.r.player.counter(pid, 'gacha_points')
        return OK, {'myPoints': int(points), 'gachaPointsRanks': [], 'activityGachaInfo': {
            'point': int(st.get('point') or 0),
            'featureBeginSeconds': int(st.get('featureBeginSeconds') or time.time()),
            'rank': 0}, 'gpGainedReward': st.get('gained') or []}

    def gain_gacha_points_rewards(self, pid, params=None):
        st = self.act.state(pid, self.KEY_GP)
        gained = st.setdefault('gained', [])
        if gained:
            return OK, {'rewards': []}
        gained.append(1)
        self.act.save_state(pid, self.KEY_GP, st)
        applied, _ = self.ctx.reward.grant(
            pid, [self.act.spec(G.RE_GEMS, 0, 100)], record=True, reason='gachaPoints')
        return OK, {'rewards': applied}

    def cross_gacha_info(self, pid):
        st = self.act.state(pid, self.KEY_CROSS_GACHA)
        return OK, {'crossGachaUserInfo': {
            'point': int(st.get('point') or 0),
            'gainedPointRewardIds': st.get('gainedPoint') or [],
            'gainedRankReward': bool(st.get('gainedRank')),
            'gainedMysteriousReward': bool(st.get('gainedMysterious'))},
            'crossGachaRanks': []}

    # ============================================================ 多重好礼 / 累充反馈
    KEY_CONSUME = 'consume_reward'

    def consume_reward_info(self, pid):
        claimed = self.act.claims(pid, self.KEY_CONSUME)
        return OK, {'recharges': [], 'rewards': [],
                    'gained': sorted(claimed)}

    def gain_consume_reward(self, pid, reward_id):
        rid = int(reward_id or 0)
        got, applied = self.act.claim_once(
            pid, self.KEY_CONSUME, rid,
            [self.act.spec(G.RE_GEMS, 0, rid * 50)], reason='consumeReward')
        return OK, {'rewards': applied}

    # ============================================================ 春节八天乐
    KEY_DAY = 'day_reward'

    def _day_rewards(self):
        return (G.game_setting_config() and None) or []

    def gain_day_reward(self, pid, day_reward_id):
        rid = int(day_reward_id or 0)
        got, applied = self.act.claim_once(
            pid, self.KEY_DAY, rid,
            [self.act.spec(G.RE_COIN, 0, 10000), self.act.spec(G.RE_GEMS, 0, 50)],
            reason='dayReward')
        return OK, {'rewards': applied}

    # ============================================================ 桃园结义
    KEY_SWORN = 'sworn'

    def gain_sworn_reward(self, pid, sworn_reward_id):
        rid = int(sworn_reward_id or 0)
        got, applied = self.act.claim_once(
            pid, self.KEY_SWORN, rid,
            [self.act.spec(G.RE_GEMS, 0, 60)], reason='swornReward')
        return OK, {'rewards': applied}

    # ============================================================ 点赞
    KEY_PRAISE = 'praise'

    def record_praise_id(self, pid, praise_id):
        """记录点赞/被赞。

        ⚠️ 客户端 `Activity_PraiseLayer.lua:171/174` 会用 `response.data.rewards`
           直接调 `RewardManager:getReward` 并弹 `RewardReviewPanel`
           （`{rewardList = response.data.rewards}`）——返回 `{}` 会让它 pairs(nil) 崩。
           所以这里必须真的发一份点赞奖励并把 rewards 带回去。
        """
        rid = int(praise_id or 0)
        self.r.social.add_praise(pid, rid, time.strftime('%Y-%m-%d'))
        got, applied = self.act.claim_once(
            pid, self.KEY_PRAISE, 100000 + rid,
            [self.act.spec(G.RE_COIN, 0, 5000)], reason='praiseRecord')
        return OK, {'rewards': applied}

    def gain_praise_reward(self, pid, praise_id):
        rid = int(praise_id or 0)
        got, applied = self.act.claim_once(
            pid, self.KEY_PRAISE, rid,
            [self.act.spec(G.RE_GEMS, 0, 30)], reason='praiseReward')
        return OK, {'rewards': applied}

    # ============================================================ 恭贺新禧（烟花）
    KEY_FIRE = 'fireworks'

    def setoff_fireworks(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, self.KEY_FIRE, int(self.db.today()),
            [self.act.spec(G.RE_COIN, 0, 5000), self.act.spec(G.RE_GEMS, 0, 10)],
            reason='fireworks')
        return OK, {'rewards': applied}

    # ============================================================ 马上升财 / 福星
    KEY_FORTUNE = 'fortune'

    def gain_fortune_rewards(self, pid, params=None):
        st = self.act.state(pid, self.KEY_FORTUNE)
        rid = int(st.get('nextId') or 1)
        got, applied = self.act.claim_once(
            pid, self.KEY_FORTUNE, rid,
            [self.act.spec(G.RE_COIN, 0, rid * 2000)], reason='fortune')
        st['nextId'] = rid + 1
        self.act.save_state(pid, self.KEY_FORTUNE, st)
        return OK, {'id': rid, 'rewards': applied}

    # ============================================================ 冲级活动
    KEY_LR = 'level_race'

    def level_race_info(self, pid):
        p = self.r.player.player(pid)
        return OK, {'lrUserLevel': int(p['level']), 'levelRaceRanks': [],
                    'levelRaceRewards': []}

    def gain_level_race_rewards(self, pid, params=None):
        got, applied = self.act.claim_once(
            pid, self.KEY_LR, int(self.db.today()),
            [self.act.spec(G.RE_GEMS, 0, 80)], reason='levelRace')
        return OK, {'rewards': applied}

    # ============================================================ 月卡
    KEY_MONTHCARD = 'month_card'

    def get_accumulate_gems(self, pid):
        p = self.r.player.player(pid)
        return OK, {'accumulateGems': int(p['recharge_gems'])}

    def buy_month_gem_card(self, pid, params=None):
        from meta_payload import get_meta_payload
        setting = get_meta_payload()['activitySettingConfig']['gemCardConfig']
        cost = int(setting['gemCardGemCost'])
        now = int(time.time())
        with self.db.tx() as con:
            if self.ctx.player.spend_gems(pid, cost) is None:
                return E_NOT_ENOUGH, None
            old = con.execute("SELECT * FROM player_gem_card WHERE player_id=? AND meta_id=1 ORDER BY end_time DESC LIMIT 1", (pid,)).fetchone()
            deadline = max(now, int(old['end_time']) if old else 0) + int(setting['gemCardLastTime']) * 86400
            if old:
                con.execute('UPDATE player_gem_card SET end_time=?,status=1 WHERE gem_card_id=?', (deadline, old['gem_card_id']))
            else:
                con.execute("INSERT INTO player_gem_card(player_id, product_id, meta_id,"
                            " start_time, end_time, status) VALUES (?,'he_month_card',1,?,?,1)",
                            (pid, now, deadline))
        return OK, {'rewards': [], 'monthGemCardDeadline': deadline, 'buyConditionGem': int(setting.get('gemCardBuyConditionGem') or 0)}

    def month_card_result(self, pid, params=None):
        row = self.db.one("SELECT * FROM player_gem_card WHERE player_id=? AND status=1"
                          " ORDER BY end_time DESC LIMIT 1", (pid,))
        return OK, {'monthGemCardDeadline': int(row['end_time']) if row else 0,
                    'remainingDays': max(0, int(((row['end_time'] if row else 0)
                                                 - time.time()) // 86400)) if row else 0}

    # ============================================================ 月历签到
    KEY_SIGNIN = 'sign_in'

    def sign_in(self, pid, type_=0):
        """月历签到领奖。奖励表用本地 consecutive_login_reward 的前 7 天等价物；
        客户端只要求 rewards 存在。"""
        today = time.strftime('%Y-%m-%d')
        day = int(time.strftime('%d'))
        rid = int(type_) or day
        got, applied = self.act.claim_once(
            pid, self.KEY_SIGNIN, rid,
            [self.act.spec(G.RE_COIN, 0, 100 * max(1, day)),
             self.act.spec(G.RE_GEMS, 0, 20)],
            reason='signIn')
        with self.db.tx() as con:
            con.execute("INSERT INTO player_sign_in(player_id, month_key, login_days_month,"
                        " last_reward_time, gained_day_ids_json)"
                        " VALUES (?,?,1,?,'[]') ON CONFLICT(player_id) DO UPDATE SET"
                        " login_days_month = login_days_month + 1,"
                        " last_reward_time = excluded.last_reward_time",
                        (int(pid), time.strftime('%Y-%m'), int(time.time())))
        row = self.db.one("SELECT login_days_month FROM player_sign_in WHERE player_id=?",
                          (int(pid),))
        return OK, {'rewards': applied,
                    'currPoint': int(row['login_days_month']) if row else 1}

    # ============================================================ 以旧换新 / 易帅换将
    KEY_EXCHANGE = 'exchange_daily'

    def exchange_daily_info(self, pid):
        st = self.act.state(pid, self.KEY_EXCHANGE)
        today = time.strftime('%Y-%m-%d')
        if st.get('_daily_date') != today:
            st = {'_daily_date': today, 'exchangeTimes': 0, 'cardMetaIds': []}
            self.act.save_state(pid, self.KEY_EXCHANGE, st)
        return OK, {'cardExchangeDailyInfo': {
            'cardMetaIds': st.get('cardMetaIds') or [],
            'exchangeTimes': int(st.get('exchangeTimes') or 0)}}

    def refresh_card_exchange(self, pid, use_gold=False):
        st = self.act.state(pid, self.KEY_EXCHANGE)
        today = time.strftime('%Y-%m-%d')
        if st.get('_daily_date') != today:
            st = {'_daily_date': today, 'exchangeTimes': 0, 'cardMetaIds': []}
        if use_gold:
            if self.ctx.player.spend_gems(pid, 20) is None:
                return E_NOT_ENOUGH, None
        metas = [int(r['metaId']) for r in rows('card_meta')
                 if str(r.get('metaId', '')).isdigit()][:3]
        if not metas:
            metas = [102111, 102121, 102131]
        st['cardMetaIds'] = metas
        self.act.save_state(pid, self.KEY_EXCHANGE, st)
        return OK, {'cardExchangeDailyInfo': {
            'cardMetaIds': metas,
            'exchangeTimes': int(st.get('exchangeTimes') or 0)}}
