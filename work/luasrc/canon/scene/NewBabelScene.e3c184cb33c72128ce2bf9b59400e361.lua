require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"

require "canon.panel.NewBabelEnterBuffPanel"
require "canon.panel.NewBabelFloorBuffPanel"
require "canon.panel.NewBabelFloorRewardPanel"
require "canon.panel.NewBabelRestartAfterDiePanel"
require "canon.panel.NewBabelSkipPanel"
require "canon.panel.NewBabelSkipFloorBuffPanel"

require "canon.request.ChallengeSkyTowerRequest"

NewBabelScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function NewBabelScene:ctor()
	self.title = getTextByKey("babel_title")
end

function NewBabelScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  local scene = NewBabelScene.new()		
  scene:initScene()
  return scene
end

function NewBabelScene:onInit()
	self.sharkSkyTowerData = DataManager.getSharkSkyTowerData()
	
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = self.builder:build("towerBabel_playergo")
	
	self.mainUI:getChildByName("txt_towerBabel_14"):getChildByName("txt"):setString(getTextByKey("skyTower_opponent"))
	self.mainUI:getChildByName("txt_towerBabel_13"):getChildByName("txt"):setString(getTextByKey("skyTower_self"))
	self.mainUI:getChildByName("txt_towerBabel_11"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
	self.mainUI:getChildByName("txt_towerBabel_9"):getChildByName("txt"):setString(getTextByKey("skyTower_totalStars"))
	self.mainUI:getChildByName("txt_towerBabel_7"):getChildByName("txt"):setString(getTextByKey("babel_presentFloor"))
	
	local fakeIcon = self.mainUI:getChildByName("normal_card_small")
	fakeIcon:setVisible(false)
	local queues = CommonManager.getQueueData( )
	local newMetaId = CommonManager:getSelfAvatarMetaByCardId( queues[1] )
	if newMetaId == 0 then
		newMetaId = CommonManager:getCardMetaByCardId(queues[1]).id
	end
	local icon = getHeadIconCanonCardByMetaId(newMetaId)
	icon:setPositionXY(fakeIcon:getPositionX(), fakeIcon:getPositionY())
	self.mainUI:addChildAt(icon, fakeIcon:getZOrder() + 1)
	
	local function onClickWatchRank(evt)
		self:replaceScene(NewBabelRankScene, {enterScene="NewBabelScene",returnScene="NewBabelScene",params={}})
	end
	
	self.mainUI:getChildByName("btn_ranking"):getChildByName("txt"):setString(getTextByKey("babel_rankingTitle"))
	local watchRankButton = Button:create(self.mainUI:getChildByName("btn_ranking"))
	watchRankButton:addEventListener( Events.kStart, onClickWatchRank, self )  
	
	local function onClickAttension(evt)
		self.targetInfoPanel = NewBabelAttensionPanel:create(self)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	
	local attensionButton = Button:create(self.mainUI:getChildByName("icon_qa"))
	attensionButton:addEventListener( Events.kStart, onClickAttension, self ) 
	
	local function onChallengeSkyTowerSucceed(evt)
		self.waitRequest = false
		local curStatus = self.sharkSkyTowerData.currStatus
		local function clearOneClimb()
			curStatus.climbTimes = curStatus.climbTimes + 1
			curStatus.currTotalStars = 0
			curStatus.currUsedStars = 0
			curStatus.currFloor = 0
			curStatus.gainFloorBuff = {}
			curStatus.selfAtkBuff = 0
			curStatus.selfDefBuff = 0
			curStatus.selfHpBuff = 0
			curStatus.enemyAtkDebuff = 0
			curStatus.enemyDefDebuff = 0
		end
		local forbidSkip = true
		local haveReward = false
		local currTotalStars = curStatus.currTotalStars
		local currFloor = curStatus.currFloor
		local firstTimeBigWin = false
		local clearNewBabel = false
		if self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor >= curStatus.currFloor + 1 then
			forbidSkip = false
		end
		if evt.data.win then
			curStatus.currFloor  = curStatus.currFloor + 1
			haveReward = (MetaManager.sky_tower_level[curStatus.currFloor].haveReward == 1)
			if curStatus.currFloor > self.sharkSkyTowerData.currStatus.maxFloor then
				self.sharkSkyTowerData.currStatus.maxFloor = curStatus.currFloor
			end
			local victoryStarsBonus = 1
			local GameMetaData = MetaManager.game_meta
			if evt.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
				victoryStarsBonus = 1
			elseif evt.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
				victoryStarsBonus = 3
				if curStatus.currFloor == self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor + 1 and self.selectDifficult == 3 then
					self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor = self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor + 1
					firstTimeBigWin = true
				end
			else
				victoryStarsBonus = 2
			end
			self.sharkSkyTowerData.currStatus.currTotalStars  = self.sharkSkyTowerData.currStatus.currTotalStars + self.selectDifficult * victoryStarsBonus
			if self.sharkSkyTowerData.currStatus.currTotalStars > self.sharkSkyTowerData.currStatus.maxTotalStars then
				self.sharkSkyTowerData.currStatus.maxTotalStars = self.sharkSkyTowerData.currStatus.currTotalStars
			end
			
			currTotalStars = curStatus.currTotalStars
			currFloor = curStatus.currFloor
			if not MetaManager.sky_tower_level[curStatus.currFloor + 1] then-- all clear
				clearOneClimb()
				clearNewBabel = true;
			end
		else--fail
			-- clearOneClimb()
			curStatus.climbTimes = curStatus.climbTimes + 1
		end
		DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)
		evt.data.forbidSkip = false--改成无论如何都允许跳过！
		evt.data.monsterGroupId = self.battleDifficultInfos[self.selectDifficult].monsterGroupId
		evt.data.haveTimesLeft = (curStatus.climbTimes < MetaManager.getNewBabelSettings().challengeChance)
		evt.data.selectDifficult = self.selectDifficult
		evt.data.haveReward = haveReward
		evt.data.currTotalStars = currTotalStars
		evt.data.currFloor = currFloor
		evt.data.firstTimeBigWin = firstTimeBigWin
		evt.data.clearNewBabel = clearNewBabel
		Director:sharedDirector():replaceScene(BattleScene:create(evt.data, BattleBackType.kNewBabel, BattleEnterEnum.kNewBabel))
	end
	
	local function onChallengeSkyTowerFailed(evt)
		self.waitRequest = false
		if evt.data == 713512 then
			local function closeCanonMessageBox()
				self:sendGetSkyTowerInfoRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713513 then
			local function closeCanonMessageBox()
				self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_cannotChallenge"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function onClickChallenge(evt)
		if BagCalcManager.isFull() then
			NewPackageFullPanel:show()
			-- SuspensionLabel:showContent(self, getTextByKey("babel_inventoryFull"))
			do return end
		end
		if self.waitRequest then
			do return end
		end
		self.waitRequest = true
		self.selectDifficult = tonumber(evt.context) + 1
		local testData = {data = readBattleInfo()}
		testData.data.floorRewards = {}
		testData.data.win = false
		--onChallengeSkyTowerSucceed(testData)
		--do return end
		local request = ChallengeSkyTowerRequest.new( {floor = (self.sharkSkyTowerData.currStatus.currFloor + 1), type = evt.context , version = 1}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.ChallengeSkyTowerSucceed, onChallengeSkyTowerSucceed )
		request:addEventListener( RequestNotifyEnum.ChallengeSkyTowerFailed, onChallengeSkyTowerFailed )
		request:start()
	end
	
	local difficultyTextKeyTable = {"skyTower_difficulty_easy", "skyTower_difficulty_normal", "skyTower_difficulty_hell"}
	local starCoefTable = {"easyStarCoef", "normalStarCoef", "hardStarCoef"}
	
	self.challengeButton = {}
	for i = 1, 3 do
		local difficultyNode = self.mainUI:getChildByName("select_mode_" .. i)
		difficultyNode:getChildByName("normal_card_small"):setVisible(false)
		difficultyNode:getChildByName("txt_towerBabel_6"):getChildByName("txt"):setString(getTextByKey(difficultyTextKeyTable[i]))
		difficultyNode:getChildByName("txt_towerBabel_6_1"):getChildByName("txt"):setString(getTextByKey("skyTower_difficulty"))
		difficultyNode:getChildByName("txt_towerBabel_6_2"):getChildByName("txt"):setString(getTextByKey("skyTower_difficulty_star"))
		difficultyNode:getChildByName("txt_towerBabel_6_3"):getChildByName("txt"):setString(tostring(MetaManager.getNewBabelSettings()[starCoefTable[i]]))
		difficultyNode:getChildByName("txt_towerBabel_6_4"):getChildByName("txt"):setString(getTextByKey("skyTower_difficulty_multiplier"))
		difficultyNode:getChildByName("btn_gofight"):getChildByName("txt"):setString(getTextByKey("babel_challengeBtn"))--btn
		self.challengeButton[i] = Button:create(difficultyNode:getChildByName("btn_gofight"))
		self.challengeButton[i]:addEventListener( Events.kStart, onClickChallenge, (i - 1) ) 
	end

	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

	if self.sharkSkyTowerData.currStatus.dead then
		self.targetInfoPanel = NewBabelRestartAfterDiePanel:create(self, self.sharkSkyTowerData,  refreshUI)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	self:refreshUI(true)
