--------------------------------------------------------------------------------
-- MaintenanceManager.lua -- 活动开关管理
-- author: Dang Chao && Jiang Yize
-- date: 2013-10-29
--------------------------------------------------------------------------------

MaintenanceManager = {}

local TIME_SECONDS_PER_DAY = 86400
local TIME_MINUTES_PER_HOUR = 60
local TIME_SECONDS_PER_MINUTE = 60
local TIME_DAY_PER_WEEK = 7

MaintenanceManager.ActivityOnOffConfigData = {}
function MaintenanceManager.getActivityOnOffConfigData()
  return MaintenanceManager.ActivityOnOffConfigData
end 

-- 判断活动是否开启
-- activityName：活动名称
-- timeStamp：时间戳
function MaintenanceManager.isOpen(activityName, timeStamp)
  local isOpenTime = false
  local isEnable = false
  local curState = 0 
  local curServerTimeStamp = timeStamp
  local lastestStartTime = 0--最近一轮开启时间

  --之前的用法不符合时区标准 改为新用法 by zheng.che @ 2014-5-23
  --local curServerTimeStampTable = os.date("*t",curServerTimeStamp)
  local currentDate = TimeUtil.getDateInServertime(curServerTimeStamp)

  --这段没有用到 原因未知 先隐藏了 by zheng.che @ 2014-5-23
  -- local curServerDateList = os.date("%x",curServerTimeStamp)
  -- curServerDateList = curServerDateList:split("/")
  -- local curServerTimeList = os.date("%X",curServerTimeStamp)
  -- curServerTimeList = curServerTimeList:split(":")
  
  if not MaintenanceManager.ActivityOnOffConfigData then
    he_log_warning("MaintenanceManager.ActivityOnOffConfigData is nil")
    return isEnable,isOpenTime,curServerTimeStamp,curState,lastestStartTime
  end
  
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    -- if v.name == "activityDoubleSilver" then
    --   print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!v.name = " .. tostringRich(v.name))
    -- end
    if v.name == activityName and v.enable then
      --print("v.name = " .. tostringRich(v.name))
      local activityBeginDateList = v.beginTime:split(" ")[1]:split("/")
      local activityEndDateList = v.endTime:split(" ")[1]:split("/")
      local activityBeginTimeList = v.beginTime:split(" ")[2]:split(":")
      local activityEndTimeList = v.endTime:split(" ")[2]:split(":")
                
      local activityBeginTimeStamp = TimeUtil.toServerTimestamp({day=activityBeginDateList[3], month=activityBeginDateList[2],year=activityBeginDateList[1], hour=activityBeginTimeList[1], min=activityBeginTimeList[2], sec=0}) 
      local activityEndTimeStamp = TimeUtil.toServerTimestamp({day=activityEndDateList[3], month=activityEndDateList[2],year=activityEndDateList[1], hour=activityEndTimeList[1], min=activityEndTimeList[2], sec=0}) 
      
      ------------------------
      --during the activity open date
      ------------------------
      if curServerTimeStamp >= activityBeginTimeStamp and curServerTimeStamp <= activityEndTimeStamp then
        --------------------------
        --during the activity open time
        --------------------------
        local function isDuringTodayOpenTime()
          local isDuring = false
          local beginHour = v.activityOpen:split(":")[1]
          local beginMin = v.activityOpen:split(":")[2]
          local beginStamp = TimeUtil.toServerTimestamp({day=currentDate.day,month=currentDate.month,year=currentDate.year,hour=beginHour,min=beginMin})
          local lastHour = v.activityDuring / 60
          local lastMin = v.activityDuring % 60
          local endStamp = beginStamp + v.activityDuring*60
          
          if beginStamp <= curServerTimeStamp and  curServerTimeStamp <= endStamp then
            isDuring = true
            curState = 1
          elseif beginStamp > curServerTimeStamp then
            curState = 0
          else
            curState = 2
          end 
          return isDuring
        end 
        
        -- 以一轮活动为单位，判断当前时间是否处在活动开启时间内
        -- baseTimeSeconds: 本轮活动起始时间（某天0点时间戳）
        local function isInTodayActivityTime(baseTimeSeconds)
          local activityOpenHour = v.activityOpen:split(":")[1]
          local activityOpenMinute = v.activityOpen:split(":")[2]
          local activityOpenTimeSeconds = baseTimeSeconds + (activityOpenHour * TIME_MINUTES_PER_HOUR + activityOpenMinute) * TIME_SECONDS_PER_MINUTE
          local activityCloseTimeSeconds = activityOpenTimeSeconds + v.activityDuring * TIME_SECONDS_PER_MINUTE
          
          if curServerTimeStamp >= activityOpenTimeSeconds and curServerTimeStamp <= activityCloseTimeSeconds then
            return true, activityOpenTimeSeconds, activityCloseTimeSeconds
          end
          return false, 0, 0
        end
        
        -- 开启方式为以天为单位循环的活动，判断是否在活动时间
        local function isInActivityTimePerDay()
          -- 合法的活动起始时间戳 
          local beginDateTimestamp = TimeUtil.toServerTimestamp({day = activityBeginDateList[3], month = activityBeginDateList[2], year = activityBeginDateList[1], hour = 0})
          local todayTimestamp = TimeUtil.toServerTimestamp({day = currentDate.day, month = currentDate.month, year = currentDate.year, hour = 0})
          local daysPerRound = v.activityDate + 1
          local gapDay = math.floor((todayTimestamp - beginDateTimestamp) / TIME_SECONDS_PER_DAY)
          local curOpenRound = math.floor(gapDay / daysPerRound)
          local isOpenDay = (gapDay % daysPerRound == 0)
          
          if isOpenDay and curOpenRound >= 1 then -- 今天恰巧是一轮活动开启的第一天，先判断以今天为起点的一轮活动是否开启
            local baseTimestamp = beginDateTimestamp + (curOpenRound - 1) * daysPerRound * TIME_SECONDS_PER_DAY
            local result, resultBegin, resultEnd = isInTodayActivityTime(baseTimestamp)
            if result then
              return result, resultBegin, resultEnd
            end
          end
          
          -- 普通情况，找到最近的上一轮活动的开启起始时间，判断最近的上一轮活动是否开启
          local baseTimestamp = beginDateTimestamp + curOpenRound * daysPerRound * TIME_SECONDS_PER_DAY
          --print(baseTimestamp)
          return isInTodayActivityTime(baseTimestamp)
        end
        
        -- 开启方式为以星期为单位循环的活动，判断是否在活动时间
        local function isInActivityTimePerWeek()
          local curDayOfWeek = currentDate.wday
          local openDayOfWeek = (v.activityDate) % TIME_DAY_PER_WEEK + 1
          local baseTimestamp = TimeUtil.toServerTimestamp({day = currentDate.day, month = currentDate.month, year = currentDate.year, hour = 0})
          
          if curDayOfWeek == openDayOfWeek then
            local result, resultBegin, resultEnd = isInTodayActivityTime(baseTimestamp)
            if result then
              return result, resultBegin, resultEnd
            end
            -- 上一轮活动为整一周以前，计算出上一轮活动起始时间
            baseTimestamp = baseTimestamp - TIME_DAY_PER_WEEK * TIME_SECONDS_PER_DAY
          else
            -- 上一轮活动为 (curDayOfWeek+7-openDayOfWeek)%7，计算出上一轮活动起始时间
            local gapDay = (curDayOfWeek + TIME_DAY_PER_WEEK - openDayOfWeek) % TIME_DAY_PER_WEEK
            local gapSecond = gapDay * TIME_SECONDS_PER_DAY
            baseTimestamp = baseTimestamp - gapSecond
          end
          
          -- 判断上一轮活动是否仍在开启
          if baseTimestamp >= TimeUtil.toServerTimestamp({day = activityBeginDateList[3], month = activityBeginDateList[2], year = activityBeginDateList[1], hour = 0}) then
            return isInTodayActivityTime(baseTimestamp)
          else
            return false, 0, 0
          end
        end
        
        -- 开启方式为以月为单位循环的活动，判断是否在活动时间
        local function isInActivityTimePerMonth()
          local dayOfMonth = currentDate.day
          local openDayOfMonth = v.activityDate
          local baseTimestamp = TimeUtil.toServerTimestamp({day = currentDate.day, month = currentDate.month, year = currentDate.year, hour = 0})
          
          if dayOfMonth == openDayOfMonth then -- 今天恰巧是一轮活动开启的第一天，先判断以今天为起点的一轮活动是否开启
            local result, resultBegin, resultEnd = isInTodayActivityTime(baseTimestamp)
            if result then
              return result, resultBegin, resultEnd
            end
          end
          
          -- 普通情况，找到最近的上一轮活动的开启起始时间，判断最近的上一轮活动是否开启
          local baseYear = currentDate.year
          local baseMonth = currentDate.month
          if dayOfMonth < openDayOfMonth then
            if baseMonth == 1 then
              baseMonth = 12
              baseYear = baseYear - 1
            else
              baseMonth = baseMonth - 1
            end
          end
          
          local baseTimestamp = TimeUtil.toServerTimestamp({day = openDayOfMonth, month = baseMonth, year = baseYear, hour = 0})
          if baseTimestamp >= TimeUtil.toServerTimestamp({day = activityBeginDateList[3], month = activityBeginDateList[2], year = activityBeginDateList[1], hour = 0}) then
            return isInTodayActivityTime(baseTimestamp)
          else
            return false, 0, 0
          end
        end
        
        if v.activityDate == 0 then
          isOpenTime = isDuringTodayOpenTime()
          isEnable = true
        else
          if v.activityUnite == 1 then
            local result, resultBegin, resultEnd = isInActivityTimePerDay()
            if result then
              isOpenTime = true
              isEnable = true
            end
          elseif v.activityUnite == 2 then
            local result, resultBegin, resultEnd = isInActivityTimePerWeek()
            if result then
              isOpenTime = true
              isEnable = true
              lastestStartTime = resultBegin
            end
          elseif v.activityUnite == 3 then
            local result, resultBegin, resultEnd = isInActivityTimePerMonth()
            if result then
              isOpenTime = true
              isEnable = true
            end
          end 
        end 
      end
    end 
  end 
  
  return isEnable,isOpenTime,curServerTimeStamp,curState,lastestStartTime
