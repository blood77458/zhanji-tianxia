require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.BaseUIScene"
require "canon.customUI/CanonCard"
require "canon.request.TriggerBattleRequest"
require "canon.request.localStorage"
require "canon.request.Communication"
require "canon.request.BaseRequest"
require "canon.data.MetaManager"
require "canon.canonUtils"
require "canon.scene.BaseUIScene"
require "canon.scene.BattleConfig"
require "canon.scene.BattleEffect"
require "canon.models.BattleManager"
require "canon.panel.BattleResultPanel"
require "canon.scene.UnionBattleScene"
require "canon.scene.MerryChristmasScene"
require "canon.panel.CrossMultiplayerBattleRewardPanel"

local special_zOrder = 10

local self_weapon_atk_effect = nil;
local enemy_weapon_atk_effect = nil;

EVENTTYPE = table.const{
	ATTACK = 0,
	SELF_SKILL = 101,
	MAIN_SKILL = 102,
	-- COMBINE_SKILL = 3,
	-- EQUIP_SKILL = 4,
	--round not 0
	ATTACK_CRIT = 1,--暴击
	ATTACK_MISS = 2,--闪避
	ATTACK_COUNTER = 3,--反击
	ATTACK_BLOCK = 4,--格挡
}

EFFECTTYPE = table.const{
	ATK_INC = 1,
	ATK_DEC = 2,
	DEF_INC = 3,
	DEF_DEC = 4,
	HP_INC = 5,
	HP_DEC = 6,
	-- COIN_INC = 7,
	-- EXP_INC = 8,
	--为6种属性预留的属性
	CRT_INC = 7,
	CRT_DEC = 8,
	TOU_INC = 9,
	TOU_DEC = 10,
	HIT_INT = 11,
	HIT_DEC = 12,
	EVA_INC = 13,
	EVA_DEC = 14,
	PAR_INC = 15,
	PAR_DEC = 16,
	PRC_INC = 17,
	PRC_DEC = 18,
}

BattleAnimEnum = table.const {
	Start = 0,
	ATKSkill = 1,
	DEFSkill = 2,
	Combine = 3,
	MainSkillSelf = 4,
	MainSkillEnemy = 5,
	Fight1 = 6,
	FightLast = 25,
	FightDeath = 26,
	TimeOut = 27,
	Win = 28,
	Kill_Two = 29,
	Lose = 30,
	JumpOut = 31,
	Crash = 32,
	HPSkill = 33,
}

ActionTypeEnum = table.const {
	ACTION_SELF = 0,
	ACTION_ENEMY = 1,
}

BattleScene = class(Scene)
local visibleSize = CCSizeMake(720, 1280)--CCDirector:sharedDirector():getVisibleSize()

local SELF = nil
local addBattleFlash

local selfAttackColor
local enemyAttackColor

local battleFlashTable = {"battle/CardbattleXX3", "battle/Cardbattle_lasthit", "battle/hero_buff", 
--[["battle/BG/bg001", "battle/BG/bg002", "battle/BG/bg003", "battle/BG/bg004", "battle/BG/bg005", "battle/BG/bg006", 
"battle/Cardbattle_normal", "battle/Cardbattle_blade", "battle/Cardbattle_spear", "battle/Cardbattle_hammer", "battle/Cardbattle_bow"--]]
}

local addedBattleFlashTable = {}

function BattleScene:ctor()
	for k,v in pairs(battleFlashTable)
	do
		if not addedBattleFlashTable[v] then
			local flash = FlashSprite:create(v)
			flash:retain();
			addedBattleFlashTable[v] = true;
		end
	end
	SELF = self
end

function BattleScene:create(data, backType, enterType, finishedType, newMissionId, musicType, fakeBattleCallback)
	if musicType == nil then
		CanonPlayBackgroundMusic("music/m_battle.mp3", true)
	elseif musicType == 1 then
		CanonPlayBackgroundMusic("music/m_instance.mp3", true)
	else
		CanonPlayBackgroundMusic("music/m_instance.mp3", true)
	end
  Set_ShareData( "Run_BattleScene", 1 ) --传递给新手引导信号
	g_isInBattleScene = true;
	local scene = BattleScene.new()
	if enterType == BattleEnterEnum.kUnionBattle or enterType == BattleEnterEnum.kCrossGVGGroupBattle or enterType == BattleEnterEnum.kCrossGVGRankBattle then
		scene.unionBattleData = data
		scene.data = data.sharkUnionBattlefieldReport
	else
		scene.data = data
	end
	-- local f = assert(io.open("d:/Onlybattle.txt", 'w'))
 -- f:write(table.serialize(data))
 -- f:close()
	-- scene.data = data
	scene.fakeBattleCallback = fakeBattleCallback
	--print(table.serialize(data))
	scene.backType = backType
	scene.enterType = enterType
  scene.finishedType = finishedType
  scene.newMissionId = newMissionId
  	scene:initScene()
  	
	
	return scene
end

local function doArenaBattleEndRequest(callback)
    local function getArenaMatchedPlayersSucceed(event)
        ArenaManager:sharedManager():resetArenaData(event.data)
                  
        if ArenaManager:sharedManager():whetherRequestForArenaScore() then
          local function gainArenaScoreByRankSucceed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            RewardManager:getReward({event.data.reward}, true)
            ArenaManager:sharedManager():gainArenaScoreByRank(event.data.reward.amount)
            if callback then
              callback()
            end
          end 
          local function gainArenaScoreByRankFailed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            if event.data.retCode == 712407 then
                      
            end
            if callback then
              callback()
            end
          end
          local params = {}
          local request = GainArenaScoreByRankRequest.new(params, rpc.SendingPriority.kHigh)
          request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankSucceed, gainArenaScoreByRankSucceed)
          request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankFailed, gainArenaScoreByRankFailed)
          request:start()
        else
          if callback then
            callback()
          end
        end      
    end 
    local function getArenaMatchedPlayersFailed(event)
        if event.data.retCode == 712400 then
        local aContent = Localization:getInstance():getText("arena_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel})
            SuspensionLabel:showContent(self, aContent)
        end
        SELF.waitResponse = false
    end
    local params = {}
    local request = GetArenaMatchedPlayersRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersSucceed, getArenaMatchedPlayersSucceed)--GetArenaMatchedPlayersFailed
    request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersFailed, getArenaMatchedPlayersFailed)
    request:start()
    SELF.waitResponse = true
end

