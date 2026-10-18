"""Activity entry contracts recovered from snzj-online-0.1.1.apk.

Only verified aliases share an implementation. Unknown purchase/battle actions
remain unimplemented rather than pretending to return successful empty data.
"""
import json
import time
import assembler as A
import gamedata as G
import luaconf
import meta_payload
from . import endpoint


@endpoint('clientPanelError')
def client_panel_error(api, params):
    pid = api.require_player()['player_id']
    panel = str(params.get('panel') or '')[:100]
    message = str(params.get('message') or '')[:2000]
    with api.db.tx() as con:
        con.execute('INSERT INTO unknown_rpc(player_id,method,params_json,create_time) VALUES (?,?,?,?)',
                    (pid, 'clientPanelError', json.dumps({'panel': panel, 'message': message}), int(time.time())))
    return {}


@endpoint('getDiceInfo')
def dice_info(api, params):
    svc = api.ctx.activities
    return svc._dice_payload(svc._dice_state(api.require_player()['player_id']))


@endpoint('getWeekReward')
def question_week_info(api, params):
    pid = api.require_player()['player_id']
    st = api.ctx.activities._q_state(pid)
    with api.db.tx():
        _, award = api.ctx.activities.question_week_reward(pid)
        return {'lastWeekNum': int(st.get('lastWeekNum') or 0),
                'thisWeekNum': int(st.get('thisWeekNum') or 0),
                'currVersion': int(time.time() // (7 * 86400)),
                'getWeeklyReward': bool(award.get('rewards')), 'rewards': award.get('rewards') or []}


@endpoint('getEatPeachInfo')
def peach_info(api, params):
    pid = api.require_player()['player_id']
    return {'lstEatPeachInfo': A.build_game_init(api.db, pid)['sharkUserExtend']['lstEatPeachInfo']}


@endpoint('getCowStageInfo')
def cow_info(api, params):
    pid = api.require_player()['player_id']
    st = api.ctx.activity.state(pid, 'cow_stage')
    return {'lstCowStageInfo': st.get('stages', []) if st.get('day') == api.db.today() else []}


@endpoint('challengeCowStage')
def cow_challenge(api, params):
    from services.battle import chapter_battle
    p = api.require_player(); pid = p['player_id']
    stage = next((r for r in luaconf.as_list(luaconf.load('cow_stage'))
                  if int(r['id']) == int(params.get('cowStageId') or 0)), None)
    if not stage: return 710071
    if int(p['level']) < int(stage['playerLevelLimit']): return 712301
    if int(p['energy']) < int(stage['consumeEnergy']): return 710513
    with api.db.tx():
        st = api.ctx.activity.state(pid, 'cow_stage')
        if st.get('day') != api.db.today(): st = {'day': api.db.today(), 'stages': []}
        info = next((r for r in st['stages'] if r['cowStageId'] == stage['id']), None)
        if info and info['challengeNums'] >= int(stage['maxChallengesPerDay']): return 714123
        battle = chapter_battle(api.db, pid, 0, event_override=stage)
        if battle['win']:
            rewards = G.roll_drop_packs([(int(stage.get('dropPackId%d' % i) or 0), float(stage.get('dropPackProb%d' % i) or 0)) for i in range(1,5)])
            rewards.append({'itemType': G.RE_COIN, 'amount': int(stage['coin'])})
            battle['rewards'], _ = api.ctx.reward.grant(pid, rewards, record=True, reason='cowStage')
            api.repos.player.add_currency(pid, 'energy', -int(stage['consumeEnergy']))
            if info: info['challengeNums'] += 1
            else: st['stages'].append({'cowStageId': int(stage['id']), 'challengeNums': 1})
            api.ctx.activity.save_state(pid, 'cow_stage', st)
        return battle


@endpoint('getAccumulateRechargeInfo')
@endpoint('getDailyRecharge')
def recharge_info(api, params):
    p = api.require_player()
    st = api.ctx.activity.state(p['player_id'], 'recharge')
    return {'rechargeGems': int(p['recharge_gems']), 'accumulateGems': int(p['recharge_gems']),
            'dailyRecharge': int(st.get('dailyRecharge') or 0),
            'gainedRewardIds': api.ctx.activity.claims(p['player_id'], 'charge_money'),
            'recharges': []}


@endpoint('getInvitationInfo')
def invitation_info(api, params):
    pid = api.require_player()['player_id']
    row = api.db.one('SELECT invite_code FROM player_invite_code WHERE player_id=?', (pid,))
    return {'sharkAccountInvitation': {'inviteCode': row['invite_code'] if row else '',
                'invitedNum': 0, 'gainedRewardIds': [], 'inviterUid': 0, 'invitePlayerNum': 0, 'gainedInviteRewardNum': 0, 'hasInvited': False},
            'deviceHasInvited': False, 'invitePlayerNum': 0, 'gainedInviteRewardNum': 0, 'hasInvited': False}


@endpoint('exchangeMysteriousItem')
def mysterious_exchange(api, params):
    pid = api.require_player()['player_id']
    item_id = int(params.get('ID') or params.get('id') or 0)
    config = meta_payload.get_meta_payload().get('activityMysteriousExchangeConfig', {})
    item = next((r for r in config.get('exchangeMetas', []) if int(r['id']) == item_id), None)
    if not item: return 710071
    with api.db.tx():
        state = api.ctx.activity.state(pid, 'mysterious_exchange')
        if state.get('day') != api.db.today(): state = {'day': api.db.today(), 'times': {}}
        used = int(state['times'].get(str(item_id), 0))
        if used >= int(item['mysteriousShopNum']): return 710001
        balance = api.db.one('SELECT amount FROM player_mysterious_coin WHERE player_id=? AND meta_id=?',
                             (pid, int(item['coinId'])))
        if not balance or int(balance['amount']) < int(item['coinNum']): return 710513
        api.repos.asset.add_mysterious_coin(pid, int(item['coinId']), -int(item['coinNum']))
        rewards, _ = api.ctx.reward.grant(pid, [
            {'itemType': int(item['goodsType']), 'metaId': int(item['goodsId']), 'amount': int(item['goodsNum'])}
        ], record=True, reason='mysteriousExchange')
        state['times'][str(item_id)] = used + 1
        api.ctx.activity.save_state(pid, 'mysterious_exchange', state)
        return {'rewards': rewards}


@endpoint('gainedMonthGemCardReward')
def gain_month_card(api, params):
    pid = api.require_player()['player_id']
    with api.db.tx():
        row = api.db.one('SELECT * FROM player_gem_card WHERE player_id=? AND meta_id=1 AND status=1 ORDER BY end_time DESC LIMIT 1', (pid,))
        today = time.strftime('%Y-%m-%d')
        if not row or int(row['end_time']) <= time.time(): return 710071
        if row['last_gain_day'] == today: return 710001
        setting = meta_payload.get_meta_payload()['activitySettingConfig']['gemCardConfig']
        rewards, _ = api.ctx.reward.grant(pid, [{'itemType': G.RE_GEMS, 'amount': int(setting['gemCardNum'])}], record=True, reason='monthCard')
        api.db.con.execute('UPDATE player_gem_card SET last_gain_day=? WHERE gem_card_id=?', (today, row['gem_card_id']))
        return {'rewards': rewards}


@endpoint('eatPeach')
def eat_peach(api, params):
    pid = api.require_player()['player_id']
    name = str(params.get('featureName') or '')
    if name not in ('activity1Rest', 'activity2Rest'): return 714102
    # Use the same local activity windows that are advertised to the client.
    window = next((r for r in G.maintenance_items() if r['name'] == name), None)
    if not window or not window.get('enable'): return 714102
    now = int(time.time())
    opened = str(window.get('activityOpen') or '00:00').split(':')
    start = int(opened[0]) * 60 + int(opened[1])
    minute = time.localtime(now).tm_hour * 60 + time.localtime(now).tm_min
    if (minute - start) % 1440 >= int(window.get('activityDuring') or 0): return 714102
    with api.db.tx():
        st = api.ctx.activity.state(pid, 'eat_peach')
        day = str(api.db.today())
        if st.get('day') != day: st = {'day': day, 'times': {}}
        if name in st['times']: return 714102
        p = api.repos.player.player(pid)
        setting = G.game_setting_config()
        cap = int(setting.get('maxEnergy') or 100)
        if int(p['energy']) >= cap: return 710513
        # No original peach amount was recovered. Reuse local energy refill size.
        gained = min(int(setting.get('energyGainedByGem') or 50), cap - int(p['energy']))
        api.repos.player.add_currency(pid, 'energy', gained)
        st['times'][name] = now
        api.ctx.activity.save_state(pid, 'eat_peach', st)
        return {'gainedEnergy': gained}


@endpoint('wishing')
def fountain_wish(api, params):
    pid = api.require_player()['player_id']
    cfg = meta_payload.get_meta_payload().get('activityFountainWishConfig', {})
    with api.db.tx():
        p = api.repos.player.player(pid)
        if int(p['level']) < int(cfg.get('requiredLevel') or 1): return 712301
        st = api.ctx.activity.state(pid, 'fountain')
        if st.get('day') != str(api.db.today()): st = {'day': str(api.db.today()), 'count': 0}
        count = int(st.get('count') or 0)
        limit = int(cfg.get('freeNum') or 0)
        vip = G.vip_level_of(p)
        if vip:
            row = next((r for r in luaconf.as_list(luaconf.load('activity_fountainwish_fountainmax'))
                        if int(r['vipLevelMin']) <= vip <= int(r['vipLevelMax'])), None)
            if row: limit = int(row['foutainMax'])
        if count >= limit: return 710001
        coin = next((r for r in cfg.get('silverCoins', []) if int(r['fountainNum']) == count+1), None)
        cost = next((r for r in luaconf.as_list(luaconf.load('activity_fountainwish_gold'))
                     if int(r['fountainNum']) == count+1), None)
        if not coin or not cost: return 710071
        if api.ctx.player.spend_gems(pid, int(cost['gold'])) is None: return 710513
        amount = int(coin['silverCoins'])
        # Original critical probability is missing; base payout is supported.
        api.ctx.reward.grant(pid, [{'itemType': G.RE_COIN, 'amount': amount}], record=True, reason='fountain')
        st['count'] = count+1
        api.ctx.activity.save_state(pid, 'fountain', st)
        return {'coins': amount, 'multiple': 1}


@endpoint('gainAccumulateRechargeReward')
def accumulate_recharge_reward(api, params):
    api.require_player()
    # This is DailyFirstCharge.rewardType=1/2, not charge_money_reward.id.
    # No original daily recharge reward config was recovered.
    return 714651


@endpoint('buyEnergyStone')
def buy_energy_stone(api, params):
    pid = api.require_player()['player_id']
    count = int(params.get('num') or 0)
    if count not in (1,10): return 710071
    cfg = meta_payload.get_meta_payload().get('activityBalloonConfig', {})
    cost = int(cfg.get('propCost') or 0)*count
    meta = int(cfg.get('propId') or 0)
    if not cost or not meta: return 710071
    with api.db.tx():
        if api.ctx.player.spend_gems(pid,cost) is None: return 710513
        rewards,_ = api.ctx.reward.grant(pid,[{'itemType':G.RE_PROP,'metaId':meta,'amount':count}],
                                         record=True,reason='balloonEnergyStone')
        return {'rewards':rewards}


@endpoint('gainCrossGachaPointReward')
def cross_gacha_point_reward(api, params):
    pid = api.require_player()['player_id']
    cfg = meta_payload.get_meta_payload().get('activityGachaXiaoyuConfig', {})
    rid = int(params.get('id') or 0)
    row = next((r for r in cfg.get('crossGachaPointRewards', []) if int(r['id']) == rid), None)
    if not row: return 710071
    with api.db.tx():
        st = api.ctx.activity.state(pid, 'cross_gacha')
        if int(st.get('point') or 0) < int(row['pointMin']): return 710513
        if rid in st.get('gainedPoint', []): return 710001
        rewards = G.reward_from_package(int(row['rewardPackageId']))
        if not rewards: return 710071
        rewards, _ = api.ctx.reward.grant(pid, rewards, record=True, reason='crossGachaPoint')
        st.setdefault('gainedPoint', []).append(rid)
        api.ctx.activity.save_state(pid, 'cross_gacha', st)
        return {'rewards': rewards}


@endpoint('gainGoldGodRewards')
def gold_god_reward(api, params):
    import random
    pid = api.require_player()['player_id']
    cfg = meta_payload.get_meta_payload().get('activityGoldGodConfig', {})
    with api.db.tx():
        st = api.ctx.activity.state(pid, 'gold_god')
        if int(st.get('version') or 0) != int(cfg.get('version') or 1):
            st = {'version': int(cfg.get('version') or 1), 'count': 0}
        count = int(st.get('count') or 0)
        if count >= int(cfg.get('goldGodMaxTimes') or 0): return 714481
        row = next((r for r in cfg.get('goldGodRewardItems', []) if int(r['id']) == count+1), None)
        if not row: return 710071
        if G.vip_level_of(api.repos.player.player(pid)) < int(row['vip']): return 712301
        cost = int(row['gemNeed'])
        if api.ctx.player.spend_gems(pid, cost) is None: return 710513
        # Config supplies bounds, not the original distribution. Local uniform fallback.
        gross = random.randint(cost+1, max(cost+1, int(row['gemMax'])))
        api.ctx.reward.grant(pid, [{'itemType': G.RE_GEMS, 'amount': gross}], record=True, reason='goldGod')
        st['count'] = count+1
        api.ctx.activity.save_state(pid, 'gold_god', st)
        # Lua adds cost to rewards[1] before animating, so response is net profit.
        return {'rewards': [{'itemType': G.RE_GEMS, 'metaId': 0, 'amount': gross-cost}]}


@endpoint('getDestinyInfo')
def h_destiny_info(api, params):
    p = api.require_player()
    state = api.ctx.activity.state(p['player_id'], 'destiny')
    return {'destinyBattleRound': 1, 'destinyBattleStage': 1,
        'destinyBattle': 1, 'bossStage': False, 'destinyBattleOver': False,
        'cardId': G.STARTER_CARD_META, 'bossId': G.STARTER_CARD_META,
        'levelPrerequisite': 20, 'destinyBattleTotalNum': 10,
        'destinyBattleNum': int(state.get('battleNum', 0)),
        'spiritConcentrateLevel': int(state.get('spiritConcentrateLevel', 0)),
        'spiritConcentrateTotalNum': 0, 'spiritConcentrateNum': 0,
        'spiritConcentrateVipTotalNum': 0, 'spiritConcentrateVipNum': 0}


@endpoint('destinyBattle')
@endpoint('spiritConcentrate')
def h_destiny_unavailable(api, params):
    # Original encounter/reward tables are absent; do not return an empty success.
    api.require_player()
    return 714651


@endpoint('gachaTreasure')
def h_gacha_treasure(api, params):
    import random
    p = api.require_player(); pid = p['player_id']
    cfg = meta_payload.get_meta_payload()
    setting = cfg['treasureSettingConfig']; node = cfg['treasureGachaConfig']['gachaNode']
    count = int(params.get('time') or 1); free = params.get('free') is True
    if count not in (1, 10) or (free and count != 1): return 710401
    if int(p['level']) < int(setting['unlockLevel']): return 710401
    # Local fallback: equal weights among original one/two-star metadata.
    pool = [x for x in luaconf.as_list(luaconf.load('treasure_meta')) if int(x.get('rare', 0)) in (1, 2)]
    if not pool: return 714651
    with api.db.tx():
        state = api.ctx.activity.state(pid, 'treasure_gacha')
        now = int(time.time())
        if free and now - int(state.get('lastFree', 0)) < int(node['countdownDuration']): return 710401
        amount = 1 if free or count == 1 else 11
        if len(api.repos.asset.treasures(pid)) + amount > int(setting['treasurePoolInitSize']): return 710516
        cost = 0 if free else count * int(node['requisites'][0]['amount'])
        if cost and api.ctx.player.spend_gems(pid, cost) is None: return 710513
        rewards = [{'itemType': G.RE_TREASURE, 'metaId': int(random.choice(pool)['treasureID']), 'amount': 1, 'level': 1} for _ in range(amount)]
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True, reason='gachaTreasure')
        if free: api.ctx.activity.patch_state(pid, 'treasure_gacha', lastFree=now)
        return {'rewards': applied}


