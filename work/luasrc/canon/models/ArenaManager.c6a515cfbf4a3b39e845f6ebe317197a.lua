require "canon.data.MetaManager"

ArenaExchangeTypeEnum = {
  kExchange = "Exchange",
  kReward = "Reward"
}

ResourceTypeEnum = {
  kCoin = 1,
  kGem = 2,
  kEnergy = 3,
  kExp = 4,
  kCard = 5,
  kEquip = 6,
  kProp = 7,
  kFriendPoint = 8,
  kGrid = 9,
  kSkillPoints = 10,
  kEventPoint = 11,
  kArenaScore = 12,
  kVipPackage = 13
}

local arena_broadcast_cache_max = 20

--
-- ArenaManager
--

ArenaManager = class(EventDispatcher)
local arenaManagerInstance = nil
function ArenaManager:sharedManager()
	if not arenaManagerInstance then
		arenaManagerInstance = ArenaManager.new()
	end
	return arenaManagerInstance
end

function ArenaManager:ctor(  )
  self:initializeData()
end

function ArenaManager:initializeData()
  self.arenaData = nil
  self.currentPlayerIndex = 0
  self.arenaReports = {}
  self.arenaExchangeData = {}
  
  self.lastString = nil
  self.lastPosX = 0
  self.startTimeInArena = false
  self.durationInArena = -1    --used for showing report
  self.shouldStayInArena = false
  
  self.hasRewardForRank = false
  self.hasRewardNum = 0
  
  self.scoreRequestTimeStamp = 0
  
  for _, aExchangeConfig in ipairs(MetaManager.arena_score_exchange) do
    local aList = {}
    aList.eType = ArenaExchangeTypeEnum.kExchange
    aList.eId = tonumber(aExchangeConfig.id, 10)
    aList.score = tonumber(aExchangeConfig.score, 10)
    aList.itemMetaId = tonumber(aExchangeConfig.itemMetaId, 10)
    aList.itemType = tonumber(aExchangeConfig.itemType, 10)
    aList.amount = tonumber(aExchangeConfig.amount, 10)
    if aList.itemType == ResourceTypeEnum.kEquip then
      local aEquipMetaConfig = MetaManager.equip_meta[aList.itemMetaId]
      aList.desc = Localization:getInstance():getText(aEquipMetaConfig.desc)
      aList.name = Localization:getInstance():getText(aEquipMetaConfig.name)
      
    elseif aList.itemType == ResourceTypeEnum.kCard then
      local aCardMetaConfig = MetaManager.card_meta[aList.itemMetaId]
      aList.desc = Localization:getInstance():getText(aCardMetaConfig.desc)
      aList.name = Localization:getInstance():getText(aCardMetaConfig.name)
      
    elseif aList.itemType == ResourceTypeEnum.kProp then
      local aPropMetaConfig = MetaManager.prop_meta[aList.itemMetaId]
      aList.desc = Localization:getInstance():getText(aPropMetaConfig.desc)
      aList.name = Localization:getInstance():getText(aPropMetaConfig.name)
      
    end
    
    table.insert(self.arenaExchangeData, aList)
  end
  for _, aRewardConfig in ipairs(MetaManager.arena_rank_reward) do
    local aList = {}
    aList.eType = ArenaExchangeTypeEnum.kReward
    aList.rank = tonumber(aRewardConfig.rank, 10)
    aList.itemMetaId = tonumber(aRewardConfig.itemMetaId, 10)
    aList.itemType = tonumber(aRewardConfig.itemType, 10)
    aList.amount = tonumber(aRewardConfig.amount, 10)
    aList.desc = Localization:getInstance():getText(aRewardConfig.desc, {num = aList.rank})
    if aList.itemType == ResourceTypeEnum.kEquip then
      local aEquipMetaConfig = MetaManager.equip_meta[aList.itemMetaId]
      aList.name = Localization:getInstance():getText(aEquipMetaConfig.name)
    elseif aList.itemType == ResourceTypeEnum.kCard then
      local aCardMetaConfig = MetaManager.card_meta[aList.itemMetaId]
      aList.name = Localization:getInstance():getText(aCardMetaConfig.name)
    elseif aList.itemType == ResourceTypeEnum.kProp then
      local aPropMetaConfig = MetaManager.prop_meta[aList.itemMetaId]
      aList.name = Localization:getInstance():getText(aPropMetaConfig.name)
    end
    table.insert(self.arenaExchangeData, aList)
  end
end

