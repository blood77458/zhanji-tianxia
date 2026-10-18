#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""「宝物系统 + 商店」共 13 个端点 —— handlers_treasure2。

客户端契约来源（每一项都在代码里标了出处，改之前先回去读一遍 Lua）
=====================================================================
宝物（work/luasrc/canon/features/treasureSystem/）
  * request/EvolveTreasureRequest      -> endpoint evolveTreasure       params {treasureId}
  * request/PotentialTreasureRequest   -> endpoint potentialTreasure    params {treasureId, type}
  * request/ResetTreasurePotential...  -> endpoint resetTreasurePotential params {treasureId}
  * request/SellTreasureRequest        -> endpoint sellTreasures        params {treasureIds[]}
  * request/SetupTreasureRequest       -> endpoint setupTreasure        params {cardId, treasureId}
  * request/SplitTreasureRequest       -> endpoint splitTreasure        params {treasureId}
  * request/UpgradeTreasureRequest     -> endpoint upgradeTreasure      params {treasureId, oneClick}
  * request/LockTreasuresRequest       -> endpoint lockTreasure（别人已实现，本文件不碰）

  ⚠️ 这 7 个接口里**只有 4 个**回包被客户端真的读：
     upgradeTreasure / evolveTreasure / potentialTreasure / resetTreasurePotential
        -> panel/TreasureNewInfoPanel 的 quickUpgradeEquipSucceed / riseStarSucceed /
           PotentialSucceed 读 `event.data.sharkTreasure`，并且**直接把它当成新的
           宝物对象**赋给 parentView.Treasure 后立刻取 .metaId/.level/.addPotential/
           .addGemPotential/.usedPotential/.lock 去算属性、拼文本。少一个字段 = Lua
           "attempt to index a nil value" = 引擎 SIGKILL。所以必须回完整 8 字段。
     sellTreasures -> 回包 rewards 被 SellTreasureRequest.onSucceedDefault 喂给
        RewardManager:getReward，缺 rewards 就是 "getReward(nil)" -> 直接崩。
     splitTreasure -> CardRebirthScene:runRebirthWithTreasure 读 e.data.rewards
        弹结算面板；同样不能缺。
     setupTreasure -> 客户端啥都不读（afterSetupEquip 自己改本地数据），但空壳回包
        会被 scripts/call_endpoint.py 判成 SHELL，且不利于排错，所以照样回完整宝物。

  客户端的「扣钱」是**本地**完成的（RewardManager:getReward({itemType=..,amount=-n})），
  所以本文件里所有消耗都不出现在 rewards 里，避免一进一出把玩家的钱扣两次：
     upgradeTreasure 扣银币      -> 客户端 quickUpgradeEquipSucceed/upgradeEquipSucceed 自己扣
     evolveTreasure 扣宝物碎片   -> 客户端 riseStarSucceed 自己扣（itemType=28）
     potentialTreasure 扣石头/银币/宝石 -> 客户端 PotentialSucceed 自己扣
     resetTreasurePotential 扣宝石 -> 客户端 ResetPotentialSucceed 自己扣
     splitTreasure 扣宝石        -> 客户端 onRebirthSucceed 自己扣
  服务端必须用**同一套配置**算出同样的数字，否则两边经济账会漂移。

商店
  * getSecretShopList / refreshSecretShop / exchangeSecretShop
        -> canon/layer/Activity_MysteryShopLayer
           `extraArgs.itemIdList` 是 **getSecretShopList 的整个回包**（ActivityPanelScene:602
           `extraArgs = data.data or {}`），随后 createTableView(extraArgs.itemIdList) 直接
           `self.list[index+1].boughtTime/...` —— itemIdList 缺失(nil) => "attempt to perform
           arithmetic on a nil value"/索引 nil，必然崩。所以 itemIdList 必须是真表。
           商品字段（MysteryShopLayerRenderer:setData）：
             id, listId, itemType, itemId, itemAmount, moneyType, moneyAmount, boughtTime
           moneyType 只认 22(星灵 astralEssence) 与 2(钻石)；boughtTime<=0 隐藏购买按钮。
           exchangeSecretShop 回包读 `response.data.rewards`；
           失败码 716454 被特判为「货架已刷新」-> 自动重新 getSecretShopList。
  * getMedalShopList / refreshMedalShop / exchangeMedalShop
        -> canon/scene/SecretaryScene:247 `medalList = evt.data.itemIdList` ->
           MedalShopScene:createTableView(medalList) -> `data[index+1]` 索引，
           itemIdList 缺失同样必崩。商品字段与神秘商店同构，货币是 29(勋章)。
           exchangeMedalShop 回包读 `evt.data.rewards`。
  * exchangeGiftBag -> canon/scene/ConfigScene:413
           回包读 `responseData.data.rewards` + `.exchangeGiftBagInfo`。
  * rechargeCalls  -> canon/request/PhoneChargeGainRequest
           回包**只读 event.params**（自己回显的 phoneNum），业务上要求真的把话费充出去。

数据落点（不新增共享文件、不改 schema.sql）
  * 宝物本体      player_treasure（已存在，单点存储：card_id 表示穿在谁身上）
  * 宝物碎片      player_extend.treasure_fragment_num
                  ⚠️ 不是 player_fragment！客户端 DataManager.getTreasureFragmentNum 读
                  `sharkUserExtendMore.treasureInfo.treasureFragmentNum`，assembler 也是从
                  player_extend.treasure_fragment_num 组包。所以 itemType=28 的发放/消耗
                  必须走这一列，走 reward.skill 的 player_fragment 客户端看不见。
  * 神秘商店      player_secret_shop（items_json 存 {"items":[..],"idSeq":n}，
                  老库里可能是裸数组，读取时兼容）
  * 勋章商店      player_activity(activity_key='treasure2_medal_shop')（复用活动状态表）
  * 礼包码        gift_code（本模块惰性建表，运营后台填；player_gift_code 已存在，记领取）
  * 话费          phone_charge（已存在）