end

-- 判断活动当前是否开启
-- activityName：活动名称
function MaintenanceManager.isActivityOpen(activityName)
  return MaintenanceManager.isOpen(activityName, TimeUtil.getServerTimeSeconds())
end

-- 判断是否已经过了活动的关闭时间
-- activityName：活动名称

function MaintenanceManager.isActivityAlreadyClose(activityName)
  local localTimeStamp = TimeUtil.getServerTimeSeconds()
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      local activityEndDateList = v.endTime:split(" ")[1]:split("/")
      local activityEndTimeList = v.endTime:split(" ")[2]:split(":")
      local activityEndTimeStamp = TimeUtil.toServerTimestamp({day=activityEndDateList[3], month=activityEndDateList[2],year=activityEndDateList[1], hour=activityEndTimeList[1], min=activityEndTimeList[2], sec=0}) 
      if localTimeStamp >= activityEndTimeStamp then
        return true
      else
        local leftTimeStamp = activityEndTimeStamp - localTimeStamp
        return false, leftTimeStamp, tonumber(activityEndDateList[2]), tonumber(activityEndDateList[3]), tonumber(activityEndTimeList[1]), activityEndDateList[1]
      end
      break
    end
  end
  return true
end

function MaintenanceManager:getStartAndEndTime(activityName)
  local result = {}
  --print("MaintenanceManager.ActivityOnOffConfigData = " .. table.tostring(MaintenanceManager.ActivityOnOffConfigData))
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      local aStartTimeTable = {}
      local activityStartDateList = v.beginTime:split(" ")[1]:split("/")
      aStartTimeTable.year = activityStartDateList[1]
      aStartTimeTable.month = activityStartDateList[2]
      aStartTimeTable.day = activityStartDateList[3]
      aStartTimeTable.time = v.beginTime:split(" ")[2]
      aStartTimeTable.activityBeginTimeStamp = TimeUtil.toServerTimestamp({day=aStartTimeTable.day , month=aStartTimeTable.month,year=aStartTimeTable.year, hour=aStartTimeTable.time:split(":")[1], min=aStartTimeTable.time:split(":")[2], sec=0}) 
      result[1] = aStartTimeTable
      
      local aEndTimeTable = {}
      local activityEndDateList = v.endTime:split(" ")[1]:split("/")
      aEndTimeTable.year = activityEndDateList[1]
      aEndTimeTable.month = activityEndDateList[2]
      aEndTimeTable.day = activityEndDateList[3]
      aEndTimeTable.time = v.endTime:split(" ")[2]
      aEndTimeTable.activityEndTimeStamp = TimeUtil.toServerTimestamp({day=aEndTimeTable.day, month=aEndTimeTable.month,year=aEndTimeTable.year, hour=aEndTimeTable.time:split(":")[1], min=aEndTimeTable.time:split(":")[2], sec=0}) 
      result[2] = aEndTimeTable
            
      break
    end
  end
  return result
