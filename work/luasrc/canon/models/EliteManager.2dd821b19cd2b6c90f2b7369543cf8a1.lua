--------------------------------------------------------------------------------
-- EliteManager.lua - 精英关卡相关的常量及存储结构
-- author: xiaojie.bai
-- date: 2013-09-26 10:53
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.models.CountryManager"
require "canon.models.VipManager"
require "canon.manager.DailyDataManager"

EliteManager = {}

----
-- 常量字典
----
EliteManager.DICT = {
    RESOURCE_FILE = "scene/elite_new.json",
    
    -- 精英关卡入口图片信息
    PIC_ATTACKON = "pic/elite_attackon_bg.png",
    PIC_ATTACKON_POSX = 0,
    PIC_ATTACKON_POSY = 119,
    PIC_ATTACKON_WIDTH = 720,
    PIC_ATTACKON_HEIGHT = 750,
    
    -- 城市列表位置信息
    TB_CITY_WIDTH = 670,
    TB_CITY_HEIGHT = 60,
    TB_CITY_POSX = 25,
    TB_CITY_POSY = 954,
    ITEM_CITY_WIDTH = 160,
    ITEM_CITY_REAL_WIDTH = 146,
    ITEM_CITY_HEIGHT = 59,
    
    -- 关卡列表位置信息
    TB_MISSION_WIDTH = 695,
    TB_MISSION_HEIGHT = 800,
    TB_MISSION_POSX = 25,
    TB_MISSION_POSY = 120,
    ITEM_MISSION_WIDTH = 670,
    ITEM_MISSION_HEIGHT = 178,
    FIRST_ELITE_MISSIONID = 109101, --精英关卡第一章
    FIRST_ELITE_CITYID = 10
  }

local sortedEliteSettingList = nil --存储按id排序后的精英关卡信息
local itemId2EliteIdsDict = nil --道具/卡牌对应的精英关卡id字典
local eliteCityDict = nil -- 存储精英关卡城市id和名称的字典

------
-- 生成按精英关卡id排序的关卡信息列表
------
function EliteManager.getSortedEliteSettingList()
  if(not sortedEliteSettingList) then
    local eliteSettings = {}
    for key, value in pairs(MetaManager.elite_setting) do
      table.insert(eliteSettings, value)
    end
    
    local function idSort(a, b)
      if a.id < b.id then
        return true
      else
        return false
      end
    end
    table.sort(eliteSettings, idSort)
    
    sortedEliteSettingList = eliteSettings
  end
  
  return sortedEliteSettingList
end

------
-- 生成道具的精英关卡来源字典
------
function EliteManager.getItemSrcDict()
  if(not itemId2EliteIdsDict) then
    local itemSrcDict = {}
    local eliteSettings = EliteManager.getSortedEliteSettingList()
    for _, value in ipairs(eliteSettings) do
      local eliteId = value.id
      local propId = value.propId
      if(propId > 0) then
        local eliteIds = itemSrcDict[propId] or {}
        table.insert(eliteIds, eliteId)
        
        itemSrcDict[propId] = eliteIds
      end
    end
    itemId2EliteIdsDict = itemSrcDict
  end
  
  return itemId2EliteIdsDict
end

--------------------
-- 获取所有精英关卡城池id和name
--------------------
function EliteManager.getEliteCityDict()
  if(not eliteCityDict) then
    eliteCityDict = {}
    for key, value in pairs(MetaManager.elite_setting) do
      local cityId = value.cityId
      if(not eliteCityDict[cityId]) then
        local cityNameKey = MetaManager.battle_country[cityId].cityNameKey
        eliteCityDict[cityId] = cityNameKey
      end
    end
  end
  
  return eliteCityDict
end

--------------------
-- 据已开启城池id获取所有精英关卡城池信息(名称，是否开启)
----
-- eliteCityIds 已开启的精英关卡城池id
--------------------
function EliteManager.getCityInfosByCityIds(eliteCityIds)
  local eliteCityInfos = {}
  
  local eliteCityDict = EliteManager.getEliteCityDict()
  for cityId, cityNameKey in pairs(eliteCityDict) do
    if(eliteCityIds[cityId]) then
      table.insert(eliteCityInfos, {cityId = cityId, cityNameKey = cityNameKey, open = true})
    else
      table.insert(eliteCityInfos, {cityId = cityId, cityNameKey = cityNameKey, open = false})
    end
  end
  
  local function cityIdSort(a, b)
    if a.cityId < b.cityId then
      return true
    else
      return false
    end
  end
  table.sort(eliteCityInfos, cityIdSort)
  
  return eliteCityInfos
