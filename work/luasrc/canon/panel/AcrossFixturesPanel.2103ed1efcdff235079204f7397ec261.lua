require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local FixturesTabEnum = {
  groupA = 1,
  groupB = 2,
  groupC = 3,
  groupD = 4,
}

local function groupASelected(evt)
  evt.context:changeToTab(FixturesTabEnum.groupA)
end

local function groupBSelected(evt)
  evt.context:changeToTab(FixturesTabEnum.groupB)
end

local function groupCSelected(evt)
  evt.context:changeToTab(FixturesTabEnum.groupC)
end

local function groupDSelected(evt)
  evt.context:changeToTab(FixturesTabEnum.groupD)
end

local tabListenerDic = {
  [FixturesTabEnum.groupA] = groupASelected,
  [FixturesTabEnum.groupB] = groupBSelected,
  [FixturesTabEnum.groupC] = groupCSelected,
  [FixturesTabEnum.groupD] = groupDSelected,
}

--
--AcrossFixturesPanel
--

AcrossFixturesPanel = class(Layer)

function AcrossFixturesPanel:ctor()
	self.container = nil
end

function AcrossFixturesPanel:create(container)
	local s = AcrossFixturesPanel.new()
	s:initLayer(container)
	return s
end

function AcrossFixturesPanel:initLayer(container)
	AcrossFixturesPanel.super.initLayer(self)
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.tabView = builder:build("event_game")
  self:addChild(self.tabView)
  
  self.tabButtons = {}
  local aDic = {[1] = 'A', [2] = 'B', [3] = 'C', [4] = 'D'}
  for i = 1, 4 do
    local aButtonDisplay = self.tabView:getChildByName("btn_inventory_switch_" .. i)
    aButtonDisplay:getChildByName("txt"):getChildByName("txt_btn_inventory_switch"):setString(Localization:getInstance():getText("cross_list_team" .. aDic[i]))
    local aTabButton = Button:create(aButtonDisplay)
    aTabButton:addEventListener(Events.kStart, tabListenerDic[i], self)
    self.tabButtons[i] = aTabButton
  end
  
  self.selectTab = nil
  self.tableData = {}
  self.tableView = nil
  self:changeToTab(FixturesTabEnum.groupA)
end

function AcrossFixturesPanel:dispose()
  AcrossFixturesPanel.super.dispose(self)
end

function AcrossFixturesPanel:changeToTab(aTab)
  if self.selectTab == aTab then
    return
  end
  
  self.selectTab = aTab
  for aIndex, aTabButton in pairs(self.tabButtons) do
    if self.selectTab == aIndex then
      aTabButton.display:getChildByName("btn_title_active"):setVisible(true)
      aTabButton.display:getChildByName("btn_inventory_switch_R"):setVisible(false)
      aTabButton:setEnable(false)
    else
      aTabButton.display:getChildByName("btn_title_active"):setVisible(false)
      aTabButton.display:getChildByName("btn_inventory_switch_R"):setVisible(true)
      aTabButton:setEnable(true)
    end
  end
  local currentTimeEnum = AcrossFightManager.getCurrentTimeEnum()
  if self.tableData then
    for aIndex, aData in ipairs(self.tableData) do
      self.tableData[aIndex] = nil
    end
  end
  local newData = AcrossFightManager.getFiguresData(self.selectTab, currentTimeEnum)
  for _, aData in ipairs(newData) do
    table.insert(self.tableData, aData)
  end
  if not self.tableView then
    self.tableView = self:createFituresTableView()
    self:addChild(self.tableView)
  end
  self.tableView:reloadData()
end

local table_width = 713
local table_height = 786
local table_posX = 3
local table_posY = 124
local item_width = 713
local item_height = 228

