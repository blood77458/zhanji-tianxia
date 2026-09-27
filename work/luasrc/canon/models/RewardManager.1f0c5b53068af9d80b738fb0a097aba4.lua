--------------------------------------------------------------------------------
-- RewardManager.lua - 奖励信息处理管理器
-- author: fanzhou.long
-- updated: 2013-08-20
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.models.ArenaManager"
require "canon.constants.GlobalConstants"
require "canon.manager.NotificationManager" 

----------------------------------------
-- 物品代码
----------------------------------------
ResourceEnum = {
  COIN = 1, --游戏币/银币
  GEMS = 2, --人民币/金币
  ENERGY = 3, --体力值
  EXP = 4, --经验值
	CARD = 5, --卡牌
	EQUIP = 6, --装备
	PROP = 7, --道具
  FRIENDPOINT = 8, --邀请点数
  GRID = 9, --背包格子
	SKILLPOINTS = 10, --技能点数
  EVENTPOINT = 11, --精力
	ARENASCORE = 12, --竞技场积分
  BEAST = 13,  --神兽
  BEAST_FRAGMENT = 14,  --神兽碎片
  GACHA_POINT = 16,  --扭蛋积分
  CARD_FRAGMENT = 17,  --卡牌碎片 将魂
  EQUIP_FRAGMENT = 18, --装备碎片 器魂
  RP_VALUE = 19,       --人品值
  UNION_CONTRIBUTION = 20, -- 军团贡献
  GENERALEXP    = 21,  -- 武将经验
  ASTRALESSENCE = 22,  -- 星灵
  VIP_EXP = 23,       --VIP经验
  SPIRIT = 24,        --元神
  ENCHANT_POINT = 26,        --装备灵值
  TREASURE = 27,      --宝物
  TREASURE_FRAGMENT = 28, --宝物碎片
  MEDAL = 29,
  MysteriousCoins = 30, --秘境货币


  CHARGE_FEEDBACK_BOX_1 = 10001,  --以下五个是充值回馈活动的宝箱
  CHARGE_FEEDBACK_BOX_2 = 10002,
  CHARGE_FEEDBACK_BOX_3 = 10003,
  CHARGE_FEEDBACK_BOX_4 = 10004,
  CHARGE_FEEDBACK_BOX_5 = 10005,
}

----------------------------------------
-- 处理奖励信息后数据更改广播通知的固定字符串
----------------------------------------
DataChangedNotifyEnum = table.const {
	CoinDataChanged = "CoinDataChanged", --1 银币（游戏币）	√ Handled - GameData.sharkUser.coins
	GemDataChanged = "GemDataChanged", --2 金币(平台币)		√ Handled - GameData.sharkUser.gems
	EnergyDataChanged = "EnergyDataChanged", --3 体力值		√ Handled - GameData.sharkUser.energy
	ExpDataChanged = "ExpDataChanged", --4 主角经验			√ Handled - GameData.sharkUser.exp
	CardDataChanged = "CardDataChanged", --5 卡牌			√ Handled - GameData.sharkCards
	EquipDataChanged = "EquipDataChanged", --6 装备			√ Handled - GameData.sharkEquips
	PropDataChanged = "PropDataChanged", --7 道具			√ Handled - Not in GameData
	FriendPointDataChanged = "FriendPointDataChanged", --8 邀请点数 √ Handled - GameData.sharkUserExtend.friendPoint
	GridDataChanged = "GridDataChanged", --9 格子			√ Handled - GameData.sharkUserExtend.boughtGridNum
	SkillPointDataChanged = "SkillPointDataChanged", --10 技能点数		× Unhandled - Not in GameData
	EventPointDataChanged = "EventPointDataChanged", --11 精力			√ Handled - GameData.sharkUser.eventPoint
	ArenaScoreDataChanged = "ArenaScoreDataChanged", --12 竞技场积分	× Unhandled - Not in GameData
    BaseUISceneDataChanged = "BaseUISceneDataChanged",  --BaseUI主角信息
  RechargeGemDataChanged = "RechargeGemDataChanged",  --充值获得的钻石
  BaseUIScenePlayerStrength = "BaseUIScenePlayerStrength", --刷新BaseUI主角战斗力
}

