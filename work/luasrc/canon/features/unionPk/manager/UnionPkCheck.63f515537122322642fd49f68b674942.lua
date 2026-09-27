-- UnionPkCheck.lua
-- 2014-8-21
-- zheng.che
-- 军团战 校验接口

UnionPkCheck = {}

--是否允许打开战场二级(进入战场)
function UnionPkCheck.canEnterBattleFieldPanel(timeLevel, cityData, withAlert)
	if timeLevel == UnionPkConsts.TIME_SELECT then
		--报名阶段
		return false
	elseif timeLevel == UnionPkConsts.TIME_SELECTING then
		--等待竞标结果阶段
		return false
	elseif timeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
		--团员参与阶段
		if UnionPkCityData.isMyChallengCity(cityData) then
			--自己已参与此场战斗
			return true
		end
		if UnionTitleManager.canChangeForm() then
			--有调整阵型权限
			if UnionPkCheck.isMemberApplied() then
				--报名过任意城池 ok 此时可以打开任意出现"进入战场"按钮的战场UI
				return true
			else
				--虽然有权限 但是还没有报名过某个城池 那么认为他不能直接打开战场二级 而是应该走报名流程(因此这里不给提示)
				return false
			end
		end
		--在这个时间段 此接口的false返回都不给提示 真正的提示交给报名接口
		return false

	elseif timeLevel == UnionPkConsts.TIME_ROUND1_FORM or 
		timeLevel == UnionPkConsts.TIME_ROUND2_FORM
		then
		--第一轮调整阵型 or 第二轮调整阵型

		--此段比较特殊 只有在需要提示的情况下才做判断
		if withAlert then
			if UnionPkData.getCityErrorTag(cityData.cityId, UnionPkConsts.CITY_ERROR_TAG_NO_FORMATION) then
				--城池已被标记为"无阵型"
				local scene = Director:mgr():run()
				SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt22"))--您的军团没有人报名本城池团战
				return false
			end
		end

		if UnionPkCityData.isMyChallengCity(cityData) then
			--自己已参与此场战斗
			return true
		end
		if UnionTitleManager.canChangeForm() then
			--有调整阵型权限
			return true
		end

		--不符合以上条件
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_supple_text2"))--主公，您没有报名本城池战场
		end
		return false

	else
		--都不是
		return false
	end
	return false
end

--获得进入战场相关数据后 是否依然允许打开战场UI
function UnionPkCheck.canEnterBattleFieldPanelByTransformData(transformEventData, cityData, withAlert)
	local currentTimeLevel = UnionPkData.getCurrTimeLevel()

	--没有进攻方1情况
	local attack1UnionData = transformEventData.sharkUnionCityApply[2]
	if not attack1UnionData then
		--第一场 并且没有第一个挑战者
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt25"))--本轮军团战没有人报名本城池，您所在的军团直接获得本轮军团战的胜利
		end
		return false
	end

	--没有进攻方2情况
	local attack2UnionData = transformEventData.sharkUnionCityApply[3]
	local currRound = UnionPkUtils.findCurrentRoundByTimeLevel(currentTimeLevel)
	if currRound == 2 and (not attack2UnionData) then
		--第二场 并且没有第二个挑战者
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt24"))--第二场团战无进攻方，您的军团获得本轮军团战的胜利
		end
		return false
	end

	--检验没有阵型的情况
	if not transformEventData.unionFormation then
		--没有阵型
		--如果在成员报名阶段 且当前玩家有权限 那么允许继续打开 否则给提示并记录状态
		
		if currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY and UnionTitleManager.canChangeForm() then
			--刚好处于团员报名阶段 并且当前玩家有权限
			--什么也不做 流程继续
		else
			--提示
			if withAlert then
				local scene = Director:mgr():run()
				SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt22"))--您的军团没有人报名本城池团战
			end

			UnionPkData.setCityErrorTag(cityData.cityId, UnionPkConsts.CITY_ERROR_TAG_NO_FORMATION)--记录该城池id 防止再次请求
			return false
		end
	end

	return true
end

--是否在鼓舞时间段内
function UnionPkCheck.isInPowerupTime(timeLevel, withAlert)
	if timeLevel < UnionPkConsts.TIME_MEMBER_APPLY then
		--时间没到
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt"))--未到鼓舞时间，请稍后重试
		end
		return false
	end

	if timeLevel > UnionPkConsts.TIME_ROUND2_FORM then
		--时间过了
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt10"))--buff鼓舞时间已过
		end
		return false
	end

	if timeLevel == UnionPkConsts.TIME_ROUND1_FIGHT then
		--时间卡在第一轮计算结果时候
		--此种情况理论上只会停留在鼓舞界面上才会出现 而这种情况其他地方应该会给提示
		return false
	end

	return true
