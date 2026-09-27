require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.ScrollView"
require "canon.data.MetaManager"
require "canon.models.ArenaManager"

local scroll_width = 720
local scroll_height = 800
local scroll_posX = 0
local scroll_posY = 160
local scroll_startPosY = 785
local overlap_height = 2
local enter_animation_duration = 0.3
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function rankButtonSelected(evt)
  evt.context.tagDisplayList[4][1]:setVisible(false)
  evt.context.tagDisplayList[4][2]:setVisible(true)
  -- evt.context.tagDisplayList[4][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[1][1]:setVisible(true)
  evt.context.tagDisplayList[1][2]:setVisible(false)
  evt.context.tagDisplayList[1][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRankScene, {enterScene="ArenaReportScene",returnScene=nil,params={ignoreAction = true}})
end

local function exchangeButtonSelected(evt)
  evt.context.tagDisplayList[4][1]:setVisible(false)
  evt.context.tagDisplayList[4][2]:setVisible(true)
  -- evt.context.tagDisplayList[4][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[2][1]:setVisible(true)
  evt.context.tagDisplayList[2][2]:setVisible(false)
  evt.context.tagDisplayList[2][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaExchangeScene, {enterScene="ArenaReportScene",returnScene=nil,params={ignoreAction = true}})
end

local function reportButtonSelected(evt)
  evt.context.tagDisplayList[4][1]:setVisible(false)
  evt.context.tagDisplayList[4][2]:setVisible(true)
  -- evt.context.tagDisplayList[4][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[3][1]:setVisible(true)
  evt.context.tagDisplayList[3][2]:setVisible(false)
  evt.context.tagDisplayList[3][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaReportScene, {enterScene="ArenaExchangeScene",returnScene=nil,params={ignoreAction = true}})
end

--
-- ArenaRuleScene
--

ArenaRuleScene = class(BaseUIScene)

function ArenaRuleScene:ctor()
	
end

function ArenaRuleScene:create(ignoreAction)
  local s = ArenaRuleScene.new()
  self.ignoreAction = ignoreAction
  s:initScene()
  return s
end

function ArenaRuleScene:onInit()
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
  reportButtonDisplay:getChildByName("btn"):setVisible(false)
  local reportButtonLabel = reportButtonDisplay:getChildByName("txt_btn_arena_battleReportTab")
  reportButtonLabel:setString(Localization:getInstance():getText("arena_battleReportTab"))
  -- reportButtonLabel:setColor(ccc3(0,0,0))
  local reportButton = Button:create(reportButtonDisplay)
  reportButton:addEventListener(Events.kStart, reportButtonSelected, self)
  local ruleButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_ruleTab")
  ruleButtonDisplay:getChildByName("disable"):setVisible(false)
  local ruleButtonLabel = ruleButtonDisplay:getChildByName("txt_arena_ruleTab")
  ruleButtonLabel:setString(Localization:getInstance():getText("arena_ruleTab"))
  
  self.tagDisplayList = {{rankButtonDisplay:getChildByName("btn"), rankButtonDisplay:getChildByName("disable"), rankButtonLabel}, {rewardButtonDisplay:getChildByName("btn"), rewardButtonDisplay:getChildByName("disable"), rewardButtonLabel}, {reportButtonDisplay:getChildByName("btn"), reportButtonDisplay:getChildByName("disable"), reportButtonLabel}, {ruleButtonDisplay:getChildByName("btn"), ruleButtonDisplay:getChildByName("disable"), ruleButtonLabel}}
  
  local aScrollContentList = {}
  local aScrollView = ScrollView:create(scroll_width, scroll_height)
  self.scrollView = aScrollView
  aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
  aScrollView:setDirection(kCCScrollViewDirectionVertical)
  ui:addChildAt(aScrollView, 10)
  local aTitle = builder:build("arena_rule_title")
  local aTitlePosX = visibleSize.width / 2.0 - aTitle:getGroupBounds().size.width / 2.0
  aTitle:setPosition(ccp(aTitlePosX, scroll_startPosY))
  local aTitleLabel = aTitle:getChildByName("txt_arena_battleRule"):getChildByName("txt_arena_battleRule")
  aTitleLabel:setString(Localization:getInstance():getText("arena_battleRule"))
  aScrollView:addChild(aTitle)
  table.insert(aScrollContentList, aTitle)
  
  local aStartPosX = aTitlePosX
  local aStartPosY = scroll_startPosY - aTitle:getGroupBounds().size.height + overlap_height
  
  self.exampleGroup = builder:build("arena_ruleTxt1")
  local aExampleLabel = self.exampleGroup:getChildByName("txt_arena_ruleTxt1")
  --local aExamplePosX = aExampleLabel:getPositionX()
  --local aExamplePosY = aExampleLabel:getPositionY()
  aExampleLabel = aExampleLabel:getChildByName("txt_arena_ruleTxt1")
  local aExampleWidth = aExampleLabel:getDimensions().width
  local aExampleFontName = aExampleLabel:getFontName()
  local aExampleFontSize = aExampleLabel:getFontSize()
  local aExampleFontColor = aExampleLabel:getColor()
  
  self.ttfLabel = TextField:create("Example", aExampleFontName, aExampleFontSize, CCSizeMake(aExampleWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  local aBaseHeight = self.ttfLabel:getTexture():getContentSize().height
  
  local aList = {}
  for i = 2, 7 do
    local aString
    if i == 4 then
      aString = Localization:getInstance():getText(string.format("arena_ruleTxt%d", i), {num = DataManager.GameMetaData.battleSettingConfig.arenaNormalVictoryHighRankScore})
    elseif i == 5 then
      aString = Localization:getInstance():getText(string.format("arena_ruleTxt%d", i), {num = DataManager.GameMetaData.battleSettingConfig.arenaNormalVictoryLowRankScore})
    elseif i == 6 then
      aString = Localization:getInstance():getText(string.format("arena_ruleTxt%d", i), {num = DataManager.GameMetaData.battleSettingConfig.arenaLossActiveScore})
    else
      aString = Localization:getInstance():getText(string.format("arena_ruleTxt%d", i))
    end
    table.insert(aList, aString)
  end
  
  local aExamplePosX
  local aExamplePosY
  for i = 1, 2 do
    local aString = aList[i]
    --[[
    self.ttfLabel:setString(aString)
    local aMultiple = self.ttfLabel:getTexture():getContentSize().height / aBaseHeight
    local aGroup
    local aLabel
    if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt1")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt1")
    elseif aMultiple > (2.0 - 0.1) and aMultiple < (2.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt2")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt2")
    elseif aMultiple > (3.0 - 0.1) and aMultiple < (3.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt3")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt3")
    end
    --aGroup:setPosition(ccp(aStartPosX, aStartPosY))
    
    aGroup:setVisible(false)
    
    aExamplePosX = aLabel:getPositionX()
    aExamplePosY = aLabel:getPositionY()]]
    
    local aReplaceLabel = TextField:create(aString, aExampleFontName, aExampleFontSize, CCSizeMake(aExampleWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    local aHeight = aReplaceLabel:getTexture():getContentSize().height
    local aTexture = CCTextureCache:sharedTextureCache():addImage("scene/arena_rule_cell.png")
    local aTextureWidth = aTexture:getContentSize().width
    local aTextureHeight = aTexture:getContentSize().height
    local aTempPosY = aStartPosY
    while true do
      if aHeight <= 0 then
        break
      end
      local bg_cc
      local bg
      if aHeight >= aTextureHeight then
        bg_cc = CCSprite:create("scene/arena_rule_cell.png")
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0, 1))
        aTempPosY = aTempPosY - aTextureHeight
        bg:setPosition(ccp(aStartPosX, aTempPosY))
        aScrollView:addChild(bg)
        table.insert(aScrollContentList, bg)
        aHeight = aHeight - aTextureHeight
      else
        bg_cc = CCSprite:create("scene/arena_rule_cell.png", CCRectMake(0,0,aTextureWidth, aHeight))
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0, 1))
        aTempPosY = aTempPosY - aHeight
        bg:setPosition(ccp(aStartPosX, aTempPosY))
        aScrollView:addChild(bg)
        table.insert(aScrollContentList, bg)
        aHeight = 0
      end
    end
    
    aReplaceLabel:setColor(aExampleFontColor)
    aReplaceLabel:setAnchorPoint(ccp(0, 0))
    aStartPosY = aStartPosY - aReplaceLabel:getTexture():getContentSize().height
    aReplaceLabel:setPosition(ccp(aStartPosX + 30, aStartPosY))
    aScrollView:addChild(aReplaceLabel)
    table.insert(aScrollContentList, aReplaceLabel)
  end
  local aRewardRuleTitle = builder:build("arena_bg_arena_rule_3")
  aRewardRuleTitle:setPosition(ccp(aStartPosX, aStartPosY))
  aStartPosY = aStartPosY - aRewardRuleTitle:getGroupBounds().size.height + overlap_height
  aRewardRuleTitle:getChildByName("txt_arena_battleRule"):getChildByName("txt_arena_battleRule"):setString(Localization:getInstance():getText("arena_rewardRule"))
  aScrollView:addChild(aRewardRuleTitle)
  table.insert(aScrollContentList, aRewardRuleTitle)
  aDistance = 0
  for i = 3, 6 do
    local aString = aList[i]
    --[[
    self.ttfLabel:setString(aString)
    local aMultiple = self.ttfLabel:getTexture():getContentSize().height / aBaseHeight
    local aGroup
    local aLabel
    if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt1")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt1")
    elseif aMultiple > (2.0 - 0.1) and aMultiple < (2.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt2")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt2")
    elseif aMultiple > (3.0 - 0.1) and aMultiple < (3.0 + 0.1) then
      aGroup = builder:build("arena_ruleTxt3")
      aLabel = aGroup:getChildByName("txt_arena_ruleTxt3")
    end
    aGroup:setPosition(ccp(aStartPosX, aStartPosY))
    aStartPosY = aStartPosY - aGroup:getGroupBounds().size.height + overlap_height
    aLabel:setVisible(false)
    
    aExamplePosX = aLabel:getPositionX()
    aExamplePosY = aLabel:getPositionY()]]
    local aReplaceLabel = TextField:create(aString, aExampleFontName, aExampleFontSize, CCSizeMake(aExampleWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    
    local aHeight = aReplaceLabel:getTexture():getContentSize().height
    local aTexture = CCTextureCache:sharedTextureCache():addImage("scene/arena_rule_cell.png")
    local aTextureWidth = aTexture:getContentSize().width
    local aTextureHeight = aTexture:getContentSize().height
    local aTempPosY = aStartPosY
    while true do
      if aHeight <= 0 then
        break
      end
      local bg_cc
      local bg
      if aHeight >= aTextureHeight then
        bg_cc = CCSprite:create("scene/arena_rule_cell.png")
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0, 1))
        aTempPosY = aTempPosY - aTextureHeight
        bg:setPosition(ccp(aStartPosX, aTempPosY))
        aScrollView:addChild(bg)
        table.insert(aScrollContentList, bg)
        aHeight = aHeight - aTextureHeight
      else
        bg_cc = CCSprite:create("scene/arena_rule_cell.png", CCRectMake(0,0,aTextureWidth, aHeight))
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0, 1))
        aTempPosY = aTempPosY - aHeight
        bg:setPosition(ccp(aStartPosX, aTempPosY))
        aScrollView:addChild(bg)
        table.insert(aScrollContentList, bg)
        aHeight = 0
      end
    end
    
    aReplaceLabel:setColor(aExampleFontColor)
    aReplaceLabel:setAnchorPoint(ccp(0, 0))
    aStartPosY = aStartPosY - aReplaceLabel:getTexture():getContentSize().height
    aReplaceLabel:setPosition(ccp(aStartPosX + 30, aStartPosY))
    aScrollView:addChild(aReplaceLabel)
    table.insert(aScrollContentList, aGroup)
  end
  local aTailTitle = builder:build("arena_bg_arena_rule_4")
  aTailTitle:setPosition(ccp(aStartPosX, aStartPosY))
  aStartPosY = aStartPosY - aTailTitle:getGroupBounds().size.height - overlap_height
  aScrollView:addChild(aTailTitle)
  table.insert(aScrollContentList, aTailTitle)
  
  aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
  if aStartPosY < 0 then
    for _, aGroup in ipairs(aScrollContentList) do
      aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
    end
    aScrollView:setContentOffset(ccp(0, aStartPosY), false)
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

function ArenaRuleScene:dispose()
  self.exampleGroup:dispose()
  self.ttfLabel:dispose()
  ArenaRuleScene.super.dispose(self)
end

function ArenaRuleScene:onUpdate(dt)
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

function ArenaRuleScene:setTableViewsEnabledInner(aEnabled)
  self.scrollView:setTouchEnabled(aEnabled)
end

function ArenaRuleScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ArenaRuleScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function ArenaRuleScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.scrollView:setPositionX(self.scrollView:getPositionX() - visibleSize.width)
  --self.scrollView:runAction(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.scrollView:runAction(CCSequence:create(arr))
  
  if not self.ignoreAction then
    self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
    self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
    self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  end
end

function ArenaRuleScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function ArenaRuleScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ArenaRuleScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function ArenaRuleScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  --self.scrollView:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.scrollView:runAction(CCSequence:create(arr))
  
  if not self.ignoreAction then
    self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.reportLabel:runAction(CCFadeOut:create(enter_animation_duration))
  end
end

function ArenaRuleScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ArenaRuleScene:back()
  self.ignoreAction = false
  self:replaceScene(CompeteScene)
end