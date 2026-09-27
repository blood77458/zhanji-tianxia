require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"

require "canon.request.GainRankRewardsRequest"

NewBabelRankScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function NewBabelRankScene:ctor()
	self.title = getTextByKey("babel_rankingTitle")
  self.curSceneEnum = SceneEnum.NewBabelRankScene
end

function NewBabelRankScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  local scene = NewBabelRankScene.new()		
  scene:initScene()
  return scene
end

function NewBabelRankScene:onInit()
		self.sharkSkyTowerData = DataManager.getSharkSkyTowerData()
	if not self.sharkSkyTowerData.pastRanks then
		self.sharkSkyTowerData.pastRanks = {}
	end
	
	if TimeUtil.isFirstMin(TimeUtil.getServerTimeSeconds()) then
		self.sharkSkyTowerData.pastRanks = {}
		self.toRegisterSchedule = true
	end
	
	self.rankData = {}
	for k, data in ipairs(self.sharkSkyTowerData.pastRanks) do
		table.insert(self.rankData, data)
	end
	
	BaseUIScene.initBackGround(self)
	--新UI加黑底
    local colorLayer = LayerColor:create()
    colorLayer:setOpacity(kDarkOpacity)
    colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(colorLayer)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = self.builder:build("towerBable_ranking")
	
	self.mainUI:getChildByName("towerBabel_qa"):setVisible(false)
	self.mainUI:getChildByName("txt_ranking_title"):getChildByName("txt"):setString(getTextByKey("skyTower_yesterdayRankingTitle"))
	self.mainUI:getChildByName("txt_ranking_info"):getChildByName("txt"):setString(getTextByKey("skyTower_rankingTxt"))
	self.mainUI:getChildByName("btn_get_reward"):getChildByName("txt"):setString(getTextByKey("skyTower_rewardBtn"))
	self.mainUI:getChildByName("txt_ranking_info_2"):getChildByName("txt"):setString(getTextByKey("skyTower_rankingProcessing"))
	local function onClickGetReward()
		self:sendGetRewardRequest()
	end
	
	self.getRewardButton = Button:create(self.mainUI:getChildByName("btn_get_reward"))
	self.getRewardButton:addEventListener(Events.kStart, onClickGetReward)
	
	self.tableView = self:createTableView(self.rankData)
	self.mainUI:addChild(self.tableView)
	
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
	
	self:refreshUI()
end

function NewBabelRankScene:sendGetRewardRequest()--获取排名奖励的请求
	if BagCalcManager.isFull() then
		-- SuspensionLabel:showContent(self, getTextByKey("shop_inventoryFull"))
		NewPackageFullPanel:show()
		do return end
	end
		
	local function onGainRankRewardsSucceed(evt)
		self.waitRequest = false
		RewardManager:getReward(evt.data.rewards)
		self.targetInfoPanel = GetRewardInfoPanel:create( self, evt.data.rewards)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
		self.sharkSkyTowerData.currStatus.gainYesterdayReward = true
		DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)
		self:refreshUI()
	end
	
	local function onGainRankRewardsFailed(evt)
		self.waitRequest = false
		if evt.data == 713500 then
			local function closeCanonMessageBox()
				self:sendGetSkyTowerInfoRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713501 then
			local function closeCanonMessageBox()
				self:sendGetSkyTowerInfoRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713503 then
			local function closeCanonMessageBox()
				self:sendGetSkyTowerInfoRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_rewardClaimed"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 710516 then
			local function closeCanonMessageBox()
			end
			self.targetInfoPanel = NewPackageFullPanel:show()
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	if self.waitRequest then
		do return end
	end
	
	self.waitRequest = true
	--onGainRankRewardsSucceed({data = {rewards = {}}})
	--do return end
	--
	local request = GainRankRewardsRequest.new( nil, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.GainRankRewardsSucceed, onGainRankRewardsSucceed )
  request:addEventListener( RequestNotifyEnum.GainRankRewardsFailed, onGainRankRewardsFailed )
  request:start()
end

function NewBabelRankScene:refreshUI()--刷新界面
	local buttonEnable = false
	
	self.mainUI:getChildByName("txt_ranking_info_2"):setVisible(false)
	if self.toRegisterSchedule then
		self.mainUI:getChildByName("txt_ranking_info_2"):setVisible(true)
	elseif self.sharkSkyTowerData.currStatus.gainYesterdayReward then
		self.getRewardButton.display:getChildByName("txt"):setString(getTextByKey("skyTower_rewardClaimed"))
	else
		self.getRewardButton.display:getChildByName("txt"):setString(getTextByKey("skyTower_rewardBtn"))
		if type(self.sharkSkyTowerData.pastRanks) == "table" then
			for k,data in pairs(self.sharkSkyTowerData.pastRanks) do
				if data.uid == self.sharkSkyTowerData.sharkSkyTower.uid then
					buttonEnable = true
					break;
				end
			end
		end
	end
	self.getRewardButton:setEnable(buttonEnable)
	self.getRewardButton.display:getChildByName("btn"):setVisible(buttonEnable)
