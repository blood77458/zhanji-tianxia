-- UnionPkCityInfoPopPanel.lua
-- zheng.che
-- 2014-7-24
-- 军团战 城池信息二级

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	local self = evt.context
	self:close()
end

--时间段更新事件
local function onTimelevelUpdate(evt)
	local self = evt.context
	local function onAfterSucceed(afterEvt)
		self.cityData = afterEvt.data.sharkUnionCity
		self.inBattle = afterEvt.data.inBattle
		self.firstBattleFailed = afterEvt.data.firstBattleFailed

		self.refreshSelf()
	end
	UnionPkGetCityInfoRequest.sendRequestDefalut(self.cityData.cityId, onAfterSucceed)
end

--点击关闭
local function onClose(evt)
	local self = evt.context
	self:close()
end

--点击奖励图标
local function onClickReward(evt)
	local rewardId = evt.context
	local scene = Director:mgr():run()

	local rewardList = MetaManager.getRewardInfoByID(rewardId) or {}
	local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = rewardList, rewardTitle = getTextByKey("pk_reward_title")} )
	scene:addChild(aRewardPanel)
	aRewardPanel:scaleIn()
end

--点击查看报名
local function onCheckSignClick(evt)
	local self = evt.context
	local scene = Director:mgr():run()

	local function onAfterSucceed(evt)
		local data = evt.data.sharkUnionCityApply or {}
		-- data = {{applyId = 1 , unionId = 1 , unionName = "76ers" , wealth = 1000}}

		local aRewardPanel = UnionCitySignUpInfoPopPanel:create(scene, self.cityData.cityId , data)
		scene:addChild(aRewardPanel)
		aRewardPanel:scaleIn()
	end
	UnionPkGetApplyUnionsRequest.sendRequestDefalut(self.cityData.cityId,onAfterSucceed)

	--测试用 直接进入第一轮战报
	--UnionPkGetBattleReportRequest.sendRequestDefalut(self.cityData.cityId, 1)
end

--点击查看战报
local function onCheckHistroyClick(evt)
	local self = evt.context
	local scene = Director:mgr():run()

	--测试用
	--UnionPkTest.testOpenPowerupPanel(self.cityData)
	--UnionPkTest.testOpenModifyFormationPanel(self.cityData)

	local function onAfterSucceed(evt)
		local data = evt.data.unionBattlefieldReportSummarys or {}
		local aReportPanel = UnionBattleReportPopPanel:create(scene, self.cityData.cityId , data)
		scene:addChild(aReportPanel)
		aReportPanel:scaleIn()
	end
	UnionPkGetBattleReportListRequest.sendRequestDefalut(self.cityData.cityId,onAfterSucceed)
end

--点击中间的安妮
local function onSignClick(evt)
	local self = evt.context
	local scene = Director:mgr():run()

	if self.currentTimeLevel == UnionPkConsts.TIME_SELECT then
		--在军团竞标报名时间段内
		if UnionPkCheck.canInUnionSign(self.currentTimeLevel, self.cityData, true) then
			--竞标报名
			function onConfirm()
				local function onAfterSucceed(requestEvt)
					--更改状态为已竞标
					self.cityData.report = true

					--刷新显示
					self.refreshSelf()

					--给提示
					SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_sign_success"))--您的军团已经成功报名本城池
				end
				UnionPkSignAttackRequest.sendRequestDefalut(self.cityData.cityId, onAfterSucceed)
			end
			CanonMessageBox.showAsConfirmBox(getTextByKey("UnionWar_sign_text", {num1 = UnionPkData.getMaxCanSignNum()}), onConfirm, nil)--您的军团本轮最多只能报名{num1}个城池，一旦报名不可取消，是否确认报名？
		end
	elseif self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
		--在报名时间段内
		if UnionPkCheck.canEnterBattleFieldPanel(self.currentTimeLevel, self.cityData, true) then
			--允许打开战场界面
			local function onComplete()
				self:close()
			end
			UnionPK.showCityPowerupPanel(self.cityData, onComplete)
		else
			--不让打开战场界面
			if UnionPkCheck.canMemberApply(self.currentTimeLevel, self.cityData, true) then
				--前端认为可报名
				function onConfirm()
					--团员报名
					local function onAfterSucceed(requestEvt)
						--弹出新窗口并关闭自己 所以不用刷新了
						local function onComplete()
							self:close()
						end
						UnionPK.showCityPowerupPanel(self.cityData, onComplete)

						--给提示
						SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success4"))--成功报名本城池
					end
					UnionPkMemberApplyRequest.sendRequestDefalut(self.cityData.cityId, onAfterSucceed)
				end
				CanonMessageBox.showAsConfirmBox(getTextByKey("UnionWar_battle_text1"), onConfirm, nil)--是否确认进入战场，本次团战您只能加入一个城池的战场，一旦进入不能更换。
			end
		end

	else
		--在进入战场时间段内
		if UnionPkCheck.canEnterBattleFieldPanel(self.currentTimeLevel, self.cityData, true) then
			--允许打开战场界面
			--print("允许打开战场界面")
			local function onComplete()
				self:close()
			end
			UnionPK.showCityPowerupPanel(self.cityData, onComplete)
		end
	end
