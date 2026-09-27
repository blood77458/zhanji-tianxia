-- TreasureSystemUtils.lua
-- meilan.xie
-- 2015-9-47
-- 宝物相关工具函数

TreasureSystemUtils = {}


--获得攻防血
function TreasureSystemUtils.CountAttandDefandHp(sharkTreasure,levels)
	local level = levels or sharkTreasure.level
		
	local treasureMate = MetaManager.treasure_meta[sharkTreasure.metaId]

	local TreasuetSettingConfig = TreasureSystemConfig.getTreasureSettingConfig()
	local treasurePotentialMate = MetaManager.treasure_potential_setting[treasureMate.rare]
	local treasureStarMate = MetaManager.treasure_star[treasureMate.rare]
    local reviseATT = treasureMate.reviseATT
    local reviseDEF = treasureMate.reviseDEF
    local reviseHP = treasureMate.reviseHP

	local initATT = treasurePotentialMate.reviseATT * treasureMate.initATT
	local initDEF = treasurePotentialMate.reviseDEF * treasureMate.initDEF
	local initHP = treasurePotentialMate.reviseHP * treasureMate.initHP
  
	local att = math.modf(reviseATT * (level + treasureStarMate.starUpLevel) + treasureMate.initATT + (treasureMate.initATT*treasurePotentialMate.reviseATT * sharkTreasure.addPotential) + (initATT*(TreasuetSettingConfig.treasurePotentialUp*0.01) * sharkTreasure.addGemPotential)) 
	local def = math.modf(reviseDEF * (level + treasureStarMate.starUpLevel) + treasureMate.initDEF + (treasureMate.initDEF*treasurePotentialMate.reviseDEF * sharkTreasure.addPotential) + ( initDEF * (TreasuetSettingConfig.treasurePotentialUp*0.01) * sharkTreasure.addGemPotential))
	local hp = math.modf(reviseHP * (level + treasureStarMate.starUpLevel) + treasureMate.initHP + (treasureMate.initDEF*treasurePotentialMate.reviseHP * sharkTreasure.addPotential) + ( initHP * (TreasuetSettingConfig.treasurePotentialUp*0.01) * sharkTreasure.addGemPotential)) 
    return hp , def , att
end

--获得攻防血强化增加值
function TreasureSystemUtils.CountAttandDefandHpAddNum(sharkTreasure)
		
	local treasureMate = MetaManager.treasure_meta[sharkTreasure.metaId]
	local attAddNum = math.modf(treasureMate.reviseATT)
	local defAddNum = math.modf(treasureMate.reviseDEF) 
	local hpAddNum = math.modf(treasureMate.reviseHP)  
    return  hpAddNum, defAddNum ,attAddNum
end


function TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(sharkTreasure,GemsAdjude)
		
	local treasureMate = MetaManager.treasure_meta[sharkTreasure.metaId]

	local TreasuetSettingConfig = TreasureSystemConfig.getTreasureSettingConfig()
	local treasurePotentialMate = MetaManager.treasure_potential_setting[treasureMate.rare]
	local GemPotential = 0
    if GemsAdjude then
      GemPotential = 1
    end
    local initATT = treasurePotentialMate.reviseATT * treasureMate.initATT
	local initDEF = treasurePotentialMate.reviseDEF * treasureMate.initDEF
	local initHP = treasurePotentialMate.reviseHP * treasureMate.initHP

	local attAddNum = math.modf(initATT + (TreasuetSettingConfig.treasurePotentialUp * 0.01* GemPotential * initATT))
	local defAddNum = math.modf(initDEF  + (TreasuetSettingConfig.treasurePotentialUp * 0.01* GemPotential * initDEF)) 
	local hpAddNum = math.modf(initHP  + (TreasuetSettingConfig.treasurePotentialUp * 0.01* GemPotential * initHP)) 
    return  hpAddNum, defAddNum ,attAddNum
end

--获得强化银币消耗值
function TreasureSystemUtils.CountCost(sharkTreasure)
		
	local treasureMate = MetaManager.treasure_strengthen[sharkTreasure.level+1]
	
	local  Cost = treasureMate.treasureUpCoin 
	 
    return Cost
end


