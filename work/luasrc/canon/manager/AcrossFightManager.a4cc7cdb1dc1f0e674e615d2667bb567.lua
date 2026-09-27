
AcrossFightTimeEnum = {
  notStart = 1,     --跨服比武奖励领取结束之后，参赛人员确定之前
  happyGuess = 2,   --参赛人员确定之后，全民竞猜结束之前
  top32OverBefore = 3,  --32强比赛开始之后，32强比赛结束之前
  top32OverAfter = 4,   --32强比赛结束之后，16强比赛开始之前
  top16OverBefore = 5,  --16强比赛开始之后，16强比赛结束之前
  top16OverAfter = 6,   --16强比赛结束之后，8强比赛开始之前
  top8OverBefore = 7,   --8强比赛开始之后，8强比赛结束之前
  top8OverAfter = 8,    --8强比赛结束之后，4强比赛开始之前
  top4OverBefore = 9,   --4强比赛开始之后，4强比赛结束之前
  top4OverAfter = 10,    --4强比赛结束之后，冠军赛(包括三四名比赛)开始之前
  top2OverBefore = 11,   --冠军赛开始之后，冠军赛结束之前
  top2OverAfter = 12,    --冠军赛结束之后，能够领取奖励之前
  rewardTime = 13,       --能够领取奖励之后，奖励领取结束之前
}

local seconds_per_week = 3600 * 24 * 7
local seconds_per_min = 60
--
--AcrossFightManager
--

AcrossFightManager = {}

local fightData = {}

local function getUserInfo(aUid)
  for _, aUserInfo in pairs(fightData.crossPKInfo.crossPkUserInfos) do
    if tostring(aUserInfo.uid) == tostring(aUid) then
      return aUserInfo
    end
  end
  return {}
end

local function generateFiguresData()
  local fight_table = {}
  for i = 1, 4 do
    fight_table[i] = {}
    local total_num = 32
    local base_number = 0
    local num_per_group = 8
    for j = 1, 3 do
      local base_number_for_round = base_number + 1 + (i - 1) * num_per_group
      if not fightData.crossPKInfo.uids[base_number_for_round] then
        break
      end
      local next_base_number = base_number + total_num / math.pow(2, j - 1)
      local next_num_per_group = num_per_group / 2
      local next_base_number_for_round = next_base_number + 1 + (i - 1) * next_num_per_group
      for k = 1, num_per_group, 2 do
        local index_1 = base_number_for_round + k - 1
        local index_2 = base_number_for_round + k
        local temp = {}
        local winner_index = next_base_number_for_round + (k + 1) / 2 - 1
        temp[1] = getUserInfo(fightData.crossPKInfo.uids[index_1])
        temp[2] = getUserInfo(fightData.crossPKInfo.uids[index_2])
        if not fightData.crossPKInfo.uids[winner_index] then   --还没决出胜负
          temp[3] = 0
        elseif fightData.crossPKInfo.uids[winner_index] == fightData.crossPKInfo.uids[index_1] then
          temp[3] = 1
        else
          temp[3] = 2
        end
        temp[4] = total_num / math.pow(2, j - 1)
        temp[5] = index_2 / 2
        table.insert(fight_table[i], temp)
      end
      base_number = next_base_number
      num_per_group = next_num_per_group
    end
  end
  fightData.crossPKInfo.figuresData = fight_table
end

