-- TreasureSystemCheck.lua
-- meilan.xie
-- 2015-8-7
--宝物校验接口

TreasureSystemCheck = {}

function TreasureSystemCheck.CheckGoldStone(nowStone,requireStone)
	if nowStone >= requireStone then
		return true
	else
		return false
	end

end


function TreasureSystemCheck.CheckSilverStone(nowStone,requireStone)
	if nowStone >= requireStone then
		return true
	else
		return false
	end

end


function TreasureSystemCheck.CheckOrdinaryStone(nowStone,requireStone)
	if nowStone >= requireStone then
		return true
	else
		return false
	end

end


function TreasureSystemCheck.CheckGoldMoney(nowGoldMoney,requireGoldMoney)
	
	if  tonumber(nowGoldMoney,10) >=  tonumber(requireGoldMoney,10) then
		return true
	else
		return false
	end

end


function TreasureSystemCheck.CheckSilverMoney(nowSilverMoney,requireSilverMoney)

	if tonumber(nowSilverMoney, 10) >= tonumber(requireSilverMoney, 10) then
		return true
	else
		return false
	end

end

function TreasureSystemCheck.CheckIsDayFirstRebirth()
  return DailyDataManager.getTreasureSacrificeTimes() == 0
end