end

function MaintenanceManager.isStarted(activityName)
  local startAndEndTime = MaintenanceManager:getStartAndEndTime(activityName)
  if not startAndEndTime then
    return false
  end
  local localTimeStamp = TimeUtil.getServerTimeSeconds()
  if localTimeStamp < startAndEndTime[1].activityBeginTimeStamp then
    return false
  end
  return true
end

function MaintenanceManager:getStartAndEndHourMinOfOneDay(activityName)
  local result = {beginHour = 0, beginMin = 0, endHour = 0, endMin = 0}
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      result.beginHour = tonumber(v.activityOpen:split(":")[1])
      result.beginMin = tonumber(v.activityOpen:split(":")[2])
      local duringMin = tonumber(v.activityDuring)
      result.endHour = result.beginHour + math.modf((result.beginMin + duringMin) / 60)
      result.endMin = math.mod(result.beginMin + duringMin, 60)
      break
    end
  end
  return result
end

function MaintenanceManager:getActivityDuring( activityName )
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      return v.activityDuring
    end
  end
  return 0
end

function MaintenanceManager:getActivityOpen( activityName )
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      local beginHour = v.activityOpen:split(":")[1]
      local beginMin = v.activityOpen:split(":")[2]
      return beginHour * 60 * 60 + beginMin * 60
    end
  end
  return 0