end

--是否允许鼓舞
function UnionPkCheck.canPowerup(timeLevel, cityId, buffId, cityFormationData, withAlert)

	if cityId ~= UnionManager.getChallengeCityId() then
		--自己报名的城池不是这个城池
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt23"))--未报名本城池的团战，不能进行鼓舞
		end
		return false
	end

	if not UnionPkCheck.isInPowerupTime(timeLevel, withAlert) then
		return false
	end

	--剩下的时间就是鼓舞时间
	if buffId == UnionPkConsts.POWERUP_SILVER then
		--银币鼓舞
		local currTimes = UnionManager.getCoinInspireNum()
		local maxTimes = UnionPkConfig.silverBuffNum()
		if currTimes >= maxTimes then
			--次数已满
			if withAlert then
				local scene = Director:mgr():run()
				SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_done"))--已达到鼓舞上限次数
			end
			return false
		end
		--允许鼓舞
		return true
	elseif buffId == UnionPkConsts.POWERUP_GOLD then
		--金币鼓舞
		local maxGoldTotleCount = UnionPkConfig.cityGoldBuffNum()
		local currentGoldTotleCount = cityFormationData.unionFormation.gemInspireNum
		if currentGoldTotleCount >= maxGoldTotleCount then
			--金币鼓舞总次数达到上限
			if withAlert then
				local scene = Director:mgr():run()
				SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_attend"))--您的军团咋本城池团队金币鼓舞次数达到上限
			end
			return false
		end

		local currTimes = UnionManager.getGemInspireNum()
		local maxTimes = UnionPkConfig.goldBuffNum()		if currTimes >= maxTimes then
			--次数已满
			if withAlert then
				local scene = Director:mgr():run()
				SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_done"))--已达到鼓舞上限次数
			end
			return false
		end
		--允许鼓舞
		return true
	else
		--奋力一击
		local currTimes = UnionManager.getStriveInspireNum()
		local maxTimes = UnionPkConfig.striveNum()
		if currTimes >= maxTimes then
			--次数已满
			return false
		end
		--允许鼓舞
		return true
	end
	return true
end

--是否在团员报名时间段内
function UnionPkCheck.isInMemberApplyTimeLevel(timeLevel)
	if timeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
		--团员参与阶段
		return true
	end
	
	return false
end

--能否进行团员报名
function UnionPkCheck.canMemberApply(timeLevel, cityData, withAlert)
	if not UnionPkCheck.isInMemberApplyTimeLevel(timeLevel) then
		--不在时间段内
		return false
	end
	
	if UnionPkData.getCityErrorTag(cityData.cityId, UnionPkConsts.CITY_ERROR_TAG_NO_CHALLENGER) then
		--被标记为"没有挑战者"
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt25"))--本轮军团战没有人报名本城池，您所在的军团直接获得本轮军团战的胜利
		end
		return false
	end

	if UnionPkData.getCityErrorTag(cityData.cityId, UnionPkConsts.CITY_ERROR_TAG_NO_FORMATION) then
		--城池已被标记为"无阵型"
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt22"))--您的军团没有人报名本城池团战
		end
		return false
	end

	local targetCityId = UnionManager.getChallengeCityId()
	if UnionPkCheck.isMemberApplied() and  (not UnionPkCityData.isMyChallengCity(cityData)) then
		--玩家已报名过 且报名的城池不是此城池
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_ready_choose"))--每名团员只能选择一个城池参加团战
		end
		return false
	end

	return true
end

