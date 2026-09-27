require "hecore.ui.TableView"
--
-- BlowBalloonRankInfoPanel
--

--跨天事件
local function onPassDay(evt)
    local self = evt.context

    local function successCallback(evt)
        local extraArgs = evt.data or {gainYesterdayPointReward = false , balloonRanks = {}}
        self.father.extraArgs = extraArgs

        local myUid = DataManager.getCurrUser().uid
        local myRank = 0
        for i,v in ipairs(extraArgs.balloonRanks) do
            if v.uid == myUid then
                myRank = i
                break
            end
        end
        g_homeInfo.balloonMyRank = myRank
    end
    
    local function failedCallback(evt)
        local errorCode = tonumber(evt.data)
        if errorCode == 714720 then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
        else
            CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end
    end

    local RewardRequest = BlowBalloonActInfoRequest.new({}, rpc.SendingPriority.kHigh)
    RewardRequest:addEventListener(RequestNotifyEnum.BlowBalloonActInfoRequestSucceed, successCallback)
    RewardRequest:addEventListener(RequestNotifyEnum.BlowBalloonActInfoRequestFailed, failedCallback)
    RewardRequest:start()
end

BlowBalloonRankInfoPanel = class(Layer)

function BlowBalloonRankInfoPanel:ctor()
    self.container = nil
end

function BlowBalloonRankInfoPanel:create(container,father)
    local s = BlowBalloonRankInfoPanel.new()
    s.father = father
    s:initLayer(container)
    return s
end

function BlowBalloonRankInfoPanel:initLayer(container)
    BlowBalloonRankInfoPanel.super.initLayer(self)
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("Blowing Balloons_Billboard_1")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("arena_myPoints"))
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(g_homeInfo.balloonDaily.balloonPoint)
    self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("balloon_rankExplain"))
    
    self.panelUI:getChildByName("table_BlowingBalloons_list"):setVisible(false)

    local rewardDataList = {}
    
    if DataManager.GameMetaData.activityBalloonConfig and DataManager.GameMetaData.activityBalloonConfig.balloonRankRewardMetas then
        rewardDataList = DataManager.GameMetaData.activityBalloonConfig.balloonRankRewardMetas
    end

    --
    -- rewardDataList = {
    --     {rankMin = 1 , rankMax = 2 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 10 , rewardType2 = ResourceEnum.PROP , rewardId2 = 400217 , rewardNum2 = 22 },
    --     {rankMin = 3 , rankMax = 3 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400216 , rewardNum1 = 10 , rewardType2 = ResourceEnum.PROP , rewardId2 = 400217 , rewardNum2 = 13 },
    --     {rankMin = 4 , rankMax = 7 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 8 , rewardType2 = ResourceEnum.PROP , rewardId2 = 0 , rewardNum2 = 1 },
    --     {rankMin = 8 , rankMax = 8 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400216 , rewardNum1 = 10 , rewardType2 = ResourceEnum.PROP , rewardId2 = 400216 , rewardNum2 = 8 }
    -- }
    --
    self:createTableView(rewardDataList)

    NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end

function BlowBalloonRankInfoPanel:createTableView(listData)
    local cellTag = 1024

    local BlowBalloonMagicRewardRenderer = class(TableViewRenderer)
    function BlowBalloonMagicRewardRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function BlowBalloonMagicRewardRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
        local aCell = builder:build("list/Blowing Balloons_Billboard_2ist")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        aCell:getChildByName("txt_1"):setTag(-11)
        aCell:getChildByName("txt_1"):getChildByName("txt"):setTag(-11)

        --图标
        for i=1,2 do
            aCell:getChildByName("normal_card_position_reward_"..i):setTag(-20-i)
            aCell:getChildByName("normal_card_position_reward_"..i):getChildByName("txt"):setTag(-30)
            aCell:getChildByName("normal_card_position_reward_"..i):getChildByName("txt"):getChildByName("txt"):setTag(-30)

            aCell:getChildByName("normal_card_position_reward_"..i):getChildByName("reward_normal_card_small_sb"):setTag(-40)
        end
    end

    function BlowBalloonMagicRewardRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        if data.rankMin == data.rankMax then
            setNodeText(aCell:getChildByTag(-11):getChildByTag(-11), getTextByKey("cross_list_rank" , {num1 = data.rankMin}))
        else
            setNodeText(aCell:getChildByTag(-11):getChildByTag(-11), getTextByKey("balloon_rank",{num1 = data.rankMin , num2 = data.rankMax}))
        end

        for i=1,2 do
            aCell:getChildByTag(-20-i):removeChildByTag(-50-i, true)
            if data["rewardId"..i] ~= 0 then
                local itemIcon = CanonGoodIcon.createGoodIcon(data["rewardType"..i], data["rewardId"..i], data["rewardNum"..i], {sourceDisplay = aCell:getChildByTag(-20-i):getChildByTag(-40) , showInCenter = true})
                itemIcon:setTag(-50-i)
                aCell:getChildByTag(-20-i):addChild(itemIcon.refCocosObj)
                setNodeText(aCell:getChildByTag(-20-i):getChildByTag(-30):getChildByTag(-30), CanonGoodIcon.getGoodName(data["rewardType"..i], data["rewardId"..i], data["rewardNum"..i], {withoutAmount = false}))

                aCell:getChildByTag(-20-i):setVisible(true)
            else
                aCell:getChildByTag(-20-i):setVisible(false)
            end
        end
    end

    local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_BlowingBalloons_list"))

    local renderer = BlowBalloonMagicRewardRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , listData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    self.panelUI:addChild(aTableView)
end

function BlowBalloonRankInfoPanel:scaleIn()
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

function BlowBalloonRankInfoPanel:dismiss()
    NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end