关于 meta_payload.treasureSettingConfig.treasurePropId
------------------------------------------------------
真配置里潜力石是 **400350**（prop_meta.readName='潜力石'），而 meta_payload 发的是
400001（经验球）。客户端 TreasureSystemUtils.getPotentialStone() 读的正是
treasureSettingConfig.treasurePropId，即**客户端显示的石头数量来自这个字段**。
为了让「客户端显示的数量」与「服务端实际扣的数量」永远同步，本文件也读同一个字段
（字段缺失时才退回配置表里的 type/ID）。要修这个数据应该去改 meta_payload.py，
改完这里自动跟着走，不需要动本文件。
"""
import json
import random
import time

import assembler as A
import gamedata as G
import luaconf
import meta_payload
from . import endpoint, ApiError, to_int_list, to_list

OK = 200

# ============================================================ 错误码
# 全部落在原厂码空间 710000+，客户端 ErrorCodeManager / 各 Request 的 onFailed 已有处理；
# 没登记过的码走 CanonMessageBox:showCommUnHandleErrorBox（弹「未知错误」，不会崩）。
E_NOT_EXIST = 710071        # 宝物/商品不存在（全项目通用「找不到了」）
E_INVALID = 710001          # 条件不满足（等级不够 / 已满级 / 已满星 / 没有可重置的潜力）
E_COIN = 710512             # 银币不足（ErrorCodeManager[710512] = silverNotEnouth）
E_GEM = 710513              # 钻石不足（ErrorCodeManager[710513] = goldNotEnough）
E_BAG_FULL = 710516         # 格子不够（ErrorCodeManager[710516] = packageIsFull）
E_MEDAL = 713004            # 勋章不足。原厂码未公开，这里自用一个：客户端本地已拦一次，
                            # 只有绕过前端时才看到通用错误弹窗。
E_SHOP_STALE = 716454       # 货架已刷新/商品售罄（Activity_MysteryShopLayer:433 特判）
E_ASTRAL = 716455           # 星灵不足（神秘商店 moneyType=22）
E_REFRESH_TICKET = 716456   # 刷新次数/刷新令/钻石都不够
E_GIFT_INVALID = 714200     # 兑换码格式不对（CommErrorCodes.EXCHANGE_GIFT_BAG_INVALID_ACTIVATION_CODE）
E_GIFT_REWARDED = 714201    # 该玩家已领过这个码（EXCHANGE_GIFT_BAG_HAS_GET_REWARD）
E_GIFT_NO_META = 714202     # 兑换码表没配置（ACTIVATION_CODE_META_NOT_CONFIGED）
E_GIFT_EXPIRED = 714203     # 不在活动时间内（EXCHANGE_GIFT_BAG_NOT_IN_ACTIVITY_TIME）
E_GIFT_NO_CODE = 714204     # 码不存在（EXCHANGE_GIFT_BAG_ACTIVATION_CODE_NOT_EXIST）
E_GIFT_USED_UP = 714205     # 码已被用完（EXCHANGE_GIFT_BAG_ACTIVATION_HAS_USED）
E_GIFT_NO_ITEM = 714207     # 码的奖励没配置（ACTIVATION_CODE_ITEM_NOT_CONFIGURED）
E_PHONE_CLOSED = 714643     # 送话费活动关闭
E_PHONE_NO_MONEY = 714644   # 没有可充入的话费（余额不足）
E_PHONE_BAD_NUM = 714645    # 手机号不正确

# 一期货架的商品数：配置里没有「一期几件」，原服货架来自运营后台，这里给固定值。
SECRET_SHELF_SIZE = 6
MEDAL_SHELF_SIZE = 8
# 刷新令道具 id（prop_meta 400163 readName='刷新令'，Activity_MysteryShopLayer 里硬编码）
REFRESH_TICKET_PROP = 400163


# ============================================================ 静态配置缓存
_CFG = {}


def _meta():
    """getMeta 载荷（和客户端看到的必须是同一份，否则两边算的价不一致）。"""
    if 'meta' not in _CFG:
        _CFG['meta'] = meta_payload.get_meta_payload()
    return _CFG['meta']


def _table(name):
    """lua 配置表 -> {主键: 行}。配置缺失时返回 {}（上层当「无此配置」处理）。"""
    key = 'tbl:' + name
    if key not in _CFG:
        rows = luaconf.as_list(luaconf.load(name))
        _CFG[key] = rows
    return _CFG[key]


def _by_key(name, field):
    key = 'idx:%s.%s' % (name, field)
    if key not in _CFG:
        out = {}
        for row in _table(name):
            try:
                out[int(row[field])] = row
            except (KeyError, TypeError, ValueError):
                continue
        _CFG[key] = out
    return _CFG[key]


def _setting():
    """treasureSettingConfig（unlockLevel / treasurePoolInitSize / treasurePropId …）。"""
    return _meta().get('treasureSettingConfig') or {}


def _game_setting():
    return _meta().get('gameSettingConfig') or {}


def _treasure_meta(meta_id):
    return _by_key('treasure_meta', 'treasureID').get(int(meta_id or 0))


def _strengthen(level):
    """treasure_strengthen[level].treasureUpCoin（强化到 level 要花的银币）。"""
    return _by_key('treasure_strengthen', 'treasureLevel').get(int(level))


def _star(rare):
    return _by_key('treasure_star', 'treasureStar').get(int(rare or 0))


def _potential_setting(rare):
    return _by_key('treasure_potential_setting', 'treasureStar').get(int(rare or 0))


def _potential_cfg(kind, level):
    """潜力激发消耗表：[1]=普通石 [2]=银币 [3]=钻石。按 potentialLevel 取。"""
    name = {1: 'treasure_potential_ordinary',
            2: 'treasure_potential_silver',
            3: 'treasure_potential_gold'}.get(int(kind or 0))
    if not name:
        return None
    return _by_key(name, 'potentialLevel').get(int(level or 0))


def _refresh_interval(cfg_name, default=86400):
    """newRefreshInterval 形如 "86400" 或 "14400|28800|…"（客户端按「距 0 点的秒数」解析）。

    服务端只需要一个「多久自动换期货架」的周期，取第一段。
    """
    raw = str((_game_setting().get(cfg_name) or {}).get('newRefreshInterval')
              or default)
    try:
        return max(60, int(raw.split('|')[0]))
    except (TypeError, ValueError):
        return default


def _shop_price(cfg_name, default):
    """商店刷新花费的钻石（secretShopConfig / dailyShopConfig.refreshGoldCost）。"""
    value = (_game_setting().get(cfg_name) or {}).get('refreshGoldCost')
    try:
        return max(0, int(default if value is None else value))
    except (TypeError, ValueError):
        return default


# ============================================================ 通用小工具
def _pid(api):
    return int(api.require_player()['player_id'])


def _treasure_json(row):
    """player_treasure 行 -> 客户端 sharkTreasure（assembler 是唯一权威）。"""
    return A.build_treasure(dict(row))


def _load_treasure(api, pid, treasure_id):
    """取自己的宝物，不存在就业务报错（绝不返回 None 让上层 index）。"""
    tid = int(treasure_id or 0)
    if tid <= 0:
        raise ApiError(E_NOT_EXIST)
    row = api.repos.asset.treasure(pid, tid)
    if row is None:
        raise ApiError(E_NOT_EXIST)
    return row


def _param_treasure_id(params):
    """宝物类接口的 id 参数名不统一：多数是 treasureId，个别客户端传 treasureIds。"""
    for key in ('treasureId', 'treasureIds', 'id'):
        ids = to_int_list((params or {}).get(key))
        if ids:
            return ids[0]
    return 0


def _fragment_num(api, pid):
    return int(api.repos.player.extend(pid)['treasure_fragment_num'] or 0)


def _add_fragment(api, pid, delta):
    """宝物碎片增减（player_extend.treasure_fragment_num，下限 0）。

    用一条 UPDATE 原子完成：ThreadingHTTPServer 下读-改-写会丢更新。
    """
    delta = int(delta)
    if not delta:
        return _fragment_num(api, pid)
    api.repos.player.extend(pid)          # 保证行存在
    with api.db.tx() as con:
        con.execute("UPDATE player_extend SET treasure_fragment_num ="
                    " MAX(0, COALESCE(treasure_fragment_num,0) + ?), updated_at=?"
                    " WHERE player_id=?", (delta, int(time.time()), int(pid)))
    return _fragment_num(api, pid)


def _grant(api, pid, rewards, reason):
    """发奖。

    和 api.ctx.reward.grant 的唯一区别：itemType=28（宝物碎片）落到
    player_extend.treasure_fragment_num，而不是 player_fragment(kind=3) ——
    客户端只认前者（DataManager.getTreasureFragmentNum）。
    """
    normal, out, frag = [], [], 0
    for rw in rewards or []:
        item_type = int((rw or {}).get('itemType') or 0)
        amount = int((rw or {}).get('amount') or 0)
        if item_type == G.RE_TREASURE_FRAGMENT:
            frag += amount
            out.append({'itemType': item_type,
                        'metaId': int((rw or {}).get('metaId') or 0),
                        'amount': amount})
        else:
            normal.append(rw)
    if normal:
        applied, _ = api.ctx.reward.grant(pid, normal, record=True, reason=reason)
        out.extend(applied)
    if frag:
        _add_fragment(api, pid, frag)
        api.db.con.execute(
            "INSERT INTO reward_log(player_id, reason, item_type, meta_id, amount,"
            " create_time) VALUES (?,?,?,?,?,strftime('%s','now'))",
            (int(pid), reason or '', G.RE_TREASURE_FRAGMENT, 0, frag))
    return out


def _spend_gems(api, pid, amount, code=E_GEM):
    amount = int(amount or 0)
    if amount <= 0:
        return
    if api.ctx.player.spend_gems(pid, amount) is None:
        raise ApiError(code)


def _spend_coin(api, pid, amount, code=E_COIN):
    amount = int(amount or 0)
    if amount <= 0:
        return
    p = api.player
    if int(p['gold']) < amount:
        raise ApiError(code)
    api.repos.player.add_currency(pid, 'gold', -amount)


def _spend_astral(api, pid, amount, code=E_ASTRAL):
    amount = int(amount or 0)
    if amount <= 0:
        return
    p = api.player
    if int(p['astral_essence']) < amount:
        raise ApiError(code)
    api.repos.player.add_currency(pid, 'astral_essence', -amount)


def _spend_medal(api, pid, amount, code=E_MEDAL):
    amount = int(amount or 0)
    if amount <= 0:
        return
    p = api.player
    if int(p['medal_num']) < amount:
        raise ApiError(code)
    api.repos.player.add_currency(pid, 'medal_num', -amount)


def _spend_prop(api, pid, meta_id, amount, code=E_INVALID):
    """先校验再扣（道具不足时报业务错误，绝不会扣成负数）。"""
    meta_id, amount = int(meta_id or 0), int(amount or 0)
    if amount <= 0:
        return
    if api.repos.asset.prop(pid, meta_id) < amount:
        raise ApiError(code)
    api.db.add_prop(int(pid), meta_id, -amount)


def _potential_stone_meta(cfg):
    """潜力石道具 id：优先跟客户端同一个来源（treasureSettingConfig.treasurePropId），
    其次才是 treasure_potential_*.ID。见文件头说明。"""
    stone = int(_setting().get('treasurePropId') or 0)
    if stone:
        return stone
    return int((cfg or {}).get('ID') or 0)


def _potential_level(add_potential):
    """TreasureSystemUtils.CheckPotentialRank：addPotential 落在哪一档就取哪档的消耗。"""
    add = int(add_potential or 0)
    for row in _table('treasure_potential_setting'):
        try:
            if int(row['potentialNum']) <= add <= int(row['PotentialMax']):
                return int(row['treasureLevel'])
        except (KeyError, TypeError, ValueError):
            continue
    return 0


# ============================================================ 一、宝物·强化
@endpoint('upgradeTreasure')
def upgrade_treasure(api, params):
    """宝物强化（TreasureNewInfoPanel TreasureStrengthenTabView）。

    调用时机：面板「强化」按钮 / 「一键强化」按钮。
    客户端算法（quickUpgradeCostFun，本函数必须逐字对齐，否则本地扣的银币和
    服务端扣的对不上）：
        maxLevel = min(treasure_meta.maxEvolvedLevel, player.level)
        从 level+1 累加到 maxLevel，超过当前银币就停
    回包：sharkTreasure（客户端直接当新对象用，见文件头）。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    row = _load_treasure(api, pid, tid)
    meta = _treasure_meta(row['meta_id'])
    if meta is None:
        raise ApiError(E_NOT_EXIST)

    level = int(row['level'])
    max_level = min(int(meta.get('maxEvolvedLevel') or 999), int(api.player['level']))
    if level >= max_level:
        # 客户端也会先拦（Treasure_tips21「宝物等级不能超过主公等级」），这里兜底
        raise ApiError(E_INVALID)

    one_click = params.get('oneclick')
    if one_click is None:
        one_click = params.get('oneClick')
    one_click = bool(one_click)

    gold = int(api.player['gold'])
    total, target = 0, level
    for lv in range(level + 1, max_level + 1):
        cfg = _strengthen(lv)
        if not cfg:
            break
        cost = int(cfg.get('treasureUpCoin') or 0)
        if total + cost > gold:
            break
        total += cost
        target = lv
        if not one_click:
            break
    if target <= level:
        raise ApiError(E_COIN)      # 一级都强化不起

    with api.db.tx():
        _spend_coin(api, pid, total)
        api.repos.asset.update_treasure(pid, tid, level=target)

    return {'sharkTreasure': _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'oneClick': one_click,
            # 银币由客户端自己扣（upgradeEquipSucceed: RewardManager COIN -cost）
            'rewards': []}


