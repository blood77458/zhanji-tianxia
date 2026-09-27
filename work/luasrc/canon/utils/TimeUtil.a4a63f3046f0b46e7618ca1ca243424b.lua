--------------------------------------------------------------------------------
-- TimeUtil.lua - 精英关卡相关的常量及存储结构
-- author: xiaojie.bai
-- date: 2013-09-26 11:20
--------------------------------------------------------------------------------

TimeUtil = class()

--后端所在时区
TimeUtil.SERVER_TIMEZONE = 8

TimeUtil.DAY = 86400
TimeUtil.WEEK = TimeUtil.DAY * 7
--------------------
-- 获取客户端时间与服务器时间差值
------
-- 说明：只有在用Request通信后才有效
--------------------
function TimeUtil.getUtcDiffSeconds()
  return _G.__g_utcDiffSeconds
end

--------------------
-- 获取服务器当前时间
------
-- 说明：只有在用Request通信后才有效
--   若Request通信后，用户手动改了手机时间
--   则需要再次Request通信更新时间信息
--------------------
function TimeUtil.getServerTimeSeconds()
  local utcDiffSeconds = 0
  if(_G.__g_utcDiffSeconds) then
    utcDiffSeconds = _G.__g_utcDiffSeconds
  end
  g_curServerTimeStamp = os.time() + utcDiffSeconds
  return os.time() + utcDiffSeconds + SystemManager.offsetTimeSec
end

----------------------------------------
-- 将秒时转换为 hh:mm:ss 格式
----------------------------------------
function TimeUtil.formatTime( timeNum )
  local aTime = {hh = 0, mm = 0, ss = 0}
  aTime.ss = math.mod(timeNum,60) 
  timeNum = math.modf(timeNum/60)
  aTime.mm = math.mod(timeNum,60)
  timeNum = math.modf(timeNum/60)
  aTime.hh = timeNum
  
  return "" .. (((aTime.hh>=10) and aTime.hh) or "0"..aTime.hh) .. ":" .. (((aTime.mm>=10) and aTime.mm) or "0"..aTime.mm) .. ":" .. (((aTime.ss>=10) and aTime.ss) or "0"..aTime.ss)
end

----------------------------------------
-- 将秒时转换为 hh:mm 格式
----------------------------------------
function TimeUtil.formatTimeWithHM( timeNum )
  local aTime = {hh = 0, mm = 0, ss = 0}
  aTime.ss = math.mod(timeNum,60) 
  timeNum = math.modf(timeNum/60)
  aTime.mm = math.mod(timeNum,60)
  timeNum = math.modf(timeNum/60)
  aTime.hh = timeNum
  
  return "" .. (((aTime.hh>=10) and aTime.hh) or "0"..aTime.hh) .. ":" .. (((aTime.mm>=10) and aTime.mm) or "0"..aTime.mm)
end

----------------------------------------
-- 将秒时转换为 hh:mm:ss 格式
----------------------------------------
function TimeUtil.formatTimeWithoutHour( timeNum )
  local aTime = {mm = 0, ss = 0}
  aTime.ss = math.mod(timeNum,60) 
  timeNum = math.modf(timeNum/60)
  aTime.mm = math.mod(timeNum,60)
  
  return "" .. (((aTime.mm>=10) and aTime.mm) or "0"..aTime.mm) .. ":" .. (((aTime.ss>=10) and aTime.ss) or "0"..aTime.ss)
end

----------------------------------------
-- 根据秒时间获取时、分、秒
----------------------------------------
function TimeUtil.getHourMinSec(timeNum)
  local aTime = {hh = 0, mm = 0, ss = 0}
  aTime.ss = math.mod(timeNum, 60) 
  timeNum = math.modf(timeNum / 60)
  aTime.mm = math.mod(timeNum, 60)
  timeNum = math.modf(timeNum / 60)
  aTime.hh = timeNum
  return aTime.hh, aTime.mm, aTime.ss
