require "hecore.ui.TableView"
--
-- BlowBalloonMagicRewardPanel
--

--跨天事件
local function onPassDay(evt)
    local self = evt.context
    self:setButtonStatus(0)
    self:checkGetAllRewardBtnStatus()

    self.UI_TableView.tableViewRenderer.list = self.rewardDataList
    self.UI_TableView:reloadData()

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

BlowBalloonMagicRewardPanel = class(Layer)

function BlowBalloonMagicRewardPanel:ctor()
    self.container = nil
end

function BlowBalloonMagicRewardPanel:create(container,father)
    local s = BlowBalloonMagicRewardPanel.new()
    s.father = father
    s:initLayer(container)
    return s
end

function BlowBalloonMagicRewardPanel:initLayer(container)
    BlowBalloonMagicRewardPanel.super.initLayer(self)
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
    self.panelUI = builder:build("Blowing Balloons_1")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
        if self.needRefreshFather then
            self.father:setData()
            self.container:resetTipInfoForActivity("Activity_BlowBalloon")
        end
        self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)


    local function getAllRewards(evt)
        local function successCallback(e)
            self.needRefreshFather = true

            if not g_homeInfo.balloonDaily then g_homeInfo.balloonDaily = {} end
            if not g_homeInfo.balloonDaily.gainedPointRewardIds then g_homeInfo.balloonDaily.gainedPointRewardIds = {} end

            for i,v in ipairs(self.rewardDataList) do
                if v.status == 1 then
                    v.status = 2
                    table.insert(g_homeInfo.balloonDaily.gainedPointRewardIds, v.id)
                end
            end
            self.UI_TableView:reloadData()
            evt.target:setEnable(false)
            evt.target.display:getChildByName("btn"):setVisible(false)


            RewardManager:getReward(e.data.rewards)
            self.UI_TableView:setTouchEnabled(false)
            local function closeRewardPanel(evt)
                self.container:setTableViewsEnabled(true)
                self.UI_TableView:setTouchEnabled(true)
            end
            local RewardPanel = GetRewardInfoPanel:create(self.container, e.data.rewards , closeRewardPanel)
            PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self.container )
        end

        local function failedCallback(e)
            local errorCode = tonumber(e.data)
            if errorCode == 710516 then  --背包已满
                NewPackageFullPanel:show()
            elseif errorCode == 714720 then
                local function callback()
                    Director:sharedDirector():replaceScene(MainMenuScene:create())
                end
                CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
        end

        local request = BlowBalloonActGetMagicRewardRequest.new({id = 0}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestSucceed, successCallback)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestFailed, failedCallback)
        request:start()
    end
    self.getAllRewardBtn = Button:create(self.panelUI:getChildByName("btn4_Blowing Balloons"))
    self.getAllRewardBtn.display:getChildByName("txt"):setString(getTextByKey("reward_claimAllBtn"))
	self.getAllRewardBtn:addEventListener(Events.kStart, getAllRewards, self)
    
    self.panelUI:getChildByName("txt _1"):getChildByName("txt"):setString(getTextByKey("balloon_tip3")..self.father.Data_Score)

    self.panelUI:getChildByName("table_Blowing Balloons_list"):setVisible(false)

    self.rewardDataList = {}
    
    if DataManager.GameMetaData.activityBalloonConfig and DataManager.GameMetaData.activityBalloonConfig.balloonPointRewardMetas then
        self.rewardDataList = table.clone(DataManager.GameMetaData.activityBalloonConfig.balloonPointRewardMetas)
    end

    -- 
    -- self.rewardDataList = {
    --     {id = 1 , pointSection = 100 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 1},
    --     {id = 2 , pointSection = 200 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 2},
    --     {id = 3 , pointSection = 300 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 3},
    --     {id = 4 , pointSection = 400 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 4},
    --     {id = 5 , pointSection = 500 , rewardType1 = ResourceEnum.PROP , rewardId1 = 400217 , rewardNum1 = 5},
    -- }
    -- 

    self:setButtonStatus(g_homeInfo.balloonDaily.balloonPoint)
    self:checkGetAllRewardBtnStatus()

    self.UI_TableView = self:createTableView(self.rewardDataList)

    -- NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end

function BlowBalloonMagicRewardPanel:setButtonStatus(point)
    local gainedPointRewardIds = nil
    if g_homeInfo and g_homeInfo.balloonDaily and g_homeInfo.balloonDaily.gainedPointRewardIds then
        gainedPointRewardIds = g_homeInfo.balloonDaily.gainedPointRewardIds
    else
        gainedPointRewardIds = {}
    end

    -- status  1.领取 2.已领取 3.不可领取
    for i,v in ipairs(self.rewardDataList) do
        if point >= v.pointSection then
            v.status = 1
            for j,k in ipairs(gainedPointRewardIds) do
                if k == v.id then
                    v.status = 2
                    break
                end
            end
        else
            v.status = 3
        end
    end
end

function BlowBalloonMagicRewardPanel:checkGetAllRewardBtnStatus()
    local enable = false
    for i,v in ipairs(self.rewardDataList) do
        if v.status == 1 then
            enable = true
            break
        end
    end

    self.getAllRewardBtn:setEnable(enable)
    self.getAllRewardBtn.display:getChildByName("btn"):setVisible(enable)