# ============================================================ 二、宝物·升星
@endpoint('evolveTreasure')
def evolve_treasure(api, params):
    """宝物升星（TreasureRisingStarTabView / RiseStarBtnFun）。

    客户端 gate（refreshInfoStar）：
        treasure_star[rare].number > 宝物碎片数   -> 按钮隐藏
        level < treasure_meta.evolutionLevel      -> 按钮隐藏
        rare == 6                                 -> 按钮隐藏（6 星是当前最高可升档）
    成功回调 riseStarSucceed 自己扣掉 `treasure_star[rare].number` 个宝物碎片
    （itemType=28），所以服务端扣完不能在 rewards 里重复扣。
    升星的实质 = metaId -> treasure_meta.evolvedCardId（rare+1 的同族宝物），level 不变。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    row = _load_treasure(api, pid, tid)
    meta = _treasure_meta(row['meta_id'])
    if meta is None:
        raise ApiError(E_NOT_EXIST)

    rare = int(meta.get('rare') or 0)
    star = _star(rare)
    need = int((star or {}).get('number') or 0)
    evolve_level = int(meta.get('evolutionLevel') or 0)
    next_meta = int(meta.get('evolvedCardId') or 0)

    if not star or not need or rare >= 6 or not next_meta:
        raise ApiError(E_INVALID)          # 已是最高星级 / 该档不可升星
    if int(row['level']) < evolve_level:
        raise ApiError(E_INVALID)          # 等级不足（evolutionLevel 门槛）
    if _fragment_num(api, pid) < need:
        raise ApiError(E_INVALID)          # 碎片不足

    with api.db.tx():
        _add_fragment(api, pid, -need)
        api.repos.asset.update_treasure(pid, tid, meta_id=next_meta)

    return {'sharkTreasure': _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'metaId': next_meta,
            # 碎片消耗由客户端自己扣（riseStarSucceed: TREASURE_FRAGMENT -number）
            'rewards': []}


# ============================================================ 三、宝物·潜力激发
@endpoint('potentialTreasure')
def potential_treasure(api, params):
    """宝物潜力激发（TreaseurePotentialTabView / PotentialBtnFun）。

    params: {treasureId, type}；type = 1 普通(只花潜力石) / 2 银币 / 3 钻石。
    客户端 gate：`treasure_potential_setting[rare].PotentialMax - usedPotential > 0`
    消耗表 treasure_potential_{ordinary,silver,gold}[CheckPotentialRank(addPotential)]：
        number  潜力石数量，type/ID 是石头道具
        number2 银币(type2=1) 或钻石(type2=2) 数量
        successRate 成功率(%)，钻石档恒 100
    成功：addPotential+1（钻石档同时 addGemPotential+1，拿 treasurePotentialUp% 额外加成，
          CountAttandDefandHp 里就是这么用的）；失败：只加 usedPotential。
    两种结果都算用掉一次潜力（usedPotential 是「已尝试次数」上限）。
    回包：sharkTreasure（客户端读它刷新面板）。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    kind = int(api.param(params, 'type', 0) or 0)
    row = _load_treasure(api, pid, tid)
    meta = _treasure_meta(row['meta_id'])
    if meta is None:
        raise ApiError(E_NOT_EXIST)
    if kind not in (1, 2, 3):
        raise ApiError(E_INVALID)

    poti = _potential_setting(int(meta.get('rare') or 0))
    if poti is None:
        raise ApiError(E_NOT_EXIST)
    used = int(row['used_potential'])
    add = int(row['add_potential'])
    gem_add = int(row['add_gem_potential'])
    if int(poti['PotentialMax']) - used <= 0 or add >= int(poti['PotentialMax']):
        raise ApiError(E_INVALID)          # 潜力已满（客户端 txt_11_9 显示的就是剩余次数）

    cfg = _potential_cfg(kind, _potential_level(add))
    if cfg is None:
        raise ApiError(E_NOT_EXIST)

    stone_meta = _potential_stone_meta(cfg)
    stone_num = int(cfg.get('number') or 0)
    money_type = int(cfg.get('type2') or 0)
    money_num = int(cfg.get('number2') or 0)
    rate = int(cfg.get('successRate') or 0)

    with api.db.tx():
        # ---- 先扣后掷（掷骰时必须先确认付得起，避免白嫖失败结果）
        _spend_prop(api, pid, stone_meta, stone_num, E_INVALID)   # 石头不足 -> 客户端本地也拦
        if money_type == G.RE_COIN:
            _spend_coin(api, pid, money_num)
        elif money_type == G.RE_GEMS:
            _spend_gems(api, pid, money_num)

        success = random.randint(1, 100) <= rate
        fields = {'used_potential': used + 1}
        if success:
            fields['add_potential'] = add + 1
            if kind == 3:                 # 钻石档：额外潜力加成（treasurePotentialUp%）
                fields['add_gem_potential'] = gem_add + 1
        api.repos.asset.update_treasure(pid, tid, **fields)

    return {'sharkTreasure': _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'type': kind, 'success': success,
            # 石头/银币/钻石客户端自己扣（PotentialSucceed 里有三处 gainReward）
            'rewards': []}


