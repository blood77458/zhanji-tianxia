-- UnionPkConfig.lua
-- 2014-7-30
-- zheng.hce
-- 军团战相关配置管理

UnionPkConfig = {}

----------------------------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------------------------
function UnionPkConfig.startup()
	
end
function UnionPkConfig.clear()
	
end

----------------------------------------------------------------------------------------
-- 通用配置
----------------------------------------------------------------------------------------

--获得军团战通用配置
function UnionPkConfig.getSettingConfig()
	local config = DataManager.GameMetaData.unionWarSettingConfig
	return config
end

--获得占领城池上限
function UnionPkConfig.cityOccupyLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityOccupyLimit
end

--获得报名城池上限
function UnionPkConfig.citySignLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.citySignLimit
end

--获得城防加成
function UnionPkConfig.cityDefenceBuff()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityDefenceBuff
end

--连续占领每次降低
function UnionPkConfig.continueOccupyDown()
	local config = UnionPkConfig.getSettingConfig()
	return config.continueOccupyDown
end

--团战参加奖奖励id(无需判断历史职位 需求by mingyang @ 2014-10-30)
function UnionPkConfig.joinWarReward()
	local config = UnionPkConfig.getSettingConfig()
	return config.joinWarReward
end

--城池攻击方人数上限
function UnionPkConfig.cityAttNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityAttNum
end

--城池防御方人数上限
function UnionPkConfig.cityDefenceNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityDefenceNum
end

--银币攻防buff
function UnionPkConfig.silverBuff()
	local config = UnionPkConfig.getSettingConfig()
	return getFloatNumber(config.silverBuff) * 100
end

--金币攻防buff
function UnionPkConfig.goldBuff()
	local config = UnionPkConfig.getSettingConfig()
	return getFloatNumber(config.goldBuff) * 100
end

--银币鼓舞上限
function UnionPkConfig.silverBuffNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.silverBuffNum
end

--金币鼓舞上限
function UnionPkConfig.goldBuffNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.goldBuffNum
end

--奋力一击上限
function UnionPkConfig.striveNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.striveNum
end

--团战最大连胜
function UnionPkConfig.winLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.winLimit
end

--城池npc防守怪物组<CityNpcGroup> list
-- <bean>
-- 	<property code="id" type="int" desc="城池类型"/>
-- 	<property code="monsterGroupId" type="int" desc="怪物组id"/>
-- </bean>
function UnionPkConfig.npcGroupMetas()
	local config = UnionPkConfig.getSettingConfig()
	return config.npcGroupMetas
end

--团战buff;1单挑普通胜利2单挑大胜3阵首4阵中5阵尾<UnionWarBuff> list
-- <bean>
-- 	<property code="id" type="int" desc="团战buff;1单挑普通胜利2单挑大胜3阵首4阵中5阵尾"/>
-- 	<property code="attBuff" type="int" desc="攻击BUFF"/>
-- 	<property code="defBuff" type="int" desc="防御BUFF"/>
-- 	<property code="hpBuff" type="int" desc="血量BUFF"/>
-- </bean>
function UnionPkConfig.unionWarBuff()
	local config = UnionPkConfig.getSettingConfig()
	return config.unionWarBuff
end

--计算减少后的城防
function UnionPkConfig.cityDefenceBuffNow(captureTimes)
	local maxDef = UnionPkConfig.cityDefenceBuff()
	local timesDown = UnionPkConfig.continueOccupyDown()
	return maxDef - captureTimes * timesDown
end

--军团战的featurename
function UnionPkConfig.unionWarFeatureName()
	local config = UnionPkConfig.getSettingConfig()
	return config.unionWarFeatureName
end

--先锋上限
function UnionPkConfig.cityVanLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityVanLimit
end

--阵首上限
function UnionPkConfig.cityFrontLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityFrontLimit
end

--阵中上限
function UnionPkConfig.cityMidLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityMidLimit
end

--阵尾上限
function UnionPkConfig.cityLastLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityLastLimit
end

--*上阵人数上限
function UnionPkConfig.cityTotalMemberLimit()
	return UnionPkConfig.cityVanLimit() + UnionPkConfig.cityFrontLimit() + UnionPkConfig.cityMidLimit() + UnionPkConfig.cityLastLimit()
end

--银币鼓舞花费
function UnionPkConfig.silverBuffCost()
	local config = UnionPkConfig.getSettingConfig()
	return config.silverBuffCost
end

--金币鼓舞花费
function UnionPkConfig.goldBuffCost()
	local config = UnionPkConfig.getSettingConfig()
	return config.goldBuffCost
end

--奋力一击花费
function UnionPkConfig.striveCost()
	local config = UnionPkConfig.getSettingConfig()
	return config.striveCost
end

--团员参战奖奖励id
function UnionPkConfig.inBattleReward()
	local config = UnionPkConfig.getSettingConfig()
	return config.inBattleReward
end

--金币城池鼓舞上限
function UnionPkConfig.cityGoldBuffNum()
	local config = UnionPkConfig.getSettingConfig()
	return config.cityGoldBuffNum
end

--城池报名军团数上限
function UnionPkConfig.unionSignLimit()
	local config = UnionPkConfig.getSettingConfig()
	return config.unionSignLimit
end

----------------------------------------------------------------------------------------
-- 城池报名限制
----------------------------------------------------------------------------------------