end

function NewBabelRankScene:refreshTable(keepOffset)--刷新排名列表
	if keepOffset then
		local tableOffset = self.tableView:getContentOffset()
		self.tableView:reloadData()
		
		self.tableView:setContentOffset(tableOffset, true)
	else
		self.tableView:reloadData()
	end
end

local TABLEVIEW_CELL_TAG = -1001
local TXT_RANKDAYS_TAG = 1001
local TXT_RANKFLOORS_TAG = 1002
local TXT_RANKSTARS_TAG = 1003
local TXT_RANKNAME_TAG = 1004
local TXT_RANKRANK_TAG = 1005
local ICON_RANKFAKEICON_TAG = 1006
local ICON_RANKREALICON_TAG = 1007
local TXT_RANKUNION_TAG = 1008

local function inArea(posX, posY, rect)
	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
		return true
	end
	return false
end

local function setTextByTag( cell, tag, str)
	local txt = cell:getChildByTag(tag):getChildByTag(tag)
	setNodeText(txt, str);
end
	
local function setNodeVisibleByTag(cell, tag, visible)
	cell:getChildByTag(tag):setVisible(visible)
end

local function getMiddlePosition(cell, tag)
	local posX, posY = cell:getChildByTag(tag):getPosition()
	return ccp(posX , posY)
end

local function addNodeReplaceWithTag(cell, tag, node, nodeTag)
	if cell:getChildByTag(nodeTag) then
		cell:removeChildByTag(nodeTag, true)
	end
	node:setTag(nodeTag)
	node:setPosition(getMiddlePosition(cell, tag))
	local zOrder = cell:getChildByTag(tag):getZOrder()
	cell:addChild(node, zOrder)
end

function NewBabelRankScene:createTableView(data)
	local NewBabelRankRenderer = class(TableViewRenderer)
	local SELF = self
	function NewBabelRankRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function NewBabelRankRenderer:buildCell(container)
		local cell = self.builder:build("list_towerBabel_ranking")
		cell:setPositionXY(55, 0)
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		cell:getChildByName("txt_towerBabel_1"):setTag(TXT_RANKDAYS_TAG)
		cell:getChildByName("txt_towerBabel_1"):getChildByName("txt"):setTag(TXT_RANKDAYS_TAG)
		cell:getChildByName("txt_towerBabel_2"):setTag(TXT_RANKFLOORS_TAG)
		cell:getChildByName("txt_towerBabel_2"):getChildByName("txt"):setTag(TXT_RANKFLOORS_TAG)
		cell:getChildByName("txt_towerBabel_5"):setTag(TXT_RANKSTARS_TAG)
		cell:getChildByName("txt_towerBabel_5"):getChildByName("txt"):setTag(TXT_RANKSTARS_TAG)
		cell:getChildByName("txt_towerBabel_3"):setTag(TXT_RANKNAME_TAG)
		cell:getChildByName("txt_towerBabel_3"):getChildByName("txt"):setTag(TXT_RANKNAME_TAG)
		cell:getChildByName("txt_towerBabel_4"):setTag(TXT_RANKRANK_TAG)
		cell:getChildByName("txt_towerBabel_4"):getChildByName("txt"):setTag(TXT_RANKRANK_TAG)
		cell:getChildByName("frame_card"):setVisible(false)
		cell:getChildByName("normal_card_small"):setVisible(false)
		cell:getChildByName("normal_card_small"):setTag(ICON_RANKFAKEICON_TAG)
		cell:getChildByName("txt_guild_namae"):setTag(TXT_RANKUNION_TAG)
		cell:getChildByName("txt_guild_namae"):getChildByName("txt"):setTag(TXT_RANKUNION_TAG)
	end

	function NewBabelRankRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local rankInfo = data[index + 1]
		
		setTextByTag(cell, TXT_RANKDAYS_TAG, getTextByKey("skyTower_ranking_continuousDays") .. tostring(rankInfo.inTopRankDays + 1))
		setTextByTag(cell, TXT_RANKFLOORS_TAG, getTextByKey("skyTower_ranking_highFloor") .. tostring(rankInfo.maxFloor))
		setTextByTag(cell, TXT_RANKSTARS_TAG, getTextByKey("skyTower_ranking_highStars") .. tostring(rankInfo.maxTotalStars))
		setTextByTag(cell, TXT_RANKNAME_TAG, tostring(rankInfo.nickName))
		setTextByTag(cell, TXT_RANKRANK_TAG, Localization:getInstance():getText("babel_rankingRank", {num = tostring(index + 1)}))
		if rankInfo.unionName then
			cell:getChildByTag(TXT_RANKUNION_TAG):setVisible(true)
			setTextByTag(cell, TXT_RANKUNION_TAG, tostring(Localization:getInstance():getText("union_name_txt", {name = rankInfo.unionName})))--otherUnionName
		else
			cell:getChildByTag(TXT_RANKUNION_TAG):setVisible(false)
		end
		--print(table.tostring(rankInfo))
		local newMeta = CommonManager:getSelfAvatarMetaByUid( rankInfo.uid )
	    if not newMeta then
	        newMeta = rankInfo.mainCardMetaId
	    end
		local icon = getHeadIconCanonCardByMetaId(newMeta)
		icon:setScale(cell:getChildByTag(ICON_RANKFAKEICON_TAG):getContentSize().width * cell:getChildByTag(ICON_RANKFAKEICON_TAG):getScaleX() / 130)
		addNodeReplaceWithTag(cell, ICON_RANKFAKEICON_TAG, icon.refCocosObj, ICON_RANKREALICON_TAG)
		icon:dispose()
	end
	
	local renderer = NewBabelRankRenderer.new(BAGCONFIG.WIDTH, 160)
	local buttonTag = {}
  local list = TableView:create(renderer, BAGCONFIG.WIDTH, BAGCONFIG.HEIGHT - 115, TABLEVIEW_CELL_TAG, buttonTag)
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		self._data = data[evt.data + 1]
		if self._data.uid == self.sharkSkyTowerData.sharkSkyTower.uid then
			--donothing
		else
			self:showUserDetailPanel(self._data.uid)
		end
	end

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(0, (1280-BAGCONFIG.HEIGHT)/2-185 + 100))
  return list