local function onOKClick(e)
	if SELF.waitResponse ~= nil and SELF.waitResponse then
            return
      end
      
	print( "On_Battle_Ok" )
	if SELF.effectId then
		SimpleAudioEngine:sharedEngine():stopEffect(SELF.effectId)
		SELF.effectId = nil;
	end
	--local mgr = CountryManager:sharedManager()
	--local backType = mgr:getBattleBackType()
	local scene = nil
	if SELF.backType == BattleBackType.kChapterMapScene then
		scene = ChapterMapScene:create({enterScene="BattleScene",returnScene=nil,params={ignoreAction = true, finishedType = SELF.finishedType, newMissionId = SELF.newMissionId, multiBossInfo = {encounterMultiPlayerBoss = SELF.data.encounterMultiPlayerBoss, multiPlayerBossInfo = SELF.data.multiPlayerBossInfo}}})
		Director:sharedDirector():replaceScene(scene)
	elseif SELF.backType == BattleBackType.kArenaScene then
		local function gotoArenaScene()
			Director:sharedDirector():replaceScene(ArenaRankScene:create())
		end
		doArenaBattleEndRequest(gotoArenaScene)
    elseif SELF.backType == BattleBackType.kTongTianTa then
		scene = SkyTowerMainScene:create()
		Director:sharedDirector():replaceScene(scene)
	elseif SELF.backType == BattleBackType.kNewBabel then
		if SELF.data.haveTimesLeft then
			Director:sharedDirector():replaceScene(NewBabelScene:create({enterScene="BattleScene",params = {floorRewards = SELF.data.floorRewards, haveReward = SELF.data.haveReward}}))
		else
			Director:sharedDirector():replaceScene(ChallengeEntersScene:create({enterScene="BattleScene",params = {showPanelName = "skytower", floorRewards = SELF.data.floorRewards, haveReward = SELF.data.haveReward}}))
		end
	elseif SELF.backType == BattleBackType.kUserDetailPanel then
		if SELF.data.tableContentHeight then
			Director:sharedDirector():replaceScene(FriendScene:create({enterScene = nil, returnScene = nil, params = {SELF.data.tableContentHeight}}))
		else
			Director:sharedDirector():replaceScene(FriendScene:create({enterScene = nil, returnScene = nil, params = {}}))
		end
	elseif SELF.backType == BattleBackType.kEliteMissionScene then
		Director:sharedDirector():replaceScene(EliteMissionScene:create({params = {eliteMissionId = SELF.newMissionId}}))
	elseif SELF.backType == BattleBackType.kActivityCowStage then
		Director:sharedDirector():replaceScene(ActivityPanelScene:create("Activity_CowStage"))
	elseif SELF.backType == BattleBackType.kDestinyFightScene then
		if SELF.data.isBossBattle and SELF.data.win then
			Director:sharedDirector():replaceScene(KingTempleScene:create({params = {ignoreAction = true }}))
		else
			Director:sharedDirector():replaceScene(DestinyFightChallengeScene:create())
		end
	elseif SELF.backType == BattleBackType.kFakeBattle then
		if SELF.fakeBattleCallback then
			SELF.fakeBattleCallback()
		end
		--Director:sharedDirector():replaceScene(LoginScene:create())
	elseif SELF.backType == BattleBackType.kBeastScene then
		local function doPrerationSucceed(fragmentsInfo)
			local argv = {enterScene="BattleScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo, beginIndex = g_savedFragmentIndex}}
			Director:sharedDirector():replaceScene(BeastScene:create(argv))
		end
				
		local function doPrerationFailed()
		end
				
		BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
	elseif SELF.backType == BattleBackType.kRobFragmentScene then
		local function successCallback(data)
			local robUserList = data.robUserList
			local robRobotList = data.robRobotList
			local argv = {enterScene="BeastScene",returnScene="BeastScene",params={robPlayers = robUserList, beastFragmentId = SELF.data.beastFragmentId, robRobots = robRobotList}}
			Director:sharedDirector():replaceScene(RobFragmentScene:create(argv))
    	end

    	local function failureCallback(data)
			if data.retCode == 716019 then
				CanonMessageBox:Show(Localization:getInstance():getText("beast_fragmentLimit"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			else
				CanonMessageBox:showCommUnHandleErrorBox(data.retCode)
			end
    	end

		RobFragmentScene.doPreparationBeforeReplaceToFragmentScene(SELF.data.beastFragmentId, successCallback, failureCallback)
	elseif SELF.backType == BattleBackType.kWorldBossScene then
		local function onGetWorldBossInfo(response)
			WorldBossScene.worldBossInfo = response.data
			WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
			WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
			Director:sharedDirector():replaceScene(WorldBossScene:create(nil))
		end
		
		local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
		request:start()
	elseif SELF.backType == BattleBackType.kMultiplayerBossChallengeScene then
	    --
	    local function getMultiplayerBossLeftHpSucceed(event)
	      SELF.data.bossInfo.leftHp = event.data.leftHp
	      local argv = {enterScene="BattleScene",returnScene=nil,params={data = SELF.data.bossInfo}}
	      Director:sharedDirector():replaceScene(MultiplayerBossChallengeScene:create(argv))
	    end 
    local function getMultiplayerBossLeftHpFailed(event)
      if event.data.retCode == 714520 then  --activity closed
        local function closeCanonMessageBox()
          Director:sharedDirector():replaceScene(MainMenuScene:create())
        end
        local text = Localization:getInstance():getText("activityNian_timeOver")
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      elseif (event.data.retCode == 714518) or (event.data.retCode == 714515) then  --overdue or activity closed but can gain reward
        local function closeCanonMessageBox()
          if SELF.data.globalReturnScene == "MultiplayerBossScene" then
            local function successCallback(data)
              local argv = {enterScene="BattleScene",returnScene=nil,params={selectedTag = MultiplayerBossTagEnum.BossList, data = data}}
              Director:sharedDirector():replaceScene(MultiplayerBossScene:create(argv))
            end
            
            local function failureCallback(data)
              if data.retCode == 714520 then
                local function closeCanonMessageBox()
                  Director:sharedDirector():replaceScene(MainMenuScene:create())
                end
                local text = Localization:getInstance():getText("activityNian_timeOver")
                CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
              else
                local function closeCanonMessageBox()
                end
                local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
                CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
              end
            end
            MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
          elseif SELF.data.globalReturnScene == "ChapterMapScene" then
            scene = ChapterMapScene:create({enterScene="BattleScene",returnScene=nil,params={ignoreAction = true, finishedType = SELF.finishedType, newMissionId = SELF.newMissionId, multiBossInfo = {encounterMultiPlayerBoss = SELF.data.encounterMultiPlayerBoss, multiPlayerBossInfo = SELF.data.multiPlayerBossInfo}}})
            Director:sharedDirector():replaceScene(scene)
          end
        end
        local text
        if event.data.retCode == 714518 then
          text = Localization:getInstance():getText("activityNian_nianList_escapedTips")
        elseif event.data.retCode == 714515 then
          text = Localization:getInstance():getText("activityNian_nianList_timeOver")
        end
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    local params = {triggerUid = SELF.data.bossInfo.triggerUid, bossId = SELF.data.bossInfo.id}
    local request = GetMultiplayerBossLeftHpRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossLeftHpSucceed, getMultiplayerBossLeftHpSucceed )
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossLeftHpFailed, getMultiplayerBossLeftHpFailed )
    request:start()
  elseif SELF.backType == BattleBackType.kMultiplayerBossSceneBossListPanel then
    local function successCallback(data)
      local argv = {enterScene="BattleScene",returnScene=nil,params={selectedTag = MultiplayerBossTagEnum.BossList, data = data}}
      Director:sharedDirector():replaceScene(MultiplayerBossScene:create(argv))
    end
    
    local function failureCallback(data)
      if data.retCode == 714520 then
        local function closeCanonMessageBox()
          Director:sharedDirector():replaceScene(MainMenuScene:create())
        end
        local text = Localization:getInstance():getText("activityNian_timeOver")
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
  elseif SELF.backType == BattleBackType.kPKScene then
    Director:sharedDirector():replaceScene(PKScene:create({enterScene = "BattleScene"}))
  elseif SELF.backType == BattleBackType.kActivityContend then
    Director:sharedDirector():replaceScene(ActivityPanelScene:create("Activity_Contend"))  
  elseif SELF.backType == BattleBackType.kMysteriousBattle then
    Director:sharedDirector():replaceScene(ActivityPanelScene:create("Activity_mysterious"))
  elseif SELF.backType == BattleBackType.kAcrossFightReview then
    local function successCallback()
      Director:sharedDirector():replaceScene(AcrossFightScene:create())
    end
    AcrossFightScene.enterScene(successCallback)
  elseif SELF.backType == BattleBackType.kUnionColosseum then
	--军团斗兽场
	UnionManager.gotoUnionColosseumScene()
  elseif SELF.backType == BattleBackType.kActivityWanted then
  	Director:sharedDirector():replaceScene(ActivityPanelScene:create("Activity_Wanted"))
  elseif SELF.backType == BattleBackType.kActivityXmas then
  	local function ReplaceScene()
  		local featureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName
	    local isEnable = MaintenanceManager.isActivityOpen(featureName)
	    if isEnable then
	    	local argv = {enterScene="BattleScene",returnScene="ActivityPanelScene",params={}}
	    	Director:sharedDirector():replaceScene(MerryChristmasScene:create(argv))
	    else
	    	Director:sharedDirector():replaceScene(MainMenuScene:create())
	    end
  	end

  	local function CheckDialog()
		if SELF.data.dialogId then
			local originalGuideCallback = getGuideFinishCallback()
            local function guideFinished()
                ReplaceScene()
                RegisterOnGuideFinishCallback(originalGuideCallback)
            end

            RegisterOnGuideFinishCallback(guideFinished)
            Run_Script_Using_Dialog_Index(SELF.data.dialogId, 1, "event_conversation_christmas")
		else
			ReplaceScene()
		end
  	end

  	if SELF.data.chapterFinishReward then
  		local GameInitData = DataManager.getGameInitData()
  		if not GameInitData then
  			GameInitData = {}
  		end
  		if not GameInitData.sharkSceneProcess then
  			GameInitData.sharkSceneProcess = {}
  		end
  		if not GameInitData.sharkSceneProcess.activitySceneChapterList then
  			GameInitData.sharkSceneProcess.activitySceneChapterList = {}
  		end
  		local needAdd = true
  		for i,v in ipairs(GameInitData.sharkSceneProcess.activitySceneChapterList) do
  			if v.sceneFeatureName == DataManager.GameMetaData.activityEventChristmasConfig.featureName then
  				v.passAll = true
  				needAdd = false
  				break
  			end
  		end
  		if needAdd then
  			local temptable = {sceneFeatureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName , passAll = true}
  			table.insert(GameInitData.sharkSceneProcess.activitySceneChapterList, temptable)
  		end
  		DataManager.setGameInitData(GameInitData)

  		
		local aPanel = ChapterFinishRewardPanel:create(SELF, SELF.data.chapterFinishReward, CheckDialog)
        SELF:addChild(aPanel)
        aPanel:scaleIn()
    else
    	CheckDialog()
  	end
  elseif SELF.backType == BattleBackType.kCrossPVP then
	CrossArena.gotoCrossPvpScene(nil, nil)
  else
	local argv = {enterScene="BattleScene",returnScene=nil,params={notReset=false, newMissionId = SELF.newMissionId, showAllFinishedPanel = SELF.data.showAllFinishedPanel}}
	scene = CityMainScene:create(argv)
	Director:sharedDirector():replaceScene(scene)
  end
end

local function onStrengthenClick(e)
	if SELF.effectId then
		SimpleAudioEngine:sharedEngine():stopEffect(SELF.effectId)
		SELF.effectId = nil;
	end
	if SELF.backType == BattleBackType.kArenaScene then
		local function gotoCardQueueScene()
			Director:sharedDirector():replaceScene(CardQueueScene:create())
		end
		doArenaBattleEndRequest(gotoCardQueueScene)
	elseif SELF.backType == BattleBackType.kNewBabel then
		if SELF.data.haveTimesLeft then
			Director:sharedDirector():replaceScene(NewBabelScene:create({enterScene="BattleScene",params = {floorRewards = SELF.data.floorRewards, haveReward = SELF.data.haveReward}}))
		else
			Director:sharedDirector():replaceScene(ChallengeEntersScene:create({enterScene="BattleScene",params = {showPanelName = "skytower", floorRewards = SELF.data.floorRewards, haveReward = SELF.data.haveReward}}))
		end
	else
		Director:sharedDirector():replaceScene(CardQueueScene:create())
	end
end

local function whetherShouldRunDialog(params)
	if params.enterType ~= BattleEnterEnum.kChapterMapScene then
      	return
    end
    if not params.win then
    	return
    end
    if not params.newMissionId then
    	return
  	end
  	
  	local aStep = params.finishedStep
  	local aMissionId = params.missionId
  	local aRouteId = params.routeId
  	
  	local aConversationId = 0
  	for _, aBattleChapterEventConfig in pairs(MetaManager.battle_chapter_event) do
    	if (aBattleChapterEventConfig.missionId == aMissionId) and (aStep == aBattleChapterEventConfig.step) then
        	if (aRouteId == 1) then
          		aConversationId = aBattleChapterEventConfig.conversation1
        	elseif (aRouteId == 2) then
          		aConversationId = aBattleChapterEventConfig.conversation2
        	elseif (aRouteId == 3) then
          		aConversationId = aBattleChapterEventConfig.conversation3
        	end
      		break
    	end
  	end
  	local conversationIdList = {}
  	if type(aConversationId) == "string" then
  		local idList = aConversationId:split("|")
  		for _, aId in ipairs(idList) do
  			local aIdValue = tonumber(aId)
  			if aIdValue ~= 0 then
  				table.insert(conversationIdList, aIdValue)
  			end
  		end
  	else
  		if aConversationId ~= 0 then
  			table.insert(conversationIdList, aConversationId)
  		end
  	end
  	--[[
  	local foundFlag = false
  	for _, aEventConversationConfig in ipairs(MetaManager.event_conversation) do
    	if aEventConversationConfig.dialogId == aConversationId then
      		foundFlag = true
      		if aEventConversationConfig.activeOpportunity == 1 then
        		return aConversationId
      		end
    	else
      		if foundFlag then
        		break
      		end
    	end
  	end
  	]]
  	return conversationIdList
end

local onFlashEvent = nil;

function BattleScene:showBattleResultPanel()
	self:stopAllActions()
	
	self.selfHpPB:stopAllActions()
	self.enemyHpPB:stopAllActions()
	
	if type (self.effectFlash) == "table"  then
		for k,v in pairs(self.effectFlash) do
			for key, effect in pairs(v) do
				self:removeChild(effect)
			end
		end
		self.effectFlash = {}
	end
	
	self.gameEnd = true
	if self.skipButton then
		self.skipButton:setEnable(false)
	end
	
	if self.skipButtonSprite then
		self.skipButtonSprite:setVisible(false)
	end
	
	if self.skipButtonBg then
		self.skipButtonBg:setVisible(false)
	end
	
	self.battle_flash_co:setVisible(false)
	--self.builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
	
	local function setFlashEnd(flash)
		flash:setVisible(false)
		flash:setIsRun(false)
	end
	
	local flashTable = {self.battle_flash, self.self_attack_flash, self.enemy_attack_flash, self.lasthit_flash, self.hero_buff_flash}
	for k,v in pairs(flashTable)
	do
		setFlashEnd(v)
	end
	
	onFlashEvent("hideSkillName")
	onFlashEvent("hideEnemySkillName")
	
	self.curRound = self.finalRound
	self.selfMaxHp = self.finalSelfHPMaxChange
	self.enemyMaxHp = self.finalEnemyHPMaxChange
	self.selfHp = self.selfMaxHp + self.finalSelfHPChange
	if self.selfHp < 0 then
		self.selfHp = 0
	end
	
	self.enemyHp = self.enemyMaxHp + self.finalEnemyHPChange
	if self.enemyHp < 0 then
		self.enemyHp = 0
	end
	
  local totalRoundNum
    if self.enterType == BattleEnterEnum.kActivityContend then
      totalRoundNum = DataManager.GameMetaData.activityContendConfig.battleRoundNum
    else
      totalRoundNum = 20
    end
	self.roundTextLabel:setString(tostring(totalRoundNum - self.curRound) .. "\n" ..  getTextByKey("battle_round"))
	
	self.selfHpNumSpt:setString(tostring(self.selfHp).. "/" .. tostring(self.selfMaxHp))
	self.enemyHpNumSpt:setString(tostring(self.enemyHp) .. "/" .. tostring(self.enemyMaxHp))
	
	self.selfHpPB:setPercentage(self.selfHp / self.selfMaxHp  * 100)
	self.enemyHpPB:setPercentage(self.enemyHp / self.enemyMaxHp  * 100)
	
	if self.backType == BattleBackType.kFakeBattle then
		onOKClick()
	else
		local function guideFinishedCallback()
			local tosendData = self.data
			tosendData.totalDamage = self.data.damage
			local aArenaManager = ArenaManager:sharedManager()
			if aArenaManager.arenaData then
				tosendData.previousArenaRankInfo = aArenaManager.arenaData.sharkArenaRank
				tosendData.selfRewardScore = self.data.selfRewardScore
			end
			
			if self.data.rewards and not addedBefore then
				RewardManager:getReward(self.data.rewards, true)
			end
			
			if self.data.qteRewards and not addedBefore then
				RewardManager:getReward(self.data.qteRewards, true)
			end
			
			if self.data.vipRewards and not addedBefore then
				RewardManager:getReward(self.data.vipRewards, true)
			end
			
			if self.data.robRewards and not addedBefore then
				RewardManager:getReward(self.data.robRewards, true)
			end
			
			if self.data.requsites and not addedBefore then
				for requisiteKey, requisitedata in pairs(self.data.requsites) do
					requisitedata.amount = tostring(-tonumber(requisitedata.amount))
				end
				RewardManager:getReward(self.data.requsites, true)
			end
		
			local whetherWin = self.data.win
			SimpleAudioEngine:sharedEngine():stopBackgroundMusic()
			if whetherWin then
				self.effectId = CanonPlayEffect("music/m_win.wav")
			else
				self.effectId = CanonPlayEffect("music/m_lose.wav")
			end
	    	if self.enterType == BattleEnterEnum.kMultiplayerBossChallengeScene then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.MULTI_BOSS_WIN, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaWin()
				else
					BattleResultPanel:show(BattleResultType.MULTI_BOSS_LOSE, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaLose()
				end
			elseif self.enterType == BattleEnterEnum.kArenaScene then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.ARENA_WIN, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaWin()
				else
					BattleResultPanel:show(BattleResultType.ARENA_LOSE, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaLose()
				end
			elseif self.enterType == BattleEnterEnum.kUserDetailPanel then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.VS_WIN, tosendData, onOKClick, onStrengthenClick, self)
					--self:showVSWin()
				else
					BattleResultPanel:show(BattleResultType.VS_LOSE, tosendData, onOKClick, onStrengthenClick, self)
					--self:showVSLose()
				end
			elseif self.enterType == BattleEnterEnum.kRobFragmentScene then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.ROB_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.ROB_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kWorldBossScene then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.BOSS_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.BOSS_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kChapterMapScene then
				if self.data.win then
					local should_check_finish_reward
					if self.backType == BattleBackType.kCityMainScene then
						should_check_finish_reward = true
					end
					BattleResultPanel:show(BattleResultType.CHAPTER_MAP_WIN, tosendData, onOKClick, onStrengthenClick, self, should_check_finish_reward)
				else
					BattleResultPanel:show(BattleResultType.CHAPTER_MAP_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kEliteMissionScene then--
				if self.data.win then
					BattleResultPanel:show(BattleResultType.EILTE_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.EILTE_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kNewBabel then
				tosendData.selectDifficult = self.data.selectDifficult
				tosendData.currTotalStars = self.data.currTotalStars
				tosendData.currFloor = self.data.currFloor
				tosendData.firstTimeBigWin = self.data.firstTimeBigWin
				tosendData.clearNewBabel = self.data.clearNewBabel
				if self.data.win then
					BattleResultPanel:show(BattleResultType.NEWBABEL_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.NEWBABEL_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kPKScene then
				local function onRefreshFinished()
					if self.data.win then
						BattleResultPanel:show(BattleResultType.PK_WIN, tosendData, onOKClick, onStrengthenClick, self)
					else
						BattleResultPanel:show(BattleResultType.PK_LOSE, tosendData, onOKClick, onStrengthenClick, self)
					end
				end
				PKScene.refreshPKInfoStatic(onRefreshFinished)
		    elseif self.enterType == BattleEnterEnum.kActivityContend then
		    	BattleResultPanel:show(BattleResultType.ACTIVITY_CONTEND, tosendData, onOKClick, nil, self)
		    elseif self.enterType == BattleEnterEnum.kAcrossFightReview then
	      		BattleResultPanel:show(BattleResultType.CROSS_PK, tosendData, onOKClick, nil, self)
			elseif self.enterType == BattleEnterEnum.kUnionColosseum then
				--军团斗兽场 unionColosseumTag
				local scene = Director:mgr():run()
				scene.targetInfoPanel = UnionColosseumBattleResultPopPanel:create(scene, tosendData)
				PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
			elseif self.enterType == BattleEnterEnum.kActivityWanted then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.ACTIVITY_WANTED_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.ACTIVITY_WANTED_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
			elseif self.enterType == BattleEnterEnum.kActivityXmas then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.ACTIVITY_XMAS_WIN, tosendData, onOKClick, onStrengthenClick, self)
				else
					BattleResultPanel:show(BattleResultType.ACTIVITY_XMAS_LOSE, tosendData, onOKClick, onStrengthenClick, self)
				end
		    elseif self.enterType == BattleEnterEnum.kActivityContend then
		    	BattleResultPanel:show(BattleResultType.ACTIVITY_CONTEND, tosendData, onOKClick, nil, self)
		    elseif self.enterType == BattleEnterEnum.kAcrossFightReview then
      			BattleResultPanel:show(BattleResultType.CROSS_PK, tosendData, onOKClick, nil, self)
			elseif self.enterType == BattleEnterEnum.kUnionColosseum then
				--军团斗兽场 unionColosseumTag
				local scene = Director:mgr():run()
				scene.targetInfoPanel = UnionColosseumBattleResultPopPanel:create(scene, tosendData)
				PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
			elseif self.enterType == BattleEnterEnum.kActivityCrossBoss then
				--跨服世界boss
				local scene = Director:mgr():run()
				scene.targetInfoPanel = CrossMultiplayerBattleRewardPanel:create(scene, tosendData)
			  	scene:addChild(scene.targetInfoPanel)
			    scene.targetInfoPanel:scaleIn()
				-- PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
			elseif self.enterType == BattleEnterEnum.kCrossPVP then
				if self.data.win then
					BattleResultPanel:show(BattleResultType.CROSS_PVP_WIN, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaWin()
				else
					BattleResultPanel:show(BattleResultType.CROSS_PVP_LOSE, tosendData, onOKClick, onStrengthenClick, self)
					--self:showArenaLose()
				end
			elseif self.enterType == BattleEnterEnum.kCrossPVPReview then
				CrossArena.gotoCrossPvpScene(CrossArena.SCENE_CHALLENGE_INDEX, CrossArenaChanllengeScene.TAB_NEWS)
			elseif self.enterType == BattleEnterEnum.kUnionBattle or self.enterType == BattleEnterEnum.kCrossGVGGroupBattle or 
	self.enterType == BattleEnterEnum.kCrossGVGRankBattle then
				if #self.data.unionBattleRounds == 0 and self.enterType == BattleEnterEnum.kUnionBattle then
					local scene = Director:mgr():run()
					local data,detailData = UnionBattleSettlementPopPanel.FormatData(self.unionBattleData)
					local aMyGuildPanel =  nil
					if detailData.available then
						aMyGuildPanel = UnionBattleSettlementPopPanel:create(scene,data,detailData)
					else
						aMyGuildPanel = UnionBattleSettlementMiniPopPanel:create(scene,data)
					end
					scene:addChild(aMyGuildPanel)
					aMyGuildPanel:scaleIn()
					return
				elseif #self.data.unionBattleRounds == 0 and 
					(self.enterType == BattleEnterEnum.kCrossGVGGroupBattle or self.enterType == BattleEnterEnum.kCrossGVGRankBattle) then
					CrossUnionPk.popBattleResultPanel(self.enterType, self.data, self.unionBattleData.currPoints, self.unionBattleData.changePoints)
					return
				end
			  	--播放单挑结算动画
				local fspt = FlashSprite:create("battle/popo_up_word")
				local winLevel
				local GameMetaData = UnionPkConfig.getSettingConfig()
				if self.data.win then
					if tosendData.leftHpRate <= GameMetaData.oneVsOneWin then
						fspt:changeAnimation(0)
						winLevel = SINGLEBATTLEWINTYPE.SELF_WIN
					else
						fspt:changeAnimation(2)
						winLevel = SINGLEBATTLEWINTYPE.SELF_BIG_WIN
					end
				else
					if tosendData.leftHpRate <= GameMetaData.oneVsOneWin then
						fspt:changeAnimation(1)
						winLevel = SINGLEBATTLEWINTYPE.ENEMY_WIN
					else
						fspt:changeAnimation(3)
						winLevel = SINGLEBATTLEWINTYPE.ENEMY_BIG_WIN
					end
				end
				
				fspt:setLoop(false)
				local fspt_co = CocosObject.new(fspt)
				local function onBattleFlashAnimationEnd(anim)
					fspt:unregisterEndAnimationScriptHandler()
					self:removeChild(fspt_co)
					--Set_ShareData( "Cloud_Finished", 1 )
					self.fspt = nil;
					--云雾动画
					local fspt2 = FlashSprite:create("map/others/flashPack/Cloud")
					fspt2:changeAnimation(2)
					fspt2:setLoop(false)
					local fspt2_co = CocosObject.new(fspt2)
					local function onCloudFlashAnimationEnd(anim)
						local function actionFinished()
							fspt2:unregisterEndAnimationScriptHandler()
							self:removeChild(fspt2_co)
							self.fspt2 = nil;
							local battleType
							if self.enterType == BattleEnterEnum.kUnionBattle then
								battleType = UnionBattleType.kUnionPk
							elseif self.enterType == BattleEnterEnum.kCrossGVGGroupBattle or self.enterType == BattleEnterEnum.kCrossGVGRankBattle then
								battleType = UnionBattleType.kGVGBattle
							end
							local scene = UnionBattleScene:create(self.unionBattleData , {winLevel = winLevel , battleType = battleType , enterType = self.enterType})
						  	Director:sharedDirector():replaceScene(scene)
						end
						local arr = CCArray:create()
					  	arr:addObject(CCDelayTime:create(0.6))
					  	arr:addObject(CCCallFunc:create(actionFinished))
					  	self:runAction(CCSequence:create(arr))
					end
					self.fspt2 = fspt2
					fspt2:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
					self:addChild(fspt2_co)
				end
				self.fspt = fspt
				fspt:registerEndAnimationScriptHandler(onBattleFlashAnimationEnd)
				self:addChild(fspt_co)
			else
				if self.data.win then
					local should_check_finish_reward
					if self.backType == BattleBackType.kCityMainScene then
						should_check_finish_reward = true
					end
					tosendData.backType = self.backType
					BattleResultPanel:show(BattleResultType.BATTLE_WIN, tosendData, onOKClick, onStrengthenClick, self, should_check_finish_reward)
					--self:showBattleWin()
					--addedBefore = true;
					else
						BattleResultPanel:show(BattleResultType.BATTLE_LOSE, tosendData, onOKClick, onStrengthenClick, self)
						--self:showBattleLose()
					end
				
				if self.data.sharkArenaRank and aArenaManager.arenaData then
					aArenaManager.arenaData.sharkArenaRank = self.data.sharkArenaRank
				end
			end
		end

		local function checkRunDiaolog()
			local params = {}
			params.enterType = self.enterType
			params.win = self.data.win
			params.missionId = self.data.missionId
			params.finishedStep = self.data.finishedStep
			params.routeId = self.data.routeId
			params.newMissionId = self.data.newMissionId
			local conversationIdList = whetherShouldRunDialog(params)
			if conversationIdList and (#conversationIdList > 0) then
				local originalGuideCallback = getGuideFinishCallback()
				local storyIndex = 0
		  		local viewGuide
		  		local function guideViewFinished()
		  			RegisterOnGuideFinishCallback(originalGuideCallback)
		  			guideFinishedCallback()
		  		end
		  		local function addTransitionTip()
				    if (Get_ShareData("Skip_Story") == 1) or (not conversationIdList[storyIndex + 1]) then
				      Set_ShareData("Skip_Story", 0)
				      guideViewFinished()
				      return
				    end
				    self.tempLayer = LayerColor:create()
				    self.tempLayer:changeWidthAndHeight(visibleSize.width, visibleSize.height)
				    self.tempLayer:setOpacity(255)
				    self:addChild(self.tempLayer)
				    local loadingSprite = FlashSprite:create("EVO2/Loading_lvbu")
				    math.randomseed(os.time())
				    local rand = math.random(3) - 1
				    loadingSprite:changeAnimation(rand)
				    local loadingSprite_co = CocosObject.new(loadingSprite)
				    self:addChild(loadingSprite_co)
				    local delayEntry
				    local function delayCallback( dt )
				      loadingSprite_co:removeFromParentAndCleanup(true)
				      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(delayEntry)
				      delayEntry = nil
				      self.tempLayer:removeFromParentAndCleanup(true)
		    		  self.tempLayer = nil
				      viewGuide()
				    end
				    delayEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(delayCallback, 0.3, false)
			  	end
		  		viewGuide = function()
				    storyIndex = storyIndex + 1
				    local aStory = conversationIdList[storyIndex]
				    if not aStory then
				      guideViewFinished()
				      return
				    end
				    RegisterOnGuideFinishCallback(addTransitionTip)
				    Run_Script_Using_Dialog_Index(aStory, 1)
			  	end
			  	viewGuide()
			else
				guideFinishedCallback()
			end
		end
		
		checkRunDiaolog()
	end
end

local function removeLastFlashEffect()
	if type (SELF.effectFlash) == "table" and #SELF.effectFlash > 0 then
		for k,v in pairs(SELF.effectFlash[1])
		do
			SELF:removeChild(v)
		end
		table.remove(SELF.effectFlash, 1)
	end
end

local function shockScreen( delayTime  )
	-- body
	delayTime = delayTime or 0.25
	local scale = 1.5
	local actionArray = CCArray:create()
		-- self:setPosition(ccp(0, 400))
	actionArray:addObject(CCDelayTime:create(delayTime))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(0, -8 * scale)))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(-0, 13.6 * scale)))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(0, -11.2 * scale)))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(-0, 10.4 * scale)))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(0, -9.6 * scale)))
	actionArray:addObject(CCMoveBy:create(0.041667, ccp(-0, 4.8 * scale)))
	-- actionArray:addObject(CCCallFuncN:create(runNumberAction))
	SELF.bg:runAction(CCSequence:create(actionArray))
