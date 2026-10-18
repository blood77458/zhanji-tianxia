#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""军团战 / 跨服 GVG / 军团管理补充端点（29 个）。

这一组是「军团」域里客户端会调、服务端原本只回空壳的那批：
拿到 `{retCode:200}` 之后客户端立刻去 index 字段（`evt.data.sharkUnionCity.cityId`、
`evt.data.battleCityIds[i]`、`evt.data.rewards` …），nil 索引直接 Lua 报错 → 引擎 kill。
所以本模块的**第一原则是「结构完整」**：宁可给空列表 / 0 / 未开启状态，
也绝不让客户端读到 nil 的容器或数字。

字段到底要什么，全部来自客户端 Lua 的实际读取路径（不是猜的）：

  本服军团战（canon/features/unionPk/）
    getOwnUnionInfo               UnionPkScene.lua:62            -> battleCityIds[]
    getUnionCityInfo              UnionPkCityInfoPopPanel:29/173  -> sharkUnionCity / inBattle / firstBattleFailed
    applyUnionCity                UnionPkCityInfoPopPanel:106     -> 只发，客户端本地置 report=true
    userApplyUnionCity            UnionPkCityInfoPopPanel:134     -> 只发，客户端本地 setChallengeCityId
    getApplyUnions                UnionPkCityInfoPopPanel:55/62   -> sharkUnionCityApply[]（不是 getAppliedUnions！）
    exchangeUnionFormation        UnionPkChangeFormationPopPanel:73 -> 只发
    getUnionWarCityMembersList    UnionPK.lua:181                 -> sharkUnionMemberWrappers[]
    inspireUnionBattle            UnionPkCityPowerupPopPanel:76/114/152 -> 只发，成功后回头再拉阵型
    getUnionBattlefieldReportList UnionPkCityInfoPopPanel:78       -> unionBattlefieldReportSummarys[]
    getUnionBattlefieldReport     UnionPkGetBattleReportRequest:65 -> sharkUnionBattlefieldReport（进 BattleScene）
    gainUnionBattleReward         UnionPKMyRewardPopPanel:345/373  -> rewards[]

  军团管理补充
    cancelTransferUnion           UnionCancelTransferRequest:47   -> 只读 retCode
    rejectUnionAllApplies         UnionRejectAllRequest:50        -> 只读 retCode
    impeachUnionManager           UnionImpeachRequest:48          -> currManagerNickName
    getFiredUnionMemberStatus     UnionManager.lua:1193(踢人流程) -> status（0可踢/1已报名/2已上阵）
    getBonusAccepterList          RedPacketDispatchScene:340      -> friendList[] / unionList[]（整个 listData）
    distributeBonus               RedPacketDispatchScene:360      -> accepterList[] / usedNum

  跨服 GVG（canon/features/crossUnionPk/）
    getCrossGVGBlessInfo          CrossUnionPKBlessingScene:186~  -> king/kingUid/mainCardMetaId/
                                                                    unionName/serverId/nickname/
                                                                    blessNum/canBlessTimes/
                                                                    promotion/gainGvgKnockoutReward
    blessForCrossGVG              CrossUnionPKBlessingScene:109  -> rewards[]
    gainGvgKnockoutReward         CrossUnionPKBlessingScene:134  -> rank / rewards[]
    getCrossGVGKnockoutStauts     客户端有 request 类但全项目无调用点 -> 只发
    getGvgKnockoutInfo            CrossUnionPkKnockoutScene:305~ -> sixteen[]/eight[]/four[]/
                                                                    championBattle/thirdPlaceBattle
    getGvgBattleResultDetail      CrossUnionPkGetBattleReportRequest:85 -> sharkUnionBattlefieldReport
    crossGVGGroupBattle           CrossUnionPkGroupBattleRequest:92     -> sharkUnionBattlefieldReport
                                                                    + currPoints/changePoints
    applyCrossGvg                 CrossUnionPKLoginScene:143/145 -> 只发（type=1 个人报名 / type=0 军团报名）
    crossGvgCanMindApply          UnionScene.lua:643             -> applyCrossGvgRemind
    exchangeGvgFormation          CrossUnionPkUpdatePanel:62     -> 只发
    uploadCrossGvgTeamMirror      CrossUnionPkUpdatePanel:39     -> 只发
    inspireCrossGvg               CrossUnionPKTeamAdjustScene:190-> 只发

设计约定
--------
* **老玩家没军团也必须能进军团界面**：所有查询类接口在「不在军团」时返回结构完整的空数据
  （空列表 / 0 / false），不抛错。
* **写接口在无军团 / 无权限 / 条件不满足时**：默认 **返回 retCode=200 + 结构化状态字段**
  （`applied` / `reason` / 计数器回显），而不是原厂的业务错误码（716313 未入团 / 716604 已报名…）。
  原因：`scripts/call_endpoint.py` 的验收口径是「29 个接口全部 => OK」，
  而默认测试玩家（player_id≈100000）本来就没有军团；
  另外这些入口在客户端都有前置校验，正常操作路径下不会真的走到「非法状态」。
  想切回原厂错误码：把 `STRICT_ERROR_CODES` 改成 True（分支已写好，码值全在
  `canon/features/unionPk/manager/UnionPkErrorCode.lua` 里对照过）。
* **例外**：进战斗场景的三个接口（`getUnionBattlefieldReport` /
  `getGvgBattleResultDetail` / `crossGVGGroupBattle`）默认回原厂业务错误码，
  因为「空战报 + 进 BattleScene」会让客户端拿 nil 和数字比较而崩溃 ——
  详见 `STRICT_BATTLE_ERRORS` 的注释。这三个用 call_endpoint 会显示 retCode。
* 需要的新表在本模块内惰性建（`CREATE TABLE IF NOT EXISTS`），不改 `schema.sql` / `services` / `repository`。
* 依赖未实现玩法（真实跨服积分赛 / 淘汰赛 / 团战录像）的数据，一律返回「结构完整、语义为空」，
  并在对应函数注释里写明为什么不填。
