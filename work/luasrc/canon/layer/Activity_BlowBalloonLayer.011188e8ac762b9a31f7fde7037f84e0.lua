require "hecore.display.Layer"
require "canon.panel.ActivityInfoPanel"
require "canon.request.BlowBalloonActBuyEnegyRequest"
require "canon.request.BlowBalloonActGetEnegyRequest"
require "canon.request.BlowBalloonActGainMagicValueRequest"
require "canon.request.BlowBalloonActGetMagicRewardRequest"
require "canon.request.BlowBalloonActGetRankRewardRequest"
require "canon.panel.BlowBalloonRankPanel"
require "canon.panel.BlowBalloonRankInfoPanel"
require "canon.panel.BlowBalloonMagicRewardPanel"
require "canon.panel.BlowBalloonBuyStonePanel"
require "canon.panel.GetRewardInfoPanel"

--
-- Activity_BlowBalloonLayer
--

--跨天事件
local function onPassDay(evt)
    local self = evt.context

    local rewardTipNum = Activity_BlowBalloonLayer.getRewardTipNum()
    if rewardTipNum > 0 then
        SuspensionLabel:showContent(self.container, getTextByKey("balloon_tip5"))
    else
        SuspensionLabel:showContent(self.container, getTextByKey("balloon_tip6"))
    end

    local featureName = DataManager.GameMetaData.activityBalloonConfig.featureName
    self.activityOutData = not MaintenanceManager.isActivityOpen(featureName)

    local featureNameReward = DataManager.GameMetaData.activityBalloonConfig.featureNameReward
    self.activityClose = not MaintenanceManager.isActivityOpen(featureNameReward)

    g_homeInfo.balloonDaily.balloonPoint = 0
    self.Data_Score = 0

    g_homeInfo.balloonDaily.receiveTimes = 0
    self.Data_ReceiveTimes = 0

    g_homeInfo.balloonDaily.balloonLevel = 0
    self.Data_JadeLevel = 0

    self.ShouldRefreshRank = true

    self:setData()
end

Activity_BlowBalloonLayer = class(Layer)
function Activity_BlowBalloonLayer:ctor()
    self.container = nil
end