end

------------------------------------------------------------------------------------------------------

UnionPkCityInfoPopPanel = class(Layer)

function UnionPkCityInfoPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionPkCityInfoPopPanel:create( container, eventData )
	local s = UnionPkCityInfoPopPanel.new()
	s:initLayer(container, eventData)
	return s
end

function UnionPkCityInfoPopPanel:initLayer(container, eventData)
	UnionPkCityInfoPopPanel.super.initLayer(self)
    
	self.container = container
	self.cityData = eventData.sharkUnionCity
	self.inBattle = eventData.inBattle
	self.firstBattleFailed = eventData.firstBattleFailed

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guildpk_registred") 

	self:addChild(self.panelUI)

	--刷新自身
	function refreshSelf()
		local lastestStartTime = UnionPkUtils.findLatestBeginTime()
		self.currentTimeLevel = UnionPkData.getCurrTimeLevel()
		--print("self.currentTimeLevel = " .. tostringRich(self.currentTimeLevel))

		-------------------------------------------------------------------处理时间显示
		if self.currentTimeLevel == UnionPkConsts.TIME_SELECT or self.currentTimeLevel == UnionPkConsts.TIME_SELECTING then
			--报名阶段 or 等待竞标结果阶段
			self.panelUI:getChildByName("txt_8"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_10"):setVisible(true)
			self.panelUI:getChildByName("txt_11"):setVisible(true)

			--报名阶段
			local selectStartTime, selectEndTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_SELECT)
			--团员参与阶段
			local memberApplyStartTime, memberApplyEndTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_MEMBER_APPLY)

			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_time1"))--报名时间:
			local selectTimeStr = UnionPkUtils.formatDate(selectStartTime) .. "-" .. UnionPkUtils.formatDate(selectEndTime)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(selectTimeStr)

			self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_time2"))--夺城战进入战场时间：
			local memeberApplyTimeStr = UnionPkUtils.formatDate(memberApplyStartTime) .. "-" .. UnionPkUtils.formatDate(memberApplyEndTime)
			self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(memeberApplyTimeStr)

		elseif self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
			--团员参与阶段
			self.panelUI:getChildByName("txt_8"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_10"):setVisible(true)
			self.panelUI:getChildByName("txt_11"):setVisible(true)

			local startTime, endTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_MEMBER_APPLY)
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_time1"))--军团成员报名进入战场时间：
			local selectTimeStr = UnionPkUtils.formatDate(startTime) .. "-" .. UnionPkUtils.formatDate(endTime)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(selectTimeStr)

			local startTime2, endTime2 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND1_FORM)
			self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_buff"))--本场团战buff鼓舞时间：
			local selectTimeStr = UnionPkUtils.formatDate(startTime) .. "-" .. UnionPkUtils.formatDate(endTime2)--(两段)
			self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(selectTimeStr)

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FORM then
			--第一轮调整阵型
			self.panelUI:getChildByName("txt_8"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_10"):setVisible(true)
			self.panelUI:getChildByName("txt_11"):setVisible(true)

			local startTime1, endTime1 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND1_FORM)
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time1"))--第一场团战调整阵型时间：--modified
			local selectTimeStr = UnionPkUtils.formatDate(startTime1) .. "-" .. UnionPkUtils.formatDate(endTime1)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(selectTimeStr)

			local startTime2, endTime2 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND1_FIGHT)
			self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_time"))--第一场团战进行时间
			local selectTimeStr = UnionPkUtils.formatDate(startTime2) .. "-" .. UnionPkUtils.formatDate(endTime2)
			self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(selectTimeStr)
			
		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FIGHT or 
		self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FORM then
			--第一轮团战 or 第二轮调整阵型
			self.panelUI:getChildByName("txt_8"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_10"):setVisible(true)
			self.panelUI:getChildByName("txt_11"):setVisible(true)

			local startTime1, endTime1 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND2_FORM)
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time3"))--第二场团战调整阵型时间：
			local selectTimeStr = UnionPkUtils.formatDate(startTime1) .. "-" .. UnionPkUtils.formatDate(endTime1)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(selectTimeStr)

			local startTime2, endTime2 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND2_FIGHT)
			self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_time1"))--第二场团战进行时间
			local selectTimeStr = UnionPkUtils.formatDate(startTime2) .. "-" .. UnionPkUtils.formatDate(endTime2)
			self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(selectTimeStr)

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FIGHT or 
		self.currentTimeLevel == UnionPkConsts.TIME_REWARD then
			--第二轮团战 or 领奖阶段
			self.panelUI:getChildByName("txt_8"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_10"):setVisible(true)
			self.panelUI:getChildByName("txt_11"):setVisible(true)

			local startTime1, endTime1 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_REWARD)
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_time2"))--本轮团战奖励领取时间
			local selectTimeStr = UnionPkUtils.formatDate(startTime1) .. "-" .. UnionPkUtils.formatDate(endTime1)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(selectTimeStr)

			--下一届=下一周
			local startTime2, endTime2 = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_SELECT)
			startTime2 = startTime2 + TimeUtil.WEEK
			endTime2 = endTime2 + TimeUtil.WEEK
			self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_time3"))--下一轮团战城池报名时间
			local selectTimeStr = UnionPkUtils.formatDate(startTime2) .. "-" .. UnionPkUtils.formatDate(endTime2)
			self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(selectTimeStr)

		else
			--均非也
			if SystemManager.debug then
				DebugManager.addError("非法时间段! 编号: " .. tostringRich(self.currentTimeLevel))
			end
		end
		
		---------------------------------------------------------------处理下半部分
		self.panelUI:getChildByName("txt_13"):setVisible(false)--最下方的文字 默认不显示
		self.panelUI:getChildByName("txt_14"):setVisible(false)
		self.panelUI:getChildByName("txt_15"):setVisible(false)

		if self.currentTimeLevel == UnionPkConsts.TIME_SELECT then
			--报名阶段
			if UnionPkCityData.myUnionIsDefencer(self.cityData) then
				--自己是守方
				self.signButton:setVisible(false)
				self.signButton:setEnable(false)
				self.panelUI:getChildByName("txt_12"):setVisible(true)
				self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text8"))--您的军团在本城池为防御方，请等待进入战场
			else
				--不是守方
				if self.cityData.report then
					--已经报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_success"))--您的军团已成功报名本城池
				else
					--没报名
					self.signButton:setVisible(true)
					self.signButton:setEnable(true)
					self.signButton.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_title2"))--报名
					self.panelUI:getChildByName("txt_12"):setVisible(false)
				end
			end

			self.panelUI:getChildByName("txt_13"):setVisible(true)
			self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_text1"))--报名时间内，报名军团获得的军团财富前两名将获得攻打资格

		elseif self.currentTimeLevel == UnionPkConsts.TIME_SELECTING then
			--等待竞标结果阶段
			self.signButton:setVisible(false)
			self.signButton:setEnable(false)

			self.panelUI:getChildByName("txt_13"):setVisible(true)
			self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_text1"))--报名时间内，报名军团获得的军团财富前两名将获得攻打资格
			self.panelUI:getChildByName("txt_12"):setVisible(true)

			if UnionPkCityData.myUnionIsDefencer(self.cityData) then
				--自己是守方
				self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text8"))--您的军团在本城池为防御方，请等待进入战场
			else
				--不是守方
				if self.cityData.report then
					--已经报名
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text"))--报名结束，请等待竞标结果
				else
					--没报名
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
			--团员参与阶段
			if UnionPkCityData.myUnionIsDefencer(self.cityData) then
				--自己是守方
				self.panelUI:getChildByName("txt_12"):setVisible(false)
				self.signButton:setVisible(true)
				self.signButton:setEnable(true)
				self.signButton.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_ready"))--进入战场
				self.panelUI:getChildByName("txt_13"):setVisible(true)
				self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text9"))--您的军团为守城方，快去战场准备防御吧
			else
				--不是守方
				if self.cityData.report then
					--报名过
					if self.cityData.successfulBid then
						--报名成功
						self.signButton:setVisible(true)
						self.signButton:setEnable(true)
						self.signButton.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_ready"))--进入战场
						self.panelUI:getChildByName("txt_12"):setVisible(false)

						self.panelUI:getChildByName("txt_13"):setVisible(true)
						self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_success"))--您的军团竞标成功，快去准备攻打城池吧
					else
						--报名失败
						self.signButton:setVisible(false)
						self.signButton:setEnable(false)
						self.panelUI:getChildByName("txt_12"):setVisible(true)
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_lose"))--很遗憾，您的军团本城池竞标失败，无缘夺城战
					end
				else
					--未报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FORM then
			--第一轮调整阵型
			if UnionPkCityData.myUnionIsDefencer(self.cityData) or (self.cityData.report and self.cityData.successfulBid) then
				--自己是守方 or 竞标过且竞标成功
				if UnionPkCityData.myUnionIsDefencer(self.cityData) then
					self.panelUI:getChildByName("txt_13"):setVisible(true)
					self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text9"))--您的军团为守城方，快去战场准备防御吧
				else
					self.panelUI:getChildByName("txt_13"):setVisible(true)
					self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_success"))--您的军团竞标成功，快去准备攻打城池吧
				end

				if UnionPkCityData.isMyChallengCity(self.cityData) or UnionTitleManager.canChangeForm() then
					--自己已报名此城池 或者有权限打开战场UI
					self.panelUI:getChildByName("txt_12"):setVisible(false)
					self.signButton:setVisible(true)
					self.signButton:setEnable(true)
					self.signButton.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_ready"))--进入战场
				else
					--自己未报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text2"))--主公，您没有报名本城池战场
				end
			else
				--未竞标 or 竞标失败 (且排除守方)
				self.signButton:setVisible(false)
				self.signButton:setEnable(false)
				self.panelUI:getChildByName("txt_12"):setVisible(true)
				if not self.cityData.report then
					--未竞标
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
				else
					--不是未竞标 那只可能是竞标失败
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_lose"))--很遗憾，您的军团本城池竞标失败，无缘夺城战
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FIGHT then
			--第一轮等待结果
			if UnionPkCityData.myUnionIsDefencer(self.cityData) or (self.cityData.report and self.cityData.successfulBid) then
				--自己是守方 or 竞标过且竞标成功
				if UnionPkCityData.isMyChallengCity(self.cityData) or UnionTitleManager.canChangeForm() then
					--自己已报名此城池 或者有权限打开战场UI
					self.panelUI:getChildByName("txt_12"):setVisible(false)
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)

					local startTime, endTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND1_FIGHT)
					self.cdLabelComponent:setTargetTime(endTime + 1)
					self.cdLabelComponent:start()

					self.panelUI:getChildByName("txt_14"):setVisible(true)
					self.panelUI:getChildByName("txt_15"):setVisible(true)
					self.panelUI:getChildByName("txt_14"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_one"))--第一场团战正在计算中：
				else
					--自己未报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text2"))--主公，您没有报名本城池战场
				end
			else
				--未竞标 or 竞标失败 (且排除守方)
				self.signButton:setVisible(false)
				self.signButton:setEnable(false)
				self.panelUI:getChildByName("txt_12"):setVisible(true)
				if not self.cityData.report then
					--未竞标
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
				else
					--不是未竞标 那只可能是竞标失败
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_lose"))--很遗憾，您的军团本城池竞标失败，无缘夺城战
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FORM then
			--第二轮调整阵型
			if UnionPkCityData.myUnionIsDefencer(self.cityData) or (self.cityData.report and self.cityData.successfulBid) then
				--自己是守方 or 竞标过且竞标成功
				if UnionPkCityData.myUnionIsDefencer(self.cityData) then
					self.panelUI:getChildByName("txt_13"):setVisible(true)
					self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text9"))--您的军团为守城方，快去战场准备防御吧
				else
					self.panelUI:getChildByName("txt_13"):setVisible(true)
					self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_success"))--您的军团竞标成功，快去准备攻打城池吧
				end
				
				if UnionPkCityData.isMyChallengCity(self.cityData) or UnionTitleManager.canChangeForm() then
					--自己已报名此城池 或者有权限打开战场UI
					if self.firstBattleFailed then
						--第一场失败
						self.signButton:setVisible(false)
						self.signButton:setEnable(false)
						self.panelUI:getChildByName("txt_12"):setVisible(true)
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_lose"))--您的军团本轮团战战斗失败
					else
						--第一场没有失败
						self.panelUI:getChildByName("txt_12"):setVisible(false)
						self.signButton:setVisible(true)
						self.signButton:setEnable(true)
						self.signButton.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_ready"))--进入战场
					end
				else
					--自己未报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text2"))--主公，您没有报名本城池战场
				end
			else
				--未竞标 or 竞标失败 当然也没准是守方被攻打下来 (且排除守方)
				self.signButton:setVisible(false)
				self.signButton:setEnable(false)
				self.panelUI:getChildByName("txt_12"):setVisible(true)
				if self.inBattle then
					--当前玩家所在军团曾经出现在战报中 说明曾经是守方 现在被击败
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_lose"))--您的军团本轮团战战斗失败
				else
					--不是历史守方 仅仅是没竞标或者竞标失败而已
					if not self.cityData.report then
						--未竞标
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
					else
						--不是未竞标 那只可能是竞标失败
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_lose"))--很遗憾，您的军团本城池竞标失败，无缘夺城战
					end
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FIGHT then
			--第二轮等待结果
			
			if UnionPkCityData.myUnionIsDefencer(self.cityData) or (self.cityData.report and self.cityData.successfulBid) then
				--自己是守方 or 竞标过且竞标成功
				if UnionPkCityData.isMyChallengCity(self.cityData) or UnionTitleManager.canChangeForm() then
					--自己已报名此城池 或者有权限打开战场UI
					self.panelUI:getChildByName("txt_12"):setVisible(false)
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)

					local startTime, endTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_ROUND2_FIGHT)
					self.cdLabelComponent:setTargetTime(endTime + 1)
					self.cdLabelComponent:start()

					self.panelUI:getChildByName("txt_14"):setVisible(true)
					self.panelUI:getChildByName("txt_15"):setVisible(true)
					self.panelUI:getChildByName("txt_14"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_two"))--第二场团战正在计算中：
				else
					--自己未报名
					self.signButton:setVisible(false)
					self.signButton:setEnable(false)
					self.panelUI:getChildByName("txt_12"):setVisible(true)
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text2"))--主公，您没有报名本城池战场
				end
			else
				--未竞标 or 竞标失败 当然也没准是守方被攻打下来 (且排除守方)
				self.signButton:setVisible(false)
				self.signButton:setEnable(false)
				self.panelUI:getChildByName("txt_12"):setVisible(true)
				if self.inBattle then
					--当前玩家所在军团曾经出现在战报中 说明曾经是守方 现在被击败
					self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_lose"))--您的军团本轮团战战斗失败
				else
					--不是历史守方 仅仅是没竞标或者竞标失败而已
					if not self.cityData.report then
						--未竞标
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text1"))--您的军团未报名本城池
					else
						--不是未竞标 那只可能是竞标失败
						self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_lose"))--很遗憾，您的军团本城池竞标失败，无缘夺城战
					end
				end
			end

		elseif self.currentTimeLevel == UnionPkConsts.TIME_REWARD then
			--领奖阶段
			self.signButton:setVisible(false)
			self.signButton:setEnable(false)
			self.panelUI:getChildByName("txt_12"):setVisible(true)
			self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text3"))--本轮团战结束
		else
			--皆非也
			if SystemManager.debug then
				DebugManager.addError("非法时间段! 编号: " .. tostringRich(self.currentTimeLevel))
			end
		end

		if self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FORM or 
		self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FIGHT then
			--
			self.panelUI:getChildByName("btn_guildppk_reguistred_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_text5"))--第一场团战战报
		elseif self.currentTimeLevel == UnionPkConsts.TIME_REWARD then
			--领奖阶段
			self.panelUI:getChildByName("btn_guildppk_reguistred_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_now"))--本輪戰報
		else
			--
			self.panelUI:getChildByName("btn_guildppk_reguistred_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_last"))--上轮战报
		end
	end
	self.refreshSelf = refreshSelf

	--倒计时tick
	function onTimeTick(remainedSec)
		--print("remainedSec = " .. remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		--print("formatedTimeStr = " .. formatedTimeStr)
		self.panelUI:getChildByName("txt_15"):getChildByName("txt"):setString(formatedTimeStr)
	end
	self.onTimeTick = onTimeTick

	--倒计时结束
	function onTimeComplete()
		--暂时不用处理 因为有接收刷新消息
	end
	self.onTimeComplete = onTimeComplete


	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)
	self.cdLabelComponent:stop()

	--固定文字
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(UnionPkUtils.getCityNameById(self.cityData.cityId))--[城池名称]
	if UnionPkCityData.haveCaptureUnion(self.cityData) then
		self.panelUI:getChildByName("icon_lv"):setVisible(true)
		self.panelUI:getChildByName("txt_2"):setVisible(true)
		self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.cityData.unionName)--[占领军团]
		self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(self.cityData.unionLevel)--[占领军团lv]

		--描边
		self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setColor(ccc3(255, 231, 24))
		self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setAroundColor(ccc3(102, 0, 0))
		self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setColor(ccc3(255, 231, 24))
		self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setAroundColor(ccc3(102, 0, 0))
	else
		self.panelUI:getChildByName("icon_lv"):setVisible(false)
		self.panelUI:getChildByName("txt_2"):setVisible(false)
		self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(UnionPkUtils.getCityNpcNameById(self.cityData.cityId))--无
	end
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_defence"))--城防加成：
	local defenceBuff = UnionPkConfig.cityDefenceBuffNow(self.cityData.occupyNum-1)
	if defenceBuff >= 0 then
		defenceBuff = "+"..tostring(defenceBuff)
	end
	self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(defenceBuff .. "%")--[城防加成]%
	self.panelUI:getChildByName("txt_7"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_defence2"))--（同一军团占领，每轮战后将降低加成）

	-- self.panelUI:getChildByName("xxxxxxxxxx"):getChildByName("txt"):setString("xxx")--
	-- self.panelUI:getChildByName("xxxxxxxxxx"):getChildByName("txt"):setString("xxx")--

	self:setRewardShow(self.panelUI:getChildByName("bank_item_1"), getTextByKey("UnionWar_sign_head"), UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(self.cityData.cityId, UnionManager.TITLE_MANAGER))
	self:setRewardShow(self.panelUI:getChildByName("bank_item_2"), getTextByKey("UnionWar_sign_elite"), UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(self.cityData.cityId, UnionManager.TITLE_ELITE_MEMBER))
	self:setRewardShow(self.panelUI:getChildByName("bank_item_3"), getTextByKey("UnionWar_sign_normal"), UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(self.cityData.cityId, UnionManager.TITLE_MEMBER))


	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local checkSignButton = Button:create(self.panelUI:getChildByName("btn_distribution_signup"))
	self.panelUI:getChildByName("btn_distribution_signup"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_check"))--查看报名
	checkSignButton:addEventListener(Events.kStart,onCheckSignClick, self)

	local checkHistroyButton = Button:create(self.panelUI:getChildByName("btn_guildppk_reguistred_2"))
	checkHistroyButton:addEventListener(Events.kStart,onCheckHistroyClick, self)

	self.signButton = Button:create(self.panelUI:getChildByName("btn_distribution_confirm"))
	self.signButton:addEventListener(Events.kStart,onSignClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_USERDATA_UPDATE, self.refreshSelf, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)

	self.refreshSelf()
end

function UnionPkCityInfoPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_USERDATA_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	UnionPkCityInfoPopPanel.super.dispose(self)
end

function UnionPkCityInfoPopPanel:setTableViewsEnabled(v)
end

--关闭对话框
function UnionPkCityInfoPopPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

function UnionPkCityInfoPopPanel:setRewardShow(itemUI, titleStr, propId)
	itemUI:getChildByName("txt_guild_pk_3"):getChildByName("txt"):setString(titleStr)--

	--itemUI:getChildByName("common_frame_card"):setVisible(false)
	local aGoodIcon = itemUI:getChildByName("common_frame_card")
	local params = {}
	params.sourceDisplay = aGoodIcon
	params.container = itemUI
	params.showInCenter = true
	params.zindex = 100
	local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.PROP, propId, 1, params)

	local propMeta = MetaManager.prop_meta[propId]
	if SystemManager.debug then
		DebugManager.assert(propMeta ~= nil, "没有这个礼包道具! propId = " .. tostringRich(propId))
	end
	local rewardId = propMeta.effectValue

	local btn = Button:create(itemUI)
	btn:addEventListener(Events.kStart,onClickReward, rewardId)
end