end
----------------------------------------
-- If switch day, return true; otherwise, return false
----------------------------------------
function TimeUtil.whetherSwitchDay(oldTime)
  local oldDateTable = os.date("*t", oldTime)
  local oldYear = oldDateTable.year
  local oldMonth = oldDateTable.month
  local oldDay = oldDateTable.day
  local oldTotalSeconds = os.time{year=oldYear,month=oldMonth,day=oldDay,hour=0}
  
  local currentTime = TimeUtil.getServerTimeSeconds()
  local currentDateTable = os.date("*t", currentTime)
  local currentYear = currentDateTable.year
  local currentMonth = currentDateTable.month
  local currentDay = currentDateTable.day
  local currentTotalSeconds = os.time{year=currentYear,month=currentMonth,day=currentDay,hour=0}
  
  local aOffsetDays = (currentTotalSeconds - oldTotalSeconds) / (24 * 3600)
  if not (aOffsetDays > -0.1 and aOffsetDays < 0.1) then
    return true
  end
  return false
end

----------------------------------------
-- If switch gain-arena-rank-score day, return true; otherwise, return false
----------------------------------------
function TimeUtil.whetherSwitchGainArenaRankScoreDay(scoreRequestTimeStamp)
  local old_request_server_seconds = scoreRequestTimeStamp
  --print("____old_request_server_seconds:" .. old_request_server_seconds)
  if old_request_server_seconds > -0.01 and old_request_server_seconds < 0.01 then
    --print("____true")
    return true
  end
  
  local oldDateTable = os.date("*t", old_request_server_seconds)
  local oldYear = oldDateTable.year
  local oldMonth = oldDateTable.month
  local oldDay = oldDateTable.day
  local tempTotalSeconds = os.time{year=oldYear,month=oldMonth,day=oldDay,hour=DataManager.GameMetaData.battleSettingConfig.arenaRewardTime}
  if tempTotalSeconds > old_request_server_seconds then
    tempTotalSeconds = tempTotalSeconds - 24 * 3600
  end
  local currentTime = TimeUtil.getServerTimeSeconds()
  --print("____currentTime:" .. currentTime)
  if currentTime - tempTotalSeconds >= 24 * 3600 then
    --print("____true")
    return true
  end
  
  return false
end

function TimeUtil.getYmd()
  local timeSeconds = TimeUtil.getServerTimeSeconds()
  return os.date("%Y%m%d", timeSeconds)
end

function TimeUtil.calcPassedDays(timeNum)
	local hours = TimeUtil.getHourMinSec(timeNum) + 8
	return math.floor(hours / 24)
end

function TimeUtil.isFirstMin(timeNum)
	local ret = false
	local hours, mins = TimeUtil.getHourMinSec(timeNum)
	if mins == 0 then
		hours = hours + 8 - 24 * math.floor((hours + 8) / 24)
		if hours == 0 then
			ret = true
		end
	end
	return ret
end

local serverTimeChecked = false
local totalTimeDiff = 0 --和标准时区时间差
--获得和后端时区时间差
function TimeUtil.getTimeZoneTotalDiffSecWithServer()
  if not serverTimeChecked then
    --只计算一次
    serverTimeChecked = true

    --方案1--
    -- local TT = os.time({year = 1970, month = 1, day = 2, hour = 0, min = 0, sec = 0, isdst = true})--若标准时间则应该是24h
  
    -- if TT == nil then
    --   --不使用夏令时
    --   print("TimeUtil.getTimeZoneTotalDiffSecWithServer 不使用夏令时!")
    --   TT = os.time({year = 1970, month = 1, day = 2, hour = 0, min = 0, sec = 0})
    -- end

    -- if TT == nil then
    --   --极端情况
    --   TT = 0
    -- end

    -- --print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<TT = " .. TT)
    -- totalTimeDiff = 24*3600 - TT - TimeUtil.SERVER_TIMEZONE*3600 -- UTC时间+8小时转为东八区北京时间(服务器所在地)

    --方案2--
    local current = os.time()
    local ut = os.date("!*t", current)
    ut.isdst = true
    local temp = os.time(ut)
    if temp == nil then
      --不使用夏令时
      print("TimeUtil.getTimeZoneTotalDiffSecWithServer 不使用夏令时!")
      ut.isdst = false
      temp = os.time(ut)
    end
    local diff = current - temp --当前设备所在时区和格林威治时区相差的秒数(例: +8时区则为 8*3600)
    totalTimeDiff = diff - TimeUtil.SERVER_TIMEZONE*3600 --和服务器时区相差秒数(目前服务器在+8区 将来服务器要提供区号或秒数)

    if SystemManager.debug then
      --只在debug模式打印
      print("totalTimeDiff/3600 = " .. tostringRich(totalTimeDiff/3600))
    end
  end

  return totalTimeDiff
