#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""核心端点处理器：登录 / 初始化 / 资产 / 抽卡 / 关卡 / 邮件。

每个处理器只做三件事：取参数 → 调 service → 喂 assembler。
业务规则一律不写在这里。
"""
import time

import assembler as A
import gamedata as G
from . import endpoint, ApiError, to_list, to_int_list

OK = 200


# ================================================================ 会话 / 初始化
@endpoint('login')
def h_login(api, params):
    """客户端 Communication:login() 直接 transponder:call("login", nil)。
    只要求 subHeader.errCode ≤ 0 且 retCode=200，body 可以是空表。"""
    return {}


@endpoint('loginServer')
def h_login_server(api, params):
    """选服。**这一步还处于账号级**，角色可能还不存在。

    ⚠️ 没有角色时必须返回字符串 "1"（LoginScene.lua:349 `uid == "1"` 判定新号，
       客户端据此跳到创角界面）。这里**不能** require_player。
    ⚠️ 老玩家**故意不下发 accountReturnRewards** —— 空表在 Lua 为真，
       会顶掉客户端默认值并弹出空的「主公归来」面板挡住闯关。
    """
    acc = api.ctx.account.account_by_session(api.sk)
    if acc is None:
        raise ApiError(710070)                 # USER_NOT_EXIST
    server_id = int(api.param(params, 'serverId', 1) or 1)
    p = api.repos.player.player_by_account(int(acc['account_id']), server_id)
    if p is None:
        return {'uid': '1', 'serverId': server_id}
    api.ctx.account.bind_session_player(api.sk, int(p['player_id']))
    api.repos.player.touch_account_login(int(acc['account_id']))
    return {'uid': str(p['player_id']), 'serverId': int(p['server_id'])}


@endpoint('getServerTimeStamp')
def h_server_ts(api, params):
    return {'ts': int(time.time())}


@endpoint('getServerStatus')
def h_server_status(api, params):
    return {'serverId': int(api.param(params, 'serverId', 1)), 'status': 0, 'amount': 0}


@endpoint('getSocketServer')
def h_socket_server(api, params):
    import os
    host = os.environ.get('CANON_SOCKET_HOST', '10.0.2.2')
    port = int(os.environ.get('CANON_REALTIME_PORT', '9700'))
    return {'serverAddress': host, 'serverPort': port, 'token': 'local-token'}


@endpoint('getUserBanInfo')
def h_user_ban(api, params):
    p = api.require_player()
    return {'noChatEndSeconds': int(p['no_chat_end_seconds'] or 0)}


@endpoint('getMaintenanceMeta')
def h_maintenance(api, params):
    from meta_payload import get_meta_payload
    items = G.maintenance_items()
    # Newly restored activity entry points, advertised only with full configs.
    for config_key, feature in (('activityGoldGodConfig','goldGod'),
                                ('activityBalloonConfig','activityBalloon')):
        cfg = get_meta_payload().get(config_key,{})
        if cfg and not any(r['name']==feature for r in items):
            template=dict(items[0]);template['name']=feature;items.append(template)
    # CrossArena calls time[1] even while checking whether the feature is open.
    cfg = get_meta_payload().get('crossArenaSettingConfig', {})
    for key in ('featureNameBattle', 'featureNameReward'):
        feature = cfg.get(key)
        if feature and not any(r['name'] == feature for r in items):
            template = dict(items[0]); template.update(name=feature, enable=False,
                beginTime='2099/01/01 00:00', endTime='2099/01/02 00:00')
            items.append(template)
    enabled = {r['name'] for r in items if r.get('enable')}
    # Recovered configs use different calculation/reward names from old stubs.
    # Add their time windows only when that activity's panel is already open.
    for config in get_meta_payload().values():
        if not isinstance(config, dict): continue
        panel_name = config.get('featureNamePanel') or config.get('featureName')
        if panel_name not in enabled: continue
        for key, value in config.items():
            if key.startswith('featureName') and isinstance(value, str) and value and value not in enabled:
                template = dict(items[0]); template['name'] = value
                items.append(template); enabled.add(value)
    return {'maintenanceItem': items}


@endpoint('geneNickname')
def h_gene_nickname(api, params):
    return {'nickname': '主公%d' % (int(time.time()) % 100000)}


@endpoint('createUser')
def h_create_user(api, params):
    """创角。客户端在 CreateCharacterScene 里调，**之后立刻 gameInit**。

    这一步才真正建 player 行，并把会话绑到新角色上 ——
    紧接着的 gameInit 才能凭同一个 sk 找到角色。
    """
    acc = api.ctx.account.account_by_session(api.sk)
    if acc is None:
        raise ApiError(710070)
    nick = str(api.param(params, 'nickName', '') or '').strip()
    avatar = int(api.param(params, 'avatarId', 0) or 0)
    invite = api.param(params, 'inviteCode', None)
    if not nick:
        raise ApiError(710073)                 # NICKNAME_IS_NULL
    server_id = int(api.param(params, 'serverId', 1) or 1)

    p = api.repos.player.player_by_account(int(acc['account_id']), server_id)
    if p is None:
        pid = api.ctx.account.create_player(int(acc['account_id']), server_id, nick,
                                            avatar, invite)
    else:
        pid = int(p['player_id'])
        if not api.repos.asset.cards(pid):
            api.ctx.account._bootstrap_new_player(pid, avatar)
    api.ctx.account.bind_session_player(api.sk, pid)
    p = api.repos.player.player(pid)
    return {'sharkUser': A.build_shark_user(p, api.repos.player.extend(pid))}


@endpoint('getMeta')
def h_get_meta(api, params):
    """45 个配置表。直接复用原服务端已实测的构造器。"""
    return api.ctx.meta_payload()


@endpoint('gameInit')
def h_game_init(api, params):
    """完整角色数据。**最容易崩的接口** —— 字段缺失/空表陷阱都在这里。"""
    p = api.require_player()
    api.ctx.player.regen_all(p['player_id'])
    return A.build_game_init(api.db, p['player_id'])


@endpoint('getHomeInfo')
def h_home_info(api, params):
    p = api.require_player()
    return A.build_home_info(api.db, p['player_id'])


@endpoint('recordTutorialStep')
def h_record_tutorial(api, params):
    p = api.require_player()
    if api.param(params, 'skipIntro', False) is True:
        steps = [{'funcName': 'Guide_EnterGame%d' % i, 'step': 1}
                 for i in range(1, 11)]
        with api.db.tx():
            for entry in steps:
                api.repos.player.add_tutorial_step(p['player_id'], 1, entry['funcName'])
        return {'tutorialSteps': steps}
    step = int(api.param(params, 'step', 0) or 0)
    # 客户端 canonUtils.ExeNewGuide 发的是 {funcName=guide, step=1}；
    # funcName 必须存下来，否则回包里的 tutorialSteps 无法满足 v.funcName 取值。
    func_name = api.param(params, 'funcName', '') or ''
    if step:
        api.repos.player.add_tutorial_step(p['player_id'], step, func_name)
    return {}


@endpoint('upgradeUser')
def h_upgrade_user(api, params):
    p = api.require_player()
    return {'sharkUser': A.build_shark_user(p, api.repos.player.extend(p['player_id']))}


@endpoint('rename')
def h_rename(api, params):
    p = api.require_player()
    nick = str(api.param(params, 'nickName', '') or '').strip()
    if not nick:
        raise ApiError(710073)
    api.repos.player.update(p['player_id'], nickname=nick,
                            last_rename_times=int(p['last_rename_times']) + 1)
    return {'nickName': nick}


# ================================================================ 资产查询
@endpoint('getProps')
def h_get_props(api, params):
    return {'sharkProps': A.build_props(api.db, api.require_player()['player_id'])}


@endpoint('getEquips')
def h_get_equips(api, params):
    return {'sharkEquips': A.build_equips(api.db, api.require_player()['player_id'])}


@endpoint('getPlayerTeamInfo')
def h_team_info(api, params):
    return A.build_team_info(api.db, api.require_player()['player_id'])


@endpoint('getCardBook')
def h_card_book(api, params):
    p = api.require_player()
    owned = {int(c['meta_id']) for c in api.repos.asset.cards(p['player_id'])}
    return {'sharkCardBook': {'cardMetaIds': sorted(owned), 'equipMetaIds': []},
            'cardBookAchievement': []}


@endpoint('getEquipFragments')
@endpoint('getCardFragments')
def h_fragments(api, params):
    p = api.require_player()
    return {
        'sharkCardFragments': [{'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
                               for r in api.repos.asset.fragments(p['player_id'],
                                                                  G.FRAG_CARD)],
        'sharkEquipFragments': [{'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
                                for r in api.repos.asset.fragments(p['player_id'],
                                                                   G.FRAG_EQUIP)],
        'fragments': [],
    }


# ================================================================ 卡牌
@endpoint('upgradeCard')
def h_upgrade_card(api, params):
    p = api.require_player()
    code, payload = api.ctx.asset.upgrade_card(
        p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)),
        api.int_list_param(params, 'slaveIds'), bool(api.param(params, 'useGold', True)))
    return code, payload


@endpoint('upgradeCardByGeneralExp')
def h_upgrade_card_exp(api, params):
    p = api.require_player()
    return api.ctx.asset.upgrade_card_by_general_exp(
        p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)), api.param(params, 'targetLevel', 1))


@endpoint('evolveCard')
def h_evolve_card(api, params):
    p = api.require_player()
    return api.ctx.asset.evolve_card(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)))


@endpoint('trainCard')
def h_train_card(api, params):
    p = api.require_player()
    return api.ctx.asset.train_card(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)),
                                    item_meta_id=int(api.param(params, 'metaId', 0) or 0),
                                    use_gold=bool(params.get('special')),
                                    train_times=int(params.get('trainTimes') or 1))


@endpoint('saveCardTrain')
def h_save_train(api, params):
    p = api.require_player()
    return api.ctx.asset.save_card_train(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)))


@endpoint('giveUpCardTrain')
def h_giveup_train(api, params):
    p = api.require_player()
    return api.ctx.asset.give_up_card_train(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)))


@endpoint('lockCard')
def h_lock_card(api, params):
    p = api.require_player()
    return api.ctx.asset.lock_card(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)),
                                   api.param(params, 'methodType', 1))


@endpoint('adjustCardAvatar')
def h_adjust_avatar(api, params):
    p = api.require_player()
    return api.ctx.asset.adjust_card_avatar(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)),
                                            api.param(params, 'avatarMetaId', 0))


@endpoint('sellCards')
def h_sell_cards(api, params):
    p = api.require_player()
    return api.ctx.asset.sell_cards(p['player_id'], api.int_list_param(params, 'slaveIds')
                                    or api.int_list_param(params, 'cardIds'))


@endpoint('splitCard')
def h_split_card(api, params):
    p = api.require_player()
    return api.ctx.asset.split_card(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)))


@endpoint('prayCardFragment')
def h_pray_fragment(api, params):
    p = api.require_player()
    return api.ctx.asset.pray_card_fragment(p['player_id'], api.param(params, 'metaId', 0))


# ================================================================ 装备
@endpoint('upgradeEquip')
def h_upgrade_equip(api, params):
    p = api.require_player()
    return api.ctx.asset.upgrade_equip(p['player_id'], api.param(params, 'equipId', 0))


@endpoint('quickUpgradeEquip')
def h_quick_upgrade_equip(api, params):
    p = api.require_player()
    return api.ctx.asset.quick_upgrade_equip(p['player_id'], api.param(params, 'equipId', 0))


@endpoint('evolveEquip')
def h_evolve_equip(api, params):
    p = api.require_player()
    return api.ctx.asset.evolve_equip(p['player_id'], api.param(params, 'equipId', 0))


@endpoint('equipEnchant')
@endpoint('enchantEquip')
def h_equip_enchant(api, params):
    p = api.require_player()
    return api.ctx.asset.equip_enchant(p['player_id'], api.param(params, 'equipId', 0),
                                       int(api.param(params, 'propId', 0) or 0))


@endpoint('setupEquip')
def h_setup_equip(api, params):
    p = api.require_player()
    return api.ctx.asset.setup_equip(p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)),
                                     api.param(params, 'equipId', 0))


@endpoint('sellEquips')
def h_sell_equips(api, params):
    p = api.require_player()
    return api.ctx.asset.sell_equips(p['player_id'], api.int_list_param(params, 'equipIds'))


@endpoint('upgradeEquipForOneCard')
def h_upgrade_equip_one_card(api, params):
    p = api.require_player()
    return api.ctx.asset.upgrade_equip_for_one_card(
        p['player_id'], api.param(params, 'masterId', api.param(params, 'cardId', 0)), api.int_list_param(params, 'equipIds'))


# ================================================================ 道具 / 商店 / 编队
@endpoint('useProp')
def h_use_prop(api, params):
    p = api.require_player()
    return api.ctx.asset.use_prop(p['player_id'], api.param(params, 'propId', 0),
                                  api.param(params, 'amount', 1))


@endpoint('buyGoods')
def h_buy_goods(api, params):
    p = api.require_player()
    return api.ctx.asset.buy_goods(p['player_id'], api.param(params, 'goodsId', 0),
                                   api.param(params, 'amount', 1))


@endpoint('buyGrid')
def h_buy_grid(api, params):
    p = api.require_player()
    return api.ctx.asset.buy_grid(p['player_id'], api.param(params, 'gridNum', 1))


@endpoint('adjustTeam')
@endpoint('replaceCard')
def h_adjust_team(api, params):
    p = api.require_player()
    return api.ctx.asset.adjust_team(p['player_id'], api.param(params, 'mainCardId', 0),
                                     api.int_list_param(params, 'additionalCardIds'))


@endpoint('setCardGroupInterworking')
def h_set_interworking(api, params):
    p = api.require_player()
    return api.ctx.asset.set_card_group_interworking(
        p['player_id'], api.list_param(params, 'cardGroupInterworking'))


@endpoint('changeBattleArray')
def h_change_battle_array(api, params):
    p = api.require_player()
    api.repos.asset.set_active_array(p['player_id'], int(api.param(params, 'battleArrayId', 1)))
    return {}


# ================================================================ 抽卡
@endpoint('gachaCard')
@endpoint('gachaCardByRp')
def h_gacha_card(api, params):
    p = api.require_player()
    times = int(api.param(params, 'time', 1) or 1)
    with api.db.tx():
        return api.ctx.gacha.gacha(p['player_id'], api.param(params, 'gachaId', 1), times)


@endpoint('gachaCardFree')
def h_gacha_free(api, params):
    p = api.require_player()
    with api.db.tx():
        return api.ctx.gacha.free_gacha(p['player_id'], api.param(params, 'gachaId', 1))


@endpoint('getGachaBroadcast')
def h_gacha_broadcast(api, params):
    return {'broadcasts': api.ctx.gacha.broadcasts()}


@endpoint('getSharkGachaBoxInfo')
def h_gacha_box_info(api, params):
    """金宝箱（扭蛋盒）信息。

    ⚠️ 客户端 `GachaScene.lua:289` 读的是 **`evt.data.gachaBoxCard`**，不是 `boxInfo`；
       原来的 `{'boxInfo': []}` 会让它 `for k,v in pairs(nil)` 直接 Lua 报错。
    ⚠️ 返回的槽位里必须**恰好有一个** `special=true`：
       `GachaScene:428 refreshUI2` 会直接读 `self.gachaSpecialCard.cardStatus`，
       没有 special 槽就是 nil 索引 → SIGKILL。

    槽位状态与 `handlers_bag2.gachaCardByBox` 共用 `player_gacha_box` 表，
    谁先被调用谁负责铺满一批，所以两边看到的是同一份数据。
    """
    import time as _t
    p = api.require_player()
    pid = int(p['player_id'])
    with api.db.tx() as con:
        con.execute(
            "CREATE TABLE IF NOT EXISTS player_gacha_box ("
            " player_id INTEGER NOT NULL,"
            " slot_id   INTEGER NOT NULL,"
            " card_id   INTEGER NOT NULL DEFAULT 0,"
            " is_special INTEGER NOT NULL DEFAULT 0,"
            " is_drawn  INTEGER NOT NULL DEFAULT 0,"
            " create_time INTEGER NOT NULL DEFAULT 0,"
            " PRIMARY KEY (player_id, slot_id))")
    slots = [dict(r) for r in api.db.all(
        "SELECT * FROM player_gacha_box WHERE player_id=? ORDER BY slot_id", (pid,))]
    if not slots:
        # 第一次来：从活动抽卡池（gacha_card id=4）铺 12 格，最后一格是特殊格
        pool = G.roll_gacha(4, 12)
        now = int(_t.time())
        with api.db.tx() as con:
            con.execute("DELETE FROM player_gacha_box WHERE player_id=?", (pid,))
            for i, reward in enumerate(pool, 1):
                con.execute(
                    "INSERT INTO player_gacha_box(player_id, slot_id, card_id,"
                    " is_special, is_drawn, create_time) VALUES (?,?,?,?,0,?)",
                    (pid, i, int(reward.get('metaId') or 0),
                     1 if i == len(pool) else 0, now))
        slots = [dict(r) for r in api.db.all(
            "SELECT * FROM player_gacha_box WHERE player_id=? ORDER BY slot_id", (pid,))]
    return {
        'gachaBoxCard': [
            {'id': int(s['slot_id']), 'cardId': int(s['card_id']),
             'cardStatus': 1 if int(s['is_drawn']) else 0,
             'special': bool(int(s['is_special']))}
            for s in slots],
        'freeTimes': 0,
    }


@endpoint('refreshGachaBox')
def h_refresh_gacha_box(api, params):
    """重铺扭蛋盒 —— 直接把已有槽位清空再走一次 getSharkGachaBoxInfo 的铺法。"""
    p = api.require_player()
    with api.db.tx() as con:
        con.execute("DELETE FROM player_gacha_box WHERE player_id=?",
                    (int(p['player_id']),))
    return h_gacha_box_info(api, params)


# ================================================================ 关卡
@endpoint('clearMission')
def h_clear_mission(api, params):
    p = api.require_player()
    return api.ctx.mission.clear_mission(p['player_id'], api.param(params, 'missionId', 100101),
                                         api.param(params, 'routeId', 1),
                                         api.param(params, 'clearRounds', 1))


@endpoint('triggerCoinEvent')
def h_trigger_coin(api, params):
    return api.ctx.mission.trigger_event(api.require_player()['player_id'], 'coin', params)


@endpoint('triggerExpEvent')
def h_trigger_exp(api, params):
    return api.ctx.mission.trigger_event(api.require_player()['player_id'], 'exp', params)


@endpoint('triggerEmptyEvent')
def h_trigger_empty(api, params):
    p = api.require_player()
    return api.ctx.mission.trigger_event(p['player_id'], 'empty', params)


@endpoint('triggerCardEvent')
def h_trigger_card(api, params):
    return api.ctx.mission.trigger_event(api.require_player()['player_id'], 'card', params)


@endpoint('triggerRandomEvent')
def h_trigger_random(api, params):
    return api.ctx.mission.trigger_event(api.require_player()['player_id'], 'random', params)


@endpoint('triggerBattleEvent')
def h_trigger_battle(api, params):
    p = api.require_player()
    return api.ctx.mission.trigger_event(p['player_id'], 'battle', params)


@endpoint('getMissionCompleteInfo')
def h_mission_complete(api, params):
    return api.ctx.mission.get_mission_complete_info(api.require_player()['player_id'])


@endpoint('getEliteInfo')
def h_elite_info(api, params):
    return api.ctx.mission.elite_info(api.require_player()['player_id'])


@endpoint('resetElite')
def h_reset_elite(api, params):
    return api.ctx.mission.reset_elite(api.require_player()['player_id'])


@endpoint('challengeElite')
def h_challenge_elite(api, params):
    p = api.require_player()
    code, payload = api.ctx.mission.challenge(p['player_id'],
                                              api.param(params, 'missionId', 100101), 2)
    if code == OK:
        api.repos.progress.set_max_finished_elite(p['player_id'],
                                                  api.param(params, 'eliteId', 0) or 0)
    return code, payload


@endpoint('EliteSweep')
@endpoint('eliteSweep')
def h_elite_sweep(api, params):
    p = api.require_player()
    return api.ctx.mission.elite_sweep(p['player_id'], api.param(params, 'eliteId', 0),
                                       api.param(params, 'round', 1))


@endpoint('challengeBabel')
def h_challenge_babel(api, params):
    return api.ctx.mission.challenge_babel(api.require_player()['player_id'],
                                           api.param(params, 'floor', 0))


@endpoint('getBabelInfo')
def h_babel_info(api, params):
    return api.ctx.mission.babel_info(api.require_player()['player_id'])


@endpoint('resetClearTime')
def h_reset_clear_time(api, params):
    """重置关卡推进（客户端「重置」按钮）。

    ⚠️ 客户端回调会读 `data.clearMissionRewards` 弹奖励展示，返回 `{}` 会崩。
       重置本身不发奖，所以这里返回结构完整的空列表。
    """
    p = api.require_player()
    today = api.db.today()
    api.repos.player.bump_daily(p['player_id'], today, 'mission_reset_num')
    api.repos.progress.update_mission_context(p['player_id'], finished_step=0)
    return {'clearMissionRewards': []}


# ================================================================ 邮件
@endpoint('getUserEmails')
def h_get_emails(api, params):
    return A.build_emails(api.db, api.require_player()['player_id'])


@endpoint('readSysEmail')
@endpoint('readSysNotice')
@endpoint('readUserEmail')
@endpoint('EmailReadRewardEmail')
def h_read_mail(api, params):
    p = api.require_player()
    for key, mt in (('sysEmailId', 1), ('sysNoticeId', 3), ('userEmailId', 4),
                    ('rewardEmailId', 2), ('sysEmailMetaId', 1)):
        if params.get(key) is not None:
            api.repos.social.mark_mail(p['player_id'], int(params[key]), is_read=True)
            break
    return {}


@endpoint('deleteSysEmail')
@endpoint('deleteSysNotice')
@endpoint('deleteUserEmail')
@endpoint('EmailBatchDeleteSysEmail')
@endpoint('EmailBatchDeleteSysNotice')
@endpoint('EmailBatchDeleteUserEmail')
@endpoint('EmailBatchDeleteRewardEmail')
@endpoint('batchDeleteEmails')
def h_delete_mail(api, params):
    """删除邮件。

    ⚠️ 客户端删邮件后会读 `data.rewards`（删带附件的邮件 = 附件自动入包并弹提示）。
       返回 `{}` 会让 `RewardManager:getReward(nil)` 崩，所以删之前先把附件结算掉。
    """
    p = api.require_player()
    grants = []
    for key, mt in (('sysEmailId', 1), ('sysEmailMetaId', 1), ('sysNoticeId', 3),
                    ('sysNoticeIds', 3), ('userEmailId', 4), ('userEmailIds', 4),
                    ('rewardEmailId', 2), ('rewardEmailIds', 2),
                    ('sysEmailIds', 1)):
        v = params.get(key)
        if v is None:
            continue
        ids = to_list(v)
        # 先结算附件，再删
        for mid in ids:
            try:
                mail = api.repos.social.mail(p['player_id'], int(mid))
            except (TypeError, ValueError):
                continue
            if mail is None or int(mail['is_gained']):
                continue
            for a in api.repos.social.mail_attachments(int(mail['mail_id'])):
                grants.append({'itemType': int(a['item_type']),
                               'metaId': int(a['meta_id']),
                               'amount': int(a['amount'])})
        api.repos.social.delete_mails(p['player_id'], mt, ids)
    applied = []
    if grants:
        applied, _ = api.ctx.reward.grant(p['player_id'], grants, record=True,
                                          reason='mailDelete')
    return {'rewards': applied}


@endpoint('gainSysEmailReward')
@endpoint('gainRewardEmailReward')
@endpoint('EmailGainRewardEmailReward')
def h_gain_mail_reward(api, params):
    """领邮件附件。

    ⚠️ 客户端发的是 `{sysEmailId = <sysEmailMetaId>}` —— 键名与值语义不一致，
       所以这里两种解释都试一遍。
    ⚠️ 成功响应里的 rewards **必须存在**：客户端 GetRewardInfoPanel 会 pairs(nil)。
    """
    p = api.require_player()
    mid = None
    for key in ('sysEmailId', 'rewardEmailId', 'rewardEmailMetaId', 'mailId'):
        if params.get(key) is not None:
            mid = int(params[key])
            break
    if mid is None:
        return {'rewards': []}
    mail = api.repos.social.mail(p['player_id'], mid)
    if mail is None:
        # 按 metaId 找第一封未领的对应邮件
        mail = api.db.one(
            "SELECT * FROM mail WHERE player_id=? AND mail_type IN (1,2) AND meta_id=?"
            " AND is_gained=0 AND is_deleted=0 ORDER BY create_time LIMIT 1",
            (p['player_id'], mid))
    if mail is None or int(mail['is_gained']):
        return {'rewards': []}
    atts = api.repos.social.mail_attachments(int(mail['mail_id']))
    rewards = [{'itemType': int(a['item_type']), 'metaId': int(a['meta_id']),
                'amount': int(a['amount'])} for a in atts]
    api.repos.social.mark_mail(p['player_id'], int(mail['mail_id']), is_gained=True,
                               is_read=True)
    applied, _ = api.ctx.reward.grant(p['player_id'], rewards, record=True,
                                      reason='mailReward')
    return {'rewards': applied}


@endpoint('sendUserEmail')
def h_send_user_mail(api, params):
    p = api.require_player()
    to = int(api.param(params, 'receiveUid', 0) or 0)
    if to and api.repos.player.player(to):
        api.repos.social.create_mail(to, 4, title=str(api.param(params, 'notice', '') or ''),
                                     content=str(api.param(params, 'content', '') or ''),
                                     sender_uid=p['player_id'],
                                     sender_name=p['nickname'] or '')
    with api.db.tx() as con:
        con.execute("INSERT INTO user_mail_log(from_uid, to_uid, title, content, create_time)"
                    " VALUES (?,?,?,?,?)",
                    (p['player_id'], to, str(api.param(params, 'notice', '') or ''),
                     str(api.param(params, 'content', '') or ''), int(time.time())))
    return {}


# ================================================================ 其它
@endpoint('getAchievements')
def h_achievements(api, params):
    return {'sharkAchievement': []}


@endpoint('getRewardList')
def h_reward_list(api, params):
    return {'sharkRewardList': []}


@endpoint('getAnnouncementInfo')
def h_announcement(api, params):
    rows = api.db.all("SELECT * FROM announcement WHERE enabled=1 ORDER BY sort_order")
    return {'announcements': [{'announceId': int(r['announce_id']), 'title': r['title'],
                               'content': r['content'], 'startTime': int(r['start_time']),
                               'endTime': int(r['end_time'])} for r in rows]}


@endpoint('getUserUnionInfo')
def h_user_union_info(api, params):
    """未入团时**允许** sharkUserUnion 缺失（客户端 UnionManager:862 判空）。"""
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        return {'hasUnion': False}
    return {'hasUnion': True, 'sharkUserUnion': _union_payload(api, p, g)}


@endpoint('getUnionInfo')
def h_union_info(api, params):
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        raise ApiError(716301)
    m = api.repos.guild.monster(int(g['guild_id']))
    return {
        'sharkUnion': _guild_payload(g),
        'sharkUserUnion': _union_payload(api, p, g),
        # ⚠️ unionMonsterHp / unionMonsterEscapeSeconds 必须非 nil
        'unionMonsterHp': int(m['monster_left_hp']),
        'unionMonsterEscapeSeconds': int(m['escape_seconds']),
        'unionTotalFightCapacity': int(g['total_fight_capacity']),
    }


def _guild_payload(g):
    """⚠️ 这个结构里**没有** unionName —— 军团名只在 sharkUserUnion.unionName。"""
    return {
        'unionId': int(g['guild_id']),
        'serverId': int(g['server_id']),
        'declaration': g['declaration'] or '',
        'notice': g['notice'] or '',
        'level': int(g['level']),
        'wealth': int(g['wealth']),
        'memberNum': int(g['member_num']),
        'managerId': int(g['leader_uid']),
        'nextManagerId': int(g['transfer_uid']),
        'transferTime': int(g['transfer_time']),
        'unbandTime': int(g['dissolve_time']),
        'status': int(g['status']),
        'createTime': int(g['create_time']),
    }


def _title_enum(raw):
    """军团职务：数据库存 99/90/10/0，客户端枚举是 1..4。

    客户端 `UnionManager.lua:87-90`：TITLE_MANAGER=1 / VICE=2 / ELITE=3 / MEMBER=4，
    `getMyTitle()` 原样返回这个值。直接把 99 发过去会让**团长/副团的所有权限判断
    全部失效**（改公告、审批申请、调整阵型按钮都不出现）。
    """
    v = int(raw or 0)
    if v >= 99:
        return 1
    if v >= 90:
        return 2
    if v >= 10:
        return 3
    return 4


def _union_payload(api, p, g):
    """sharkUserUnion：**19 个字段，缺一个都可能出问题**。"""
    return {
        'unionId': int(g['guild_id']),
        'unionName': g['name'] or '',
        'title': _title_enum(g['member_title']),
        'contribute': int(g['contrib_week'] or 0),
        'hisContribute': int(g['contrib_total'] or 0),
        'status': int(g['member_status'] or 0),
        'joinSeconds': int(g['join_time'] or 0),
        'reactiveSeconds': int(g['reactive_time'] or 0),
        'dissolvedSeconds': int(g['dissolved_time'] or 0),
        'lastestConstructSeconds': int(g['last_construct_time'] or 0),
        'challengeCityId': int(g['challenge_city_id'] or 0),
        'coinInspireNum': int(g['coin_inspire_num'] or 0),
        'striveInspireNum': int(g['strive_inspire_num'] or 0),
        'gemInspireNum': int(g['gem_inspire_num'] or 0),
        'unionWarVersion': int(g['union_war_version'] or 0),
        'unionWarRound': int(g['union_war_round'] or 0),
        'gainUnionWarPlayReward': bool(g['gain_war_play']),
        'gainUnionWarOccupyReward': bool(g['gain_war_occupy']),
        'gainUnionWarInBattleReward': bool(g['gain_war_in_battle']),
    }


@endpoint('getUnionList')
def h_union_list(api, params):
    p = api.require_player()
    rows = api.repos.guild.guild_list(int(p['server_id']))
    return {'sharkUnionWrappers': [
        {'unionId': int(r['guild_id']), 'name': r['name'], 'level': int(r['level']),
         'memberNum': int(r['member_num']), 'wealth': int(r['wealth']),
         'rank': int(r['rank']), 'declaration': r['declaration'] or '',
         'managerId': int(r['leader_uid']),
         'managerName': (api.repos.player.player(r['leader_uid']) or {'nickname': ''})['nickname'],
         'managerLevel': int((api.repos.player.player(r['leader_uid']) or {'level': 1})['level'])} for r in rows]}


@endpoint('createUnion')
def h_create_union(api, params):
    p = api.require_player()
    if api.repos.guild.is_in_guild(p['player_id']):
        raise ApiError(716300)             # USER_JOINED_UNION
    name = str(api.param(params, 'unionName', '') or '').strip()
    if not name:
        raise ApiError(716301)
    if api.repos.guild.guild_by_name(int(p['server_id']), name):
        raise ApiError(716302)
    cost = 500
    if api.ctx.player.spend_gems(p['player_id'], cost) is None:
        raise ApiError(710513)
    gid = api.repos.guild.create_guild(int(p['server_id']), name, p['player_id'],
                                       declaration=str(api.param(params, 'declaration', '') or ''),
                                       notice=str(api.param(params, 'notice', '') or ''))
    api.repos.guild.add_news(gid, 1, 1, actor_uid=p['player_id'],
                             actor_name=p['nickname'] or '', actor_level=int(p['level']))
    return {'unionId': gid}


@endpoint('getUnionMembersList')
def h_union_members(api, params):
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        raise ApiError(716301)
    rows = api.repos.guild.members(int(g['guild_id']))
    return {'sharkUnionMemberWrappers': [
        {'uid': int(r['player_id']), 'nickName': r['nickname'] or '',
         'level': int(r['level'] or 1), 'title': _title_enum(r['title']),
         'mainCardId': int(r['main_card_id'] or 0),
         'fightCapacity': int(r['fight_capacity'] or 0),
         'hisContribute': int(r['contrib_total']),
         'contribute': int(r['contrib_week']),
         'online': bool(r['online']),
         'lastestActiveSeconds': int(r['last_active_time'] or 0),
         'lastestConstructSeconds': int(r['last_construct_time'] or 0),
         'lastestConstructType': int(r['last_construct_type'] or 0),
         'arenaRank': 0} for r in rows]}


@endpoint('getUnionBuildingHallInfo')
@endpoint('getUnionBuildingBankInfo')
@endpoint('getUnionBuildingShopInfo')
@endpoint('getUnionBuildingColosseumInfo')
def h_union_building(api, params):
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        raise ApiError(716301)
    gid = int(g['guild_id'])
    b = api.repos.guild.building(gid, int(api.param(params, 'unionBuildingId', 1) or 1))
    m = api.repos.guild.monster(gid)
    return {
        'sharkUnionBuildingWrapper': {'buildingId': int(b['building_id']),
                                      'level': int(b['level']),
                                      'constructTimesToday': int(b['construct_times_today']),
                                      'lastestConstructSeconds': int(b['last_construct_seconds'])},
        'donateAnnouncement': [],
        'summonTimes': int(m['summon_times']),
        'specialProps': [],
        'specialShopRecord': [],
        'sharkUnionMonster': _monster_payload(m),
    }


def _monster_payload(m):
    """⚠️ reward 必须是**对象**且含 amount（客户端取 .reward.amount 做减法）。"""
    return {
        'monsterId': int(m['monster_id']),
        'monsterLeftHp': int(m['monster_left_hp']),
        'escapeSeconds': int(m['escape_seconds']),
        'summonUserNickname': m['summon_user_nickname'] or '',
        'rewardDouble': bool(m['reward_double']),
        'distributingUid': int(m['distributing_uid']),
        'rewardDistributed': bool(m['reward_distributed']),
        'reward': {'amount': int(m['reward_amount'])},
    }


@endpoint('getUnionNews')
def h_union_news(api, params):
    p = api.require_player()
    g = api.repos.guild.guild_of(p['player_id'])
    if not g:
        raise ApiError(716301)
    rows = api.repos.guild.news(int(g['guild_id']))
    return {
        'sharkUnionNewsWrappers': [
            {'senderUid': int(r['actor_uid']), 'senderNickname': r['actor_name'] or '',
             'senderLevel': int(r['actor_level']), 'mainCardId': int(r['actor_main_card_id']),
             'type': int(r['event_type']), 'detail': r['content'] or '{}',
             'createTime': int(r['create_time'])}
            for r in rows if int(r['news_type']) == 1],
        'unionWarNewsWrappers': [
            {'senderUid': int(r['actor_uid']), 'senderNickname': r['actor_name'] or '',
             'type': int(r['event_type']), 'detail': r['content'] or '{}',
             'createTime': int(r['create_time'])}
            for r in rows if int(r['news_type']) == 2],
    }
