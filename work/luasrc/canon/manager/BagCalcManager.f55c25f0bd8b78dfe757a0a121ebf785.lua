--------------------------------------------------------------------------------
-- BagCalcManager.lua -- 背包管理：背包格子计算、背包满计算
-- author: xiaojie.bai
-- date: 2013-10-29
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.data.MetaManager"

BagCalcManager = {}

--------------------
-- 检查这个道具是否需要检测背包已满
--------------------
function BagCalcManager.needToCheck(item)
  if item == ResourceEnum.CARD or item == ResourceEnum.EQUIP or item == ResourceEnum.PROP then
    return true
  else 
    return false
  end 
end

--------------------
-- 判断背包是否满
--------------------
function BagCalcManager.isFull()
  local usedGridNum = BagCalcManager.calcUsedGridNum()
  local totalGridNum = BagCalcManager.calcTotalGridNum()
  
  return usedGridNum >= totalGridNum
end

--------------------
-- 计算已使用格子详情
--------------------
function BagCalcManager.calcUsedGridNum()
  local GameMetaData = MetaManager.game_meta
  -- prop
  local propUsedGrid = 0
  
  local inventoryMaxStack = GameMetaData.gameSettingConfig.inventoryMaxStack --gamesetting中的第8项对应于inventoryMaxStack
  local propData = DataManager.getPropsData()
  if(propData) then
    for _, aConfig in ipairs( propData ) do  --显示信息
      local usedGrid = math.ceil( aConfig.amount / inventoryMaxStack )
      propUsedGrid = propUsedGrid + usedGrid
    end
  end
  
  -- unEquiped equip
  local equipUsedGrid = 0
  local equipData = DataManager.getEquipsData()
  if(equipData) then
    for _, aConfig in ipairs( equipData ) do
      if aConfig.cardId == 0 then  --没有被card穿戴
        equipUsedGrid = equipUsedGrid + 1
      end
    end
  end
  
  -- card
  local cardUsedGrid = 0
  
  local sharkUser = DataManager.getGameInitData().sharkUser
  local additionalCardIdsList = sharkUser.additionalCardIds:split(",")
  local mainCardId = sharkUser.mainCardId
  local sharkCards = DataManager.getGameInitData().sharkCards.sharkCards
  local matricesData = DataManager.getSharkMatricesData() 
  for _, aConfig in ipairs( sharkCards ) do
    if aConfig.cardId ~= mainCardId then  --判断不等于mainCardId 
      local isAddionalCard = false
      for _, aAdditionalCardId in ipairs(additionalCardIdsList) do  --判断不等于additionalCardIds
        if (aConfig.cardId == tonumber(aAdditionalCardId)) then
          isAddionalCard = true
          break
        end
      end
      for k,v in pairs(matricesData) do
        if not v.sharkMatrixGrids then v.sharkMatrixGrids = {} end
        for _, value in pairs(v.sharkMatrixGrids) do  --阵法武将也不占背包叻
          if (aConfig.cardId == value.cardId) then
            isAddionalCard = true
            break
          end
        end
      end
      if not isAddionalCard then
        cardUsedGrid = cardUsedGrid + 1
      end
    end
  end
  
  local totalUsedGridNum = propUsedGrid + equipUsedGrid + cardUsedGrid
  --print("totalUsedGridNum:", totalUsedGridNum, "propUsedGrid:", propUsedGrid, "equipUsedGrid:", equipUsedGrid, "cardUsedGrid:", cardUsedGrid)
    
  return totalUsedGridNum, propUsedGrid, equipUsedGrid, cardUsedGrid
end

--------------------
-- 计算总格子详情
--------------------
function BagCalcManager.calcTotalGridNum()
  -- bought grid
  local boughtGridNum = 0
  if DataManager.getGameInitData().sharkUserExtend ~= nil then
    boughtGridNum = DataManager.getGameInitData().sharkUserExtend.boughtGridNum
  end
  
  local sharkUser = DataManager.getGameInitData().sharkUser
  
  -- level grid
  local gridNum = 0
  local level = sharkUser.level
  local userLevelConfig = MetaManager.user_level[level]
  if(userLevelConfig) then
    gridNum = userLevelConfig.gridNum
  end
  
  -- vipLevel grid
  local vipLevel = sharkUser.vipLevel
  local extraInventorySlots = 0
  local vipSetting = MetaManager.vip_setting[vipLevel]
  if(vipSetting) then
    extraInventorySlots = vipSetting.extraInventorySlots
  end
  
  local totalGridNum = boughtGridNum + gridNum + extraInventorySlots
  --print("totalGridNum:", totalGridNum, "boughtGridNum:", boughtGridNum, "gridNum:", gridNum, "extraInventorySlots:", extraInventorySlots)
  
  return totalGridNum, boughtGridNum, gridNum, extraInventorySlots