# ============================================================ 四、宝物·重置潜力
@endpoint('resetTreasurePotential')
def reset_treasure_potential(api, params):
    """宝物重置潜力（TreaseurePotentialTabView / ResetPotentialBtnFun）。

    客户端 gate：`usedPotential <= 0` 时按钮灰。确认框写的是
    treasureSettingConfig.treasurePotentialCost 钻石（默认 100），成功回调自己扣。
    效果：addPotential / addGemPotential / usedPotential 全部归零（客户端本地也是这么改的）。

    ⚠️ 客户端 bug：ResetTreasurePotentialRequest.onSucceedDefault 会把宝物的 lock
       **取反**（那段是 lockTreasure 抄过来的）。服务端不跟着改 is_locked，否则
       一次重置就把玩家锁的宝物解锁了。下次 gameInit 会用服务端的 lock 覆盖回去。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    row = _load_treasure(api, pid, tid)
    if int(row['used_potential']) <= 0 and int(row['add_potential']) <= 0:
        raise ApiError(E_INVALID)          # 没有任何潜力可重置

    cost = int(_setting().get('treasurePotentialCost') or 0)
    with api.db.tx():
        _spend_gems(api, pid, cost)
        api.repos.asset.update_treasure(pid, tid, add_potential=0, add_gem_potential=0,
                                        used_potential=0)

    return {'sharkTreasure': _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'costGems': cost,
            # 钻石客户端自己扣（ResetPotentialSucceed: GEMS -treasurePotentialCost）
            'rewards': []}


# ============================================================ 五、宝物·卖出
@endpoint('sellTreasures')
def sell_treasures(api, params):
    """批量卖出宝物（ItemSellMessageBoxPanel / BAGCATEGORY.treasure）。

    params: {treasureIds[]}（AMF3 密集数组解出来是 {1:..,2:..}，必须过 to_int_list）
    价格：MetaManager.treasure_meta[metaId].basicPrice（客户端算价用的是同一个字段）。
    回包：rewards = 一笔银币，客户端 onSucceedDefault 直接 RewardManager:getReward(rewards)。

    破坏性操作 -> **先全量校验再动手**：任何一件不存在/上锁/穿在身上的，
    整批拒绝，绝不半途删一半。
    """
    pid = _pid(api)
    ids = sorted({i for i in to_int_list(params.get('treasureIds') or params.get('treasureId'))
                  if int(i) > 0})
    if not ids:
        return {'rewards': [], 'treasureIds': []}

    total, rows = 0, []
    for tid in ids:
        row = api.repos.asset.treasure(pid, tid)
        if row is None:
            raise ApiError(E_NOT_EXIST)
        if int(row['is_locked']):
            raise ApiError(E_INVALID)      # 上锁的宝物不能卖（客户端也隐藏了卖按钮）
        if int(row['card_id']):
            raise ApiError(E_INVALID)      # 穿在武将身上的不能卖（要先卸下）
        meta = _treasure_meta(row['meta_id'])
        total += int((meta or {}).get('basicPrice') or 0)
        rows.append(tid)

    with api.db.tx():
        for tid in rows:
            api.repos.asset.delete_treasure(pid, tid)
        _grant(api, pid, [{'itemType': G.RE_COIN, 'metaId': 0, 'amount': total}],
               'sellTreasures')

    return {'rewards': [{'itemType': G.RE_COIN, 'metaId': 0, 'amount': total}],
            'treasureIds': rows, 'sellPrice': total}


# ============================================================ 六、宝物·装备/卸下
@endpoint('setupTreasure')
def setup_treasure(api, params):
    """宝物装备到武将（TreasureBackpackScene:1009 `{cardId, treasureId}`）。

    cardId=0 表示卸下。客户端 afterSetupEquip 自己改本地数据，回包不读；
    但要把「一件宝物只能穿一个人」这件事在库里做对：
      1) 目标武将身上原有的宝物先脱（player_treasure.card_id 单点存储）
      2) 再把要穿的宝物挂上去
    回包给完整 sharkTreasure，方便排错和 call_endpoint 判定。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    card_id = int(api.param(params, 'cardId', 0) or 0)
    row = _load_treasure(api, pid, tid)

    with api.db.tx():                     # 换装是三步，必须同一个事务
        if card_id:
            if api.repos.asset.card(pid, card_id) is None:
                raise ApiError(E_NOT_EXIST)    # 武将不存在
            current = api.repos.asset.treasure_of_card(pid, card_id)
            if current is not None and int(current['treasure_id']) != tid:
                api.repos.asset.update_treasure(pid, int(current['treasure_id']), card_id=0)
        api.repos.asset.update_treasure(pid, tid, card_id=card_id)
    return {'sharkTreasure': _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'cardId': card_id, 'rewards': []}


