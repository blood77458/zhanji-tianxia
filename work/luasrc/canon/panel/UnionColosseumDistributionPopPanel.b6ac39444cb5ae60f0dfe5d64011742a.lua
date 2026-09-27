-- UnionColosseumDistributionPopPanel.lua
-- 2014-6-4 zheng.che
-- 分配UI

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	--print("onClose")
	local self = evt.context
	--请求放弃分配结果
	UnionColosseumGiveUpAllocationRequest.sendRequest(UnionColosseumGiveUpAllocationRequest.onSucceedDefault, UnionColosseumGiveUpAllocationRequest.onFailedDefault)
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击确认分配
local function onConfirmBtnCLick(evt)
	--print("onConfirmBtnCLick")
	local self = evt.context

	--确认分配状态
	if UnionManager.checkColosseumDistributionIsEmpty() then
		--分配完毕
		function onConfirm()
			--玩家确认分配
			local hash = UnionManager.getColosseumDistributionHash()
			local requestList = {}
			for k, v in pairs(hash) do
				table.insert(requestList, v)
			end
			--请求保存分配结果
			UnionColosseumAllocateRequest.sendRequest(requestList, UnionColosseumAllocateRequest.onSucceedDefault, UnionColosseumAllocateRequest.onFailedDefault)
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )

			self.confirmBox = nil
		end
		function onCancel()
			self.confirmBox = nil
		end
		self.confirmBox = CanonMessageBox:Show(getTextByKey("union_monster_reward_distribution_confirm_remind"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, onCancel)--你确定要分配战利品吗？
	else
		--还有剩余
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_monster_reward_distribution_not_finish_remind"))--还有未分配完的战利品
	end
end
------------------------------------------------------------------------------------------------------

UnionColosseumDistributionPopPanel = class(Layer)

function UnionColosseumDistributionPopPanel:ctor()
	self.container = nil
	self.content = nil
	self.confirmBox = nil--正在弹出的确认框 没再弹出状态为niil
end

function UnionColosseumDistributionPopPanel:create( container, buildingId )
	local s = UnionColosseumDistributionPopPanel.new()
	s:initLayer(container, buildingId)
	return s
end

function UnionColosseumDistributionPopPanel:initLayer(container, buildingId)
	UnionColosseumDistributionPopPanel.super.initLayer(self)

	--分配数据刷新
	local function onDistibutionDataUpdate()
		--print("onDistibutionDataUpdate! ")
		self.panelUI:getChildByName("txt_guild_63"):getChildByName("txt"):setString("x" .. UnionManager.getColosseumDistributionRemainNum())--x[剩余数量]
		self.panelUI:getChildByName("txt_guild_65"):getChildByName("txt"):setString(UnionManager.getColosseumDistributionUserNum() .. "/" .. UnionManager.getUnionMemberCount())--[已分配数量]/[成员总数]

		--刷新每一条的状态
		--保持列表位置
		local tableOffset = self.listTableView:getContentOffset()
		self.listTableView:reloadData()
		self.listTableView:setContentOffset(tableOffset, true)
	end
	self.onDistibutionDataUpdate = onDistibutionDataUpdate

	--间隔时间调用
	local function tick()
		--确认是否允许分配
		local function onFailed(evt)
			--关闭自身对话框
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )

			--print("self.confirmBox is nil ? " .. tostringRich(self.confirmBox == nil))
			if self.confirmBox then
				--关闭弹出的确认对话框
				PopoutManager:sharedManager():pullin(self.confirmBox, kPopoutDir.kScale )
				self.confirmBox = nil
			end

			--给提示
			CanonMessageBox:Show(getTextByKey("union_data_refresh_remind"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)--数据已过期，请重新进入界面
		end
		UnionColosseumStartAllocationRequest.sendRequest(nil, onFailed, true)
	end
	self.tick = tick
    
	self.container = container
	self.buildingId = buildingId

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_damage_rank") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_guild_62"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_distribution_last_num"))--剩余：
	self.panelUI:getChildByName("txt_guild_64"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_distribution_finish_player"))--已分配人数：
	self.panelUI:getChildByName("txt_distribution"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_distribution_title_txt"))--分配奖励
	self.panelUI:getChildByName("btn_distribution_confirm"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_distribution_confirm_txt"))--确认分配
	self.panelUI:getChildByName("txt_guild_77"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_refurbish", {num = UnionManager.getUnionMonsteWeeklyrGiftTotalNum(), time = TimeUtil.formatTimeWithHM(UnionManager.getUnionMonsterRefreshHour()*3600)}))--每个玩家每周获得上限:{num}. 每周六{time}刷新

	--关闭按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	--确认分配按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_distribution_confirm"))
	closeButton:addEventListener(Events.kStart,onConfirmBtnCLick, self)

	--加侦听
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
	--分配数据更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.COLOSSEUM_DISTRIBUTION_UPDATE, self.onDistibutionDataUpdate, self)

	--显示奖励图标
	local bossDataList = UnionManager.getColosseumBossConfigList()
	local currentBossMetaId = UnionManager.getColosseumMonsterMetaId()
	for k, bossConfigData in ipairs(bossDataList) do
		local showThisBoss = (bossConfigData.id == currentBossMetaId)

		local bossRewardIconDisplay = self.panelUI:getChildByName("icon_monster_treasure_" .. bossConfigData.cardPic)
		if bossRewardIconDisplay then
			bossRewardIconDisplay:setVisible(showThisBoss)
		else
			print("军团斗兽场美术资源缺少boss奖励图标的层名! target = " .. "icon_monster_treasure_" .. bossConfigData.cardPic)
		end
	end

	--初始化列表
	self.dataList = UnionManager.getMembers()
	--对显示内容排序
	local function sortFunc(a, b)
		local rankA = UnionManager.findRankByUid(a.uid)
		local rankB = UnionManager.findRankByUid(b.uid)

		if rankA == -1 then
			rankA = 10000
		end
		if rankB == -1 then
			rankB = 10000
		end

		if rankA ~= rankB then
			return rankA < rankB
		end

		local contributeA = tonumber(a.hisContribute)
		local contributeB = tonumber(b.hisContribute)
		if contributeA ~= contributeB then
			return contributeA > contributeB
		end
		return b.title < a.title
	end
	table.sort(self.dataList, sortFunc)
	--print("self.dataList = " .. tostringRich(self.dataList))

	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)
	self.listTableView:reloadData()

	--清空数据
	UnionManager.colosseumDistributionClear()

	if not self.tickEntry then
		self.tickEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.tick, 5, false)--间隔5s
		self.tick()
	end

	--刷新
	self.onDistibutionDataUpdate()
end

function UnionColosseumDistributionPopPanel:dispose()
	if self.tickEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
		self.tickEntry = nil
	end

	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_DISTRIBUTION_UPDATE, self.onDistibutionDataUpdate)

	UnionColosseumDistributionPopPanel.super.dispose(self)
end

function UnionColosseumDistributionPopPanel:setTableViewsEnabled(v)
	self.listTableView:setTouchEnabled(v)
end


------------------------------------------------------------------------------------------------------

function UnionColosseumDistributionPopPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {-51, -52, -53, -54}
	local aPanel = self
	local DistributionTableViewRenderer = class(TableViewRenderer)
	function DistributionTableViewRenderer:ctor(width, height)
		self.list = aPanel.dataList or {}
	end

	function DistributionTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_distribution_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		aCell:getChildByName("txt_guild_67"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_hurt_turns_remind_txt"))--伤害排名
		aCell:getChildByName("txt_guild_69"):getChildByName("txt"):setString(Localization:getInstance():getText("union_fight_num_text"))--战斗力：
		aCell:getChildByName("txt_guild_70"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_contribute_all_text"))--个人总贡献：
		aCell:getChildByName("txt_guild_68"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_hurt_turns_not_play_remind"))--未参与

		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)
    
		local aNameLabel = aCell:getChildByName("txt_guild_member_name")
		aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-11)
    
		local aLevelLabel = aCell:getChildByName("txt_guild_14")
		aLevelLabel:setTag(-12)
		aLevelLabel = aLevelLabel:getChildByName("txt")
		aLevelLabel:setTag(-12)
    
		local aDamageRankLabel = aCell:getChildByName("txt_guild_52")
		aDamageRankLabel:setTag(-13)
		aDamageRankLabel = aDamageRankLabel:getChildByName("txt")
		aDamageRankLabel:setTag(-13)
    
		local aPowerLabel = aCell:getChildByName("txt_guild_16_1")
		aPowerLabel:setTag(-14)
		aPowerLabel = aPowerLabel:getChildByName("txt")
		aPowerLabel:setTag(-14)
    
		local aContributeLabel = aCell:getChildByName("txt_guild_16_2")
		aContributeLabel:setTag(-15)
		aContributeLabel = aContributeLabel:getChildByName("txt")
		aContributeLabel:setTag(-15)
    
		local aGiveNumLabel = aCell:getChildByName("txt_other_upgrade3")
		aGiveNumLabel:setTag(-16)
		aGiveNumLabel = aGiveNumLabel:getChildByName("txt")
		aGiveNumLabel:setTag(-16)
    
		local aNoRankLabel = aCell:getChildByName("txt_guild_68")
		aNoRankLabel:setTag(-17)
    
		local aHaveRankLabel = aCell:getChildByName("txt_guild_67")
		aHaveRankLabel:setTag(-18)
    
    	--等级标记
		aCell:getChildByName("lbl_1st"):setTag(-31)--军团长
		aCell:getChildByName("lbl_2rd"):setTag(-32)--副团长
		aCell:getChildByName("lbl_elite"):setTag(-33)--精英团员
		aCell:getChildByName("lbl_mem"):setTag(-34)--成员

		--按钮+1
		local aAdd1BtnDisplay = aCell:getChildByName("btn_other_upgrade1")
		aAdd1BtnDisplay:getChildByName("txt"):setString("+1")
		aAdd1BtnDisplay:setTag(-51)
		aAdd1BtnDisplay:getChildByName("normal"):setTag(-11)
		aAdd1BtnDisplay:getChildByName("disabled"):setTag(-12)

		--按钮+10
		local aAdd2BtnDisplay = aCell:getChildByName("btn_other_upgrade2")
		aAdd2BtnDisplay:getChildByName("txt"):setString("+10")
		aAdd2BtnDisplay:setTag(-52)
		aAdd2BtnDisplay:getChildByName("normal"):setTag(-11)
		aAdd2BtnDisplay:getChildByName("disabled"):setTag(-12)

		--按钮-1
		local aAdd3BtnDisplay = aCell:getChildByName("btn_other_upgrade3")
		aAdd3BtnDisplay:getChildByName("txt"):setString("-1")
		aAdd3BtnDisplay:setTag(-53)
		aAdd3BtnDisplay:getChildByName("normal"):setTag(-11)
		aAdd3BtnDisplay:getChildByName("disabled"):setTag(-12)

		--按钮-10
		local aAdd4BtnDisplay = aCell:getChildByName("btn_other_upgrade4")
		aAdd4BtnDisplay:getChildByName("txt"):setString("-10")
		aAdd4BtnDisplay:setTag(-54)
		aAdd4BtnDisplay:getChildByName("normal"):setTag(-11)
		aAdd4BtnDisplay:getChildByName("disabled"):setTag(-12)
	end

	function DistributionTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		local aCardDisplay = aCell:getChildByTag(-10)

		local oldIcon = aCell:getChildByTag(-200)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		--print(table.tostring(aData))
		local newMeta = CommonManager:getSelfAvatarMetaByUid( aData.uid )
	    if not newMeta then
	        newMeta = aData.mainCardId
	    end
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 1, params)
		aCell:addChild(icon.refCocosObj, 10)
		if icon then
			icon:setTag(-200)
			icon:dispose()
		end
    
		local aNameLabel = aCell:getChildByTag(-11)
		setNodeText(aNameLabel:getChildByTag(-11), aData.nickName or "")
    
		local aLevelLabel = aCell:getChildByTag(-12)
		setNodeText(aLevelLabel:getChildByTag(-12), aData.level or "")

		local aDamageRankLabel = aCell:getChildByTag(-13)
		local aHaveRankLabel = aCell:getChildByTag(-18)
		local aNoRankLabel = aCell:getChildByTag(-17)
		local rank = UnionManager.findRankByUid(aData.uid)
		if rank == -1 then
			--未上榜
			aDamageRankLabel:setVisible(false)
			aHaveRankLabel:setVisible(false)
			aNoRankLabel:setVisible(true)
		else
			aDamageRankLabel:setVisible(true)
			aHaveRankLabel:setVisible(true)
			aNoRankLabel:setVisible(false)
			setNodeText(aDamageRankLabel:getChildByTag(-13), rank or "")
		end

		local aPowerLabel = aCell:getChildByTag(-14)
		setNodeText(aPowerLabel:getChildByTag(-14), aData.fightCapacity or "")

		local aContributeLabel = aCell:getChildByTag(-15)
		setNodeText(aContributeLabel:getChildByTag(-15), aData.hisContribute or "")

		--显示职位
		if tonumber(aData.title) == UnionManager.TITLE_MANAGER then
			aCell:getChildByTag(-31):setVisible(true)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(false)
		elseif tonumber(aData.title) == UnionManager.TITLE_VICE_MANAGER then
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(true)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(false)
		elseif tonumber(aData.title) == UnionManager.TITLE_ELITE_MEMBER then
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(true)
			aCell:getChildByTag(-34):setVisible(false)
		else
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(true)
		end

		self:refreshData(rawCocosObj, aData)
	end

	--更新状态
	function DistributionTableViewRenderer:refreshData(rawCocosObj, aData)
		--print("refreshData")
		local aCell = self:getChildByTag(rawCocosObj, cellTag)

		--当前分配点数
		local currentNum = UnionManager.getColosseumDistributionNumByUid(aData.uid)
		local aGiveNumLabel = aCell:getChildByTag(-16)
		local maxNum = UnionManager.memberGiftMaxNum(aData.uid)
		setNodeText(aGiveNumLabel:getChildByTag(-16), currentNum .. "/" .. maxNum)

		--按钮元件
		local aAdd1BtnDisplay = aCell:getChildByTag(-51)
		local aAdd2BtnDisplay = aCell:getChildByTag(-52)
		local aAdd3BtnDisplay = aCell:getChildByTag(-53)
		local aAdd4BtnDisplay = aCell:getChildByTag(-54)

		--判断能否增加
		if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, 1) then
			--可以增加
			aAdd1BtnDisplay:getChildByTag(-11):setVisible(true)
			aAdd2BtnDisplay:getChildByTag(-11):setVisible(true)

			aAdd1BtnDisplay:getChildByTag(-12):setVisible(false)
			aAdd2BtnDisplay:getChildByTag(-12):setVisible(false)

			aAdd1BtnDisplay.ignoreTouch = false
			aAdd2BtnDisplay.ignoreTouch = false
		else
			--不让增加
			aAdd1BtnDisplay:getChildByTag(-11):setVisible(false)
			aAdd2BtnDisplay:getChildByTag(-11):setVisible(false)

			aAdd1BtnDisplay:getChildByTag(-12):setVisible(true)
			aAdd2BtnDisplay:getChildByTag(-12):setVisible(true)

			aAdd1BtnDisplay.ignoreTouch = true
			aAdd2BtnDisplay.ignoreTouch = true
		end

		--判断能否减少
		if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, -1) then
			--可以减少
			aAdd3BtnDisplay:getChildByTag(-11):setVisible(true)
			aAdd4BtnDisplay:getChildByTag(-11):setVisible(true)

			aAdd3BtnDisplay:getChildByTag(-12):setVisible(false)
			aAdd4BtnDisplay:getChildByTag(-12):setVisible(false)

			aAdd3BtnDisplay.ignoreTouch = false
			aAdd4BtnDisplay.ignoreTouch = false
		else
			--不让减少
			aAdd3BtnDisplay:getChildByTag(-11):setVisible(false)
			aAdd4BtnDisplay:getChildByTag(-11):setVisible(false)

			aAdd3BtnDisplay:getChildByTag(-12):setVisible(true)
			aAdd4BtnDisplay:getChildByTag(-12):setVisible(true)

			aAdd3BtnDisplay.ignoreTouch = true
			aAdd4BtnDisplay.ignoreTouch = true
		end
    end

	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]

		local buttonDisplay
		local exchangeDisplay

		buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-51)
		exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("+1")
			--判断能否增加
			if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, 1) then
				UnionManager.colosseumDistributionAdd(aData.uid, 1)
			end
		end

		buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-52)
		exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("+10")
			--判断能否增加
			if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, 10) then
				UnionManager.colosseumDistributionAdd(aData.uid, 10)
			end
		end

		buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-53)
		exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("-1")
			--判断能否减少
			if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, -1) then
				UnionManager.colosseumDistributionAdd(aData.uid, -1)
			end
		end

		buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-54)
		exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("-10")
			--判断能否减少
			if UnionManager.checkColosseumDistributionIncreaceByUid(aData.uid, -10) then
				UnionManager.colosseumDistributionAdd(aData.uid, -10)
			end
		end
	end

	self.panelUI:getChildByName("table_distribution_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_distribution_list"))
	local renderer = DistributionTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)

	return aTableView
end