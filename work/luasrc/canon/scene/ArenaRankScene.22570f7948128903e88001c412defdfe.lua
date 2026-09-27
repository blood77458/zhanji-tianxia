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
require "canon.request.ChallengeArenaRequest"
require "canon.request.BuyChallengeNumRequest"
require "canon.panel.UserDetailPanel"
require "canon.customUI.SuspensionLabel"
require "canon.scene.BattleScene"

local arenaTable_width = 705
local arenaTable_height = 725
local arenaTable_posX = 15
local arenaTable_posY = 155
local arenaItem_width = 690
local arenaItem_height = 160
local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function exchangeButtonSelected(evt)
  evt.context.tagDisplayList[1][1]:setVisible(false)
  evt.context.tagDisplayList[1][2]:setVisible(true)
  -- evt.context.tagDisplayList[1][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[2][1]:setVisible(true)
  evt.context.tagDisplayList[2][2]:setVisible(false)
  evt.context.tagDisplayList[2][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaExchangeScene, {enterScene="ArenaRankScene",returnScene=nil,params={ignoreAction = true}})
end

local function reportButtonSelected(evt)
  evt.context.tagDisplayList[1][1]:setVisible(false)
  evt.context.tagDisplayList[1][2]:setVisible(true)
  -- evt.context.tagDisplayList[1][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[3][1]:setVisible(true)
  evt.context.tagDisplayList[3][2]:setVisible(false)
  evt.context.tagDisplayList[3][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaReportScene, {enterScene="ArenaRankScene",returnScene=nil,params={ignoreAction = true}})
end

local function ruleButtonSelected(evt)
  evt.context.tagDisplayList[1][1]:setVisible(false)
  evt.context.tagDisplayList[1][2]:setVisible(true)
  -- evt.context.tagDisplayList[1][3]:setColor(ccc3(0,0,0))
  evt.context.tagDisplayList[4][1]:setVisible(true)
  evt.context.tagDisplayList[4][2]:setVisible(false)
  evt.context.tagDisplayList[4][3]:setColor(ccc3(255,255,255))
  evt.context.ignoreAction = true
  evt.context:replaceScene(ArenaRuleScene, {enterScene="ArenaRankScene",returnScene=nil,params={ignoreAction = true}})
end

local function purchaseButtonSelected(evt)
  local aArenaRankScene = evt.context
  aArenaRankScene:purchaseChallengeNumButtonTapped()
end

--
-- ArenaRankScene
--

ArenaRankScene = class(BaseUIScene)

function ArenaRankScene:ctor()
	self.curSceneEnum = SceneEnum.ArenaRankScene
end

function ArenaRankScene:create(argv)
  local s = ArenaRankScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.ignoreAction = self.argv.params.ignoreAction
  if not self.ignoreAction then
    ArenaManager:sharedManager():startTime()
  end
  s:initScene()
  return s
end

function ArenaRankScene:onInit()
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
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
  rankButtonDisplay:getChildByName("disable"):setVisible(false)
  local rankButtonLabel = rankButtonDisplay:getChildByName("txt_arena_arenaTab")
  rankButtonLabel:setString(Localization:getInstance():getText("arena_arenaTab"))
  local rewardButtonDisplay = self.uiGroup2:getChildByName("arena_btn_arena_exchangeTab")
  rewardButtonDisplay:getChildByName("btn"):setVisible(false)
  local rewardButtonLabel = rewardButtonDisplay:getChildByName("txt_arena_exchangeTab")
  rewardButtonLabel:setString(Localization:getInstance():getText("arena_exchangeTab"))
  --[[print(rewardButtonLabel:getFontName())
  rewardButtonLabel:setFontName("Algerian")
  print(rewardButtonLabel:getFontName())]]
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
  self.uiGroup4:getChildByName("arena_txt_myscore_num"):getChildByName("font"):setString(string.format("%d", aArenaManager.arenaData.sharkArenaRank.score))
  self.uiGroup4:getChildByName("arena_txt_count"):getChildByName("txt_count"):setString(Localization:getInstance():getText("arena_challengeTimesRemain"))
  local aVipSettingConfig = MetaManager.vip_setting[DataManager.getGameInitData().sharkUser.vipLevel]
  local leftChallengeCount = aArenaManager.arenaData.arenaBoughtNum * DataManager.GameMetaData.battleSettingConfig.arenaChallengeChancesPerPurchase + aVipSettingConfig.arenaChallengeChancesPerDay - aArenaManager.arenaData.arenaChallengeNum
  local currentTotalChallengeCount = aVipSettingConfig.arenaChallengeChancesPerDay
  self.challengeNumLabel = self.uiGroup4:getChildByName("arena_txt_count_num"):getChildByName("txt_count_num")
  self.challengeNumLabel:setString(string.format("%d/%d", leftChallengeCount, currentTotalChallengeCount))
  local purchaseButtonDisplay = self.uiGroup4:getChildByName("arena_btn_arenaTab_buy")
  if leftChallengeCount > 0 then
    purchaseButtonDisplay:setVisible(false)
  else
    purchaseButtonDisplay:getChildByName("txt_arenaTab_buy"):setString(Localization:getInstance():getText("arena_purchaseBtn"))
    local purchaseButton = Button:create(purchaseButtonDisplay)
    purchaseButton:addEventListener(Events.kStart, purchaseButtonSelected, self)
  end
  self.purchaseButtonDisplay = purchaseButtonDisplay
  
  self.arenaTableView = self:createArenaTableView()
  ui:addChild(self.arenaTableView)
  self.arenaTableView:reloadData()
  local originalOffset = self.arenaTableView:getContentOffset()
  self.originalOffsetY = originalOffset.y
  local aOffsetY = (aArenaManager.currentPlayerIndex - 1) * arenaItem_height - (arenaTable_height - arenaItem_height)
  if aOffsetY < 0 then
    aOffsetY = 0
  end
  self.originalResetOffsetY = aOffsetY + originalOffset.y
  self.arenaTableView:setContentOffset(ccp(0, self.originalResetOffsetY), false)
  
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

function ArenaRankScene:onUpdate(dt)
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

function ArenaRankScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #ArenaManager:sharedManager().arenaData.sharkArenaPlayers do
    if (self.newOffsetY - self.originalOffsetY) < i * arenaItem_height and (self.newOffsetY - self.originalOffsetY + arenaTable_height + arenaItem_height) > i * arenaItem_height then
      table.insert(self.animatedCells, self.arenaTableView:cellAtIndex(i - 1))
    end
  end
end

function ArenaRankScene:createArenaTableView()
  local cellTag = 1024
  local buttonTag = {-15,-16}
  local aArenaScene = self
  local ArenaTableViewRenderer = class(TableViewRenderer)
  function ArenaTableViewRenderer:ctor(width, height)
    self.list = ArenaManager:sharedManager().arenaData.sharkArenaPlayers
  end
  function ArenaTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/arena_new.json")
    local aCell = builder:build("arena_arenaTab_entry")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(cellTag)
    local aRankLabel = aCell:getChildByName("arena_txt_arena_rankTableTxt"):getChildByName("txt_arena_rankTableTxt")
    aRankLabel:setString(Localization:getInstance():getText("arena_rankTableTxt"))
    local aRankNumLabel = aCell:getChildByName("arena_txt_arenaTap_rank_num")
    aRankNumLabel:setTag(-10)
    aRankNumLabel = aRankNumLabel:getChildByName("font")
    aRankNumLabel:setTag(-10)
    local aRewardLabel = aCell:getChildByName("arena_txt_arenaTap_integral"):getChildByName("txt_arenaTap_integral")
    aRewardLabel:setString(Localization:getInstance():getText("arena_myRankReward"))
    local aRewardNumLabel = aCell:getChildByName("arena_txt_arena_reward_num")
    aRewardNumLabel:setTag(-11)
    aRewardNumLabel = aRewardNumLabel:getChildByName("font")
    aRewardNumLabel:setTag(-10)
    local aCardDisplay = aCell:getChildByName("arena_normal_card_small")
    aCardDisplay:setTag(-12)
    aCardDisplay:setVisible(false)
    local aNameLabel = aCell:getChildByName("arena_txt_arena_playerName")
    aNameLabel:setTag(-13)
    aNameLabel = aNameLabel:getChildByName("txt_arena_playerName")
    aNameLabel:setTag(-10)
    local aLevelNameLabel = aCell:getChildByName("arena_txt_arena_lv_num")
    aLevelNameLabel:setTag(-14)
    aLevelNameLabel = aLevelNameLabel:getChildByName("font")
    aLevelNameLabel:setTag(-10)
    local aButtonDisplay = aCell:getChildByName("arena_btn_arena_challengeBtn")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("txt_arena_challengeBtn")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("arena_challengeBtn"))
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
    aButtonDisplay = aCell:getChildByName("arena_btn_arena_counterfireBtn")
    aButtonDisplay:setTag(-16)
    local challangeLabel = aButtonDisplay:getChildByName("txt_arena_counterfireBtn")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("arena_revengeBtn"))
    challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
    local othersFlag = aCell:getChildByName("yellow9_panel")
    othersFlag:setTag(-17)
    local selfFlag = aCell:getChildByName("arena_personal")
    selfFlag:setTag(-18)
    local huawen1 = aCell:getChildByName("arena_huawen_1")
    huawen1:setTag(-7)
    local huawen2 = aCell:getChildByName("arena_huawen_2")
    huawen2:setTag(-8)

    local aUnionLabel = aCell:getChildByName("txt_guild_namae")
    aUnionLabel:setTag(-19)
    aUnionLabel = aUnionLabel:getChildByName("txt")
    aUnionLabel:setTag(-10)
    
    local firstTag = aCell:getChildByName("icn_paiming1")
    firstTag:setTag(-31)
    local secondTag = aCell:getChildByName("icn_paiming2")
    secondTag:setTag(-32)
    local thirdTag = aCell:getChildByName("icn_paiming3")
    thirdTag:setTag(-33)
  end
  function ArenaTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    local firstTag = aCell:getChildByTag(-31)
    local secondTag = aCell:getChildByTag(-32)
    local thirdTag = aCell:getChildByTag(-33)
    firstTag:setVisible(false)
    secondTag:setVisible(false)
    thirdTag:setVisible(false)
    if self.list[index + 1].rank > 1 - 0.01 and self.list[index + 1].rank < 1 + 0.01 then
      firstTag:setVisible(true)
    elseif self.list[index + 1].rank > 2 - 0.01 and self.list[index + 1].rank < 2 + 0.01 then
      secondTag:setVisible(true)
    elseif self.list[index + 1].rank > 3 - 0.01 and self.list[index + 1].rank < 3 + 0.01 then
      thirdTag:setVisible(true)
    end
    
    local aRankNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
    setNodeText(aRankNumLabel, string.format("%d", self.list[index + 1].rank))

    local aUnionLabel = aCell:getChildByTag(-19):getChildByTag(-10)
    if self.list[index + 1].unionName then
      aUnionLabel:setVisible(true)
      setNodeText(aUnionLabel, string.format("%s", Localization:getInstance():getText("union_name_txt", {name = self.list[index + 1].unionName})))--otherUnionName
    else
      aUnionLabel:setVisible(false)
    end

    local aRewardNumLabel = aCell:getChildByTag(-11)
    aRewardNumLabel = aRewardNumLabel:getChildByTag(-10)
    local aArenaRankScoreConfig
    for _, temp in ipairs(MetaManager.arena_rank_score) do
      if self.list[index + 1].rank >= tonumber(temp.startRank, 10) and (self.list[index + 1].rank <= tonumber(temp.endRank, 10) or (tonumber(temp.endRank, 10) == -1)) then
        aArenaRankScoreConfig = temp
        break
      end
    end
    setNodeText(aRewardNumLabel, string.format("%d", tonumber(aArenaRankScoreConfig.score, 10)))
    local aCardDisplay =  aCell:getChildByTag(-12)
    --print(table.tostring(self.list[index + 1]))
    local newMeta = CommonManager:getSelfAvatarMetaByUid( self.list[index + 1].uid )
    if not newMeta then
      newMeta = self.list[index + 1].mainCardMetaId
    end
    local card3_co = getHeadIconCanonCardByMetaId(newMeta)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.7)
    aCell:addChild(card3_co.refCocosObj, 4)
    card3_co:setTag(-20)
    card3_co:dispose()
    local aNameLabel = aCell:getChildByTag(-13):getChildByTag(-10)
    setNodeText(aNameLabel, self.list[index + 1].nickName)
    local aLevelNameLabel = aCell:getChildByTag(-14):getChildByTag(-10)
    setNodeText(aLevelNameLabel, string.format("%d", self.list[index + 1].level))
    local aButtonDisplay = aCell:getChildByTag(-15)
    local aButtonDisplay2 = aCell:getChildByTag(-16)
    local othersFlag = aCell:getChildByTag(-17)
    local selfFlag = aCell:getChildByTag(-18)
    local huawen1 = aCell:getChildByTag(-7)
    local huawen2 = aCell:getChildByTag(-8)
    --if index + 1 == ArenaManager:sharedManager().currentPlayerIndex then
    if self.list[index + 1].rank == ArenaManager:sharedManager().arenaData.sharkArenaRank.rank then
      othersFlag:setVisible(false)
      selfFlag:setVisible(true)
      huawen1:setVisible(false)
      huawen2:setVisible(true)
      aButtonDisplay:setVisible(false)
      aButtonDisplay2:setVisible(false)
    else
      selfFlag:setVisible(false)
      othersFlag:setVisible(true)
      huawen2:setVisible(false)
      huawen1:setVisible(true)
      if ArenaManager:sharedManager().arenaData.sharkArenaRank.rank <= 10 then
        if self.list[index + 1].rank <= 10 then
          if ArenaManager:sharedManager():containInFoes(self.list[index + 1].uid) then
            aButtonDisplay:setVisible(false)
            aButtonDisplay2:setVisible(true)
          else
            aButtonDisplay:setVisible(true)
            aButtonDisplay2:setVisible(false)
          end
        else
          aButtonDisplay:setVisible(false)
          aButtonDisplay2:setVisible(false)
        end
      elseif ArenaManager:sharedManager().arenaData.sharkArenaRank.rank <= 20 then
        if index + 1 < ArenaManager:sharedManager().currentPlayerIndex then
          if ArenaManager:sharedManager():containInFoes(self.list[index + 1].uid) then
            aButtonDisplay:setVisible(false)
            aButtonDisplay2:setVisible(true)
          else
            aButtonDisplay:setVisible(true)
            aButtonDisplay2:setVisible(false)
          end
        else
          aButtonDisplay:setVisible(false)
          aButtonDisplay2:setVisible(false)
        end
      else
        if index + 1 < ArenaManager:sharedManager().currentPlayerIndex and index + 1 + 10 >= ArenaManager:sharedManager().currentPlayerIndex and self.list[index + 1].rank > 10 then
          if ArenaManager:sharedManager():containInFoes(self.list[index + 1].uid) then
            aButtonDisplay:setVisible(false)
            aButtonDisplay2:setVisible(true)
          else
            aButtonDisplay:setVisible(true)
            aButtonDisplay2:setVisible(false)
          end
        else
          aButtonDisplay:setVisible(false)
          aButtonDisplay2:setVisible(false)
        end
      end
    end
    
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.arenaTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    --[[
    local aCardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-12)
    if posInCell.x > aCardDisplay:getPositionX() - aCardDisplay:getContentSize().width / 2 and
      posInCell.x < (aCardDisplay:getPositionX() + aCardDisplay:getContentSize().width / 2) and
      posInCell.y > (aCardDisplay:getPositionY() - aCardDisplay:getContentSize().height / 2) and
      posInCell.y < aCardDisplay:getPositionY() + aCardDisplay:getContentSize().height / 2 then
      if aIndex ~= ArenaManager:sharedManager().currentPlayerIndex then
        self:showUserDetailPanel(ArenaManager:sharedManager().arenaData.sharkArenaPlayers[aIndex].uid)
        return
      end
    end
    ]]
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    local buttonDisplay2 = newCell:getChildByTag(cellTag):getChildByTag(-16)
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    --print(posInCell.x, posInCell.y)
    if (not buttonDisplay:isVisible()) and (not buttonDisplay2:isVisible()) then
      --if aIndex ~= ArenaManager:sharedManager().currentPlayerIndex then
      if ArenaManager:sharedManager().arenaData.sharkArenaPlayers[aIndex].uid ~= DataManager.getCurrUser().uid then
        self:showUserDetailPanel(ArenaManager:sharedManager().arenaData.sharkArenaPlayers[aIndex].uid)
      end
      return
    end
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      
      local revenge
      if buttonDisplay:isVisible() then
        revenge = false
      else
        revenge = true
      end
      
      self:checkArenaChallenge({matchedUid = ArenaManager:sharedManager().arenaData.sharkArenaPlayers[aIndex].uid, revenge = revenge})
    else
      self:showUserDetailPanel(ArenaManager:sharedManager().arenaData.sharkArenaPlayers[aIndex].uid)
    end
  end
  local renderer = ArenaTableViewRenderer.new(arenaItem_width, arenaItem_height)
  local aTableView = TableView:create(renderer, arenaTable_width, arenaTable_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(arenaTable_posX, arenaTable_posY))
  return aTableView
