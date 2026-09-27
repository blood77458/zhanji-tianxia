require "hecore.ui.TableView"
--
-- BlowBalloonRankPanel
--

--跨天事件
local function onPassDay(evt)
    local self = evt.context

    local function successCallback(evt)
        local extraArgs = evt.data or {gainYesterdayPointReward = false , balloonRanks = {}}
        self.father.extraArgs = extraArgs
        self.dataList = extraArgs.balloonRanks or {}

        self.UI_TableView.tableViewRenderer.list = self.dataList
        self.UI_TableView:reloadData()

        local myUid = DataManager.getCurrUser().uid
        local myRank = 0
        for i,v in ipairs(extraArgs.balloonRanks) do
            if v.uid == myUid then
                myRank = i
                break
            end
        end
        g_homeInfo.balloonMyRank = myRank

        self:refreshBtn()
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

BlowBalloonRankPanel = class(Layer)

function BlowBalloonRankPanel:ctor()
    self.container = nil
end

function BlowBalloonRankPanel:create(container,father,dataList)
    local s = BlowBalloonRankPanel.new()
    s.father = father
    s.dataList = dataList
    s:initLayer(container)
    return s
end

function BlowBalloonRankPanel:initLayer(container)
    BlowBalloonRankPanel.super.initLayer(self)
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
    self.panelUI = builder:build("Blowing Balloons_Billboard")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
        if self.needRefreshFather then
            self.container:resetTipInfoForActivity("Activity_BlowBalloon")

            self.father:setData()
        end
        self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_home_back"))
    closeButton:addEventListener(Events.kStart, closeAction, self)


    local function onGetRewardBtn(evt)
        if self.father.activityClose then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end
        
        -- 判断背包是否满
        if BagCalcManager.isFull() then
            self.UI_TableView:setTouchEnabled(false)
            local function closeFullPanel(evt)
                self.UI_TableView:setTouchEnabled(true)
            end
            self.container.targetInfoPanel = NewPackageFullPanel:show(closeFullPanel)
            return
        end

        local function successCallback(e)
            g_homeInfo.balloonDaily.gainedRankReward = not g_homeInfo.balloonDaily.gainedRankReward
            self.needRefreshFather = true

            evt.target.display:getChildByName("txt"):setString(getTextByKey("activetask_receive"))
            evt.target:setEnable(false)
            evt.target.display:getChildByName("btn_yellow_long"):setVisible(false)

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

        local request = BlowBalloonActGetRankRewardRequest.new({}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetRankRewardRequestSucceed, successCallback)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetRankRewardRequestFailed, failedCallback)
        request:start()
    end

    self.getRewardBtn = Button:create(self.panelUI:getChildByName("btn_Blowing Balloons_Billboard"))
    self.getRewardBtn:addEventListener(Events.kStart, onGetRewardBtn, self)

    self:refreshBtn()

    self.panelUI:getChildByName("table_Blowing Balloons_Billboard_list"):setVisible(false)

    local rewardDataList = self.dataList or {}
    self.UI_TableView = self:createTableView(rewardDataList)

    -- NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end

function BlowBalloonRankPanel:refreshBtn()
    -- 排名
    if g_homeInfo and g_homeInfo.balloonMyRank > 0 and g_homeInfo.balloonMyRank ~= 100000000 then--g_homeInfo.balloonMyRank ~= 100000000与后端约定
        self.panelUI:getChildByName("txt_Blowing Balloons_Billboard_5"):getChildByName("txt"):setString(getTextByKey("activityNian_myRank",{rank = g_homeInfo.balloonMyRank}))
    else
        self.panelUI:getChildByName("txt_Blowing Balloons_Billboard_5"):getChildByName("txt"):setString(getTextByKey("balloon_noRankReward"))
    end

    -- 按钮
    local btnEnable = nil
    if g_homeInfo and g_homeInfo.balloonMyRank > 0 then
        if g_homeInfo.balloonDaily.gainedRankReward then
            btnEnable = false
            self.getRewardBtn.display:getChildByName("txt"):setString(getTextByKey("activity-sworn-got"))
        else
            btnEnable = true
            self.getRewardBtn.display:getChildByName("txt"):setString(getTextByKey("balloon_getRankReward"))
        end
    else
        btnEnable = false
        self.getRewardBtn.display:getChildByName("txt"):setString(getTextByKey("balloon_getRankReward"))
    end
    self.getRewardBtn:setEnable(btnEnable)
    self.getRewardBtn.display:getChildByName("btn_yellow_long"):setVisible(btnEnable)
end

function BlowBalloonRankPanel:createTableView(listData)
    local cellTag = 1024

    local BlowBalloonRankRenderer = class(TableViewRenderer)
    function BlowBalloonRankRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function BlowBalloonRankRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
        local aCell = builder:build("list/Blowing Balloons_Billboard_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        -- 排名
        aCell:getChildByName("txt_Blowing Balloons_Billboard"):setTag(-11)
        aCell:getChildByName("txt_Blowing Balloons_Billboard"):getChildByName("txt"):setTag(-11)

        -- 等级
        aCell:getChildByName("txt_Blowing Balloons_Billboard_1"):setTag(-12)
        aCell:getChildByName("txt_Blowing Balloons_Billboard_1"):getChildByName("txt"):setTag(-12)

        -- 玩家名
        aCell:getChildByName("txt_Blowing Balloons_Billboard_2"):setTag(-13)
        aCell:getChildByName("txt_Blowing Balloons_Billboard_2"):getChildByName("txt"):setTag(-13)
        
        -- 魔力值
        aCell:getChildByName("txt_Blowing Balloons_Billboard_3"):setTag(-14)
        aCell:getChildByName("txt_Blowing Balloons_Billboard_3"):getChildByName("txt"):setTag(-14)

        -- 充能次数
        aCell:getChildByName("txt_Blowing Balloons_Billboard_4"):setTag(-15)
        aCell:getChildByName("txt_Blowing Balloons_Billboard_4"):getChildByName("txt"):setTag(-15)

        --图标
        aCell:getChildByName("reward_normal_card_small_sb"):setTag(-20)
    end

    function BlowBalloonRankRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        setNodeText(aCell:getChildByTag(-11):getChildByTag(-11), getTextByKey("cross_list_rank",{num1 = index + 1}))
        setNodeText(aCell:getChildByTag(-12):getChildByTag(-12), data.level)
        setNodeText(aCell:getChildByTag(-13):getChildByTag(-13), data.nickName)
        setNodeText(aCell:getChildByTag(-14):getChildByTag(-14), getTextByKey("balloon_point")..data.point)
        setNodeText(aCell:getChildByTag(-15):getChildByTag(-15), getTextByKey("balloon_getTimes")..data.receiveTimes)

        aCell:removeChildByTag(-30, true)
        local itemIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, data.mainCardMetaId, 1, {sourceDisplay = aCell:getChildByTag(-20) , showInCenter = true})
        itemIcon:setTag(-30)
        aCell:addChild(itemIcon.refCocosObj,11)
    end

    local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_Blowing Balloons_Billboard_list"))

    local renderer = BlowBalloonRankRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , listData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    self.panelUI:addChild(aTableView)

    return aTableView
end

function BlowBalloonRankPanel:scaleIn()
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

function BlowBalloonRankPanel:dismiss()
    -- NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end