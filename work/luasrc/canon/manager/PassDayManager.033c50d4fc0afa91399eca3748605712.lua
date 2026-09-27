--
-- PassDayManager.lua
-- Author: zheng.che
-- Date: 2014-04-28 15:44:42
-- 跨天管理
--

PassDayManager = {}

----------------------------------------------------------------------------------------------------------------------------------枚举

--聊天相关事件
PassDayManager.PASS_DAY = "PASS_DAY" --跨天 无参数

----------------------------------------------------------------------------------------------------------------------------------数据

--计时器-大
PassDayManager.tickEntryBig = nil
--计时器-小
PassDayManager.tickEntrySmall = nil

PassDayManager.targetTime = 0

----------------------------------------------------------------------------------------------------------------------------------初始化

--控制器初始化
function PassDayManager.startup()
	PassDayManager.targetTime = TimeUtil.getTodayTimestampBy(0, 0, 0) + TimeUtil.DAY

	if not PassDayManager.tickEntryBig then
		PassDayManager.tickEntryBig = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(PassDayManager.tickBig, 30, false)--间隔30s
		PassDayManager.tickBig()
	end
end

----------------------------------------------------------------------------------------------------------------------------------对外接口

--获得今天的标记数值(用来比较是否跨天)
function PassDayManager.getTodayMark()
	return PassDayManager.targetTime
end

----------------------------------------------------------------------------------------------------------------------------------私有

function PassDayManager.tickBig()
	local currentTime = TimeUtil.getServerTimeSeconds()
	local diff = PassDayManager.targetTime - currentTime
	--print("currentTime = " .. currentTime)
	if SystemManager.debugPassDay then
		print("timeTickBig! diff = " .. diff)
	end
	if diff <= 90 then
		--开始小计时
		if not PassDayManager.tickEntrySmall then
			PassDayManager.tickEntrySmall = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(PassDayManager.tickSmall, 1, false)--间隔1s
			PassDayManager.tickSmall()
		end
	end
	-- 延迟五秒触发
	if diff + 5 < 0 then
		--垮了个天
		PassDayManager.dayPassed()
	end
end

function PassDayManager.tickSmall()
	local currentTime = TimeUtil.getServerTimeSeconds()
	local diff = PassDayManager.targetTime - currentTime
	if SystemManager.debugPassDay then
		print("timeTickSmall! diff = " .. diff)
	end
	-- 延迟五秒触发
	if diff + 5 <= 0 then
		--垮了个天
		PassDayManager.dayPassed()
	end
end

--跨天了
function PassDayManager.dayPassed()
	print("dayPassed!!")
	--停止小计时
	if PassDayManager.tickEntrySmall then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(PassDayManager.tickEntrySmall)
		PassDayManager.tickEntrySmall = nil
	end

	--设定新的目标时间为今天0点+一天
	PassDayManager.targetTime = TimeUtil.getTodayTimestampBy(0, 0, 0) + TimeUtil.DAY

	--通知外界跨天了
	NotificationManager:dispatchEvent(Event.new(PassDayManager.PASS_DAY))
end