end

function ArenaRankScene:checkArenaChallenge(args)
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
    local params = {matchedUid = args.matchedUid, revenge = args.revenge}
    local request = ChallengeArenaRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.ChallengeArenaSucceed, challengeArenaSucceed)
    request:addEventListener(RequestNotifyEnum.ChallengeArenaFailed, challengeArenaFailed)
    request:start()
  end
end

function ArenaRankScene:showNotEnoughEventPointPanel()
  local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
  if hasProp then
    self:showUseEventPointProptPanel(eventPointPropList)
  else
    self:showEventPointLimitPanel()
  end
end

function ArenaRankScene:showUseEventPointProptPanel(eventPointPropList)
  local function callback(aEventPointPropId)
    self:recoveryEventPoint(aEventPointPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, eventPointPropList, callback)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:recoveryEventPoint(aEventPointPropId)
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

function ArenaRankScene:showEventPointLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:showMainActorPanel()
  self.arenaTableView:setTouchEnabled(false)
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end

function ArenaRankScene:panelDismiss()
  self.arenaTableView:setTouchEnabled(true)
end

function ArenaRankScene:setTableViewsEnabledInner(v)
  self.arenaTableView:setTouchEnabled(v)
end

function ArenaRankScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ArenaRankScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
  self.arenaTableView.refCocosObj:setScrollBar(nil)
  self.arenaTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaRankScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.arenaTableView:getContentOffset().y
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
  
  self.arenaTableView:setPositionX(self.arenaTableView:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.arenaTableView:runAction(CCSequence:create(arr))
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

function ArenaRankScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  if ArenaManager:sharedManager().hasRewardForRank then
    local aContent = Localization:getInstance():getText("arena_gainPoints", {num = ArenaManager:sharedManager().hasRewardNum})
    SuspensionLabel:showContent(self, aContent)
    ArenaManager:sharedManager():removeArenaScoreByRank()
  end
  
  if IsGuideExecuted(GuideConfig.kRisk3) then --主要新手引导的最后一个执行完后，才执行这个
    ExeNewGuide(GuideConfig.kArena)
  end
  
  --facebook share arena rank info
  if IsGuideExecuted(GuideConfig.kArena) and FacebookShareManager.isOpenFacebookShareFunc() then 
	local aArenaManager = ArenaManager:sharedManager()
	local myRank = aArenaManager.arenaData.sharkArenaRank.rank
	if myRank <= 100 and myRank > 10 then
		FacebookShareManager.facebookShareArenaRank(FacebookArenaRankShareID.FIRST_100)
	elseif myRank <= 10 then
		FacebookShareManager.facebookShareArenaRank(FacebookArenaRankShareID.FIRST_10)
	end
  end
  

  self.arenaTableView.refCocosObj:setScrollBar(CCScale9Sprite:create("pic/scroll.png"))
  self.arenaTableView.refCocosObj:setScrollTrack(CCScale9Sprite:create("pic/scroll.png"))
  self.arenaTableView:reloadData()
  self.arenaTableView:setContentOffset(ccp(0, self.originalResetOffsetY), false)
end

function ArenaRankScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ArenaRankScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
  self.arenaTableView.refCocosObj:setScrollBar(nil)
  self.arenaTableView.refCocosObj:setScrollTrack(nil)
end

function ArenaRankScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.arenaTableView:getContentOffset().y
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
  self.arenaTableView:runAction(CCSequence:create(arr))
  
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

function ArenaRankScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ArenaRankScene:back()
  self.ignoreAction = false
  self:replaceScene(CompeteScene)
end

function ArenaRankScene:buySucceed()
  local aArenaManager = ArenaManager:sharedManager()
  self.purchaseButtonDisplay:setVisible(false)
  aArenaManager.arenaData.arenaBoughtNum = aArenaManager.arenaData.arenaBoughtNum + 1
  local aVipSettingConfig = MetaManager.vip_setting[DataManager.getGameInitData().sharkUser.vipLevel]
  local leftChallengeCount = aArenaManager.arenaData.arenaBoughtNum * DataManager.GameMetaData.battleSettingConfig.arenaChallengeChancesPerPurchase + aVipSettingConfig.arenaChallengeChancesPerDay - aArenaManager.arenaData.arenaChallengeNum
  local currentTotalChallengeCount = aVipSettingConfig.arenaChallengeChancesPerDay
  self.challengeNumLabel:setString(string.format("%d/%d", leftChallengeCount, currentTotalChallengeCount))
end

function ArenaRankScene:showChallengeBuyLimitPanel()
  self.arenaTableView:setTouchEnabled(false)
  local aMaxValue = -1
  for _, temp in pairs(MetaManager.vip_setting) do
    if temp.level > aMaxValue then
      aMaxValue = temp.level
    end
  end
  local fullVip
  if DataManager.getGameInitData().sharkUser.vipLevel >= aMaxValue then
    fullVip = true
  else
    fullVip = false
  end
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kArenaChallengeBuyLimit, {fullVip = fullVip})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:showChallengeNumLimitPanel()
  self.arenaTableView:setTouchEnabled(false)
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kArenaChallengeNumLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:showGemLimitPanel()
  self.arenaTableView:setTouchEnabled(false)
  local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:moveToIAPShop()
  self:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
