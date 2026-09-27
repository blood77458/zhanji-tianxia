RemindingUserGetXiaoyuBigRewardPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function RemindingUserGetXiaoyuBigRewardPanel:ctor()
  self.container = nil
end

function RemindingUserGetXiaoyuBigRewardPanel:show(userName,callBackFunc)
  local panel = RemindingUserGetXiaoyuBigRewardPanel.new()
  panel.container = Director:sharedDirector():getRunningScene()
  panel.userName = userName
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

function RemindingUserGetXiaoyuBigRewardPanel:initLayer()
  RemindingUserGetXiaoyuBigRewardPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  self.container.targetInfoPanel = self
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  self.ui = builder:build("common_popup_package_full")
  self:addChild(self.ui)
  
  self.ui:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("activity_specialAnnounce",{name = self.userName}))

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

  
  self.ui:getChildByName("common_btn_goarena2"):setVisible(false)
  self.ui:getChildByName("common_btn_close2"):setVisible(false)
  self.ui:getChildByName("common_btn_goarena"):setVisible(false)
  self.ui:getChildByName("common_btn_close"):setVisible(false)
  self.ui:getChildByName("common_btn_close3"):getChildByName("txt"):setString(getTextByKey("activity_enter1"))
  
  local knownButton = Button:create(self.ui:getChildByName("common_btn_close3"))
  knownButton:addEventListener(Events.kStart, onClosePanel, self)

  PopoutManager:sharedManager():popout(self, kPopoutDir.kScale, true, false ,self.container)
end


function RemindingUserGetXiaoyuBigRewardPanel:setTableViewsEnabled(flag)

end

function RemindingUserGetXiaoyuBigRewardPanel:dispose()
  self.container.targetInfoPanel = nil
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
 
  RemindingUserGetXiaoyuBigRewardPanel.super.dispose(self)
end