function ArenaManager:resetArenaData(aArenaData)
  self.arenaDataRefreshTime = TimeUtil.getServerTimeSeconds()
  self.arenaData = aArenaData
  --print(self.arenaData.arenaChallengeNum, self.arenaData.arenaBoughtNum)
  table.sort(self.arenaData.sharkArenaPlayers, function(a, b)
      return a.rank < b.rank
    end
  )
  table.sort(self.arenaData.sharkArenaReports, function(a, b)
      return tonumber(a.challengeTime, 10) > tonumber(b.challengeTime, 10)
    end
  )
  for aIndex, temp in ipairs(self.arenaData.sharkArenaPlayers) do
    if temp.rank == self.arenaData.sharkArenaRank.rank then
      self.currentPlayerIndex = aIndex
    end
  end
  if self.arenaData.sharkArenaRankReward then
    for _, aRewardReceived in ipairs(self.arenaData.sharkArenaRankReward) do
      for aExchangeIndex, aExchangeData in ipairs(self.arenaExchangeData) do
        if (aExchangeData.eType == ArenaExchangeTypeEnum.kReward) and aExchangeData.rank == aRewardReceived.rank then
          table.remove(self.arenaExchangeData, aExchangeIndex)
          break
        end
      end
    end
  end
  
end

function ArenaManager:containInFoes(aUid)
  for _, temp in pairs(self.arenaData.foes) do
    if temp.uid == aUid then
      return true
    end
  end
  return false
end

function ArenaManager:receiveNewReport(aReport)
  table.insert(self.arenaReports, aReport)
  if #self.arenaReports > arena_broadcast_cache_max then
    table.remove(self.arenaReports, 1)
  end
  if self.shouldStayInArena then
    table.remove(self.arenaReports, 1)
    self.shouldStayInArena = false
  end
end

function ArenaManager:popoutReport()
  local _json = require("cjson")
  --
  local aReport
  if #self.arenaReports == 1 then
    aReport = self.arenaReports[1]
    self.shouldStayInArena = true
  else
    aReport = table.remove(self.arenaReports, 1)
    self.shouldStayInArena = false
  end
  
  local result
  if aReport.type == 1 then
    local num = _json.decode(aReport.content).battleConinuousWins
    local aIndex = 5
    if num == 5 then
      aIndex = 1
    elseif num == 10 then
      aIndex = 2
    elseif num == 15 then
      aIndex = 3
    elseif num == 20 then
      aIndex = 4
    elseif num == 30 then
      aIndex = 5
    end
    result = Localization:getInstance():getText(string.format("arena_broadcast_consecutiveWin%d", aIndex), {player = aReport.userName, num = num})
  elseif aReport.type == 2 then
    result = Localization:getInstance():getText("arena_broadcast_totalPoints", {player = aReport.userName, num = _json.decode(aReport.content).gainedScore})
  elseif aReport.type == 3 then
    local aList = _json.decode(aReport.content)
    result = Localization:getInstance():getText("arena_broadcast_topX", {player = aReport.userName, num1 = aList.topRank, num2 = aList.arenaRank})
  elseif aReport.type == 4 then
    result = Localization:getInstance():getText("arena_broadcast_firstTopX", {player = aReport.userName, num = _json.decode(aReport.content).topRank})
  end
  return result
end

function ArenaManager:exchangeSucceedByArenaScore(aRequisite, aRewardList)
  RewardManager:getReward(aRewardList)
  --[[
  if aRequisite.itemType == ResourceTypeEnum.kEventPoint then
    self.arenaData.sharkArenaRank.score = self.arenaData.sharkArenaRank.score - aRequisite.amount
  end
  ]]
  local aNegativeReward = aRequisite
  aNegativeReward.amount = -tonumber(aNegativeReward.amount)
  RewardManager:getReward({aNegativeReward})
end

function ArenaManager:gainRankFirstReward(aRank, aRewardList)
  RewardManager:getReward(aRewardList)
  for aExchangeIndex, aExchangeData in ipairs(self.arenaExchangeData) do
    if (aExchangeData.eType == ArenaExchangeTypeEnum.kReward) and aExchangeData.rank == aRank then
      table.remove(self.arenaExchangeData, aExchangeIndex)
      break
    end
  end
end

