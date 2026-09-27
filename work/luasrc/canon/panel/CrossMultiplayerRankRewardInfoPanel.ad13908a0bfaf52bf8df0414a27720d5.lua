--
-- CrossMultiplayerRankRewardInfoPanel
--

CrossMultiplayerRankRewardInfoPanel = class(Layer)

function CrossMultiplayerRankRewardInfoPanel:ctor()
    self.container = nil
end

function CrossMultiplayerRankRewardInfoPanel:create(container,version)
    local s = CrossMultiplayerRankRewardInfoPanel.new()
    s.version = version or 0
    s:initLayer(container)
    return s
end

function CrossMultiplayerRankRewardInfoPanel:initLayer(container)
    CrossMultiplayerRankRewardInfoPanel.super.initLayer(self)
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
    sureBtn.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("close"))
    sureBtn:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossBoss_rewardPreview"))

    self.TableView = self:createTableView(self.panelUI:getChildByName("table_siren_reward_list"))

end

function CrossMultiplayerRankRewardInfoPanel:createTableView(display)
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

        if data.minRank == data.maxRank then
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey("cross_list_rank" , {num1 = data.minRank}))
        else
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey("balloon_rank",{num1 = data.minRank , num2 = data.maxRank}))
        end

        for i=1,4 do
            aCell:getChildByTag(-20-i):removeChildByTag(-30, true)
            aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10):setVisible(false)

            if data["content"..i.."Type"] ~= 0 then
                local itemIcon = CanonGoodIcon.createGoodIcon(data["content"..i.."Type"], data["content"..i.."Id"], data["content"..i.."Amount"], {sourceDisplay = aCell:getChildByTag(-20-i):getChildByTag(-20) , showInCenter = true})
                itemIcon:setTag(-30)
                aCell:getChildByTag(-20-i):addChild(itemIcon.refCocosObj,10)

                setNodeText(aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10),CanonGoodIcon.getGoodName(data["content"..i.."Type"], data["content"..i.."Id"], data["content"..i.."Amount"],{withoutAmount = false}))
                aCell:getChildByTag(-20-i):getChildByTag(-10):getChildByTag(-10):setVisible(true)
            end
        end
    end

    local tableViewSizes = getTableViewSizes(display)
    display:setVisible(false)

    local tableData = nil
    for i,v in ipairs(DataManager.GameMetaData.crossBossRewardConfig.rankRewardNodes) do
        if v.minVersion == 0 and v.maxVersion == 0 then
            tableData = v.rewards
            if self.version == 0 then
                break
            end
        elseif self.version >= v.minVersion and self.version <= v.maxVersion then
            tableData = v.rewards
            break
        end
    end

    local renderer = CrossMultiplayerRankRewardRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    self.panelUI:addChild(aTableView)
    return aTableView
end

function CrossMultiplayerRankRewardInfoPanel:scaleIn()
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

function CrossMultiplayerRankRewardInfoPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end

