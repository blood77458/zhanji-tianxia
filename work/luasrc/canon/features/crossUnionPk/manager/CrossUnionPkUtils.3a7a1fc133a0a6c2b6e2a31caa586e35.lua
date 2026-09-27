-- CrossUnionPkUtils.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG相关工具函数

CrossUnionPkUtils = {}

--获得现在所处时间区间
function CrossUnionPkUtils.findCurrentTimeLevel()
	local currTime = TimeUtil.getServerTimeSeconds()
	local lastestStartTime = CrossUnionPkUtils.findLatestBeginTime()
	local gapTime = currTime - lastestStartTime

	-- print("currTime = " .. tostringRich(currTime))
	-- print("lastestStartTime = " .. tostringRich(lastestStartTime))
	-- print("gapTime = " .. tostringRich(gapTime))
	for i=CrossUnionPkConsts.MAX_TIMES, 1, -1 do
		--print("i = " .. i)
		local timeLevelMeta = CrossUnionPkConfig.getLevelTimeMeta(i)
		local warBeginTime = timeLevelMeta.uwarBeginTime * 60
		local warEndTime = warBeginTime + timeLevelMeta.uwarContinueTime * 60
		-- print("timeLevelMeta = " .. tostringRich(timeLevelMeta))
		-- print("warBeginTime = " .. tostringRich(warBeginTime))
		-- print("warEndTime = " .. tostringRich(warEndTime))
		-- print("------------------------------------------------")
		if gapTime >= warBeginTime and gapTime < warEndTime then
			return i 
		end
	end

	--默认为膜拜时间
	return  CrossUnionPkConsts.TIME_NONE --TIME_WORSHIP
end


--计算得到军团战真实首次开战时间 (区别于maintenance配置的时间)
function CrossUnionPkUtils.findRealUnionPkMainStartTime()
	--获得第一届的开启时间
	local startAndEndTimeTable = MaintenanceManager:getStartAndEndTime(CrossUnionPkConfig.unionWarFeatureName())
	local featureStartTime = startAndEndTimeTable[1].activityBeginTimeStamp

	local firstTimeLevelMeta = CrossUnionPkConfig.getLevelTimeMeta(CrossUnionPkConsts.TIME_ARMY_APPLY)
	-- print("featureStartTime = " .. tostringRich(featureStartTime))
	-- print("firstTimeLevelMeta.warBeginTime = " .. tostringRich(firstTimeLevelMeta.warBeginTime))
	local pkStartTime = featureStartTime + firstTimeLevelMeta.uwarBeginTime * 60
	return pkStartTime
end



--返回"xx月xx日 xx:xx"  
function CrossUnionPkUtils.formatDate(timestamp)
	return TimeUtil.formatDate(timestamp, "WGVG_Detail04")
end


--计算得到某一时间段的起始时间和结束时间
function CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel)
	local lastestStartTime = CrossUnionPkUtils.findLatestBeginTime()
	local timeMeta = CrossUnionPkConfig.getLevelTimeMeta(timeLevel)
	local startTime = lastestStartTime + timeMeta.uwarBeginTime * 60
	local endTime = startTime + timeMeta.uwarContinueTime * 60
	return startTime, endTime
end


function CrossUnionPkUtils.findLatestBeginTime()
  local config = MaintenanceManager:findActivityConfig(CrossUnionPkConfig.unionWarFeatureName()) --通过FeatureName 来获取配置
 
  -- print("config = " .. tostringRich(config))
  if SystemManager.debug then
    DebugManager.assert(config ~= nil, "无法找到对应的配置文件! activityName = " .. tostringRich(activityName))
  end

  local currTime = TimeUtil.getServerTimeSeconds()
  local activityBeginDateList = config.beginTime:split(" ")[1]:split("/")
  local activityBeginTimeList = config.beginTime:split(" ")[2]:split(":")

  local yy = activityBeginDateList[1]
  local mm = activityBeginDateList[2]
  local dd = activityBeginDateList[3]
  local hour = activityBeginTimeList[1]
  local min = activityBeginTimeList[2]
  local activityBeginTimeStamp = TimeUtil.toServerTimestamp({day=dd, month=mm,year=yy, hour=hour, min=min, sec=0})
  --print("activityBeginTimeStamp = " .. tostringRich(activityBeginTimeStamp))
  
  if currTime < activityBeginTimeStamp then
    --还没开始
    if SystemManager.debug then
    	print("gvg还没开始! currTime = " .. tostringRich(currTime))
    	print("gvg还没开始! activityBeginTimeStamp = " .. tostringRich(activityBeginTimeStamp))
    end
    return 0
  end

  local gap = currTime - activityBeginTimeStamp--时间间隔
  local loopTime = 2 * TimeUtil.WEEK--循环时间为两周一循环(后端写死 保持和后端一致 2015-4-22)
  local loopCount = math.floor(gap / loopTime)--循环次数
  local result = activityBeginTimeStamp + loopCount * loopTime
  return result
end

--入口按钮闪烁 
function CrossUnionPkUtils.isShineUnionBtnWhenInUnionPKTime()
	if not UnionManager.isInUnion() then
		return false
	end
	if CrossUnionPkData.getUnionWarLightOnWhenIsRightTime() then
		return false
	end
	local curTimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
	if curTimeLevel >= CrossUnionPkConsts.TIME_ARMY_APPLY  and curTimeLevel < CrossUnionPkConsts.TIME_REWARD then
		return true
	end
	return false
end