--能否参与城池竞标
function UnionPkCheck.canInUnionSign(timeLevel, cityData, withAlert)
	if not UnionTitleManager.canCitySign() then
		--没有权限
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt15"))--权限不足
		end
		return false
	end

	if UnionManager.isDissolving() then
		--当前军团在解散期间
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt4"))--该军团处于解散状态，不能进行报名操作
		end
		return false
	end

	if timeLevel ~= UnionPkConsts.TIME_SELECT then
		--不在报名阶段
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt3"))--军团报名时间已过
		end
		return false
	end

	local currentDefenceCount = UnionPkData.getDefenceCityNum()
	local maxDefenceNum = UnionPkConfig.citySignLimit()
	if currentDefenceCount >= maxDefenceNum then
		--占领数已满
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_sign_text2"))--您的军团本轮已经占领了两个城池，不能报名其他城池了，快发动团员去防御占领城池吧。
		end
		return false
	end

	local currentSignCount = UnionPkData.signedCityCount()
	local maxSignNum = UnionPkData.getMaxCanSignNum()
	if currentSignCount >= maxSignNum then
		--可报名数已满
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt7"))--您的军团报名城池数量达到上限
		end
		return false
	end

	local cityTypeId = UnionPkUtils.getCityTypeById(cityData.cityId)
	local singLimitUnionLevel = UnionPkConfig.getSignUnionLevelByCityId(cityTypeId)
	if UnionManager.getUnionLevel() < singLimitUnionLevel then
		--军团等级小于最低可报名等级
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_optimize_supply", {num1 = singLimitUnionLevel}))--主公，您的军团等级需要大于{num1}级才能报名本城池。
		end
		return false
	end

	local singLimitFightCapacity = UnionPkConfig.getSignFightCapacityByCityId(cityTypeId)
	if UnionPkData.getUnionTotalFightCapacity() < singLimitFightCapacity then
		--军团总战力不足
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_optimize_supply1", {num1 = singLimitFightCapacity}))--主公，您的军团所有成员战力总和大于{num1}才能进行报名。
		end
		return false
	end

	if UnionPkData.getCityErrorTag(cityData.cityId, UnionPkConsts.CITY_ERROR_TAG_SIGN_FULL) then
		--城池已被标记为"团满为患"
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt6"))--该城池报名军团数已经到达上限
		end
		return false
	end

	if UnionPkCityData.myUnionIsDefencer(cityData) then
		--自己是守方
		return false
	end

	return true
end

--能否调整阵型
function UnionPkCheck.canModifiyForm(timeLevel, withAlert)
	if not UnionTitleManager.canChangeForm( UnionManager.getMyTitle() ) then
		--职位不符
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt4"))--只有军团长/副团长有权限调整阵型
		end
		return false
	end
	
	if timeLevel ~= UnionPkConsts.TIME_ROUND1_FORM and timeLevel ~= UnionPkConsts.TIME_ROUND2_FORM then
		--不在调整阵型阶段
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt3"))--阵型调整时间未到
		end
		return false
	end
	
	-- if timeLevel == UnionPkConsts.TIME_ROUND1_BUFF or timeLevel == UnionPkConsts.TIME_ROUND2_BUFF then
	-- 	--
	-- 	if withAlert then
	-- 		local scene = Director:mgr():run()
	-- 		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt9"))--阵型调整时间已过
	-- 	end
	-- 	return false
	-- end

	return true
end

--调整阵型按钮是否可见
--myUnionIsInCurrentRound 自己的军团是否在本轮中有出场 传nil表示未出场
--round1Losed 第一轮是否失败 传nil表示第一轮未失败
function UnionPkCheck.canSeeModifiyFormBtn(timeLevel, myUnionIsInCurrentRound, round1Losed)
	return true
end

--领奖按钮是否可见
function UnionPkCheck.canSeeRewardFormBtn(timeLevel)
	if timeLevel ~= UnionPkConsts.TIME_REWARD then
		--不在领奖时间
		return false
	end

	local seeNum = 0
	for i=1,UnionPkConsts.REWARD_MAX_COUNT do
		if UnionPkCheck.canSeeReward(i) then
			seeNum = seeNum + 1
		end
	end
	if seeNum <= 0 then
		--没有可见的奖励
		return false
	end

	return true
end


--我党军团按钮是否可见
function UnionPkCheck.canSeeMyUnionBtn(timeLevel)
	if timeLevel >= UnionPkConsts.TIME_MEMBER_APPLY and timeLevel <= UnionPkConsts.TIME_ROUND2_FIGHT then
		return true
	end
	return false
end


--军团财富是否可见
function UnionPkCheck.canSeeWealthTxt(timeLevel)
	if timeLevel > UnionPkConsts.TIME_SELECTING then
		return false
	end

	--
	return true
end


--当前玩家是否已报名过任意城池
function UnionPkCheck.isMemberApplied()
	local targetCityId = UnionManager.getChallengeCityId()
	if targetCityId == nil then
		return false
	end
	if targetCityId == 0 then
		return false
	end
	return true
end


--是否在鼓舞时段
function UnionPkCheck.isInPowerupTime(timeLevel)
	if timeLevel == UnionPkConsts.TIME_MEMBER_APPLY or 
		timeLevel == UnionPkConsts.TIME_ROUND1_FORM or 
		timeLevel == UnionPkConsts.TIME_ROUND2_FORM
		then
		return true
	end

	--
	return false
end

