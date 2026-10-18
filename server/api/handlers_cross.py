#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""跨服 PVP / 跨服 Boss / 跨服比武（武道会）/ 跨服扭蛋排行奖 —— 19 个端点。

本模块只新增文件，不改共享文件；`api/__init__.py:load_handlers()` 会自动
发现 `handlers_*.py` 并注册 `@endpoint`。

============================================================================
一、这一组接口的语义边界（为什么大多是「空列表 + 0 + 状态字段」）
============================================================================
这四个玩法在**原厂是跨服玩法**：参赛名单来自「多个服务器一起打的天梯」，
名额是从别的服务器同步过来的。本项目是单服还原，物理上只有一个 server_id，
跨服阶段的对手名单 / 服务器分组 / 跨服 Boss 血池**都不存在**。

所以正确的回包不是打桩一套假对手（那会让客户端渲染出「打一枪就报错」的假数据），
而是「本期未开启 / 无对手」：

    名单类      -> 空列表
    名次/积分   -> 0
    状态位      -> 明确的 0/False（客户端用它们决定按钮灰化）

每个 handler 都注明了客户端在哪个 Lua 文件、什么时机调、读哪些字段，
以及「为什么这个字段即使是 0 也必须给」——客户端 index 一个 nil 就会
Lua 报错、被引擎 kill 进程，这是本项目的头号崩溃源。

============================================================================
二、战斗类接口为什么仍然回完整战斗包
============================================================================
`challengeCrossUser` / `challengeCrossBoss` / `getCrossPkReport` 成功后，
客户端会直接 `replaceScene(BattleScene:create(e.data, ...))`。
BattleScene 里 `self.data.cardInitDatas` / `self.data.eventFlow` 是硬需求
（BattleScene.lua:2545 只有 kCrossGVG* 才有「无 cardInitDatas」分支，
其余分支必然 `pairs(nil)` 崩），所以这三个接口必须回一份**可演出**的战斗包。

战斗本身是真算的：走 `services/battle.py:chapter_battle()`，用该玩家
`player_battle_slot` 里真实的上阵卡（含装备/元神/宝物的属性加成）对
`battle_mission` 里真实的怪物组逐回合模拟，得出 win / leftHpRate 和逐帧
事件流。唯一「不是真跨服」的地方是**对手**：单服没有跨服对手，因此用本服
的参照怪物组当对手，注释里逐处写明了。

============================================================================
三、资源消耗为什么放在客户端
============================================================================
跨服 PVP 买次数（`buyCrossPvpChallengeTime`）、刷新对手（`refreshMatch` 的
付费模式）、跨服 Boss 鼓舞（`inspireCrossBossTeam`）的**价格与道具 id**
只存在于客户端配置 `crossArenaSettingConfig` / `crossBossSettingConfig`
（这两个 key 由 getMeta 下发，服务端 `meta_payload.py` 里没有），
服务端拿不到权威价格。客户端在这三个成功回调里已经本地扣了钻石/道具
（`RewardManager:getReward({itemType=GEMS, amount=-cost})` 等），
若服务端再扣一次就会和客户端显示**双重扣除**。