function Activity_BlowBalloonLayer:create(container , extraArgs)
    local s = Activity_BlowBalloonLayer.new()
    s.container = container
    s.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_BlowBalloonLayer:initLayer()
    Activity_BlowBalloonLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("Blowing Balloons")
    self:addChild(self.mainUI)

    local activityTimeKey = DataManager.GameMetaData.activityBalloonConfig.featureName
    local activityTimeInfo = MaintenanceManager:getStartAndEndTime(activityTimeKey)
    self.mainUI:getChildByName("Blowing Balloons_txt _7"):getChildByName("txt"):setString(getTextByKey("activity_dice_top_title4",{num1 = activityTimeInfo[1].month ,num2 = activityTimeInfo[1].day , num3 = activityTimeInfo[2].month , num4 = activityTimeInfo[2].day}))

    self.mainUI:getChildByName("Blowing Balloons_txt _1"):getChildByName("txt"):setString(getTextByKey("activity_timeOver"))

    self.frontEffectContainer = self.mainUI:getChildByName("frontEffectContainer")
    self.backEffectContainer = self.mainUI:getChildByName("backEffectContainer")

    if not g_homeInfo then g_homeInfo = {} end
    
    if not g_homeInfo.balloonDaily then
        g_homeInfo.balloonDaily = {}
        g_homeInfo.balloonDaily.receiveTimes = 0
        g_homeInfo.balloonDaily.balloonLevel = 0
        g_homeInfo.balloonDaily.balloonPoint = 0
    end

    self.Data_ReceiveTimes = g_homeInfo.balloonDaily.receiveTimes -- 收获次数
    self.Data_JadeLevel = g_homeInfo.balloonDaily.balloonLevel -- 灵玉等级
    self.Data_Score = g_homeInfo.balloonDaily.balloonPoint -- 当前积分
    self.Data_EnegyStoneId = DataManager.GameMetaData.activityBalloonConfig.propId

    self.JadePicArr = {}
    for i=1,7 do
        self.mainUI:getChildByName("JadePic_"..(i-1)):setAnchorPoint(ccp(0.5, 0.5))
        table.insert(self.JadePicArr, self.mainUI:getChildByName("JadePic_"..(i-1)))
    end
    
    -- 帮助界面
    local function infoButtonSelected(evt)
        self.container:setTableViewsEnabled(false)

        local activityTimeKey = DataManager.GameMetaData.activityBalloonConfig.featureName
        local activityTimeInfo = MaintenanceManager:getStartAndEndTime(activityTimeKey)

        local activityRewardDeadlineKey = DataManager.GameMetaData.activityBalloonConfig.featureNameReward
        local activityRewardDeadlineInfo = MaintenanceManager:getStartAndEndTime(activityRewardDeadlineKey)

        local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("balloon_help1",{month1 = activityTimeInfo[1].month , day1 = activityTimeInfo[1].day , month2 = activityTimeInfo[2].month , day2 = activityTimeInfo[2].day , month3 = activityRewardDeadlineInfo[2].month , day3 = activityRewardDeadlineInfo[2].day}))
        self.container:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
    end
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    -- 收获
    local function getMagicValueFunc(evt)
        if self.activityClose then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        local function successCallback(e)
            if g_homeInfo then
                if not g_homeInfo.balloonDaily then
                    g_homeInfo.balloonDaily = {}
                end
                
                g_homeInfo.balloonDaily.balloonPoint = e.data.currPoint
                self.Data_Score = e.data.currPoint

                g_homeInfo.balloonDaily.receiveTimes = g_homeInfo.balloonDaily.receiveTimes + 1
                self.Data_ReceiveTimes = g_homeInfo.balloonDaily.receiveTimes

                local originalJadeLevel = g_homeInfo.balloonDaily.balloonLevel
                g_homeInfo.balloonDaily.balloonLevel = 0
                self.Data_JadeLevel = 0

                -- self:setData()
                self:showGainJadeAni(originalJadeLevel)

            else
                print("连homeInfo都没了？")
            end
        end
        local function failedCallback(e)
            local errorCode = tonumber(e.data)
            if errorCode == 714720 then
                CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
            -- CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end

        local request = BlowBalloonActGainMagicValueRequest.new({}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGainMagicValueRequestSucceed, successCallback)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGainMagicValueRequestFailed, failedCallback)
        request:start()
    end
    self.getMagicValueBtn = Button:create(self.mainUI:getChildByName("Blowing Balloons_btn"))
    self.getMagicValueBtn:addEventListener(Events.kStart, getMagicValueFunc, self)

    -- 补充
    local function addEnegyFunc(evt)
        if self.activityClose then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        self.container:setTableViewsEnabled(false)

        local aBuyStonePanel = BlowBalloonBuyStonePanel:create(self.container,self)
        self.container:addChild(aBuyStonePanel)
        aBuyStonePanel:scaleIn()
    end

    self.addEnegyBtn = Button:create(self.mainUI:getChildByName("Blowing Balloons_btn3"))
    self.addEnegyBtn.display:getChildByName("txt"):setString(getTextByKey("replenish_txt"))
    self.addEnegyBtn:addEventListener(Events.kStart, addEnegyFunc, self)

    -- 充能
    local function reChargeEnegyFunc(evt)
        if self.activityClose then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        if DataManager.GameMetaData.activityBalloonConfig.cost > BagCalcManager.getNumById(self.Data_EnegyStoneId) then
            -- 没能量石了，补充
            addEnegyFunc(evt)
            return
        end

        -- 看钱够不够
        if self.CheckBoxSelected then
            local gems = CalculationManager.calcComplex_getGemsNow()
            if self.costGoldNum > gems then
                local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
                self:addChild(aPanel)
                aPanel:scaleIn()
                return
            end
        end

        local function successCallback(e)
            -- 扣钱
            if self.CheckBoxSelected then
                RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.costGoldNum}})
            end

            if g_homeInfo then
                if not g_homeInfo.balloonDaily then
                    g_homeInfo.balloonDaily = {}
                end
                g_homeInfo.balloonDaily.balloonLevel = e.data.balloonLevel
                self.Data_JadeLevel = e.data.balloonLevel

                local successOrFailed = nil
                if e.data.balloonLevel == 0 then
                    successOrFailed = false
                else
                    successOrFailed = true
                end
                self:showAnimation(e.data.balloonLevel,successOrFailed)

                -- 扣能量石
                RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = self.Data_EnegyStoneId , amount = -DataManager.GameMetaData.activityBalloonConfig.cost}})
                RewardManager:getReward(e.data.rewards)

                -- self:setData()
            else
                print("连homeInfo都没了？")
            end
        end
        local function failedCallback(e)
            local errorCode = tonumber(e.data)
            if errorCode == 714720 then
                CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
        end

        local request = BlowBalloonActGetEnegyRequest.new({ensureSuccess = self.CheckBoxSelected}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetEnegyRequestSucceed, successCallback)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActGetEnegyRequestFailed, failedCallback)
        request:start()
    end
    self.reChargeEnegyBtn = Button:create(self.mainUI:getChildByName("Blowing Balloons_btn2"))
    self.reChargeEnegyBtn.display:getChildByName("txt"):setString(getTextByKey("balloon_charge"))
    self.reChargeEnegyBtn:addEventListener(Events.kStart, reChargeEnegyFunc, self)

    -- 复选框
    self.checkBoxDisplay = self.mainUI:getChildByName("keep_control_all_select")
    local function onClickCheckBox(evt)
        self.CheckBoxSelected = not self.CheckBoxSelected
        self:setCheckBoxStatus()
    end
    local checkBoxBtn = Button:create(self.checkBoxDisplay:getChildByName("btn_not_selected_all"))
    checkBoxBtn:addEventListener(Events.kStart, onClickCheckBox, self)
    self.checkBoxDisplay:getChildByName("btn_selected_all").touchEnabled = false
    self.checkBoxDisplay:getChildByName("btn_selected_all").touchChildren = false
    self.checkBoxDisplay:getChildByName("txt_select"):getChildByName("txt"):setString(getTextByKey("balloon_tip1"))

    self.CheckBoxSelected = false
    
    -- 排行榜
    local function openRankPanelFunc(evt)
        if self.activityClose then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        local function openRankPanel()
            self.container:setTableViewsEnabled(false)
            local aRankPanel = nil
            -- 
            -- self.extraArgs.balloonRanks = {
            --     {nickName = "傻逼1" , level = 15 , receiveTimes = 10 , point = 500 , mainCardMetaId = 101117},
            --     {nickName = "傻逼2" , level = 12 , receiveTimes = 10 , point = 500 , mainCardMetaId = 101117},
            --     {nickName = "傻逼3" , level = 13 , receiveTimes = 10 , point = 500 , mainCardMetaId = 101117},
            --     {nickName = "傻逼4" , level = 10 , receiveTimes = 10 , point = 500 , mainCardMetaId = 101117},
            --     {nickName = "傻逼5" , level = 16 , receiveTimes = 10 , point = 500 , mainCardMetaId = 101117}
            -- }
            -- 

            if self.extraArgs.balloonRanks and #self.extraArgs.balloonRanks > 0 then
                aRankPanel = BlowBalloonRankPanel:create(self.container,self,self.extraArgs.balloonRanks)
            else
                aRankPanel = BlowBalloonRankInfoPanel:create(self.container,self)
            end
            
            self.container:addChild(aRankPanel)
            aRankPanel:scaleIn()
        end


        if self.ShouldRefreshRank then
            local function successCallback(evt)
                local extraArgs = evt.data or {gainYesterdayPointReward = false , balloonRanks = {}}
                self.extraArgs = extraArgs

                local myUid = DataManager.getCurrUser().uid
                local myRank = 0
                for i,v in ipairs(extraArgs.balloonRanks) do
                    if v.uid == myUid then
                        myRank = i
                        break
                    end
                end
                if g_homeInfo == nil then
                    g_homeInfo = {}
                end
                g_homeInfo.balloonMyRank = myRank
                self.ShouldRefreshRank = nil
                openRankPanel()
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
        else
            openRankPanel()
        end
    end

    self.openRankPanelBtn = CanonButton:create(self.mainUI:getChildByName("BlowBalloonRankBtn"))
    self.openRankPanelBtn:addEventListener(Events.kStart, openRankPanelFunc, self)

    -- 魔力值奖励
    local function openMagicRewardPanelFunc(evt)
        self.container:setTableViewsEnabled(false)

        local aMagicRewardPanel = BlowBalloonMagicRewardPanel:create(self.container,self)
        self.container:addChild(aMagicRewardPanel)
        aMagicRewardPanel:scaleIn()
    end

    self.openMagicRewardPanelBtn = CanonButton:create(self.mainUI:getChildByName("BlowBalloonRewardBtn"))
    self.openMagicRewardPanelBtn:addEventListener(Events.kStart, openMagicRewardPanelFunc, self)

    self.MaxBalloonLevel = (#DataManager.GameMetaData.activityBalloonConfig.balloonLevelMetas) - 1

    local featureName = DataManager.GameMetaData.activityBalloonConfig.featureName
    self.activityOutData = not MaintenanceManager.isActivityOpen(featureName)

    local featureNameReward = DataManager.GameMetaData.activityBalloonConfig.featureNameReward
    self.activityClose = not MaintenanceManager.isActivityOpen(featureNameReward)

    -- 设置界面内容
    self:setData()

    if self.extraArgs.gainYesterdayPointReward then
        SuspensionLabel:showContent(self, getTextByKey("balloon_tip5"))
    end

    -- NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end

-- 播放动画
function Activity_BlowBalloonLayer:showAnimation(JadeLevel,successOrFailed)
    local RunningScene = Director:sharedDirector():getRunningScene()
    RunningScene:setTouchEnabled(false)
    self.container:setTableViewsEnabled(false)

    self:switchJadePic(-1)
    self.JadePicArr[JadeLevel+1]:setOpacity(0)
    self.JadePicArr[JadeLevel+1]:setVisible(true)

    local arr = CCArray:create()
    
    local function checkAnimationOver()
        self.AnimationRetain = self.AnimationRetain - 1
        if self.AnimationRetain == 0 then
            self:setData()
            RunningScene:setTouchEnabled(true)
            self.container:setTableViewsEnabled(true)
        end
    end
    if successOrFailed then
        arr:addObject(CCDelayTime:create(1))
        arr:addObject(CCFadeIn:create(1.4))
        self.AnimationRetain = 2
        local fspt_0 = FlashSprite:create("EVO2/blowballoon")
        fspt_0:changeAnimation(0)
        fspt_0:setLoop(false)
        self.fspt_co_0 = CocosObject.new(fspt_0)
        local function animationEnd_0(anim)
            fspt_0:unregisterEndAnimationScriptHandler()
            self.backEffectContainer:removeChild(self.fspt_co_0)
            checkAnimationOver()
        end
        fspt_0:registerEndAnimationScriptHandler(animationEnd_0)
        self.frontEffectContainer:addChild(self.fspt_co_0)

        local fspt_1 = FlashSprite:create("EVO2/blowballoon")
        fspt_1:changeAnimation(1)
        fspt_1:setLoop(false)
        self.fspt_co1 = CocosObject.new(fspt_1)
        local function animationEnd_1(anim)
            fspt_1:unregisterEndAnimationScriptHandler()
            self.frontEffectContainer:removeChild(self.fspt_co1)
            checkAnimationOver()
        end
        fspt_1:registerEndAnimationScriptHandler(animationEnd_1)
        self.backEffectContainer:addChild(self.fspt_co1)
    else
        arr:addObject(CCDelayTime:create(1.6))
        arr:addObject(CCFadeIn:create(0.9))
        self.AnimationRetain = 1
        local fspt_2 = FlashSprite:create("EVO2/blowballoon")
        fspt_2:changeAnimation(2)
        fspt_2:setLoop(false)
        self.fspt_co_2 = CocosObject.new(fspt_2)
        local function animationEnd_2(anim)
            fspt_2:unregisterEndAnimationScriptHandler()
            self.backEffectContainer:removeChild(self.fspt_co_2)
            checkAnimationOver()
        end
        fspt_2:registerEndAnimationScriptHandler(animationEnd_2)
        self.backEffectContainer:addChild(self.fspt_co_2)
    end

    -- local function enterActionFinished()
        
    -- end
    -- arr:addObject(CCCallFunc:create(enterActionFinished))
    self.JadePicArr[JadeLevel+1]:runAction(CCSequence:create(arr))
end

-- 收获特效
function Activity_BlowBalloonLayer:showGainJadeAni(JadeLevel)
    local RunningScene = Director:sharedDirector():getRunningScene()
    RunningScene:setTouchEnabled(false)
    self.container:setTableViewsEnabled(false)

    local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(0.8))
    arr:addObject(CCScaleTo:create(0.8,5))

    local function enterActionFinished()
        self.JadePicArr[JadeLevel+1]:setScale(1)
        self:setData()
        RunningScene:setTouchEnabled(true)
        self.container:setTableViewsEnabled(true)
    end
    self.JadePicArr[1]:setVisible(true)
    self.JadePicArr[JadeLevel+1]:runAction(CCSequence:createWithTwoActions(CCSpawn:create(arr), CCCallFunc:create(enterActionFinished)))