function AcrossFixturesPanel:createFituresTableView()
	local cellTag = 1024
	local buttonTag = {-17}
	local aPanel = self
	local FixturesTableViewRenderer = class(TableViewRenderer)
	function FixturesTableViewRenderer:ctor(width, height)
		self.list = aPanel.tableData or {}
	end
	function FixturesTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_event_game")
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
		local aPlayerDisplay1 = aCell:getChildByName("list_internal")
		aPlayerDisplay1:setTag(-10)
		local aIcon1 = aPlayerDisplay1:getChildByName("equip_normal_card_small_sb1")
    aIcon1:setTag(-10)
    aIcon1:setVisible(false)
    local aServerLabel1 = aPlayerDisplay1:getChildByName("txt_across_fight_1")
    aServerLabel1:setTag(-11)
		aServerLabel1 = aServerLabel1:getChildByName("txt")
		aServerLabel1:setTag(-10)
    local aNameLabel1 = aPlayerDisplay1:getChildByName("txt_across_fight_2")
    aNameLabel1:setTag(-12)
		aNameLabel1 = aNameLabel1:getChildByName("txt")
		aNameLabel1:setTag(-10)
    
    local aWinTag1 = aCell:getChildByName("signInIcon_victory_f_1")
		aWinTag1:setTag(-11)
    
    local aLoseTag1 = aCell:getChildByName("signInIcon_negative_f_1")
		aLoseTag1:setTag(-12)
    
    local aPlayerDisplay2 = aCell:getChildByName("list_internal2")
		aPlayerDisplay2:setTag(-13)
		local aIcon2 = aPlayerDisplay2:getChildByName("equip_normal_card_small_sb1")
    aIcon2:setTag(-10)
    aIcon2:setVisible(false)
    local aServerLabel2 = aPlayerDisplay2:getChildByName("txt_across_fight_1")
    aServerLabel2:setTag(-11)
		aServerLabel2 = aServerLabel2:getChildByName("txt")
		aServerLabel2:setTag(-10)
    local aNameLabel2 = aPlayerDisplay2:getChildByName("txt_across_fight_2")
    aNameLabel2:setTag(-12)
		aNameLabel2 = aNameLabel2:getChildByName("txt")
		aNameLabel2:setTag(-10)
    
    local aWinTag2 = aCell:getChildByName("signInIcon_victory_f_2")
		aWinTag2:setTag(-14)
    
    local aLoseTag2 = aCell:getChildByName("signInIcon_negative_f_2")
		aLoseTag2:setTag(-15)
    
    local aBgTag = aCell:getChildByName("bg_across_fight__flame")
		aBgTag:setTag(-16)
    
    local aReviewBtnDisplay = aCell:getChildByName("btn_the_view")
		aReviewBtnDisplay:setTag(-17)
		aReviewBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cross_race_video"))
		aReviewBtnDisplay:getChildByName("btn"):setTag(-10)
    
    local aNobodyFlag1 = aCell:getChildByName("txt_across_fight_22_2")
    aNobodyFlag1:setTag(-18)
		aNobodyFlag1 = aNobodyFlag1:getChildByName("txt")
		aNobodyFlag1:setTag(-10)
    
    local aNobodyFlag2 = aCell:getChildByName("txt_across_fight_22_1")
    aNobodyFlag2:setTag(-19)
		aNobodyFlag2 = aNobodyFlag2:getChildByName("txt")
		aNobodyFlag2:setTag(-10)
	end

	function FixturesTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local aPlayerDisplay1 = aCell:getChildByTag(-10)
    local aCard = aPlayerDisplay1:getChildByTag(-20)
    if aCard then
      aCard:removeFromParentAndCleanup(true)
    end
    local aPlayerDisplay2 = aCell:getChildByTag(-13)
    local aCard = aPlayerDisplay2:getChildByTag(-20)
    if aCard then
      aCard:removeFromParentAndCleanup(true)
    end
    local aWinTag1 = aCell:getChildByTag(-11)
    local aLoseTag1 = aCell:getChildByTag(-12)
    local aWinTag2 = aCell:getChildByTag(-14)
    local aLoseTag2 = aCell:getChildByTag(-15)
    local aBgTag = aCell:getChildByTag(-16)
    local aReviewBtnDisplay = aCell:getChildByTag(-17)
    local aNobodyFlag1 = aCell:getChildByTag(-18)
    local aNobodyFlag2 = aCell:getChildByTag(-19)
    
    local aServerLabel1 = aPlayerDisplay1:getChildByTag(-11)
    local aNameLabel1 = aPlayerDisplay1:getChildByTag(-12)
    if not aData[1].uid then
      aServerLabel1:setVisible(false)
      aNameLabel1:setVisible(false)
      aNobodyFlag1:setVisible(true)
      setNodeText(aNobodyFlag1:getChildByTag(-10), Localization:getInstance():getText("cross_wrong_nobody"))
    else
      aServerLabel1:setVisible(true)
      aNameLabel1:setVisible(true)
      aNobodyFlag1:setVisible(false)
      local aIcon1 = aPlayerDisplay1:getChildByTag(-10)
      local params = {}
      params.sourceDisplay = aIcon1
      params.container = aPlayerDisplay1
      --params.showInCenter = true
      params.zindex = 10
      local newMeta = CommonManager:getSelfAvatarMetaByUid( aData[1].uid )
      if not newMeta then
          newMeta = aData[1].mainCardMetaId
      end
      aCard = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 0, params)
      if aCard then
        aCard:setTag(-20)
        aCard:dispose()
      end
      local serverNumber = tonumber(string.sub(aData[1].uid, -4, -1))
      if __IOS then
        setNodeText(aServerLabel1:getChildByTag(-10), Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
      else
        setNodeText(aServerLabel1:getChildByTag(-10), Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
      end
      setNodeText(aNameLabel1:getChildByTag(-10), aData[1].nickName)
    end
    
    local aServerLabel2 = aPlayerDisplay2:getChildByTag(-11)
    local aNameLabel2 = aPlayerDisplay2:getChildByTag(-12)
    if not aData[2].uid then
      aServerLabel2:setVisible(false)
      aNameLabel2:setVisible(false)
      aNobodyFlag2:setVisible(true)
      setNodeText(aNobodyFlag2:getChildByTag(-10), Localization:getInstance():getText("cross_wrong_nobody"))
    else
      aServerLabel2:setVisible(true)
      aNameLabel2:setVisible(true)
      aNobodyFlag2:setVisible(false)
      local aIcon2 = aPlayerDisplay2:getChildByTag(-10)
      local params = {}
      params.sourceDisplay = aIcon2
      params.container = aPlayerDisplay2
      --params.showInCenter = true
      params.zindex = 10
      aCard = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, aData[2].mainCardMetaId, 0, params)
      if aCard then
        aCard:setTag(-20)
        aCard:dispose()
      end
      local serverNumber = tonumber(string.sub(aData[2].uid, -4, -1))
      if __IOS then
        setNodeText(aServerLabel2:getChildByTag(-10), Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
      else
        setNodeText(aServerLabel2:getChildByTag(-10), Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
      end
      setNodeText(aNameLabel2:getChildByTag(-10), aData[2].nickName)
    end
    
    if aData[3] == 0 then
      aWinTag1:setVisible(false)
      aLoseTag1:setVisible(false)
      aWinTag2:setVisible(false)
      aLoseTag2:setVisible(false)
      aBgTag:setVisible(true)
      aReviewBtnDisplay:setVisible(false)
    elseif aData[3] == 1 then
      if not aData[1].uid then
        aWinTag1:setVisible(false)
        aLoseTag1:setVisible(false)
      else
        aWinTag1:setVisible(true)
        aLoseTag1:setVisible(false)
      end
      if not aData[2].uid then
        aWinTag2:setVisible(false)
        aLoseTag2:setVisible(false)
      else
        aWinTag2:setVisible(false)
        aLoseTag2:setVisible(true)
      end
      aBgTag:setVisible(false)
      if not aData[1].uid or not aData[2].uid then
        aReviewBtnDisplay:setVisible(false)
      else
        aReviewBtnDisplay:setVisible(true)
      end
    else
      if not aData[1].uid then
        aWinTag1:setVisible(false)
        aLoseTag1:setVisible(false)
      else
        aWinTag1:setVisible(false)
        aLoseTag1:setVisible(true)
      end
      if not aData[2].uid then
        aWinTag2:setVisible(false)
        aLoseTag2:setVisible(false)
      else
        aWinTag2:setVisible(true)
        aLoseTag2:setVisible(false)
      end
      aBgTag:setVisible(false)
      if not aData[1].uid or not aData[2].uid then
        aReviewBtnDisplay:setVisible(false)
      else
        aReviewBtnDisplay:setVisible(true)
      end
    end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.tableData[aIndex]

		local aReviewBtnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-17)
		local reviewDisplay = aReviewBtnDisplay:getChildByTag(-10)
    local aPlayerDisplay1 = newCell:getChildByTag(cellTag):getChildByTag(-10)
    local aCard1 = aPlayerDisplay1:getChildByTag(-10)
    local posInUser1 = aPlayerDisplay1:convertToNodeSpace(evt.globalPosition)
    local aPlayerDisplay2 = newCell:getChildByTag(cellTag):getChildByTag(-13)
    local aCard2 = aPlayerDisplay2:getChildByTag(-10)
    local posInUser2 = aPlayerDisplay2:convertToNodeSpace(evt.globalPosition)
    if posInUser1.x > (aCard1:getPositionX() - aCard1:getContentSize().width / 2) and
		posInUser1.x < (aCard1:getPositionX() + aCard1:getContentSize().width / 2) and
		posInUser1.y > (aCard1:getPositionY() - aCard1:getContentSize().height / 2) and
		posInUser1.y < (aCard1:getPositionY() + aCard1:getContentSize().height / 2) then
      if aData[1].uid and aData[1].uid ~= DataManager.getCurrUser().uid then
        self:showUserDetailPanel(aData[1].uid)
      end
    elseif posInUser2.x > (aCard2:getPositionX() - aCard2:getContentSize().width / 2) and
		posInUser2.x < (aCard2:getPositionX() + aCard2:getContentSize().width / 2) and
		posInUser2.y > (aCard2:getPositionY() - aCard2:getContentSize().height / 2) and
		posInUser2.y < (aCard2:getPositionY() + aCard2:getContentSize().height / 2) then
      if aData[2].uid and tonumber(aData[2].uid) ~= tonumber(DataManager.getCurrUser().uid) then
        self:showUserDetailPanel(aData[2].uid)
      end
    elseif aReviewBtnDisplay:isVisible() and posInCell.x > aReviewBtnDisplay:getPositionX() and
		posInCell.x < (aReviewBtnDisplay:getPositionX() + reviewDisplay:getContentSize().width) and
		posInCell.y > (aReviewBtnDisplay:getPositionY() - reviewDisplay:getContentSize().height) and
		posInCell.y < aReviewBtnDisplay:getPositionY() then
      self:reviewBattle(aData[5], aData[1], aData[2], aData[3] == 1)
    end
	end

	local renderer = FixturesTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))
  
	return aTableView