RewardManager = class(EventDispatcher)

function RewardManager:ctor(  )
  self.rechargeGemChangeListener = function(ee)
    local addedRechargeGemNum = ee.data
    
    if DataManager.GameMetaData.activityNewYearConfig and MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityNewYearConfig.featureNameCalcPay) then
      --Activity_NewChargeRewardLayer
      local sharkActivity = DataManager.getSharkActivity()
      sharkActivity.chargeInfo = sharkActivity.chargeInfo or {}
      if (not sharkActivity.chargeInfo.currVersion) or (sharkActivity.chargeInfo.currVersion ~= DataManager.GameMetaData.activityNewYearConfig.version) then
        sharkActivity.chargeInfo.currVersion = DataManager.GameMetaData.activityNewYearConfig.version
        sharkActivity.chargeInfo.gems = 0
        sharkActivity.chargeInfo.gainedRewardIds = {}
      end
      sharkActivity.chargeInfo.gems = sharkActivity.chargeInfo.gems + addedRechargeGemNum
      DataManager.setSharkActivity(sharkActivity)
      NotificationManager:dispatchEvent(Event.new("refreshForRechargeGemDataChanged"))
    end
  end
  if not NotificationManager:hasEventListener(DataChangedNotifyEnum.RechargeGemDataChanged,self.rechargeGemChangeListener) then
    NotificationManager:addEventListener(DataChangedNotifyEnum.RechargeGemDataChanged,self.rechargeGemChangeListener)
  end
end

RewardManager = RewardManager.new()

----------------------------------------
-- 将服务器返回的itemType码字与广播通知标识符对应
----------------------------------------
local itemTypeToRewardNotifyEnum = {
	DataChangedNotifyEnum.CoinDataChanged,
	DataChangedNotifyEnum.GemDataChanged,
	DataChangedNotifyEnum.EnergyDataChanged,
	DataChangedNotifyEnum.ExpDataChanged,
	DataChangedNotifyEnum.CardDataChanged,
	DataChangedNotifyEnum.EquipDataChanged,
	DataChangedNotifyEnum.PropDataChanged,
	DataChangedNotifyEnum.FriendPointDataChanged,
	DataChangedNotifyEnum.GridDataChanged,
	DataChangedNotifyEnum.SkillPointDataChanged,
	DataChangedNotifyEnum.EventPointDataChanged,
	DataChangedNotifyEnum.ArenaScoreDataChanged,
}

function RewardManager.getMaxLimitOfUserLevel()
  local result = 0
  for _, aUserLevelConfig in pairs(MetaManager.user_level) do
    if result < aUserLevelConfig.level then
      result = aUserLevelConfig.level
    end
  end
  return result
end

