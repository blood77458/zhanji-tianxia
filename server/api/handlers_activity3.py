#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""活动组 3 —— 6 个 endpoint：买体力/精力、重置关卡次数、每日目标、圣诞挑战、调试推送。

框架会自动发现本文件（`api/__init__.py:load_handlers` 里 pkgutil 扫 `handlers_*.py`），
所以新增处理器不用改任何共享文件。

谁调、什么时候调（依据 work/luasrc 下的解密 Lua）：

    buyEnergy                 EENPSupplyPanel:supplyBtnAction（supplyType=Energy）
                              入口：MainActorPanel「立即恢复体力」、ChapterMapScene 没体力时的
                              补体力弹窗、圣诞/牧场等活动里的补体力弹窗
    buyEventPoint             EENPSupplyPanel:supplyBtnAction（supplyType=EventPoint）
                              入口：MainActorPanel「立即恢复精力」等
    buyMissionCompleteCount   ChapterMapScene:readyToResetMissionCompleteCount /
                              CityMainScene:challangeLimitForMissionId（同一枚「重置次数」按钮）
    getDailyAchieveInfo       DailyTargetScene.gotoDailyTargetScene，
                              AchievementScene / SecretaryScene 的「每日目标」页签
    challengeChrist           MerryChristmasChallengePanel:onListItemTouch（挑战按钮）
    testEvent                 **调试接口，客户端不请求它**（详见函数注释）

