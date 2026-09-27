sacrifice_already_showed = false

local function getUserBackpackSpaceByLevel(level)
	local boughtSpace = DataManager.getGameInitData().sharkUserExtend.boughtGridNum
	local levelSpace = MetaManager.user_level[level].gridNum
	local vipSpace = MetaManager.vip_setting[DataManager.getGameInitData().sharkUser.vipLevel].extraInventorySlots
	return boughtSpace + levelSpace + vipSpace
end

local function gotoArena( evt )
  	local function getArenaMatchedPlayersSucceed(event)  
	    ArenaManager:sharedManager():resetArenaData(event.data)
      
      if ArenaManager:sharedManager():whetherRequestForArenaScore() then
        local function gainArenaScoreByRankSucceed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            RewardManager:getReward({event.data.reward})
            ArenaManager:sharedManager():gainArenaScoreByRank(event.data.reward.amount)
            Director:sharedDirector():replaceScene(ArenaRankScene:create())
        end 
        local function gainArenaScoreByRankFailed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            if event.data.retCode == 712407 then
            
            end
            Director:sharedDirector():replaceScene(ArenaRankScene:create())
        end
        local params = {}
        local request = GainArenaScoreByRankRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankSucceed, gainArenaScoreByRankSucceed)
        request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankFailed, gainArenaScoreByRankFailed)
        request:start()
      else
        Director:sharedDirector():replaceScene(ArenaRankScene:create())
      end
	    
  	end 
	local function getArenaMatchedPlayersFailed(event)
		if event.data.retCode == 712400 then
	  		local aContent = Localization:getInstance():getText("arena_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel})
	  		SuspensionLabel:showContent(Director():sharedDirector():getRunningScene(), aContent)
		end
	end
	local params = {}
	local request = GetArenaMatchedPlayersRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersSucceed, getArenaMatchedPlayersSucceed)
	request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersFailed, getArenaMatchedPlayersFailed)
	request:start()
end	

local gotoCardTrain = function()
	local scene = CardQueueScene:create()
	Director:sharedDirector():replaceScene(scene)
	ExeNewGuide(GuideConfig.kCardTrain)
end

local gotoBabel = function()
  --[[
	local function Success(event)
		if event ~= nil then
		  	DataManager.GetBabelInfoData = event.data
        DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
		end
		Director:sharedDirector():replaceScene(SkyTowerMainScene:create())
	end
	local function Failed(event)
		if event.data == 713103 then
		  SuspensionLabel:showContent(Director:sharedDirector():getRunningScene(), Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
		end
	end
	local params = {}
	local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
	getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success)
	getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Failed)
	getBabelInfoRequest:start()]]
  ChallengeEntersScene.readyToNewBabelEnterPanel()
end

local gotoMatrix = function()
	Director:sharedDirector():replaceScene(MatrixScene:create())
end

local gotoCowStage = function()
	Director:sharedDirector():replaceScene(ActivityPanelScene:create({selectPanelName = "Activity_CowStage"}))
end

local gotoBeast = function ()
  local function doPrerationSucceed(fragmentsInfo)
			local argv = {enterScene="",returnScene="",params={fragmentsInfo=fragmentsInfo}}
      Director:sharedDirector():replaceScene(BeastScene:create(argv))
		end
				
		local function doPrerationFailed()
			Director():sharedDirector():getRunningScene().isChangeingScene = false
		end
  
  BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
end

local gotoUnion = function()
	UnionManager.gotoUnionListScene()
end

local gotoPKScene = function()
  Director:sharedDirector():replaceScene(PKScene:create())
end

local gotoRebirthScene = function()
	Director:sharedDirector():replaceScene(CardRebirthScene:create())
end

local gotoContend = function()
	Director:sharedDirector():replaceScene(ActivityPanelScene:create({selectPanelName = "Activity_Contend"}))
end

local gotoDestinyFight = function()
	Director:sharedDirector():replaceScene(ChallengeEntersScene:create({params = {showPanelName = "destiny"}}))
end

local gotoCardFate = function()
	local scene = CardQueueScene:create()
	Director:sharedDirector():replaceScene(scene)
end

local gotoBreak = function()
	Director:sharedDirector():replaceScene(CardRebirthScene:create({params = {showPanelIndex = 3}}))
end