-- 得到显示区名 如: [11区]
-- serverId 区编号
function CrossUnionPkUtils.getLocationStrById(serverId)
	return "["  .. Localization:getInstance():getText("login_serverNo", {num = serverId}) .. "]"
end

-- 得到显示的军团名 如: [xx军团]
-- unionName 军团名称
function CrossUnionPkUtils.getUnionNameStrById(unionName)
	if not unionName then
		return ""
	end
	return "["  .. unionName .. "]"
end

--更新版本号
function CrossUnionPkUtils.refreshVersion()
	local currTime = TimeUtil.getServerTimeSeconds()
	if currTime > CrossUnionPkData.reversionEndTime then
		--尝试匹配版本号

		--计算得到当前版本号
		--获得第一届的开启时间
		local startAndEndTimeTable = MaintenanceManager:getStartAndEndTime(CrossUnionPkConfig.unionWarFeatureName())
		
		local featureStartTime = startAndEndTimeTable[1].activityBeginTimeStamp

		--获得最近一届开启时间
		local featureLastestStartTime = CrossUnionPkUtils.findLatestBeginTime()
		--活动起始时间和当前的时间差 用于计算客户端版本号(后端版本号计算规则: 以maintenance里配的时间为准)
		local gap = currTime - featureStartTime
		local currVersion = math.ceil(gap /(TimeUtil.WEEK*2))+1
		--服务器版本号
		local serverVersion = UnionManager.getGainCrossUnionWarIncrossGvgVersion()

		--更新到期时间(定位到下个时段的起始时间 如果是最后一个时段 就定位到下轮开启时间)
		local currentTimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
		--设置最新的时间段
		CrossUnionPkData.setCurrTimeLevel(currentTimeLevel)

		if currentTimeLevel > 0 and currentTimeLevel < CrossUnionPkConsts.MAX_TIMES then
			--军团战进行中 不是最后一个阶段 只需要得到下一段开始时间即可
			local nextLevelTimeMeta = CrossUnionPkConfig.getLevelTimeMeta(currentTimeLevel + 1)
			local nextLevelStartTime = featureLastestStartTime + nextLevelTimeMeta.uwarBeginTime * 60

			CrossUnionPkData.reversionEndTime = nextLevelStartTime
		else
			--边界情况 需要考虑跨届
			--第一阶段的数据 用它的开启时间来计算真实的下一届军团战开始时刻(因为featureLastestStartTime的时间必定是0点而实际开始时间与第一阶段配置有关)
			local firstLevelTimeMeta = CrossUnionPkConfig.getLevelTimeMeta(1)
			CrossUnionPkData.reversionEndTime = featureLastestStartTime + firstLevelTimeMeta.uwarBeginTime*60 + TimeUtil.WEEK*2
		end


		if SystemManager.debug then
			print("--------------------------------------------------------更新版本号↓")
			print("currTime = " .. tostringRich(currTime))
			print("featureStartTime = " .. tostringRich(featureStartTime))
			print("featureLastestStartTime = " .. tostringRich(featureLastestStartTime))
			print("gap = " .. tostringRich(gap))
			print("currentTimeLevel = " .. tostringRich(currentTimeLevel))
			print("UnionPkData.reversionEndTime = " .. tostringRich(CrossUnionPkData.reversionEndTime))
			print("currVersion = " .. tostringRich(currVersion))
		end

		if currVersion ~= serverVersion then
			--更新版本号
			if SystemManager.debug then
				print("currVersion ~= serverVersion!!")
			end
			UnionManager.setCrossUnionWarVersion(currVersion)
			
			-- --版本号匹配失败 清除版本信息
			-- UnionManager.setChallengeCityId(0)--设为没有报名


			

			-- --清除城池标记
			-- UnionPkData.clearMarkHash()

			-- --清除鼓舞次数
			-- UnionManager.setCoinInspireNum(0)
			-- UnionManager.setStriveInspireNum(0)
			-- UnionManager.setGemInspireNum(0)
		end


		--只要更新时间段就要清除的数据
		--清空鼓舞提示状态
		-- UnionPkData.setPowerupSilverConfirmed(false)
		-- UnionPkData.setPowerupGoldConfirmed(false)
	end
end

-- 得到显示的排名 如: 第一名
-- rank 排名数字
function CrossUnionPkUtils.getRankStr(rank)
	return getTextByKey("pk_session_rank4", {num1 = rank})--第{num1}名
end

--获得下一个时间段编号
function CrossUnionPkUtils.findNextTimeLevel(timeLevel)
	return CrossUnionPkConsts.NEXT_TIME[timeLevel]
end

--获得淘汰赛名称
--timeLevel 时间阶段编号
function CrossUnionPkUtils.getKnockoutNameByType(timeLevel)
	if timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 then
		return getTextByKey("WGVG_Name09")--十六强赛
	elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8 then
		return getTextByKey("WGVG_Name10")--八强赛
	elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4 then
		return getTextByKey("WGVG_Name11")--四强赛
	end
	return getTextByKey("WGVG_Name31")--决赛
end

function CrossUnionPkUtils.getTeamStageNameByScore( score )
	local text = {
		[1] = "WGVG_Name01",
		[2] = "WGVG_Name02",
		[3] = "WGVG_Name03",
		[4] = "WGVG_Name04",
	}

	local config = CrossUnionPkConfig.getSettingConfig().groupIntervals

	local index = 1
	for k,v in pairs(config) do
		if score >= v.regionMin and score < v.regionMax then
			index = k
		end
	end

	return getTextByKey(text[index]) 
end