end

-- 设置灵玉图片
function Activity_BlowBalloonLayer:switchJadePic(JadeLevel)
    -- 设置灵玉图片
    for i,v in ipairs(self.JadePicArr) do
        if i == (JadeLevel + 1) then
            v:setVisible(true)
        else
            v:setVisible(false)
        end
    end
end

function Activity_BlowBalloonLayer:setData()
    if self.activityOutData then
        self.mainUI:getChildByName("Blowing Balloons_txt _1"):setVisible(true)

        self.mainUI:getChildByName("Blowing Balloons_txt _6"):setVisible(false)
        self.mainUI:getChildByName("Blowing Balloons_txt _4"):setVisible(false)
        self.mainUI:getChildByName("Blowing Balloons_txt _3"):setVisible(false)
    else
        self.mainUI:getChildByName("Blowing Balloons_txt _1"):setVisible(false)

        self.mainUI:getChildByName("Blowing Balloons_txt _6"):setVisible(true)
        self.mainUI:getChildByName("Blowing Balloons_txt _4"):setVisible(true)
        self.mainUI:getChildByName("Blowing Balloons_txt _3"):setVisible(true)

        -- 当前积分
        self.mainUI:getChildByName("Blowing Balloons_txt _6"):getChildByName("txt"):setString(getTextByKey("balloon_tip3")..self.Data_Score)

        -- 魔力值+
        if self.Data_JadeLevel < self.MaxBalloonLevel then
            local nextLevelPoint = DataManager.GameMetaData.activityBalloonConfig.balloonLevelMetas[self.Data_JadeLevel+2].point
            self.mainUI:getChildByName("Blowing Balloons_txt _4"):getChildByName("txt"):setString(getTextByKey("balloon_tip2",{num4 = nextLevelPoint}))
        else
            self.mainUI:getChildByName("Blowing Balloons_txt _4"):getChildByName("txt"):setString(getTextByKey("balloon_tip7"))
        end

        -- 灵玉等级
        self.mainUI:getChildByName("Blowing Balloons_txt _3"):getChildByName("txt"):setString("Lv.".. self.Data_JadeLevel)
    end

    
    -- 拥有能量石
    local enegyStoneCount = BagCalcManager.getNumById(self.Data_EnegyStoneId)
    self.mainUI:getChildByName("Blowing Balloons_txt _5"):getChildByName("txt"):setString(getTextByKey("balloon_stone",{num = enegyStoneCount}))

    local currentLevelPoint = DataManager.GameMetaData.activityBalloonConfig.balloonLevelMetas[self.Data_JadeLevel+1].point
    self.mainUI:getChildByName("Blowing Balloons_txt _2"):getChildByName("txt"):setString(getTextByKey("balloon_tip4",{num3 = currentLevelPoint}))

    -- 设置灵玉图片
    self:switchJadePic(self.Data_JadeLevel)

    local getMagicValueLeftTimes = DataManager.GameMetaData.activityBalloonConfig.gainsChance - self.Data_ReceiveTimes

    -- 设置充能按钮
    if self.Data_JadeLevel < self.MaxBalloonLevel and getMagicValueLeftTimes > 0 and not self.activityOutData then
        self.reChargeEnegyBtn:setEnable(true)
        self.reChargeEnegyBtn.display:getChildByName("normal"):setVisible(true)
    else
        self.reChargeEnegyBtn:setEnable(false)
        self.reChargeEnegyBtn.display:getChildByName("normal"):setVisible(false)
    end

    -- 设置补充按钮
    if self.activityOutData then
        self.addEnegyBtn:setEnable(false)
        self.addEnegyBtn.display:getChildByName("normal"):setVisible(false)
    else
        self.addEnegyBtn:setEnable(true)
        self.addEnegyBtn.display:getChildByName("normal"):setVisible(true)
    end
    
    -- 设置收获按钮
    local getMagicValueEnable = nil
    if self.Data_JadeLevel > 0 and getMagicValueLeftTimes > 0 and not self.activityOutData then
        getMagicValueEnable = true
    else
        getMagicValueEnable = false
    end

    self.getMagicValueBtn:setEnable(getMagicValueEnable)
    self.getMagicValueBtn.display:getChildByName("normal"):setVisible(getMagicValueEnable)
    self.getMagicValueBtn.display:getChildByName("txt"):setString(getTextByKey("balloon_get",{num = getMagicValueLeftTimes}))

    self.openRankPanelBtn:setNum(Activity_BlowBalloonLayer.getRankTipNum())
    self.openMagicRewardPanelBtn:setNum(Activity_BlowBalloonLayer.getRewardTipNum())

    -- 设置复选框
    self:setCheckBoxStatus()
