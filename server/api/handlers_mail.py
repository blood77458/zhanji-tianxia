#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""邮件 / 领奖组（15 个端点）。

文件定位
--------
这是「补齐包」：**只新增本文件**，不改 `api/__init__.py`、`services/*`、
`repository/*`、`schema.sql`。`api.load_handlers()` 会自动 import 同目录的
`handlers_*.py`，所以这里写的 `@endpoint(...)` 直接生效，不需要注册。

字段依据怎么来的（改字段前请先看这一段）
--------------------------------------
每个 docstring 里的「字段依据」都是按这条链路在 `work/luasrc/` 里查出来的：

    canon/request/XxxRequest.lua    →  endpoint 串 + Succeed 事件名
    grep <事件名>                    →  真正消费数据的面板 onSuccess 回调
    面板回调里读的 event.data.xxx   →  响应必须带的字段

另外 `work/api_analysis/records.json` 里已经抽好了「请求参数 / 响应字段 /
调用点」三件套，用 `python work/api_analysis/contract.py <关键字>` 可以复查。
注意其中 **getLimitReward / getSysEmailMeta 零调用点**（死代码），
这两个接口没有面板消费，字段只能按本地配置和同名字段约定给。

本模块自己建的表（惰性初始化，第一次调用时建，不改 schema.sql）
-------------------------------------------------------------
    player_pending_reward   待领奖励队列（pickUpReward / pickUpAllReward 消费）
    player_invite_device    被邀请设备号去重（gainInvitedReward）