function generateCard(aCardId, aMetaId, aLevel, aExp)
  local aCard = {}
  aCard.cardId = aCardId
  aCard.metaId = aMetaId
  aCard.level = aLevel
  aCard.exp = aExp
  aCard.usedPotential = 0
  aCard.attTrainValue = 0
  aCard.defTrainValue = 0
  aCard.hpTrainValue = 0
  aCard.attEvolveValue = 0
  aCard.defEvolveValue = 0
  aCard.hpEvolveValue = 0
  aCard.equipIds = {}
  aCard.cardSkills = {}
  aCard.avatarMetaId = 0
  aCard.treasureId = 0
  
  local aSkillIDList = {}
  local aSkill = nil
  local aCardMetaConfig = MetaManager.card_meta[aCard.metaId]
  if tonumber(aCardMetaConfig.skill, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.skill, 10)
    aSkill.groupIds = nil
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.mainSkill, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.mainSkill, 10)
    aSkill.groupIds = nil
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.groupSkill1, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.groupSkill1, 10)
    aSkill.groupIds = tostring(aCardMetaConfig.group1)
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.groupSkill2, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.groupSkill2, 10)
    aSkill.groupIds = tostring(aCardMetaConfig.group2)
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.groupSkill3, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.groupSkill3, 10)
    aSkill.groupIds = tostring(aCardMetaConfig.group3)
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.groupSkill4, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.groupSkill4, 10)
    aSkill.groupIds = tostring(aCardMetaConfig.group4)
    table.insert(aSkillIDList, aSkill)
  end
  if tonumber(aCardMetaConfig.groupSkill5, 10) ~= 0 then
    aSkill = {}
    aSkill.skillId = tonumber(aCardMetaConfig.groupSkill5, 10)
    aSkill.groupIds = tostring(aCardMetaConfig.group5)
    table.insert(aSkillIDList, aSkill)
  end
  local cardGroupId = aCardMetaConfig.cardGroupId
  if MetaManager.special_group_skill[cardGroupId] ~= nil then
    local specialGroupSkills = MetaManager.special_group_skill[cardGroupId]
    for i=1,3 do
      if specialGroupSkills["groupSkill"..i] == 0 then
        break
      else
        aSkill = {}
        aSkill.skillId = tonumber(specialGroupSkills["groupSkill"..i], 10)
        aSkill.groupIds = nil
        aSkill.countryGroupId = tonumber(specialGroupSkills["group"..i], 10)
        aSkill.countryGroupNum = tonumber(specialGroupSkills["groupNum"..i], 10)
        table.insert(aSkillIDList, aSkill)
      end
    end
  end
  
  for _, aSkill in ipairs(aSkillIDList) do
    local aCardSkill = {}
    local aSkillMeta = MetaManager.skill_meta[aSkill.skillId]
    if SystemManager.debug then
      DebugManager.assert(aSkillMeta ~= nil, "没有这个卡牌技能id! aSkill.skillId = " .. tostringRich(aSkill.skillId) .. ", aCardId = " .. tostringRich(aCardId) .. ", aMetaId = " .. tostringRich(aMetaId))
    end
    aCardSkill.skillType = aSkillMeta.skillType
    aCardSkill.skillId = aSkill.skillId
    aCardSkill.currQuality = aSkillMeta.quality
    if aSkill.groupIds then
      aCardSkill.cardGroupIds = aSkill.groupIds:split("|")
      local aCount = #aCardSkill.cardGroupIds
      for i = 1, aCount do
        aCardSkill.cardGroupIds[i] = tonumber(aCardSkill.cardGroupIds[i], 10)
      end
    else
      aCardSkill.cardGroupIds = {}
    end
    if aCardSkill.skillType == 4 then
      aCardSkill.countryGroupId = aSkill.countryGroupId 
      aCardSkill.countryGroupNum = aSkill.countryGroupNum
    else
      aCardSkill.countryGroupId = 0 
      aCardSkill.countryGroupNum = 0
    end
    table.insert(aCard.cardSkills, aCardSkill)
  end
  return aCard
end

function generateEquip(aEquipId, aMetaId, aLevel, aExp, enchantLevel, enchantNum)
  local aEquip = {}
  aEquip.equipId = aEquipId
  aEquip.metaId = aMetaId
  aEquip.level = aLevel
  aEquip.cardId = 0
  aEquip.exp = aExp
  aEquip.enchantLevel = enchantLevel or 0--ENCHANT_MODIFY
  aEquip.enchantNum = enchantNum or 0
  return aEquip
end

function generateSpirit(aSpiritId, aMetaId, aLevel, aExp)
  local aSpirit = {}
  aSpirit.spiritId = aSpiritId
  aSpirit.metaId = aMetaId
  aSpirit.level = aLevel
  aSpirit.cardId = 0
  aSpirit.exp = 0
  aSpirit.lockAttributeIndex = 0
  aSpirit.sharkSpiritAttributes = {}
  return aSpirit
end

