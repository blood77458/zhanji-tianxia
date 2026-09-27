require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.data.MetaManager"
require "canon.models.ArenaManager"
require "canon.models.CommonManager"

local arenaTable_width = 711
local arenaTable_height = 804
local arenaTable_posX = 9
local arenaTable_posY = 155
local arenaItem_width = 702
local arenaItem_height = 127
local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function rankButtonSelected(evt)
  evt.context.tagDisplayList[3][1]:setVisible(false)
  evt.context.tagDisplayList[3][2]:setVisible(true)
  -- evt.context.tagDisplayList[3][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[1][1]:setVisible(true)
  evt.context.tagDisplayList[1][2]:setVisible(false)
  evt.context.tagDisplayList[1][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRankScene, {enterScene="ArenaReportScene",returnScene=nil,params={ignoreAction = true}})
end

local function exchangeButtonSelected(evt)
  evt.context.tagDisplayList[3][1]:setVisible(false)
  evt.context.tagDisplayList[3][2]:setVisible(true)
  -- evt.context.tagDisplayList[3][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[2][1]:setVisible(true)
  evt.context.tagDisplayList[2][2]:setVisible(false)
  evt.context.tagDisplayList[2][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaExchangeScene, {enterScene="ArenaReportScene",returnScene=nil,params={ignoreAction = true}})
end

local function ruleButtonSelected(evt)
  evt.context.tagDisplayList[3][1]:setVisible(false)
  evt.context.tagDisplayList[3][2]:setVisible(true)
  -- evt.context.tagDisplayList[3][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[4][1]:setVisible(true)
  evt.context.tagDisplayList[4][2]:setVisible(false)
  evt.context.tagDisplayList[4][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRuleScene, {enterScene="ArenaReportScene",returnScene=nil,params={ignoreAction = true}})
end

--
-- ArenaReportScene
--

ArenaReportScene = class(BaseUIScene)

function ArenaReportScene:ctor()
	
end

function ArenaReportScene:create(argv)
  local s = ArenaReportScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.ignoreAction = self.argv.params.ignoreAction
  s:initScene()
  return s
end

function ArenaReportScene:onInit()
	BaseUIScene.initBackGround(self)
  
  --ÐÂUI¼ÓºÚµ×
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)
    
  self.title = Localization:getInstance():getText("arena_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/arena_new.json")
  builder.useArtLabelTTF = true
  local ui = builder:build("arena")
  self:addChild(ui)
  ui:getChildByName("arena_exchangeTab"):setVisible(false)
  ui:getChildByName("arena_arenaTab"):setVisible(false)
  self.uiGroup1 = ui:getChildByName("arena_bg_arena")
  self.uiGroup2 = ui:getChildByName("arena_title")
  self.uiGroup3 = ui:getChildByName("arena_txt_arena_battleReport")
  self.uiGroup5 = ui:getChildByName("arena_bg_home_broadcast")
  self.uiGroup7 = builder:build("arenna_xian")
  self.uiGroup7:setPosition(ccp(visibleSize.width / 2.0, 154))
  ui:addChild(self.uiGroup7)
  
  local rankButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_arenaTab")
  rankButtonDisplay:getChildByName("btn"):setVisible(false)
  local rankButtonLabel = rankButtonDisplay:getChildByName("txt_arena_arenaTab")
  rankButtonLabel:setString(Localization:getInstance():getText("arena_arenaTab"))
  -- rankButtonLabel:setColor(ccc3(0,0,0))
  local rankButton = Button:create(rankButtonDisplay)
  rankButton:addEventListener(Events.kStart, rankButtonSelected, self)
  local rewardButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_exchangeTab")
  rewardButtonDisplay:getChildByName("btn"):setVisible(false)
  local rewardButtonLabel = rewardButtonDisplay:getChildByName("txt_arena_exchangeTab")
  rewardButtonLabel:setString(Localization:getInstance():getText("arena_exchangeTab"))
  -- rewardButtonLabel:setColor(ccc3(0,0,0))
  local exchangeButton = Button:create(rewardButtonDisplay)
  exchangeButton:addEventListener(Events.kStart, exchangeButtonSelected, self)
  local reportButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_battleReportTab")
  reportButtonDisplay:getChildByName("disable"):setVisible(false)
  local reportButtonLabel = reportButtonDisplay:getChildByName("txt_btn_arena_battleReportTab")
  reportButtonLabel:setString(Localization:getInstance():getText("arena_battleReportTab"))
  local ruleButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_ruleTab")
  ruleButtonDisplay:getChildByName("btn"):setVisible(false)
  local ruleButtonLabel = ruleButtonDisplay:getChildByName("txt_arena_ruleTab")
  ruleButtonLabel:setString(Localization:getInstance():getText("arena_ruleTab"))
  -- ruleButtonLabel:setColor(ccc3(0,0,0))
  local ruleButton = Button:create(ruleButtonDisplay)
  ruleButton:addEventListener(Events.kStart, ruleButtonSelected, self)
  
  self.tagDisplayList = {{rankButtonDisplay:getChildByName("btn"), rankButtonDisplay:getChildByName("disable"), rankButtonLabel}, {rewardButtonDisplay:getChildByName("btn"), rewardButtonDisplay:getChildByName("disable"), rewardButtonLabel}, {reportButtonDisplay:getChildByName("btn"), reportButtonDisplay:getChildByName("disable"), reportButtonLabel}, {ruleButtonDisplay:getChildByName("btn"), ruleButtonDisplay:getChildByName("disable"), ruleButtonLabel}}
  
  
  
  
  
  self.longOneUI = builder:build("arena_txt_popup_arena_battleReport_entry_txt3")
  self.longOneLabel = self.longOneUI:getChildByName("txt_popup_arena_battleReport_entry_txt3")
  self.exampleLongWidth = self.longOneLabel:getDimensions().width
  self.exampleFontName = self.longOneLabel:getFontName()
  self.exampleFontSize = self.longOneLabel:getFontSize()
  self.exampleFontColor = self.longOneLabel:getColor()
  self.ttfLongLabel = TextField:create("Example", self.exampleFontName, self.exampleFontSize, CCSizeMake(self.exampleLongWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  self.baseHeight = self.ttfLongLabel:getTexture():getContentSize().height
  
  self.shortOneUI = builder:build("arena_txt_popup_arena_battleReport_entry_txt1")
  self.shortOneLabel = self.shortOneUI:getChildByName("txt_popup_arena_battleReport_entry_txt1")
  self.exampleShortWidth = self.shortOneLabel:getDimensions().width
  self.ttfShortLabel = TextField:create("Example", self.exampleFontName, self.exampleFontSize, CCSizeMake(self.exampleShortWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  
  self.reports = ArenaManager:sharedManager():getArenaPersonalReports()
  self.reportTableView = self:createReportTableView()
  ui:addChild(self.reportTableView)
  self.reportTableView:reloadData()
  local originalOffset = self.reportTableView:getContentOffset()
  self.originalOffsetY = originalOffset.y
  
  if #self.reports == 0 then
    self.uiGroup6 = builder:build("arena_no_report_label")
    ui:addChild(self.uiGroup6)
    self.uiGroup6:getChildByName("no_report_label"):setString(Localization:getInstance():getText("arena_noReportTxt"))
  end
  
  local aArenaManager = ArenaManager:sharedManager()
  self.reportLabel = self.uiGroup3:getChildByName("txt_arena_battleReport")
  self.originalPosX = self.reportLabel:getPositionX() + visibleSize.width
  self.reportLabel:setString(aArenaManager.lastString or "")
  local currentPosX
  if aArenaManager.lastString then
    currentPosX = aArenaManager.lastPosX
  else
    currentPosX = self.originalPosX
    aArenaManager.lastPosX = currentPosX
  end
  self.reportLabel:setPositionX(currentPosX)
  
  BaseUIScene.onInit(self)
end

function ArenaReportScene:dispose()
  self.longOneUI:dispose()
  self.shortOneUI:dispose()
  self.ttfLongLabel:dispose()
  self.ttfShortLabel:dispose()
  ArenaReportScene.super.dispose(self)
end

function ArenaReportScene:onUpdate(dt)
  dt = 0.016
  local aArenaManager = ArenaManager:sharedManager()
  
  if aArenaManager.shouldStayInArena and (aArenaManager.durationInArena > 5.8) then
      return
  end
  
  if aArenaManager.durationInArena < 0 then
    if #aArenaManager.arenaReports > 0 then
      aArenaManager.lastString = aArenaManager:popoutReport()
    else
      aArenaManager.lastString = ""
    end
    --aArenaManager.lastString = "GHHHHHG"
    self.reportLabel:setString(aArenaManager.lastString)
    aArenaManager.durationInArena = 0
  end
  
  aArenaManager.durationInArena = aArenaManager.durationInArena + dt
  
  if aArenaManager.durationInArena <= 0.8 then
    self.reportLabel:setPositionX(aArenaManager.lastPosX - visibleSize.width / 0.8 * dt)
    aArenaManager.lastPosX = aArenaManager.lastPosX - visibleSize.width / 0.8 * dt
  elseif aArenaManager.durationInArena <= 5.8 then
    self.reportLabel:setPositionX(self.originalPosX - visibleSize.width)
    aArenaManager.lastPosX = self.originalPosX - visibleSize.width
  elseif (aArenaManager.durationInArena > 5.8) and (aArenaManager.durationInArena <= 6.6) then
    self.reportLabel:setPositionX(aArenaManager.lastPosX - visibleSize.width / 0.8 * dt)
    aArenaManager.lastPosX = aArenaManager.lastPosX - visibleSize.width / 0.8 * dt
  elseif aArenaManager.durationInArena <= 7.1 then
    self.reportLabel:setPositionX(self.originalPosX - visibleSize.width * 2)
    aArenaManager.lastPosX = self.originalPosX - visibleSize.width * 2
  elseif aArenaManager.durationInArena > 7.1 then
    self.reportLabel:setPositionX(self.originalPosX)
    aArenaManager.lastPosX = self.originalPosX
    aArenaManager.durationInArena = -1
  end
  
  
end

function ArenaReportScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #self.reports do
    if (self.newOffsetY - self.originalOffsetY) < i * arenaItem_height and (self.newOffsetY - self.originalOffsetY + arenaTable_height + arenaItem_height) > i * arenaItem_height then
      table.insert(self.animatedCells, self.reportTableView:cellAtIndex(i - 1))
    end
  end
end

function ArenaReportScene:createReportTableView()
  local cellTag = 1024
  local buttonTag = -15
  local aArenaReportScene = self
  local ArenaTableViewRenderer = class(TableViewRenderer)
  function ArenaTableViewRenderer:ctor(width, height)
    self.list = aArenaReportScene.reports
  end
  function ArenaTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena_new.json")
    local aCell = builder:build("arena_battleReport")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(cellTag)
    local aTimeLabel = aCell:getChildByName("arena_txt_popup_arena_battleReport_entry_time")
    aTimeLabel:setTag(-10)
    aTimeLabel = aTimeLabel:getChildByName("txt_popup_arena_battleReport_entry_time")
    aTimeLabel:setTag(-10)
    
    local aLongTwoLabel = aCell:getChildByName("arena_txt_popup_arena_battleReport_entry_txt4")
    aLongTwoLabel:setTag(-11)
    aLongTwoLabel:setVisible(false)
    aLongTwoLabel = aLongTwoLabel:getChildByName("txt_popup_arena_battleReport_entry_txt4")
    aLongTwoLabel:setTag(-10)
    local aLongOneLabel = aCell:getChildByName("arena_txt_popup_arena_battleReport_entry_txt3")
    aLongOneLabel:setTag(-12)
    aLongOneLabel:setVisible(false)
    aLongOneLabel = aLongOneLabel:getChildByName("txt_popup_arena_battleReport_entry_txt3")
    aLongOneLabel:setTag(-10)
    local aShortTwoLabel = aCell:getChildByName("arena_txt_popup_arena_battleReport_entry_txt2")
    aShortTwoLabel:setTag(-13)
    aShortTwoLabel:setVisible(false)
    aShortTwoLabel = aShortTwoLabel:getChildByName("txt_popup_arena_battleReport_entry_txt2")
    aShortTwoLabel:setTag(-10)
    local aShortOneLabel = aCell:getChildByName("arena_txt_popup_arena_battleReport_entry_txt1")
    aShortOneLabel:setTag(-14)
    aShortOneLabel:setVisible(false)
    aShortOneLabel = aShortOneLabel:getChildByName("txt_popup_arena_battleReport_entry_txt1")
    aShortOneLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("arena_btn_arena_counterfireBtn")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("txt_arena_counterfireBtn")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("arena_revengeBtn"))
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
  end
  function ArenaTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aTempLabel1 = aCell:getChildByTag(-20)
    local aTempLabel2 = aCell:getChildByTag(-21)
    if aTempLabel1 then
      aTempLabel1:removeFromParentAndCleanup(true)
    end
    if aTempLabel2 then
      aTempLabel2:removeFromParentAndCleanup(true)
    end
    local aTimeLabel = aCell:getChildByTag(-10):getChildByTag(-10)
    setNodeText(aTimeLabel, self.list[index + 1].reportDate)
    local aLongTwoLabel = aCell:getChildByTag(-11)
    local aLongOneLabel = aCell:getChildByTag(-12)
    local aShortTwoLabel = aCell:getChildByTag(-13)
    local aShortOneLabel = aCell:getChildByTag(-14)
    local aButtonDisplay = aCell:getChildByTag(-15)
    local aResultLabel
    local aString
    local aLabelWidth
    if self.list[index + 1].rankChanged then
      aString = self.list[index + 1].reportDes .. self.list[index + 1].resultRank
    else
      aString = self.list[index + 1].reportDes
    end
    
    local whetherTwoLine
    local twoLineTempLabel
    
    if (not self.list[index + 1].initiative) and ArenaManager:sharedManager():containInFoes(self.list[index + 1].uid) and (not self.list[index + 1].result) then
      aButtonDisplay:setVisible(true)
      
      aArenaReportScene.ttfShortLabel:setString(aString)
      local aMultiple = aArenaReportScene.ttfShortLabel:getTexture():getContentSize().height / aArenaReportScene.baseHeight
      if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
        aResultLabel = aShortOneLabel
        whetherTwoLine = false
      else
        aResultLabel = aShortTwoLabel
        whetherTwoLine = true
        twoLineTempLabel = aArenaReportScene.ttfShortLabel
      end
      aLabelWidth = aArenaReportScene.exampleShortWidth
    else
      aButtonDisplay:setVisible(false)
      
      aArenaReportScene.ttfLongLabel:setString(aString)
      local aMultiple = aArenaReportScene.ttfLongLabel:getTexture():getContentSize().height / aArenaReportScene.baseHeight
      if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
        aResultLabel = aLongOneLabel
        whetherTwoLine = false
      else
        aResultLabel = aLongTwoLabel
        whetherTwoLine = true
        twoLineTempLabel = aArenaReportScene.ttfLongLabel
      end
      aLabelWidth = aArenaReportScene.exampleLongWidth
    end
    
    local aPosX = aResultLabel:getPositionX()
    local aPosY = aResultLabel:getPositionY()
    
    local aLabelString1
    local aLabelString2
    local aLabelColor1
    local aLabelColor2
    if self.list[index + 1].rankChanged then
      if whetherTwoLine then
        aLabelString1 = self.list[index + 1].reportDesPart1 .. self.list[index + 1].reportDesPart2
      else
        aLabelString1 = self.list[index + 1].reportDes
      end
      
      aLabelColor1 = aArenaReportScene.exampleFontColor
      aLabelString2 = aLabelString1 .. self.list[index + 1].resultRank
      aLabelColor2 = ccc3(255,0,0)
    else
      aLabelString1 = self.list[index + 1].reportDes
      aLabelColor1 = aArenaReportScene.exampleFontColor
      aLabelString2 = self.list[index + 1].reportDes
      aLabelColor2 = ccc3(255,0,0)
    end
    local aReplaceLabel2 = TextField:create(aLabelString2, aArenaReportScene.exampleFontName, aArenaReportScene.exampleFontSize, CCSizeMake(aLabelWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    local aReplaceLabel1 = TextField:create(aLabelString1, aArenaReportScene.exampleFontName, aArenaReportScene.exampleFontSize, CCSizeMake(aLabelWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    --aPosY = aPosY - aReplaceLabel2:getTexture():getContentSize().height
    
    aReplaceLabel1:setColor(aLabelColor1)
    aReplaceLabel1:setAnchorPoint(ccp(0, 1))
    aReplaceLabel1:setPosition(ccp(aPosX, aPosY))
    aReplaceLabel2:setColor(aLabelColor2)
    aReplaceLabel2:setAnchorPoint(ccp(0, 1))
    aReplaceLabel2:setPosition(ccp(aPosX, aPosY))
    
    aCell:addChild(aReplaceLabel2.refCocosObj, 20)
    aReplaceLabel2:setTag(-20)
    aReplaceLabel2:dispose()
    aCell:addChild(aReplaceLabel1.refCocosObj, 20)
    aReplaceLabel1:setTag(-21)
    aReplaceLabel1:dispose()
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.reportTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    --print(posInCell.x, posInCell.y)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if buttonDisplay:isVisible() then
        self:revengeChallenge(self.reports[aIndex].uid)
      end
    end
  end
  local renderer = ArenaTableViewRenderer.new(arenaItem_width, arenaItem_height)
  local aTableView = TableView:create(renderer, arenaTable_width, arenaTable_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(arenaTable_posX, arenaTable_posY))
  return aTableView
end

function ArenaReportScene:panelDismiss()
  self.reportTableView:setTouchEnabled(true)
end

function ArenaReportScene:setTableViewsEnabledInner(aEnabled)
  self.reportTableView:setTouchEnabled(aEnabled)
end

function ArenaReportScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ArenaReportScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
  self.reportTableView.refCocosObj:setScrollBar(nil)
  self.reportTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaReportScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.reportTableView:getContentOffset().y
  self:generateAnimatedCells()
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = enter_animation_duration - enter_animation_cell_duration
  else
    aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    aCell:setPositionX(aCell:getPositionX() - visibleSize.width)
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  self.reportTableView:setPositionX(self.reportTableView:getPositionX() - visibleSize.width)
  --self.reportTableView:runAction(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.reportTableView:runAction(CCSequence:create(arr))
  
  if self.uiGroup6 then
    self.uiGroup6:setPositionX(self.uiGroup6:getPositionX() - visibleSize.width)
    self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  end
  
  for _, aChild in pairs(self.uiGroup7.list) do
    aChild:setOpacity(0)
    aChild:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  if not self.ignoreAction then
    self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
    self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
    self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  end
end

function ArenaReportScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  self.reportTableView.refCocosObj:setScrollBar(CCScale9Sprite:create("pic/scroll.png"))
  self.reportTableView.refCocosObj:setScrollTrack(CCScale9Sprite:create("pic/scroll.png"))
  self.reportTableView:reloadData()
end

function ArenaReportScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ArenaReportScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
  self.reportTableView.refCocosObj:setScrollBar(nil)
  self.reportTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaReportScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.reportTableView:getContentOffset().y
  self:generateAnimatedCells()
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = enter_animation_duration - enter_animation_cell_duration
  else
    aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(-visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  --self.reportTableView:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.reportTableView:runAction(CCSequence:create(arr))
  
  if self.uiGroup6 then
    self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  end
  
  for _, aChild in pairs(self.uiGroup7.list) do
    aChild:runAction(CCFadeOut:create(enter_animation_cell_duration))
  end
  
  if not self.ignoreAction then
    self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.reportLabel:runAction(CCFadeOut:create(enter_animation_duration))
  end
end

function ArenaReportScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ArenaReportScene:back()
  self.ignoreAction = false
  self:replaceScene(CompeteScene)
end

function ArenaReportScene:revengeChallenge(aUid)
  local epConsumed = DataManager.GameMetaData.battleSettingConfig.arenaBattleEventPointConsumed
  if CalculationManager.calcComplex_getEPNow() < epConsumed then
    self:showNotEnoughEventPointPanel()
  elseif BagCalcManager.isFull() then
    local aContent = Localization:getInstance():getText("bagFull_move")
    -- SuspensionLabel:showContent(self, aContent)
    NewPackageFullPanel:show()
  else
    local function challengeArenaSucceed(evt)
      RewardManager:getReward({{itemType = ResourceEnum.EVENTPOINT, amount = -epConsumed}})
      Director:sharedDirector():replaceScene(BattleScene:create(evt.data, BattleBackType.kArenaScene, BattleEnterEnum.kArenaScene, 2))
    end
    local function challengeArenaFailed(evt)
      if evt.data.retCode == 712411 then
        self:showChallengeNumLimitPanel()
      elseif evt.data.retCode == 710515 then
        self:showNotEnoughEventPointPanel()
      elseif evt.data.retCode == 712414 then
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("arena_opponentInBattle")
        self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = evt.data.retCode})
        self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    local params = {matchedUid = aUid, revenge = true}
    local request = ChallengeArenaRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.ChallengeArenaSucceed, challengeArenaSucceed)
    request:addEventListener(RequestNotifyEnum.ChallengeArenaFailed, challengeArenaFailed)
    request:start()
  end
end

function ArenaReportScene:showNotEnoughEventPointPanel()
  local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
  if hasProp then
    self:showUseEventPointProptPanel(eventPointPropList)
  else
    self:showEventPointLimitPanel()
  end
end

function ArenaReportScene:showUseEventPointProptPanel(eventPointPropList)
  local function callback(aEventPointPropId)
    self:recoveryEventPoint(aEventPointPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, eventPointPropList, callback)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaReportScene:recoveryEventPoint(aEventPointPropId)
  local function usePropSucceed(event)
    local aReward = {
      {	itemType = ResourceEnum.PROP, metaId = aEventPointPropId, amount = -1
      },
      {	itemType = ResourceEnum.EVENTPOINT,
        amount = event.data.rewards[1].amount,
      }
    }
    RewardManager:getReward(aReward)
    CanonPlayEffect("music/sfx_engly_lvup.wav")
    SuspensionLabel:showContent(self, getTextByKey("propInfo_eventPointReplenished"))
  end
  
  local function usePropFailed(event)
    if event.data.retCode == 712309 then
      local function closeCanonMessageBox()
      end
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("propInfo_eventPointFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 712301 then
      local function closeCanonMessageBox()
      end
      local aPropMetaConfig = MetaManager.prop_meta[aEventPointPropId]
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  local request = UsePropRequest.new( {propId = aEventPointPropId, amount = 1}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
	request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
	request:start()
end

function ArenaReportScene:showEventPointLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaReportScene:showMainActorPanel()
  self.reportTableView:setTouchEnabled(false)
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end

function ArenaReportScene:showChallengeNumLimitPanel()
  self.reportTableView:setTouchEnabled(false)
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kArenaChallengeNumLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end