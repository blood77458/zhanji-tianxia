-- UnionCitySignUpInfoPopPanel.lua
-- zhehua.ou
-- 2014-8-19
-- 军团战 城池 查看报名

local visibleSize = CCDirector:sharedDirector():getVisibleSize()


------------------------------------------------------------------------------------------------------

UnionCitySignUpInfoPopPanel = class(Layer)

function UnionCitySignUpInfoPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionCitySignUpInfoPopPanel:create( container , cityId , dataList)
	local s = UnionCitySignUpInfoPopPanel.new()
	s.container = container
	s.cityId = cityId
	s.dataList = dataList
	s:initLayer()
	return s
end

function UnionCitySignUpInfoPopPanel:initLayer()
	UnionCitySignUpInfoPopPanel.super.initLayer(self)

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
    self.panelUI = builder:build("popup_guikdpk_registered")
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )

    local sureBtnDisplay = self.panelUI:getChildByName("btn")
    sureBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(getTextByKey("yes"))
    local sureBtn = Button:create(sureBtnDisplay)
    sureBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_supple1",{num1 = UnionPkConfig.unionSignLimit(self.cityId)}))
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_screen"))
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_name"))
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_wealth2"))

	self.tableView = self:createTableView(self.dataList)
	self.panelUI:addChild(self.tableView)

	self.tempLayer:setScale(0.1)
end

function UnionCitySignUpInfoPopPanel:createTableView(data)
	local cellTag = 1024

	local UnionCitySignUpInfoRenderer = class(TableViewRenderer)

	-- 构造函数中计算cell个数
  	function UnionCitySignUpInfoRenderer:ctor(width, height)
		self.list = data or {}
	end

	-- 构建Cell
	function UnionCitySignUpInfoRenderer:buildCell(container)
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	    local aCell = builder:build("list/list_registered")
	    container:addChild(aCell)
	    aCell:setTag(cellTag)
	    
	    local aNumLabel = aCell:getChildByName("txt_guild_pk_19")
	    aNumLabel:setTag(-10)
	    aNumLabel = aNumLabel:getChildByName("txt")
	    aNumLabel:setTag(-10)
	    
	    local aNameLabel_me = aCell:getChildByName("txt_1")
	    aNameLabel_me:setTag(-11)
	    aNameLabel_me = aNameLabel_me:getChildByName("txt")
	    aNameLabel_me:setTag(-10)
	    
	    local aNameLabel_other = aCell:getChildByName("txt_2")
	    aNameLabel_other:setTag(-12)
	    aNameLabel_other = aNameLabel_other:getChildByName("txt")
	    aNameLabel_other:setTag(-10)

	    local aScoreLabel = aCell:getChildByName("txt_guild_pk_20")
	    aScoreLabel:setTag(-13)
	    aScoreLabel = aScoreLabel:getChildByName("txt")
	    aScoreLabel:setTag(-10)
	end

	-- 设置数据
  	function UnionCitySignUpInfoRenderer:setData(rawCocosObj, index)
  		local aCell = self:getChildByTag(rawCocosObj, cellTag)

  		local aNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
	    setNodeText(aNumLabel, Localization:getInstance():getText("UnionWar_sign_rank2", {num1 = (index + 1) }))
	
		local aNameLabel_me = aCell:getChildByTag(-11):getChildByTag(-10)
		local aNameLabel_other = aCell:getChildByTag(-12):getChildByTag(-10)

	    if UnionManager.getMyUnionId() == self.list[index + 1].unionId then
	    	aNameLabel_me:setVisible(true)
	    	aNameLabel_other:setVisible(false)
		    setNodeText(aNameLabel_me, self.list[index + 1].unionName)
		else
			aNameLabel_me:setVisible(false)
			aNameLabel_other:setVisible(true)
		    setNodeText(aNameLabel_other, self.list[index + 1].unionName)
	    end

	    local aScoreLabel = aCell:getChildByTag(-13):getChildByTag(-10)
	    setNodeText(aScoreLabel, string.format("%d", self.list[index + 1].wealth))
  	end

	self.panelUI:getChildByName("table_registered_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_registered_list"))
	local renderer = UnionCitySignUpInfoRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	return aTableView
end

function UnionCitySignUpInfoPopPanel:dispose()
	UnionCitySignUpInfoPopPanel.super.dispose(self)
end

function UnionCitySignUpInfoPopPanel:scaleIn()
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

function UnionCitySignUpInfoPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end