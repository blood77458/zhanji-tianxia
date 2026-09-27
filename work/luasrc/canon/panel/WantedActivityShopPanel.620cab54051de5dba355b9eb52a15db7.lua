--
-- WantedActivityShopPanel
--

local GoldMetalPropID = 400217
local SilverMetalPropID = 400216

WantedActivityShopPanel = class(Layer)

function WantedActivityShopPanel:ctor()
    self.container = nil
end

function WantedActivityShopPanel:create(container)
    local s = WantedActivityShopPanel.new()
    s:initLayer(container)
    return s
end

function WantedActivityShopPanel:initLayer(container)
    WantedActivityShopPanel.super.initLayer(self)
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/wanted.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("wanted_shoup_exchange_popup")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)

    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close_s"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("goldShop_exchange_list"):setVisible(false)
    self.panelUI:getChildByName("silverShop_exchange_list"):setVisible(false)
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("wanted_hold"))
    
    local metaGoods = DataManager.GameMetaData.wantedShopConfig.items
    self.goldGoods = {}
    self.silverGoods = {}
    for i,v in ipairs(metaGoods) do
        if v.costID == GoldMetalPropID then
            table.insert(self.goldGoods, v)
        elseif v.costID == SilverMetalPropID then
            table.insert(self.silverGoods, v)
        else
            print("操,配置有问题")
        end
    end

    local function changeShopType(evt)
        self:setShopType(evt.context)
    end
    
    self.goldShopBtn = Button:create(self.panelUI:getChildByName("btn_wanted_exchange_cold"))
    self.goldShopBtn:addEventListener(Events.kStart, changeShopType, 1)

    self.silverShopBtn = Button:create(self.panelUI:getChildByName("btn_wanted_exchange_silverr"))
    self.silverShopBtn:addEventListener(Events.kStart, changeShopType, 2)

    self:refreshMetalNum(1)
    self:refreshMetalNum(2)
    self:setShopType(1)
end

function WantedActivityShopPanel:refreshMetalNum(type)
    if type == 1 then
        self.goldNum = BagCalcManager.getNumById(GoldMetalPropID)
        self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(self.goldNum)
    elseif type == 2 then
        self.silverNum = BagCalcManager.getNumById(SilverMetalPropID)
        self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(self.silverNum)
    else
        print("你他妈传进来个什么鸡巴变量？")
    end
end

function WantedActivityShopPanel:setShopType(shopType)
    if shopType == self.shopType then
        return
    end

    self.shopType = shopType

    local goldOrSilver = nil

    if shopType == 1 then
        goldOrSilver = true
        if self.goldTableView == nil then
            self.goldTableView = self:createTableView(1,self.panelUI:getChildByName("goldShop_exchange_list"))
        end
        self.goldTableView:setVisible(true)

        if self.silverTableView ~= nil then
            self.silverTableView:setVisible(false)
        end
    else
        goldOrSilver = false
        if self.silverTableView == nil then
            self.silverTableView = self:createTableView(2,self.panelUI:getChildByName("silverShop_exchange_list"))
        end
        self.silverTableView:setVisible(true)

        if self.goldTableView ~= nil then
            self.goldTableView:setVisible(false)
        end
    end

    self.goldShopBtn:setEnable(not goldOrSilver)
    self.goldShopBtn.display:getChildByName("normal"):setVisible(goldOrSilver)
    self.goldShopBtn.display:getChildByName("lbl_in_shopmedal_cold"):setVisible(goldOrSilver)
    self.silverShopBtn:setEnable(goldOrSilver)
    self.silverShopBtn.display:getChildByName("normal"):setVisible(not goldOrSilver)
    self.silverShopBtn.display:getChildByName("lbl_in_shopmedal_cold"):setVisible(not goldOrSilver)
end

function WantedActivityShopPanel:setTableViewsEnabled(bool)
    if self.goldTableView then
        self.goldTableView:setTouchEnabled(bool)
    end
    if self.silverTableView then
        self.silverTableView:setTouchEnabled(bool)
    end
end

