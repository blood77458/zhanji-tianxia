require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"

NewPackageFullPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function NewPackageFullPanel:ctor()
  self.container = nil
end

function NewPackageFullPanel:show(callBackFunc)
  local panel = NewPackageFullPanel.new()
  panel.container = Director:sharedDirector():getRunningScene()
  panel.callBackFunc = callBackFunc
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

function NewPackageFullPanel:initLayer()
  NewPackageFullPanel.super.initLayer(self)
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
    if self.callBackFunc and type(self.callBackFunc) == "function" then
      self:callBackFunc()
    end
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end

  -- 关闭按钮
  local closeButtonDisplay = self.ui:getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)

  local function onLargerPackage( evt )
    local toBuyTimes = DataManager.getGameInitData().sharkUserExtend.boughtGridTimes + 1
    if toBuyTimes > MetaManager.game_meta.gameSettingConfig.inventoryMaxExpandTimes then
      SuspensionLabel:showContent(self.container, getTextByKey("bag_canNotExpand"))
      return 
    end
    self:switchButton(true)
  end
  self.largerPackageButton = Button:create(self.ui:getChildByName("common_btn_close"))
  self.largerPackageButton:addEventListener(Events.kStart, onLargerPackage, self)

  local function onSortPackage( evt )
    self.container:replaceScene(BackpackScene,{params = {isCardTrain = false}})
    -- Director:sharedDirector():replaceScene(BackpackScene:create())
  end
  self.sortPackageButton = Button:create(self.ui:getChildByName("common_btn_goarena"))
  self.sortPackageButton:addEventListener(Events.kStart, onSortPackage, self)

  local function onConformLarger( evt )
    self:buyGridRequest(true)
  end

  self.conformLargerButton  = Button:create(self.ui:getChildByName("common_btn_close2"))
  self.conformLargerButton:addEventListener(Events.kStart, onConformLarger, self)

  local function onCancelLarger( evt )
    self:switchButton(false)
  end

  self.cancelLargerButton  = Button:create(self.ui:getChildByName("common_btn_goarena2"))
  self.cancelLargerButton:addEventListener(Events.kStart, onCancelLarger, self)

  self:switchButton(false)

  self.ui:getChildByName("common_btn_goarena2"):getChildByName("txt"):setString(getTextByKey("cancel"))
  self.ui:getChildByName("common_btn_close2"):getChildByName("txt"):setString(getTextByKey("yes"))
  self.ui:getChildByName("common_btn_goarena"):getChildByName("txt"):setString(getTextByKey("inventoryFull_jumpBtn"))
  self.ui:getChildByName("common_btn_close"):getChildByName("txt"):setString(getTextByKey("bag_ExpandBtn"))
  self.ui:getChildByName("common_btn_close3"):setVisible(false)

  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)

  PopoutManager:sharedManager():popout(self, kPopoutDir.kScale, true, false ,self.container)
end

function NewPackageFullPanel:switchButton(evt)
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
    self.goldCost = 0
    local toBuyTimes = DataManager.getGameInitData().sharkUserExtend.boughtGridTimes + 1
    local increaseGridNum = MetaManager.game_meta.gameSettingConfig.inventoryExtraSlotsPerPurchase
    for k,v in pairs(MetaManager.expand_inventory) do
      if (tonumber(v.startTimes) <= toBuyTimes) and ((tonumber(v.endTimes) >= (toBuyTimes)) or tonumber(v.endTimes) == -1) then
        self.goldCost = tonumber(v.goldCost)
        break;
      end
    end
    aString = Localization:getInstance():getText("bag_confirmExpand", {num1 = self.goldCost, num2 = increaseGridNum})
    self.ui:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(aString)
  else
    self.ui:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("inventoryFull_text"))
  end
end

function NewPackageFullPanel:buyGridRequest(buy)
  -- self:setTableViewsEnabled(true)
  if not buy then
    do return end
  end
  
  if CalculationManager.calcComplex_getGemsNow() < self.goldCost then
    local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
    self.container:addChild(aPanel)
    aPanel:scaleIn()
    do return end
  end
  
  local function buyGridFailed(e)
    if e.data == 710513 then
      local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
      self.container:addChild(aPanel)
      aPanel:scaleIn()
    -- elseif e.data == 713301 then
    --   local gameInitData = DataManager.getGameInitData()
    --   gameInitData.sharkUserExtend.boughtGridTimes = MetaManager.game_meta.gameSettingConfig.inventoryMaxExpandTimes
    --   DataManager.setGameInitData(gameInitData)
    --   self:setTableViewsEnabled(false)
    --   self.targetInfoPanel = MessageBoxPanel:create(self, MessageBoxType.kEnsureBuyGridWarning, {setTargetInfoPanelNil = true})
    --   self:addChild(self.targetInfoPanel)
    --   self.targetInfoPanel:scaleIn()
    else
      CanonMessageBox:showCommUnHandleErrorBox(e.data)
    end
  end

  local function buyGridResponse( e )
    SuspensionLabel:showContent(self.container, getTextByKey("bag_expandSuccess"))
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkUserExtend.boughtGridTimes = gameInitData.sharkUserExtend.boughtGridTimes + 1
    DataManager.setGameInitData(gameInitData)
    RewardManager:getReward(e.data.rewards)
    e.data.requisite.amount = tostring(-tonumber(e.data.requisite.amount))
    RewardManager:getReward({e.data.requisite})
    if self.container.recalcBagInfo and type(self.container.recalcBagInfo) == "function" then
      self.container:recalcBagInfo()
    end
 
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil

    if self.callBackFunc and type(self.callBackFunc) == "function" then
      self:callBackFunc()
    end
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end
    
  local request = BuyGridRequest.new( nil, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.BuyGridSucceed, buyGridResponse )
  request:addEventListener( RequestNotifyEnum.BuyGridFailed, buyGridFailed )
  request:start()
end

function NewPackageFullPanel:setTableViewsEnabled(flag)

end

function NewPackageFullPanel:dispose()
  self.container.targetInfoPanel = nil
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
  if type(self.container.refreshRewardList) == "function" then
    self.container:refreshRewardList("notShowAnimation")
  end
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
  NewPackageFullPanel.super.dispose(self)
end