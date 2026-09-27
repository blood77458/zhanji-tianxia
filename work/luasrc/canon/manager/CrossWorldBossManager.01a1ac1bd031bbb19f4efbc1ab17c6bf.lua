require "hecore.display.CocosObject"
CrossWorldBossManager = {}

function CrossWorldBossManager.getCrossBossGoldBattleConfig()
	return DataManager.GameMetaData.crossBossGoldBattleConfig or {}
end

function CrossWorldBossManager.getCrossBossHeroConfig()
	return DataManager.GameMetaData.crossBossHeroConfig or {}
end

function CrossWorldBossManager.getCrossBossRewardConfig()
	return DataManager.GameMetaData.crossBossRewardConfig or {}
end

function CrossWorldBossManager.getCrossBossSettingConfig()
	return DataManager.GameMetaData.crossBossSettingConfig or {}
end

-- local godHeros = {}

function CrossWorldBossManager.getGodHerosByVersion(version)
	local godHeros = {}
	local allHeros = CrossWorldBossManager.getCrossBossHeroConfig()

	for k,v in pairs(allHeros.heros) do
		if version >= v.beginVersion and version <= v.endVersion then
			table.insert(godHeros , {metaId = v.heroMetaId0 , isActive = false})
			table.insert(godHeros , {metaId = v.heroMetaId1 , isActive = false})
			table.insert(godHeros , {metaId = v.heroMetaId2 , isActive = false})
			table.insert(godHeros , {metaId = v.heroMetaId3 , isActive = false})
			break
		end
	end

	for k, aCardId in pairs(CommonManager:getEffectCardQueue()) do
		local metaGroup = CommonManager:getCardMetaByCardId(aCardId).cardGroupId
		for i=1,#godHeros do
			heroMetaGroup = MetaManager.card_meta[godHeros[i].metaId].cardGroupId
			if heroMetaGroup == metaGroup then
				godHeros[i].isActive = true
			end
		end
	end
	return godHeros
end

function CrossWorldBossManager.getGodHerosIncreaseValue(version)
	local value = 0
	local setting = CrossWorldBossManager.getCrossBossSettingConfig()
	local godHeros = CrossWorldBossManager.getGodHerosByVersion(version)
	for i=1,#godHeros do
		if godHeros[i].isActive then
			value = value + setting.heroAtkAddtion
		end
	end
	local curStar = (version%4) + 1
	if godHeros[curStar].isActive then
		value = value + setting.heroExtraAtkAddtion
	end
	return value
end

function CrossWorldBossManager.getSpecialHero( version )
	local godHeros = CrossWorldBossManager.getGodHerosByVersion(version)
	local curStar = (version%4) + 1
	return godHeros[curStar]
end

function CrossWorldBossManager.getNormalHeros( version )
	local godHeros = CrossWorldBossManager.getGodHerosByVersion(version)
	local normalHeros = {}
	local curStar = (version%4) + 1
	for i=1,4 do
		if i ~= curStar then
			table.insert(normalHeros , godHeros[i])
		end
	end
	return normalHeros
end

function CrossWorldBossManager.getWitchInfos()
	local setting = CrossWorldBossManager.getCrossBossSettingConfig()
	local witchs  = setting.witchInfos
	return witchs
end

function CrossWorldBossManager.getWitchByType( witchType )
	local witchs = CrossWorldBossManager.getWitchInfos()
	for k,v in pairs(witchs) do
		if v.type == witchType then
			return v
		end
	end
end


function CrossWorldBossManager.getChallengeCostAndTimes()
	local function getExtraBattleNumsAndCost()
		local vipLevel = DataManager.getCurrUser().vipLevel
		local crossBossGoldBattleConfig = CrossWorldBossManager.getCrossBossGoldBattleConfig()
		local isFind = false
		local battleNum = 0
		for k,v in pairs(crossBossGoldBattleConfig.extraBattleNums) do
			if vipLevel >= v.minVipLevel and vipLevel <= v.maxVipLevel then
				isFind = true
				battleNum = v.battleNum
				break
			end
		end
		local cost = 0
		local crossBossTimes = DailyDataManager.getCrossBossTimes()
		local freeDailyBattleNum = CrossWorldBossManager.getCrossBossSettingConfig().freeDailyBattleNum
		local challendgedNum = (crossBossTimes - freeDailyBattleNum) + 1
		if isFind then
			for k,v in pairs(crossBossGoldBattleConfig.extraBattleCosts) do
				if challendgedNum >= v.minTime and challendgedNum <= v.maxTime then
					cost = v.goldCost
					break
				end
			end
		end
		return battleNum ,cost
	end
	local crossBossTimes = DailyDataManager.getCrossBossTimes()
	local freeDailyBattleNum = CrossWorldBossManager.getCrossBossSettingConfig().freeDailyBattleNum
	if crossBossTimes < freeDailyBattleNum then
		return 0 , (freeDailyBattleNum - crossBossTimes)
	else
		local num , cost = getExtraBattleNumsAndCost()
		return cost , (num + freeDailyBattleNum - crossBossTimes)
	end
