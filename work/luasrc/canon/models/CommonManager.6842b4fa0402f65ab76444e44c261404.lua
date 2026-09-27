-- 战斗力改用后端的计算结果 modified by zheng.che @ 2014-12-21
-- 阵魂加入计算加成 by dangchao 2015/4/10
require "canon.data.MetaManager"
require "canon.manager.MagicCircleManager"

g_previousPlayerStrength = nil
g_previousPlayerFateStatus = nil

VipFunctionEnum = {
  kMiddleGradeGacha = 1,
  kHighGradeGacha = 2,
  kMasterTrain = 3,
  kSkipBattleAnimation = 4,
  kImmediatelyFinishTower = 5,
  kLimitPurchaseVip = 6,
  kVipPack = 7,
  kUseVipProp = 8,
  kAddElitePVECount = 9,
  kBuyEquipEvolveProp = 10,
  kBuySkillUpgradeProp = 11,
}

g_cardInfoCache = {}
g_cardCountryNumCache = {}

local tEquipDataCache = nil
local tQueueDataCache = nil
local tMatrixCardDataCache = nil
local tSharkMatrixDataCache = nil
local tCardDataCache = nil
local tTreasureDataCache = nil
local bInCacheState = false

local function getCardGroupListWithCardEquipedList(cardEquipedList,cardData, matrixList)
	if not matrixList then
		matrixList = tMatrixCardDataCache or CommonManager:getMatrixCardData()
	end
	local effectCardList = table.clone(cardEquipedList, true)
	for k, v in pairs(matrixList) do 
		table.insert(effectCardList, v)
	end
	
  cardData = cardData or DataManager.getCardsData()
  --get all card groups whick each card equiped belongs to
  local cardGroupList = {}
  for _, aCardId in ipairs(effectCardList) do
    local temp = CommonManager.getSubTableByKey(
		cardData,
		{name = "cardId", value = aCardId}
	)
	local temp2 = MetaManager.card_meta[temp.metaId]
  if SystemManager.debug then
    DebugManager.assert(temp2 ~= nil, "CommonManager 无此卡牌配置! temp.metaId = " .. tostringRich(temp.metaId))
  end
	table.insert(cardGroupList, temp2.cardGroupId)
  end
  return cardGroupList
end

local function getGroupSkillEffect(aCardGroupList, aGroupSkillID, aGroup , aCardMeta ,extraParams)
  if aGroupSkillID == 0 then
    return
  end
  local aTemporaryGroupList = {}

  if extraParams.cardGroupInterworking then
    for _, temp in ipairs(aCardGroupList) do
      local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
      if specialGroupMeta[temp] == nil then
        aTemporaryGroupList[temp] = (aTemporaryGroupList[temp] or 0) + 1
        -- table.insert(aTemporaryGroupList, temp)
      else
        local aGroupList = specialGroupMeta[temp]
        for k,v in pairs(aGroupList) do
          aTemporaryGroupList[v] = (aTemporaryGroupList[v] or 0) + 1
          -- table.insert(aTemporaryGroupList, tonumber(v))
        end
      end
    end
  else
    for _, temp in ipairs(aCardGroupList) do
      aTemporaryGroupList[temp] = (aTemporaryGroupList[temp] or 0) + 1
      -- table.insert(aTemporaryGroupList, temp)
    end
  end

  local aRequiredGroupList = aGroup:split("|")
  for _, temp in ipairs(aRequiredGroupList) do
    local aGroupID = tonumber(temp, 10)
    local existed = false
    for aIndex, temp2 in pairs(aTemporaryGroupList) do
      if aGroupID == tonumber(aIndex) then
        -- table.remove(aTemporaryGroupList, aIndex)
        local cardGroupId = aCardMeta.cardGroupId
        if extraParams.cardGroupInterworking and CommonManager:checkSpecialGroupCombineSelf( cardGroupId , aRequiredGroupList) then
          cardGroupId = tostring(cardGroupId)
          if aTemporaryGroupList[cardGroupId] and aTemporaryGroupList[cardGroupId] >= 2 then
            existed = true
          else
            existed = false
          end
        else
          existed = true
        end
        break
      end
    end
    if not existed then
      return
    end
  end
  
  local aSkillMetaConfig = MetaManager.skill_meta[aGroupSkillID]

  --在debug模式校验是否存在技能配置 add by zheng.che @ 2014-9-10 15:23:04
  if SystemManager.debug then
    DebugManager.assert(aSkillMetaConfig ~= nil, "无此技能编号! aGroupSkillID = " .. tostringRich(aGroupSkillID))
  end
  
  local result = {}
  local aSkillStatusList = aSkillMetaConfig.statusIdList:split("|")
  for _, temp in ipairs(aSkillStatusList) do
    local aSkillStatus = tonumber(temp, 10)
    if aSkillStatus ~= 0 then
      local aSkillStatusConfig = MetaManager.skill_status[aSkillStatus]
      if tonumber(aSkillStatusConfig.feedback, 10) == 1 then
        local aResult = {}
        aResult.impactAttr = tonumber(aSkillStatusConfig.impactAttr, 10)
        aResult.valueType = tonumber(aSkillStatusConfig.valueType, 10)
        aResult.effectValue = tonumber(aSkillStatusConfig.effectValue, 10)
        table.insert(result, aResult)
      end
    end
  end
  return result
end

local function getSpecialGroupSkillEffect(aGroupSkillID)
  if aGroupSkillID == 0 then
    return
  end
  
  local aSkillMetaConfig = MetaManager.skill_meta[aGroupSkillID]
  
  local result = {}
  local aSkillStatusList = aSkillMetaConfig.statusIdList:split("|")
  for _, temp in ipairs(aSkillStatusList) do
    local aSkillStatus = tonumber(temp, 10)
    if aSkillStatus ~= 0 then
      local aSkillStatusConfig = MetaManager.skill_status[aSkillStatus]
      if tonumber(aSkillStatusConfig.feedback, 10) == 1 then
        local aResult = {}
        aResult.impactAttr = tonumber(aSkillStatusConfig.impactAttr, 10)
        aResult.valueType = tonumber(aSkillStatusConfig.valueType, 10)
        aResult.effectValue = tonumber(aSkillStatusConfig.effectValue, 10)
        table.insert(result, aResult)
      end
    end
  end
  return result
end

--
-- CommonManager
--

CommonManager = class()
local commonManagerInstance = nil
function CommonManager:sharedManager()
	if not commonManagerInstance then
		commonManagerInstance = CommonManager.new()
	end
	return commonManagerInstance
end

function CommonManager:ctor(  )
end

function CommonManager:getUnlockVipLevel(aVipFunction)
  local result = 10000
  local existed = false
  for _, aVipConfig in pairs(MetaManager.vip_setting) do
    if aVipConfig.level <= result then
      local aFuncList = aVipConfig.unlockContents:split(",")
      for _, aFuncNum in pairs(aFuncList) do
        if tonumber(aFuncNum, 10) == aVipFunction then
          result = aVipConfig.level
          existed = true
        end
      end
    end
  end
  if not existed then
    result = 0
  end
  return result
end

