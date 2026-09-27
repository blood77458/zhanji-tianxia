-- UnionPkUtils.lua
-- 2014-8-5
-- zheng.che
-- 军团战相关工具函数

UnionPkUtils = {}

--获得城池类型
function UnionPkUtils.getCityTypeById(cityId)
	--大
	if (cityId >= UnionPkConsts.bigCityStartNum) and (cityId < UnionPkConsts.midCityStartNum) then
		return UnionPkConsts.CITY_TYPE_BIG
	end

	--中
	if (cityId >= UnionPkConsts.midCityStartNum) and (cityId < UnionPkConsts.smallCityStartNum) then
		return UnionPkConsts.CITY_TYPE_MIDDLE
	end

	--小
	return UnionPkConsts.CITY_TYPE_SMALL
end

--获得城池名称
function UnionPkUtils.getCityNameById(cityId)
	local cityType = UnionPkUtils.getCityTypeById(cityId)
	--大
	if cityType == UnionPkConsts.CITY_TYPE_BIG then
		return Localization:getInstance():getText("UnionWar_city_big")
	end

	--中
	if cityType == UnionPkConsts.CITY_TYPE_MIDDLE then
		return Localization:getInstance():getText("UnionWar_city_middle" .. (cityId - UnionPkConsts.midCityStartNum + 1))
	end

	--小
	local smallCityNum = cityId - UnionPkConsts.smallCityStartNum + 1
	return Localization:getInstance():getText("UnionWar_city_small", {num1 = smallCityNum})--军粮库{num1}区
end

--获得城池默认守城NPC军团名称
function UnionPkUtils.getCityNpcNameById(cityId)
	local cityType = UnionPkUtils.getCityTypeById(cityId)
	--大
	if cityType == UnionPkConsts.CITY_TYPE_BIG then
		return Localization:getInstance():getText("UnionWar_npc_name1")--洛阳守军
	end

	--中
	if cityType == UnionPkConsts.CITY_TYPE_MIDDLE then
		return Localization:getInstance():getText("UnionWar_npc_name2")--NPC守军
	end

	--小
	return Localization:getInstance():getText("UnionWar_npc_name3")--军粮库守军
end

--获得城池默认守城NPC卡牌名称
function UnionPkUtils.getCityCardNpcNameById(cityId)
	local cityType = UnionPkUtils.getCityTypeById(cityId)
	--大
	if cityType == UnionPkConsts.CITY_TYPE_BIG then
		return Localization:getInstance():getText("UnionWar_npc_name1")--洛阳守军
	end

	--中
	if cityType == UnionPkConsts.CITY_TYPE_MIDDLE then
		return Localization:getInstance():getText("UnionWar_npc_name2")--NPC守军
	end

	--小
	return Localization:getInstance():getText("UnionWar_npc_name3")--军粮库守军
end

--通过挑战军团数据获得军团名称
function UnionPkUtils.getCityNpcNameByUnionCityApplyData(unionCityApplyData, cityId)
	--print("unionCityApplyData = " .. tostringRich(unionCityApplyData))
	if not unionCityApplyData then
		--不存在(理论不应出现)
		return UnionPkUtils.getCityNpcNameById(cityId)
	end
	if unionCityApplyData.unionId == 0 then
		--是npc守军
		return UnionPkUtils.getCityNpcNameById(cityId)
	end
	--正常返回名称
	return unionCityApplyData.unionName
end

