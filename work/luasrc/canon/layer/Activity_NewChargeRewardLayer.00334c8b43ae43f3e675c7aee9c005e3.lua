require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainNewYearRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_NewChargeRewardLayer
--

local function existInGainedRewardList(aInt, gainedList)
  for _, v in ipairs(gainedList) do
    if v == aInt then
      return true
    end
  end
  return false
end

Activity_NewChargeRewardLayer = class(Layer)
function Activity_NewChargeRewardLayer:ctor()
    self.container = nil
end

function Activity_NewChargeRewardLayer:create( container )
    local s = Activity_NewChargeRewardLayer.new()
    self.container = container
    s:initLayer()
    return s
end

function Activity_NewChargeRewardLayer:initLayer()
    Activity_NewChargeRewardLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("launch_activity6")
    self:addChild(self.mainUI)
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      
      local activityTimeInfo = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.activityNewYearConfig.featureNameCalcPay)
      local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.activityNewYearConfig.featureNameGainReward)
      local InfoTxt = DataManager.GameMetaData.activityNewYearConfig.payRewards[1].rewardText
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText(InfoTxt, {year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time, year3 = activityGainRewardTimeInfo[2].year, month3 = activityGainRewardTimeInfo[2].month, day3 = activityGainRewardTimeInfo[2].day, time3 = activityGainRewardTimeInfo[2].time}))
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_activity_helpinfo"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    local guide_other = self.mainUI:getChildByName("guide_other")
    guide_other:setVisible(false)
    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103165))
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
    
    local tipLabel1_1 = self.mainUI:getChildByName("txt_chargeto1_s")
    tipLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips1"))
    local tipLabel1_2 = self.mainUI:getChildByName("txt_chargeto2_s")
    tipLabel1_2:getChildByName("txt"):setString(string.format("%d", rechargeRewardConfigs[1].gold))
    local tipLabel1_3 = self.mainUI:getChildByName("txt_chargeto3_s")
    tipLabel1_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips2"))
    local tipLabel1_4 = self.mainUI:getChildByName("txt_chargeto_s")
    tipLabel1_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips3"))
    
    local tipLabel2_1 = self.mainUI:getChildByName("txt_chargeto1_s1")
    tipLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips1"))
    local tipLabel2_2 = self.mainUI:getChildByName("txt_chargeto2_s1")
    tipLabel2_2:getChildByName("txt"):setString(string.format("%d", rechargeRewardConfigs[2].gold))
    local tipLabel2_3 = self.mainUI:getChildByName("txt_chargeto3_s1")
    tipLabel2_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips2"))
    local tipLabel2_4 = self.mainUI:getChildByName("txt_chargeto_s2")
    tipLabel2_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips3"))
    
    local tipLabel3_1 = self.mainUI:getChildByName("txt_chargeto1_s2")
    tipLabel3_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips1"))
    local tipLabel3_2 = self.mainUI:getChildByName("txt_chargeto2_s2")
    --
    local tipLabel3_3 = self.mainUI:getChildByName("txt_chargeto3_s2")
    tipLabel3_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips2"))
    local tipLabel3_4 = self.mainUI:getChildByName("txt_chargeto_s3")
    tipLabel3_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_chargeReward_rewardTips3"))
    
    local gameInitData = DataManager.getGameInitData()
    
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
        --
        table.insert(gameInitData.sharkActivity.chargeInfo.gainedRewardIds, aRewardId)
        DataManager.setGameInitData(gameInitData)
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_NewChargeReward")
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
    
    
    
    local firstButtonDisplay = self.mainUI:getChildByName("btn_c1get")
    local function firstButtonSelected(evt)
      gainReward(rechargeRewardConfigs[1].id)
    end
    local firstButton = Button:create(firstButtonDisplay)
    firstButton:addEventListener(Events.kStart,firstButtonSelected, self)
    local secondButtonDisplay = self.mainUI:getChildByName("btn_c2get")
    local function secondButtonSelected(evt)
      gainReward(rechargeRewardConfigs[2].id)
    end
    local secondButton = Button:create(secondButtonDisplay)
    secondButton:addEventListener(Events.kStart,secondButtonSelected, self)
    local thirdButtonDisplay = self.mainUI:getChildByName("btn_c3get")
    local function thirdButtonSelected(evt)
      local aRewardId
      local gameInitData = DataManager.getGameInitData()
      local gainedRewardList = gameInitData.sharkActivity.chargeInfo.gainedRewardIds
      if not existInGainedRewardList(rechargeRewardConfigs[3].id, gainedRewardList) then
        aRewardId = rechargeRewardConfigs[3].id
      elseif not existInGainedRewardList(rechargeRewardConfigs[4].id, gainedRewardList) then
        aRewardId = rechargeRewardConfigs[4].id
      else
        aRewardId = rechargeRewardConfigs[5].id
      end
      gainReward(aRewardId)
    end
    local thirdButton = Button:create(thirdButtonDisplay)
    thirdButton:addEventListener(Events.kStart,thirdButtonSelected, self)
    
    local buttonList = {}
    table.insert(buttonList, firstButton)
    table.insert(buttonList, secondButton)
    table.insert(buttonList, thirdButton)
    
    local buttonDisplayList = {}
    table.insert(buttonDisplayList, firstButtonDisplay)
    table.insert(buttonDisplayList, secondButtonDisplay)
    table.insert(buttonDisplayList, thirdButtonDisplay)
    
    
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(DataManager.GameMetaData.activityNewYearConfig.featureNameCalcPay)
      local whetherPassedGainRewardTime, leftGainRewardTimeStamp, gainEndMonth, gainEndDay, gainEndHour, gainEndYear = MaintenanceManager.isActivityAlreadyClose(DataManager.GameMetaData.activityNewYearConfig.featureNameGainReward)
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
        local gainedRewardList = gameInitData.sharkActivity.chargeInfo.gainedRewardIds
        for i = 1, 3 do
          local rewardGained
          local aRewardConfig
          if i == 3 then
            if not existInGainedRewardList(rechargeRewardConfigs[3].id, gainedRewardList) then
              rewardGained = false
              aRewardConfig = rechargeRewardConfigs[3]
            elseif not existInGainedRewardList(rechargeRewardConfigs[4].id, gainedRewardList) then
              rewardGained = false
              aRewardConfig = rechargeRewardConfigs[4]
            elseif not existInGainedRewardList(rechargeRewardConfigs[5].id, gainedRewardList) then
              rewardGained = false
              aRewardConfig = rechargeRewardConfigs[5]
            else
              rewardGained = true
              aRewardConfig = rechargeRewardConfigs[5]
            end
            tipLabel3_2:getChildByName("txt"):setString(string.format("%d", aRewardConfig.gold))
          else
            rewardGained = existInGainedRewardList(rechargeRewardConfigs[i].id, gainedRewardList)
            aRewardConfig = rechargeRewardConfigs[i]
          end
          if rewardGained then
            buttonList[i]:setEnable(false)
            buttonDisplayList[i]:getChildByName("normal"):setVisible(false)
            buttonDisplayList[i]:getChildByName("disabled"):setVisible(true)
            buttonDisplayList[i]:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
          elseif gameInitData.sharkActivity.chargeInfo.gems < aRewardConfig.gold then
            buttonList[i]:setEnable(false)
            buttonDisplayList[i]:getChildByName("normal"):setVisible(false)
            buttonDisplayList[i]:getChildByName("disabled"):setVisible(true)
            buttonDisplayList[i]:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
          else
            buttonList[i]:setEnable(true)
            buttonDisplayList[i]:getChildByName("normal"):setVisible(true)
            buttonDisplayList[i]:getChildByName("disabled"):setVisible(false)
            buttonDisplayList[i]:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
          end
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
    local reward2BtnDisplay = self.mainUI:getChildByName("icon_prop_3")
    local reward2Btn = Button:create(reward2BtnDisplay)
    reward2Btn:addEventListener(Events.kStart, reward2BtnSelected, self)
    
    local function reward3BtnSelected(evt)
      showRewardPanel(MetaManager.getRewardInfoByID(rechargeRewardConfigs[3].rewardPackId) or {})
    end
    local reward3BtnDisplay = self.mainUI:getChildByName("icon_prop_2")
    local reward3Btn = Button:create(reward3BtnDisplay)
    reward3Btn:addEventListener(Events.kStart, reward3BtnSelected, self)
    
    self.refreshUIListener = function(ee)
      refreshSelf()
      self.container:resetTipInfoForActivity("Activity_NewChargeReward")
    end
    NotificationManager:addEventListener("refreshForRechargeGemDataChanged",self.refreshUIListener)