----------------------------------------
-- Description: 从 目标表 中根据 键名和键值 获得 相关子表 的函数
--[[
Example: 从card_meta表中获取 "id" 的值为 "101011" 的卡片子表
local aCard, cardNo = CommonManager.getSubTableByKey(
  MetaManager.card_meta,
  {name = "id", value = "101011"}
)
]]
function CommonManager.getSubTableByKey(sourceTable, key)
	local subTable = nil
	local keyNo = -1
	for aKey, aValue in pairs(sourceTable) do
		if (tostring(sourceTable[aKey][key.name])==tostring(key.value)) then
			subTable = sourceTable[aKey]
			keyNo = aKey
			break;
		end
	end
	return subTable,keyNo
end

--added by lixin
function CommonManager.cacheCardInfo()
  bInCacheState = bEnabled
  tQueueDataCache = CommonManager.getQueueData()
  tMatrixCardDataCache = CommonManager.getMatrixCardData()
  tSharkMatrixDataCache = DataManager.getSharkMatricesData()
  tCardDataCache = DataManager.getCardsData()
  tEquipDataCache = DataManager.getEquipsData()
  tTreasureDataCache = DataManager.getTreasuresData()
end

function CommonManager.clearCaches()
  bInCacheState = bEnabled
  tQueueDataCache = nil
  tMatrixCardDataCache = nil
  tSharkMatrixDataCache = nil
  tCardDataCache = nil
  tEquipDataCache = nil
  tTreasureDataCache = nil
end

----------------------------------------
-- Description: 获取当前队列中卡牌的ID，第1位为主将
-- author: fangzhou.long
----------------------------------------
function CommonManager.getQueueData( mCardId, addCardList )
	local queue = {}

	local UserData = DataManager.getCurrUser()
	--sort the additionalcard
	local additionalCardIdStr =
		(type(addCardList) == "string")
		and addCardList
		or UserData.additionalCardIds
	tempQueue = additionalCardIdStr:split(",")
	--sort the main card
	local mainCardId = 
		(type(mCardId) == "number")
		and mCardId
		or tonumber(UserData.mainCardId)
	table.insert(
		queue,
		mainCardId
	)
	for _,aCardIdStr in pairs(tempQueue) do
		table.insert(
			queue,
			tonumber(aCardIdStr)
		)
	end
	return queue
end

function CommonManager:getCardPropertiesWithCardId(aCardId, cardEquipedList, cardGroupList, cardData)   --get card att, def and hp by cardId
  local aCard
	if not cardData then
		cardData = tCardDataCache or DataManager.getCardsData()
	end
  for _, temp in ipairs(cardData) do
    if aCardId == temp.cardId then
      aCard = temp
      break
    end
  end
  return self:getCardPropertiesWithSharkCard(aCard)
end

function CommonManager:setCardNeedUpdate(cardIdTable)
	if type(cardIdTable) == "table" then
		for k, v in pairs(cardIdTable)
		do
			print("set CARD dirty  with cardId " .. v)
			if g_cardInfoCache[v] then
				g_cardInfoCache[v].needUpdate = true
			else
				if table.getn(g_cardInfoCache) > 0 then
				print("maybe error?")
				end
			end
		end
	end
end



function CommonManager:getBackpackCardPropertiesWithSharkCard(aCard)
--when need update ? 1.card levelup or evolved   2. dealwithequip 3.dealwithqueue
	if not g_cardInfoCache[aCard.cardId] or g_cardInfoCache[aCard.cardId].needUpdate then
   
		g_cardInfoCache[aCard.cardId] = self:getCardPropertiesWithSharkCard(aCard)
		g_cardInfoCache[aCard.cardId].price = MetaManager.card_meta[aCard.metaId].basicPrice * MetaManager.card_level[aCard.level].priceCoefficient
		local matterCardLevelConfig = MetaManager.card_level[aCard.level]
		local matterCardExp = matterCardLevelConfig.totalExp + aCard.exp
		g_cardInfoCache[aCard.cardId].resultExp = MetaManager.card_meta[aCard.metaId].basicExp + (matterCardExp*matterCardLevelConfig.expConvertCoefficient)
		g_cardInfoCache[aCard.cardId].totalPotential =  MetaManager.card_rare[MetaManager.card_meta[aCard.metaId].rare].addPotential * aCard.level
	end
	g_cardInfoCache[aCard.cardId].needUpdate = false;
 
	return g_cardInfoCache[aCard.cardId]
end

function CommonManager:getBackpackCardPropertiesWithSharkCardWithoutCardProperties(aCard)
  local cardProperty = {}
  cardProperty.level = aCard.level
  cardProperty.price = MetaManager.card_meta[aCard.metaId].basicPrice * MetaManager.card_level[aCard.level].priceCoefficient
  local matterCardLevelConfig = MetaManager.card_level[aCard.level]
  local matterCardExp = matterCardLevelConfig.totalExp + aCard.exp
  cardProperty.resultExp = MetaManager.card_meta[aCard.metaId].basicExp + (matterCardExp*matterCardLevelConfig.expConvertCoefficient)
  cardProperty.totalPotential =  MetaManager.card_rare[MetaManager.card_meta[aCard.metaId].rare].addPotential * aCard.level

  return cardProperty
end


function CommonManager:getSimpleCardProperties(aCardId)
  local aCard = nil
  local cardData = DataManager.getCardsData()
  
  for _, temp in ipairs(cardData) do
    if aCardId == temp.cardId then
      aCard = temp
      break
    end
  end
  
  local result = {level=aCard.level,att = 0, def = 0, hp = 0}
  
  local aCardMetaConfig = MetaManager.card_meta[aCard.metaId]
  local aCardLevelConfig = MetaManager.card_level[aCard.level]
  local aCardEvolveConfig = MetaManager.card_evolve[tonumber(aCardMetaConfig.evolutionLevel)]
  local aCardRareConfig = MetaManager.card_rare[tonumber(aCardMetaConfig.rare)]
  
  local aBaseAttack = tonumber(aCardMetaConfig.initAtt, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseATT, 10) * tonumber(aCardRareConfig.basicAttack, 10) * tonumber(aCardEvolveConfig.reviseAttack, 10) + aCard.attTrainValue + aCard.attEvolveValue
  local aBaseDefence = tonumber(aCardMetaConfig.initDef, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseDEF, 10) * tonumber(aCardRareConfig.basicDefence, 10) * tonumber(aCardEvolveConfig.reviseDefence, 10) + aCard.defTrainValue + aCard.defEvolveValue
  local aBaseHP = tonumber(aCardMetaConfig.initHp, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseHP, 10) * tonumber(aCardRareConfig.basicHP, 10) * tonumber(aCardEvolveConfig.reviseHp, 10) + aCard.hpTrainValue + aCard.hpEvolveValue
  
  result.att = math.floor(aBaseAttack)
  result.def = math.floor(aBaseDefence)
  result.hp = math.floor(aBaseHP)
  
  return result
end

function CommonManager:getCardPropertiesWithSharkCardCache(aCard)
  return self:getBackpackCardPropertiesWithSharkCard(aCard)
end

