require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainMonthCardRequest"
require "canon.request.BuyMonthGemCardRequest"
require "canon.panel.ActivityInfoPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_MonthCardLayer
--

local id1 = 1
local id2 = 1

local shortPayCodeId = nil
local shortPayChannel = ""

Activity_MonthCardLayer = class(Layer)
function Activity_MonthCardLayer:ctor()
    self.container = nil
    self.extraArgs = nil
end

function Activity_MonthCardLayer:create( container, extraArgs )
    local s = Activity_MonthCardLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

local function isCurVipMaxLevel(level)
	local maxLevel = 0
	for k,v in pairs(MetaManager.vip_setting) do
		if maxLevel < v.level then
			maxLevel = v.level
		end
	end
	return level >= maxLevel
end

function Activity_MonthCardLayer:initLayer()
    Activity_MonthCardLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/monthcard.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("monthcard")
    self:addChild(self.mainUI)
    --[[
    local guide_other = self.mainUI:getChildByName("guide_other")
    guide_other:setVisible(false)
    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103011))
    card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0))
    self.mainUI:addChildAt(card3_spf, 3)
    ]]
    local receiveLabel1 = self.mainUI:getChildByName("monthcard_txt1")
    receiveLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec1"))
    local receiveLabel2 = self.mainUI:getChildByName("monthcard_allgold")
    receiveLabel2:getChildByName("txt"):setDimensions(CCSizeMake(0,receiveLabel2:getChildByName("txt"):getDimensions().height))
    receiveLabel2:getChildByName("txt"):setString(string.format("%d", DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardNum * DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardLastTime))
    local receiveLabel3 = self.mainUI:getChildByName("monthcard_txt2")
    receiveLabel3:getChildByName("txt"):setDimensions(CCSizeMake(0,receiveLabel3:getChildByName("txt"):getDimensions().height))
    receiveLabel3:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec2"))
    local aNewPosX = receiveLabel2:getPosition().x + receiveLabel2:getChildByName("txt"):getTexture():getContentSize().width
    receiveLabel3:setPositionX(aNewPosX)
    local receiveLabel4 = self.mainUI:getChildByName("monthcard_txt3")
    receiveLabel4:getChildByName("txt"):setDimensions(CCSizeMake(0,receiveLabel4:getChildByName("txt"):getDimensions().height))
    receiveLabel4:getChildByName("txt"):setString(string.format("%d", DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardNum))
    aNewPosX = receiveLabel2:getPosition().x + receiveLabel2:getChildByName("txt"):getTexture():getContentSize().width + receiveLabel3:getChildByName("txt"):getTexture():getContentSize().width
    receiveLabel4:setPositionX(aNewPosX)
    local receiveLabel5 = self.mainUI:getChildByName("monthcard_txt4")
    receiveLabel5:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec3"))
    aNewPosX = receiveLabel2:getPosition().x + receiveLabel2:getChildByName("txt"):getTexture():getContentSize().width + receiveLabel3:getChildByName("txt"):getTexture():getContentSize().width + receiveLabel4:getChildByName("txt"):getTexture():getContentSize().width
    receiveLabel5:setPositionX(aNewPosX)
    
    local buyLabel = self.mainUI:getChildByName("monthcard_info_txt")
	buyLabel:getChildByName("txt"):setDimensions(CCSizeMake(0,0))
	local pos = buyLabel:getChildByName("txt"):getPosition()
	buyLabel:getChildByName("txt"):setPosition(ccp(pos.x - 15, pos.y))
    buyLabel:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec", {num = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardLastTime}))
    local canGetLabel = self.mainUI:getChildByName("txt_canget")
    canGetLabel:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_remind_1"))
    local cannotGetLabel = self.mainUI:getChildByName("txt_cantget")
    cannotGetLabel:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_remind_2"))
    
    local refreshSelf
    
    local buyButton
    
    local function buyButtonSelected(evt)
      if self.extraArgs.buyConditionGem < DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardBuyConditionGem then
        CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("gemCard_dec6", {num = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardBuyConditionGem - self.extraArgs.buyConditionGem}), 
          {
            text = getTextByKey("cancel"),
            callbackFunc = function()
            end
          }, 
          nil,
          {
            text = getTextByKey("chargeMoney_go"),
            callbackFunc = function()
              self.container:replaceScene(ShopScene, {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE, selectPanelName = "Activity_GemCard"}})
            end
          }
        )
        return
      end
      if DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardGemCost > CalculationManager.calcComplex_getGemsNow() then
        local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          self.container.targetInfoPanel = nil
        end
        
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
      end
      local function buyMonthGemCardSucceed(event)
        local gameData = DataManager.getGameInitData()
        gameData.sharkGemCards = gameData.sharkGemCards or {}
        gameData.sharkGemCards.sharkGemCards = gameData.sharkGemCards.sharkGemCards or {}
        local aOldCard
        for _, v in ipairs(gameData.sharkGemCards.sharkGemCards) do
          if v.type == 1 then
            aOldCard = v
            break
          end
        end
        if not aOldCard then
          local aNewCard = {}
          aNewCard.type = 1
          aNewCard.deadline = event.data.monthGemCardDeadline
          aNewCard.gainedRewardDate = {}
          table.insert(gameData.sharkGemCards.sharkGemCards, aNewCard)
        elseif (aOldCard.deadline ~= event.data.monthGemCardDeadline) then
          aOldCard.deadline = event.data.monthGemCardDeadline
          aOldCard.gainedRewardDate = {}
        end
        DataManager.setGameInitData(gameData)
        RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardGemCost})
        
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_GemCard")
      end 
      local function buyMonthGemCardFailed(event)
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
        self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
      local params = {}
      local request = BuyMonthGemCardRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.BuyMonthGemCardSucceed, buyMonthGemCardSucceed)
      request:addEventListener(RequestNotifyEnum.BuyMonthGemCardFailed, buyMonthGemCardFailed)
      request:start()
    end
    
    local shortBuyBtn = nil
    if isShortPayForMonthCardOpen() then
        shortBuyBtn = self.mainUI:getChildByName("btn_more_credit")
        shortBuyBtn:getChildByName("txt"):setString(Localization:getInstance():getText("bill_buy_title"))
        buyButton = Button:create(shortBuyBtn)
        buyButton:addEventListener(Events.kStart, buyButtonSelected,"shortPay")
    else
        self.mainUI:getChildByName("btn_more_credit"):setVisible(false)
    end
    local buyButtonDisplay = self.mainUI:getChildByName("btn_buy")
    local aText
    if DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardGemCost > 0 then
      aText = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardGemCost .. Localization:getInstance():getText("gemCard_by")
    else
      aText = Localization:getInstance():getText("free_buy")
    end
    buyButtonDisplay:getChildByName("txt"):setString(aText)
    buyButton = Button:create(buyButtonDisplay)
    buyButton:addEventListener(Events.kStart, buyButtonSelected, self)
    
    local function getButtonSelected(evt)
      local server_date = os.date("*t", TimeUtil.getServerTimeSeconds())
      local function gainMonthCardSucceed(event)
        RewardManager:getReward(event.data.rewards)
        local gameData = DataManager.getGameInitData()
        local aOldCard
        for _, v in ipairs(gameData.sharkGemCards.sharkGemCards) do
          if v.type == 1 then
            aOldCard = v
            break
          end
        end
        table.insert(aOldCard.gainedRewardDate, string.format("%d/%d/%d", server_date.year, server_date.month, server_date.day))
        DataManager.setGameInitData(gameData)
        local aContent = Localization:getInstance():getText("gemCard_obtain", {num = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardNum})
        SuspensionLabel:showContent(self, aContent)
        local fspt = FlashSprite:create("EVO2/coindown")
        fspt:changeAnimation(0)
        fspt:setLoop(false)
        local fspt_co = CocosObject.new(fspt)
        self.container:addChild(fspt_co)
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_GemCard")
      end 
      local function gainMonthCardFailed(event)
        if event.data.retCode == 714452 then  --month card overdue
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("gemCard_expired")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714453 then  --already gained
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("gemCard_alreadyClaimed")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {}
      local request = GainMonthCardRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainMonthCardSucceed, gainMonthCardSucceed)
      request:addEventListener(RequestNotifyEnum.GainMonthCardFailed, gainMonthCardFailed)
      request:start()
    end
    local getButtonDisplay = self.mainUI:getChildByName("btn_getc")
    getButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_obtain_button"))
    local getButton = Button:create(getButtonDisplay)
    getButton:addEventListener(Events.kStart, getButtonSelected, self)
    
    local endTimeLabel1 = self.mainUI:getChildByName("monthcard_time_txt1")
    endTimeLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_end_time_1"))
    local endTimeLabel2 = self.mainUI:getChildByName("monthcard_time_txt2")

    local monthCardInfo1 = self.mainUI:getChildByName("monthcard_info_txt2")
    monthCardInfo1:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec4", {num1 = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardBuyConditionTime, num2 = DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardBuyConditionGem}))
    local monthCardInfo2 = self.mainUI:getChildByName("txt_monthcard_nowcharge")
    monthCardInfo2:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_dec5", {num = self.extraArgs.buyConditionGem}))
    self.mainUI:getChildByName("monthcard_info_txt3"):setVisible(false)

    refreshSelf = function()
      local ownGemCard
      local canget
      local gemCard
      local sharkGemCards = DataManager.getGameInitData().sharkGemCards
      --print(table.tostring(sharkGemCards))
      if (type(sharkGemCards) == "table") and (type(sharkGemCards.sharkGemCards) == "table") then
        for _, v in ipairs(sharkGemCards.sharkGemCards) do
          if v.type == 1 then
            gemCard = v
            break
          end
        end
        if gemCard then
          if gemCard.deadline and (TimeUtil.getServerTimeSeconds() < gemCard.deadline) then
            ownGemCard = true
            gemCard.gainedRewardDate = gemCard.gainedRewardDate or {}
            if #gemCard.gainedRewardDate == 0 then
              canget = true
            else
              local date_list = gemCard.gainedRewardDate[#gemCard.gainedRewardDate]:split("/")
              local server_date = os.date("*t", TimeUtil.getServerTimeSeconds())
              if (server_date.year == tonumber(date_list[1])) and (server_date.month == tonumber(date_list[2])) and (server_date.day == tonumber(date_list[3])) then
                canget = false
              else
                canget = true
              end
            end
          else
            ownGemCard = false
            canget = false
          end
        else
          ownGemCard = false
          canget = false
        end
      else
        ownGemCard = false
        canget = false
      end
      
      if not ownGemCard then
        buyLabel:setVisible(true)
        canGetLabel:setVisible(false)
        cannotGetLabel:setVisible(false)
        buyButtonDisplay:setVisible(true)
        if shortBuyBtn then
            shortBuyBtn:setVisible(true)
        end
        buyButton:setEnable(true)
        getButtonDisplay:setVisible(false)
        getButton:setEnable(false)
        endTimeLabel1:setVisible(false)
        endTimeLabel2:setVisible(false)
        monthCardInfo1:setVisible(true)
        monthCardInfo2:setVisible(true)
        if self.extraArgs.buyConditionGem >= DataManager.GameMetaData.activitySettingConfig.gemCardConfig.gemCardBuyConditionGem then
          monthCardInfo1:setVisible(false)
          monthCardInfo2:setVisible(false)
        else
          monthCardInfo1:setVisible(true)
          monthCardInfo2:setVisible(true)
        end
      else
        buyLabel:setVisible(false)
        buyButtonDisplay:setVisible(false)
        if shortBuyBtn then
            shortBuyBtn:setVisible(false)
        end
        buyButton:setEnable(false)
        getButtonDisplay:setVisible(true)
        endTimeLabel1:setVisible(true)
        endTimeLabel2:setVisible(true)
        monthCardInfo1:setVisible(false)
        monthCardInfo2:setVisible(false)
        local end_server_date = os.date("*t", gemCard.deadline)
        endTimeLabel2:getChildByName("txt"):setString(Localization:getInstance():getText("gemCard_end_time_2", {num1 = end_server_date.year, num2 = end_server_date.month, num3 = end_server_date.day}))
        if not canget then
          canGetLabel:setVisible(false)
          cannotGetLabel:setVisible(true)
          getButton:setEnable(false)
          getButtonDisplay:getChildByName("btn_inactive"):setVisible(true)
          getButtonDisplay:getChildByName("btn"):setVisible(false)
        else
          canGetLabel:setVisible(true)
          cannotGetLabel:setVisible(false)
          getButton:setEnable(true)
          getButtonDisplay:getChildByName("btn_inactive"):setVisible(false)
          getButtonDisplay:getChildByName("btn"):setVisible(true)
        end
      end
    end
    
    refreshSelf()
    
    local oldDate = TimeUtil.getYmd()
    local function checkSwitchDay()
      local aTempTime = TimeUtil.getYmd()
      if oldDate ~= aTempTime then
        oldDate = aTempTime
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_GemCard")
      end
    end
    self.checkSwitchDayFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSwitchDay, 15, false)