----------------------------------------
-- 设置体力值，并更新时间为当前值
----------------------------------------
function RewardManager.setEnergy(energy)
  local gameInitData = DataManager.getGameInitData()
  gameInitData.sharkUser.energy = energy
  gameInitData.sharkUser.energyLastUpdateTime = TimeUtil.getServerTimeSeconds()
  DataManager.setGameInitData(gameInitData)
end

----------------------------------------
-- 设置精力值，并更新时间为当前值
----------------------------------------
function RewardManager.setEventPoint(eventPoint)
  local gameInitData = DataManager.getGameInitData()
  gameInitData.sharkUser.eventPoint = eventPoint
  gameInitData.sharkUser.eventPointLastUpdateTime = TimeUtil.getServerTimeSeconds()
  DataManager.setGameInitData(gameInitData)
end

local function isCurVipMaxLevel(level)--判断VIPLEVEL是否为最大
	local maxLevel = 0
	for k,v in pairs(MetaManager.vip_setting) do
		if maxLevel < v.level then
			maxLevel = v.level
		end
	end
	return level >= maxLevel
end

----------------------------------------
-- 对于奖励的响应数据进行统一的处理
--Example:
--function equipSellResponse( evt )
--	RewardManager.getReward(evt.data.rewards)
--  ...
--end
----------------------------------------
function RewardManager:getReward( rewardData , inBattleScene)
	--兼容处理获得与消耗，本函数只负责计算数值，对于消耗的边界判断应在之前进行
  if not rewardData then
    return
  end
  if type(rewardData) ~= "table" then
    assert(false, "RewardManager.lua, getReward:rewardData must a table!")
  end
  if #rewardData <= 0 then
    return
  end
	--print(table.tostring(rewardData))
	--将游戏数据读出
	local GameData = DataManager.getGameInitData()
	local gemChanged = false
	for key, value in pairs(rewardData) do
		--处理奖励数据
		--资源类型字典参见：
		--http://wiki.happyelements.net/pages/viewpage.action?pageId=13218126
		if (value.itemType == ResourceEnum.COIN) then
			GameData.sharkUser.coins = ""..(tonumber(GameData.sharkUser.coins) + tonumber(value.amount))
		elseif (value.itemType == ResourceEnum.GEMS) then
			--TODO 区分充值获得的金币与奖励获得的金币
			GameData.sharkUser.freeGems = GameData.sharkUser.freeGems + tonumber(value.amount)
      gemChanged = true
      
		elseif (value.itemType == ResourceEnum.ENERGY) then
			local maxEnergy = MetaManager.game_meta.gameSettingConfig.maxEnergy
			if (CalculationManager.calcComplex_getEnergyNow()>=maxEnergy) then
				GameData.sharkUser.energyLastUpdateTime = TimeUtil.getServerTimeSeconds()
				if (GameData.sharkUser.energy<maxEnergy) then
					GameData.sharkUser.energy = maxEnergy
				end
			end
			GameData.sharkUser.energy = GameData.sharkUser.energy + tonumber(value.amount)
			if (GameData.sharkUser.energy<0) then
				local nowTime = TimeUtil.getServerTimeSeconds()
				local stRecovered = math.modf((nowTime - GameData.sharkUser.energyLastUpdateTime) / st_recover_per_second)
				GameData.sharkUser.energy = GameData.sharkUser.energy + stRecovered
				GameData.sharkUser.energyLastUpdateTime = nowTime - ((nowTime - GameData.sharkUser.energyLastUpdateTime) % st_recover_per_second)
			end
		elseif (value.itemType == ResourceEnum.EXP) then
			GameData.sharkUser.exp = ""..(tonumber(GameData.sharkUser.exp) + tonumber(value.amount))
			local aUserLevelConfig = MetaManager.user_level[GameData.sharkUser.level]
			local aMaxLevel = RewardManager.getMaxLimitOfUserLevel()
      
			while tonumber(GameData.sharkUser.exp, 10) >= tonumber(aUserLevelConfig.exp, 10) do
				if GameData.sharkUser.level >= aMaxLevel then
					break
				end
				GameData.sharkUser.exp = tostring(tonumber(GameData.sharkUser.exp)-tonumber(aUserLevelConfig.exp))
				GameData.sharkUser.level = GameData.sharkUser.level + 1
				aUserLevelConfig = MetaManager.user_level[GameData.sharkUser.level]
			end
      
		elseif (value.itemType == ResourceEnum.CARD) then
			--TODO 消耗卡牌
			local aCard = generateCard(value.id, value.metaId, value.level, tonumber(value.exp))
			table.insert(GameData.sharkCards.sharkCards, aCard)
		elseif (value.itemType == ResourceEnum.EQUIP) then
			--TODO 消耗装备
			local aEquip = generateEquip(value.id, value.metaId, value.level, tonumber(value.exp), value.enchantLevel, value.enchantNum)
			table.insert(GameData.sharkEquips.sharkEquips, aEquip)
		elseif (value.itemType == ResourceEnum.PROP) then
			local aProp = {
				metaId = value.metaId,
				amount = tonumber(value.amount),
			}
			local propTable,keyNo = CommonManager.getSubTableByKey(
				GameData.sharkProps.sharkProps,
				{name = "metaId", value = aProp.metaId}
			)
			if (propTable) then
				GameData.sharkProps.sharkProps[keyNo].amount = tonumber(propTable.amount) + aProp.amount
			else
				table.insert(GameData.sharkProps.sharkProps, aProp)
			end
    elseif (value.itemType == ResourceEnum.SPIRIT) then
      --TODO 消耗元神
      local aSpirit = generateSpirit(value.id, value.metaId, value.level, tonumber(value.exp))
      table.insert(GameData.sharkSpirits.sharkSpirits, aSpirit)
    elseif (value.itemType == ResourceEnum.TREASURE) then
      if GameData.sharkTreasures == nil then
        GameData.sharkTreasures = {sharkTreasures = {}}
      end

      if GameData.sharkTreasures.sharkTreasures == nil then
        GameData.sharkTreasures.sharkTreasures = {}
      end
      --宝宝奖励
      local aTreasure = {
        treasureId = value.id,
        metaId = value.metaId,
        level = value.level,
        cardId = 0,
        addPotential = 0,
        addGemPotential = 0,
        usedPotential = 0,
        lock = false
      }
      table.insert(GameData.sharkTreasures.sharkTreasures, aTreasure)
    elseif (value.itemType == ResourceEnum.MEDAL) then
      if not GameData.sharkUserExtendMore then
          --若无数据 则建立默认数据
          GameData.sharkUserExtendMore = {medalNum = 0}
        end
      GameData.sharkUserExtendMore.medalNum = GameData.sharkUserExtendMore.medalNum + tonumber(value.amount)
    elseif (value.itemType == ResourceEnum.ENCHANT_POINT) then
      --装备灵值
      EnchantData.setEnchantPoint(EnchantData.getEnchantPoint() + tonumber(value.amount))

		elseif (value.itemType == ResourceEnum.FRIENDPOINT) then
			GameData.sharkUserExtend.friendPoint = GameData.sharkUserExtend.friendPoint + tonumber(value.amount)
		elseif (value.itemType == ResourceEnum.GRID) then
			GameData.sharkUserExtend.boughtGridNum = GameData.sharkUserExtend.boughtGridNum + tonumber(value.amount)
		elseif (value.itemType == ResourceEnum.EVENTPOINT) then
      local maxEventPoint = MetaManager.game_meta.gameSettingConfig.maxEventPoint
			if (CalculationManager.calcComplex_getEPNow()>=maxEventPoint) then
				GameData.sharkUser.eventPointLastUpdateTime = TimeUtil.getServerTimeSeconds()
				if (GameData.sharkUser.eventPoint<maxEventPoint) then
					GameData.sharkUser.eventPoint = maxEventPoint
				end
			end
			GameData.sharkUser.eventPoint = GameData.sharkUser.eventPoint + tonumber(value.amount)
			if (GameData.sharkUser.eventPoint<0) then
				local nowTime = TimeUtil.getServerTimeSeconds()
				local viRecovered = math.modf((nowTime - GameData.sharkUser.eventPointLastUpdateTime) / vi_recover_per_second)
				GameData.sharkUser.eventPoint = GameData.sharkUser.eventPoint + viRecovered
				GameData.sharkUser.eventPointLastUpdateTime = nowTime - ((nowTime - GameData.sharkUser.eventPointLastUpdateTime) % vi_recover_per_second)
			end
		elseif (value.itemType == ResourceEnum.ARENASCORE) then
			ArenaManager:sharedManager().arenaData.sharkArenaRank.score = ArenaManager:sharedManager().arenaData.sharkArenaRank.score + tonumber(value.amount)
      ArenaManager:sharedManager():dispatchEvent(Event.new(DataChangedNotifyEnum.ArenaScoreDataChanged))
		elseif (value.itemType == ResourceEnum.BEAST) or (value.itemType == ResourceEnum.BEAST_FRAGMENT) then
			--donothing
    elseif (value.itemType == ResourceEnum.GACHA_POINT) then
      --积分 黄水晶
      local gachaNodes = DataManager.GameMetaData.gachaCardConfig.gachaNodes
      if GameData.sharkActivity == nil then
        GameData.sharkActivity = {}
      end
      if GameData.sharkActivity.activityGachaInfo == nil then
        GameData.sharkActivity.activityGachaInfo = {}
      end
      for _, gachaNode in ipairs(gachaNodes) do
        if gachaNode.id == 5 then
          local gachaBeginTime = MaintenanceManager:getStartAndEndTime(gachaNode.activityName)[1].activityBeginTimeStamp
          local activityInfo = DataManager.getSharkActivity().activityGachaInfo

					if MaintenanceManager.isActivityOpen(gachaNode.activityName) and (GameData.sharkActivity.activityGachaInfo.featureBeginSeconds ~= gachaBeginTime) then
						--如果活动已经开启 并且版本号不一致 则重置版本号 并且积分清零
						GameData.sharkActivity.activityGachaInfo.featureBeginSeconds = gachaBeginTime
						GameData.sharkActivity.activityGachaInfo.point = 0
					end
				end
			end
			GameData.sharkActivity.activityGachaInfo.point = GameData.sharkActivity.activityGachaInfo.point + tonumber(value.amount)
		elseif (value.itemType == ResourceEnum.CARD_FRAGMENT) then
			--卡牌碎片
			local aCardFragment = {
				metaId = value.metaId,
				amount = tonumber(value.amount),
			}
			if not GameData.sharkCardFragments then
				--若无数据 则建立默认数据
				GameData.sharkCardFragments = {sharkCardFragments = {}}
			end
			local cardFragmentTable,keyNo = CommonManager.getSubTableByKey(
				GameData.sharkCardFragments.sharkCardFragments,
				{name = "metaId", value = aCardFragment.metaId}
			)
			if (cardFragmentTable) then
				GameData.sharkCardFragments.sharkCardFragments[keyNo].amount = tonumber(cardFragmentTable.amount) + aCardFragment.amount
			else
				table.insert(GameData.sharkCardFragments.sharkCardFragments, aCardFragment)
			end
		elseif (value.itemType == ResourceEnum.EQUIP_FRAGMENT) then
			--装备碎片
			local aEquipFragment = {
				metaId = value.metaId,
				amount = tonumber(value.amount),
			}
			if not GameData.sharkEquipFragments then
				--若无数据 则建立默认数据
				GameData.sharkEquipFragments = {sharkEquipFragments = {}}
			end
			local equipFragmentTable,keyNo = CommonManager.getSubTableByKey(
				GameData.sharkEquipFragments.sharkEquipFragments,
				{name = "metaId", value = aEquipFragment.metaId}
			)
			if (equipFragmentTable) then
				GameData.sharkEquipFragments.sharkEquipFragments[keyNo].amount = tonumber(equipFragmentTable.amount) + aEquipFragment.amount
			else
				table.insert(GameData.sharkEquipFragments.sharkEquipFragments, aEquipFragment)
			end
		elseif (value.itemType == ResourceEnum.RP_VALUE) then
			if GameData.sharkGachaInfo then
				GameData.sharkGachaInfo.rpValue = (tonumber(GameData.sharkGachaInfo.rpValue) + tonumber(value.amount))
			end
		elseif (value.itemType == ResourceEnum.ASTRALESSENCE) then
			GameData.sharkUserExtend.astralEssence = GameData.sharkUserExtend.astralEssence + tonumber(value.amount)
		elseif (value.itemType == ResourceEnum.GENERALEXP) then
			GameData.sharkUserExtend.generalExp = GameData.sharkUserExtend.generalExp + tonumber(value.amount)
    elseif (value.itemType == ResourceEnum.VIP_EXP) then
      GameData.sharkUser.vipExp = GameData.sharkUser.vipExp + tonumber(value.amount)
      while not isCurVipMaxLevel(GameData.sharkUser.vipLevel) and (GameData.sharkUser.rechargeGems + GameData.sharkUser.vipExp) >= MetaManager.vip_setting[GameData.sharkUser.vipLevel + 1].requireGold do
        GameData.sharkUser.vipLevel = GameData.sharkUser.vipLevel + 1
      end
    elseif (value.itemType == ResourceEnum.UNION_CONTRIBUTION) then
      local contributeValue = UnionManager.getMyContribute()
      contributeValue = contributeValue + tonumber(value.amount)
      UnionManager.setMyContribute(contributeValue)
    elseif (value.itemType == ResourceEnum.TREASURE_FRAGMENT) then
        if not GameData.sharkUserExtendMore then
          --若无数据 则建立默认数据
          GameData.sharkUserExtendMore = {treasureInfo = {treasureFragmentNum = 0}}
        end
        if not GameData.sharkUserExtendMore.treasureInfo then
          --若无数据 则建立默认数据
          GameData.sharkUserExtendMore.treasureInfo = {treasureFragmentNum = 0}
        end
      GameData.sharkUserExtendMore.treasureInfo.treasureFragmentNum = GameData.sharkUserExtendMore.treasureInfo.treasureFragmentNum + tonumber(value.amount)
    elseif (value.itemType == ResourceEnum.MysteriousCoins) then
        if not GameData.sharkMysteriousCoins then
          --若无数据 则建立默认数据
          GameData.sharkMysteriousCoins = {sharkMysteriousCoins = {}}
        end
        if not GameData.sharkMysteriousCoins.sharkMysteriousCoins then
          --若无数据 则建立默认数据
          GameData.sharkMysteriousCoins.sharkMysteriousCoins = {}
        end
        local NewMysteriousCoinsConfig = {}
        for _,config in ipairs(GameData.sharkMysteriousCoins.sharkMysteriousCoins) do
          NewMysteriousCoinsConfig[config.metaId] = config
        end
        for i=1,5 do
          if NewMysteriousCoinsConfig[i] == nil then
             NewMysteriousCoinsConfig[i] = {metaId = i,amount = "0"}
          end
        end
       GameData.sharkMysteriousCoins.sharkMysteriousCoins = NewMysteriousCoinsConfig
      GameData.sharkMysteriousCoins.sharkMysteriousCoins[value.metaId].amount  = tonumber(GameData.sharkMysteriousCoins.sharkMysteriousCoins[value.metaId].amount) + tonumber(value.amount)
		else
			assert(false, string.format("RewardManager:getReward unhandled item type:"..value.itemType))
		end
	end
	
	--将修改后的数据再次包装放进内存
	DataManager.setGameInitData(GameData)
    --通知BaseUIScene
	if not inBattleScene and not g_isInBattleScene then
		BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged,value))
	end
  
  if gemChanged and NotificationManager then
    NotificationManager:dispatchEvent(Event.new(DataChangedNotifyEnum.GemDataChanged))
  end