function CommonManager:getCardPropertiesWithSharkCard(aCard, cardEquipedList, cardGroupList, cardList, equipList, matrixList, sharkMatricesData, sharkBeasts , sharkSpirits ,sharkTreasure, extraParams)  --get card att, def and hp by sharkCard  
  local equipData = equipList or tEquipDataCache or DataManager.getEquipsData()
  local treasureData = sharkTreasure or tTreasureDataCache or DataManager.getTreasuresData()
  --math.floor()依据服务器需求使用
  local result = {level=aCard.level,att = 0, def = 0, hp = 0}
	local usePreviousData = false
  
  if not cardEquipedList then
    cardEquipedList = tQueueDataCache or CommonManager.getQueueData( )
  end
	
	if not matrixList then
		matrixList = tMatrixCardDataCache or CommonManager:getMatrixCardData()
	end
	
	if not sharkMatricesData then
		sharkMatricesData = tSharkMatrixDataCache or DataManager.getSharkMatricesData()
		usePreviousData = true
	end
	
  if not cardGroupList then
    cardGroupList = getCardGroupListWithCardEquipedList(cardEquipedList, cardList, matrixList)
  end

  local aCardAttack = 0
  local aCardDefence = 0
  local aCardHP = 0
  local aCardMetaConfig
  local aCardLevelConfig
  local aCardEvolveConfig
  local aCardRareConfig
  aCardMetaConfig = MetaManager.card_meta[aCard.metaId]
  aCardLevelConfig = MetaManager.card_level[aCard.level]
  aCardEvolveConfig = MetaManager.card_evolve[tonumber(aCardMetaConfig.evolutionLevel)]
  aCardRareConfig = MetaManager.card_rare[tonumber(aCardMetaConfig.rare)]
  
  --calculate base property of card itself
  -- print("ACardMetaConfig:",table.tostring(aCardMetaConfig))
  --print("ACardLevelConfig:",table.tostring(aCardLevelConfig))
  --print("ACardRareConfig:",table.tostring(aCardRareConfig))
  --print("ACardEvolveConfig:",table.tostring(aCardEvolveConfig))

  local aBaseAttack = tonumber(aCardMetaConfig.initAtt, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseATT, 10) * tonumber(aCardRareConfig.basicAttack, 10) * tonumber(aCardEvolveConfig.reviseAttack, 10) + aCard.attTrainValue + aCard.attEvolveValue
  local aBaseDefence = tonumber(aCardMetaConfig.initDef, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseDEF, 10) * tonumber(aCardRareConfig.basicDefence, 10) * tonumber(aCardEvolveConfig.reviseDefence, 10) + aCard.defTrainValue + aCard.defEvolveValue
  local aBaseHP = tonumber(aCardMetaConfig.initHp, 10) + tonumber(aCardLevelConfig.levelCoefficient, 10) * tonumber(aCardMetaConfig.reviseHP, 10) * tonumber(aCardRareConfig.basicHP, 10) * tonumber(aCardEvolveConfig.reviseHp, 10) + aCard.hpTrainValue + aCard.hpEvolveValue
  --print("Base Status:",aBaseAttack, aBaseDefence, aBaseHP)
  --calculate the sum of each property value of all equips equiped
  --and calculate additional value of equip suit
  local aTotalEquipAttack = 0
  local aTotalEquipDefence = 0
  local aTotalEquipHP = 0

  --宝物
  local aTreasureAttact = 0
  local aTreasureDefence = 0
  local aTreasureHP = 0

  local aTotalEquipSuitAttackPercentage = 0
  local aTotalEquipSuitAttackValue = 0
  local aTotalEquipSuitDefencePercentage = 0
  local aTotalEquipSuitDefenceValue = 0
  local aTotalEquipSuitHPPercentage = 0
  local aTotalEquipSuitHPValue = 0

  local aTotalTreasureSuitAttackPercentage = 0
  local aTotalTreasureSuitAttackValue = 0
  local aTotalTreasureSuitDefencePercentage = 0
  local aTotalTreasureSuitDefenceValue = 0
  local aTotalTreasureSuitHPPercentage = 0
  local aTotalTreasureSuitHPValue = 0

  local aTempTreasureAtk = 0
  local aTempTreasureDef = 0
  local aTempTreasureHp = 0

  if aCard.treasureId ~= 0 then
    local cardGroupId = aCardMetaConfig.cardGroupId
    local aTreasure = CommonManager.getSubTableByKey(treasureData,{name = "treasureId", value = aCard.treasureId})
    aTempTreasureHp,aTempTreasureDef,aTempTreasureAtk = TreasureSystemUtils.CountAttandDefandHp(aTreasure)
    local aTreasureMetaConfig = MetaManager.treasure_meta[aTreasure.metaId]
    for i=1,5 do
      local aTreasureGroup = string.split(aTreasureMetaConfig["group"..i] , "|")
      for k,v in pairs(aTreasureGroup) do
        if tonumber(v, 10) == tonumber(cardGroupId, 10) then
          --说明这个宝物跟这个卡有连携
          local aGroupSkillID = aTreasureMetaConfig["groupSkill"..i]

          local aSkillMetaConfig = MetaManager.skill_meta[aGroupSkillID]

          --在debug模式校验是否存在技能配置 add by zheng.che @ 2014-9-10 15:23:04
          if SystemManager.debug then
            DebugManager.assert(aSkillMetaConfig ~= nil, "无此技能编号! aGroupSkillID = " .. tostringRich(aGroupSkillID))
          end
          
          local result = {}
          local aSkillStatusList = aSkillMetaConfig.statusIdList:split("|")
          for _, temp in ipairs(aSkillStatusList) do
            local aSkillStatus = tonumber(temp, 10)
            if aSkillStatus ~= 0 then
              local aSkillStatusConfig = MetaManager.skill_status[aSkillStatus]
              if tonumber(aSkillStatusConfig.feedback, 10) == 1 then
                local aResult = {}
                aResult.impactAttr = tonumber(aSkillStatusConfig.impactAttr, 10)
                aResult.valueType = tonumber(aSkillStatusConfig.valueType, 10)
                aResult.effectValue = tonumber(aSkillStatusConfig.effectValue, 10)
                table.insert(result, aResult)
              end
            end
          end

          print(table.tostring(result))

          if result and #result > 0 then
          for _, temp in ipairs(result) do
            if temp.impactAttr == 1 then
              if temp.valueType == 1 then
                aTotalTreasureSuitAttackPercentage = aTotalTreasureSuitAttackPercentage + temp.effectValue
              elseif temp.valueType == 2 then
                aTotalTreasureSuitAttackValue = aTotalTreasureSuitAttackValue + temp.effectValue
              end
            elseif temp.impactAttr == 2 then
              if temp.valueType == 1 then
                aTotalTreasureSuitDefencePercentage = aTotalTreasureSuitDefencePercentage + temp.effectValue
              elseif temp.valueType == 2 then
                aTotalTreasureSuitDefenceValue = aTotalTreasureSuitDefenceValue + temp.effectValue
              end
            elseif temp.impactAttr == 3 then
              if temp.valueType == 1 then
                aTotalTreasureSuitHPPercentage = aTotalTreasureSuitHPPercentage + temp.effectValue
              elseif temp.valueType == 2 then
                aTotalTreasureSuitHPValue = aTotalTreasureSuitHPValue + temp.effectValue
              end
            end

            aTempTreasureAtk = aTempTreasureAtk + math.floor(aTotalTreasureSuitAttackPercentage*aTempTreasureAtk) + aTotalTreasureSuitAttackValue
            aTempTreasureDef = aTempTreasureDef + math.floor(aTotalTreasureSuitDefencePercentage*aTempTreasureDef) + aTotalTreasureSuitDefenceValue
            aTempTreasureHp = aTempTreasureHp + math.floor(aTotalTreasureSuitHPPercentage*aTempTreasureHp) + aTotalTreasureSuitHPValue
          end
        end

        end
      end
    end
  end

  if aCard.equipIds then
    for _, aEquipId in ipairs(aCard.equipIds) do
      local aEquip = CommonManager.getSubTableByKey(equipData,{name = "equipId", value = aEquipId})
      local aEquipMetaConfig
      local aEquipLevelConfig
      aEquipMetaConfig = MetaManager.equip_meta[aEquip.metaId]
      aEquipLevelConfig = MetaManager.equip_level[aEquip.level]
      local aEquipSuitConfigList = {}
      for _, aEquipSuitConfig in pairs(MetaManager.equip_suit) do
        if aEquipMetaConfig.prefixId == aEquipSuitConfig.equipId then
          table.insert(aEquipSuitConfigList, aEquipSuitConfig)
        end
      end
      for _, aEquipSuitConfig in ipairs(aEquipSuitConfigList) do
        if tonumber(aEquipSuitConfig.cardGroupId, 10) == tonumber(aCardMetaConfig.cardGroupId, 10) then
          if tonumber(aEquipSuitConfig.activeAttr, 10) == 1 then
            if tonumber(aEquipSuitConfig.valueType, 10) == 1 then
              aTotalEquipSuitAttackPercentage = aTotalEquipSuitAttackPercentage + tonumber(aEquipSuitConfig.effectValue, 10)
            elseif tonumber(aEquipSuitConfig.valueType, 10) == 2 then
              aTotalEquipSuitAttackValue = aTotalEquipSuitAttackValue + tonumber(aEquipSuitConfig.effectValue, 10)
            end
          elseif tonumber(aEquipSuitConfig.activeAttr, 10) == 2 then
            if tonumber(aEquipSuitConfig.valueType, 10) == 1 then
              aTotalEquipSuitDefencePercentage = aTotalEquipSuitDefencePercentage + tonumber(aEquipSuitConfig.effectValue, 10)
            elseif tonumber(aEquipSuitConfig.valueType, 10) == 2 then
              aTotalEquipSuitDefenceValue = aTotalEquipSuitDefenceValue + tonumber(aEquipSuitConfig.effectValue, 10)
            end
          elseif tonumber(aEquipSuitConfig.activeAttr, 10) == 3 then
            if tonumber(aEquipSuitConfig.valueType, 10) == 1 then
              aTotalEquipSuitHPPercentage = aTotalEquipSuitHPPercentage + tonumber(aEquipSuitConfig.effectValue, 10)
            elseif tonumber(aEquipSuitConfig.valueType, 10) == 2 then
              aTotalEquipSuitHPValue = aTotalEquipSuitHPValue + tonumber(aEquipSuitConfig.effectValue, 10)
            end
          end
        end
      end

      --增加装备点数 包括附灵点数 ENCHANT_MODIFY
      local attrInfos = EquipUtils.findFirstAttrs(aEquip.metaId, aEquip.level, aEquip.enchantLevel)
      --print("attrInfos = " .. tostringRich(attrInfos))
      for i, attrInfo in ipairs(attrInfos) do
        if attrInfo.id == ConstManager.ATTR_ATK then
          aTotalEquipAttack = aTotalEquipAttack + attrInfo.num
        elseif attrInfo.id == ConstManager.ATTR_DEF then
          aTotalEquipDefence = aTotalEquipDefence + attrInfo.num
        elseif attrInfo.id == ConstManager.ATTR_HP then
          aTotalEquipHP = aTotalEquipHP + attrInfo.num
        end
      end
    end
  end


  --print("Total Equip Value:", aTotalEquipSuitAttackValue, aTotalEquipSuitDefenceValue, aTotalEquipSuitHPValue)
  --calculate group skill additional value
  local totalGroupSkillAttackPercentage = 0
  local totalGroupSkillAttackValue = 0
  local totalGroupSkillDefencePercentage = 0
  local totalGroupSkillDefenceValue = 0
  local totalGroupSkillHPPercentage = 0
  local totalGroupSkillHPValue = 0
  
	local existInEffectQueue = false
	local existInQueue = false
	for k, v in pairs(cardEquipedList) do
		if v == aCard.cardId then
			existInEffectQueue = true
			existInQueue = true
			break;
		end
	end

	if not existInEffectQueue then
		for k, v in pairs(matrixList) do
			if v == aCard.cardId then
				existInEffectQueue = true
				break;
			end
		end
	end
  if existInEffectQueue then
    if extraParams == nil then
      extraParams = {}
      extraParams.cardGroupInterworking = g_previousPlayerFateStatus
    end
    for i=1,5 do
      local aGroupSkillEffectList = getGroupSkillEffect(
        cardGroupList,
        aCardMetaConfig["groupSkill"..i],
        aCardMetaConfig["group"..i],
        aCardMetaConfig,
        extraParams
      )
      if aGroupSkillEffectList and #aGroupSkillEffectList > 0 then
        for _, temp in ipairs(aGroupSkillEffectList) do
          if temp.impactAttr == 1 then
            if temp.valueType == 1 then
              totalGroupSkillAttackPercentage = totalGroupSkillAttackPercentage + temp.effectValue
            elseif temp.valueType == 2 then
              totalGroupSkillAttackValue = totalGroupSkillAttackValue + temp.effectValue
            end
          elseif temp.impactAttr == 2 then
            if temp.valueType == 1 then
              totalGroupSkillDefencePercentage = totalGroupSkillDefencePercentage + temp.effectValue
            elseif temp.valueType == 2 then
              totalGroupSkillDefenceValue = totalGroupSkillDefenceValue + temp.effectValue
            end
          elseif temp.impactAttr == 3 then
            if temp.valueType == 1 then
              totalGroupSkillHPPercentage = totalGroupSkillHPPercentage + temp.effectValue
            elseif temp.valueType == 2 then
              totalGroupSkillHPValue = totalGroupSkillHPValue + temp.effectValue
            end
          end
        end
      end
    end
    --特殊合体技
    for i=1,4 do
      if MetaManager.special_group_skill[aCardMetaConfig.cardGroupId] == nil then
        break
      end
      local cardCountryNums = extraParams.cardCountryNums or CommonManager:getCardCountryNums()
      local aGroupSkill = MetaManager.special_group_skill[aCardMetaConfig.cardGroupId]
      if aGroupSkill["groupSkill"..i] == 0 then
        break
      end
      local isActive = CommonManager:checkSpecialGroupIsActive(aCardMetaConfig["country"] , aGroupSkill , i)
      if isActive then
        local aGroupSkillEffectList = getSpecialGroupSkillEffect(aGroupSkill["groupSkill"..i])

        if aGroupSkillEffectList and #aGroupSkillEffectList > 0 then
          for _, temp in ipairs(aGroupSkillEffectList) do
            if temp.impactAttr == 1 then
              if temp.valueType == 1 then
                totalGroupSkillAttackPercentage = totalGroupSkillAttackPercentage + temp.effectValue
              elseif temp.valueType == 2 then
                totalGroupSkillAttackValue = totalGroupSkillAttackValue + temp.effectValue
              end
            elseif temp.impactAttr == 2 then
              if temp.valueType == 1 then
                totalGroupSkillDefencePercentage = totalGroupSkillDefencePercentage + temp.effectValue
              elseif temp.valueType == 2 then
                totalGroupSkillDefenceValue = totalGroupSkillDefenceValue + temp.effectValue
              end
            elseif temp.impactAttr == 3 then
              if temp.valueType == 1 then
                totalGroupSkillHPPercentage = totalGroupSkillHPPercentage + temp.effectValue
              elseif temp.valueType == 2 then
                totalGroupSkillHPValue = totalGroupSkillHPValue + temp.effectValue
              end
            end
          end
        end
      end
    end
  end


  --beast property addition
  local aBeastAttAddition = 0
  local aBeastDefAddition = 0
  local aBeastHpAddition = 0
  local aBeastAttPerAddition = 0
  local aBeastDefPerAddition = 0
  local aBeastHpPerAddition = 0
  if existInQueue then
		if not sharkBeasts then
			sharkBeasts = DataManager.getSharkBeastsData()
		end
    if sharkBeasts.currBeastIds then
      for _, aBeastId in ipairs(sharkBeasts.currBeastIds) do
        local aBeastMetaConfig = MetaManager.beast_meta[aBeastId]
        if aBeastMetaConfig.attrs.beastSkillCountry == aCardMetaConfig.country then
          local locatedSharkBeast
          for _, aSharkBeast in ipairs(sharkBeasts.sharkBeasts) do
            if (aSharkBeast.metaId > aBeastId - 0.01) and ((aSharkBeast.metaId < aBeastId + 0.01)) then
              locatedSharkBeast = aSharkBeast
              break
            end
          end
          local aSkillId
          for _, aItem in pairs(aBeastMetaConfig.items) do
            if aItem.level == locatedSharkBeast.level then
              aSkillId = aItem.beastSkillId
              break
            end
          end
          local statusIdList = MetaManager.skill_meta[aSkillId].statusIdList:split("|")
          for _, aStatusString in pairs(statusIdList) do
            local aStatusId = tonumber(aStatusString, 10)
            if aStatusId > 0 then
              local aSkillStatusConfig = MetaManager.skill_status[aStatusId]
              if aSkillStatusConfig.impactAttr == 1 then
                if aSkillStatusConfig.valueType == 1 then
                  aBeastAttPerAddition = aBeastAttPerAddition + aSkillStatusConfig.effectValue
                else
                  aBeastAttAddition = aBeastAttAddition + aSkillStatusConfig.effectValue
                end
              elseif aSkillStatusConfig.impactAttr == 2 then
                if aSkillStatusConfig.valueType == 1 then
                  aBeastDefPerAddition = aBeastDefPerAddition + aSkillStatusConfig.effectValue
                else
                  aBeastDefAddition = aBeastDefAddition + aSkillStatusConfig.effectValue
                end
              elseif aSkillStatusConfig.impactAttr == 3 then
                if aSkillStatusConfig.valueType == 1 then
                  aBeastHpPerAddition = aBeastHpPerAddition + aSkillStatusConfig.effectValue
                else
                  aBeastHpAddition = aBeastHpAddition + aSkillStatusConfig.effectValue
                end
              end
            end
          end
        end
      end
    end
  end
	
	local matrixBonusAttrs = {att = 0, def = 0, hp = 0}
	if existInQueue then
    if extraParams and extraParams.matrixBonusAttrs then
      matrixBonusAttrs = extraParams.matrixBonusAttrs 
    else
		  matrixBonusAttrs = CommonManager:getAllMatrixBonus(sharkMatricesData, cardList, usePreviousData)
    end
	end
	if existInQueue then
		--计算阵魂加成begin
		if MagicCircleManager.IsCurMagicCircleOpen() then
			local curMatrixId = MetaManager.getCurInBattleMatrixId()
			local magicCircleInfo = MagicCircleManager.GetMagicCircleInfoByMatrixId(curMatrixId)
			if magicCircleInfo ~= nil then
				for mck,mcv in pairs(magicCircleInfo.magicCircleInfo) do 
					if mcv.isOpen then
						if mcv.magicCircleType == MagicCircleType.Def then
							totalGroupSkillDefencePercentage = totalGroupSkillDefencePercentage + mcv.magicCircleNum / 100
						else
							--其他类型的加成，后续扩展
						end
					end
				end
			end
		end
	--计算阵魂加成end
	end


  local spiritOfferedAttribute = SpiritManager.getCardSpiritOfferedCardStrength( aCard  , sharkSpirits)
  -- aCardAttack = aCardAttack + spiritOfferedAttribute.atk
  -- aCardDefence = aCardDefence + spiritOfferedAttribute.def
  -- aCardHP = aCardHP + spiritOfferedAttribute.hp

  local tempAtk = math.floor(aBaseAttack) + aTotalEquipAttack + spiritOfferedAttribute.atk + aTempTreasureAtk
  local tempDef = math.floor(aBaseDefence) + aTotalEquipDefence + spiritOfferedAttribute.def + aTempTreasureDef
  local tempHp = math.floor(aBaseHP) + aTotalEquipHP + spiritOfferedAttribute.hp + aTempTreasureHp
  --print("Status with equips:", tempAtk, tempDef, tempHp)
  aCardAttack = (tempAtk + math.floor(totalGroupSkillAttackPercentage*tempAtk) + math.floor(aTotalEquipSuitAttackPercentage*tempAtk) + math.floor(aBeastAttPerAddition*tempAtk)) + totalGroupSkillAttackValue + aTotalEquipSuitAttackValue + matrixBonusAttrs.att + aBeastAttAddition
  aCardDefence = (tempDef + math.floor(tempDef*totalGroupSkillDefencePercentage) + math.floor(tempDef*aTotalEquipSuitDefencePercentage) + math.floor(aBeastDefPerAddition*tempDef)) + totalGroupSkillDefenceValue + aTotalEquipSuitDefenceValue + matrixBonusAttrs.def + aBeastDefAddition
  aCardHP = (tempHp + math.floor(tempHp*totalGroupSkillHPPercentage) + math.floor(tempHp*aTotalEquipSuitHPPercentage) + math.floor(aBeastHpPerAddition*tempHp)) + totalGroupSkillHPValue + aTotalEquipSuitHPValue + matrixBonusAttrs.hp + aBeastHpAddition

  result.att = math.floor(aCardAttack)
  result.def = math.floor(aCardDefence)
  result.hp = math.floor(aCardHP)

  --print("Result status:",table.tostring(result))
  return result