奖励数量说明
-----------
能从 DB / 本地配置算出来的都真算（章节奖励、每日成就、限时档位、新手礼包、
每日达成进度…）。少数活动的奖励数值原厂配置没随包下发（`reference_meta.json`
里就是空表），这类用模块顶部的 `[自编]` 常量并在注释里写明来源缺失，
方便以后拿到真配置时一处替换。
"""
import json
import time

import assembler as A
import gamedata as G

from . import endpoint, ApiError

# ---------------------------------------------------------------- 错误码
# 通用码沿用本工程既有约定（services/activities.py 里同样这几个）。
E_PARAM = 710071        # 参数缺失 / 非法
E_ALREADY = 710001      # 已领取，不能重复领
E_NOT_ENOUGH = 710513   # 条件不足（等级/次数/充值额…）

# 下面这些是客户端**有专门分支**的错误码，必须逐字对上，否则只会弹通用错误框。
#   ChapterFinishRewardPanel:116-123 / CityMainScene:1407-1410
E_CHAPTER_NOT_FINISH = 710407
E_CHAPTER_GAINED = 710408
#   CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED / _NOT_REACH_TIME
E_COUNTDOWN_NO_META = 714180
E_COUNTDOWN_NOT_TIME = 714181
#   Activity_InvitationCodeLayer:235-240  邀请相关
E_INVITE_CODE = 716813          # invitation_errorCode（邀请码不存在/是自己的）
E_INVITE_DEVICE = 716810        # invitation_errorDeviceInvited
E_INVITE_ACCOUNT = 716811       # invitation_errorAccountInvited
#   ConfigScene:283-286  绑定邮箱
E_EMAIL_EMPTY = 710060          # login_wrong_none（邮箱为空/格式非法）
E_EMAIL_WRONG_OLD = 710069      # login_wrong_none（原邮箱不符）
E_EMAIL_BOOKED = 710095         # login_mail_error5（邮箱已被占用）
#   BaseUIScene:1242  周一礼包「活动已结束」
E_MONDAY_CLOSED = 714681
#   Activity_ChargeFeedbackLayer:156  充值返利「活动已结束」
E_CHARGE_FB_CLOSED = 716915
# 另外 710516（背包满）客户端在好几个面板里有专门弹窗（gainDailyAchieveReward、
# gainInviteReward、getChargeFeedbackReward…），但本工程其它发奖接口一律**不**做
# 背包容量拦截，交给客户端 BagCalcManager 自己判（见 handlers_more.py），
# 这里保持一致，不引入 E_BAG_FULL。

# ---------------------------------------------------------------- 领取去重 scope
# player_activity_reward_claim 的 scope 取值。已存在的 scope 见
# assembler.build_activity_snapshot（'new_year' / 'charge_money' / 'limit_reward'…），
# 这里只新增本组自己的，不要去动别人的。
SCOPE_CHAPTER = 'chapter_finish'        # reward_id = chapterId
SCOPE_NEW_YEAR = 'new_year'             # reward_id = 累充档位 id（assembler 已按此读）
SCOPE_CHARGE_FB = 'charge_feedback'     # reward_id = payRewards 档位 id
SCOPE_MONDAY = 'monday_reward'          # reward_id = 当日 stat_date（每天一次）
SCOPE_INVITED = 'invited_reward'        # reward_id = 1（被邀请人只能领一次）
SCOPE_TUTORIAL = 'tutorial_finish'      # reward_id = 1（引导完成奖励只能领一次）

# ---------------------------------------------------------------- [自编] 常量
# 原厂配置没随包下发、或 reference_meta.json 里是空表的奖励，只能自拟。
# 全部集中在这里，将来拿到真配置只改这一处。
#
# 1) 邀请好友奖励：活动面板 Activity_InvitationCodeLayer 只显示「还剩几次可领」，
#    从不读配置，奖励完全由服务端给。定 100 钻/人。
INVITE_REWARD_EACH = {'itemType': G.RE_GEMS, 'amount': 100}
# 2) 被邀请人（填码方）奖励：同上，定 200 钻。
INVITED_REWARD = [{'itemType': G.RE_GEMS, 'amount': 200}]
# 3) 周一礼包（activityOneDay）：客户端只在 MaintenanceManager.isActivityOpen
#    ("activityOneDay") 为真时显示，本地 maintenance 配置里没有这条 feature，
#    所以正常流程暂时看不到这个按钮。数值参考同类日礼包量级。
MONDAY_REWARD = [{'itemType': G.RE_COIN, 'amount': 2000},
                 {'itemType': G.RE_ENERGY, 'amount': 50}]
# 4) 新手引导完成奖励：客户端把 rewards 直接丢给 GetRewardInfoPanel 展示，
#    变量名就叫 Aquire_One_Card（MainMenuScene:1189），所以是一张武将卡。
#    用初始武将（关平，G.STARTER_CARD_META）——card_meta 里一定存在，
#    重复获得可以当强化素材，不会破坏任何客户端逻辑。
TUTORIAL_FINISH_REWARD = [{'itemType': G.RE_CARD,
                           'metaId': G.STARTER_CARD_META,
                           'amount': 1, 'level': 1, 'exp': 0}]

# 邀请人数上限：Activity_InvitationCodeLayer:201 / :289 写死 30。
INVITE_MAX = 30


# ================================================================ 小工具
def _int_param(params, *keys, **kw):
    """按顺序取第一个能转成 int 的参数。

    客户端不同面板对同一个概念键名并不统一（chapterId / id / taskId…），
    所以这里一次给多个候选键。
    """
    default = kw.get('default', 0)
    for k in keys:
        v = (params or {}).get(k)
        if v is None or v == '':
            continue
        try:
            return int(v)
        except (TypeError, ValueError):
            continue
    return default


def _str_param(params, *keys):
    for k in keys:
        v = (params or {}).get(k)
        if v is None:
            continue
        return str(v).strip()
    return ''


# meta_payload.get_meta_payload() 每次都会重建整个 meta 包（要读几十个 lua 配置），
# 单次请求里连调几个接口会很慢，所以按配置名缓存静态活动配置。
# 注意：只缓存静态配置，**不要**缓存玩家相关的东西。
_CFG_CACHE = {}


def _config(name):
    if name not in _CFG_CACHE:
        import meta_payload
        _CFG_CACHE[name] = (meta_payload.get_meta_payload() or {}).get(name) or {}
    return _CFG_CACHE[name]


def _rows(name, key):
    """取活动配置里的一个数组字段，顺手过滤掉非 dict 的脏行。"""
    items = (_config(name) or {}).get(key) or []
    return [r for r in items if isinstance(r, dict)]


# ---- 扩展 JSON（player_extend.extend_json）-------------------------------
# countdownRewardInfo 就存在这里：assembler.build_shark_extend 会把
# extend_json['countdownRewardInfo'] 原样下发给客户端（登录时的新手礼包 UI
# 读的就是它），所以本接口写状态时**必须**写回这里，不能只写自己的表。
def _ext_json(api, pid):
    row = api.repos.player.extend(pid)
    try:
        data = json.loads(row['extend_json'] or '{}')
    except Exception:
        data = {}
    return data if isinstance(data, dict) else {}


def _save_ext_json(api, pid, key, value):
    data = _ext_json(api, pid)
    data[key] = value
    api.repos.player.update_extend(pid, extend_json=data)
    return data


# ---- 惰性建表 -----------------------------------------------------------
_SCHEMA_READY = set()

_PENDING_DDL = """
CREATE TABLE IF NOT EXISTS player_pending_reward (
    player_id   INTEGER NOT NULL,
    reward_id   INTEGER NOT NULL,          -- 客户端 pickUpReward 传的那个 rewardId
    item_type   INTEGER NOT NULL,          -- ResourceEnum
    meta_id     INTEGER NOT NULL DEFAULT 0,
    amount      INTEGER NOT NULL DEFAULT 0,
    level       INTEGER NOT NULL DEFAULT 1,
    exp         INTEGER NOT NULL DEFAULT 0,
    reason      TEXT    NOT NULL DEFAULT '',
    create_time INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id, reward_id)
)
"""

_INVITE_DEVICE_DDL = """
CREATE TABLE IF NOT EXISTS player_invite_device (
    device_id   TEXT    PRIMARY KEY,        -- 客户端 getDeviceId()
    player_id   INTEGER NOT NULL,
    create_time INTEGER NOT NULL DEFAULT 0
)
"""


def _ensure_schema(api):
    """第一次调用时建本模块私有的两张表。

    走 `con.execute` 直接执行（db.con 是 isolation_level=None，自动提交），
    不占用写锁多久；失败也吞掉——建不出来最多是这两个接口不好用，
    不能让整个 RPC 变 500。
    """
    key = '%s#%d' % (getattr(api.db, 'path', '') or '', id(api.db))
    if key in _SCHEMA_READY:
        return
    for ddl in (_PENDING_DDL, _INVITE_DEVICE_DDL):
        try:
            api.db.con.execute(ddl)
        except Exception:
            pass
    try:
        api.db.con.execute("CREATE INDEX IF NOT EXISTS idx_pending_player"
                           " ON player_pending_reward(player_id)")
    except Exception:
        pass
    _SCHEMA_READY.add(key)


def _pending_to_reward(row):
    """player_pending_reward 行 → 客户端 RewardManager 认的 reward 对象。"""
    rw = {'itemType': int(row['item_type']),
          'metaId': int(row['meta_id']),
          'amount': int(row['amount'])}
    if int(rw['itemType']) in (G.RE_CARD, G.RE_EQUIP, G.RE_SPIRIT, G.RE_TREASURE):
        rw['level'] = int(row['level'] or 1)
        rw['exp'] = int(row['exp'] or 0)
    return rw


# ================================================================ 1. 章节通关奖励
_CHAPTERS = None


def _chapters():
    """本地 battle_chapter 配置（141 个章节），id → 行。"""
    global _CHAPTERS
    if _CHAPTERS is None:
        import luaconf
        _CHAPTERS = {}
        for r in luaconf.as_list(luaconf.load('battle_chapter')):
            if isinstance(r, dict) and r.get('id'):
                _CHAPTERS[int(r['id'])] = r
    return _CHAPTERS


def _chapter_missions(row):
    out = []
    for part in str(row.get('missionIdList') or '').split('|'):
        try:
            out.append(int(part))
        except (TypeError, ValueError):
            continue
    return out


@endpoint('gainChapterFinishReward')
def h_gain_chapter_finish_reward(api, params):
    """章节通关奖励。

    客户端调用时机（两处，参数都只有 chapterId）：
      * CityMainScene:1379  gainChapterFinishReward()    —— 章节列表里点「领取」
      * BattleResultPanel:433 → ChapterFinishRewardPanel 打完最后一场的弹窗

    字段依据：
      * 请求：GainChapterFinishRewardRequest.lua:ctor 前 `{chapterId = ...}`
        （CityMainScene:1414）
      * 响应：`reward` —— **必须是数组**。CityMainScene:1386 直接
        `local aReward = event.data.reward[1]` 然后读 aReward.amount /
        itemType / metaId，空数组或非数组都会 Lua 崩。
        ChapterFinishRewardPanel:104 则把整表丢给 RewardManager:getReward。
      * 奖励内容：battle_chapter[id].rewardType / rewardID / rewardNum，
        客户端自己也是用这三个字段画面板的（CountryManager:490-497），
        所以必须一条对一条地用同一份配置，不能自己编。
      * 错误码：710407 未通关/不可领（kCannotGainChapterReward）、
        710408 已领过（kAlreadyGainChapterReward）。

    无 chapterId 时不猜档位，回结构完整的空包（客户端正常流程必带 id）。
    """
    p = api.require_player()
    pid = p['player_id']
    cid = _int_param(params, 'chapterId', 'chapterID', 'chapter_id')
    if not cid:
        return {'chapterId': 0, 'reward': []}

    row = _chapters().get(cid)
    if not row:
        raise ApiError(E_CHAPTER_NOT_FINISH)
    missions = _chapter_missions(row)
    # 通关判定用「已通过的最大关卡 id」——services/mission 推进时写的就是它。
    done = int(api.repos.progress.scene_process(pid)['max_finished_mission_id'] or 0)
    if not missions or done < max(missions):
        raise ApiError(E_CHAPTER_NOT_FINISH)
    if api.ctx.activity.has_claimed(pid, SCOPE_CHAPTER, cid):
        raise ApiError(E_CHAPTER_GAINED)

    rewards = [G.reward_from_spec(row.get('rewardType'), row.get('rewardID'),
                                  row.get('rewardNum'))]
    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, SCOPE_CHAPTER, cid)
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='chapterFinish:%d' % cid)
    return {'chapterId': cid, 'reward': applied}


# ================================================================ 2. 每日成就
def _daily_achieve_rows():
    """dailyAchieveConfig.dailyAchieve —— 本地没有同名 lua 配置，
    但 meta_payload 会用抓包回来的 reference_meta.json 补上，所以能拿到真表：

        [{achieveId, achieveType, achieveNum, achieveReward}, ...]

    客户端是把它当 **1 基数组**用的（DailyTargetScene:586 直接
    `configList[taskId]`），所以 achieveId 与下标是一致的。
    """
    return _rows('dailyAchieveConfig', 'dailyAchieve')


def _achieve_progress(api, pid, achieve_type):
    """当日该类型成就的完成次数。

    能真算的算：抽卡流水 gacha_log 里有 gacha_type 和 times。
      achieveType 1 = 至尊求将   → gacha_type normal / free
      achieveType 2 = 开启金宝箱 → gacha_type box
    算不出来的（3 = 凝神，服务端还没实现该玩法、也没有计数器）回 0，
    这样客户端看到的是「未完成」，点不了领取，不会崩也不会白拿奖励。
    """
    if achieve_type in (1, 2):
        kinds = ('box',) if achieve_type == 2 else ('normal', 'free')
        sql = ("SELECT COALESCE(SUM(times),0) AS n FROM gacha_log"
               " WHERE player_id=? AND create_time>=? AND gacha_type IN (%s)"
               % ','.join('?' * len(kinds)))
        row = api.db.one(sql, (pid, api.db.today()) + kinds)
        return int(row['n']) if row else 0
    return 0


def _achieve_info(api, pid, rows):
    """→ DailyAchieve.xml 的 bean：{taskId, num, complete, gain}。

    客户端 DailyTargetScene:50-59 / :543-552 会拿它排序、算红点，
    四个字段缺一个都会在 ipairs 里读到 nil。
    """
    claimed = api.ctx.activity.claims(pid, _daily_achieve_scope(api))
    out = []
    for i, r in enumerate(rows, 1):
        aid = int(r.get('achieveId') or i)
        need = int(r.get('achieveNum') or 0)
        num = _achieve_progress(api, pid, int(r.get('achieveType') or 0))
        out.append({'taskId': aid, 'num': num,
                    'complete': bool(num >= need), 'gain': aid in claimed})
    return out


def _daily_achieve_scope(api):
    """当日成就的领取去重 scope —— 带日期，跨天自动失效。"""
    return 'daily_achieve:%d' % api.db.today()


@endpoint('gainDailyAchieveReward')
def h_gain_daily_achieve_reward(api, params):
    """每日成就（DailyTargetScene 列表里的「领取」）。

    字段依据：
      * 请求：GainDailyAchieveRequest.lua:39 `{achieveId = achieveId}`
      * 响应：`rewards` —— GainDailyAchieveRequest.onSucceedDefault:69-73
        先 `RewardManager:getReward(event.data.rewards)`，再用同一份
        `event.data.rewards` 建 RewardReviewPanel，所以必须是数组
        （空数组安全：getReward 里 `#rewardData <= 0` 直接 return）。
      * 奖励：dailyAchieveConfig.dailyAchieve[i].achieveReward 是
        reward_package 的包 id（客户端 :425 / :297 也是这么解的），
        用 G.reward_from_package 展开。
      * 错误码：710516 背包满（客户端 :81）、其余弹 defaultError_popupText。

    无 achieveId 时返回当前成就进度（dailyAchieveInfo），不发奖。
    """
    p = api.require_player()
    pid = p['player_id']
    rows = _daily_achieve_rows()
    info = _achieve_info(api, pid, rows)

    aid = _int_param(params, 'achieveId', 'taskId', 'id')
    if not aid:
        return {'rewards': [], 'dailyAchieveInfo': info}

    row = next((r for r in rows if int(r.get('achieveId') or 0) == aid), None)
    if row is None and 1 <= aid <= len(rows):      # 客户端按数组下标取配置
        row = rows[aid - 1]
    if row is None:
        raise ApiError(E_PARAM)

    need = int(row.get('achieveNum') or 0)
    if _achieve_progress(api, pid, int(row.get('achieveType') or 0)) < need:
        raise ApiError(E_NOT_ENOUGH)
    scope = _daily_achieve_scope(api)
    if api.ctx.activity.has_claimed(pid, scope, aid):
        raise ApiError(E_ALREADY)

    rewards = G.reward_from_package(int(row.get('achieveReward') or 0))
    if not rewards:
        raise ApiError(E_PARAM)
    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, scope, aid)
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='dailyAchieve:%d' % aid)
    return {'rewards': applied, 'dailyAchieveInfo': _achieve_info(api, pid, rows)}


# ================================================================ 3. 邀请好友奖励
@endpoint('gainInviteReward')
def h_gain_invite_reward(api, params):
    """我来领「我邀请的人」对应的奖励。**没有请求参数**。

    字段依据：
      * Activity_InvitationCodeLayer:195  `GainInviteRewardRequest.sendRequest(nil, ...)`
      * 响应：`rewards`（:162 `RewardManager:getReward(response.data.rewards)`、
        :166 RewardReviewPanel，必须是数组）。
      * 失败：:182 只认 710516（背包满），其它错误码无提示 —— 所以
        「没有可领的」不要抛错，回空数组 + 两个计数即可，
        客户端本来就把按钮藏了（:201 `invitePlayerNum - gainedInviteRewardNum <= 0`）。
      * 计数来源：player_invite_code.invited_count（invitePlayerNum）与
        gained_invite_reward_num（gainedInviteRewardNum），后者是「已领到第几个」。
        这两个字段客户端 no nil guard 地解引用（:201 / :287），必须一直有值。
    """
    p = api.require_player()
    pid = p['player_id']
    row = api.repos.social.invite_code(pid)      # 没有就顺手建一条
    total = min(int(row['invited_count'] or 0), INVITE_MAX)
    gained = min(int(row['gained_invite_reward_num'] or 0), INVITE_MAX)
    out = {'invitePlayerNum': total, 'gainedInviteRewardNum': gained, 'rewards': []}
    n = total - gained
    if n <= 0:
        return out

    rewards = [{'itemType': INVITE_REWARD_EACH['itemType'],
                'amount': INVITE_REWARD_EACH['amount'] * n}]
    with api.db.tx() as con:
        con.execute("UPDATE player_invite_code SET gained_invite_reward_num=?"
                    " WHERE player_id=?", (total, pid))
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='inviteReward:%d' % n)
    out['rewards'] = applied
    out['gainedInviteRewardNum'] = total
    return out


@endpoint('gainInvitedReward')
def h_gain_invited_reward(api, params):
    """我填别人的邀请码，领「被邀请」奖励。

    字段依据：
      * 请求：Activity_InvitationCodeLayer:258
        `param = {invitationCode = 6位码, deviceId = getDeviceId()}`
      * 响应：`rewards`（:209 RewardManager:getReward、:211 RewardReviewPanel）。
      * 失败码一一对应客户端的三个弹窗（:235-240）：
          716813 invitation_errorCode          邀请码不存在 / 是自己的
          716810 invitation_errorDeviceInvited 该设备已被邀请过
          716811 invitation_errorAccountInvited 该账号已被邀请过
      * 数据：player_invite_code.invited_by 记录「被谁邀请」，
        inviter 的 invited_count 是「被邀请人数」（gainInviteReward 用它）；
        设备去重落在本模块自己的 player_invite_device 表里。

    无 invitationCode 时只回当前绑定状态（客户端自己会先校验 6 位长度）。
    """
    _ensure_schema(api)
    p = api.require_player()
    pid = p['player_id']
    mine = api.repos.social.invite_code(pid)
    out = {'hasInvited': bool(int(mine['invited_by'] or 0)),
           'invitePlayerNum': min(int(mine['invited_count'] or 0), INVITE_MAX),
           'gainedInviteRewardNum': min(
               int(mine['gained_invite_reward_num'] or 0), INVITE_MAX),
           'rewards': []}

    code = _str_param(params, 'invitationCode', 'inviteCode').upper()
    device = _str_param(params, 'deviceId', 'device_id')[:64]
    if not code:
        return out

    inviter = api.db.one("SELECT * FROM player_invite_code WHERE UPPER(invite_code)=?",
                         (code,))
    if inviter is None or int(inviter['player_id']) == pid:
        raise ApiError(E_INVITE_CODE)
    # 「已被邀请过」有两个证据：invited_by 落库，或领奖流水里已经有记录。
    # 两个都查，避免哪天运营后台手工清空 invited_by 之后又能重复领一次。
    if (int(mine['invited_by'] or 0)
            or api.ctx.activity.has_claimed(pid, SCOPE_INVITED, 1)):
        raise ApiError(E_INVITE_ACCOUNT)
    if device:
        used = api.db.one("SELECT 1 FROM player_invite_device WHERE device_id=?"
                          " AND player_id<>?", (device, pid))
        if used:
            raise ApiError(E_INVITE_DEVICE)

    now = int(time.time())
    with api.db.tx() as con:
        con.execute("UPDATE player_invite_code SET invited_by=?, has_invited=1"
                    " WHERE player_id=?", (int(inviter['player_id']), pid))
        con.execute("UPDATE player_invite_code SET invited_count=invited_count+1,"
                    " has_invited=1 WHERE player_id=?",
                    (int(inviter['player_id']),))
        if device:
            con.execute("INSERT INTO player_invite_device(device_id, player_id,"
                        " create_time) VALUES (?,?,?)"
                        " ON CONFLICT(device_id) DO UPDATE SET player_id=excluded.player_id",
                        (device, pid, now))
        api.ctx.activity.mark_claimed(pid, SCOPE_INVITED, 1)
        applied, _ = api.ctx.reward.grant(pid, INVITED_REWARD, record=True,
                                          reason='invitedReward')
    out.update({'rewards': applied, 'hasInvited': True})
    return out


# ================================================================ 4. 周一礼包
@endpoint('gainMondayReward')
def h_gain_monday_reward(api, params):
    """周一大利宝（BaseUIScene 主界面右下角的礼包）。**没有请求参数**。

    字段依据：
      * 请求：BaseUIScene:1250 `GainMondayRewardRequest.sendRequest(nil, ...)`
      * 响应：`rewards`（:1227 RewardManager:getReward、:1234 RewardReviewPanel）
      * 失败：:1240 只认 710516（背包满）与 714681（活动已结束）。
      * 客户端领完自己把 `gameInitData.gainMondayRewardStatus = true`，
        跨天事件再置回 false（:1271），所以服务端的「已领」判定必须**按天**。
      * 领取时间用 player_activity_reward_claim（scope=monday_reward,
        reward_id=当日 stat_date），跨天自动失效。
      * 活动开关：客户端用 MaintenanceManager.isActivityOpen("activityOneDay")
        自己判断要不要显示按钮；服务端如果**配置了**这个 feature 却把它关了，
        就回 714681（客户端有专门提示）。本地 maintenance 配置里没有这条
        feature，所以默认不拦截（否则这个接口永远不可用）。
    """
    p = api.require_player()
    pid = p['player_id']
    feature = G.feature_config('activityOneDay')
    if feature is not None and not feature.get('enable'):
        raise ApiError(E_MONDAY_CLOSED)
    today = api.db.today()
    if api.ctx.activity.has_claimed(pid, SCOPE_MONDAY, today):
        # 已领：回空 rewards 是安全的（RewardReviewPanel 拿到空表不弹任何东西）。
        return {'rewards': [], 'gainTime': 0}
    now = int(time.time())
    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, SCOPE_MONDAY, today)
        applied, _ = api.ctx.reward.grant(pid, MONDAY_REWARD, record=True,
                                          reason='mondayReward')
    return {'rewards': applied, 'gainTime': now}


# ================================================================ 5. 新年 / 累充档位
def _new_year_tiers():
    """累充档位表：{id: {id, requireGold, rewards[]}}。

    优先用 activityNewYearConfig.payRewards（两个面板都是按它画按钮的：
    Activity_NewYearLayer:74、Activity_NewChargeRewardLayer:149 读的是
    `DataManager.GameMetaData.activityNewYearConfig.payRewards[i].id`）。
    但抓包回来的配置里这个字段是空的（reference_meta.json 的
    activityNewYearConfig 就是 {}），所以退回同构的
    `charge_money_reward`（8 档，字段 requireGold + rewards，见 gamedata）。
    """
    out = {}
    for i, r in enumerate(_config('activityNewYearConfig').get('payRewards') or [], 1):
        if not isinstance(r, dict):
            continue
        rid = int(r.get('id') or i)
        rewards = []
        for n in range(1, 6):
            t = int(r.get('rewardType%d' % n) or 0)
            if t:
                rewards.append(G.reward_from_spec(
                    t, r.get('rewardId%d' % n),
                    r.get('rewardNum%d' % n) or r.get('rewardAmount%d' % n)))
        if not rewards and r.get('rewardPackage'):
            rewards = G.reward_from_package(int(r['rewardPackage']))
        if not rewards and isinstance(r.get('reward'), dict):
            rewards = [r['reward']]
        out[rid] = {'id': rid,
                    'requireGold': int(r.get('gold') or r.get('requireGold') or 0),
                    'rewards': rewards}
    if not out:
        for rid, cfg in (G.charge_money_rewards() or {}).items():
            out[int(rid)] = {'id': int(rid),
                             'requireGold': int(cfg.get('requireGold') or 0),
                             'rewards': list(cfg.get('rewards') or [])}
    return out


def _new_year_claimed(api, pid):
    """已领档位。

    `new_year` 是 assembler.build_activity_snapshot 里 nyGainedRewardIds 用的
    scope；`charge_money` 是累充活动（gainChargeMoneyReward）用的。两张表
    共用同一份档位配置（见 _new_year_tiers），所以判断「已领」时两边都要算，
    否则同一档位能从两个入口各领一次。
    """
    return (api.ctx.activity.claims(pid, SCOPE_NEW_YEAR)
            | api.ctx.activity.claims(pid, 'charge_money'))


def _new_year_payload(api, pid):
    tiers = _new_year_tiers()
    claimed = _new_year_claimed(api, pid)
    return [dict(tiers[k], gained=(k in claimed)) for k in sorted(tiers)]


@endpoint('gainNewYearRewards')
def h_gain_new_year_rewards(api, params):
    """新年累充 / 新累充活动领档位奖励。

    字段依据：
      * 请求：{id = 档位 id}（Activity_NewYearLayer:136、:149 都是
        `params = {id = aRewardId}`，aRewardId 来自 payRewards[i].id）
      * 响应：`rewards`（:111 RewardManager:getReward、:120 RewardReviewPanel；
        Activity_NewChargeRewardLayer:125 / :133 同理），必须是数组。
      * 失败：:124 只特判 714420（活动已结束），其它弹 defaultError。
        这里用 710513（累计充值额不足）——会走客户端的通用错误框。
      * 「已领」清单：assembler 把 scope='new_year' 的 reward_id 下发成
        sharkActivity.nyGainedRewardIds，面板拿它画「已领取」，
        所以本接口必须写同一个 scope（见 _new_year_claimed 的说明）。

    无 id 时回档位表（payRewards），不发奖。
    """
    p = api.require_player()
    pid = p['player_id']
    tiers = _new_year_tiers()
    rid = _int_param(params, 'id', 'rewardId', 'stepId')
    if not rid:
        return {'rewards': [], 'payRewards': _new_year_payload(api, pid)}

    tier = tiers.get(rid)
    if tier is None:
        raise ApiError(E_PARAM)
    if int(p['recharge_gems']) < int(tier['requireGold']):
        raise ApiError(E_NOT_ENOUGH)
    if rid in _new_year_claimed(api, pid):
        # 已领：和 gainChargeMoneyReward 一样，回空 rewards（客户端本地也记过）。
        return {'rewards': [], 'payRewards': _new_year_payload(api, pid)}
    if not tier['rewards']:
        raise ApiError(E_PARAM)

    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, SCOPE_NEW_YEAR, rid)
        applied, _ = api.ctx.reward.grant(pid, tier['rewards'], record=True,
                                          reason='newYearCharge:%d' % rid)
    return {'rewards': applied, 'payRewards': _new_year_payload(api, pid)}


# ================================================================ 6. 新手引导完成奖励
@endpoint('gainTutorialFinishReward')
def h_gain_tutorial_finish_reward(api, params):
    """新手引导 10 步走完后的「送你一张武将」。

    字段依据：
      * 请求：MainMenuScene:1198 `GainTutorialFinishRewardRequest.new({}, ...)`
        —— 空参数。
      * 响应：`rewards`（MainMenuScene:1190-1195：先 GetRewardInfoPanel
        展示，再 RewardManager:getReward，必须是数组）。
      * 响应里**故意不下发 limitTime**：GainTutorialFinishRewardRequest:18-26
        一看到 `data.limitTime` 就会 `gameInitData.sharkActivity.flashRecharge.times
        = data.limitTime` 并弹出「限时充值」引导面板；本服限时充值活动没有
        真实档位数据，下发它等于把玩家领进一个空活动。
      * 只领一次：player_activity_reward_claim(scope=tutorial_finish)。
    """
    p = api.require_player()
    pid = p['player_id']
    if api.ctx.activity.has_claimed(pid, SCOPE_TUTORIAL, 1):
        return {'rewards': []}
    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, SCOPE_TUTORIAL, 1)
        applied, _ = api.ctx.reward.grant(pid, TUTORIAL_FINISH_REWARD, record=True,
                                          reason='tutorialFinish')
    return {'rewards': applied}


# ================================================================ 7. 充值返利
@endpoint('getChargeFeedbackReward')
def h_get_charge_feedback_reward(api, params):
    """充值返利活动领奖（Activity_ChargeFeedbackLayer）。

    字段依据：
      * 请求：{rewardId = selectId}，selectId 是 1..8 的**数组下标**
        （Activity_ChargeFeedbackLayer:82-117 就是 `for i=1,8` 配上
        `self.chargeMeta[i]`）。
      * 响应：`rewards`（:144 RewardManager:getReward、:137 RewardReviewPanel）
      * 配置：activityChargeFeedbackConfig.chargeFeedbackList
        （:74 读的就是它；每档字段 gold / enable / rewardType1..5 /
        rewardId1..5 / rewardNum1..5，:99-107 已经给出字段名）。
      * 失败：:154 只认 710516（背包满）与 716915（活动已结束）。

    ⚠️ 抓包回来的 activityChargeFeedbackConfig 是空表（reference_meta.json），
    说明原服这个活动也没配。这时回**结构完整、语义为空**的
    `rewards: []`（客户端拿到空数组只是不弹奖励面板，不会崩），
    而不是抛错误——否则一进活动面板就弹「活动已结束」。
    但如果配置表在、且所有档位都是 enable=false，那就是活动真的关了，
    按客户端分支回 716915。
    """
    p = api.require_player()
    pid = p['player_id']
    rows = _rows('activityChargeFeedbackConfig', 'chargeFeedbackList')
    rid = _int_param(params, 'rewardId', 'id')
    if not rows or not rid:
        return {'rewards': [], 'chargeFeedbackList': rows}
    if not any(r.get('enable') for r in rows):
        raise ApiError(E_CHARGE_FB_CLOSED)

    row = rows[rid - 1] if 1 <= rid <= len(rows) else None
    if row is None:
        row = next((r for r in rows if int(r.get('id') or 0) == rid), None)
    if row is None:
        raise ApiError(E_PARAM)
    if int(p['recharge_gems']) < int(row.get('gold') or 0):
        raise ApiError(E_NOT_ENOUGH)
    if api.ctx.activity.has_claimed(pid, SCOPE_CHARGE_FB, rid):
        raise ApiError(E_ALREADY)

    rewards = []
    for n in range(1, 6):
        t = int(row.get('rewardType%d' % n) or 0)
        if t:
            rewards.append(G.reward_from_spec(t, row.get('rewardId%d' % n),
                                              row.get('rewardNum%d' % n)))
    if not rewards:
        return {'rewards': [], 'chargeFeedbackList': rows}

    with api.db.tx():
        api.ctx.activity.mark_claimed(pid, SCOPE_CHARGE_FB, rid)
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='chargeFeedback:%d' % rid)
    return {'rewards': applied, 'chargeFeedbackList': rows}


# ================================================================ 8. 新手倒计时礼包
def _countdown_rows():
    """countdownRewardConfig.rewards —— 8 档新手礼包。

    每档 {id, countdownTime, rewardPackage}，客户端
    CountDownRewardNewPanel:275-297 用 countdownTime 算冷却、
    MetaManager.reward_package[rewardPackage] 画图标。
    奖励内容用本地 reward_package 配置展开（11001..11008）。
    """
    rows = _rows('countdownRewardConfig', 'rewards')
    rows.sort(key=lambda r: int(r.get('id') or 0))
    return rows


def _countdown_info(api, pid, rows):
    """当前新手礼包状态。

    存在 player_extend.extend_json['countdownRewardInfo']：
    assembler.build_shark_extend 会把它原样下发成
    `sharkUserExtend.countdownRewardInfo`，主界面的礼包 UI 登录时读的就是它
    （BaseUIScene:1073-1083）。所以**必须**写在这里才能让登录后的状态一致。

    `finished` 一定要是 **bool**：客户端写的是 `not countdownRewardInfo.finished`，
    Lua 里 `not 0` 是 false（数字 0 也是「真」），回 int 会让面板永远显示。
    """
    info = _ext_json(api, pid).get('countdownRewardInfo')
    if not isinstance(info, dict):
        info = {}
    last = int(info.get('latestRewardTimestamp') or 0)
    rid = int(info.get('inProcessRewardId') or 0)
    ids = [int(r.get('id') or 0) for r in rows]
    if not rid:
        # inProcessRewardId=0 有两种含义，必须靠 finished 区分：
        #   从没领过（finished 缺失）      → 从第一档开始
        #   8 档全领完了（finished=True）  → 永远 finished，绝不能绕回第一档
        # 早期版本这里直接 idx=0，导致领完之后又能从头再领一遍。
        if info.get('finished'):
            return {'latestRewardTimestamp': last, 'inProcessRewardId': 0,
                    'finished': True}
        idx = 0
    elif rid in ids:
        idx = ids.index(rid)
    else:
        # 配置改过、存的 id 已不存在：当从第一档重新开始
        idx = 0
    if idx >= len(rows):
        return {'latestRewardTimestamp': last, 'inProcessRewardId': 0,
                'finished': True}
    return {'latestRewardTimestamp': last,
            'inProcessRewardId': ids[idx],
            'finished': False}


@endpoint('getCountdownReward')
def h_get_countdown_reward(api, params):
    """领下一档新手礼包（也叫「新手倒计时礼包 / 新手礼包」）。**没有请求参数**。

    字段依据：
      * 请求：CountDownRewardNewPanel:359 `local params = {}`
      * 响应四个字段全都要（:329-345）：
          rewards               RewardManager:getReward(:342) + RewardReviewPanel
                                最外面还有 `RewardManager:getReward(responseData.data.rewards)`(:345)
          latestRewardTimestamp DataManager.setCountdownRewardInfo → 主界面算冷却
          inProcessRewardId     下一档的 id（MetaManager.countdown_reward[rewardId]）
          finished              全部领完后隐藏 UI（必须是 bool，见 _countdown_info）
      * 失败码：714180 没有配置（COUNTDOWN_REWARD_META_NOT_CONFIGED）、
        714181 没到领取时间（COUNTDOWN_REWARD_NOT_REACH_TIME），
        客户端 :352-355 两个弹窗就是这两条。
    """
    p = api.require_player()
    pid = p['player_id']
    rows = _countdown_rows()
    if not rows:
        raise ApiError(E_COUNTDOWN_NO_META)

    info = _countdown_info(api, pid, rows)
    if info['finished']:
        return {'rewards': [], 'latestRewardTimestamp': info['latestRewardTimestamp'],
                'inProcessRewardId': 0, 'finished': True}

    # _countdown_info 已经保证 inProcessRewardId 就是 ids 里的一项（否则会报 finished），
    # 这里再兜一层：真丢了就当从第一档重新开始，不能抛 500。
    ids = [int(r.get('id') or 0) for r in rows]
    idx = ids.index(info['inProcessRewardId']) \
        if info['inProcessRewardId'] in ids else 0
    row = rows[idx]
    now = int(time.time())
    wait = int(row.get('countdownTime') or 0)
    last = int(info['latestRewardTimestamp'] or 0)
    if wait and last and now - last < wait:
        raise ApiError(E_COUNTDOWN_NOT_TIME)

    rewards = G.reward_from_package(int(row.get('rewardPackage') or 0))
    if not rewards:
        rewards = [r for r in (row.get('rewardItems') or []) if isinstance(r, dict)]
    if not rewards:
        raise ApiError(E_COUNTDOWN_NO_META)

    nxt = idx + 1
    new_info = {'latestRewardTimestamp': now,
                'inProcessRewardId': ids[nxt] if nxt < len(rows) else 0,
                'finished': bool(nxt >= len(rows))}
    with api.db.tx():
        _save_ext_json(api, pid, 'countdownRewardInfo', new_info)
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='countdownReward:%d'
                                                 % int(row.get('id') or 0))
    out = {'rewards': applied}
    out.update(new_info)
    return out


# ================================================================ 9. 附灵引导奖励
@endpoint('getEnchantStepReward')
def h_get_enchant_step_reward(api, params):
    """装备附灵（enchant）新手引导完成奖励。**没有请求参数**。

    字段依据：
      * 请求：EnchantGuideRewardPanel:45 `sendRequestDefalut(nil, cb)`
        —— 空参数。
      * 响应：`rewards`（GetEnchantStepRewardRequest:65-71：遍历
        event.data.rewards，给其中的 EQUIP 补 enchantLevel，
        然后 RewardManager:getReward）。所以数组里最好有一个装备。
      * 装备 metaId 用 enchantTotalConfig.equipMetaId —— 这份配置本来
        就下发给了客户端（Enchant 模块读它），保证是「附灵引导」那件装备。
      * 一次性：player_extend.enchant_step_reward 是既有列，
        assembler:163 会把它下发成 sharkUserExtend.enchantStepReward，
        客户端 Enchant 模块据此不再弹引导。
    """
    p = api.require_player()
    pid = p['player_id']
    ext = api.repos.player.extend(pid)
    if int(ext['enchant_step_reward']):
        return {'rewards': [], 'enchantStepReward': True}

    meta_id = int((_config('enchantTotalConfig') or {}).get('equipMetaId') or 0)
    if not meta_id:
        raise ApiError(E_PARAM)
    equip = {'itemType': G.RE_EQUIP, 'metaId': meta_id, 'amount': 1,
             'level': 1, 'exp': 0}
    with api.db.tx():
        api.repos.player.update_extend(pid, enchant_step_reward=1)
        applied, _ = api.ctx.reward.grant(pid, [equip], record=True,
                                          reason='enchantStepReward')
    return {'rewards': applied, 'enchantStepReward': True}


# ================================================================ 10. 限时首充档位
@endpoint('getLimitReward')
def h_get_limit_reward(api, params):
    """限时首充 / 限时累充的档位查询。

    ⚠️ 本包（snzj-online）里这个 endpoint **零调用点**：
       ActiveEnterRechangeRequest.lua 的 endpoint 是 getLimitReward，
       但整个 work/luasrc 里没有任何地方 new 它（records.json 里也没有
       调用点）；客户端真正发的是 ActiveRechangeRequest → gainLimitReward。
       所以这里没有面板契约可依，字段按本地配置 + 同名字段约定给。

    配置来源：activityLimitRewardConfig（meta_payload + 线上活动配置里都有）
        limitRewards: [{stepId, limitTime, rewardDetail, reward}, ...]
        finalReward:  {stepId, reward}
    Activity_rechargeLayer 读的是同一份，字段名逐字照抄：
        getLimitRewardList():712 取 metas.limitRewards；
        循环里读 aLimitRewardConfig.rewardDetail / .limitTime。
    「已领」取自 player_activity_reward_claim(scope=limit_reward)，
    与 gainLimitReward 共用，保证不会重复领。
    """
    p = api.require_player()
    pid = p['player_id']
    cfg = _config('activityLimitRewardConfig') or {}
    claimed = api.ctx.activity.claims(pid, 'limit_reward')
    tiers = []
    for i, r in enumerate(cfg.get('limitRewards') or [], 1):
        if not isinstance(r, dict):
            continue
        sid = int(r.get('stepId') or i)
        tiers.append({'stepId': sid,
                      'rewardDetail': int(r.get('rewardDetail') or 0),
                      'limitTime': int(r.get('limitTime') or 0),
                      'reward': r.get('reward') or {},
                      'gained': sid in claimed})
    final = cfg.get('finalReward')
    return {'featureName': cfg.get('featureName') or 'ActivityLimitReward',
            'limitRewards': tiers,
            'finalReward': final if isinstance(final, dict) else {},
            'rechargeGems': int(p['recharge_gems'])}


# ================================================================ 11. 系统邮件模板
@endpoint('getSysEmailMeta')
def h_get_sys_email_meta(api, params):
    """系统邮件模板表（sysEmailMeta）。

    ⚠️ 本包里 GetSysEmailMetaRequest **零调用点**（只有 getMeta 随大包下发
       的 sysEmailMeta 被 EmailViewPanel 用到），所以这个接口是死代码；
       但字段必须与随包下发的那份**完全一致**，将来客户端真去单拉时才对得上。

    字段来源直接复用 assembler.build_emails 的 sysEmailMeta 分支
    （正是 getUserEmails 里下发的那份）：
        [{id, titleText, contentText, containReward}, ...]
    其中 contentText 缺失会让客户端 gsub(nil) 直接崩，所以不能省。
    """
    p = api.require_player()
    return {'sysEmailMeta': A.build_emails(api.db, p['player_id'])['sysEmailMeta']}


# ================================================================ 12. 绑定/修改邮箱
@endpoint('modifyEmail')
def h_modify_email(api, params):
    """设置界面里的「绑定 / 修改邮箱」（EmailChangeRequest）。

    字段依据：
      * 请求（ConfigScene:293-305）：
          未绑定 → {newEmail}
          已绑定 → {oldEmail, newEmail}
      * 响应：客户端**完全不读**（ConfigScene:262 EmailChangeSuccess 只用本地
        变量），但框架要求回包有实质字段，所以回绑定状态，方便排查。
      * 失败码（ConfigScene:283-286）：
          710060 / 710069 → login_wrong_none（邮箱为空/格式非法、原邮箱不符）
          710095          → login_mail_error5（该邮箱已被占用）

    无 newEmail 时当「查询绑定状态」用，不做任何写入。
    """
    p = api.require_player()
    acc = api.db.one("SELECT * FROM account WHERE account_id=?",
                     (int(p['account_id']),))
    cur = (acc['email'] or '') if acc else ''
    new = _str_param(params, 'newEmail', 'email')
    old = _str_param(params, 'oldEmail')

    if not new:
        return {'email': cur, 'bound': bool(cur)}

    if '@' not in new or len(new) < 5 or len(new) > 128 or ' ' in new:
        raise ApiError(E_EMAIL_EMPTY)
    if cur and old.lower() != cur.lower():
        raise ApiError(E_EMAIL_WRONG_OLD)
    taken = api.db.one("SELECT 1 FROM account WHERE LOWER(email)=? AND account_id<>?",
                       (new.lower(), int(p['account_id'])))
    if taken:
        raise ApiError(E_EMAIL_BOOKED)
    with api.db.tx() as con:
        con.execute("UPDATE account SET email=? WHERE account_id=?",
                    (new, int(p['account_id'])))
    return {'email': new, 'bound': True}


# ================================================================ 13. 待领奖励队列
# getRewardList（handlers.py 里已实现）现在恒回空表：服务端还没有「挂起奖励」
# 这个概念。本模块把队列落成一张真表 player_pending_reward：
# 以后哪个玩法想「先攒着、让玩家去奖励界面逐条领」，只要往这张表插一行
# （顺便让 getRewardList 读它），下面两个接口就自动能用，不用再改。
# 目前没有任何代码往里写，所以两者的语义就是「队列为空」：
# 回的是结构完整、内容为空的数据，客户端不会崩。
@endpoint('pickUpReward')
def h_pick_up_reward(api, params):
    """奖励界面里「单条领取」。

    字段依据：
      * 请求：RewardScene:449 `{rewardId = data[selectedIndex].rewardId}`
      * 响应：`reward` —— RewardScene:452
        `local rewardInfo = evt.data.reward; RewardManager:getReward(rewardInfo)`
        并且 :454 把它丢给 GetRewardInfoPanel，所以它和别的接口一样是
        **reward 的数组**（不是单个对象）。空数组安全：
        getReward 里 `#rewardData <= 0` 直接 return。
    """
    _ensure_schema(api)
    p = api.require_player()
    pid = p['player_id']
    rid = _int_param(params, 'rewardId', 'id')
    if not rid:
        return {'reward': []}
    row = api.db.one("SELECT * FROM player_pending_reward WHERE player_id=?"
                     " AND reward_id=?", (pid, rid))
    if row is None:
        return {'reward': []}
    rw = _pending_to_reward(row)
    with api.db.tx() as con:
        con.execute("DELETE FROM player_pending_reward WHERE player_id=?"
                    " AND reward_id=?", (pid, rid))
        applied, _ = api.ctx.reward.grant(pid, [rw], record=True,
                                          reason='pickUpReward:%d' % rid)
    return {'reward': applied}


@endpoint('pickUpAllReward')
def h_pick_up_all_reward(api, params):
    """奖励界面里「一键领取」。

    字段依据：
      * 请求：RewardScene:723 `{pickUpCard = not(getNoCardReward),
        pickUpEquip = not(getNoEquipReward)}` —— 这两个布尔是**勾选框的
        反向**：玩家勾了「不领卡」时 pickUpCard 才会是 false。
      * 响应：`rewards` —— :670-674 用 pairs/table.insert 逐条塞给
        RewardManager:getReward 和 refreshRewardList。空数组安全。
    """
    _ensure_schema(api)
    p = api.require_player()
    pid = p['player_id']
    # 三个勾选框只有卡（5）和装备（6）两档；其余类型永远领。
    take_card = (params or {}).get('pickUpCard')
    take_equip = (params or {}).get('pickUpEquip')

    chosen = []
    for row in api.db.all("SELECT * FROM player_pending_reward WHERE player_id=?"
                          " ORDER BY reward_id", (pid,)):
        t = int(row['item_type'])
        if t == G.RE_CARD and (take_card is False or take_card == 0):
            continue
        if t == G.RE_EQUIP and (take_equip is False or take_equip == 0):
            continue
        chosen.append(row)
    if not chosen:
        return {'rewards': []}

    rewards = [_pending_to_reward(r) for r in chosen]
    with api.db.tx() as con:
        for r in chosen:
            con.execute("DELETE FROM player_pending_reward WHERE player_id=?"
                        " AND reward_id=?", (pid, int(r['reward_id'])))
        applied, _ = api.ctx.reward.grant(pid, rewards, record=True,
                                          reason='pickUpAllReward')
    return {'rewards': applied}