function WantedActivityShopPanel:createTableView(type,display)
    local cellTag = 1024

    local WantedActivityShopRenderer = class(TableViewRenderer)

    function WantedActivityShopRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function WantedActivityShopRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/wanted.json")
        local aCell = builder:build("list/table_shoupexchange_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        if type == 1 then
            aCell:getChildByName("icon_medal_silver"):setVisible(false)
        elseif type == 2 then
            aCell:getChildByName("icon_medal_gold"):setVisible(false)
        end
        aCell:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("wanted_price"))
        
        aCell:getChildByName("txt_1"):setTag(-11)
        aCell:getChildByName("txt_1"):getChildByName("txt"):setTag(-11)
        aCell:getChildByName("txt_3"):setTag(-12)
        aCell:getChildByName("txt_3"):getChildByName("txt"):setTag(-12)
        aCell:getChildByName("txt_4"):setTag(-13)
        aCell:getChildByName("txt_4"):getChildByName("txt"):setTag(-13)

        aCell:getChildByName("btn"):setTag(-21)
        aCell:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("wanted_button3"))
        aCell:getChildByName("normal_card_small"):setTag(-22)
    end

    function WantedActivityShopRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        setNodeText(aCell:getChildByTag(-12):getChildByTag(-12),data.costNum)

        aCell:removeChildByTag(-30, true)
        local itemIcon = CanonGoodIcon.createGoodIcon(data.propType, data.propID, data.propNum, {sourceDisplay = aCell:getChildByTag(-22) , showInCenter = true})
        itemIcon:setTag(-30)
        aCell:addChild(itemIcon.refCocosObj,10)
        setNodeText(aCell:getChildByTag(-11):getChildByTag(-11),CanonGoodIcon.getGoodName(data.propType, data.propID, data.propNum, {withoutAmount = false}))
        setNodeText(aCell:getChildByTag(-13):getChildByTag(-13),CanonGoodIcon.getGoodDescribe(data.propType,data.propID))
    end

    local tableViewSizes = getTableViewSizes(display)

    local tableData = nil
    if type == 1 then
        tableData = self.goldGoods
    elseif type == 2 then
        tableData = self.silverGoods
    end

    local renderer = WantedActivityShopRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {-21}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    local function onListItemTouch( evt )
        local aIndex = evt.data + 1
        local newCell = evt.target:cellAtIndex(aIndex - 1)
        local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

        local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-21)
        if posInCell.x > (cardDisplay:getPositionX()) and
            posInCell.x < (cardDisplay:getPositionX() + 168) and
            posInCell.y > (cardDisplay:getPositionY() - 67) and
            posInCell.y < (cardDisplay:getPositionY()) then

            local data = evt.target.tableViewRenderer.list[aIndex]

            if data.costID == GoldMetalPropID then
                if data.costNum > self.goldNum then
                    SuspensionLabel:showContent(self, getTextByKey("wanted_noGoldMedal"))
                    return
                end
            elseif data.costID == SilverMetalPropID then
                if data.costNum > self.silverNum then
                    SuspensionLabel:showContent(self, getTextByKey("wanted_noSilverMedal"))
                    return
                end
            else
                return
            end
            
            local function exchangeSucceed(e)
                RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = data.costID , amount = -data.costNum}})
                RewardManager:getReward(e.data.rewards)
                
                local RewardPanel = GetRewardInfoPanel:create(self, e.data.rewards)
                PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self )

                if data.costID == GoldMetalPropID then
                    self:refreshMetalNum(1)
                elseif data.costID == SilverMetalPropID then
                    self:refreshMetalNum(2)
                end
            end
            local function exchangeFailed(e)
                local errorCode = tonumber(e.data)
                if errorCode == 710516 then  --背包已满
                    local function closeCallBack()
                        self:setTableViewsEnabled(true)
                    end
                    self:setTableViewsEnabled(false)
                    NewPackageFullPanel:show(closeCallBack)
                else
                    CanonMessageBox:showCommUnHandleErrorBox(errorCode)
                end
            end

            local request = WantedActivityExchangeRequest.new({itemId = data.id}, rpc.SendingPriority.kHigh)
            request:addEventListener(RequestNotifyEnum.WantedActivityExchangeRequestSucceed, exchangeSucceed)
            request:addEventListener(RequestNotifyEnum.WantedActivityExchangeRequestFailed, exchangeFailed)
            request:start()
        end
    end
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

    self.panelUI:addChild(aTableView)

    return aTableView
end

function WantedActivityShopPanel:scaleIn()
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

function WantedActivityShopPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end