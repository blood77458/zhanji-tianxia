-- CrossUnionPkTimeLevel.lua
-- meilan.xie
-- 2015-4-14
-- 跨服GVG 开时间段

CrossUnionPkTimeLevel = {}

CrossUnionPkTimeLevel.TimeLevel = nil
CrossUnionPkTimeLevel.tickEntry = nil

-------------------------------------------------
-- 操作
-------------------------------------------------

--每秒tick
	function CrossUnionPkTimeLevel.onTick()
		
		local tempTimeLevel = CrossUnionPkData.getCurrTimeLevel()
		-- print("~~~~~~~~~~~~~~~~~~~~~~tempTimeLevel = "..tempTimeLevel)
		-- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~CrossUnionPkTimeLevel.TimeLevel ="..CrossUnionPkTimeLevel.TimeLevel)
		if tempTimeLevel ~= CrossUnionPkTimeLevel.TimeLevel then
			CrossUnionPkTimeLevel.TimeLevel = tempTimeLevel
			--通知更新
			-- print("通知更新")
			UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED))
		end

		
	end

function CrossUnionPkTimeLevel.startup(timelevel)
    CrossUnionPkTimeLevel.TimeLevel = timelevel
    -- print("~~~~~~~~~~~~~~~~~~~CrossUnionPkTimeLevel.TimeLevel = "..CrossUnionPkTimeLevel.TimeLevel)
	CrossUnionPkTimeLevel.tickEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(CrossUnionPkTimeLevel.onTick, 1, false)--间隔1s
end

function CrossUnionPkTimeLevel.clear()
	CrossUnionPkTimeLevel.TimeLevel = nil
	if CrossUnionPkTimeLevel.tickEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CrossUnionPkTimeLevel.tickEntry)
	end
end