function ArenaManager:getArenaPersonalReports()
  local result = {}
  --print(table.tostring(self.arenaData.sharkArenaReports))
  if #self.arenaData.sharkArenaReports == 0 then
    return result
  end
  local currentDateTable = os.date("*t")
  local currentYear = currentDateTable.year
  local currentMonth = currentDateTable.month
  local currentDay = currentDateTable.day
  local currentTotalSeconds = os.time{year=currentYear,month=currentMonth,day=currentDay,hour=0}
  for _, aPersonalReport in ipairs(self.arenaData.sharkArenaReports) do
    local aResult = {}
    local aString
    local aDateTable = os.date("*t", math.modf(aPersonalReport.challengeTime / 1000))
    local aYear = aDateTable.year
    local aMonth = aDateTable.month
    local aDay = aDateTable.day
    local aTotalSeconds = os.time{year=aYear,month=aMonth,day=aDay,hour=0}
    local aOffsetDays = (currentTotalSeconds - aTotalSeconds) / (24 * 3600)
    if aOffsetDays > -0.1 and aOffsetDays < 0.1 then
      aString = string.format("%.2d:%.2d", aDateTable.hour, aDateTable.min)
    elseif aOffsetDays > 1 - 0.1 and aOffsetDays < 1 + 0.1 then
      aString = Localization:getInstance():getText("arena_reportDateYesterday")
    elseif aOffsetDays > 2 - 0.1 and aOffsetDays < 7 + 0.1 then
      for i = 2, 7 do
        if aOffsetDays > i - 0.1 and aOffsetDays < i + 0.1 then
          aString = Localization:getInstance():getText("arena_reportDateDaysAgo", {num = i})
          break
        end
      end
    else
      aString = string.format("%.2d/%.2d", aMonth, aDay)
    end
    aResult.reportDate = aString
    local aDesString
    if aPersonalReport.initiative then
      aDesString = Localization:getInstance():getText("arena_reportContentFirst1", {player = aPersonalReport.matchedNickName})
      if aPersonalReport.result then
        aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentSecond1")
      else
        aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentSecond2")
      end
    else
      aDesString = Localization:getInstance():getText("arena_reportContentFirst2", {player = aPersonalReport.matchedNickName})
      if aPersonalReport.result then
        aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentSecond3")
      else
        aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentSecond4")
      end
    end
    if aPersonalReport.rewardScore > 0 then
      aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentFourth1", {num = aPersonalReport.rewardScore})
    else
      aDesString = aDesString .. Localization:getInstance():getText("arena_reportContentFourth2")
    end
    local rankChanged = false
    local rankChangedDes
    local rankChangedDes2
    if aPersonalReport.initRank > aPersonalReport.resultRank then
      rankChanged = true
      rankChangedDes = Localization:getInstance():getText("arena_reportContentThird1")
      rankChangedDes2 = Localization:getInstance():getText("arena_reportContentThird1_2")
    elseif aPersonalReport.initRank < aPersonalReport.resultRank then
      rankChanged = true
      rankChangedDes = Localization:getInstance():getText("arena_reportContentThird2")
      rankChangedDes2 = Localization:getInstance():getText("arena_reportContentThird2_2")
    else
      rankChangedDes = ""
    end
    
    aResult.reportDes = aDesString .. rankChangedDes
    aResult.reportDesPart1 = aDesString
    aResult.reportDesPart2 = rankChangedDes2
    aResult.uid = aPersonalReport.matchedUid
    aResult.initiative = aPersonalReport.initiative
    aResult.rankChanged = rankChanged
    aResult.resultRank = aPersonalReport.resultRank
    aResult.result = aPersonalReport.result
    table.insert(result, aResult)
  end
  --print(table.tostring(result))
  return result
end

function ArenaManager:startTime()
  self.lastString = nil
  self.lastPosX = 0
  self.startTimeInArena = true
  self.durationInArena = -1
  self.shouldStayInArena = false
end

function ArenaManager:stopTime()
  self.lastString = nil
  self.lastPosX = 0
  self.startTimeInArena = false
  self.durationInArena = -1
  self.shouldStayInArena = false
end

function ArenaManager:gainArenaScoreByRank(aScore)
  self.hasRewardForRank = true
  self.hasRewardNum = aScore
end

function ArenaManager:removeArenaScoreByRank()
  self.hasRewardForRank = false
  self.hasRewardNum = 0
end

function ArenaManager:whetherRequestForArenaScore()
  return TimeUtil.whetherSwitchGainArenaRankScoreDay(self.scoreRequestTimeStamp)
end

function ArenaManager:cacheGainArenaRankScoreTime()
  self.scoreRequestTimeStamp = TimeUtil.getServerTimeSeconds()
end