# ============================================================ 七、宝物·拆分(重生)
@endpoint('splitTreasure')
def split_treasure(api, params):
    """拆解/重生宝物（CardRebirthScene:1114 `SplitTreasureRequest.sendRequestDefalut(treasureId)`）。

    协议注释（SplitTreasureRequest 文件头）：
        request  {treasureId}
        response {rewards[]}  拆分获得的物品列表
    客户端算法：
        cost    = treasure_star[rare].rebirthCost          钻石（客户端自己扣）
        refund  = Σ treasure_strengthen[1..level-1].treasureUpCoin * treasureRenascence/100
        结果    = 宝物 level 归 1（客户端本地也把 level 改成 1）
    onRebirthSucceed 会拿 rewards 弹 GetRewardInfoPanel 并 RewardManager:getReward(rewards)，
    所以 rewards 必须和服务端真正发下去的完全一致（含 0 件的情况 -> 空表，面板 0 行不崩）。
    """
    pid = _pid(api)
    tid = _param_treasure_id(params)
    row = _load_treasure(api, pid, tid)
    meta = _treasure_meta(row['meta_id'])
    if meta is None:
        raise ApiError(E_NOT_EXIST)
    if int(row['is_locked']):
        raise ApiError(E_INVALID)          # 上锁的不能拆

    star = _star(int(meta.get('rare') or 0)) or {}
    gems = int(star.get('rebirthCost') or 0)
    level = int(row['level'])
    coin = 0
    for lv in range(1, level):
        cfg = _strengthen(lv)
        if cfg:
            coin += int(cfg.get('treasureUpCoin') or 0)
    coin = int(coin * int(_setting().get('treasureRenascence') or 0) / 100)
    rewards = [{'itemType': G.RE_COIN, 'metaId': 0, 'amount': coin}] if coin > 0 else []

    with api.db.tx():
        _spend_gems(api, pid, gems)
        if rewards:
            _grant(api, pid, rewards, 'splitTreasure')
        api.repos.asset.update_treasure(pid, tid, level=1)

    return {'rewards': rewards, 'sharkTreasure':
            _treasure_json(api.repos.asset.treasure(pid, tid)),
            'treasureId': tid, 'costGems': gems}


# ============================================================ 神秘商店：状态
def _secret_row(api, pid):
    """取/建 player_secret_shop 行（客户端 gameInit 的 sharkUserSecretShop 也读它）。"""
    row = api.db.one("SELECT * FROM player_secret_shop WHERE player_id=?", (int(pid),))
    if row is None:
        now = int(time.time())
        with api.db.tx() as con:
            con.execute("INSERT OR IGNORE INTO player_secret_shop(player_id, free_times,"
                        " last_refresh_second, if_list_fresh, version, items_json)"
                        " VALUES (?,?,?,0,0,'{}')", (int(pid), 5, now))
        row = api.db.one("SELECT * FROM player_secret_shop WHERE player_id=?", (int(pid),))
    return row


def _secret_state(api, pid):
    """state = {version, freeTimes, lastRefresh, idSeq, items[]}

    items_json 约定存 dict：{"items":[...], "idSeq":n}；
    老库/旧实现里可能是裸数组，这里兼容读。
    """
    row = _secret_row(api, pid)
    try:
        blob = json.loads(row['items_json'] or '{}')
    except (TypeError, ValueError):
        blob = {}
    if isinstance(blob, list):
        blob = {'items': blob}
    if not isinstance(blob, dict):
        blob = {}
    items = blob.get('items') if isinstance(blob.get('items'), list) else []
    return {'version': int(row['version']),
            'freeTimes': int(row['free_times']),
            'lastRefresh': int(row['last_refresh_second']),
            'idSeq': int(blob.get('idSeq') or 0),
            'items': items}


def _secret_save(api, pid, state):
    blob = {'items': state.get('items') or [], 'idSeq': int(state.get('idSeq') or 0)}
    with api.db.tx() as con:
        con.execute("UPDATE player_secret_shop SET items_json=?, version=?, free_times=?,"
                    " last_refresh_second=? WHERE player_id=?",
                    (json.dumps(blob, ensure_ascii=False), int(state.get('version') or 0),
                     int(state.get('freeTimes') or 0), int(state.get('lastRefresh') or 0),
                     int(pid)))


# 神秘商店商品池。
# 原厂的货架是运营后台数据（客户端包里没有这张配置表，assets 里也没有），
# 所以这里用 shop_meta（同属商城系统、含真实道具 id 与钻石定价的配置表）筛一个池：
#   enable=1 且 discountPrice <= 600 的便宜货，避免抽到 60000 钻的东西。
# moneyType 一律 2（钻石）：星灵(22) 定价没有随包配置，货架生成时不会产出；
# 但 exchangeSecretShop 里 22 的分支是实装的，运营配表后可直接用。
def _secret_pool(vip_level):
    pool, seen = [], set()
    for row in _table('shop_meta'):
        try:
            if not row.get('enable'):
                continue
            if int(row.get('moneyType') or 0) != G.RE_GEMS:
                continue
            price = int(row.get('discountPrice') or row.get('price') or 0)
            if price < 5 or price > 600:
                continue
            item_id = int(row.get('metaId') or 0)
            if item_id in seen:
                continue
            if not _vip_allowed(row.get('requireVipLevel'), vip_level):
                continue
            seen.add(item_id)
        except (TypeError, ValueError):
            continue
        pool.append({'itemType': int(row.get('itemType') or 0), 'itemId': item_id,
                     'itemAmount': max(1, int(row.get('amount') or 1)),
                     'moneyType': int(row.get('moneyType') or G.RE_GEMS),
                     'moneyAmount': price,
                     # 限购次数：配置里的 dailyPurchaseLimit>0 就照它，否则每期货架 1 次
                     'boughtTime': (int(row.get('dailyPurchaseLimit'))
                                    if int(row.get('dailyPurchaseLimit') or -1) > 0 else 1)})
    return pool


def _vip_allowed(require_vip_level, vip_level):
    """requireVipLevel 是 "1,2,3,..." 这种白名单；空/0 表示不限。"""
    text = str(require_vip_level or '').strip()
    if not text or text == '0':
        return True
    return str(int(vip_level or 0)) in [x.strip() for x in text.split(',') if x.strip()]


