require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- EEPSupplyPanel
--

EEPSupplyPanel = class(Layer)

function EEPSupplyPanel:ctor()
    self.container = nil
    self.args = nil
end

function EEPSupplyPanel:create( container, args, callback, isEnergy )
    local s = EEPSupplyPanel.new()
    s:initLayer(container, args, callback, isEnergy)
    return s
end

function EEPSupplyPanel:initLayer(container, args, callback, isEnergy)
    EEPSupplyPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    self.callback = callback
    self.isEnergy = isEnergy
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_chargestamina") 
    self.tempLayer:addChild(self.panelUI)
    
    if self.isEnergy then
      self.panelUI:getChildByName("txt_rechargestamina_title"):getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_replenishStamina"))
      self.panelUI:getChildByName("txt_stamina_charge1"):getChildByName("txt"):setString(Localization:getInstance():getText("popup_replenishEnergyByPropTxt"))
    else
      self.panelUI:getChildByName("txt_rechargestamina_title"):getChildByName("txt"):setString(Localization:getInstance():getText("playerInfo_replenishVigour"))
      self.panelUI:getChildByName("txt_stamina_charge1"):getChildByName("txt"):setString(Localization:getInstance():getText("popup_replenishEventPointByPropTxt"))
    end
    
    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("common_btn_close_sb")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    local refreshButtons
    
    local function prop1Selected(evt)
      self.selectIndex = 1
      refreshButtons()
    end
    local aPropDisplay1 = self.panelUI:getChildByName("common_usepotion_s")
    aPropDisplay1:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setString(Localization:getInstance():getText(MetaManager.prop_meta[self.args[1].metaId].name))
    aPropDisplay1:getChildByName("common_txt_item_quantity"):getChildByName("txt_item_quantity"):setString(string.format("x%d", self.args[1].amount))
    local aCardDisplay1 = aPropDisplay1:getChildByName("common_normal_card_small")
    aCardDisplay1:setVisible(false)
    aCardDisplay1.touchEnabled = false
    aPropDisplay1:getChildByName("magnate_token_select").touchEnabled = false
    local icon1 = CanonItem:create()
    icon1:loadByMetaId(self.args[1].metaId)
    icon1:setScale(0.85)
    icon1:setPosition(ccp(aCardDisplay1:getPositionX(), aCardDisplay1:getPositionY()))
    aPropDisplay1:addChildAt(icon1, 1)
    local iconButton1 = Button:create(icon1)
    iconButton1:addEventListener( Events.kStart, prop1Selected, self )
    if self.args[1].amount > 0 then
      self.selectIndex = 1
    end
    
    local function prop2Selected(evt)
      self.selectIndex = 2
      refreshButtons()
    end
    local aPropDisplay2 = self.panelUI:getChildByName("common_usepotion_s1")
    aPropDisplay2:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setString(Localization:getInstance():getText(MetaManager.prop_meta[self.args[2].metaId].name))
    aPropDisplay2:getChildByName("common_txt_item_quantity"):getChildByName("txt_item_quantity"):setString(string.format("x%d", self.args[2].amount))
    local aCardDisplay2 = aPropDisplay2:getChildByName("common_normal_card_small")
    aCardDisplay2:setVisible(false)
    aCardDisplay2.touchEnabled = false
    aPropDisplay2:getChildByName("magnate_token_select").touchEnabled = false
    local icon2 = CanonItem:create()
    icon2:loadByMetaId(self.args[2].metaId)
    icon2:setScale(0.85)
    icon2:setPosition(ccp(aCardDisplay2:getPositionX(), aCardDisplay2:getPositionY()))
    aPropDisplay2:addChildAt(icon2, 1)
    local iconButton2 = Button:create(icon2)
    iconButton2:addEventListener( Events.kStart, prop2Selected, self )
    if (not self.selectIndex) and (self.args[2].amount > 0) then
      self.selectIndex = 2
    end
    
    local function prop3Selected(evt)
      self.selectIndex = 3
      refreshButtons()
    end
    local aPropDisplay3 = self.panelUI:getChildByName("common_usepotion_s2")
    aPropDisplay3:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setString(Localization:getInstance():getText(MetaManager.prop_meta[self.args[3].metaId].name))
    aPropDisplay3:getChildByName("common_txt_item_quantity"):getChildByName("txt_item_quantity"):setString(string.format("x%d", self.args[3].amount))
    local aCardDisplay3 = aPropDisplay3:getChildByName("common_normal_card_small")
    aCardDisplay3:setVisible(false)
    aCardDisplay3.touchEnabled = false
    aPropDisplay3:getChildByName("magnate_token_select").touchEnabled = false
    local icon3 = CanonItem:create()
    icon3:loadByMetaId(self.args[3].metaId)
    icon3:setScale(0.85)
    icon3:setPosition(ccp(aCardDisplay3:getPositionX(), aCardDisplay3:getPositionY()))
    aPropDisplay3:addChildAt(icon3, 1)
    local iconButton3 = Button:create(icon3)
    iconButton3:addEventListener( Events.kStart, prop3Selected, self )
    if (not self.selectIndex) and (self.args[3].amount > 0) then
      self.selectIndex = 3
    end
    
    local l_arrow = self.panelUI:getChildByName("select_triangle_l")
    local m_arrow = self.panelUI:getChildByName("select_triangle_m")
    local r_arrow = self.panelUI:getChildByName("select_triangle_r")
    
    local aSelectPropDisplay = self.panelUI:getChildByName("common_usepotion_l")
    local aSelectPropName = aSelectPropDisplay:getChildByName("common_txt_item_name"):getChildByName("txt_item_name")
    local aSelectpropNum = aSelectPropDisplay:getChildByName("common_txt_item_quantity"):getChildByName("txt_item_quantity")
    aSelectPropDisplay:getChildByName("magnate_token_select"):setVisible(false)
    local aSelectPropIcon = aSelectPropDisplay:getChildByName("common_normal_card_small")
    aSelectPropIcon:setVisible(false)
    local aSelectPropDes = self.panelUI:getChildByName("txt_stamina_charge2"):getChildByName("txt")
    local function useBtnSelected(evt)
      self:dismissSelf()
      if self.callback then
        self.callback(self.args[self.selectIndex].metaId)
      end
    end
    local useBtnDisplay = self.panelUI:getChildByName("common_btn_propInfo_useBtn")
    useBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(Localization:getInstance():getText("bag_UseBtn"))
    local useBtn = Button:create(useBtnDisplay)
    useBtn:addEventListener( Events.kStart, useBtnSelected, self )
    
    refreshButtons = function()
      if self.args[self.selectIndex].amount > 0 then
        useBtnDisplay:getChildByName("btn"):setVisible(true)
        useBtnDisplay:getChildByName("btn_inactive"):setVisible(false)
        useBtn:setEnable(true)
      else
        useBtnDisplay:getChildByName("btn"):setVisible(false)
        useBtnDisplay:getChildByName("btn_inactive"):setVisible(true)
        useBtn:setEnable(false)
      end
      if self.selectIndex == 1 then
        l_arrow:setVisible(true)
        m_arrow:setVisible(false)
        r_arrow:setVisible(false)
        aPropDisplay1:getChildByName("magnate_token_select"):setVisible(true)
        iconButton1:setEnable(false)
        aPropDisplay2:getChildByName("magnate_token_select"):setVisible(false)
        iconButton2:setEnable(true)
        --[[
        if self.args[2].amount > 0 then
          iconButton2:setEnable(true)
        else
          iconButton2:setEnable(false)
        end
        ]]
        aPropDisplay3:getChildByName("magnate_token_select"):setVisible(false)
        iconButton3:setEnable(true)
        --[[
        if self.args[3].amount > 0 then
          iconButton3:setEnable(true)
        else
          iconButton3:setEnable(false)
        end
        ]]
      elseif self.selectIndex == 2 then
        l_arrow:setVisible(false)
        m_arrow:setVisible(true)
        r_arrow:setVisible(false)
        aPropDisplay2:getChildByName("magnate_token_select"):setVisible(true)
        iconButton2:setEnable(false)
        aPropDisplay1:getChildByName("magnate_token_select"):setVisible(false)
        iconButton1:setEnable(true)
        --[[
        if self.args[1].amount > 0 then
          iconButton1:setEnable(true)
        else
          iconButton1:setEnable(false)
        end
        ]]
        aPropDisplay3:getChildByName("magnate_token_select"):setVisible(false)
        iconButton3:setEnable(true)
        --[[
        if self.args[3].amount > 0 then
          iconButton3:setEnable(true)
        else
          iconButton3:setEnable(false)
        end
        ]]
      elseif self.selectIndex == 3 then
        l_arrow:setVisible(false)
        m_arrow:setVisible(false)
        r_arrow:setVisible(true)
        aPropDisplay3:getChildByName("magnate_token_select"):setVisible(true)
        iconButton3:setEnable(false)
        aPropDisplay1:getChildByName("magnate_token_select"):setVisible(false)
        iconButton1:setEnable(true)
        --[[
        if self.args[1].amount > 0 then
          iconButton1:setEnable(true)
        else
          iconButton1:setEnable(false)
        end
        ]]
        aPropDisplay2:getChildByName("magnate_token_select"):setVisible(false)
        iconButton2:setEnable(true)
        --[[
        if self.args[2].amount > 0 then
          iconButton2:setEnable(true)
        else
          iconButton2:setEnable(false)
        end
        ]]
      end
      aSelectPropName:setString(Localization:getInstance():getText(MetaManager.prop_meta[self.args[self.selectIndex].metaId].name))
      aSelectpropNum:setString(string.format("x%d", self.args[self.selectIndex].amount))
      if self.selectedIcon then
        self.selectedIcon:removeFromParentAndCleanup(true)
      end
      self.selectedIcon = CanonItem:create()
      self.selectedIcon:loadByMetaId(self.args[self.selectIndex].metaId)
      self.selectedIcon:setScale(0.85)
      self.selectedIcon:setPosition(ccp(aSelectPropIcon:getPositionX(), aSelectPropIcon:getPositionY()))
      aSelectPropDisplay:addChildAt(self.selectedIcon, 2)
      aSelectPropDes:setString(Localization:getInstance():getText(MetaManager.prop_meta[self.args[self.selectIndex].metaId].desc))
    end
    
    refreshButtons()
    
    self.tempLayer:setScale(0.1)
end

function EEPSupplyPanel:scaleIn()
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

function EEPSupplyPanel:dismissSelf()
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(true)
    end
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
end