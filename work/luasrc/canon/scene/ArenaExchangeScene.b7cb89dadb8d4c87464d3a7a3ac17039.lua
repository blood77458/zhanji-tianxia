require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.data.MetaManager"
require "canon.models.ArenaManager"
require "canon.request.ExchangeTrainDanRequest"
require "canon.request.GainRankFirstRewardRequest"
require "canon.panel.MessageBoxPanel"
require "canon.customUI.SuspensionLabel"
require "canon.panel.ExchangeStoneResultPanel"

local exchangeTable_width = 705
local exchangeTable_height = 725
local exchangeItem_width = 690
local exchangeItem_height = 160
local exchangeTable_posX = 15
local exchangeTable_posY = 155
local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function rankButtonSelected(evt)
  evt.context.tagDisplayList[2][1]:setVisible(false)
  evt.context.tagDisplayList[2][2]:setVisible(true)
  -- evt.context.tagDisplayList[2][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[1][1]:setVisible(true)
  evt.context.tagDisplayList[1][2]:setVisible(false)
  evt.context.tagDisplayList[1][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRankScene, {enterScene="ArenaExchangeScene",returnScene=nil,params={ignoreAction = true}})
end

local function reportButtonSelected(evt)
  evt.context.tagDisplayList[2][1]:setVisible(false)
  evt.context.tagDisplayList[2][2]:setVisible(true)
  -- evt.context.tagDisplayList[2][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[3][1]:setVisible(true)
  evt.context.tagDisplayList[3][2]:setVisible(false)
  evt.context.tagDisplayList[3][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaReportScene, {enterScene="ArenaExchangeScene",returnScene=nil,params={ignoreAction = true}})
end

local function ruleButtonSelected(evt)
  evt.context.tagDisplayList[2][1]:setVisible(false)
  evt.context.tagDisplayList[2][2]:setVisible(true)
  -- evt.context.tagDisplayList[2][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[4][1]:setVisible(true)
  evt.context.tagDisplayList[4][2]:setVisible(false)
  evt.context.tagDisplayList[4][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRuleScene, {enterScene="ArenaExchangeScene",returnScene=nil,params={ignoreAction = true}})
end

--
-- ArenaExchangeScene
--

ArenaExchangeScene = class(BaseUIScene)

function ArenaExchangeScene:ctor()
	
end

function ArenaExchangeScene:create(ignoreAction)
  local s = ArenaExchangeScene.new()
  self.ignoreAction = ignoreAction
  s:initScene()
  return s
end

function ArenaExchangeScene:onInit()
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
  self.uiGroup1 = ui:getChildByName("arena_bg_arena")
  self.uiGroup2 = ui:getChildByName("arena_title")
  self.uiGroup3 = ui:getChildByName("arena_txt_arena_battleReport")
  self.uiGroup4 = ui:getChildByName("arena_arenaTab")
  self.uiGroup5 = ui:getChildByName("arena_bg_home_broadcast")
  self.uiGroup6 = builder:build("arenna_xian")
  self.uiGroup6:setPosition(ccp(visibleSize.width / 2.0, 880))
  ui:addChild(self.uiGroup6)
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
  rewardButtonDisplay:getChildByName("disable"):setVisible(false)
  local rewardButtonLabel = rewardButtonDisplay:getChildByName("txt_arena_exchangeTab")
  rewardButtonLabel:setString(Localization:getInstance():getText("arena_exchangeTab"))
  local reportButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_battleReportTab")
  reportButtonDisplay:getChildByName("btn"):setVisible(false)
  local reportButtonLabel = reportButtonDisplay:getChildByName("txt_btn_arena_battleReportTab")
  reportButtonLabel:setString(Localization:getInstance():getText("arena_battleReportTab"))
  -- reportButtonLabel:setColor(ccc3(0,0,0))
  local reportButton = Button:create(reportButtonDisplay)
  reportButton:addEventListener(Events.kStart, reportButtonSelected, self)
  local ruleButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_ruleTab")
  ruleButtonDisplay:getChildByName("btn"):setVisible(false)
  local ruleButtonLabel = ruleButtonDisplay:getChildByName("txt_arena_ruleTab")
  ruleButtonLabel:setString(Localization:getInstance():getText("arena_ruleTab"))
  -- ruleButtonLabel:setColor(ccc3(0,0,0))
  local ruleButton = Button:create(ruleButtonDisplay)
  ruleButton:addEventListener(Events.kStart, ruleButtonSelected, self)
  
  self.tagDisplayList = {{rankButtonDisplay:getChildByName("btn"), rankButtonDisplay:getChildByName("disable"), rankButtonLabel}, {rewardButtonDisplay:getChildByName("btn"), rewardButtonDisplay:getChildByName("disable"), rewardButtonLabel}, {reportButtonDisplay:getChildByName("btn"), reportButtonDisplay:getChildByName("disable"), reportButtonLabel}, {ruleButtonDisplay:getChildByName("btn"), ruleButtonDisplay:getChildByName("disable"), ruleButtonLabel}}
  
  local aArenaManager = ArenaManager:sharedManager()
  
  self.uiGroup4:getChildByName("arena_txt_myarena"):getChildByName("txt_myarena"):setString(Localization:getInstance():getText("arena_myRank"))
  self.uiGroup4:getChildByName("arena_txt_myarena_num"):getChildByName("font"):setString(string.format("%d", aArenaManager.arenaData.sharkArenaRank.rank))
  self.uiGroup4:getChildByName("arena_txt_myscore"):getChildByName("txt_myscore"):setString(Localization:getInstance():getText("arena_myPoints"))
  local aArenaScoreLabel = self.uiGroup4:getChildByName("arena_txt_myscore_num"):getChildByName("font")
  aArenaScoreLabel:setString(string.format("%d", aArenaManager.arenaData.sharkArenaRank.score))
  self.uiGroup4:getChildByName("arena_txt_count"):setVisible(false)
  self.uiGroup4:getChildByName("arena_txt_count_num"):setVisible(false)
  self.uiGroup4:getChildByName("arena_btn_arenaTab_buy"):setVisible(false)
  
  self.updateArenaScoreLabelFunc = function (event)
    aArenaScoreLabel:setString(string.format("%d", aArenaManager.arenaData.sharkArenaRank.score))
  end
  aArenaManager:addEventListener(DataChangedNotifyEnum.ArenaScoreDataChanged,self.updateArenaScoreLabelFunc)
  
  self.exchangeTableView = self:createExchangeTableView()
  self:addChild(self.exchangeTableView)
  self.exchangeTableView:reloadData()
  local originalOffset = self.exchangeTableView:getContentOffset()
  self.originalOffsetY = originalOffset.y
  
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

function ArenaExchangeScene:onExit()
  ArenaManager:sharedManager():removeEventListener(DataChangedNotifyEnum.ArenaScoreDataChanged, self.updateArenaScoreLabelFunc)
end

function ArenaExchangeScene:onUpdate(dt)
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

function ArenaExchangeScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #ArenaManager:sharedManager().arenaExchangeData do
    if (self.newOffsetY - self.originalOffsetY) < i * exchangeItem_height and (self.newOffsetY - self.originalOffsetY + exchangeTable_height + exchangeItem_height) > i * exchangeItem_height then
      table.insert(self.animatedCells, self.exchangeTableView:cellAtIndex(i - 1))
    end
  end
end

function ArenaExchangeScene:createExchangeTableView()
  local cellTag = 1024
  local buttonTag = {-15,-16}
  local aExchangeScene = self
  local ExchangeTableViewRenderer = class(TableViewRenderer)
  function ExchangeTableViewRenderer:ctor(width, height)
    self.list = ArenaManager:sharedManager().arenaExchangeData
  end
  function ExchangeTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena_new.json")
    local aCell = builder:build("arena_exchangeTab_entry")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local aItemDisplay = aCell:getChildByName("arena_normal_card_small")
    aItemDisplay:setTag(-10)
    aItemDisplay:setVisible(false)
    local aTitleLabel = aCell:getChildByName("arena_txt_arena_playerName")
    aTitleLabel:setTag(-11)
    aTitleLabel = aTitleLabel:getChildByName("txt_arena_playerName")
    aTitleLabel:setTag(-10)
    local aDescriptionLabel = aCell:getChildByName("arena_txt_arenaExchange_propDesc")
    aDescriptionLabel:setTag(-12)
    aDescriptionLabel = aDescriptionLabel:getChildByName("txt_arenaExchange_propDesc")
    aDescriptionLabel:setTag(-10)
    local aExchangeTitleLabel = aCell:getChildByName("arena_txt_arenaTap_integral")
    aExchangeTitleLabel:setTag(-13)
    aExchangeTitleLabel = aExchangeTitleLabel:getChildByName("txt_arenaTap_integral")
    aExchangeTitleLabel:setString(Localization:getInstance():getText("arena_exchangePoints"))
    local aConsumedPointsLabel = aCell:getChildByName("arena_txt_arena_lv_num")
    aConsumedPointsLabel:setTag(-14)
    aConsumedPointsLabel = aConsumedPointsLabel:getChildByName("font")
    aConsumedPointsLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("arena_btn_arena_challengeBtn")
    aButtonDisplay:setTag(-15)
    local aButtonLabel = aButtonDisplay:getChildByName("txt_arena_challengeBtn")
    aButtonLabel:setTag(-10)
    aButtonLabel:setString(Localization:getInstance():getText("arena_exchangeBtn"))
    aButtonDisplay = aButtonDisplay:getChildByName("btn")
    aButtonDisplay:setTag(-11)
    aButtonDisplay = aCell:getChildByName("arena_btn_arena_counterfireBtn")
    aButtonDisplay:setTag(-16)
    local aButtonLabel = aButtonDisplay:getChildByName("txt_arena_counterfireBtn")
    aButtonLabel:setTag(-10)
    aButtonLabel:setString(Localization:getInstance():getText("arena_claimBtn"))
    local aButtonPic = aButtonDisplay:getChildByName("btn")
    aButtonPic:setTag(-11)
    aButtonPic = aButtonDisplay:getChildByName("disable")
    aButtonPic:setTag(-12)
    
  end
  function ExchangeTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aTitleLabel = aCell:getChildByTag(-11):getChildByTag(-10)
    setNodeText(aTitleLabel, string.format("%sx%d", self.list[index + 1].name, self.list[index + 1].amount))
    local aDescriptionLabel = aCell:getChildByTag(-12):getChildByTag(-10)
    setNodeText(aDescriptionLabel, self.list[index + 1].desc)
    local aExchangeTitleLabel = aCell:getChildByTag(-13)
    local aConsumedPointsLabel = aCell:getChildByTag(-14):getChildByTag(-10)
    local aButtonDisplay = aCell:getChildByTag(-15)
    local aButtonDisplay2 = aCell:getChildByTag(-16)
    local aButtonLabel2 = aButtonDisplay2:getChildByTag(-10)
    -- aButtonLabel2 = tolua.cast(aButtonLabel2, "CCLabelTTF")
    local aButtonPic2 = aButtonDisplay2:getChildByTag(-11)
    local aButtonPic3 = aButtonDisplay2:getChildByTag(-12)
    if self.list[index + 1].eType == ArenaExchangeTypeEnum.kReward then
      aExchangeTitleLabel:setVisible(false)
      aConsumedPointsLabel:setVisible(false)
      aButtonDisplay:setVisible(false)
      aButtonDisplay2:setVisible(true)
      if self.list[index + 1].rank < ArenaManager:sharedManager().arenaData.sharkArenaRank.bestRank then
        --aButtonLabel2:setColor(ccc3(128,128,128))
        aButtonPic2:setVisible(false)
        aButtonPic3:setVisible(true)
      else
        --aButtonLabel2:setColor(ccc3(255,255,255))
        aButtonPic2:setVisible(true)
        aButtonPic3:setVisible(false)
      end
    else
      aExchangeTitleLabel:setVisible(true)
      aConsumedPointsLabel:setVisible(true)
      setNodeText(aConsumedPointsLabel, string.format("%d", self.list[index + 1].score))
      aButtonDisplay:setVisible(true)
      aButtonDisplay2:setVisible(false)
    end
    
    local aPropItem = aCell:getChildByTag(-20)
    if aPropItem then
      aPropItem:removeFromParentAndCleanup(true)
    end
    local aItemDisplay =  aCell:getChildByTag(-10)
    aPropItem = CanonItem:create()
    aPropItem:loadByMetaId(self.list[index + 1].itemMetaId)
    aPropItem:setScale(0.9)
    aPropItem:setPosition(ccp(aItemDisplay:getPositionX(), aItemDisplay:getPositionY()))
    aCell:addChild(aPropItem.refCocosObj, 100)
    aPropItem:setTag(-20)
    aPropItem:dispose()
  end

  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.exchangeTableView:cellAtIndex(aIndex - 1)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local exchangeDisplay = buttonDisplay:getChildByTag(-11)
    local buttonDisplay2 = newCell:getChildByTag(cellTag):getChildByTag(-16)
    local exchangeDisplay2 = buttonDisplay2:getChildByTag(-11)
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    --print(posInCell.x, posInCell.y)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if not buttonDisplay:isVisible() then
        if exchangeDisplay2:isVisible() then
          self:gainRankFirstReward(ArenaManager:sharedManager().arenaExchangeData[aIndex].rank)
        end
      else
        self:exchangeTrainDan(ArenaManager:sharedManager().arenaExchangeData[aIndex].eId)
      end
    end
  end
  
  local renderer = ExchangeTableViewRenderer.new(exchangeItem_width, exchangeItem_height)
  local aTableView = TableView:create(renderer, exchangeTable_width, exchangeTable_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)
  aTableView:setPosition(ccp(exchangeTable_posX, exchangeTable_posY))
  return aTableView
end

function ArenaExchangeScene:panelDismiss()
  self.exchangeTableView:setTouchEnabled(true)
end

function ArenaExchangeScene:setTableViewsEnabledInner(aEnabled)
  self.exchangeTableView:setTouchEnabled(aEnabled)
end

function ArenaExchangeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ArenaExchangeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
  self.exchangeTableView.refCocosObj:setScrollBar(nil)
  self.exchangeTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaExchangeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.exchangeTableView:getContentOffset().y
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
  
  self.exchangeTableView:setPositionX(self.exchangeTableView:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.exchangeTableView:runAction(CCSequence:create(arr))
  --[[
  ]]
  
  for _, aChild in pairs(self.uiGroup6.list) do
    aChild:setOpacity(0)
    aChild:runAction(CCFadeIn:create(enter_animation_duration))
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
    
    self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
    self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  else
    for _, aChild in pairs(self.uiGroup4.list) do
      for _, aSecondChild in pairs(aChild.list) do
        aSecondChild:setOpacity(0)
        aSecondChild:runAction(CCFadeIn:create(enter_animation_duration))
      end
    end
  end
end

function ArenaExchangeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  self.exchangeTableView.refCocosObj:setScrollBar(CCScale9Sprite:create("pic/scroll.png"))
  self.exchangeTableView.refCocosObj:setScrollTrack(CCScale9Sprite:create("pic/scroll.png"))
  self.exchangeTableView:reloadData()
  
	if Get_ShareData("New_User_Guide_Running") == 1 then
		local checkGuideHandle = nil
		local function checkGuide()
			if Get_ShareData("New_User_Guide_Running") ~= 1 then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(checkGuideHandle)
				if self.exchangeTableView and not self.exchangeTableView.isDisposed then
					self.exchangeTableView:setDragEnabled(true)
				end
			end
		end
		checkGuideHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkGuide, 0, false)
	end
end

function ArenaExchangeScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ArenaExchangeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
  self.exchangeTableView.refCocosObj:setScrollBar(nil)
  self.exchangeTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaExchangeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.exchangeTableView:getContentOffset().y
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
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.exchangeTableView:runAction(CCSequence:create(arr))
  
  for _, aChild in pairs(self.uiGroup6.list) do
    aChild:runAction(CCFadeOut:create(enter_animation_cell_duration))
  end
  for _, aChild in pairs(self.uiGroup7.list) do
    aChild:runAction(CCFadeOut:create(enter_animation_cell_duration))
  end
  
  if not self.ignoreAction then
    self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.reportLabel:runAction(CCFadeOut:create(enter_animation_duration))
    
    self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  else
    for _, aChild in pairs(self.uiGroup4.list) do
      for _, aSecondChild in pairs(aChild.list) do
        aSecondChild:runAction(CCFadeOut:create(enter_animation_duration))
      end
    end
  end
end

function ArenaExchangeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ArenaExchangeScene:back()
  self.ignoreAction = false
  self:replaceScene(CompeteScene)
end

function ArenaExchangeScene:gainRankFirstReward(aRank)
  if BagCalcManager.isFull() then
    self:showBagFullPanel()
    return
  end
  
  local function gainRankFirstRewardSucceed(event)
    --gainRankFirstReward successfully
    local aReward = event.data.rewards[1]
    local aName = ""
    local aAmount = aReward.amount
    if aReward.itemType == ResourceEnum.CARD then
      aName = Localization:getInstance():getText(MetaManager.card_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.EQUIP then
      aName = Localization:getInstance():getText(MetaManager.equip_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.PROP then
      aName = Localization:getInstance():getText(MetaManager.prop_meta[aReward.metaId].name)
    end
    local aContent = Localization:getInstance():getText("arena_claimRewardSuccess", {num = aAmount, itemname = aName})
    SuspensionLabel:showContent(self, aContent)
    ArenaManager:sharedManager():gainRankFirstReward(aRank, event.data.rewards)
    local aOffsetY = self.exchangeTableView:getContentOffset().y
    self.exchangeTableView:reloadData()
    aOffsetY = aOffsetY + exchangeItem_height
    self.originalOffsetY = self.originalOffsetY + exchangeItem_height
    if exchangeItem_height * #ArenaManager:sharedManager().arenaExchangeData < exchangeTable_height then
      aOffsetY = exchangeTable_height - exchangeItem_height * #ArenaManager:sharedManager().arenaExchangeData
    elseif aOffsetY > 0 then
      aOffsetY = 0
    end
    self.exchangeTableView:setContentOffset(ccp(0, aOffsetY), false)
  end
  local function gainRankFirstRewardFailed(event)
    if event.data.retCode == 710516 then
      self:showBagFullPanel()
    elseif event.data.retCode == 712408 then  --already gained
      self:showAlreadyGainRankRewardPanel()
    elseif event.data.retCode == 712410 then  --can't gain
      self:showCannotGainRankRewardPanel()
    end
  end
  local params = {rank = aRank}
  local request = GainRankFirstRewardRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.GainRankFirstRewardSucceed, gainRankFirstRewardSucceed)
  request:addEventListener(RequestNotifyEnum.GainRankFirstRewardFailed, gainRankFirstRewardFailed)
  request:start()
end

function ArenaExchangeScene:exchangeTrainDan(aEId)
  if BagCalcManager.isFull() then
    self:showBagFullPanel()
    return
  end
  
  local function exchangeTrainDanSucceed(event)
    --exchange successfully
    local aReward = event.data.rewards[1]
    local aName = ""
    local aAmount = aReward.amount
    if aReward.itemType == ResourceEnum.CARD then
      aName = Localization:getInstance():getText(MetaManager.card_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.EQUIP then
      aName = Localization:getInstance():getText(MetaManager.equip_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.PROP then
      aName = Localization:getInstance():getText(MetaManager.prop_meta[aReward.metaId].name)
    end
    ArenaManager:sharedManager():exchangeSucceedByArenaScore(event.data.requisite, event.data.rewards)
    
    self:showExchangeResultPanel({num = aAmount, itemname = aName, exchangeType = aEId})
    
  end
  local function exchangeTrainDanFailed(event)
    if event.data.retCode == 712403 then
      local aPanel = MessageBoxPanel:create(self, MessageBoxType.kArenaScoreNotEnough)
      self:addChild(aPanel)
      aPanel:scaleIn()
      self.exchangeTableView:setTouchEnabled(false)
    elseif event.data.retCode == 710516 then
      -- local aPanel = MessageBoxPanel:create(self, MessageBoxType.kBagFullForArenaExchange)
      -- self:addChild(aPanel)
      -- aPanel:scaleIn()
      NewPackageFullPanel:show()
      self.exchangeTableView:setTouchEnabled(false)
    end
  end
  local params = {exchangeType = aEId}
  local request = ExchangeTrainDanRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.ExchangeTrainDanSucceed, exchangeTrainDanSucceed)
  request:addEventListener(RequestNotifyEnum.ExchangeTrainDanFailed, exchangeTrainDanFailed)
  request:start()
end

function ArenaExchangeScene:showExchangeResultPanel(args)
  local aPanel = ExchangeStoneResultPanel:create(self, args)
  self:addChild(aPanel)
  aPanel:scaleIn()
  self.exchangeTableView:setTouchEnabled(false)
end

function ArenaExchangeScene:moveToCardTrainScene()
  self.ignoreAction = false
  local arg = {enterScene="ArenaExchangeScene",returnScene="ArenaExchangeScene",params={isCardTrain = true}}
  self:replaceScene(BackpackScene , arg)
end

function ArenaExchangeScene:showBagFullPanel()
  -- local aPanel = MessageBoxPanel:create(self, MessageBoxType.kBagFullForArenaReward)
  -- self:addChild(aPanel)
  -- aPanel:scaleIn()
  NewPackageFullPanel:show()
  self.exchangeTableView:setTouchEnabled(false)
end

function ArenaExchangeScene:showAlreadyGainRankRewardPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kAlreadyGainForArenaReward)
  self:addChild(aPanel)
  aPanel:scaleIn()
  self.exchangeTableView:setTouchEnabled(false)
end

function ArenaExchangeScene:showCannotGainRankRewardPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCannotGainForArenaReward)
  self:addChild(aPanel)
  aPanel:scaleIn()
  self.exchangeTableView:setTouchEnabled(false)
end
