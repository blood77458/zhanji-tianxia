require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.utils.TimeUtil"

--
-- CalculationManager
--

CalculationManager = class()
local calculationManagerInstance = nil
function CalculationManager:sharedManager()
	if not calculationManagerInstance then
		calculationManagerInstance = CalculationManager.new()
	end
	return calculationManagerInstance
end

function CalculationManager:ctor(  )

end

----------------------------------------
-- Description: 获取当前金币数量
----------------------------------------
function CalculationManager.calcComplex_getGemsNow(userData)
	local sharkUser = userData or DataManager.getCurrUser()
	if (sharkUser) then
		return (sharkUser.rechargeGems + sharkUser.freeGems - sharkUser.usedFreeGems - sharkUser.usedRechargeGems)
	else
		return 0
  end
end

----------------------------------------
----------------------------------------
function CalculationManager.calcComplex_getEnergyNow(userData)
	local energyMax = MetaManager.game_meta.gameSettingConfig.maxEnergy
	local sharkUser = userData or DataManager.getCurrUser()
	
	local nowTime = TimeUtil.getServerTimeSeconds()
	local timePassed = nowTime - sharkUser.energyLastUpdateTime
	
	local stNow = sharkUser.energy
	
	local stRecovery = ( energyMax - stNow) * st_recover_per_second - timePassed
	if (stRecovery<0) then
		stRecovery = 0
	end
	
	if (stNow < energyMax) then
		stNow = stNow + math.modf(timePassed/ st_recover_per_second)
		stNow = (stNow > energyMax) and energyMax or stNow
	end
	
	local stNextTime = stRecovery%st_recover_per_second
	local stAllTime = stRecovery
	
	local isEnergyFull = false
	if stNow >= energyMax then
		isEnergyFull = true
	end
	return stNow, stNextTime, stAllTime, isEnergyFull ,energyMax
end

----------------------------------------
----------------------------------------
--TODO
function CalculationManager.calcComplex_getEPNow(userData)
	local viPer = vi_recover_per_second
	local epMax = MetaManager.game_meta.gameSettingConfig.maxEventPoint
	local sharkUser = userData or DataManager.getCurrUser()
	local nowTime = TimeUtil.getServerTimeSeconds()
	local viRecovered = math.modf((nowTime - sharkUser.eventPointLastUpdateTime) / viPer)
	
  local viNow = sharkUser.eventPoint
  if viNow < epMax then
    viNow = sharkUser.eventPoint + viRecovered
    viNow = (viNow > epMax) and epMax or viNow
  end
	
	local stRecovery = ( epMax - sharkUser.eventPoint) * viPer - (nowTime - sharkUser.eventPointLastUpdateTime)
	if (stRecovery<0) then
		stRecovery = 0
	end
	local viNextTime = stRecovery%viPer
	local viAllTime = stRecovery
	
	local isViFull = false
	if viNow >= epMax then
		isViFull = true
	end
	return viNow, viNextTime, viAllTime, isViFull ,epMax
end

----------------------------------------
-- Description: 计算装备强化消耗
----------------------------------------
function CalculationManager.calcEquip_getEquipUpgradeCost( aEquip )
	local aEquipMetaConfig = MetaManager.equip_meta[tonumber(aEquip.metaId, 10)]
	local aEquipLevelConfig = MetaManager.equip_level[aEquip.level]
	
	return tonumber(aEquipMetaConfig.coinConsumeCoe, 10) * tonumber(aEquipLevelConfig.upgradeCoinBase, 10)
end

----------------------------------------
-- Description: 计算卡牌队列统御力
----------------------------------------
function CalculationManager.calcComplex_getQueueLeaderPoints( queueData, userData)
	local result = 0

	if (queueData) then
		for _, aCard in pairs(queueData) do
			result = result + MetaManager.card_meta[aCard["metaId"]].leadPoint
		end
	else
		local queue = CommonManager.getQueueData()
		local cardData = DataManager.getCardsData()
		local cardMap = {}
		for _, value in ipairs(cardData) do
			cardMap[value.cardId] = value.metaId
		end
		for _, value in pairs(queue) do
			result = result + MetaManager.card_meta[cardMap[value]].leadPoint
		end
	end
	
	local userData = userData or DataManager.getCurrUser()
	local maxLeadP = MetaManager.user_level[userData.level]["leadPoint"] + MetaManager.vip_setting[userData.vipLevel]["extraLeadershipPoints"]
	
	return result, maxLeadP
end

function CalculationManager.calcComplex_getRenameCoolingTime()
	local nowTime = TimeUtil.getServerTimeSeconds()
    local timePassed = nowTime - DataManager.getGameInitData().sharkUserExtend.lastRenameTimes
    local timeRemain = MetaManager.game_meta.gameSettingConfig.renameCooldown - timePassed
    if timeRemain < 0 then
    	timeRemain = 0
    end
    local renameNextTime = TimeUtil.formatTime(timeRemain)
    return renameNextTime , timeRemain
end