end

function CommonManager:getAttDefHp()
	 --get all ids of equip equiped
  local cardEquipedList = tQueueDataCache or CommonManager.getQueueData( )

  local cardData = DataManager.getCardsData()
  local matrixList = tMatrixCardDataCache or CommonManager:getMatrixCardData()
  --get all card groups whick each card equiped belongs to
  local cardGroupList = getCardGroupListWithCardEquipedList(cardEquipedList, cardData, matrixList)
  
  local equipList = DataManager.getEquipsData()
  local sharkMatricesData = tSharkMatrixDataCache or DataManager.getSharkMatricesData()
  local sharkBeasts = DataManager.getSharkBeastsData()

  local totalAttack = 0
  local totalDefence = 0
  local totalHP = 0
  local extraParams = {}
  extraParams.matrixBonusAttrs = CommonManager:getAllMatrixBonus(sharkMatricesData, cardData, false)
  -- local gameInitData = DataManager.getGameInitData()
  
  extraParams.cardGroupInterworking = g_previousPlayerFateStatus
  extraParams.cardCountryNums = CommonManager:getCardCountryNums()

  for _, aCardId in ipairs(cardEquipedList) do  --calculate each property of each card equiped
    local aCard
    for _,temp in ipairs(cardData) do
      if aCardId == temp.cardId then
        aCard = temp
        break
      end
    end
    g_cardInfoCache[aCard.cardId] = self:getCardPropertiesWithSharkCard(aCard, cardEquipedList, cardGroupList, cardData, equipList, matrixList, sharkMatricesData, sharkBeasts ,nil,nil, extraParams)
    totalAttack = totalAttack + g_cardInfoCache[aCard.cardId].att
    totalDefence = totalDefence + g_cardInfoCache[aCard.cardId].def
    totalHP = totalHP + g_cardInfoCache[aCard.cardId].hp

    --算完直接cache住
    g_cardInfoCache[aCard.cardId].price = MetaManager.card_meta[aCard.metaId].basicPrice * MetaManager.card_level[aCard.level].priceCoefficient
    local matterCardLevelConfig = MetaManager.card_level[aCard.level]
    local matterCardExp = matterCardLevelConfig.totalExp + aCard.exp
    g_cardInfoCache[aCard.cardId].resultExp = MetaManager.card_meta[aCard.metaId].basicExp + (matterCardExp*matterCardLevelConfig.expConvertCoefficient)
    g_cardInfoCache[aCard.cardId].totalPotential =  MetaManager.card_rare[MetaManager.card_meta[aCard.metaId].rare].addPotential * aCard.level
    g_cardInfoCache[aCard.cardId].needUpdate = false;
	--print("Total Status:", totalAttack, totalDefence, totalHP)
  end
  return totalAttack, totalDefence, totalHP
