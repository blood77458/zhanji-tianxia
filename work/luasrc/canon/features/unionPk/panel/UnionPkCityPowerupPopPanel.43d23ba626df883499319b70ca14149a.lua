-- UnionPkCityPowerupPopPanel.lua
-- zheng.che
-- 2014-8-26
-- 军团战 鼓舞二级

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

--点击关闭
local function onClose(evt)
	local self = evt.context

	--玩家自己点击的关闭 先回到城镇信息窗口
	UnionPK.showCityInfoPanel(self.cityData.cityId)

	self:close()
end

--点击修改阵型
local function onModifyClick(evt)
	local self = evt.context

	local tempTimeLevel = UnionPkData.getCurrTimeLevel()
	if tempTimeLevel ~= self.enterTimeLevel and tempTimeLevel ~= UnionPkConsts.TIME_ROUND1_FORM and tempTimeLevel ~= UnionPkConsts.TIME_ROUND2_FORM then
		--点击按钮的时间阶段和进入UI时不一致 并且点击时不在调整时间
		local function onConfirme()
			--回到城镇信息窗口
			UnionPK.showCityInfoPanel(self.cityData.cityId)
			self:close()
		end
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt9"), onConfirme)--阵型调整时间已过
		--强制结束流程
		return
	end

	if UnionPkCheck.canModifiyForm(tempTimeLevel, true) then
		--现在可以修改阵型
		UnionPK.showChangeFormationPanel(self.cityData)
		self:close()
	end
end

--点击银币鼓舞
local function onPower1Click(evt)
	local self = evt.context

	local tempTimeLevel = UnionPkData.getCurrTimeLevel()
	if tempTimeLevel ~= self.enterTimeLevel and (not UnionPkCheck.isInPowerupTime(tempTimeLevel, false)) then
		--点击按钮的时间阶段和进入UI时不一致 并且鼓舞时间已过(自己做提示)
		local function onConfirme()
			--回到城镇信息窗口
			UnionPK.showCityInfoPanel(self.cityData.cityId)
			self:close()
		end
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt10"), onConfirme)--buff鼓舞时间已过
		return
	end

	if UnionPkCheck.canPowerup(self.currentTimeLevel, self.cityData.cityId, UnionPkConsts.POWERUP_SILVER, self.cityFormationData, true) then
		--允许鼓舞
		if UnionPkData.getPowerupSilverConfirmed() then
			--玩家确认过
			local function onAfterSucceed(requestEvt)
				self.refreshData()
			end
			UnionPkPowerupRequest.sendRequestDefalut(self.cityData.cityId, UnionPkConsts.POWERUP_SILVER, onAfterSucceed)
		else
			function onConfirm()
				--玩家确认
				UnionPkData.setPowerupSilverConfirmed(true)
				local function onAfterSucceed(requestEvt)
					self.refreshData()
				end
				UnionPkPowerupRequest.sendRequestDefalut(self.cityData.cityId, UnionPkConsts.POWERUP_SILVER, onAfterSucceed)
			end
			CanonMessageBox.showAsConfirmBox(getTextByKey("UnionWar_battle_text4", {num1=UnionPkConfig.silverBuffCost(), num2=UnionPkConfig.silverBuff().."%"}), onConfirm, nil)--花费{num1}银币在本场团战中增加自身{num2}攻防
		end
	end
end