local gotoActivityFountain = function()
	Director:sharedDirector():replaceScene(ActivityPanelScene:create({selectPanelName = "Activity_FountainWish"}))
end

local gotoCompeteScene = function ()
	local scene = CompeteScene:create()
	Director:sharedDirector():replaceScene(scene)
end

local gotoTreasureGachaScene = function ()
	local scene = TreasureGachaScene:create()
	Director:sharedDirector():replaceScene(scene)
end

local userUnlockConfig = {
  	{level = 9, text = "levelup_beastUnlock", gotoFunc = gotoBeast},
	{level = 15, text = "matrix_unlock_remind", gotoFunc = gotoMatrix},
	{level = 19, text = "levelup_cardTrainingUnlock", gotoFunc = gotoCardTrain},
	{level = 20, text = "levelup_arenaUnlock", gotoFunc = gotoArena},
	{level = 22, text = "levelup_unionUnlock", gotoFunc = gotoUnion},
	{level = 25, text = "levelup_babelUnlock", gotoFunc = gotoBabel},
	{level = 27, text = "levelup_contend", gotoFunc = gotoContend},
	{level = 30, text = "levelup_cowStageUnlock", gotoFunc = gotoCowStage},
	{level = 31, text = "levelup_pkUnlock", gotoFunc = gotoPKScene},
	{level = 35, text = "levelup_rebirthUnlock", gotoFunc = gotoRebirthScene},
	{level = 40, text = "levelup_destinyBattleUnlock", gotoFunc = gotoDestinyFight},
	{level = 42, text = "activity_fountainWish_guide2", gotoFunc = gotoActivityFountain},
	{level = 43, text = "Lineup_guide1", gotoFunc = gotoCardFate},
	{level = 45, text = "cardSplit_help1", gotoFunc = gotoBreak},
	{level = 50, text = "crossArena_babytalk", gotoFunc = gotoCompeteScene},
	{level = TreasureManager.getTreasureUserLevel(), text = "Treasure_help", gotoFunc = gotoTreasureGachaScene},
	{level = 80, text = "cardFate_tips8", gotoFunc = gotoCardFate},
	{level = "MagicCircle", text = "magicCircle_babytalk", gotoFunc = gotoMatrix},
}

local function needShowUnlock(newLevel)
	local showUnlock = false
	for k,v in pairs(userUnlockConfig) do
		if v.level == newLevel then
			if v.level == 30 and not MaintenanceManager.isActivityOpen("cowStage") then
				break
			elseif v.level == 50 and not CrossArenaManager.checkPVPIsOpen() then
				break
			else
				showUnlock = true
				break
			end
		end
	end
	return showUnlock
end

local userLevelUpZOrder = 1000

UserLevelupBox = class(Layer)

function UserLevelupBox:ctor()
	self.panelUI = nil
	self.callback = nil
end

function UserLevelupBox:create(arg, callback)
	self.callback = callback
	local layer = UserLevelupBox.new()
	layer:initLayer(arg)
	return layer
end