end

--这个接口已经没有实际用处 但因为使用地方太多 所以保留 modified by zheng.che @ 2014-12-21
function CommonManager:getLocalPlayerStrength( usePreviousData , totalAttack, totalDefence, totalHP)
  return DataManager.getRealFightCapacity()
  
 --  if usePreviousData and g_previousPlayerStrength then
 --    return g_previousPlayerStrength
 --  end
 --  local result = 0
 --  local totalAttack = totalAttack or 0
 --  local totalDefence = totalDefence or 0
 --  local totalHP = totalHP or 0
 --  if totalAttack == 0 then
 --    totalAttack, totalDefence, totalHP = self:getAttDefHp()
 --  end

 --  local spiritOfferedAttribute = SpiritManager.getPlayerAllSpiritOfferedAttribute()
 --  totalAttack = totalAttack + spiritOfferedAttribute.atk
 --  totalDefence = totalDefence + spiritOfferedAttribute.def
 --  totalHP = totalHP + spiritOfferedAttribute.hp
  
 --  --local GameMetaData = table.deserialize(HeMemDataHolder:getString("GameMeta"))
 --  local GameMetaData = MetaManager.game_meta
 --  local cardPowerConfig = GameMetaData.gameSettingConfig.cardPowerConfig
 --  local spiritAttributeResult = 
 --  (spiritOfferedAttribute.crt * tonumber(cardPowerConfig.cardPowerCriticalCoef, 10) + 
 --    spiritOfferedAttribute.eva * tonumber(cardPowerConfig.cardPowerEvadeCoef, 10) + 
 --    spiritOfferedAttribute.par * tonumber(cardPowerConfig.cardPowerParryCoef, 10) + 
 --    spiritOfferedAttribute.tou * tonumber(cardPowerConfig.cardPowerToughnessCoef, 10) + 
 --    spiritOfferedAttribute.hit * tonumber(cardPowerConfig.cardPowerHitCoef, 10) + 
 --    spiritOfferedAttribute.prc * tonumber(cardPowerConfig.cardPowerPierceCoef, 10)) * tonumber(cardPowerConfig.cardPowerTotalCoef, 10)
 --  result = (totalAttack * tonumber(cardPowerConfig.cardPowerAttackCoef, 10) + totalDefence * tonumber(cardPowerConfig.cardPowerDefenseCoef, 10) + totalHP * tonumber(getFloatNumber(cardPowerConfig.cardPowerHPCoef), 10)) * tonumber(cardPowerConfig.cardPowerTotalCoef, 10)
 --  result = result + spiritAttributeResult
	-- if result > tonumber(cardPowerConfig.cardPowerMax, 10) then
 --    result = tonumber(cardPowerConfig.cardPowerMax, 10)
 --  end

 --  g_previousPlayerStrength = result
  
 --  BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUIScenePlayerStrength,math.floor(result) ))
 --  return result
