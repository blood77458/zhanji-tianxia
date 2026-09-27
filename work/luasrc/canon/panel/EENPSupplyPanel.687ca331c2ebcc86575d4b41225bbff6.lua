require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

EESupplyTypeEnum = {
  Energy = 1,
  EventPoint = 2,
}

--
-- EENPSupplyPanel
--

EENPSupplyPanel = class(Layer)

function EENPSupplyPanel:ctor()
    self.container = nil
    self.args = nil
end

function EENPSupplyPanel:create( container, args )
    local s = EENPSupplyPanel.new()
    s:initLayer(container, args)
    return s
end

function EENPSupplyPanel:initLayer(container, args)
    EENPSupplyPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    self.pre_container_targetInfoPanel = self.container.targetInfoPanel
    self.container.targetInfoPanel = self
    
    if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(false)
    end
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local aSupplyEnergyNum
    local aSupplyEnergyCost
    local aSupplyEventPointNum
    local aSupplyEventPointCost
    local aEnergyConfigs = DataManager.GameMetaData.replenishEnergyConfig.items
    local aEventPointConfigs = DataManager.GameMetaData.replenishEventPointConfig.items
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_charge_stamina_bycoin") 
    self.tempLayer:addChild(self.panelUI)
    
    if self.args.supplyType == EESupplyTypeEnum.Energy then
      self.panelUI:getChildByName("txt_charge_stamina_bycoin_title"):getChildByName("txt"):setString(Localization:getInstance():getText("replenish_txt") .. Localization:getInstance():getText("home_stamina"))
    elseif self.args.supplyType == EESupplyTypeEnum.EventPoint then
      self.panelUI:getChildByName("txt_charge_stamina_bycoin_title"):getChildByName("txt"):setString(Localization:getInstance():getText("replenish_txt") .. Localization:getInstance():getText("home_energy"))
    end
    
    local refreshSelf
    
    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("common_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    local function supplyBtnAction(evt)
      if self.args.supplyType == EESupplyTypeEnum.Energy then
        if (aSupplyEnergyCost>CalculationManager.calcComplex_getGemsNow()) then
          self:dismissSelf()
          local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
          self.container:addChild(aPanel)
          aPanel:scaleIn()
        else
          local function afterBuyEnergy()
            local curEnergy = CalculationManager.calcComplex_getEnergyNow()
            local energyAmount = 0
            if curEnergy + MetaManager.getEnergyGainedByGem() <= DataManager.GameMetaData.gameSettingConfig.maxEnergy then
              energyAmount = MetaManager.getEnergyGainedByGem()
            else
              energyAmount = DataManager.GameMetaData.gameSettingConfig.maxEnergy - curEnergy
            end
            if energyAmount < 0 then
              energyAmount = 0
            end
            local aReward = {
              {	itemType = ResourceEnum.GEMS,
                amount = aSupplyEnergyCost * -1,
              },
              {	itemType = ResourceEnum.ENERGY,
                amount = energyAmount,
              }
            }
            RewardManager:getReward(aReward)
          
            SuspensionLabel:showContent(self.container, getTextByKey("playerInfo_recoverStaminaComplete", {num = energyAmount}))
            DailyDataManager.setEnergyBoughtNum(DailyDataManager.getEnergyBoughtNum() + 1)
            refreshSelf()
            self.args.callback()
          end
          local function buyEnergyFailed(evt) 
            self:dismissSelf()
            local errorCode = tonumber(evt.data)
            if 710090 == errorCode then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_ENERGY_FULL, nil, nil, nil)
            elseif 710091 == errorCode then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_ENERGY_BOUGHT_NUM_FULL, nil, nil, nil)
            end
          end
          local request = BuyEnergyRequest.new( params, rpc.SendingPriority.kHigh )
          request:addEventListener(RequestNotifyEnum.BuyEnergySucceed, afterBuyEnergy)
          request:addEventListener(RequestNotifyEnum.BuyEnergyFailed, buyEnergyFailed)
          request:start()
        end
      elseif self.args.supplyType == EESupplyTypeEnum.EventPoint then
        if (aSupplyEventPointCost>CalculationManager.calcComplex_getGemsNow()) then
          self:dismissSelf()
          local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
          self.container:addChild(aPanel)
          aPanel:scaleIn()
        else
          local function afterBuyEventPoint()
            local curEventPoint = CalculationManager.calcComplex_getEPNow()
            local eventPointAmount = 0
            if curEventPoint + MetaManager.getEventPointGainedByGem() <= DataManager.GameMetaData.gameSettingConfig.maxEventPoint then
              eventPointAmount = MetaManager.getEventPointGainedByGem()
            else
              eventPointAmount = DataManager.GameMetaData.gameSettingConfig.maxEventPoint - curEventPoint
            end
            if eventPointAmount < 0 then
              eventPointAmount = 0
            end
            local aReward = {
              {	itemType = ResourceEnum.GEMS,
                amount = aSupplyEventPointCost * -1,
              },
              {	itemType = ResourceEnum.EVENTPOINT,
                amount = eventPointAmount,
              }
            }
            RewardManager:getReward(aReward)
            --RewardManager.setEventPoint(curEventPoint + eventPointAmount)
          
            SuspensionLabel:showContent(self.container, getTextByKey("playerInfo_recoverVigourComplete", {num = eventPointAmount}))
            DailyDataManager.setEventPointBoughtNum(DailyDataManager.getEventPointBoughtNum() + 1)
            refreshSelf()
            self.args.callback()
          end
          local function buyEventPointFailed(evt) 
            self:dismissSelf()
            local errorCode = tonumber(evt.data)
            if 710092 == errorCode then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_EVENT_POINT_FULL, nil, nil, nil)
            elseif 710093 == errorCode then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_EVENT_POINT_BOUGHT_NUM_FULL, nil, nil, nil)
            end
          end
          local request = BuyEventPointRequest.new( params, rpc.SendingPriority.kHigh )
          request:addEventListener(RequestNotifyEnum.BuyEventPointSucceed, afterBuyEventPoint)
          request:addEventListener(RequestNotifyEnum.BuyEventPointFailed, buyEventPointFailed)
          request:start()
        end
      end
    end
    local supplyBtnDisplay = self.panelUI:getChildByName("btn_charge_stamina_bycoin")
    supplyBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("replenish_txt"))
    local supplyBtn = Button:create(supplyBtnDisplay)
    supplyBtn:addEventListener( Events.kStart, supplyBtnAction, self )
    
    local function cancelBtnAction(evt)
      self:dismissSelf()
    end
    local cancelBtnDisplay = self.panelUI:getChildByName("btn_charge_stamina_bycoin_cancel")
    cancelBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cancel"))
    local cancelBtn = Button:create(cancelBtnDisplay)
    cancelBtn:addEventListener( Events.kStart, cancelBtnAction, self )
    
    local infoLabel1 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info3")
    infoLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("replenish_expense"))
    local infoLabel2 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info4")
    local infoLabel3 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info5")
    infoLabel3:getChildByName("txt"):setString(Localization:getInstance():getText("replenish_gold"))
    local infoLabel4 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info6")
    local infoLabel5 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info7")
    local infoLabel6 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info")
    local infoLabel7 = self.panelUI:getChildByName("txt_charge_stamina_bycoin_info2")
    
    refreshSelf = function()
      local userInfo = DataManager.getCurrUser()
      if self.args.supplyType == EESupplyTypeEnum.Energy then
        if DailyDataManager.getEnergyBoughtNum() >= MetaManager.vip_setting[userInfo.vipLevel].purchaseStaminaPerDay then
          infoLabel1:setVisible(false)
          infoLabel2:setVisible(false)
          infoLabel3:setVisible(false)
          infoLabel4:setVisible(false)
          infoLabel5:setVisible(false)
          infoLabel6:setVisible(true)
          infoLabel6:getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_cannotRecoverStamina"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(false)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(true)
          supplyBtn:setEnable(false)
        elseif CalculationManager.calcComplex_getEnergyNow() < DataManager.GameMetaData.gameSettingConfig.maxEnergy then
          infoLabel1:setVisible(true)
          infoLabel2:setVisible(true)
          infoLabel3:setVisible(true)
          infoLabel4:setVisible(true)
          infoLabel5:setVisible(true)
          infoLabel6:setVisible(false)
          for _,value in pairs(aEnergyConfigs) do
            if (DailyDataManager.getEnergyBoughtNum() + 1 <= value["endTimes"]) then
              aSupplyEnergyCost = value["goldCost"]
              break
            end
            if (value["endTimes"] == -1) then
              aSupplyEnergyCost = value["goldCost"]
            end
          end
          aSupplyEnergyNum = MetaManager.getEnergyGainedByGem()
          local curEnergy = CalculationManager.calcComplex_getEnergyNow()
          if (curEnergy + aSupplyEnergyNum) > DataManager.GameMetaData.gameSettingConfig.maxEnergy then
            aSupplyEnergyNum = DataManager.GameMetaData.gameSettingConfig.maxEnergy - curEnergy
          end
          infoLabel2:getChildByName("txt"):setString(string.format("%d", aSupplyEnergyCost))
          infoLabel4:getChildByName("txt"):setString(string.format("%d", aSupplyEnergyNum))
          infoLabel5:getChildByName("txt"):setString(Localization:getInstance():getText("home_stamina"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(true)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(false)
          supplyBtn:setEnable(true)
        else
          infoLabel1:setVisible(false)
          infoLabel2:setVisible(false)
          infoLabel3:setVisible(false)
          infoLabel4:setVisible(false)
          infoLabel5:setVisible(false)
          infoLabel6:setVisible(true)
          infoLabel6:getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_energyFull"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(false)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(true)
          supplyBtn:setEnable(false)
        end
        infoLabel7:getChildByName("txt"):setString(Localization:getInstance():getText("replenish_txt1") .. (MetaManager.vip_setting[userInfo.vipLevel].purchaseStaminaPerDay - DailyDataManager.getEnergyBoughtNum()))
      elseif self.args.supplyType == EESupplyTypeEnum.EventPoint then
        if DailyDataManager.getEventPointBoughtNum() >= MetaManager.vip_setting[userInfo.vipLevel].purchaseVigourPerDay then
          infoLabel1:setVisible(false)
          infoLabel2:setVisible(false)
          infoLabel3:setVisible(false)
          infoLabel4:setVisible(false)
          infoLabel5:setVisible(false)
          infoLabel6:setVisible(true)
          infoLabel6:getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_cannotRecoverVigour"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(false)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(true)
          supplyBtn:setEnable(false)
        elseif CalculationManager.calcComplex_getEPNow() < DataManager.GameMetaData.gameSettingConfig.maxEventPoint then
          infoLabel1:setVisible(true)
          infoLabel2:setVisible(true)
          infoLabel3:setVisible(true)
          infoLabel4:setVisible(true)
          infoLabel5:setVisible(true)
          infoLabel6:setVisible(false)
          for _,value in pairs(aEventPointConfigs) do
            if (DailyDataManager.getEventPointBoughtNum() + 1 <= value["endTimes"]) then
              aSupplyEventPointCost = value["goldCost"]
              break
            end
            if (value["endTimes"] == -1) then
              aSupplyEventPointCost = value["goldCost"]
            end
          end
          aSupplyEventPointNum = MetaManager.getEventPointGainedByGem()
          local curEventPoint = CalculationManager.calcComplex_getEPNow()
          if (curEventPoint + aSupplyEventPointNum) > DataManager.GameMetaData.gameSettingConfig.maxEventPoint then
            aSupplyEventPointNum = DataManager.GameMetaData.gameSettingConfig.maxEventPoint - curEventPoint
          end
          infoLabel2:getChildByName("txt"):setString(string.format("%d", aSupplyEventPointCost))
          infoLabel4:getChildByName("txt"):setString(string.format("%d", aSupplyEventPointNum))
          infoLabel5:getChildByName("txt"):setString(Localization:getInstance():getText("home_energy"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(true)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(false)
          supplyBtn:setEnable(true)
        else
          infoLabel1:setVisible(false)
          infoLabel2:setVisible(false)
          infoLabel3:setVisible(false)
          infoLabel4:setVisible(false)
          infoLabel5:setVisible(false)
          infoLabel6:setVisible(true)
          infoLabel6:getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_eventPointFull"))
          supplyBtnDisplay:getChildByName("btn"):setVisible(false)
          supplyBtnDisplay:getChildByName("btn_inactive"):setVisible(true)
          supplyBtn:setEnable(false)
        end
        infoLabel7:getChildByName("txt"):setString(Localization:getInstance():getText("replenish_txt1") .. (MetaManager.vip_setting[userInfo.vipLevel].purchaseVigourPerDay - DailyDataManager.getEventPointBoughtNum()))
      end
    end
    refreshSelf()
    
    self.tempLayer:setScale(0.1)
end

function EENPSupplyPanel:scaleIn()
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

function EENPSupplyPanel:dismissSelf()
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(true)
    end
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
end