end

function Activity_MonthCardLayer:enable()
  if not DataManager.GameMetaData.activitySettingConfig or not DataManager.GameMetaData.activitySettingConfig.gemCardConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activitySettingConfig.gemCardConfig.featureName)-- and (tonumber(DataManager.getCurrUser().rechargeGems) > 0)
    return isEnable
end 

function Activity_MonthCardLayer:dispose()
  if self.checkSwitchDayFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkSwitchDayFunc)
    self.checkSwitchDayFunc = nil
  end
  Activity_MonthCardLayer.super.dispose(self)
end

function Activity_MonthCardLayer.shouldShowParticle()
  local canget = false
  local sharkGemCards = DataManager.getGameInitData().sharkGemCards
  if (type(sharkGemCards) == "table") and (type(sharkGemCards.sharkGemCards) == "table") then
    local gemCard
    for _, v in ipairs(sharkGemCards.sharkGemCards) do
      if v.type == 1 then
        gemCard = v
        break
      end
    end
    if gemCard and gemCard.deadline then
      if (TimeUtil.getServerTimeSeconds() < gemCard.deadline) then  --月卡有效未过期
        gemCard.gainedRewardDate = gemCard.gainedRewardDate or {}
        if #gemCard.gainedRewardDate == 0 then
          canget = true
        else
          local date_list = gemCard.gainedRewardDate[#gemCard.gainedRewardDate]:split("/")
          local server_date = os.date("*t", TimeUtil.getServerTimeSeconds())
          if (server_date.year == tonumber(date_list[1])) and (server_date.month == tonumber(date_list[2])) and (server_date.day == tonumber(date_list[3])) then
            canget = false
          else
            canget = true
          end
        end
      end
    end
  end
  return canget
end

function Activity_MonthCardLayer.getTipNum()
  if not Activity_MonthCardLayer.enable() then
    return 0
  end
  
  local gameData = DataManager.getGameInitData()
  if (not gameData.sharkGemCards) or not gameData.sharkGemCards.sharkGemCards then
    return 0, true
  end
  
  local gemCard
  for _, v in ipairs(gameData.sharkGemCards.sharkGemCards) do
    if v.type == 1 then
      gemCard = v
      break
    end
  end
  if not gemCard then
    return 0, true
  end
  
  if TimeUtil.getServerTimeSeconds() >= gemCard.deadline then
    return 0, true
  end
  
  local canget
  gemCard.gainedRewardDate = gemCard.gainedRewardDate or {}
  if #gemCard.gainedRewardDate == 0 then
    canget = true
  else
    local date_list = gemCard.gainedRewardDate[#gemCard.gainedRewardDate]:split("/")
    local server_date = os.date("*t", TimeUtil.getServerTimeSeconds())
    if (server_date.year == tonumber(date_list[1])) and (server_date.month == tonumber(date_list[2])) and (server_date.day == tonumber(date_list[3])) then
      canget = false
    else
      canget = true
    end
  end
  if canget then
    return 1
  else
    return 0
  end
end

function isShortPayForMonthCardOpen()
    local monthCardMeta = DataManager.GameMetaData.payShopConfig.payShopMetas
    for k,v in ipairs(monthCardMeta) do
        local id = v.id
        idArr = id:split("_")
		if string.find(idArr[1], "YIDONG") ~= nil and isYidongPayOpen() then
			shortPayCodeId = id
            shortPayChannel = "YIDONG"
            return true
		end
		if string.find(idArr[1], "LIANTONG") ~= nil and isLiantongPayOpen() then
			shortPayCodeId = id
            shortPayChannel = "LIANTONG"
            return true
		end
		if string.find(idArr[1], "DIANXIN") ~= nil and isDianxinPayOpen() then
			shortPayCodeId = id
            shortPayChannel = "DIANXIN"
            return true
		end
    end  
    return false  
end