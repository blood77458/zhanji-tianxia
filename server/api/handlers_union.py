#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""军团端点（覆盖 handlers.py 里的占位实现）。

配置来自本地 union_shop_normal / union_shop_special / union_building_* /
union_boss_meta，数据完整。
"""
from . import endpoint, ApiError

OK = 200


def _pid(api):
    return api.require_player()['player_id']


def _wrap(res):
    """service 返回 (code, payload) 或 dict。"""
    return res


# ---------------------------------------------------------------- 商店
@endpoint('getUnionBuildingShopInfo')
def h_union_shop_info(api, params):
    return api.ctx.union.building_shop_info(_pid(api))


@endpoint('buyUnionProp')
def h_buy_union_prop(api, params):
    return api.ctx.union.buy_union_prop(
        _pid(api), api.param(params, 'unionPropId', api.param(params, 'propId', 0)),
        api.param(params, 'unionPropType', 2))


# ---------------------------------------------------------------- 建筑
@endpoint('getUnionBuildingHallInfo')
def h_union_hall(api, params):
    return api.ctx.union.building_info(_pid(api), 1)


@endpoint('getUnionBuildingBankInfo')
def h_union_bank(api, params):
    return api.ctx.union.building_info(_pid(api), 3)


@endpoint('getUnionBuildingColosseumInfo')
def h_union_colosseum(api, params):
    return api.ctx.union.building_info(_pid(api), 4)


@endpoint('constructUnion')
def h_construct_union(api, params):
    return api.ctx.union.construct(
        _pid(api), api.param(params, 'unionBuildingId', 1),
        api.param(params, 'constructType', 1), api.param(params, 'coinType', 0),
        api.param(params, 'amount', 0))


@endpoint('upgradeUnionBuilding')
def h_upgrade_union_building(api, params):
    return api.ctx.union.upgrade_building(_pid(api),
                                          api.param(params, 'unionBuildingId', 1))


@endpoint('receiveUnionWage')
def h_receive_wage(api, params):
    return api.ctx.union.receive_wage(_pid(api))


# ---------------------------------------------------------------- 斗兽场
@endpoint('summonUnionMonster')
def h_summon_monster(api, params):
    return api.ctx.union.summon_monster(_pid(api),
                                        api.param(params, 'monsterMetaId', 0),
                                        api.param(params, 'summonType', 0))


@endpoint('challengeUnionMonster')
def h_challenge_monster(api, params):
    return api.ctx.union.challenge_union_monster(_pid(api), params)


@endpoint('getUnionMonsterRank')
def h_monster_rank(api, params):
    return api.ctx.union.monster_rank(_pid(api))


@endpoint('unionMonsterRewardDistributeBegin')
def h_monster_dist_begin(api, params):
    return api.ctx.union.monster_reward_distribute(_pid(api), True)


@endpoint('unionMonsterRewardDistributeGiveUp')
@endpoint('unionMonsterRewardDistributeSave')
def h_monster_dist_end(api, params):
    return api.ctx.union.monster_reward_distribute(_pid(api), False)


# ---------------------------------------------------------------- 申请 / 审批
@endpoint('applyUnion')
def h_apply_union(api, params):
    return api.ctx.union.apply(_pid(api), api.param(params, 'unionId', 0))


@endpoint('cancelUnionApply')
def h_cancel_apply(api, params):
    return api.ctx.union.cancel_apply(_pid(api), api.param(params, 'unionId', 0))


@endpoint('getUnionAppliers')
def h_union_appliers(api, params):
    return api.ctx.union.applier_list(_pid(api))


@endpoint('acceptUnionApply')
@endpoint('acceptUnion')
def h_accept_union(api, params):
    return api.ctx.union.accept(_pid(api), api.param(params, 'applierUid', 0))


@endpoint('rejectUnionApply')
@endpoint('rejectUnion')
def h_reject_union(api, params):
    return api.ctx.union.reject(_pid(api), api.param(params, 'applierUid', 0))


@endpoint('quitUnion')
@endpoint('forceQuitUnion')
def h_quit_union(api, params):
    return api.ctx.union.quit(_pid(api))


# ---------------------------------------------------------------- 公告 / 搜索
@endpoint('modifyUnionDeclaration')
@endpoint('modifyUnionNotice')
@endpoint('changeUnionDeclaration')
@endpoint('changeUnionNotice')
def h_modify_union(api, params):
    return api.ctx.union.modify(_pid(api), api.param(params, 'declaration', ''),
                                api.param(params, 'notice', ''))


@endpoint('searchUnion')
def h_search_union(api, params):
    return api.ctx.union.search(_pid(api), api.param(params, 'keyword',
                                                     api.param(params, 'name', '')))


@endpoint('cancelDissolveUnion')
def h_cancel_dissolve_union(api, params):
    """撤销「解散军团」的申请。

    ⚠️ 不能和 dissolveUnion 共用实现：客户端调这个接口时**不会**带任何标志参数，
       共用一个函数会导致「取消解散」反而把军团解散掉。
    """
    pid = _pid(api)
    g = api.ctx.union.my(pid)
    if not g:
        return OK, {'sharkUnion': {}, 'sharkUserUnion': {}}
    if int(g['leader_uid']) != int(pid):
        raise ApiError(716301)
    with api.db.tx() as con:
        con.execute("UPDATE guild SET status=0, dissolve_time=0 WHERE guild_id=?",
                    (int(g['guild_id']),))
    return OK, {'sharkUnion': {}, 'sharkUserUnion': {}}


@endpoint('dissolveUnion')
def h_dissolve_union(api, params):
    """解散军团（军团长专属，立即生效）。

    ⚠️ 客户端回调会读 `data.sharkUnion` / `data.sharkUserUnion` 来刷界面，
       返回 `{}` 会让它 index(nil) 崩。解散后这两者都是「已无军团」的空结构。
    """
    pid = _pid(api)
    g = api.ctx.union.my(pid)
    if not g:
        return OK, {'sharkUnion': {}, 'sharkUserUnion': {}}
    if int(g['leader_uid']) != int(pid):
        raise ApiError(716301)
    with api.db.tx() as con:
        con.execute("UPDATE guild SET status=1, dissolve_time=? WHERE guild_id=?",
                    (int(__import__('time').time()), int(g['guild_id'])))
        con.execute("UPDATE guild_member SET status=3 WHERE guild_id=?",
                    (int(g['guild_id']),))
    return OK, {'sharkUnion': {}, 'sharkUserUnion': {}}
