require "canon.data.MetaManager"
require "hecore.utils"
require "canon.utils.TimeUtil"

ChapterEventIDs = {
  "event_battle",
  "event_boss",
  "event_money",
  "event_exp",
  "event_card",
  "event_normal",
  "event_random"
}

ChapterEventGIDOffsize = {
  5,
  8,
  0,
  1,
  2,
  -1,
  7
}

chapter_empty_event_gid_offsize = 17
chapter_not_event_gid_offsize = 18

RewardTypeEnum = {
  kCoin = 1,  --银币
  kGem = 2,    --金币
  kEnergy = 3,
  kExp = 4,           --主角经验
  kCard = 5,
  kEquip = 6,
  kProp = 7,
  kFriendPoint = 8,   --邀请点数
  kGrid = 9,          --格子
  kSkillPoints = 10,  --技能点数
  kEventPoint = 11    --精力
}

ChapterEventFinishedType = {
  kChapterFinished = 1,   --chapter完成
  kMissionFinished = 2,   --chapter未完成，mission完成
  kEventFinished = 3      --chapter未完成，mission未完成
}

max_unlock_city_id = 39

step_num_per_mission = 5

--
-- CountryManager
--

CountryManager = class()
local countryManagerInstance = nil
function CountryManager:sharedManager()
	if not countryManagerInstance then
		countryManagerInstance = CountryManager.new()
	end
	return countryManagerInstance
end

function CountryManager:ctor(  )
  self.tmxSourceCache = {}
  
  self:initializeData()
end

function CountryManager:initializeData()
  local GameInitData = DataManager.getGameInitData()
	self.countryData = GameInitData.sharkSceneProcess
  self.missionContext = GameInitData.sharkMissionContext
  self.selectedCountryID = 0
  self.selectedChapterID = 0
  self.selectedMissionID = 0
  self.missionIDInChallenge = nil
  self.missionCompleteInfo = GameInitData.missionCompletes
  if not self.missionCompleteInfo then
    self.missionCompleteInfo = {}
  end
  
  if not self.countryData then
    self.countryData = {}
    self.countryData.uid = GameInitData.sharkUser.uid
    self.countryData.finishedCountryIds = {}
    self.countryData.sceneCountries = {}
    self.countryData.maxFinishedMissionId = 0
    self.countryData.lastClearTime = 0
  end
  --print(table.tostring(self.missionContext))
  if not self.missionContext then
    local aFirstCountryID = self:getFirstCountryIDInConfig()
    local aFirstChapterID = self:getFirstChapterIDWithCountryIDInConfig(aFirstCountryID)
    local aFirstMissionID = self:getFirstMissionIDWithChapterIDInConfig(aFirstChapterID)
    self.missionContext = {
      missionId = aFirstMissionID,
      finishedStep = 0,
      fightLose = false, 
      routeId = 1
    }
  end
  --print(table.tostring(self.missionContext))
  self:reconstructMissionContext()
  --print(table.tostring(self.missionContext))
  --print(self.missionIDInChallenge)
  
  self:resetCurrentSelectedItem()
end

