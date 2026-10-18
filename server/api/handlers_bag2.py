#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""背包 / 装备 / 武将养成 / 杂项 —— 第二批补齐的 19 个端点。

===============================================================================
改这个文件之前，先读完这三条
===============================================================================
1) 客户端 onSuccess 回调几乎**没有 nil 守卫**：少一个键就是
   "attempt to index a nil value" → 引擎直接 kill 进程。
   每个处理器开头都注明了「哪个 Lua 文件的哪一段在读哪个键」，照那个键给全。

2) 这批接口的成功语义是「服务端已经算完并落库了，客户端照着在本地再扣/加一遍」。
   客户端会**无条件**执行本地扣减（技能书、道具、碎片、卡牌、体力、钻石……）。
   所以参数非法时**必须** `raise ApiError(业务码)`，绝不能回 200 + 空表 ——
   回 200 等于让客户端白扣一次资源，本地存档就和服务器错位了。
   唯一天然允许"成功但什么都不做"的情况是参数里本来就没有要做的事
   （例如 sellProps 收到空列表）。

3) 会删数据的（sellProps / rebirthItem / sacrificeItem / synthetizeCard /
   synthetizeEquip）**先把整批参数校验完再动手**，中途失败不能留下
   "删了一半"的中间态。SQLite 事务尽量短，一次业务一个事务。

===============================================================================
端点 -> 客户端请求类 -> 调用它的界面
===============================================================================
    exchangeCard         CardOldToNewExchangeRequest          CardOldToNewExchangeScene（以旧换新）
    exchangeCardDaily    ActivityexchangeCardDailyRequest     Activity_ExchangeDailyLayer（易帅换将）
    exchangeItem         WantedActivityExchangeRequest        WantedActivityShopPanel（悬赏商店兑换）
    gachaCardByBox       GachaCardByBoxRequest                GachaScene（扭蛋盒 / activityBoxGacha）
    rebirthItem          ItemRebirthRequest                   CardRebirthScene（重生）
    sacrificeItem        ItemSacrificeRequest                 CardRebirthScene（祭炼）
    sellProps            SellPropsRequest                     ItemSellMessageBoxPanel（背包出售）
    synthetizeCard       FragmentSynthetizeCardRequest        FragmentCardListPanel（将魂合成）
    synthetizeEquip      FragmentSynthetizeEquipRequest       FragmentEquipListPanel（器魂合成）
    upgradeSkill         UpgradeSkillRequest                  SkillUpgradeScene / SkillEvolveScene
    robBeastFragment     RobBeastFragmentRequest              RobFragmentScene / RobFragmentBeforePanel
    bindAccount          BindAccountRequest                   ThirdPlatformLogin（游客号绑平台）
    challengeContend     ChallengeContendRequest              Activity_ContendLayer（争霸）
    challengeFriendList  ChallengeFriendListRequest           UserDetailPanel（一键切磋）
    challengeMysterious  ChallengeMysteriousRequest            MesteriousChanllengePanel（秘境挑战）
    clearElite           EliteSweepRequest                    EliteSweepConfirmPopmPanel（精英扫荡）
    defaultPhoneNum      PhoneChargeSetNumRequest             PhoneChargeBindPopPanel（话费返还绑号码）
    getRobUserList       GetRobUserListRequest                RobFragmentScene（可抢碎片的人）
    inviteFbFriends      FacebookInviteFriendRequest          Activity_FacebookShareLayer（FB 邀请）
