-- CrossArenaRankLayer.lua
-- 2015-3-6
-- zheng.che
-- 跨服竞技场排名页

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewTouched(evt.data == nil)
end

------------------------------------------------------------------------------------------------------

CrossArenaRankLayer = class(Layer)

function CrossArenaRankLayer:ctor()
	self.container = nil
end

function CrossArenaRankLayer:create( container , sceneId, currentTabIndex)
	self.container = container
	self.sceneId = sceneId
	self.currentTabIndex = currentTabIndex
	local s = CrossArenaRankLayer.new()
	s:initLayer()
	return s
end

function CrossArenaRankLayer:panelDismiss()
	self.container.targetInfoPanel = nil
end

function CrossArenaRankLayer:initLayer()
	CrossArenaRankLayer.super.initLayer(self)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("table_crossArena_ph")
	self:addChild(self.mainUI)

	self.refreshSelf = function()
		self.mainUI:getChildByName("txt_jj_28"):getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_battleRank3") .. CrossArenaManager.getMyRank())--我的排名
		self.mainUI:getChildByName("txt_jj_43"):getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_remainBattleTimes") .. CrossArenaManager.getLastChangllengeNum())--剩余挑战次数：
		self.mainUI:getChildByName("txt_jj_29"):getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_battleScore") .. CrossArenaManager.getMyBattleScore())--天梯积分
	end

	--不会变的文本

	--初始化列表
	self.dataList = CrossArenaManager.getShowRanks()
	--print("self.dataList = " .. tostringRich(self.dataList, 1))
	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)
	self.listTableView:reloadData()

	--事件侦听
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	self.refreshSelf()
end

function CrossArenaRankLayer:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	if self.listTableView then
		self.listTableView:removeFromParentAndCleanup(true)
	end

	CrossArenaRankLayer.super.dispose(self)
end

----------------------------------------------------------------------
-- 列表操作
----------------------------------------------------------------------

function CrossArenaRankLayer:createListTableView()
	local cellTag = 1024
	local buttonTag = {-100}
	local aListPanel = self
	local tableViewRenderer = class(TableViewRenderer)
	function tableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function tableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/list_ph_1")
		container:addChild(aCell)
		aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		-- <bean desc="排行榜信息">
		--  <property code="uid" type="long" desc="uid" />
		-- 	<property code="rank" type="int" desc="排名" />
		-- 	<property code="battleScore" type="int" desc="天梯积分" />
		-- 	<property code="metaId" type="int" desc="主卡牌ID" />
		-- 	<property code="nickName" type="string" desc="昵称" />
		-- 	<property code="level" type="int" desc="等级" />
		-- 	<property code="server" type="int" desc="服务器" />
		-- 	<property code="unionName" type="string" desc="军团名称" />
		-- 	<property code="combat" type="int" desc="战斗力" />
		-- </bean>
		--print("aData = " .. table.tostring(aData))

		--显示头像
		local aCardDisplay = self:getChildByNames(aCell, "card_normal_card_small_sb_upR")
		local oldIcon = aCell:getChildByTag(-100)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true

		local metaId = CommonManager:getSelfAvatarMetaByUid( aData.uid )
		if not metaId then
			metaId = aData.metaId
		end

		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, metaId, 0, params)
		aCell:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
		if icon then
			icon:setTag(-100)
			icon:dispose()
		end

		--显示排名
		self:getChildByNames(aCell, "lbl_1st_jj"):setVisible(false)
		self:getChildByNames(aCell, "lbl_2nd_jj"):setVisible(false)
		self:getChildByNames(aCell, "lbl_3rd_jj"):setVisible(false)
		self:getChildByNames(aCell, "icn_paiming1"):setVisible(false)
		self:getChildByNames(aCell, "icn_paiming2"):setVisible(false)
		self:getChildByNames(aCell, "icn_paiming3"):setVisible(false)
		self:getChildByNames(aCell, "txt_jj_27"):setVisible(false)
		if aData.rank == 1 then
			self:getChildByNames(aCell, "lbl_1st_jj"):setVisible(true)
			self:getChildByNames(aCell, "icn_paiming1"):setVisible(true)
		elseif aData.rank == 2 then
			self:getChildByNames(aCell, "lbl_2nd_jj"):setVisible(true)
			self:getChildByNames(aCell, "icn_paiming2"):setVisible(true)
		elseif aData.rank == 3 then
			self:getChildByNames(aCell, "lbl_3rd_jj"):setVisible(true)
			self:getChildByNames(aCell, "icn_paiming3"):setVisible(true)
		else
			self:getChildByNames(aCell, "txt_jj_27"):setVisible(true)
			self:setTxtByNames(aCell, "txt_jj_27/txt", Localization:getInstance():getText("crossArena_battleRank2") .. aData.rank)--排名：[]
		end

		self:setTxtByNames(aCell, "txt_jj_20/txt", aData.battleScore)--天梯积分：[]
		self:setTxtByNames(aCell, "txt_jj_47/txt", Localization:getInstance():getText("crossArena_battleScore"))--天梯积分：[]
		self:setTxtByNames(aCell, "txt_jj_22/txt", CrossArenaUtils.getLocationStrById(aData.server))--{num}区
		self:setTxtByNames(aCell, "txt_jj_23/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]
		self:setTxtByNames(aCell, "txt_jj_21/txt", aData.nickName)
		self:setTxtByNames(aCell, "txt_jj_25/txt", aData.level)
		self:setTxtByNames(aCell, "txt_jj_26/txt", aData.combat)
        self:setTxtByNames(aCell, "lbl_ztl_jj/txt", getTextByKey("crossArena_battleCapacity"))
		--不显示按钮
		self:getChildByNames(aCell, "btn"):setVisible(false)
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]


		local btnDisplay = self.renderer:getChildByNames(aCell, "card_normal_card_small_sb_upR")
		if isHittedDisplay(posInCell, btnDisplay) then
			--点击头像
			--print("onListItemTouch btnClicked")
			--进入玩家队列
			CrossArena.gotoUserFormationScene(aData.uid, self.sceneId, self.currentTabIndex)
		end
	end

	local tableViewSizes = getTableViewSizes(self.mainUI:getChildByName("table_ph_list"))
	self.mainUI:getChildByName("table_ph_list"):setVisible(false)
	self.renderer = tableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)

	--添加tag
    local builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
    local aCell = builder:build("list/list_ph_1")
    self.renderer:scanTags(aCell)
    
	local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

----------------------------------------------------------------------
-- 切页动作
----------------------------------------------------------------------

-- 进入页面
function CrossArenaRankLayer:panelEnter(callback)
	if self.listTableView then
		ViewControlUtil.showTableViewAction(self.listTableView, visibleSize, nil)	
  	else
    	if callback then
		    callback()
		end
	end

	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(callback))
	self.mainUI:runAction(CCSequence:create(arr))
end

-- 退出页面
function CrossArenaRankLayer:panelExit(callback)
	if self.listTableView then
		ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, nil)
  	else
    	if callback then
		    callback()
		end
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(callback))
	self.mainUI:runAction(CCSequence:create(arr))	
end

--设置触摸是否开启
function CrossArenaRankLayer:setTableViewTouched(enabled)
	--print("enabled = " .. tostringRich(enabled))
	if self.listTableView then
		self.listTableView:setTouchEnabled(enabled)
	end
end