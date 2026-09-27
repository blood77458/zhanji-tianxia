-- CrossArenaCheck.lua
-- 2015-3-11
-- zheng.che
-- 跨服pvp查询接口

CrossArenaCheck = {}

-- 能否领取排名奖励
-- withAlert 需提示
function CrossArenaCheck.canGainRankReward(withAlert)
	if BagCalcManager.isFull() then
		--背包已满
		if withAlert then
			local scene = Director:mgr():run()
			scene.targetInfoPanel = NewPackageFullPanel:show()
		end
		return false
	end

	return true
end

-- 能否领取冠军奖励
-- withAlert 需提示
function CrossArenaCheck.canGainTopReward(withAlert)
	if BagCalcManager.isFull() then
		--背包已满
		if withAlert then
			local scene = Director:mgr():run()
			scene.targetInfoPanel = NewPackageFullPanel:show()
		end
		return false
	end

	return true
end