end

function NewBabelRankScene:showUserDetailPanel(aUid)--显示用户详情弹框
	local function onCloseCallback()
		self:setTableViewsEnabled(true)
	end
	self:setTableViewsEnabled(false)
  self.targetInfoPanel = UserDetailPanel:create( self, {friendUid = aUid} )
	self.targetInfoPanel.Close_CallBack = onCloseCallback
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
end

function NewBabelRankScene:dispose()
	self:unregisterCheckSchedule()
	BaseUIScene.dispose(self)
end

function NewBabelRankScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function NewBabelRankScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function NewBabelRankScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function NewBabelRankScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	self:registerCheckSchedule()
end

function NewBabelRankScene:checkSendGetSkyTowerInfoRequest()
	if not TimeUtil.isFirstMin(TimeUtil.getServerTimeSeconds()) then
		self:sendGetSkyTowerInfoRequest()
	end
end

function NewBabelRankScene:sendGetSkyTowerInfoRequest()
	local function onGetSkyTowerInfoSucceed(evt)
		self.waitRequest = false
		table.removeAll(self.rankData)
		self.sharkSkyTowerData = evt.data
		if type(self.sharkSkyTowerData.pastRanks) == "table" then
			for k,data in ipairs(self.sharkSkyTowerData.pastRanks) do
				table.insert(self.rankData, data)
			end
		end
		self:unregisterCheckSchedule()
		self:refreshUI()
		self:refreshTable(false)
	end
	
	local function onGetSkyTowerInfoFailed(evt)
		self.waitRequest = false
	end
	
	if self.waitRequest then
		do return end
	end
	
	self.waitRequest = true
	generalSendGetSkyTowerInfoRequest(onGetSkyTowerInfoSucceed, nil, onGetSkyTowerInfoFailed)
end

function NewBabelRankScene:registerCheckSchedule()
	if self.toRegisterSchedule then
		self.toRegisterSchedule = nil;
		local function checkNeedSendRequest()
			self:checkSendGetSkyTowerInfoRequest()
		end
		if not self.checkNeedSendRequestSchedule then
			self.checkNeedSendRequestSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkNeedSendRequest, 1, false)
		end
		checkNeedSendRequest()
	end
end

function NewBabelRankScene:unregisterCheckSchedule()
	if self.checkNeedSendRequestSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkNeedSendRequestSchedule)
		self.checkNeedSendRequestSchedule = nil
	end
end

function NewBabelRankScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function NewBabelRankScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function NewBabelRankScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function NewBabelRankScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function NewBabelRankScene:back()
	if self.argv.returnScene == "NewBabelScene" then
		self:replaceScene(NewBabelScene)
	else
		self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
	end
end

function NewBabelRankScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			if self.tableView then
				self.tableView:setTouchEnabled(v)
			end
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.tableView then
			self.tableView:setTouchEnabled(v)
		end
		self.mainUI:setTouchEnabled(v)
	end
end