--获得现在所处时间区间
function UnionPkUtils.findCurrentTimeLevel()
	local currTime = TimeUtil.getServerTimeSeconds()
	local lastestStartTime = UnionPkUtils.findLatestBeginTime()
	local gapTime = currTime - lastestStartTime

	-- print("currTime = " .. tostringRich(currTime))
	-- print("lastestStartTime = " .. tostringRich(lastestStartTime))
	-- print("gapTime = " .. tostringRich(gapTime))
	for i=UnionPkConsts.MAX_TIMES, 1, -1 do
		--print("i = " .. i)
		local timeLevelMeta = UnionPkConfig.getLevelTimeMeta(i)
		local warBeginTime = timeLevelMeta.warBeginTime * 60
		local warEndTime = warBeginTime + timeLevelMeta.warContinueTime * 60
		-- print("timeLevelMeta = " .. tostringRich(timeLevelMeta))
		-- print("warBeginTime = " .. tostringRich(warBeginTime))
		-- print("warEndTime = " .. tostringRich(warEndTime))
		-- print("------------------------------------------------")
		if gapTime >= warBeginTime and gapTime < warEndTime then
			return i
		end
	end

	--默认为领奖时间
	return UnionPkConsts.TIME_REWARD
end

--更新版本号
function UnionPkUtils.refreshVersion()
	local currTime = TimeUtil.getServerTimeSeconds()
	if currTime > UnionPkData.reversionEndTime then
		--尝试匹配版本号

		--计算得到当前版本号
		--获得第一届的开启时间
		local startAndEndTimeTable = MaintenanceManager:getStartAndEndTime(UnionPkConfig.unionWarFeatureName())
		
		local featureStartTime = startAndEndTimeTable[1].activityBeginTimeStamp

		--获得最近一届开启时间
		local featureLastestStartTime = UnionPkUtils.findLatestBeginTime()
		--活动起始时间和当前的时间差 用于计算客户端版本号(后端版本号计算规则: 以maintenance里配的时间为准)
		local gap = currTime - featureStartTime
		local currVersion = math.ceil(gap / TimeUtil.WEEK)
		--服务器版本号
		local serverVersion = UnionManager.getUnionWarVersion()

		--更新到期时间(定位到下个时段的起始时间 如果是最后一个时段 就定位到下轮开启时间)
		local currentTimeLevel = UnionPkUtils.findCurrentTimeLevel()
		--设置最新的时间段
		UnionPkData.setCurrTimeLevel(currentTimeLevel)

		if currentTimeLevel > 0 and currentTimeLevel < UnionPkConsts.MAX_TIMES then
			--军团战进行中 不是最后一个阶段 只需要得到下一段开始时间即可
			local nextLevelTimeMeta = UnionPkConfig.getLevelTimeMeta(currentTimeLevel + 1)
			local nextLevelStartTime = featureLastestStartTime + nextLevelTimeMeta.warBeginTime * 60

			UnionPkData.reversionEndTime = nextLevelStartTime
		else
			--边界情况 需要考虑跨届
			--第一阶段的数据 用它的开启时间来计算真实的下一届军团战开始时刻(因为featureLastestStartTime的时间必定是0点而实际开始时间与第一阶段配置有关)
			local firstLevelTimeMeta = UnionPkConfig.getLevelTimeMeta(1)
			UnionPkData.reversionEndTime = featureLastestStartTime + firstLevelTimeMeta.warBeginTime*60 + TimeUtil.WEEK
		end


		if SystemManager.debug then
			print("--------------------------------------------------------更新版本号↓")
			print("currTime = " .. tostringRich(currTime))
			print("featureStartTime = " .. tostringRich(featureStartTime))
			print("featureLastestStartTime = " .. tostringRich(featureLastestStartTime))
			print("gap = " .. tostringRich(gap))
			print("currentTimeLevel = " .. tostringRich(currentTimeLevel))
			print("UnionPkData.reversionEndTime = " .. tostringRich(UnionPkData.reversionEndTime))
			print("currVersion = " .. tostringRich(currVersion))
		end

		if currVersion ~= serverVersion then
			--更新版本号
			if SystemManager.debug then
				print("currVersion ~= serverVersion!!")
			end
			UnionManager.setUnionWarVersion(currVersion)
			
			--版本号匹配失败 清除版本信息
			UnionManager.setChallengeCityId(0)--设为没有报名


			--轮数改为默认数值
			UnionManager.setUnionWarRound(1)

			--清除城池标记
			UnionPkData.clearMarkHash()

			--清除鼓舞次数
			UnionManager.setCoinInspireNum(0)
			UnionManager.setStriveInspireNum(0)
			UnionManager.setGemInspireNum(0)
		end

		local newRound = UnionPkUtils.findCurrentRoundByTimeLevel(currentTimeLevel)
		local currRound = UnionManager.getUnionWarRound()

		if SystemManager.debug then
			print("newRound = " .. tostringRich(newRound))
			print("currRound = " .. tostringRich(currRound))
			print("--------------------------------------------------------更新版本号↑")
		end
		
		if newRound ~= currRound then
			--轮数改为默认数值
			UnionManager.setUnionWarRound(newRound)
		end

		--只要更新时间段就要清除的数据
		--清空鼓舞提示状态
		UnionPkData.setPowerupSilverConfirmed(false)
		UnionPkData.setPowerupGoldConfirmed(false)
	end
