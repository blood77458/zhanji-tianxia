#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""getMeta 的响应构造（从 canon_server.py 自动抽取，请勿手改本文件的载荷部分）。

抽取自 canon_server.py 第 2705-2908 行。里面每个字段都有踩坑注释，
改动前请先读那些注释 —— 这个接口是「少一个字段就 SIGKILL」的重灾区。
"""
import canon_server as _cs

# 把 canon_server 的模块级名字（含下划线开头的配置构造器）引进本命名空间，
# 让下面抽出来的代码能直接引用 _payment_exchanges() 等。
globals().update({k: v for k, v in vars(_cs).items() if not k.startswith('__')})


def get_meta_payload():
    method = "getMeta"          # 原代码在 _endpoint_response 里读外层变量，这里补上
    # The client loads most of its data locally (require "canon.configs.X");
    # only a handful of tables come from the server.  LoginScene.lua:228
    # requires DataManager.GameMetaData.cardPictureConfig.cardPictures.
    _ad_url = "http://android1.canon.happyelements.cn/static/ad/banner.png"
    # GachaScene.preloadAd (line 1167) iterates these ids and dereferences
    # MetaManager.getAdPictureById(id).url with NO nil check -> every id
    # listed there must exist or the client SIGKILLs.
    _ad_ids = ["advacedGacha_1", "advacedGacha_2", "normalGacha_1",
               "activityGacha_1", "activityGacha_2", "friendGacha_1",
               "boxGacha"]
    # Activity_*:enable() / MainMenuScene icon filters dereference
    # GameMetaData.activity*Config.featureName with NO nil guard.
    def _act(name, name2=None, **extra):
        d = {"featureName": name}
        if name2:
            d["featureName2"] = name2
        d.update(extra)
        return d

    payload = {
        "method": method, "retCode": 200,
        "cardPictureConfig": {"cardPictures": []},
        # read as game_meta.adPictureConfig.adPictures (MetaManager:487)
        "adPictureConfig": {
            "adPictures": [{"id": i, "url": _ad_url, "name": i}
                           for i in _ad_ids],
        },
        # MainMenuScene:440/1527 read game_meta.adMainUiConfig.adMainUis
        # DIRECTLY (no guard); getAdvPicByMeta handles a nil entry, so an
        # empty list degrades to the built-in default banner.
        "adMainUiConfig": {"adMainUis": []},
        # ChallengeEntersScene:147 nil-guards unlockLevel — empty {} => SIGKILL.
        "skyTowerSettingConfig": {
            "unlockLevel": 25,
            "challengeChance": 3,
            "startBuffMin": 1,
            "startBuffMax": 3,
            "startBuffConvertCoef": 0.005,
        },
        # SpiritManager.isUserLevelEnough compares unlockLevel with NO
        # nil guard (unlike TreasureManager). Empty {} => SIGKILL when
        # MainMenu scrolls past SpiritBackPack.
        "spiritSettingConfig": {
            "unlockLevel": 20,
            "spiritPoolInitSize": 50,
            "spiritPoolExtraSizePerPurchase": 10,
            "spiritPoolMaxExpandTimes": 20,
            "spiritPoolExpandCost": 50,
            "lockedRefreshMultiplier": 2,
            "unlockPrice": 100,
            "refreshPropId": 0,
        },
        # 圣诞/元旦活动。⚠️ `christList` 必须存在：
        # MerryChristmasChallengePanel.lua:250 一进来就 `table.clone(getMerryChristmasConfig().christList)`，
        # 为 nil 时 pairs(nil) 直接 Lua 报错（引擎 kill）。
        # 原厂 christList（怪物组/消耗/奖励）没有随包下发，暂给空表 —— 面板能打开但不显示关卡，
        # 对应 challengeChrist 返回 714651（见 api/handlers_activity3.py）。
        "activityEventChristmasConfig": _act(
            "eventNewyear", christList=[], costPower=0, costMoney=0, specialReward=[]),
        "activityGachaXiaoyuConfig": _act(
            "activityGachaXiaoyu",
            crossGachaServerGroups=[{"serverIds": [1]}]),
        "activityCowStageConfig": {
            "featureNamesList": ["cowStage"],
        },
        "activityFountainWishConfig": _act(
            "fountainWish", requiredLevel=1),
        "activityWorldBossConfig": _act(
            "worldBoss", "worldBoss1",
            prepareTime=1800, dantengTime=12, rankProcessTime=3600,
            rankingRange=100, inspireLimit=10),
        # WantedActivity refresh() indexes questRewards[wantedId] for
        # contentID1/contentNum1/contentNum2 — empty {} => SIGKILL.
        "activityWantedConfig": _act(
            "activityWanted",
            completeNum=5,
            newRefreshPrice="20",
            refreshPrice="10",
            questRewards={
                1: {"contentID1": 400216, "contentNum1": 1, "contentNum2": 500},
                2: {"contentID1": 400216, "contentNum1": 2, "contentNum2": 800},
                3: {"contentID1": 400217, "contentNum1": 1, "contentNum2": 1200},
                4: {"contentID1": 400217, "contentNum1": 2, "contentNum2": 1800},
                5: {"contentID1": 400217, "contentNum1": 3, "contentNum2": 2500},
            }),
        "activityGoldGodConfig": _act(
            "goldGod",
            version=2,
            goldGodMaxTimes=0,
            goldGodRewardItems=[]),
        "activityTreasureboxPointsConfig": _act(
            "treasureboxPoints",
            featureNameTreasureboxPoints="treasureboxPoints",
            featureNameGainReward="treasureboxPointsReward",
            featureNamePanel="treasureboxPointsPanel",
            rankRewardMetas=[], pointRewardMetas=[]),
        "activitySwornBrothersConfig": _act(
            "activitySwornBrothers", swornBrothersRewardItems=[]),
        "activitySeckillConfig": _act("activitySeckill"),
        "activityDiceConfig": _act("activityThrowDice", maxThrowDiceCount=10,
                                    freeChangeLuckCount=3,
                                    baseCoinThrowDice=100,
                                    diceCoinMultipleItems=[],
                                    diceGoldConsumeItems=[]),
        "activityPraiseConfig": _act("activityPraise"),
        "activityMultiplayerBossConfig": _act(
            "multiplayerBossPanel",
            escapeTime=3600,
            rankingFeatureName="multiplayerBossRank",
            rewardFeatureName="multiplayerBossReward",
            prepareTime=1800,
            dantengTime=12),
        "activityNewYearConfig": _act(
            "newyear",
            featureNamePanel="activityChargeRewardPanel",
            featureNameCalcPay="activityNewyearCalcPay",
            featureNameGainReward="activityNewyearGainReward",
            version=1),
        "activityBalloonConfig": _act("activityBalloon"),
        # LotteryFortuneLayer.getTipNum / shouldShowParticle read
        # fortuneFreeTime with no nil guard. Missing field => SIGKILL
        # when MainMenu refreshes tip badges after closing 每日签到.
        "activityFortuneNowConfig": _act(
            "fortuneNow",
            fortuneFreeTime=0,
            fortuneTimeMax=10,
            fortuneCost=20,
            fortuneRewardItems=[]),
        "activityContendConfig": _act(
            "contend",
            panelFeatureName="activityContendPanel",
            featureNameList=["activityContendPanel"],
            levelLimit=1),
        "activityLevelRaceConfig": _act(
            "activityLevelRacePanel",
            # Client expects [{id, type}, ...]; numbers crash ActivityPanelScene:207
            displayTypes=[{"id": 0, "type": 0}],
            levelRewardItems=[],
            winnerNickname="0"),
        "activityGemConsumeConfig": _act("activityGemConsume"),
        "activityDayRewardConfig": _act("activityDayReward", dayRewards={}),
        "activityConsumeRewardConfig": _act("consumeRewards"),
        "multiplicityRewardConfig": _act("activityDoubleSilver"),
        "exchangeDailyConfig": _act("exchangeDaily"),
        "activityCardExchangeConfig": _act(
            "activityCardExchange", cardExchangeMeta=[]),
        "prayConfig": _act("activityPray"),
        "fbShareConfig": _act("activityFbShare"),
        "activitySettingConfig": {
            "gemCardConfig": {
                "featureName": "gemCard",
                "gemCardNum": 100,
                "gemCardLastTime": 30,
                "gemCardBuyConditionGem": 0,
                "gemCardBuyConditionTime": 0,
                "gemCardGemCost": 60,
            },
            "phoneChargeConfig": {
                "featureName": "activity_phoneCharge",
                "minPayment": 0,
                "chargeAmounts": [],
            },
        },
        # Activity_ChallengeMysteriousLayer:setData always reads
        # eventMysteriousConfig.eventLimit (even when all nodes are off).
        # Nil config => SIGKILL on opening 活动.
        "eventMysteriousConfig": {
            "eventLimit": 99,
            "energyCost": 2,
        },
        # Shop tab gates on featureName; keep closed via empty maintenance.
        "activityMysteriousExchangeConfig": _act(
            "mysteriousShop",
            exchangeMetas=[]),
        # Activity_rechargeLayer.getTipNum -> getUnreceievedRewardsNum
        # compares recharge[i] >= limitRewards[stepId].rewardDetail; missing
        # entries leave limitMoney nil => SIGKILL on main-menu tip badges.
        "activityLimitRewardConfig": {
            "featureName": "ActivityLimitReward",
            "limitRewards": [
                {"stepId": 1, "rewardDetail": 999999, "limitTime": 7,
                 "reward": []},
                {"stepId": 2, "rewardDetail": 999999, "limitTime": 7,
                 "reward": []},
                {"stepId": 3, "rewardDetail": 999999, "limitTime": 7,
                 "reward": []},
            ],
            "finalReward": [],
        },
        # CountDownRewardNewPanel indexes .rewards[].countdownTime /
        # .rewardPackage (MetaManager.getRewardInfoByID). Shape from
        # configs/countdown_reward.lua — wrong field names => SIGKILL.
        "countdownRewardConfig": {
            "rewards": [
                {"id": 1, "countdownTime": 0, "rewardPackage": 11001},
                {"id": 2, "countdownTime": 60, "rewardPackage": 11002},
                {"id": 3, "countdownTime": 180, "rewardPackage": 11003},
                {"id": 4, "countdownTime": 300, "rewardPackage": 11004},
                {"id": 5, "countdownTime": 900, "rewardPackage": 11005},
                {"id": 6, "countdownTime": 1800, "rewardPackage": 11006},
                {"id": 7, "countdownTime": 3600, "rewardPackage": 11007},
                {"id": 8, "countdownTime": 86400, "rewardPackage": 11008},
            ],
        },
        # CrossArenaScoreLayer:68 reads activeRewards[i].rewards
        "crossArenaRewardConfig": {
            "activeRewards": [
                {"id": 1, "score": 5, "rewards": [
                    {"itemType": 1, "metaId": 0, "amount": 500}]},
                {"id": 2, "score": 10, "rewards": [
                    {"itemType": 1, "metaId": 0, "amount": 1000}]},
                {"id": 3, "score": 15, "rewards": [
                    {"itemType": 1, "metaId": 0, "amount": 2000}]},
                {"id": 4, "score": 20, "rewards": [
                    {"itemType": 2, "metaId": 0, "amount": 50}]},
            ],
        },
        # DestinyFightChallengeScene:201 iterates destinyBattleList
        "destinyBattleConfig": {
            "destinyBattleList": [
                {"id": 1, "monsterGroupId": 100101, "stageType": 1},
                {"id": 2, "monsterGroupId": 100102, "stageType": 1},
                {"id": 3, "monsterGroupId": 100103, "stageType": 2},
            ],
        },
        # KingTempleScene:72 indexes spiritConcentrateCostList
        "spiritConcentrateCostConfig": {
            "spiritConcentrateCostList": [
                {"concentrateMin": 1, "concentrateMax": 5, "cost": 10},
                {"concentrateMin": 6, "concentrateMax": 10, "cost": 20},
                {"concentrateMin": 11, "concentrateMax": 20, "cost": 50},
                {"concentrateMin": 21, "concentrateMax": -1, "cost": 100},
            ],
        },
        # EnchantGuideRewardPanel / Enchant.enabled read this with no nil
        # guard. Missing after closing 每日签到 (level>=35) => SIGKILL.
        "enchantTotalConfig": {
            "equipMetaId": 210011,
            "enchantLevel": 1,
            "atk": 1,
            "def": 1,
            "hp": 1,
            "quality3": 100,
            "quality4": 100,
            "quality5": 100,
            "quality6": 100,
            "quality7": 100,
        },
        # TreasureGachaScene:67 / :213 — gachaNode.requisites[1].amount +
        # countdownDuration. Missing => SIGKILL on 宝物扭蛋.
        "treasureGachaConfig": {
            "gachaNode": {
                "id": 1,
                "countdownDuration": 86400,
                "requisites": [
                    {"itemType": 2, "metaId": 0, "amount": 50},
                ],
            },
        },
        # TreasureManager / MessageBoxPanel / SecretaryScene — unlockLevel
        # is nil-guarded in some paths, but treasurePool* are not.
        "treasureSettingConfig": {
            "unlockLevel": 60,
            "treasurePoolInitSize": 50,
            "treasureExtraSizePerPurchase": 10,
            "treasurePoolMaxExpandTimes": 20,
            "treasurePoolExpandCost": 50,
            "treasurePotentialUp": 10,
            "treasurePotentialCost": 100,
            # ⚠️ 400001 是「经验球」，不是潜力石。客户端 TreasureSystemUtils.getPotentialStone()
            # 读的就是这个字段，填错会让界面把经验球当潜力石显示/校验。
            # 真正的潜力石 = 400350（prop_meta.readName='潜力石'，treasure_potential_*.ID 也是它）。
            "treasurePropId": 400350,
            "treasureRenascence": 50,
        },
        # ChatManager / UnionChatContainerPanel — no nil guards.
        "chatSettingConfig": {
            "worldChatShowMax": 50,
            "privateChatShowMax": 50,
            "unionChatShowMax": 50,
            "messageLengthMax": 60,
            "worldChatQuota": 20,
        },
        # GachaScene activity node (id=5). Nil-guarded in getActivityConfigNode
        # but other paths iterate gachaNodes via ipairs without a parent check.
        "gachaCardConfig": {
            "gachaNodes": [
                {"id": 1, "showCards": "101011,102011,103011",
                 "pointReward": 0, "rpReward": 0, "activityName": ""},
                {"id": 2, "showCards": "101021,102021,103021",
                 "pointReward": 0, "rpReward": 0, "activityName": ""},
                {"id": 3, "showCards": "101031,102031,103031",
                 "pointReward": 1, "rpReward": 1, "activityName": ""},
                {"id": 5, "showCards": "101041,102041,103041",
                 "pointReward": 1, "rpReward": 1,
                 "activityName": "activityGachaXiaoyu"},
            ],
        },
        "gameSettingConfig": _game_setting_config(),
        "battleSettingConfig": _battle_setting_config(),
        # ⚠️ 日常任务配置。MainMenuScene.lua:893 点「任务」时**无 nil 守卫**地读
        #     DataManager.GameMetaData.dailyActiveConfig.levelLimit
        # 少一个字段就是 "attempt to index field 'dailyActiveConfig' (a nil value)"
        # -> engine SIGKILL。AchievementScene:458 / DailyTargetScene:143 /
        # MainMenuScene:1686 同样直接解引用。
        # activeConfigItems: [{id, conditionNum, ...}]   activeRewardItems: [{id, activeValue, ...}]
        "dailyActiveConfig": {
            "levelLimit": 1,
            "activeConfigItems": [],
            "activeRewardItems": [],
        },
        # SecretaryScene.lua:67-69 直接读 .unlockLevel（且 spiritSettingConfig /
        # treasureSettingConfig 在别处也有解引用），必须给全。
        # treasureSettingConfig is defined above with its full native contract.
        # Repeating the key here discarded that config and changed 60 to 1,
        # which triggered an unlock popup with no matching client definition.
        "paymentExchangeConfig": {
            # MetaManager.getPaymentExchangeConfig reads .paymentExchanges
            "paymentExchanges": _payment_exchanges(),
        },
        "serverPartitionConfig": {
            "runningServers": [{"serverId": 1, "serverName": "本地测试服",
                                "enable": True, "beginTime": "0",
                                "serverBusy": 100000, "serverNormal": 50000,
                                "newServer": False, "whiteAccountIds": ""}],
            "preparedServers": [],
        },
        "metaVersion": {"meta_version": "0.0.0", "maintenance_version": "0.0.0",
                        "methods": []},
    }

    # Captured non-chat configuration fills absent fields; existing economy and
    # local server routing retain precedence. No reference player data is used.
    import json
    from pathlib import Path
    captured = json.loads(Path(__file__).with_name('reference_meta.json').read_text(encoding='utf8'))
    def supplement(target, source):
        for key, value in source.items():
            if key not in target:
                target[key] = value
            elif isinstance(target[key], dict) and isinstance(value, dict):
                supplement(target[key], value)
    supplement(payload, captured)
    # Actual online activity configuration supersedes placeholder empty rewards.
    online = json.loads(Path(__file__).with_name('online_activity_meta.json').read_text(encoding='utf8'))
    def merge_activity(target, source):
        for key, value in source.items():
            if isinstance(value, dict) and isinstance(target.get(key), dict):
                merge_activity(target[key], value)
            elif value != {}:
                target[key] = value
    merge_activity(payload, online)
    # Native activity_gem_consume.lua repeats the key `item` six times;
    # a dict-based Lua parser silently retained only the final tier.
    payload['activityGemConsumeConfig']['gemConsumeRewards'] = [
        {'id': i, 'requireGold': threshold, 'rewardPackageId': 15048 + i}
        for i, threshold in enumerate([500, 1000, 2000, 5000, 10000, 30000], 1)]
    # Match the UI price and cooldown to the rules used by GachaService.
    import luaconf
    nodes=[]
    for rule in luaconf.as_list(luaconf.load('gacha_card')):
        requisite=(rule.get('requisites') or {}).get('requisite') or {}
        nodes.append({'id':int(rule['id']),
                      'pointReward':int(rule.get('pointReward') or 0),
                      'rpReward':int(rule.get('rpReward') or 0),
                      'activityName':rule.get('activityName') or '',
                      'requisites':[requisite] if requisite else [],
                      'freeEnabled':bool(rule.get('countdownFree')),
                      'freeResetSeconds':int(rule.get('countdownDuration') or 0)})
    payload['gachaCardConfig']={'gachaNodes':nodes}
    _fill_missing_client_fields(payload)
    return payload


# ---------------------------------------------------------------------------
# 客户端会**直接读**、但原厂没随包下发的字段。
#
# 这类缺失最阴：顶层 key 都在，界面看着能开，一进某个活动页签就
# `attempt to index a nil value` → 引擎 SIGKILL（闪退）。
# 例子：Activity_NewChargeRewardLayer.lua:89 读 `payRewards[1].gold`，
# 而 activityNewYearConfig 原来只有 featureName 那几个字段。
#
# 判据脚本：`python scripts/audit_meta_keys.py`（比对客户端 GameMetaData.<k>[.<f>]）
# 取值原则：**结构完整、语义为空**。会被下标访问的（payRewards / diceNewRewardItems）
# 必须给出足够长的数组，且元素内部字段齐全。
# ---------------------------------------------------------------------------
_DICE_STAR_EMPTY = [
    {'starCount': s,
     'content1Type': 0, 'content1Id': 0, 'content1Amount': 0,
     'content2Type': 0, 'content2Id': 0, 'content2Amount': 0,
     'content3Type': 0, 'content3Id': 0, 'content3Amount': 0}
    for s in range(1, 7)
]

_FILL_MISSING = {
    # Activity_NewChargeRewardLayer:89  payRewards[1].gold / payRewards[2].gold
    # Activity_NewYearLayer:135/149    payRewards[i].rewardText
    'activityNewYearConfig': {
        'payRewards': [
            {'id': 1, 'gold': 100, 'rewardText': '', 'rewardPackageId': 0},
            {'id': 2, 'gold': 300, 'rewardText': '', 'rewardPackageId': 0},
            {'id': 3, 'gold': 1000, 'rewardText': '', 'rewardPackageId': 0},
        ],
    },
    # ActivitySilverDiceLayer_POP:89  diceNewRewardItems[starCount].contentNId
    'activityDiceConfig': {
        'diceNewRewardItems': _DICE_STAR_EMPTY,
        'maxChangeLuckCount': 3,
    },
    # 社群点赞：Activity_PraiseLayer:88 `rewardIds = praiseRewardItems`，
    # :208 直接 `rewardIds[i].rewardPackId`（i=1..3）—— 空数组会 nil 索引崩。
    # 马上发财：Activity_LotteryFortuneLayer:58 遍历 fortuneRewardItems，
    # :64 `MetaManager.reward_package[v.package_id]`，:68 直接读它的
    # content1Type —— package_id 指向的包不存在就 nil 索引崩。
    # 这里用真实存在、且 content1 是「卡/装备/道具」的包（11001/11002/11004...）。
    'activityFortuneNowConfig': {
        'fortuneRewardItems': [
            {'id': 1, 'package_id': 11001, 'packageId': 11001},
            {'id': 2, 'package_id': 11002, 'packageId': 11002},
            {'id': 3, 'package_id': 11003, 'packageId': 11003},
            {'id': 4, 'package_id': 11004, 'packageId': 11004},
            {'id': 5, 'package_id': 11005, 'packageId': 11005},
        ],
    },
    # 社群点赞：Activity_PraiseLayer:88 `rewardIds = praiseRewardItems`，
    # :208 直接 `rewardIds[i].rewardPackId`（i=1..3）—— 空数组会 nil 索引崩。
    'activityPraiseConfig': {
        'praiseRewardItems': [
            {'id': 1, 'rewardPackId': 10019},   # 魂石x500 + 钻石x10
            {'id': 2, 'rewardPackId': 11001},   # 金币x2000 + 一张卡
            {'id': 3, 'rewardPackId': 11004},   # 金币x5000 + 铜宝箱x3
        ],
    },
    'activityMultiplayerBossConfig': {'helpCardId': 0, 'encounterCardId': 0},
    'activityChargeFeedbackConfig': {'chargeFeedbackList': []},
    # 多重好礼：Activity_ConsumeRewardsLayer:458 取 config.consumeRewards 后
    # `pairs()` 建格子，nil 直接崩；格子按 `id` 找 icon_prop_<id>/btn_c<n>get。
    # 本服是纯充值活动、没有内容，给空数组（活动本身也已关闭，这里是兜底）。
    'activityConsumeRewardConfig': {
        'consumeRewards': [],
        'featureNameCharging': '',
    },
    # Activity_FacebookShareLayer / FacebookShareManager
    'fbShareConfig': {
        'requestNum': 0, 'finalReward': [], 'fbShareMetas': [],
        'featureNamePopup': 'activityFbShare',
    },
    # PKScene / CompeteScene / AcrossFightManager
    'pkSettingConfig': {
        'featureNamePkSession': 'pkSession',
        'featureNameGainReward': 'pkGainReward',
        'pkUnlockLevel': 15,
        'atkBuffId': 0,
        'atkBuffEffect': 0,
        'atkBuffNum': 0,
        'foeDisplayNum': 4,
        'rankListNum': 50,
        'refreshCooldown': 0,
        'eventPointCost': 0,
    },
    'pkRewardConfig': {'items': []},
    'pkDisplayPointsConfig': {'items': []},
    'redBagConfig': {'redBagList': []},
    'crossServerTimeConfig': {'items': []},
    'crossServerRewardConfig': {'items': []},
    'crossBossRewardConfig': {'rankRewardNodes': []},
}

# 顶层整个 key 都不在的
_FILL_TOP = {
    # AchievementScene.isEnable() 读这个 + MaintenanceManager.isActivityOpen(name)。
    # 为空/false 时「成就任务」里的图鉴成就那一类不加载，
    # 客户端 CellNumberList 少一项 → 领成就奖励必崩（AchievementScene:1289）。
    'cardBookFeatureName': 'cardBook',
    'crossServerSettingConfig': {
        'crossVersion': 0,
        'crossServerFeatureName': 'crossServer',
        # ⚠️ `serverIds` 必须是**逗号分隔的字符串**，不是数组：
        #    AcrossFightManager.lua:699 `aCrossServerGroup.serverIds:split(",")`。
        #    给数组 -> "attempt to call method 'split' (a nil value)" -> 进竞技场直接闪退。
        'crossServerGroups': [{'serverIds': '1'}],
        'guessPayGold': 0,
        'guessFactorMax': 0,
    },
    'payShopConfig': {'items': [], 'payShopMetas': []},
}


def _fill_missing_client_fields(payload):
    """就地补齐缺失字段。

    `_FILL_MISSING`：父配置在、只补子字段；已有值不覆盖。
    `_FILL_TOP`：整块补齐；**已有值为空（'' / None / [] / {}）也覆盖** ——
                 比如 cardBookFeatureName 原来被写成 ''，
                 AchievementScene.isEnable() 就永远 false，领成就必崩。
    """
    for key, extra in _FILL_MISSING.items():
        node = payload.get(key)
        if not isinstance(node, dict):
            continue
        for field, val in extra.items():
            # 空值（None/[]/''/{}）也覆盖：原厂占位里常是空数组，
            # 而客户端会直接下标取 [1] / 读 .field，空数组等于没给。
            if not node.get(field):
                node[field] = val
    for key, val in _FILL_TOP.items():
        if not payload.get(key):
            payload[key] = val
