-- UnionBattleReportPopPanel.lua
-- zhehua.ou
-- 2014-8-25
-- 军团战 城池 查看战报

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

UnionBattleReportPopPanel = class(Layer)

function UnionBattleReportPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionBattleReportPopPanel:create( container , cityId , dataList)
	local s = UnionBattleReportPopPanel.new()
	s.container = container
	s.cityId = cityId
	s.dataList = dataList
	s:initLayer()
	return s
end

function UnionBattleReportPopPanel:initLayer()
	UnionBattleReportPopPanel.super.initLayer(self)

	self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_guikdpk_previou_fight") 
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(UnionPkUtils.getCityNameById(self.cityId))
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_screen"))
    self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_war"))
    self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("cross_race_video"))

	self.tableView = self:createTableView(self.dataList)
	self.panelUI:addChild(self.tableView)

	self.tempLayer:setScale(0.1)
end

function UnionBattleReportPopPanel:createTableView(data)
	local cellTag = 1024

	local UnionBattleReportRenderer = class(TableViewRenderer)

  	function UnionBattleReportRenderer:ctor(width, height, creater)
		self.list = data or {}
		self.creater = creater
	end

	function UnionBattleReportRenderer:buildCell(container)
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	    local aCell = builder:build("list/list_previou_fight")
	    container:addChild(aCell)
	    aCell:setTag(cellTag)
	    
		local session = aCell:getChildByName("session")
		session:setTag(-10)
		session:getChildByName("lbl_fight_one"):setTag(-10)
		session:getChildByName("lbl_fight_two"):setTag(-11)

	    local aNameLabel_win = aCell:getChildByName("txt_1")
	    aNameLabel_win:setTag(-11)
	    aNameLabel_win = aNameLabel_win:getChildByName("txt")
	    aNameLabel_win:setTag(-10)
	    
	    local aNameLabel_lose = aCell:getChildByName("txt_2")
	    aNameLabel_lose:setTag(-12)
	    aNameLabel_lose = aNameLabel_lose:getChildByName("txt")
	    aNameLabel_lose:setTag(-10)

	    local btn = aCell:getChildByName("icon_VV")
	    btn:setTag(-20)
	end

	function UnionBattleReportRenderer:setData(rawCocosObj, index)
		local aCell = self:getChildByTag(rawCocosObj, cellTag)

		if (index+1) == 1 then
			aCell:getChildByTag(-10):getChildByTag(-10):setVisible(true)
			aCell:getChildByTag(-10):getChildByTag(-11):setVisible(false)
		elseif (index+1) == 2 then
			aCell:getChildByTag(-10):getChildByTag(-10):setVisible(false)
			aCell:getChildByTag(-10):getChildByTag(-11):setVisible(true)
		else
			aCell:getChildByTag(-10):getChildByTag(-10):setVisible(false)
			aCell:getChildByTag(-10):getChildByTag(-11):setVisible(false)
		end

		local aNameLabel_win = aCell:getChildByTag(-11):getChildByTag(-10)
		local victorName = self.list[index + 1].victor
		if victorName == nil or victorName == "" then
			setNodeText(aNameLabel_win, UnionPkUtils.getCityNpcNameById(self.creater.cityId))
		else
			setNodeText(aNameLabel_win, victorName)
		end
		
		local aNameLabel_lose = aCell:getChildByTag(-12):getChildByTag(-10)
		local loserName = self.list[index + 1].loser
		if loserName == nil or loserName == "" then
			setNodeText(aNameLabel_lose, UnionPkUtils.getCityNpcNameById(self.creater.cityId))
		else
			setNodeText(aNameLabel_lose, loserName)
		end
	end

	self.panelUI:getChildByName("table_previou_fight_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_previou_fight_list"))
	local renderer = UnionBattleReportRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height,self)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
	    local newCell = self.tableView:cellAtIndex(aIndex - 1)
	    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

	    local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20)
	    if posInCell.x > (cardDisplay:getPositionX()) and
		    posInCell.x < (cardDisplay:getPositionX() + 78) and
		    posInCell.y > (cardDisplay:getPositionY() - 71) and
		    posInCell.y < (cardDisplay:getPositionY()) then
		    
		    local function onAfterSucceed(evt)
				
			end

			UnionPkGetBattleReportRequest.sendRequestDefalut(self.cityId,evt.target.tableViewRenderer.list[aIndex].reportId,onAfterSucceed)
		end
	end
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

	return aTableView
end

function UnionBattleReportPopPanel:dispose()
	UnionBattleReportPopPanel.super.dispose(self)
end

function UnionBattleReportPopPanel:scaleIn()
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
	  self.tempLayer.touchEnabled = true
	  self.tempLayer.touchChildren = true
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))

	--添加到二级堆栈
	UiStackManager.push(self)
end

function UnionBattleReportPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end