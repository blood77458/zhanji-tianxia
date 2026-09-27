require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
--AcrossTop4Panel
--

AcrossTop4Panel = class(Layer)

function AcrossTop4Panel:ctor()
	self.container = nil
end

function AcrossTop4Panel:create(container)
	local s = AcrossTop4Panel.new()
	s:initLayer(container)
	return s
end

function AcrossTop4Panel:initLayer(container)
	AcrossTop4Panel.super.initLayer(self)
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  self.table_meta_info = getTableViewSizes(builder:build("tabel_lastfour_list"))
  print(table.tostring(self.table_meta_info))
  self.table_meta_info.table_posX = 0
  self.table_meta_info.table_posY = 120
  self.table_meta_info.table_width = 720
  self.tableData = AcrossFightManager.getTop4Data()
  self.tableView = self:createTableView()
  self:addChild(self.tableView)
  self.tableView:reloadData()
end

function AcrossTop4Panel:createTableView()
	local cellTag = 1024
	local buttonTag = {-12}
	local aPanel = self
	local tableViewRenderer = class(TableViewRenderer)
	function tableViewRenderer:ctor(width, height)
		self.list = aPanel.tableData or {}
	end
	function tableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_across_fight_lastfour")
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
    local playerInfoGroup1 = aCell:getChildByName("playerlist_fo_lastfour")
    playerInfoGroup1:setTag(-10)
		local aServerLabel1 = playerInfoGroup1:getChildByName("txt_across_fight_1")
		aServerLabel1:setTag(-10)
    aServerLabel1 = aServerLabel1:getChildByName("txt")
		aServerLabel1:setTag(-10)
    local aNameLabel1 = playerInfoGroup1:getChildByName("txt_player_name")
    aNameLabel1:setTag(-11)
		aNameLabel1 = aNameLabel1:getChildByName("txt")
		aNameLabel1:setTag(-10)
    local posRef1 = playerInfoGroup1:getChildByName("bg_player_name")
    posRef1:setTag(-12)
    
    local playerInfoGroup2 = aCell:getChildByName("playerlist_fo_lastfour2")
    playerInfoGroup2:setTag(-11)
		local aServerLabel2 = playerInfoGroup2:getChildByName("txt_across_fight_1")
		aServerLabel2:setTag(-10)
    aServerLabel2 = aServerLabel2:getChildByName("txt")
		aServerLabel2:setTag(-10)
    local aNameLabel2 = playerInfoGroup2:getChildByName("txt_player_name")
    aNameLabel2:setTag(-11)
		aNameLabel2 = aNameLabel2:getChildByName("txt")
		aNameLabel2:setTag(-10)
    local posRef2 = playerInfoGroup2:getChildByName("bg_player_name")
    posRef2:setTag(-12)
    
    local aReviewBtnDisplay = aCell:getChildByName("btn_the_view")
		aReviewBtnDisplay:setTag(-12)
		aReviewBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cross_race_video"))
		aReviewBtnDisplay:getChildByName("btn"):setTag(-10)
    
    local aWinTag1 = aCell:getChildByName("signInIcon_victory_f_1")
		aWinTag1:setTag(-13)
    local aLoseTag1 = aCell:getChildByName("signInIcon_negative_f_1")
		aLoseTag1:setTag(-14)
    local aWinTag2 = aCell:getChildByName("signInIcon_victory_f_2")
		aWinTag2:setTag(-15)
    local aLoseTag2 = aCell:getChildByName("signInIcon_negative_f_2")
		aLoseTag2:setTag(-16)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local aCard1 = aCell:getChildByTag(-20)
    local aCard2 = aCell:getChildByTag(-21)
    if aCard1 then
      aCard1:removeFromParentAndCleanup(true)
    end
    if aCard2 then
      aCard2:removeFromParentAndCleanup(true)
    end
    
    local playerInfoGroup1 = aCell:getChildByTag(-10)
    local aServerLabel1 = playerInfoGroup1:getChildByTag(-10)
    local serverNumber1 = tonumber(string.sub(tostring(aData[1].uid), -4, -1))
    if __IOS then
      setNodeText(aServerLabel1:getChildByTag(-10), Localization:getInstance():getText("cross_list_text", {num1 = serverNumber1}))
    else
      setNodeText(aServerLabel1:getChildByTag(-10), Localization:getInstance():getText("cross_list_android", {num1 = serverNumber1}))
    end
    local aNameLabel1 = playerInfoGroup1:getChildByTag(-11)
    setNodeText(aNameLabel1:getChildByTag(-10), aData[1].nickName)
    print(table.tostring(aData))
    local newMeta = CommonManager:getSelfAvatarMetaByUid( aData[1].uid )
    if not newMeta then
        newMeta = aData[1].mainCardMetaId
    end
    local card = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(newMeta))
    card:setAnchorPoint(ccp(0.5, 0))
    card:setScaleX(0.7)
    card:setScaleY(0.7)
    local posRef = playerInfoGroup1:getChildByTag(-12)
    local posX = playerInfoGroup1:getPositionX() + posRef:getPositionX() + 0.5 * posRef:getContentSize().width
    local posY = playerInfoGroup1:getPositionY() + posRef:getPositionY()
    card:setPosition(ccp(posX, posY))
    card:setTag(-20)
    aCell:addChild(card.refCocosObj, 0)
    card:dispose()
    
    local playerInfoGroup2 = aCell:getChildByTag(-11)
    local aServerLabel2 = playerInfoGroup2:getChildByTag(-10)
    local serverNumber2 = tonumber(string.sub(tostring(aData[2].uid), -4, -1))
    if __IOS then
      setNodeText(aServerLabel2:getChildByTag(-10), Localization:getInstance():getText("cross_list_text", {num1 = serverNumber2}))
    else
      setNodeText(aServerLabel2:getChildByTag(-10), Localization:getInstance():getText("cross_list_android", {num1 = serverNumber2}))
    end
    local aNameLabel2 = playerInfoGroup2:getChildByTag(-11)
    setNodeText(aNameLabel2:getChildByTag(-10), aData[2].nickName)
    local newMeta = CommonManager:getSelfAvatarMetaByUid( aData[2].uid )
    if not newMeta then
        newMeta = aData[2].mainCardMetaId
    end
    local card = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(newMeta))
    card:setAnchorPoint(ccp(0.5, 0))
    card:setScaleX(0.7)
    card:setScaleY(0.7)
    local posRef = playerInfoGroup2:getChildByTag(-12)
    local posX = playerInfoGroup2:getPositionX() + posRef:getPositionX() + 0.5 * posRef:getContentSize().width
    local posY = playerInfoGroup2:getPositionY() + posRef:getPositionY()
    card:setPosition(ccp(posX, posY))
    card:setTag(-21)
    aCell:addChild(card.refCocosObj, 0)
    card:dispose()
    
    local aReviewBtnDisplay = aCell:getChildByTag(-12)
    local aWinTag1 = aCell:getChildByTag(-13)
    local aLoseTag1 = aCell:getChildByTag(-14)
    local aWinTag2 = aCell:getChildByTag(-15)
    local aLoseTag2 = aCell:getChildByTag(-16)
    if not aData[3] then
      aReviewBtnDisplay:setVisible(false)
      aWinTag1:setVisible(false)
      aLoseTag1:setVisible(false)
      aWinTag2:setVisible(false)
      aLoseTag2:setVisible(false)
    else
      aReviewBtnDisplay:setVisible(true)
      if aData[5] == 1 then
        aWinTag1:setVisible(true)
        aLoseTag1:setVisible(false)
        aWinTag2:setVisible(false)
        aLoseTag2:setVisible(true)
      elseif aData[5] == 2 then
        aWinTag1:setVisible(false)
        aLoseTag1:setVisible(true)
        aWinTag2:setVisible(true)
        aLoseTag2:setVisible(false)
      end
    end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.tableData[aIndex]

		local aReviewBtnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-12)
		local normalDisplay = aReviewBtnDisplay:getChildByTag(-10)
    local aCard1 = newCell:getChildByTag(cellTag):getChildByTag(-20)
    local posX1 = aCard1:getPositionX()
    local posY1 = aCard1:getPositionY()
    local aCard2 = newCell:getChildByTag(cellTag):getChildByTag(-21)
    local posX2 = aCard2:getPositionX()
    local posY2 = aCard2:getPositionY()
    if aReviewBtnDisplay:isVisible() and 
      posInCell.x > aReviewBtnDisplay:getPositionX() and
      posInCell.x < (aReviewBtnDisplay:getPositionX() + normalDisplay:getContentSize().width) and
      posInCell.y > (aReviewBtnDisplay:getPositionY() - normalDisplay:getContentSize().height) and
      posInCell.y < aReviewBtnDisplay:getPositionY() then
      self:reviewBattle(aData[4], aData[1], aData[2], aData[5] == 1)
    elseif posInCell.x > posX1 - 105 and posInCell.x < posX1 + 105 and posInCell.y > posY1 and posInCell.y < posY1 + 300 and tonumber(aData[1].uid) ~= tonumber(DataManager.getCurrUser().uid) then
      self:showUserDetailPanel(aData[1].uid)
    elseif posInCell.x > posX2 - 105 and posInCell.x < posX2 + 105 and posInCell.y > posY2 and posInCell.y < posY2 + 300 and tonumber(aData[2].uid) ~= tonumber(DataManager.getCurrUser().uid) then
      self:showUserDetailPanel(aData[2].uid)
    end
	end

	local renderer = tableViewRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
	local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  
	return aTableView