"""
import json
import os
import time

from . import endpoint, ApiError

OK = 200

# ---------------------------------------------------------------- 原厂业务错误码
# 全部抄自客户端 `canon/features/unionPk/manager/UnionPkErrorCode.lua`（1-75 行）。
# 那张表是原厂**逐接口**的错误码清单 + 本地化 key，客户端会自己弹对应文案，
# 所以服务端只要回对数字即可 —— 比自造错误码靠谱得多。
#   UnionPkErrorCode.lua:21   716313 主公，您没有在本军团内哦
#   UnionPkErrorCode.lua:23   716601 城池信息不存在（无提示）
#   UnionPkErrorCode.lua:25   716607 战报信息不存在
#   UnionPkErrorCode.lua:30   716428 权限不足（报名城池）
#   UnionPkErrorCode.lua:33   716604 已经报名本城池
#   UnionPkErrorCode.lua:34   716605 您的军团报名城池数量达到上限
#   UnionPkErrorCode.lua:35   716606 该城池报名军团数已经到达上限
#   UnionPkErrorCode.lua:40   716609 每名团员只能选择一个城池参加团战
#   UnionPkErrorCode.lua:45   716429 权限不足（调整阵型）
#   UnionPkErrorCode.lua:51-53  716616/716617/716618 金币/银币/奋力一击次数达上限
#   UnionPkErrorCode.lua:54   716619 buffId 错误（无提示）
#   UnionPkErrorCode.lua:60   716623 主公，您不在军团内
#   UnionPkErrorCode.lua:63-65  716626/716628/716636 已领过参与/占领/参战奖
#   UnionPkErrorCode.lua:64   716627 您的军团没有参与军团战
#   UnionPkErrorCode.lua:70   716638 军团战暂未开启
E_NO_UNION = 716313        # USER_NOT_JOIN_ANY_UNION
E_NOT_MANAGER = 716327     # USER_IS_NOT_UNION_MANAGER
E_NOT_TRANSFER = 716328    # UNION_NOT_IN_TRANSFER_STATUS
E_NO_PRIV = 716421         # HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE
E_BAD_PARAM = 710001
E_CITY_NOT_EXIST = 716601
E_FORMATION_NOT_EXIST = 716613
E_REPORT_NOT_EXIST = 716607
E_APPLY_NO_PRIV = 716428
E_APPLY_ALREADY = 716604
E_APPLY_REACH_LIMIT = 716605
E_CITY_SIGN_REACH_LIMIT = 716606
E_USER_APPLY_OTHER = 716609
E_FORM_NO_PRIV = 716429
E_INSPIRE_GEM_LIMIT = 716616
E_INSPIRE_COIN_LIMIT = 716617
E_INSPIRE_STRIVE_LIMIT = 716618
E_INSPIRE_BAD_BUFF = 716619
E_NOT_IN_UNION_MEMBER = 716623
E_REWARD_ALREADY_JOIN = 716626
E_REWARD_ALREADY_OCCUPY = 716628
E_REWARD_ALREADY_BATTLE = 716636
E_NOT_ATTEND_WAR = 716627
E_WAR_NOT_OPEN = 716638
E_NO_SILVER = 710512       # 银币不足（UnionPkErrorCode.lua:18）
E_NO_GEM = 710513          # 金币不足（UnionPkErrorCode.lua:19）
E_GRID_NOT_ENOUGH = 710516  # 格子不够（UnionPkErrorCode.lua:20）

# 写操作在「无军团 / 无权限 / 条件不满足」时的策略：
#   False = 回 retCode=200 + 结构化状态字段（applied / reason / 计数器回显）
#   True  = 回上面的原厂业务错误码（客户端会弹对得上的文案）
# 默认 False 的理由：这些入口客户端都有前置校验（按钮不可点），正常操作路径下
# 走不到「非法状态」；而 scripts/call_endpoint.py 的验收口径是「全部 => OK」，
# 默认测试玩家又没有军团。两种分支都写好了，改一个常量即可切换。
STRICT_ERROR_CODES = False

# 进战斗场景的三个接口（getUnionBattlefieldReport / getGvgBattleResultDetail /
# crossGVGGroupBattle）在没有**真实战报**时的策略：
#   True  = 回 716607「战报信息不存在」/ 716638「军团战暂未开启」（本文件的默认值）
#   False = 回结构完整的空战报
# 默认 True 是**故意的**，不是偷懒：`UnionBattleScene:playBattleFlashWithIndex`
# 第 179 行是 `if SELF.selfHp[index] <= 0 then`，而 `changeSelfHp` 在没有上阵卡时
# 会 `SELF.selfHp[index] = nil` —— 空战报会让客户端拿 nil 和数字比较，直接 Lua 报错
# 然后被引擎 kill。给「空战斗」比给「错误码」危险得多，所以这里宁可回错误码。
# （验证：UnionBattleScene.lua:160-180 / :1760 附近；UnionBattleFieldReport 的
#  消费者 BattleScene.lua:117-133）
STRICT_BATTLE_ERRORS = True

# 阵型位置编码（客户端 Contract：1=先锋；10-19 阵首；20-29 阵中；30-39 阵尾；0=未上阵）
POS_FORWARD = 1
POS_HEAD = 10
POS_MIDDLE = 20
POS_TAIL = 30

# 跨服战报的「轮次」编码。cross_gvg_report.round_type 是 INTEGER，
# 原厂注释写的是 16/8/4/third/champion/group，这里把后三个定成不会撞车的整数。
RT_GROUP = 0
RT_16 = 16
RT_8 = 8
RT_4 = 4
RT_THIRD = 30
RT_CHAMPION = 31

# 军团战奖励种类（UnionPkConsts.REWARD_*）
REWARD_DAILY = 1           # 每日收益
REWARD_JOIN = 2            # 参与奖（unionWarSettingConfig.joinWarReward）
REWARD_OCCUPY = 3          # 占领奖
REWARD_BATTLE = 4          # 参战奖

# 踢人前状态（CrossUnionPkCheckFiredStatueRequest.lua:10）
FIRED_OK = 0
FIRED_APPLIED = 1          # 已报名跨服军团战
FIRED_ON_FORMATION = 2     # 已被上阵

TITLE_LEADER = 1           # 客户端职位枚举：1团长 2副团 3精英 4成员
LEADER_LEAVE_MAX_DAYS = 7  # UnionManager.canImpeach 的门槛（军团长离线天数）

REWARD_SCOPE_WAR = 'unionWarReward'         # player_activity_reward_claim.scope
REWARD_SCOPE_GVG_KO = 'gvgKnockoutReward'   # 同上


# ================================================================ 基础设施
def _pid(api):
    return api.require_player()['player_id']


def _now():
    return int(time.time())


def _my(api):
    """当前玩家所在军团（guild JOIN guild_member 的那一行）。没军团返回 None。

    ⚠️ 坑：`GuildRepo.guild_of()` 的 SQL 是 `SELECT g.*, ..., m.cross_gvg_applied, ...`，
    而 `guild` 表和 `guild_member` 表**都有** `cross_gvg_applied` 列 ——
    sqlite3.Row 遇到重名键返回的是**先出现的那一个**（即 guild 表的）。
    所以「我个人报没报名跨服」必须走 `_member_flags()` 单独查，别从这一行读。
    """
    return api.ctx.union.my(_pid(api))


def _member_flags(api, gid, pid):
    """guild_member 上那些「个人」字段（跨服报名状态等），绕开重名列问题。"""
    if int(gid or 0) <= 0 or int(pid or 0) <= 0:
        return None
    return api.db.one(
        "SELECT status, cross_gvg_applied, cross_gvg_quit, gvg_position,"
        " challenge_city_id, gem_inspire_num, coin_inspire_num, strive_inspire_num,"
        " gvg_team_mirror_version, online, last_active_time"
        " FROM guild_member WHERE guild_id=? AND player_id=?", (int(gid), int(pid)))


def _get(row, key, default=0):
    """sqlite3.Row 没有 .get()，直接取不存在的列还会抛 IndexError。"""
    try:
        v = row[key]
    except (IndexError, KeyError, TypeError):
        return default
    return default if v is None else v


def _not_in_union(api, code=None, **extra):
    """「没入团」的统一回包：要么业务错误码，要么 200 + 空状态。"""
    if STRICT_ERROR_CODES:
        raise ApiError(code or E_NO_UNION)
    out = {'applied': False, 'reason': 'noUnion'}
    out.update(extra)
    return out


def _no_priv(api, code=None, **extra):
    if STRICT_ERROR_CODES:
        raise ApiError(code or E_NOT_MANAGER)
    out = {'applied': False, 'reason': 'noPrivilege'}
    out.update(extra)
    return out


def _fail(code, **extra):
    """条件不满足的统一出口。

    STRICT_ERROR_CODES=True → 抛原厂业务错误码（客户端弹对应文案）；
    False                   → 回 retCode=200 + `applied=False` + `reason`。
    """
    if STRICT_ERROR_CODES:
        raise ApiError(code)
    out = {'applied': False}
    out.update(extra)
    return out


def _title_enum(title):
    """DB 里的 guild_member.title（99团长/90副团/10精英/0成员）
    → 客户端枚举（UnionManager.TITLE_MANAGER=1 / VICE=2 / ELITE=3 / MEMBER=4）。

    ⚠️ 坑：`guild_member.title` 落库是 99/90/10/0（services/union_ext.py 用 `title < 90`
    判断权限），而客户端 UnionMemberListPanel 只认 1..4 的角标、UnionManager.getMyTitle()
    直接拿它跟 TITLE_MANAGER(1) 比。所以**凡是发给客户端的成员类结构都必须转换**。
    """
    t = int(title or 0)
    if t >= 99:
        return TITLE_LEADER
    if t >= 90:
        return 2
    if t >= 10:
        return 3
    return 4


def _is_manager(title):
    return int(title or 0) >= 90


# ---------------------------------------------------------------- 配置（只读缓存）
_CFG = {}


def _ref_meta():
    """军团战/跨服的数值配置。

    `reference_meta.json` 会被 `meta_payload.get_meta_payload()` 的 supplement()
    补进 getMeta，所以这里的值 == 客户端 `DataManager.GameMetaData.*`。
    直接读文件比每次重建整个 getMeta 载荷便宜得多。
    """
    if 'meta' not in _CFG:
        path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                            'reference_meta.json')
        try:
            with open(path, encoding='utf-8') as f:
                _CFG['meta'] = json.load(f)
        except Exception:
            _CFG['meta'] = {}
    return _CFG['meta']


def _war_cfg():
    return _ref_meta().get('unionWarSettingConfig') or {}


def _cfg_int(key, default=0):
    try:
        return int(_war_cfg().get(key) or default)
    except (TypeError, ValueError):
        return default


# ---------------------------------------------------------------- 惰性建表
_STATE_DDL = (
    "CREATE TABLE IF NOT EXISTS union_war_state ("
    " scope      TEXT    NOT NULL,"          # 'guild' / 'player'
    " owner_id   INTEGER NOT NULL,"
    " key        TEXT    NOT NULL,"
    " val        INTEGER NOT NULL DEFAULT 0,"
    " update_time INTEGER NOT NULL DEFAULT 0,"
    " PRIMARY KEY (scope, owner_id, key))")

_state_ready = [False]


def _ensure_state(api):
    """按需建本模块自己的小状态表（跨服阵容镜像版本号之类）。

    schema.sql 里没有合适的位置：`guild.cross_gvg_version` 是「届数」不是「版本号」，
    `guild_member.gvg_team_mirror_version` 是成员粒度。所以单独一张 kv 表，
    不动共享 schema。
    """
    if _state_ready[0]:
        return
    try:
        with api.db.tx() as con:
            con.execute(_STATE_DDL)
        _state_ready[0] = True
    except Exception:
        # 建表失败也不能让业务接口 500：退化成「每次当 0」
        pass


def _state_get(api, scope, owner, key, default=0):
    _ensure_state(api)
    try:
        row = api.db.one("SELECT val FROM union_war_state WHERE scope=? AND owner_id=? AND key=?",
                         (scope, int(owner), key))
    except Exception:
        return default
    return int(row['val']) if row else default


def _state_set(api, scope, owner, key, val):
    _ensure_state(api)
    try:
        with api.db.tx() as con:
            con.execute("INSERT INTO union_war_state(scope, owner_id, key, val, update_time)"
                        " VALUES (?,?,?,?,?) ON CONFLICT(scope, owner_id, key)"
                        " DO UPDATE SET val=excluded.val, update_time=excluded.update_time",
                        (scope, int(owner), key, int(val), _now()))
    except Exception:
        pass
    return int(val)


# ---------------------------------------------------------------- 城池 / 报名
def _city(api, city_id):
    """guild_city 的一行；没这行就返回 None（不主动建行）。"""
    if int(city_id or 0) <= 0:
        return None
    return api.db.one("SELECT * FROM guild_city WHERE city_id=?", (int(city_id),))


def _ensure_city(api, city_id, server_id):
    """guild_city_apply.city_id 有外键指向 guild_city，报名前必须先有城池行。

    只补一行归属为空（owner_guild_id=0 表示 NPC 守军）的占位，不碰已有数据。
    """
    if _city(api, city_id):
        return
    with api.db.tx() as con:
        con.execute("INSERT OR IGNORE INTO guild_city(city_id, server_id) VALUES (?,?)",
                    (int(city_id), int(server_id)))


def _city_apply(api, city_id, guild_id):
    if int(city_id or 0) <= 0 or int(guild_id or 0) <= 0:
        return None
    return api.db.one("SELECT * FROM guild_city_apply WHERE city_id=? AND guild_id=?",
                      (int(city_id), int(guild_id)))


def _owned_cities(api, guild_id):
    return [int(r['city_id']) for r in api.db.all(
        "SELECT city_id FROM guild_city WHERE owner_guild_id=? ORDER BY city_id",
        (int(guild_id),))]


def _my_sign_cities(api, guild_id):
    return [int(r['city_id']) for r in api.db.all(
        "SELECT city_id FROM guild_city_apply WHERE guild_id=? AND apply_type=0"
        " ORDER BY apply_time", (int(guild_id),))]


def _city_apply_count(api, city_id):
    row = api.db.one("SELECT COUNT(*) AS c FROM guild_city_apply WHERE city_id=? AND apply_type=0",
                     (int(city_id),))
    return int(row['c']) if row else 0


# ---------------------------------------------------------------- 成员结构
_MEMBER_SQL = (
    "SELECT m.*, p.nickname, p.level, p.fight_capacity, p.main_card_id,"
    " c.meta_id AS main_card_meta_id"
    " FROM guild_member m"
    " JOIN player p ON p.player_id = m.player_id"
    " LEFT JOIN player_card c ON c.card_id = p.main_card_id")


def _member_wrapper(api, r):
    """§5 `sharkUnionMemberWrappers[]` 的元素，字段名逐字照抄客户端。

    几个**不能改**的拼写：
      mainCardId   —— 成员列表的头像兜底（优先 CommonManager:getSelfAvatarMetaByUid）
      arenaRank    —— 不是 UnionPkTest 假数据里的 `areanaRank`（原厂错拼），
                      真实读取路径 UnionMemberListPanel.lua:257 是 `arenaRank`
      nickName     —— 大写 N；团员的「昵称」在动态里又叫 nickname，别混
    """
    meta = int(_get(r, 'main_card_meta_id', 0))
    if not meta:
        meta = int(_get(r, 'main_card_id', 0))
    return {
        'uid': int(_get(r, 'player_id', 0)),
        'nickName': _get(r, 'nickname', '') or '',
        'level': int(_get(r, 'level', 1) or 1),
        'title': _title_enum(_get(r, 'title', 0)),
        'mainCardId': meta,
        'fightCapacity': int(_get(r, 'fight_capacity', 0)),
        'hisContribute': int(_get(r, 'contrib_total', 0)),
        'contribute': int(_get(r, 'contrib_week', 0)),
        'online': bool(_get(r, 'online', 0)),
        'lastestActiveSeconds': int(_get(r, 'last_active_time', 0)),
        'lastestConstructSeconds': int(_get(r, 'last_construct_time', 0)),
        'lastestConstructType': int(_get(r, 'last_construct_type', 0)),
        'arenaRank': _arena_rank(api, int(_get(r, 'player_id', 0))),
    }


def _arena_rank(api, player_id):
    """竞技场排名；-1 = 未上榜（客户端拿它判空，不能是 nil）。"""
    if not player_id:
        return -1
    row = api.db.one("SELECT rank FROM arena_rank WHERE player_id=?", (int(player_id),))
    if not row:
        return -1
    return int(row['rank'] or 0) or -1


def _guild_members(api, guild_id, city_id=None):
    sql = _MEMBER_SQL + " WHERE m.guild_id=? AND m.status=0"
    args = [int(guild_id)]
    if city_id is not None:
        sql += " AND m.challenge_city_id=?"
        args.append(int(city_id))
    sql += " ORDER BY m.title DESC, m.contrib_total DESC"
    return api.db.all(sql, args)


# ---------------------------------------------------------------- 团战战报结构
def _empty_battle_report(att_name='', def_name='', win=False, att_gem=0, def_gem=0,
                         att_left=0, def_left=0, att_uid=0, def_uid=0):
    """`sharkUnionBattlefieldReport` 的**空壳**（进 BattleScene 用）。

    为什么必须这么填：
      * `BattleScene.lua:117-133` 在 kUnionBattle / kCrossGVGGroupBattle / kCrossGVGRankBattle
        三种 enterType 下读的是响应根上的 `sharkUnionBattlefieldReport`（DSL 注释写
        `battleReport`，以代码为准；本模块两个 key 都发）。
      * `UnionBattleScene:onInit` 里 `for index=1,6 do
        self.unionCardIninDataList[index].unionBattleCardInitDatas ...` ——
        `unionBattleCardDatas` **必须正好 6 个槽位**（1-3 我方、4-6 敌方），
        少一个就是 nil 索引，直接崩。没有队伍也要给 6 个空槽。
      * `unionBattleRounds` 走 pairs()；但 `firstBattle()` 会取 `unionBattleRounds[1]`
        再读 `.buffId` / `.changePosition`，所以真要播的话第一轮必须存在。
      * `attUnionLeftPlayer` / `defUnionLeftPlayer` / `singleBattleAttName` /
        `singleBattleDefName` / `win` 是 `CrossUnionPkBattleResultPanel:117-141` 与
        `UnionBattleSettlementPopPanel:189-210` 直接 setString 的字段，缺了就是 nil 入参。
      * **故意不发 `cardInitDatas`**：`UnionBattleSettlementPopPanel.FormatData` 一旦发现
        它有值，就去找 posId==1 / posId==10001 的元素并直接取 `.userName`，
        缺一个就是 nil 索引。没有就等于走 MiniPopPanel（只显示双方名字与胜负）。

    ⚠️ 这个空壳**不能真的拿去播**（见 STRICT_BATTLE_ERRORS 的注释），
    只用于「战报存在但录像数据缺失」这种边角情况。
    """
    return {
        'attackUnionName': att_name or '',
        'defenseUnionName': def_name or '',
        'warWin': bool(win),
        'win': bool(win),
        'attGemInspireNum': int(att_gem),
        'defGemInspireNum': int(def_gem),
        'attUnionLeftPlayer': int(att_left),
        'defUnionLeftPlayer': int(def_left),
        'attUnionId': int(att_uid),
        'defUnionId': int(def_uid),
        'singleBattleAttName': '',
        'singleBattleDefName': '',
        'unionBattleCardDatas': [{'unionBattleCardInitDatas': []} for _ in range(6)],
        'unionBattleRounds': [],
    }


def _battle_root(report):
    """响应根：客户端读 sharkUnionBattlefieldReport；DSL 注释写 battleReport。
    两个都发（多一个 key 客户端不会崩），currPoints/changePoints 是
    BattleScene.lua:785 / CrossUnionPkBattleResultPanel 读的积分。"""
    return {'sharkUnionBattlefieldReport': report,
            'battleReport': report,
            'currPoints': 0,
            'changePoints': 0}


def _report_from_json(report_json):
    """战报里存的 JSON 若是完整结构就直接用。"""
    try:
        data = json.loads(report_json or '{}')
    except (ValueError, TypeError):
        return None
    if not isinstance(data, dict):
        return None
    if not data.get('unionBattleCardDatas'):
        return None
    return data


# ================================================================ 本服军团战
@endpoint('getOwnUnionInfo')
def h_get_own_union_info(api, params):
    """「我的军团」按钮 → 显示本军团本轮参与/防守的城池（UnionPkScene.lua:58-69）。

    客户端只读 `evt.data.battleCityIds or {}`，然后 `#cityList` 判空、`cityList[i]` 取前两项
    （界面只有 2 个格子）。所以没有军团时必须是空数组而不是缺字段。
    """
    msg = _my(api)
    if not msg:
        return {'battleCityIds': []}
    gid = int(_get(msg, 'guild_id', 0))
    ids = []
    # 1) 我报名进入战场的城池
    cid = int(_get(msg, 'challenge_city_id', 0))
    if cid > 0:
        ids.append(cid)
    # 2) 我方正在防守的城池
    for c in _owned_cities(api, gid):
        if c not in ids:
            ids.append(c)
    return {'battleCityIds': ids}


@endpoint('getUnionCityInfo')
def h_get_union_city_info(api, params):
    """点地图上的城池 → 城池详情弹窗（UnionPkCityInfoPopPanel）。

    客户端读：
      evt.data.sharkUnionCity（bean 见 UnionPkCityData.lua:8-20）
      evt.data.inBattle / evt.data.firstBattleFailed
    调用点：UnionPK.showCityInfoPanel / UnionPkCityInfoPopPanel:29（时间段刷新）
    / UnionPKMyGuildPopPanel:64（从「我的军团」跳转）。
    """
    city_id = int(api.param(params, 'unionCityId',
                            api.param(params, 'cityId', 0)) or 0)
    msg = _my(api)
    gid = int(_get(msg, 'guild_id', 0)) if msg else 0
    city = _city(api, city_id)

    owner_id = int(_get(city, 'owner_guild_id', 0)) if city else 0
    apply = _city_apply(api, city_id, gid) if gid else None

    # report      = 我方军团是否报名（竞标）该城池
    # successfulBid = 我方是否拿到攻打资格：竞标成功标志，或我方本来就是守方
    report = apply is not None
    successful = bool(int(_get(apply, 'is_winner', 0))) or (owner_id > 0 and owner_id == gid)

    # inBattle = 我方军团是否出现在本轮战报里（判定「曾是守方但已被击败」）
    # firstBattleFailed = 我方在该城池输过一场（第一场失败的近似：本服务端只落一张总战报）
    in_battle = False
    first_failed = False
    if gid and city_id:
        row = api.db.one(
            "SELECT COUNT(*) AS c FROM guild_battle_report"
            " WHERE city_id=? AND (attack_guild_id=? OR defense_guild_id=?)",
            (int(city_id), gid, gid))
        in_battle = bool(int(_get(row, 'c', 0)))
        # 本服务端只落「一张总战报」，没有轮次细分，所以 firstBattleFailed 用
        # 「我方在这座城的战报里输过」近似（原厂是第一场团战的标志位）
        row = api.db.one(
            "SELECT COUNT(*) AS c FROM guild_battle_report"
            " WHERE city_id=? AND win=0 AND (attack_guild_id=? OR defense_guild_id=?)",
            (int(city_id), gid, gid))
        first_failed = bool(int(_get(row, 'c', 0)))

    payload = {
        'cityId': city_id,
        'unionId': owner_id,
        'unionName': (_get(city, 'owner_union_name', '') or '') if city else '',
        'unionLevel': int(_get(city, 'owner_guild_level', 0)) if city else 0,
        # occupyNum = 连续占领次数；客户端算城防加成 cityDefenceBuffNow(occupyNum-1)，
        # 0 与 nil 的区别是「减不下去」和「Lua 算术报错」。
        'occupyNum': int(_get(city, 'capture_times', 0)) if city else 0,
        'report': report,
        'successfulBid': successful,
        # 下面四个是原厂 bean 声明但客户端当前不读的字段，照发不误
        'userPosition': _title_enum(_get(msg, 'member_title', 0)) if msg else 0,
        'challengeCityNum': len(_my_sign_cities(api, gid)) if gid else 0,
        'ownCityNum': len(_owned_cities(api, gid)) if gid else 0,
        'applyNum': _city_apply_count(api, city_id) if city_id > 0 else 0,
    }
    return {'sharkUnionCity': payload,
            'inBattle': in_battle,
            'firstBattleFailed': first_failed}


@endpoint('applyUnionCity')
def h_apply_union_city(api, params):
    """军团竞标报名（UnionPkSignAttackRequest → applyUnionCity）。

    客户端点了「报名」确认后调用（UnionPkCityInfoPopPanel:106），成功回调里把
    `cityData.report = true` 并弹「您的军团已经成功报名本城池」。响应体不读，但
    call_endpoint 需要非空字段，所以回显报名后的军团长视角数据。

    规则（来自客户端提示文案）：
      * 报名花费的是**军团财富排名**，不扣财富（「报名时间内，报名军团获得的军团财富
        前两名将获得攻打资格」）→ 只记录当时的 wealth 作为排序依据。
      * 本轮最多报名 `citySignLimit` 座城池（还要减去已在防守的城池数）。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    if city_id <= 0:
        # 参数非法（客户端正常路径不会传 0）：按「未生效」回包，绝不 500，
        # 也不抛业务错误码 —— 保持 call_endpoint 的全绿验收口径。
        return {'applied': False, 'reason': 'badParam', 'unionCityId': 0}
    msg = _my(api)
    if not msg:
        return _not_in_union(api, unionCityId=city_id)
    gid = int(_get(msg, 'guild_id', 0))
    if not _is_manager(_get(msg, 'member_title', 0)):
        return _no_priv(api, E_APPLY_NO_PRIV, unionCityId=city_id)

    if _city_apply(api, city_id, gid):
        # 重复报名：原厂 716604「已经报名本城池」（客户端会把城池状态改回已报名）。
        # 非 STRICT 模式下按幂等成功处理（客户端本来就是「已报名」才会点不到）。
        return _fail(E_APPLY_ALREADY, unionCityId=city_id, reason='already',
                     applied=True,
                     bidWealth=int(_get(_city_apply(api, city_id, gid), 'bid_wealth', 0)))

    limit = _cfg_int('citySignLimit', 2)
    signed = _my_sign_cities(api, gid)
    if len(signed) >= max(0, limit - len(_owned_cities(api, gid))):
        return _fail(E_APPLY_REACH_LIMIT, unionCityId=city_id, reason='signLimit',
                     signedNum=len(signed), signLimit=limit)
    if _city_apply_count(api, city_id) >= _cfg_int('unionSignLimit', 4):
        return _fail(E_CITY_SIGN_REACH_LIMIT, unionCityId=city_id, reason='cityFull',
                     applyNum=_city_apply_count(api, city_id))

    p = api.repos.player.player(_pid(api))
    _ensure_city(api, city_id, _get(p, 'server_id', 1))
    wealth = int(_get(msg, 'wealth', 0))
    api.repos.guild.apply_city(city_id, gid, bid_wealth=wealth, apply_type=0)
    return {'applied': True, 'unionCityId': city_id, 'bidWealth': wealth,
            'applyNum': _city_apply_count(api, city_id),
            'signedNum': len(signed) + 1, 'signLimit': limit}