--判断在当前潜力品阶
function TreasureSystemUtils.CheckPotentialRank(sharkTreasure)
	local MetaId = sharkTreasure.metaId
	local treasureMate = MetaManager.treasure_meta[MetaId]

	local starLevel = treasureMate.rare
	local treasureLevel = -1
	local PotentialSettingMeta = MetaManager.treasure_potential_setting
	-- if treasureMate.rare == 1 then
	-- 	treasureLevel = PotentialSettingMeta[starLevel].treasureLevel
	-- else
		for _,PotentialSetting in pairs(MetaManager.treasure_potential_setting) do
			if sharkTreasure.addPotential >= PotentialSetting.potentialNum and  sharkTreasure.addPotential <= PotentialSetting.PotentialMax then
               treasureLevel = PotentialSetting.treasureLevel
               break
			end
		end
	-- end
    return treasureLevel
end

function TreasureSystemUtils.getPotentialStone()
	local  TreasureSetting = TreasureSystemConfig.getTreasureSettingConfig()
    local PotentialStone = CommonManager.getSubTableByKey(
    DataManager.getPropsData(),
    {name = "metaId", value = TreasureSetting.treasurePropId}
  )
  PotentialStone = PotentialStone and PotentialStone or {
    metaId = TreasureSetting.treasurePropId,
    amount = 0,
  }
  -- print("~~~~~~~~~~~~~~~~~~~~~DataManager.getPropsData() = "..tostringRich(DataManager.getPropsData()))
  return PotentialStone.amount
end

function TreasureSystemUtils.setPotentialStone(num)

	local  TreasureSetting = TreasureSystemConfig.getTreasureSettingConfig()
	local itemData = DataManager.getPropsData()
	for k,v in pairs(itemData) do
		if v.metaId == TreasureSetting.treasurePropId then
			v.amount = v.amount - num
			break;
		end
	end
	DataManager.setPropsData(itemData)
end

--[[TreasureSystemConsts.Potentiallevel_FAN = 1 --凡
TreasureSystemConsts.Potentiallevel_LIANG = 2 --良
TreasureSystemConsts.Potentiallevel_YOU = 3 --优
TreasureSystemConsts.Potentiallevel_JI = 4 --极
TreasureSystemConsts.Potentiallevel_JUE = 5 --绝
TreasureSystemConsts.Potentiallevel_SHEN = 6 --神]]
function TreasureSystemUtils.getColorByRarity( rarity )
	-- print("~~~~~~~~~~~~~~~~~~~rarity = "..rarity)
	if rarity == TreasureSystemConsts.Potentiallevel_FAN then
		return ccc3(1 , 215 ,21)
	elseif rarity == TreasureSystemConsts.Potentiallevel_LIANG then
		return ccc3(0,183,236)
	elseif rarity == TreasureSystemConsts.Potentiallevel_YOU then
		return ccc3(231 ,0,217)
	elseif rarity == TreasureSystemConsts.Potentiallevel_JI then
		return ccc3(244 ,155,0)
	elseif rarity == TreasureSystemConsts.Potentiallevel_JUE then
		return ccc3(234 ,85,4)
	elseif rarity == TreasureSystemConsts.Potentiallevel_SHEN then
		return ccc3(255 ,222,0)
	-- elseif rarity == 7 then
	-- 	return ccc3(255 ,222,0)
	-- else
	-- 	return ccc3(255,255,255)
	end
end

function TreasureSystemUtils.getTextByTreasureAttrType( attrtype )
	-- print("~~~~~~~~~~~~~~~~~~~attrtype = "..attrtype)
	if attrtype == TreasureSystemConsts.Potentiallevel_FAN then
		return getTextByKey("Treasure_text_16")
	elseif attrtype == TreasureSystemConsts.Potentiallevel_LIANG then
		return getTextByKey("Treasure_text_17")
	elseif attrtype == TreasureSystemConsts.Potentiallevel_YOU then
		return getTextByKey("Treasure_text_18")
	elseif attrtype == TreasureSystemConsts.Potentiallevel_JI then
		return getTextByKey("Treasure_text_19")
	elseif attrtype == TreasureSystemConsts.Potentiallevel_JUE then
		return getTextByKey("Treasure_text_20")
	elseif attrtype == TreasureSystemConsts.Potentiallevel_SHEN then
		return getTextByKey("Treasure_text_21")
	else
		return nil
	end
end

function TreasureSystemUtils.getUINameTreasureAttrType( attrtype )
	if attrtype == TreasureSystemConsts.Potentiallevel_NONE then
		return "q_white9_panel"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_FAN then
		return "q_green9_panel"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_LIANG then
		return "q_blue9_panel"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_YOU then
		return "q_purple9_panel"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_JI then
		return "q_orange9_pic"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_JUE then
		return "q_red9_panel"
	elseif attrtype == TreasureSystemConsts.Potentiallevel_SHEN then
		return "q_yellow9_panel"

	else
		return nil
	end
end


--