end

function BlowBalloonMagicRewardPanel:createTableView(listData)
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
        local aCell = builder:build("list/Blowing Balloons_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        aCell:getChildByName("txt _8_Blowing Balloons"):setTag(-11)
        aCell:getChildByName("txt _8_Blowing Balloons"):getChildByName("txt"):setTag(-11)

        aCell:getChildByName("txt _9_Blowing Balloons"):setTag(-12)
        aCell:getChildByName("txt _9_Blowing Balloons"):getChildByName("txt"):setTag(-12)

        --领取按钮
        aCell:getChildByName("btn3_Blowing Balloons"):setTag(-20)
        aCell:getChildByName("btn3_Blowing Balloons"):getChildByName("normal"):setTag(-10)
        aCell:getChildByName("btn3_Blowing Balloons"):getChildByName("txt"):setTag(-20)

        --图标
        aCell:getChildByName("normal_card_small"):setTag(-30)
    end

    function BlowBalloonMagicRewardRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        setNodeText(aCell:getChildByTag(-11):getChildByTag(-11), CanonGoodIcon.getGoodName(data.rewardType1, data.rewardId1, data.rewardNum1, {withoutAmount = false}))
        setNodeText(aCell:getChildByTag(-12):getChildByTag(-12), getTextByKey("balloon_getPoint",{num = data.pointSection}))


        if data.status == 1 then
            setNodeText(aCell:getChildByTag(-20):getChildByTag(-20), getTextByKey("achieve_task_get"))
            aCell:getChildByTag(-20):getChildByTag(-10):setVisible(true)
        elseif data.status == 2 then
            setNodeText(aCell:getChildByTag(-20):getChildByTag(-20), getTextByKey("achieve_task_got"))
            aCell:getChildByTag(-20):getChildByTag(-10):setVisible(false)
        else
            setNodeText(aCell:getChildByTag(-20):getChildByTag(-20), getTextByKey("achieve_task_get"))
            aCell:getChildByTag(-20):getChildByTag(-10):setVisible(false)
        end

        aCell:removeChildByTag(-40, true)
		local itemIcon = CanonGoodIcon.createGoodIcon(data.rewardType1, data.rewardId1, data.rewardNum1, {sourceDisplay = aCell:getChildByTag(-30) , showInCenter = true})
        itemIcon:setTag(-40)
        aCell:addChild(itemIcon.refCocosObj,8)
    end

    local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_Blowing Balloons_list"))

    local renderer = BlowBalloonMagicRewardRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , listData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {-20}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    local function onListItemTouch( evt )
        local aIndex = evt.data + 1
        local newCell = evt.target:cellAtIndex(aIndex - 1)
        local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

        local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20)
        if posInCell.x > (cardDisplay:getPositionX()) and
            posInCell.x < (cardDisplay:getPositionX() + 168) and
            posInCell.y > (cardDisplay:getPositionY() - 65) and
            posInCell.y < (cardDisplay:getPositionY()) then

            -- 判断背包是否满
            if BagCalcManager.isFull() then
                self.UI_TableView:setTouchEnabled(false)
                local function closeFullPanel(evt)
                    self.UI_TableView:setTouchEnabled(true)
                end
                self.container.targetInfoPanel = NewPackageFullPanel:show(closeFullPanel)
                return
            end

            local data = evt.target.tableViewRenderer.list[aIndex]

            if data.status ~= 1 then
                return
            end

            local function successCallback(e)
                self.needRefreshFather = true

                data.status = 2
                if not g_homeInfo.balloonDaily then g_homeInfo.balloonDaily = {} end
                if not g_homeInfo.balloonDaily.gainedPointRewardIds then g_homeInfo.balloonDaily.gainedPointRewardIds = {} end
                table.insert(g_homeInfo.balloonDaily.gainedPointRewardIds, data.id)

                evt.target:reloadData()
                self:checkGetAllRewardBtnStatus()

                RewardManager:getReward(e.data.rewards)
                evt.target:setTouchEnabled(false)
                local function closeRewardPanel(closeEvt)
                    self.container:setTableViewsEnabled(true)
                    evt.target:setTouchEnabled(true)
                end
                local RewardPanel = GetRewardInfoPanel:create(self.container, e.data.rewards , closeRewardPanel)
                PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false , self.container )
            end

            local function failedCallback(e)
                local errorCode = tonumber(e.data)
                if errorCode == 710516 then  --背包已满
                    NewPackageFullPanel:show()
                elseif errorCode == 714720 then
                    local function callback()
                        Director:sharedDirector():replaceScene(MainMenuScene:create())
                    end
                    CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
                else
                    CanonMessageBox:showCommUnHandleErrorBox(errorCode)
                end
            end

            local request = BlowBalloonActGetMagicRewardRequest.new({id = data.id}, rpc.SendingPriority.kHigh)
            request:addEventListener(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestSucceed, successCallback)
            request:addEventListener(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestFailed, failedCallback)
            request:start()
        end
    end

    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

    self.panelUI:addChild(aTableView)

    return aTableView
end

function BlowBalloonMagicRewardPanel:scaleIn()
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

function BlowBalloonMagicRewardPanel:dismiss()
    -- NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end