function CountryManager:reconstructMissionContext()
  local aChapterID = math.modf(self.missionContext.missionId / 100)
  local aStepNum = self:getTotalStepsWithChapterID(aChapterID)
  if aStepNum == self.missionContext.finishedStep then
    --new chapter
    if MetaManager.battle_chapter[aChapterID + 1] then
      --new chapter in the same country
      self.missionContext.missionId = self:getFirstMissionIDWithChapterIDInConfig(aChapterID + 1)
      self.missionContext.finishedStep = 0
      self.missionContext.routeId = 1
    else
      --new chapter in next country
      local aCountryID = math.modf(aChapterID / 100)
      if aCountryID < max_unlock_city_id then
        if MetaManager.battle_country[aCountryID + 1] then
          local aNewChapterID = self:getFirstChapterIDWithCountryIDInConfig(aCountryID + 1)
          self.missionContext.missionId = self:getFirstMissionIDWithChapterIDInConfig(aNewChapterID)
          self.missionContext.finishedStep = 0
          self.missionContext.routeId = 1
        else
          self.missionContext.missionId = self:getFirstMissionIDWithChapterIDInConfig(aChapterID)
          self.missionContext.finishedStep = 0
          self.missionContext.routeId = 1
        end
      else
        self.missionContext.missionId = self:getFirstMissionIDWithChapterIDInConfig(aChapterID)
        self.missionContext.finishedStep = 0
        self.missionContext.routeId = 1
      end
    end
    self.selectedMissionID = self.missionContext.missionId
    self.missionIDInChallenge = nil
    return ChapterEventFinishedType.kChapterFinished
  end
  
  for aIndex, aStepConfig in ipairs(MetaManager.battle_chapter_event) do
    if (aStepConfig.missionId == self.missionContext.missionId) and (aStepConfig.step == self.missionContext.finishedStep) then
      local aNextStepConfig = MetaManager.battle_chapter_event[aIndex + 1]
      if aNextStepConfig.missionId ~= self.missionContext.missionId then
        --new mission in the same chapter
        self.missionContext.missionId = aNextStepConfig.missionId
        self.selectedMissionID = self.missionContext.missionId
        self.missionIDInChallenge = nil
        return ChapterEventFinishedType.kMissionFinished
      else
        self.selectedMissionID = self.missionContext.missionId
        self.missionIDInChallenge = self.missionContext.missionId
        return ChapterEventFinishedType.kEventFinished
      end
      break
    end
  end
end

function CountryManager:resetCurrentSelectedItem()
  self.selectedCountryID = self:getCountryIDOfLastBattle()
  self.selectedChapterID = self:getChapterIDOfLastBattle()
  self.selectedMissionID = self:getMissionIDOfLastBattle()
end

function CountryManager:getFirstCountryIDInConfig()
  local result = 10000
  for _, aCountry in pairs(MetaManager.battle_country) do
    local aCountryID = tonumber(aCountry.id, 10)
    if result > aCountryID then
      result = aCountryID
    end
  end
  return result
end

function CountryManager:getFirstChapterIDWithCountryIDInConfig(aCountryID)
  return tonumber(MetaManager.battle_country[aCountryID].chapterIdList:split("|")[1], 10)
end

function CountryManager:getLastChapterIDWithCountryIDInConfig(aCountryID)
  if not MetaManager.battle_country[aCountryID] then
    return nil
  end
  local chapter_id_list = MetaManager.battle_country[aCountryID].chapterIdList:split("|")
  local result
  for _, chapter_id in ipairs(chapter_id_list) do
    if tonumber(chapter_id, 10) == 0 then
      break
    end
    result = tonumber(chapter_id, 10)
  end
  return result
end

function CountryManager:getFirstMissionIDWithChapterIDInConfig(aChapterID)
  --print(aChapterID)
  --print(MetaManager.battle_chapter[aChapterID].missionIdList)
  return tonumber(MetaManager.battle_chapter[aChapterID].missionIdList:split("|")[1], 10)
end

function CountryManager:getCountryIDOfLastBattle()
  if self.missionContext then
    return math.modf(math.modf(self.missionContext.missionId / 100) / 100)
  end
end

function CountryManager:getChapterIDOfLastBattle()
  if self.missionContext then
    return math.modf(self.missionContext.missionId / 100)
  end
end

function CountryManager:getMissionIDOfLastBattle()
  if self.missionContext then
    return self.missionContext.missionId
  end
end

function CountryManager:getAllChapterIDsWithCountryID(aCountryID)
  local result = {}
  local idList = MetaManager.battle_country[aCountryID].chapterIdList:split("|")
  for i = 1, #idList do
    if idList[i] == "0" then
      break
    else
      result[i] = tonumber(idList[i], 10)
    end
  end
  return result
end

function CountryManager:getAllMissionIDsWithChapterID(aChapterID)
  local result = {}
  local idList = MetaManager.battle_chapter[aChapterID].missionIdList:split("|")
  for i = 1, #idList do
    result[i] = tonumber(idList[i], 10)
  end
  return result
end