end

local function setToPlayEffect(eventFlowTable)
	if not SELF.toPlayEffectTable then
		SELF.toPlayEffectTable = {}
	end
	table.insert(SELF.toPlayEffectTable, eventFlowTable)
end

local function playAttriChangeEffect(eventFlow)
	local isMainSkill = eventFlow.isMainSkill
	
	local totalEffectSelf = 0
	local totalEffectEnemy = 0
	local curEffectSelfIndex = 1
	local curEffectEnemyIndex = 1

	if isMainSkill then
		for k,v in pairs(eventFlow) do
			if type(v) == "table" and v.effectId ~= 0 then
				if v.posId < 10000 then
					totalEffectSelf = totalEffectSelf + 1
				else
					totalEffectEnemy = totalEffectEnemy + 1
				end
			end
		end
	end
	
	local function doEventInfo(k, v)
		local function getEffectPixielX()
			local effectPixielX
			if v.posId < 100 then
				effectPixielX = 230 * (curEffectSelfIndex - (totalEffectSelf + 1) / 2)
				curEffectSelfIndex = curEffectSelfIndex + 1
			else
				effectPixielX = 230 * (curEffectEnemyIndex - (totalEffectEnemy + 1) / 2)
				curEffectEnemyIndex = curEffectEnemyIndex + 1
			end
			
			return effectPixielX
		end
	
		local effect
		local color
		local number
		
		if v.effectId == EFFECTTYPE.ATK_INC then
			--effect = FlashSprite:create("battle/fire")
			color = NumberColorEnum.yellow  
			number = v.changedValue
			--print("attackincrease:" .. v.changedValue)
		elseif v.effectId == EFFECTTYPE.ATK_DEC then
			--effect = FlashSprite:create("battle/fire")
			color = NumberColorEnum.yellow
			number = -v.changedValue
			--print("attackdecrease:" .. v.changedValue)
		elseif v.effectId == EFFECTTYPE.DEF_INC then
			--effect = FlashSprite:create("battle/GREEN_BIRD")
			color = NumberColorEnum.blue
			number = v.changedValue
			--print("defincrease:" .. v.changedValue)
		elseif v.effectId == EFFECTTYPE.DEF_DEC then
			--effect = FlashSprite:create("battle/GREEN_BIRD")
			color = NumberColorEnum.blue
			number = -v.changedValue
			--print("defdecrease:" .. v.changedValue)
		elseif v.effectId == EFFECTTYPE.HP_INC then
			--effect = FlashSprite:create("battle/Def")
			color = NumberColorEnum.red
			number = v.changedValue
			--print("hpincrease:" .. v.changedValue)
			if v.posId < 10000 then
				SELF.selfMaxHp = SELF.selfMaxHp + v.changedValue
				SELF.selfHp = SELF.selfHp + v.changedValue
				SELF.selfHpNumSpt:setString(tostring(SELF.selfHp).. "/" .. tostring(SELF.selfMaxHp))
			else
				SELF.enemyMaxHp = SELF.enemyMaxHp + v.changedValue
				SELF.enemyHp = SELF.enemyHp + v.changedValue
				SELF.enemyHpNumSpt:setString(tostring(SELF.enemyHp) .. "/" .. tostring(SELF.enemyMaxHp))
			end
		elseif v.effectId == EFFECTTYPE.HP_DEC or v.eventType == EVENTTYPE.ATTACK or v.eventType == EVENTTYPE.ATTACK_BLOCK or v.eventType == EVENTTYPE.ATTACK_COUNTER then
			--effect = FlashSprite:create("battle/Def")
			color = NumberColorEnum.red
			number = -v.changedValue
			if v.posId < 10000 then
				SELF.selfHp = SELF.selfHp - v.changedValue
				if SELF.selfHp < 0 then
					SELF.selfHp = 0
				end
				SELF.selfHpPB:runAction(CCProgressTo:create(0.5, SELF.selfHp / SELF.selfMaxHp * 100))
				SELF.selfHpNumSpt:setString(tostring(SELF.selfHp).. "/" .. tostring(SELF.selfMaxHp))
			else
				SELF.enemyHp = SELF.enemyHp - v.changedValue
				if SELF.enemyHp < 0 then
					SELF.enemyHp = 0
				end
				SELF.enemyHpPB:runAction(CCProgressTo:create(0.5, SELF.enemyHp / SELF.enemyMaxHp * 100))
				SELF.enemyHpNumSpt:setString(tostring(SELF.enemyHp) .. "/" .. tostring(SELF.enemyMaxHp))
			end
		elseif v.eventType == EVENTTYPE.ATTACK_CRIT then
			color = NumberColorEnum.critical
			number = -v.changedValue
			if v.posId < 10000 then
				SELF.selfHp = SELF.selfHp - v.changedValue
				if SELF.selfHp < 0 then
					SELF.selfHp = 0
				end
				SELF.selfHpPB:runAction(CCProgressTo:create(0.5, SELF.selfHp / SELF.selfMaxHp * 100))
				SELF.selfHpNumSpt:setString(tostring(SELF.selfHp).. "/" .. tostring(SELF.selfMaxHp))
			else
				SELF.enemyHp = SELF.enemyHp - v.changedValue
				if SELF.enemyHp < 0 then
					SELF.enemyHp = 0
				end
				SELF.enemyHpPB:runAction(CCProgressTo:create(0.5, SELF.enemyHp / SELF.enemyMaxHp * 100))
				SELF.enemyHpNumSpt:setString(tostring(SELF.enemyHp) .. "/" .. tostring(SELF.enemyMaxHp))
			end
		-- elseif v.enterType == EVENTTYPE.ATTACK_COUNTER then


		else
			--donothing
		end
		if effect or color then
			local cardNum 
			local moveByPos
			local effectAnimation = 0
			if v.posId < 10000 then
				cardNum = SELF.selfCardNum
				moveByPos = ccp(0, -50)
			else
				cardNum = SELF.enemyCardNum
				moveByPos = ccp(0, 50)
			end
			local configData = getConfigData(v.posId, cardNum)
			
			local mainAttriPath, updownPath
			local txtMovePos
			local mainSkillPixielX = 0
			if isMainSkill then
				mainAttriPath = "battle/pic/"
				updownPath = "battle/pic/"
				mainSkillPixielX = getEffectPixielX()
				if math.floor((v.effectId - 1) / 2 ) == 0 then
					mainAttriPath = mainAttriPath .. "ATK.png"
				elseif math.floor((v.effectId - 1) / 2 ) == 1 then
					mainAttriPath = mainAttriPath .. "DEF.png"
				else
					mainAttriPath = mainAttriPath .. "HP.png"
				end
				
				--effect = FlashSprite:create("battle/gold_light")
				if (v.effectId - 1) % 2 == 0 then
					updownPath = updownPath .. "UP.png"
					txtMovePos = ccp(0, 100)
				else
					updownPath = updownPath .. "DOWN.png"
					txtMovePos = ccp(0, -100)
					effectAnimation = 1
				end
				
			end
			
			--to do, bug for xiao wangzi
			effect = nil
			
			if effect then
				moveByPos = ccp(0, 50)
				effect:changeAnimation(effectAnimation)
				effect:setLoop(false)
				effect:setPosition( configData.pos_x + mainSkillPixielX, configData.pos_y )
				local effect_co = CocosObject.new(effect)
				table.insert(SELF.effectFlash[#SELF.effectFlash], effect_co)
				SELF:addChild(effect_co)
			end
			
			
			if mainAttriPath then
				local mainAttriSprite = Sprite:create(mainAttriPath)
				mainAttriSprite:setPosition(ccp(configData.pos_x - 10 + mainSkillPixielX, configData.pos_y))
				mainAttriSprite:setAnchorPoint(ccp(1, 0.5))
				SELF:addChild(mainAttriSprite)
				
				mainAttriSprite:runAction(CCFadeOut:create(0.6))
				mainAttriSprite:runAction(CCMoveBy:create(0.6, txtMovePos))
				
				local updownSprite = Sprite:create(updownPath)
				updownSprite:setPosition(ccp(configData.pos_x + 10 + mainSkillPixielX, configData.pos_y))
				updownSprite:setAnchorPoint(ccp(0, 0.5))
				SELF:addChild(updownSprite)
				
				updownSprite:runAction(CCFadeOut:create(0.6))
				updownSprite:runAction(CCMoveBy:create(0.6, txtMovePos))
			end

			local numberEffect = nil

			if v.eventType == EVENTTYPE.SELF_SKILL or v.eventType == EVENTTYPE.MAIN_SKILL then
				local scaleFactor = 0.7
				numberEffect = createNumberEffect(number, configData.pos_x + mainSkillPixielX, configData.pos_y + 20, color, true, 4 * scaleFactor, false, 2 * scaleFactor, moveByPos, true)
			else
				numberEffect = createNumberEffect(number, configData.pos_x + mainSkillPixielX, configData.pos_y + 20, color, true, 4, false, 2, moveByPos, true)
			end

			-- local numberEffect = createNumberEffect(number, configData.pos_x + mainSkillPixielX, configData.pos_y + 20, color, true, 4, false, 2, moveByPos, true)
			table.insert(SELF.effectFlash[#SELF.effectFlash], numberEffect)
			SELF:addChild(numberEffect)
		
			if v.eventType == EVENTTYPE.ATTACK or v.enterType == EVENTTYPE.ATTACK_BLOCK or v.eventType == EVENTTYPE.ATTACK_CRIT or v.enterType == EVENTTYPE.ATTACK_COUNTER then
				local attackShine
				if v.posId < 10000 then
					attackShine = CCLayerGradient:create(ccc4(enemyAttackColor.r, enemyAttackColor.g, enemyAttackColor.b, 255), ccc4(enemyAttackColor.r, enemyAttackColor.g, enemyAttackColor.b, 0))
					attackShine:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height / 2))
					attackShine:setVector(ccp(0, 1))
				else
					attackShine = CCLayerGradient:create(ccc4(selfAttackColor.r, selfAttackColor.g, selfAttackColor.b, 255), ccc4(selfAttackColor.r, selfAttackColor.g, selfAttackColor.b, 0))
					attackShine:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height / 2))
					attackShine:setPosition(ccp(0, visibleSize.height / 2))
					attackShine:setVector(ccp(0, -1))
				end
				SELF:addChild(CocosObject.new(attackShine))
				table.insert(SELF.effectFlash[#SELF.effectFlash], attackShine)
				local actionArray = CCArray:create()
				actionArray:addObject(CCFadeOut:create(0))
				actionArray:addObject(CCFadeTo:create(0.3, 255* 0.4))
				actionArray:addObject(CCFadeTo:create(0.3, 0))
				attackShine:runAction(CCSequence:create(actionArray))
				
				local particle = CCParticleSystemQuad:create("effect/fx_card_beattacked.plist")
				particle:setPosition(ccp(configData.pos_x, configData.pos_y))
				particle:setAutoRemoveOnFinish(true)
				SELF:addChild(CocosObject.new(particle))

			end
		end
	end

	for k,v in pairs(eventFlow) do
		if type(v) == "table" then
			doEventInfo(k,v)
		end
	end

end

local function playNextEffect()
	if type(SELF.toPlayEffectTable) == "table" and #SELF.toPlayEffectTable > 0 then
		table.insert(SELF.effectFlash, {})
		-- for k,v in pairs(SELF.toPlayEffectTable[1])
		do
			playAttriChangeEffect(SELF.toPlayEffectTable[1])
		end
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(1))
		actionArray:addObject(CCCallFuncN:create(removeLastFlashEffect))
		SELF:runAction(CCSequence:create(actionArray))
		table.remove(SELF.toPlayEffectTable, 1)
	end
end

local function isSkillExist()
	local exist = false
	if (SELF.skillAttackSelf ~= nil and #SELF.skillAttackSelf > 0) or (SELF.skillAttackEnemy ~= nil and #SELF.skillAttackEnemy > 0) then
		SELF.playAnimation = BattleAnimEnum.ATKSkill
		exist = true;
	elseif (SELF.skillDefenseSelf ~= nil and #SELF.skillDefenseSelf > 0) or (SELF.skillDefenseEnemy ~= nil and #SELF.skillDefenseEnemy > 0) then
		SELF.playAnimation = BattleAnimEnum.DEFSkill
		exist = true
	elseif (SELF.skillHpSelf ~= nil and #SELF.skillHpSelf > 0) or (SELF.skillHpEnemy ~= nil and #SELF.skillHpEnemy > 0) then
		SELF.playAnimation = BattleAnimEnum.HPSkill
		exist = true
	end
	return exist
end

local function isSelfSkillExist()
	local exist = false
	if SELF.skillAttackSelf ~= nil and #SELF.skillAttackSelf > 0 then
		exist = true
	elseif SELF.skillDefenseSelf ~= nil and #SELF.skillDefenseSelf > 0 then
		exist = true
	elseif SELF.skillHpSelf ~= nil and #SELF.skillHpSelf > 0 then
		exist = true
	end
	return exist
end

local function isEnemySkillExist()
	local exist = false
	if SELF.skillAttackEnemy ~= nil and #SELF.skillAttackEnemy > 0 then
		exist = true
	elseif SELF.skillDefenseEnemy ~= nil and #SELF.skillDefenseEnemy > 0 then
		exist = true
	elseif SELF.skillHpEnemy ~= nil and #SELF.skillHpEnemy > 0 then
		exist = true
	end
	return exist
end

local function playSkillEffect()
	if (SELF.skillAttackSelf ~= nil and #SELF.skillAttackSelf > 0) or (SELF.skillAttackEnemy ~= nil and #SELF.skillAttackEnemy > 0) then
		local toplayTable = {}
		for k,v in pairs(SELF.skillAttackSelf)
		do
			table.insert(toplayTable, v)
		end
		for k,v in pairs(SELF.skillAttackEnemy)
		do
			table.insert(toplayTable, v)
		end
		setToPlayEffect(toplayTable)
		SELF.skillAttackSelf = nil;
		SELF.skillAttackEnemy = nil;
	elseif (SELF.skillDefenseSelf ~= nil and #SELF.skillDefenseSelf > 0) or (SELF.skillDefenseEnemy ~= nil and #SELF.skillDefenseEnemy > 0) then
		local toplayTable = {}
		for k,v in pairs(SELF.skillDefenseSelf)
		do
			table.insert(toplayTable, v)
		end
		for k,v in pairs(SELF.skillDefenseEnemy)
		do
			table.insert(toplayTable, v)
		end
		setToPlayEffect(toplayTable)
		SELF.skillDefenseSelf = nil;
		SELF.skillDefenseEnemy = nil;
	elseif (SELF.skillHpSelf ~= nil and #SELF.skillHpSelf > 0) or (SELF.skillHpEnemy ~= nil and #SELF.skillHpEnemy > 0) then
		local toplayTable = {}
		for k,v in pairs(SELF.skillHpSelf)
		do
			table.insert(toplayTable, v)
		end
		for k,v in pairs(SELF.skillHpEnemy)
		do
			table.insert(toplayTable, v)
		end
		setToPlayEffect(toplayTable)
		SELF.skillHpSelf = nil;
		SELF.skillHpEnemy = nil;
	end
end

local function playSelfSkillEffect()
	if SELF.skillAttackSelf ~= nil and #SELF.skillAttackSelf > 0 then
		setToPlayEffect(SELF.skillAttackSelf)
		SELF.skillAttackSelf = nil;
	elseif SELF.skillDefenseSelf ~= nil and #SELF.skillDefenseSelf > 0 then
		setToPlayEffect(SELF.skillDefenseSelf )
		SELF.skillDefenseSelf = nil
	elseif SELF.skillHpSelf ~= nil and #SELF.skillHpSelf > 0 then
		setToPlayEffect(SELF.skillHpSelf )
		SELF.skillHpSelf = nil
	end
end

local function playEnemySkillEffect()
	if SELF.skillAttackEnemy ~= nil and #SELF.skillAttackEnemy > 0 then
		setToPlayEffect(SELF.skillAttackEnemy )
		SELF.skillAttackEnemy = nil;
	elseif SELF.skillDefenseEnemy ~= nil and #SELF.skillDefenseEnemy > 0 then
		setToPlayEffect(SELF.skillDefenseEnemy )
		SELF.skillDefenseEnemy = nil
	elseif SELF.skillHpEnemy ~= nil and #SELF.skillHpEnemy > 0 then
		setToPlayEffect(SELF.skillHpEnemy )
		SELF.skillHpEnemy = nil
	end
end

local function isMainSelfSkillExist()
	return #SELF.mainSkillSelf ~= 0
end

local function isMainEnemySkillExist()
	return #SELF.mainSkillEnemy ~= 0
end

local function playMainSkillSelf()
	SELF.mainSkillSelf.isMainSkill = true
	setToPlayEffect(SELF.mainSkillSelf)
	SELF.mainSkillSelf = {};
end

local function playMainSkillEnemy()
	SELF.mainSkillEnemy.isMainSkill = true
	setToPlayEffect(SELF.mainSkillEnemy)
	SELF.mainSkillEnemy = {};
end

local function playBattleFlash()
	--print("playBattleFlash")
	SELF.self_attack_flash_co:setVisible(false)
	SELF.enemy_attack_flash_co:setVisible(false)
	SELF.self_attack_flash:setIsRun(false)
	SELF.enemy_attack_flash:setIsRun(false)
  --[[
  if SELF.enterType == BattleEnterEnum.kActivityContend and #SELF.fightEventFlow == 0 then
    SELF:showBattleResultPanel()
    return
  end
  ]]
	if #SELF.fightEventFlow == 0 and SELF.selfHp > 0 and SELF.enemyHp > 0 then
		SELF.battle_flash_co:setVisible(true)
		SELF.battle_flash:changeAnimation(BattleAnimEnum.TimeOut)
		return
	else
		local fightEvent = SELF.fightEventFlow[1]
		table.remove(SELF.fightEventFlow , 1)
    local totalRoundNum
    if SELF.enterType == BattleEnterEnum.kActivityContend then
      totalRoundNum = DataManager.GameMetaData.activityContendConfig.battleRoundNum
    else
      totalRoundNum = 20
    end
		SELF.roundTextLabel:setString(tostring(totalRoundNum - fightEvent.round) .. "\n" ..  getTextByKey("battle_round"))
		local function playLastHitAnim( id )
			-- body
			SELF.lasthit_flash:setIsRun(true)
			SELF.lasthit_flash:changeAnimation(id)
			CanonPlayEffect("music/sfx_attack_final.wav")
			SELF.lasthit_flash_co:setVisible(true)
		end

		local function playBattleAnim( id , weapon)
			-- body
			SELF.self_attack_flash_co:setVisible(true)
			SELF.self_attack_flash:setIsRun(true)
			SELF.self_attack_flash:changeAnimation(id)
			CanonPlayEffect(weapon)
		end

		local function playBattleAnimEnemy( id , weapon )
			-- body
			SELF.enemy_attack_flash_co:setVisible(true)
			SELF.enemy_attack_flash:setIsRun(true)
			SELF.enemy_attack_flash:changeAnimation(id)
			CanonPlayEffect(weapon)
		end
		if fightEvent.actionType == ActionTypeEnum.ACTION_SELF then
			setToPlayEffect({fightEvent})
			if SELF.enemyHp - fightEvent.changedValue <= 0 then
				
				if fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then
					shockScreen(1.208)
					playLastHitAnim(9)
				elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then
					playLastHitAnim(3)
				elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
					playLastHitAnim(6)
				else
					playLastHitAnim(0)
				end

			elseif fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then
				shockScreen()

				playBattleAnim(SELF.selfFlashIndex + 36, self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_MISS then

				playBattleAnim(SELF.selfFlashIndex + 9 , self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then

				playBattleAnim(SELF.selfFlashIndex + 18 , self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
				playBattleAnim(27 , self_weapon_atk_effect)
			else

				playBattleAnim(SELF.selfFlashIndex  , self_weapon_atk_effect)
			end
		else
			setToPlayEffect({fightEvent})
			if SELF.selfHp - fightEvent.changedValue <= 0 then
				if fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then
					shockScreen(1.208)
					playLastHitAnim(10)
				elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then
					playLastHitAnim(4)
				elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
					playLastHitAnim(7)
				else
					playLastHitAnim(1)
				end
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then
				shockScreen()

				playBattleAnimEnemy(SELF.enemyFlashIndex + 36 , enemy_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_MISS then

				playBattleAnimEnemy(SELF.enemyFlashIndex + 9 , enemy_weapon_atk_effect)
	-- 			ATTACK_COUNTER = 3,--反击
	-- ATTACK_BLOCK = 4--格挡
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then

				playBattleAnimEnemy(SELF.enemyFlashIndex + 18 , enemy_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
				playBattleAnimEnemy(28 , enemy_weapon_atk_effect)
			else
				-- SELF.enemy_attack_flash_co:setVisible(true)
				-- SELF.enemy_attack_flash:setIsRun(true)
				-- SELF.enemy_attack_flash:changeAnimation(SELF.enemyFlashIndex)
				-- CanonPlayEffect(enemy_weapon_atk_effect)
				playBattleAnimEnemy(SELF.enemyFlashIndex  , enemy_weapon_atk_effect)
			end
		end

	end

end

local function onAttackFlashFinish(anim)
	--print("attackover")
	if SELF.gameEnd then
		do return end
	end
	playBattleFlash()
end

local function playBuffFlash()
	SELF.hero_buff_flash_co:setVisible(true)
	if isMainSelfSkillExist() then
		playMainSkillSelf();
		CanonPlayEffect("music/sfx_skile_card.wav")
		SELF.hero_buff_flash:changeAnimation(1)
	elseif isMainEnemySkillExist() then
		playMainSkillEnemy();
		CanonPlayEffect("music/sfx_skile_card.wav")
		SELF.hero_buff_flash:changeAnimation(0)
	else
		SELF.hero_buff_flash:setIsRun(false)
		SELF.hero_buff_flash_co:setVisible(false)
		--print("setVisiblefalse")
		SELF.curRound = 1
		SELF.curIsSelfAttack = true
		SELF.self_attack_flash:setIsRun(true)
		SELF.enemy_attack_flash:setIsRun(true)
		playBattleFlash();
	end
end

local function onFlashAnimationEnd(anim)
	if SELF.gameEnd then
		do return end
	end
	--print("animation end" .. anim)
	if anim == BattleAnimEnum.Start
	or anim == BattleAnimEnum.ATKSkill
	or anim == BattleAnimEnum.DEFSkill
	or anim == BattleAnimEnum.HPSkill then
		if isSkillExist() then
			playSkillEffect()
			CanonPlayEffect("music/sfx_exp_lvup.wav")
			SELF.battle_flash:changeAnimation(SELF.playAnimation)
		else
			SELF.battle_flash:changeAnimation(BattleAnimEnum.Combine)
		end		
	elseif anim == BattleAnimEnum.Combine
	or anim == BattleAnimEnum.MainSkillSelf
	or anim == BattleAnimEnum.MainSkillEnemy then
		SELF.battle_flash_co:setVisible(false)
		SELF.hero_buff_flash_co:setVisible(true)
		--print("setvisibletrue")
		SELF.hero_buff_flash:setIsRun(true)
		playBuffFlash()
	
	elseif anim == BattleAnimEnum.FightDeath then
		if SELF.data.win then
			if not isPlatformAndroid() and not isBukaAndroid() and not isChuangMengAndroid() and not isYYBAndroid()
			and not isTWHE() and not isIosTW() and not isFunFunTW() and not isPubgameTW() and not isOffermeTW() then
				SELF.battle_flash:changeAnimation(BattleAnimEnum.Win)
			else
				if SELF.data.qte then
					SELF:setChildIndex(SELF.battle_flash_co, 9999)
					SELF:refreshIndex()
					SELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)
				else
					SELF.battle_flash:changeAnimation(BattleAnimEnum.Win)
				end
			end
		else
			SELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)
		end
	elseif anim == BattleAnimEnum.TimeOut then
		--print("timeout")
		SELF:showBattleResultPanel()
		--Director:sharedDirector():replaceScene(MainMenuScene:create())
	elseif anim == BattleAnimEnum.Win then
		SELF:showBattleResultPanel()
		--SELF.battle_flash:changeAnimation(BattleAnimEnum.JumpOut)
	elseif anim == BattleAnimEnum.Lose then
		--print("lose")
		SELF:showBattleResultPanel()
		--Director:sharedDirector():replaceScene(MainMenuScene:create())
	elseif anim == BattleAnimEnum.JumpOut then
		--print("win")
		SELF:showBattleResultPanel()
		--Director:sharedDirector():replaceScene(MainMenuScene:create())
	elseif anim == BattleAnimEnum.Crash then
		SELF:showBattleResultPanel()
		--SELF.battle_flash:changeAnimation(BattleAnimEnum.JumpOut)
	else
		--print("error")
	end
end

local crashSound
local function playCrashSound()
	if crashSound then
		CanonPlayEffect("music/" .. crashSound .. ".wav")
	end
end

onFlashEvent =  function(eventName)
	--print(eventName)
	if eventName == "showSkillName" then
		if SELF.skillName then
			SELF:removeChild(SELF.skillName, true)
		end
		SELF.skillName = BitmapText:create(SELF.mainSkillNameText,"common/skillName.fnt")--TextField:create(SELF.mainSkillNameText, nil, 50)
		SELF.skillName:setPosition(ccp(578 - 140, 1280 - 798 - 45))
		SELF.skillName:setRotation(-12)
		SELF.skillName:setScale(2)
		SELF:addChild(SELF.skillName)
	elseif eventName == "showEnemySkillName" then
		if SELF.enemyskillName then
			SELF:removeChild(SELF.enemyskillName, true)
		end
		SELF.enemyskillName = BitmapText:create(SELF.enemySkillNameText,"common/skillName.fnt")--TextField:create(SELF.enemySkillNameText, nil, 50)
		SELF.enemyskillName:setPosition(ccp(578 - 140 , 1280 - 798 - 45))
		SELF.enemyskillName:setRotation(-12)
		SELF.enemyskillName:setScale(2)
		SELF:addChild(SELF.enemyskillName)
	elseif eventName == "hideSkillName" then
		if SELF.skillName then
			SELF:removeChild(SELF.skillName, true)
		end
		SELF.skillName = nil;
	elseif eventName == "hideEnemySkillName" then
		if SELF.enemyskillName then
			SELF:removeChild(SELF.enemyskillName, true)
		end
		SELF.enemyskillName = nil;
	elseif eventName == "playCrashSound" then
		playCrashSound()
	else
		if SELF.gameEnd then
			do return end
		end
		if eventName == "lastHit" then
			CanonPlayEffect("music/sfx_card_broken.wav")
		end
		playNextEffect()
	end
end

local weaponMapTable = {}
weaponMapTable[0] = "battle/Cardbattle_normal"
weaponMapTable[1] = "battle/Cardbattle_blade"
weaponMapTable[2] = "battle/Cardbattle_spear"
weaponMapTable[3] = "battle/Cardbattle_hammer"
weaponMapTable[4] = "battle/Cardbattle_bow"

local weaponEffectTable = {}
weaponEffectTable[0] = "music/sfx_attack_bow.wav"
weaponEffectTable[1] = "music/sfx_attack_sword.wav"
weaponEffectTable[2] = "music/sfx_attack_spear.wav"
weaponEffectTable[3] = "music/sfx_attack_hammer.wav"
weaponEffectTable[4] = "music/sfx_attack_bow.wav"

local function getBattleIndexByEvolveLevel(evolveLevel, isSelf)
	local level = 1
	local battleIndex
	if tonumber(evolveLevel) == 1 then
		level = 1
	elseif tonumber(evolveLevel) == 2 then
		level = 2
	elseif tonumber(evolveLevel) == 7 then
		level = 4
	else
		level = 3
	end
	if isSelf then
		battleIndex = (level - 1) * 2
	else
		battleIndex = (level - 1) * 2 + 1
	end
	return battleIndex, level
end

local ATTACK_COLOR_GREEN = ccc3(85, 255, 145)
local ATTACK_COLOR_BLUE = ccc3(120, 153, 255)
local ATTACK_COLOR_PURPLE = ccc3(217, 119, 255)
local ATTACK_COLOR_GOLD = ccc3(255, 222, 80)
local attackColorMap = {}
attackColorMap[1] = ATTACK_COLOR_GREEN
attackColorMap[2] = ATTACK_COLOR_BLUE
attackColorMap[3] = ATTACK_COLOR_PURPLE
attackColorMap[4] = ATTACK_COLOR_GOLD
local function getSelfAttackFlash(weaponInfo)
	local attackFlashName = "battle/Cardbattle_normal"
	self_weapon_atk_effect = weaponEffectTable[1]
	if weaponInfo.weaponType and weaponMapTable[weaponInfo.weaponType] then
		attackFlashName = weaponMapTable[weaponInfo.weaponType]
		self_weapon_atk_effect = weaponEffectTable[weaponInfo.weaponType]
	end
	local battleIndex = 0
	local level = 1
	if weaponInfo.evolveLevel then
		battleIndex, level = getBattleIndexByEvolveLevel(weaponInfo.evolveLevel, true)
	end
	selfAttackColor = attackColorMap[level]
	
	if attackFlashName == "battle/Cardbattle_normal" then
		battleIndex = battleIndex % 2
	end
	
	return attackFlashName, battleIndex
end

local function getEnemyAttackFlash(weaponInfo)
	local attackFlashName = "battle/Cardbattle_normal"
	enemy_weapon_atk_effect = weaponEffectTable[1]
	if weaponInfo.weaponType and weaponMapTable[weaponInfo.weaponType] then
		attackFlashName = weaponMapTable[weaponInfo.weaponType]
		enemy_weapon_atk_effect = weaponEffectTable[weaponInfo.weaponType]
	end
	local battleIndex = 1
	local level = 1
	if weaponInfo.evolveLevel then
		battleIndex, level = getBattleIndexByEvolveLevel(weaponInfo.evolveLevel, false)
	end
	enemyAttackColor = attackColorMap[level]
	
	if attackFlashName == "battle/Cardbattle_normal" then
		battleIndex = battleIndex % 2
	end
	
	return attackFlashName, battleIndex
end

local function onLastHitFlashEnd(anim)
	if SELF.gameEnd then
		do return end
	end
	--print("onLastHitFlashEnd" .. anim)
	SELF.lasthit_flash_co:setVisible(false)
	SELF.battle_flash_co:setVisible(true)
	if SELF.data.win then

		if not isPlatformAndroid() and not isBukaAndroid() and not isChuangMengAndroid() and not isYYBAndroid()
			and not isTWHE() and not isIosTW() and not isFunFunTW() and not isPubgameTW() and not isOffermeTW() then
			SELF.battle_flash:changeAnimation(BattleAnimEnum.Win)
		else
			if SELF.data.qte then
				SELF:setChildIndex(SELF.battle_flash_co, 9999)
				SELF:refreshIndex()
				SELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)
			else
				SELF.battle_flash:changeAnimation(BattleAnimEnum.Win)
			end
		end
		-- if SELF.data.qte then
		-- 	SELF:setChildIndex(SELF.battle_flash_co, 9999)
		-- 	SELF:refreshIndex()
		-- 	SELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)
		-- else
		-- 	SELF.battle_flash:changeAnimation(BattleAnimEnum.Win)
		-- end
	else
		SELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)
	end
end

local function onHeroBuffFlashEnd(anim)
	if SELF.gameEnd then
		do return end
	end
	--print("onHeroBuffFlashEnd" .. anim)
	playNextEffect()
	local actionArray = CCArray:create()
	actionArray:addObject(CCDelayTime:create(1))
	actionArray:addObject(CCCallFuncN:create(playBuffFlash))
	SELF:runAction(CCSequence:create(actionArray))
end

function BattleScene:addBattleFlash()
	local selfMainData = nil
	local enemyMainData = nil
	local selfData = {}
	local enemyData = {}
	self.selfHp = 0
	self.enemyHp = 0
	for k, v in pairs(self.data.cardInitDatas) do
		local pos = v.posId
		if pos < 10000 then
			if pos == 1 then
				selfMainData = v
			else
				selfData[pos-1] = v
			end
			self.selfHp = self.selfHp + tonumber(v.hp)
		else
			pos = pos - 10000;
			if pos == 1 then
				enemyMainData = v
			else
				enemyData[pos-1] = v
			end
			self.enemyHp = self.enemyHp + tonumber(v.hp)
		end
	end
	self.selfMaxHp = self.selfHp
	self.enemyMaxHp = self.enemyHp
	self.finalSelfHPMaxChange = self.finalSelfHPMaxChange + self.selfMaxHp
	self.finalEnemyHPMaxChange = self.finalEnemyHPMaxChange + self.enemyMaxHp
	self.selfCardNum = #selfData + 1
	self.enemyCardNum = #enemyData + 1
	
	self.battle_flash = FlashSprite:create("battle/CardbattleXX3")
	
	local emptySpriteFrame = createSpriteFrame("pic/empty.png")
	
	for i = 1, 9 do
		local border = "cardBorder1" .. i
		local card = "card1" .. i
		local cardBg = "cardBg1" .. i
		local cardBall = "card1" .. i .. "ball"
		local cardBallbg = "card1" .. i .. "ballbg"
		local shadow = "shadow1" .. i
		self.battle_flash:addChangeInstance(border, emptySpriteFrame)
		self.battle_flash:addChangeInstance(card, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBg, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBall, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBallbg, emptySpriteFrame)
		self.battle_flash:addChangeInstance(shadow, emptySpriteFrame)
			
		border = "cardBorder2" .. i
		card = "card2" .. i
		cardBg = "cardBg2" .. i
		local cardBall = "card2" .. i .. "ball"
		local cardBallbg = "card2" .. i .. "ballbg"
		shadow = "shadow2" .. i
		self.battle_flash:addChangeInstance(border, emptySpriteFrame)
		self.battle_flash:addChangeInstance(card, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBg, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBall, emptySpriteFrame)
		self.battle_flash:addChangeInstance(cardBallbg, emptySpriteFrame)
		self.battle_flash:addChangeInstance(shadow, emptySpriteFrame)
	end
	
	local function changeFlashCard(posId, metaId, amount, flash , notAddName)
		local cardMeta = MetaManager.card_meta[tonumber(metaId)]
		local cardConfigData = getConfigData(posId, amount)
		local cardSpf = getCardSpriteFrame(metaId)
		--local cardBoardSpf = createSpriteFrame(BigBorderDict[cardMeta.rare])
		local cardBoardSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[cardMeta.rare])
		--local cardBgSpf = createSpriteFrame("card/background/" .. cardMeta.backgroundName)
		local cardBgSpf = getCardBackGroundSpriteFrameByMeta(cardMeta)
		--local cardBallSpf = createSpriteFrame("card/border/countryIcon_" .. cardMeta.country .. ".png")
		local cardBallSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryIcon_" .. cardMeta.country .. ".png")
		--local cardBallbgSpf = createSpriteFrame("card/border/countryCircle_" .. cardMeta.country .. ".png")
		local cardBallbgSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. cardMeta.country .. ".png")
		flash:addChangeInstance(cardConfigData.card, cardSpf)
		flash:addChangeInstance(cardConfigData.cardBg, cardBgSpf)
		flash:addChangeInstance(cardConfigData.cardBorder, cardBoardSpf)
		flash:addChangeInstance(cardConfigData.cardBall, emptySpriteFrame)
		flash:addChangeInstance(cardConfigData.cardBallBg, cardBallbgSpf)
		if cardConfigData.shadow then
			local shadowSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("CardbattleXX3_card_shadow.png")
			flash:addChangeInstance(cardConfigData.shadow, shadowSpf)
		end

		if self.enterType == BattleEnterEnum.kUnionBattle and not notAddName then
			local selfName = self.data.singleBattleAttName
			local enemyName = self.data.singleBattleDefName
			if enemyName == nil then
				local cityId = UnionPkData.getBattleCityId()
				enemyName = UnionPkUtils.getCityCardNpcNameById(cityId)
			end
			if cardConfigData.card == "card1M" then
				local selfNameLabel = CCLabelTTF:create(selfName, "Helvetica", 28)
				flash:addUnionBattleInstance(cardConfigData.card.."_HpBar" , selfNameLabel)
			elseif cardConfigData.card == "card2M" then
				local enemyNameLabel = CCLabelTTF:create(enemyName, "Helvetica", 28)
				flash:addUnionBattleInstance(cardConfigData.card.."_HpBar" , enemyNameLabel)
			end
		end
	end

	--替换武将头像
	if DataManager.getCurrUser().uid == selfMainData.uid then
		local mainAvatarMetaId = CommonManager:getSelfAvatarMetaByCardId(selfMainData.cardId)
		if mainAvatarMetaId ~= 0 then
			selfMainData.metaId = mainAvatarMetaId
		end

		for k,v in pairs(selfData) do
			local avatarMetaId = CommonManager:getSelfAvatarMetaByCardId(v.cardId)
			if avatarMetaId ~= 0 then
				selfData[k].metaId = avatarMetaId
			end
		end
	end
	
	changeFlashCard(selfMainData.posId, selfMainData.metaId, self.selfCardNum, self.battle_flash , true)
	for k, v in pairs(selfData) do
		changeFlashCard(v.posId, v.metaId, self.selfCardNum, self.battle_flash , true)
	end
	
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, self.enemyCardNum, self.battle_flash , true)
	for k, v in pairs(enemyData) do
		changeFlashCard(v.posId, v.metaId, self.enemyCardNum, self.battle_flash , true)
	end
	
	local notResetTable = {}
	for k,v in pairs(selfData) do
		local cardConfigIndex = getConfigDataIndex(v.posId, self.selfCardNum)
		table.insert(notResetTable, cardConfigIndex)
	end
	
	for k,v in pairs(BattleSelfConfig)
	do
		local toset = true;
		for key, value in pairs(notResetTable)
		do
			if k == value then
				toset = false;
				break;
			end
		end
		if toset and v.light then
			self.battle_flash:addChangeInstance(v.light, emptySpriteFrame)
		end
		--[[if toset and v.shadow then
			self.battle_flash:addChangeInstance(v.shadow, emptySpriteFrame)
			print("v.shadow = " .. v.shadow)
		end--]]
	end
	
	local notResetTable = {}
	for k,v in pairs(enemyData) do
		local cardConfigIndex = getConfigDataIndex(v.posId - 10000, self.enemyCardNum)
		table.insert(notResetTable, cardConfigIndex)
	end
	
	for k,v in pairs(BattleEnemyConfig)
	do
		local toset = true;
		for key, value in pairs(notResetTable)
		do
			if k == value then
				toset = false;
				break;
			end
		end
		if toset and v.light then
			self.battle_flash:addChangeInstance(v.light, emptySpriteFrame)
		end
		if toset and v.shadow then
			self.battle_flash:addChangeInstance(v.shadow, emptySpriteFrame)
			--print("v.shadow = " .. v.shadow)
		end
	end
	
	if table.getn(selfData) <= 1 then
		self.battle_flash:addChangeInstance("card1Mcircle", emptySpriteFrame)
	end
	
	if table.getn(selfData) <= 1 then
		self.battle_flash:addChangeInstance("card2Mcircle", emptySpriteFrame)
	end	
	
	local myCardSprite = CardSprite:create("card/card/" .. MetaManager.card_meta[tonumber(selfMainData.metaId)].figureId, "full")
	self.battle_flash:addChangeInstance("card2full", myCardSprite:getSpriteFrameByName("sdandard.png"))
	if self.data.qte then
		local infos = string.split(MetaManager.card_meta[tonumber(enemyMainData.metaId)].figureId, '_')
		local crushId = ""
		for infok,infov in pairs(infos)
		do
			if infok == #infos then
				crushId = crushId .. "_0"
			elseif infok + 1 == #infos then
				crushId = crushId .. infov
				crashSound = crushId
			else
				crushId = crushId .. infov .. "_"
			end
		end
		CCFileUtils:sharedFileUtils():setPopupNotify(false)
		local isExist = CCString:createWithContentsOfFile(CCFileUtils:sharedFileUtils():fullPathForFilename("card/crush/" .. crushId .. ".png"));
		if isExist then
			local spriteFrame = createSpriteFrame("card/crush/" .. crushId .. ".png")
			-- spriteFrame = createSpriteFrame("card/webpCrush/" .. crushId .. ".webp")
			if spriteFrame then
				self.battle_flash:addChangeInstance("card2crash", spriteFrame)
			end
		else
			self.data.qte = false
		end
		CCFileUtils:sharedFileUtils():setPopupNotify(true)
		
	end
	
	self.battle_flash:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	self.battle_flash:registerFlashScriptHandler(onFlashEvent)
	
	self.battle_flash:addFrameEvent("battleClip2", 1, 10)
	self.battle_flash:addFrameEvent("battleClip3", 2, 10)
	self.battle_flash:addFrameEvent("battleClip34", 33, 10)
	self.battle_flash:addFrameEvent("battleClip5", 4, 10)
	self.battle_flash:addFrameEvent("battleClip6", 5, 10)
	self.battle_flash:addFrameEvent("battleClip27", 26, 35)
	self.battle_flash:addFrameEvent("playCrashSound", BattleAnimEnum.Crash, 67)
		
	self.battle_flash:changeAnimation(0)
	self.battle_flash:setLoop(false)

	self.battle_flash_co = CocosObject.new(self.battle_flash)
	self:addChild(self.battle_flash_co)
	
	local selfAttackFlashName, selfFlashIndex = getSelfAttackFlash(self.selfWeaponInfo)
	self.selfFlashIndex = selfFlashIndex
	self.self_attack_flash = FlashSprite:create(selfAttackFlashName)
	if not addedBattleFlashTable[selfAttackFlashName] then
		self.self_attack_flash:retain();
		addedBattleFlashTable[selfAttackFlashName] = true;
	end
	changeFlashCard(selfMainData.posId, selfMainData.metaId, self.selfCardNum, self.self_attack_flash)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, self.enemyCardNum, self.self_attack_flash)
	self.self_attack_flash:changeAnimation(self.selfFlashIndex)
	self.self_attack_flash:setLoop(false)
	self.self_attack_flash:setIsRun(false)
	self.self_attack_flash:registerEndAnimationScriptHandler(onAttackFlashFinish)
	self.self_attack_flash:registerFlashScriptHandler(onFlashEvent)
	self.self_attack_flash:addFrameEvent("self_attack", self.selfFlashIndex, 10)
	self.self_attack_flash:addFrameEvent("self_attack_miss", self.selfFlashIndex + 9, 10)
	self.self_attack_flash:addFrameEvent("self_attack_block", self.selfFlashIndex + 18, 6)
	self.self_attack_flash:addFrameEvent("self_attack_crit", self.selfFlashIndex + 36, 6)
	self.self_attack_flash:addFrameEvent("self_attack_counter", 27, 8)
	
	local enemyAttackFlashName, enemyFlashIndex = getEnemyAttackFlash(self.enemyWeaponInfo)
	self.enemyFlashIndex = enemyFlashIndex
	self.enemy_attack_flash = FlashSprite:create(enemyAttackFlashName)
	if not addedBattleFlashTable[enemyAttackFlashName] then
		self.enemy_attack_flash:retain();
		addedBattleFlashTable[enemyAttackFlashName] = true;
	end
	changeFlashCard(selfMainData.posId, selfMainData.metaId, self.selfCardNum, self.enemy_attack_flash)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, self.enemyCardNum, self.enemy_attack_flash)
	self.enemy_attack_flash:changeAnimation(self.enemyFlashIndex)
	self.enemy_attack_flash:setLoop(false)
	self.enemy_attack_flash:setIsRun(false)
	self.enemy_attack_flash:registerEndAnimationScriptHandler(onAttackFlashFinish)
	self.enemy_attack_flash:registerFlashScriptHandler(onFlashEvent)
	self.enemy_attack_flash:addFrameEvent("enemy_attack", self.enemyFlashIndex, 10)
	self.enemy_attack_flash:addFrameEvent("enemy_attack_miss", self.enemyFlashIndex + 9, 10)
	self.enemy_attack_flash:addFrameEvent("enemy_attack_block", self.enemyFlashIndex + 18, 6)
	self.enemy_attack_flash:addFrameEvent("enemy_attack_crit", self.enemyFlashIndex + 36, 6)
	self.enemy_attack_flash:addFrameEvent("enemy_attack_counter", 28, 8)
	
	self.self_attack_flash_co = CocosObject.new(self.self_attack_flash)
	self:addChild(self.self_attack_flash_co)
	self.self_attack_flash_co:setVisible(false)
	self.enemy_attack_flash_co = CocosObject.new(self.enemy_attack_flash)
	self:addChild(self.enemy_attack_flash_co)
	self.enemy_attack_flash_co:setVisible(false)
	
	self.lasthit_flash = FlashSprite:create("battle/Cardbattle_lasthit")
	changeFlashCard(selfMainData.posId, selfMainData.metaId, self.selfCardNum, self.lasthit_flash)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, self.enemyCardNum, self.lasthit_flash)
	self.lasthit_flash:addChangeInstance("blackcover", emptySpriteFrame)
	self.lasthit_flash:setLoop(false)
	self.lasthit_flash:setIsRun(false)
	self.lasthit_flash:registerEndAnimationScriptHandler(onLastHitFlashEnd)
	self.lasthit_flash:registerFlashScriptHandler(onFlashEvent)
	self.lasthit_flash:addFrameEvent("lastHit", 0, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 1, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 3, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 4, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 6, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 7, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 9, 25)
	self.lasthit_flash:addFrameEvent("lastHit", 10, 25)
	
	self.lasthit_flash_co = CocosObject.new(self.lasthit_flash)
	self:addChild(self.lasthit_flash_co)
	self.lasthit_flash_co:setVisible(false)
	
	self.hero_buff_flash = FlashSprite:create("battle/hero_buff")
	self.hero_buff_flash:addChangeInstance("skillname", emptySpriteFrame)
	changeFlashCard(selfMainData.posId, selfMainData.metaId, self.selfCardNum, self.hero_buff_flash)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, self.enemyCardNum, self.hero_buff_flash)
	self.hero_buff_flash:addChangeInstance("card1Mfull", getFullCardSpriteFrame(selfMainData.metaId))
	self.hero_buff_flash:addChangeInstance("card2Mfull", getFullCardSpriteFrame(enemyMainData.metaId))
	self.hero_buff_flash:setLoop(false)
	self.hero_buff_flash:setIsRun(false)
	self.hero_buff_flash:registerEndAnimationScriptHandler(onHeroBuffFlashEnd)
	self.hero_buff_flash:registerFlashScriptHandler(onFlashEvent)
	self.hero_buff_flash:addFrameEvent("showSkillName", 1, 10)
	self.hero_buff_flash:addFrameEvent("showEnemySkillName", 0, 10)
	self.hero_buff_flash:addFrameEvent("hideSkillName", 1, 30)
	self.hero_buff_flash:addFrameEvent("hideEnemySkillName", 0, 30)
	
	self.hero_buff_flash_co = CocosObject.new(self.hero_buff_flash)
	self:addChild(self.hero_buff_flash_co)
	self.hero_buff_flash_co:setVisible(false)
	--print("setvisiblefalse")