end

function AcrossTop4Panel:showUserDetailPanel(aUid)
  local function panelClosed()
    self.tableView:setTouchEnabled(true)
  end
  self.tableView:setTouchEnabled(false)
  local userDetailPanel = AcrossUserDetailPanel:create( self.container, {uid = aUid, closeCallback = panelClosed} )
  PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
end

function AcrossTop4Panel:dispose()
  AcrossTop4Panel.super.dispose(self)
end

function AcrossTop4Panel:reviewBattle(aUid, aUserInfo1, aUserInfo2, whetherWin)
  local function onSucceed(requestEvent)
		GetCrossPkReportRequest.onSucceedDefault(requestEvent)
    requestEvent.data.userinfo1 = aUserInfo1
    requestEvent.data.userinfo2 = aUserInfo2
    requestEvent.data.whetherWin = whetherWin
    Director:sharedDirector():replaceScene(BattleScene:create(requestEvent.data, BattleBackType.kAcrossFightReview, BattleEnterEnum.kAcrossFightReview))
	end

	GetCrossPkReportRequest.sendRequest(onSucceed, GetCrossPkReportRequest.onFailedDefault, {reportId = aUid})
end

function AcrossTop4Panel:setTableViewTouched(enabled)
  self.tableView:setTouchEnabled(enabled)
end

function AcrossTop4Panel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.tableView, visibleSize,callback)
  
end

function AcrossTop4Panel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, callback)
  
end