⚠️ 关于两个「购买」接口的回包：客户端 onSuccess 回调**完全不读**回包
（`afterBuyEnergy()` / `afterBuyEventPoint()` 没有参数，数值全靠本地
`CalculationManager` + `DailyDataManager` 自己算），所以这里多给的字段只是为了
联调/自测能看出结果，不会影响客户端。
"""
import json
import time

import gamedata as G
import luaconf
import meta_payload
from . import endpoint, ApiError

# ===================================================================== 错误码
# 这些码全部来自客户端自己的错误码表，不要自己编：
#   CommErrorCodes.lua  90/91/92/93   体力满 / 体力购买次数满 / 精力满 / 精力购买次数满
#   ErrorCodeManager.lua 710512 银币不足 / 710513 钻石不足 / 710516 格子不够
E_ENERGY_FULL = 710090              # CommErrorCodes.USER_ENERGY_FULL
E_ENERGY_BOUGHT_FULL = 710091       # CommErrorCodes.USER_ENERGY_BOUGHT_NUM_FULL
E_EVENT_POINT_FULL = 710092         # CommErrorCodes.USER_EVENT_POINT_FULL
E_EVENT_POINT_BOUGHT_FULL = 710093  # CommErrorCodes.USER_EVENT_POINT_BOUGHT_NUM_FULL
E_GEM_NOT_ENOUGH = 710513           # ErrorCodeManager.goldNotEnough（钻石不足）
E_ENERGY_NOT_ENOUGH = 710514        # 体力不足（MerryChristmasChallengePanel 映射它）
E_MISSION_NOT_EXIST = 710401        # 与 services/mission.py 的 E_MISSION_NOT_EXIST 一致
E_REFUSED = 710001                  # 通用「不满足条件」：客户端没有专属文案，走默认弹窗
E_ACTIVITY_UNAVAILABLE = 714651     # 与 handlers_activity_online.py 的约定一致

# ===================================================================== 计数器键
# 走 player_daily_counter（按 stat_date 分桶，跨天天然失效）。
# 键名故意用客户端 sharkDailyData 里的字段名，将来 getHomeInfo 若把这些计数
# 带出给客户端，两边是同一套名字，不会各叫一套。
KEY_ENERGY_BOUGHT = 'energyBoughtNum'
KEY_EVENT_POINT_BOUGHT = 'eventPointBoughtNum'
# 注意：不要复用 'mission_reset_num'。那个键已经被 handlers.py 的 resetClearTime
# （扫荡冷却重置，完全另一件事）在写，共用会让「买次数」的额度被扫荡吃掉。
KEY_MISSION_RESET = 'missionCompleteBuyNum'

# 每日目标（DailyAchieve.achieveType，见 DailyTargetScene.lua:75-77）
ACHIEVE_GACHA = 1     # 至尊求将：抽将次数
ACHIEVE_GOLD_BOX = 2  # 开启金宝箱
ACHIEVE_SPIRIT = 3    # 凝神

DAILY_ACHIEVE_CLAIM_SCOPE = 'daily_achieve'   # 与 gainDailyAchieveReward 的领奖 scope 对齐

_META = None


# ===================================================================== 小工具
def _meta():
    """getMeta 载荷（本组要用 replenish*Config / dailyAchieveConfig / …）。

    缓存一份：meta_payload.get_meta_payload() 每次调用都要重读几个 json 文件，
    不能放在每个请求的热路径上。
    """
    global _META
    if _META is None:
        _META = meta_payload.get_meta_payload()
    return _META


def _cfg(name):
    return _meta().get(name) or {}


def _vip_row(vip_level):
    """vip_setting 的一行。客户端是 `MetaManager.vip_setting[userInfo.vipLevel]` 直接下标。"""
    rows = luaconf.as_list(luaconf.load('vip_setting'))
    for row in rows:
        if int(row.get('level') or 0) == int(vip_level or 0):
            return row
    return rows[0] if rows else {}


def _vip_limit(player, field):
    """VIP 每日次数上限（purchaseStaminaPerDay / purchaseVigourPerDay / extraMissionPerDay）。"""
    return int(_vip_row(G.vip_level_of(player)).get(field) or 0)


def _offer(items, bought):
    """复刻客户端 EENPSupplyPanel:refreshSelf 里那段「第 N 次多少钱」的定价循环：

        for _, v in pairs(items) do
          if bought + 1 <= v.endTimes then cost = v.goldCost; break end
          if v.endTimes == -1        then cost = v.goldCost end
        end

    表由 getMeta 下发（replenishEnergyConfig / replenishEventPointConfig），
    服务端和客户端用**同一张表**，不会出现「界面写 50，扣了 200」。
    返回 (cost, table_amount)；表缺失返回 (None, None)。
    """
    if not items:
        return None, None
    cost = amount = None
    for row in items:
        end_times = int(row.get('endTimes') or 0)
        if int(bought) + 1 <= end_times:
            cost = int(row.get('goldCost') or 0)
            amount = int(row.get('amount') or 0)
            break
        if end_times == -1:
            cost = int(row.get('goldCost') or 0)
            amount = int(row.get('amount') or 0)
    return cost, amount


def _as_rewards(raw):
    """把配置里的「奖励」字段展开成 reward 列表。

    原厂两种约定（见 services/activity.py 顶部注释）：
      * 包 id：值就是 reward_package.id          -> G.reward_from_package
      * 直接表征：{rewardType, rewardID, amount} -> G.reward_from_spec
    这里两种都认，认不出来就当没有奖励（返回 []）。
    """
    if isinstance(raw, (list, tuple)):
        out = []
        for one in raw:
            out += _as_rewards(one)
        return out
    if isinstance(raw, bool) or raw is None:
        return []
    if isinstance(raw, int):
        return G.reward_from_package(int(raw)) if raw else []
    if isinstance(raw, str) and raw.strip().isdigit():
        return G.reward_from_package(int(raw))
    if isinstance(raw, dict):
        pkg_id = int(raw.get('packageId') or raw.get('rewardPackageId') or 0)
        if pkg_id:
            return G.reward_from_package(pkg_id)
        item_type = int(raw.get('rewardType') or raw.get('itemType') or 0)
        if item_type:
            return [G.reward_from_spec(item_type,
                                       int(raw.get('rewardID') or raw.get('metaId') or 0),
                                       int(raw.get('amount') or 1))]
    return []


# ===================================================================== 买体力
@endpoint('buyEnergy')
def h_buy_energy(api, params):
    """买体力（客户端点「立即恢复体力」→ EENPSupplyPanel 的「补满」按钮）。

    客户端做的事（EENPSupplyPanel.lua:88-125）：
      * 价格：replenishEnergyConfig.items 按当日已购次数取档（钻石）
      * 回体力：MetaManager.getEnergyGainedByGem()，且不超过 maxEnergy
      * 失败只认两个码：710090 体力满、710091 今日购买次数满
    所以服务端必须用同一张表、同一个上限、同一组错误码，否则玩家会看到
    「界面说能买」但服务端拒绝（或者反过来扣钱不恢复）。
    """
    p = api.require_player()
    pid = int(p['player_id'])
    cap = api.ctx.player.energy_cap()
    # 只在没满的时候结算恢复：满体力时 regen 只会白写一次时间戳，
    # 而这里（以及下面的拒绝分支）尽量别碰写锁，并发下少一次 database is locked 的机会
    if int(p['energy']) < cap:
        api.ctx.player.regen_all(pid)
        p = api.repos.player.player(pid)
    cur = int(p['energy'])
    if cur >= cap:
        raise ApiError(E_ENERGY_FULL)

    limit = _vip_limit(p, 'purchaseStaminaPerDay')
    today = api.db.today()
    bought = api.repos.player.daily_counter(pid, today, KEY_ENERGY_BOUGHT)
    if limit and bought >= limit:
        raise ApiError(E_ENERGY_BOUGHT_FULL)

    cost, table_amount = _offer(_cfg('replenishEnergyConfig').get('items'), bought)
    if not cost:
        raise ApiError(E_ACTIVITY_UNAVAILABLE)
    # 每次买回多少体力：客户端用 MetaManager.getEnergyGainedByGem()
    # = gameSettingConfig.energyGainedByGem（表里 amount 同值，兜底用）
    per_buy = int(G.game_setting_config().get('energyGainedByGem') or table_amount or 0)

    with api.db.tx():
        # 事务里重新取一次体力再夹上限：并发/spend 期间数值可能已被别的请求改过
        cur = int(api.repos.player.player(pid)['energy'])
        gain = min(per_buy, cap - cur)
        if gain <= 0:
            raise ApiError(E_ENERGY_FULL)
        if api.ctx.player.spend_gems(pid, cost) is None:   # 钻石不足 -> 客户端弹充值面板
            raise ApiError(E_GEM_NOT_ENOUGH)
        energy = api.repos.player.add_currency(pid, 'energy', gain)
        bought = api.repos.player.bump_daily(pid, today, KEY_ENERGY_BOUGHT)

    return {'energy': int(energy), 'energyGained': int(gain), 'costGems': int(cost),
            'boughtNum': int(bought), 'buyLimit': int(limit)}


# ===================================================================== 买精力
@endpoint('buyEventPoint')
def h_buy_event_point(api, params):
    """买精力（客户端「立即恢复精力」按钮）。

    与买体力同构，只是换成精力列 / replenishEventPointConfig /
    eventPointGainedByGem / maxEventPoint，错误码换成 710092 / 710093
    （EENPSupplyPanel.lua:156-186）。
    """
    p = api.require_player()
    pid = int(p['player_id'])
    cap = api.ctx.player.event_point_cap()
    # 同 buyEnergy：满精力时不写库（regen 只会白改一次时间戳）
    if int(p['event_point']) < cap:
        api.ctx.player.regen_all(pid)
        p = api.repos.player.player(pid)
    cur = int(p['event_point'])
    if cur >= cap:
        raise ApiError(E_EVENT_POINT_FULL)

    limit = _vip_limit(p, 'purchaseVigourPerDay')
    today = api.db.today()
    bought = api.repos.player.daily_counter(pid, today, KEY_EVENT_POINT_BOUGHT)
    if limit and bought >= limit:
        raise ApiError(E_EVENT_POINT_BOUGHT_FULL)

    cost, table_amount = _offer(_cfg('replenishEventPointConfig').get('items'), bought)
    if not cost:
        raise ApiError(E_ACTIVITY_UNAVAILABLE)

    per_buy = int(G.game_setting_config().get('eventPointGainedByGem') or table_amount or 0)

    with api.db.tx():
        cur = int(api.repos.player.player(pid)['event_point'])
        gain = min(per_buy, cap - cur)
        if gain <= 0:
            raise ApiError(E_EVENT_POINT_FULL)
        if api.ctx.player.spend_gems(pid, cost) is None:
            raise ApiError(E_GEM_NOT_ENOUGH)
        event_point = api.repos.player.add_currency(pid, 'event_point', gain)
        bought = api.repos.player.bump_daily(pid, today, KEY_EVENT_POINT_BOUGHT)

    return {'eventPoint': int(event_point), 'eventPointGained': int(gain),
            'costGems': int(cost), 'boughtNum': int(bought), 'buyLimit': int(limit)}


# ===================================================================== 重置关卡次数
@endpoint('buyMissionCompleteCount')
def h_buy_mission_complete_count(api, params):
    """买一次「关卡重复挑战次数」（花钻石把某关的当日通关计数清零）。

    客户端链路（ChapterMapScene.lua:2486-2511 / CityMainScene.lua
    `challangeLimitForMissionId`）：
      1. 本地判 `getMissionCurrentBattleTime(id) >= battleWinMax`（battle_mission 表）
         且当日已重置次数 `getResetMissionNum() < vip_setting[vip].extraMissionPerDay`；
      2. 发 `{missionId = xxx}`；
      3. **onSuccess 里读 `event.data.gems`**：
             local aGem = calcComplex_getGemsNow() - event.data.gems
             RewardManager:gainReward({itemType = GEMS, amount = -aGem})
         也就是说 `gems` 必须是「扣钱后的钻石余额」，否则客户端会算错账
         （多扣/少扣都会写坏本地缓存的钻石数，直到下次登录取真值）；
      4. 然后 `CountryManager:resetMissionCompleteInfo(missionId)` 把本地计数清零。
    失败时客户端只处理 710513（钻石不足→弹充值）；服务端没有「次数超上限」的专属码，
    用通用 710001 兜底（客户端走默认错误弹窗，不会崩）。
    """
    p = api.require_player()
    pid = int(p['player_id'])
    mission_id = int(api.param(params, 'missionId', 0) or 0)

    cfg = next((r for r in luaconf.as_list(luaconf.load('battle_mission'))
                if int(r.get('id') or 0) == mission_id), None)
    if cfg is None:
        raise ApiError(E_MISSION_NOT_EXIST)

    cost = int(cfg.get('battleWinPrice') or 0)      # 客户端也是读这个字段当价格
    limit = _vip_limit(p, 'extraMissionPerDay')
    today = api.db.today()
    used = api.repos.player.daily_counter(pid, today, KEY_MISSION_RESET)
    if limit and used >= limit:
        raise ApiError(E_REFUSED)

    with api.db.tx():
        if cost > 0 and api.ctx.player.spend_gems(pid, cost) is None:
            raise ApiError(E_GEM_NOT_ENOUGH)
        # 「买次数」= 把这关的当日通关计数清零（player_mission_complete 是
        # assembler 里 missionCompletes[].missionCompleteCount 的来源）。
        # 没有这一行就什么也不用做：客户端拿到成功后本地也是从 0 开始算。
        api.db.q("UPDATE player_mission_complete SET complete_count=0"
                 " WHERE player_id=? AND mission_id=?", (pid, mission_id))
        used = api.repos.player.bump_daily(pid, today, KEY_MISSION_RESET)
        gems = int(api.repos.player.player(pid)['gem'])

    return {'gems': gems, 'missionId': mission_id, 'costGems': cost,
            'resetNum': int(used), 'resetLimit': int(limit)}


# ===================================================================== 每日目标
def _today_gacha_times(api, pid, today):
    """当日抽将次数（来自 gacha_log，真实记录，不做假）。

    「每日目标」类型 1 的原文（zh_CN activity.strings）是
    `使用金币至尊求将{num1}/{num2}次`。本服 gacha_card 里没有金币节点
    （1=友情点、2/3/4=钻石、5=求将点），所以这里统计**当日全部求将次数**，
    语义上是「今天抽将了几次」，比硬编一个数字更接近原意。
    """
    try:
        row = api.db.one("SELECT COALESCE(SUM(times),0) AS t FROM gacha_log"
                         " WHERE player_id=? AND create_time>=?", (int(pid), int(today)))
    except Exception:                      # 老库没有 gacha_log 就当 0
        return 0
    return int(row['t'] or 0) if row else 0


@endpoint('getDailyAchieveInfo')
def h_daily_achieve_info(api, params):
    """每日目标信息（DailyTargetScene 整页的数据源）。

    客户端（DailyTargetScene.lua:531-563）拿到回包后：
        local targetList = self.argv.params.data.dailyAchieveInfo
        local configData = DailyTargetScene.getTargetConfigById(v.taskId)   -- configList[taskId]
        if v.num >= configData.achieveNum then ... if not v.gain then tipNum+1 end
        -- 列表项还会读 v.complete（排序：可领 > 未完成 > 已领）
    所以 `dailyAchieveInfo` 里每一项**必须**有 `taskId / num / complete / gain`：
      * taskId  → 去 dailyAchieveConfig.dailyAchieve 里取条件与奖励包
                  （客户端是数组下标取值，原厂 achieveId 恰好 1..N 连续，两者一致）
      * num     → 当前进度，决定显示「前往 / 领取」以及角标数
      * complete→ 排序用
      * gain    → 已领取标记，true 时按钮显示「已领取」并置灰
    少任何一个键，DailyTargetScene:setData / sortFunc 就会 index nil → 引擎 kill。

    语义为空的两种类型（真数据不存在，不编）：
      * achieveType 2「开启金宝箱」：本服 getSharkGachaBoxInfo / refreshGachaBox 还是
        空壳，没有开箱记录可统计 → num 恒 0
      * achieveType 3「使用金币凝神」：凝神（spiritConcentrate / destinyBattle）
        仍是 714651，没有产出记录 → num 恒 0
    等对应玩法落地后，在这里挂上真实计数即可（结构不用改）。
    """
    p = api.require_player()
    pid = int(p['player_id'])
    rows = _cfg('dailyAchieveConfig').get('dailyAchieve') or []
    today = api.db.today()

    gacha_times = _today_gacha_times(api, pid, today)
    gained = api.ctx.activity.claims(pid, DAILY_ACHIEVE_CLAIM_SCOPE)

    out = []
    for index, row in enumerate(rows):
        task_id = int(row.get('achieveId') or (index + 1))
        kind = int(row.get('achieveType') or 0)
        need = int(row.get('achieveNum') or 0)
        if kind == ACHIEVE_GACHA:
            num = gacha_times
        else:                                   # ACHIEVE_GOLD_BOX / ACHIEVE_SPIRIT / 未知类型
            num = 0
        out.append({
            'taskId': task_id,
            'num': int(num),
            'complete': bool(need <= 0 or num >= need),
            'gain': bool(task_id in gained),
        })

    return {'dailyAchieveInfo': out}


# ===================================================================== 圣诞挑战
@endpoint('challengeChrist')
def h_challenge_christ(api, params):
    """圣诞活动挑战（MerryChristmasChallengePanel 的「挑战 / 刷新」按钮，这里只管挑战）。

    客户端（MerryChristmasChallengePanel.lua:347-410）在 onSuccess 里读：
        e.data.win       —— 必须；决定是否扣体力、是否 +challengeNum
        e.data.bigReward —— 首次通关的大奖，**给了就会 `bigReward[1].itemType`**，
                            所以只能给非空列表，或者干脆不给（这里是后者）
        e.data.dialogId  —— 首次通关并 win 时客户端自己会覆盖成配置里的 dialogId，
                            之后 BattleScene 用它在战斗结束后放剧情
      然后把**整个回包**丢进 `BattleScene:create(e.data, ...)`，
      也就是必须是一个完整的战斗包（cardInitDatas / eventFlow / leftHpRate / qte …）。

    ⚠️ 现状说明（重要，别当成偷懒）：
    圣诞关卡的**内容表没有恢复**。客户端从 `MetaManager.getMerryChristmasConfig()`
    = `game_meta.activityEventChristmasConfig` 取 `christList`（每关的 chapterId /
    monsterGroupId / regularReward / freeTimes / buyTimes / dialogId）和
    `costPower` / `costMoney` / `specialReward`，而本项目的 getMeta 只下发了
    `{"featureName": "eventNewyear"}`（meta_payload.py 里 `_act("eventNewyear")`），
    work/ 里也找不到任何 christList 残留（连"冬"系卡都不在 card_meta 里），
    所以拿不到 monsterGroupId 就构造不出真实战斗 —— 这正是本接口的硬前提。

    处理方式：配置在，就按配置完整实现（下面这条主路径已经写好，配置一补上就能用）；
    配置不在，就返回 714651（内容未开放），**不伪造战斗包**——假战斗包会让客户端
    `BattleScene` 带着空 cardInitDatas/eventFlow 进战斗，比报错更容易崩。
    """
    p = api.require_player()
    pid = int(p['player_id'])
    christ_id = int(api.param(params, 'christId', 0) or 0)

    cfg = _cfg('activityEventChristmasConfig')
    stages = cfg.get('christList') or []
    stage = next((s for s in stages if int(s.get('id') or 0) == christ_id), None)
    if stage is None:
        raise ApiError(E_ACTIVITY_UNAVAILABLE)

    # ---- 玩家进度：player_christ.data_json 里就是客户端那份 listSharkChristInfo
    state = api.repos.progress.christ(pid)
    try:
        blob = json.loads(state['data_json'] or '{}')
        if not isinstance(blob, dict):
            blob = {}
    except Exception:
        blob = {}
    infos = [r for r in (blob.get('listSharkChristInfo') or []) if isinstance(r, dict)]
    info = next((r for r in infos if int(r.get('christId') or 0) == christ_id), None)
    challenge_num = int((info or {}).get('challengeNum') or 0)
    max_finished = int(state['max_finished_christ_id'] or 0)

    # 客户端按钮状态就是这么判的（panel:212-220）：前一次没通关就打不开下一关
    if christ_id > max_finished + 1:
        raise ApiError(E_ACTIVITY_UNAVAILABLE)
    free_times = int(stage.get('freeTimes') or 0)
    if free_times and challenge_num >= free_times:
        raise ApiError(E_ACTIVITY_UNAVAILABLE)

    cost_power = int(cfg.get('costPower') or 0)
    api.ctx.player.regen_all(pid)
    p = api.repos.player.player(pid)
    if int(p['energy']) < cost_power:                 # 客户端把 710514 映射成「体力不足」
        raise ApiError(E_ENERGY_NOT_ENOUGH)

    # 战斗包：用关卡配置里的怪物组跑一场真实战斗（chapter_battle 与关卡战斗同源）
    try:
        from services.battle import chapter_battle
        pack = chapter_battle(api.db, pid, 0, event_override={
            'monsterGroupId': int(stage['monsterGroupId']),
            'monsterLevel': int(stage.get('monsterLevel') or 1),
            'monsterRevise': float(stage.get('monsterRevise') or 1),
        })
    except (ValueError, KeyError):
        raise ApiError(E_ACTIVITY_UNAVAILABLE)        # 缺怪物组 / 没有出战阵容

    first_clear = christ_id > max_finished
    with api.db.tx():
        if pack.get('win'):
            # ⚠️ 体力只在 win 时扣：客户端 afterChallenge 也是 `if e.data.win then
            #    RewardManager:getReward({ENERGY, -costPower}) end`，服务端多扣会让
            #    客户端本地体力值偏高（要等下次登录才纠正）。handlers_activity_online
            #    里 challengeCowStage 也是这个约定。
            api.repos.player.add_currency(pid, 'energy', -cost_power)
            applied = []
            regular = []
            if int(stage.get('regularReward') or 0):      # 常规掉落（原厂是道具 id）
                regular = [{'itemType': G.RE_PROP,
                            'metaId': int(stage['regularReward']), 'amount': 1}]
            if regular:
                applied, _ = api.ctx.reward.grant(pid, regular, record=True,
                                                  reason='challengeChrist:%d' % christ_id)
            big = _as_rewards(stage.get('bigReward') or cfg.get('bigReward')) \
                if first_clear else []
            big_applied = []
            if big:
                big_applied, _ = api.ctx.reward.grant(pid, big, record=True,
                                                      reason='challengeChristBig:%d' % christ_id)
            pack['rewards'] = applied + big_applied
            if first_clear:
                api.repos.progress.set_max_finished_christ(pid, christ_id)
            # 客户端只在自己 win 时 +challengeNum，这里同步服务端那份
            if info is None:
                info = {'christId': christ_id, 'challengeNum': 0, 'resetNum': 0}
                infos.append(info)
            info['challengeNum'] = challenge_num + 1
            blob['listSharkChristInfo'] = infos
            api.db.q("UPDATE player_christ SET data_json=? WHERE player_id=?",
                     (json.dumps(blob, ensure_ascii=False), pid))
            if big_applied:
                # 只在真发了才给 bigReward：客户端会立刻读 bigReward[1]，空表会炸
                pack['bigReward'] = big_applied
        if stage.get('dialogId'):
            pack['dialogId'] = int(stage['dialogId'])
    return pack


# ===================================================================== 调试推送
@endpoint('testEvent')
def h_test_event(api, params):
    """调试接口。**客户端不会请求它** —— 这是「服务端 → 客户端」的推送通道：

        MainApplication.lua: initCommunicatonSuccess
            Communication:getInstance():registEventHandler("TestEventHandler")
        TestEventHandler.lua:  endpoint = "testEvent"，handle(data) 只做
            he_log_info("testEvent " .. table.serialize(data))

    也就是说客户端注册了一个「收到 name=testEvent 的推送就打印内容」的处理器，
    用来在联调时从服务端塞任意数据看日志。服务端这边只需要一条能通、不报 500
    的 echo：把参数原样（截断）带回去，方便用 scripts/call_endpoint.py 验证链路。
    故意不 require_player：推送通道不该因为会话状态而失败。
    """
    out = {}
    for key, value in (params or {}).items():
        if isinstance(value, (int, float, bool, str)) or value is None:
            out[str(key)] = value
        else:
            out[str(key)] = str(value)[:200]
    return {'echo': out, 'serverTime': int(time.time())}