end

function NewBabelScene:checkHavePopoutPanel()--检测是否需要弹出奖励或者BUFF加成弹框
	local function refreshUI()
		self:refreshUI()
		self:checkHavePopoutPanel()
	end
	
	local function isGainFloorBuff(curFloor)
		local ret = false
		if self.sharkSkyTowerData.currStatus then
			if type(self.sharkSkyTowerData.currStatus.gainFloorBuff) == "table" then
				for k, data in pairs(self.sharkSkyTowerData.currStatus.gainFloorBuff) do
					if data == curFloor then
						ret = true
						break;
					end
				end
			end
		end
		return ret
	end
	
	-- 跳过阶段
	if self.sharkSkyTowerData.currStatus.skipBattle then
		local function showSkipRewardsPanel()
			local function callbackFunc()
				self.sharkSkyTowerData = DataManager.getSharkSkyTowerData()
				if not MetaManager.sky_tower_level[self.sharkSkyTowerData.currStatus.currFloor + 1] then-- all clear
					self.sharkSkyTowerData.currStatus.climbTimes = self.sharkSkyTowerData.currStatus.climbTimes + 1
					self.sharkSkyTowerData.currStatus.currTotalStars = 0
					self.sharkSkyTowerData.currStatus.currUsedStars = 0
					self.sharkSkyTowerData.currStatus.currFloor = 0
					self.sharkSkyTowerData.currStatus.gainFloorBuff = {}
					self.sharkSkyTowerData.currStatus.selfAtkBuff = 0
					self.sharkSkyTowerData.currStatus.selfDefBuff = 0
					self.sharkSkyTowerData.currStatus.selfHpBuff = 0
					self.sharkSkyTowerData.currStatus.enemyAtkDebuff = 0
					self.sharkSkyTowerData.currStatus.enemyDefDebuff = 0
					DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)
				end
				self:refreshUI(true)
			end
			local aBabelSkipPanel = NewBabelSkipPanel:create(self , 2 , callbackFunc)
			self:addChild(aBabelSkipPanel)
			aBabelSkipPanel:scaleIn()
		end
		if DataManager.getSharkSkyTowerNeedAddFloor() == 0 then
			showSkipRewardsPanel()
		else
			-- 造假星星
			local targetFloor = DataManager.getSharkSkyTowerNeedAddFloor()
			local skipFloorNum = targetFloor - self.sharkSkyTowerData.currStatus.currFloor
			-- 3 代表最高难度 和 不掉血过关
			local starGained = 3 * 3 * skipFloorNum
			self.sharkSkyTowerData.currStatus.currTotalStars  = self.sharkSkyTowerData.currStatus.currTotalStars + starGained
			self.sharkSkyTowerData.currStatus.currFloor = targetFloor
			DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)

			self.targetInfoPanel = NewBabelSkipFloorBuffPanel:create(self, self.sharkSkyTowerData, showSkipRewardsPanel)
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
		end
	elseif self.argv.enterScene == "BattleScene" and self.argv.params.haveReward then --reward
		self.argv.params.haveReward = false;
		self.targetInfoPanel = NewBabelFloorRewardPanel:create(self, self.sharkSkyTowerData, self.argv.params.floorRewards, refreshUI)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	elseif self.sharkSkyTowerData.currStatus.currFloor == 0 and self.sharkSkyTowerData.pastStatus and self.sharkSkyTowerData.pastStatus.maxTotalStars > 0 then--yesterday
		if not isGainFloorBuff(self.sharkSkyTowerData.currStatus.currFloor) then
			local existInRank = false
			if type(self.sharkSkyTowerData.pastRanks) == "table" then
				for k,data in pairs(self.sharkSkyTowerData.pastRanks) do
					if data.uid == self.sharkSkyTowerData.sharkSkyTower.uid then
						existInRank = true
						break;
					end
				end
			end
			if not existInRank then
				self.targetInfoPanel = NewBabelEnterBuffPanel:create(self, self.sharkSkyTowerData,  refreshUI)
				PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
			end
		end
	elseif MetaManager.sky_tower_level[self.sharkSkyTowerData.currStatus.currFloor + 1].haveBuff == 1 then  --floor
		if not isGainFloorBuff(self.sharkSkyTowerData.currStatus.currFloor + 1) then
			self.targetInfoPanel = NewBabelFloorBuffPanel:create(self, self.sharkSkyTowerData,  refreshUI)
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
		end
	end
	