end

--计算得到军团战真实首次开战时间 (区别于maintenance配置的时间)
function UnionPkUtils.findRealUnionPkMainStartTime()
	--获得第一届的开启时间
	local startAndEndTimeTable = MaintenanceManager:getStartAndEndTime(UnionPkConfig.unionWarFeatureName())
	local featureStartTime = startAndEndTimeTable[1].activityBeginTimeStamp

	local firstTimeLevelMeta = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_SELECT)
	-- print("featureStartTime = " .. tostringRich(featureStartTime))
	-- print("firstTimeLevelMeta.warBeginTime = " .. tostringRich(firstTimeLevelMeta.warBeginTime))
	local pkStartTime = featureStartTime + firstTimeLevelMeta.warBeginTime * 60
	return pkStartTime
end

--计算得到最近一次军团战的真实开始时间 (区别于maintenance配置的时间)
function UnionPkUtils.findRealLatestStartTime()
	--print("UnionPkConfig.unionWarFeatureName() = " .. tostringRich(UnionPkConfig.unionWarFeatureName()))
	local lastestFeatureStartTime = UnionPkUtils.findLatestBeginTime()
	local firstTimeLevelMeta = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_SELECT)
	local pkStartTime = lastestFeatureStartTime + firstTimeLevelMeta.warBeginTime * 60
	return pkStartTime
end

--获得当前轮数 如果不在某一轮时间内 返回-1
function UnionPkUtils.findCurrentRoundByTimeLevel(timeLevel)
	if timeLevel == UnionPkConsts.TIME_SELECT then
		--报名阶段
		return -1
	elseif timeLevel == UnionPkConsts.TIME_SELECTING then
		--等待竞标结果阶段
		return -1
	elseif timeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
		--团员参与阶段
		return -1
	elseif timeLevel == UnionPkConsts.TIME_ROUND1_FORM then
		--第一轮调整阵型
		return 1
	elseif timeLevel == UnionPkConsts.TIME_ROUND1_FIGHT then
		--第一轮团战时间
		return 1
	elseif timeLevel == UnionPkConsts.TIME_ROUND2_FORM then
		--第二轮调整阵型
		return 2
	elseif timeLevel == UnionPkConsts.TIME_ROUND2_FIGHT then
		--第二轮等待结果
		return 2
	elseif timeLevel == UnionPkConsts.TIME_REWARD then
		--战后领奖阶段
		return -1
	else
		--都不是
		return -1
	end
	return -1
end

--计算得到某一时间段的起始时间和结束时间
function UnionPkUtils.findTImeLevelStartAndEndTime(timeLevel)
	local lastestStartTime = UnionPkUtils.findLatestBeginTime()
	local timeMeta = UnionPkConfig.getLevelTimeMeta(timeLevel)
	local startTime = lastestStartTime + timeMeta.warBeginTime * 60
	local endTime = startTime + timeMeta.warContinueTime * 60
	return startTime, endTime