--点击金币鼓舞
local function onPower2Click(evt)
	local self = evt.context

	local tempTimeLevel = UnionPkData.getCurrTimeLevel()
	if tempTimeLevel ~= self.enterTimeLevel and (not UnionPkCheck.isInPowerupTime(tempTimeLevel, false)) then
		--点击按钮的时间阶段和进入UI时不一致 并且鼓舞时间已过(自己做提示)
		local function onConfirme()
			--回到城镇信息窗口
			UnionPK.showCityInfoPanel(self.cityData.cityId)
			self:close()
		end
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt10"), onConfirme)--buff鼓舞时间已过
		return
	end

	if UnionPkCheck.canPowerup(self.currentTimeLevel, self.cityData.cityId, UnionPkConsts.POWERUP_GOLD, self.cityFormationData, true) then
		--允许鼓舞
		if UnionPkData.getPowerupGoldConfirmed() then
			--玩家确认过
			local function onAfterSucceed(requestEvt)
				self.refreshSelf(true)--列表也刷新
			end
			UnionPkPowerupRequest.sendRequestDefalut(self.cityData.cityId, UnionPkConsts.POWERUP_GOLD, onAfterSucceed)
		else
			function onConfirm()
				--玩家确认
				UnionPkData.setPowerupGoldConfirmed(true)
				local function onAfterSucceed(requestEvt)
					self.refreshSelf(true)--列表也刷新
				end
				UnionPkPowerupRequest.sendRequestDefalut(self.cityData.cityId, UnionPkConsts.POWERUP_GOLD, onAfterSucceed)
			end
			CanonMessageBox.showAsConfirmBox(getTextByKey("UnionWar_battle_text5", {num1=UnionPkConfig.goldBuffCost(), num2=UnionPkConfig.goldBuff().."%"}), onConfirm, nil)--花费{num1}金币在本场团战中增加全体团员{num2}攻防
		end
	end
end

--点击奋力一击
local function onPower3Click(evt)
	local self = evt.context

	local tempTimeLevel = UnionPkData.getCurrTimeLevel()
	if tempTimeLevel ~= self.enterTimeLevel and (not UnionPkCheck.isInPowerupTime(tempTimeLevel, false)) then
		--点击按钮的时间阶段和进入UI时不一致 并且鼓舞时间已过(自己做提示)
		local function onConfirme()
			--回到城镇信息窗口
			UnionPK.showCityInfoPanel(self.cityData.cityId)
			self:close()
		end
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt10"), onConfirme)--buff鼓舞时间已过
		return
	end
	
	if UnionPkCheck.canPowerup(self.currentTimeLevel, self.cityData.cityId, UnionPkConsts.POWERUP_STRIKE, self.cityFormationData, true) then
		--允许鼓舞
		function onConfirm()
			--玩家确认
			local function onAfterSucceed(requestEvt)
				self.refreshData()
			end
			UnionPkPowerupRequest.sendRequestDefalut(self.cityData.cityId, UnionPkConsts.POWERUP_STRIKE, onAfterSucceed)
		end
		CanonMessageBox.showAsConfirmBox(getTextByKey("UnionWar_battle_text6", {num1=UnionPkConfig.striveCost()}), onConfirm, nil)--花费{num1}金币在本场团战中增加一次连胜次数
	end
end

--点击查看第一轮战报
local function onCheckRound11Click(evt)
	local self = evt.context
	UnionPkGetBattleReportRequest.sendRequestDefalut(self.cityData.cityId, 1)--第一轮
end

------------------------------------------------------------------------------------------------------

UnionPkCityPowerupPopPanel = class(Layer)

function UnionPkCityPowerupPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionPkCityPowerupPopPanel:create( container, cityData, cityFormationData)
	local s = UnionPkCityPowerupPopPanel.new()
	s:initLayer(container, cityData, cityFormationData)
	return s
end