end

function Activity_NewChargeRewardLayer:enable()
    if not DataManager.GameMetaData.activityNewYearConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityNewYearConfig.featureNamePanel)
    if isEnable then
      local sharkActivity = DataManager.getSharkActivity()
      sharkActivity.chargeInfo = sharkActivity.chargeInfo or {}
      if (not sharkActivity.chargeInfo.currVersion) or (sharkActivity.chargeInfo.currVersion ~= DataManager.GameMetaData.activityNewYearConfig.version) then
        sharkActivity.chargeInfo.currVersion = DataManager.GameMetaData.activityNewYearConfig.version
        sharkActivity.chargeInfo.gems = 0
        sharkActivity.chargeInfo.gainedRewardIds = {}
      end
      DataManager.setSharkActivity(sharkActivity)
    end
    return isEnable
end 

function Activity_NewChargeRewardLayer:dispose()
  NotificationManager:removeEventListener("refreshForRechargeGemDataChanged",self.refreshUIListener)
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_NewChargeRewardLayer.super.dispose(self)
end

function Activity_NewChargeRewardLayer.getTipNum()
  if not Activity_NewChargeRewardLayer.enable() then
    return 0
  end
  
  local result = 0
  local gameInitData = DataManager.getGameInitData()
  local gainedRewardList = gameInitData.sharkActivity.chargeInfo.gainedRewardIds
  local rechargeRewardConfigs = DataManager.GameMetaData.activityNewYearConfig.payRewards
  for i = 1, #rechargeRewardConfigs do
    if not existInGainedRewardList(rechargeRewardConfigs[i].id, gainedRewardList) then
      if gameInitData.sharkActivity.chargeInfo.gems >= rechargeRewardConfigs[i].gold then
        result = result + 1
      end
    end
  end
  return result
end