end

--------------------
-- 获取带有解锁信息的所有精英关卡城池信息
--------------------
function EliteManager.getCityInfos(maxFinishedEliteMissionId)
  local maxMissionId = EliteManager.getMaxMissionId();
  
  if(not maxFinishedEliteMissionId) then
    maxFinishedEliteMissionId = 0
  end
  
  local eliteCityIds = {}
  local sortedEliteSettings = EliteManager.getSortedEliteSettingList()
  for _, value in ipairs(sortedEliteSettings) do
    if(value.unlockRequireMissionId <= maxMissionId and value.id <= maxFinishedEliteMissionId) then
      eliteCityIds[value.cityId] = value.cityId
    elseif(value.id > maxFinishedEliteMissionId) then
      break
    end
  end
  
  local finishNewCityInfo = EliteManager.isFinishEliteCity(maxFinishedEliteMissionId, maxMissionId)
  if(#eliteCityIds == 0) then
    eliteCityIds[EliteManager.DICT.FIRST_ELITE_CITYID] = EliteManager.DICT.FIRST_ELITE_CITYID
  end
  if(finishNewCityInfo.finish) then
    eliteCityIds[finishNewCityInfo.nextCityId] = finishNewCityInfo.nextCityId
  end
  
  return EliteManager.getCityInfosByCityIds(eliteCityIds)
end

------
-- 判断精英关卡对应的当前城市是否完成，同时返回下一城市(当前城市)id
------
function EliteManager.isFinishEliteCity(eliteMissionId, maxMissionId)
  local finish = false
  
  local missionInfo = EliteManager.getEliteMissionByMissionId(eliteMissionId)
  local nextCityId = EliteManager.DICT.FIRST_ELITE_CITYID
  if(missionInfo) then
    nextCityId = missionInfo.cityId
    local nextMissionInfo = EliteManager.getEliteMissionByMissionId(missionInfo.nextEliteId)
    if(nextMissionInfo and nextMissionInfo.unlockRequireMissionId <= maxMissionId 
        and missionInfo.cityId ~= nextMissionInfo.cityId) then
      finish = true
      nextCityId = nextMissionInfo.cityId
    end
  end
  return {finish = finish, nextCityId = nextCityId}
end

--------------------
-- 获取指定城池的普通关卡解锁的关卡信息列表
--------------------
function EliteManager.getEliteMissionsByCityId(cityId)
  local maxMissionId = EliteManager.getMaxMissionId();
  
  local eliteMissions = {}
  local sortedEliteSettings = EliteManager.getSortedEliteSettingList()
  for _, value in ipairs(sortedEliteSettings) do
    if(value.cityId == cityId and value.unlockRequireMissionId <= maxMissionId) then
      table.insert(eliteMissions, value)
    elseif(value.cityId > cityId ) then
      break;
    end
  end
  
  return eliteMissions
end

--------------------
-- 据获取精英关卡信息
--------------------
function EliteManager.getEliteMissionByMissionId(missionId)
  return MetaManager.elite_setting[missionId]
end

--------------------
-- 获取精英关卡第一关信息
--------------------
function EliteManager.getFirstEliteMission()
  return MetaManager.elite_setting[EliteManager.DICT.FIRST_ELITE_MISSIONID]
end

--------------------
-- 获取玩家普通关卡最大通关数
--------------------
function EliteManager.getMaxMissionId()
  return CountryManager:sharedManager():getMaxFinishedMissionID() or 0
end

--------------------
-- 精英关卡功能是否解锁
--------------------
function EliteManager.isUnlockElite()
  local eliteMission = EliteManager.getFirstEliteMission()
  if(not eliteMission) then --配置有误
    return false
  end
  
  local maxMissionId = EliteManager.getMaxMissionId()
  if(maxMissionId >= eliteMission.unlockRequireMissionId) then
    return true
  else
    return false
  end
end

--------------------
-- 精英关卡系统配置{eliteConsumeEnergy=5, eliteRefreshGoldCost=10}
--------------------
function EliteManager.getEliteSetting()
  return MetaManager.getGameSettingConfig().eliteConfig
end

--------------------
-- 可否购买精英关卡挑战次数
--------------------
function EliteManager.canRefreshChallengeTimes(vipLevel)
  local vipInfo = VipManager.getVipInfo(vipLevel)
  
  if(not vipInfo or vipInfo.extraEliteStagePerDay <= 0) then
    return false
  end
  
  local extraEliteStagePerDay = vipInfo.extraEliteStagePerDay
  local resetEliteNum = DailyDataManager.getResetEliteNum()
  
  return extraEliteStagePerDay > resetEliteNum
end

--------------------
-- 获取精英关卡功能解锁普通关卡名称
--------------------
function EliteManager.getFuncUnlockStageName()
  local eliteMission = EliteManager.getFirstEliteMission()
  if(not eliteMission) then --配置有误
    return nil
  end
  
  local missionMeta = MetaManager.battle_mission[eliteMission.unlockRequireMissionId]
  if(not missionMeta) then
    return nil
  else
    return getTextByKey(missionMeta.missionNameKey)
  end
end

function EliteManager.isEliteMissionUnlock(eliteMissionInfo, maxFinishedEliteId, maxMissionId)
  local isUnlock = false
  
  isUnlock = (eliteMissionInfo.id <= maxFinishedEliteId or eliteMissionInfo.previousEliteId == maxFinishedEliteId)
  isUnlock = isUnlock and (maxMissionId >= eliteMissionInfo.unlockRequireMissionId)
  
  return isUnlock
end

-- 能否扫荡
function EliteManager.canEliteMissionSweep(eliteMissionInfo, maxFinishedEliteId, maxMissionId)
  --能打 并且当前编号不超过最大过关编号
  return EliteManager.isEliteMissionUnlock(eliteMissionInfo, maxFinishedEliteId, maxMissionId) and (eliteMissionInfo.id <= maxFinishedEliteId)
end

------
-- 设置玩家已完成的最大精英关卡id
------
function EliteManager.setMaxFinishedEliteId(eliteId)
  local gameInitData = DataManager.getGameInitData()
  if(not gameInitData.sharkElite) then
    gameInitData.sharkElite = {}
  end
  
  gameInitData.sharkElite.maxFinishedEliteId = eliteId
  
	DataManager.setGameInitData(gameInitData)
end

------
-- 获取玩家已完成的最大精英关卡id
------
function EliteManager.getMaxFinishedEliteId()
  local sharkElite = DataManager.getGameInitData().sharkElite
  
  return sharkElite and sharkElite.maxFinishedEliteId or 0
end

------
-- 据道具获取精英关卡信息{eliteMissionId:0, unlock=true}
------
function EliteManager.getMaterialSrc(itemId)
  local maxFinishedEliteId = EliteManager.getMaxFinishedEliteId()
  local maxMissionId = EliteManager.getMaxMissionId()
  
  local itemSrcDict = EliteManager.getItemSrcDict()
  local eliteId = itemSrcDict[itemId] and itemSrcDict[itemId][1] or 0
  
  local unlock = false
  if(eliteId and eliteId > 0) then
    if(maxFinishedEliteId >= eliteId) then
      unlock = true
    else
      local nextMissionInfo = nil
      if(maxFinishedEliteId > 0) then
        local missionInfo = EliteManager.getEliteMissionByMissionId(maxFinishedEliteId)
        nextMissionInfo = EliteManager.getEliteMissionByMissionId(missionInfo.nextEliteId)
      else
        nextMissionInfo = EliteManager.getFirstEliteMission()
      end
      
      if(nextMissionInfo and maxMissionId >= nextMissionInfo.unlockRequireMissionId and nextMissionInfo.id >= eliteId) then
        unlock = true
      end
    end
  end
  
  return {eliteMissionId = eliteId, unlock = unlock}
end

function EliteManager.getNextEliteInfo(eliteId)
  if(not eliteId or eliteId <= 0) then
    return EliteManager.DICT.FIRST_ELITE_MISSIONID
  end
  
  local eliteSetting = EliteManager.getEliteMissionByMissionId(eliteId)
  if(eliteSetting) then
    return eliteSetting.nextEliteId
  else
    return EliteManager.DICT.FIRST_ELITE_MISSIONID
  end
end
