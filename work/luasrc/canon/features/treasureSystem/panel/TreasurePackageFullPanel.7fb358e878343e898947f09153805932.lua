--------------------------------------------------------------------------------
-- TreasurePackageFullPanel.lua
-- author: l1ghtsaber
-- date: 2015-8-3
--------------------------------------------------------------------------------
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"

TreasurePackageFullPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function TreasurePackageFullPanel:ctor()
  self.container = nil
end

function TreasurePackageFullPanel:show()
  self.container = Director:sharedDirector():getRunningScene()
  
  local panel = TreasurePackageFullPanel.new()
  panel:initLayer()
  
  return panel
end

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
  PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

function TreasurePackageFullPanel:initLayer()
  TreasurePackageFullPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  self.container.targetInfoPanel = self
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  self.ui = builder:build("common_popup_package_full")
  self:addChild(self.ui)

  -- -- 设置页面标题
  -- local titleLabel = self.ui:getChildByName("common_txt_reward_title"):getChildByName("txt_reward_title")
  -- titleLabel:setString(getTextByKey("countdownReward_title"))

  -- 关闭Panel事件
  local function onClosePanel(evt)
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end

  -- 关闭按钮
  local closeButtonDisplay = self.ui:getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)

  local function onLargerPackage( evt )
    local toBuyTimes = DataManager.getGameInitData().sharkUserExtendMore.treasureInfo.buyGridTimes + 1
    if toBuyTimes > DataManager.GameMetaData.treasureSettingConfig.treasurePoolMaxExpandTimes then
      SuspensionLabel:showContent(self.container, getTextByKey("Treasure_tips_5"))
      return
    end
    self:switchButton(true)
  end
  self.largerPackageButton = Button:create(self.ui:getChildByName("common_btn_close"))
  self.largerPackageButton:addEventListener(Events.kStart, onLargerPackage, self)

  local function onSortPackage( evt )
    self.container:replaceScene(TreasureBackpackScene)
    -- Director:sharedDirector():replaceScene(BackpackScene:create())
  end
  self.sortPackageButton = Button:create(self.ui:getChildByName("common_btn_goarena"))
  self.sortPackageButton:addEventListener(Events.kStart, onSortPackage, self)

  local function onConformLarger( evt )
    self.goldCost = DataManager.GameMetaData.treasureSettingConfig.treasurePoolExpandCost
    if self.goldCost > CalculationManager.calcComplex_getGemsNow() then 
      local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
      self:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
    local function afterBuyGrid(  )
      if self.container.recalcBagInfo and type(self.container.recalcBagInfo) == "function" then
        self.container:recalcBagInfo()
      end
      self.container:setTableViewsEnabled(true)
      self.container.targetInfoPanel = nil
      PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
      SuspensionLabel:showContent(self.container, getTextByKey("Treasure_text_33"))
    end
    
    BuyTreasureGridRequest.sendRequestDefalut(afterBuyGrid)
  end

  self.conformLargerButton  = Button:create(self.ui:getChildByName("common_btn_close2"))
  self.conformLargerButton:addEventListener(Events.kStart, onConformLarger, self)

  local function onCancelLarger( evt )
    self:switchButton(false)
  end

  self.cancelLargerButton  = Button:create(self.ui:getChildByName("common_btn_goarena2"))
  self.cancelLargerButton:addEventListener(Events.kStart, onCancelLarger, self)

  self:switchButton(false)

  self.ui:getChildByName("common_btn_goarena2"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_17"))
  self.ui:getChildByName("common_btn_close2"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_16"))
  self.ui:getChildByName("common_btn_goarena"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_15"))
  self.ui:getChildByName("common_btn_close"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_14"))
  self.ui:getChildByName("common_btn_close3"):setVisible(false)

  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)

  PopoutManager:sharedManager():popout(self, kPopoutDir.kScale, true, false ,self.container)
end

function TreasurePackageFullPanel:switchButton(evt)
  self.conformLargerButton:setVisible(evt)
  self.conformLargerButton:setEnable(evt)
  self.conformLargerButton.touchEnabled = evt

  self.cancelLargerButton:setVisible(evt)
  self.cancelLargerButton:setEnable(evt)
  self.cancelLargerButton.touchEnabled = evt

  self.sortPackageButton:setVisible(not evt)
  self.sortPackageButton:setEnable(not evt)
  self.sortPackageButton.touchEnabled = not evt

  self.largerPackageButton:setVisible(not evt)
  self.largerPackageButton:setEnable(not evt)
  self.largerPackageButton.touchEnabled = not evt

  if(evt) then
    self.goldCost = DataManager.GameMetaData.treasureSettingConfig.treasurePoolExpandCost
    local increaseGridNum = DataManager.GameMetaData.treasureSettingConfig.treasureExtraSizePerPurchase
    aString = Localization:getInstance():getText("Treasure_tips_4", {nmb1 = self.goldCost, nmb2 = increaseGridNum})
    self.ui:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(aString)
  else
    self.ui:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("Treasure_tips_3"))
  end
end

function TreasurePackageFullPanel:setTableViewsEnabled(flag)

end

function TreasurePackageFullPanel:dispose()
  self.container.targetInfoPanel = nil
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
  if type(self.container.refreshRewardList) == "function" then
    self.container:refreshRewardList("notShowAnimation")
  end
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
  TreasurePackageFullPanel.super.dispose(self)
end