end

local tBattleBgMap = {}
tBattleBgMap["bg001_png"] = "battle/BG/bg001"
tBattleBgMap["bg002_png"] = "battle/BG/bg002"
tBattleBgMap["bg004_png"] = "battle/BG/bg004"
tBattleBgMap["bg003_png"] = "battle/BG/bg003"
local function getBgFlashName()
	local bgFlashName = "battle/BG/bg001"
	
	if SELF.enterType == BattleEnterEnum.kUserDetailPanel
	or SELF.enterType == BattleEnterEnum.kArenaScene then
		bgFlashName = "battle/BG/bg005"
	elseif SELF.enterType == BattleEnterEnum.kTongTianTa or SELF.enterType == BattleEnterEnum.kCrossPVP then
		bgFlashName = "battle/BG/bg006"
	elseif SELF.enterType == BattleEnterEnum.kNewBabel or SELF.enterType == BattleEnterEnum.kActivityCrossBoss then
		bgFlashName = "battle/BG/bg006"
	elseif SELF.enterType == BattleEnterEnum.kPKScene or SELF.enterType == BattleEnterEnum.kRobFragmentScene then
		bgFlashName = "battle/BG/bg005"
	elseif SELF.enterType == BattleEnterEnum.kUnionBattle then
		bgFlashName = "battle/BG/bg001"
	elseif SELF.enterType ~= BattleEnterEnum.kFakeBattle then
		local missionId
		if SELF.data then
			missionId = SELF.data.missionID
		end
		if not missionId then
			missionId = CountryManager:sharedManager().selectedMissionID
		end
		local cityId = tonumber(string.sub(tostring(missionId), 1, 2))
		for k,v in pairs(MetaManager.battle_country)
		do
			if v.id == cityId then
				bgFlashName = v.battleBGID
				if tBattleBgMap[bgFlashName] then
					bgFlashName = tBattleBgMap[bgFlashName]
				else
					bgFlashName = "battle/BG/" .. bgFlashName
				end
				break;
			end
		end
	else
	end
	return bgFlashName