end

function CommonManager:getCardMetaByCardId(cardId, cardList)
	if not cardList then
		cardList = DataManager.getCardsData()
	end
	local cardMeta
	local metaId
	for key ,data in pairs(cardList) do
		if cardId == data.cardId then
			metaId = data.metaId
			break;
		end
	end
	if metaId then
		cardMeta = MetaManager.card_meta[metaId]
	end
	return cardMeta
end

function CommonManager:getMatrixCardData(sharkMatricesData)
	if not sharkMatricesData then
		sharkMatricesData = DataManager.getSharkMatricesData()
	end
	local matrixCardData = {}
	for k, data in pairs(sharkMatricesData) do
		if type(data.sharkMatrixGrids) == "table" then
			for key, value in pairs(data.sharkMatrixGrids) do 
				if value.cardId > 0 then
					table.insert(matrixCardData, value.cardId)
				end
			end
		end
	end
	return matrixCardData
end

function CommonManager:getEffectCardQueue()
	local cardQueue = CommonManager:getQueueData()
	for k, v in pairs(CommonManager:getMatrixCardData()) do 
		table.insert(cardQueue, v)
	end
	return cardQueue
end

function CommonManager:getAllMatrixBonus(sharkMatricesData, cardData, usePreviousData)
	if usePreviousData and g_previousBonusTable then
		do return g_previousBonusTable end
	end
	local bonusTable = {att = 0, def = 0, hp = 0} 
	for k, data in pairs(sharkMatricesData) do
		local result = CommonManager:getMatrixBonus(data, cardData)
		bonusTable.att = bonusTable.att + result.att
		bonusTable.def = bonusTable.def + result.def
		bonusTable.hp = bonusTable.hp + result.hp
	end
	if usePreviousData then
		g_previousBonusTable = bonusTable
	end
	return bonusTable
end

function CommonManager:getMatrixBonus(matrixInfo, cardData)
	local bonusTable = {att = 0, def = 0, hp = 0}
	if type(matrixInfo.sharkMatrixGrids) ~= "table" or table.size(matrixInfo.sharkMatrixGrids) <= 0 then
		do return bonusTable end
	end
	if not matrixInfo.matrixLevelId then
		for k, data in pairs(MetaManager.matrix_level) do
			if data.matrixObtain == matrixInfo.matrixId and data.matrixLevel == matrixInfo.matrixLevel then
				matrixInfo.matrixLevelId = k
				break;
			end
		end
	end
	
	local matrixLevelMeta = MetaManager.matrix_level[matrixInfo.matrixLevelId]
	for k, data in pairs(matrixInfo.sharkMatrixGrids) do
		if data.cardId > 0 then
			if not data.matrixGridId then
				local gridIds = string.split(matrixLevelMeta.gridUnlock, '|')
				data.matrixGridId = tonumber(gridIds[data.posId + 1])
			end
			if MetaManager.matrix_grid[data.matrixGridId] then
				local result = CommonManager:getMatrixGridBonus(data.matrixGridId, data.cardId, matrixLevelMeta.attrAddCoef, cardData)
				bonusTable.att = bonusTable.att + result.att
				bonusTable.def = bonusTable.def + result.def
				bonusTable.hp = bonusTable.hp + result.hp
			end
		end
	end
	
	return bonusTable