@endpoint('gainRankFirstReward')
def h_arena_first_rank(api, params):
    pid = api.require_player()['player_id']; rank = int(params.get('rank') or 0)
    cfg = next((r for r in luaconf.as_list(luaconf.load('arena_rank_reward')) if int(r['rank']) == rank), None)
    if not cfg or api.ctx.arena.rank_of(pid) > rank: return 712410
    with api.db.tx():
        if api.ctx.activity.has_claimed(pid, 'arena_first_rank', rank): return 712408
        _, rewards = api.ctx.activity.claim_once(pid, 'arena_first_rank', rank,
            [{'itemType': int(cfg['itemType']), 'metaId': int(cfg['itemMetaId']), 'amount': int(cfg['amount'])}], reason='arenaFirstRank')
        return {'rewards': rewards}


@endpoint('getAchievements')
def reported_achievements(api, params):
    pid = api.require_player()['player_id']
    return {'sharkAchievement': [{'achievementConfigId': int(i), 'status': 3}
        for i in api.ctx.activity.claims(pid, 'achievement')]}


@endpoint('gainAchievementReward')
def reported_achievement_reward(api, params):
    p = api.require_player(); pid = p['player_id']; aid = int(params.get('achievementId') or 0)
    cfg = next((c for c in luaconf.as_list(luaconf.load('achievement_task')) if int(c['achieveId']) == aid), None)
    if not cfg or int(params.get('achievementType') or 0) != int(cfg['achieveType']): return 710401
    kind = int(cfg['achieveType']); need = int(cfg['achieveCondition'])
    ready = False
    if kind == 1: ready = int(p['level']) >= need
    elif kind == 2:
        maximum = int(api.repos.progress.scene_process(pid)['max_finished_mission_id'])
        missions = [int(c['missionId']) for c in luaconf.as_list(luaconf.load('battle_chapter_event')) if int(c['missionId']) // 10000 == need]
        ready = bool(missions) and maximum >= max(missions)
    elif kind == 3:
        maximum = int(api.repos.progress.elite(pid)['max_finished_elite_id'])
        ready = maximum > 0 and maximum // 100 >= need
    if not ready or not int(cfg.get('achieveReward') or 0): return 710401
    with api.db.tx():
        if api.ctx.activity.has_claimed(pid, 'achievement', aid): return 710401
        rewards = api.ctx.activity.pkg(cfg['achieveReward'])
        if not rewards: return 710401
        _, applied = api.ctx.activity.claim_once(pid, 'achievement', aid, rewards, reason='achievement')
        return {'reward': applied, 'rewards': applied}


@endpoint('getAppliedUnions')
def reported_applied_unions(api, params):
    pid = api.require_player()['player_id']
    return {'sharkUnionWrappers': [{'unionId': int(row['guild_id']), 'name': row['name'],
        'level': int(row['level']), 'memberNum': int(row['member_num']), 'rank': 999,
        'managerName': '', 'managerLevel': 1, 'declaration': ''}
        for row in api.repos.guild.my_applies(pid)]}