end

function ArenaRankScene:showUserDetailPanel(aUid)
  self.arenaTableView:setTouchEnabled(false)
  local userDetailPanel = UserDetailPanel:create( self, {friendUid = aUid} )
  self.targetInfoPanel = userDetailPanel
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
end

function ArenaRankScene:setTableViewsEnabledInner(aEnabled)
  self.arenaTableView:setTouchEnabled(aEnabled)
end

function ArenaRankScene:purchaseChallengeNumButtonTapped()
  local aArenaManager = ArenaManager:sharedManager()
  if TimeUtil.whetherSwitchDay(aArenaManager.arenaDataRefreshTime) then
    aArenaManager.arenaData.arenaBoughtNum = 0
  end
  local purchase_num_per_day = MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].purchaseArenaPerDay
  if aArenaManager.arenaData.arenaBoughtNum >= purchase_num_per_day then
    if DataManager.getCurrUser().vipLevel > 0 then
      self:showChallengeBuyLimitPanel()
    else
      self.targetInfoPanel = VipWarningPanel:create( self, 1)
      PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
    end
  else
    self:showPurchaseChallengeNumTipPanel()
  end
end

function ArenaRankScene:showPurchaseChallengeNumTipPanel()
  self.arenaTableView:setTouchEnabled(false)
  
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kArenaChallengeBuyTip, {gem = DataManager.GameMetaData.battleSettingConfig.arenaChallengeChancesGoldCost, num = DataManager.GameMetaData.battleSettingConfig.arenaChallengeChancesPerPurchase})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ArenaRankScene:confirmPurchaseChallengeNum()
  if DataManager.GameMetaData.battleSettingConfig.arenaChallengeChancesGoldCost > CalculationManager.calcComplex_getGemsNow() then
    self:showGemLimitPanel()
    return
  end
  
  local function buyChallengeNumSucceed(event)
    local aContent = Localization:getInstance():getText("arena_purchaseSuccess")
    SuspensionLabel:showContent(self, aContent)
    local aNegativeReward = event.data.requisite
    aNegativeReward.amount = -aNegativeReward.amount
    RewardManager:getReward({aNegativeReward})
    self:buySucceed()
  end 
  local function buyChallengeNumFailed(event)
    if event.data.retCode == 712412 then
      self:showChallengeBuyLimitPanel()
    elseif event.data.retCode == 710513 then
      self:showGemLimitPanel()
    end
  end
  local params = {}
  local request = BuyChallengeNumRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.BuyChallengeNumSucceed, buyChallengeNumSucceed)
  request:addEventListener(RequestNotifyEnum.BuyChallengeNumFailed, buyChallengeNumFailed)
  request:start()
end
