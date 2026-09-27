--------------------------------------------------------------------------------
-- TreasureManager.lua
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "hecore.display.CocosObject"
TreasureManager = {}

local treasureFreeRefreshTimes = 0

function TreasureManager.getColorByRarity( rarity )
	if rarity == 1 then
		return ccc3(125,125,125)
	elseif rarity == 2 then
		return ccc3(1 , 215 ,21)
	elseif rarity == 3 then
		return ccc3(0,183,236)
	elseif rarity == 4 then
		return ccc3(231 ,0,217)
	elseif rarity == 5 then
		return ccc3(244 ,155,0)
	elseif rarity == 6 then
		return ccc3(234 ,85,4)
	elseif rarity == 7 then
		return ccc3(255 ,222,0)
	else
		return ccc3(255,255,255)
	end
end

function TreasureManager.getTreasureQua( rarity )
	if rarity == 1 then
		return getTextByKey("Treasure_text_16")
	elseif rarity == 2 then
		return getTextByKey("Treasure_text_17")
	elseif rarity == 3 then
		return getTextByKey("Treasure_text_18")
	elseif rarity == 4 then
		return getTextByKey("Treasure_text_19")
	elseif rarity == 5 then
		return getTextByKey("Treasure_text_20")
	elseif rarity == 6 then
		return getTextByKey("Treasure_text_21")
	else
		return ""
	end
end

function TreasureManager.isUserLevelEnough()
	return DataManager.getCurrUser().level >= (DataManager.GameMetaData.treasureSettingConfig and DataManager.GameMetaData.treasureSettingConfig.unlockLevel or 60)
end

function TreasureManager.getTreasureUserLevel()
	return (DataManager.GameMetaData.treasureSettingConfig and DataManager.GameMetaData.treasureSettingConfig.unlockLevel or 60)
end

function TreasureManager.getTreasureRare( treasure )
	return MetaManager.treasure_meta[treasure.metaId].rare
end

function TreasureManager.calcTreasureTotalGridNum()
	local boughtGridNum = 0
	if DataManager.getGameInitData().sharkUserExtend ~= nil then
		boughtGridNum = DataManager.getGameInitData().sharkUserExtendMore.treasureInfo.buyGridTimes * --买的次数
		DataManager.GameMetaData.treasureSettingConfig.treasureExtraSizePerPurchase --买一次增加的容量
	end

	local initGridNum = DataManager.GameMetaData.treasureSettingConfig.treasurePoolInitSize --宝物初始容量
	local totalGridNum = boughtGridNum + initGridNum

	return totalGridNum, boughtGridNum, initGridNum
end

function TreasureManager.calcTreasureUsingGridNum()
	local treasureInfo = DataManager.getTreasuresData()
	local usingGridNum = 0
	for k,v in pairs(treasureInfo) do
		if (not v.cardId or v.cardId == 0) then
			usingGridNum = usingGridNum + 1
		end
	end
	return usingGridNum
end	

function TreasureManager.isTreasurePoolFull()
	if TreasureManager.calcTreasureUsingGridNum() >= TreasureManager.calcTreasureTotalGridNum() then 
		return true
	else
		return false
	end
end

function TreasureManager.isFreeGacha()
	local info = DataManager.getGameInitData().sharkGachaInfo
	local lastTime = 0
	if info then
		lastTime = tonumber(info.lastFreeTreasureGachaSeconds) or 0
	end
	local leftTime = lastTime + 86400 - TimeUtil.getServerTimeSeconds()
	if (leftTime <= 0 or lastTime == 0) then 
		return true
	else
		return false
	end
end

function TreasureManager.getTreasureName( treasure )
	return getTextByKey(MetaManager.treasure_meta[treasure.metaId].name)
end

function TreasureManager.getTreasureNameByMeta( treasureMeta )
	return getTextByKey(MetaManager.treasure_meta[treasureMeta].name)
end

function TreasureManager.getTreasureRare( treasure )
	return MetaManager.treasure_meta[treasure.metaId].rare
end

function TreasureManager.isSaigou( treasure )
	if treasure.level >= DataManager.getGameInitData().sharkUser.level then
		do return true end
	else
		do return false end
	end
end

function TreasureManager.isLevelSaigou( treasure )
	if MetaManager.treasure_meta[treasure.metaId].evolutionLevel ~= 0 and 
	treasure.level >= MetaManager.treasure_meta[treasure.metaId].evolutionLevel then
		do return true end
	else
		do return false end
	end
end