因此服务端只做权威的**次数/状态记账**（player_daily_counter + player_activity），
不重复扣费。价格字段原样带回给客户端。
"""
import json
import time

import gamedata as G

from . import endpoint, ApiError

OK = 200

# 本组接口目前只会抛 710071（参数不合法）。留档：客户端
# GetCrossPkInfoRequest.onFailedDefault / GainCrossPkRankRewardRequest.onFailedDefault
# 认得这几个跨服错误码，将来真开跨服周期时按它们回：
#   710560/710561 未开启   710562/710563 不在时间窗
#   710564 竞猜未开放      710565 已竞猜过
#   710566 领奖未开放      710567/710571 已领过
#   710568 本服不是冠军服  710569 不在榜单内
E_PARAM = 710071               # 参数不合法

# 跨服 PVP 每日计数键（player_daily_counter.counter_key）
CK_PVP_CHALLENGE = 'cross_pvp_challenge_num'
CK_PVP_BUY = 'cross_pvp_buy_num'
CK_PVP_REFRESH = 'cross_pvp_refresh_num'

# player_activity.activity_key
KEY_CROSS_BOSS = 'cross_boss'
KEY_CROSS_PVP = 'cross_pvp'


# ============================================================================
#  基础设施
# ============================================================================
def _pid(api):
    return api.require_player()['player_id']


def _player(api, pid=None):
    return api.ctx.repos.player.player(_pid(api) if pid is None else pid)


def _server_id(api, pid=None):
    """玩家所在服 —— 单服环境下跨服分组里只有它自己。"""
    try:
        return int(_player(api, pid)['server_id'] or 1)
    except Exception:
        return 1


# ---------------------------------------------------------------- 惰性建表
# `player_cross_pk` 在 schema.sql 里已有（sharkCrossPkUser 的落库形态）。
# 这里仍然 CREATE TABLE IF NOT EXISTS 一次：本模块要在「没有跑过 schema.sql 的
# 库」上也能跑，而且规则要求新表/新列只能在自己模块内惰性建。
_DDL = (
    "CREATE TABLE IF NOT EXISTS player_cross_pk ("
    " player_id         INTEGER PRIMARY KEY,"
    " cross_version     INTEGER NOT NULL DEFAULT 0,"
    " guess_uid         INTEGER NOT NULL DEFAULT 0,"
    " gain_guess_reward INTEGER NOT NULL DEFAULT 0,"
    " gain_rank_reward  INTEGER NOT NULL DEFAULT 0,"
    " gain_server_reward INTEGER NOT NULL DEFAULT 0,"
    " data_json         TEXT    NOT NULL DEFAULT '{}')",
)


_TABLES_READY = set()


def _ensure_tables(api):
    """惰性建表（每个进程只跑一次，避免每次请求都去抢写锁）。"""
    key = id(api.db) if api.db is not None else 0
    if key in _TABLES_READY:
        return
    ok = True
    for ddl in _DDL:
        try:
            with api.db.tx() as con:
                con.execute(ddl)
        except Exception:
            ok = False
    if ok:
        _TABLES_READY.add(key)


def _cross_pk_row(api, pid):
    """跨服比武（武道会）的个人状态行：竞猜对象 / 已领奖标记 / 届数。

    客户端 `sharkCrossPkUser` 有三个本地标记（guessUid / gainGuessReward /
    gainRankReward / gainServerReward），换手机重登后靠服务端这一行恢复。
    """
    _ensure_tables(api)
    pid = int(pid)
    try:
        with api.db.tx() as con:
            con.execute("INSERT INTO player_cross_pk(player_id) VALUES (?)"
                        " ON CONFLICT(player_id) DO NOTHING", (pid,))
        row = api.db.one("SELECT * FROM player_cross_pk WHERE player_id=?", (pid,))
    except Exception:
        row = None
    if row is None:
        # 表被外部锁住 / 旧库结构不符时退化成默认值，绝不 500。
        return {'player_id': pid, 'cross_version': 0, 'guess_uid': 0,
                'gain_guess_reward': 0, 'gain_rank_reward': 0,
                'gain_server_reward': 0, 'data_json': '{}'}
    return row


def _cross_pk_patch(api, pid, **fields):
    _ensure_tables(api)
    cols = [c for c in fields if c in ('cross_version', 'guess_uid',
                                       'gain_guess_reward', 'gain_rank_reward',
                                       'gain_server_reward')]
    if not cols:
        return
    sql = ("UPDATE player_cross_pk SET %s WHERE player_id=?"
           % ', '.join('%s=?' % c for c in cols))
    try:
        with api.db.tx() as con:
            con.execute(sql, tuple(int(fields[c]) for c in cols) + (int(pid),))
    except Exception:
        pass


# ---------------------------------------------------------------- 活动状态
def _state(api, pid, key):
    try:
        return api.ctx.activity.state(int(pid), key)
    except Exception:
        return {}


def _save_state(api, pid, key, data):
    try:
        api.ctx.activity.save_state(int(pid), key, data)
    except Exception:
        pass


def _today(api):
    return int(api.db.today())


def _daily(api, pid, key):
    try:
        return int(api.ctx.repos.player.daily_counter(int(pid), _today(api), key))
    except Exception:
        return 0


def _bump_daily(api, pid, key):
    try:
        return int(api.ctx.repos.player.bump_daily(int(pid), _today(api), key))
    except Exception:
        return _daily(api, pid, key)


def _int_param(api, params, key, default=0):
    """读整型参数。

    客户端正常只发 int，但 AMF3 里也可能来字符串/浮点（Lua 端 tonumber 过）。
    这里统一兜住：转不了就按业务错误码 710071 回，绝不让 int() 抛 ValueError
    变成 500（dispatch 会把未捕获异常包成 retCode=500 + extraMsg）。
    """
    v = api.param(params, key, default)
    if v is None:
        return int(default)
    try:
        return int(v)
    except (TypeError, ValueError):
        try:
            return int(float(v))
        except (TypeError, ValueError):
            raise ApiError(E_PARAM)


# ---------------------------------------------------------------- 战斗包
def _fallback_pack(api, pid, mission_id=100101, battle_type=1):
    """玩家还没配阵型 / 关卡表缺行时的兜底战斗包（**纯读，无副作用**）。

    为什么不直接用 `gamedata.build_battle_response()`：那个构造器会调用
    SoloStore 把 coin/exp 落进单机存档（canon_server._build_battle_response
    末尾的 `ST.apply_rewards(...)`），从 HTTP 接口里调会污染单机存档。
    这里只读 player_card + battle_mission 表，自己拼事件流。
    """
    p = _player(api, pid)
    G.init_battle_meta()
    src = G._cs
    ev = (src._BATTLE_EVENT.get((int(mission_id), int(battle_type)))
          or src._BATTLE_EVENT.get((int(mission_id), 1))
          or src._BATTLE_EVENT.get(int(mission_id)) or {})
    group = src._BATTLE_MONSTER_GROUP.get(ev.get('monsterGroupId')) or []
    level = int(ev.get('monsterLevel') or 1)
    revise = float(ev.get('monsterRevise') or 1.0)

    card = None
    try:
        card = api.ctx.repos.asset.card(int(pid), p['main_card_id'])
    except Exception:
        card = None
    main_meta = int(card['meta_id']) if card else G.STARTER_CARD_META
    main_lv = int(card['level']) if card else max(1, int(p['level'] or 1))

    units = [{
        'posId': 1, 'cardId': int(p['main_card_id'] or 0), 'metaId': main_meta,
        'level': main_lv, 'exp': 0,
        'hp': 1500 + main_lv * 80,
        'attack': 150 + main_lv * 12,
        'defense': 40 + main_lv * 4,
    }]
    enemies = []
    for i, mid in enumerate(group[:5]):
        mon = src._BATTLE_MONSTER.get(mid) or {
            'cardId': G.STARTER_CARD_META, 'reviseHP': 360,
            'reviseATT': 60, 'reviseDEF': 0}
        ehp = max(80, int(mon['reviseHP'] * revise * (0.5 + level * 0.15)))
        unit = {
            'posId': 10001 + i, 'cardId': 1000 + i, 'metaId': int(mon['cardId']),
            'level': level, 'exp': 0, 'hp': ehp,
            'attack': max(10, int(mon['reviseATT'] * revise)),
            'defense': max(0, int(mon['reviseDEF'] * revise)),
        }
        units.append(unit)
        enemies.append(unit)
    if not enemies:
        # 本地关卡表缺这一关的怪物组：给一个 1 血占位目标，避免空事件流
        unit = {'posId': 10001, 'cardId': 1000, 'metaId': G.STARTER_CARD_META,
                'level': level, 'exp': 0, 'hp': 1, 'attack': 1, 'defense': 0}
        units.append(unit)
        enemies.append(unit)

    # 每个敌人一刀打死：既让敌方血条掉到 0，也让客户端播完 ATTACK 演出后
    # 正常进结算（空 eventFlow 会变成 TIME UP / 无战斗）。
    event_flow = []
    for i, e in enumerate(enemies):
        event_flow.append({
            'eventType': 0, 'round': i, 'actionType': 0,
            'battleCardActs': [{'posId': e['posId'], 'skillId': 0,
                                'effectId': 0, 'changedValue': int(e['hp'])}],
        })
    total = sum(int(e['hp']) for e in enemies)
    return {'win': True, 'leftHpRate': 100, 'qte': False, 'rewards': [],
            'cardInitDatas': units, 'eventFlow': event_flow,
            'encounterMultiPlayerBoss': False, 'showQuery': False,
            'damage': total}


def _battle_pack(api, pid, mission_id=100101, battle_type=1):
    """构造一份客户端 BattleScene 能直接演出的战斗包。

    为什么必须给：客户端成功后立刻 `BattleScene:create(e.data, ...)`，
    `cardInitDatas`（双方所有单位的初始属性，posId>=10000 是敌方）和
    `eventFlow`（逐帧动作）缺一个就是 SIGKILL。

    真算：`chapter_battle()` 从 player_battle_slot 取真实上阵卡，叠加
    装备/元神/宝物属性，再对 battle_mission 的怪物组逐回合模拟。
    """
    from services.battle import chapter_battle
    try:
        pack = chapter_battle(api.db, int(pid), int(mission_id), int(battle_type))
    except Exception:
        pack = _fallback_pack(api, pid, mission_id, battle_type)
    pack.setdefault('win', True)
    pack.setdefault('leftHpRate', 80)
    pack.setdefault('qte', False)
    pack.setdefault('encounterMultiPlayerBoss', False)
    pack.setdefault('showQuery', False)
    if not pack.get('rewards'):
        pack['rewards'] = []
    return pack


def _pack_damage(pack):
    """从事件流里统计「我方对敌方造成的总伤害」。

    posId >= 10000 是敌方（见 services/battle.py 与 canon_server 的约定），
    事件里 `battleCardActs[].posId` 是被打的目标。
    """
    total = 0
    for ev in pack.get('eventFlow') or []:
        for act in ev.get('battleCardActs') or []:
            try:
                if int(act.get('posId') or 0) >= 10000:
                    total += max(0, int(act.get('changedValue') or 0))
            except (TypeError, ValueError):
                continue
    return total


def _enemy_hp_total(pack):
    total = 0
    for u in pack.get('cardInitDatas') or []:
        try:
            if int(u.get('posId') or 0) >= 10000:
                total += max(0, int(u.get('hp') or 0))
        except (TypeError, ValueError):
            continue
    return total


def _user_info(api, pid=None):
    """排行榜条目（跨服比武 / 跨服 Boss 共用的展示结构）。

    客户端 AcrossRewardPanel / AcrossFixturesPanel 读：
    uid、nickName、level、mainCardMetaId；服务器号从 uid 末 4 位截出来
    （AcrossFightManager.whetherHasServerReward），所以 uid 必须是
    「服务端 uid」而不是自增序号。
    """
    try:
        p = _player(api, pid)
        card = api.ctx.repos.asset.card(int(p['player_id']), p['main_card_id'])
        return {
            'uid': str(int(p['player_id'])),
            'nickName': p['nickname'] or '',
            'level': int(p['level'] or 1),
            'mainCardMetaId': int(card['meta_id']) if card else G.STARTER_CARD_META,
            'mainCardMeataId': int(card['meta_id']) if card else G.STARTER_CARD_META,
            'server': _server_id(api, pid),
            'unionName': '',
            'combat': int(p['fight_capacity'] or 0),
            'battleScore': 0,
            'score': 0,
            'rank': 0,
        }
    except Exception:
        return {'uid': '0', 'nickName': '', 'level': 1, 'mainCardMetaId': 0,
                'mainCardMeataId': 0, 'server': 1, 'unionName': '', 'combat': 0,
                'battleScore': 0, 'score': 0, 'rank': 0}


# ============================================================================
#  跨服 Boss（Siren / 女妖）—— 6 个端点
#
#  客户端调用链：
#    ActivityPanelScene.lua:715  -> GetCrossBossInfoRequest
#    Activity_CrossMultiplayerBossLayer.lua -> 按 phaseType 进 备战/战斗/领奖
#    challengeCrossBoss / refreshCrossBossBattlePhase / inspireCrossBossTeam /
#    getCrossBossRankInfo / gainCrossBossReward
# ============================================================================
#
#  phaseType 语义（客户端 AcrossFightTimeEnum 之外的 CrossBoss 三阶段）：
#      0 = 备战期（本期未开启，只有服务器分组展示）
#      1 = 战斗期（Boss 血池 / 个人分数 / 排名）
#      2 = 领奖期
#
#  单服没有跨服 Boss 周期（周期锚点是客户端 crossBossSettingConfig 里的
#  featureNamePrepare/Battle/Reward 开启时间，服务端没有这份配置），
#  因此统一上报 phaseType = 0「本期未开启」。
# ============================================================================
CROSS_BOSS_VERSION = 1   # 第 1 期；客户端 getGodHerosByVersion((v%4)+1) 取神将表


def _boss_scores(api):
    """跨服 Boss 里所有玩家的累计伤害 -> {player_id: damage}。

    player_activity(activity_key='cross_boss') 的 data_json 里的 damage 就是
    真算的累计伤害（challengeCrossBoss 每次累加），所以个人名次可以真排。
    """
    out = {}
    try:
        rows = api.db.all("SELECT player_id, data_json FROM player_activity"
                          " WHERE activity_key=?", (KEY_CROSS_BOSS,))
    except Exception:
        return out
    for r in rows:
        try:
            d = json.loads(r['data_json'] or '{}')
            if not isinstance(d, dict):
                continue
            out[int(r['player_id'])] = int(d.get('damage') or 0)
        except Exception:
            continue
    return out


def _boss_rank(api, pid):
    """返回 (rank, myScore)。rank 从 1 开始；没参与过记 0。"""
    scores = _boss_scores(api)
    mine = int(scores.get(int(pid)) or 0)
    if mine <= 0:
        return 0, mine
    better = sum(1 for v in scores.values() if v > mine)
    return better + 1, mine


@endpoint('getCrossBossInfo')
def h_get_cross_boss_info(api, params):
    """跨服 Boss 面板信息（备战期）。

    客户端：ActivityPanelScene.lua:715 先拉一次决定活动卡是否可点；
    进入后 Activity_CrossMultiplayerBossLayer:getCrossBossInfo() 再拉，
    把**整个回包**当 extraArgs：

        self.version  = extraArgs.crossVersion          （期数）
        self.extraArgs.phaseType                        （0/1/2，决定进哪个界面）
        preparePhase.serverIds                          （备战期展示本组服务器）
        battlePhase.{bossType,maxHp,inspireAddition,score,rank,battlePhaseMini}
        rewardPhase.{bossStatus,ranks,rank,score,canReward}

    ⚠️ phaseType 只能是 0/1/2：changeLayerByStatus 末尾
    `getEndTimeByCurrentStage(phaseType)` 返回 nil 会让
    `CdLabelComponent:setTargetTime(nil + 5)` 崩。所以这里绝不给别的值。
    ⚠️ preparePhase.serverIds 必须是数组（initPrepare 用 pairs 遍历并取
    `#serverIds` 做分隔符判断），空数组也安全，但不能缺。
    """
    pid = _pid(api)
    st = _state(api, pid, KEY_CROSS_BOSS)
    rank, score = _boss_rank(api, pid)
    sid = _server_id(api)
    info = _user_info(api, pid)

    return {
        'crossVersion': CROSS_BOSS_VERSION,
        # 0 = 备战期 / 本期未开启：单服没有跨服 Boss 周期
        'phaseType': 0,
        'preparePhase': {
            # 本组服务器：单服环境里只有自己这一台
            'serverIds': [sid],
            'bossType': 0,
            'beginTime': 0,
            'endTime': 0,
        },
        'battlePhase': {
            'bossType': int(st.get('bossType') or 1),
            'maxHp': 0,          # 跨服共享血池，本期没开启 => 0
            'inspireAddition': float(st.get('inspireAddition') or 0),
            'score': score,
            'rank': rank,
            'battlePhaseMini': {
                'hp': 0,         # Boss 未开启，剩余血量 0
                'wake': True,
                'combos': [],    # 别人的连击弹幕（跨服才有）
                'ranks': [],
            },
        },
        'rewardPhase': {
            'bossStatus': 0,
            'rank': rank,
            'score': score,
            'canReward': False,   # 不在领奖期
            'ranks': [],
        },
        # 以下为便于面板直接读的平铺镜像（客户端不强制，但缺了也不会崩）
        'challengeTime': int(st.get('challengeTime') or 0),
        'inspireTimes': int(st.get('inspireTimes') or 0),
        'inspireAddition': float(st.get('inspireAddition') or 0),
        'damage': score,
        'rank': rank,
        'bloodStatus': 0,
        'crossBossUserInfo': info,
    }


@endpoint('challengeCrossBoss')
def h_challenge_cross_boss(api, params):
    """挑战跨服 Boss（params: {type 0免费/1付费, bossType 1普通/2觉醒/3狂暴}）。

    客户端：Activity_CrossMultiplayerBossLayer.lua:780 onChallenge
        successCallback 里 data.data.type / bossHpMax 会被改写，然后
        replaceScene(BattleScene:create(data.data, kActivityCrossBoss, ...))
    战斗结束进 CrossMultiplayerBattleRewardPanel:create(scene, tosendData)，
    它读 data.{win, damage, score, rewards, type}。

    ⚠️ 所以回包必须同时满足两个消费者：
       BattleScene    -> cardInitDatas / eventFlow / win / leftHpRate
       结算面板       -> damage / score / rewards / type

    战斗是真算的（玩家真实阵容 vs 参照怪物组）；单服没有跨服 Boss 血池，
    所以 bossHp/bossHpMax 给 0、score 直接用本次真实造成的伤害累加
    （跨服 Boss 的分数定义本来就是「对 Boss 造成的伤害」）。
    """
    pid = _pid(api)
    boss_type = _int_param(api, params, 'bossType', 1)
    if boss_type not in (1, 2, 3):
        boss_type = 1

    pack = _battle_pack(api, pid, 100101, 1)
    damage = _pack_damage(pack)
    max_hp = _enemy_hp_total(pack)

    st = _state(api, pid, KEY_CROSS_BOSS)
    st['damage'] = int(st.get('damage') or 0) + damage
    st['challengeTime'] = int(st.get('challengeTime') or 0) + 1
    st['bossType'] = boss_type
    st['lastChallengeTime'] = int(time.time())
    _save_state(api, pid, KEY_CROSS_BOSS, st)
    _bump_daily(api, pid, 'cross_boss_challenge_num')

    rank, score = _boss_rank(api, pid)
    pack.update({
        'type': boss_type,
        'damage': damage,
        'score': score,
        'rank': rank,
        'bossHp': 0,
        'bossHpMax': max_hp,
        'bossType': boss_type,
        # 攻击奖励的配置（crossBossRewardConfig）只在客户端，服务端不凭猜测
        # 发奖；真正的排名/参与奖走 gainCrossBossReward。
        'rewards': [],
        'whetherWin': bool(pack.get('win')),
    })
    return OK, pack


@endpoint('refreshCrossBossBattlePhase')
def h_refresh_cross_boss_battle_phase(api, params):
    """轮询「别人打在 Boss 上的战况」（客户端每 battleReportSleepTime 秒拉一次）。

    客户端：Activity_CrossMultiplayerBossLayer.lua:511
        successCallback: data.data.miniInfo.hp <= 0 -> 重新 getCrossBossInfo，
        否则 self.battlePhaseMini = data.data.miniInfo（随后用 .combos 播弹幕、
        .ranks 刷新右侧 3 人榜、.wake 判断觉醒）。

    miniInfo 的四个字段都必须在：combos 要能被 pairs 遍历、ranks 要能被
    `#ranks` + 下标访问，缺一个就会在 refreshBattle / playOtherPlayerFlash 里崩。
    """
    pid = _pid(api)
    rank, score = _boss_rank(api, pid)
    st = _state(api, pid, KEY_CROSS_BOSS)
    return {
        'miniInfo': {
            'hp': 0,                       # 本期 Boss 未开启
            'wake': True,
            'combos': [],
            'ranks': [],
        },
        'bossType': int(st.get('bossType') or 1),
        'rank': rank,
        'score': score,
        'combos': [],
        'ranks': [],
    }


@endpoint('inspireCrossBossTeam')
def h_inspire_cross_boss_team(api, params):
    """跨服 Boss 鼓舞（params: {props 道具鼓舞次数, gems 钻石鼓舞次数}）。

    客户端：CrossBossInspirePanel.lua:189 确认时把「本次用了几次道具/钻石」
    传上来；成功回调里客户端自己扣道具和钻石，并把
    CrossWorldBossManager.setInsprieValue(expectInspire) 写回本地。

    服务端只做两件事：
      1. 记账（次数），保证重登后 getCrossBossInfo 的 inspireTimes 一致；
      2. 回 succ / inspireTimes，绝不在服务端二次扣费 —— 鼓舞道具 id
         (crossBossSettingConfig.inspirePropId) 和单价只在客户端配置里，
         服务端猜一个 id 去扣会扣错东西。
    """
    pid = _pid(api)
    props = _int_param(api, params, 'props', 0)
    gems = _int_param(api, params, 'gems', 0)
    if props < 0 or gems < 0:
        raise ApiError(E_PARAM)

    st = _state(api, pid, KEY_CROSS_BOSS)
    times = int(st.get('inspireTimes') or 0) + props + gems
    st['inspireTimes'] = times
    st['lastInspireTime'] = int(time.time())
    _save_state(api, pid, KEY_CROSS_BOSS, st)

    return {
        'succ': True,
        'inspireTimes': times,
        'propsInspire': props,
        'gemsInspire': gems,
        # 加成百分比算法（每档 +inspirePropBuff/inspireGoldBuff）在客户端
        # 配置里，客户端已经自己算好并写回本地，这里只回起点值不回假值。
        'inspireAddition': float(st.get('inspireAddition') or 0),
        'rewards': [],
    }


@endpoint('getCrossBossRankInfo')
def h_get_cross_boss_rank_info(api, params):
    """跨服 Boss 伤害榜。

    客户端：Activity_CrossMultiplayerBossLayer.lua:900
        CrossBossRankInfoPanel:create(self, {ranks = data.data.ranks})
    面板每条读 serverId / nickName / score / uid
    （CrossBossRankInfoPanel.lua:94-98、129-135、185）。

    本期没开启 => 空榜。⚠️ 不能给只有自己一条的榜：面板会用
    `self.list[index].xxx` 直接下标，条目字段缺一个就崩；空榜走 0 行最安全。
    """
    pid = _pid(api)
    rank, score = _boss_rank(api, pid)
    return {
        'ranks': [],
        'rank': rank,
        'score': score,
        'myRank': rank,
        'myScore': score,
        'rankingListNum': len(_boss_scores(api)),
    }


@endpoint('gainCrossBossReward')
def h_gain_cross_boss_reward(api, params):
    """领取跨服 Boss 结算奖励。

    客户端：Activity_CrossMultiplayerBossLayer.lua:1081 onReward
        CrossMultiplayerGetRankRewardPanel:create(self.container, data.data)
    面板对**整个回包**做 `for k, v in pairs(self.rewards)`，每个 key 起一行，
    行标题按 key 匹配（CrossMultiplayerGetRankRewardPanel.lua:95-103）：

        rankRewards  -> 「排名奖励」
        partRewards  -> 「参与奖励」
        beatRewards  -> 「最后一击奖励」

    ⚠️ 三个 key 必须都在，且值必须是**奖励数组**：面板会 `data.rewards[i]`
    下标读取，若某个 key 给成数字/字符串会直接 index 崩。
    本期不在领奖期 => 三组都是空数组（面板会渲染 3 行空图标，不崩）。
    """
    pid = _pid(api)
    rank, score = _boss_rank(api, pid)
    st = _state(api, pid, KEY_CROSS_BOSS)
    return {
        'rankRewards': [],
        'partRewards': [],
        'beatRewards': [],
        'rewards': [],
        'canReward': False,        # 不在领奖期（phaseType==0）
        'rank': rank,
        'score': score,
        'damage': int(st.get('damage') or 0),
        'gained': False,
    }


# ============================================================================
#  跨服 PVP（crossArena）—— 5 个端点
#
#  客户端：canon/features/crossArena/layer/CrossArenaChanllengeLayer.lua
#          canon/features/crossArena/layer/CrossArenaScoreLayer.lua
#          canon/features/crossArena/layer/CrossArenaRewardLayer.lua
#  场景公开信息 getCrossPvpInfo / getCrossPvpRankInfo / getCrossPvpReport
#  已在 handlers_more.py 有实现，本模块只补「点进去会报错」的那 5 个。
# ============================================================================
def _pvp_state(api, pid):
    return _state(api, pid, KEY_CROSS_PVP)


@endpoint('refreshMatch')
def h_refresh_match(api, params):
    """跨服 PVP 刷新对手（params: {type 0免费/1付费钻石}）。

    客户端：CrossArenaChanllengeLayer.lua:194 onRefresh
        successCallback: `self.matchList = e.data.matchList`，
        然后 refreshChanllgeList() 用 `pairs(self.matchList)` 逐条渲染
        list_jj_1..4，每条读 uid / metaId / rank / nickName / server /
        battleScore / combat。

    ⚠️ matchList 必须是数组（客户端先判 `== nil` 决定「刷新按钮灰化」，
    再用 pairs 遍历；给 nil 会走「未开启」分支，给非数组会崩下标）。
    单服没有跨服对手 => 空数组，按钮会自然灰掉而不是崩。
    """
    pid = _pid(api)
    refresh_type = _int_param(api, params, 'type', 0)
    n = _bump_daily(api, pid, CK_PVP_REFRESH)
    st = _pvp_state(api, pid)
    # 免费刷新（type==0）成功后记下本次刷新时刻，作为下一次「免费倒计时」起点；
    # 付费刷新不动它。客户端 refreshRefreshButton 用 now - ts >= 600 秒判免费。
    if refresh_type == 0:
        st['freeRefreshTimestamp'] = int(time.time())
    _save_state(api, pid, KEY_CROSS_PVP, st)
    # 单服没有跨服对手：matchList 保持空数组，客户端把刷新按钮置灰而不是崩
    return {
        'matchList': [],
        'matchNum': 0,
        'refreshType': refresh_type,
        'refreshTimes': n,
        'freeRefreshTimestamp': int(st.get('freeRefreshTimestamp') or 0),
        'cost': 0,
    }


@endpoint('challengeCrossUser')
def h_challenge_cross_user(api, params):
    """跨服 PVP 挑战某个对手（params: {index 0..3，对应 matchList 下标}）。

    客户端：CrossArenaChanllengeLayer.lua:142 onTouchBtn
        param = {index = i - 1}
        successCallback -> replaceScene(BattleScene:create(e.data, kCrossPVP))
        战斗结果走 BattleResultPanel:show(CROSS_PVP_WIN/CROSS_PVP_LOSE)，
        读 data.leftHpRate（BattleResultPanel.lua:594）。

    单服没有跨服天梯 => matchList 为空，不存在第 index 个对手。
    但直接报错会让「点了挑战」这条主链路断掉，所以这里仍然回一场**真算的**
    战斗（玩家真实阵容 vs 参照怪物组），只是不改任何跨服积分/名次
    （跨服天梯的分数由跨服服集群维护，本服无权改）。
    """
    pid = _pid(api)
    battles = _battle_pack(api, pid, 100101, 1)
    times = _bump_daily(api, pid, CK_PVP_CHALLENGE)
    battles.update({
        'index': _int_param(api, params, 'index', 0),
        'whetherWin': bool(battles.get('win')),
        'challengeTimes': times,
        # 跨服天梯积分/名次：单服无跨服榜单，保持 0 而不是编一个增量
        'battleScore': 0,
        'addScore': 0,
        'rank': 0,
        'myRank': 0,
        'reward': {'itemType': G.RE_GEMS, 'metaId': 0, 'amount': 0},
        'rewards': [],
    })
    return OK, battles


@endpoint('buyCrossPvpChallengeTime')
def h_buy_cross_pvp_challenge_time(api, params):
    """跨服 PVP 买挑战次数。

    客户端：CrossArenaChanllengeLayer.lua:179 onBuyTimes
        successCallback 里立刻本地扣钻石
        （RewardManager:getReward({itemType=GEMS, amount=-self.buyCost})），
        然后 crossPvpBuyTimes += 1。

    => 钻石已经由客户端扣过了，服务端再 spend_gems 就是双重扣除；
       而且单价（crossArenaSettingConfig.goldBattleCosts）只有客户端配置有，
       服务端拿不到权威价格。所以服务端只做权威的**每日购买次数记账**
       并把 cost 原样带回，客户端用它显示/扣除。
    """
    pid = _pid(api)
    n = _bump_daily(api, pid, CK_PVP_BUY)
    return {
        'buyTimes': n,
        'crossPvpBuyTimes': n,
        'challengeTime': n,
        'cost': 0,
        'succ': True,
        'rewards': [],
    }


@endpoint('gainCrossPvpBattleReward')
def h_gain_cross_pvp_battle_reward(api, params):
    """跨服 PVP 战斗阶段奖励（params: {type 0=全区礼包 1=排名礼包}）。

    客户端：CrossArenaRewardLayer.lua:17/39
        type 用 CrossArenaConsts.REWARD_TYPE_RANK(1) / REWARD_TYPE_SERVER(0)
        成功后 `RewardManager:getReward(event.data.rewards)` 并
        `RewardReviewPanel:create(scene, {rewardList = event.data.rewards})`

    ⚠️ rewards 必须是数组（getReward 对 nil 容忍，但 RewardReviewPanel
    会拿它当 rewardList 建 TableView，给 nil 要额外兜底）。
    单服没有跨服排名/冠军服 => 没有可领的礼包，返回空数组 + 状态位。
    """
    pid = _pid(api)
    reward_type = _int_param(api, params, 'type', 0)
    return {
        'rewards': [],
        'type': reward_type,
        'canGain': False,
        # 0=不可领 1=可领 2=已领（CrossArenaConsts.REWARD_STATE_*）
        'rankRewardStatus': 0,
        'serverRewardStatus': 0,
        'rank': 0,
        'battleScore': 0,
    }


@endpoint('gainCrossPvpActiveReward')
def h_gain_cross_pvp_active_reward(api, params):
    """跨服 PVP 活跃积分奖励（params: {activeId 1..4}）。

    客户端：CrossArenaScoreLayer.lua:84 onClickList
        activeId = 1..4，门槛 5/10/15/20 分（arrNum = baseFig * i），
        奖励表是 getMeta 下发的 crossArenaRewardConfig.activeRewards[id].rewards。
        成功后客户端把 activeId 记进本地 activeRewards，
        再 `RewardReviewPanel:create(scene, {rewardList = event.data.rewards})`。

    活跃积分来自 getCrossPvpInfo 的 battleInfo.activeScore（战斗期才有）。
    单服没有跨服对局 => 活跃积分恒为 0，1..4 档一个都达不到。
    这里如实返回「无奖励」，并把 activeScore / 门槛一起带回去，
    客户端 refreshListUI 会据此把四个按钮全部置灰（不会崩）。
    """
    pid = _pid(api)
    active_id = _int_param(api, params, 'activeId',
                           _int_param(api, params, 'id', 1)) or 1
    if active_id < 1:
        raise ApiError(E_PARAM)
    st = _pvp_state(api, pid)
    active_score = int(st.get('activeScore') or 0)
    # 客户端 arrNum[i] = 5 * i（CrossArenaScoreLayer.lua:47-49）
    need = 5 * active_id
    can_gain = active_score >= need
    claimed = [int(x) for x in (st.get('activeRewards') or []) if str(x).isdigit()]
    if can_gain and active_id not in claimed:
        claimed.append(active_id)
        st['activeRewards'] = claimed
        _save_state(api, pid, KEY_CROSS_PVP, st)
    return {
        'rewards': [],
        'activeId': active_id,
        'activeScore': active_score,
        'needScore': need,
        'canGain': bool(can_gain),
        'gained': active_id in claimed,
        'activeRewards': claimed,
    }


# ============================================================================
#  跨服比武 / 武道会（AcrossFight）—— 7 个端点
#
#  客户端：
#    canon/request/GetCrossPkInfoRequest.lua -> AcrossFightManager.resetCrossPKInfo
#    canon/manager/AcrossFightManager.lua（全局单例，所有面板都从它取数据）
#    canon/scene/AcrossFightScene.lua、canon/panel/Across*.lua
#
#  resetCrossPKInfo 之后的**必须字段**（AcrossFightManager.lua:128-132）：
#      crossPkGroupInfo.crossPkUserInfos  （getUserInfo 用 pairs 遍历）
#      crossPkGroupInfo.uids              （generateFiguresData 用 uids[i] 判空 break）
#      crossPkGroupInfo.guessRank         （AcrossGuessPanel 取前三名标记）
#      crossPkGroupInfo.crossVersion      （与本地 sharkCrossPkUser.crossVersion 比对）
#
#  ⚠️ 为什么 uids 必须给**空**数组而不是「只有我自己」：
#  generateFiguresData 会按 32 人签表算对手位，若 uids 只有 1 个人，
#  签表里会出现 `{}`（genUserInfo 找不到）但 index 仍然成立的对阵格，
#  AcrossFixturesPanel 里 `aData[1].nickName` 之类就会 setString(nil) 崩。
#  空 uids 会让 generateFiguresData/generateScheduleTableData 在第 1 轮
#  `if not uids[...] then break end` 直接退出，得到 4 个空分组 —— 客户端
#  所有面板都能正常渲染成「暂无对阵」。
# ============================================================================
@endpoint('getCrossPkInfo')
def h_get_cross_pk_info(api, params):
    """跨服比武总信息。本期无参赛者 => 空签表。"""
    pid = _pid(api)
    row = _cross_pk_row(api, pid)
    return {
        'crossPkGroupInfo': {
            'crossVersion': int(row['cross_version'] or 0),
            # getUserInfo 用 pairs 遍历，空数组安全
            'crossPkUserInfos': [],
            # 32 人签表来源；空数组让 generateFiguresData 立刻 break
            'uids': [],
            # 竞猜前三名标记（AcrossFightManager.getGuessRank 直接返回它，
            # AcrossGuessPanel 用它点亮 1/2/3 名小旗）；没开赛即 0
            'guessRank': 0,
            'guessUid': str(int(row['guess_uid'] or 0)),
            'serverIds': [_server_id(api)],
        },
        # 以下为服务端视角的补充状态（客户端不强制读，但便于面板/客服查）
        'myUid': str(int(pid)),
        'gainRankReward': bool(int(row['gain_rank_reward'] or 0)),
        'gainGuessReward': bool(int(row['gain_guess_reward'] or 0)),
        'gainServerReward': bool(int(row['gain_server_reward'] or 0)),
    }


@endpoint('getCrossPkCapacity')
def h_get_cross_pk_capacity(api, params):
    """竞猜候选人的战力列表（按 combat 倒序展示）。

    客户端：AcrossGuessPanel.lua:83 -> GetCrossPkCapacityRequest
        onSucceedDefault: AcrossFightManager.setCapacityList(data.crossPkUserCapacities)
        AcrossGuessSelectPanel 每条读 aData.uid / aData.capacity，
        昵称再用 uid 去 crossPkUserInfos 里查（AcrossFightManager.getGuessUsername）。

    ⚠️ 每条必须有 uid + capacity；且 uid 必须能在 crossPkUserInfos 里找到，
    否则昵称列是 nil（setNodeText(nil) 会崩）。
    单服没有参赛者 => 空数组（列表 0 行，不崩）。
    """
    pid = _pid(api)
    row = _cross_pk_row(api, pid)
    return {
        'crossPkUserCapacities': [],
        'capacityNum': 0,
        'myCapacity': int(_player(api)['fight_capacity'] or 0),
        'crossVersion': int(row['cross_version'] or 0),
    }


@endpoint('getCrossPkReport')
def h_get_cross_pk_report(api, params):
    """看某一轮对阵的战报回放（params: {reportId 实际传的是对手 uid}）。

    客户端：AcrossFixturesPanel.lua:395 reviewBattle
        GetCrossPkReportRequest.sendRequest(..., {reportId = aUid})
        onSucceed 里客户端会用本地签表数据覆盖 userinfo1/userinfo2/whetherWin，
        然后把**整个回包**喂给 replaceScene(BattleScene:create(..., kAcrossFightReview))。

    ⚠️ 所以 cardInitDatas / eventFlow 必须给（BattleScene 没有「无战斗数据」的
    kAcrossFightReview 分支，`pairs(nil)` 直接崩）。
    单服没有跨服战报，这里用「玩家真实阵容 vs 参照怪物组」跑一场真战斗当回放，
    userinfo1/userinfo2 用双方真实档案（客户端随后会覆盖，给真值只是兜底）。
    """
    pid = _pid(api)
    try:
        rival = _int_param(api, params, 'reportId', 0)
    except ApiError:
        rival = 0
    if rival < 0:
        rival = 0

    pack = _battle_pack(api, pid, 100101, 1)
    info1 = _user_info(api, pid)
    info2 = _user_info(api, rival) if rival > 0 else {}
    pack.update({
        'reportId': rival,
        'userinfo1': info1,
        'userinfo2': info2,
        'whetherWin': bool(pack.get('win')),
        'rewards': [],
    })
    return OK, pack


@endpoint('guessCrossPkRank')
def h_guess_cross_pk_rank(api, params):
    """竞猜本届冠军（params: {guessUid}）。

    客户端：AcrossGuessPanel.lua:114 -> GuessCrossPkRankRequest
        成功回调里根本不读回包，只把 sharkCrossPkUser.guessUid 写成本地选择；
        失败回调会弹错误框（710564 未开放 / 710565 已猜过）。

    服务端仍然把竞猜对象落库（player_cross_pk.guess_uid），
    这样重登后 getCrossPkInfo 能恢复；不做二次扣除（竞猜费用 guessPayGold
    只在客户端配置里，服务端拿不到权威价格）。

    本期没有参赛者 => guessUid 传不上来时（客户端候选列表为空，正常不会走到
    这里）返回 canGuess=False 而不是抛错：抛错只会让客户端弹一个没有意义的
    错误框。重复竞猜同样返回 OK + alreadyGuess=True，保持接口幂等。
    """
    pid = _pid(api)
    try:
        guess_uid = int(api.param(params, 'guessUid',
                                  api.param(params, 'uid', 0)) or 0)
    except (TypeError, ValueError):
        guess_uid = 0

    row = _cross_pk_row(api, pid)
    recorded = int(row['guess_uid'] or 0)
    if recorded > 0:
        return {
            'guessUid': str(recorded),
            'guessRank': 0,
            'canGuess': False,
            'alreadyGuess': True,
            'gained': False,
        }
    if guess_uid <= 0:
        # 本期无参赛者，没有可竞猜的对象
        return {
            'guessUid': '0',
            'guessRank': 0,
            'canGuess': False,
            'alreadyGuess': False,
            'gained': False,
        }
    _cross_pk_patch(api, pid, guess_uid=guess_uid)
    return {
        'guessUid': str(guess_uid),
        'guessRank': 0,
        'canGuess': True,
        'alreadyGuess': False,
        'gained': True,
    }


@endpoint('gainCrossPkRankReward')
def h_gain_cross_pk_rank_reward(api, params):
    """领取跨服比武「排名奖励」（32 强名次奖）。

    客户端：AcrossRewardPanel.lua:111
        `RewardManager:getReward(event.data.rewards)` +
        `GetRewardInfoPanel:create(container, event.data.rewards)`，
        随后 AcrossFightManager.gainRankRewardSucceed() 打本地已领标记。

    ⚠️ rewards 必须是数组：GetRewardInfoPanel 拿它当奖励列表渲染。
    本期无参赛者 => 玩家不在 32 强签表里（whetherHasRankReward 走 uids 比对，
    空签表恒为 false），没有可领奖励，reward 数组为空。
    """
    pid = _pid(api)
    row = _cross_pk_row(api, pid)
    return {
        'rewards': [],
        'rankRewardStatus': 0,      # 0 不可领 1 可领 2 已领
        'gained': bool(int(row['gain_rank_reward'] or 0)),
        'rank': 0,
        'inRank': False,
    }


@endpoint('gainCrossPkGuessReward')
def h_gain_cross_pk_guess_reward(api, params):
    """领取跨服比武「竞猜奖励」（猜中冠军）。

    客户端：AcrossRewardPanel.lua:136，同样读 event.data.rewards。
    本期没开赛 => 没有冠军可猜中（whetherHasGuessReward 要求 guessUid≠0 且
    处于领奖期），没有可领奖励。
    """
    pid = _pid(api)
    row = _cross_pk_row(api, pid)
    return {
        'rewards': [],
        'guessRewardStatus': 0,
        'gained': bool(int(row['gain_guess_reward'] or 0)),
        'guessUid': str(int(row['guess_uid'] or 0)),
        'guessRank': 0,
    }


@endpoint('gainCrossPkServerReward')
def h_gain_cross_pk_server_reward(api, params):
    """领取跨服比武「全服/冠军服奖励」。

    客户端：AcrossRewardPanel.lua:161，读 event.data.rewards。
    客户端的判定（AcrossFightManager.whetherHasServerReward）是：
      领奖期 + uids[66]（冠军）存在 + 冠军 uid 末 4 位 == 我的服务器号。
    uids 为空 => uids[66] 为 nil => 恒不可领。

    本地配置 cross_server_reward（rank 1/2/3/4/8/16/32 -> rewardPackageId）
    是「跨服排名 -> 奖励包」表；单服没有跨服排名，所以不去猜一个名次发奖。
    """
    pid = _pid(api)
    row = _cross_pk_row(api, pid)
    return {
        'rewards': [],
        'serverRewardStatus': 0,
        'gained': bool(int(row['gain_server_reward'] or 0)),
        'serverId': _server_id(api),
        'championServerId': 0,
        'isChampionServer': False,
    }


# ============================================================================
#  跨服扭蛋「小玉嫁到」排行 + 神秘奖励 —— 1 个端点
# ============================================================================
@endpoint('gainCrossGachaRankAndMysteriousReward')
def h_gain_cross_gacha_rank_reward(api, params):
    """领取跨服扭蛋排名奖 + 神秘大奖（无参数）。

    客户端：Activity_GachaXiaoyuLayer.lua:266（onGachaOrRankBtnClick）
        onSucceed:
            RewardManager:getReward(event.data.rankRewards)
            RewardManager:getReward(event.data.mysteriousRewards)
            if (#event.data.mysteriousRewards == 0) -> RewardReviewPanel(rankRewards)
            else -> GachaXiaoyuRankRewardPanel:create(container, event.data, onGet)

    ⚠️ rankRewards / mysteriousRewards 两个 key 必须在，且都必须是数组：
       `#event.data.mysteriousRewards` 对 nil 取长度会崩。
    客户端「神秘大奖」的发放条件是「我的服务器 == 第一名所在服务器」，
    榜首来自跨服扭蛋榜（getCrossGachaInfo 的 crossGachaRanks）。
    单服没有跨服榜 => 没有排名、没有神秘大奖，两个数组都为空，
    客户端走 RewardReviewPanel（空奖励列表，不崩）。服务端也不发任何奖励，
    避免出现「榜单上没有我，但我领到了奖」的不一致。
    """
    _pid(api)
    return {
        'rankRewards': [],
        'mysteriousRewards': [],
        'rewards': [],
        'gainedRankReward': False,
        'gainedMysteriousReward': False,
        'rank': 0,
    }
