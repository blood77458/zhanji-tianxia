-- CrossUnionPkConfig.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG相关配置管理

CrossUnionPkConfig = {}

----------------------------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------------------------
function CrossUnionPkConfig.startup()
	
end
function CrossUnionPkConfig.clear()
	
end

--试用
--奖励预览配置
--获得军团战通用配置
function CrossUnionPkConfig.getRewardConfig()
	local config = DataManager.GameMetaData.wgvgRewardConfig
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config
end

function CrossUnionPkConfig.getGVGRewardMetas()
	local config = CrossUnionPkConfig.getRewardConfig()
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config.wGVGRewardMetas))
    return config.wGVGRewardMetas
end
--获得军团战通用配置
function CrossUnionPkConfig.getSettingConfig()
	local config = DataManager.GameMetaData.wgvgTotalConfig
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config
end

--军团战的featurename
function CrossUnionPkConfig.unionWarFeatureName()
	local config = CrossUnionPkConfig.getSettingConfig()

	return config.featureName
end

----------------------------------------------------------------------------------------
-- 时间配置
----------------------------------------------------------------------------------------

--获得军团战时间配置
function CrossUnionPkConfig.getTimeConfig()
	local config = DataManager.GameMetaData.crossGvgTimeConfig  --修改名字
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config
end

--军团战时间配置<interUnionWarTimeMeta> list
-- <bean>
-- 	<property code="id" type="int" desc="事件id"/>
-- 	<property code="warBeginTime" type="int" desc="事件开始时间"/>
-- 	<property code="warContinueTime" type="int" desc="事件持续时间"/>
-- </bean>
function CrossUnionPkConfig.interUnionWarTimeMeta()
	local config = CrossUnionPkConfig.getTimeConfig()
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config.interUnionWarTimeMeta
end

function CrossUnionPkConfig.getLevelTimeMeta(timeLevel)
	return CrossUnionPkConfig.interUnionWarTimeMeta()[timeLevel]
end

function CrossUnionPkConfig.CrossunionWarServerMetas()
	local config = DataManager.GameMetaData.wgvgTotalConfig
	return config.crossServerGroupMetas
end

--serverId 服务器id
function CrossUnionPkConfig.isCorrectServer(serverId)
	local tempList = CrossUnionPkConfig.CrossunionWarServerMetas()
	if SystemManager.debug then
		print("serverId = " .. tostringRich(serverId))
		print("tempList = " .. tostringRich(tempList))
	end

   
	if not tempList then
		return false
	end

	for i= 1 ,#tempList do
		for _,id in ipairs(tempList[i].serverIdList) do
			if id == serverId then
				return true
			end
		end
	end
	
	return false
end