end

--通过名称查询活动配置 若没有返回nil
function MaintenanceManager:findActivityConfig(activityName)
  if not MaintenanceManager.ActivityOnOffConfigData then
    he_log_warning("MaintenanceManager.ActivityOnOffConfigData is nil")
    return nil
  end
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do
    if v.name == activityName then 
      return v
    end
  end
  return nil
end

--通过名称查询活动开启时间是星期几(0-6 = Sunday-Saturday)
function MaintenanceManager:getActivityBeginWeekday(activityName)
  local config = MaintenanceManager:findActivityConfig(activityName)
  if not config then
    return 0
  end
  if config.beginTimeWeekday == nil then
    local activityBeginDateList = config.beginTime:split(" ")[1]:split("/")
    config.beginTimeWeekday = TimeUtil.getWeekday(activityBeginDateList[1], activityBeginDateList[2], activityBeginDateList[3])
  end

  return config.beginTimeWeekday
end

function MaintenanceManager:getActivityBeginAndEndTimeButThisActivityIsOpenEveryWeek(activityName)
  local result = {}
  --print("MaintenanceManager.ActivityOnOffConfigData = " .. table.tostring(MaintenanceManager.ActivityOnOffConfigData))
  for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
    if v.name == activityName then
      local aStartTimeTable = {}
      local activityStartDateList = v.beginTime:split(" ")[1]:split("/")
      aStartTimeTable.year = activityStartDateList[1]
      aStartTimeTable.month = activityStartDateList[2]
      aStartTimeTable.day = activityStartDateList[3]
      aStartTimeTable.time = v.beginTime:split(" ")[2]
      aStartTimeTable.activityBeginTimeStamp = TimeUtil.toServerTimestamp({day=aStartTimeTable.day , month=aStartTimeTable.month,year=aStartTimeTable.year, hour=aStartTimeTable.time:split(":")[1], min=aStartTimeTable.time:split(":")[2], sec=0}) 
      -- result[1] = aStartTimeTable

      local currentTime = TimeUtil.getServerTimeSeconds()
      local ver = math.modf((currentTime - aStartTimeTable.activityBeginTimeStamp) / (TIME_SECONDS_PER_DAY * TIME_DAY_PER_WEEK))
      local beginHour = v.activityOpen:split(":")[1]
      local beginMin = v.activityOpen:split(":")[2]
      local newBeginTimeStamp = aStartTimeTable.activityBeginTimeStamp + ver * TIME_SECONDS_PER_DAY * TIME_DAY_PER_WEEK + beginHour * 3600 + beginMin * 60
      local newEndTimeStamp = newBeginTimeStamp + v.activityDuring * 60
      result[1]= os.date("*t",newBeginTimeStamp)
      result[2]= os.date("*t",newEndTimeStamp)
      
      -- local aEndTimeTable = {}
      -- local activityEndDateList = v.endTime:split(" ")[1]:split("/")
      -- aEndTimeTable.year = activityEndDateList[1]
      -- aEndTimeTable.month = activityEndDateList[2]
      -- aEndTimeTable.day = activityEndDateList[3]
      -- aEndTimeTable.time = v.endTime:split(" ")[2]
      -- aEndTimeTable.activityEndTimeStamp = TimeUtil.toServerTimestamp({day=aEndTimeTable.day, month=aEndTimeTable.month,year=aEndTimeTable.year, hour=aEndTimeTable.time:split(":")[1], min=aEndTimeTable.time:split(":")[2], sec=0}) 
      -- result[2] = aEndTimeTable
            
      break
    end
  end
  return result
end