local function generateScheduleTableData()
  local schedule_table_data = {}
  local total_num = 32
  for i = 1, 4 do
    --print("----start:" .. i)
    schedule_table_data[i] = {}
    local base_number = 0
    local num_per_group = 8
    for j = 1, 4 do
      local base_number_for_round = base_number + 1 + (i - 1) * num_per_group
      if not fightData.crossPKInfo.uids[base_number_for_round] then
        break
      end
      for k = 1, num_per_group do
        table.insert(schedule_table_data[i], getUserInfo(fightData.crossPKInfo.uids[base_number_for_round + k - 1]))
      end
      base_number = base_number + total_num / math.pow(2, j - 1)
      num_per_group = num_per_group / 2
    end
    --print("----end:" .. i)
  end
  
  local first_top4_index = 1
  for i = 1, 3 do
    first_top4_index = first_top4_index + total_num / math.pow(2, i - 1)
  end
  if fightData.crossPKInfo.uids[first_top4_index] then
    schedule_table_data[5] = {}
    for i = 1, 4 do
      --print(first_top4_index + i - 1)
      table.insert(schedule_table_data[5], getUserInfo(fightData.crossPKInfo.uids[first_top4_index + i - 1]))
    end
  end
  local temp_index_list = {63,64,66}
  for i = 1, 3 do
    if fightData.crossPKInfo.uids[temp_index_list[i]] then
      table.insert(schedule_table_data[5], getUserInfo(fightData.crossPKInfo.uids[temp_index_list[i]]))
    end
  end
  fightData.crossPKInfo.scheduleTableData = schedule_table_data
end

local function getTimeItem(itemId)
  for _, aTimeItem in ipairs(DataManager.GameMetaData.crossServerTimeConfig.items) do
    if aTimeItem.id == itemId then
      return aTimeItem
    end
  end
  return nil
end

function AcrossFightManager.resetCrossPKInfo(aCrossPKInfo)
  fightData.crossPKInfo = aCrossPKInfo
  generateFiguresData()
  generateScheduleTableData()
end

function AcrossFightManager.getGuessTipNum()
  if AcrossFightManager.getCurrentTimeEnum() == AcrossFightTimeEnum.happyGuess then
    local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
    local curVersion = AcrossFightManager.getCurVersion()
    if sharkCrossPkUser.crossVersion ~= curVersion then
      DataManager.resetSharkCrossPkUser(curVersion)
      sharkCrossPkUser = DataManager.getSharkCrossPkUser()
    end
    if tonumber(sharkCrossPkUser.guessUid) == 0 then
      return 1
    else
      return 0
    end
  else
    return 0
  end
end

function AcrossFightManager.whetherHasServerReward()
  if AcrossFightManager.getCurrentTimeEnum() ~= AcrossFightTimeEnum.rewardTime then
    return false
  end
  if not fightData.crossPKInfo.uids[66] then
    return false
  end
  
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  if sharkCrossPkUser.gainServerReward then
    return false
  end
  
  local serverNumber1 = tonumber(string.sub(fightData.crossPKInfo.uids[66], -4, -1))
  local serverNumber2 = tonumber(string.sub(tostring(DataManager.getCurrUser().uid), -4, -1))
  if serverNumber1 == serverNumber2 then
    return true
  end
  return false
end

function AcrossFightManager.whetherHasRankReward()
  if AcrossFightManager.getCurrentTimeEnum() ~= AcrossFightTimeEnum.rewardTime then
    return false
  end
  
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  if sharkCrossPkUser.gainRankReward then
    return false
  end
  
  for _, aUid in ipairs(fightData.crossPKInfo.uids) do
    if tonumber(aUid) == tonumber(DataManager.getCurrUser().uid) then
      return true
    end
  end
  return false
end

function AcrossFightManager.whetherHasGuessReward()
  if AcrossFightManager.getCurrentTimeEnum() ~= AcrossFightTimeEnum.rewardTime then
    return false
  end
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  
  if sharkCrossPkUser.gainGuessReward then
    return false
  end
  
  if tonumber(sharkCrossPkUser.guessUid) == 0 then
    return false
  else
    return true
  end
end

function AcrossFightManager.getRewardTipNum()
  if AcrossFightManager.getCurrentTimeEnum() == AcrossFightTimeEnum.rewardTime then
    local aTipNum = 0
    if AcrossFightManager.whetherHasServerReward() then
      aTipNum = aTipNum + 1
    end
    if AcrossFightManager.whetherHasRankReward() then
      aTipNum = aTipNum + 1
    end
    if AcrossFightManager.whetherHasGuessReward() then
      aTipNum = aTipNum + 1
    end
    return aTipNum
  else
    return 0
  end
end