end

function CrossWorldBossManager.checkCrossDay()
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local currentTime = TimeUtil.getServerTimeSeconds()
	local featureNamePrepare = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNamePrepare)
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameBattle)
	local featureNameReward = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameReward)
-- activityBeginTimeStamp
-- activityEndTimeStamp
	if currentTime >= featureNameBattle[1].activityBeginTimeStamp and currentTime <= featureNameBattle[2].activityEndTimeStamp then
		return 1
	elseif currentTime >= featureNameReward[1].activityBeginTimeStamp and currentTime <= featureNameReward[2].activityEndTimeStamp then
		return 2
	end
end

function CrossWorldBossManager.getPrepareEndTime(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNamePrepare = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNamePrepare)
	local oepn = MaintenanceManager:getActivityOpen( crossBossSettingConfig.featureNamePrepare )
	local activityDuring = MaintenanceManager:getActivityDuring( crossBossSettingConfig.featureNamePrepare )

	return featureNamePrepare[1].activityBeginTimeStamp + activityDuring * 60 + (version -1) * 604800 + oepn
end

function CrossWorldBossManager.getPrepareEndTimeTxt( version )
	local endTimeStamp = CrossWorldBossManager.getPrepareEndTime(version)
	return string.sub(TimeUtil.formatDateOutPutChineseData(endTimeStamp) , 1, -4)
end

function CrossWorldBossManager.getPrepareEndTimeWeekdayText(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNamePrepare = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNamePrepare)
	return string.sub(TimeUtil.getWeekdayTextByTimeStamp(CrossWorldBossManager.getPrepareEndTime(version)) , 1 , -4)
end

function CrossWorldBossManager.getBattleEndTime(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameBattle)
	local activityDuring = MaintenanceManager:getActivityDuring( crossBossSettingConfig.featureNameBattle )
	local oepn = MaintenanceManager:getActivityOpen( crossBossSettingConfig.featureNameBattle )
	return featureNameBattle[1].activityBeginTimeStamp  + activityDuring * 60 + oepn + (version -1) * 604800
end

function CrossWorldBossManager.getBattleBeginTimeTxt( version )
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameBattle)
	local activityDuring = MaintenanceManager:getActivityDuring( crossBossSettingConfig.featureNameBattle )
	local beginStamp = featureNameBattle[1].activityBeginTimeStamp + (version -1) * 604800
	return string.sub(TimeUtil.formatDateOutPutChineseData(beginStamp) , 1,-4)
end

function CrossWorldBossManager.getBattleEndTimeTxt( version )
	local endTimeStamp = CrossWorldBossManager.getBattleEndTime(version)
	return string.sub(TimeUtil.formatDateOutPutChineseData(endTimeStamp) , 1,-4)
	-- return TimeUtil.formatDateOutPutChineseData(endTimeStamp)
end

function CrossWorldBossManager.getBattleEndTimeWeekdayText(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameBattle)
	return TimeUtil.getWeekdayTextByTimeStamp(CrossWorldBossManager.getBattleEndTime(version))
end

function CrossWorldBossManager.getRewardEndTime(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNamePrepare = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNamePrepare)

	return featureNamePrepare[1].activityBeginTimeStamp + (7*24*60*60) + (version -1) * 604800
end

function CrossWorldBossManager.getRewardEndTimeTxt( version )
	local endTimeStamp = CrossWorldBossManager.getRewardEndTime(version)
	return string.sub(TimeUtil.formatDateOutPutChineseData(endTimeStamp) , 1 , -4)
end

function CrossWorldBossManager.getRewardEndTimeWeekdayText(version)
	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()
	local featureNameReward = MaintenanceManager:getStartAndEndTime(crossBossSettingConfig.featureNameReward)
	return TimeUtil.getWeekdayTextByTimeStamp(CrossWorldBossManager.getRewardEndTime(version))
end

function CrossWorldBossManager.getEndTimeByCurrentStage( stage , version)
	if stage == 0 then
		return CrossWorldBossManager.getPrepareEndTime(version)
	elseif stage == 1 then
		return CrossWorldBossManager.getBattleEndTime(version)
	elseif stage == 2 then
		return CrossWorldBossManager.getRewardEndTime(version)
	end
end

function CrossWorldBossManager.getInsprieValue()
	return CrossWorldBossManager.insprireValue or 0
end

function CrossWorldBossManager.setInsprieValue(v)
	CrossWorldBossManager.insprireValue = v
end

function CrossWorldBossManager.getIsInCrossBossLayer()
	return CrossWorldBossManager.isInCrossBossLayer or false
end

function CrossWorldBossManager.setIsInCrossBossLayer(s)
	CrossWorldBossManager.isInCrossBossLayer = s
end