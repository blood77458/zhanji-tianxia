#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""组装层：数据库表行 → 客户端契约 JSON。

这是**唯一**允许出现客户端字段名（camelCase）的模块。repository 只认数据库，
handler 只负责调 assembler，谁都不许在这里写 SQL 以外的东西。

三条铁律（详见 SERVER_DATA_MODEL.md §5.2）：
  1. 数组永远是数组（Lua 空表为真，编成对象会让 ipairs 读不到东西）
  2. 要么给全、要么别给（绝不下发 {} 顶掉客户端默认值）
  3. uid / additionalCardIds 是字符串，其余数字是数字
"""
import json
import os
import time

# 是否让「七日登录奖励」弹窗按真实状态弹出。
# 默认 0 = 标记为已领完（抑制弹窗），因为该弹窗每次回主界面都会重开并挡住点击，
# 会让 UI 自动化测试无法进行。设 CANON_SHOW_CONTINUOUS_LOGIN=1 恢复真实行为。
SHOW_CONTINUOUS_LOGIN = os.environ.get('CANON_SHOW_CONTINUOUS_LOGIN', '0') == '1'

# 客户端 ResourceEnum（RewardManager.lua）
RE_COIN, RE_EXP, RE_ENERGY, RE_GEMS, RE_EQUIP = 1, 4, 5, 6, 6

# 全部新手引导的 funcName（取自 canon/script_and_guide/Guide_*.lua 与
# canonUtils.ExeNewGuide 的调用点）。旧服务端对「回归玩家」直接把这份清单
# 当成 tutorialSteps 下发，让客户端认为引导已全部完成 —— 否则
# MainMenuScene:321 会 setDispatchEvents(false) 锁住输入，界面点不动。
DONE_TUTORIAL_STEPS = [
    {'funcName': 'Guide_EnterGame%d' % i, 'step': 1} for i in range(1, 11)
] + [
    {'funcName': n, 'step': 1} for n in (
        # ⚠️ 这份清单要和客户端**全部** Guide_ 名字对齐（`grep '"Guide_' work/luasrc`）。
        # 少一个都不行：客户端只要发现有一条未完成，就会从那条开始重跑引导，
        # 期间 setDispatchEvents(false) 锁住输入。实测漏掉 Guide_Lineup* 时，
        # 进「队伍」会被「点击此处进入缘分互通」的提示卡死，连返回箭头都点不动。
        'Guide_EquipUpgrade', 'Guide_Elite', 'Guide_CardOn', 'Guide_EquipQuality',
        'Guide_Arena', 'Guide_Beast', 'Guide_Change_Card', 'Guide_CardTrain',
        'Guide_Sacrifice', 'Guide_TreasureBox', 'Guide_Treasure',
        'Guide_MultiLineupBox', 'Guide_MultiLineup', 'Guide_CrossPVP',
        'Guide_CrossPVPBox', 'Guide_Matrix',
        'Guide_CardFate', 'Guide_Lineup1', 'Guide_Lineup3',
        'Guide_MagicCircle', 'Guide_Save_State',
    )
]


def _j(text, default):
    """宽松解析 *_json 列：空/坏数据回退到默认值，绝不返回 None。"""
    if not text:
        return default
    if isinstance(text, (list, dict)):
        return text
    try:
        v = json.loads(text)
    except Exception:
        return default
    return v if isinstance(v, type(default)) else default


def _split_ids(text):
    out = []
    for part in str(text or '').split(','):
        part = part.strip()
        if part.isdigit():
            out.append(int(part))
    return out


# ============================================================ 角色
def build_shark_user(p, ext, now=None, fight_capacity=None):
    """player + player_extend → 客户端 `sharkUser`。

    ⚠️ uid 必须是**字符串**：CreateCharacterScene 调
       CanonEnvInjector:setGspGameUserId(java.lang.String)V，
       luajava 不会把 Lua number 转成 String，传数字 → SIGKILL。
    ⚠️ additionalCardIds 必须是**逗号字符串**：CommonManager.getQueueData()
       直接对它 :split(",")，nil 或 table 都会崩。
    """
    now = now or int(time.time())
    nick = p['nickname'] or '测试主公'
    return {
        'uid': str(p['player_id']),          # 字符串！
        'serverId': int(p['server_id']),
        'nickname': nick,                    # 两种拼写都下发：老 UI 读 nickname，新 UI 读 nickName
        'nickName': nick,
        'level': int(p['level']),
        'exp': int(p['exp']),
        'gold': int(p['gold']),
        'coins': int(p['gold']),             # BaseUIScene.lua:447 setString(userData.coins)
        'gem': int(p['gem']),
        'silver': int(p['silver']),
        # --- 这 4 个必须同时存在，calcComplex_getGemsNow 做四则运算 ---
        'freeGems': int(p['free_gems']),
        'usedFreeGems': int(p['used_free_gems']),
        'rechargeGems': int(p['recharge_gems']),
        'usedRechargeGems': int(p['used_recharge_gems']),
        'vipLevel': int(p['vip_level']),
        'vipExp': int(p['vip_exp']),
        # --- 体力 / 精力：带更新时间戳，客户端自己按秒恢复 ---
        'energy': int(p['energy']),
        'energyLastUpdateTime': int(p['energy_last_update_time'] or now),
        'eventPoint': int(p['event_point']),
        'eventPointLastUpdateTime': int(p['event_point_last_update_time'] or now),
        'actionPower': int(p['action_power']),
        'createTime': int(p['create_time']),
        'lastLoginTime': int(p['last_login_time'] or now),
        'fightCapacity': int(fight_capacity if fight_capacity is not None else (p['fight_capacity'] or 0)),
        'leadership': int(p['leadership']),
        'guideStep': int(p['guide_step']),
        'newGuideStep': int(p['new_guide_step']),
        # 主将位：CommonManager.getQueueData() 只认这两个字段
        'mainCardId': int(p['main_card_id']),
        'additionalCardIds': p['additional_card_ids'] or '',
    }


def build_shark_extend(p, ext, steps, sign_in, cont_login, claims, now=None,
                       fight_capacity=None):
    """→ 客户端 `sharkUserExtend`。
    这里的字段被 canonUtils.IsGuideExecuted 之类**无 nil 守卫**地解引用，
    少一个就是 SIGKILL，所以全部给默认值。"""
    blob = _j(ext['extend_json'], {})
    return {
        'fightCapacity': int(fight_capacity if fight_capacity is not None else (p['fight_capacity'] or 0)),
        # --- 列表 ---
        # steps 已经是 [{'funcName':..,'step':..}, ...]；**不能**再 int()，
        # 客户端读的是 v.funcName（见 build_game_init 里的说明）。
        'tutorialSteps': steps,
        'cardGroupInterworking': blob.get('cardGroupInterworking', []),
        'countdownFreeGachaInfos': blob.get('countdownFreeGachaInfos', []),
        'gainedChargeMoneyRewardList': [c['reward_id'] for c in claims if c['scope'] == 'charge_money'],
        'lifeLimitGoods': blob.get('lifeLimitGoods', []),
        'lstEatPeachInfo': blob.get('lstEatPeachInfo', []),
        'paidChannelNames': blob.get('paidChannelNames', []),
        'vipPackages': blob.get('vipPackages', []),
        # --- 字典 ---
        # 以下 5 个字段旧服务端（已验证可玩）有、分层版曾漏掉；
        # 客户端多处无 nil 守卫地解引用它们，少一个就可能 SIGKILL。
        'battleArrayId': int(blob.get('battleArrayId', 0) or 0),
        'continuousLoginRewardInfoV2': blob.get('continuousLoginRewardInfoV2', {}),
        'doubleChargeInfo': blob.get('doubleChargeInfo',
                                     {'doubleCharge': False, 'version': 0}),
        'medalNum': int(blob.get('medalNum', 0) or 0),
        'treasureInfo': blob.get('treasureInfo', {'treasureFragmentNum': 0}),
        'continuousLoginInfo': {
            'firstGetRewardTime': int(cont_login['first_get_reward_time']) if cont_login else 0,
            'latestGetRewardTime': int(cont_login['latest_get_reward_time']) if cont_login else 0,
            'gainRewards': _j(cont_login['gain_rewards_json'], []) if cont_login else [],
            'gainRewardInOrder': int(cont_login['gain_reward_in_order']) if cont_login else 0,
            'getBigReward': int(cont_login['get_big_reward']) if cont_login else 0,
        },
        'countdownRewardInfo': blob.get('countdownRewardInfo', {}),
        'exchangeGiftBagInfo': blob.get('exchangeGiftBagInfo', {}),
        'signInInfo': {
            'loginDaysMonth': int(sign_in['login_days_month']) if sign_in else 0,
            'getRewardTimeStamp': int(sign_in['last_reward_time']) if sign_in else 0,
        },
        # --- 数字 ---
        'astralEssence': int(p['astral_essence']),
        'boughtGridNum': int(ext['bought_grid_num']),
        'boughtGridTimes': int(ext['bought_grid_times']),
        'boughtSpiritPoolNum': int(ext['bought_spirit_pool_num']),
        'friendPoint': int(p['friend_point']),
        'generalExp': int(p['general_exp']),
        'lastRenameTimes': int(p['last_rename_times']),
        'renameCd': int(p['rename_cd']),
        'seniorGachaTenTimes': int(ext['senior_gacha_ten_times']),
        'enchantStepReward': bool(ext['enchant_step_reward']),
    }


def build_shark_extend_more(p, ext, cont_v2, now=None):
    """→ 客户端 `sharkUserExtendMore`。

    注意：原服务端把这些字段混在 sharkUserExtend 里也发了一份。客户端实际
    读的是 **ExtendMore**（`DataManager.getGameInitData().sharkUserExtendMore
    .battleArrayId`），放在 Extend 里读不到。
    """
    v2 = _j(cont_v2['gained_rewards_json'], []) if cont_v2 else []
    gain_days = int(cont_v2['gain_reward_days']) if cont_v2 else 0
    if not SHOW_CONTINUOUS_LOGIN:
        # 把七日连登标记成「已领完」。
        # canonUtils.shouldPopContinueLoginPanelToday: 当
        #   #gainedContinuousLoginRewards >= 7 且 paraOffsetDay 为 nil（主界面那次调用）
        # 时 isEnable=false，于是回主界面不会自动弹「七日登录奖励」。
        # 否则该弹窗每次回主界面都出现并挡住点击，UI 自动化测不动。
        # 想看真实弹出：设 CANON_SHOW_CONTINUOUS_LOGIN=1
        gain_days = int((now or time.time()) + 28800) // 86400
        v2 = [1, 2, 3, 4, 5, 6, 7]
    return {
        'battleArrayId': int(ext['battle_array_id']),     # CardQueueScene / BackpackScene 索引用
        'treasureInfo': {
            'treasureFragmentNum': int(ext['treasure_fragment_num']),
            'buyGridTimes': int(ext['treasure_buy_grid_times']),
        },
        'doubleChargeInfo': {'doubleCharge': False, 'version': 0},
        'medalNum': int(p['medal_num']),
        'continuousLoginRewardInfoV2': {
            'gainRewardDays': gain_days,
            'gainedContinuousLoginRewards': v2,
        },
    }


# ============================================================ 资产
def build_card(card, skills, equips, spirits, treasure_id=0, now=None, treasure=None):
    """→ `sharkCards.sharkCards[]` 的一项。

    equipIds / cardSpirits / treasureId 都是**反查**出来的（单点存储原则）：
    唯一权威数据是 player_equip.card_id / player_spirit.card_id /
    player_treasure.card_id。

    fightCapacity 按客户端原公式（CommonManager:410-412）逐卡算，
    含该卡身上的装备 / 宝物 / 元神加成。
    """
    from services import cardstats as CS
    import gamedata as G
    att = CS.card_attributes(card)
    for e in equips or []:
        if isinstance(e, dict):
            att = CS.sum_attributes(att, CS.equip_attributes(e))
    for s in spirits or []:
        if isinstance(s, dict):
            att = CS.sum_attributes(att, CS.spirit_attributes(s))
    if treasure is not None:
        att = CS.sum_attributes(att, CS.treasure_attributes(treasure))
    return {
        'cardId': int(card['card_id']),
        'metaId': int(card['meta_id']),
        'avatarMetaId': (int(card['avatar_meta_id'])
                         if int(card['avatar_meta_id']) and G.card_meta_exists(int(card['avatar_meta_id']))
                         else 0),
        'level': int(card['level']),
        'exp': int(card['exp']),
        'cardGroupId': int(card['card_group_id']),
        'fightCapacity': CS.fight_capacity(att['att'], att['def'], att['hp']),
        'equipIds': [int(e['equip_id']) for e in equips],
        'cardSpirits': [int(s['spirit_id']) for s in spirits],
        # treasureId 由 player_treasure.card_id 反查得到；0 表示未装备。
        # **绝不能是 None**：CommonManager 判的是 `~= 0`，nil ~= 0 在 Lua 为真。
        'treasureId': int(treasure_id or 0),
        'skillLevels': [],
        # cardSkills 空 + card_meta.skill ~= 0 → QueueCardPanel 索引 nil → SIGKILL
        'cardSkills': [{
            'skillType': int(s['skill_type']),
            'skillId': int(s['skill_id']),
            'currQuality': int(s['curr_quality']),
            'cardGroupIds': _split_ids(s['card_group_ids']),
            'countryGroupId': int(s['country_group_id']),
            'countryGroupNum': int(s['country_group_num']),
        } for s in skills],
        'attTrainValue': int(card['att_train_value']),
        'defTrainValue': int(card['def_train_value']),
        'hpTrainValue': int(card['hp_train_value']),
        'attEvolveValue': int(card['att_evolve_value']),
        'defEvolveValue': int(card['def_evolve_value']),
        'hpEvolveValue': int(card['hp_evolve_value']),
        'usedPotential': int(card['used_potential']),
        'lock': bool(card['is_locked']),
    }


def build_equip(e):
    return {
        'equipId': int(e['equip_id']),
        'metaId': int(e['meta_id']),
        'level': int(e['level']),
        'exp': int(e['exp']),
        'cardId': int(e['card_id']),
        'enchantLevel': int(e['enchant_level']),
        'enchantNum': int(e['enchant_num']),
    }


def build_spirit(s, attrs):
    return {
        'spiritId': int(s['spirit_id']),
        'metaId': int(s['meta_id']),
        'level': int(s['level']),
        'exp': int(s['exp']),
        'cardId': int(s['card_id']),
        'lockAttributeIndex': int(s['lock_attribute_index']),
        'sharkSpiritAttributes': [{
            'attributeType': int(a['attribute_type']),
            'attributeGrowing': float(a['attribute_growing']),   # 客户端做浮点乘法
        } for a in attrs],
    }


def build_treasure(t):
    return {
        'treasureId': int(t['treasure_id']),
        'metaId': int(t['meta_id']),
        'level': int(t['level']),
        'addPotential': int(t['add_potential']),
        'addGemPotential': int(t['add_gem_potential']),
        'usedPotential': int(t['used_potential']),
        'cardId': int(t['card_id']),
        'lock': bool(t['is_locked']),
    }


# ============================================================ 阵容
def build_battle_arrays(rows, slots, equips, spirits, treasures, matrices, grids):
    """→ `sharkUserBattleArray`。

    客户端结构（ChangeBattleArrayRequest.onSucceedDefault 是权威来源）：
      [arrayId] = { sharkUserQueue=[{cardId,equips[],spirits[],treasureId}],
                    sharkMatrices={sharkMatrices=[{matrixId,sharkMatrixGrids=[...]}]} }
    索引是 **1-based**：客户端 `sharkUserBattleArray[nowId]`，nowId 从 1 开始。

    槽位里的 equips / spirits / treasureId **不落库**，全部从「谁穿了什么」反查：
      player_equip.card_id / player_spirit.card_id / player_treasure.card_id
    这样切阵容时不可能出现两处不同步导致的丢装备。
    """
    worn_equips, worn_spirits, worn_treasure = {}, {}, {}
    for e in equips:
        worn_equips.setdefault(int(e['card_id']), []).append(int(e['equip_id']))
    for s in spirits:
        worn_spirits.setdefault(int(s['card_id']), []).append(int(s['spirit_id']))
    for t in treasures:
        if int(t['card_id']):
            worn_treasure[int(t['card_id'])] = int(t['treasure_id'])

    grid_by_matrix = {}
    for g in grids:
        grid_by_matrix.setdefault(int(g['matrix_id']), []).append({
            'matrixGridId': int(g['matrix_grid_id']),
            'cardId': int(g['card_id']),
        })
    matrix_list = [{'matrixId': int(m['matrix_id']),
                    'sharkMatrixGrids': grid_by_matrix.get(int(m['matrix_id']), [])}
                   for m in matrices]

    out = []
    for a in sorted(rows, key=lambda x: int(x['array_id'])):
        aid = int(a['array_id'])
        queue = []
        for s in sorted([x for x in slots if int(x['array_id']) == aid],
                        key=lambda x: int(x['slot'])):
            cid = int(s['card_id'])
            queue.append({
                'cardId': cid,
                'equips': worn_equips.get(cid, []),
                'spirits': worn_spirits.get(cid, []),
                'treasureId': worn_treasure.get(cid, 0),
            })
        out.append({
            'sharkUserQueue': queue,
            'sharkMatrices': {'sharkMatrices': matrix_list},
        })
    return out


# ============================================================ 进度
def build_mission_context(mc):
    """→ `sharkMissionContext`。**必须完整**：下发 {} 会顶掉客户端默认值，
    下一行 `missionContext.missionId / 100` 崩。"""
    if not mc:
        return {'missionId': 100101, 'finishedStep': 0, 'fightLose': False, 'routeId': 1}
    return {
        'missionId': int(mc['mission_id']),
        'finishedStep': int(mc['finished_step']),
        'fightLose': bool(mc['fight_lose']),
        'routeId': int(mc['route_id']),
    }


def build_scene_process(sp, countries):
    if not sp:
        return {'uid': '', 'finishedCountryIds': [], 'sceneCountries': [],
                'maxFinishedMissionId': 0, 'lastClearTime': 0}
    blob = _j(sp['data_json'], {})
    fin = [int(c['country_id']) for c in countries if int(c['kind']) == 1]
    # Lua expects country/chapter/mission objects, never numeric country IDs.
    import luaconf
    chapters = luaconf.as_list(luaconf.load('battle_chapter'))
    maximum = int(sp['max_finished_mission_id'])
    by_country = {}
    for chapter in chapters:
        cid = int(chapter['id'])
        mids = [int(x) for x in str(chapter.get('missionIdList', '')).split('|') if x]
        completed = [mid for mid in mids if mid <= maximum]
        if not completed:
            continue
        country = by_country.setdefault(cid // 100, {'countryId': cid // 100, 'sceneChapters': []})
        country['sceneChapters'].append({'chapterId': cid, 'finish': len(completed) == len(mids),
            'rewardReceived': False, 'sceneMissions': [{'missionId': mid, 'star': 0, 'score': 0} for mid in completed]})
    sce = list(by_country.values())
    # Preserve claim flags and richer existing records.
    for saved in blob.get('sceneCountries', []):
        if isinstance(saved, dict):
            for country in sce:
                if country['countryId'] == saved.get('countryId'):
                    for chapter in country['sceneChapters']:
                        old = next((c for c in saved.get('sceneChapters', []) if c.get('chapterId') == chapter['chapterId']), {})
                        chapter.update({k: v for k, v in old.items() if k not in ('sceneMissions', 'finish')})
    return {
        'uid': '',
        'finishedCountryIds': fin or blob.get('finishedCountryIds', []),
        'sceneCountries': sce or blob.get('sceneCountries', []),
        'maxFinishedMissionId': int(sp['max_finished_mission_id']),
        'lastClearTime': int(sp['last_clear_time']),
        'activitySceneChapterList': blob.get('activitySceneChapterList', []),
    }


def build_daily(daily, daily_ext):
    d = _j(daily['data_json'], {}) if daily else {}
    e = _j(daily['extend_json'], {}) if daily else {}
    return (
        {'_date': int(daily['stat_date']) if daily else 0,
         'lstCowStageInfo': d.get('lstCowStageInfo', []),
         'lstEatPeachInfo': d.get('lstEatPeachInfo', []),
         'crossPvpDailyData': d.get('crossPvpDailyData', {})},
        {'mysteriousChallengeTimes': e.get('mysteriousChallengeTimes', []),
         'mysteriousExchangeTimes': e.get('mysteriousExchangeTimes', []),
         'treasureSacrificeTimes': e.get('treasureSacrificeTimes', []),
         'cardExchangeDailyInfo': e.get('cardExchangeDailyInfo',
                                        {'cardMetaIds': [], 'exchangeTimes': 0})},
    )


# ============================================================ 战斗力
def _load_spirits(db, card_id):
    """取一张卡上生效的元神（含副属性）。

    客户端 `cardSpirits[]` 是 `{index, spiritId}`，生效上限 =
    `card_rare[rare].spiritNum + card_level[level].spiritNum`，只认 `index <= 上限`。
    我们的 `player_spirit` 表**没有存 index**，所以按 `spirit_id` 升序当作位序
    —— 正常流程（依次镶嵌）下两者一致，但人工改库换将后可能对不上。
    """
    rows = db.all("SELECT * FROM player_spirit WHERE card_id=? ORDER BY spirit_id",
                  (int(card_id),))
    out = []
    for s in rows:
        sd = dict(s)
        sd['attributes'] = [dict(x) for x in db.all(
            "SELECT * FROM player_spirit_attr WHERE spirit_id=? ORDER BY slot",
            (int(s['spirit_id']),))]
        out.append(sd)
    return out


def _card_panel(db, card, matrix_bonus=None, country_nums_map=None):
    """一张卡的攻防血（客户端 `getCardPropertiesWithSharkCard` 的主体）。

    顺序逐字对齐客户端第 766-772 行：
        基础 → 装备 → 宝物 → 元神
        → + floor(temp*连协%) + floor(temp*套装%) + floor(temp*神兽%)
        → + 连协值 + 套装值 + 神兽值 → + 阵位加成

    country_nums_map 缺省时连协一定不满足条件（等于没加成），
    所以要拿到准确面板的调用方（战力、战斗）必须把队伍国家分布传进来。
    """
    from services import cardstats as CS
    equips = db.all("SELECT * FROM player_equip WHERE card_id=?",
                    (int(card['card_id']),))
    treasure = db.one("SELECT * FROM player_treasure WHERE card_id=?",
                      (int(card['card_id']),))
    spirits = _load_spirits(db, card['card_id'])
    extra = {'matrix': matrix_bonus} if matrix_bonus else None
    return CS.panel(card, equips, treasure, spirits, extra,
                    country_nums_map=country_nums_map)


def compute_fight_capacity(db, player_id):
    """总战斗力。

    **客户端不算战力** —— `CommonManager:getLocalPlayerStrength` 整个函数体
    被注释掉，直接 `return DataManager.getRealFightCapacity()`，而这个值只由
    服务端下发（`sharkUserExtend.fightCapacity` 初值 + `fightCapacityChangeEvent` 推送）。
    所以这个数完全由我们决定，客户端只负责显示。

    结构照抄原厂那段被注释掉的原公式（CommonManager 第 860-864 行）：

        result = (Σ攻*cardPowerAttackCoef + Σ防*cardPowerDefenseCoef
                  + Σ血*cardPowerHPCoef) * cardPowerTotalCoef
                 + (crt*..+prc*..) * cardPowerTotalCoef
        上限 cardPowerMax

    三个必须照做的点：
      1. **对合计攻防血算一次**，不是每张卡各算一次再相加（系数不同结果就不同）。
      2. **只有出战队列计入** —— 客户端 `getAttDefHp` 只遍历 `getQueueData()`。
         阵法格子里的卡**不单独计战力**，它只通过阵位加成影响全队。
      3. 阵位加成是**全队共用一份**，加到队列里每一张卡上。
    """
    from services import cardstats as CS

    cards = {}
    queue_ids = []
    for r in db.all(
            "SELECT s.card_id FROM player_battle_slot s"
            " JOIN player_battle_array a ON a.player_id=s.player_id"
            " AND a.array_id=s.array_id AND a.is_active=1"
            " WHERE s.player_id=? AND s.card_id>0 ORDER BY s.slot", (int(player_id),)):
        cid = int(r['card_id'])
        if cid not in cards:
            card = db.one("SELECT * FROM player_card WHERE card_id=?", (cid,))
            if card is not None:
                cards[cid] = card
                queue_ids.append(cid)
    if not queue_ids:
        return 0

    # 连协要按「队伍里各国的卡数」判定是否激活，所以先算一次国家分布
    from services import cardstats as CS
    nums = CS.country_nums([cards[cid] for cid in queue_ids])

    def _panel_no_matrix(cid):
        # 阵位加成用的占位卡面板：**不含阵位、也不含连协**（客户端传的是空队列）
        return _card_panel(db, cards[cid])

    # 阵位加成：占位卡的面板**不含阵位加成**，否则自己套自己
    grids = []
    for g in db.all(
            "SELECT g.matrix_id, g.matrix_grid_id, g.card_id, m.level"
            " FROM player_matrix_grid g JOIN player_matrix m"
            " ON m.player_id=g.player_id AND m.matrix_id=g.matrix_id"
            " WHERE g.player_id=? AND g.card_id>0", (int(player_id),)):
        gcard = int(g['card_id'])
        if gcard not in cards:
            card = db.one("SELECT * FROM player_card WHERE card_id=?", (gcard,))
            if card is None:
                continue
            cards[gcard] = card
        grids.append((int(g['matrix_id']), int(g['level']),
                      int(g['matrix_grid_id']), gcard))
    matrix_bonus = CS.matrix_bonus(grids, _panel_no_matrix) if grids else None

    total_att = total_def = total_hp = 0
    spirit_extra = {}
    for cid in queue_ids:
        card = cards[cid]
        p = _card_panel(db, card, matrix_bonus, country_nums_map=nums)
        total_att += p['att']
        total_def += p['def']
        total_hp += p['hp']
        # 二级属性来自队列卡的元神，受 spiritNum 上限约束
        slots = CS.spirit_slots_for(card)
        for i, s in enumerate(_load_spirits(db, cid)):
            if slots and (i + 1) > slots:
                break
            for k, v in CS.spirit_attributes(s).items():
                if k in ('crt', 'tou', 'hit', 'eva', 'par', 'prc'):
                    spirit_extra[k] = spirit_extra.get(k, 0) + int(v)

    return int(CS.fight_capacity(total_att, total_def, total_hp, spirit_extra))


# ============================================================ 列表类响应
def build_props(db, player_id):
    """→ sharkProps.sharkProps[]（只发 amount>0 的）"""
    return [{'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
            for r in db.all("SELECT * FROM player_prop WHERE player_id=? AND amount>0"
                            " ORDER BY meta_id", (player_id,))]


def build_equips(db, player_id):
    return [build_equip(e) for e in db.all(
        "SELECT * FROM player_equip WHERE player_id=? ORDER BY equip_id", (player_id,))]


def build_spirits(db, player_id):
    out = []
    for s in db.all("SELECT * FROM player_spirit WHERE player_id=? ORDER BY spirit_id",
                    (player_id,)):
        attrs = db.all("SELECT * FROM player_spirit_attr WHERE spirit_id=? ORDER BY slot",
                       (int(s['spirit_id']),))
        out.append(build_spirit(s, attrs))
    return out


def build_treasures(db, player_id):
    return [build_treasure(t) for t in db.all(
        "SELECT * FROM player_treasure WHERE player_id=? ORDER BY treasure_id", (player_id,))]


def build_cards(db, player_id):
    """卡牌的 equipIds / cardSpirits / treasureId 全部反查（单点存储）。"""
    treasure_of = {int(t['card_id']): int(t['treasure_id'])
                   for t in db.all("SELECT treasure_id, card_id FROM player_treasure"
                                   " WHERE player_id=? AND card_id>0", (player_id,))}
    out = []
    for c in db.all("SELECT * FROM player_card WHERE player_id=? ORDER BY card_id", (player_id,)):
        cid = int(c['card_id'])
        skills = db.all("SELECT * FROM player_card_skill WHERE card_id=? ORDER BY slot", (cid,))
        eqs = [dict(x) for x in db.all(
            "SELECT * FROM player_equip WHERE player_id=? AND card_id=? ORDER BY equip_id",
            (player_id, cid))]
        sps = []
        for s in db.all("SELECT * FROM player_spirit WHERE player_id=? AND card_id=?"
                        " ORDER BY spirit_id", (player_id, cid)):
            sd = dict(s)
            sd['attributes'] = [dict(x) for x in db.all(
                "SELECT * FROM player_spirit_attr WHERE spirit_id=?", (int(s['spirit_id']),))]
            sps.append(sd)
        tro = db.one("SELECT * FROM player_treasure WHERE player_id=? AND card_id=?",
                     (player_id, cid))
        out.append(build_card(c, skills, eqs, sps, treasure_of.get(cid, 0),
                              treasure=dict(tro) if tro else None))
    return out


def build_team_info(db, player_id):
    """→ getPlayerTeamInfo 的响应。客户端队列界面靠它渲染别人的阵容。"""
    p = db.one("SELECT * FROM player WHERE player_id=?", (player_id,))
    return {
        'sharkCards': {'sharkCards': build_cards(db, player_id)},
        'sharkEquips': {'sharkEquips': build_equips(db, player_id)},
        'sharkTreasures': {'sharkTreasures': build_treasures(db, player_id)},
        'sharkUserBattleArray': _battle_arrays(db, player_id),
    }


def _battle_arrays(db, player_id):
    arrays = db.all("SELECT * FROM player_battle_array WHERE player_id=? ORDER BY array_id",
                    (player_id,))
    if not arrays:
        return []
    return build_battle_arrays(
        arrays,
        db.all("SELECT * FROM player_battle_slot WHERE player_id=?", (player_id,)),
        db.all("SELECT equip_id, card_id FROM player_equip WHERE player_id=?", (player_id,)),
        db.all("SELECT spirit_id, card_id FROM player_spirit WHERE player_id=?", (player_id,)),
        db.all("SELECT treasure_id, card_id FROM player_treasure WHERE player_id=?", (player_id,)),
        db.all("SELECT * FROM player_matrix WHERE player_id=?", (player_id,)),
        db.all("SELECT * FROM player_matrix_grid WHERE player_id=?", (player_id,)))


# ============================================================ 首页信息
def build_home_info(db, player_id):
    """→ getHomeInfo。

    ⚠️ unionMonsterEscapeSeconds / unionMonsterHp 必须是数字：
    客户端 UnionManager.setColosseumMonsterRunTime 会做 `+3` 与 `<=0` 比较，nil 必崩。
    """
    def activity_state(key):
        row = db.one('SELECT data_json FROM player_activity WHERE player_id=? AND activity_key=?',
                     (player_id, key))
        return _j(row['data_json'], {}) if row else {}
    balloon = activity_state('balloon')
    if balloon.get('_daily_date') != time.strftime('%Y-%m-%d'): balloon = {}
    question = activity_state('question')
    consumption = db.one("SELECT value FROM player_counter WHERE player_id=? AND counter_key='gem_consumed'", (player_id,))
    consumption_claims = [int(r['reward_id']) for r in db.all(
        "SELECT reward_id FROM player_activity_reward_claim WHERE player_id=? AND scope='gem_consume'", (player_id,))]
    gym = db.one("SELECT g.monster_left_hp, g.escape_seconds FROM guild_monster g"
                 " JOIN guild_member m ON m.guild_id = g.guild_id"
                 " WHERE m.player_id=? AND m.status=0", (player_id,))
    unread = db.one("SELECT COUNT(*) AS c FROM mail WHERE player_id=? AND is_deleted=0"
                    " AND is_read=0", (player_id,))['c']
    return {
        'unionMonsterHp': int(gym['monster_left_hp']) if gym else 0,
        'unionMonsterEscapeSeconds': int(gym['escape_seconds']) if gym else 0,
        'consumeRewardRecharges': 0,
        'consumeRewards': [],
        'consumeGems': int(consumption['value']) if consumption else 0,
        'gainedGemConsumeRewards': consumption_claims,
        'unreadMessageNum': int(unread),
        'rewardNum': 0,
        'invitedNum': 0,
        'enableGainDailyActiveRewardNum': 0,
        'enableGainDailyAchieveRewardNum': 0,
        'eatPeachStatus': 0,
        'cowStageStatus': 0,
        'dailyQuestionStatus': (1 if question.get('_daily_date') != time.strftime('%Y-%m-%d')
                                else 0 if question.get('dailyGained')
                                else 3 if question.get('pool') and int(question.get('idx') or 0) >= len(question['pool'])
                                else 2 if int(question.get('idx') or 0) else 1),
        'balloonDaily': {
            'receiveTimes': int(balloon.get('receiveTimes') or 0),
            'balloonLevel': int(balloon.get('balloonLevel') or 0),
            'balloonPoint': int(balloon.get('point') or 0),
            'gainedPointRewardIds': list(balloon.get('gainedPointIds') or []),
            'gainedRankReward': bool(balloon.get('gainedRank', False)),
        },
        'dailyTaskRewardNum': 0,
        'freeSpiritRefreshNum': 3,
        'chargeRewardStatus': 0,
        'freeGachaStatus': 0,
    }


def build_sky_tower(db, player_id, now=None):
    """Login and getSkyTowerInfo must expose the same persisted tower state."""
    row = db.one('SELECT data_json FROM player_activity WHERE player_id=? AND activity_key=?',
                 (player_id, 'sky_tower'))
    state = _j(row['data_json'], {}) if row else {}
    legacy = db.one('SELECT * FROM player_sky_tower WHERE player_id=?', (player_id,))
    best = int(state.get('maxBigWinFloor') or (legacy['max_big_win_floor'] if legacy else 0))
    days = int(((now or time.time()) + 28800) // 86400)
    defaults = {'days': days, 'climbTimes': 0, 'maxTotalStars': 0,
                'currTotalStars': 0, 'currUsedStars': 0, 'maxFloor': best,
                'currFloor': 0, 'inTopRankDays': 0, 'gainFloorBuff': [],
                'selfAtkBuff': 0, 'selfDefBuff': 0, 'selfHpBuff': 0,
                'enemyAtkDebuff': 0, 'enemyDefDebuff': 0,
                'gainYesterdayReward': False, 'dead': False,
                'skipBattle': False, 'beginSkipFloor': 0}
    status = dict(defaults)
    status.update({k: state[k] for k in defaults if k in state})
    status['maxTotalStars'] = max(int(status['maxTotalStars']), int(status['currTotalStars']))
    past = dict(defaults, days=days-1)
    past.update(state.get('pastStatus') or {})
    return {'uid': str(player_id), 'maxBigWinFloor': best,
            'currStatus': status, 'pastStatus': past, 'pastRanks': [],
            'sharkSkyTower': {'uid': str(player_id), 'maxBigWinFloor': best}}


# ============================================================ 邮件
def build_emails(db, player_id):
    """→ getUserEmails。

    ⚠️ sysEmails 与 rewardEmails **必须分别下发**：客户端自己 table.union 合并。
    ⚠️ receiveSeconds / rewardEmail.content / sysEmailMeta.contentText 三个字段
       缺失会直接崩（排序比较、gsub(nil)），这里一律保证非空。
    """
    def _base(r, id_key):
        d = {
            id_key: int(r['mail_id']),
            'sendUid': int(r['sender_uid']),
            'sendName': r['sender_name'] or '',
            'title': r['title'] or '',
            'content': r['content'] or '',
            'receiveSeconds': int(r['create_time']),
            'expireSeconds': int(r['expire_time']),
            'read': bool(r['is_read']),
            'gainedReward': bool(r['is_gained']),
        }
        return d

    sys_mails, reward_mails = [], []
    for r in db.all("SELECT * FROM mail WHERE player_id=? AND mail_type=1 AND is_deleted=0"
                    " ORDER BY create_time DESC", (player_id,)):
        d = _base(r, 'sysEmailId')
        d['sysEmailMetaId'] = int(r['meta_id'])
        d['reward'] = _attachments(db, r['mail_id'])
        sys_mails.append(d)
    for r in db.all("SELECT * FROM mail WHERE player_id=? AND mail_type=2 AND is_deleted=0"
                    " ORDER BY create_time DESC", (player_id,)):
        d = _base(r, 'rewardEmailId')
        d['rewardEmailMetaId'] = int(r['meta_id'])
        d['content'] = r['content'] or ''          # 不能空：客户端 gsub(content)
        d['reward'] = _attachments(db, r['mail_id'])
        reward_mails.append(d)

    notices = []
    for r in db.all("SELECT * FROM mail WHERE player_id=? AND mail_type=3 AND is_deleted=0"
                    " ORDER BY create_time DESC", (player_id,)):
        notices.append({
            'sysNoticeId': int(r['mail_id']),
            'title': r['title'] or '',
            # detail 必须是合法 JSON 文本（客户端 cjson.decode）
            'detail': r['detail'] or '{}',
            'receiveTime': int(r['create_time']),
            'read': bool(r['is_read']),
        })

    user_mails = []
    for r in db.all("SELECT * FROM mail WHERE player_id=? AND mail_type=4 AND is_deleted=0"
                    " ORDER BY create_time DESC", (player_id,)):
        d = _base(r, 'userEmailId')
        d['receiveUid'] = int(r['sender_uid'])
        d['sendUid'] = int(r['sender_uid'])
        d['sendTime'] = int(r['create_time'])
        user_mails.append(d)

    meta = [{'id': int(r['meta_id']), 'titleText': r['title_text'] or '',
             'contentText': r['content_text'] or '',      # 不能空：gsub(nil) 崩
             'containReward': bool(r['contain_reward'])}
            for r in db.all("SELECT * FROM sys_email_meta WHERE enabled=1 ORDER BY meta_id")]

    return {'sysEmails': sys_mails, 'rewardEmails': reward_mails, 'sysNotices': notices,
            'userEmails': user_mails, 'sysEmailMeta': meta}


def _attachments(db, mail_id):
    return [{'itemType': int(a['item_type']), 'metaId': int(a['meta_id']),
             'amount': int(a['amount'])}
            for a in db.all("SELECT * FROM mail_attachment WHERE mail_id=? ORDER BY slot",
                            (int(mail_id),))]


# ============================================================ 好友
def build_friend_entry(db, self_id, friend_id):
    """好友条目。⚠️ online 为假时 lastestOfflineSeconds 必须存在（客户端做时间减法）。"""
    p = db.one("SELECT * FROM player WHERE player_id=?", (int(friend_id),))
    if p is None:
        return None
    card = db.one("SELECT meta_id FROM player_card WHERE card_id=?",
                  (int(p['main_card_id'] or 0),))
    guild = db.one("SELECT g.name FROM guild_member m JOIN guild g ON g.guild_id=m.guild_id"
                   " WHERE m.player_id=? AND m.status=0", (int(friend_id),))
    online = db.one("SELECT COUNT(*) AS c FROM auth_session WHERE player_id=? AND revoked=0"
                    " AND expire_time>?", (int(friend_id), int(time.time())))['c'] > 0
    last = int(p['last_logout_time'] or p['last_login_time'] or time.time())
    rel = db.one("SELECT * FROM friend WHERE player_id=? AND friend_uid=?",
                 (int(self_id), int(friend_id)))
    inv = db.one("SELECT status FROM friend_invitation WHERE from_uid=? AND to_uid=?"
                 " ORDER BY create_time DESC LIMIT 1", (int(self_id), int(friend_id)))
    return {
        'friendUid': int(friend_id),
        'nickName': p['nickname'] or '',
        'level': int(p['level']),
        'mainCardMetaId': int(card['meta_id']) if card else 0,
        'unionName': (guild['name'] if guild else '') or '',
        'online': bool(online),
        'lastestOfflineSeconds': max(0, int(time.time()) - last),
        'fightCapacity': int(p['fight_capacity'] or 0),
        'giftSent': bool(rel and rel['gift_sent_date'] == time.strftime('%Y-%m-%d')),
        'invitationSent': bool(inv and int(inv['status']) == 0),
        'friend': bool(rel),
    }


# ============================================================ gameInit 总装
def build_activity_snapshot(db, player_id):
    """Persisted local activity state with the fields consumed by activity UI."""
    states = {r['activity_key']: _j(r['data_json'], {}) for r in db.all(
        'SELECT activity_key,data_json FROM player_activity WHERE player_id=?', (player_id,))}
    claim_rows = db.all('SELECT scope,reward_id FROM player_activity_reward_claim WHERE player_id=?', (player_id,))
    def claimed(scope):
        return [int(r['reward_id']) for r in claim_rows if r['scope'] == scope]
    p = db.one('SELECT level,recharge_gems FROM player WHERE player_id=?', (player_id,))
    tb = states.get('treasurebox', {})
    return {
        'flashRecharge': states.get('flash_recharge') or {'times': 0, 'recharge': [0,0,0], 'rewards': claimed('limit_reward')},
        'chargeInfo': {'gems': int(p['recharge_gems']), 'gainedRewardIds': claimed('charge_money')},
        'gainedSwornRewardList': claimed('sworn'), 'gainedPraiseRewardIds': claimed('praise'),
        'recordPraiseIds': [], 'defaultPhoneNum': '',
        'dayRewardInfo': {'featureStartSeconds': 0, 'gainedIds': claimed('day_reward')},
        'gpGainedReward': bool(states.get('gacha_points', {}).get('gained')),
        'goldGodNum': int(states.get('gold_god', {}).get('count') or 0), 'ggVersion': int(states.get('gold_god', {}).get('version') or 0),
        'levelRaceRewards': claimed('level_race'), 'lrUserLevel': int(p['level']),
        'nyChagrgedGems': int(p['recharge_gems']), 'nyGainedRewardIds': claimed('new_year'),
        'cardExchangeInfo': states.get('card_exchange') or {'version': 0, 'gainedIds': []},
        'treasureboxPointsInfo': {'point': int(tb.get('point') or 0),
            'featureBeginSeconds': int(tb.get('featureBeginSeconds') or 0),
            'gainedPointRewards': tb.get('gainedPointIds') or [], 'gainedRankReward': bool(tb.get('gainedRank'))},
    }


def build_game_init(db, player_id, now=None):
    """把全部零件拼成 `gameInit` 的完整响应。

    这个函数就是「表结构是否成立」的证明：只要它能无条件产出下面这些 key，
    客户端的 DataManager.getGameInitData().X 就都有东西可读。
    """
    now = now or int(time.time())
    p = db.one("SELECT * FROM player WHERE player_id=?", (player_id,))
    if p is None:
        return None
    ext = db.one("SELECT * FROM player_extend WHERE player_id=?", (player_id,))
    if ext is None:      # 兜底：不允许缺行，否则后面全是 None 解引用
        with db.tx() as con:
            con.execute("INSERT INTO player_extend(player_id) VALUES (?)", (player_id,))
        ext = db.one("SELECT * FROM player_extend WHERE player_id=?", (player_id,))

    # 总战力由服务端算（客户端只显示，见 assembler.compute_fight_capacity）
    fc = compute_fight_capacity(db, player_id)
    if fc != int(p['fight_capacity'] or 0):
        with db.tx() as con:
            con.execute("UPDATE player SET fight_capacity=? WHERE player_id=?",
                        (int(fc), int(player_id)))

    # ⚠️ tutorialSteps 必须是 **{funcName, step} 字典数组**，不能只发 step 数字：
    #     canonUtils.IsGuideExecuted:
    #         for k,v in pairs(data.sharkUserExtend.tutorialSteps) do
    #             if v.funcName == guide then ... end
    #     发数字 -> "attempt to index local 'v' (a number value)" -> SIGKILL。
    rows = db.all("SELECT step, func_name FROM player_tutorial_step"
                  " WHERE player_id=? ORDER BY step", (player_id,))
    rows = db.all("SELECT step,func_name FROM player_guide_progress WHERE player_id=? ORDER BY func_name", (player_id,)) or rows
    named = [{'funcName': (r['func_name'] or ''), 'step': int(r['step'])}
             for r in rows if (r['func_name'] or '')]
    # ⚠️ 一律把「已知引导」全部标成完成，再并上库里真实记录的进度。
    #
    # 为什么不能只发库里那几条：只要客户端发现**任何**一条引导未完成，
    # 就会从那条开始重跑新手引导，期间 `MainMenuScene:321 setDispatchEvents(false)`
    # 会锁住输入 —— 只有高亮的那一个控件响应，别的点击全部被吞掉，
    # 界面看起来就是「点了没反应 / 卡住」。本服没有实现引导脚本，
    # 所以这里统一标记为「引导已全部完成」，客户端直接进主界面。
    # （实测：只发 1 条 Guide_MagicCircle 时，进队伍界面会被
    #   「点击阵容切换…」的引导提示卡住，连返回键都点不动。）
    seen, merged = set(), []
    for s in list(DONE_TUTORIAL_STEPS) + named:
        if s['funcName'] in seen:
            continue
        seen.add(s['funcName'])
        merged.append(s)
    steps = merged
    sign_in = db.one("SELECT * FROM player_sign_in WHERE player_id=?", (player_id,))
    cont_login = db.one("SELECT * FROM player_continuous_login WHERE player_id=?", (player_id,))
    cont_v2 = db.one("SELECT * FROM player_continuous_login_v2 WHERE player_id=?", (player_id,))
    claims = db.all("SELECT scope, reward_id FROM player_activity_reward_claim WHERE player_id=?",
                    (player_id,))

    cards = db.all("SELECT * FROM player_card WHERE player_id=? ORDER BY card_id", (player_id,))
    # 宝物归属反查（player_card 上没有 treasure_id 列）
    treasure_of = {int(t['card_id']): int(t['treasure_id'])
                   for t in db.all("SELECT treasure_id, card_id FROM player_treasure"
                                   " WHERE player_id=? AND card_id>0", (player_id,))}
    out_cards = []
    for c in cards:
        cid = int(c['card_id'])
        skills = db.all("SELECT * FROM player_card_skill WHERE card_id=? ORDER BY slot", (cid,))
        eqs = [dict(x) for x in db.all(
            "SELECT * FROM player_equip WHERE player_id=? AND card_id=?", (player_id, cid))]
        sps = []
        for s in db.all("SELECT * FROM player_spirit WHERE player_id=? AND card_id=?",
                        (player_id, cid)):
            sd = dict(s)
            sd['attributes'] = [dict(x) for x in db.all(
                "SELECT * FROM player_spirit_attr WHERE spirit_id=?", (int(s['spirit_id']),))]
            sps.append(sd)
        tro = db.one("SELECT * FROM player_treasure WHERE player_id=? AND card_id=?",
                     (player_id, cid))
        out_cards.append(build_card(c, skills, eqs, sps, treasure_of.get(cid, 0),
                                    treasure=dict(tro) if tro else None))

    out_equips = [build_equip(e) for e in db.all(
        "SELECT * FROM player_equip WHERE player_id=? ORDER BY equip_id", (player_id,))]

    out_spirits = []
    for s in db.all("SELECT * FROM player_spirit WHERE player_id=? ORDER BY spirit_id", (player_id,)):
        attrs = db.all("SELECT * FROM player_spirit_attr WHERE spirit_id=? ORDER BY slot",
                       (int(s['spirit_id']),))
        out_spirits.append(build_spirit(s, attrs))

    out_treasures = [build_treasure(t) for t in db.all(
        "SELECT * FROM player_treasure WHERE player_id=? ORDER BY treasure_id", (player_id,))]

    arrays = db.all("SELECT * FROM player_battle_array WHERE player_id=? ORDER BY array_id",
                    (player_id,))
    if not arrays:      # 客户端会 sharkUserBattleArray[battleArrayId] 直接索引，不能为空
        with db.tx() as con:
            con.execute("INSERT INTO player_battle_array(player_id, array_id, is_active)"
                        " VALUES (?,1,1)", (player_id,))
        arrays = db.all("SELECT * FROM player_battle_array WHERE player_id=? ORDER BY array_id",
                        (player_id,))

    battle_arrays = build_battle_arrays(
        arrays,
        db.all("SELECT * FROM player_battle_slot WHERE player_id=?", (player_id,)),
        db.all("SELECT equip_id, card_id FROM player_equip WHERE player_id=?", (player_id,)),
        db.all("SELECT spirit_id, card_id FROM player_spirit WHERE player_id=?", (player_id,)),
        db.all("SELECT treasure_id, card_id FROM player_treasure WHERE player_id=?", (player_id,)),
        db.all("SELECT * FROM player_matrix WHERE player_id=?", (player_id,)),
        db.all("SELECT * FROM player_matrix_grid WHERE player_id=?", (player_id,)))

    mc = db.one("SELECT * FROM player_mission_context WHERE player_id=?", (player_id,))
    sp = db.one("SELECT * FROM player_scene_process WHERE player_id=?", (player_id,))
    countries = db.all("SELECT * FROM player_scene_country WHERE player_id=?", (player_id,))
    daily = db.one("SELECT * FROM player_daily WHERE player_id=? ORDER BY stat_date DESC LIMIT 1",
                   (player_id,))
    secret = db.one("SELECT * FROM player_secret_shop WHERE player_id=?", (player_id,))

    daily_data, daily_ext = build_daily(daily, None)
    cow_row = db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='cow_stage'", (player_id,))
    cow_state = _j(cow_row['data_json'], {}) if cow_row else {}
    if cow_state.get('day') == db.today():
        daily_data['lstCowStageInfo'] = cow_state.get('stages', [])
    exchange_row = db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='mysterious_exchange'", (player_id,))
    exchange_state = _j(exchange_row['data_json'], {}) if exchange_row else {}
    if exchange_state.get('day') == db.today():
        daily_ext['mysteriousExchangeTimes'] = [
            {'nodeId': int(k), 'times': int(v)} for k, v in exchange_state.get('times', {}).items()]
    peach_row = db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='eat_peach'", (player_id,))
    peach_state = _j(peach_row['data_json'], {}) if peach_row else {}
    peach_infos = [{'featureName': name, 'eatPeachTime': int(peach_state.get('times', {}).get(name) or 0)}
                   for name in ('activity1Rest', 'activity2Rest')]
    ext_blob = _j(ext['extend_json'], {})
    ext_blob['lstEatPeachInfo'] = peach_infos
    ext = dict(ext); ext['extend_json'] = json.dumps(ext_blob)
    daily_data['lstEatPeachInfo'] = peach_infos
    fountain_row = db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='fountain'", (player_id,))
    fountain = _j(fountain_row['data_json'], {}) if fountain_row else {}
    daily_data['wishings'] = int(fountain.get('count') or 0) if fountain.get('day') == str(db.today()) else 0
    cross_row = db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='cross_gacha'", (player_id,))
    cross_state = _j(cross_row['data_json'], {}) if cross_row else {}

    pending_row = db.one("SELECT activity_key,data_json FROM player_activity WHERE player_id=? AND activity_key LIKE 'card_train_%' AND data_json != '{}' ORDER BY update_time DESC LIMIT 1", (player_id,))
    pending_train = _j(pending_row['data_json'], {}) if pending_row else {}
    train_cards = {'sharkCards': out_cards, 'trainValueSaved': not bool(pending_train)}
    if pending_train:
        train_cards.update(trainCardId=int(pending_row['activity_key'].rsplit('_',1)[1]),
                           unsavedAttTrainValue=int(pending_train.get('attTrainValue') or 0),
                           unsavedDefTrainValue=int(pending_train.get('defTrainValue') or 0),
                           unsavedHpTrainValue=int(pending_train.get('hpTrainValue') or 0))


    return {
        'sharkUser': build_shark_user(p, ext, now, fc),
        'sharkUserExtend': build_shark_extend(p, ext, steps, sign_in, cont_login, claims,
                                              now, fc),
        'sharkUserExtendMore': build_shark_extend_more(p, ext, cont_v2, now),

        'sharkCards': train_cards,
        'sharkEquips': {'sharkEquips': out_equips},
        'sharkProps': {'sharkProps': [
            {'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
            for r in db.all("SELECT * FROM player_prop WHERE player_id=? AND amount>0"
                            " ORDER BY meta_id", (player_id,))]},
        'sharkSpirits': {'sharkSpirits': out_spirits},
        'sharkTreasures': {'sharkTreasures': out_treasures},
        'sharkMatrices': {'sharkMatrices': [
            {'matrixId': int(m['matrix_id']), 'sharkMatrixGrids': [
                {'matrixGridId': int(g['matrix_grid_id']), 'cardId': int(g['card_id'])}
                for g in db.all("SELECT * FROM player_matrix_grid"
                                " WHERE player_id=? AND matrix_id=? ORDER BY matrix_grid_id",
                                (player_id, int(m['matrix_id'])))]}
            for m in db.all("SELECT * FROM player_matrix WHERE player_id=?", (player_id,))]},

        'sharkCardFragments': {'sharkCardFragments': [
            {'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
            for r in db.all("SELECT * FROM player_fragment WHERE player_id=? AND kind=1",
                            (player_id,))]},
        'sharkEquipFragments': {'sharkEquipFragments': [
            {'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
            for r in db.all("SELECT * FROM player_fragment WHERE player_id=? AND kind=2",
                            (player_id,))]},
        'sharkMysteriousCoins': {'sharkMysteriousCoins': [
            {'metaId': int(r['meta_id']), 'amount': int(r['amount'])}
            for r in db.all("SELECT * FROM player_mysterious_coin WHERE player_id=?",
                            (player_id,))]},

        # ⚠️ 这一项不能省：BackpackScene:1084 无守卫地索引 [1..3]
        'sharkUserBattleArray': battle_arrays,
        'sharkMissionContext': build_mission_context(mc),
        'sharkSceneProcess': build_scene_process(sp, countries),
        'missionCompletes': [
            {'missionId': int(r['mission_id']), 'star': int(r['star']),
             'missionCompleteCount': int(r['complete_count'])}
            for r in db.all("SELECT * FROM player_mission_complete WHERE player_id=?", (player_id,))],

        'sharkDailyData': daily_data,
        'sharkDailyDataExtend': daily_ext,
        'sharkUserSecretShop': {
            'freeTimes': int(secret['free_times']) if secret else 0,
            'lastRefreshSecond': int(secret['last_refresh_second']) if secret else 0,
            'ifListFresh': bool(secret['if_list_fresh']) if secret else False,
            'version': int(secret['version']) if secret else 0,
        },
        'sharkElite': {'maxFinishedEliteId': int(
            (db.one("SELECT max_finished_elite_id FROM player_elite WHERE player_id=?",
                    (player_id,)) or {'max_finished_elite_id': 0})['max_finished_elite_id'])},
        'sharkSkyTower': build_sky_tower(db, player_id, now),
        'sharkActivity': build_activity_snapshot(db, player_id),
        'sharkActivityExtend': {'crossGachaUserInfo': {
            'point': int(cross_state.get('point') or 0),
            'gainedPointRewardIds': cross_state.get('gainedPoint') or [],
            'gainedRankReward': bool(cross_state.get('gainedRank')),
            'gainedMysteriousReward': bool(cross_state.get('gainedMysterious'))}},
        'sharkChristInfo': {'maxFinishedChristId': 0, 'listSharkChristInfo': []},
        # ⚠️ rpGachaTimes 必填：GachaScene.lua:936-944 做的是
        #     rpTimes = sharkGachaInfo.rpGachaTimes          (无默认值！)
        #     if v.rpGachaTimesMin <= rpTimes ...            (数字比较)
        # 缺该字段 -> rpTimes=nil -> "attempt to compare number with nil"
        # -> 引擎 SIGKILL（表现：主界面点「求将」直接闪退）。
        'sharkGachaInfo': {'rpValue': 0,
                           'rpGachaTimes': 0,
                           'lastFreeTreasureGachaSeconds': int(_j((db.one("SELECT data_json FROM player_activity WHERE player_id=? AND activity_key='treasure_gacha'", (player_id,)) or {'data_json': '{}'})['data_json'], {}).get('lastFree', 0))},
        'sharkDice': {'throwDiceCount': 0, 'changeDiceLuckCount': 0,
                      'changeLuckCountPerThrow': 0, 'coins': 0, 'gainedReward': 0,
                      'diceStates': []},
        'sharkShop': {'loopPurchaseInfos': [
            {'shopId': int(r['shop_id']), 'goodsId': int(r['goods_id']),
             'buyCount': int(r['buy_count'])}
            for r in db.all("SELECT * FROM player_shop_loop WHERE player_id=?", (player_id,))]},
        'sharkGemCards': {'sharkGemCards': [
            {'gemCardId': int(r['gem_card_id']), 'productId': r['product_id'],
             'startTime': int(r['start_time']), 'endTime': int(r['end_time']),
             'type': int(r['meta_id']), 'deadline': int(r['end_time']),
             'gainedRewardDate': ['/'.join(str(int(part)) for part in r['last_gain_day'].split('-'))]
                 if r['last_gain_day'] else []}
            for r in db.all("SELECT * FROM player_gem_card WHERE player_id=?", (player_id,))]},
        'invitationCode': (db.one("SELECT invite_code FROM player_invite_code WHERE player_id=?", (player_id,)) or {'invite_code': ''})['invite_code'],
        'fishInviteCode': (db.one("SELECT invite_code FROM player_invite_code WHERE player_id=?",
                                  (player_id,)) or {'invite_code': ''})['invite_code'],
        'crossPvpActivityStatus': False,
        'sharkDestinyInfo': {'spiritConcentrateLevel': 0},
        # 跨服 Boss 暂时关闭：客户端 Activity_CrossMultiplayerBossLayer:131 第一句就是
        # `level < CrossWorldBossManager.getCrossBossSettingConfig().unlockLevel`，
        # 而 meta 里的 crossBossSettingConfig 原厂就没随包下发（客户端 configs 里没有，
        # 单机端也是空表），unlockLevel 为 nil → 一进面板就 Lua 报错。
        # 等拿到真实跨服配置再打开；接口侧已经实现（handlers_cross.py）。
        'crossBossActivityStatus': False,
        'timestamp': now,
    }