function CountryManager:getTotalStepsWithChapterID(aChapterID, aMissionID)
  local result = 0
  local result2 = 0
  local mission_start_step
  local haveFound = false
  for _, aStepConfig in ipairs(MetaManager.battle_chapter_event) do
    if math.modf(aStepConfig.missionId / 100) == aChapterID then
      result = result + 1
      if aStepConfig.missionId == aMissionID then
        if not mission_start_step then
          mission_start_step = aStepConfig.step
        end
        result2 = result2 + 1
      end
      haveFound = true
    else
      if haveFound then
        break
      end
    end
  end
  return result, result2, mission_start_step
end

function CountryManager:getBattleChapterEventConfigs(aChapterId)
  local result = {}
  local haveFound = false
  for _, aStepConfig in ipairs(MetaManager.battle_chapter_event) do
    if math.modf(aStepConfig.missionId / 100) == aChapterId then
      haveFound = true
      table.insert(result, aStepConfig)
    else
      if haveFound then
        break
      end
    end
  end
  return result
end

function CountryManager:tileGIDOffsizeWithStep(aStepDir, aStepConfig)
  local aEvents = {aStepConfig.eventType1, aStepConfig.eventType2, aStepConfig.eventType3}
  local aEventType = tonumber(aEvents[aStepDir], 10)
  if aEventType ~= 0 then
    return ChapterEventGIDOffsize[aEventType], ChapterEventIDs[aEventType]
  else
    return nil
  end
  --[[
  local aCurrentChapterID = math.modf(self.selectedMissionID / 100)
  
  for _, aEventStep in ipairs(MetaManager.battle_chapter_event[aCurrentChapterID]) do
    local aStepIndex = tonumber(aEventStep.step, 10)
    if aStepIndex == aStep then
      local aEvents = {aEventStep.eventType1, aEventStep.eventType2, aEventStep.eventType3}
      local aEventType = tonumber(aEvents[aStepDir], 10)
      if aEventType ~= 0 then
        return ChapterEventGIDOffsize[aEventType], ChapterEventIDs[aEventType]
      else
        return nil
      end
    end
  end
  ]]
end

function CountryManager:getMaxFinishedMissionID()
  return self.countryData.maxFinishedMissionId
end

function CountryManager:getNewMissionID()
  if #self.countryData.sceneCountries == 0 then
    local aFirstCountryID = self:getFirstCountryIDInConfig()
    local aFirstChapterID = self:getFirstChapterIDWithCountryIDInConfig(aFirstCountryID)
    local aFirstMissionID = self:getFirstMissionIDWithChapterIDInConfig(aFirstChapterID)
    return aFirstMissionID
  end
  --[[
  local aMaxCountryID = 0
  local aMaxCountry
  for _, aCountry in ipairs(self.countryData.sceneCountries) do
    if aCountry.countryId > aMaxCountryID then
      aMaxCountryID = aCountry.countryId
      aMaxCountry = aCountry
    end
  end
  local aMaxChapterID = 0
  local aMaxChapter
  for _, aChapter in ipairs(aMaxCountry.sceneChapters) do
    if aChapter.chapterId > aMaxChapterID then
      aMaxChapterID = aChapter.chapterId
      aMaxChapter = aChapter
    end
  end
  local aMaxMissionID = 0
  --local aMaxMission
  for _, aMission in ipairs(aMaxChapter.sceneMissions) do
    if aMission.missionId > aMaxMissionID then
      aMaxMissionID = aMission.missionId
      --aMaxMission = aMission
    end
  end
  ]]
  local aMaxMissionID = self:getMaxFinishedMissionID()
  --print(aMaxCountryID .. "__" .. aMaxChapterID .. "__" .. aMaxMissionID)
  local result = 1000000
  local noNewExisted = true
  for _, aMission in pairs(MetaManager.battle_mission) do
    local aMissionID = tonumber(aMission.id, 10)
    if aMissionID > aMaxMissionID then
      if aMissionID < result then
        result = aMissionID
        noNewExisted = false
      end
    end
  end
  
  return result, noNewExisted
end

function CountryManager:getLastOpenedCountryID()
  --print("__" .. self:getNewMissionID())
  local aNewMissionID
  local noNewExisted
  aNewMissionID, noNewExisted = self:getNewMissionID()
  if not noNewExisted then
    local aCountryID = math.modf(math.modf(aNewMissionID / 100) / 100)
    if aCountryID > max_unlock_city_id then
      aCountryID = max_unlock_city_id
    end
    return aCountryID
  end
  local result = -1
  for _, v in pairs(MetaManager.battle_country) do
    if v.id > result then
      result = v.id
    end
  end
  if result > max_unlock_city_id then
    result = max_unlock_city_id
  end
  return result
