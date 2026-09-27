-- UnionPkChangeFormationPopPanel.lua
-- 2014-8-28
-- zheng.che
-- 军团战 调整阵型UI

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	local self = evt.context
	self:back()
end

--点击确定
local function onConfirmClick(evt)
	local self = evt.context
	local scene = Director:mgr():run()

	if self.dataChanged == true then
		--数据有变更 需要通知后端变更结果
		--先检验是否合法
		if not self.forwardMemberData then
			--没有头阵
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt2"))--阵型调整失败，阵容内未设置单挑武将，请进行设置
			return
		end

		--3列的玩家id列表
		local lines = {}
		lines[1] = {}
		lines[2] = {}
		lines[3] = {}

		for x = 1, 3 do
			--记录是否有人 默认有人
			local stateHaveData = true
			local maxColumn = UnionPkConfig.cityFrontLimit()
			for y=1,maxColumn do
				local memberData = self.dataList[y][x]
				if memberData ~= nil then
					--有人
					table.insert(lines[x], memberData.uid)
					if stateHaveData == false then
						--从上到下 出现过没人的位置 现在又遇到有人位置
						SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt1"))--阵型调整失败，您的阵容内不能存在间隔空位，请重新调整
						return
					end
				else
					--没人
					stateHaveData = false
				end
			end
		end

		--成功
		local headUids  = lines[1]
		local middleUids  = lines[2]
		local tailUids  = lines[3]
		local function onAfterSucceed(requestEvt)
			self:back()
		end
		UnionPkExchangeUnionFormationRequest.sendRequestDefalut(self.cityData.cityId, self.forwardMemberData.uid, headUids, middleUids, tailUids, onAfterSucceed)
	else
		self:back()
	end
end

--点击头阵
local function onForwardIconClick(evt)
	local self = evt.context
	local i = -1
	local aIndex = -1

	if self.currSelectPosition then
		--已有选中位置
		if  (self.currSelectPosition[1] == i) and (self.currSelectPosition[2] == aIndex) then
			--和当前位置一样
			--取消选中
			self.currSelectPosition = nil
		else
			--和当前位置不同
			--交换位置
			local currSelectData = UnionPkChangeFormationPopPanel.getPositionAtPos(self, self.currSelectPosition[1], self.currSelectPosition[2])
			local newData = UnionPkChangeFormationPopPanel.getPositionAtPos(self, i, aIndex)

			UnionPkChangeFormationPopPanel.setPositionAtPos(self, i, aIndex, currSelectData)
			UnionPkChangeFormationPopPanel.setPositionAtPos(self, self.currSelectPosition[1], self.currSelectPosition[2], newData)

			self.currSelectPosition = nil
		end
	else
		--没有选中
		--选中当前点击位置
		self.currSelectPosition = {i, aIndex}
	end

	self.refreshSelf(true)
end

------------------------------------------------------------------------------------------------------

UnionPkChangeFormationPopPanel = class(Layer)

function UnionPkChangeFormationPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionPkChangeFormationPopPanel:create( container, cityData, cityFormationData)
	local s = UnionPkChangeFormationPopPanel.new()
	s:initLayer(container, cityData, cityFormationData)
	return s
end