function AcrossFightManager.getCurrentTimeEnum()
  if not AcrossFightManager.isOpen() then
    return AcrossFightTimeEnum.notStart
  end
  
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local crossServerTimeConfig = DataManager.GameMetaData.crossServerTimeConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  local curRoundBaseSeconds = activityBeginSeconds + seconds_per_week * math.floor((curSeconds - activityBeginSeconds) / seconds_per_week)
  local timeItems = {}
  for i = 0, 9 do
    timeItems[i] = getTimeItem(i)
  end
  if curSeconds >= (curRoundBaseSeconds + (timeItems[0].crossServerBegin + timeItems[0].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[1].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.happyGuess
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[1].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[1].crossServerBegin + timeItems[1].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.top32OverBefore
  elseif curSeconds >= (curRoundBaseSeconds + (timeItems[1].crossServerBegin + timeItems[1].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[2].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.top32OverAfter
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[2].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[2].crossServerBegin + timeItems[2].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.top16OverBefore
  elseif curSeconds >= (curRoundBaseSeconds + (timeItems[2].crossServerBegin + timeItems[2].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[3].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.top16OverAfter
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[3].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[3].crossServerBegin + timeItems[3].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.top8OverBefore
  elseif curSeconds >= (curRoundBaseSeconds + (timeItems[3].crossServerBegin + timeItems[3].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[4].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.top8OverAfter
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[4].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[4].crossServerBegin + timeItems[4].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.top4OverBefore
  elseif curSeconds >= (curRoundBaseSeconds + (timeItems[4].crossServerBegin + timeItems[4].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[6].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.top4OverAfter
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[6].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[6].crossServerBegin + timeItems[6].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.top2OverBefore
  elseif curSeconds >= (curRoundBaseSeconds + (timeItems[6].crossServerBegin + timeItems[6].crossServerContinue) * seconds_per_min) and curSeconds < (curRoundBaseSeconds + timeItems[9].crossServerBegin * seconds_per_min) then
    return AcrossFightTimeEnum.top2OverAfter
  elseif curSeconds >= (curRoundBaseSeconds + timeItems[9].crossServerBegin * seconds_per_min) and curSeconds < (curRoundBaseSeconds + (timeItems[9].crossServerBegin + timeItems[9].crossServerContinue) * seconds_per_min) then
    return AcrossFightTimeEnum.rewardTime
  end
  
  return AcrossFightTimeEnum.notStart
end

function AcrossFightManager.getAcrossFightTabType()
  local aTimeEnum = AcrossFightManager.getCurrentTimeEnum()
  if aTimeEnum == AcrossFightTimeEnum.happyGuess or aTimeEnum == AcrossFightTimeEnum.top32OverBefore or aTimeEnum == AcrossFightTimeEnum.top32OverAfter or aTimeEnum == AcrossFightTimeEnum.top16OverBefore or aTimeEnum == AcrossFightTimeEnum.top16OverAfter or aTimeEnum == AcrossFightTimeEnum.top8OverBefore then
    return 1
  elseif aTimeEnum == AcrossFightTimeEnum.top8OverAfter or aTimeEnum == AcrossFightTimeEnum.top4OverBefore or aTimeEnum == AcrossFightTimeEnum.top4OverAfter or aTimeEnum == AcrossFightTimeEnum.top2OverBefore then
    return 2
  elseif aTimeEnum == AcrossFightTimeEnum.top2OverAfter or aTimeEnum == AcrossFightTimeEnum.rewardTime then
    return 3
  else
    return 4
  end
end

function AcrossFightManager.getFiguresData(groupId, aTimeEnum)
  local result = {}
  local groud_data = fightData.crossPKInfo.figuresData[groupId]
  local top_num
  local finished
  if aTimeEnum == AcrossFightTimeEnum.happyGuess or aTimeEnum == AcrossFightTimeEnum.top32OverBefore then
    top_num = 32
    finished = false
  elseif aTimeEnum == AcrossFightTimeEnum.top32OverAfter then
    top_num = 32
    finished = true
  elseif aTimeEnum == AcrossFightTimeEnum.top16OverBefore then
    top_num = 16
    finished = false
  elseif aTimeEnum == AcrossFightTimeEnum.top16OverAfter then
    top_num = 16
    finished = true
  elseif aTimeEnum == AcrossFightTimeEnum.top8OverBefore then
    top_num = 8
    finished = false
  else
    top_num = 8
    finished = true
  end
  for i = #groud_data, 1, -1 do
  --for _, aData in ipairs(groud_data) do
    local aData = groud_data[i]
    if aData[4] >= top_num then
      local temp = {}
      temp[1] = aData[1]
      temp[2] = aData[2]
      temp[3] = aData[3]
      temp[4] = aData[4]
      temp[5] = aData[5]
      if temp[4] == top_num and not finished then
        temp[3] = 0
      end
      table.insert(result, temp)
    end
  end
  return result
end

function AcrossFightManager.getScheduleTableData(aTimeEnum)
  local result = {}
  local data = fightData.crossPKInfo.scheduleTableData
  local num_per_group = 0
  local num_top4 = 0
  if aTimeEnum == AcrossFightTimeEnum.happyGuess or aTimeEnum == AcrossFightTimeEnum.top32OverBefore then
    num_per_group = 8
  elseif aTimeEnum == AcrossFightTimeEnum.top32OverAfter or aTimeEnum == AcrossFightTimeEnum.top16OverBefore then
    num_per_group = 8 + 4
  elseif aTimeEnum == AcrossFightTimeEnum.top16OverAfter or aTimeEnum == AcrossFightTimeEnum.top8OverBefore then
    num_per_group = 8 + 4 + 2
  elseif aTimeEnum == AcrossFightTimeEnum.top8OverAfter or aTimeEnum == AcrossFightTimeEnum.top4OverBefore then
    num_per_group = 8 + 4 + 2 + 1
    num_top4 = 4
  elseif aTimeEnum == AcrossFightTimeEnum.top4OverAfter or aTimeEnum == AcrossFightTimeEnum.top2OverBefore then
    num_per_group = 8 + 4 + 2 + 1
    num_top4 = 4 + 2
  else
    num_per_group = 8 + 4 + 2 + 1
    num_top4 = 4 + 2 + 1
  end
  for i = 1, 4 do
    local temp = {}
    for j = 1, num_per_group do
      table.insert(temp, data[i][j])
    end
    table.insert(result, temp)
  end
  if num_top4 > 0 then
    local temp = {}
    for j = 1, num_top4 do
      table.insert(temp, data[5][j])
    end
    table.insert(result, temp)
  end
  return result
end

function AcrossFightManager.getRewardTime()
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  local curRoundBaseSeconds = activityBeginSeconds + seconds_per_week * math.floor((curSeconds - activityBeginSeconds) / seconds_per_week)
  local rewardTimeItem = getTimeItem(9)
  local startSeconds = curRoundBaseSeconds + rewardTimeItem.crossServerBegin * seconds_per_min
  local endSeconds = curRoundBaseSeconds + (rewardTimeItem.crossServerBegin + rewardTimeItem.crossServerContinue) * seconds_per_min
  local result = {}
  result[1] = TimeUtil.getDateInServertime(startSeconds)
  result[2] = TimeUtil.getDateInServertime(endSeconds)
  return result
end

function AcrossFightManager.getCurVersion()
  return fightData.crossPKInfo.crossVersion
end

function AcrossFightManager.getGuessLeftSeconds()
  if AcrossFightManager.getCurrentTimeEnum() ~= AcrossFightTimeEnum.happyGuess then
    return 0
  end
  
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  local curRoundBaseSeconds = activityBeginSeconds + seconds_per_week * math.floor((curSeconds - activityBeginSeconds) / seconds_per_week)
  local guessTimeItem = getTimeItem(8)
  --local guessStartSeconds = curRoundBaseSeconds + guessTimeItem.crossServerBegin * seconds_per_min
  local guessEndSeconds = curRoundBaseSeconds + (guessTimeItem.crossServerBegin + guessTimeItem.crossServerContinue) * seconds_per_min
  if curSeconds < guessEndSeconds then
    return guessEndSeconds - curSeconds
  end
  
  return 0
end

function AcrossFightManager.getGuessRank()
  return fightData.crossPKInfo.guessRank
end

function AcrossFightManager.getGuessUsername(aUid)
  local aUserInfo = getUserInfo(aUid)
  if aUserInfo then
    return aUserInfo.nickName
  end
  return ""
end

function AcrossFightManager.getRewardPlayerList()
  if not fightData.crossPKInfo.uids[66] then
    return nil
  end
  local result = {}
  table.insert(result, getUserInfo(fightData.crossPKInfo.uids[66]))
  if fightData.crossPKInfo.uids[66] == fightData.crossPKInfo.uids[63] then
    table.insert(result, getUserInfo(fightData.crossPKInfo.uids[64]))
  else
    table.insert(result, getUserInfo(fightData.crossPKInfo.uids[63]))
  end
  table.insert(result, getUserInfo(fightData.crossPKInfo.uids[65]))
  return result
end

function AcrossFightManager.gainRankRewardSucceed()
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  sharkCrossPkUser.gainRankReward = true
  DataManager.setSharkCrossPkUser(sharkCrossPkUser)
end

function AcrossFightManager.gainGuessRewardSucceed()
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  sharkCrossPkUser.gainGuessReward = true
  DataManager.setSharkCrossPkUser(sharkCrossPkUser)
end

function AcrossFightManager.gainServerRewardSucceed()
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  sharkCrossPkUser.gainServerReward = true
  DataManager.setSharkCrossPkUser(sharkCrossPkUser)
end

function AcrossFightManager.setCapacityList(data)
  fightData.capacityList = data
end

function AcrossFightManager.getCapacityList()
  local result = fightData.capacityList or {}
  table.sort(result, function(a, b)
      return a.capacity > b.capacity
    end
  )
  return result
end

function AcrossFightManager.getTop4Data()
  local currentTime = AcrossFightManager.getCurrentTimeEnum()
  if currentTime < AcrossFightTimeEnum.top8OverAfter then
    return {}
  end
  local result = {}
  if fightData.crossPKInfo.uids[57] then
    local temp = {}
    temp[1] = getUserInfo(fightData.crossPKInfo.uids[57])
    temp[2] = getUserInfo(fightData.crossPKInfo.uids[58])
    temp[3] = false
    temp[4] = 58 / 2
    temp[5] = 0
    if fightData.crossPKInfo.uids[63] == fightData.crossPKInfo.uids[57] then
      temp[5] = 1
    elseif fightData.crossPKInfo.uids[63] == fightData.crossPKInfo.uids[58] then
      temp[5] = 2
    end
    table.insert(result, temp)
    temp = {}
    temp[1] = getUserInfo(fightData.crossPKInfo.uids[59])
    temp[2] = getUserInfo(fightData.crossPKInfo.uids[60])
    temp[3] = false
    temp[4] = 60 / 2
    temp[5] = 0
    if fightData.crossPKInfo.uids[64] == fightData.crossPKInfo.uids[59] then
      temp[5] = 1
    elseif fightData.crossPKInfo.uids[64] == fightData.crossPKInfo.uids[60] then
      temp[5] = 2
    end
    table.insert(result, temp)
  end
  if currentTime >= AcrossFightTimeEnum.top4OverAfter then
    for _, temp in ipairs(result) do
      temp[3] = true
    end
    if fightData.crossPKInfo.uids[61] then
      local temp = {}
      temp[1] = getUserInfo(fightData.crossPKInfo.uids[61])
      temp[2] = getUserInfo(fightData.crossPKInfo.uids[62])
      temp[3] = false
      temp[4] = 62 / 2
      temp[5] = 0
      if fightData.crossPKInfo.uids[65] == fightData.crossPKInfo.uids[61] then
        temp[5] = 1
      elseif fightData.crossPKInfo.uids[65] == fightData.crossPKInfo.uids[62] then
        temp[5] = 2
      end
      table.insert(result, 1, temp)
      temp = {}
      temp[1] = getUserInfo(fightData.crossPKInfo.uids[63])
      temp[2] = getUserInfo(fightData.crossPKInfo.uids[64])
      temp[3] = false
      temp[4] = 64 / 2
      temp[5] = 0
      if fightData.crossPKInfo.uids[66] == fightData.crossPKInfo.uids[63] then
        temp[5] = 1
      elseif fightData.crossPKInfo.uids[66] == fightData.crossPKInfo.uids[64] then
        temp[5] = 2
      end
      table.insert(result, 1, temp)
    end
  end
  if currentTime >= AcrossFightTimeEnum.top2OverAfter then
    for _, temp in ipairs(result) do
      temp[3] = true
    end
  end
  return result
end

function AcrossFightManager.getNextCrossPkBeginTime()
  local resultTimestamp = 0
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  local selectPKListTimeItem = getTimeItem(0)
  local rewardTimeItem = getTimeItem(9)
  if curSeconds < activityBeginSeconds then
    resultTimestamp = activityBeginSeconds
  else
    local activityRound = math.ceil((curSeconds - activityBeginSeconds) / seconds_per_week)
    local roundOffset = math.floor((activityRound - 1) / 2)
    local curRoundBaseSeconds = activityBeginSeconds + roundOffset * seconds_per_week * 2
    if curSeconds < (curRoundBaseSeconds + (selectPKListTimeItem.crossServerBegin + selectPKListTimeItem.crossServerContinue) * seconds_per_min) then
      resultTimestamp = curRoundBaseSeconds
    else
      resultTimestamp = curRoundBaseSeconds + seconds_per_week * 2
    end
  end
  
  return TimeUtil.getDateInServertime(resultTimestamp + (selectPKListTimeItem.crossServerBegin + selectPKListTimeItem.crossServerContinue) * seconds_per_min)
end

function AcrossFightManager.getCurrentOrNextCrossPkTimeTable()
  local roundBaseSeconds
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  local timeItems = {}
  for i = 0, 9 do
    timeItems[i] = getTimeItem(i)
  end
  if curSeconds < activityBeginSeconds then
    roundBaseSeconds = activityBeginSeconds
  else
    local activityRound = math.ceil((curSeconds - activityBeginSeconds) / seconds_per_week)
    local roundOffset = math.floor((activityRound - 1) / 2)
    local curRoundBaseSeconds = activityBeginSeconds + roundOffset * seconds_per_week * 2
    if curSeconds < (curRoundBaseSeconds + (timeItems[9].crossServerBegin + timeItems[9].crossServerContinue) * seconds_per_min) then
      roundBaseSeconds = curRoundBaseSeconds
    else
      roundBaseSeconds = curRoundBaseSeconds + seconds_per_week * 2
    end
  end
  
  local result = {}
  local tempTime
  
  tempTime =  roundBaseSeconds + (timeItems[0].crossServerBegin + timeItems[0].crossServerContinue) * seconds_per_min
  result[1] = TimeUtil.getDateInServertime(tempTime)
  result[2] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[1].crossServerBegin * seconds_per_min
  result[3] = TimeUtil.getDateInServertime(tempTime)
  result[4] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[1].crossServerBegin + timeItems[1].crossServerContinue) * seconds_per_min
  result[5] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[2].crossServerBegin * seconds_per_min
  result[6] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[2].crossServerBegin + timeItems[2].crossServerContinue) * seconds_per_min
  result[7] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[3].crossServerBegin * seconds_per_min
  result[8] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[3].crossServerBegin + timeItems[3].crossServerContinue) * seconds_per_min
  result[9] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[4].crossServerBegin * seconds_per_min
  result[10] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[4].crossServerBegin + timeItems[4].crossServerContinue) * seconds_per_min
  result[11] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[6].crossServerBegin * seconds_per_min
  result[12] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[6].crossServerBegin + timeItems[6].crossServerContinue) * seconds_per_min
  result[13] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + timeItems[9].crossServerBegin * seconds_per_min
  result[14] = TimeUtil.getDateInServertime(tempTime)
  tempTime =  roundBaseSeconds + (timeItems[9].crossServerBegin + timeItems[9].crossServerContinue) * seconds_per_min
  result[15] = TimeUtil.getDateInServertime(tempTime)
  
  return result
end

function AcrossFightManager.getCurrentCrossPkRewardTime()
  local result = {num1 = 0, num2 = 0, num3 = 0, num4 = 0, num5 = 0, num6 = 0}
  if AcrossFightManager.isOpen() then
    local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
    local curSeconds = TimeUtil.getServerTimeSeconds()
    local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
    local rewardTimeItem = getTimeItem(9)
    local activityRound = math.ceil((curSeconds - activityBeginSeconds) / seconds_per_week)
    local roundOffset = math.floor((activityRound - 1) / 2)
    local curRoundBaseSeconds = activityBeginSeconds + roundOffset * seconds_per_week * 2
    local rewardStartTime = TimeUtil.getDateInServertime(curRoundBaseSeconds + rewardTimeItem.crossServerBegin * seconds_per_min)
    local rewardEndTime = TimeUtil.getDateInServertime(curRoundBaseSeconds + (rewardTimeItem.crossServerBegin + rewardTimeItem.crossServerContinue) * seconds_per_min)
    result.num1 = rewardStartTime.month
    result.num2 = rewardStartTime.day
    result.num3 = rewardStartTime.hour
    result.num4 = rewardEndTime.month
    result.num5 = rewardEndTime.day
    result.num6 = rewardEndTime.hour
  end
  return result
end

function AcrossFightManager.isOpen()
  if not AcrossFightManager.whetherCrossPkExistInServer() then
    return false, true
  end
  
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local curSeconds = TimeUtil.getServerTimeSeconds()
  local activityBeginSeconds = MaintenanceManager:getStartAndEndTime(crossServerSettingConfig.crossServerFeatureName)[1].activityBeginTimeStamp
  if curSeconds < activityBeginSeconds then
    return false
  end
  --print(curSeconds .. "_" .. beginSeconds .. "=" .. (curSeconds-beginSeconds))
  local activityRound = math.ceil((curSeconds - activityBeginSeconds) / seconds_per_week)
  if math.mod(activityRound, 2) == 0 then
    return false
  end
  
  local curRoundBaseSeconds = activityBeginSeconds + seconds_per_week * math.floor((curSeconds - activityBeginSeconds) / seconds_per_week)
  local selectPKListTimeItem = getTimeItem(0)
  local rewardTimeItem = getTimeItem(9)
  if not (curSeconds >= (curRoundBaseSeconds + (selectPKListTimeItem.crossServerBegin + selectPKListTimeItem.crossServerContinue) * seconds_per_min + 5) and curSeconds <= (curRoundBaseSeconds + (rewardTimeItem.crossServerBegin + rewardTimeItem.crossServerContinue) * seconds_per_min)) then
    return false
  end
  
  return true
end

function AcrossFightManager.whetherCrossPkExistInServer()
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  if not crossServerSettingConfig then
    return false
  end
  
  local existed = false
  local curServerId = tonumber(string.sub(DataManager.getCurrUser().uid, -4, -1))
  --print(crossServerSettingConfig.crossServerGroups)
  --print(table.tostring(crossServerSettingConfig.crossServerGroups))
  for _, aCrossServerGroup in ipairs(crossServerSettingConfig.crossServerGroups) do
    local serverIds = aCrossServerGroup.serverIds:split(",")
    for _, aServerId in ipairs(serverIds) do
      if tonumber(aServerId) == curServerId then
        existed = true
        break
      end
    end
    if existed then
      break
    end
  end
  if not existed then
    return false
  end
  
  return true
end


---------------------------------------------------
--武道会逻辑
---------------------------------------------------

function AcrossFightManager.isPkOpen()
  if not DataManager.GameMetaData.pkSettingConfig
    or (not MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
    and not MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNameGainReward))
    then
    return false
  else
    return true
  end
end

function AcrossFightManager.whetherInPkDoingTime()
  if not DataManager.GameMetaData.pkSettingConfig then
    return false
  end
  if MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession) then
    return true
  else
    return false
  end
end

function AcrossFightManager.whetherInPkRewardTime()
  if not DataManager.GameMetaData.pkSettingConfig then
    return false
  end
  if MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNameGainReward) then
    return true
  else
    return false
  end
end


