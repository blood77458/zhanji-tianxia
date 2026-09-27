require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainNewYearRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_NewYearLayer
--

Activity_NewYearLayer = class(Layer)
function Activity_NewYearLayer:ctor()
    self.container = nil
end

function Activity_NewYearLayer:create( container )
    local s = Activity_NewYearLayer.new()
    self.container = container
    s:initLayer()
    return s
end

function Activity_NewYearLayer:initLayer()
    Activity_NewYearLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.mainUI = self.builder:build("launch_activity4")
    self:addChild(self.mainUI)
    self.builder.useArtLabelTTF = true
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      
      local activityTimeInfo = MaintenanceManager:getStartAndEndTime("activityNewyeatCalcPay")
      local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime("activityNewyearGainReward")
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText("activity_newyear_help", {year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time, year3 = activityGainRewardTimeInfo[2].year, month3 = activityGainRewardTimeInfo[2].month, day3 = activityGainRewardTimeInfo[2].day, time3 = activityGainRewardTimeInfo[2].time}))
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_activity_helpinfo"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    local guide_other = self.mainUI:getChildByName("guide_other")
    guide_other:setVisible(false)
    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103004))
    card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0))
    self.mainUI:addChildAt(card3_spf, 4)
    
    local rewardLabel1_1 = self.mainUI:getChildByName("txt_newyear_reward_time1")
    rewardLabel1_1:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_1:getChildByName("txt"):getDimensions().height))
    rewardLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime"))
    local rewardLabel1_2 = self.mainUI:getChildByName("txt_newyear_reward_time1_1")
    local aNewPosX = rewardLabel1_1:getPosition().x + rewardLabel1_1:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_2:setPositionX(aNewPosX)
    local rewardLabel1_3 = self.mainUI:getChildByName("txt_newyear_reward_time2")
    rewardLabel1_3:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_3:getChildByName("txt"):getDimensions().height))
    rewardLabel1_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown1"))
    local rewardLabel1_4 = self.mainUI:getChildByName("txt_newyear_reward_time2_1")
    aNewPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_4:setPositionX(aNewPosX)
    rewardLabel1_4:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_4:getChildByName("txt"):getDimensions().height))
    local rewardLabel1_5 = self.mainUI:getChildByName("txt_owurida")
    rewardLabel1_5:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown3"))
    local rewardLabel2_1 = self.mainUI:getChildByName("txt_wonreward_over")
    rewardLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_timeOver"))
    local rewardLabel2_2 = self.mainUI:getChildByName("txt_activity_getreward_time")
    rewardLabel2_2:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel2_2:getChildByName("txt"):getDimensions().height))
    rewardLabel2_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_reward_endTime"))
    local rewardLabel2_3 = self.mainUI:getChildByName("txt_newyear_reward_time1_2")
    aNewPosX = rewardLabel2_2:getPosition().x + rewardLabel2_2:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel2_3:setPositionX(aNewPosX)
    
    local rechargeRewardConfigs = DataManager.GameMetaData.activityNewYearConfig.payRewards
    --print(table.tostring(rechargeRewardConfigs))
    local tipLabel1_1 = self.mainUI:getChildByName("txt_chargeto1")
    tipLabel1_1:getChildByName("txt"):setDimensions(CCSizeMake(0,tipLabel1_1:getChildByName("txt"):getDimensions().height))
    tipLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_newyear_rewardTips1"))
    local tipLabel1_2 = self.mainUI:getChildByName("txt_chargeto2")
    tipLabel1_2:getChildByName("txt"):setDimensions(CCSizeMake(0,tipLabel1_2:getChildByName("txt"):getDimensions().height))
    tipLabel1_2:setPositionX(tipLabel1_1:getPosition().x + tipLabel1_1:getChildByName("txt"):getTexture():getContentSize().width)
    tipLabel1_2:getChildByName("txt"):setString(string.format("%d", rechargeRewardConfigs[1].gold))
    local tipLabel1_3 = self.mainUI:getChildByName("txt_chargeto3")
    tipLabel1_3:setPositionX(tipLabel1_1:getPosition().x + tipLabel1_1:getChildByName("txt"):getTexture():getContentSize().width + tipLabel1_2:getChildByName("txt"):getTexture():getContentSize().width)
    tipLabel1_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_newyear_rewardTips2"))
    local tipLabel2_1 = self.mainUI:getChildByName("txt_chargeto1_1")
    tipLabel2_1:getChildByName("txt"):setDimensions(CCSizeMake(0,tipLabel2_1:getChildByName("txt"):getDimensions().height))
    tipLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_newyear_rewardTips1"))
    local tipLabel2_2 = self.mainUI:getChildByName("txt_chargeto2_1")
    tipLabel2_2:getChildByName("txt"):setDimensions(CCSizeMake(0,tipLabel2_2:getChildByName("txt"):getDimensions().height))
    tipLabel2_2:setPositionX(tipLabel2_1:getPosition().x + tipLabel2_1:getChildByName("txt"):getTexture():getContentSize().width)
    tipLabel2_2:getChildByName("txt"):setString(string.format("%d", rechargeRewardConfigs[2].gold))
    local tipLabel2_3 = self.mainUI:getChildByName("txt_chargeto3_1")
    tipLabel2_3:setPositionX(tipLabel2_1:getPosition().x + tipLabel2_1:getChildByName("txt"):getTexture():getContentSize().width + tipLabel2_2:getChildByName("txt"):getTexture():getContentSize().width)
    tipLabel2_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_newyear_rewardTips2"))
    
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkActivity = gameInitData.sharkActivity or {}
    local amountRecharged = gameInitData.sharkActivity.nyChagrgedGems or 0
    
    local refreshSelf
    
    local function gainReward(aRewardId)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function gainNewYearRewardsSucceed(event)
        RewardManager:getReward(event.data.rewards)
        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkActivity = gameInitData.sharkActivity or {}
        if not gameInitData.sharkActivity.nyGainedRewardIds then
          gameInitData.sharkActivity.nyGainedRewardIds = {}
        end
        table.insert(gameInitData.sharkActivity.nyGainedRewardIds, aRewardId)
        DataManager.setGameInitData(gameInitData)
        refreshSelf()
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, event.data.rewards )
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
      end 
      local function gainNewYearRewardsFailed(event)
        if event.data.retCode == 714420 then  --activity closed
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_error_expired")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {id = aRewardId}
      local request = GainNewYearRewardsRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainNewYearRewardsSucceed, gainNewYearRewardsSucceed)
      request:addEventListener(RequestNotifyEnum.GainNewYearRewardsFailed, gainNewYearRewardsFailed)
      request:start()
    end
    
    local firstButtonDisplay = self.mainUI:getChildByName("btn_lv20get")
    local function firstButtonSelected(evt)
      gainReward(rechargeRewardConfigs[1].id)
    end
    local firstButton = Button:create(firstButtonDisplay)
    firstButton:addEventListener(Events.kStart,firstButtonSelected, self)
    local secondButtonDisplay = self.mainUI:getChildByName("btn_lv40get")
    local function secondButtonSelected(evt)
      gainReward(rechargeRewardConfigs[2].id)
    end
    local secondButton = Button:create(secondButtonDisplay)
    secondButton:addEventListener(Events.kStart,secondButtonSelected, self)
    
    
    local function existInGainedRewardList(aInt, gainedList)
      for _, v in ipairs(gainedList) do
        if v == aInt then
          return true
        end
      end
      return false
    end
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose("activityNewyeatCalcPay")
      local whetherPassedGainRewardTime, leftGainRewardTimeStamp, gainEndMonth, gainEndDay, gainEndHour, gainEndYear = MaintenanceManager.isActivityAlreadyClose("activityNewyearGainReward")
      if whetherPassedActivityTime then
        rewardLabel1_1:setVisible(false)
        rewardLabel1_2:setVisible(false)
        rewardLabel1_3:setVisible(false)
        rewardLabel1_4:setVisible(false)
        rewardLabel1_5:setVisible(false)
        rewardLabel2_1:setVisible(true)
        rewardLabel2_2:setVisible(true)
        rewardLabel2_3:setVisible(true)
        rewardLabel2_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = gainEndYear, month = gainEndMonth, day = gainEndDay, hour = gainEndHour}))
        
        if self.checkActivityPassedEntry then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
          self.checkActivityPassedEntry = nil
        end
      else
        rewardLabel1_1:setVisible(true)
        rewardLabel1_2:setVisible(true)
        rewardLabel1_3:setVisible(true)
        rewardLabel1_4:setVisible(true)
        rewardLabel1_5:setVisible(true)
        rewardLabel2_1:setVisible(false)
        rewardLabel2_2:setVisible(false)
        rewardLabel2_3:setVisible(false)
        rewardLabel1_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = activityEndYear, month = activityEndMonth, day = activityEndDay, hour = activityEndHour}))
        rewardLabel1_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown2", {hour = math.modf(leftActivityTimeStamp / 3600), min = math.modf(math.mod(leftActivityTimeStamp, 3600) / 60)}))
        local aPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width + rewardLabel1_4:getChildByName("txt"):getTexture():getContentSize().width
        rewardLabel1_5:setPositionX(aPosX)
        
        if not self.checkActivityPassedEntry then
          self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,15,false)
        end
      end
      
      local function refreshButtons()
        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkActivity = gameInitData.sharkActivity or {}
        local gainedRewardList = gameInitData.sharkActivity.nyGainedRewardIds or {}
        if existInGainedRewardList(rechargeRewardConfigs[1].id, gainedRewardList) then
          firstButton:setEnable(false)
          firstButtonDisplay:getChildByName("btn_yellow_long"):setVisible(false)
          firstButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          firstButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
        elseif amountRecharged < rechargeRewardConfigs[1].gold then
          firstButton:setEnable(false)
          firstButtonDisplay:getChildByName("btn_yellow_long"):setVisible(false)
          firstButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          firstButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        else
          firstButton:setEnable(true)
          firstButtonDisplay:getChildByName("btn_yellow_long"):setVisible(true)
          firstButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
          firstButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        end
        
        if existInGainedRewardList(rechargeRewardConfigs[2].id, gainedRewardList) then
          secondButton:setEnable(false)
          secondButtonDisplay:getChildByName("btn_green_long"):setVisible(false)
          secondButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          secondButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
        elseif amountRecharged < rechargeRewardConfigs[2].gold then
          secondButton:setEnable(false)
          secondButtonDisplay:getChildByName("btn_green_long"):setVisible(false)
          secondButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          secondButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        else
          secondButton:setEnable(true)
          secondButtonDisplay:getChildByName("btn_green_long"):setVisible(true)
          secondButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
          secondButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        end
      end
      
      refreshButtons()
    end
    
    refreshSelf()
    
    local function showRewardPanel(rewardList)
      local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
      self.container:addChild(aRewardPanel)
      aRewardPanel:scaleIn()
    end
    
    local function reward1BtnSelected(evt)
      showRewardPanel(MetaManager.getRewardInfoByID(rechargeRewardConfigs[1].rewardPackId) or {})
    end
    local reward1BtnDisplay = self.mainUI:getChildByName("icon_prop_1")
    local reward1Btn = Button:create(reward1BtnDisplay)
    reward1Btn:addEventListener(Events.kStart, reward1BtnSelected, self)
    
    local function reward2BtnSelected(evt)
      showRewardPanel(MetaManager.getRewardInfoByID(rechargeRewardConfigs[2].rewardPackId) or {})
    end
    local reward2BtnDisplay = self.mainUI:getChildByName("icon_prop_2")
    local reward2Btn = Button:create(reward2BtnDisplay)
    reward2Btn:addEventListener(Events.kStart, reward2BtnSelected, self)
end

function Activity_NewYearLayer:enable()
    local isEnable = MaintenanceManager.isActivityOpen("activityNewyearPanel")
    return isEnable
end 

function Activity_NewYearLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_NewYearLayer.super.dispose(self)
end

function Activity_NewYearLayer.getTipNum()
  
  return 0
end