end

function CountryManager:getLastOpenedChapterID()
  local aNewMissionID
  local noNewExisted
  aNewMissionID, noNewExisted = self:getNewMissionID()
  if not noNewExisted then
    return math.modf(aNewMissionID / 100)
  end
  local result = -1
  for _, v in pairs(MetaManager.battle_chapter) do
    if v.id > result then
      result = v.id
    end
  end
  return result
end

function CountryManager:getLastOpenedMissionID()
  local aNewMissionID
  local noNewExisted
  aNewMissionID, noNewExisted = self:getNewMissionID()
  if not noNewExisted then
    return aNewMissionID
  end
  local result = -1
  for _, v in pairs(MetaManager.battle_mission) do
    if v.id > result then
      result = v.id
    end
  end
  return result
end

function CountryManager:getCountryName(aCountryID)
  return Localization:getInstance():getText(MetaManager.battle_country[aCountryID].cityNameKey)
end

function CountryManager:getChapterName(aChapterID)
  return Localization:getInstance():getText(MetaManager.battle_chapter[aChapterID].chapterNameKey)
end

function CountryManager:getMissionName(aMissionID)
  --print("CountryManager:getMissionName " .. aMissionID)
  return Localization:getInstance():getText(MetaManager.battle_mission[aMissionID].missionNameKey)
end

function CountryManager:getMissionBattleLimit(aMissionID)
  return tonumber(MetaManager.battle_mission[aMissionID].battleWinMax)
end

function CountryManager:getMissionCurrentBattleTime(aMissionID)
  local aMissionInfoList = self.missionCompleteInfo
  --print(table.tostring(aMissionInfoList))
  for _, aMissionInfo in pairs(aMissionInfoList) do
    if aMissionInfo.missionId == aMissionID then
      return aMissionInfo.missionCompleteCount
    end
  end
  return 0
end

function CountryManager:getMissionInfo(aMissionID)
  return Localization:getInstance():getText(MetaManager.battle_mission[aMissionID].missionDescKey)
end

function CountryManager:getChapterInfo(aChapterID)
  return Localization:getInstance():getText(MetaManager.battle_chapter[aChapterID].chapterDescKey)
end

function CountryManager:getChapterCompleteInfo(aChapterID)
  local result = {finish = false, finishReward = false}
  local aCountryID = math.modf(aChapterID / 100)
  local existed = false
  for _, aCountryData in ipairs(self.countryData.sceneCountries) do
    if existed then
      break
    end
    if aCountryData.countryId == aCountryID then
      for _, aChapterData in ipairs(aCountryData.sceneChapters) do
        if aChapterData.chapterId == aChapterID then
          existed = true
          result.finish = aChapterData.finish
          result.finishReward = aChapterData.finishReward
          break
        end
      end
    end
  end
  return result
end

function CountryManager:shouldShowChapterFinishRewardPanel()
  local result = self:getChapterCompleteInfo(self.selectedChapterID)
  if result.finish and (not result.finishReward) then
    return true
  end
  return false
end

function CountryManager:getChapterFinishReward()
  local result = {}
  local aBattleChapterConfig = MetaManager.battle_chapter[self.selectedChapterID]
  result.rewardType = aBattleChapterConfig.rewardType
  result.rewardID = aBattleChapterConfig.rewardID
  result.amount = aBattleChapterConfig.rewardNum
  return result
end

function CountryManager:getChapterName(aChapterID)
  return Localization:getInstance():getText(MetaManager.battle_chapter[aChapterID].chapterNameKey)
end

function CountryManager:getAllCountryIDs()
  local result = {}
  for _, aCountry in pairs(MetaManager.battle_country) do
    local aID = tonumber(aCountry.id, 10)
    table.insert(result, aID)
  end
  table.sort(result, function(a, b)
      return a < b
    end
  )
  return result
end

