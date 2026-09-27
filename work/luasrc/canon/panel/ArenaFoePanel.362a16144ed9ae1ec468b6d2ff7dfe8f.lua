require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "hecore.ui.TableView"
require "canon.request.ChallengeArenaRequest"

local table_width = 586
local table_height = 373
local table_posX = 66
local table_posY = 482
local item_width = 161
local item_height = 373
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function closeAction(evt)
  local aPanel = evt.context
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  aPanel:removeFromParentAndCleanup(true)
end

--
-- ArenaFoePanel
--

ArenaFoePanel = class(Layer)

function ArenaFoePanel:ctor()
    self.container = nil
end

function ArenaFoePanel:create( container)
    local s = ArenaFoePanel.new()
    self.container = container
    s:initLayer()
    return s
end

function ArenaFoePanel:initLayer()
    ArenaFoePanel.super.initLayer(self)
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena.json")
    self.panelUI = builder:build("popup_arena_enemyList") 
    self.tempLayer:addChild(self.panelUI)
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
    closeButton:addEventListener( Events.kStart, closeAction, self )
    
    local function foeTabAction(evt)
      self.selectedTabIndex = 1
      self:resetTab()
    end
    local function reportTabAction(evt)
      --[[
      self.selectedTabIndex = 0
      self:resetTab()
      ]]
      local aPanel = ArenaReportFoePanel:create(self.container)
      self.container:addChild(aPanel)
      aPanel:showPanel()
      self.container:removeChild(self)
    end
    self.selectedTabIndex = 1
    self.reportTabDisplay = self.panelUI:getChildByName("btn_arena_reportTab")
    self.reportTabDisplay:getChildByName("txt_arena_reportTab"):setString(Localization:getInstance():getText("arena_reportTab"))
    self.reportTab = Button:create(self.reportTabDisplay)
    self.reportTab:addEventListener( Events.kStart, reportTabAction, self )
    self.foeTabDisplay = self.panelUI:getChildByName("btn_arena_enemyListTab")
    self.foeTabDisplay:getChildByName("txt_arena_enemyListTab"):setString(Localization:getInstance():getText("arena_enemyListTab"))
    self.foeTab = Button:create(self.foeTabDisplay)
    self.foeTab:addEventListener( Events.kStart, foeTabAction, self )
    
    self.foeTableView = self:createFoeTableView()
    self.panelUI:addChildAt(self.foeTableView, 4)
    self.foeTableView:reloadData()
    
    self:resetTab()
    
    self.tempLayer:setScale(0.1)
end

function ArenaFoePanel:createFoeTableView()
  local aArenaFoePanel = self
  local FoeTableViewRenderer = class(TableViewRenderer)
  function FoeTableViewRenderer:ctor(width, height)
    self.list = ArenaManager:sharedManager().arenaPersonalFoes.foes
    if not self.list then
      self.list = {}
    end
  end
  function FoeTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena.json")
    local aCell = builder:build("popup_arena_enemyList_entry")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(-1001)
    local aRankNumLabel = aCell:getChildByName("txt_arena_myRank_num")
    aRankNumLabel:setTag(-10)
    aRankNumLabel = aRankNumLabel:getChildByName("font")
    aRankNumLabel:setTag(-10)
    local aCardDisplay = aCell:getChildByName("frameM")
    aCardDisplay:setTag(-11)
    aCardDisplay:setVisible(false)
    local aNameLabel = aCell:getChildByName("txt_arena_playerName")
    aNameLabel:setTag(-12)
    aNameLabel = aNameLabel:getChildByName("txt_arena_playerName")
    aNameLabel:setTag(-10)
    local aLevelNameLabel = aCell:getChildByName("txt_arena_lv_num")
    aLevelNameLabel:setTag(-13)
    aLevelNameLabel = aLevelNameLabel:getChildByName("font")
    aLevelNameLabel:setTag(-10)
    local aButtonDisplay = aCell:getChildByName("btn_arena_revengeBtn")
    aButtonDisplay:setTag(-14)
    --[[
    local challangeButton = Button:create(aButtonDisplay)
    challangeButton:addEventListener(Events.kStart, challangeButtonSelected, self)
    ]]
    aButtonDisplay:getChildByName("txt_arena_revengeBtn"):setString(Localization:getInstance():getText("arena_revengeBtn"))
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
  end
  function FoeTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-11)
    local card3_co = getSmallCanonCardNoInfoByMetaId(self.list[index + 1].mainCardMetaId)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.7)
    aCell:addChild(card3_co.refCocosObj)
    card3_co:setTag(-20)
    
    local aRankNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
    aRankNumLabel = tolua.cast(aRankNumLabel, "CCLabelTTF")
    aRankNumLabel:setString(string.format("%d", self.list[index + 1].rank))
    local aNameLabel = aCell:getChildByTag(-12):getChildByTag(-10)
    aNameLabel = tolua.cast(aNameLabel, "CCLabelTTF")
    aNameLabel:setString(self.list[index + 1].nickName)
    local aLevelNameLabel = aCell:getChildByTag(-13):getChildByTag(-10)
    aLevelNameLabel = tolua.cast(aLevelNameLabel, "CCLabelTTF")
    aLevelNameLabel:setString(string.format("%d", self.list[index + 1].level))
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    --print("HAHA " .. aIndex)
    local newCell = self.foeTableView:cellAtIndex(aIndex - 1)
    local buttonDisplay = newCell:getChildByTag(-1001):getChildByTag(-14)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    --print(posInCell.x, posInCell.y)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      local function challengeArenaSucceed(evt)
        Director:sharedDirector():replaceScene(TestBattleScene:create(evt.data, BattleBackType.kArenaScene, BattleEnterEnum.kArenaScene))
      end
      local params = {matchedUid = ArenaManager:sharedManager().arenaPersonalFoes.foes[aIndex].uid, revenge = true}
      local request = ChallengeArenaRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.ChallengeArenaSucceed, challengeArenaSucceed)
      request:start()
    end
  end
  local renderer = FoeTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height)
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:setPageEnabled(true)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function ArenaFoePanel:resetTab()
  if self.selectedTabIndex == 0 then
    self.reportTabDisplay:getChildByName("normal"):setVisible(false)
    self.reportTabDisplay:getChildByName("btn"):setVisible(true)
    self.reportTab:setEnable(false)
    self.foeTabDisplay:getChildByName("normal"):setVisible(true)
    self.foeTabDisplay:getChildByName("btn"):setVisible(false)
    self.foeTab:setEnable(true)
    --self.foeTableView:setVisible(false)
  else
    self.reportTabDisplay:getChildByName("normal"):setVisible(true)
    self.reportTabDisplay:getChildByName("btn"):setVisible(false)
    self.reportTab:setEnable(true)
    self.foeTabDisplay:getChildByName("normal"):setVisible(false)
    self.foeTabDisplay:getChildByName("btn"):setVisible(true)
    self.foeTab:setEnable(false)
    --self.foeTableView:setVisible(true)
  end
end

function ArenaFoePanel:scaleIn()
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

function ArenaFoePanel:showPanel()
  self.tempLayer:setScale(1.0)
end