#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 363 个接口映射到 server/schema.sql 里的表，产出：
     work/api_analysis/table_map.json
     work/api_analysis/table_map.csv
   并在后面用于生成文档章节。
"""
import os, re, io, sys, json, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
REC = json.load(open(os.path.join(HERE, 'records.json'), encoding='utf-8'))

# ---------------------------------------------------------------- 规则表
# 两级：
#   PRIMARY —— 有序，**首个命中**决定主表组（回答「这个接口围绕哪张表转」）
#   EXTRA   —— **全部命中**累加补充表（回答「还要顺带动哪些表」）
PRIMARY = [
    # 账号 / 会话 / 元数据
    (r'^(login|loginServer|createUser|geneNickname|getServerStatus|getSocketServer|'
     r'getServerTimeStamp|getUserBanInfo|recordTutorialStep|rename|bindAccount|'
     r'getMaintenanceMeta|getMeta|gameInit|speakLimitStutas|getHomeInfo|upgradeUser)$',
     ['account', 'account_binding', 'player', 'player_extend', 'player_tutorial_step']),

    # 邮件
    (r'[Mm]ail|[Nn]otice', ['mail', 'mail_attachment', 'sys_email_meta']),

    # 军团（细分，见 EXTRA）
    (r'[Uu]nion|gvg|Gvg|GVG', ['guild', 'guild_member']),

    # 竞技 / PK / 跨服 PVP
    (r'[Aa]rena|[Cc]rossPvp|crossPk|CrossPk|^pk[A-Z]|PkUser|PkFoes|PkInfo|PkBuff|PkReward|'
     r'PkTop|refreshMatch|challengeCrossUser',
     ['arena_rank', 'pk_record']),

    # 元神
    (r'[Ss]pirit|subAttribute', ['player_spirit', 'player_spirit_attr', 'player_spirit_unsaved']),

    # 宝物
    (r'[Tt]reasure', ['player_treasure']),

    # 抽卡
    (r'[Gg]acha', ['player_card', 'player_card_skill', 'player_counter', 'gacha_log', 'id_alloc']),

    # 技能升级（卡牌技能 + 消耗道具）
    (r'^upgradeSkill$', ['player_card_skill', 'player_prop', 'player']),

    # 卡牌
    (r'[Cc]ard|card', ['player_card', 'player_card_skill']),

    # 装备
    (r'[Ee]quip', ['player_equip', 'player_card']),

    # 关卡 / 战斗 / 精英
    (r'^(clearMission|clearElite|challengeElite|eliteSweep|resetElite|getEliteInfo|resetClearTime|'
     r'changeBattleArray|trigger[A-Z]|getMissionCompleteInfo|gainChapterFinishReward|'
     r'buyMissionCompleteCount|missionComplete|challengeBabel)',
     ['player_mission_context', 'player_scene_process', 'player_mission_complete']),

    # 通天塔
    (r'[Bb]abel|[Ss]kyTower|climb|Climb|floorAddition|yesterdayAddition|resetClimb|'
     r'^gainRankRewards$|^resetClearTime$',
     ['player_sky_tower']),

    # 宿命对决 / 圣诞
    (r'[Dd]estiny', ['player_activity', 'pk_record']),
    (r'[Cc]hrist', ['player_christ', 'player_activity']),

    # 好友 / 社交
    (r'[Ff]riend|[Ii]nvitation|[Ff]reeGift', ['friend', 'friend_invitation']),
    (r'[Pp]raise', ['player_praise']),
    (r'[Bb]onus|[Rr]edPacket', ['red_packet', 'red_packet_claim']),
    (r'[Ii]nviteCode|inviteReward|invitedReward|InvitationInfo|getInvitationInfo',
     ['player_invite_code']),
    (r'[Ff]acebook|fbShare', ['player_activity']),

    # 签到 / 连登
    (r'signIn|SignIn|Signin|getSigninReward', ['player_sign_in']),
    (r'[Cc]ontinueLogin|continuousLogin|LoginReward|getLoginReward',
     ['player_continuous_login', 'player_continuous_login_v2']),
    (r'[Mm]onthGemCard|GemCard|getAccumulateGems', ['player_gem_card', 'payment_order']),

    # 道具 / 背包 / 商店
    (r'^(useProp|sellProps|getProps|buyGoods|buyGrid|buyUnionProp|useEnergy|exchangeMedalShop|'
     r'getMedalShopList|exchangeMysteriousItem|seckillBuy|seckillGetInfo|exchangeGiftBag|'
     r'getSecretShopList|exchangeSecretShop|refreshSecretShop|refreshMedalShop|'
     r'synthetizeItem|buyTreasureGrid|buy[A-Z]|item)',
     ['player_prop', 'player_secret_shop']),

    # 活动 / 玩法（大兜底，放在道具之后）
    (r'[Aa]ctivity|Active|Balloon|Fireworks|Question|Wanted|Sworn|GoldGod|Fortune|'
     r'LevelRace|GachaPoints|Treasurebox|ConsumeReward|EatPeach|CowStage|Seckill|'
     r'PhoneCharge|Christmas|NewYear|Monday|Festival|Wishing|Fountain|Contend|Dice|'
     r'WorldBoss|MultiplayerBoss|CrossBoss|beast|Beast|ItemRebirth|ItemSacrifice|'
     r'Enchant|Matrix|energy|Energy|ActionPower|ChallengeNum|EventPoint|SkipBattle|'
     r'AddictedTime|Announcement|DayReward|WeekReward|LimitReward|GemConsume|'
     r'Question|ThrowDice|rebirthItem|sacrificeItem|eatPeach|wishing|exchangeItem|'
     r'Wishing|EatPeach|ExchangeItem',
     ['player_activity']),

    # 任务 / 成就 / 每日
    (r'[Tt]ask|[Aa]chieve|dailyActive|DailyAchieve|Reward',
     ['player_daily', 'player_daily_counter']),

    # 充值
    (r'[Pp]ayment|[Oo]rder|recharge|Recharge|chargeMoney|ChargeMoney|phoneCharge|PhoneCharge',
     ['payment_order', 'charge_log']),

    # 排行
    (r'[Rr]ank', ['rank_board']),

    # 兜底
    (r'\.', ['player']),
]

EXTRA = [
    # 军团细分
    (r'[Ff]ormation', ['guild_formation_slot', 'guild_formation_team']),
    (r'[Uu]nionMonster|challengeUnionMonster|summonUnionMonster|unionMonsterReward|'
     r'gainUnionBattleReward|unionMonsterRewardDistribute|UnionMonsterRank',
     ['guild_monster', 'guild_monster_damage', 'guild_monster_allocate']),
    (r'[Uu]nionCity|applyUnionCity|CityInfo|CityList|userApplyUnionCity',
     ['guild_city', 'guild_city_apply']),
    (r'[Uu]nionBuilding|constructUnion|upgradeUnionBuilding|UnionConstruct|'
     r'BuildingHall|BuildingBank|BuildingShop|BuildingColosseum',
     ['guild_building', 'guild_donate_log', 'guild_shop_record']),
    (r'[Uu]nionNews|unionWarNews|getUnionNews|[Nn]ewsList', ['guild_news']),
    (r'[Uu]nionAppl|applyUnion|acceptUnionApply|rejectUnion|rejectAllUnion|'
     r'cancelUnionApply|getUnionAppliers|getMyApplyList|getAppliedUnions',
     ['guild_apply']),
    (r'[Uu]nionMember|appointUnion|kickUnion|transferUnion|impeachUnion|quitUnion|'
     r'forceQuitUnion|getUnionMembersList|receiveUnionWage|getFiredUnionMemberStatus|'
     r'unionFormation|getUnionFormation|exchangeUnionFormation|UnionColosseum|'
     r'[Ii]nspireUnion|gainUnionWar|blessForCrossGVG',
     ['guild_member']),
    (r'gvg|Gvg|GVG|Battlefield|battleReport|BattleResultDetail|TeamMirror|Knockout|'
     r'WarcityMembers|GvgGroup|CrossGvg',
     ['cross_gvg_apply', 'cross_gvg_score', 'cross_gvg_formation', 'cross_gvg_report',
      'cross_gvg_group', 'cross_gvg_bless', 'cross_gvg_bless_log',
      'guild_formation_slot', 'guild_formation_team', 'guild_battle_report']),
    (r'getUnionList|searchUnion|createUnion|dissolveUnion|cancelDissolveUnion|'
     r'getUnionInfo|getOwnUnionInfo|getUserUnionInfo|modifyUnionDeclaration|'
     r'modifyUnionNotice|changeUnion|unionWealth',
     ['guild']),

    # 资产补充
    (r'[Ss]pirit|subAttribute', ['player_extend']),
    (r'[Tt]reasure', ['player_card', 'player_extend']),
    (r'[Ff]ragment', ['player_fragment']),
    (r'[Cc]ard|card', ['player_prop', 'id_alloc']),
    (r'[Ee]quip', ['player_prop']),

    # 关卡补充
    (r'^(clearMission|clearElite|eliteSweep|challengeElite|resetElite|trigger[A-Z])',
     ['player_elite', 'player_daily_counter', 'player_prop']),

    # 背包容量 / 购买次数
    (r'buyGrid|buySpiritPool|boughtGrid', ['player_extend', 'player_daily_counter']),
    (r'^buy[A-Z]|buyEnergy|buyEventPoint|buyActionPower|buyChallengeNum|buyMissionCompleteCount',
     ['player_daily_counter', 'player']),

    # 阵容
    (r'changeBattleArray|adjustTeam|replaceCard|setCardGroupInterworking|getPlayerTeamInfo|'
     r'Matrix',
     ['player_battle_array', 'player_battle_slot', 'player_matrix', 'player_matrix_grid']),

    # 排行 / 奖励
    (r'[Rr]ank', ['rank_board']),
    (r'^(gain|pickUp|claim)|Reward', ['player_activity_reward_claim']),
    (r'[Pp]raise|Invite|invite|Sworn|Charge|charge|MonthCard|GemCard|Seckill|'
     r'Treasurebox|Question|GoldGod|Fortune|LevelRace|GachaPoints|ConsumeReward|'
     r'NewYear|Monday|Festival|Contend|Christmas|Dice|Wish|Wishing|EatPeach|CowStage',
     ['player_activity_reward_claim']),

    # 每日
    (r'[Cc]hallenge|[Rr]eset|gacha|Gacha|buy|Buy|use|Use|daily|Daily|signIn|SignIn|'
     r'Dice|throw|Throw|Question|answer|Answer',
     ['player_daily']),
    (r'buy|Buy|[Rr]eset|challenge|Challenge|use|Use|daily|Daily',
     ['player_daily_counter']),

    # 玩家本体
    (r'[Cc]oin|coin|gem|Gem|energy|Energy|eventPoint|EventPoint|Exp|exp|Level|level|'
     r'gold|Gold|silver|medal|Medal|friendPoint|generalExp|astralEssence|vip|Vip|VIP',
     ['player']),
    (r'^(gain|Gain|buy|Buy|use|Use|upgrade|Upgrade|evolve|Evolve|sell|Sell|split|Split|'
     r'synthetize|Synthetize|exchange|Exchange|charge|Charge|recharge|Recharge|'
     r'validatePaymentOrder|eatPeach|inspire|throwDice|setoffFireworks|wishing)',
     ['player']),
]

WRITE_PREFIX = re.compile(
    r'^(gain|buy|use|upgrade|evolve|set|refresh|challenge|exchange|sell|split|synthetize|'
    r'create|delete|accept|refuse|send|setup|unequip|equip|lock|unlock|reset|answer|throw|'
    r'change|adjust|rename|bind|record|distribute|inspire|eat|charge|throw|pickUp|claim|'
    r'validate|sign|receive|apply|appoint|kick|quit|dissolve|construct|transfer|impeach|'
    r'reject|cancel|start|finish|rob|avoid|wish|setoff|fire|draw|roll|select|insert|'
    r'remove|replace|modify|submit|upload|save|giveUp|pay|recharge|open|buy)')
READ_PREFIX = re.compile(r'^(get|list|search|query|gene|has|is|check|fetch|load|make)')


def tables_for(r):
    m = r['method']
    t = []
    for pat, tabs in PRIMARY:
        if re.search(pat, m):
            t.extend(tabs)
            break
    for pat, tabs in EXTRA:
        if re.search(pat, m):
            for x in tabs:
                if x not in t:
                    t.append(x)
    # 顺序：主表在前，其余按名字
    return t


# 名字有误导性的接口，手工纠正「读/写」判定
OP_OVERRIDE = {
    # 名字像 get，实际是「领取」→ 会写
    'getSignInReward': '写', 'getLoginReward': '写', 'getEnchantStepReward': '写',
    'getCountdownReward': '写', 'getChargeFeedbackReward': '写', 'getDailyRecharge': '写',
    'getContinuousLoginReward': '写', 'getBuyMonthGemCardResult': '写',
    # 会话/元数据类
    'gameInit': '读', 'login': '读', 'loginServer': '读', 'getMeta': '读',
    'logout': '写', 'online': '写', 'offline': '写',
    'challengeArena': '写', 'challengeBabel': '写', 'challengeElite': '写',
}


def op_kind(m):
    if m in OP_OVERRIDE:
        return OP_OVERRIDE[m]
    if READ_PREFIX.match(m):
        return '读'
    if WRITE_PREFIX.match(m):
        return '写'
    return '读'

rows = []
for r in REC:
    tabs = tables_for(r)
    rows.append({
        'method': r['method'],
        'category': r['category'],
        'op': op_kind(r['method']),
        'tables': tabs,
        'server_implemented': r['server_impl'],
        'params': sorted(k for k in r['params'] if k not in ('*dynamic*', 'serverId')),
        'response_fields': sorted(r['response_fields']),
    })

json.dump(rows, open(os.path.join(HERE, 'table_map.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)

import csv
with open(os.path.join(HERE, 'table_map.csv'), 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.writer(f)
    w.writerow(['method', '操作', '分类', '涉及表', '请求参数', '响应字段', '服务端已实现'])
    for r in rows:
        w.writerow([r['method'], r['op'], r['category'], '|'.join(r['tables']),
                    '|'.join(r['params']), '|'.join(r['response_fields']),
                    'Y' if r['server_implemented'] else 'N'])

cnt = collections.Counter()
for r in rows:
    for t in r['tables']:
        cnt[t] += 1
print('接口 %d 个，映射到 %d 张表' % (len(rows), len(cnt)))
print()
print('表热度（被多少接口涉及）:')
for t, c in cnt.most_common():
    print('   %-32s %3d' % (t, c))

unmapped = [r['method'] for r in rows if r['tables'] == ['player'] and not re.search(
    r'player|user|login|account|tutorial|ban|server|meta', r['method'], re.I)]
print()
print('只兜底到 player 的接口（%d 个，建议人工确认）:' % len(unmapped))
print('   ' + ', '.join(unmapped[:60]))
