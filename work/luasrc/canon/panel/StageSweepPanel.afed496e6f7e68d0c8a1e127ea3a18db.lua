require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.ClearMissionRequest"
require "canon.request.ResetClearTimeRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- StageSweepPanel
--

local function existIntInComplexString(aInt, aString, aDelimiter)
  local aTable = aString:split(aDelimiter)
  for _, v in ipairs(aTable) do
    if string.format("%d", aInt) == v then
      return true
    end
  end
  return false
end

StageSweepPanel = class(Layer)

function StageSweepPanel:ctor()
    self.container = nil
    self.args = nil
end

function StageSweepPanel:create( container, args )
    local s = StageSweepPanel.new()
    s:initLayer(container, args)
    return s
end

function StageSweepPanel:initLayer(container, args)
    StageSweepPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_chapterSelect") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("txt_chs"):getChildByName("txt"):setString(Localization:getInstance():getText("stage_times", {challengeNum = string.format("%d/%d", self.args.currentTime, self.args.limitTime)}))
    
    self.panelUI:getChildByName("txt_popup_chapterSelect"):getChildByName("txt"):setString(string.format("%s\n%s\n%s\n%s", Localization:getInstance():getText("stage_stageClearTips1"), Localization:getInstance():getText("stage_stageClearTips2"), Localization:getInstance():getText("stage_stageClearTips3"), Localization:getInstance():getText("stage_stageClearTips4")))
    
    local function onCloseButtonClicked(evt)
      self:dismissSelf()
    end
    local closeButtonDisplay = self.panelUI:getChildByName("btn_close")
    local closeButton = Button:create(closeButtonDisplay)
    closeButton:addEventListener( Events.kStart, onCloseButtonClicked, self )
    
    local function onGoButtonClicked(evt)
      self:dismissSelf()
      self.container:checkStageChallenge(self.args.missionId)
    end
    local goButtonDisplay = self.panelUI:getChildByName("btn_go_stage")
    goButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("stage_stageClearChallengeBtn"))
    local goButton = Button:create(goButtonDisplay)
    goButton:addEventListener( Events.kStart, onGoButtonClicked, self )
    
    self.panelUI:getChildByName("txt_cutstamina"):getChildByName("txt"):setString(Localization:getInstance():getText("stage_stepConsumeTip", {num = DataManager.GameMetaData.battleSettingConfig.missionStepEnergy}))
    
    local roundForEnergy = math.modf((CalculationManager.calcComplex_getEnergyNow() / DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.roundConsumeEnergy))
    local sweepRound = math.min(DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.maxRounds, self.args.limitTime - self.args.currentTime, roundForEnergy)
    
    local levelEnough = DataManager.getCurrUser().level >= (MetaManager.getGameSettingConfig().clearMissionUnlockLevel or 0)
    local sweepTipsLabel = self.panelUI:getChildByName("txt_rushstamina")
    if not levelEnough then
      sweepTipsLabel:getChildByName("txt"):setString(Localization:getInstance():getText("stage_stageClear_level_remind", {num = MetaManager.getGameSettingConfig().clearMissionUnlockLevel}))
    elseif sweepRound > 0 then
      sweepTipsLabel:getChildByName("txt"):setString(Localization:getInstance():getText("stage_stageClearConsumeTip", {num = sweepRound * DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.roundConsumeEnergy}))
    else
      sweepTipsLabel:setVisible(false)
    end
    
    
    
    local freeSkipCooDown = existIntInComplexString(13, MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].unlockContents, ",")
    local chargeSkipCoolDown = existIntInComplexString(12, MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].unlockContents, ",")
    local countryManager = CountryManager:sharedManager()
    
    
    local function getCoolDownTime()
      return (DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.coolDownTime - (TimeUtil.getServerTimeSeconds() - countryManager.countryData.lastClearTime))
    end
    
    
    local function onSweepButtonClicked(evt)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("bagFull_challenge")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
      elseif sweepRound <= 0 then
        if roundForEnergy > 0 then
          self:dismissSelf()
          self.container:challangeLimitForMissionId(self.args.missionId, {sweep = true})
        else
          self:dismissSelf()
          self.container:energyLimitForMissionId(self.args.missionId, {sweep = true})
        end
      elseif (getCoolDownTime() <= 0) or freeSkipCooDown then --扫荡
        self:dismissSelf()
        self.container:sweepStage({missionId = self.args.missionId, routeId = 1, clearRounds = sweepRound})
      else  --重置冷却时间
        self:dismissSelf()
        self.container:showResetSweepTimePanel({missionId = self.args.missionId, routeId = 1, clearRounds = sweepRound})
      end
    end
    
    
    
    
    
    local coolDownLabel = self.panelUI:getChildByName("txt_chapterSelect_time")
    local coolDownLabel2 = coolDownLabel:getChildByName("txt")
    local sweepButtonDisplay = self.panelUI:getChildByName("btn_sweep")
    local sweepButton = Button:create(sweepButtonDisplay)
    local sweepLabel1 = sweepButtonDisplay:getChildByName("txt")
    local sweepLabel2 = sweepButtonDisplay:getChildByName("txt2")
    local sweepLabel3 = sweepButtonDisplay:getChildByName("txt3")
    local sweepGemIcon = sweepButtonDisplay:getChildByName("icon_manycoin")
    
    local function resetForCoolDownTimeChange()
      local coolDownLeftTime = getCoolDownTime()
      if (coolDownLeftTime > 0) and (not freeSkipCooDown) and levelEnough then
        coolDownLabel:setVisible(true)
        coolDownLabel2:setString(Localization:getInstance():getText("stage_cooldown", {time = string.format("%02d:%02d", math.modf(coolDownLeftTime / 60), math.mod(coolDownLeftTime, 60))}))
      else
        coolDownLabel:setVisible(false)
      end
      
      if ((coolDownLeftTime > 0) and (not chargeSkipCoolDown)) or (not levelEnough) then
        sweepButtonDisplay:getChildByName("btn_disadble"):setVisible(true)
        sweepButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
        sweepButton:removeEventListener(Events.kStart, onSweepButtonClicked)
      else
        sweepButtonDisplay:getChildByName("btn_disadble"):setVisible(false)
        sweepButtonDisplay:getChildByName("btn_long_blue"):setVisible(true)
        sweepButton:addEventListener( Events.kStart, onSweepButtonClicked, self )
      end
      
      if sweepRound > 0 then
        if (coolDownLeftTime > 0) and (not freeSkipCooDown) and chargeSkipCoolDown then
          sweepLabel1:setVisible(false)
          sweepLabel2:setVisible(true)
          sweepLabel2:setString(Localization:getInstance():getText("stage_stageClearRoundsBtn", {num = sweepRound}))
          sweepLabel3:setVisible(true)
          local gemNeeded = math.modf(coolDownLeftTime / 300) * DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.resetCoolDownFiveMinsCost
          if math.mod(coolDownLeftTime, 300) > 0.01 then
            gemNeeded = gemNeeded + DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.resetCoolDownFiveMinsCost
          end
          sweepLabel3:setString(string.format("%d", gemNeeded))
          sweepGemIcon:setVisible(true)
        else
          sweepLabel1:setVisible(true)
          sweepLabel1:setString(Localization:getInstance():getText("stage_stageClearRoundsBtn", {num = sweepRound}))
          sweepLabel2:setVisible(false)
          sweepLabel3:setVisible(false)
          sweepGemIcon:setVisible(false)
        end
      else
        sweepLabel1:setString(Localization:getInstance():getText("stage_stageClear"))
        sweepLabel2:setVisible(false)
        sweepLabel3:setVisible(false)
        sweepGemIcon:setVisible(false)
      end
    end
    
    resetForCoolDownTimeChange()
    
    if (getCoolDownTime() > 0) and (not freeSkipCooDown) and levelEnough then
      self.coolDownScript = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(resetForCoolDownTimeChange,1,false)
    end

    self.tempLayer:setScale(0.1)
end

function StageSweepPanel:dispose()
  if self.coolDownScript then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.coolDownScript)
    self.coolDownScript = nil
  end
  StageSweepPanel.super.dispose(self)
end

function StageSweepPanel:scaleIn()
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

function StageSweepPanel:dismissSelf()
  if self.coolDownScript then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.coolDownScript)
    self.coolDownScript = nil
  end
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
end