def _secret_gen(api, pid, state):
    """换一期货架：version+1、id 用 idSeq 全局自增（客户端拿 id 当 exchangeId）。"""
    pool = _secret_pool(G.vip_level_of(api.player))
    take = min(SECRET_SHELF_SIZE, len(pool))
    chosen = random.sample(pool, take) if take else []
    version = int(state.get('version') or 0) + 1
    seq = int(state.get('idSeq') or 0)
    items = []
    for good in chosen:
        seq += 1
        items.append({'id': seq, 'listId': version,
                      'itemType': good['itemType'], 'itemId': good['itemId'],
                      'itemAmount': good['itemAmount'],
                      'moneyType': good['moneyType'],
                      'moneyAmount': good['moneyAmount'],
                      'boughtTime': good['boughtTime']})
    state.update({'items': items, 'idSeq': seq, 'version': version,
                  'lastRefresh': int(time.time())})
    _secret_save(api, pid, state)
    return state


def _secret_interval():
    return _refresh_interval('secretShopConfig', 86400)


def _secret_ensure(api, pid):
    """读状态；空了或过期（secretShopConfig.newRefreshInterval）就自动换期。

    客户端倒计时（Activity_MysteryShopLayer:refreshTime）算的是
    `lastRefreshSecond + 周期`，所以换期必须把 last_refresh_second 一起写。
    """
    state = _secret_state(api, pid)
    now = int(time.time())
    if not state['items'] or now - int(state['lastRefresh']) >= _secret_interval():
        state = _secret_gen(api, pid, state)
    return state


def _secret_payload(state):
    """getSecretShopList / refreshSecretShop 的回包。

    字段契约（Activity_MysteryShopLayer）：
      itemIdList       货架（**必须存在**，见文件头）
      freeTimes        免费刷新剩余（面板显示「免费刷新 {num} 次」）
      version          客户端比对 version 判断要不要重画列表
      lastRefreshSecond 倒计时基准
      paidLeft         客户端未使用，固定 -1（原服同款占位）
    """
    return {'itemIdList': state.get('items') or [],
            'freeTimes': int(state.get('freeTimes') or 0),
            'version': int(state.get('version') or 0),
            'lastRefreshSecond': int(state.get('lastRefresh') or 0),
            'paidLeft': -1}


@endpoint('getSecretShopList')
def get_secret_shop_list(api, params):
    """打开神秘商店面板（ActivityPanelScene:624 -> Activity_MysteryShopLayer）。

    ⚠️ 这里**覆盖** handlers_more.h_secret_shop：原来的实现把 items_json 当
    secretShopItems 返回、itemIdList 恒为 []，客户端 `extraArgs.itemIdList` 是空表
    -> 面板一件商品都没有（且与 refreshSecretShop 生成的数据不同步）。
    本实现让两个接口共用同一份货架状态。返回字段是原实现的超集，不影响别处。
    """
    pid = _pid(api)
    state = _secret_ensure(api, pid)
    payload = _secret_payload(state)
    payload['secretShopItems'] = payload['itemIdList']      # 兼容旧字段名
    return payload


@endpoint('refreshSecretShop')
def refresh_secret_shop(api, params):
    """手动刷新神秘商店（Activity_MysteryShopLayer / toRefresh 按钮）。

    客户端扣费顺序（refreshSucceed 里写死的）：
        1) freeTimes > 0            -> 免费，本地 freeTimes-1
        2) 背包有刷新令 400163       -> 本地扣 1 个
        3) 否则扣 secretShopConfig.refreshGoldCost 钻石
    服务端必须用同一顺序、同一份配置，否则两边扣的东西不一致。
    回包：itemIdList（客户端 createTableView(response.data.itemIdList)）+ freeTimes + version。
    """
    pid = _pid(api)
    state = _secret_ensure(api, pid)
    now = int(time.time())
    cost_gem = _shop_price('secretShopConfig', 50)

    with api.db.tx():
        if int(state['freeTimes']) > 0:
            state['freeTimes'] = int(state['freeTimes']) - 1
        elif api.repos.asset.prop(pid, REFRESH_TICKET_PROP) > 0:
            _spend_prop(api, pid, REFRESH_TICKET_PROP, 1, E_REFRESH_TICKET)
        else:
            _spend_gems(api, pid, cost_gem, E_REFRESH_TICKET)
        state['lastRefresh'] = now          # 换期时间 = 现在，客户端据此重算倒计时
        state = _secret_gen(api, pid, state)

    return _secret_payload(state)


@endpoint('exchangeSecretShop')
def exchange_secret_shop(api, params):
    """神秘商店兑换（Activity_MysteryShopLayer / onListItemTouch）。

    params {exchangeId, exchangeListId}：exchangeId 是商品 id，exchangeListId 是货架
    version。**先校验货架版本/库存，再扣钱，最后发货**，绝不允许先扣后查。
    失败码 716454 被客户端特判成「货架已刷新」-> 自动重新 getSecretShopList。
    回包：rewards（客户端 RewardManager:getReward(response.data.rewards)）。
    """
    pid = _pid(api)
    exchange_id = int(api.param(params, 'exchangeId', 0) or 0)
    list_id = int(api.param(params, 'exchangeListId', 0) or 0)
    if exchange_id <= 0:
        raise ApiError(E_NOT_EXIST)

    state = _secret_state(api, pid)
    if list_id and list_id != int(state['version']):
        raise ApiError(E_SHOP_STALE)        # 货架已换期
    item = next((it for it in state['items']
                 if int(it.get('id') or 0) == exchange_id), None)
    if item is None or int(item.get('boughtTime') or 0) <= 0:
        raise ApiError(E_SHOP_STALE)        # 已售罄/已下架

    money_type = int(item.get('moneyType') or 0)
    price = int(item.get('moneyAmount') or 0)
    item_type = int(item.get('itemType') or 0)
    item_id = int(item.get('itemId') or 0)
    amount = max(1, int(item.get('itemAmount') or 1))

    with api.db.tx():
        if money_type == 22:                       # 星灵（sharkUserExtend.astralEssence）
            _spend_astral(api, pid, price, E_ASTRAL)
        elif money_type == G.RE_GEMS:              # 钻石
            _spend_gems(api, pid, price)
        else:
            raise ApiError(E_INVALID)              # 未支持的货币类型
        rewards = _grant(api, pid, [{'itemType': item_type, 'metaId': item_id,
                                     'amount': amount}], 'exchangeSecretShop')
        item['boughtTime'] = int(item.get('boughtTime') or 0) - 1
        _secret_save(api, pid, state)

    return {'rewards': rewards}


# ============================================================ 勋章商店：状态
# 复用 player_activity：勋章商店只要「一期货架 + 每日重置」，不值得单开一张表。
MEDAL_KEY = 'treasure2_medal_shop'