end

function CommonManager:getMatrixGridBonus(matrixGridId, cardId, attrAddCoef, cardData)
	local bonusTable = {att = 0, def = 0, hp = 0}
	if cardId <= 0 then
		do return bonusTable end
	end
	local result = CommonManager:getCardPropertiesWithCardId(cardId, {}, nil, cardData)
	local gridMeta = MetaManager.matrix_grid[matrixGridId]
	if gridMeta.type == 1 then--atk
		bonusTable.att = math.floor(result.att * attrAddCoef)
	elseif gridMeta.type == 2 then--def
		bonusTable.def = math.floor(result.def * attrAddCoef)
	else--hp
		bonusTable.hp = math.floor(result.hp * attrAddCoef)
	end
	return bonusTable
end

local skillAttrTexts = {
	getTextByKey("attr_Attack"),
	getTextByKey("attr_Defense"),
	getTextByKey("attr_HP")
}

g_previousSkillTable = nil
g_shouldCalc = true

function CommonManager:checkEnableSkill(container)
	if not g_shouldCalc then
		do return end
	end
	g_shouldCalc = false
	local newSkillEffectList = {}

	local curSkillTable = {}
	local groupList = {}
  local gameInitData = DataManager.getGameInitData()
	for k, aCardId in pairs(CommonManager:getEffectCardQueue()) do
		local cardMeta = CommonManager:getCardMetaByCardId(aCardId)
		curSkillTable[aCardId] = {combineSkills = {}, equipSkills = {},treasureSkills = {} ,cardGroupId = cardMeta.cardGroupId,cardName = getTextByKey(cardMeta.name), cardMeta = cardMeta}
    if gameInitData.sharkUserExtend.cardGroupInterworking then
      -- for _, temp in ipairs(aCardGroupList) do
        local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
        if specialGroupMeta[cardMeta.cardGroupId] == nil then
          groupList[cardMeta.cardGroupId] = (groupList[cardMeta.cardGroupId] or 0) + 1
        else
          local aGroupList = specialGroupMeta[cardMeta.cardGroupId]
          -- local aGroupList = group:split("|")
          for k,v in pairs(aGroupList) do
            groupList[tonumber(v)] = (groupList[cardMeta.cardGroupId] or 0) + 1
          end
        end
      -- end
    else
      groupList[cardMeta.cardGroupId] = (groupList[cardMeta.cardGroupId] or 0) + 1
    end
		-- groupList[cardMeta.cardGroupId] = true
	end
	
	--补全 combineSkills
	for k , data in pairs(curSkillTable) do
		for i = 1, 5 do
			local groupSkill = data.cardMeta["groupSkill" .. i]
			if MetaManager.skill_meta[groupSkill] then
				local ids = string.split(data.cardMeta["group" .. i], '|')
				local effect = true
				for kk, vv in ipairs(ids) do
					if groupList[tonumber(vv)] == nil then
						effect = false
						break;
					end
				end
        if gameInitData.sharkUserExtend.cardGroupInterworking and CommonManager:checkSpecialGroupCombineSelf( data.cardGroupId , ids) then
          if groupList[data.cardGroupId] < 2 then
            effect = false
          end
        end
				if effect then
					data.combineSkills[groupSkill] = MetaManager.skill_meta[groupSkill]
				end
			end
		end
    --补全 specialCombineSkills
    -- local cardCountryNums = CommonManager:getCardCountryNums()
    if MetaManager.special_group_skill[data.cardGroupId] ~= nil then
      local groupSkill = MetaManager.special_group_skill[data.cardGroupId]
      for i = 1, 4 do
        if groupSkill["groupSkill"..i] == 0 then
          break
        end
        local isActive = CommonManager:checkSpecialGroupIsActive(data.cardMeta["country"] , groupSkill , i)
        -- if MetaManager.skill_meta[groupSkill] then
          if isActive then
            data.combineSkills[groupSkill["groupSkill"..i]] = MetaManager.skill_meta[groupSkill["groupSkill"..i]]
          end
        -- end
      end
    end
	end

	--补全equipSkills
	local equipList = DataManager.getEquipsData()
	for k, equipData in pairs(DataManager.getEquipsData()) do
		local cardId = equipData.cardId
		if cardId > 0 and curSkillTable[cardId] then
			local equipPrefixId = MetaManager.equip_meta[equipData.metaId].prefixId
			for kk, vv in pairs(MetaManager.equip_suit) do
				if equipPrefixId == vv.equipId and curSkillTable[cardId].cardGroupId == vv.cardGroupId then 
					curSkillTable[cardId].equipSkills[equipPrefixId] = vv
					break;
				end
			end
		end
	end

    --treasureSkills
  local treasureList = DataManager.getTreasuresData()
  for k, treasureData in pairs(DataManager.getTreasuresData()) do
    local cardId = treasureData.cardId
    if cardId > 0 and curSkillTable[cardId] then
      local treasurePrefixId = MetaManager.treasure_meta[treasureData.metaId].prefixID
      local tempSuit = MetaManager.treasure_suit[curSkillTable[cardId].cardGroupId]
      if tempSuit ~= nil then
        for i=1,5 do
          if tempSuit["prefixID"..i] == treasurePrefixId then
            curSkillTable[cardId].treasureSkills[treasurePrefixId] = tempSuit["SkillId"..i]
          end
        end
      end
    end
  end
	
	--对比PREIVIOUS显示增加的
	if g_previousSkillTable then
		for k, v in pairs(curSkillTable) do
			for kk , vv in pairs(v.combineSkills) do
				if g_previousSkillTable[k] and g_previousSkillTable[k].combineSkills[kk] then
				else
					local skillStatus = MetaManager.skill_status[tonumber(vv.statusIdList:split("|")[1])]
					local aDesc = Localization:getInstance():getText(
						"formation_groupSkillInfo",
						{
							cardname = v.cardName,
							skillname = getTextByKey(vv.name),
							value = tostring(skillStatus.effectValue * 100) .. "%",
							valueType = skillAttrTexts[skillStatus.impactAttr],
						}
					)
					table.insert(newSkillEffectList,aDesc)
				end
			end
			
			for kk, vv in pairs(v.treasureSkills) do
				if g_previousSkillTable[k] and g_previousSkillTable[k].treasureSkills[kk] then
				else
          local aSkill = MetaManager.skill_meta[vv]
          local skillStatus = aSkill.statusIdList:split("|")
          local aValue = 0
          local aType = 1
          for i=1,#skillStatus do
            if (skillStatus[i]~="0") then
              local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
              aValue = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
              aType = aSkillStatus.impactAttr
              break
            end
          end
					local aDesc = Localization:getInstance():getText(
						"Treasure_text_44",
						{
							cardname = v.cardName,
							skillname = getTextByKey(aSkill.name),
							value = aValue,
							valueType = skillAttrTexts[aType],
						}
					)
					table.insert(newSkillEffectList,aDesc)
				end
			end

      for kk, vv in pairs(v.equipSkills) do
        if g_previousSkillTable[k] and g_previousSkillTable[k].equipSkills[kk] then
        else
          local aDesc = Localization:getInstance():getText(
            "formation_groupSkillInfo",
            {
              cardname = v.cardName,
              skillname = getTextByKey(getTextByKey(MetaManager.equip_meta[kk*10+1].name)),
              value = tostring(vv.effectValue * 100) .. "%",
              valueType = skillAttrTexts[vv.activeAttr],
            }
          )
          table.insert(newSkillEffectList,aDesc)
        end
      end
		end
	end
	
	g_previousSkillTable = curSkillTable
	
	if (#newSkillEffectList>0) then
		SuspensionLabel:showContent(container, newSkillEffectList)
	end
end

function CommonManager:changeAvatarByCardInfo( cardInfo )
    local metaId 
    if cardInfo.avatarMetaId ~= 0 then
        metaId = cardInfo.avatarMetaId
    else
        metaId = cardInfo.metaId
    end
    return metaId
end

function CommonManager:getSelfAvatarMetaByUid( uid )
    local selfUid = DataManager.getCurrUser().uid
    if tonumber(selfUid) == tonumber(uid) then
      local queue = CommonManager.getQueueData()
      for k,v in pairs(DataManager.getCardsData())
      do
        if queue[1] == v.cardId then
          if v.avatarMetaId == 0 then
            return nil
          end
          return v.avatarMetaId
        end
      end
    end
    return nil
end

function CommonManager.getSelfAvatarMeta()
  local queue = CommonManager.getQueueData()
  for k,v in pairs(DataManager.getCardsData())
  do
    if queue[1] == v.cardId then
      if v.avatarMetaId == 0 then
        return v.metaId
      end
      return v.avatarMetaId
    end
  end
end

function CommonManager:getSelfAvatarMetaByCardId( cardId )
    for k,v in pairs(DataManager.getCardsData())
    do
      if cardId == v.cardId then
        return v.avatarMetaId
      end
    end
    return 0
end

function CommonManager:getCardCountryNums()
  if not g_cardCountryNumCache["cardCountryNums"] or g_cardCountryNumCache.needUpdate then
    local cardQueue = CommonManager:getEffectCardQueue()
    local cardCountryNums = {}
    for i=1,4 do
      cardCountryNums[i] = 0
    end
    for _, aCardId in pairs(cardQueue) do
      local aMetaId = CommonManager.getSubTableByKey(
        DataManager.getCardsData(),
        {name = "cardId", value = aCardId}
      ).metaId
      local country = MetaManager.card_meta[aMetaId].country
      cardCountryNums[country] = cardCountryNums[country] + 1
    end
    g_cardCountryNumCache["cardCountryNums"] = cardCountryNums
  end
  g_cardCountryNumCache.needUpdate = false
  -- local a = os.clock()
  -- local cardQueue = CommonManager:getEffectCardQueue()
  -- local cardCountryNums = {}
  -- for i=1,4 do
  --   cardCountryNums[i] = 0
  -- end
  -- for _, aCardId in pairs(cardQueue) do
  --   local aMetaId = CommonManager.getSubTableByKey(
  --     DataManager.getCardsData(),
  --     {name = "cardId", value = aCardId}
  --   ).metaId
  --   local country = MetaManager.card_meta[aMetaId].country
  --   cardCountryNums[country] = cardCountryNums[country] + 1
  -- end
  -- print(")()()())()()()())()()()()(()("..os.clock() - a)
  return g_cardCountryNumCache["cardCountryNums"]
end

function CommonManager:checkIsCardPerfect(card)
  local perfectCardFactor = {
  [3] = 7,
  [4] = 17,
  [5] = 32,
  [6] = 52,
  [7] = 77,
}

  local cardMeta = MetaManager.card_meta
  local evolutionLevel = cardMeta[card.metaId].evolutionLevel
  if evolutionLevel <= 2 then
    return false
  end

  --保证两个有一个就显示完美
  local cardFactor = card.attEvolveValue / cardMeta[card.metaId].reviseATT
  local cardFactor2 = (card.attEvolveValue + 1) / cardMeta[card.metaId].reviseATT

  local cardFactorAfterRoundOff = roundOff(cardFactor , 1)
  local cardFactorAfterRoundOff2 = roundOff(cardFactor2 , 1)
  if cardFactorAfterRoundOff == perfectCardFactor[evolutionLevel] or cardFactorAfterRoundOff2 == perfectCardFactor[evolutionLevel] then
    return true
  end

  return false
end

function CommonManager:checkTwoCardsInOneGroup( cardMeta1 , cardMeta2 )
  local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
  local cardGroupId1 = MetaManager.card_meta[cardMeta1].cardGroupId
  local cardGroupId2 = MetaManager.card_meta[cardMeta2].cardGroupId
  if specialGroupMeta[cardGroupId1] then
    local aGroupList = specialGroupMeta[cardGroupId1]
    -- local aGroupList = group:split("|")
    for k,v in pairs(aGroupList) do
      if tonumber(cardGroupId2) == tonumber(v) then
        return true
      end
    end
  end
  return false
end

function CommonManager:getSpecialGroupFirstCardName( aCardMeta )
  local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
  local cardGroupId = aCardMeta.cardGroupId
  local newMeta = aCardMeta.id - aCardMeta.evolutionLevel + 1
  if specialGroupMeta[cardGroupId] then
    local aGroupList = specialGroupMeta[cardGroupId]
    -- local aGroupList = group:split("|")
    newMeta = 100001 + tonumber(aGroupList[1])*10
  end
  return MetaManager.card_meta[newMeta].name
end

function CommonManager:checkSpecialGroupCombineSelf( cardMetaGroup , ids)
  local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
  if specialGroupMeta[cardMetaGroup] == nil then
    return false
  end
  local aGroupList = specialGroupMeta[cardMetaGroup]
  -- local aGroupList = group:split("|")
  for k,v in pairs(ids) do
    for kk,vv in pairs(aGroupList) do
      if tonumber(vv) == tonumber(v) then
        return true
      end
    end
  end
  return false
end

function CommonManager:updateEffectQueueStatus()
  local effectQueue = CommonManager:getEffectCardQueue()
  for k,v in pairs(effectQueue) do
    if g_cardInfoCache[v] then
      g_cardInfoCache[v].needUpdate = true
    end
  end
end

function CommonManager:checkSpecialGroupIsActive( cardCountry , groupSkill , i)
  local cardCountryNums = CommonManager:getCardCountryNums()
  local isActive = false
  if cardCountry == groupSkill["group"..i] then
    if cardCountryNums[groupSkill["group"..i]] >= groupSkill["groupNum"..i] + 1 then
      isActive = true
    end
  else
    if cardCountryNums[groupSkill["group"..i]] >= groupSkill["groupNum"..i] then
      isActive = true
    end
  end
  return isActive
end

function CommonManager:checkIsTreasureActive( treasureMetaId , cardGroupId)
  local aTreasureMeta = MetaManager.treasure_meta[treasureMetaId]
  for i=1,5 do
    local aGroup = string.split(aTreasureMeta["group"..i] , "|")
    for k,v in pairs(aGroup) do
      if tonumber(v) == tonumber(cardGroupId) then
        return true
      end
    end
  end
  return false
end