end

function Activity_BlowBalloonLayer:setCheckBoxStatus()
    if self.CheckBoxSelected then
        self.reChargeEnegyBtn.display:getChildByName("txt"):setVisible(false)
        if self.Data_JadeLevel < self.MaxBalloonLevel then
            self.costGoldNum = DataManager.GameMetaData.activityBalloonConfig.balloonLevelMetas[self.Data_JadeLevel+1].money
            self.reChargeEnegyBtn.display:getChildByName("txt2"):setString(self.costGoldNum..getTextByKey("balloon_charge"))
            self.reChargeEnegyBtn.display:getChildByName("txt2"):setVisible(true)
            self.reChargeEnegyBtn.display:getChildByName("txt"):setVisible(false)
            self.reChargeEnegyBtn.display:getChildByName("icon_gold"):setVisible(true)
        else
            self.reChargeEnegyBtn.display:getChildByName("txt2"):setVisible(false)
            self.reChargeEnegyBtn.display:getChildByName("txt"):setVisible(true)
            self.reChargeEnegyBtn.display:getChildByName("icon_gold"):setVisible(false)
        end
        self.checkBoxDisplay:getChildByName("btn_selected_all"):setVisible(true)
    else
        self.reChargeEnegyBtn.display:getChildByName("txt"):setVisible(true)
        self.reChargeEnegyBtn.display:getChildByName("txt2"):setVisible(false)
        self.reChargeEnegyBtn.display:getChildByName("icon_gold"):setVisible(false)
        self.checkBoxDisplay:getChildByName("btn_selected_all"):setVisible(false)
    end