def _medal_gen(api, pid, state):
    """按 daily_shop 配置的 weight 抽一期勋章货架。

    daily_shop 每行 {id(货架), listId(档位), itemType, itemId, itemAmount,
                    moneyType(29=勋章), moneyAmount, weight}。
    5 个 id 货架内容完全相同，listId 1..32 是 32 个候选档位（同一件东西有
    50/75/100 三种档，weight 决定出现权重）——原服货架是运营后台配的，没有随包
    下发「一期几件」，这里按 weight 无重复抽 MEDAL_SHELF_SIZE 个档位组成一期。
    """
    candidates = []
    seen = set()
    for row in _table('daily_shop'):
        try:
            if int(row.get('moneyType') or 0) != G.RE_MEDAL:
                continue                 # 只卖勋章定价的商品
            mark = (int(row.get('itemType') or 0), int(row.get('itemId') or 0),
                    int(row.get('itemAmount') or 0))
            if mark in seen:
                continue                 # 5 个货架 id 是重复数据，去重
            seen.add(mark)
            candidates.append({'listId': int(row.get('listId') or 0),
                               'itemType': mark[0], 'itemId': mark[1],
                               'itemAmount': max(1, mark[2]),
                               'moneyType': G.RE_MEDAL,
                               'moneyAmount': int(row.get('moneyAmount') or 0),
                               'weight': max(1, int(row.get('weight') or 1))})
        except (TypeError, ValueError):
            continue

    version = int(state.get('version') or 0) + 1
    items, seq = [], 0
    pool = list(candidates)
    for _ in range(min(MEDAL_SHELF_SIZE, len(pool))):
        weights = [c['weight'] for c in pool]
        pick = random.choices(pool, weights=weights, k=1)[0]
        pool.remove(pick)
        seq += 1
        items.append({'id': seq, 'listId': version,
                      'itemType': pick['itemType'], 'itemId': pick['itemId'],
                      'itemAmount': pick['itemAmount'],
                      'moneyType': pick['moneyType'],
                      'moneyAmount': pick['moneyAmount'],
                      # 每期每档限购 1 次（daily_shop 没有限购字段，取最保守值）
                      'boughtTime': 1})

    state = {'version': version, 'day': time.strftime('%Y-%m-%d'),
             'items': items, 'idSeq': seq}
    api.ctx.activity.save_state(pid, MEDAL_KEY, state)
    return state


def _medal_ensure(api, pid):
    """跨天/为空自动换一期（MedalShopScene:refreshUpdateTime 用
    dailyShopConfig.newRefreshInterval 做倒计时，到点自己重新拉列表）。"""
    state = api.ctx.activity.state(pid, MEDAL_KEY)
    if not state.get('items') or state.get('day') != time.strftime('%Y-%m-%d'):
        state = _medal_gen(api, pid, state)
    return state


def _medal_payload(state):
    """itemIdList 是 MedalShopScene 唯一读的字段（SecretaryScene:247 medalList=itemIdList）。"""
    items = state.get('items') or []
    return {'itemIdList': items, 'medalShopItems': items,
            'version': int(state.get('version') or 0),
            'freeTimes': 0, 'paidLeft': -1}


@endpoint('getMedalShopList')
def get_medal_shop_list(api, params):
    """打开勋章商店（SecretaryScene:252 -> MedalShopScene:create）。

    ⚠️ 这里**覆盖** handlers_more.h_medal_shop（它只回 medalShopItems + freeTimes，
    没有 itemIdList）。客户端 `medalList = evt.data.itemIdList` 拿到 nil 之后
    MedalShopScene:createTableView(nil) 会 `#data` / `data[index+1]` -> 直接崩，
    这就是「点开勋章商店就闪退」的根因。返回字段是原实现的超集。
    """
    pid = _pid(api)
    return _medal_payload(_medal_ensure(api, pid))


@endpoint('refreshMedalShop')
def refresh_medal_shop(api, params):
    """手动刷新勋章商店（MedalShopScene / onClickUpdate）。

    客户端先校验钻石 >= dailyShopConfig.refreshGoldCost，成功后自己
    RewardManager:getReward 扣费，然后用回包的 itemIdList 覆盖 self.medalList。
    """
    pid = _pid(api)
    state = _medal_ensure(api, pid)
    cost = _shop_price('dailyShopConfig', 50)
    with api.db.tx():
        _spend_gems(api, pid, cost)
        state = _medal_gen(api, pid, state)
    return _medal_payload(state)


@endpoint('exchangeMedalShop')
def exchange_medal_shop(api, params):
    """勋章商店兑换（MedalShopScene / sendBuyGoodsReuqest）。

    params {exchangeId, exchangeListId}；货币恒为勋章(player.medal_num)。
    客户端失败分支认这几个码：710513 不足 / 713001 每日限购 / 713002 终身限购 /
    712906 VIP 不够 / 710516 包满 / 其它走通用错误弹窗。
    回包：rewards（客户端 RewardManager:getReward(evt.data.rewards)）。
    """
    pid = _pid(api)
    exchange_id = int(api.param(params, 'exchangeId', 0) or 0)
    list_id = int(api.param(params, 'exchangeListId', 0) or 0)
    if exchange_id <= 0:
        raise ApiError(E_NOT_EXIST)

    state = _medal_ensure(api, pid)
    if list_id and list_id != int(state.get('version') or 0):
        raise ApiError(E_SHOP_STALE)
    item = next((it for it in (state.get('items') or [])
                 if int(it.get('id') or 0) == exchange_id), None)
    if item is None or int(item.get('boughtTime') or 0) <= 0:
        raise ApiError(713001)             # 每日限购（客户端认识的码）
    if int(item.get('moneyType') or 0) != G.RE_MEDAL:
        raise ApiError(E_INVALID)

    price = int(item.get('moneyAmount') or 0)
    amount = max(1, int(item.get('itemAmount') or 1))
    item_type = int(item.get('itemType') or 0)
    item_id = int(item.get('itemId') or 0)

    with api.db.tx():
        _spend_medal(api, pid, price)
        rewards = _grant(api, pid, [{'itemType': item_type, 'metaId': item_id,
                                     'amount': amount}], 'exchangeMedalShop')
        item['boughtTime'] = int(item.get('boughtTime') or 0) - 1
        api.ctx.activity.save_state(pid, MEDAL_KEY, state)

    return {'rewards': rewards}


# ============================================================ 礼包码
_GIFT_TABLE_READY = False


def _ensure_gift_table(api):
    """惰性建礼包码表（不改 schema.sql）。

    gift_code       运营发码用：code -> 奖励包，可设时间窗与全服次数上限
    player_gift_code schema 里已有，记录「谁领过哪个码」（主键自带防重）
    """
    global _GIFT_TABLE_READY
    if _GIFT_TABLE_READY:
        return
    try:
        with api.db.tx() as con:
            con.execute(
                "CREATE TABLE IF NOT EXISTS gift_code ("
                " code TEXT PRIMARY KEY,"
                " reward_json TEXT NOT NULL DEFAULT '[]',"
                " start_time INTEGER NOT NULL DEFAULT 0,"
                " end_time INTEGER NOT NULL DEFAULT 0,"
                " limit_times INTEGER NOT NULL DEFAULT 0,"
                " used_times INTEGER NOT NULL DEFAULT 0,"
                " enabled INTEGER NOT NULL DEFAULT 1)")
        _GIFT_TABLE_READY = True
    except Exception:
        # 建表失败（只读库/并发）不阻塞业务：后面查表会抛错，被 dispatch 兜成 500 前
        # 这里已经能给出 714202「兑换码未配置」的语义化错误。
        _GIFT_TABLE_READY = False