end

function BattleScene:unionSingleBattleBeforeInit()
	if not self.isSceneInitialized then
	    self.isSceneInitialized = true;
	    self.rootLayer = RootLayer.new(); --scene's root layer is a RootLayer class
	    self.rootLayer:initLayer();
	    self:superAddChild(self.rootLayer);
	end
	  
	    self:setTouchEnabled(true);
	local singleBattle = FlashSprite:create("battle/SingleBattleWord")
	singleBattle:changeAnimation(0)
	singleBattle:setLoop(false)
	local singleBattle_co = CocosObject.new(singleBattle)
	local function onCloudFlashAnimationEnd(anim)
		singleBattle:unregisterEndAnimationScriptHandler()
		self:removeChild(singleBattle_co)
		--Set_ShareData( "Cloud_Finished", 1 )
		self.singleBattle = nil;
		self:initScene()
	end
	self.singleBattle = singleBattle
	singleBattle:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
	self:addChild(singleBattle_co)
end

function BattleScene:onInit()
	local bgFlashName = getBgFlashName()
	local bg = FlashSprite:create(bgFlashName)
	if not addedBattleFlashTable[bgFlashName] then
		bg:retain();
		addedBattleFlashTable[bgFlashName] = true;
	end
	bg:changeAnimation(0)
	local bg_co = CocosObject.new(bg)
	self.bg = bg
	self:addChild(bg_co)
	
	local function addParticle(effectPath , position)
		local particle = CCParticleSystemQuad:create(effectPath)
		particle:setPosition(position)
		particle:setScale(2)
		self:addChild(CocosObject.new(particle))
	end
	
	if bgFlashName == "battle/BG/bg001" then
		addParticle("effect/fx_fireworm.plist", ccp(30, 640))
		addParticle("effect/fx_fireworm.plist", ccp(690, 640))
	elseif bgFlashName == "battle/BG/bg003" then
		addParticle("effect/fx_snow.plist", ccp(360, 1280))
	elseif bgFlashName == "battle/BG/bg005" then
		addParticle("effect/fx_fire.plist", ccp(30, 640))
		addParticle("effect/fx_fire.plist", ccp(30, 40))
		addParticle("effect/fx_fire.plist", ccp(30, 1240))
		addParticle("effect/fx_fire.plist", ccp(690, 640))
		addParticle("effect/fx_fire.plist", ccp(690, 40))
		addParticle("effect/fx_fire.plist", ccp(690, 1240))
	elseif bgFlashName == "battle/BG/bg006" then
		addParticle("effect/fx_blue_fire.plist", ccp(30, 640))
		addParticle("effect/fx_blue_fire.plist", ccp(30, 40))
		addParticle("effect/fx_blue_fire.plist", ccp(30, 1240))
		addParticle("effect/fx_blue_fire.plist", ccp(690, 640))
		addParticle("effect/fx_blue_fire.plist", ccp(690, 40))
		addParticle("effect/fx_blue_fire.plist", ccp(690, 1240))
	end

	local function afterShowSingleBattleWordForUnionBattle(  )
		--self:sceneFitDevice("pic/BattleShipei.png")
		self.selfWeaponInfo = {}
		if self.enterType == BattleEnterEnum.kFakeBattle then
			for k,v in pairs(self.data.cardInitDatas)
			do
				if v.posId == 1 then
	        if(not v.sharkEquips) then -- add by spark
	          break;
	        end
					for equipkey,equipvalue in pairs(v.sharkEquips)
					do
						local equipMeta = MetaManager.equip_meta[equipvalue.metaId]
						if equipMeta.position == 1 then
							self.selfWeaponInfo = equipMeta
							break;
						end
					end
					break;
				end
			end
		else
			local selfMainCardId = CommonManager.getQueueData( )[1]
			for k,v in pairs(DataManager.getEquipsData())
			do
				if selfMainCardId == v.cardId then
					local equipMeta = MetaManager.equip_meta[v.metaId]
					if equipMeta.position == 1 then
						self.selfWeaponInfo = equipMeta
						break;
					end
				end
			end
		end
		self.enemyWeaponInfo = {}
		if SELF.enterType == BattleEnterEnum.kUserDetailPanel
		or SELF.enterType == BattleEnterEnum.kArenaScene then
			for k,v in pairs(self.data.cardInitDatas)
			do
				if v.posId == 10001 then
	        if(not v.sharkEquips) then -- add by spark
	          break;
	        end
					for equipkey,equipvalue in pairs(v.sharkEquips)
					do
						local equipMeta = MetaManager.equip_meta[equipvalue.metaId]
						if equipMeta.position == 1 then
							self.enemyWeaponInfo = equipMeta
							break;
						end
					end
					break;
				end
			end
		else
			if self.enterType == BattleEnterEnum.kFakeBattle then
			else
				local monsterGroup
				local monsterId
				
				print("selectid = " .. tostring(SELF.data.selectId))
				if SELF.enterType == BattleEnterEnum.kTongTianTa then
					for k,v in pairs(MetaManager.babel_setting)
					do
						if tonumber(v.id) == tonumber(SELF.data.selectId) then
							monsterGroup = tonumber(v.monsterGroupId)
							break;
						end
					end
				elseif SELF.enterType == BattleEnterEnum.kNewBabel then
					monsterGroup = SELF.data.monsterGroupId
				elseif SELF.enterType == BattleEnterEnum.kDestinyFightScene then
					monsterGroup = SELF.data.monsterGroupId
				elseif SELF.enterType == BattleEnterEnum.kActivityCowStage then
					for k,v in pairs(MetaManager.cow_stage)
					do
						if tonumber(v.id) == tonumber(SELF.data.selectId) then
							monsterGroup = tonumber(v.monsterGroupId)
							break;
						end
					end
				elseif SELF.enterType == BattleEnterEnum.kEliteMissionScene then
					for k,v in pairs(MetaManager.elite_setting)
					do
						if tonumber(v.id) == tonumber(SELF.data.selectId) then
							monsterGroup = tonumber(v.monsterGroupId)
							break;
						end
					end
				else			
					for k,v in pairs(MetaManager.battle_event_battle)
					do
						if tonumber(v.missionId) == tonumber(CountryManager:sharedManager().selectedMissionID) then
							monsterGroup = v.monsterGroupId
							break;
						end
					end
				end
				
				if monsterGroup then
					for k, v in pairs(MetaManager.battle_monster_group)
					do
						if tonumber(monsterGroup) == tonumber(v.id) then
							monsterId = string.split(v.monsterIdList, '|')[1]
							break					
						end
					end
				end
				
				
				local cardId = MetaManager.battle_monster[tonumber(monsterId)].cardId
				
				local cardMeta = MetaManager.card_meta[tonumber(cardId)]
				
				self.enemyWeaponInfo.weaponType = cardMeta.weaponType
				self.enemyWeaponInfo.evolveLevel = cardMeta.rare
			end
		--todo  get monsterWeaponInfoByCardMeta  rare and weaponType
		end
		
		self.effectFlash = {}
		self.skillAttackSelf = {}
		self.skillDefenseSelf = {}
		self.skillHpSelf = {}
		self.skillAttackEnemy = {}
		self.skillDefenseEnemy = {}
		self.skillHpEnemy = {}
		self.mainSkillSelf = {}
		self.mainSkillEnemy = {}
		self.fightEventFlow = {}
		self.fightRound = 0
		self.finalRound = 0
		self.finalSelfHPChange = 0
		self.finalEnemyHPChange = 0
		self.finalSelfHPMaxChange = 0
		self.finalEnemyHPMaxChange = 0
		-- print(table.tostring(self.data.eventFlow))
		local function realignEventFlow(  )
			-- body
			self.newEventFlow = {}
			for k,v in pairs(self.data.eventFlow) do
				local event = {}
				event.eventType = v.eventType
				event.round = v.round
				event.actionType = v.actionType
				if v.battleCardActs then
					event.posId = v.battleCardActs[1].posId
					event.skillId = v.battleCardActs[1].skillId
					event.effectId = v.battleCardActs[1].effectId
					event.changedValue = v.battleCardActs[1].changedValue
				else
					if v.actionType == ActionTypeEnum.ACTION_SELF then
						event.posId = 10000
					else
						event.posId = 0
					end
					event.skillId = 0
					event.effectId = 0
					event.changedValue = 0
				end
				table.insert(self.newEventFlow , event)
			end
			
		end
		realignEventFlow()
		for k, v in pairs(self.newEventFlow) do
		-- for k, v in pairs(self.data.eventFlow) do
			if tonumber(v.round) > self.finalRound then
				self.finalRound = tonumber(v.round)
			end
			-- if v.round == 0 then
				if v.eventType == EVENTTYPE.SELF_SKILL then
					if v.actionType == ActionTypeEnum.ACTION_SELF then
						if v.effectId == EFFECTTYPE.ATK_INC then
							table.insert(self.skillAttackSelf, v)
						elseif v.effectId == EFFECTTYPE.DEF_INC then
							table.insert(self.skillDefenseSelf, v)
						elseif v.effectId == EFFECTTYPE.HP_INC then
							table.insert(self.skillHpSelf, v)
							--self.finalSelfHPChange = self.finalSelfHPChange + v.toCardActs[1].changedValue
							self.finalSelfHPMaxChange = self.finalSelfHPMaxChange + v.changedValue
						end
					else
						if v.effectId == EFFECTTYPE.ATK_INC then
							table.insert(self.skillAttackEnemy, v)
						elseif v.effectId == EFFECTTYPE.DEF_INC then
							table.insert(self.skillDefenseEnemy, v)
						elseif v.effectId == EFFECTTYPE.HP_INC then
							table.insert(self.skillHpEnemy, v)
							--self.finalEnemyHPChange = self.finalEnemyHPChange + v.toCardActs[1].changedValue
							self.finalEnemyHPMaxChange = self.finalEnemyHPMaxChange + v.changedValue
						end
					end
				elseif v.eventType == EVENTTYPE.MAIN_SKILL then
					if v.actionType == ActionTypeEnum.ACTION_SELF then
						table.insert(self.mainSkillSelf , v)
					else
						table.insert(self.mainSkillEnemy , v)
					end
					--数值变化
					if v.effectId == EFFECTTYPE.HP_INC then
						if v.posId < 10000 then
							self.finalSelfHPMaxChange = self.finalSelfHPMaxChange + v.changedValue
						else
							self.finalEnemyHPMaxChange = self.finalEnemyHPMaxChange + v.changedValue
						end
					elseif v.effectId == EFFECTTYPE.HP_DEC then
						if v.posId < 10000 then
							self.finalSelfHPChange = self.finalSelfHPChange - v.changedValue
						else
							self.finalEnemyHPChange = self.finalEnemyHPChange - v.changedValue
						end
					end

				elseif v.eventType == EVENTTYPE.ATTACK 
						or v.eventType == EVENTTYPE.ATTACK_CRIT 
						or v.eventType == EVENTTYPE.ATTACK_MISS 
						or v.eventType == EVENTTYPE.ATTACK_COUNTER 
						or v.eventType == EVENTTYPE.ATTACK_BLOCK then
						if v.eventType == EVENTTYPE.ATTACK_COUNTER then
							v.actionType = (v.actionType + 1)%2
						end
					table.insert(self.fightEventFlow , v)
					
					if v.posId < 10000 then
						self.finalSelfHPChange = self.finalSelfHPChange - v.changedValue
					else
						self.finalEnemyHPChange = self.finalEnemyHPChange - v.changedValue
					end
				end
		end
		
		self.mainSkillNameText = ""
		if self.mainSkillSelf and #self.mainSkillSelf > 0 then
			local skillId = self.mainSkillSelf[1].skillId
			if skillId then
				self.mainSkillNameText = getTextByKey(MetaManager.skill_meta[skillId].name1)
			end
		end
		
		self.enemySkillNameText = ""
		if self.mainSkillEnemy and #self.mainSkillEnemy > 0 then
			local skillId = self.mainSkillEnemy[1].skillId
			if skillId then
				self.enemySkillNameText = getTextByKey(MetaManager.skill_meta[skillId].name1)
			end
		end
		
		local roundBg = Sprite:create("battle/pic/bbg.png")
		roundBg:setAnchorPoint(ccp(1, 0.5))
		roundBg:setPosition(ccp(720, 640))
		self:addChild(roundBg)
		
	  local totalRoundNum
	    if self.enterType == BattleEnterEnum.kActivityContend then
	      totalRoundNum = DataManager.GameMetaData.activityContendConfig.battleRoundNum
	    else
	      totalRoundNum = 20
	    end
		self.roundTextLabel = TextField:create(totalRoundNum .. "\n" .. getTextByKey("battle_round"), nil, 30, CCSizeMake(40, 0), kCCTextAlignmentCenter, kCCVerticalTextAlignmentCenter)
		self.roundTextLabel:setPosition(ccp(720 - 37, 640))
		self:addChild(self.roundTextLabel)
		
		self:addBattleFlash();
		
		local buttonBg = Sprite:create("battle/pic/juice.png")
		buttonBg:setAnchorPoint(ccp(1, 0))
		buttonBg:setPosition(ccp(720, 0))
		self:addChild(buttonBg)
		self.skipButtonBg = buttonBg
		
		local function addSkipButtonInBattle()
			local skipSprite = Sprite:create("battle/pic/skip_active.png")
			skipSprite:setAnchorPoint(ccp(1, 0))
			skipSprite:setPosition(ccp(720, 0))
			self:addChild(skipSprite)
			self.skipButtonSprite = skipSprite
			
			local function onSkipClick( evt )
				SELF:showBattleResultPanel()
			end
			
			local skipButton = Button:create(skipSprite)
			skipButton:addEventListener( Events.kStart, onSkipClick )
			self.skipButton = skipButton
		end
		
		if isCurVersionForTest() then
			addSkipButtonInBattle()
		else
			local newBabelData = DataManager.getSharkSkyTowerData()
			if self.enterType == BattleBackType.kFakeBattle or self.data.forbidSkip == true then
				buttonBg:setVisible(false)
			elseif tonumber(DataManager.getCurrUser().vipLevel) >= 1 then
				addSkipButtonInBattle()
			elseif self.enterType == BattleEnterEnum.kNewBabel  then
				addSkipButtonInBattle()
			else
				local skipSprite = Sprite:create("battle/pic/skip_inactive.png")
				skipSprite:setAnchorPoint(ccp(1, 0))
				skipSprite:setPosition(ccp(720, 0))
				self:addChild(skipSprite)
				self.skipButtonSprite = skipSprite
			end
		end
		
		local hpBarBg = Sprite:create("battle/pic/xuecao.png")
		hpBarBg:setPosition(ccp(visibleSize.width/2,30))
		hpBarBg:setScaleX(0.9)
		self:addChild(hpBarBg)
		
		local hpBarBg = Sprite:create("battle/pic/xuecao.png")
		hpBarBg:setPosition(ccp(visibleSize.width/2,visibleSize.height - 30))
		hpBarBg:setScaleX(0.9)
		self:addChild(hpBarBg)
		
		self.selfHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
		self.selfHpPB:setPosition(ccp(visibleSize.width/2, 30))
		self.selfHpPB:setType(kCCProgressTimerTypeBar);
		self.selfHpPB:setMidpoint(ccp(0,0))
		self.selfHpPB:setBarChangeRate(ccp(1, 0))
		self.selfHpPB:setPercentage(99.99)
		self.selfHpPB:setScaleX(0.9)
		self:addChild(CocosObject.new(self.selfHpPB))
		
		
		if self.data.bossHpMax then
			self.enemyMaxHp = self.data.bossHpMax
			self.finalEnemyHPChange = self.finalEnemyHPChange + self.enemyHp - self.data.bossHpMax
			self.finalEnemyHPMaxChange = self.enemyMaxHp
		end
		local enemyHPPercentage = self.enemyHp / self.enemyMaxHp * 100
		if enemyHPPercentage > 99.99 then
			enemyHPPercentage = 99.99
		end
		

		self.enemyHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
		self.enemyHpPB:setPosition(ccp(visibleSize.width/2,visibleSize.height - 30))
		self.enemyHpPB:setType(kCCProgressTimerTypeBar);
		self.enemyHpPB:setMidpoint(ccp(1,1))
		self.enemyHpPB:setBarChangeRate(ccp(1, 0))
		self.enemyHpPB:setPercentage(enemyHPPercentage)
		self.enemyHpPB:setScaleX(0.9)
		self:addChild(CocosObject.new(self.enemyHpPB))
			
		self.selfHpNumSpt = ArtTextField:create(tostring(self.selfHp) .. "/" .. tostring(self.selfMaxHp), nil, 25)
		self.selfHpNumSpt:setPosition(ccp(visibleSize.width/2, 30 + 30))
		self:addChild(self.selfHpNumSpt)
		
		self.enemyHpNumSpt = ArtTextField:create(tostring(self.enemyHp) .. "/" .. tostring(self.enemyMaxHp), nil, 25)
		self.enemyHpNumSpt:setPosition(ccp(visibleSize.width/2, visibleSize.height -30 - 30))
		self:addChild(self.enemyHpNumSpt)
	end

	if self.enterType == BattleEnterEnum.kUnionBattle and self.data.cardInitDatas == nil then
		local data,detailData = UnionBattleSettlementPopPanel.FormatData(self.unionBattleData)
		local aMyGuildPanel =  nil
		if detailData.available then
			aMyGuildPanel = UnionBattleSettlementPopPanel:create(self,data,detailData)
		else
			aMyGuildPanel = UnionBattleSettlementMiniPopPanel:create(self,data)
		end

		self:addChild(aMyGuildPanel)
		aMyGuildPanel:scaleIn()
		return
	end

	if self.data.cardInitDatas == nil and 
					(self.enterType == BattleEnterEnum.kCrossGVGGroupBattle or self.enterType == BattleEnterEnum.kCrossGVGRankBattle) then
		self.targetInfoPanel = CrossUnionPkBattleResultPanel:create(self.enterType, self.data, self.unionBattleData.currPoints, self.unionBattleData.changePoints)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
		return
	end

	if self.enterType == BattleEnterEnum.kUnionBattle or self.enterType == BattleEnterEnum.kCrossGVGGroupBattle or 
	self.enterType == BattleEnterEnum.kCrossGVGRankBattle then
		local singleBattle = FlashSprite:create("battle/SingleBattleWord")
		singleBattle:changeAnimation(0)
		singleBattle:setLoop(false)
		local singleBattle_co = CocosObject.new(singleBattle)
		local function onCloudFlashAnimationEnd(anim)
			singleBattle:unregisterEndAnimationScriptHandler()
			self:removeChild(singleBattle_co)
			--Set_ShareData( "Cloud_Finished", 1 )
			self.singleBattle = nil;
			afterShowSingleBattleWordForUnionBattle()
		end
		self.singleBattle = singleBattle
		singleBattle:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
		self:addChild(singleBattle_co)
	else
		afterShowSingleBattleWordForUnionBattle()
	end

	
		
