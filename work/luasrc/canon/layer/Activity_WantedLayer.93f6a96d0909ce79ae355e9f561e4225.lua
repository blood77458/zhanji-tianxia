require "hecore.display.Layer"
require "canon.panel.WantedActivityShopPanel"
require "canon.panel.WantedActivityInfoPanel"
require "canon.scene.BattleScene"
require "canon.request.WantedActivityRefreshTaskRequest"
require "canon.request.WantedActivityChallengeRequest"
require "canon.request.WantedActivityExchangeRequest"
require "canon.request.WantedActivityGetWantedInfoRequest"

--
-- Activity_WantedLayer
--

--跨天事件
local function onPassDay(evt)
  local self = evt.context
  self:getData()
end

Activity_WantedLayer = class(Layer)
function Activity_WantedLayer:ctor()
    self.container = nil
end

function Activity_WantedLayer:create(container)
    local s = Activity_WantedLayer.new()
    s.container = container
    s:initLayer()
    return s
end

function Activity_WantedLayer:initLayer()
    Activity_WantedLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/wanted.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("wanted_activity")
    self:addChild(self.mainUI)

    self.mainUI:getChildByName("txt1"):getChildByName("txt"):setString(getTextByKey("wanted_questChance1"))
    self.mainUI:getChildByName("txt3"):getChildByName("txt"):setString(getTextByKey("wanted_questChance2"))

    self.DailyData = DailyDataManager.getWantedActivityData()

    self.starsArr = {}
    for i=1,5 do
        table.insert(self.starsArr,self.mainUI:getChildByName("wanted"):getChildByName("card_xing"..i))
    end

    local wantedName = {"wuguodaobing" , "ahuinan" , "jinhuansanjie" , "zhurong" , "menghuo"}
    self.wantedPicArr = {}
    for i=1,5 do
        table.insert(self.wantedPicArr,self.mainUI:getChildByName("wanted"):getChildByName(wantedName[i]))
    end

    self.checkBoxDisplay = self.mainUI:getChildByName("keep_control_all_select")
    
    local function setCheckBoxStatus()
        if self.CheckBoxSelected then
            self.checkBoxDisplay:getChildByName("btn_selected_all"):setVisible(true)
        else
            self.checkBoxDisplay:getChildByName("btn_selected_all"):setVisible(false)
        end
    end
    local function onClickCheckBox(evt)
        self.CheckBoxSelected = not self.CheckBoxSelected
        setCheckBoxStatus()

        self:setRefreshCost()
    end
    
    local checkBoxBtn = Button:create(self.checkBoxDisplay:getChildByName("btn_not_selected_all"))
    checkBoxBtn:addEventListener(Events.kStart, onClickCheckBox, self)
    self.checkBoxDisplay:getChildByName("btn_selected_all").touchEnabled = false
    self.checkBoxDisplay:getChildByName("btn_selected_all").touchChildren = false
    self.checkBoxDisplay:getChildByName("txt_select"):getChildByName("txt"):setString(getTextByKey("wanted_tip1"))

    self.CheckBoxSelected = false
    setCheckBoxStatus()


    -- 弹出商店
    local function onShopButton(evt)
        self.container:setTableViewsEnabled(false)
        local aShopPanel = WantedActivityShopPanel:create(self.container)
        self.container:addChild(aShopPanel)
        aShopPanel:scaleIn()
    end
    local shopButton = Button:create(self.mainUI:getChildByName("icon_shop_exchange"))
    shopButton:addEventListener(Events.kStart, onShopButton, self)

    -- 帮助界面
    local function infoButtonSelected(evt)
        self.container:setTableViewsEnabled(false)
        local aInfoPanel = WantedActivityInfoPanel:create(self.container)
        self.container:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
    end
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    -- 刷新任务
    local function refreshTask(evt)
        local gems = CalculationManager.calcComplex_getGemsNow()
        if self.currentCost > gems then
            local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
            self.container:addChild(aPanel)
            aPanel:scaleIn()
            return
        else
            local function refreshTaskSucceed(e)
                RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -self.currentCost})

                local DailyData = DailyDataManager.getWantedActivityData()
                if not self.CheckBoxSelected then
                    DailyData.refresh = true
                end
                DailyData.wantedConfigId = e.data.wantedId
                self.DailyData = DailyData
                DailyDataManager.setWantedActivityData(self.DailyData)

                self:refresh(e.data.wantedId)
            end
            local function refreshTaskFailed(e)
                local errorCode = tonumber(e.data)
                if errorCode == 710516 then  --背包已满
                    self.targetInfoPanel = NewPackageFullPanel:show()
                else
                    CanonMessageBox:showCommUnHandleErrorBox(errorCode)
                end
            end

            local request = WantedActivityRefreshTaskRequest.new({minimum = self.CheckBoxSelected}, rpc.SendingPriority.kHigh)
            request:addEventListener(RequestNotifyEnum.WantedActivityRefreshTaskRequestSucceed, refreshTaskSucceed)
            request:addEventListener(RequestNotifyEnum.WantedActivityRefreshTaskRequestFailed, refreshTaskFailed)
            request:start()
        end
    end
    self.refreshTaskBtn = Button:create(self.mainUI:getChildByName("btn_gold_referesh"))
    self.refreshTaskBtn:addEventListener(Events.kStart, refreshTask, self)
    self.refreshTaskBtn.display:getChildByName("txt"):setString(getTextByKey("pk_session_refresh"))

    -- 开始任务
    local function startTask(evt)
        local function challengeSucceed(e)
            if e.data.win then
                self.DailyData.wantedConfigId = e.data.wantedId
                self.DailyData.wanteds = self.DailyData.wanteds + 1
                DailyDataManager.setWantedActivityData(self.DailyData)
            end
            Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kActivityWanted, BattleEnterEnum.kActivityWanted))
        end

        local function challengeFailed(e)
            local errorCode = tonumber(e.data)
            if errorCode == 710516 then  --背包已满
                self.targetInfoPanel = NewPackageFullPanel:show()
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
        end

        local request = WantedActivityChallengeRequest.new({}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.WantedActivityChallengeRequestSucceed, challengeSucceed)
        request:addEventListener(RequestNotifyEnum.WantedActivityChallengeRequestFailed, challengeFailed)
        request:start()
    end
    self.startTaskBtn = Button:create(self.mainUI:getChildByName("wanted_btn_go"))
    self.startTaskBtn:addEventListener(Events.kStart, startTask, self)
    self.startTaskBtn.display:getChildByName("txt_btn_friend_ChangeBtn"):setString(getTextByKey("wanted_button2"))

    NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

    if self.DailyData.fake then
        self:getData()
    else
        self:setData()
    end