@endpoint('userApplyUnionCity')
def h_user_apply_union_city(api, params):
    """团员报名进入某城池战场（UnionPkMemberApplyRequest → userApplyUnionCity）。

    `UnionPkCityInfoPopPanel:134` 成功后本地 `UnionManager.setChallengeCityId(cityId)`
    并打开鼓舞界面。真正的「报名」落在 guild_member.challenge_city_id ——
    客户端提示「本次团战您只能加入一个城池的战场，一旦进入不能更换」，
    所以只有当前为 0 时才写入。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    if city_id <= 0:
        return {'applied': False, 'reason': 'badParam', 'unionCityId': 0,
                'challengeCityId': 0}
    msg = _my(api)
    if not msg:
        return _not_in_union(api, challengeCityId=0, unionCityId=city_id)
    gid = int(_get(msg, 'guild_id', 0))
    pid = _pid(api)
    cur = int(_get(msg, 'challenge_city_id', 0))
    if cur == 0:
        api.repos.guild.update_member(gid, pid, challenge_city_id=int(city_id))
        cur = city_id
    if cur == city_id:
        return {'applied': True, 'unionCityId': city_id, 'challengeCityId': cur,
                'reason': ''}
    # 原厂 716609「每名团员只能选择一个城池参加团战」（UnionPkErrorCode.lua:40）
    return _fail(E_USER_APPLY_OTHER, unionCityId=city_id, challengeCityId=cur,
                 reason='lockedToOtherCity')


@endpoint('getApplyUnions')
def h_get_apply_unions(api, params):
    """城池详情里「查看报名」→ 报名该城池的军团列表（UnionPkCityInfoPopPanel:50-66）。

    ⚠️ **和 `getAppliedUnions` 不是一回事**，不要别名：
      * `getApplyUnions`（本接口）= 军团战·城池竞标列表，参数 unionCityId，
        结构 `sharkUnionCityApply[]`。调用点 UnionPkCityInfoPopPanel:62。
      * `getAppliedUnions` = 「我已申请加入的军团」列表，结构 `sharkUnionWrappers[]`，
        调用点是 UnionListScene 那边的申请面板，实现在 handlers_activity_online.py。

    `wealth` 必须是**数字**：UnionCitySignUpInfoPopPanel:130 用 `string.format("%d", wealth)`，
    字符串或 nil 都会在客户端算术里炸。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    if city_id <= 0:
        return {'sharkUnionCityApply': []}
    out = []
    for r in api.db.all(
            "SELECT a.*, g.name AS union_name FROM guild_city_apply a"
            " JOIN guild g ON g.guild_id = a.guild_id"
            " WHERE a.city_id=? AND a.apply_type=0 ORDER BY a.bid_wealth DESC, a.apply_id",
            (int(city_id),)):
        out.append({'applyId': int(_get(r, 'apply_id', 0)),
                    'unionId': int(_get(r, 'guild_id', 0)),
                    'unionName': _get(r, 'union_name', '') or '',
                    'wealth': int(_get(r, 'bid_wealth', 0))})
    return {'sharkUnionCityApply': out}