end

function AcrossFixturesPanel:showUserDetailPanel(aUid)
  local function panelClosed()
    self.tableView:setTouchEnabled(true)
  end
  self.tableView:setTouchEnabled(false)
  local userDetailPanel = AcrossUserDetailPanel:create( self.container, {uid = aUid, closeCallback = panelClosed} )
  PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
end

function AcrossFixturesPanel:reviewBattle(aUid, aUserInfo1, aUserInfo2, whetherWin)
  local function onSucceed(requestEvent)
		GetCrossPkReportRequest.onSucceedDefault(requestEvent)
    requestEvent.data.userinfo1 = aUserInfo1
    requestEvent.data.userinfo2 = aUserInfo2
    requestEvent.data.whetherWin = whetherWin
    Director:sharedDirector():replaceScene(BattleScene:create(requestEvent.data, BattleBackType.kAcrossFightReview, BattleEnterEnum.kAcrossFightReview))
	end

	GetCrossPkReportRequest.sendRequest(onSucceed, GetCrossPkReportRequest.onFailedDefault, {reportId = aUid})
end

function AcrossFixturesPanel:setTableViewTouched(enabled)
  self.tableView:setTouchEnabled(enabled)
end

function AcrossFixturesPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.tableView, visibleSize,callback)
  
  self.tabView:setPositionX(self.tabView:getPositionX() - visibleSize.width)
  self.tabView:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
end

function AcrossFixturesPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, callback)
  
  self.tabView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
end