function CountryManager:selectCountryID(aCountryID)
  self.selectedCountryID = aCountryID
  if self.selectedCountryID == self:getCountryIDOfLastBattle() then
    self.selectedChapterID = self:getChapterIDOfLastBattle()
    self.selectedMissionID = self:getMissionIDOfLastBattle()
  else
    self.selectedChapterID = self:getFirstChapterIDWithCountryIDInConfig(self.selectedCountryID)
    self.selectedMissionID = self:getFirstMissionIDWithChapterIDInConfig(self.selectedChapterID)
  end
end

function CountryManager:selectChapterID(aChapterID)
  --print(aChapterID)
  if self.selectedChapterID ~= aChapterID then
    self.selectedChapterID = aChapterID
    if self.selectedChapterID == self:getChapterIDOfLastBattle() then
      self.selectedMissionID = self:getMissionIDOfLastBattle()
    else
      self.selectedMissionID = self:getFirstMissionIDWithChapterIDInConfig(self.selectedChapterID)
    end
  end
end

function CountryManager:selectMissionID(aMissionID)
  self.selectedMissionID = aMissionID
end

function CountryManager:challangeMissionID(aMissionID)
  if aMissionID then
    self.selectedMissionID = aMissionID
    self.selectedChapterID = math.modf(self.selectedMissionID / 100)
    self.selectedCountryID = math.modf(self.selectedChapterID / 100)
    
  end
  
  --[[
  if aMissionID then
    self.missionContext.missionId = aMissionID
  else
    self.missionContext.missionId = self.selectedMissionID
  end
  self.missionContext.finishedStep = 0
  self.missionContext.routeId = 1]]
end

function CountryManager:getMissionProgress(aMissionID)
  local aChapterID = math.modf(aMissionID / 100)
  local aCountryID = math.modf(aChapterID / 100)
  for _, aCountryData in ipairs(self.countryData.sceneCountries) do
    if aCountryData.countryId == aCountryID then
      for _, aChapterData in ipairs(aCountryData.sceneChapters) do
        if aChapterData.chapterId == aChapterID then
          for _, aMissionData in ipairs(aChapterData.sceneMissions) do
            if aMissionData.missionId == aMissionID then
              return 100
            end
          end
          break
        end
      end
      break
    end
  end
  if self.missionContext.missionId == aMissionID then
    local aMinStepIndex = 10000
    local aMaxStepIndex = 0
    local haveFound = false
    for _, aEventStep in ipairs(MetaManager.battle_chapter_event) do
      if tonumber(aEventStep.missionId, 10) == aMissionID then
        haveFound = true
        local aStepIndex = tonumber(aEventStep.step, 10)
        if aStepIndex < aMinStepIndex then
          aMinStepIndex = aStepIndex
        end
        if aStepIndex > aMaxStepIndex then
          aMaxStepIndex = aStepIndex
        end
      else
        if haveFound then
          break
        end
      end
    end
    --[[
    for _, aEventStep in ipairs(MetaManager.battle_chapter_event[aChapterID]) do
      if tonumber(aEventStep.missionId, 10) == aMissionID then
        local aStepIndex = tonumber(aEventStep.step, 10)
        if aStepIndex < aMinStepIndex then
          aMinStepIndex = aStepIndex
        end
        if aStepIndex > aMaxStepIndex then
          aMaxStepIndex = aStepIndex
        end
      end
    end]]
    local aFinishedStep = self.missionContext.finishedStep - (aMinStepIndex - 1)
    local aTotalStep = aMaxStepIndex - (aMinStepIndex - 1)
    return math.modf(aFinishedStep / aTotalStep * 100)
  else
    return 0
  end
end

function CountryManager:getNextEventID(aMissionID, aFinishedStep, aRouteId)
  local result
  local aEventID = 0
  for _, aChapterEventConfig in pairs(MetaManager.battle_chapter_event) do
    if (aChapterEventConfig.missionId == aMissionID) and (aChapterEventConfig.step == aFinishedStep) then
      if aRouteId == 1 then
        aEventID = aChapterEventConfig.eventType1
      elseif aRouteId == 2 then
        aEventID = aChapterEventConfig.eventType2
      elseif aRouteId == 3 then
        aEventID = aChapterEventConfig.eventType3
      end
      break
    end
  end
  if aEventID ~= 0 then
    result = ChapterEventIDs[aEventID]
  end
  return result
