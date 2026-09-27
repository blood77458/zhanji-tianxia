require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainGoldGodRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_WealthGodLayer
--

Activity_WealthGodLayer = class(Layer)
function Activity_WealthGodLayer:ctor()
    self.container = nil
end

function Activity_WealthGodLayer:create( container, extraArgs )
    local s = Activity_WealthGodLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_WealthGodLayer:initLayer()
    Activity_WealthGodLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/wealth_fucker.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("wealth_fucker")
    self:addChild(self.mainUI)
    
    local guide_other = self.mainUI:getChildByName("guide")
    guide_other:setVisible(false)
    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103004))
    card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0))
    self.mainUI:addChildAt(card3_spf, 3)
    
    local activityGoldGodConfig = DataManager.GameMetaData.activityGoldGodConfig
    
    self.mainUI:getChildByName("wealth_fucker_txt"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_dec1"))
    local mostGoldLabel = self.mainUI:getChildByName("wealth_fucker_txt2")
    
    self.mainUI:getChildByName("wealth_fucker_txt3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_dec2"))
    self.mainUI:getChildByName("wealth_fucker_txt4"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_end_time1"))
    local leftDayLabel = self.mainUI:getChildByName("wealth_fucker_txt5")
    
    self.mainUI:getChildByName("wealth_fucker_txt6"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_end_time2"))
    local leftHourLabel = self.mainUI:getChildByName("wealth_fucker_txt7")
    
    self.mainUI:getChildByName("wealth_fucker_txt8"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_end_time3"))
    local leftMinuteLabel = self.mainUI:getChildByName("wealth_fucker_txt9")
    
    self.mainUI:getChildByName("wealth_fucker_txt10"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_end_time4"))
    
    self.mainUI:getChildByName("wealth_fucker_txt11"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_need_gem"))
    local needGoldLabel = self.mainUI:getChildByName("wealth_fucker_txt12")
    
    
    self.mainUI:getChildByName("wealth_fucker_txt13"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_times1"))
    local leftNumberLabel = self.mainUI:getChildByName("wealth_fucker_txt14")
    
    self.mainUI:getChildByName("wealth_fucker_txt15"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_times2"))
    
    self.mainUI:getChildByName("wealth_fucker_txt16"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_goldGod_own_gem"))
    local ownGemLabel = self.mainUI:getChildByName("wealth_fucker_txt22")
    
    local goldGodBroadCastList = EventManager:sharedManager():getGoldGodActivityBroadcast()
    local _json = require("cjson")
    for aIndex, aBroadcast in ipairs(goldGodBroadCastList) do
      local goldReward = _json.decode(aBroadcast.content).goldReward
      local goldGodNum = _json.decode(aBroadcast.content).goldGodNum
      local aRewardItemConfig
      local aDefaultNum = 500
      for _, v in pairs(activityGoldGodConfig.goldGodRewardItems) do
        if v.id == goldGodNum then
          aRewardItemConfig = v
          break
        end
      end
      if aRewardItemConfig then
        aDefaultNum = aRewardItemConfig.gemNeed
      end
      local aLabel = TextField:create(Localization:getInstance():getText("activity_goldGod_broadcast_content", {name = aBroadcast.userName, num = goldReward + aDefaultNum}), "Helvetica", 28, CCSizeMake(0,0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setAnchorPoint(ccp(0, 0.5))
      aLabel:setPosition(ccp(160, 216 - (aIndex - 1) * 35))
      aLabel:setColor(ccc3(255,255,160))
      self.mainUI:addChild(aLabel)
    end
    
    
    local refreshSelf
    local currentNeedGem
    
    local start_duration = 0.05
    local delay_coefficient = 1.02
    local start_round_num = 2
    local stencil_scale_x = 5.1
    local stencil_scale_y = 2.0
    local stencil = CCSprite:create("pic/5.png")
    local original_w = stencil:getContentSize().width
    local original_h = stencil:getContentSize().height
    local numberClipLayer = CCClippingNode:create()
    local numberClipLayer_co = CocosObject.new(numberClipLayer)
    numberClipLayer:setContentSize(CCSizeMake(original_w * stencil_scale_x, original_h * stencil_scale_y))
    numberClipLayer:setAnchorPoint(ccp(0, 0))
    numberClipLayer:setPosition(ccp(127, 532))
    self.mainUI:addChildAt(numberClipLayer_co, 6)
    
    stencil:setScaleX(stencil_scale_x)
    stencil:setScaleY(stencil_scale_y)
    stencil:setAnchorPoint(ccp(0, 0))
    stencil:setPosition(ccp(0, 0))
    numberClipLayer:setStencil(stencil)
    local clipList = {}
    for i = 1, 5 do
      local subClipList = {}
      for j = 0, 10 do
        local aValue = math.mod(j, 10)
        local aNumSprite = CCSprite:create(string.format("pic/NO%d.png", aValue))
        aNumSprite:setAnchorPoint(ccp(0.5, 0.5))
        aNumSprite:setPositionX(original_w * stencil_scale_x / 5 * (i - 0.5))
        aNumSprite:setPositionY(original_h * stencil_scale_y * (j + 0.5))
        numberClipLayer:addChild(aNumSprite)
        aNumSprite.original_x = aNumSprite:getPositionX()
        aNumSprite.original_y = aNumSprite:getPositionY()
        table.insert(subClipList, aNumSprite)
      end
      table.insert(clipList, subClipList)
    end
    
    
    local function doGoldGodAction(gemRewards)
      self.mainUI:getChildByName("wealth_fucker_upbg"):setVisible(false)
      self.mainUI:getChildByName("gold_coin"):setVisible(false)
      self.mainUI:getChildByName("wealth_fucker_txt11"):setVisible(false)
      self.mainUI:getChildByName("wealth_fucker_txt12"):setVisible(false)
      local tempLayer = Layer:create()
      tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
      self.container:addChild(tempLayer)
      self.container.targetInfoPanel = tempLayer
      self.container:setTableViewsEnabled(false)
      
      local aGemNum = gemRewards[1].amount
      local numList = {}
      local totalNum = 0
      local aNum1 = math.modf(aGemNum / 10000) + (start_round_num + 4) * 10
      totalNum = totalNum + aNum1
      table.insert(numList, aNum1)
      local aNum1_1 = math.mod(aGemNum, 10000)
      local aNum2 = math.modf(aNum1_1 / 1000) + (start_round_num + 3) * 10
      totalNum = totalNum + aNum2
      table.insert(numList, aNum2)
      local aNum2_1 = math.mod(aNum1_1, 1000)
      local aNum3 = math.modf(aNum2_1 / 100) + (start_round_num + 2) * 10
      totalNum = totalNum + aNum3
      table.insert(numList, aNum3)
      local aNum3_1 = math.mod(aNum2_1, 100)
      local aNum4 = math.modf(aNum3_1 / 10) + (start_round_num + 1) * 10
      totalNum = totalNum + aNum4
      table.insert(numList, aNum4)
      local aNum5 = math.mod(aNum3_1, 10) + start_round_num * 10
      totalNum = totalNum + aNum5
      table.insert(numList, aNum5)
      
      local function goldGodActionFinished()
        self.mainUI:getChildByName("wealth_fucker_upbg"):setVisible(true)
        self.mainUI:getChildByName("gold_coin"):setVisible(true)
        self.mainUI:getChildByName("wealth_fucker_txt11"):setVisible(true)
        self.mainUI:getChildByName("wealth_fucker_txt12"):setVisible(true)
        for _, subClipList in ipairs(clipList) do
          for _, aNumSprite in ipairs(subClipList) do
            aNumSprite:setPositionX(aNumSprite.original_x)
            aNumSprite:setPositionY(aNumSprite.original_y)
          end
        end
        tempLayer:removeFromParentAndCleanup(true)
        self.container.targetInfoPanel = nil
        self.container:setTableViewsEnabled(true)
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, gemRewards )
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
        RewardManager:getReward(gemRewards)
        local sharkActivity = DataManager.getSharkActivity()
        sharkActivity.goldGodNum = sharkActivity.goldGodNum + 1
        DataManager.setSharkActivity(sharkActivity)
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_goldGod")
      end
      
      for i = 1, 5 do
        local function startScroll()
          local start_delay_duration = start_duration
          local subClipList = clipList[i]
          local moveTime = numList[i]
          local currentTime = 0
          local doOneMoveAction
          local function oneMoveFinished()
            currentTime = currentTime + 1
            totalNum = totalNum - 1
            if math.mod(currentTime, 10) == 0 then
              for _, aNumSprite in ipairs(subClipList) do
                aNumSprite:setPositionY(aNumSprite:getPositionY() + 10 * original_h * stencil_scale_y)
              end
            end
            if currentTime < moveTime then
              doOneMoveAction()
            end
            if totalNum <= 0 then
              local fspt = FlashSprite:create("EVO2/coindown")
              fspt:changeAnimation(0)
              fspt:setLoop(false)
              local fspt_co = CocosObject.new(fspt)
              self.container:addChild(fspt_co)
              local arr = CCArray:create()
              arr:addObject(CCDelayTime:create(1.0))
              arr:addObject(CCCallFunc:create(goldGodActionFinished))
              self:runAction(CCSequence:create(arr))
            end
          end
          doOneMoveAction = function()
            start_delay_duration = start_delay_duration * delay_coefficient
            for j = 1, 11 do
              local aNumSprite = subClipList[j]
              local arr = CCArray:create()
              arr:addObject(CCMoveBy:create(start_delay_duration, ccp(0, -original_h * stencil_scale_y)))
              if j == 1 then
                arr:addObject(CCCallFunc:create(oneMoveFinished))
              end
              aNumSprite:runAction(CCSequence:create(arr))
            end
          end
          doOneMoveAction()
        end
        
        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(0.2 * (5 - i)))
        arr:addObject(CCCallFunc:create(startScroll))
        self:runAction(CCSequence:create(arr))
      end
    end
    
    local function getButtonSelected(evt)
      local sharkActivity = DataManager.getSharkActivity()
      local goldNum = sharkActivity.goldGodNum or 0
      if activityGoldGodConfig.goldGodRewardItems[goldNum + 1] and DataManager.getGameInitData().sharkUser.vipLevel < activityGoldGodConfig.goldGodRewardItems[goldNum + 1].vip then
        CanonMessageBox.showText(
            ShowButtonType.ID_OK_CANCEL,
            getTextByKey("activity_goldGod_tips" , {num = activityGoldGodConfig.goldGodRewardItems[goldNum + 1].vip}),
            {
                text = getTextByKey("yes"),
                callbackFunc = function()
                    Director:sharedDirector():replaceScene(ShopScene:create({params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}}))
                end
            }
        )
        return
      end

      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(activityGoldGodConfig.featureName)
      if whetherPassedActivityTime then
        local aContent = Localization:getInstance():getText("activity_goldGod_end_remind")
        SuspensionLabel:showContent(self.container, aContent)
        return
      elseif (activityGoldGodConfig.goldGodMaxTimes <= DataManager.getSharkActivity().goldGodNum) then
        local aContent = Localization:getInstance():getText("activity_goldGod_finishall_remind")
        SuspensionLabel:showContent(self.container, aContent)
        return
      elseif currentNeedGem > CalculationManager.calcComplex_getGemsNow() then
        local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          self.container.targetInfoPanel = nil
        end
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
      end
      
      local function gainGoldGodRewardsSucceed(event)
        RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -currentNeedGem}})
        event.data.rewards[1].amount = event.data.rewards[1].amount + currentNeedGem
        doGoldGodAction(event.data.rewards)
      end 
      local function GainGoldGodRewardsFailed(event)
        if event.data.retCode == 714480 then  --activity closed
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_error_expired")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714481 then  --num over max
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_goldGod_times_max_remind")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {}
      local request = GainGoldGodRewardsRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainGoldGodRewardsSucceed, gainGoldGodRewardsSucceed)
      request:addEventListener(RequestNotifyEnum.GainGoldGodRewardsFailed, gainGoldGodRewardsFailed)
      request:start()
    end
    local getButton = Button:create(self.mainUI:getChildByName("btn_fuck_wealth"))
    getButton:addEventListener(Events.kStart, getButtonSelected, self)
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(activityGoldGodConfig.featureName)
      if whetherPassedActivityTime then
        leftActivityTimeStamp = 0
      end
      local sharkActivity = DataManager.getSharkActivity()
      
      local aRewardItemConfig
      local aTempNum
      if activityGoldGodConfig.goldGodMaxTimes <= sharkActivity.goldGodNum then
        aTempNum = activityGoldGodConfig.goldGodMaxTimes
      else
        aTempNum = sharkActivity.goldGodNum + 1
      end
      for _, v in pairs(activityGoldGodConfig.goldGodRewardItems) do
        if v.id == aTempNum then
          aRewardItemConfig = v
          break
        end
      end
      currentNeedGem = aRewardItemConfig.gemNeed
      
      mostGoldLabel:getChildByName("txt"):setString(string.format("%d", aRewardItemConfig.gemMax))
      leftDayLabel:getChildByName("txt"):setString(string.format("%d", math.modf(leftActivityTimeStamp / (3600 * 24))))
      leftHourLabel:getChildByName("txt"):setString(string.format("%d", math.modf(math.mod(leftActivityTimeStamp, (3600 * 24)) / 3600)))
      leftMinuteLabel:getChildByName("txt"):setString(string.format("%d", math.modf(math.mod(math.mod(leftActivityTimeStamp, (3600 * 24)), 3600) / 60)))
      needGoldLabel:getChildByName("txt"):setString(string.format("%d", aRewardItemConfig.gemNeed))
      leftNumberLabel:getChildByName("txt"):setString(string.format("%d", activityGoldGodConfig.goldGodMaxTimes - sharkActivity.goldGodNum))
      ownGemLabel:getChildByName("txt"):setString(string.format("%d", CalculationManager.calcComplex_getGemsNow()))

      if self.numberLabel then
        self.numberLabel:removeFromParentAndCleanup(true)
        self.numberLabel = nil
      end

      if activityGoldGodConfig.goldGodRewardItems[sharkActivity.goldGodNum + 1] then
        local neededVip = activityGoldGodConfig.goldGodRewardItems[sharkActivity.goldGodNum + 1].vip
        self.numberLabel = CCLabelAtlas:create(tostring(neededVip), "pic/number_vip.png", 22, 41, 48)
        self.numberLabel:setScale(1.25)
        self.numberLabel:setAnchorPoint(ccp(0, 0.5))
        local vipPosX = self.mainUI:getChildByName("shop_icon_common_vip_ing"):getPositionX()
        local vipPosY = self.mainUI:getChildByName("shop_icon_common_vip_ing"):getPositionY()
        local vipContentSize = self.mainUI:getChildByName("shop_icon_common_vip_ing"):getContentSize()
        self.numberLabel:setPosition(ccp(vipPosX + vipContentSize.width + 6, vipPosY - vipContentSize.height /2))
        local numberLabel_co = CocosObject.new(self.numberLabel)
        self.mainUI:addChild(numberLabel_co , 1000)
      else
        self.mainUI:getChildByName("shop_icon_common_vip_ing"):setVisible(false)
      end


    end
    
    refreshSelf()
    
    self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,60,false)
    
    self.gemChangeListener = function(ee)
      self.container:resetTipInfoForActivity("Activity_goldGod")
      ownGemLabel:getChildByName("txt"):setString(string.format("%d", CalculationManager.calcComplex_getGemsNow()))
    end
    NotificationManager:addEventListener(DataChangedNotifyEnum.GemDataChanged,self.gemChangeListener)
end

function Activity_WealthGodLayer:dispose()
  NotificationManager:removeEventListener(DataChangedNotifyEnum.GemDataChanged, self.gemChangeListener)
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_WealthGodLayer.super.dispose(self)
end

function Activity_WealthGodLayer:enable()
  local activityGoldGodConfig = DataManager.GameMetaData.activityGoldGodConfig
    if not activityGoldGodConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(activityGoldGodConfig.featureName)
    if isEnable then
      local sharkActivity = DataManager.getSharkActivity()
      if (not sharkActivity.ggVersion) or (sharkActivity.ggVersion ~= activityGoldGodConfig.version) then
        sharkActivity.ggVersion = activityGoldGodConfig.version
        sharkActivity.goldGodNum = 0
      end
      DataManager.setSharkActivity(sharkActivity)
      if activityGoldGodConfig.goldGodMaxTimes <= sharkActivity.goldGodNum then
        isEnable = false
      end
    end
    return isEnable
end

function Activity_WealthGodLayer.shouldShowParticle()
  local activityGoldGodConfig = DataManager.GameMetaData.activityGoldGodConfig
  local sharkActivity = DataManager.getSharkActivity()
  local aRewardItemConfig
  for _, v in pairs(activityGoldGodConfig.goldGodRewardItems) do
    if v.id == (sharkActivity.goldGodNum + 1) then
      aRewardItemConfig = v
      break
    end
  end
  
  if not aRewardItemConfig then
	return false
  end
  
  if CalculationManager.calcComplex_getGemsNow() >= aRewardItemConfig.gemNeed then
    return true
  else
    return false
  end
end

function Activity_WealthGodLayer.getTipNum()
  if not Activity_WealthGodLayer.enable() then
    return 0
  end
  
  local aTipNum = 0
  local aParticleStatus = true
  local activityGoldGodConfig = DataManager.GameMetaData.activityGoldGodConfig
  local sharkActivity = DataManager.getSharkActivity()
  local ownGemNum = CalculationManager.calcComplex_getGemsNow()
  while true do
    if activityGoldGodConfig.goldGodMaxTimes <= sharkActivity.goldGodNum + aTipNum then
      break
    end
    local aRewardItemConfig
    local nextId = sharkActivity.goldGodNum + aTipNum + 1   --modified by jet
    for _, v in pairs(activityGoldGodConfig.goldGodRewardItems) do
      --local nextId = sharkActivity.goldGodNum + aTipNum + 1
      if v.id == nextId then
        aRewardItemConfig = v
        break
      end
    end
    if not aRewardItemConfig then
      break
    end
    if aRewardItemConfig.gemNeed > ownGemNum then
      break
    end
    ownGemNum = ownGemNum - aRewardItemConfig.gemNeed
    aTipNum = aTipNum + 1
  end
  return aTipNum, aParticleStatus
end