end

function BattleScene:dispose()
	g_isInBattleScene = false
	local function unregisterScriptHandler(flash)
		if flash then
			flash:unregisterEndAnimationScriptHandler()
		end
	end
	--[[unregisterScriptHandler(self.battle_flash)
	unregisterScriptHandler(self.self_attack_flash)
	unregisterScriptHandler(self.enemy_attack_flash)
	unregisterScriptHandler(self.lasthit_flash)
	unregisterScriptHandler(self.hero_buff_flash)--]]
	Scene.dispose(self)
end

function BattleScene:showNotEnoughEventPointPanel()
  local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
  if hasProp then
    self:showUseEventPointProptPanel(eventPointPropList)
  else
    self:showEventPointLimitPanel()
  end
end

function BattleScene:showUseEventPointProptPanel(eventPointPropList)
  local function callback(aEventPointPropId)
    self:recoveryEventPoint(aEventPointPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, eventPointPropList, callback)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function BattleScene:recoveryEventPoint(aEventPointPropId)
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

function BattleScene:showEventPointLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function BattleScene:setTableViewsEnabled( flag )
	--do nothing
end

function BattleScene:replaceScene(Scene, argumentList)
	Director:sharedDirector():replaceScene(Scene:create(argumentList ,true))
end

function BattleScene:showMainActorPanel()
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end