end

function Activity_BlowBalloonLayer:enable()
    -- return true
    local featureName = DataManager.GameMetaData.activityBalloonConfig.featureNameReward
    local isEnable = MaintenanceManager.isActivityOpen(featureName)
    return isEnable
end

function Activity_BlowBalloonLayer:dispose()
    -- NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    Activity_BlowBalloonLayer.super.dispose(self)
end

function Activity_BlowBalloonLayer.getTipNum()
    if not Activity_BlowBalloonLayer.enable() then
        return 0
    end
    
    local tipNum = 0

    local rankTipNum = Activity_BlowBalloonLayer.getRankTipNum()
    if rankTipNum > 0 then
        tipNum = tipNum + 1
    end

    local rewardTipNum = Activity_BlowBalloonLayer.getRewardTipNum()
    if rewardTipNum > 0 then
        tipNum = tipNum + 1
    end

    return tipNum
end

function Activity_BlowBalloonLayer.getRankTipNum()
    local tipNum = 0
    if g_homeInfo and g_homeInfo.balloonMyRank then
        if g_homeInfo.balloonMyRank > 0 and not g_homeInfo.balloonDaily.gainedRankReward then
            tipNum = tipNum + 1
        end
    end
    return tipNum
end

function Activity_BlowBalloonLayer.getRewardTipNum()
    local tipNum = 0
    if g_homeInfo and g_homeInfo.balloonDaily then
        if g_homeInfo.balloonDaily.gainedPointRewardIds and g_homeInfo.balloonDaily.balloonPoint and DataManager.GameMetaData.activityBalloonConfig and DataManager.GameMetaData.activityBalloonConfig.balloonPointRewardMetas then
            for i,v in ipairs(DataManager.GameMetaData.activityBalloonConfig.balloonPointRewardMetas) do
                if v.pointSection > g_homeInfo.balloonDaily.balloonPoint then
                    break
                else
                    local shouldAdd = true
                    for j,k in ipairs(g_homeInfo.balloonDaily.gainedPointRewardIds) do
                        if k == v.id then
                            shouldAdd = false
                            break
                        end
                    end
                    if shouldAdd then
                        tipNum = tipNum + 1
                    end
                end
            end
        end        
    end
    return tipNum
end