end

function CountryManager:moveToNextStep(aMissionID, aFinishedStep, aRouteId)
  --print(self.missionIDInChallenge)
  --print(aMissionID)
  if self.missionIDInChallenge ~= aMissionID then
    self.missionIDInChallenge = aMissionID
    self:consumeMissionChallengeCount(aMissionID)
  end
  
  self.missionContext.missionId = aMissionID
  self.missionContext.finishedStep = aFinishedStep
  self.missionContext.routeId = aRouteId
  local result =  self:reconstructMissionContext()
  if result == ChapterEventFinishedType.kEventFinished then
    return result
  end
  
  local newMissionId
  if self.countryData.maxFinishedMissionId < aMissionID then
    self.countryData.maxFinishedMissionId = aMissionID
    newMissionId = aMissionID
  end
  
  local aChapterID = math.modf(aMissionID / 100)
  local aCountryID = math.modf(aChapterID / 100)
  local aSharkSceneCountry
  local aSharkSceneChapter
  local aSharkSceneMission
  for _, aValue in ipairs(self.countryData.sceneCountries) do
    if aValue.countryId == aCountryID then
      aSharkSceneCountry = aValue
      break
    end
  end
  if not aSharkSceneCountry then
    aSharkSceneMission = {}
    aSharkSceneMission.missionId = aMissionID
    aSharkSceneMission.star = 0
    aSharkSceneMission.score = 0
    
    aSharkSceneChapter = {}
    aSharkSceneChapter.chapterId = aChapterID
    aSharkSceneChapter.sceneMissions = {aSharkSceneMission}
    aSharkSceneChapter.finish = false
    aSharkSceneChapter.finishReward = false
    
    aSharkSceneCountry = {}
    aSharkSceneCountry.countryId = aCountryID
    aSharkSceneCountry.sceneChapters = {aSharkSceneChapter}
    
    table.insert(self.countryData.sceneCountries, aSharkSceneCountry)
    --print("1")
    --print(table.tostring(self.countryData.sceneCountries))
    
    if result == ChapterEventFinishedType.kChapterFinished then
      aSharkSceneChapter.finish = true
    end
    
    return result, newMissionId
  end
  
  for _, aValue in ipairs(aSharkSceneCountry.sceneChapters) do
    if aValue.chapterId == aChapterID then
      aSharkSceneChapter = aValue
      break
    end
  end
  if not aSharkSceneChapter then
    aSharkSceneMission = {}
    aSharkSceneMission.missionId = aMissionID
    aSharkSceneMission.star = 0
    aSharkSceneMission.score = 0
    
    aSharkSceneChapter = {}
    aSharkSceneChapter.chapterId = aChapterID
    aSharkSceneChapter.sceneMissions = {aSharkSceneMission}
    aSharkSceneChapter.finish = false
    aSharkSceneChapter.finishReward = false
    
    table.insert(aSharkSceneCountry.sceneChapters, aSharkSceneChapter)
    --print("2")
    --print(table.tostring(self.countryData.sceneCountries))
    
    if result == ChapterEventFinishedType.kChapterFinished then
      aSharkSceneChapter.finish = true
    end
    
    return result, newMissionId
  end
  
  for _, aValue in ipairs(aSharkSceneChapter.sceneMissions) do
    if aValue.missionId == aMissionID then
      aSharkSceneMission = aValue
      break
    end
  end
  if not aSharkSceneMission then
    aSharkSceneMission = {}
    aSharkSceneMission.missionId = aMissionID
    aSharkSceneMission.star = 0
    aSharkSceneMission.score = 0
    
    table.insert(aSharkSceneChapter.sceneMissions, aSharkSceneMission)
    --print("3")
    --print(table.tostring(self.countryData.sceneCountries))
    
    if result == ChapterEventFinishedType.kChapterFinished then
      aSharkSceneChapter.finish = true
    end
    
    return result, newMissionId
  end
  
  return result, newMissionId
end