function UnionPkChangeFormationPopPanel:initLayer(container, cityData, cityFormationData)
	UnionPkChangeFormationPopPanel.super.initLayer(self)
    
	self.container = container
	self.cityData = cityData
	self.cityFormationData = cityFormationData

	--当前选中的头像位置 格式{x, y} 默认nil
	self.currSelectPosition = nil
	--修改过程中的阵型状态
	--self.currFormationState = table.clone(cityFormationData.unionFormation, true)
	--头阵头像
	self.forwardIcon = nil
	--头阵玩家信息 没有则为nil
	self.forwardMemberData = cityFormationData.unionFormation.forwardInfo
	--是否有数据变更 如果没有则不发请求
	self.dataChanged = false

	--计算列表显示内容
	--例: 有头阵 阵首3人 阵中2人 阵尾1人
	--{nil, {头阵}, nil}
	--{{阵首1}, {阵中1}, {阵尾1}}
	--{{阵首2}, {阵中2}, nil}
	--{{阵首3}, nil, nil}
	self.dataList = {}

	local maxColumn = UnionPkConfig.cityFrontLimit()
	if maxColumn > 0 then
		for i=1,maxColumn do
			table.insert(self.dataList, {cityFormationData.unionFormation.formationHeadInfo[i], cityFormationData.unionFormation.formationMiddleInfo[i], cityFormationData.unionFormation.formationTailInfo[i]})
		end
	end

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guildPK_formation_3")

	self:addChild(self.panelUI)

	--刷新自身
	--keepOffset 保持位置不变
	function refreshSelf(keepOffset)
		if keepOffset == nil then
			--一般来说 只有第一次调用这个函数的情况 keepOffset是false
			keepOffset = true
		end

		--刷新列表
		if keepOffset then
			--保持列表位置
			local tableOffset = self.listTableView:getContentOffset()
			self.listTableView:reloadData()
			self.listTableView:setContentOffset(tableOffset, true)
		else
			self.listTableView:reloadData()
		end

		--刷新头阵显示
		if self.forwardIcon then
			self.forwardIcon:removeFromParentAndCleanup(true)
		end
		local aCardDisplay = self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("normal_card_small")
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		if self.forwardMemberData then
			local newMeta = CommonManager:getSelfAvatarMetaByUid( self.forwardMemberData.uid )
			if not newMeta then
				newMeta = self.forwardMemberData.mainCardMeataId
			end
			self.forwardIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 0, params)
			self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.forwardMemberData.userName)
		else
			self.forwardIcon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_NONE, 0, 0, params)
			self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_empty"))--米有人
		end

		--处理选中状态
		if self.currSelectPosition then
			--已有选中位置
			if  (self.currSelectPosition[1] == -1) and (self.currSelectPosition[2] == -1) then
				--当前位置被选中 显示黄框 不显示黑底
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("bg_guildPK_selectthebox_general"):setVisible(true)
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("txt_02"):setVisible(false)
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("q_translucent_gray9_pic"):setVisible(false)
			else
				--选中的不是当前位置 显示黑底 不显示黄框
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("bg_guildPK_selectthebox_general"):setVisible(false)
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("txt_02"):setVisible(true)
				self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("q_translucent_gray9_pic"):setVisible(true)
			end
		else
			--没有任何选中 什么都不显示
			self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("bg_guildPK_selectthebox_general"):setVisible(false)
			self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("txt_02"):setVisible(false)
			self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("q_translucent_gray9_pic"):setVisible(false)
		end
		
		--设置为可穿透 这样可以触发按钮点击事件
		self.forwardIcon.touchEnabled = false
		self.forwardIcon.touchChildren = false
		--self.panelUI:addChild(self.forwardIcon)
		self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):addChildAt(self.forwardIcon, aCardDisplay:getZOrder())
	end
	self.refreshSelf = refreshSelf

	--固定文字
	self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"):getChildByName("txt_02"):getChildByName("38"):setString(getTextByKey("UnionWar_battle_exchange"))--点击更换
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_firstArray"))--阵首
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_array"))--阵中
	self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_lastArray"))--阵尾
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_head"))--团长/副团长可点击头像进行更换阵型

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("btn_guildppk_reguistred"))
	self.panelUI:getChildByName("btn_guildppk_reguistred"):getChildByName("txt"):setString(getTextByKey("yes"))--确定
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	local forwardIconButton = Button:create(self.panelUI:getChildByName("guildPK_bank_item_fdrmation_4"))
	forwardIconButton:addEventListener(Events.kStart,onForwardIconClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_ERROR_CONFIRM_EXCHANGE_TIME_PASSED, onClose, self)

	--显示列表
	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)

	self.refreshSelf()
end

function UnionPkChangeFormationPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_ERROR_CONFIRM_EXCHANGE_TIME_PASSED, onClose)

	UnionPkChangeFormationPopPanel.super.dispose(self)
end

function UnionPkChangeFormationPopPanel:setTableViewsEnabled(v)
	self.listTableView:setTouchEnabled(v)
end

--关闭对话框
function UnionPkChangeFormationPopPanel:back()
	--玩家自己点击的关闭 先回到城镇信息窗口
	local tempTimeLevel = UnionPkData.getCurrTimeLevel()
	if UnionPkCheck.canEnterBattleFieldPanel(tempTimeLevel, self.cityData, false) then
		local function onComplete()
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end
		UnionPK.showCityPowerupPanel(self.cityData, onComplete)
	else
		--此时不能返回到鼓舞界面 应该直接返回到城镇界面
		UnionPK.showCityInfoPanel(self.cityData.cityId)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
end

--------------------------------------------------------------------------------------------------------------------------------------tableview

function UnionPkChangeFormationPopPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aListPanel = self
	local UnionPkChangeFormationListTableViewRenderer = class(TableViewRenderer)
	function UnionPkChangeFormationListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionPkChangeFormationListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/formation_team_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		--

		for i = 1, 3 do
			local memberDisplay = aCell:getChildByName("item_employees" .. i)
			memberDisplay:setTag(-100 - i)

			--固定文本
			memberDisplay:getChildByName("txt_02"):getChildByName("38"):setString(getTextByKey("UnionWar_battle_exchange"))--点击更换

			local aCardDisplay = memberDisplay:getChildByName("normal_card_small")
			aCardDisplay:setTag(-10)

			local aNameLabel = memberDisplay:getChildByName("txt")
			aNameLabel:setTag(-11)
			aNameLabel = aNameLabel:getChildByName("txt")
			aNameLabel:setTag(-11)

			local aClickLabelDisplay = memberDisplay:getChildByName("txt_02")
			aClickLabelDisplay:setTag(-12)

			local aGrayDisplay = memberDisplay:getChildByName("q_translucent_gray9_pic")
			aGrayDisplay:setTag(-13)

			local aLightDisplay = memberDisplay:getChildByName("bg_guildPK_selectthebox_general")
			aLightDisplay:setTag(-14)
		end
	end

	function UnionPkChangeFormationListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		for i = 1, 3 do
			local memberDisplay = aCell:getChildByTag(-100 - i)
			local memberData = aData[i]

			local aClickLabelDisplay = memberDisplay:getChildByTag(-12)
			local aGrayDisplay = memberDisplay:getChildByTag(-13)
			local aLightDisplay = memberDisplay:getChildByTag(-14)

			if memberData then
				memberDisplay:setVisible(true)

				--显示头像
				local aCardDisplay = memberDisplay:getChildByTag(-10)
				local oldIcon = memberDisplay:getChildByTag(-100)
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
				local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 0, params)
				memberDisplay:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
				if icon then
					icon:setTag(-100)
					icon:dispose()
				end

				--显示昵称
				local aNameLabel = memberDisplay:getChildByTag(-11)
				setNodeText(aNameLabel:getChildByTag(-11), memberData.userName or "")
			else
				memberDisplay:setVisible(true)

				--显示fake头像
				local aCardDisplay = memberDisplay:getChildByTag(-10)
				local oldIcon = memberDisplay:getChildByTag(-100)
				if oldIcon then
					oldIcon:removeFromParentAndCleanup(true)
				end
				local params = {}
				params.sourceDisplay = aCardDisplay
				params.showInCenter = true
				local icon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_NONE, 0, 0, params)
				memberDisplay:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
				if icon then
					icon:setTag(-100)
					icon:dispose()
				end

				--显示昵称
				local aNameLabel = memberDisplay:getChildByTag(-11)
				setNodeText(aNameLabel:getChildByTag(-11), getTextByKey("UnionWar_battle_empty"))--米有人
			end

			--处理选中状态
			if aListPanel.currSelectPosition then
				--已有选中位置
				if  (aListPanel.currSelectPosition[1] == i) and (aListPanel.currSelectPosition[2] == (index+1)) then
					--当前位置被选中 显示黄框 不显示黑底
					aLightDisplay:setVisible(true)
					aClickLabelDisplay:setVisible(false)
					aGrayDisplay:setVisible(false)
				else
					--选中的不是当前位置 显示黑底 不显示黄框
					aLightDisplay:setVisible(false)
					aClickLabelDisplay:setVisible(true)
					aGrayDisplay:setVisible(true)
				end
			else
				--没有任何选中 什么都不显示
				aLightDisplay:setVisible(false)
				aClickLabelDisplay:setVisible(false)
				aGrayDisplay:setVisible(false)
			end
		end
	end

	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local aData = self.dataList[aIndex]

		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)

		for i = 1, 3 do
			local memberDisplay = aCell:getChildByTag(-100 - i)
			local memberData = aData[i]
			local posInCell = memberDisplay:convertToNodeSpace(evt.globalPosition)

			local cardDisplay = memberDisplay:getChildByTag(-10)
			exchangeDisplay = cardDisplay
			exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
			-- print("posInCell.x = " .. posInCell.x)
			-- print("posInCell.y = " .. posInCell.y)
			-- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
			-- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
			-- print("exchangeSize.width = " .. exchangeSize.width)
			-- print("exchangeSize.height = " .. exchangeSize.height)
			if posInCell.x > (cardDisplay:getPositionX()) and
			posInCell.x < (cardDisplay:getPositionX() + exchangeSize.width) and
			posInCell.y > (cardDisplay:getPositionY() - exchangeSize.height) and
			posInCell.y < (cardDisplay:getPositionY()) then
				--点击物品图标
				if self.currSelectPosition then
					--已有选中位置
					if  (self.currSelectPosition[1] == i) and (self.currSelectPosition[2] == aIndex) then
						--和当前位置一样
						--取消选中
						self.currSelectPosition = nil
					else
						--和当前位置不同
						--交换位置
						local currSelectData = UnionPkChangeFormationPopPanel.getPositionAtPos(self, self.currSelectPosition[1], self.currSelectPosition[2])
						local newData = UnionPkChangeFormationPopPanel.getPositionAtPos(self, i, aIndex)

						UnionPkChangeFormationPopPanel.setPositionAtPos(self, i, aIndex, currSelectData)
						UnionPkChangeFormationPopPanel.setPositionAtPos(self, self.currSelectPosition[1], self.currSelectPosition[2], newData)

						self.currSelectPosition = nil
					end
				else
					--没有选中
					--选中当前点击位置
					self.currSelectPosition = {i, aIndex}
				end

				self.refreshSelf(true)

				return
			end
		end
	end

	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_formation_list"))
	tableViewSizes.table_height = tableViewSizes.table_height + 15--高度修正(因为上下边缘有文本框)
	tableViewSizes.table_width = tableViewSizes.table_width - 10--宽度修正(用于显示滚动条)
	self.panelUI:getChildByName("table_formation_list"):setVisible(false)
	--print("tableViewSizes = " .. tostringRich(tableViewSizes))
	local renderer = UnionPkChangeFormationListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

--------------------------------------------------------------------------------------------------------------------------------------static

--获得一个位置的角色数据
function UnionPkChangeFormationPopPanel.getPositionAtPos(self, x, y)
	if (x == -1) or (y == -1) then
		--头阵
		return self.forwardMemberData
	end

	--否则 阵列中的
	return self.dataList[y][x]
end

--设置一个位置的角色数据
function UnionPkChangeFormationPopPanel.setPositionAtPos(self, x, y, v)
	--print("setPositionAtPos: " .. tostringRich({x, y, v}))

	--数据变更
	self.dataChanged = true

	if (x == -1) or (y == -1) then
		--头阵
		self.forwardMemberData = v
		return
	end

	--否则 阵列中的
	self.dataList[y][x] = v
end