"""
import random
import time

import gamedata as G
import luaconf as LC
from . import endpoint, ApiError, to_list

OK = 200

# ============================================================ 业务错误码
# 全部来自客户端：canon/manager/ErrorCodeManager.lua 的 _codes 表 + 各面板的
# onFailed 分支。**不要自己编数字**，客户端认不出就只弹一个"未知错误"。
E_GEM_NOT_ENOUGH = 710513   # goldNotEnough → 打开"补充钻石"面板
E_COIN_NOT_ENOUGH = 710512  # silverNotEnouth → 打开"补充银币"面板
E_ENERGY_NOT_ENOUGH = 710514
E_EVENT_POINT_NOT_ENOUGH = 710515   # RobFragmentBeforePanel:59 showNotEnoughEventPointPanel
E_CARD_NOT_EXIST = 712401   # User does not own card
E_EQUIP_NOT_EXIST = 712501
E_PROP_NOT_ENOUGH = 712301  # Prop is not enough
E_SKILL_MAX_LEVEL = 712005  # CardSkill has reached max level（SkillUpgradeScene:822）
E_SKILL_NOT_BOOK = 712013   # Prop is not skill book（SkillUpgradeScene:824）
E_SKILL_BOOKS_TOO_MANY = 712014   # 技能书一次最多 5 本（SkillUpgradeScene:819）
E_SKILL_LEVEL_LIMIT = 712015      # 技能升级受主公等级限制（SkillUpgradeScene:831）
E_CARD_LOCKED = 711081      # Card is locked
E_CARD_IN_QUEUE = 711059    # Card is in battle queue
E_CARD_FRAGMENT_NOT_ENOUGH = 713600   # FragmentCardListPanel:435
E_EQUIP_FRAGMENT_NOT_ENOUGH = 713601  # FragmentEquipListPanel:383
E_MISSION_NOT_EXIST = 710401
E_EXCHANGE_CLOSED = 714700            # cardExchange 活动未开启（客户端会退回主界面）
E_EXCHANGE_TIMES_OUT = 714701         # 兑换次数已用完
E_EXCHANGE_NO_MATERIAL = 714702       # 材料武将数量不足
E_EXCHANGE_MATERIAL_REBORN = 714703   # 材料武将转生过，不能当材料
E_ASTRAL_ESSENCE_NOT_ENOUGH = 716484  # 星灵不足
E_CARD_NOT_CONFIGED = 711001          # Card is not configed in card-meta.xml
E_BEAST_FRAGMENT_LIMIT = 716019       # beast_fragmentLimit（RobFragmentScene:45）
E_COMMON = 714717                     # EC_COMMON_TXT：通用"操作失败"，用于参数非法


# ============================================================ 配置 / 元数据
# luaconf 自己有缓存，这里再包一层是为了「list 版」和「按 id 索引版」不重复构造：
# skill_meta 有 3391 行、card_meta 有 1350 行，每个请求重建一次索引太亏。
_CFG = {}


def _raw(name):
    """读 work/luasrc/canon/configs/<name>.<md5>.lua 的原始表。"""
    if name not in _CFG:
        _CFG[name] = LC.load(name)
    return _CFG[name]


def _rows(name):
    """同一张配置表的 list 形态。"""
    key = '#list:' + name
    if key not in _CFG:
        _CFG[key] = LC.as_list(LC.load(name))
    return _CFG[key]


def _index(name, field='id'):
    """list 形态 -> {int(field): row}。配置里的数字多半是字符串，统一转 int。"""
    key = '#idx:%s:%s' % (name, field)
    if key not in _CFG:
        out = {}
        for row in _rows(name):
            if not isinstance(row, dict):
                continue
            try:
                out[int(row.get(field))] = row
            except (TypeError, ValueError):
                continue
        _CFG[key] = out
    return _CFG[key]


def _at(table, key):
    """配置表取行：键可能是 int 也可能是 '123' 字符串，两种都试。"""
    if not isinstance(table, dict):
        return None
    try:
        key = int(key)
    except (TypeError, ValueError):
        return None
    if key in table:
        return table[key]
    return table.get(str(key))


def _val(row, key, default=None):
    """从一行（dict 或 sqlite3.Row）里取一个值。

    ⚠️ sqlite3.Row **没有 .get()**，取不存在的列抛 IndexError；而配置表是 dict。
       两种都可能出现在调用方，所以统一走这个函数，别直接 row.get / row[...]。
    """
    if row is None:
        return default
    try:
        return row[key]
    except (KeyError, IndexError, TypeError):
        pass
    try:
        return row.get(key, default)
    except AttributeError:
        return default


def _int(table, key, default=0):
    """取 int，缺字段/空串/None 都退回 default。"""
    value = _val(table, key)
    if value is None or value == '':
        return default
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


_META_CACHE = None


def _meta():
    """getMeta 的那份载荷（活动配置都在里面）。

    客户端所有活动接口的参数（contendId、itemId、eliteId…）都对应这张表里的配置行，
    服务端必须用**同一份**配置校验，否则会出现"客户端能点、服务端说不存在"。
    """
    global _META_CACHE
    if _META_CACHE is None:
        from meta_payload import get_meta_payload
        _META_CACHE = get_meta_payload() or {}
    return _META_CACHE


def _meta_cfg(name):
    value = _meta().get(name)
    return value if isinstance(value, dict) else {}


def _game_setting():
    return G.game_setting_config() or {}


def _battle_setting():
    return G.battle_setting_config() or {}


# ============================================================ 惰性建表
# 本模块自用的三张表。**不碰 schema.sql**：按项目约定，补齐用的新模块把自己的
# 表在自己这里 CREATE TABLE IF NOT EXISTS，进程内只跑一次。
_TABLES_READY = False


def _ensure_tables(api):
    """建本模块私有的表（幂等）。任何异常都吞掉：表已存在、库只读都不该让接口 500。"""
    global _TABLES_READY
    if _TABLES_READY:
        return
    _TABLES_READY = True
    ddl = (
        # 扭蛋盒（gachaCardByBox）：一批固定卡片，每抽走一张标记 is_drawn。
        # 现有 getSharkGachaBoxInfo 属于别的模块且目前回的是 boxInfo（客户端读的是
        # gachaBoxCard），所以盒子状态先由本模块自己维护，抽完再铺一批。
        "CREATE TABLE IF NOT EXISTS player_gacha_box ("
        " player_id INTEGER NOT NULL,"
        " slot_id   INTEGER NOT NULL,"
        " card_id   INTEGER NOT NULL DEFAULT 0,"
        " is_special INTEGER NOT NULL DEFAULT 0,"
        " is_drawn  INTEGER NOT NULL DEFAULT 0,"
        " create_time INTEGER NOT NULL DEFAULT 0,"
        " PRIMARY KEY (player_id, slot_id))",
        # 圣兽碎片（ResourceEnum.BEAST_FRAGMENT=14）。
        # reward 引擎没有这一种资源类型（见 services/reward.py），抢到的碎片只能
        # 存在这里。展示端 getSharkBeasts 属于别的模块，目前还回空表，所以碎片
        # 先"存下来但不显示"，等那边补上再改成从这张表读。
        "CREATE TABLE IF NOT EXISTS player_beast_fragment ("
        " player_id INTEGER NOT NULL,"
        " meta_id   INTEGER NOT NULL,"
        " amount    INTEGER NOT NULL DEFAULT 0,"
        " PRIMARY KEY (player_id, meta_id))",
        # FB 邀请好友（inviteFbFriends）：客户端只把 id 塞进本地
        # sharkFbShareActivity.inviteFbFriendList，服务端这边单独留档。
        "CREATE TABLE IF NOT EXISTS player_fb_invite ("
        " player_id INTEGER NOT NULL,"
        " fb_friend TEXT    NOT NULL,"
        " create_time INTEGER NOT NULL DEFAULT 0,"
        " PRIMARY KEY (player_id, fb_friend))",
    )
    for sql in ddl:
        try:
            with api.db.tx() as con:
                con.execute(sql)
        except Exception:
            pass


# ============================================================ 小工具
def _pid(api):
    return int(api.require_player()['player_id'])


def _today(api):
    return api.db.today()


def _daily(api, pid, key):
    return api.repos.player.daily_counter(pid, _today(api), key)


def _bump_daily(api, pid, key, delta=1):
    return api.repos.player.bump_daily(pid, _today(api), key, delta)


def _grant(api, pid, rewards, reason):
    """发奖并返回客户端认的 reward 列表（{itemType, metaId, amount, id?, level?}）。"""
    applied, _changed = api.ctx.reward.grant(pid, list(rewards or []),
                                             record=True, reason=reason)
    return applied


def _merge(rewards):
    """把 (itemType, metaId) 相同的奖励合成一条，保持首次出现的顺序。"""
    out, where = [], {}
    for rw in rewards or []:
        item_type = int(rw.get('itemType') or 0)
        if item_type <= 0:
            continue
        meta_id = int(rw.get('metaId') or 0)
        key = (item_type, meta_id)
        if key in where:
            out[where[key]]['amount'] = int(out[where[key]]['amount']) + int(rw.get('amount') or 0)
            continue
        where[key] = len(out)
        out.append({'itemType': item_type, 'metaId': meta_id,
                    'amount': int(rw.get('amount') or 0)})
    return [rw for rw in out if int(rw['amount']) > 0]


def _battle_pack(mission_id=100101, battle_type=1):
    """构造一个完整的战斗结算包（BattleScene 用它播动画）。

    `G.build_battle_response` 是纯函数，不落库、不发奖 —— 奖励由调用方自己算完
    再塞进 `pack['rewards']`，这样不同活动可以给不同的产出。
    """
    try:
        pack = G.build_battle_response(int(mission_id), int(battle_type))
    except Exception:
        # 战斗表缺行时的兜底。cardInitDatas 为空客户端会演出失败，但至少不是 500。
        pack = {'win': False, 'leftHpRate': 0, 'qte': False, 'rewards': [],
                'cardInitDatas': [], 'eventFlow': [], 'encounterMultiPlayerBoss': False}
    if not isinstance(pack, dict):
        pack = {'win': False, 'leftHpRate': 0, 'qte': False, 'rewards': [],
                'cardInitDatas': [], 'eventFlow': [], 'encounterMultiPlayerBoss': False}
    pack.setdefault('rewards', [])
    return pack


def _card_meta_raw(meta_id):
    """原始 card_meta 行（含 rare / astralEssence 等字段）。

    ⚠️ 不能用 `gamedata.card_meta()`：那是 features 精简过的视图，只有技能相关字段，
    没有 rare / astralEssence / basicPrice。
    """
    return _at(_raw('card_meta'), meta_id)


def _card_rare(meta_id):
    """卡牌稀有度（1..7）。先读 card_meta.rare，读不到再退回 gamedata 的稀有度索引。"""
    row = _card_meta_raw(meta_id)
    rare = _int(row, 'rare', 0)
    if rare:
        return rare
    try:
        return int(G.card_rare(int(meta_id)) or 1)
    except (TypeError, ValueError):
        return 1


def _skill_row(skill_id):
    return _index('skill_meta').get(int(skill_id))


def _skill_max_level(skill_group_id):
    """某个技能组里最高的 level（客户端 SkillEvolveScene:48 getMaxLv 同样算法）。"""
    key = '#skillmax:%d' % int(skill_group_id)
    if key not in _CFG:
        best = 0
        for row in _rows('skill_meta'):
            if not isinstance(row, dict):
                continue
            if _int(row, 'skillGroupId') == int(skill_group_id):
                best = max(best, _int(row, 'level'))
        _CFG[key] = best
    return _CFG[key]


def _skill_payload(row):
    """`cardSkill` 回包项 —— 与 assembler.build_card 里 cardSkills[] 的形状一致。

    客户端 SkillUpgradeScene:779 只读 `e.data.cardSkill.skillId`（用来判断
    "升级成功还是失败"：变了就是成功），但 rest 字段给全，免得别的界面复用时报 nil。
    """
    return {
        'slot': _int(row, 'slot'),
        'skillId': _int(row, 'skill_id'),
        'skillType': _int(row, 'skill_type'),
        'currQuality': _int(row, 'curr_quality'),
        'countryGroupId': _int(row, 'country_group_id'),
        'countryGroupNum': _int(row, 'country_group_num'),
        'cardGroupIds': [int(x) for x in str(_val(row, 'card_group_ids') or '').split(',')
                         if x],
    }


def _card_skills_map(api, pid):
    """{card_id: set(skill_id)}，一次查完，避免在循环里反复查。"""
    out = {}
    for row in api.db.all("SELECT card_id, skill_id FROM player_card_skill"
                          " WHERE card_id IN (SELECT card_id FROM player_card WHERE player_id=?)",
                          (int(pid),)):
        out.setdefault(int(row['card_id']), set()).add(int(row['skill_id']))
    return out


# ================================================================ 背包：卖道具
@endpoint('sellProps')
def h_sell_props(api, params):
    """卖道具（背包 → 道具页 → 出售 → 确认）。

    客户端：ItemSellMessageBoxPanel:227
        params = { requisite = [ {metaId=<道具配置id>, amount=<数量>}, ... ] }
                （同文件 :80-82 用 prop_meta[metaId].sellPrice * amount 算总价）
    回包：`rewards` —— 同文件 :205 `RewardManager:getReward(evt.data.rewards)`，
        之后客户端自己再拉一次 getProps 刷列表。

    安全：sellProps 会**删道具**，所以先把整批校验完（够不够、能不能卖）再扣。
    """
    pid = _pid(api)
    rows = api.list_param(params, 'requisite') or api.list_param(params, 'props')

    # 同一个 metaId 可能分多行传进来，合并后统一校验
    want = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        meta_id = _int(row, 'metaId') or _int(row, 'propId')
        amount = _int(row, 'amount') or _int(row, 'propAmount')
        if meta_id <= 0 or amount <= 0:
            continue
        want[meta_id] = want.get(meta_id, 0) + amount

    if not want:
        # 没有可卖的东西：不删任何行，按"成功但什么都不做"返回。
        return OK, {'rewards': []}

    total = 0
    for meta_id, amount in want.items():
        meta = G.prop_meta(meta_id) or {}
        if not meta:
            raise ApiError(E_COMMON)                 # 配置里没有这个道具
        if meta.get('canSell') is False:
            raise ApiError(E_COMMON)                 # 客户端本来就把它置灰了
        if api.repos.asset.prop(pid, meta_id) < amount:
            raise ApiError(E_PROP_NOT_ENOUGH)
        total += _int(meta, 'sellPrice') * amount

    with api.db.tx():
        for meta_id, amount in want.items():
            api.repos.asset.add_prop(pid, meta_id, -amount)

    rewards = [{'itemType': G.RE_COIN, 'amount': total}] if total else []
    return OK, {'rewards': _grant(api, pid, rewards, 'sellProps')}


# ================================================================ 碎片合成
@endpoint('synthetizeCard')
def h_synthetize_card(api, params):
    """将魂（卡牌碎片）合成整卡。

    客户端：FragmentCardListPanel:461 → params = { metaId = <碎片配置id> }
        （FragmentSynthetizeCardRequest，onSuccess 读 `event.data.rewards`）
    碎片映射表：card_fragment_meta[碎片id] = {cardId: 目标卡, amount: 需要几个}

    失败码（客户端分支见 :430-437）：710516 背包满 / 713600 碎片不够；
    其它走通用错误弹窗。所以"碎片不够"必须回 713600，骂人不要骂错。
    """
    pid = _pid(api)
    frag_id = _int(params, 'metaId')
    frag = _at(_raw('card_fragment_meta'), frag_id)
    if not frag:
        # 客户端只会传自己碎片列表里的 metaId，走到这里说明参数就是错的。
        # 不能回 200：onSuccess 会无条件播"合成成功"动画并在本地扣碎片。
        raise ApiError(E_CARD_NOT_CONFIGED)
    need = _int(frag, 'amount')
    card_meta_id = _int(frag, 'cardId')
    if need <= 0 or not G.card_meta_exists(card_meta_id):
        raise ApiError(E_CARD_NOT_CONFIGED)

    have = 0
    for row in api.repos.asset.fragments(pid, G.FRAG_CARD):
        if int(row['meta_id']) == frag_id:
            have = int(row['amount'])
            break
    if have < need:
        raise ApiError(E_CARD_FRAGMENT_NOT_ENOUGH)

    with api.db.tx():
        api.repos.asset.add_fragment(pid, G.FRAG_CARD, frag_id, -need)
        applied = _grant(api, pid, [{'itemType': G.RE_CARD, 'metaId': card_meta_id,
                                     'amount': 1, 'level': 1, 'exp': 0}], 'synthetizeCard')
    return OK, {'rewards': applied}


@endpoint('synthetizeEquip')
def h_synthetize_equip(api, params):
    """器魂（装备碎片）合成整件装备。与 synthetizeCard 完全同构。

    客户端：FragmentEquipListPanel:409 → params = { metaId = <器魂配置id> }
    映射表：equip_fragment_meta[碎片id] = {equipId: 目标装备, amount: 需要几个}
    失败码：713601 碎片不够（:383）。
    """
    pid = _pid(api)
    frag_id = _int(params, 'metaId')
    frag = _at(_raw('equip_fragment_meta'), frag_id)
    if not frag:
        raise ApiError(E_CARD_NOT_CONFIGED)
    need = _int(frag, 'amount')
    equip_meta_id = _int(frag, 'equipId')
    if need <= 0 or not equip_meta_id:
        raise ApiError(E_CARD_NOT_CONFIGED)

    have = 0
    for row in api.repos.asset.fragments(pid, G.FRAG_EQUIP):
        if int(row['meta_id']) == frag_id:
            have = int(row['amount'])
            break
    if have < need:
        raise ApiError(E_EQUIP_FRAGMENT_NOT_ENOUGH)

    with api.db.tx():
        api.repos.asset.add_fragment(pid, G.FRAG_EQUIP, frag_id, -need)
        applied = _grant(api, pid, [{'itemType': G.RE_EQUIP, 'metaId': equip_meta_id,
                                     'amount': 1, 'level': 1, 'exp': 0}], 'synthetizeEquip')
    return OK, {'rewards': applied}


# ================================================================ 技能升级 / 进化
@endpoint('upgradeSkill')
def h_upgrade_skill(api, params):
    """技能升级（吃技能书，有成功率）与技能进化（吃配置材料，必定成功）**共用**一个端点。

    客户端两处调用，参数只差一个 skillBooks：
      SkillUpgradeScene:857（技能升级，玩家自选技能书）
          params = { cardId, skillId, skillBooks = [技能书metaId, ...] }  ← 最多 5 本
          onSuccess 读 `e.data.cardSkill.skillId`（:779）：和旧 skillId 不同=成功。
          概率：Σ(书数×prop_meta.book.effectValue) / skill_meta[skillId].upgradeValue，
          面板自己也算同一个公式（:196-216），所以服务端必须用同一套。
      SkillEvolveScene:364（技能进化），params = { cardId, skillId }（无 skillBooks）
          成功后客户端直接把 skillId 当 +1 处理（:332 `self.skillId + 1`），必定成功。

    两种情况都是"扣银币 + 扣材料，成功则 skillId 变成 skillId+1"，
    所以这里合并成一条实现：有 skillBooks 走概率，没有就按 skill_meta 配置扣材料。

    ⚠️ 客户端 Upgrade_Finished 里扣银币/扣技能书是**无条件**执行的（:755-777），
       所以失败（概率没中）也必须真的扣掉，只是 skillId 不变。
    """
    pid = _pid(api)
    card_id = _int(params, 'cardId') or _int(params, 'masterId')
    skill_id = _int(params, 'skillId')
    books = [int(x) for x in api.int_list_param(params, 'skillBooks')]

    card = api.repos.asset.card(pid, card_id)
    if card is None:
        raise ApiError(E_CARD_NOT_EXIST)
    if int(card['is_locked']):
        raise ApiError(E_CARD_LOCKED)

    cur = None
    skills = api.repos.asset.card_skills(card_id)
    for row in skills:
        if int(row['skill_id']) == skill_id:
            cur = row
            break
    if cur is None:
        raise ApiError(E_COMMON)                     # 这张卡没有这个技能

    cur_meta = _skill_row(skill_id)
    if not cur_meta:
        raise ApiError(E_COMMON)
    group_id = _int(cur_meta, 'skillGroupId')
    cur_level = _int(cur_meta, 'level', 1)
    next_meta = _skill_row(skill_id + 1)

    # 满级判定：同组技能没有下一级，或者下一级跨组（配置里组末尾就是最高级）
    if (not next_meta or _int(next_meta, 'skillGroupId') != group_id
            or _int(next_meta, 'level') <= cur_level
            or cur_level >= _skill_max_level(group_id)):
        raise ApiError(E_SKILL_MAX_LEVEL)

    # 主公等级门槛：要升到 cur_level+1 需要主公等级 >= cur_level*10
    # （客户端 :831 把 curLevel*10 拼进提示文案，就是这个数）
    if int(api.require_player()['level']) < cur_level * 10:
        raise ApiError(E_SKILL_LEVEL_LIMIT)

    coin_cost = _int(cur_meta, 'coin')

    # ---- 材料 ----
    cost_props = {}                                  # {propMetaId: 数量}
    if books:
        if len(books) > 5:
            raise ApiError(E_SKILL_BOOKS_TOO_MANY)
        score = 0.0
        for meta_id in books:
            meta = G.prop_meta(meta_id) or {}
            if _int(meta, 'effectType') != 8:        # effectType==8 才是技能书
                raise ApiError(E_SKILL_NOT_BOOK)
            cost_props[meta_id] = cost_props.get(meta_id, 0) + 1
            score += float(meta.get('effectValue') or 0)
        need_score = float(cur_meta.get('upgradeValue') or 0)
        probability = 1.0 if need_score <= 0 else min(1.0, score / need_score)
    else:
        # 进化：材料由 skill_meta 直接指定（SkillEvolveScene:refreshItems 读的
        # 就是 skill_meta[skillId].propId1..5 / propAmount1..5）
        for i in range(1, 6):
            meta_id = _int(cur_meta, 'propId%d' % i)
            amount = _int(cur_meta, 'propAmount%d' % i)
            if meta_id and amount:
                cost_props[meta_id] = cost_props.get(meta_id, 0) + amount
        probability = 1.0

    player = api.require_player()
    if coin_cost and int(player['gold']) < coin_cost:
        raise ApiError(E_COIN_NOT_ENOUGH)
    for meta_id, amount in cost_props.items():
        if api.repos.asset.prop(pid, meta_id) < amount:
            raise ApiError(E_PROP_NOT_ENOUGH)

    upgrade = random.random() < probability
    new_skill_id = skill_id
    with api.db.tx():
        if coin_cost:
            api.repos.player.add_currency(pid, 'gold', -coin_cost)
        for meta_id, amount in cost_props.items():
            api.repos.asset.add_prop(pid, meta_id, -amount)
        if upgrade:
            # 同组 +1：只改 skill_id / curr_quality / skill_type，
            # card_group_ids 这些"缘分白名单"来自卡牌配置，同组不变。
            new_skill_id = skill_id + 1
            with api.db.tx() as con:
                con.execute(
                    "UPDATE player_card_skill SET skill_id=?, curr_quality=?, skill_type=?"
                    " WHERE card_id=? AND slot=?",
                    (new_skill_id, _int(next_meta, 'quality'),
                     _int(next_meta, 'skillType'), int(card_id), _int(cur, 'slot')))

    row = None
    for item in api.repos.asset.card_skills(card_id):
        if int(item['slot']) == _int(cur, 'slot'):
            row = item
            break
    return OK, {'cardSkill': _skill_payload(row or cur),
                'upgradeSuccess': bool(upgrade)}


# ================================================================ 重生 / 祭炼
@endpoint('rebirthItem')
def h_rebirth_item(api, params):
    """武将重生：把一张卡洗回 1 级，返还培养成本。

    客户端：CardRebirthScene:1176（重生页 → 确认）
        params = { resourceType = ResourceEnum.CARD(5), resourceId = cardId }
        （客户端目前只用 CARD 这一种，装备/宝物重生走别的请求类）
    回包：`rewards` —— :1144 用它弹奖励面板并 `RewardManager:getReward`。

    规则与客户端预览面板**完全同源**（CardRebirthScene:getRebirthReward，:829-880）：
        返还 = 累计经验 → 武将经验(GENERALEXP)
             + 累计经验×cardUpgradeCoinRevise + 已升过级的每一级技能银币 → 金币
             + used_potential×rebirthSoulstoneReturnRate 个潜能石(pydMetaId)
             + 每条技能升过的每一级按 rebirthSkillBookReturnRate 折算成技能书
    消耗：card_rare[rare].rebirthCost 钻（客户端自己也会扣一遍显示）
    """
    pid = _pid(api)
    resource_type = _int(params, 'resourceType')
    resource_id = _int(params, 'resourceId') or _int(params, 'cardId')
    if resource_type and resource_type != G.RE_CARD:
        # 装备/宝物重生客户端没有走这个端点，收到就说明是脏参数
        raise ApiError(E_COMMON)

    card = api.repos.asset.card(pid, resource_id)
    if card is None:
        raise ApiError(E_CARD_NOT_EXIST)
    if int(card['is_locked']):
        raise ApiError(E_CARD_LOCKED)

    meta_id = int(card['meta_id'])
    rare = _card_rare(meta_id)
    rare_cfg = _at(_raw('card_rare'), rare) or {}
    gem_cost = _int(rare_cfg, 'rebirthCost')

    game_setting = _game_setting()
    rebirth_cfg = game_setting.get('rebirthConfig') or {}
    soul_rate = float(rebirth_cfg.get('rebirthSoulstoneReturnRate') or 0)
    book_rate = float(rebirth_cfg.get('rebirthSkillBookReturnRate') or 0)
    book_max = _int(rebirth_cfg, 'rebirthSkillBookMaxValue', 0)
    coin_revise = float(game_setting.get('cardUpgradeCoinRevise') or 1)
    train_cfg = game_setting.get('cardTrainConfig') or {}
    soul_prop = _int(train_cfg, 'pydMetaId', 400010)

    # ---- 返还清单（必须在重置之前算，重置会把 level/exp/技能都清掉）----
    level_cfg = G.card_level_row(int(card['level'])) or {}
    total_exp = _int(level_cfg, 'totalExp') + int(card['exp'] or 0)
    rewards = []
    coin = 0
    if total_exp > 0:
        rewards.append({'itemType': G.RE_GENERAL_EXP, 'metaId': 0, 'amount': total_exp})
        coin += int(total_exp * coin_revise)

    soul_stone = int(int(card['used_potential'] or 0) * soul_rate)
    if soul_stone > 0:
        rewards.append({'itemType': G.RE_PROP, 'metaId': soul_prop, 'amount': soul_stone})

    # 技能书退还：把每条升过的技能等级折成"升级值"，再按从大到小的书去凑
    books = [row for row in _rows('prop_meta')
             if isinstance(row, dict) and _int(row, 'effectType') == 8
             and float(row.get('effectValue') or 0) <= book_max]
    books.sort(key=lambda r: float(r.get('effectValue') or 0), reverse=True)
    book_num = [0] * len(books)
    owned_skills = _card_skills_map(api, pid).get(int(resource_id), set())
    for skill_id in sorted(owned_skills):
        skill_meta = _skill_row(skill_id)
        if not skill_meta or _int(skill_meta, 'level', 1) <= 1:
            continue
        group_id = _int(skill_meta, 'skillGroupId')
        need_level = _int(skill_meta, 'level', 1)
        # 同组里所有低于当前等级的技能各退一次（客户端也是这么遍历的，:864-880）
        below = sorted((row for row in _rows('skill_meta')
                        if isinstance(row, dict) and _int(row, 'skillGroupId') == group_id
                        and 0 < _int(row, 'level') < need_level),
                       key=lambda r: _int(r, 'level'))
        for low in below[:max(0, need_level - 1)]:
            coin += _int(low, 'coin')
            value = int(_int(low, 'upgradeValue') * book_rate)
            for i, book in enumerate(books):
                book_value = int(float(book.get('effectValue') or 0))
                if book_value <= 0 or value < book_value:
                    continue
                num = value // book_value
                value -= num * book_value
                book_num[i] += num
    for i, book in enumerate(books):
        if book_num[i]:
            rewards.append({'itemType': G.RE_PROP, 'metaId': _int(book, 'id'),
                            'amount': book_num[i]})
    if coin > 0:
        rewards.insert(0, {'itemType': G.RE_COIN, 'metaId': 0, 'amount': coin})

    # ---- 扣钻 + 重置 + 返还（同一个事务，失败一起回滚）----
    if gem_cost and int(api.require_player()['gem'] or 0) < gem_cost:
        raise ApiError(E_GEM_NOT_ENOUGH)
    with api.db.tx():
        if gem_cost and api.ctx.player.spend_gems(pid, gem_cost) is None:
            raise ApiError(E_GEM_NOT_ENOUGH)
        api.repos.asset.update_card(
            pid, resource_id, level=1, exp=0, used_potential=0,
            att_train_value=0, def_train_value=0, hp_train_value=0)
        # 等级回到 1 级，技能也要重建成 1 级技能的配置（客户端 :1155 也是用
        # generateCard(0, metaId, 1, 0).cardSkills 覆盖本地的）
        api.repos.asset.replace_card_skills(int(resource_id), G.build_card_skills(meta_id))
        applied = _grant(api, pid, rewards, 'rebirthItem')
    return OK, {'rewards': applied, 'cardId': int(resource_id)}


@endpoint('sacrificeItem')
def h_sacrifice_item(api, params):
    """祭炼：把「武将 / 装备 / 宝物」直接熔了换资源。

    客户端：CardRebirthScene:1336（祭炼页 → 确认）
        params = { resourceType, resourceIds = [id, ...] }
        resourceType: 5=CARD / 6=EQUIP / 27=TREASURE
    回包：`rewards` —— :1206-1214 拿它排序后弹奖励面板 + `RewardManager:getReward`。
        ⚠️ 客户端会 `table.sort(e.data.rewards, ...)`，所以 rewards 必须是**数组**，
        不能是 nil（空数组可以）。

    产出按客户端预览同一套公式（同文件 :910-1010 getSacrificeReward）：
        武将 -> 星灵(Σ card_meta.astralEssence)
        装备 -> 灵值 + 银币 + 进化材料（按 equip_evolve / equip_level 折算）
        宝物 -> 宝物碎片(Σ treasure_meta.astralEssence)

    安全：会**删资源**，所以先把整批 id 校验完（属于我 / 没上阵 / 没锁）再删。
    """
    pid = _pid(api)
    resource_type = _int(params, 'resourceType')
    ids = [int(x) for x in api.int_list_param(params, 'resourceIds')]
    if not ids:
        # 没选东西：什么都不删，成功返回空数组（客户端弹一个空奖励面板，无害）
        return OK, {'rewards': []}

    game_setting = _game_setting()
    material_rate = float(game_setting.get('equipSpiritMaterial') or 1) / 1000.0
    silver_rate = float(game_setting.get('equipSpiritSilver') or 1) / 1000.0
    equip_evolve = _index('equip_evolve', 'equipId')
    equip_level = _index('equip_level', 'level')

    rewards, coin = [], 0
    props = {}                                        # {propMetaId: 数量}

    if resource_type in (0, G.RE_CARD):
        holder = api.repos.asset.card_holder_ids(pid)
        cards = []
        for card_id in ids:
            card = api.repos.asset.card(pid, card_id)
            if card is None:
                raise ApiError(E_CARD_NOT_EXIST)
            if int(card_id) in holder:
                raise ApiError(E_CARD_IN_QUEUE)       # 上阵/穿戴中，不许熔
            if int(card['is_locked']):
                raise ApiError(E_CARD_LOCKED)
            cards.append(dict(card))
        for card in cards:
            row = _card_meta_raw(int(card['meta_id'])) or {}
            astral = _int(row, 'astralEssence')
            if astral:
                rewards.append({'itemType': G.RE_ASTRAL_ESSENCE, 'amount': astral})
        with api.db.tx():
            for card in cards:
                api.repos.asset.delete_card(pid, int(card['card_id']))
            applied = _grant(api, pid, rewards, 'sacrificeCard')

    elif resource_type == G.RE_EQUIP:
        equips = []
        for equip_id in ids:
            equip = api.repos.asset.equip(pid, equip_id)
            if equip is None:
                raise ApiError(E_EQUIP_NOT_EXIST)
            equips.append(dict(equip))
        for equip in equips:
            meta_id = int(equip['meta_id'])
            meta = _at(_raw('equip_meta'), meta_id) or {}
            # ① 强化花掉的银币
            spent = 0
            for level in range(1, int(equip['level'])):
                level_row = _at(equip_level, level) or {}
                spent += int(float(meta.get('coinConsumeCoe') or 0)
                             * float(level_row.get('upgradeCoinBase') or 0))
            # ② 进化花掉的银币 + 材料（metaId 末位就是进化阶数）
            evolve_coin = 0
            prefix, step = meta_id // 10, meta_id % 10
            for i in range(1, step):
                evolve = _at(equip_evolve, prefix * 10 + i)
                if not evolve:
                    continue
                evolve_coin += _int(evolve, 'coins')
                for j in range(1, 6):
                    prop_id = _int(evolve, 'propId%d' % j)
                    amount = _int(evolve, 'propAmount%d' % j)
                    if not prop_id or not amount:
                        continue
                    if j == 1:
                        add_amount = amount
                    else:
                        add_amount = int(float(amount) * material_rate)
                    props[prop_id] = props.get(prop_id, 0) + add_amount
            coin += int((spent + evolve_coin) * silver_rate)
        # ⚠️ 客户端预览里还有一项「灵值」(ResourceEnum.ENCHANT_POINT=26) ——
        #   那是"装备附灵投入"的折算值。灵值在数据模型里只存在于某件装备上
        #   （reward.grant 处理 26 时需要 rw['id'] 指向装备），而这里的装备马上就要
        #   被删掉，没有载体可挂，所以服务端**不产出**这一项。
        #   结果面板用的是回包 rewards（不是预览），所以两边仍然自洽。
        if coin > 0:
            rewards.append({'itemType': G.RE_COIN, 'amount': coin})
        for prop_id, amount in props.items():
            if amount > 0:
                rewards.append({'itemType': G.RE_PROP, 'metaId': prop_id,
                                'amount': amount})
        with api.db.tx():
            for equip in equips:
                api.repos.asset.delete_equip(pid, int(equip['equip_id']))
            applied = _grant(api, pid, rewards, 'sacrificeEquip')

    elif resource_type == G.RE_TREASURE:
        treasures = []
        for treasure_id in ids:
            treasure = api.repos.asset.treasure(pid, treasure_id)
            if treasure is None:
                raise ApiError(E_COMMON)
            treasures.append(dict(treasure))
        for treasure in treasures:
            row = _at(_raw('treasure_meta'), int(treasure['meta_id'])) or {}
            astral = _int(row, 'astralEssence')
            if astral:
                rewards.append({'itemType': G.RE_TREASURE_FRAGMENT, 'amount': astral})
        with api.db.tx():
            for treasure in treasures:
                api.repos.asset.delete_treasure(pid, int(treasure['treasure_id']))
            applied = _grant(api, pid, rewards, 'sacrificeTreasure')

    else:
        raise ApiError(E_COMMON)

    return OK, {'rewards': applied}


# ================================================================ 抽卡：扭蛋盒
_BOX_SLOTS = 12          # 盒子格子数（客户端不关心总数，只按数组长度显示 x/12）


@endpoint('gachaCardByBox')
def h_gacha_card_by_box(api, params):
    """扭蛋盒（活动 activityBoxGacha）：一批固定卡片，每花钻抽走一张。

    客户端：GachaScene:566（活动页 → "抽取"按钮）
        params = nil（RequestNotifyClass 直接 sendRequest(nil, ...)）
    回包：`rewards` —— :524-537 只读 `response.data.rewards[1].id`（要和本地
        gachaBoxCard 里的槽位 id 对上）和 `response.data.rewards[1].reward`（真正的
        奖励）。所以第一项必须是 `{id=<槽位id>, reward=<reward>}`。

    消耗：activityGachaBoxConfig.requisites[1].amount 钻石（客户端自己也会扣一遍）。
    盒子状态由本模块的 player_gacha_box 维护（见 _ensure_tables 注释）。
    """
    _ensure_tables(api)
    pid = _pid(api)
    cfg = _meta_cfg('activityGachaBoxConfig')
    requisites = cfg.get('requisites') or []
    cost = _int(requisites[0] if requisites else {}, 'amount')
    cost_type = _int(requisites[0] if requisites else {}, 'itemType', G.RE_GEMS)

    slots = [dict(row) for row in api.db.all(
        "SELECT * FROM player_gacha_box WHERE player_id=? ORDER BY slot_id", (pid,))]
    undrawn = [row for row in slots if not int(row['is_drawn'])]
    if not undrawn:
        # 抽完了（或第一次来）：从活动抽卡池（gacha_card id=4）重新铺一批。
        # 盒子里必须**恰好有一个** special 槽：客户端 refreshUI2 会直接读
        # `self.gachaSpecialCard.cardStatus`（GachaScene:428），没有 special 槽
        # 就会 nil 索引 → SIGKILL。
        pool = G.roll_gacha(4, _BOX_SLOTS)
        now = int(time.time())
        with api.db.tx() as con:
            con.execute("DELETE FROM player_gacha_box WHERE player_id=?", (pid,))
            for i, reward in enumerate(pool, 1):
                con.execute(
                    "INSERT INTO player_gacha_box(player_id, slot_id, card_id,"
                    " is_special, is_drawn, create_time) VALUES (?,?,?,?,0,?)",
                    (pid, i, int(reward.get('metaId') or 0),
                     1 if i == len(pool) else 0, now))
        slots = [dict(row) for row in api.db.all(
            "SELECT * FROM player_gacha_box WHERE player_id=? ORDER BY slot_id", (pid,))]
        undrawn = [row for row in slots if not int(row['is_drawn'])]

    slot = undrawn[0]
    spec = {'itemType': G.RE_CARD, 'metaId': int(slot['card_id']),
            'amount': 1, 'level': 1, 'exp': 0}
    # 扣费 + 发卡 + 标记槽位放在同一个事务里：任何一步失败都不会出现
    # "钻石扣了但卡没发"或"卡发了槽位还能再抽"。
    with api.db.tx():
        if cost:
            if cost_type == G.RE_GEMS:
                if api.ctx.player.spend_gems(pid, cost) is None:
                    raise ApiError(E_GEM_NOT_ENOUGH)
            elif cost_type == G.RE_COIN:
                if int(api.require_player()['gold']) < cost:
                    raise ApiError(E_COIN_NOT_ENOUGH)
                api.repos.player.add_currency(pid, 'gold', -cost)
            else:
                raise ApiError(E_COMMON)
        applied = _grant(api, pid, [spec], 'gachaCardByBox')
        with api.db.tx() as con:
            con.execute("UPDATE player_gacha_box SET is_drawn=1 WHERE player_id=?"
                        " AND slot_id=?", (pid, int(slot['slot_id'])))
    reward = applied[0] if applied else spec
    return OK, {'rewards': [{'id': int(slot['slot_id']),
                             'cardId': int(slot['card_id']),
                             'special': bool(int(slot['is_special'])),
                             'reward': reward}]}


# ================================================================ 活动兑换
def _exchange_meta_list(cfg):
    metas = cfg.get('cardExchangeMeta') or []
    return [row for row in metas if isinstance(row, dict)]


def _find_exchange(metas, key, value):
    for row in metas:
        if _int(row, key) == int(value):
            return row
    return None


def _do_card_exchange(api, pid, target_row, material_ids, cfg, times_key):
    """以旧换新 / 易帅换将的公共实现。

    客户端 CardOldToNewExchangeScene:344-360 `getNeedEssence` 的规则（照抄）：
      需要星灵 = exchangeMeta.secretNum - Σ材料卡的 astralEssence
                 （同名卡组按 oldCardRatio 放大材料卡的星灵）→ 下限 0
      兑换次数上限 exchangeMeta.exchangeNum（前端用 Activity_*Layer.addCurrentExchangeNum
      本地累加，服务端必须自己记账，否则刷新页面就能无限兑换）
    回包键是单数 `reward`（请求类 onSucceedDefault:80
    `RewardManager:getReward(event.data.reward)`），顺手也给一份 `rewards`。
    """
    holder = api.repos.asset.card_holder_ids(pid)
    target_meta = _int(target_row, 'cardId')
    if not material_ids:
        raise ApiError(E_EXCHANGE_NO_MATERIAL)

    old_ratio = float(cfg.get('oldCardRatio') or 1)
    target_group = _int(_card_meta_raw(target_meta) or {}, 'cardGroupId')
    total_astral = 0
    materials = []
    for card_id in material_ids:
        card = api.repos.asset.card(pid, card_id)
        if card is None:
            raise ApiError(E_CARD_NOT_EXIST)
        if int(card_id) in holder:
            raise ApiError(E_CARD_IN_QUEUE)           # 上阵/穿戴中的卡不能当材料
        if int(card['is_locked']):
            raise ApiError(E_CARD_LOCKED)
        meta = _card_meta_raw(int(card['meta_id'])) or {}
        if _int(meta, 'evolutionLevel', 1) > 1:
            raise ApiError(E_EXCHANGE_MATERIAL_REBORN)  # 转生过的卡不能当材料
        astral = _int(meta, 'astralEssence')
        if target_group and _int(meta, 'cardGroupId') == target_group:
            astral = int(astral * old_ratio)          # 同名卡（缘分卡）折得多
        total_astral += astral
        materials.append(dict(card))

    need_essence = max(0, _int(target_row, 'secretNum') - total_astral)
    limit = _int(target_row, 'exchangeNum')
    if limit and api.repos.player.counter(pid, times_key) >= limit:
        raise ApiError(E_EXCHANGE_TIMES_OUT)
    if need_essence and int(api.require_player()['astral_essence'] or 0) < need_essence:
        raise ApiError(E_ASTRAL_ESSENCE_NOT_ENOUGH)

    with api.db.tx():
        if need_essence:
            api.repos.player.add_currency(pid, 'astral_essence', -need_essence)
        for card in materials:
            api.repos.asset.delete_card(pid, int(card['card_id']))
        applied = _grant(api, pid, [{'itemType': G.RE_CARD, 'metaId': target_meta,
                                     'amount': 1, 'level': 1, 'exp': 0}],
                         'exchangeCard')
        api.repos.player.bump_counter(pid, times_key, 1)
    return applied


@endpoint('exchangeCard')
def h_exchange_card(api, params):
    """卡牌以旧换新（活动 activityCardExchange）。

    客户端：CardOldToNewExchangeScene:96
        params = { shopId = <cardExchangeMeta.id>, cardId = [材料卡 cardId...] }
        （needEssence 只在前端算，不传给服务端）
    回包：`reward`（单数）—— CardOldToNewExchangeRequest:80。

    ⚠️ 本服 getMeta 下发的 activityCardExchangeConfig.cardExchangeMeta 是**空表**
       （configs/activity_card_exchange 这类配置本来就没随包下发），所以活动入口
       在前端根本开不出来，真到了这里就是"活动没开" → 714700。客户端
       onFailedDefault:88 收到 714700 会直接退回主界面，不会卡死。
       配置一旦补齐（meta_payload 那边），下面的逻辑不用改就能用。
    """
    pid = _pid(api)
    cfg = _meta_cfg('activityCardExchangeConfig')
    metas = _exchange_meta_list(cfg)
    if not metas:
        raise ApiError(E_EXCHANGE_CLOSED)

    shop_id = _int(params, 'shopId')
    target = _find_exchange(metas, 'id', shop_id)
    if not target:
        raise ApiError(E_EXCHANGE_CLOSED)
    if not G.card_meta_exists(_int(target, 'cardId')):
        raise ApiError(E_CARD_NOT_CONFIGED)

    material_ids = [int(x) for x in api.int_list_param(params, 'cardId')]
    applied = _do_card_exchange(api, pid, target, material_ids, cfg,
                               'card_exchange_%d' % shop_id)
    return OK, {'reward': applied, 'rewards': applied}


@endpoint('exchangeCardDaily')
def h_exchange_card_daily(api, params):
    """易帅换将（活动 exchangeDaily，每天刷一批可兑换的卡）。

    客户端：CardOldToNewExchangeScene:92 → ActivityexchangeCardDailyRequest:38
        params = { metaId = <目标卡 cardId>, cardId = [材料卡 cardId...] }
        （注意：这个接口传的是**目标卡 metaId**，不是 exchangeId）
    回包：`reward`（单数）—— ActivityexchangeCardDailyRequest:76。

    配置 exchangeDailyConfig 里目前没有 cardExchangeMeta（只有 featureName），
    所以同样按"活动没开"拒绝（714700）。
    """
    pid = _pid(api)
    cfg = _meta_cfg('exchangeDailyConfig')
    if not _exchange_meta_list(cfg):
        raise ApiError(E_EXCHANGE_CLOSED)

    target_meta = _int(params, 'metaId')
    if not G.card_meta_exists(target_meta):
        raise ApiError(E_CARD_NOT_CONFIGED)
    target = _find_exchange(_exchange_meta_list(cfg), 'cardId', target_meta)
    material_ids = [int(x) for x in api.int_list_param(params, 'cardId')]
    applied = _do_card_exchange(api, pid, target, material_ids, cfg,
                               'card_exchange_daily_%d' % target_meta)
    return OK, {'reward': applied, 'rewards': applied}


@endpoint('exchangeItem')
def h_exchange_item(api, params):
    """悬赏商店兑换（活动 activityWanted 的兑换页）。

    客户端：WantedActivityShopPanel:261
        params = { itemId = <wantedShopConfig.items[].id> }
    回包：`rewards` —— :234 `RewardManager:getReward(e.data.rewards)`，同时弹奖励面板。
    价格/产出全部来自 wantedShopConfig.items 一行：
        costID/costNum = 花掉的勋章道具，propType/propID/propNum = 换到的东西。
    """
    pid = _pid(api)
    cfg = _meta_cfg('wantedShopConfig')
    items = [row for row in (cfg.get('items') or []) if isinstance(row, dict)]
    item_id = _int(params, 'itemId')
    row = None
    for candidate in items:
        if _int(candidate, 'id') == item_id:
            row = candidate
            break
    if row is None:
        # 客户端只会传自己列表里的 id，走到这里就是脏参数。不能回 200：
        # onSuccess 会无条件在本地扣掉 costNum 个勋章。
        raise ApiError(E_COMMON)

    cost_id = _int(row, 'costID')
    cost_num = _int(row, 'costNum')
    if cost_num > 0 and api.repos.asset.prop(pid, cost_id) < cost_num:
        raise ApiError(E_PROP_NOT_ENOUGH)

    reward = {'itemType': _int(row, 'propType'), 'metaId': _int(row, 'propID'),
              'amount': _int(row, 'propNum')}
    if reward['itemType'] == G.RE_CARD:
        reward.update({'level': 1, 'exp': 0})
    with api.db.tx():
        if cost_num > 0:
            api.repos.asset.add_prop(pid, cost_id, -cost_num)
        applied = _grant(api, pid, [reward], 'exchangeItem')
    return OK, {'rewards': applied}


# ================================================================ 精英关扫荡
@endpoint('clearElite')
def h_clear_elite(api, params):
    """精英关扫荡（精英关卡 → 扫荡）。

    客户端：EliteSweepConfirmPopmPanel:144
        params = { eliteId = <elite_setting.id> }
        （轮数 rounds 只在前端算，**不传**给服务端：客户端 = min(maxRounds,
          maxChallengesPerDay - 已挑战数, 体力/每轮消耗)，服务端要自己用同一套规则重算，
          否则客户端显示扫 3 轮、服务端只给 1 轮，两边体力就对不上了。）
    回包（EliteSweepRequest.onSucceedDefault:79-119）四个键缺一不可：
        lastEnergy   -> RewardManager.setEnergy(event.data.lastEnergy)
        mergeRewards -> RewardManager:getReward(event.data.mergeRewards)
        rewards      -> 每轮 `{round=i, rewards=[...]}`，SweepResultPanel 逐轮展示
        challengeNum -> event.eilteMissionInfo.challengeNum = event.data.challengeNum
    """
    pid = _pid(api)
    elite_id = _int(params, 'eliteId')
    cfg = _index('elite_setting').get(elite_id)
    if not cfg:
        raise ApiError(E_MISSION_NOT_EXIST)

    elite_cfg = _game_setting().get('eliteConfig') or {}
    # 客户端 EliteManager.getEliteSetting() 读的就是 gameSettingConfig.eliteConfig；
    # 本服 getMeta 里那张表是空占位（canon_server 里写死的 {}），所以这里用客户端
    # 源码注释里记录的原值 5 兜底（EliteManager.lua:255）。
    per_round_energy = _int(elite_cfg, 'eliteConsumeEnergy', 5) or 5
    max_rounds = _int(_battle_setting().get('clearMissionConfig') or {}, 'maxRounds', 3) or 3
    per_day = _int(cfg, 'maxChallengesPerDay', 99) or 99

    counter_key = 'elite_challenge_%d' % elite_id
    done = _daily(api, pid, counter_key)
    remain = max(0, per_day - done)
    energy = int(api.require_player()['energy'] or 0)
    rounds = min(max_rounds, remain, energy // per_round_energy)
    if rounds <= 0:
        # 体力不够 / 今日次数用完，客户端都走同一个"补充体力"面板
        raise ApiError(E_ENERGY_NOT_ENOUGH)

    drop_packs = []
    for i in range(1, 5):
        pack_id = _int(cfg, 'dropPackId%d' % i)
        prob = float(cfg.get('dropPackProb%d' % i) or 0)
        if pack_id and prob > 0:
            drop_packs.append((pack_id, prob))

    base_rewards = [{'itemType': G.RE_EXP, 'amount': _int(cfg, 'exp')},
                    {'itemType': G.RE_COIN, 'amount': _int(cfg, 'coin')}]

    rounds_payload, merged = [], []
    energy_cost = per_round_energy * rounds
    with api.db.tx():
        api.repos.player.add_currency(pid, 'energy', -energy_cost)
        for index in range(rounds):
            one = [dict(rw) for rw in base_rewards if int(rw['amount']) > 0]
            one += G.roll_drop_packs(drop_packs) if drop_packs else []
            applied = _grant(api, pid, one, 'clearElite')
            rounds_payload.append({'round': index + 1, 'rewards': applied})
            merged += applied
        new_count = _bump_daily(api, pid, counter_key, rounds)
        api.repos.progress.set_max_finished_elite(pid, elite_id)

    last_energy = int(api.require_player()['energy'] or 0)
    return OK, {'lastEnergy': last_energy,
                'rewards': rounds_payload,
                'mergeRewards': _merge(merged),
                'challengeNum': int(new_count)}


# ================================================================ 争霸 / 切磋 / 秘境
@endpoint('challengeContend')
def h_challenge_contend(api, params):
    """争霸（活动 activityContend，"为情而战"）。

    客户端：Activity_ContendLayer:203-243
        params = { contendId = <1..4> }   （4 个对手位，见 getTableData :78）
    回包：整包直接喂给 BattleScene:create(requestEvent.data, kActivityContend, ...)，
        所以**必须是完整的战斗结算包**（win / cardInitDatas / eventFlow / rewards …），
        少一个键 BattleScene 就崩。

    次数：activityContendConfig.challengedNum（每个对手每天）+ dayDareNum（每天总量）。
    产出：activity_contend_fragment.lua 里按 contendId 分组的碎片 id，
        赢了给 1 个（card_fragment，ResourceEnum.CARD_FRAGMENT=17）。

    ⚠️ 活动专属的怪物组没有随包下发，敌人用第一章的怪物组占位（战斗过程本来就是
       服务端算、客户端演的，字段契约与普通关卡一致）。
    """
    pid = _pid(api)
    player = api.require_player()
    cfg = _meta_cfg('activityContendConfig')
    level_limit = _int(cfg, 'levelLimit')
    if level_limit and int(player['level']) < level_limit:
        raise ApiError(E_COMMON)

    contend_id = _int(params, 'contendId')
    if contend_id <= 0:
        # 客户端只会点列表里的对手；没 id 就没法确定对手，也就没法算奖励
        raise ApiError(E_COMMON)

    per_target = _int(cfg, 'challengedNum', 2) or 2
    per_day = _int(cfg, 'dayDareNum', 5) or 5
    target_key = 'contend_target_%d' % contend_id
    if _daily(api, pid, target_key) >= per_target:
        raise ApiError(E_COMMON)
    if _daily(api, pid, 'contend_total') >= per_day:
        raise ApiError(E_COMMON)

    group = [row for row in _rows('activity_contend_fragment')
             if isinstance(row, dict) and _int(row, 'id') == contend_id]
    fragment_ids = [_int(row, 'fragmentId') for row in group if _int(row, 'fragmentId')]

    pack = _battle_pack(100101, 1)
    rewards = []
    with api.db.tx():
        _bump_daily(api, pid, target_key, 1)
        _bump_daily(api, pid, 'contend_total', 1)
        if pack.get('win') and fragment_ids:
            rewards = [{'itemType': G.RE_CARD_FRAGMENT,
                        'metaId': random.choice(fragment_ids), 'amount': 1}]
        applied = _grant(api, pid, rewards, 'challengeContend')
    pack['rewards'] = applied
    return OK, pack


@endpoint('challengeFriendList')
def h_challenge_friend_list(api, params):
    """一键切磋（好友列表页的"全部切磋"按钮）。

    客户端：UserDetailPanel:355-381
        params = { friendUids = [uid, ...] }（只传今天还没切磋过的好友）
    回包：`rewards` —— ChallengeFriendListRequest.onSucceedDefault:68
        `RewardManager:getReward(event.data.rewards)` + 把 amount 求和显示
        "共获得 X 点友情点"。所以 rewards 必须是数组（空数组可以）。

    规则：每个好友每天只能切磋一次（服务端用 player_daily_counter 记账，
    不信任客户端传的列表，重复传也只算一次）。
    友情点数值：配置里没有单独下发"切磋奖励"，按每个好友 1 点计（客户端本地
    调试数据 ChallengeFriendListRequest.getDebugDatas 也是用 itemType=8 的友情点）。
    """
    pid = _pid(api)
    uids = [int(x) for x in api.int_list_param(params, 'friendUids')]
    if not uids:
        return OK, {'rewards': []}

    points = 0
    with api.db.tx():
        for uid in uids:
            if uid <= 0 or uid == pid:
                continue
            if not api.repos.social.is_friend(pid, uid):
                continue                              # 不是好友：跳过，不报错
            key = 'fight_friend_%d' % uid
            if _daily(api, pid, key) > 0:
                continue                              # 今天已经切磋过
            _bump_daily(api, pid, key, 1)
            points += 1
        rewards = [{'itemType': G.RE_FRIEND_POINT, 'amount': points}] if points else []
        applied = _grant(api, pid, rewards, 'challengeFriendList')
    return OK, {'rewards': applied}


@endpoint('challengeMysterious')
def h_challenge_mysterious(api, params):
    """秘境挑战（活动 activityMysterious）。

    客户端：MesteriousChanllengePanel:87
        params = { id = <国家id 1..4>, difficultyDegree = <1普通/2折磨/3深层> }
    回包：整包喂给 BattleScene:create(e.data, kMysteriousBattle, ...)，
        所以必须是完整的战斗结算包。

    消耗：eventMysteriousConfig.energyCost **精力**（不是体力），
        每国每天次数上限 eventMysteriousConfig.eventLimit。
    ⚠️ 秘境的掉落表没有随包下发（只有兑换配置 activityMysteriousExchangeConfig），
       所以这里返回**结构完整、产出为空**的结算包：战斗照打、次数/精力照扣，
       rewards 留空，等掉落配置补齐再发神秘币（ResourceEnum.MYSTERIOUS_COINS=30）。
    """
    pid = _pid(api)
    player = api.require_player()
    cfg = _meta_cfg('eventMysteriousConfig')
    country = _int(params, 'id')
    if country <= 0:
        raise ApiError(E_COMMON)
    difficulty = _int(params, 'difficultyDegree', 1) or 1

    limit = _int(cfg, 'eventLimit', 0)
    cost = _int(cfg, 'energyCost', 0)
    key = 'mysterious_%d' % country
    if limit and _daily(api, pid, key) >= limit:
        raise ApiError(E_COMMON)
    if cost and int(player['event_point'] or 0) < cost:
        raise ApiError(E_EVENT_POINT_NOT_ENOUGH)

    pack = _battle_pack(100101, 1)
    with api.db.tx():
        if cost:
            api.repos.player.add_currency(pid, 'event_point', -cost)
        _bump_daily(api, pid, key, 1)
    pack['rewards'] = []
    pack['difficultyDegree'] = difficulty
    return OK, pack


# ================================================================ 圣兽碎片抢夺
_ROB_DAILY_LIMIT = 5        # 单个碎片每天最多抢几次（配置没有下发，按客户端提示卡一个上限）


@endpoint('getRobUserList')
def h_get_rob_user_list(api, params):
    """可抢夺碎片的人列表（圣兽碎片页 → 选人）。

    客户端：RobFragmentScene:555（doPreparationBeforeReplaceToFragmentScene）
        params = { beastFragmentId = <碎片id> }
    回包（RobFragmentScene:refreshSelf:151-188）：
        robUserList  -> [{uid, nickName, level, mainCardId, mainCardMetaId, rank,
                          lastChallengeTime, unionName}]  ★ 缺字段直接 nil 索引
        robRobotList -> [{robotId, nameKey, level, mainCardMetaId}]（机器人）
    两个数组都必须是数组（空数组可以，客户端会显示"暂无可抢玩家"）。

    ⚠️ 机器人表没有随包下发，robRobotList 先给空数组（语义为空，不是假数据）；
       玩家列表是真的：本服其它角色（按等级降序，排除自己）。
    """
    player = api.require_player()
    pid = int(player['player_id'])

    rows = api.db.all(
        "SELECT p.player_id, p.nickname, p.level, p.main_card_id"
        " FROM player p WHERE p.player_id<>? AND p.server_id=?"
        " ORDER BY p.level DESC, p.player_id LIMIT 10",
        (pid, int(player['server_id'])))
    rob_users = []
    for row in rows:
        other_uid = int(row['player_id'])
        main_card_id = int(row['main_card_id'] or 0)
        main_meta_id = 0
        if main_card_id:
            card = api.repos.asset.card(other_uid, main_card_id)
            main_meta_id = int(card['meta_id']) if card else 0
        guild = api.repos.guild.guild_of(other_uid)
        rob_users.append({
            'uid': other_uid,
            'nickName': row['nickname'] or '',
            'level': int(row['level'] or 1),
            'mainCardId': main_card_id,
            'mainCardMetaId': main_meta_id,
            'rank': _arena_rank(api, other_uid),
            'lastChallengeTime': 0,
            'unionName': (guild['name'] if guild else None),
        })
    return OK, {'robUserList': rob_users, 'robRobotList': []}


def _arena_rank(api, player_id):
    """竞技场名次（1 起）。算不出来时返回 -1 —— 客户端 RobFragmentScene 用
    `rank < 0` 显示"未上榜"，返回 0 会显示成第 0 名。"""
    row = api.db.one("SELECT score FROM arena_rank WHERE player_id=?", (int(player_id),))
    if not row:
        return -1
    better = api.db.one("SELECT COUNT(*) AS c FROM arena_rank WHERE score > ?",
                        (int(row['score']),))
    return int(better['c']) + 1 if better else -1


@endpoint('robBeastFragment')
def h_rob_beast_fragment(api, params):
    """抢别人的圣兽碎片。

    客户端：RobFragmentBeforePanel:75 / BattleResultPanel:353
        params = { beastFragmentId, enemyUid, robType(0=玩家 1=机器人), robotId }
    回包：
      * 整包喂 `BattleScene:create(data, ...)`（RobFragmentBeforePanel:56），必须是完整战斗包；
      * `data.rewards` 里只要有 `itemType == BEAST_FRAGMENT(14)` 就算抢成功
        （:45-49 据此决定回哪个场景），所以抢到了必须把这一条放进 rewards。

    消耗：battleSettingConfig.robSettingConfig.robConsumeEventPoints 点精力
        （客户端 :33 也读同一处）；不够回 710515，客户端弹"补充精力"。
    """
    _ensure_tables(api)
    pid = _pid(api)
    robber = api.require_player()

    beast_fragment_id = _int(params, 'beastFragmentId')
    if beast_fragment_id <= 0:
        raise ApiError(E_COMMON)
    if not _at(_raw('beast_fragment'), beast_fragment_id):
        raise ApiError(E_COMMON)
    rob_type = _int(params, 'robType')
    robot_id = _int(params, 'robotId')
    enemy_uid = _int(params, 'enemyUid')

    cost = _int((_battle_setting().get('robSettingConfig') or {}),
                'robConsumeEventPoints', 5)
    if _daily(api, pid, 'beast_rob_%d' % beast_fragment_id) >= _ROB_DAILY_LIMIT:
        raise ApiError(E_BEAST_FRAGMENT_LIMIT)
    if cost and int(robber['event_point'] or 0) < cost:
        raise ApiError(E_EVENT_POINT_NOT_ENOUGH)

    pack = _battle_pack(100101, 1)
    rewards = []
    with api.db.tx():
        if cost:
            api.repos.player.add_currency(pid, 'event_point', -cost)
        _bump_daily(api, pid, 'beast_rob_%d' % beast_fragment_id, 1)
        if pack.get('win'):
            # 抢到的碎片存进本模块自己的表（reward 引擎不支持 itemType=14）
            with api.db.tx() as con:
                con.execute(
                    "INSERT INTO player_beast_fragment(player_id, meta_id, amount)"
                    " VALUES (?,?,1) ON CONFLICT(player_id, meta_id)"
                    " DO UPDATE SET amount = amount + 1", (pid, beast_fragment_id))
            rewards.append({'itemType': G.RE_BEAST_FRAGMENT,
                            'metaId': beast_fragment_id, 'amount': 1})
        applied = _grant(api, pid, rewards, 'robBeastFragment')
    pack['rewards'] = applied
    pack['beastFragmentId'] = beast_fragment_id
    pack['enemyUid'] = enemy_uid
    # 客户端会自己往 data 里补这三个字段再进战斗，这里回显只是为了排查日志对得上
    pack['robType'] = rob_type
    pack['robotId'] = robot_id
    return OK, pack


# ================================================================ 账号 / 杂项
@endpoint('bindAccount')
def h_bind_account(api, params):
    """游客号绑定第三方平台（登录流程里 isNewUser 才会调）。

    客户端：ThirdPlatformLogin:525
        params = { platformId = <平台号>, platformUid = <平台 uid>, sid = <会话 sk> }
    回包：客户端 `bindAccountFinish(timedata)` 只用来打点（算加载耗时），
        所以回时间戳即可；但这里顺手把绑定关系**真的**写进 account_binding
        （`/mappingAccount`、`/check/*` 下次就靠它反查账号）。
        `ts` 是打点用的服务端秒；`platformId/platformUid/bindTime` 方便排查。

    账号来源优先级：会话里的 account_id → 角色自己的 account_id。
    后者是为了让 GM/单机（无会话）调用也能落库，而不是直接报错。
    """
    player = api.require_player()
    account_id = None
    acc = api.ctx.account.account_by_session(api.sk) if api.sk else None
    if acc is not None:
        account_id = int(acc['account_id'])
    else:
        account_id = int(player['account_id'])

    platform_id = str(api.param(params, 'platformId', '') or '').strip()
    platform_uid = str(api.param(params, 'platformUid', '') or '').strip()
    sid = str(api.param(params, 'sid', api.sk) or '')
    now = int(time.time())
    if not platform_id:
        # 客户端没给平台号（例如本地包没有第三方 SDK）：记成 local，
        # 用 account_id 当 uid，保证每个账号有且只有一条 local 绑定。
        platform_id = 'local'
    if not platform_uid:
        platform_uid = str(account_id)

    api.repos.player.bind(account_id, platform_id, platform_uid, sid=sid or None)
    return OK, {'ts': now, 'platformId': platform_id, 'platformUid': platform_uid,
                'bindTime': now}


@endpoint('defaultPhoneNum')
def h_default_phone_num(api, params):
    """话费返还活动：绑定/修改手机号。

    客户端：PhoneChargeBindPopPanel:33（绑定）/ PhoneChargeChangePhoneNumberPopPanel:52（改号）
        params = { phoneNum = "13800138000" }
        前端已经用 Activity_PhoneChargeLayer.isPhoneNumber() 校验过一次格式。
    回包：客户端用 **event.params.phoneNum** 更新本地显示（PhoneChargeSetNumRequest:53-66），
        不读回包字段；这里仍然回 `phoneNum/setNumTime`，方便别处核对。

    落库：phone_charge(player_id, phone_num, set_num_time)。号码格式服务端再校验一遍
    （纯数字、6~20 位），非法直接业务错误，避免脏号码进库。
    """
    pid = _pid(api)
    phone_num = str(api.param(params, 'phoneNum', '') or '').strip()
    if not phone_num.isdigit() or not (6 <= len(phone_num) <= 20):
        raise ApiError(E_COMMON)

    now = int(time.time())
    with api.db.tx() as con:
        con.execute(
            "INSERT INTO phone_charge(player_id, phone_num, set_num_time)"
            " VALUES (?,?,?) ON CONFLICT(player_id) DO UPDATE SET"
            " phone_num=excluded.phone_num, set_num_time=excluded.set_num_time",
            (pid, phone_num, now))
    return OK, {'phoneNum': phone_num, 'setNumTime': now}


@endpoint('inviteFbFriends')
def h_invite_fb_friends(api, params):
    """FB 活动：记录"已邀请的好友"。

    客户端：Activity_FacebookShareLayer:247
        params = { fbFriendIds = ["<fb id>", ...] }
    回包：`FacebookInviteFriendSucc()` 不收参数（本地直接用自己发出去的 friendList
        去合并 inviteFbFriendList），所以回包字段读不到也不崩；这里回
        `inviteFbFriendList`（全量去重后的列表）方便排查和以后接服务端下发。
    """
    _ensure_tables(api)
    pid = _pid(api)
    ids = []
    for value in to_list(params.get('fbFriendIds')):
        text = str(value).strip()
        if text:
            ids.append(text)

    now = int(time.time())
    if ids:
        with api.db.tx() as con:
            for friend in set(ids):
                con.execute("INSERT OR IGNORE INTO player_fb_invite"
                            "(player_id, fb_friend, create_time) VALUES (?,?,?)",
                            (pid, friend, now))
    rows = api.db.all("SELECT fb_friend FROM player_fb_invite WHERE player_id=?"
                      " ORDER BY create_time", (pid,))
    invite_list = [row['fb_friend'] for row in rows]
    return OK, {'inviteFbFriendList': invite_list, 'inviteNum': len(invite_list)}