end

function NewBabelScene:refreshUI(refreshMonster)--刷新界面
	if self.sharkSkyTowerData.currStatus.climbTimes >= MetaManager.getNewBabelSettings().challengeChance then
		self:back()
		return
	end

	self.mainUI:getChildByName("txt_towerBabel_buff_a2"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyAtkDebuff))
	self.mainUI:getChildByName("txt_towerBabel_buff_a1"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyDefDebuff))
	self.mainUI:getChildByName("txt_towerBabel_buff_d2"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfAtkBuff) * 100) .. "%")
	self.mainUI:getChildByName("txt_towerBabel_buff_d1"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfDefBuff) * 100) .. "%")
	self.mainUI:getChildByName("txt_towerBabel_buff_d0"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfHpBuff) * 100) .. "%")
	self.mainUI:getChildByName("txt_towerBabel_12"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars))
	self.mainUI:getChildByName("txt_towerBabel_10"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars))
	self.mainUI:getChildByName("txt_towerBabel_8"):getChildByName("txt"):setString(Localization:getInstance():getText("babel_floor", {num = self.sharkSkyTowerData.currStatus.currFloor}))
	print("..............."..table.tostring(self.sharkSkyTowerData.currStatus))
	if self.sharkSkyTowerData.currStatus.currFloor < self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor then
		local pic = self.mainUI:getChildByName("btn_canskip")
		pic:setVisible(true)
		local btn = Button:create(pic)

		local function onClick()
			local function callbackFunc()
				self.sharkSkyTowerData = DataManager.getSharkSkyTowerData()
				self:refreshUI()
				self:checkHavePopoutPanel()
			end

			local aBabelSkipPanel = NewBabelSkipPanel:create(self , 1 , callbackFunc)
			self:addChild(aBabelSkipPanel)
			aBabelSkipPanel:scaleIn()
		end
		btn:addEventListener(Events.kStart, onClick)
	else
		self.mainUI:getChildByName("btn_canskip"):setVisible(false)
	end
	if refreshMonster then
		self.battleDifficultInfos = {}
		local newBabelSetting = MetaManager.getNewBabelSettings()
		for i = 0, 2 do
			local battleDifficultInfo = {}
			local difficultyNode = self.mainUI:getChildByName("select_mode_" .. tostring(i + 1))
			local monster = difficultyNode:getChildByName("monsterCard")
			if monster then
				monster:removeFromParentAndCleanup(true)
			end
			local monsterGroupCalcNum = ((((i * newBabelSetting.monsterReviseHashPrime % newBabelSetting.hashModPrime 
			+ self.sharkSkyTowerData.currStatus.climbTimes * newBabelSetting.challengeTimeHashPrime) % newBabelSetting.hashModPrime 
			+ (self.sharkSkyTowerData.currStatus.currFloor + 1) * newBabelSetting.floorHashPrime) % newBabelSetting.hashModPrime
			+ self.sharkSkyTowerData.currStatus.days * newBabelSetting.dateHashPrime ) % newBabelSetting.hashModPrime
			+ self.sharkSkyTowerData.sharkSkyTower.uid * newBabelSetting.userIdHashPrime ) % newBabelSetting.hashModPrime
			local monsterRandomGroupNum = MetaManager.random_number_table[monsterGroupCalcNum % table.getn(MetaManager.random_number_table) + 1] % 10
			local monsterGroup
			local leaderMonster
			for k, data in pairs(MetaManager.sky_tower_monster) do
				if (self.sharkSkyTowerData.currStatus.currFloor + 1) >= data.startFloor and (self.sharkSkyTowerData.currStatus.currFloor + 1) <= data.endFloor then
					monsterGroup = MetaManager.battle_monster_group[data["randomMonsterGroup" .. monsterRandomGroupNum]]
					break;
				end
			end
			if monsterGroup then
				battleDifficultInfo.monsterGroupId = monsterGroup.id
				leaderMonster = MetaManager.battle_monster[tonumber(string.split(monsterGroup.monsterIdList, '|')[1])]

				if leaderMonster then
					local fakeIcon = difficultyNode:getChildByName("normal_card_small")
					local monsterHead = getBackpackHeadIconCanonCardByMetaId(leaderMonster.cardId)
					monsterHead.name = "monsterCard"
					monsterHead:setPositionXY(fakeIcon:getPositionX(), fakeIcon:getPositionY())
					difficultyNode:addChildAt(monsterHead, fakeIcon:getZOrder() + 1)
				end
			end
			self.battleDifficultInfos[i + 1] = battleDifficultInfo
		end
		self:checkHavePopoutPanel()
	end
	
