--
-- SilverDiceInfoPanel
--

SilverDiceInfoPanel = class(Layer)

function SilverDiceInfoPanel:ctor()
    self.container = nil
end

function SilverDiceInfoPanel:create(container)
    local s = SilverDiceInfoPanel.new()
    s:initLayer(container)
    return s
end

function SilverDiceInfoPanel:initLayer(container)
    SilverDiceInfoPanel.super.initLayer(self)
    local visibleSize = CCDirector:sharedDirector():getVisibleSize()

    self.container = container
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/sixhorse.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_reward_preview")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("txt_activity_info1"):getChildByName("txt"):setString(getTextByKey("reward_title"))

    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("table_sixhorse_list"):setVisible(false)
    self:createTableView(self.panelUI:getChildByName("table_sixhorse_list"))    
end

function SilverDiceInfoPanel:createTableView(display)
	local cellTag = 1024

	local SilverDiceInfoPanelRenderer = class(TableViewRenderer)

	function SilverDiceInfoPanelRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end
	function SilverDiceInfoPanelRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/sixhorse.json")
        local aCell = builder:build("sixgorse_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        aCell:getChildByName("txt_1"):setTag(-10)
        aCell:getChildByName("txt_1"):getChildByName("txt"):setTag(-10)

        aCell:getChildByName("normal_card_small1"):setVisible(false)
        aCell:getChildByName("normal_card_small1"):setTag(-14)
        aCell:getChildByName("normal_card_small2"):setVisible(false)
        aCell:getChildByName("normal_card_small2"):setTag(-11)
        aCell:getChildByName("normal_card_small3"):setVisible(false)
        aCell:getChildByName("normal_card_small3"):setTag(-12)
        aCell:getChildByName("normal_card_small4"):setVisible(false)
        aCell:getChildByName("normal_card_small4"):setTag(-13)

        aCell:getChildByName("number_1"):setTag(-21)
        aCell:getChildByName("number_1"):getChildByName("txt"):setTag(-21)
        aCell:getChildByName("number_1"):getChildByName("txt"):getChildByName("txt"):setTag(-21)
        aCell:getChildByName("number_2"):setTag(-22)
        aCell:getChildByName("number_2"):getChildByName("txt"):setTag(-22)
        aCell:getChildByName("number_2"):getChildByName("txt"):getChildByName("txt"):setTag(-22)
        aCell:getChildByName("number_3"):setTag(-23)
        aCell:getChildByName("number_3"):getChildByName("txt"):setTag(-23)
        aCell:getChildByName("number_3"):getChildByName("txt"):getChildByName("txt"):setTag(-23)
    end

	function SilverDiceInfoPanelRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        aCell:removeChildByTag(-34, true)
        local itemIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.COIN, 0, 0, {sourceDisplay = aCell:getChildByTag(-14) , showInCenter = true})
        itemIcon:setTag(-34)
        aCell:addChild(itemIcon.refCocosObj,10)

		setNodeText(aCell:getChildByTag(-10):getChildByTag(-10),getTextByKey("activity_dice_rewardTip"..(index+1)))

        for i=1,3 do
        	aCell:removeChildByTag(-30 - i, true)
        	if data["content"..i.."Id"] ~= 0 then
        		local tag = -10 - i
        		local itemIcon = CanonGoodIcon.createGoodIcon(data["content"..i.."Type"], data["content"..i.."Id"], data["content"..i.."Amount"], {sourceDisplay = aCell:getChildByTag(tag) , showInCenter = true})
        		itemIcon:setTag(-30 - i)
        		aCell:addChild(itemIcon.refCocosObj,1)
        		tag = -20 - i
                -- print("~~~~~~~~~~~~~~~~tag = "..tostring(tag))
        		aCell:getChildByTag(tag):setVisible(true)
        		setNodeText(aCell:getChildByTag(tag):getChildByTag(tag):getChildByTag(tag),"x"..data["content"..i.."Amount"])
        	else
        		local tag = -20 - i
        		aCell:getChildByTag(tag):setVisible(false)
        	end
        end
    end

	local tableViewSizes = getTableViewSizes(display)
	local tableData = DataManager.GameMetaData.activityDiceConfig.diceNewRewardItems

	local renderer = SilverDiceInfoPanelRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, nil, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	self.panelUI:addChild(aTableView)

    return aTableView
end

function SilverDiceInfoPanel:scaleIn()
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
end

function SilverDiceInfoPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end