--查询奖励是否可见 (除"是否领取过"以外 是否满足领奖条件)
--index 领奖类型
function UnionPkCheck.canSeeReward(index)
	if index == UnionPkConsts.REWARD_DAILY then
		for k,v in pairs(UnionPkData.getDefenceCityIdsHash()) do
			local reward = UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(tonumber(k))
			if reward ~= -1 then
				return true
			end
		end
	elseif index == UnionPkConsts.REWARD_IN then
		if UnionPkCheck.hasAttendUnionPk() then
			--参与过军团
			local reward = UnionPkConfig.joinWarReward()
			if reward ~= -1 then
				return true
			end
		end
	elseif index == UnionPkConsts.REWARD_CAPTRUE then
		for i,v in ipairs(UnionPkData.getUnionWinNumList()) do
			local reward = UnionPkConfig.getMyHistoryTitleDefenceRewardByCityId(tonumber(v.cityId))
			if reward ~= -1 then
				return true
			end
		end
	elseif index == UnionPkConsts.REWARD_BATTLE then
		if UnionPkCheck.isMemberApplied() then
			local reward = UnionPkConfig.inBattleReward()
			if reward ~= -1 then
				return true
			end
		end
	end
	return false
end

--查询是否可以领奖
--index 领奖类型
function UnionPkCheck.canGetReward(index)
	--print("canGetReward! index = " .. tostringRich(index))
	if not UnionPkCheck.canSeeReward(index) then
		--不能领
		return false
	end
	
	if index == UnionPkConsts.REWARD_DAILY then
		return not DailyDataManager.getDailyDataGainUnionWarDailyReward()
	elseif index == UnionPkConsts.REWARD_IN then
		if UnionPkCheck.hasAttendUnionPk() then
			--参与过军团
			return not UnionManager.getGainUnionWarPlayReward()
		end
	elseif index == UnionPkConsts.REWARD_CAPTRUE then
		return not UnionManager.getGainUnionWarOccupyReward()
	elseif index == UnionPkConsts.REWARD_BATTLE then
		return not UnionManager.getGainUnionWarInBattleReward()
	end
	--不能领
	return false
end

--查询是否参与过军团战
function UnionPkCheck.hasAttendUnionPk()
	if (UnionPkData.signedCityCount() > 0) or (UnionPkData.getDefenceCityNum() > 0) or (UnionPkData.getAttendBattleNum() > 0) then
		--有防守城池 或者 报名过(不必成功) 或者 参加过战斗
		return true
	end
	return false
end

--查询当前玩家是否在阵型信息里
function UnionPkCheck.isInFormation(formationData)
	local myUid = DataManager.getCurrUser().uid

	if formationData.forwardInfo then
		if formationData.forwardInfo.uid == myUid then
			--自己是先锋
			return true
		end
	end

	if formationData.formationHeadInfo then
		for i, v in ipairs(formationData.formationHeadInfo) do
			if v.uid == myUid then
				--自己在阵首
				return true
			end
		end
	end

	if formationData.formationMiddleInfo then
		for i, v in ipairs(formationData.formationMiddleInfo) do
			if v.uid == myUid then
				--自己在阵中
				return true
			end
		end
	end

	if formationData.formationTailInfo then
		for i, v in ipairs(formationData.formationTailInfo) do
			if v.uid == myUid then
				--自己在阵尾
				return true
			end
		end
	end

	return false
end

-- 是否在正确的军团战服务器
function UnionPkCheck.isInCorrectServer()
	local serverId = DataManager.getServerid()
	return UnionPkConfig.isCorrectServer(serverId)
end

-- ---------------------------------------------------------------处理下半部分
-- 		if timeLevel == UnionPkConsts.TIME_SELECT then
-- 			--报名阶段

-- 		elseif timeLevel == UnionPkConsts.TIME_SELECTING then
-- 			--等待竞标结果阶段

-- 		elseif timeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
-- 			--团员参与阶段

-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND1_FORM then
-- 			--第一轮调整阵型
-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND1_BUFF then
-- 			--第一轮buff鼓舞
-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND1_FIGHT then
-- 			--第一轮等待结果
-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND2_FORM then
-- 			--第二轮调整阵型
-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND2_BUFF then
-- 			--第二轮buff鼓舞
-- 		elseif timeLevel == UnionPkConsts.TIME_ROUND2_FIGHT then
-- 			--第二轮等待结果
-- 		elseif timeLevel == UnionPkConsts.TIME_REWARD then
-- 			--领奖阶段
-- 		else
-- 			--皆非也
-- 			if SystemManager.debug then
-- 				DebugManager.addError("非法时间段! 编号: " .. tostringRich(timeLevel))
-- 			end
-- 		end