function UnionPkCityPowerupPopPanel:initLayer(container, cityData, cityFormationData)
	UnionPkCityPowerupPopPanel.super.initLayer(self)
    
	self.container = container
	self.cityData = cityData
	self.cityFormationData = cityFormationData

	--计算列表显示内容
	--例: 有头阵 阵首3人 阵中2人 阵尾1人
	--{nil, {头阵}, nil}
	--{{阵首1}, {阵中1}, {阵尾1}}
	--{{阵首2}, {阵中2}, nil}
	--{{阵首3}, nil, nil}
	self.dataList = {}
	if cityFormationData.unionFormation and cityFormationData.unionFormation.forwardInfo then
		--有阵型和头阵
		table.insert(self.dataList, {nil, cityFormationData.unionFormation.forwardInfo, nil})--头阵
		local maxColumn = math.max(#cityFormationData.unionFormation.formationHeadInfo, math.max(#cityFormationData.unionFormation.formationMiddleInfo, #cityFormationData.unionFormation.formationTailInfo) )
		if maxColumn > 0 then
			for i=1,maxColumn do
				table.insert(self.dataList, {cityFormationData.unionFormation.formationHeadInfo[i], cityFormationData.unionFormation.formationMiddleInfo[i], cityFormationData.unionFormation.formationTailInfo[i]})
			end
		end
	end

	--得到本期活动开始时间
	local lastestStartTime = UnionPkUtils.findLatestBeginTime()
	self.currentTimeLevel = UnionPkData.getCurrTimeLevel()
	--print("self.currentTimeLevel = " .. tostringRich(self.currentTimeLevel))
	self.enterTimeLevel = self.currentTimeLevel

	--处理谁vs谁
	--防守方
	local defenceUnionData = cityFormationData.sharkUnionCityApply[1]
	--进攻方1
	local attack1UnionData = cityFormationData.sharkUnionCityApply[2]
	--进攻方2
	local attack2UnionData = cityFormationData.sharkUnionCityApply[3]

	--当前时刻的防守方
	local currDefUnion = nil
	--当前时刻的进攻方
	local currAtkUnion = nil

	--要显示的防守方
	local showDefUnion = nil
	--要显示的进攻方
	local showAtkUnion = nil

	--自己身处的军团是否属于当前某方
	local isInCurrFight = false
	--玩家自己的军团id
	local myUnionId = UnionManager.getMyUnionId()
	--print("myUnionId = " .. tostringRich(myUnionId))

	local currRound = UnionPkUtils.findCurrentRoundByTimeLevel(self.currentTimeLevel)
	--print("currRound = " .. tostringRich(currRound))

	--当后端已经计算出结果时 需要处理需要还原现场的情况(因为前端认为还没结束)
	if cityFormationData.loserUnionCityApply[1] then
		--第一轮已经出现胜利/失败方 说明结果已出
		--还原现场
		if attack1UnionData.unionId == cityFormationData.winnerUnionCityApply[1].unionId then
			--第一轮的进攻方是第一轮胜利者 说明第一轮防守方式第一轮失败者
			defenceUnionData = cityFormationData.loserUnionCityApply[1]
		else
			--第一轮防守方是第一轮胜利者
			defenceUnionData = cityFormationData.winnerUnionCityApply[1]
		end
	end

	if currRound == 1 or self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
		--第一轮
		currDefUnion = defenceUnionData
		currAtkUnion = attack1UnionData

		if attack2UnionData and attack2UnionData.unionId == myUnionId then
			--自己的军团在第二场才开始
			isInCurrFight = false

			showDefUnion = nil--还不知道防御方是谁
			showAtkUnion = attack2UnionData
		else
			--自己参与第一轮
			isInCurrFight = true

			showDefUnion = currDefUnion
			showAtkUnion = currAtkUnion
		end
	elseif currRound == 2 then
		--第二轮
		if cityFormationData.winnerUnionCityApply[1] and cityFormationData.winnerUnionCityApply[1].unionId == defenceUnionData.unionId then
			--第一轮的胜利方是当时的守城军团
			currDefUnion = defenceUnionData
		else
			currDefUnion = attack1UnionData
		end
		currAtkUnion = attack2UnionData

		--判定是否在当前轮战斗中
		local isDef = currDefUnion and (currDefUnion.unionId == myUnionId)
		local isAtk = currAtkUnion and (currAtkUnion.unionId == myUnionId)
		if isDef or isAtk then
			isInCurrFight = true
		else
			isInCurrFight = false
		end

		if not isInCurrFight then
			--自己军团无缘本轮战斗 显示内容有差异 改为显示上一轮的战斗军团
			showDefUnion = defenceUnionData
			showAtkUnion = attack1UnionData
		else
			--正常显示
			showDefUnion = currDefUnion
			showAtkUnion = currAtkUnion
		end
	else
		--不在任何一轮的情况
		isInCurrFight = false
	end
	-- print("currDefUnion = " .. tostringRich(currDefUnion))
	-- print("currAtkUnion = " .. tostringRich(currAtkUnion))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guildpk_formation")

	self:addChild(self.panelUI)

	--刷新自身
	function refreshData()
		--鼓舞增加量
		if self.cityData.cityId == UnionManager.getChallengeCityId() then
			--自己报名的城池是这个城池
			self.panelUI:getChildByName("txt_7"):getChildByName("txt"):setString( "+" .. (UnionManager.getCoinInspireNum()*UnionPkConfig.silverBuff()) .. "%" )--[银币鼓舞增加量]
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString( "+" .. (UnionManager.getGemInspireNum()*UnionPkConfig.goldBuff()) .. "%" )--[金币鼓舞增加量]
		else
			--自己没报名此城池
			self.panelUI:getChildByName("txt_7"):getChildByName("txt"):setString( "+0%" )--[银币鼓舞增加量]
			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString( "+0%" )--[金币鼓舞增加量]
		end

		if UnionManager.getStriveInspireNum() >= UnionPkConfig.striveNum() then
			--奋力一击达到上限 按钮不可用
			self.panelUI:getChildByName("txt_9"):setVisible(true)
			self.panelUI:getChildByName("txt_9"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_done1"))--完事
			self.power3Button:setEnable(false)
		else
			--按钮可用
			self.panelUI:getChildByName("txt_9"):setVisible(false)
			self.power3Button:setEnable(true)
		end

		--拥有金币银币数量
		self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(CalculationManager.calcComplex_getGemsNow())--[金币总数]
		self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(DataManager.getCurrUser().coins)--[银币总数]
	end
	self.refreshData = refreshData

	--刷新自身
	function refreshSelf(keepOffset)
		if self.listTableView then
			--刷新列表
			if keepOffset then
				--保持列表位置
				local tableOffset = self.listTableView:getContentOffset()
				self.listTableView:reloadData()
				self.listTableView:setContentOffset(tableOffset, true)
			else
				self.listTableView:reloadData()
			end
		end
		
		self.currentTimeLevel = UnionPkData.getCurrTimeLevel()
		--print("self.currentTimeLevel = " .. tostringRich(self.currentTimeLevel))

		--当后端已经计算出结果时 需要处理需要还原现场的情况(因为前端认为还没结束)
		if cityFormationData.loserUnionCityApply[1] then
			--第一轮已经出现胜利/失败方 说明结果已出
			--还原现场
			if attack1UnionData.unionId == cityFormationData.winnerUnionCityApply[1].unionId then
				--第一轮的进攻方是第一轮胜利者 说明第一轮防守方式第一轮失败者
				defenceUnionData = cityFormationData.loserUnionCityApply[1]
			else
				--第一轮防守方是第一轮胜利者
				defenceUnionData = cityFormationData.winnerUnionCityApply[1]
			end
		end

		--重新计算当前是谁vs谁
		currRound = UnionPkUtils.findCurrentRoundByTimeLevel(self.currentTimeLevel)
		--print("currRound = " .. tostringRich(currRound))
		if currRound == 1 or self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
			--第一轮
			currDefUnion = defenceUnionData
			currAtkUnion = attack1UnionData

			if attack2UnionData and attack2UnionData.unionId == myUnionId then
				--自己的军团在第二场才开始
				isInCurrFight = false

				showDefUnion = nil--还不知道防御方是谁
				showAtkUnion = attack2UnionData
			else
				--自己参与第一轮
				isInCurrFight = true

				showDefUnion = currDefUnion
				showAtkUnion = currAtkUnion
			end
		elseif currRound == 2 then
			--第二轮

			if cityFormationData.winnerUnionCityApply[1] and cityFormationData.winnerUnionCityApply[1].unionId == defenceUnionData.unionId then
				--第一轮的胜利方是当时的守城军团
				currDefUnion = defenceUnionData
			else
				currDefUnion = attack1UnionData
			end
			currAtkUnion = attack2UnionData

			--判定是否在当前轮战斗中
			local isDef = currDefUnion and (currDefUnion.unionId == myUnionId)
			local isAtk = currAtkUnion and (currAtkUnion.unionId == myUnionId)
			if isDef or isAtk then
				isInCurrFight = true
			else
				isInCurrFight = false
			end

			if not isInCurrFight then
				--自己军团无缘本轮战斗 显示内容有差异 改为显示上一轮的战斗军团
				showDefUnion = defenceUnionData
				showAtkUnion = attack1UnionData
			else
				--正常显示
				showDefUnion = currDefUnion
				showAtkUnion = currAtkUnion
			end
		else
			--不在任何一轮的情况 理论不应出现
			print("不在任何一轮的情况 self.currentTimeLevel = " .. tostringRich(self.currentTimeLevel))
			isInCurrFight = false
		end

		
		if UnionPkCheck.canSeeModifiyFormBtn(self.currentTimeLevel, isInCurrFight, (not isInCurrFight)) then
			--显示 调整阵型 按钮
			self.modifyButton:setVisible(true)
		else
			self.modifyButton:setVisible(false)
		end

		--显示标题
		if currRound == 1 or self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
			--当前是第一场 或者参与阶段
			if isInCurrFight then
				--当前军团出现在第一场
				self.panelUI:getChildByName("txt_title"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_first"))--军团战第一场
			else
				--本场没有当前军团 所以将会出现在第二场
				self.panelUI:getChildByName("txt_title"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_second"))--军团战第二场
			end
		else
			self.panelUI:getChildByName("txt_title"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_second"))--军团战第二场
		end

		--刷新显示pk关系
		if showDefUnion then
			self.panelUI:getChildByName("icon_flags_green"):setVisible(true)
			self.panelUI:getChildByName("txt_2"):setVisible(true)
			self.btnShowUnknowInfo:setVisible(false)
			self.btnShowUnknowInfo:setEnable(false)

			if showDefUnion.unionId ~= 0 then
				--是真实军团
				self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(showDefUnion.unionName or "")--[军团名称]
			else
				self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(UnionPkUtils.getCityNpcNameById(self.cityData.cityId))--[npc军团名称]
			end
		else
			self.panelUI:getChildByName("icon_flags_green"):setVisible(false)
			self.panelUI:getChildByName("txt_2"):setVisible(false)
			self.btnShowUnknowInfo:setVisible(true)
			self.btnShowUnknowInfo:setEnable(true)
		end

		if showAtkUnion then
			self.panelUI:getChildByName("icon_flags_red"):setVisible(true)
			self.panelUI:getChildByName("txt_1"):setVisible(true)

			if showAtkUnion.unionId ~= 0 then
				--是真实军团
				self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(showAtkUnion.unionName or "")--[军团名称]
			else
				self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(UnionPkUtils.getCityNpcNameById(self.cityData.cityId))--[npc军团名称]
			end
		else
			--一定是在第一场 无法决定第二场谁是进攻者的情况
			self.panelUI:getChildByName("icon_flags_red"):setVisible(false)
			self.panelUI:getChildByName("txt_1"):setVisible(false)
		end

		--刷新人数
		local currMemberCount = 0
		if cityFormationData.unionFormation then
			currMemberCount = 1 + #cityFormationData.unionFormation.formationHeadInfo + #cityFormationData.unionFormation.formationMiddleInfo + #cityFormationData.unionFormation.formationTailInfo
		end
		
		self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_people") .. currMemberCount .. "/" .. UnionPkConfig.cityTotalMemberLimit())--当前人数: [当前人数]/[最大人数]

		self.refreshData()
	end
	self.refreshSelf = refreshSelf

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	self.modifyButton = Button:create(self.panelUI:getChildByName("btn_guildppk_reguistred"), true)
	self.panelUI:getChildByName("btn_guildppk_reguistred"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_adjust"))--调整阵型
	self.modifyButton:addEventListener(Events.kStart,onModifyClick, self)

	--刷新下方显示的内容
	--固定文字
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_mine"))--增加自身属性
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_union"))--增加全团属性
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_win"))--连胜次数+1
	self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(getTextByKey("UnionWar_gold_now"))--当前拥有：

	--按钮
	self.power1Button = Button:create(self.panelUI:getChildByName("btn_1"), true)--存在灰色状态
	self.power1Button:addEventListener(Events.kStart,onPower1Click, self)

	self.power2Button = Button:create(self.panelUI:getChildByName("btn_2"), true)--存在灰色状态
	self.power2Button:addEventListener(Events.kStart,onPower2Click, self)

	self.power3Button = Button:create(self.panelUI:getChildByName("btn_3"), true)--存在灰色状态
	self.power3Button:addEventListener(Events.kStart,onPower3Click, self)

	--查看未知军团信息
	local function onCheckUnknownUnionInfo( evt )
		local self = evt.context
		local function onConfirm()

			local curTimeLevel = UnionPkData.getCurrTimeLevel()
			if curTimeLevel ~= self.currentTimeLevel then
				if curTimeLevel == UnionPkConsts.TIME_ROUND2_FORM
				or curTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY
				or curTimeLevel == UnionPkConsts.TIME_ROUND1_FORM then
					local function onAfterSucceed(evt)
						self.cityFormationData = evt.data
						self.refreshSelf(true)
					end
					UnionPkGetCityFormationRequest.sendRequestDefalut(self.cityData.cityId, onAfterSucceed)
				else
					UnionPK.showCityInfoPanel(self.cityData.cityId)
					self:close()
				end
			end

		end
		local curAtkUnionName
		local curDefUnionName
		if currAtkUnion.unionId ~= 0 then
			--是真实军团
			curAtkUnionName = currAtkUnion.unionName or ""
		end
		if currDefUnion.unionId ~= 0 then
			--是真实军团
			curDefUnionName = currDefUnion.unionName or ""
		else
			curDefUnionName = UnionPkUtils.getCityNpcNameById(self.cityData.cityId)
		end

		local function getStartAndEndTime(timeConsts)
			local TimeMeta = UnionPkConfig.getLevelTimeMeta(timeConsts)
			local StartTime = lastestStartTime + TimeMeta.warBeginTime * 60
			local EndTime = StartTime + TimeMeta.warContinueTime * 60

			local StartTimeStr = TimeUtil.formatDate(StartTime, "UnionWar_sign_time3")
			local EndTimeStr = TimeUtil.formatDate(EndTime, "UnionWar_sign_time3")
			return StartTimeStr , EndTimeStr
		end
		local str = getTextByKey("UnionWar_supple_time6" , {num1 = getStartAndEndTime(UnionPkConsts.TIME_ROUND2_FIGHT)}) 

		local str2 = getTextByKey("UnionWar_supple_time9", {num1=curAtkUnionName , num2 = curDefUnionName})

		CanonMessageBox.showTextBox(str..str2 , onConfirm)
	end

	self.btnShowUnknowInfo = Button:create(self.panelUI:getChildByName("icon_flags_unknown"))--存在灰色状态
	self.btnShowUnknowInfo:addEventListener(Events.kStart,onCheckUnknownUnionInfo, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_USERDATA_UPDATE, self.refreshSelf, self)

	if #self.dataList > 0 then
		--显示列表
		self.panelUI:getChildByName("txt_10"):setVisible(false)
		
		self.listTableView = self:createListTableView()
		self:addChild(self.listTableView)
		self.listTableView:reloadData()
	else
		--显示文字提示
		self.panelUI:getChildByName("txt_10"):setVisible(true)
		self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_error_txt22"))
	end
	self.panelUI:getChildByName("table_formation_list3"):setVisible(false)

	self.refreshSelf()
end

function UnionPkCityPowerupPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_USERDATA_UPDATE, self.refreshSelf)

	UnionPkCityPowerupPopPanel.super.dispose(self)
end

function UnionPkCityPowerupPopPanel:setTableViewsEnabled(v)
	if self.listTableView then--不加会崩 不必现
		self.listTableView:setTouchEnabled(v)
	end
end

--关闭对话框
function UnionPkCityPowerupPopPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--------------------------------------------------------------------------------------------------------------------------------------tableview

function UnionPkCityPowerupPopPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aListPanel = self
	local UnionPkPowerupListTableViewRenderer = class(TableViewRenderer)
	function UnionPkPowerupListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionPkPowerupListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/formation_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		--

		local lowerDisplay = aCell:getChildByName("bg_pioneer")
		lowerDisplay:setTag(-1002)

		for i = 1, 3 do
			local memberDisplay = aCell:getChildByName("item_employees" .. i)
			memberDisplay:setTag(-100 - i)

			local aCardDisplay = memberDisplay:getChildByName("normal_card_small")
			aCardDisplay:setTag(-10)

			local aNameLabel = memberDisplay:getChildByName("txt_1")
			aNameLabel:setTag(-11)
			aNameLabel = aNameLabel:getChildByName("txt")
			aNameLabel:setTag(-11)

			local aBroadDisplay = memberDisplay:getChildByName("equipBorder8")
			aBroadDisplay:setTag(-12)

			local aGoldDisplay = memberDisplay:getChildByName("icon_gold_inspire_number")
			aGoldDisplay:setTag(-13)

			local aGoldLabelDisplay = memberDisplay:getChildByName("txt_2")
			aGoldLabelDisplay:setTag(-14)
			aGoldLabelDisplay = aGoldLabelDisplay:getChildByName("txt")
			aGoldLabelDisplay:setTag(-11)
			--描边
			aGoldLabelDisplay:setColor(ccc3(255, 255, 255))
			aGoldLabelDisplay:setAroundColor(ccc3(66, 0, 0))
		end
	end

	function UnionPkPowerupListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		local lowerDisplay = aCell:getChildByTag(-1002)
		--print("index = " .. table.tostring(index))
		if index > 0 then
			lowerDisplay:setVisible(false)
		else
			lowerDisplay:setVisible(true)
		end

		for i = 1, 3 do
			local memberDisplay = aCell:getChildByTag(-100 - i)
			local memberData = aData[i]

			local aCardDisplay = memberDisplay:getChildByTag(-10)
			local aNameLabel = memberDisplay:getChildByTag(-11)
			local aBroadDisplay = memberDisplay:getChildByTag(-12)
			local aGoldDisplay = memberDisplay:getChildByTag(-13)
			local aGoldLabelDisplay = memberDisplay:getChildByTag(-14)

			--显示先锋边框
			if index == 0 then
				--第一排 说明是先锋 理论只有一个
				aBroadDisplay:setVisible(true)
			else
				--不显示边框
				aBroadDisplay:setVisible(false)
			end


			if memberData then
				--有玩家
				memberDisplay:setVisible(true)

				--显示头像
				local oldIcon = memberDisplay:getChildByTag(-200)
				if oldIcon then
					oldIcon:removeFromParentAndCleanup(true)
				end
				local params = {}
				params.sourceDisplay = aCardDisplay
				params.showInCenter = true
				local newMeta = CommonManager:getSelfAvatarMetaByUid( memberData.uid )
				if not newMeta then
					newMeta = memberData.mainCardMeataId
				end
				local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 1, params)
				memberDisplay:addChild(icon.refCocosObj)
				if icon then
					icon:setTag(-200)
					icon:dispose()
				end

				--显示昵称
				setNodeText(aNameLabel:getChildByTag(-11), memberData.userName or "")

				--显示角标金币
				local showGemNum = memberData.gemInspireNum
				if memberData.uid == DataManager.getGameInitData().sharkUser.uid then
					--是当前玩家
					showGemNum = UnionManager.getGemInspireNum()
				end
				if showGemNum > 0 then
					--显示金币鼓舞次数
					aGoldDisplay:setVisible(true)
					aGoldLabelDisplay:setVisible(true)
					setNodeText(aGoldLabelDisplay:getChildByTag(-11), getTextByKey("UnionWar_attend_supple", {num1 = showGemNum}))--鼓：{num1}次

				else
					--没金币鼓舞
					aGoldDisplay:setVisible(false)
					aGoldLabelDisplay:setVisible(false)
				end
			else
				--没有玩家
				aGoldDisplay:setVisible(false)
				aGoldLabelDisplay:setVisible(false)

				if index > 0 then
					memberDisplay:setVisible(true)

					--显示默认头像
					local oldIcon = memberDisplay:getChildByTag(-200)
					if oldIcon then
						oldIcon:removeFromParentAndCleanup(true)
					end
					local params = {}
					params.sourceDisplay = aCardDisplay
					params.showInCenter = true
					local icon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_NONE, 0, 0, params)
					memberDisplay:addChild(icon.refCocosObj)
					if icon then
						icon:setTag(-200)
						icon:dispose()
					end

					--显示默认昵称
					setNodeText(aNameLabel:getChildByTag(-11), getTextByKey("UnionWar_battle_empty"))
				else
					memberDisplay:setVisible(false)
				end
			end
		end
	end

	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_formation_list3"))
	tableViewSizes.table_height = tableViewSizes.table_height + 8--高度修正(因为上下边缘有文本框)
	tableViewSizes.table_width = tableViewSizes.table_width + 20--宽度修正(用于显示滚动条)
	tableViewSizes.table_posY = tableViewSizes.table_posY + 5--纵坐标修正(因为上下边缘有文本框)
	--print("tableViewSizes = " .. tostringRich(tableViewSizes))
	local renderer = UnionPkPowerupListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end