end

--计算得到当前奖励数量
function UnionPkUtils.findRewardNum()
	local result = 0
	for i=1,UnionPkConsts.REWARD_MAX_COUNT do
		if UnionPkCheck.canGetReward(i) then
			result = result + 1
		end
	end
	return result
end

function UnionPkUtils.isShineUnionBtnWhenInUnionPKTime()
	if not UnionManager.isInUnion() then
		return false
	end
	if UnionPkData.getUnionWarLightOnWhenIsRightTime() then
		return false
	end
	local curTimeLevel = UnionPkUtils.findCurrentTimeLevel()--modified by zheng.che @ 2014-10-29 当前接口被调用的时候过早了 改成直接强制计算得到当前时间段
	if curTimeLevel >= UnionPkConsts.TIME_SELECTING and curTimeLevel < UnionPkConsts.TIME_REWARD then
		return true
	end
	return false
end

--返回"xx月xx日 xx:xx"
function UnionPkUtils.formatDate(timestamp)
	return TimeUtil.formatDate(timestamp, "UnionWar_sign_time3")
end



--最近一轮开启时间(0点时间)
function UnionPkUtils.findLatestBeginTime()
  local config = MaintenanceManager:findActivityConfig(UnionPkConfig.unionWarFeatureName())
  --print("config = " .. tostringRich(config))
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
    return 0
  end

  if config.activityDate == 0 then
    --每天开启 暂不处理 如需处理可加代码
    return 0
  else
    if config.activityUnite == 1 then
      --每天开启 暂不处理 如需处理可加代码
      return 0
    elseif config.activityUnite == 2 then
      --每周开启
      local gap = currTime - activityBeginTimeStamp
      --已经是第几周
      local weekCount = math.floor(gap / TimeUtil.WEEK)
      --剩余时间
      local remainTimeSec = math.mod(gap, TimeUtil.WEEK)
      -- print("weekCount = " .. tostringRich(weekCount))
      -- print("remainTimeSec = " .. tostringRich(remainTimeSec))
      local result = activityBeginTimeStamp + weekCount * TimeUtil.WEEK
      --第一阶段时间配置
      local selectTimeMeta = UnionPkConfig.getLevelTimeMeta(1)
      if remainTimeSec <= selectTimeMeta.warBeginTime * 60 then
        result = result - TimeUtil.WEEK
      end

      return result
    elseif config.activityUnite == 3 then
      --每月开启 暂不处理 如需处理可加代码
      return 0
    end 
  end 

  return 0
end

-------------------------------------------------
-- 获得军团动态文字内容 军团战大类型的解析
-- newsType 动态类型
-- detailData 后端返回的详细信息json
-------------------------------------------------
function UnionPkUtils.getNewsStr(newsType, detailData)
	local _json = require("cjson")
	detailData = _json.decode(detailData)

	if newsType == UnionPkConsts.WAR_NEWS_TYPE_PREPARE then
		--{creatorNickname：xxx, unionName:xxx}
		return Localization:getInstance():getText("union_dynamic_content1", {name = detailData.creatorNickname, name2 = detailData.unionName})--yyy
	elseif newsType == UnionPkConsts.WAR_NEWS_TYPE_DEFENSE then
		--{nickname:xxx}
		return Localization:getInstance():getText("xxx", {name = detailData.nickname})--yyy
	elseif newsType == UnionPkConsts.WAR_NEWS_TYPE_BID then
		--{nickname:xxx}
		return Localization:getInstance():getText("xxx", {name = detailData.nickname})--yyy
	elseif newsType == UnionPkConsts.WAR_NEWS_TYPE_OCCUPY then
		--{nickname:xxx}
		return Localization:getInstance():getText("xxx", {name = detailData.nickname})--yyy
	end
	return ""
end