end

--
-- 获取背包中当前适合使用的体力药的id及其个数
--
function BagCalcManager.getOneEnergyProp()
  local result_id
  local result_num
  local propDataList = DataManager.getPropsData()
  local tempValue = 0
  for _, v in pairs(propDataList) do
    if tonumber(v.amount, 10) > 0 then
      local aPropMetaConfig = MetaManager.prop_meta[tonumber(v.metaId, 10)]
      if aPropMetaConfig.effectType == 1 then
        if aPropMetaConfig.effectValue > tempValue then
          result_id = tonumber(v.metaId, 10)
          result_num = tonumber(v.amount, 10)
          tempValue = aPropMetaConfig.effectValue
        end
      end
    end
  end
  return result_id, result_num
end

--
-- 获取背包中对应某id的物品个数
--
function BagCalcManager.getNumById(id)
  local propDataList = DataManager.getPropsData()
  local tempValue = 0
  for _, v in pairs(propDataList) do
    if tonumber(v.metaId, 10) == tonumber(id, 10) then
      return v.amount
    end
  end
  return 0
end

--
-- 获取背包中体力药的id及其个数
--

function BagCalcManager.getEnergyPropList()
  local result = {}
  for _, aPropMetaConfig in pairs(MetaManager.prop_meta) do
    if aPropMetaConfig.effectType == 1 then
      local aList = {}
      aList.metaId = tonumber(aPropMetaConfig.id, 10)
      aList.amount = 0
      table.insert(result, aList)
    end
  end
  table.sort(result, function(a, b)
    local aPropMetaConfig1 = MetaManager.prop_meta[a.metaId]
    local aPropMetaConfig2 = MetaManager.prop_meta[b.metaId]
    return (aPropMetaConfig1.effectValue < aPropMetaConfig2.effectValue)
  end)
  local hasProp = false
  local propDataList = DataManager.getPropsData()
  for _, v in pairs(propDataList) do
    if tonumber(v.amount, 10) > 0 then
      local aPropMetaConfig = MetaManager.prop_meta[tonumber(v.metaId, 10)]
      if aPropMetaConfig.effectType == 1 then
        hasProp = true
        for _, aEnergyData in ipairs(result) do
          if aEnergyData.metaId == tonumber(v.metaId, 10) then
            aEnergyData.amount = tonumber(v.amount, 10)
          end
        end
      end
    end
  end
  
  return hasProp, result
end

--
-- 获取背包中当前适合使用的精力药的id及其个数
--
function BagCalcManager.getOneEventPointProp()
  local result_id
  local result_num
  local propDataList = DataManager.getPropsData()
  local tempValue = 0
  for _, v in pairs(propDataList) do
    if tonumber(v.amount, 10) > 0 then
      local aPropMetaConfig = MetaManager.prop_meta[tonumber(v.metaId, 10)]
      if aPropMetaConfig.effectType == 2 then
        if aPropMetaConfig.effectValue > tempValue then
          result_id = tonumber(v.metaId, 10)
          result_num = tonumber(v.amount, 10)
          tempValue = aPropMetaConfig.effectValue
        end
      end
    end
  end
  return result_id, result_num
end

--
-- 获取背包中精力药的id及其个数
--

function BagCalcManager.getEventPointPropList()
  local result = {}
  for _, aPropMetaConfig in pairs(MetaManager.prop_meta) do
    if aPropMetaConfig.effectType == 2 then
      local aList = {}
      aList.metaId = tonumber(aPropMetaConfig.id, 10)
      aList.amount = 0
      table.insert(result, aList)
    end
  end
  table.sort(result, function(a, b)
    local aPropMetaConfig1 = MetaManager.prop_meta[a.metaId]
    local aPropMetaConfig2 = MetaManager.prop_meta[b.metaId]
    return (aPropMetaConfig1.effectValue < aPropMetaConfig2.effectValue)
  end)
  local hasProp = false
  local propDataList = DataManager.getPropsData()
  for _, v in pairs(propDataList) do
    if tonumber(v.amount, 10) > 0 then
      local aPropMetaConfig = MetaManager.prop_meta[tonumber(v.metaId, 10)]
      if aPropMetaConfig.effectType == 2 then
        hasProp = true
        for _, aEventPointData in ipairs(result) do
          if aEventPointData.metaId == tonumber(v.metaId, 10) then
            aEventPointData.amount = tonumber(v.amount, 10)
          end
        end
      end
    end
  end
  
  return hasProp, result
end

