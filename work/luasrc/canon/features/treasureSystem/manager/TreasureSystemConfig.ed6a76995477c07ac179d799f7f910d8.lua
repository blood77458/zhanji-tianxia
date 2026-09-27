-- TreasureSystemConfig.lua
-- meilan.xie
-- 2015-4-14
-- 宝物相关配置

TreasureSystemConfig = {}

----------------------------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------------------------
function TreasureSystemConfig.startup()
	
end
function TreasureSystemConfig.clear()
	
end

--
function TreasureSystemConfig.getTreasureSettingConfig()
	local config = DataManager.GameMetaData.treasureSettingConfig  --
	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config
end


function TreasureSystemConfig.getTreasureGoldCnfig(PotentialLevel)
	local config = MetaManager.treasure_potential_gold

	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config[PotentialLevel]
end


function TreasureSystemConfig.getTreasureSilverCnfig(PotentialLevel)
	local config = MetaManager.treasure_potential_silver

	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config[PotentialLevel]
end


function TreasureSystemConfig.getTreasureOrdinaryCnfig(PotentialLevel)
	local config = MetaManager.treasure_potential_ordinary

	-- print("~~~~~~~~~~~~~~~~~~~~~~~config = "..tostringRich(config))
	return config[PotentialLevel]
end