function UserLevelupBox:initLayer(arg)
	UserLevelupBox.super.initLayer(self)

	local userData = DataManager.getCurrUser()
	local currentLevel = userData.level
	if currentLevel >= arg.level then
		currentLevel = arg.level - 1
	end

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup_levelup1")
	
	self.panelUI:getChildByName("common_txt_bestrong"):getChildByName("txt"):setString(getTextByKey("levelup_title"))
	self.panelUI:getChildByName("common_txt_Leadership"):getChildByName("txt"):setString(getTextByKey("levelup_leadershipPoints"))
	self.panelUI:getChildByName("common_txt_maxfriend"):getChildByName("txt"):setString(getTextByKey("levelup_maxFriends"))
	self.panelUI:getChildByName("common_txt_bag"):getChildByName("txt"):setString(getTextByKey("levelup_inventorySlots"))
	self.panelUI:getChildByName("common_txt_battlecard"):getChildByName("txt"):setString(getTextByKey("levelup_formationCards"))
	self.panelUI:getChildByName("common_txt_staminainfo"):getChildByName("txt"):setString(getTextByKey("levelup_recoverText1"))
	self.panelUI:getChildByName("common_txt_energyinfo"):getChildByName("txt"):setString(getTextByKey("levelup_recoverText2"))
	self.panelUI:getChildByName("common_dot"):getChildByName("txt_propInfo_desc"):setString(getTextByKey("levelup_recoverText3"))
	self.panelUI:getChildByName("common_dot2"):getChildByName("txt_propInfo_desc"):setString(getTextByKey("levelup_recoverText3"))

	self.panelUI:getChildByName("common_stamina_up"):getChildByName("txt"):setString(tonumber(MetaManager.game_meta.gameSettingConfig.energyGainedByLevelUp))
	self.panelUI:getChildByName("common_energyinfo_up"):getChildByName("txt"):setString(tonumber(MetaManager.game_meta.gameSettingConfig.eventPointGainedByLevelUp))

	self.panelUI:getChildByName("common_txt"):getChildByName("txt"):setString(string.gsub(getTextByKey("levelup_level"), "{num}", arg.level))


	local currentData = MetaManager.user_level[currentLevel]
	local oldBagSpace = getUserBackpackSpaceByLevel(currentLevel)
	arg.noChatEndSeconds = userData.noChatEndSeconds
	DataManager.setCurrUser(arg)
	local newData = MetaManager.user_level[arg.level]
	local totalBagSpace = getUserBackpackSpaceByLevel(arg.level)
	local vipLeadPoint = MetaManager.vip_setting[DataManager.getGameInitData().sharkUser.vipLevel].extraLeadershipPoints

	self.panelUI:getChildByName("common_leadership_figure"):getChildByName("txt"):setString(currentData.leadPoint + vipLeadPoint)
	self.panelUI:getChildByName("common_maxfriend_figure"):getChildByName("txt"):setString(currentData.friendMax)
	self.panelUI:getChildByName("common_bag_figure"):getChildByName("txt"):setString(oldBagSpace)
	self.panelUI:getChildByName("common_battlecard_figure"):getChildByName("txt"):setString(currentData.maxQueueCardNum)

	self.panelUI:getChildByName("common_leadership_figure_up"):getChildByName("txt"):setString(newData.leadPoint + vipLeadPoint)
	self.panelUI:getChildByName("common_maxfriend_figure_up"):getChildByName("txt"):setString(newData.friendMax)
	self.panelUI:getChildByName("common_bag_figure_up"):getChildByName("txt"):setString(totalBagSpace)
	self.panelUI:getChildByName("common_battlecard_figure_up"):getChildByName("txt"):setString(newData.maxQueueCardNum)

	--通知BaseUIScene
	if not g_isInBattleScene then
    	BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged,arg))
    end

	local function onConfirmButtonClicked( )
		local rewardId = MetaManager.user_level[arg.level].levelUpReward
		local rewardContent = MetaManager.reward_package[rewardId]
		if rewardContent.content1Type == 0 then
			if needShowUnlock(arg.level) then
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
				local newBox = UserUnlockContentBox:create(arg.level, self.callback)
				PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
			else
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
				if self.callback and type(self.callback) == "function" then
					self.callback()
				end
			end
		else
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			local newBox = UserLevelupRewardBox:create(arg.level, self.callback)
			PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
		end

		--初始化阵容状态
		if arg.level == (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
			local gameData = DataManager.getGameInitData()
			local cardData = DataManager.getCardsData()
			local mainCardId = gameData.sharkUser.mainCardId
			for BattleArrayId = 1,3 do 
				gameData.sharkUserBattleArray[BattleArrayId] = {}
				gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue = {}
				gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices = {}
				gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices = DataManager.getSharkMatricesData() 
				if BattleArrayId == 1 then 
					local teamData = CommonManager.getQueueData()
					for k,v in pairs(teamData) do
						for _,value in pairs(cardData) do
							if v == value.cardId then		
								local params = {cardId = v,equips = value.equipIds,spirits = value.cardSpirits}						
								table.insert(gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue,params)
								break
							end 
						end
					end
				else
					local params = {cardId = mainCardId,equips = {},spirits = {}}		
					table.insert(gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue,params)

					for k,v in pairs(gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices) do
						v.sharkMatrixGrids = {}
					end
				end
			end
			DataManager.setGameInitData(gameData)
			--多阵容
			if GuideConfig.kMultiLineupBox == nil then
				GuideConfig.kMultiLineupBox = "Guide_MultiLineupBox"
			end
			if not IsGuideExecuted(GuideConfig.kMultiLineupBox) then  
				local gameData = DataManager.getGameInitData()
		  		table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_MultiLineupBox",step = 1})
		  		DataManager.setGameInitData(gameData)
		  		local params = {funcName = "Guide_MultiLineupBox",step = 1}
	        	local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
	        	request:start()
	        end
		end

		--宝物
		if arg.level == (TreasureManager.getTreasureUserLevel()) then 
			if GuideConfig.kTreasureBox == nil then
				GuideConfig.kTreasureBox = "Guide_TreasureBox"
			end
			if not IsGuideExecuted(GuideConfig.kTreasureBox) then  
				local gameData = DataManager.getGameInitData()
		  		table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_TreasureBox",step = 1})
		  		DataManager.setGameInitData(gameData)
		  		local params = {funcName = "Guide_TreasureBox",step = 1}
	        	local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
	        	request:start()
	        end
	    end

        --此时已经弹过框了~
		if GuideConfig.kCrossPVPBox == nil then
			GuideConfig.kCrossPVPBox = "Guide_CrossPVPBox"
		end
		if not IsGuideExecuted(GuideConfig.kCrossPVPBox) then  
			local gameData = DataManager.getGameInitData()
	  		table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_CrossPVPBox",step = 1})
	  		DataManager.setGameInitData(gameData)
	  		local params = {funcName = "Guide_CrossPVPBox",step = 1}
        	local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
        	request:start()
        end
	end

	local comfirmBtn = Button:create(self.panelUI:getChildByName("common_btn_sure"))
	comfirmBtn:addEventListener( Events.kStart, onConfirmButtonClicked, self )

	self.panelUI:getChildByName("common_btn_sure"):getChildByName("txt"):setString(getTextByKey("yes"))

	self:addChild(self.panelUI)
end

UserLevelupRewardBox = class(Layer)

function UserLevelupRewardBox:ctor()
	self.panelUI = nil
	self.callback = nil
end

function UserLevelupRewardBox:create(newLevel, callback)
	self.callback = callback
	local layer = UserLevelupRewardBox.new()
	layer:initLayer(newLevel)
	return layer
end

function UserLevelupRewardBox:initLayer(newLevel)
	UserLevelupRewardBox.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup_levelup2")

	self.panelUI:getChildByName("common_txt_levelupreward"):getChildByName("txt"):setString(getTextByKey("levelup_rewardText1"))

	local itemBox = self.panelUI:getChildByName("common_normal_card_small")
	itemBox:setVisible(false)
	local rewardId = MetaManager.user_level[newLevel].levelUpReward
	local rewardContent = MetaManager.reward_package[rewardId]
	local posX, posY = itemBox:getPosition().x, itemBox:getPosition().y
	local rewardName = nil
	local GameData = DataManager.getGameInitData()

	if rewardContent.content1Type == 1 then
		local coinIcon = Sprite:create("common/CoinIcon.png")
	    coinIcon:setPosition(ccp(posX, posY))
	    self.panelUI:addChild(coinIcon)
		GameData.sharkUser.coins = ""..(tonumber(GameData.sharkUser.coins) + tonumber(rewardContent.content1Amount))
		rewardName = getTextByKey("resource_silverCoin")
		DataManager.setGameInitData(GameData)
	elseif rewardContent.content1Type == 2 then
		local gemIcon = Sprite:create("common/GemIcon.png")
	    gemIcon:setPosition(ccp(posX, posY))
	    self.panelUI:addChild(gemIcon)
	    GameData.sharkUser.freeGems = GameData.sharkUser.freeGems + tonumber(rewardContent.content1Amount)
	    rewardName = getTextByKey("resource_goldCoin")
	    DataManager.setGameInitData(GameData)
	elseif rewardContent.content1Type == 7 then
		local itemMeta = MetaManager.prop_meta[rewardContent.content1Id]
		local item = CanonItem:create()
		item:loadByMetaId(rewardContent.content1Id)
		item:setPosition(ccp(posX, posY))
		self.panelUI:addChild(item)
		local newReward = {
			{
				amount = rewardContent.content1Amount,
				exp = 0,
				id = 0,
				level = 0,
				itemType = 7,
				metaId = rewardContent.content1Id
			}
		}
		if itemMeta == nil then
	        rewardName = "Prop"..rewardInfo.reward.metaId
	    else
	        rewardName = getTextByKey(itemMeta.name)
	    end 
		RewardManager:getReward(newReward)
	end
	self.panelUI:getChildByName("common_txt_holyfont"):setZOrder(20)
	self.panelUI:getChildByName("common_txt_holyfont"):getChildByName("txt"):setString("x"..rewardContent.content1Amount)
	self.panelUI:getChildByName("common_txt_itemname"):getChildByName("txt"):setString(tostring(rewardName))

	if not g_isInBattleScene then
		BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged, nil))
	end

	if needShowUnlock(newLevel) then
		local function onConfirmButtonClicked( )
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			local newBox = UserUnlockContentBox:create(newLevel, self.callback)
			PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
		end

		local comfirmBtn = Button:create(self.panelUI:getChildByName("common_btn_sure"))
		comfirmBtn:addEventListener( Events.kStart, onConfirmButtonClicked, self )

		self.panelUI:getChildByName("common_btn_close"):setVisible(false)
		self.panelUI:getChildByName("common_btn_getreward"):setVisible(false)

		self.panelUI:getChildByName("common_btn_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	else
		local function onConfirmButtonClicked()
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			if self.callback and type(self.callback) == "function" then
				self.callback()
			end
		end

		local comfirmBtn = Button:create(self.panelUI:getChildByName("common_btn_sure"))
		comfirmBtn:addEventListener( Events.kStart, onConfirmButtonClicked, self )

		self.panelUI:getChildByName("common_btn_close"):setVisible(false)
		self.panelUI:getChildByName("common_btn_getreward"):setVisible(false)

		self.panelUI:getChildByName("common_btn_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	end

	self:addChild(self.panelUI)
end

UserUnlockContentBox = class(Layer)

function UserUnlockContentBox:ctor()
	self.callback = nil
	self.panelUI = nil
end

function UserUnlockContentBox:create(newLevel, callback)
	self.callback = callback
	local layer = UserUnlockContentBox.new()
	layer:initLayer(newLevel)
	return layer
end

function UserUnlockContentBox:initLayer(newLevel)
	UserUnlockContentBox.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup_levelup3")

	self.panelUI:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("levelup_newSystemText"))

	local config = nil
	for k,v in pairs(userUnlockConfig) do
		if v.level == newLevel then
			config = v
		end
	end
	if config == nil then
		print("read levelupConfigs failed!! newLevel = " .. tostringRich(newLevel))
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if self.callback and type(self.callback) == "function" then
			self.callback()
		end
	end
	
	if config.level == "MagicCircle" then
		self.panelUI:getChildByName("common_font_levelup"):setVisible(false)
	end
	self.panelUI:getChildByName("common_txt_morefunction"):getChildByName("txt"):setString(getTextByKey(config.text))

	local function onCloseButtonClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if self.callback and type(self.callback) == "function" then
			self.callback()
		end
	end

	local function onGotoButtonClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if config.gotoFunc and type(config.gotoFunc) == "function" then
			config.gotoFunc()
		end
	end

	local closeBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
	closeBtn:addEventListener( Events.kStart, onCloseButtonClicked, self )

	self.panelUI:getChildByName("common_btn_close"):getChildByName("txt"):setString(getTextByKey("yes"))

	local gotoBtn = Button:create(self.panelUI:getChildByName("common_btn_goarena"))
	gotoBtn:addEventListener( Events.kStart, onGotoButtonClicked, self)

	self.panelUI:getChildByName("common_btn_goarena"):getChildByName("txt"):setString(getTextByKey("levelup_goBtn"))

	self:addChild(self.panelUI)
end

local action_time_for_exp = 0.8
local loadingLayer = nil
local loadingLayer_zOrder = 100002

local function addTouchLayer()
	if loadingLayer then
		return
	end
	loadingLayer = Layer:create()
	local function onTouch(event, x, y)
		if event == CCTOUCHBEGAN then
			return true
		else
			return
		end
	end
	loadingLayer:registerScriptTouchHandler(onTouch, false, -100, true)
	loadingLayer:setTouchEnabled(true)
	local RunningScene = Director:sharedDirector():getRunningScene()
    if RunningScene ~= nil then
      if RunningScene.rootLayer ~= nil then
        CCDirector:sharedDirector():getRunningScene():addChild(loadingLayer.refCocosObj, loadingLayer_zOrder)
      end
    end
end

local function removeTouchLayer()
	if (not loadingLayer) or (not loadingLayer.refCocosObj) then
		return
	end
	loadingLayer.refCocosObj:removeFromParentAndCleanup(true)
	loadingLayer = nil
end

local function resumeCoroutine(aCoroutine, add_Exp_callback)
	coroutine.resume(aCoroutine)
	if (coroutine.status(aCoroutine) == "dead") and (type(add_Exp_callback) == "function") then
		add_Exp_callback()
	end
end

function doUIActionForAddedExp(levelLabel, expLabel, expBar, add_Exp_callback)
	addTouchLayer()
	local userData = DataManager.getCurrUser()
	local oldLevel = tonumber(string.sub(levelLabel:getString(), 4))
	local oldExp = tonumber(expLabel:getString():split("/")[1])
	
	local function showExpAction(nextLevel, nextExp, nextPercent, oldExp, nextExp2, aConfig)
		local currentPercent = expBar:getPercentage()
		local actionTime = action_time_for_exp * (nextPercent - currentPercent) / 100
		expBar:progressTo(nextPercent, actionTime)
		local expNumChangeHandler
		local aStep = (nextExp2 - oldExp) / actionTime
		local tempNum = oldExp
		local function changeExpShowNum(dt)
			tempNum = tempNum + aStep * dt
			if tempNum >= nextExp2 then
				tempNum = nextExp2
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(expNumChangeHandler)
				expNumChangeHandler = nil
			end
			expLabel:setString(math.floor(tempNum) .. "/" ..tostring(aConfig.exp))
		end
		expNumChangeHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(changeExpShowNum, 0, false)
		local currentCoroutine = coroutine.running()
		local handle = nil
		local function expActionFinished()
			levelLabel:setString( "Lv." .. nextLevel)
			local aUserLevelConfig = MetaManager.user_level[nextLevel]
			expLabel:setString(nextExp .. "/" ..tostring(aUserLevelConfig.exp))
			expBar:setPercentage(nextExp * 100 / aUserLevelConfig.exp)
			expBar:stopProgress()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
			handle = nil
			if expNumChangeHandler then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(expNumChangeHandler)
				expNumChangeHandler = nil
			end 
			resumeCoroutine(currentCoroutine, add_Exp_callback)
		end
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(expActionFinished, actionTime, false)
		coroutine.yield()
	end

	local function showLevelUpFlash()
		local fspt = FlashSprite:create("EVO2/levelup")
	    fspt:changeAnimation(0)
	    fspt:setLoop(false)
	    local fspt_co = CocosObject.new(fspt)
	    local RunningScene = Director:sharedDirector():getRunningScene()
	    local currentCoroutine = coroutine.running()
	    local function onFlashAnimationEnd(anim)
	      fspt:unregisterEndAnimationScriptHandler()
	      RunningScene:removeChild(fspt_co)
	      resumeCoroutine(currentCoroutine, add_Exp_callback)
	    end
	    fspt:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	    RunningScene:addChild(fspt_co)
	    coroutine.yield()
	end

	local addExpCoroutine = coroutine.create(
		function()
			while((oldLevel ~= userData.level) or (oldExp ~= tonumber(userData.exp))) do
				local nextLevel
				local nextExp
				local nextPercent
				local nextExp2
				local aUserLevelConfig = MetaManager.user_level[oldLevel]
				local whetherLevelUp = false
				if oldLevel == userData.level then
					nextLevel = userData.level
					nextExp = tonumber(userData.exp)
					nextPercent = tonumber(userData.exp) * 100 / aUserLevelConfig.exp
					nextExp2 = nextExp
				else
					whetherLevelUp = true
					nextLevel = oldLevel + 1
					nextExp = 0
					nextPercent = 100
					nextExp2 = aUserLevelConfig.exp
				end
				showExpAction(nextLevel, nextExp, nextPercent, oldExp, nextExp2, aUserLevelConfig)
				if whetherLevelUp then
					showLevelUpFlash()
				end

				oldLevel = nextLevel
				oldExp = nextExp
			end
			removeTouchLayer()
			
		end
	)
	resumeCoroutine(addExpCoroutine, add_Exp_callback)
end