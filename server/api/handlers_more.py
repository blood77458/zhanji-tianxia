#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""第二批端点：签到 / 连续登录 / 累充 / 商店 / 好友 / 任务 / 跨服占位。

新增接口时**只要在这里加一个 `@endpoint("method")` 函数**，
不用再动任何分发代码。
"""
import json
import time

import assembler as A
import gamedata as G
from . import endpoint, ApiError

OK = 200


@endpoint('getMonthlyLoginRewardMeta')
def h_monthly_login_meta(api, params):
    import calendar
    now = time.localtime()
    days = calendar.monthrange(now.tm_year, now.tm_mon)[1]
    return OK, {'adNum': 0, 'monthlyLoginRewardItems': [
        {'rewardType': 1, 'rewardId': 0, 'rewardAmount': 100 * day,
         'levelMin': 0, 'rewardMultiple': 1}
        for day in range(1, days + 1)]}


# ================================================================ 签到 / 连登
@endpoint('getSignInReward')
@endpoint('getLoginReward')
def h_sign_in(api, params):
    """月签到领奖。

    ⚠️ 响应里的 rewards 必须存在（客户端 GetRewardInfoPanel 会 pairs 它）。
    """
    p = api.require_player()
    pid = p['player_id']
    today = api.db.today()
    month_key = time.strftime('%Y-%m')
    row = api.db.one("SELECT * FROM player_sign_in WHERE player_id=?", (pid,))
    if row is None:
        with api.db.tx() as con:
            con.execute("INSERT INTO player_sign_in(player_id, month_key) VALUES (?,?)",
                        (pid, month_key))
        row = api.db.one("SELECT * FROM player_sign_in WHERE player_id=?", (pid,))
    if row['month_key'] != month_key:
        with api.db.tx() as con:
            con.execute("UPDATE player_sign_in SET month_key=?, login_days_month=0,"
                        " gained_day_ids_json='[]' WHERE player_id=?", (month_key, pid))
        row = api.db.one("SELECT * FROM player_sign_in WHERE player_id=?", (pid,))

    day = int(time.strftime('%d'))
    gained = set(json.loads(row['gained_day_ids_json'] or '[]'))
    if day in gained:
        return OK, {'rewards': [], 'currPoint': int(row['login_days_month'])}
    gained.add(day)
    with api.db.tx() as con:
        con.execute("UPDATE player_sign_in SET login_days_month=?, last_reward_time=?,"
                    " gained_day_ids_json=? WHERE player_id=?",
                    (len(gained), int(time.time()),
                     json.dumps(sorted(gained)), pid))
    rewards = [{'itemType': G.RE_COIN, 'amount': 100 * day},
               {'itemType': G.RE_GEMS, 'amount': 20}]
    applied, _ = api.ctx.reward.grant(pid, rewards, record=True, reason='signIn')
    return OK, {'rewards': applied, 'currPoint': len(gained)}


@endpoint('getContinuousLoginReward')
@endpoint('getContinueLoginReward')
def h_continuous_login(api, params):
    p = api.require_player()
    row = api.db.one("SELECT * FROM player_continuous_login WHERE player_id=?",
                     (p['player_id'],))
    if row is None:
        with api.db.tx() as con:
            con.execute("INSERT INTO player_continuous_login(player_id) VALUES (?)",
                        (p['player_id'],))
        row = api.db.one("SELECT * FROM player_continuous_login WHERE player_id=?",
                         (p['player_id'],))
    return {'continuousLoginInfo': {
        'firstGetRewardTime': int(row['first_get_reward_time']),
        'latestGetRewardTime': int(row['latest_get_reward_time']),
        'gainRewards': json.loads(row['gain_rewards_json'] or '[]'),
        'gainRewardInOrder': int(row['gain_reward_in_order']),
        'getBigReward': int(row['get_big_reward']),
    }}


@endpoint('gainContinuousLoginRewardV2')
def h_gain_continuous_v2(api, params):
    p = api.require_player()
    pid = p['player_id']
    row = api.db.one("SELECT * FROM player_continuous_login_v2 WHERE player_id=?", (pid,))
    if row is None:
        with api.db.tx() as con:
            con.execute("INSERT INTO player_continuous_login_v2(player_id) VALUES (?)", (pid,))
        row = api.db.one("SELECT * FROM player_continuous_login_v2 WHERE player_id=?", (pid,))
    days = int(row['gain_reward_days'])
    if days >= 7:
        return OK, {'rewards': []}
    gained = json.loads(row['gained_rewards_json'] or '[]')
    gained.append(days)
    with api.db.tx() as con:
        con.execute("UPDATE player_continuous_login_v2 SET gain_reward_days=?,"
                    " gained_rewards_json=? WHERE player_id=?",
                    (days + 1, json.dumps(gained), pid))
    applied, _ = api.ctx.reward.grant(
        pid, [{'itemType': G.RE_GEMS, 'amount': 50},
              {'itemType': G.RE_COIN, 'amount': 500}], record=True, reason='continuousV2')
    return OK, {'rewards': applied}


# ================================================================ 累充 / 充值
@endpoint('getRechargeInfo')
def h_recharge_info(api, params):
    p = api.require_player()
    return {'recharges': [], 'dailyRecharge': 0,
            'accumulateGems': int(p['recharge_gems'])}


@endpoint('getAccumulateGems')
def h_accumulate_gems(api, params):
    p = api.require_player()
    return {'accumulateGems': int(p['recharge_gems'])}


@endpoint('gainChargeMoneyReward')
def h_gain_charge_reward(api, params):
    p = api.require_player()
    rid = int(api.param(params, 'rewardId', 0) or 0)
    cfg = G.charge_money_rewards().get(rid)
    if not cfg:
        return OK, {'rewards': []}
    need = int(cfg.get('requireGold') or 0)
    if int(p['recharge_gems']) < need:
        raise ApiError(714001)
    existing = api.db.one("SELECT 1 FROM player_activity_reward_claim WHERE player_id=?"
                          " AND scope='charge_money' AND reward_id=?", (p['player_id'], rid))
    if existing:
        return OK, {'rewards': []}
    with api.db.tx() as con:
        con.execute("INSERT INTO player_activity_reward_claim(player_id, scope, reward_id,"
                    " claim_time) VALUES (?,'charge_money',?,?)",
                    (p['player_id'], rid, int(time.time())))
    applied, _ = api.ctx.reward.grant(p['player_id'], cfg.get('rewards') or [],
                                      record=True, reason='chargeMoneyReward')
    return OK, {'rewards': applied}


@endpoint('validatePaymentOrder')
def h_validate_order(api, params):
    """本地校验：不接真实支付，按 productId 发钻石。

    ⚠️ 订单号做主键天然防重复发货。
    """
    p = api.require_player()
    pid = p['player_id']
    order_id = str(api.param(params, 'orderId', '') or ('local-%d-%d' % (pid, time.time())))
    product_id = str(api.param(params, 'productId', '') or '')
    existing = api.db.one("SELECT * FROM payment_order WHERE order_id=?", (order_id,))
    if existing and int(existing['status']) == 3:
        return OK, {'succ': True, 'productId': product_id,
                    'rechargeGems': int(existing['recharge_gems']),
                    'freeGems': int(existing['free_gems'])}
    import re as _re
    m = _re.search(r'(\d+)', product_id)
    gems = int(m.group(1)) if m else 60
    with api.db.tx() as con:
        con.execute(
            "INSERT INTO payment_order(order_id, player_id, product_id, gold_num,"
            " recharge_gems, free_gems, status, create_time, finish_time)"
            " VALUES (?,?,?,?,?,?,3,?,?)"
            " ON CONFLICT(order_id) DO UPDATE SET status=3, finish_time=excluded.finish_time",
            (order_id, pid, product_id, gems, gems, 0, int(time.time()), int(time.time())))
        con.execute("INSERT INTO charge_log(player_id, order_id, product_id, recharge_gems,"
                    " free_gems, source, create_time) VALUES (?,?,?,?,?,'iap',?)",
                    (pid, order_id, product_id, gems, 0, int(time.time())))
    api.ctx.player.buy_gems(pid, gems)
    return OK, {'succ': True, 'productId': product_id, 'rechargeGems': gems, 'freeGems': 0}


# ================================================================ 商店
@endpoint('getSecretShopList')
def h_secret_shop(api, params):
    p = api.require_player()
    row = api.db.one("SELECT * FROM player_secret_shop WHERE player_id=?", (p['player_id'],))
    if row is None:
        with api.db.tx() as con:
            con.execute("INSERT INTO player_secret_shop(player_id) VALUES (?)", (p['player_id'],))
        row = api.db.one("SELECT * FROM player_secret_shop WHERE player_id=?", (p['player_id'],))
    return {'secretShopItems': json.loads(row['items_json'] or '[]'),
            'freeTimes': int(row['free_times']),
            'itemIdList': [],
            'version': int(row['version']),
            'lastRefreshSecond': int(row['last_refresh_second'])}


@endpoint('getMedalShopList')
def h_medal_shop(api, params):
    return {'medalShopItems': [], 'freeTimes': 0}


@endpoint('getSharkBeasts')
@endpoint('getSharkBeastFragments')
def h_beasts(api, params):
    return {'sharkBeasts': [], 'sharkBeastFragments': []}


# ================================================================ 好友
@endpoint('getFriends')
def h_get_friends(api, params):
    p = api.require_player()
    out = []
    for r in api.repos.social.friends(p['player_id']):
        e = A.build_friend_entry(api.db, p['player_id'], int(r['friend_uid']))
        if e:
            out.append(e)
    return {'sharkFriends': out}


@endpoint('getReviewFriends')
@endpoint('getInvitationFriends')
def h_review_friends(api, params):
    p = api.require_player()
    status = 0 if params.get('_review') else None
    rows = api.repos.social.invitations(to_uid=p['player_id'] if status == 0 else None,
                                        from_uid=p['player_id'])
    out = []
    for inv in rows:
        other = int(inv['from_uid']) if int(inv['to_uid']) == int(p['player_id']) \
            else int(inv['to_uid'])
        e = A.build_friend_entry(api.db, p['player_id'], other)
        if e:
            e['invitationId'] = int(inv['invitation_id'])
            out.append(e)
    return {'sharkFriends': out}


@endpoint('getRecommendedFriends')
def h_recommended_friends(api, params):
    p = api.require_player()
    rows = api.db.all("SELECT player_id FROM player WHERE player_id<>? ORDER BY level DESC"
                      " LIMIT 10", (p['player_id'],))
    out = []
    for r in rows:
        e = A.build_friend_entry(api.db, p['player_id'], int(r['player_id']))
        if e:
            out.append(e)
    return {'sharkFriends': out}


@endpoint('searchUserByNickname')
def h_search_user(api, params):
    p = api.require_player()
    nick = str(api.param(params, 'nickName', '') or '').strip()
    rows = api.repos.social.search_players(nick, exclude=p['player_id'])
    if not rows:
        return {'sharkFriendDetail': None, 'sharkFriends': []}
    e = A.build_friend_entry(api.db, p['player_id'], int(rows[0]['player_id']))
    return {'sharkFriendDetail': e, 'sharkFriends': [e] if e else []}


@endpoint('sendInvitation')
@endpoint('sendAllInvitations')
def h_send_invitation(api, params):
    p = api.require_player()
    uids = api.int_list_param(params, 'friendUids') or ([api.param(params, 'friendUid', 0)]
                                               if params.get('friendUid') else [])
    for uid in uids:
        if uid and int(uid) != int(p['player_id']):
            api.repos.social.add_invitation(p['player_id'], int(uid))
    return {'friendUids': [int(u) for u in uids if u]}


@endpoint('acceptInvitation')
@endpoint('acceptAllInvitations')
def h_accept_invitation(api, params):
    p = api.require_player()
    invs = api.repos.social.invitations(to_uid=p['player_id'], status=0)
    accepted = []
    for inv in invs:
        api.repos.social.set_invitation_status(int(inv['invitation_id']), 1)
        api.repos.social.add_friend(p['player_id'], int(inv['from_uid']))
        e = A.build_friend_entry(api.db, p['player_id'], int(inv['from_uid']))
        if e:
            accepted.append(e)
    return {'acceptedFriends': accepted,
            'acceptedFriend': accepted[0] if accepted else None}


@endpoint('deleteFriend')
def h_delete_friend(api, params):
    p = api.require_player()
    api.repos.social.remove_friend(p['player_id'],
                                   int(api.param(params, 'friendUid', 0) or 0))
    return {}


@endpoint('getFriendDetail')
def h_friend_detail(api, params):
    """⚠️ sharkFriendDetail 为 nil 客户端会崩（UserDetailPanel:657 无保护）。"""
    p = api.require_player()
    other = int(api.param(params, 'friendUid', 0) or 0)
    e = A.build_friend_entry(api.db, p['player_id'], other) if other else None
    if e is None:
        raise ApiError(710601)
    e['friendNum'] = 0
    e['friendNumMax'] = 50
    e['arenaRank'] = 0
    return {'sharkFriendDetail': e}


@endpoint('recordPraiseId')
def h_record_praise(api, params):
    """响应体客户端完全不读（回调第一参是自己传的 echo），返回 {} 即可。"""
    return {}


# ================================================================ 任务 / 成就
@endpoint('getTaskInfo')
def h_task_info(api, params):
    return {'dailyTaskInfos': [], 'taskCounters': []}


@endpoint('gainDailyTaskReward')
def h_gain_task_reward(api, params):
    p = api.require_player()
    rid = int(api.param(params, 'taskId', 0) or 0)
    applied, _ = api.ctx.reward.grant(
        p['player_id'], [{'itemType': G.RE_COIN, 'amount': 200}],
        record=True, reason='dailyTask:%d' % rid)
    return {'rewards': applied}


@endpoint('getDailyActiveInfo')
def h_daily_active(api, params):
    return {'dailyActiveInfo': {'activeValue': 0, 'taskCounters': [], 'gainedRewards': []}}


@endpoint('gainActiveReward')
def h_gain_active_reward(api, params):
    p = api.require_player()
    applied, _ = api.ctx.reward.grant(
        p['player_id'], [{'itemType': G.RE_GEMS, 'amount': 30}],
        record=True, reason='dailyActive')
    return {'rewards': applied}


@endpoint('getAchievements')
def h_achievements(api, params):
    return {'sharkAchievement': []}


@endpoint('gainAchievementReward')
def h_gain_achievement(api, params):
    return {'rewards': []}


# ================================================================ 排行 / 竞技
@endpoint('getArenaMatchedPlayers')
def h_arena_matched(api, params):
    return {'pkUserInfos': []}


@endpoint('challengeArena')
def h_challenge_arena(api, params):
    """竞技场/演武挑战。

    ⚠️ 原来固定打 `100101`（第 1 章小怪）：60 级角色一刀秒，`leftHpRate` 恒为 100，
       **永远不可能战败** —— 于是客户端「战败」分支（含爆衣演出）永远走不到。
       改成按玩家等级挑对手，让胜负真的有可能。
    """
    p = api.require_player()
    mid = _arena_mission_for(int(p['level']))
    code, pack = api.ctx.mission.challenge(p['player_id'], mid, 3)
    if code == OK and (pack or {}).get('win'):
        with api.db.tx() as con:
            con.execute("INSERT INTO arena_rank(player_id, server_id, score, win_count)"
                        " VALUES (?,1,10,1) ON CONFLICT(player_id) DO UPDATE SET"
                        " score=score+10, win_count=win_count+1",
                        (p['player_id'],))
    return code, pack


def _arena_mission_for(player_level):
    """按玩家等级挑一个「打得动、也可能打输」的关卡。

    选 `monsterLevel` 最接近 `player_level + 2` 的关卡（略强一点），
    落不到就退回 100101。
    """
    try:
        src = G._cs
        src._init_battle_meta()
        best, best_gap = 0, None
        want = int(player_level)
        # ⚠️ _BATTLE_EVENT 的 key 有两种：`(missionId, battleType)` 元组和纯 missionId，
        #    不能直接 `for (mid, btype), ev in ...` 解包（会 TypeError 被兜底吃掉）。
        for key, ev in list(src._BATTLE_EVENT.items()):
            if isinstance(key, tuple):
                mid, btype = key[0], key[1]
            else:
                mid, btype = key, 1
            if int(btype) != 1:
                continue
            lv = int(ev.get('monsterLevel') or 0)
            if lv <= 0:
                continue
            gap = abs(lv - want)
            if best_gap is None or gap < best_gap:
                best, best_gap = int(mid), gap
        return best or 100101
    except Exception:
        return 100101


@endpoint('gainArenaScoreByRank')
def h_arena_rank_reward(api, params):
    p = api.require_player()
    applied, _ = api.ctx.reward.grant(
        p['player_id'], [{'itemType': G.RE_GEMS, 'amount': 100}],
        record=True, reason='arenaRankReward')
    return {'rewards': applied}


@endpoint('gainRankFirstReward')
def h_rank_first(api, params):
    p = api.require_player()
    applied, _ = api.ctx.reward.grant(
        p['player_id'], [{'itemType': G.RE_GEMS, 'amount': 200}],
        record=True, reason='rankFirst')
    return {'rewards': applied}


# ================================================================ 跨服 / 活动（占位）
# 这些接口客户端会读响应体，必须给**结构完整**的空值，不能给 {}。
@endpoint('getCrossPvpInfo')
def h_cross_pvp_info(api, params):
    return {'crossVersion': 1, 'phaseIndex': 1,
            'battleInfo': {'battleScore': 0, 'rank': 0, 'activeScore': 0,
                           'matchList': [], 'freeRefreshTimestamp': 0},
            'rewardInfo': {'ranks': [], 'rankRewardStatus': 0, 'serverRewardStatus': 0}}


@endpoint('getCrossPvpRankInfo')
def h_cross_pvp_rank(api, params):
    return {'ranks': [], 'rankRewardStatus': 0, 'serverRewardStatus': 0}


@endpoint('getCrossPvpReport')
@endpoint('getCrossPvpVideo')
def h_cross_pvp_report(api, params):
    return {'reports': [], 'reportInfo': {}}


@endpoint('getCrossGvgInfo')
def h_cross_gvg_info(api, params):
    """跨服 GVG 总览。

    ⚠️ 客户端还会读 `score / challengeNum / teamMirrorRemind / groupChallengedRemind`
       （`CrossUnionPkData.lua:74-120`、`CrossUnionPKTeamAdjustScene.lua:31,88,277,282,335,369`），
       少一个就是 nil 索引。本服没有真实跨服数据，字段给 0 / false。
    """
    return {'version': 0, 'out': 0, 'unionApplyCrossGvg': False,
            'selfApplyCrossGvg': False, 'selfQuitCrossGvg': False,
            'crossGvgVersion': 0, 'promotion': 0, 'unionWarHintNum': 0,
            'score': 0, 'challengeNum': 0,
            'teamMirrorRemind': False, 'groupChallengedRemind': False,
            'signs': [], 'reports': [], 'top10ScoreList': [], 'sixteen': [],
            'eight': [], 'four': []}


@endpoint('getCrossGvgInfoBase')
def h_cross_gvg_base(api, params):
    return {'version': 0, 'unionApplied': False, 'appliedNum': 0, 'quitNum': 0,
            'out': 0, 'promotion': 0, 'signs': []}


@endpoint('getCrossGvgGroupInfo')
def h_cross_gvg_group(api, params):
    p = api.require_player()
    rows = api.db.all("SELECT DISTINCT server_id FROM server_partition ORDER BY server_id")
    return {'serverIds': [int(r['server_id']) for r in rows] or [int(p['server_id'])]}


@endpoint('getCrossGvgGroupTop10Score')
def h_cross_gvg_top10(api, params):
    return {'selfScore': 0, 'top10ScoreList': []}


@endpoint('getCrossGvgGroupReports')
def h_cross_gvg_reports(api, params):
    return {'reports': []}


@endpoint('getUnionFormation')
def h_union_formation(api, params):
    """军团战阵容。

    ⚠️ 字段名必须是客户端读的那一套：
       `UnionPkCityPowerupPopPanel.lua:193-199,486` / `UnionPkChangeFormationPopPanel.lua:140,155`
       读的是 `forwardInfo`(对象) / `formationHeadInfo` / `formationMiddleInfo` / `formationTailInfo`，
       其中 `:196` 直接 `#...formationHeadInfo` —— 原来返回的 `forward/head/middle/tail`
       名字对不上，拿到 nil 后取长度就崩。
    ⚠️ `sharkUnionCityApply` 至少 1 个元素（[1] 必须是防守方，NPC 也要占位）。
    """
    return {
        'unionFormation': {
            'gemInspireNum': 0,
            'version': 0,
            'forwardInfo': {},
            'formationHeadInfo': [],
            'formationMiddleInfo': [],
            'formationTailInfo': [],
        },
        'sharkUnionCityApply': [{'unionId': 0, 'unionName': 'NPC', 'wealth': 0}],
        'winnerUnionCityApply': [],
        'loserUnionCityApply': [],
    }


@endpoint('getUnionCityList')
def h_union_city_list(api, params):
    return {'sharkUnionCityWrappers': [], 'ownCityIds': [], 'challengeCityIds': [],
            'fightingCityIds': [], 'unionWinNum': []}


# ================================================================ 各种「确认收到」类
# 这些接口客户端只关心 retCode==200，响应体不被读取。
# 注意：`transferUnion`（要 data.transferTime）、`resetChrist`（要 data.params）
#      已被下面的真实现接管，故意不在这个列表里。
for _m in ('recordAddictedTime', 'speakLimitStutas', 'online', 'offline',
           'recordActivityFbShare', 'recordGameFbShare',
           'setAutoSave', 'setSpiritRefreshAutoSave', 'lockTreasure',
           'gainFbActivityReward', 'setoffFireworks', 'refreshSubAttribute',
           'selectSubAttribute', 'unlockSubAttribute', 'upgradeSpirit',
           'equipSpirit', 'unequipSpirit', 'sellSpirit', 'buySpiritPool',
           'spiritConcentrate', 'constructUnion', 'upgradeUnionBuilding',
           'applyUnion', 'quitUnion', 'appointUnion'):
    def _ack(api, params, _name=_m):
        return {}
    endpoint(_m)(_ack)


# ---------------------------------------------------------------- 需要回包的两个
@endpoint('transferUnion')
def h_transfer_union(api, params):
    """转让军团长。

    ⚠️ 客户端回调读 `data.transferTime` 显示「转让冷却到 X」，返回 `{}` 会崩。
    """
    import time as _t
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        raise ApiError(716301)
    if int(g['leader_uid']) != int(p['player_id']):
        raise ApiError(716301)                    # 只有军团长能转让
    to_uid = int(api.param(params, 'uid', 0) or api.param(params, 'targetUid', 0) or 0)
    if to_uid and to_uid != int(p['player_id']):
        m = api.repos.guild.member(int(g['guild_id']), to_uid)
        if m is None:
            raise ApiError(716302)                # 目标不是本军团成员
        api.repos.guild.update_guild(int(g['guild_id']), leader_uid=to_uid)
        api.repos.guild.update_member(int(g['guild_id']), to_uid, title=1)
        api.repos.guild.update_member(int(g['guild_id']), int(p['player_id']), title=0)
    return {'transferTime': int(_t.time())}


@endpoint('resetChrist')
def h_reset_christ(api, params):
    """重置迎财神。

    ⚠️ 客户端回调读 `data.params`（重置后的活动参数），返回 `{}` 会崩。
    """
    pid = api.require_player()['player_id']
    try:
        st = api.ctx.activity.state(pid, 'christ')
        st['resetDate'] = api.db.today()
        st['times'] = 0
        api.ctx.activity.save_state(pid, 'christ', st)
        return {'params': st}
    except Exception:
        return {'params': {}}