function CountryManager:receiveChapterFinishReward(aChapterID)
  local aCountryID = math.modf(aChapterID / 100)
  local aSharkSceneCountry
  local aSharkSceneChapter
  for _, aValue in ipairs(self.countryData.sceneCountries) do
    if aValue.countryId == aCountryID then
      aSharkSceneCountry = aValue
      break
    end
  end
  for _, aValue in ipairs(aSharkSceneCountry.sceneChapters) do
    if aValue.chapterId == aChapterID then
      aSharkSceneChapter = aValue
      break
    end
  end
  aSharkSceneChapter.finishReward = true
end


function CountryManager:missionFailed()
  --[[
  local aCurrentChapterID = math.modf(self.missionContext.missionId / 100)
  local aMinStepIndex = 100
  
  for _, aEventStep in ipairs(MetaManager.battle_chapter_event[aCurrentChapterID]) do
    if tonumber(aEventStep.missionId, 10) == self.missionContext.missionId then
      local aStepIndex = tonumber(aEventStep.step, 10)
      if aStepIndex < aMinStepIndex then
        aMinStepIndex = aStepIndex
      end
    end
  end
  
  self.missionContext.finishedStep = aMinStepIndex - 1
  self.missionContext.fightLose = false]]
end

function CountryManager:getStartStepWithMissionID(aMissionID)
  --local aChapterID = math.modf(aMissionID / 100)
  --local aChapterEventConfig = MetaManager.battle_chapter_event[aChapterID]
  
  local result = 0
  
  for _, aStepConfig in ipairs(MetaManager.battle_chapter_event) do
    if aStepConfig.missionId == aMissionID then
      result = aStepConfig.step
      break
    end
  end
  
  return result
end

function CountryManager:getTMXSourceNames(aTMXName)
  local result = {}
  local _, last_index = string.find(aTMXName, ".+/")
  if last_index then
    prefix_path = string.sub(aTMXName, 1, last_index)
  else
    prefix_path = ""
  end
  local tmx_handler = assert(io.open(CCFileUtils:sharedFileUtils():fullPathForFilename(aTMXName), "r"))
  local tmx_content
  while true do
    tmx_content = tmx_handler:read()
    if string.find(tmx_content, "layer") then
      break
    end
    
   if string.find(tmx_content, ".png") or string.find(tmx_content, ".webp") then
      for v in string.gmatch(tmx_content, 'source="([^"]+)"') do
      	if string.find(v,".png")  or string.find(v, ".webp") then
	        table.insert(result, prefix_path..v)
	end
      end
    end
  end 
  return result
end

function CountryManager:cacheTMXSources(aTexture, aKey)
  if self.tmxSourceCache[aKey] then
    return
  end
  aTexture:retain()
  self.tmxSourceCache[aKey] = aTexture
end

function CountryManager:checkMissionComplete()
  local oldTime = HeMemDataHolder:getInteger("oldTime")
  if TimeUtil.whetherSwitchDay(oldTime) then
    HeMemDataHolder:setInteger("oldTime", TimeUtil.getServerTimeSeconds())
    self:resetMissionCompleteInfo()
  end
end

function CountryManager:resetMissionCompleteInfo(aMissionId)
  if aMissionId then
    for _, aMissionInfo in pairs(self.missionCompleteInfo) do
      if aMissionInfo.missionId == aMissionId then
        aMissionInfo.missionCompleteCount = 0
        break
      end
    end
  else
    for _, aMissionInfo in pairs(self.missionCompleteInfo) do
      aMissionInfo.missionCompleteCount = 0
    end
  end
end

function CountryManager:consumeMissionChallengeCount(aMissionId, aCount)
  --print(table.tostring(self.missionCompleteInfo))
  --print(aMissionId)
  aCount = aCount or 1
  for _, aMissionInfo in pairs(self.missionCompleteInfo) do
    if aMissionInfo.missionId == aMissionId then
      aMissionInfo.missionCompleteCount = aMissionInfo.missionCompleteCount + aCount
      return
    end
  end
  local aInfo = {}
  aInfo.missionId = aMissionId
  aInfo.missionCompleteCount = aCount
  table.insert(self.missionCompleteInfo, aInfo)
end

function CountryManager:missionIDBeforeMissionID(aMissionId)
  local aBattleMissionConfig = MetaManager.battle_mission[aMissionId]
  if aBattleMissionConfig then
    return aBattleMissionConfig.preMissionId
  else
    return nil
  end
end