end
----------------------------------------
-- 计算server所在时区的时间戳(目前固定为+8小时)
-- osTimeParams table 和os.time()中的参数一致
----------------------------------------
function TimeUtil.toServerTimestamp(osTimeParams)
  osTimeParams.isdst = true--每次计算强制使用夏令时
  local tt = os.time(osTimeParams)

  if tt == nil then
    --不使用夏令时
    print("TimeUtil.toServerTimestamp 不使用夏令时!")
    osTimeParams.isdst = false
    tt = os.time(osTimeParams)
  end

  if tt == nil then
    --极端情况
    tt = 0
  end
  local serverLocalTimestamp = tt + TimeUtil.getTimeZoneTotalDiffSecWithServer()
  return serverLocalTimestamp
end

----------------------------------------
-- 通过秒数获得整数小时
-- sec 持续秒数
----------------------------------------
function TimeUtil.getHoursBySec(sec)
  local hours = sec / 3600
  return math.floor(hours)
end

----------------------------------------
-- 通过秒数获得相差天数
-- lastTimeSec 用于比较的目标时刻 从1970开始秒数
----------------------------------------
function TimeUtil.getPasseddDaysToNow(lastTimeSec)
  local lastDays = TimeUtil.calcPassedDays(lastTimeSec)
  local nowDays = TimeUtil.calcPassedDays(TimeUtil.getServerTimeSeconds())
  -- print("lastDays = " .. lastDays)
  -- print("nowDays = " .. nowDays)
  local result = math.floor(nowDays - lastDays)
  if result < 0 then
    result = 0
  end
  return result
end

----------------------------------------
-- 通过时间戳获得显示时间 例:2014-04-04 11:15:13
-- timeNum (server所在时区对应的)时间戳 单位:秒
-- formatTxt 多语言编号 对应多语言里应包含{year}{month}{day}{hour}{min}{sec}中的若干种参数
-- otherTxtParams (可nil) 其他需要替换文本的参数集, 如: {num1=100}
----------------------------------------
function TimeUtil.formatDate(timeNum, formatTxt, otherTxtParams)
  local noTimezoneTime = timeNum + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)
  local Year = dateTable.year
  local Month = ((dateTable.month>=10) and dateTable.month) or "0"..dateTable.month
  local Day = ((dateTable.day>=10) and dateTable.day) or "0"..dateTable.day

  local daySecond = math.mod(noTimezoneTime, 3600*24)

  if formatTxt then
    local hh, mm, ss = TimeUtil.getHourMinSec(daySecond)
    hh = ((hh>=10) and hh) or "0"..hh
    mm = ((mm>=10) and mm) or "0"..mm
    ss = ((ss>=10) and ss) or "0"..ss
    local txtParams = {year=Year, month=Month, day=Day, hour=hh, min=mm, sec=ss}
    if otherTxtParams then
      txtParams = table.union(txtParams, otherTxtParams)
    end
    return Localization:getInstance():getText(formatTxt, txtParams)
  end

  --"yyyy-mm-dd hh:mm:ss"
  return Year.."-"..Month.."-"..Day.." "..TimeUtil.formatTime(daySecond)
end