end

function NewBabelScene:dispose()	
	if self.checkNeedSendRequestSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkNeedSendRequestSchedule)
		self.checkNeedSendRequestSchedule = nil
	end
	BaseUIScene.dispose(self)
end

function NewBabelScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function NewBabelScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function NewBabelScene:startEnterAnimation()
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

function NewBabelScene:checkSendGetSkyTowerInfoRequest()--检测是否需要刷新通天塔信息
	if not self.sharkSkyTowerData then
		self.sharkSkyTowerData = DataManager.getSharkSkyTowerData()
	end

	local shouldRequest = false
	if self.sharkSkyTowerData == nil or next(self.sharkSkyTowerData) == nil then
		shouldRequest = true
	elseif self.sharkSkyTowerData.currStatus == nil or next(self.sharkSkyTowerData.currStatus) == nil then
		shouldRequest = true
	elseif self.sharkSkyTowerData.currStatus.days == nil or TimeUtil.calcPassedDays(TimeUtil.getServerTimeSeconds()) ~= self.sharkSkyTowerData.currStatus.days  then
		shouldRequest = true
	end
	if shouldRequest then
		self:sendGetSkyTowerInfoRequest()
	end
end

function NewBabelScene:sendGetSkyTowerInfoRequest()--重新拉取通天塔信息
	local function onGetSkyTowerInfoSucceed(evt)
		self.waitRequest = false
		self.sharkSkyTowerData = evt.data
		self:refreshUI(true)
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

function NewBabelScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	local function checkNeedSendRequest()
		self:checkSendGetSkyTowerInfoRequest()
	end
	if not self.checkNeedSendRequestSchedule then
		self.checkNeedSendRequestSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkNeedSendRequest, 1, false)
	end
	checkNeedSendRequest()
end

function NewBabelScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function NewBabelScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function NewBabelScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function NewBabelScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function NewBabelScene:back()
  self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
end

function NewBabelScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		self.mainUI:setTouchEnabled(v)
	end
end