@endpoint('exchangeGiftBag')
def exchange_gift_bag(api, params):
    """兑换礼包码（ConfigScene:413 / onClickExchange）。

    params {activationCode}（客户端只接受长度 9 或 12 的码：EXCHANGE_CODE_LENGTH）。
    回包读两处：
        responseData.data.rewards              -> RewardManager:getReward
        responseData.data.exchangeGiftBagInfo   -> DataManager.setExchangeGiftBagInfo
    失败码见 CommErrorCodes（714200 格式 / 714201 已领 / 714202 未配置 /
    714203 过期 / 714204 不存在 / 714205 用完 / 714207 奖励未配置），
    客户端的 exchangeGiftBagFailed 对这 7 个码分别有提示文案。

    本服没有官方发码后台，码由运营直接写进 gift_code 表；表空时就是 714204。
    """
    pid = _pid(api)
    _ensure_gift_table(api)
    code = str(api.param(params, 'activationCode', '') or '').strip().upper()
    if not code or len(code) not in (9, 12):
        raise ApiError(E_GIFT_INVALID)
    try:
        row = api.db.one("SELECT * FROM gift_code WHERE code=?", (code,))
    except Exception:
        raise ApiError(E_GIFT_NO_META)
    if row is None:
        raise ApiError(E_GIFT_NO_CODE)

    now = int(time.time())
    if not int(row['enabled'] or 0):
        raise ApiError(E_GIFT_NO_CODE)
    if int(row['start_time'] or 0) and now < int(row['start_time']):
        raise ApiError(E_GIFT_EXPIRED)
    if int(row['end_time'] or 0) and now > int(row['end_time']):
        raise ApiError(E_GIFT_EXPIRED)
    if api.db.one("SELECT 1 FROM player_gift_code WHERE player_id=? AND code=?",
                  (pid, code)) is not None:
        raise ApiError(E_GIFT_REWARDED)
    if int(row['limit_times'] or 0) and int(row['used_times'] or 0) >= int(row['limit_times']):
        raise ApiError(E_GIFT_USED_UP)

    rewards = _gift_rewards(row['reward_json'])
    if not rewards:
        raise ApiError(E_GIFT_NO_ITEM)

    with api.db.tx() as con:
        con.execute("INSERT OR IGNORE INTO player_gift_code(player_id, code, exchange_time)"
                    " VALUES (?,?,?)", (pid, code, now))
        con.execute("UPDATE gift_code SET used_times = used_times + 1 WHERE code=?", (code,))
        applied = _grant(api, pid, rewards, 'exchangeGiftBag:%s' % code)

    return {'rewards': applied,
            # 客户端只把它塞进 gameInit.sharkUserExtend.exchangeGiftBagInfo，形态自由，
            # 但必须是 dict（Lua 空表也行）——给 nil 会让 setExchangeGiftBagInfo 存 nil。
            'exchangeGiftBagInfo': {'code': code, 'exchangeTime': now,
                                    'gainCount': len(applied)}}


def _gift_rewards(reward_json):
    """礼包码奖励：支持两种写法
        [{"itemType":.., "metaId":.., "amount":..}, ...]   直接列表
        {"package": 10001}                                 奖励包 id（reward_package）
    """
    try:
        data = json.loads(reward_json or '[]')
    except (TypeError, ValueError):
        return []
    if isinstance(data, dict):
        if data.get('package'):
            return G.reward_from_package(int(data['package']))
        data = data.get('rewards') or []
    out = []
    for rw in to_list(data):
        try:
            item_type = int(rw.get('itemType') or 0)
        except AttributeError:
            continue
        if not item_type:
            continue
        out.append({'itemType': item_type,
                    'metaId': int(rw.get('metaId') or 0),
                    'amount': int(rw.get('amount') or 0)})
    return out


# ============================================================ 送话费
@endpoint('rechargeCalls')
def recharge_calls(api, params):
    """送话费活动·领取话费（PhoneChargeGainRequest，params {phoneNum, callsType}）。

    客户端成功回调（PhoneChargeGainRequest.onSucceedDefault）只读 event.params，
    **不读回包**；失败回调认得 714643 活动关闭 / 714644 没有可充入话费 /
    714642 接口错误 / 714645 手机号不正确。

    业务事实（重要）：话费余额的算法是
        chargeAmounts = gameSettingConfig.phoneChargeConfig.chargeAmounts
        getChargeByMoney(money) 在 chargeAmounts 里找 <= 充值金额的最高档
    本服 meta_payload 把 chargeAmounts 配成 **[]**（见 meta_payload.py:
    phoneChargeConfig），也就是说客户端充值后算出来的返还是 0，
    Activity_PhoneChargeLayer.havePhoneMoneyLeft() 恒 false，这个入口根本点不进来。
    所以本接口按真实语义实现：
        * 手机号必须 11 位、以 1 开头（对齐 Activity_PhoneChargeLayer.isPhoneNumber）
        * 余额取自 phone_charge.total_amount（由充值发货侧累加；本服不会增加）
        * 余额 <= 0 -> 714644「您现在没有可以充入的话费」
        * 有余额 -> 记流水、清零余额、回包带上实际充出金额
    """
    pid = _pid(api)
    phone = str(api.param(params, 'phoneNum', '') or '').strip()
    calls_type = int(api.param(params, 'callsType', 0) or 0)
    if (len(phone) != 11 or not phone.isdigit() or not phone.startswith('1')):
        raise ApiError(E_PHONE_BAD_NUM)

    row = api.db.one("SELECT * FROM phone_charge WHERE player_id=?", (pid,))
    balance = int(row['total_amount'] or 0) if row is not None else 0
    now = int(time.time())
    with api.db.tx() as con:
        # 顺带把绑定的手机号记下来（客户端成功时会本地 setBindPhoneNumber）
        con.execute("INSERT INTO phone_charge(player_id, phone_num, set_num_time,"
                    " total_amount, last_gain_time) VALUES (?,?,?,?,?)"
                    " ON CONFLICT(player_id) DO UPDATE SET phone_num=excluded.phone_num,"
                    " set_num_time=excluded.set_num_time",
                    (pid, phone, now, balance, int(row['last_gain_time'] or 0)
                     if row is not None else 0))
    if balance <= 0:
        raise ApiError(E_PHONE_NO_MONEY)   # 没有可充入的话费（本服此时恒成立）

    with api.db.tx() as con:
        con.execute("UPDATE phone_charge SET total_amount=0, last_gain_time=? WHERE player_id=?",
                    (now, pid))
        con.execute("INSERT INTO charge_log(player_id, order_id, product_id, recharge_gems,"
                    " free_gems, source, create_time) VALUES (?,?,?,0,0,'phone',?)",
                    (pid, 'phone-%d' % now, phone, now))

    # callsType: 0=单次充值 1=余额充值（客户端固定传 1）；余额充出后归零
    return {'phoneNum': phone, 'callsType': calls_type,
            'gainAmount': balance, 'balance': 0, 'gainTime': now}


# ============================================================ 说明
# 本模块只新增 handlers/tables，不修改任何共享文件：
#   * @endpoint 自动发现（api/__init__.py:load_handlers -> pkgutil.iter_modules）
#   * 新表 gift_code 惰性建；其余全部落在已有表
#   * getSecretShopList / getMedalShopList 是**覆盖**更早注册的同名实现
#     （和 handlers_activity_online.py 覆盖 handlers_more.py 的做法一致），
#     目的是让货架数据与 refresh/exchange 共用同一份状态，并补上客户端必需的
#     itemIdList 字段。
