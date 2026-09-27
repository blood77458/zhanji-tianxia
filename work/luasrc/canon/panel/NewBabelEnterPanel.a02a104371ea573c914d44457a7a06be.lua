require "canon.request.GetSkyTowerInfoRequest"
require "canon.panel.NewBabelAttensionPanel"
require "canon.panel.NewBabelFloorRewardPanel"
require "canon.scene.NewBabelRankScene"
require "canon.scene.NewBabelScene"

local function getMaxClimbTimes()
	return MetaManager.getNewBabelSettings().challengeChance
end

NewBabelEnterPanel = class(Layer)

function NewBabelEnterPanel:ctor()
end

function NewBabelEnterPanel:create(container)
  self.container = container

  local panel = NewBabelEnterPanel.new()
  panel:initLayer()
  return panel
end

function NewBabelEnterPanel.enable()
  return true
end

function NewBabelEnterPanel:initLayer()
  NewBabelEnterPanel.super.initLayer(self)
  
  local bgSpirte = Sprite:create( "pic/icon_babel_Bg.png" )
  bgSpirte:setAnchorPoint(ccp(0, 0))
  --bgSpirte:setScale(2.0)
  bgSpirte:setPosition(ccp( 0, 119 ))
  self:addChild(bgSpirte)
	
  local builder = LayoutBuilder:createWithContentsOfFile( "scene/towerBabel.json" )
  self.towerBabelLayer = builder:build("towerBabel_main")
	self:addChild(self.towerBabelLayer)
	self.towerBabelLayer:setVisible(false)
	self.towerBabelLayer:getChildByName("txt_towerBabel_10_2"):setVisible(false)
	self.towerBabelLayer:getChildByName("txt_towerBabel_9_4"):getChildByName("txt"):setString(getTextByKey("skyTower_highStars"))
	self.towerBabelLayer:getChildByName("txt_towerBabel_9_3"):setVisible(false)
	self.towerBabelLayer:getChildByName("txt_towerBabel_9_2"):getChildByName("txt"):setString(getTextByKey("skyTower_highFloor"))
	self.towerBabelLayer:getChildByName("txt_towerBabel_9_1"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingChances"))
	self.towerBabelLayer:getChildByName("btn_challenge"):getChildByName("txt"):setString(getTextByKey("skyTower_enterBtn"))
	self.towerBabelLayer:getChildByName("btn_watchranking"):getChildByName("txt"):setString(getTextByKey("skyTower_rankingBtn"))
	
	local function onClickAttension(evt)
		self.container.targetInfoPanel = NewBabelAttensionPanel:create(self.container)
		PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
	end
	
	local function onClickChallenge(evt)
		if self.skyTowerData.currStatus.climbTimes >= getMaxClimbTimes() then
			SuspensionLabel:showContent(self.container, getTextByKey("skyTower_cannotChallenge"))
		else
			self.container:replaceScene(NewBabelScene)
		end
	end
	
	local function onClickWatchRank(evt)
		self.container:replaceScene(NewBabelRankScene)
	end
	
	local attensionButton = Button:create(self.towerBabelLayer:getChildByName("icon_qa"))
	attensionButton:addEventListener( Events.kStart, onClickAttension, self ) 
	
	self.challengeButton = Button:create(self.towerBabelLayer:getChildByName("btn_challenge"))
	self.challengeButton:addEventListener( Events.kStart, onClickChallenge, self ) 
	
	local watchRankButton = Button:create(self.towerBabelLayer:getChildByName("btn_watchranking"))
	watchRankButton:addEventListener( Events.kStart, onClickWatchRank, self )  
	
  local function onEnter(evt)
		local function checkNeedSendRequest()
			self:checkSendGetSkyTowerInfoRequest()
			if self.container.argv.enterScene == "BattleScene" and self.container.argv.params.haveReward then
				if not self.showedReward then
					self.container.targetInfoPanel = NewBabelFloorRewardPanel:create(self.container, self.skyTowerData, self.container.argv.params.floorRewards)
					PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
				end
			end
			self.showedReward = true;
		end
		if not self.checkNeedSendRequestSchedule then
			self.checkNeedSendRequestSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkNeedSendRequest, 1, false)
		end
		self:checkSendGetSkyTowerInfoRequest()
	end
	self:addEventListener(Events.kAddToStage, onEnter)
	
end

function NewBabelEnterPanel:refreshUI(skyTowerData)
	self.skyTowerData = skyTowerData
	self.towerBabelLayer:setVisible(true)
	self.towerBabelLayer:getChildByName("txt_towerBabel_buff"):getChildByName("txt"):setString(
	tostring(getMaxClimbTimes() - skyTowerData.currStatus.climbTimes))
	
	self.towerBabelLayer:getChildByName("txt_towerBabel_10_3"):getChildByName("txt"):setString(
	tostring(skyTowerData.currStatus.maxTotalStars))
	
	self.towerBabelLayer:getChildByName("txt_towerBabel_10_1"):getChildByName("txt"):setString(
	tostring(skyTowerData.currStatus.maxFloor))
	
	local challengeEnable = (self.skyTowerData.currStatus.climbTimes < getMaxClimbTimes())
	self.challengeButton:setEnable(challengeEnable)
	self.challengeButton.display:getChildByName("btn"):setVisible(challengeEnable)
end

function NewBabelEnterPanel:checkSendGetSkyTowerInfoRequest()
	local firstTime = false;
	if not self.skyTowerData then
		self.skyTowerData = DataManager.getSharkSkyTowerData()
		firstTime = true
	end
	local shouldRequest = false
	if self.skyTowerData == nil or next(self.skyTowerData) == nil then
		shouldRequest = true
	elseif self.skyTowerData.currStatus == nil or next(self.skyTowerData.currStatus) == nil then
		shouldRequest = true
	elseif self.skyTowerData.currStatus.days == nil or TimeUtil.calcPassedDays(TimeUtil.getServerTimeSeconds()) ~= self.skyTowerData.currStatus.days  then
		shouldRequest = true
	end
	if shouldRequest then
		self:sendGetSkyTowerInfoRequest()
	elseif firstTime then
		self:refreshUI(self.skyTowerData)
	end
end

function NewBabelEnterPanel:sendGetSkyTowerInfoRequest()
	local function onGetSkyTowerInfoSucceed(evt)
		self.waitRequest = false
		self:refreshUI(evt.data)
		self.skyTowerData = evt.data
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

function NewBabelEnterPanel:dispose()
	if self.checkNeedSendRequestSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkNeedSendRequestSchedule)
		self.checkNeedSendRequestSchedule = nil
	end
	Layer:dispose(self)
end