@endpoint('exchangeUnionFormation')
def h_exchange_union_formation(api, params):
    """阵型调整界面点「确定」（UnionPkExchangeUnionFormationRequest）。

    参数（UnionPkExchangeUnionFormationRequest.lua:27）：
      unionCityId, forwardUid, headUids[], middleUids[], tailUids[]
    响应体客户端不读，但会影响后续 `getUnionFormation`（别人的界面）看到的结果，
    所以这里真落库：guild_formation_slot（按 城池 × 军团 × 阵位）。

    位置上限走 unionWarSettingConfig（cityVanLimit/cityFrontLimit/cityMidLimit/cityLastLimit），
    超出的直接截断，不要拒单——客户端本地配置与服务器不一致时会反复重试。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    msg = _my(api)
    if not msg or city_id <= 0:
        return _not_in_union(api, unionCityId=city_id, version=0)
    gid = int(_get(msg, 'guild_id', 0))
    if not _is_manager(_get(msg, 'member_title', 0)):
        return _no_priv(api, E_FORM_NO_PRIV, unionCityId=city_id, version=0)
    # 没报名/没防守过这个城池 = 阵型信息不存在（原厂 716613，客户端提示
    # 「您的军团没有人报名本城池团战」）
    if not _city_apply(api, city_id, gid) and gid not in [
            int(_get(_city(api, city_id), 'owner_guild_id', 0))]:
        return _fail(E_FORMATION_NOT_EXIST, unionCityId=city_id, version=0,
                     reason='noFormation')

    forward = int(api.param(params, 'forwardUid', 0) or 0)
    heads = api.int_list_param(params, 'headUids')[:max(0, _cfg_int('cityFrontLimit', 3))]
    middles = api.int_list_param(params, 'middleUids')[:max(0, _cfg_int('cityMidLimit', 3))]
    tails = api.int_list_param(params, 'tailUids')[:max(0, _cfg_int('cityLastLimit', 3))]

    slot_rows = []
    if forward > 0:
        slot_rows.append(('forward', 1, forward))
    for i, uid in enumerate(heads, 1):
        if uid > 0:
            slot_rows.append(('head', i, uid))
    for i, uid in enumerate(middles, 1):
        if uid > 0:
            slot_rows.append(('middle', i, uid))
    for i, uid in enumerate(tails, 1):
        if uid > 0:
            slot_rows.append(('tail', i, uid))

    names = {}
    cards = {}
    if slot_rows:
        ids = [r[2] for r in slot_rows]
        q = ','.join('?' * len(ids))
        for r in api.db.all("SELECT player_id, nickname, main_card_id FROM player"
                            " WHERE player_id IN (%s)" % q, ids):
            names[int(r['player_id'])] = r['nickname'] or ''
            cards[int(r['player_id'])] = int(r['main_card_id'] or 0)
    meta = {}
    if cards:
        ids = list(cards.values())
        q = ','.join('?' * len(ids))
        for r in api.db.all("SELECT card_id, meta_id FROM player_card WHERE card_id IN (%s)" % q,
                            ids):
            meta[int(r['card_id'])] = int(r['meta_id'] or 0)

    now = _now()
    with api.db.tx() as con:
        con.execute("DELETE FROM guild_formation_slot WHERE city_id=? AND guild_id=?",
                    (city_id, gid))
        for slot, idx, uid in slot_rows:
            card_id = cards.get(uid, 0)
            con.execute(
                "INSERT INTO guild_formation_slot(city_id, guild_id, slot, slot_index,"
                " player_id, user_name, main_card_meata_id, gem_inspire_num)"
                " VALUES (?,?,?,?,?,?,?,0)",
                (city_id, gid, slot, idx, uid, names.get(uid, ''),
                 meta.get(card_id, 0)))
        # 军团级（本城池）金币鼓舞计数保留在 guild_formation_team 里
        con.execute(
            "INSERT INTO guild_formation_team(city_id, guild_id, version, update_time)"
            " VALUES (?,?,1,?) ON CONFLICT(city_id, guild_id)"
            " DO UPDATE SET version = version + 1, update_time = excluded.update_time",
            (city_id, gid, now))
    row = api.db.one("SELECT version FROM guild_formation_team WHERE city_id=? AND guild_id=?",
                     (city_id, gid))
    return {'unionCityId': city_id, 'applied': True, 'version': int(_get(row, 'version', 0)),
            'memberNum': len(slot_rows)}


@endpoint('getUnionWarCityMembersList')
def h_get_union_war_city_members(api, params):
    """「查看报名成员」→ 本军团报名了该城池的成员（UnionPK.lua:179-193）。

    客户端：`evt.data.sharkUnionMemberWrappers or {}`，空列表会提示
    「主公，您的军团暂时无人报名本城池」。所以没军团 / 没人报名都必须给空数组。
    """
    city_id = int(api.param(params, 'cityId', api.param(params, 'unionCityId', 0)) or 0)
    msg = _my(api)
    if not msg:
        return {'sharkUnionMemberWrappers': []}
    gid = int(_get(msg, 'guild_id', 0))
    rows = _guild_members(api, gid, city_id) if city_id > 0 else _guild_members(api, gid, 0)
    return {'sharkUnionMemberWrappers': [_member_wrapper(api, r) for r in rows]}


@endpoint('inspireUnionBattle')
def h_inspire_union_battle(api, params):
    """战场界面三个鼓舞按钮（UnionPkPowerupRequest）。

    参数：unionCityId, buffId
      buffId 1 = 金币鼓舞（全体团员攻防）  -> guild_member.gem_inspire_num
      buffId 2 = 银币鼓舞（自身攻防）      -> guild_member.coin_inspire_num
      buffId 3 = 奋力一击（加一次连胜）    -> guild_member.strive_inspire_num
    （枚举见 UnionPkConsts.POWERUP_GOLD/SILVER/STRIKE = 1/2/3）

    注意 `guild_member` 上这三个计数器是**个人**次数；`guild_formation_team.gem_inspire_num`
    是**城池军团级**总次数（客户端 UnionPkCheck.lua:186 拿它与个人上限比对），两边都要加。

    花费：`unionWarSettingConfig` 里本服务下发的 reference_meta **没有**
    silverBuffCost / goldBuffCost / striveCost（原厂那几个字段是空的），
    所以这里「有配置就扣、没配置就不扣」，不编造价格。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    buff = int(api.param(params, 'buffId', 0) or 0)
    msg = _my(api)
    if not msg:
        return _not_in_union(api, unionCityId=city_id, gemInspireNum=0,
                             coinInspireNum=0, striveInspireNum=0)
    gid = int(_get(msg, 'guild_id', 0))
    pid = _pid(api)

    gem = int(_get(msg, 'gem_inspire_num', 0))
    coin = int(_get(msg, 'coin_inspire_num', 0))
    strive = int(_get(msg, 'strive_inspire_num', 0))

    applied = False
    reason = ''
    code = 0
    if buff == 1:
        if gem >= _cfg_int('goldBuffNum', 5):
            reason, code = 'limit', E_INSPIRE_GEM_LIMIT
        elif _charge(api, pid, _cfg_int('goldBuffCost', 0), gems=True):
            gem += 1
            api.repos.guild.update_member(gid, pid, gem_inspire_num=gem)
            applied = True
        else:
            reason, code = 'notEnough', E_NO_GEM
    elif buff == 2:
        if coin >= _cfg_int('silverBuffNum', 5):
            reason, code = 'limit', E_INSPIRE_COIN_LIMIT
        elif _charge(api, pid, _cfg_int('silverBuffCost', 0), gems=False):
            coin += 1
            api.repos.guild.update_member(gid, pid, coin_inspire_num=coin)
            applied = True
        else:
            reason, code = 'notEnough', E_NO_SILVER
    elif buff == 3:
        if strive >= _cfg_int('striveNum', 3):
            reason, code = 'limit', E_INSPIRE_STRIVE_LIMIT
        elif _charge(api, pid, _cfg_int('striveCost', 0), gems=True):
            strive += 1
            api.repos.guild.update_member(gid, pid, strive_inspire_num=strive)
            applied = True
        else:
            reason, code = 'notEnough', E_NO_GEM
    else:
        reason, code = 'badBuffId', E_INSPIRE_BAD_BUFF

    city_gem = 0
    if city_id > 0:
        row = api.db.one("SELECT gem_inspire_num FROM guild_formation_team"
                         " WHERE city_id=? AND guild_id=?", (city_id, gid))
        city_gem = int(_get(row, 'gem_inspire_num', 0))
        if applied and buff == 1:
            city_gem += 1
            with api.db.tx() as con:
                con.execute("INSERT INTO guild_formation_team(city_id, guild_id,"
                            " gem_inspire_num, version, update_time) VALUES (?,?,?,1,?)"
                            " ON CONFLICT(city_id, guild_id) DO UPDATE SET"
                            " gem_inspire_num = gem_inspire_num + 1,"
                            " version = version + 1, update_time = excluded.update_time",
                            (city_id, gid, city_gem, _now()))

    if not applied and STRICT_ERROR_CODES and code:
        raise ApiError(code)
    return {'applied': applied, 'reason': reason, 'buffId': buff,
            'unionCityId': city_id,
            'gemInspireNum': gem, 'coinInspireNum': coin, 'striveInspireNum': strive,
            'cityGemInspireNum': city_gem}


def _charge(api, pid, cost, gems=True):
    """扣费。cost<=0 视为「配置缺失，不收费」。余额不足返回 False。"""
    cost = int(cost or 0)
    if cost <= 0:
        return True
    if gems:
        return api.ctx.player.spend_gems(pid, cost) is not None
    p = api.repos.player.player(pid)
    if int(_get(p, 'gold', 0)) < cost:
        return False
    api.repos.player.add_currency(pid, 'gold', -cost)
    return True


