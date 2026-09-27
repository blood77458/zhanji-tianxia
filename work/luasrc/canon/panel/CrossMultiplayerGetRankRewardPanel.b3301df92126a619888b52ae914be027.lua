--
-- CrossMultiplayerGetRankRewardPanel
--

CrossMultiplayerGetRankRewardPanel = class(Layer)

function CrossMultiplayerGetRankRewardPanel:ctor()
    self.container = nil
end

function CrossMultiplayerGetRankRewardPanel:create(container,rewards)
    local s = CrossMultiplayerGetRankRewardPanel.new()
    s.rewards = rewards or {}
    s:initLayer(container)
    return s
end

function CrossMultiplayerGetRankRewardPanel:initLayer(container)
    CrossMultiplayerGetRankRewardPanel.super.initLayer(self)
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_Siren_05")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    local sureBtn = Button:create(self.panelUI:getChildByName("btn"))
    sureBtn.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))
    sureBtn:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossBoss_rewardPreview"))

    self.TableView = self:createTableView(self.panelUI:getChildByName("table_siren_reward_list"))

end

function CrossMultiplayerGetRankRewardPanel:createTableView(display)
    local cellTag = 1024

    local CrossMultiplayerRankRewardRenderer = class(TableViewRenderer)

    function CrossMultiplayerRankRewardRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function CrossMultiplayerRankRewardRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
        local aCell = builder:build("list/siren_reward_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        aCell:getChildByName("txt_07"):setTag(-10)
        aCell:getChildByName("txt_07"):getChildByName("txt"):setTag(-10)

        for i=1,4 do
            aCell:getChildByName("normal_card_small_reward"..i):setTag(-20-i)

            aCell:getChildByName("normal_card_small_reward"..i):getChildByName("txt_01"):setTag(-10)
            aCell:getChildByName("normal_card_small_reward"..i):getChildByName("txt_01"):getChildByName("txt"):setTag(-10)

            aCell:getChildByName("normal_card_small_reward"..i):getChildByName("normal_card_small_mid"):setTag(-20)
            aCell:getChildByName("normal_card_small_reward"..i):getChildByName("normal_card_small_mid"):setVisible(false)
        end
    end

    function CrossMultiplayerRankRewardRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        if data.keyName == "rankRewards" then
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey("crossBoss_rankReward"))
        elseif data.keyName == "partRewards" then
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey("crossBoss_playReward"))
        elseif data.keyName == "beatRewards" then
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey("crossBoss_lastShotReward"))
        else
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), "")
        end

        for i=1,4 do
            aCell:getChildByTag(-20-i):removeChildByTag(-30, true)
            aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10):setVisible(false)

            if data.rewards[i] then
                local itemIcon = CanonGoodIcon.createGoodIcon(data.rewards[i].itemType, data.rewards[i].metaId, data.rewards[i].amount, {sourceDisplay = aCell:getChildByTag(-20-i):getChildByTag(-20) , showInCenter = true})
                itemIcon:setTag(-30)
                aCell:getChildByTag(-20-i):addChild(itemIcon.refCocosObj,10)

                setNodeText(aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10),CanonGoodIcon.getGoodName(data.rewards[i].itemType, data.rewards[i].metaId, data.rewards[i].amount,{withoutAmount = false}))
                aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10):setVisible(true)
            end
        end
    end

    local tableViewSizes = getTableViewSizes(display)
    display:setVisible(false)

    -- local temp = {itemType = ResourceEnum.PROP , metaId = 400024 , amount = 1 , level = 1 , exp = 10}
    -- self.rewards = {
    --     rankRewards = {temp,temp},
    --     partRewards = {temp,temp},
    --     beatRewards = {temp,temp,temp}
    -- }

    local tableData = {}
    for k,v in pairs(self.rewards) do
        RewardManager:getReward(v)
        local tempTable = {keyName = k , rewards = v}
        table.insert(tableData, tempTable)
    end


    local renderer = CrossMultiplayerRankRewardRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    self.panelUI:addChild(aTableView)
    return aTableView
end

function CrossMultiplayerGetRankRewardPanel:scaleIn()
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

function CrossMultiplayerGetRankRewardPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end