--获得不同种类城池报名限制的配置表 list类型
-- <bean desc="城池报名限制配置">
-- 	<property code="cityId" type="int" desc="城池类型id"/>
-- 	<property code="signUpLevel" type="int" desc="军团等级限制"/>
-- 	<property code="signUpStrength" type="int" desc="军团战斗力限制"/>
-- </bean>
function UnionPkConfig.unionWarLimitMetas()
	local config = UnionPkConfig.getSettingConfig()
	return config.unionWarLimitMetas
end

--获得城池竞标的军团最低等级
--cityTypeId 城池类型id
function UnionPkConfig.getSignUnionLevelByCityId(cityTypeId)
	local tempList = UnionPkConfig.unionWarLimitMetas()

	if not tempList then
		return 0
	end

	for i, v in ipairs(tempList) do
		if v.cityId == cityTypeId then
			return v.signUpLevel
		end
	end
	return 0
end

--获得城池竞标的最低总战力
--cityTypeId 城池类型id
function UnionPkConfig.getSignFightCapacityByCityId(cityTypeId)
	local tempList = UnionPkConfig.unionWarLimitMetas()

	if not tempList then
		return 0
	end

	for i, v in ipairs(tempList) do
		if v.cityId == cityTypeId then
			return v.signUpStrength
		end
	end
	return 0
end

----------------------------------------------------------------------------------------
-- 军团战server编号限制
----------------------------------------------------------------------------------------

--生效服务器 list类型
-- <bean desc="斗兽奖励分配">
-- 	<property code="serverMin" type="int" desc="生效服务器min（闭集）" />
-- 	<property code="serverMax" type="int" desc="生效服务器max（闭集）" />
-- </bean>
function UnionPkConfig.unionWarServerMetas()
	local config = UnionPkConfig.getSettingConfig()
	return config.unionWarServerMetas
end

--获得城池竞标的军团最低等级
--serverId 服务器id
function UnionPkConfig.isCorrectServer(serverId)
	local tempList = UnionPkConfig.unionWarServerMetas()
	if SystemManager.debug then
		print("serverId = " .. tostringRich(serverId))
		print("tempList = " .. tostringRich(tempList))
	end

	if not tempList then
		return false
	end

	for i, v in ipairs(tempList) do
		if serverId >= v.serverMin and serverId <= v.serverMax then
			return true
		end
	end
	
	return false
end

----------------------------------------------------------------------------------------
-- 奖励配置
----------------------------------------------------------------------------------------

--获得军团战奖励配置
function UnionPkConfig.getRewardConfig()
	local config = DataManager.GameMetaData.unionWarRewardConfig
	return config
end

--军团战奖励Config<UnionWarRewardMeta> dic
-- <bean>
-- 	<property code="cityId" type="int" desc="城市类型id"/>
-- 	<property code="dailyProfit1" type="int" desc="奖励1"/>
-- 	<property code="dailyProfit2" type="int" desc="奖励2"/>
-- 	<property code="dailyProfit3" type="int" desc="奖励3"/>
-- 	<property code="cityOccupyReward" type="int" desc="城市占领奖励"/>
-- </bean>
function UnionPkConfig.unionWarRewardMeta()
	local config = UnionPkConfig.getRewardConfig()
	return config.unionWarRewardMeta
end

--通过城池id获得每日奖励 -1表示没有奖励
--targeTitle 目标职位(不传表示历史职位)
function UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(cityId, targeTitle)
	if not targeTitle then
		targeTitle = UnionPkData.getHistoryTitle()
	end
	local config = UnionPkConfig.unionWarRewardMeta()
	local cityType = UnionPkUtils.getCityTypeById(cityId)
	local cityRewards = config[cityType]

	if targeTitle == UnionManager.TITLE_MANAGER then
		return cityRewards.dailyProfit1
	elseif targeTitle == UnionManager.TITLE_VICE_MANAGER then
		return cityRewards.dailyProfit1
	elseif targeTitle == UnionManager.TITLE_ELITE_MEMBER then
		return cityRewards.dailyProfit2
	elseif targeTitle == UnionManager.TITLE_MEMBER then
		return cityRewards.dailyProfit3
	end

	--默认情况 当时没有进军团的玩家返回这个
	return -1
end

--通过城池id获得防守奖励
function UnionPkConfig.getMyHistoryTitleDefenceRewardByCityId(cityId)
	local myHistoryTitle = UnionPkData.getHistoryTitle()
	if myHistoryTitle == UnionManager.TITLE_NONE then
		--当时不在军团里 不给奖励
		return -1
	end

	local config = UnionPkConfig.unionWarRewardMeta()
	local cityType = UnionPkUtils.getCityTypeById(cityId)
	local cityRewards = config[cityType]

	return cityRewards.cityOccupyReward
end

----------------------------------------------------------------------------------------
-- 时间配置
----------------------------------------------------------------------------------------

--获得军团战时间配置
function UnionPkConfig.getTimeConfig()
	local config = DataManager.GameMetaData.unionWarTimeConfig
	return config
end

--军团战时间配置<UnionWarTimeMeta> list
-- <bean>
-- 	<property code="id" type="int" desc="事件id"/>
-- 	<property code="warBeginTime" type="int" desc="事件开始时间"/>
-- 	<property code="warContinueTime" type="int" desc="事件持续时间"/>
-- </bean>
function UnionPkConfig.unionWarTimeMeta()
	local config = UnionPkConfig.getTimeConfig()
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config.unionWarTimeMeta
end

function UnionPkConfig.getLevelTimeMeta(timeLevel)
	return UnionPkConfig.unionWarTimeMeta()[timeLevel]
end