end

function RewardManager:gainReward( value )
	local GameData = DataManager.getGameInitData()
  local gemChanged = false
  --处理奖励数据
  --资源类型字典参见：
  --http://wiki.happyelements.net/pages/viewpage.action?pageId=13218126
  if (value.itemType == ResourceEnum.COIN) then
    GameData.sharkUser.coins = ""..(tonumber(GameData.sharkUser.coins) + tonumber(value.amount))
  elseif (value.itemType == ResourceEnum.GEMS) then
    local aNegativeValue = -value.amount
    local aNegativeFree = 0
    local aNegativeRecharge = 0
    if aNegativeValue <= tonumber(GameData.sharkUser.freeGems) then
      GameData.sharkUser.freeGems = tonumber(GameData.sharkUser.freeGems) - aNegativeValue
    else
      GameData.sharkUser.rechargeGems = tonumber(GameData.sharkUser.rechargeGems) - (aNegativeValue - tonumber(GameData.sharkUser.freeGems))
      GameData.sharkUser.freeGems = 0
    end
    gemChanged = true
  elseif (value.itemType == ResourceEnum.ENERGY) then
    GameData.sharkUser.energy = GameData.sharkUser.energy + tonumber(value.amount)
  elseif (value.itemType == ResourceEnum.EXP) then
    GameData.sharkUser.exp = ""..(tonumber(GameData.sharkUser.exp) + tonumber(value.amount))
  elseif (value.itemType == ResourceEnum.FRIENDPOINT) then
    GameData.sharkUserExtend.friendPoint = GameData.sharkUserExtend.friendPoint + tonumber(value.amount)
  elseif (value.itemType == ResourceEnum.GRID) then
    GameData.sharkUserExtend.boughtGridNum = GameData.sharkUserExtend.boughtGridNum + tonumber(value.amount)
  elseif (value.itemType == ResourceEnum.EVENTPOINT) then
    GameData.sharkUser.eventPoint = GameData.sharkUser.eventPoint + tonumber(value.amount)
	elseif (value.itemType == ResourceEnum.BEAST) or (value.itemType == ResourceEnum.BEAST_FRAGMENT) then
		--donothing
  elseif (value.itemType == ResourceEnum.ASTRALESSENCE) then
    GameData.sharkUserExtend.astralEssence = GameData.sharkUserExtend.astralEssence + tonumber(value.amount)

  else
    assert(false, string.format("RewardManager:gainReward unhandled item type:"..value.itemType))
  end
	--将修改后的数据再次包装放进内存
	DataManager.setGameInitData(GameData)
  
  --通知BaseUIScene
    BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged,value))
    
    if gemChanged and NotificationManager then
      NotificationManager:dispatchEvent(Event.new(DataChangedNotifyEnum.GemDataChanged))
    end
end

function RewardManager:resetGem(gemCount)
  local GameData = DataManager.getGameInitData()
  GameData.sharkUser.gems = gemCount
  DataManager.setGameInitData(GameData)
  BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged))
  if NotificationManager then
    NotificationManager:dispatchEvent(Event.new(DataChangedNotifyEnum.GemDataChanged))
  end
end

-----------------------------------------------------
-- 删除卡牌
-- removeIds 卡牌id列表
-- 一定要提前判断不能删除的情况 比如主卡牌或者上阵卡牌/阵型卡牌
-----------------------------------------------------
function RewardManager:removeCards(removeIds)
  local cardData = DataManager.getCardsData()
  local toremoveKeys = {}
  for k,card in ipairs(cardData) do
    for key, mCard in pairs(removeIds) do
      if card.cardId == mCard then
        table.insert(toremoveKeys, k)
        break;
      end
    end
  end
  for i = #toremoveKeys, 1, -1 do
    table.remove(cardData, toremoveKeys[i])
  end
  DataManager.setCardsData(cardData)
end