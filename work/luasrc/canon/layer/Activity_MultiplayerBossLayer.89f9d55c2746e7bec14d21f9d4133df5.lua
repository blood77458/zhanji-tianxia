require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.scene.MultiplayerBossScene"
require "canon.request.GainMultiplayerBossRankRewardRequest"
require "canon.panel.ActivityMultiplayerBossInfoPanel"
require "canon.manager.CrossWorldBossManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_MultiplayerBossLayer
--

Activity_MultiplayerBossLayer = class(Layer)
function Activity_MultiplayerBossLayer:ctor()
    self.container = nil
    self.extraArgs = nil
end

function Activity_MultiplayerBossLayer:create( container, extraArgs )
    local s = Activity_MultiplayerBossLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_MultiplayerBossLayer:initLayer()
    Activity_MultiplayerBossLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("monster_nian_info")
    self:addChild(self.mainUI)
    self.mainUI:getChildByName("lbl_monster_nian"):setVisible(false)
    self.mainUI:getChildByName("lbl_lv"):setVisible(false)
    -- local aCardSprite = Sprite:create("pic/worldboss02.png")
    -- aCardSprite:setPosition(ccp(359, 539.9))
    -- aCardSprite:setScale(1.17)
    -- self.mainUI:addChildAt(aCardSprite, 2)

    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103211))
    card3_spf:setPosition(ccp(359, 539.9))
    self.mainUI:addChildAt(card3_spf, 2)
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      local activityTimeInfo = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.activityMultiplayerBossConfig.rankingFeatureName)
      local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.activityMultiplayerBossConfig.rewardFeatureName)
      local content1 = Localization:getInstance():getText("activityNian_popup_infoTxt1", {year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time, year3 = activityGainRewardTimeInfo[2].year, month3 = activityGainRewardTimeInfo[2].month, day3 = activityGainRewardTimeInfo[2].day, time3 = activityGainRewardTimeInfo[2].time})
      local content2 = Localization:getInstance():getText("activityNian_popup_infoTxt2")
      --{103211, 103181, 101261} 2014-6-9 11:06:30 替换
      local bossIds = string.split(DataManager.GameMetaData.activityMultiplayerBossConfig.helpCardId , "|")
      local aInfoPanel = ActivityMultiplayerBossInfoPanel:create(self.container, {content1 = content1, content2 = content2, cardIdList = {tonumber(bossIds[1]), tonumber(bossIds[2])}})
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_nian_30"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    local leftTimeLabel1 = self.mainUI:getChildByName("txt_nian_3")
    leftTimeLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_timeRemain"))
    local leftTimeLabel2 = self.mainUI:getChildByName("txt_nian_4")
    local leftTimeLabel3 = self.mainUI:getChildByName("txt_nian_29")
    leftTimeLabel3:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_timeOver"))
    
    self.mainUI:getChildByName("txt_nian_1"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_myNianHorn", {num = self.extraArgs.point}))
    self.mainUI:getChildByName("txt_nian_2"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_myRank", {rank = ((self.extraArgs.rank == 0) and Localization:getInstance():getText("activityNian_outOfRank") or self.extraArgs.rank)}))
    
    local beastTipLabel = self.mainUI:getChildByName("txt_nian_st")
    beastTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianAppeared"))
    local rewardTipLabel = self.mainUI:getChildByName("txt_nian_st2")
    rewardTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_haveReward"))
    
    local refreshSelf
    
    local function enterMBScene(tagType)
      local function successCallback(data)
        local argv = {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",params={selectedTag = tagType, data = data}}
        self.container:replaceScene(MultiplayerBossScene, argv)
      end
      
      local function failureCallback(data)
        if data.retCode == 714520 then
          local function closeCanonMessageBox()
            self.container:replaceScene(MainMenuScene)
          end
          local text = Localization:getInstance():getText("activityNian_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      
      MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
    end
    
    local leftButtonDisplay = self.mainUI:getChildByName("btn_watch_nian")
    
    local function viewBeasts()
      enterMBScene(MultiplayerBossTagEnum.BossList)
    end
    local function getLeaderboardRewards()
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("bagFull_move")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function gainMultiplayerBossRankRewardSucceed(event)
        RewardManager:getReward(event.data.rewards)
        local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activityNian_popup_rankRewardTitle"), rewardSubTitle = Localization:getInstance():getText("activityNian_popup_rankRewardTxt", {rank = ((self.extraArgs.rank == 0) and Localization:getInstance():getText("activityNian_outOfRank") or self.extraArgs.rank)})} )
        self.container:addChild(aRewardPanel)
        aRewardPanel:scaleIn()
        self.extraArgs.gainedRankReward = true
        refreshSelf()
        local homeInfo = ActivityPanelScene.getStatusInfo()
        if homeInfo.ungainedRewardNum and (homeInfo.ungainedRewardNum > 0) then
          homeInfo.ungainedRewardNum = homeInfo.ungainedRewardNum - 1
          self.container:resetTipInfoForActivity("Activity_MultiplayerBoss")
        end
      end 
      local function gainMultiplayerBossRankRewardFailed(event)
        if event.data.retCode == 714522 then  --not in rank reward time
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activityNian_rewardNotInTime")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
          self.extraArgs.gainedRankReward = true
          refreshSelf()
          local homeInfo = ActivityPanelScene.getStatusInfo()
          if homeInfo.ungainedRewardNum and (homeInfo.ungainedRewardNum > 0) then
            homeInfo.ungainedRewardNum = homeInfo.ungainedRewardNum - 1
            self.container:resetTipInfoForActivity("Activity_MultiplayerBoss")
          end
        elseif event.data.retCode == 714523 then  --not in rank
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activityNian_rewardOutOfRank")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
          self.extraArgs.gainedRankReward = true
          refreshSelf()
          local homeInfo = ActivityPanelScene.getStatusInfo()
          if homeInfo.ungainedRewardNum and (homeInfo.ungainedRewardNum > 0) then
            homeInfo.ungainedRewardNum = homeInfo.ungainedRewardNum - 1
            self.container:resetTipInfoForActivity("Activity_MultiplayerBoss")
          end
        elseif event.data.retCode == 714528 then  --gained already
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activityNian_rewardAlreadyClaimed")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
          self.extraArgs.gainedRankReward = true
          refreshSelf()
          local homeInfo = ActivityPanelScene.getStatusInfo()
          if homeInfo.ungainedRewardNum and (homeInfo.ungainedRewardNum > 0) then
            homeInfo.ungainedRewardNum = homeInfo.ungainedRewardNum - 1
            self.container:resetTipInfoForActivity("Activity_MultiplayerBoss")
          end
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {}
      local request = GainMultiplayerBossRankRewardRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener( RequestNotifyEnum.GainMultiplayerBossRankRewardSucceed, gainMultiplayerBossRankRewardSucceed )
      request:addEventListener( RequestNotifyEnum.GainMultiplayerBossRankRewardFailed, gainMultiplayerBossRankRewardFailed )
      request:start()
    end
    local leftButton = Button:create(leftButtonDisplay)
    
    local rightButtonDisplay = self.mainUI:getChildByName("btn_get_reward")
    rightButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardListBtn"))
    local function rightButtonSelected()
      enterMBScene(MultiplayerBossTagEnum.ChallengeRecord)
    end
    local rightButton = Button:create(rightButtonDisplay)
    rightButton:addEventListener(Events.kStart, rightButtonSelected, self)
    
    local hasBeast = self.extraArgs.activeBossInfo and (#self.extraArgs.activeBossInfo > 0)
    local hasReward = false
    if self.extraArgs.bossChallengeRecord then
      for _, aRecord in ipairs(self.extraArgs.bossChallengeRecord) do
        if not aRecord.gainReward and (aRecord.leftHp <= 0) then
          hasReward = true
          break
        end
      end
    end
    
    local leftLightActionOn = false
    local rightLightActionOn = false
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(DataManager.GameMetaData.activityMultiplayerBossConfig.rankingFeatureName)
      if whetherPassedActivityTime then
        leftTimeLabel1:setVisible(false)
        leftTimeLabel2:setVisible(false)
        leftTimeLabel3:setVisible(true)
        
        beastTipLabel:setVisible(false)
        leftButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rankRewardBtn"))
        if self.extraArgs.gainedRankReward or (self.extraArgs.rank == 0) then
          leftLightActionOn = false
          leftButtonDisplay:getChildByName("btn_light"):stopAllActions()
          leftButtonDisplay:getChildByName("btn"):setVisible(false)
          leftButtonDisplay:getChildByName("btn_light"):setVisible(false)
          leftButtonDisplay:getChildByName("btn_inactive"):setVisible(true)
          leftButton:removeEventListener(Events.kStart, viewBeasts)
          leftButton:removeEventListener(Events.kStart, getLeaderboardRewards)
          leftButton:setEnable(false)
        else
          if not leftLightActionOn then
            leftLightActionOn = true
            local actionArray = CCArray:create()
            actionArray:addObject(CCFadeOut:create(0.5))
            actionArray:addObject(CCFadeIn:create(0.5))
            leftButtonDisplay:getChildByName("btn_light"):runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
          end
          leftButtonDisplay:getChildByName("btn"):setVisible(true)
          leftButtonDisplay:getChildByName("btn_light"):setVisible(true)
          leftButtonDisplay:getChildByName("btn_inactive"):setVisible(false)
          leftButton:removeEventListener(Events.kStart, viewBeasts)
          leftButton:addEventListener(Events.kStart, getLeaderboardRewards, self)
          leftButton:setEnable(true)
        end
        if self.checkActivityPassedEntry then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
          self.checkActivityPassedEntry = nil
        end
      else
        leftTimeLabel1:setVisible(true)
        leftTimeLabel2:setVisible(true)
        leftTimeLabel3:setVisible(false)
        local leftDay = math.modf(leftActivityTimeStamp / (3600 * 24))
        local leftTimeStamp = math.mod(leftActivityTimeStamp, (3600 * 24))
        local leftHour = math.modf(leftTimeStamp / 3600)
        leftTimeStamp = math.mod(leftTimeStamp, 3600)
        local leftMin = math.modf(leftTimeStamp / 60)
        local leftSec = math.mod(leftTimeStamp, 60)
        leftTimeLabel2:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_time", {day = leftDay, hour = leftHour, min = leftMin, sec = leftSec}))
        
        leftButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianListBtn"))
        leftButtonDisplay:getChildByName("btn"):setVisible(true)
        leftButtonDisplay:getChildByName("btn_inactive"):setVisible(false)
        if hasBeast then
          beastTipLabel:setVisible(true)
          leftButtonDisplay:getChildByName("btn_light"):setVisible(true)
          if not leftLightActionOn then
            leftLightActionOn = true
            local actionArray = CCArray:create()
            actionArray:addObject(CCFadeOut:create(0.5))
            actionArray:addObject(CCFadeIn:create(0.5))
            leftButtonDisplay:getChildByName("btn_light"):runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
          end
        else
          beastTipLabel:setVisible(false)
          leftLightActionOn = false
          leftButtonDisplay:getChildByName("btn_light"):setVisible(false)
          leftButtonDisplay:getChildByName("btn_light"):stopAllActions()
        end
        leftButton:removeEventListener(Events.kStart, getLeaderboardRewards)
        leftButton:addEventListener(Events.kStart, viewBeasts, self)
        leftButton:setEnable(true)
        
        if not self.checkActivityPassedEntry then
          self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,1,false)
        end
      end
      
      if hasReward then
        rewardTipLabel:setVisible(true)
        rightButtonDisplay:getChildByName("btn_light"):setVisible(true)
        if not rightLightActionOn then
          rightLightActionOn = true
          local actionArray = CCArray:create()
          actionArray:addObject(CCFadeOut:create(0.5))
          actionArray:addObject(CCFadeIn:create(0.5))
          rightButtonDisplay:getChildByName("btn_light"):runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
        end
      else
        rewardTipLabel:setVisible(false)
        rightLightActionOn = false
        rightButtonDisplay:getChildByName("btn_light"):setVisible(false)
        rightButtonDisplay:getChildByName("btn_light"):stopAllActions()
      end
    end
    
    refreshSelf()
end

function Activity_MultiplayerBossLayer:enable()
    if not DataManager.GameMetaData.activityMultiplayerBossConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityMultiplayerBossConfig.featureName)
    return isEnable
end 

function Activity_MultiplayerBossLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_MultiplayerBossLayer.super.dispose(self)
end

function Activity_MultiplayerBossLayer.getTipNum()
  if not Activity_MultiplayerBossLayer.enable() then
    return 0
  end
  
  local homeInfo = ActivityPanelScene.getStatusInfo()
  return homeInfo.ungainedRewardNum or 0, homeInfo.hasUnDefeatedBoss
end