end

function Activity_WantedLayer:getData()
    local function getWantedInfoSucceed(e)
        self.DailyData = e.data.wantedInfo
        DailyDataManager.setWantedActivityData(self.DailyData)
        self:setData()
    end
    local function getWantedInfoFailed(e)

    end
    local request = WantedActivityGetWantedInfoRequest.new({}, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.WantedActivityGetWantedInfoRequestSucceed, getWantedInfoSucceed)
    request:addEventListener(RequestNotifyEnum.WantedActivityGetWantedInfoRequestFailed, getWantedInfoFailed)
    request:start()
end

function Activity_WantedLayer:setData()
    local leftChallengeTime = DataManager.GameMetaData.activityWantedConfig.completeNum - self.DailyData.wanteds
    
    self.mainUI:getChildByName("txt2"):getChildByName("txt"):setString(leftChallengeTime)
    if leftChallengeTime > 0 then
        self.startTaskBtn.display:getChildByName("normal"):setVisible(true)
        self.startTaskBtn:setEnable(true)
        self.mainUI:getChildByName("icon_wanted_complete"):setVisible(false)
    else
        self.startTaskBtn.display:getChildByName("normal"):setVisible(false)
        self.startTaskBtn:setEnable(false)
        self.mainUI:getChildByName("icon_wanted_complete"):setVisible(true)
    end

    self:refresh(self.DailyData.wantedConfigId)
end

function Activity_WantedLayer:refresh(wantedId)
    local rewardsInfo = DataManager.GameMetaData.activityWantedConfig.questRewards[wantedId]

    local goldOrSilver = nil
    if rewardsInfo.contentID1 == 400217 then -- 400217 金
        goldOrSilver = true
    elseif rewardsInfo.contentID1 == 400216 then -- 400216 银
        goldOrSilver = false
    else
        print("操,配置有问题")
    end

    local rewardMedal = rewardsInfo.contentNum1
    local rewardMoney = rewardsInfo.contentNum2
    local starCount = wantedId

    self.mainUI:getChildByName("icon_medal_gold"):setVisible(goldOrSilver)
    self.mainUI:getChildByName("icon_medal_silver"):setVisible(not goldOrSilver)
    self.mainUI:getChildByName("txt4"):getChildByName("txt"):setString(rewardMedal)
    self.mainUI:getChildByName("txt5"):getChildByName("txt"):setString(rewardMoney)
    
    self:setRefreshCost()

    local leftChallengeTime = DataManager.GameMetaData.activityWantedConfig.completeNum - self.DailyData.wanteds
    if starCount == 5 or leftChallengeTime == 0 then
        self.refreshTaskBtn.display:getChildByName("normal"):setVisible(false)
        self.refreshTaskBtn:setEnable(false)
    else
        self.refreshTaskBtn.display:getChildByName("normal"):setVisible(true)
        self.refreshTaskBtn:setEnable(true)
    end

    self:setWantedPicAndStar(starCount)

    self.rewardsInfo = {goldOrSilver = goldOrSilver , rewardMedal = rewardMedal , rewardMoney = rewardMoney , starCount = starCount}
end

function Activity_WantedLayer:setWantedPicAndStar(count)
    if count > 0 and count < 6 then
        for i=1,5 do
            if i <= count then
                self.starsArr[i]:setVisible(true)
            else
                self.starsArr[i]:setVisible(false)
            end

            if i == count then
                self.wantedPicArr[i]:setVisible(true)
            else
                self.wantedPicArr[i]:setVisible(false)
            end
        end
    end
end

function Activity_WantedLayer:setRefreshCost()
    if self.CheckBoxSelected then
        self.currentCost = tonumber(DataManager.GameMetaData.activityWantedConfig.newRefreshPrice)
    else
        if self.DailyData.refresh then
            self.currentCost = tonumber(DataManager.GameMetaData.activityWantedConfig.refreshPrice)
        else
            self.currentCost = 0
        end
    end

    self.refreshTaskBtn.display:getChildByName("txt2"):setString(self.currentCost)
end

function Activity_WantedLayer:enable()
     local isEnable = MaintenanceManager.isActivityOpen("activityWanted")
     return isEnable
end

function Activity_WantedLayer:dispose()
    NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    Activity_WantedLayer.super.dispose(self)
end

function Activity_WantedLayer.getTipNum()
    if not Activity_WantedLayer.enable() then
        return 0
    end

    local DailyData = DailyDataManager.getWantedActivityData()
    if DailyData then
        local leftChallengeTime = DataManager.GameMetaData.activityWantedConfig.completeNum - DailyData.wanteds
        return leftChallengeTime
    else
        return 0
    end
end