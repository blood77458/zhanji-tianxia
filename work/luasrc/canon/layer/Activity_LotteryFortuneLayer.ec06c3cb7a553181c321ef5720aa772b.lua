require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainFortuneRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_LotteryFortuneLayer
--

Activity_LotteryFortuneLayer = class(Layer)
function Activity_LotteryFortuneLayer:ctor()
    self.container = nil
    self.extraArgs = nil
end

function Activity_LotteryFortuneLayer:create( container, extraArgs )
    local s = Activity_LotteryFortuneLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_LotteryFortuneLayer:initLayer()
    Activity_LotteryFortuneLayer.super.initLayer(self)
    
    local original_free = (DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime > DailyDataManager.getDailyDataFortuneNum())
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/daily_lottery.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("daily_lottery")
    self:addChild(self.mainUI)
    
    -- local guide_other = self.mainUI:getChildByName("guide")
    -- guide_other:setVisible(false)
    -- local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(104031))
    -- card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0))
    -- self.mainUI:addChildAt(card3_spf, 3)
    
    local titleLabel_1 = self.mainUI:getChildByName("daily_lottery_info_txt")
    titleLabel_1:getChildByName("txt"):setDimensions(CCSizeMake(0,titleLabel_1:getChildByName("txt"):getDimensions().height))
    titleLabel_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_dec1"))
    local titleLabel_2 = self.mainUI:getChildByName("daily_lottery_info_txt2")
    local aNewPosX = titleLabel_1:getPosition().x + titleLabel_1:getChildByName("txt"):getTexture():getContentSize().width
    titleLabel_2:setPositionX(aNewPosX)
    titleLabel_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_dec2"))
    titleLabel_2:getChildByName("txt"):setAroundColor(ccc3(223,123,12))
    
    local item_group_list = {}
    for i = 1, 8 do
      local aItemGroup = self.mainUI:getChildByName(string.format("daily_lottery_reward_item%d", i))
      table.insert(item_group_list, aItemGroup)
      local aCardDisplay = aItemGroup:getChildByName("normal_card_small")
      local temp_content_size = aCardDisplay:getContentSize()
      aCardDisplay:setVisible(false)
      local package_id
      for _, v in pairs(DataManager.GameMetaData.activityFortuneNowConfig.fortuneRewardItems) do
        if v.id == i then
          package_id = v.rewardPackId
          break
        end
      end
      local aRewardPackageConfig = MetaManager.reward_package[package_id]
      local icon
      local aRewardNameString
      local aBorder
      if aRewardPackageConfig.content1Type == 5 then
        icon = getHeadIconCanonCardByMetaId(aRewardPackageConfig.content1Id)
        icon:setScale(0.9)
        aRewardNameString = Localization:getInstance():getText(MetaManager.card_meta[aRewardPackageConfig.content1Id].name) .. "x" .. aRewardPackageConfig.content1Amount
      elseif (aRewardPackageConfig.content1Type == 6) or (aRewardPackageConfig.content1Type == 7) then
        icon = CanonItem:create()
        icon:loadByMetaId(aRewardPackageConfig.content1Id)
        icon:setScale(0.84)
        if aRewardPackageConfig.content1Type == 6 then
          aRewardNameString = Localization:getInstance():getText(MetaManager.equip_meta[aRewardPackageConfig.content1Id].name) .. "x" .. aRewardPackageConfig.content1Amount
        else
          aRewardNameString = Localization:getInstance():getText(MetaManager.prop_meta[aRewardPackageConfig.content1Id].name) .. "x" .. aRewardPackageConfig.content1Amount
        end
      elseif aRewardPackageConfig.content1Type == 1 then
        icon = Sprite:create("common/CoinIcon_Mission.png")
        icon:setScale(temp_content_size.width / icon:getContentSize().width)
        aBorder = Sprite:create("Item/border/equipBorder1.png")
        aBorder:setScale(temp_content_size.width / icon:getContentSize().width)
        aRewardNameString = Localization:getInstance():getText("resource_silverCoin") .. "x" .. aRewardPackageConfig.content1Amount
      elseif aRewardPackageConfig.content1Type == 2 then
        icon = Sprite:create("common/GemIcon_Mission.png")
        icon:setScale(temp_content_size.width / icon:getContentSize().width)
        aBorder = Sprite:create("Item/border/equipBorder1.png")
        aBorder:setScale(temp_content_size.width / icon:getContentSize().width)
        aRewardNameString = Localization:getInstance():getText("resource_goldCoin") .. "x" .. aRewardPackageConfig.content1Amount
      end
      icon:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
      aItemGroup:addChildAt(icon, 1)
      if aBorder then
        aBorder:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
        aItemGroup:addChildAt(aBorder, 2)
      end
      aItemGroup:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(aRewardNameString)
    end
    
    local select_tag = self.mainUI:getChildByName("activity_item")
    select_tag:setVisible(false)
    local offset_x = select_tag:getPositionX() - item_group_list[1]:getPositionX()
    local offset_y = select_tag:getPositionY() - item_group_list[1]:getPositionY()
    
    local refreshSelf
    local start_delay_duration = 0.05
    local delay_coefficient = 1.05
    local function doLotteryAction(aIndex, aRewards)
      local tempLayer = Layer:create()
      tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
      self.container:addChild(tempLayer)
      self.container.targetInfoPanel = tempLayer
      self.container:setTableViewsEnabled(false)
      select_tag:setVisible(true)
      select_tag:setPositionX(item_group_list[1]:getPositionX() + offset_x)
      select_tag:setPositionY(item_group_list[1]:getPositionY() + offset_y)
      local repeat_time = 24 + aIndex - 1
      if aIndex == 1 then
        repeat_time = repeat_time + 8
      end
      local current_repeat_time = 0
      local currentSelectIndex = 1
      local current_delay_duration = start_delay_duration
      
      local oneMoveFinished
      local function move()
        current_delay_duration = current_delay_duration * delay_coefficient
        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(current_delay_duration))
        arr:addObject(CCCallFunc:create(oneMoveFinished))
        select_tag:runAction(CCSequence:create(arr))
      end
      
      oneMoveFinished = function()
        currentSelectIndex = currentSelectIndex + 1
        if currentSelectIndex >= 9 then
          currentSelectIndex = 1
        end
        select_tag:setPositionX(item_group_list[currentSelectIndex]:getPositionX() + offset_x)
        select_tag:setPositionY(item_group_list[currentSelectIndex]:getPositionY() + offset_y)
        current_repeat_time = current_repeat_time + 1
        if current_repeat_time >= repeat_time then
          local function showPanel()
            RewardManager:getReward(aRewards)
            tempLayer:removeFromParentAndCleanup(true)
            self.container.targetInfoPanel = nil
            self.container:setTableViewsEnabled(true)
            select_tag:setVisible(false)
            local RewardPanel1 = GetRewardInfoPanel:create( self.container, aRewards )
            PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
          end
          local arr2 = CCArray:create()
          arr2:addObject(CCDelayTime:create(1.0))
          arr2:addObject(CCCallFunc:create(showPanel))
          select_tag:runAction(CCSequence:create(arr2))
          
        else
          move()
        end
      end
      move()
    end
    
    local function startLottery(gemCost)
      local function gainFortuneRewardsSucceed(event)
        if gemCost then
          RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemCost})
        end
        local aFortuneNum = DailyDataManager.getDailyDataFortuneNum()
        aFortuneNum = aFortuneNum + 1
        DailyDataManager.setDailyDataFortuneNum(aFortuneNum)
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_FortuneNow")
        doLotteryAction(event.data.id, event.data.rewards)
      end 
      local function gainFortuneRewardsFailed(event)
        if event.data.retCode == 714470 then  --activity closed
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_error_expired")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714471 then  --FortuneNum over max
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_fortuneNow__go_fortune_max")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {}
      local request = GainFortuneRewardsRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainFortuneRewardsSucceed, gainFortuneRewardsSucceed)
      request:addEventListener(RequestNotifyEnum.GainFortuneRewardsFailed, gainFortuneRewardsFailed)
      request:start()
    end
    
    local function freeButtonSelected(evt)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("shop_inventoryFull")
        NewPackageFullPanel:show()
        -- SuspensionLabel:showContent(self.container, aContent)
        return
      end
      startLottery()
    end
    local freeButtonDisplay = self.mainUI:getChildByName("btn_lucky")
    freeButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_go_fortune"))
    local freeButton = Button:create(freeButtonDisplay)
    freeButton:addEventListener(Events.kStart,freeButtonSelected, self)
    
    local function gemButtonSelected(evt)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("shop_inventoryFull")
        NewPackageFullPanel:show()
        -- SuspensionLabel:showContent(self.container, aContent)
        return
      end
      if CalculationManager.calcComplex_getGemsNow() < DataManager.GameMetaData.activityFortuneNowConfig.fortuneCost then
        local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          self.container.targetInfoPanel = nil
        end
        
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
      end
      startLottery(DataManager.GameMetaData.activityFortuneNowConfig.fortuneCost)
    end
    local gemButtonDisplay = self.mainUI:getChildByName("btn_lucky2")
    gemButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_go_fortune"))
    gemButtonDisplay:getChildByName("txt2"):setString(string.format("%d", DataManager.GameMetaData.activityFortuneNowConfig.fortuneCost))
    local gemButton = Button:create(gemButtonDisplay)
    gemButton:addEventListener(Events.kStart,gemButtonSelected, self)
    
    local infoTitle1 = self.mainUI:getChildByName("daily_lottery_info_txt3")
    infoTitle1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow__go_fortune_max"))
    local infoTitle2 = self.mainUI:getChildByName("daily_lottery_info_txt4")
    infoTitle2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_end_time"))
    local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(DataManager.GameMetaData.activityFortuneNowConfig.featureName)
    local infoTitle3 = self.mainUI:getChildByName("daily_lottery_info_txt5")
    infoTitle3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_time", {num1 = activityEndMonth, num2 = activityEndDay}))
    local infoTitle4 = self.mainUI:getChildByName("daily_lottery_free1")
    infoTitle4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_fortuneNow_free_dec"))
    local infoTitle5 = self.mainUI:getChildByName("daily_lottery_free2")
    
    refreshSelf = function()
      local canfree = (DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime > DailyDataManager.getDailyDataFortuneNum())
      local canLottery = (DataManager.GameMetaData.activityFortuneNowConfig.fortuneTimeMax > DailyDataManager.getDailyDataFortuneNum())
      if canfree then
        infoTitle1:setVisible(false)
        infoTitle4:setVisible(true)
        infoTitle5:setVisible(true)
        infoTitle5:getChildByName("txt"):setString(string.format("%d", DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime - DailyDataManager.getDailyDataFortuneNum()))
        freeButtonDisplay:setVisible(true)
        freeButton:setEnable(true)
        gemButtonDisplay:setVisible(false)
        gemButton:setEnable(false)
      elseif canLottery then
        infoTitle1:setVisible(false)
        infoTitle4:setVisible(false)
        infoTitle5:setVisible(false)
        freeButtonDisplay:setVisible(false)
        freeButton:setEnable(false)
        gemButtonDisplay:setVisible(true)
        gemButton:setEnable(true)
      else
        infoTitle1:setVisible(true)
        infoTitle4:setVisible(false)
        infoTitle5:setVisible(false)
        freeButtonDisplay:setVisible(false)
        freeButton:setEnable(false)
        gemButtonDisplay:setVisible(false)
        gemButton:setEnable(false)
      end
    end
    
    refreshSelf()
    
    local oldDate = TimeUtil.getYmd()
    local function checkSwitchDay()
      local aTempTime = TimeUtil.getYmd()
      if oldDate ~= aTempTime then
        oldDate = aTempTime
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_FortuneNow")
      end
    end
    self.checkSwitchDayFunc =  CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSwitchDay,15,false)
end

function Activity_LotteryFortuneLayer:enable()
    if not DataManager.GameMetaData.activityFortuneNowConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityFortuneNowConfig.featureName)
    return isEnable
end 

function Activity_LotteryFortuneLayer:dispose()
  if self.checkSwitchDayFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkSwitchDayFunc)
    self.checkSwitchDayFunc = nil
  end
  Activity_LotteryFortuneLayer.super.dispose(self)
end

function Activity_LotteryFortuneLayer.shouldShowParticle()
  if (DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime > DailyDataManager.getDailyDataFortuneNum()) then
    return true
  else
    return false
  end
end

function Activity_LotteryFortuneLayer.getTipNum()
  if not Activity_LotteryFortuneLayer.enable() then
    return 0
  end
  
  local result = DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime - DailyDataManager.getDailyDataFortuneNum()
  if result > 0 then
    return result
  else
    return 0
  end
end