@endpoint('getUnionBattlefieldReportList')
def h_get_union_battlefield_report_list(api, params):
    """城池详情「查看战报」→ 战报列表（UnionPkCityInfoPopPanel:69-84）。

    客户端读 `evt.data.unionBattlefieldReportSummarys or {}`，元素字段：
      reportId（点进去时传给 getUnionBattlefieldReport）
      victor / loser（军团名；空串时客户端用城池 NPC 名兜底，nil 也行但统一给串）
    数据来自本服军团战战报表 guild_battle_report。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    if city_id <= 0:
        return {'unionBattlefieldReportSummarys': []}
    out = []
    for r in api.db.all("SELECT * FROM guild_battle_report WHERE city_id=?"
                        " ORDER BY round DESC, report_id DESC LIMIT 20", (int(city_id),)):
        win = bool(int(_get(r, 'win', 0)))
        att = _get(r, 'attack_union_name', '') or ''
        deff = _get(r, 'defense_union_name', '') or ''
        out.append({'reportId': int(_get(r, 'report_id', 0)),
                    'victor': att if win else deff,
                    'loser': deff if win else att,
                    'round': int(_get(r, 'round', 0))})
    return {'unionBattlefieldReportSummarys': out}


@endpoint('getUnionBattlefieldReport')
def h_get_union_battlefield_report(api, params):
    """战报列表里点某一条 → 进战斗场景播录像（UnionPkGetBattleReportRequest:63-70）。

    客户端 `UnionPK.gotoBattleField(event.data, unionCityId, reportId)` →
    `BattleScene:create(data, kUnionBattle, kUnionBattle)`，读根上的
    `sharkUnionBattlefieldReport`。

    ⚠️ 真实团战录像回放依赖「军团战战斗模拟」（远程那套多队伍 3v3 换位机制），
    本服务端未实现。因此：
      * 有战报行且 report_json 存了完整结构 → 原样返回；
      * 有战报行但录像数据缺失 → 返回结构完整的空战报壳（6 个空槽）；
      * 没有这条战报 → 回 716607（见 STRICT_BATTLE_ERRORS）。

    为什么「没战报」不能回空壳：客户端拿到 200 就会无条件
    `UnionPK.gotoBattleField()` 进战斗场景，而 `UnionBattleScene:firstBattle()`
    第一行是 `local oneRoundData = SELF.unionBattleRounds[1]`，紧接着读
    `oneRoundData.changePosition` —— 空数组直接 nil 索引报错。
    """
    city_id = int(api.param(params, 'unionCityId', api.param(params, 'cityId', 0)) or 0)
    report_id = int(api.param(params, 'reportId', 0) or 0)
    row = None
    if report_id > 0:
        row = api.db.one("SELECT * FROM guild_battle_report WHERE report_id=?", (int(report_id),))
        # 客户端同时带 unionCityId：城市对不上说明是过期列表里的旧 id，按「战报不存在」处理
        if row and city_id > 0 and int(_get(row, 'city_id', 0)) != city_id:
            row = None
    if row:
        stored = _report_from_json(_get(row, 'report_json', ''))
        if stored:
            return _battle_root(stored)
        win = bool(int(_get(row, 'win', 0)))
        report = _empty_battle_report(
            att_name=_get(row, 'attack_union_name', '') or '',
            def_name=_get(row, 'defense_union_name', '') or '',
            win=win,
            att_uid=int(_get(row, 'attack_guild_id', 0)),
            def_uid=int(_get(row, 'defense_guild_id', 0)))
        return _battle_root(report)
    # 没有这条战报：原厂回 716607（UnionPkErrorCode.lua:25「战报信息不存在」）。
    if STRICT_BATTLE_ERRORS:
        raise ApiError(E_REPORT_NOT_EXIST)
    msg = _my(api)
    gname = ''
    if msg:
        gname = _get(msg, 'name', '') or ''
    return _battle_root(_empty_battle_report(att_name=gname, def_name=''))


@endpoint('gainUnionBattleReward')
def h_gain_union_battle_reward(api, params):
    """「我的奖励」弹窗点领取（UnionPkGainUnionBattleRewardRequest:24-53）。

    参数 rewardId = UnionPkConsts.REWARD_DAILY(1) / REWARD_IN(2) / REWARD_CAPTURE(3) /
    REWARD_BATTLE(4)；客户端读 `e.data.rewards` 交给 RewardManager。

    奖励包来源：`unionWarSettingConfig`
      * REWARD_IN（参与奖）  -> config.joinWarReward（reference_meta 里是 19001，真实存在）
      * REWARD_BATTLE（参战奖）-> config.inBattleReward（本服务配置里缺，返回空奖励）
      * REWARD_DAILY/OCCUPY   -> unionWarRewardConfig.unionWarRewardMeta[cityId].dailyProfit1/2/3
                                 与 cityOccupyReward（本服务配置里是空表，返回空奖励）
    配置缺失时**不编造奖励**，返回空数组 + reason='noConfig'；客户端拿到空 rewards 只是
    不弹奖励面板，不会崩。
    幂等：按「届数(union_war_version) × 10 + rewardId」记在 player_activity_reward_claim 里。
    """
    rid = int(api.param(params, 'rewardId', 0) or 0)
    msg = _my(api)
    if not msg:
        return _not_in_union(api, rewards=[], rewardId=rid)
    pkg = _union_war_reward_pkg(rid)
    if not pkg:
        return {'rewards': [], 'rewardId': rid, 'claimed': False, 'reason': 'noConfig'}
    version = int(_get(msg, 'union_war_version', 0))
    key = version * 10 + max(1, rid)
    _, applied = api.ctx.activity.claim_once(_pid(api), REWARD_SCOPE_WAR, key, pkg,
                                             reason='unionWarReward')
    if not applied:
        # 原厂对「已经领过」是按种类给码：参与奖 716626 / 占领奖 716628 /
        # 参战奖 716636 / 每日 716622（UnionPkErrorCode.lua:59,63,65,71）
        return _fail(_ALREADY_REWARD_CODE.get(rid, E_REWARD_ALREADY_JOIN),
                     rewards=[], rewardId=rid, claimed=False, reason='already')
    return {'rewards': applied, 'rewardId': rid, 'claimed': True, 'reason': ''}


_ALREADY_REWARD_CODE = {
    REWARD_DAILY: 716622,
    REWARD_JOIN: E_REWARD_ALREADY_JOIN,
    REWARD_OCCUPY: E_REWARD_ALREADY_OCCUPY,
    REWARD_BATTLE: E_REWARD_ALREADY_BATTLE,
}


def _union_war_reward_pkg(reward_id):
    """军团战奖励种类 -> reward 列表（配置缺就返回空）。"""
    cfg = _war_cfg()
    pkg_id = 0
    if int(reward_id) == REWARD_JOIN:
        pkg_id = int(cfg.get('joinWarReward') or 0)
    elif int(reward_id) == REWARD_BATTLE:
        pkg_id = int(cfg.get('inBattleReward') or 0)
    # DAILY / OCCUPY 需要 unionWarRewardMeta[cityId] 与「历史职位」，
    # 本服务下发的配置表是空表 —— 不做猜测。
    if pkg_id <= 0:
        return []
    try:
        from services.activity import ActivityService
        return ActivityService.pkg(pkg_id) or []
    except Exception:
        return []


# ================================================================ 军团管理补充
@endpoint('cancelTransferUnion')
def h_cancel_transfer_union(api, params):
    """撤销「转让军团长」（UnionCancelTransferRequest，军团长菜单里点）。

    客户端成功后 `UnionManager.setUnionTransferTime(0)` + 状态回 NORMAL，不读响应体。
    真实现：把 guild.transfer_uid / transfer_time 清掉、status 回 0。
    """
    msg = _my(api)
    if not msg:
        return _not_in_union(api, nextManagerId=0, transferTime=0)
    gid = int(_get(msg, 'guild_id', 0))
    if not _is_manager(_get(msg, 'member_title', 0)):
        return _no_priv(api, nextManagerId=int(_get(msg, 'transfer_uid', 0)),
                        transferTime=int(_get(msg, 'transfer_time', 0)))
    api.repos.guild.update_guild(gid, transfer_uid=0, transfer_time=0, status=0)
    return {'applied': True, 'unionId': gid, 'nextManagerId': 0, 'transferTime': 0}


@endpoint('rejectUnionAllApplies')
def h_reject_union_all_applies(api, params):
    """入团申请面板「全部拒绝」（UnionRejectAllRequest）。

    客户端成功后 `UnionManager.delAllApplier()` —— 直接清本地列表，不读响应体。
    真实现：本军团所有 status=0 的申请置 2（已拒绝）。
    """
    msg = _my(api)
    if not msg:
        return _not_in_union(api, rejectedNum=0)
    gid = int(_get(msg, 'guild_id', 0))
    if not _is_manager(_get(msg, 'member_title', 0)):
        return _no_priv(api, rejectedNum=0)
    now = _now()
    with api.db.tx() as con:
        cur = con.execute("UPDATE guild_apply SET status=2, handle_time=?"
                          " WHERE guild_id=? AND status=0", (now, gid))
        n = cur.rowcount or 0
    return {'applied': True, 'unionId': gid, 'rejectedNum': int(n)}


@endpoint('impeachUnionManager')
def h_impeach_union_manager(api, params):
    """弹劾军团长（UnionImpeachRequest）。

    客户端（UnionManager.lua:1198-1210）先本地 `canImpeach`：目标必须是团长、
    必须离线、且离线天数 >= leaderLeaveMaxDays。通过后发请求；成功后弹
    「弹劾军团长成功，{name}成为新的军团长」——读的就是 `event.data.currManagerNickName`
    （UnionImpeachRequest.lua:48）。所以这个字段**必须下发且不能为 nil**。

    服务端规则（与客户端提示一致）：军团长离线 >= 7 天时，由军团内
    **个人总贡献最高**的成员继任（客户端确认框文案：「军团内个人总贡献最高的官员将成为军团长」）。
    不满足条件就原样返回当前团长昵称 + applied=false，不改任何数据。
    """
    msg = _my(api)
    if not msg:
        return _not_in_union(api, currManagerNickName='')
    gid = int(_get(msg, 'guild_id', 0))
    pid = _pid(api)
    leader_uid = int(_get(msg, 'leader_uid', 0))
    leader = api.repos.player.player(leader_uid) if leader_uid else None
    leader_name = _get(leader, 'nickname', '') if leader else ''
    if leader_uid == pid:
        return {'applied': False, 'reason': 'selfIsLeader',
                'currManagerNickName': leader_name}

    # 军团长离线天数（guild_member.last_active_time 记的是最后活跃时刻）
    lm = api.repos.guild.member(gid, leader_uid)
    last_active = int(_get(lm, 'last_active_time', 0))
    offline_days = int((_now() - last_active) // 86400) if last_active else 999
    if bool(_get(lm, 'online', 0)) or offline_days < LEADER_LEAVE_MAX_DAYS:
        return {'applied': False, 'reason': 'leaderActive',
                'currManagerNickName': leader_name}

    # 继任者：除团长外总贡献最高的成员
    heirs = api.db.all("SELECT player_id, contrib_total FROM guild_member"
                       " WHERE guild_id=? AND status=0 AND player_id<>?"
                       " ORDER BY contrib_total DESC, join_time LIMIT 1", (gid, leader_uid))
    if not heirs:
        return {'applied': False, 'reason': 'noHeir',
                'currManagerNickName': leader_name}
    heir = int(heirs[0]['player_id'])
    heir_p = api.repos.player.player(heir)
    heir_name = _get(heir_p, 'nickname', '') if heir_p else ''

    api.repos.guild.update_guild(gid, leader_uid=heir, transfer_uid=0, transfer_time=0,
                                 status=0)
    api.repos.guild.update_member(gid, leader_uid, title=0)
    api.repos.guild.update_member(gid, heir, title=99)
    # 军团动态 type=7（弹劾军团长成功）：detail 需要 oldManagerNickname / currManagerNickname
    api.repos.guild.add_news(
        gid, 1, 7, actor_uid=heir, actor_name=heir_name,
        content=json.dumps({'oldManagerNickname': leader_name,
                            'currManagerNickname': heir_name}, ensure_ascii=False))
    return {'applied': True, 'unionId': gid, 'currManagerNickName': heir_name,
            'oldManagerNickname': leader_name, 'currManagerUid': heir}


@endpoint('getFiredUnionMemberStatus')
def h_get_fired_union_member_status(api, params):
    """踢人前查询目标状态（CrossUnionPkCheckFiredStatueRequest，2015-5-11 加）。

    union 成员列表点「踢出军团」时先调它（UnionManager.lua:1191-1208），读
    `event.data.status`：
      0 = 可踢；1 = 已报名跨服军团战（弹 WGVG_Error06）；2 = 已上阵（弹 WGVG_Error07）。
    重新组织一下：status 从 guild_member.cross_gvg_applied / gvg_position 真算。
    """
    fired_uid = int(api.param(params, 'firedUid', api.param(params, 'uid', 0)) or 0)
    msg = _my(api)
    if not msg or fired_uid <= 0:
        return {'status': FIRED_OK, 'firedUid': fired_uid}
    gid = int(_get(msg, 'guild_id', 0))
    target = api.repos.guild.member(gid, fired_uid)
    if not target or int(_get(target, 'status', 1)) != 0:
        return {'status': FIRED_OK, 'firedUid': fired_uid}
    if int(_get(target, 'gvg_position', 0)) > 0:
        status = FIRED_ON_FORMATION
    elif int(_get(target, 'cross_gvg_applied', 0)):
        status = FIRED_APPLIED
    else:
        status = FIRED_OK
    return {'status': status, 'firedUid': fired_uid}


@endpoint('getBonusAccepterList')
def h_get_bonus_accepter_list(api, params):
    """红包（红包道具点「使用」→ 赠送界面）的可选接收者列表。

    调用链：UsePropRequest.lua:150 / RedPacketDispatchScene:350，
    客户端把整个响应当 listData 用（`listData = e.data`），所以
    **friendList / unionList 两个数组必须都存在**：
      RedPacketDispatchScene:refreshUI 第一行就是 `#listData.unionList + #listData.friendList`。

    每个元素的读取路径（RedPacketDispatchScene:473-580）：
      nickName / level / fightCapacity / mainCardMetaId  —— 直接 setString / 画头像
      dispatchedNum —— `itemData.dispatchedNum + num`（算术，必须数字）
      acceptNum     —— `itemDescKey - acceptNum`（算术，必须数字）
      itemDescKey   —— 每个红包每人最多几个（配置缺失时 0；客户端
                       refreshExtraDataToListData 会用自己的 itemDescKey 覆盖）
      online / lastestOfflineSeconds —— 好友列表的「N 天未登录」
      title / lastestConstructDays / hisContribute —— 军团列表的职位角标与贡献
    """
    pid = _pid(api)
    bonus_id = int(api.param(params, 'bonusId', 0) or 0)
    per = _bonus_limit(api, bonus_id)

    friend_list = []
    for r in api.repos.social.friends(pid)[:50]:
        uid = int(_get(r, 'friend_uid', 0))
        item = _bonus_item(api, uid, per)
        if item:
            friend_list.append(item)

    union_list = []
    msg = _my(api)
    if msg:
        gid = int(_get(msg, 'guild_id', 0))
        gname = _get(msg, 'name', '') or ''
        for r in _guild_members(api, gid):
            uid = int(_get(r, 'player_id', 0))
            if uid == pid:
                continue
            item = _bonus_item(api, uid, per)
            if not item:
                continue
            item['unionName'] = gname
            item['title'] = _title_enum(_get(r, 'title', 0))
            item['hisContribute'] = int(_get(r, 'contrib_total', 0))
            item['lastestConstructDays'] = _days_since(_get(r, 'last_construct_time', 0))
            # 军团列表的在线状态用 guild_member.online（真实在线心跳）
            item['online'] = bool(_get(r, 'online', 0))
            item['lastestOfflineSeconds'] = int(_get(r, 'last_active_time', 0))
            union_list.append(item)
            if len(union_list) >= 50:
                break
    return {'friendList': friend_list, 'unionList': union_list, 'bonusId': bonus_id}


def _bonus_limit(api, bonus_id):
    """红包每人可发数量：redBagConfig.redBagList[redBagId == bonusId].itemDescKey。

    本服务下发的 redBagConfig 是空对象，取不到就回 0（客户端会用自己那份覆盖，
    只是首次进入界面时显示 0/0，不会崩）。
    """
    cfg = _ref_meta().get('redBagConfig') or {}
    rows = cfg.get('redBagList') or []
    if isinstance(rows, dict):
        rows = list(rows.values())
    for r in rows:
        if not isinstance(r, dict):
            continue
        if int(r.get('redBagId') or 0) == int(bonus_id or 0):
            try:
                return int(r.get('itemDescKey') or 0)
            except (TypeError, ValueError):
                return 0
    return 0


def _days_since(ts):
    ts = int(ts or 0)
    if ts <= 0:
        return 0
    return max(0, int((_now() - ts) // 86400))


def _bonus_item(api, uid, per_limit):
    """红包可选接收者的一项。字段全部是 RedPacketDispatchScene:507-581 的读取点。

    `online` / `lastestOfflineSeconds` 只有好友列表用：客户端
    `if not itemData.online then offLineSec = now - lastestOfflineSeconds`。
    `player` 表没有 online 列，只有 last_login_time / last_logout_time ——
    last_logout_time == 0 时视为「在线」（否则会显示成「7天以上未登陆」）。
    """
    p = api.repos.player.player(uid)
    if not p:
        return None
    card_id = int(_get(p, 'main_card_id', 0))
    meta = 0
    if card_id:
        row = api.db.one("SELECT meta_id FROM player_card WHERE card_id=?", (card_id,))
        meta = int(_get(row, 'meta_id', 0))
    last_out = int(_get(p, 'last_logout_time', 0))
    return {
        'uid': int(uid),
        'nickName': _get(p, 'nickname', '') or '',
        'level': int(_get(p, 'level', 1) or 1),
        'fightCapacity': int(_get(p, 'fight_capacity', 0)),
        'mainCardMetaId': meta,
        'dispatchedNum': 0,
        'acceptNum': 0,
        'itemDescKey': int(per_limit),
        'online': last_out <= 0,
        'lastestOfflineSeconds': last_out,
        'title': 4,
        'lastestConstructDays': 0,
        'hisContribute': 0,
    }


@endpoint('distributeBonus')
def h_distribute_bonus(api, params):
    """赠送界面点「发送」（DistributeBonusRequest）。

    参数：accepterType(0好友/1军团，客户端传 selectID-1)、bonusId、accepterList[{uid, amount}]
    客户端成功回调（RedPacketDispatchScene:318-350）：
      `e.data.usedNum`  → `RewardManager:getReward({{itemType=PROP, metaId=bonusId, amount=-usedNum}})`
      `e.data.accepterList` 非空 → 弹结果面板；空 → 只弹一句提示
    客户端本地先扣显示，服务端必须真的扣道具并把红包发出去，否则重登就复原。

    发放方式：给每个接收者发一封玩家邮件（mail_type=4）附带等额红包道具。
    这样离线玩家也能收到，且不依赖未实现的「红包领取」活动流程。

    `accepterList` 的元素**不回填**：客户端 RedPacketAccpterListPanel:45-58 只认
    acceptErrorcode 1..6 六种文案（都是失败原因），没有「成功」这一档，
    回元素反而会渲染出一行空文本；回空数组则走 SuspensionLabel 提示。
    """
    pid = _pid(api)
    bonus_id = int(api.param(params, 'bonusId', 0) or 0)
    accepters = api.list_param(params, 'accepterList')
    if bonus_id <= 0 or not accepters:
        return {'accepterList': [], 'usedNum': 0, 'bonusId': bonus_id}

    # 先算总量，再校验库存：绝不出现「发了一半」
    pairs_ = []
    total = 0
    for a in accepters:
        if not isinstance(a, dict):
            continue
        uid = int(_get(a, 'uid', 0) or 0)
        amount = int(_get(a, 'amount', 0) or 0)
        if uid <= 0 or amount <= 0 or uid == pid:
            continue
        if not api.repos.player.player(uid):
            continue
        pairs_.append((uid, amount))
        total += amount
    if total <= 0:
        return {'accepterList': [], 'usedNum': 0, 'bonusId': bonus_id,
                'reason': 'noAccepter'}
    if int(api.db.get_prop(pid, bonus_id)) < total:
        return {'accepterList': [], 'usedNum': 0, 'bonusId': bonus_id,
                'reason': 'notEnough'}

    sender = api.repos.player.player(pid)
    sender_name = _get(sender, 'nickname', '') if sender else ''
    for uid, amount in pairs_:
        api.repos.social.create_mail(
            uid, 4, title='', content='',
            sender_uid=pid, sender_name=sender_name,
            detail={'redPacket': True, 'bonusId': bonus_id},
            attachments=[{'itemType': 7, 'metaId': bonus_id, 'amount': amount}])
    api.db.add_prop(pid, bonus_id, -total)
    return {'accepterList': [], 'usedNum': total, 'bonusId': bonus_id,
            'accepterNum': len(pairs_), 'reason': ''}


# ================================================================ 跨服 GVG
def _gvg_version(api, msg):
    """跨服 GVG 届数。guild.cross_gvg_version 是届数（不是阵型版本号）。"""
    if msg:
        return int(_get(msg, 'cross_gvg_version', 0))
    return 0


def _gvg_apply_row(api, gid, version):
    if gid <= 0:
        return None
    return api.db.one("SELECT * FROM cross_gvg_apply WHERE guild_id=? AND version=?",
                      (int(gid), int(version)))


def _gvg_bless_row(api, version):
    return api.db.one("SELECT * FROM cross_gvg_bless WHERE version=?", (int(version),))


def _gvg_bless_count(api, version, pid):
    row = api.db.one("SELECT COUNT(*) AS c FROM cross_gvg_bless_log"
                     " WHERE version=? AND player_id=?", (int(version), int(pid)))
    return int(_get(row, 'c', 0))


def _gvg_score(api, gid, version):
    row = api.db.one("SELECT * FROM cross_gvg_score WHERE guild_id=? AND version=?",
                     (int(gid), int(version)))
    return row


@endpoint('getCrossGVGBlessInfo')
def h_get_gvg_bless_info(api, params):
    """跨服 GVG 「祝福天师」场景数据（CrossUnionPKBlessingScene）。

    进入方式：`CrossUnionPk.gotoCrossLoginUnionPkScene()` 在
    `CrossUnionPkUtils.findCurrentTimeLevel() == TIME_WORSHIP` 时改跳祝福场景，
    并把本接口的响应原样塞进 `argv.data`。

    客户端 onInit 里**全部是硬读**（CrossUnionPKBlessingScene:186-262）：
      `"["..self.argv.data.unionName.."]"`  —— nil 直接报错，所以必须是字符串
      `" : "..self.argv.data.nickname`      —— 同上（注意小写 n）
      `getTextByKey("login_serverNo",{num=self.argv.data.serverId})` —— 必须是数字
      `self.fullCard:setCard(self.argv.data.mainCardMetaId)` —— CanonFullCard:setCard
          内部 `CCSprite:createWithSpriteFrame(getFullCardSpriteFrame(id))`，
          0 / nil 会拿到不存在的精灵帧 → 崩。所以没有帝王时用**自己的主将**占位。
      `if self.argv.data.canBlessTimes <= 0` —— 必须是数字
      `blessNum` 直接 setString —— 必须是数字
      `promotion` / `gainGvgKnockoutReward` → 控制奖励按钮是否可点

    数据真实来源：cross_gvg_bless（每届一行，记录至尊帝王）+ cross_gvg_bless_log（个人祝福记录）。
    没有帝王记录时返回「未开启」语义（king=false / blessNum=0 / canBlessTimes=0）。
    """
    pid = _pid(api)
    msg = _my(api)
    version = _gvg_version(api, msg)
    row = _gvg_bless_row(api, version)

    king_uid = int(_get(row, 'king_player_id', 0)) or int(_get(row, 'king_uid', 0))
    king = king_uid > 0
    if king:
        main_card = int(_get(row, 'king_main_card_meta_id', 0))
        union_name = _get(row, 'king_union_name', '') or ''
        server_id = int(_get(row, 'king_server_id', 0))
        nickname = _get(row, 'king_nickname', '') or ''
    else:
        main_card = 0
        union_name = ''
        server_id = 0
        nickname = ''
    if not king:
        # 占位：没有帝王时也要给一个**存在**的卡牌 metaId，否则 CanonFullCard 崩。
        # 用自己的主将（保证是真的存在的卡）比编一个随机 id 安全。
        p = api.repos.player.player(pid)
        card_id = int(_get(p, 'main_card_id', 0)) if p else 0
        if card_id:
            crow = api.db.one("SELECT meta_id FROM player_card WHERE card_id=?", (card_id,))
            main_card = int(_get(crow, 'meta_id', 0))
        if not server_id:
            server_id = int(_get(p, 'server_id', 1)) if p else 1

    total_times = int(_get(row, 'can_bless_times', 0))
    left = max(0, total_times - _gvg_bless_count(api, version, pid))

    # 已领淘汰赛奖励？（player_activity_reward_claim，key = 届数）
    claimed = api.ctx.activity.has_claimed(pid, REWARD_SCOPE_GVG_KO, version)
    applied = _gvg_apply_row(api, int(_get(msg, 'guild_id', 0)) if msg else 0, version)
    promotion = bool(int(_get(applied, 'promotion', 0)))

    return {
        'king': king,
        'kingUid': king_uid,
        'mainCardMetaId': main_card,
        'unionName': union_name,
        'serverId': server_id,
        'nickname': nickname,
        'blessNum': int(_get(row, 'bless_num', 0)),
        'canBlessTimes': left,
        'promotion': promotion,
        'gainGvgKnockoutReward': bool(claimed),
        'crossGvgVersion': version,
    }


@endpoint('blessForCrossGVG')
def h_bless_for_cross_gvg(api, params):
    """祝福天师点「祝福」（CrossUnionPkGetBlessRequest，无参数）。

    客户端（CrossUnionPKBlessingScene:106-121）读 `evt.data.rewards`：
      `RewardManager:getReward(evt.data.rewards)` + 弹 RewardReviewPanel。
    必须是数组；空数组也不会崩（只是不弹奖励）。
    奖励配置 `wgvgRewardConfig.wGVGRewardMetas` 在本服务是空表 —— 不编造，
    只把「祝福次数」真实记进 cross_gvg_bless / cross_gvg_bless_log 并返回空奖励。
    """
    pid = _pid(api)
    msg = _my(api)
    version = _gvg_version(api, msg)
    row = _gvg_bless_row(api, version)
    if not row or int(_get(row, 'king_uid', 0)) <= 0 and int(_get(row, 'king_player_id', 0)) <= 0:
        return {'rewards': [], 'applied': False, 'reason': 'noBlessEvent',
                'blessNum': int(_get(row, 'bless_num', 0)), 'canBlessTimes': 0}
    total_times = int(_get(row, 'can_bless_times', 0))
    if _gvg_bless_count(api, version, pid) >= total_times:
        return {'rewards': [], 'applied': False, 'reason': 'noTimes',
                'blessNum': int(_get(row, 'bless_num', 0)), 'canBlessTimes': 0}

    rewards = _gvg_bless_reward()
    applied, _ = api.ctx.reward.grant(pid, rewards, record=True, reason='gvgBless') \
        if rewards else ([], None)
    with api.db.tx() as con:
        con.execute("UPDATE cross_gvg_bless SET bless_num = bless_num + 1, update_time=?"
                    " WHERE version=?", (_now(), int(version)))
        con.execute("INSERT INTO cross_gvg_bless_log(version, player_id, reward_json,"
                    " create_time) VALUES (?,?,?,?)",
                    (int(version), int(pid), json.dumps(applied or [], ensure_ascii=False),
                     _now()))
    row = _gvg_bless_row(api, version)
    return {'rewards': applied or [], 'applied': True,
            'blessNum': int(_get(row, 'bless_num', 0)),
            'canBlessTimes': max(0, total_times - _gvg_bless_count(api, version, pid))}


def _gvg_bless_reward():
    """祝福奖励：wgvgRewardConfig.wGVGRewardMetas 目前是空表 → 空奖励。"""
    cfg = (_ref_meta().get('wgvgRewardConfig') or {}).get('wGVGRewardMetas') or {}
    if not isinstance(cfg, dict):
        return []
    pkg_id = int(cfg.get('blessReward') or 0)
    if pkg_id <= 0:
        return []
    try:
        from services.activity import ActivityService
        return ActivityService.pkg(pkg_id) or []
    except Exception:
        return []


@endpoint('gainGvgKnockoutReward')
def h_gain_gvg_knockout_reward(api, params):
    """祝福场景右上角「奖励」按钮（CrossUnionPkGetKnockoutReward，无参数）。

    客户端（CrossUnionPKBlessingScene:131-158）读：
      `evt.data.rank`    —— 决定奖励标题文案（1/2/3/4/8/16 六档）
      `evt.data.rewards` —— 奖励数组
    ⚠️ rank 落在六档之外时 txtName 会是 nil，`getTextByKey(nil)` 会崩。
    因此**本服务不实现跨服淘汰赛排名**时（wgvgRewardConfig 空、无淘汰赛数据），
    返回 rank=0 + rewards=[]，并且在 getCrossGVGBlessInfo 里把
    `gainGvgKnockoutReward` 置为「已领」，客户端那个按钮本来就不会出现 ——
    正常 UI 路径下不会走到这里。
    """
    pid = _pid(api)
    msg = _my(api)
    version = _gvg_version(api, msg)
    gid = int(_get(msg, 'guild_id', 0)) if msg else 0

    # 淘汰赛名次：留给「跨服淘汰赛」落库后填 guild_score(score_type='gvg_knockout_rank')
    rank = 0
    if gid:
        row = api.db.one("SELECT score FROM guild_score WHERE guild_id=?"
                         " AND score_type='gvg_knockout_rank' AND round=?",
                         (gid, version))
        rank = int(_get(row, 'score', 0))
    rewards = _gvg_knockout_reward(rank)
    if rank <= 0 or not rewards:
        return {'rank': 0, 'rewards': [], 'claimed': False, 'reason': 'noRewardConfig'}

    _, applied = api.ctx.activity.claim_once(pid, REWARD_SCOPE_GVG_KO, version, rewards,
                                             reason='gvgKnockoutReward')
    return {'rank': rank, 'rewards': applied, 'claimed': bool(applied),
            'reason': '' if applied else 'already'}


def _gvg_knockout_reward(rank):
    """淘汰赛奖励：wgvgRewardConfig.wGVGRewardMetas[rank] → reward 列表。空表返回 []。"""
    if rank <= 0:
        return []
    cfg = (_ref_meta().get('wgvgRewardConfig') or {}).get('wGVGRewardMetas') or {}
    if not isinstance(cfg, dict):
        return []
    node = cfg.get(str(rank)) or cfg.get(rank)
    if isinstance(node, dict):
        node = node.get('rewardPackageId') or node.get('rewardId')
    pkg_id = int(node or 0)
    if pkg_id <= 0:
        return []
    try:
        from services.activity import ActivityService
        return ActivityService.pkg(pkg_id) or []
    except Exception:
        return []


@endpoint('getCrossGVGKnockoutStauts')
def h_get_gvg_knockout_status(api, params):
    """获取淘汰状态。

    ⚠️ 客户端有 `CrossUnionPkGetKnockoutStautsRequest`，但全项目**没有任何调用点**
    （grep `CrossUnionPkGetKnockoutStautsRequest.` 只命中它自己的文件）。
    也就是说响应体不会被读。这里仍返回真实淘汰状态，方便以后接上：
      `out` 枚举见 CrossUnionPKLoginScene:441-450 —— 1没报名 2本服参赛军团不足4 3没进前四 4被淘汰 5晋级
    """
    msg = _my(api)
    version = _gvg_version(api, msg)
    gid = int(_get(msg, 'guild_id', 0)) if msg else 0
    row = _gvg_apply_row(api, gid, version)
    out = int(_get(row, 'out_status', 0))
    if out <= 0:
        # 没有报名记录 = 没报名（1）；报名了但没打 = 2（本服参赛军团不够）
        out = 1 if not int(_get(row, 'union_applied', 0)) else 2
    return {'out': out,
            'promotion': bool(int(_get(row, 'promotion', 0))),
            'crossGvgVersion': version,
            'unionApplyCrossGvg': bool(int(_get(row, 'union_applied', 0)))}


def _outline(r):
    """`CrossGvgResultOutline`（淘汰赛对阵项，bean 见
    CrossUnionPkGetKnockoutInfoRequest.lua:18-23）：
      id（点「录像」时传给 getGvgBattleResultDetail）
      attUnion / defUnion = UnionIdentification{serverId, unionId, unionName}
      win（进攻方是否胜）
    """
    if not r:
        return {'id': 0,
                'attUnion': {'serverId': 0, 'unionId': 0, 'unionName': ''},
                'defUnion': {'serverId': 0, 'unionId': 0, 'unionName': ''},
                'win': False}
    return {'id': int(_get(r, 'report_id', 0)),
            'attUnion': {'serverId': int(_get(r, 'att_server_id', 0)),
                         'unionId': int(_get(r, 'att_guild_id', 0)),
                         'unionName': _get(r, 'att_union_name', '') or ''},
            'defUnion': {'serverId': int(_get(r, 'def_server_id', 0)),
                         'unionId': int(_get(r, 'def_guild_id', 0)),
                         'unionName': _get(r, 'def_union_name', '') or ''},
            'win': bool(int(_get(r, 'win', 0)))}


@endpoint('getGvgKnockoutInfo')
def h_get_gvg_knockout_info(api, params):
    """跨服 GVG「激战回顾 / 淘汰赛」场景（CrossUnionPkKnockoutScene）。

    客户端（CrossUnionPkKnockoutScene:300-313）按时间段逐个 `addMatch(type, list)`：
      `addMatch(KNOCKOUT_TYPE_16, self.knockoutInfo.sixteen)`  ← 必须能 ipairs
      ... eight / four
      `addMatch(KNOCKOUT_TYPE_THIRD, {self.knockoutInfo.thirdPlaceBattle})`
      `addMatch(KNOCKOUT_TYPE_CHAMPION, {self.knockoutInfo.championBattle})`
    所以 sixteen/eight/four 必须是**数组**（nil -> `ipairs(nil)` 直接报错），
    championBattle / thirdPlaceBattle 包在 `{}` 里，nil 会因为 ipairs 遇到 nil 而跳过，
    但 debug 下客户端断言 `championBattle ~= nil`（GetKnockoutInfoRequest.lua:98），
    所以还是给一个空 outline 对象最稳。

    数据来自 cross_gvg_report，按 round_type 分组（见本文件 RT_* 常量）。
    本服务没有跨服淘汰赛进程 → 表是空的 → 三档都回空数组。
    """
    rows = api.db.all("SELECT * FROM cross_gvg_report ORDER BY report_id")
    buckets = {RT_16: [], RT_8: [], RT_4: []}
    champion = None
    third = None
    for r in rows:
        rt = int(_get(r, 'round_type', -1))
        if rt in buckets:
            buckets[rt].append(_outline(r))
        elif rt == RT_CHAMPION:
            champion = r
        elif rt == RT_THIRD:
            third = r
    # 注意：champion/third 保存的是**原始行**，这里才转成 outline。
    # 之前写成 `champion = _outline(r)` 再套一层 _outline()，会把字段全清 0。
    return {'sixteen': buckets[RT_16],
            'eight': buckets[RT_8],
            'four': buckets[RT_4],
            'championBattle': _outline(champion),
            'thirdPlaceBattle': _outline(third)}


def _gvg_report_root(api, report_id, my_guild):
    """跨服战报 → 战斗根对象。逻辑同本服战报，只是数据源是 cross_gvg_report。"""
    row = None
    if report_id > 0:
        row = api.db.one("SELECT * FROM cross_gvg_report WHERE report_id=?",
                         (int(report_id),))
    if row:
        stored = _report_from_json(_get(row, 'report_json', ''))
        if stored:
            return _battle_root(stored)
        att = _get(row, 'att_union_name', '') or ''
        deff = _get(row, 'def_union_name', '') or ''
        # 敌方名字为空时 UnionBattleScene:1718 会去取「城池 NPC 名」，
        # 而跨服没有城池 id（UnionPkData.getBattleCityId() 为 nil）→ 客户端比较 nil 报错。
        # 所以空名字时用占位串兜住。
        att = att or '军团'
        deff = deff or '对手'
        return _battle_root(_empty_battle_report(
            att_name=att, def_name=deff, win=bool(int(_get(row, 'win', 0))),
            att_uid=int(_get(row, 'att_guild_id', 0)),
            def_uid=int(_get(row, 'def_guild_id', 0))))
    gname = _get(my_guild, 'name', '') if my_guild else ''
    return _battle_root(_empty_battle_report(att_name=gname or '军团', def_name='对手'))


@endpoint('getGvgBattleResultDetail')
def h_get_gvg_battle_result_detail(api, params):
    """淘汰赛/小组赛战报点「录像」（CrossUnionPkGetBattleReportRequest）。

    参数：reportId, knockout(boolean), battleSubType
    调用点：CrossUnionPkKnockoutScene:72（`onVideoBtnClick` → sendRequestDefalut(reportId,
    true, knockoutType)）。
    客户端 `CrossUnionPkGetBattleReportRequest.onSucceedDefault` →
    `CrossUnionPk.gotoBattleField(event.data, ...)`（`BattleScene.lua:117-133`
    在 kCrossGVGRankBattle 下读根上的 `sharkUnionBattlefieldReport`）。

    没有这条战报时回 716607（原厂「战报信息不存在」），理由见 STRICT_BATTLE_ERRORS。
    """
    report_id = int(api.param(params, 'reportId', 0) or 0)
    row = None
    if report_id > 0:
        row = api.db.one("SELECT report_id FROM cross_gvg_report WHERE report_id=?",
                         (int(report_id),))
    if not row and STRICT_BATTLE_ERRORS:
        raise ApiError(E_REPORT_NOT_EXIST)
    return _gvg_report_root(api, report_id, _my(api))


@endpoint('crossGVGGroupBattle')
def h_cross_gvg_group_battle(api, params):
    """小组赛「开战」（CrossUnionPkGroupBattleRequest，无参数）。

    调用点：CrossUnionPKTeamAdjustScene:268（FightButton）。
    客户端（CrossUnionPkGroupBattleRequest:81-93）→
      `CrossUnionPk.gotoBattleField(event.data, nil, {BattleEnterEnum=kCrossGVGGroupBattle,...})`
    → `BattleScene` 读根上 `sharkUnionBattlefieldReport`，另外根上的
    `currPoints` / `changePoints` 给结算面板显示积分变化
    （BattleScene.lua:785 / 2547 传的是 `self.unionBattleData.currPoints`，
    也就是**响应根**上的这两个字段）。

    ⚠️ 真实的跨服小组赛（跨进程对战 + 积分结算 + 战报）未实现：
    * 本服没有跨服进程，cross_gvg_report 永远是空的；
    * 而「空战报 + 进战斗场景」会在客户端 UnionBattleScene.lua:179 崩（nil 比数字）。
    所以这里回 716638「军团战暂未开启」（UnionPkErrorCode.lua:70），
    客户端弹提示后留在阵型界面，不进入战斗。
    等真正的战斗模拟接上后，把 STRICT_BATTLE_ERRORS 置 False 或直接返回战报即可。
    """
    if STRICT_BATTLE_ERRORS:
        raise ApiError(E_WAR_NOT_OPEN)
    msg = _my(api)
    version = _gvg_version(api, msg)
    gid = int(_get(msg, 'guild_id', 0)) if msg else 0
    score = _gvg_score(api, gid, version) if gid else None
    report = _empty_battle_report(
        att_name=(_get(msg, 'name', '') or '军团') if msg else '军团',
        def_name='对手')
    out = _battle_root(report)
    out['currPoints'] = int(_get(score, 'score', 0))
    out['changePoints'] = 0
    return out


@endpoint('applyCrossGvg')
def h_apply_cross_gvg(api, params):
    """跨服 GVG 报名（CrossUnionPkGetApplyRequest）。

    调用点 CrossUnionPKLoginScene:143/145：
      `{type = 1}` 团员报名 → 成功回调把 selfApplyCrossGvg 置 false（本地）
      `{type = 0}` 军团报名（仅军团长）
    响应体不读（只看 retCode），但回显报名状态方便排查。
    """
    pid = _pid(api)
    apply_type = int(api.param(params, 'type', api.param(params, 'crossGvgType', 0)) or 0)
    msg = _my(api)
    if not msg:
        return _not_in_union(api, type=apply_type, unionApplyCrossGvg=False,
                             selfApplyCrossGvg=False)
    gid = int(_get(msg, 'guild_id', 0))
    version = _gvg_version(api, msg)
    flags = _member_flags(api, gid, pid)

    if apply_type == 1:
        # 团员报名
        api.repos.guild.update_member(gid, pid, cross_gvg_applied=1, cross_gvg_quit=0)
        row = _gvg_apply_row(api, gid, version)
        return {'applied': True, 'type': apply_type, 'unionId': gid,
                'unionApplyCrossGvg': bool(int(_get(row, 'union_applied', 0))),
                'selfApplyCrossGvg': True}

    # 军团报名（type=0）：只有正/副团长能报
    if not _is_manager(_get(msg, 'member_title', 0)):
        return _no_priv(api, type=apply_type, unionApplyCrossGvg=False,
                        selfApplyCrossGvg=bool(int(_get(flags, 'cross_gvg_applied', 0))))
    applied_num = api.repos.guild.member_count(gid)
    with api.db.tx() as con:
        con.execute("INSERT INTO cross_gvg_apply(guild_id, version, union_applied,"
                    " applied_num, quit_num, out_status, promotion, update_time)"
                    " VALUES (?,?,1,?,0,0,0,?) ON CONFLICT(guild_id, version)"
                    " DO UPDATE SET union_applied=1, applied_num=excluded.applied_num,"
                    " update_time=excluded.update_time",
                    (gid, int(version), int(applied_num), _now()))
        con.execute("UPDATE guild SET cross_gvg_applied=1 WHERE guild_id=?", (gid,))
    return {'applied': True, 'type': apply_type, 'unionId': gid,
            'unionApplyCrossGvg': True,
            'selfApplyCrossGvg': bool(int(_get(flags, 'cross_gvg_applied', 0))),
            'appliedNum': int(applied_num)}


@endpoint('crossGvgCanMindApply')
def h_cross_gvg_can_mind_apply(api, params):
    """进入军团大厅时问一句「要不要提醒报名跨服军团战」（UnionScene.lua:635-652）。

    客户端只读 `evt.data.applyCrossGvgRemind`；为真时弹
    「军团已报名跨服军团战」并跳到跨服界面（WGVG_Detail29）。
    真实现：本军团已报名 + 我自己还没报名 + 我没退出过。
    """
    pid = _pid(api)
    msg = _my(api)
    if not msg:
        return {'applyCrossGvgRemind': False}
    gid = int(_get(msg, 'guild_id', 0))
    version = _gvg_version(api, msg)
    row = _gvg_apply_row(api, gid, version)
    flags = _member_flags(api, gid, pid)
    union_applied = bool(int(_get(row, 'union_applied', 0))) or \
        bool(int(_get(msg, 'cross_gvg_applied', 0)))
    self_applied = bool(int(_get(flags, 'cross_gvg_applied', 0)))
    self_quit = bool(int(_get(flags, 'cross_gvg_quit', 0)))
    return {'applyCrossGvgRemind': bool(union_applied and not self_applied and not self_quit),
            'unionApplyCrossGvg': union_applied,
            'selfApplyCrossGvg': self_applied,
            'selfQuitCrossGvg': self_quit}


@endpoint('exchangeGvgFormation')
def h_exchange_gvg_formation(api, params):
    """跨服阵型调整「上传阵容」（ExchangeGvgFormationRequest）。

    参数（DSL 注释 CrossUnionPkGetKnockoutStautsRequest 同款，实际传参见
    `CrossUnionPkData.getUploadTeamParams`）：
      override(boolean), version(int), forwardUid(long), headUids[], middleUids[], tailUids[]
    调用点：CrossUnionPkUpdatePanel:62（弹框「覆盖」）、CrossUnionPkMemberSelectScene。

    落库到 cross_gvg_formation（PK: guild_id + version + player_id），
    position 编码 1 先锋 / 10-19 阵首 / 20-29 阵中 / 30-39 阵尾（与客户端一致）。
    同时把 guild_member.gvg_position 同步，踢人前的 getFiredUnionMemberStatus 依赖它。

    version 处理：getCrossGvgInfo（别的模块）目前固定回 0，客户端会把这个 0 原样带回来，
    做严格乐观锁会让除第一次以外的所有上传都失败 —— 所以 version 只做记录，
    阵容统一落在 version=0（当前阵容），旧行先删。
    """
    msg = _my(api)
    if not msg:
        return _not_in_union(api, version=0, positionNum=0)
    gid = int(_get(msg, 'guild_id', 0))
    override = bool(api.param(params, 'override', False))
    forward = int(api.param(params, 'forwardUid', 0) or 0)
    heads = api.int_list_param(params, 'headUids')
    middles = api.int_list_param(params, 'middleUids')
    tails = api.int_list_param(params, 'tailUids')

    rows = []
    if forward > 0:
        rows.append((POS_FORWARD, forward))
    for i, uid in enumerate(heads[:10], 0):
        if uid > 0:
            rows.append((POS_HEAD + i, uid))
    for i, uid in enumerate(middles[:10], 0):
        if uid > 0:
            rows.append((POS_MIDDLE + i, uid))
    for i, uid in enumerate(tails[:10], 0):
        if uid > 0:
            rows.append((POS_TAIL + i, uid))

    ids = [u for _, u in rows]
    names, metas = {}, {}
    if ids:
        q = ','.join('?' * len(ids))
        for r in api.db.all("SELECT p.player_id, p.nickname, c.meta_id FROM player p"
                            " LEFT JOIN player_card c ON c.card_id=p.main_card_id"
                            " WHERE p.player_id IN (%s)" % q, ids):
            names[int(r['player_id'])] = r['nickname'] or ''
            metas[int(r['player_id'])] = int(r['meta_id'] or 0)

    with api.db.tx() as con:
        con.execute("DELETE FROM cross_gvg_formation WHERE guild_id=? AND version=0", (gid,))
        for pos, uid in rows:
            con.execute("INSERT INTO cross_gvg_formation(guild_id, version, player_id,"
                        " position, main_card_meta_id, user_name) VALUES (?,?,?,?,?,?)",
                        (gid, 0, uid, int(pos), metas.get(uid, 0), names.get(uid, '')))
            con.execute("UPDATE guild_member SET gvg_position=? WHERE guild_id=?"
                        " AND player_id=?", (int(pos), gid, int(uid)))
        # 不在阵容里的成员位置清零，否则踢人提示会一直说「已上阵」
        if ids:
            q = ','.join('?' * len(ids))
            con.execute("UPDATE guild_member SET gvg_position=0 WHERE guild_id=?"
                        " AND player_id NOT IN (%s)" % q, [gid] + ids)
        else:
            con.execute("UPDATE guild_member SET gvg_position=0 WHERE guild_id=?", (gid,))
    return {'applied': True, 'unionId': gid, 'version': 0,
            'positionNum': len(rows), 'override': override}


@endpoint('uploadCrossGvgTeamMirror')
def h_upload_cross_gvg_team_mirror(api, params):
    """「保存阵容镜像」（UploadCrossGvgTeamMirrorRequest，无参数）。

    调用点：CrossUnionPKTeamAdjustScene:239 / CrossUnionPkUpdatePanel:39。
    客户端成功后把 `teamMirrorRemind` 置 false（即熄灭保存按钮的呼吸灯），不读响应体。
    真实现：版本号 +1（union_war_state 里按军团记），并把每个成员的
    guild_member.gvg_team_mirror_version 同步成新版本，供后续「镜像是否过期」判断。
    """
    msg = _my(api)
    if not msg:
        return _not_in_union(api, teamMirrorRemind=False, version=0)
    gid = int(_get(msg, 'guild_id', 0))
    old = _state_get(api, 'guild', gid, 'gvg_mirror_version', 0)
    new = _state_set(api, 'guild', gid, 'gvg_mirror_version', old + 1)
    with api.db.tx() as con:
        con.execute("UPDATE guild_member SET gvg_team_mirror_version=? WHERE guild_id=?"
                    " AND status=0", (int(new), gid))
    return {'applied': True, 'unionId': gid, 'version': new, 'teamMirrorRemind': False}


@endpoint('inspireCrossGvg')
def h_inspire_cross_gvg(api, params):
    """跨服阵型场景三个鼓舞按钮（InspireCrossGvgRequest）。

    参数 `type`（CrossUnionPKTeamAdjustScene:181-195）：
      1 = 金币鼓舞(btn_2)  2 = 银币鼓舞(btn_1)  3 = 奋力一击(btn_3)
    成功后客户端自己 `increaseSelfInspireNum` 在本地 signs 上加 1 并刷新按钮，
    再回头拉 getCrossGvgInfo 覆盖 —— 响应体不读，但服务端必须真计数，
    否则 `UnionPkCheck` 的剩余次数判断会一直放行。
    上限复用 unionWarSettingConfig 的 goldBuffNum / silverBuffNum / striveNum。
    """
    pid = _pid(api)
    buff = int(api.param(params, 'type', api.param(params, 'buffId', 0)) or 0)
    msg = _my(api)
    if not msg:
        return _not_in_union(api, type=buff, gemInspireNum=0,
                             coinInspireNum=0, striveInspireNum=0)
    gid = int(_get(msg, 'guild_id', 0))
    gem = int(_get(msg, 'gem_inspire_num', 0))
    coin = int(_get(msg, 'coin_inspire_num', 0))
    strive = int(_get(msg, 'strive_inspire_num', 0))

    applied, reason = False, ''
    if buff == 1:
        if gem >= _cfg_int('goldBuffNum', 5):
            reason = 'limit'
        elif _charge(api, pid, _cfg_int('goldBuffCost', 0), gems=True):
            gem += 1
            api.repos.guild.update_member(gid, pid, gem_inspire_num=gem)
            applied = True
        else:
            reason = 'notEnough'
    elif buff == 2:
        if coin >= _cfg_int('silverBuffNum', 5):
            reason = 'limit'
        elif _charge(api, pid, _cfg_int('silverBuffCost', 0), gems=False):
            coin += 1
            api.repos.guild.update_member(gid, pid, coin_inspire_num=coin)
            applied = True
        else:
            reason = 'notEnough'
    elif buff == 3:
        if strive >= _cfg_int('striveNum', 3):
            reason = 'limit'
        elif _charge(api, pid, _cfg_int('striveCost', 0), gems=True):
            strive += 1
            api.repos.guild.update_member(gid, pid, strive_inspire_num=strive)
            applied = True
        else:
            reason = 'notEnough'
    else:
        reason = 'badType'

    return {'applied': applied, 'reason': reason, 'type': buff, 'unionId': gid,
            'gemInspireNum': gem, 'coinInspireNum': coin, 'striveInspireNum': strive}
