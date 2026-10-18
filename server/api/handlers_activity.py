#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""活动 / 玩法端点。

契约来自 work/api_analysis/contract.py 的扫描结果；
配置来自本地 canon/configs（luaconf）。
本文件只做「取参数 → 调 service → 回 payload」，业务在 services/activities.py。
"""
import time

import gamedata as G
from . import endpoint, ApiError

OK = 200


def _pid(api):
    return api.require_player()['player_id']


# ================================================================ 每日答题
@endpoint('getQuestionInfo')
def h_question_info(api, params):
    """注意：这两个接口客户端读同一组字段，签到式领奖走 daily 那个。"""
    pid = _pid(api)
    if api.ctx is None:
        raise ApiError(710070)
    return api.ctx.activities.question_info(pid)


@endpoint('getQuestionDailyReward')
def h_question_daily_reward(api, params):
    with api.db.tx():
        return api.ctx.activities.question_daily_reward(_pid(api))


@endpoint('getQuestionWeekReward')
def h_question_week(api, params):
    return api.ctx.activities.question_week_reward(_pid(api))


@endpoint('answerQuestion')
def h_answer_question(api, params):
    with api.db.tx():
        return api.ctx.activities.answer_question(
            _pid(api), params.get('answer', ''), api.param(params, 'questionMetaId', 0))


# ================================================================ 通天塔（新）
@endpoint('getSkyTowerInfo')
def h_tower_info(api, params):
    return api.ctx.activities.sky_tower_info(_pid(api))


@endpoint('challengeSkyTower')
def h_tower_challenge(api, params):
    return api.ctx.activities.challenge_sky_tower(
        _pid(api), api.param(params, 'floor', 1), api.param(params, 'type', 0),
        api.param(params, 'version', 0))


@endpoint('resetClimbData')
def h_tower_reset(api, params):
    return api.ctx.activities.reset_climb_data(_pid(api), api.param(params, 'type', 0))


@endpoint('gainFloorAddition')
def h_tower_floor_add(api, params):
    return api.ctx.activities.gain_floor_addition(_pid(api), api.param(params, 'type', 0))


@endpoint('gainYesterdayAddition')
def h_tower_yesterday(api, params):
    return api.ctx.activities.gain_yesterday_addition(_pid(api))


@endpoint('gainRankRewards')
def h_tower_rank_reward(api, params):
    return api.ctx.activities.gain_tower_rank_rewards(_pid(api))


@endpoint('skyTowerSkipBattle')
def h_tower_skip(api, params):
    return api.ctx.activities.tower_skip_battle(_pid(api), api.param(params, 'floor', 0))


@endpoint('skyTowerSkipGainAdd')
def h_tower_skip_add(api, params):
    return api.ctx.activities.tower_skip_gain_add(_pid(api))


@endpoint('skyTowerSkipGainRewards')
def h_tower_skip_rewards(api, params):
    return api.ctx.activities.tower_skip_gain_rewards(_pid(api))


@endpoint('startAutoClimbBabel')
def h_auto_climb(api, params):
    return api.ctx.activities.start_auto_climb(_pid(api))


@endpoint('gainAutoClimbReward')
def h_auto_climb_reward(api, params):
    return api.ctx.activities.gain_auto_climb_reward(_pid(api),
                                                     api.param(params, 'speedUp', False))


# ================================================================ 旧通天塔
@endpoint('challengeBabel')
def h_challenge_babel(api, params):
    return api.ctx.activities.challenge_babel(_pid(api), params)


@endpoint('resetBabel')
def h_reset_babel(api, params):
    return api.ctx.activities.reset_babel(_pid(api))


# ================================================================ 竞技场 / PK
@endpoint('getArenaMatchedPlayers')
def h_arena_matched(api, params):
    return api.ctx.arena.matched_players(_pid(api))


@endpoint('challengeArena')
def h_challenge_arena(api, params):
    return api.ctx.arena.challenge(_pid(api), api.param(params, 'matchedUid', 0),
                                   api.param(params, 'revenge', False))


@endpoint('gainArenaScoreByRank')
def h_arena_rank_reward(api, params):
    return api.ctx.arena.gain_score_by_rank(_pid(api))


@endpoint('buyChallengeNum')
def h_buy_challenge_num(api, params):
    return api.ctx.arena.buy_challenge_num(_pid(api))


@endpoint('exchangeTrainDanByArenaScore')
def h_arena_exchange(api, params):
    return api.ctx.arena.exchange_train_dan(_pid(api),
                                            api.param(params, 'exchangeType', 1))


@endpoint('getPkInfo')
def h_pk_info(api, params):
    return api.ctx.arena.pk_info(_pid(api))


@endpoint('getPkFoes')
def h_pk_foes(api, params):
    return api.ctx.arena.pk_foes(_pid(api))


@endpoint('getPkTopRankUsers')
def h_pk_top(api, params):
    return api.ctx.arena.pk_top_rank(_pid(api))


@endpoint('challengePkUser')
def h_pk_challenge(api, params):
    return api.ctx.arena.challenge(_pid(api), api.param(params, 'opponentUid', 0), True)


@endpoint('gainPkBuff')
def h_pk_buff(api, params):
    return api.ctx.arena.gain_pk_buff(_pid(api), params)


@endpoint('gainPkRewards')
def h_pk_rewards(api, params):
    return api.ctx.arena.gain_pk_rewards(_pid(api), params)


# ================================================================ 世界 Boss
@endpoint('getWorldBossInfo')
def h_world_boss_info(api, params):
    return api.ctx.activities.world_boss_info(_pid(api))


@endpoint('challengeWorldBoss')
def h_challenge_world_boss(api, params):
    return api.ctx.activities.challenge_world_boss(_pid(api), params)


@endpoint('gainWorldBossRewards')
def h_world_boss_rewards(api, params):
    return api.ctx.activities.gain_world_boss_rewards(_pid(api), params)


@endpoint('inspireInWorldBoss')
def h_inspire_world_boss(api, params):
    return api.ctx.activities.inspire_world_boss(_pid(api), params)


@endpoint('setAutoWorldBoss')
def h_set_auto_world_boss(api, params):
    return api.ctx.activities.set_auto_world_boss(_pid(api), params)


# ================================================================ 多人 Boss / 年兽
@endpoint('getMultiplayserBossInfo')
def h_mb_info(api, params):
    return api.ctx.activities.multiplayer_boss_info(_pid(api))


@endpoint('challengeMultiplayerBoss')
def h_mb_challenge(api, params):
    return api.ctx.activities.challenge_multiplayer_boss(_pid(api), params)


@endpoint('getMultiplayerBossRank')
def h_mb_rank(api, params):
    return api.ctx.activities.multiplayer_boss_rank(_pid(api))


@endpoint('getMultiplayerBossDamage')
def h_mb_damage(api, params):
    return api.ctx.activities.multiplayer_boss_damage(_pid(api))


@endpoint('getMultiplayerBossLeftHp')
def h_mb_hp(api, params):
    return api.ctx.activities.multiplayer_boss_left_hp(_pid(api))


@endpoint('gainMultiplayerBossRankReward')
def h_mb_rank_reward(api, params):
    return api.ctx.activities.gain_multiplayer_boss_rank_reward(_pid(api), params)


@endpoint('gainMultiplayerBossParticipationReward')
def h_mb_part_reward(api, params):
    return api.ctx.activities.gain_multiplayer_boss_participation_reward(_pid(api), params)


@endpoint('buyActionPower')
def h_buy_action_power(api, params):
    return api.ctx.activities.buy_action_power(_pid(api), params)


# ================================================================ 消费送好礼
@endpoint('getGemConsumeInfo')
def h_gem_consume_info(api, params):
    return api.ctx.activities.get_gem_consume_info(_pid(api))


@endpoint('gainGemConsumeRewards')
def h_gain_gem_consume(api, params):
    return api.ctx.activities.gain_gem_consume_rewards(
        _pid(api), api.param(params, 'rewardId', 0))


# ================================================================ 累充 / 限时充值
@endpoint('getRechargeInfo')
def h_recharge_info(api, params):
    return api.ctx.activities.recharge_info(_pid(api))


@endpoint('gainChargeMoneyReward')
def h_gain_charge(api, params):
    return api.ctx.activities.gain_charge_money_reward(_pid(api),
                                                       api.param(params, 'rewardId', 0))


@endpoint('gainLimitReward')
def h_gain_limit(api, params):
    return api.ctx.activities.gain_limit_reward(_pid(api), api.param(params, 'stepId', 0))


# ================================================================ 连登
@endpoint('getContinuousLoginReward')
@endpoint('getContinueLoginReward')
def h_cont_login(api, params):
    return api.ctx.activities.continuous_info(_pid(api))


@endpoint('gainContinuousLoginRewardV2')
def h_gain_cont_v2(api, params):
    return api.ctx.activities.gain_continuous(_pid(api), api.param(params, 'day', 1), True)


# ================================================================ 吹气球
@endpoint('getActivityBalloonInfo')
def h_balloon_info(api, params):
    return api.ctx.activities.get_balloon_info(_pid(api))


@endpoint('chargeBalloon')
def h_balloon_charge(api, params):
    return api.ctx.activities.charge_balloon(_pid(api), params)


@endpoint('gainBalloonPoint')
def h_balloon_point(api, params):
    return api.ctx.activities.gain_balloon_point(_pid(api), params)


@endpoint('gainBalloonPointReward')
def h_balloon_point_reward(api, params):
    return api.ctx.activities.gain_balloon_point_reward(_pid(api),
                                                        api.param(params, 'id', 0))


@endpoint('gainBalloonRankReward')
def h_balloon_rank_reward(api, params):
    return api.ctx.activities.gain_balloon_rank_reward(_pid(api), params)


# ================================================================ 骰子
@endpoint('throwDice')
def h_throw_dice(api, params):
    return api.ctx.activities.throw_dice(_pid(api), params)


@endpoint('gainDiceReward')
def h_gain_dice(api, params):
    return api.ctx.activities.gain_dice_reward(_pid(api), params)


@endpoint('changeDiceLuck')
def h_change_dice(api, params):
    return api.ctx.activities.change_dice_luck(_pid(api), params)


# ================================================================ 通缉令
@endpoint('getWantedInfo')
def h_wanted_info(api, params):
    return api.ctx.activities.get_wanted_info(_pid(api))


@endpoint('refreshWanted')
def h_refresh_wanted(api, params):
    return api.ctx.activities.refresh_wanted(_pid(api), api.param(params, 'minimum', 0))


@endpoint('challengeWanted')
def h_challenge_wanted(api, params):
    return api.ctx.activities.challenge_wanted(_pid(api), params)


# ================================================================ 秒杀
@endpoint('getSeckillInfo')
def h_seckill_info(api, params):
    return api.ctx.activities.get_seckill_info(_pid(api))


@endpoint('buySeckillItem')
@endpoint('seckillBuy')
def h_seckill_buy(api, params):
    return api.ctx.activities.buy_seckill_item(_pid(api), api.param(params, 'id', 0))


# ================================================================ 神兵谱
@endpoint('getTreasureboxPointsInfo')
def h_tb_info(api, params):
    return api.ctx.activities.treasurebox_info(_pid(api))


@endpoint('gainTreasureboxPointsReward')
def h_tb_point(api, params):
    return api.ctx.activities.gain_treasurebox_point_reward(_pid(api),
                                                            api.param(params, 'id', 0))


@endpoint('gainTreasureboxPointsRankReward')
def h_tb_rank(api, params):
    return api.ctx.activities.gain_treasurebox_rank_reward(_pid(api), params)


# ================================================================ 扭蛋 / 小玉嫁到
@endpoint('getGachaPointsInfo')
def h_gp_info(api, params):
    return api.ctx.activities.gacha_points_info(_pid(api))


@endpoint('gainGachaPointsRewards')
def h_gp_reward(api, params):
    return api.ctx.activities.gain_gacha_points_rewards(_pid(api), params)


@endpoint('getCrossGachaInfo')
def h_cross_gacha(api, params):
    return api.ctx.activities.cross_gacha_info(_pid(api))


# ================================================================ 多重好礼
@endpoint('getConsumeRewardInfo')
def h_consume_info(api, params):
    return api.ctx.activities.consume_reward_info(_pid(api))


@endpoint('gainConsumeReward')
def h_gain_consume(api, params):
    return api.ctx.activities.gain_consume_reward(_pid(api), api.param(params, 'id', 0))


# ================================================================ 其他活动
@endpoint('gainDayReward')
def h_gain_day(api, params):
    return api.ctx.activities.gain_day_reward(_pid(api),
                                              api.param(params, 'dayRewardId', 0))


@endpoint('gainSwornReward')
def h_gain_sworn(api, params):
    return api.ctx.activities.gain_sworn_reward(_pid(api),
                                                api.param(params, 'swornRewardId', 0))


@endpoint('recordPraiseId')
def h_record_praise(api, params):
    return api.ctx.activities.record_praise_id(_pid(api), api.param(params, 'praiseId', 0))


@endpoint('gainPraiseReward')
def h_gain_praise(api, params):
    return api.ctx.activities.gain_praise_reward(_pid(api), api.param(params, 'praiseId', 0))


@endpoint('setoffFireworks')
def h_fireworks(api, params):
    return api.ctx.activities.setoff_fireworks(_pid(api), params)


@endpoint('gainFortuneRewards')
def h_fortune(api, params):
    return api.ctx.activities.gain_fortune_rewards(_pid(api), params)


@endpoint('getLevelRaceInfo')
def h_level_race_info(api, params):
    return api.ctx.activities.level_race_info(_pid(api))


@endpoint('gainLevelRaceRewards')
def h_level_race_reward(api, params):
    return api.ctx.activities.gain_level_race_rewards(_pid(api), params)


# ================================================================ 月卡
@endpoint('getAccumulateGems')
def h_accumulate_gems(api, params):
    return api.ctx.activities.get_accumulate_gems(_pid(api))


@endpoint('buyMonthGemCard')
def h_buy_month_card(api, params):
    return api.ctx.activities.buy_month_gem_card(_pid(api), params)


@endpoint('getBuyMonthGemCardResult')
def h_month_card_result(api, params):
    return api.ctx.activities.month_card_result(_pid(api), params)


# ================================================================ 以旧换新 / 易帅换将
@endpoint('refreshCardExchangeDaillyCard')
def h_refresh_card_exchange(api, params):
    return api.ctx.activities.refresh_card_exchange(_pid(api),
                                                    api.param(params, 'useGold', False))


# ================================================================ 日常签到（月历）
@endpoint('getSignInReward')
@endpoint('getLoginReward')
def h_sign_in(api, params):
    return api.ctx.activities.sign_in(_pid(api), api.param(params, 'type', 0))
