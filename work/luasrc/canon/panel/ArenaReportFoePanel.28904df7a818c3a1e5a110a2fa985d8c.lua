require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "hecore.ui.ScrollView"
require "canon.panel.ArenaFoePanel"

local scroll_width = 528
local scroll_height = 396
local scroll_posX = 100
local scroll_posY = 472
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function closeAction(evt)
  local aPanel = evt.context
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  aPanel:removeFromParentAndCleanup(true)
end

--
-- ArenaReportFoePanel
--

ArenaReportFoePanel = class(Layer)

function ArenaReportFoePanel:ctor()
    self.container = nil
end

function ArenaReportFoePanel:create( container)
    local s = ArenaReportFoePanel.new()
    self.container = container
    s:initLayer()
    return s
end

function ArenaReportFoePanel:initLayer()
    ArenaReportFoePanel.super.initLayer(self)
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena.json")
    self.panelUI = builder:build("popup_arena_battleReport") 
    self.tempLayer:addChild(self.panelUI)
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
    closeButton:addEventListener( Events.kStart, closeAction, self )
    
    local function foeTabAction(evt)
      --[[
      self.selectedTabIndex = 1
      self:resetTab()
      ]]
      local aPanel = ArenaFoePanel:create(self.container)
      self.container:addChild(aPanel)
      aPanel:showPanel()
      self.container:removeChild(self)
    end
    local function reportTabAction(evt)
      self.selectedTabIndex = 0
      self:resetTab()
    end
    self.selectedTabIndex = 0
    self.reportTabDisplay = self.panelUI:getChildByName("btn_arena_reportTab")
    self.reportTabDisplay:getChildByName("txt_arena_reportTab"):setString(Localization:getInstance():getText("arena_reportTab"))
    self.reportTab = Button:create(self.reportTabDisplay)
    self.reportTab:addEventListener( Events.kStart, reportTabAction, self )
    self.foeTabDisplay = self.panelUI:getChildByName("btn_arena_enemyListTab")
    self.foeTabDisplay:getChildByName("txt_arena_enemyListTab"):setString(Localization:getInstance():getText("arena_enemyListTab"))
    self.foeTab = Button:create(self.foeTabDisplay)
    self.foeTab:addEventListener( Events.kStart, foeTabAction, self )
    
    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    self.reportsScrollView = aScrollView
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.tempLayer:addChild(aScrollView)
    
    local aGroup = self.panelUI:getChildByName("popup_arena_battleReport_entry1")
    aGroup:setVisible(false)
    local aStartPosX = aGroup:getPositionX() - scroll_posX
    local aStartPosY = aGroup:getPositionY() - scroll_posY
    local aExampleLabel = aGroup:getChildByName("txt_popup_arena_battleReport_entry_txt1"):getChildByName("txt_popup_arena_battleReport_entry_txt1")
    aExampleLabel:setDimensions(CCSizeMake(aExampleLabel:getDimensions().width, 0))
    aExampleLabel:setString("Example")
    local aBaseHeight = aExampleLabel.refCocosObj:getTexture():getContentSize().height
    local aDistance
    local personalReports = ArenaManager:sharedManager():getArenaPersonalReports()
    local reportsNum = #personalReports
    for i = 1, reportsNum do
      local aString = personalReports[i].reportDes
      aExampleLabel:setString(aString)
      local aMultiple = aExampleLabel.refCocosObj:getTexture():getContentSize().height / aBaseHeight
      local aGroup
      local aLabel
      if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
        aGroup = builder:build("popup_arena_battleReport_entry1")
        aLabel = aGroup:getChildByName("txt_popup_arena_battleReport_entry_txt1"):getChildByName("txt_popup_arena_battleReport_entry_txt1")
        aDistance = 20
        --print("1__" .. aGroup:getGroupBounds().size.height)
      elseif aMultiple > (2.0 - 0.1) and aMultiple < (2.0 + 0.1) then
        aGroup = builder:build("popup_arena_battleReport_entry2")
        aLabel = aGroup:getChildByName("txt_popup_arena_battleReport_entry_txt2"):getChildByName("txt_popup_arena_battleReport_entry_txt2")
        aDistance = 20
        --print("2__" .. aGroup:getGroupBounds().size.height)
      elseif aMultiple > (3.0 - 0.1) and aMultiple < (3.0 + 0.1) then
        aGroup = builder:build("popup_arena_battleReport_entry3")
        aLabel = aGroup:getChildByName("txt_popup_arena_battleReport_entry_txt3"):getChildByName("txt_popup_arena_battleReport_entry_txt3")
        --print("3__" .. aGroup:getGroupBounds().size.height)
        aDistance = 20
      end
      --print("__" .. aStartPosY)
      aGroup:setPosition(ccp(aStartPosX, aStartPosY))
      aStartPosY = aStartPosY - aGroup:getGroupBounds().size.height - aDistance
      aLabel:setString(aString)
      aGroup:getChildByName("txt_popup_arena_battleReport_entry_time"):getChildByName("txt_popup_arena_battleReport_entry_time"):setString(personalReports[i].reportDate)
      aScrollView:addChild(aGroup)
      table.insert(aScrollContentList, aGroup)
    end
    --print(aStartPosY)
    aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
    if aStartPosY < 0 then
      for _, aGroup in ipairs(aScrollContentList) do
        aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
      end
      aScrollView:setContentOffset(ccp(0, aStartPosY), false)
    end
    
    
    self:resetTab()
    
    self.tempLayer:setScale(0.1)
end

function ArenaReportFoePanel:resetTab()
  if self.selectedTabIndex == 0 then
    self.reportTabDisplay:getChildByName("normal"):setVisible(false)
    self.reportTabDisplay:getChildByName("btn"):setVisible(true)
    self.reportTab:setEnable(false)
    self.foeTabDisplay:getChildByName("normal"):setVisible(true)
    self.foeTabDisplay:getChildByName("btn"):setVisible(false)
    self.foeTab:setEnable(true)
    self.reportsScrollView:setVisible(true)
  else
    self.reportTabDisplay:getChildByName("normal"):setVisible(true)
    self.reportTabDisplay:getChildByName("btn"):setVisible(false)
    self.reportTab:setEnable(true)
    self.foeTabDisplay:getChildByName("normal"):setVisible(false)
    self.foeTabDisplay:getChildByName("btn"):setVisible(true)
    self.foeTab:setEnable(false)
    self.reportsScrollView:setVisible(false)
  end
end

function ArenaReportFoePanel:scaleIn()
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

function ArenaReportFoePanel:showPanel()
  self.tempLayer:setScale(1.0)
end