function TimeUtil.formatDateOutPutChineseData(timeNum, formatTxt, otherTxtParams)
  local noTimezoneTime = timeNum + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)
  local Year = dateTable.year
  local Month = ((dateTable.month>=10) and dateTable.month) or "0"..dateTable.month
  local Day = ((dateTable.day>=10) and dateTable.day) or "0"..dateTable.day

  local daySecond = math.mod(noTimezoneTime, 3600*24)

  if formatTxt then
    local hh, mm, ss = TimeUtil.getHourMinSec(daySecond)
    hh = ((hh>=10) and hh) or "0"..hh
    mm = ((mm>=10) and mm) or "0"..mm
    ss = ((ss>=10) and ss) or "0"..ss
    local txtParams = {year=Year, month=Month, day=Day, hour=hh, min=mm, sec=ss}
    if otherTxtParams then
      txtParams = table.union(txtParams, otherTxtParams)
    end
    return Localization:getInstance():getText(formatTxt, txtParams)
  end

  --"yyyy-mm-dd hh:mm:ss"
  return Year..getTextByKey("activity_consume_text7")..Month..getTextByKey("activity_consume_text8")..Day..getTextByKey("activity_consume_text9").." "..TimeUtil.formatTime(daySecond)
end

----------------------------------------
-- 获得某时间的date table(服务器所在时区)
----------------------------------------
function TimeUtil.getDateInServertime(timestamp)
  local noTimezoneTime = timestamp + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)--通过标准时区转换
  return dateTable
end

----------------------------------------
-- 获得当前时间的date table(服务器所在时区)
----------------------------------------
function TimeUtil.getCurrentDateInServertime()
  local currentTime = TimeUtil.getServerTimeSeconds()
  return TimeUtil.getDateInServertime(currentTime)
end

----------------------------------------
-- 获得某天某时刻时间戳
----------------------------------------
function TimeUtil.getTargetTimestampBy(year, month, day, h, m, s)

  if not h then
    h = 0
  end
  if not m then
    m = 0
  end
  if not s then
    s = 0
  end
  local dateTable = TimeUtil.getCurrentDateInServertime()
  dateTable.hour = h
  dateTable.min = m
  dateTable.sec = s

  if year ~= nil then
    dateTable.year = year
  end
  if month ~= nil then
    dateTable.month = month
  end
  if day ~= nil then
    dateTable.day = day
  end

  --print("dateTable = " .. table.tostring(dateTable))
  local result = TimeUtil.toServerTimestamp(dateTable)
  --print("result = " .. result)
  return result
end

----------------------------------------
-- 获得今天某时刻时间戳
----------------------------------------
function TimeUtil.getTodayTimestampBy(h, m, s)
  return TimeUtil.getTargetTimestampBy(nil, nil, nil, h, m, s)
end

----------------------------------------
-- 今天礼拜几(0-6 = Sunday-Saturday)
----------------------------------------
function TimeUtil.getTodayWeekday()
  local currentTime = TimeUtil.getServerTimeSeconds()
  local noTimezoneTime = currentTime + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)--通过标准时区转换
  --print("dateTable = " .. table.tostring(dateTable))
  return math.mod(dateTable.wday, 7)
end

----------------------------------------
-- 这天礼拜几(0-6 = Sunday-Saturday)
----------------------------------------
function TimeUtil.getWeekday(y, m, d)
  local osTimeParams = {year = y, month = m, day = d, hour = 12, min = 0, sec = 0}
  local tempTime = TimeUtil.toServerTimestamp(osTimeParams)
  local noTimezoneTime = tempTime + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)--通过标准时区转换
  -- print("dateTable = " .. table.tostring(dateTable))
  return math.mod(dateTable.wday, 7)
end

----------------------------------------
-- 这天礼拜几(0-6 = Sunday-Saturday)直接输出多语言
----------------------------------------

function TimeUtil.getWeekdayTextByTimeStamp(timestamp)
	local ret = getTextByKey("crossBoss_timeWeek")
  local noTimezoneTime = timestamp + TimeUtil.SERVER_TIMEZONE*3600--要补正才能使用标准时区转换
  local dateTable = os.date("!*t", noTimezoneTime)--通过标准时区转换
	local wDay = math.mod(dateTable.wday, 7)
	ret = ret..getTextByKey("crossBoss_timeDay_"..((wDay + 6)%7 + 1))

  	return ret
end