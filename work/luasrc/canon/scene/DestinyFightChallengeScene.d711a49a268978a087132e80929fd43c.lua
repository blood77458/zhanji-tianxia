require "canon.scene.BaseUIScene"
require "canon.request.DestinyBattleRequest"
require "canon.panel.ChoseMainCardDestinyFightPanel"

DestinyFightChallengeScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function DestinyFightChallengeScene:ctor()
  self.title = getTextByKey("destinyBattle_title")
  self.argv = nil
  
  self.mainUI = nil
  self.contentLayer = nil
end

function DestinyFightChallengeScene:create(argv)
  local scene = DestinyFightChallengeScene.new()
  
  if(argv) then
    scene.argv = argv
  else 
    scene.argv = {enterScene = nil, returnScene = nil, params = {}}
  end
    
  scene:initScene()
  return scene
end

function DestinyFightChallengeScene:back()
	self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "destiny"}})
end



function DestinyFightChallengeScene:refreshUI(destinyData)
	self.destinyData = destinyData
	self.mainUI:getChildByName("txt_destiny_fight2"):getChildByName("txt"):setString(getTextByKey("destinyBattle_stage",{num = destinyData.destinyBattleRound}))--destiny round
	self.mainUI:getChildByName("txt_destiny_fight3"):getChildByName("txt"):setString(getTextByKey("destinyBattle_battle" .. destinyData.destinyBattleStage))--destiny stage
	
	--是否是boss战
	if destinyData.bossStage then
		--boss战，只选一个武将出战，默认主将
		setDestinyFightCardId(DataManager.getGameInitData().sharkUser.mainCardId)
	else
		--非boss战，全队列武将出战
		setDestinyFightCardId(0)
	end
	
	--记录王者殿堂等级
	local gameInitData = DataManager.getGameInitData()
	local destinyLocalInfo = gameInitData.sharkDestinyInfo
	destinyLocalInfo.spiritConcentrateLevel = destinyData.spiritConcentrateLevel
	DataManager.setGameInitData(gameInitData)
	
	--跳转到王者殿堂
	local function onClickGotoBossHall(evt)
		Director:sharedDirector():replaceScene(KingTempleScene:create( {returnScene = "DestinyFightChallengeScene" , params = {ignoreAction = false}}))
	end
	self.challengeButton = Button:create(self.mainUI:getChildByName("icon_getsoul"))
	self.challengeButton:addEventListener( Events.kStart, onClickGotoBossHall, self ) 
	if destinyData.spiritConcentrateLevel <= 0 then
		self.challengeButton:setVisible(false)
		self.challengeButton:setEnable(false)
	else
		self.challengeButton:setVisible(true)
		self.challengeButton:setEnable(true)
	end
	
	local guide_other = self.mainUI:getChildByName("full")
    guide_other:setVisible(false)
    local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(destinyData.cardId))
    card3_spf:setScale(1.3)
    card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0 +75))
    self.mainUI:addChildAt(card3_spf, 4)
	
	--挑战宿命对决
	local function onClickDestinyFight(evt)
		if destinyData.destinyBattleTotalNum <= destinyData.destinyBattleNum then
			CanonMessageBox.showText(ShowButtonType.ID_OK, getTextByKey("destinyBattle_challengeTimes").."0", nil,
											{
												text = getTextByKey("yes"),
												callbackFunc = function()
												end
											}
										)
			return 
		end
		
		if destinyData.bossStage then
			--boss战，先选出战武将
			self.targetInfoPanel = ChoseMainCardDestinyFightPanel:create( self, destinyData)
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
		else
			--非boss战，全队列武将直接出战
			challengeDestinyFight(destinyData)
		end
				
	end
	self.challengeButton = Button:create(self.mainUI:getChildByName("btn_goup"))
	self.challengeButton:addEventListener( Events.kStart, onClickDestinyFight, self ) 
	if destinyData.destinyBattleOver then
		self.challengeButton:setVisible(false)
		self.mainUI:getChildByName("txt_destiny_fight1"):getChildByName("txt"):setString(getTextByKey("destinyBattle_clear"))
	elseif DataManager.getCurrUser().level < destinyData.levelPrerequisite then
		self.mainUI:getChildByName("btn_goup"):getChildByName("btn"):setVisible(false)
		self.challengeButton:setEnable(false)
		self.mainUI:getChildByName("txt_destiny_fight1"):getChildByName("txt"):setString(getTextByKey("destinyBattle_levelInsufficient",{num = destinyData.levelPrerequisite}))--destiny info
	else
		self.mainUI:getChildByName("btn_goup"):getChildByName("btn"):setVisible(true)
		self.challengeButton:setEnable(true)
		self.mainUI:getChildByName("txt_destiny_fight1"):getChildByName("txt"):setString(getTextByKey("destinyBattle_challengeTimes") .. (destinyData.destinyBattleTotalNum-destinyData.destinyBattleNum) .. "/"..destinyData.destinyBattleTotalNum)--destiny info
	end
	self.mainUI:getChildByName("btn_goup"):getChildByName("txt"):setString(getTextByKey("destinyBattle_challengeBtn"))
end

function DestinyFightChallengeScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile( "scene/destiny_fight.json" )
	builder.useArtLabelTTF = true
	self.mainUI = builder:build("destiny_fight_2")
	self:addChild(self.mainUI)
	
	local guide_other = self.mainUI:getChildByName("full")
	guide_other:setVisible(false)
	BaseUIScene.onInit(self)
	
	 local function onEnter(evt)
		
		local function getInfoSuccess(e)
			--print("getDestinyInfo Success: " .. table.serialize(e.data))
			self:refreshUI(e.data)
		end
		
		local function getInfoFail(e)
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		end
		local params = nil
		local getDestinyInfoRequest = GetDestinyInfoRequest.new(params, rpc.SendingPriority.kHigh)
		getDestinyInfoRequest:addEventListener(RequestNotifyEnum.GetDestinyInfoSucceed, getInfoSuccess)
		getDestinyInfoRequest:addEventListener(RequestNotifyEnum.GetDestinyInfoFailed, getInfoFail)
		getDestinyInfoRequest:start()
	end
	self:addEventListener(Events.kAddToStage, onEnter)
end

function DestinyFightChallengeScene:dispose()
  DestinyFightChallengeScene.super.dispose(self)
end

function DestinyFightChallengeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function DestinyFightChallengeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function DestinyFightChallengeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() + visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function DestinyFightChallengeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function DestinyFightChallengeScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function DestinyFightChallengeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function DestinyFightChallengeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function DestinyFightChallengeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function challengeDestinyFight(destinyData)
	local function gotoBattleSuccess(e)
		local destinyBattleList = MetaManager.game_meta.destinyBattleConfig.destinyBattleList
		local monsterGroupId = nil
		local isBossBattle = false
		for k,v in pairs(destinyBattleList) do
			if destinyData.destinyBattle == v.id then
				monsterGroupId = v.monsterGroupId
				if v.stageType == 2 then
					isBossBattle = true
				end
				break
			end
		end
		e.data.monsterGroupId = monsterGroupId
		e.data.isBossBattle = isBossBattle
		Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kDestinyFightScene, BattleEnterEnum.kDestinyFightScene))
	end
		
	local function gotoBattleFail(e)
		CanonMessageBox:showCommUnHandleErrorBox( e.data )
	end
		
	local params = {cardId = getDestinyFightCardId() , destinyBattleId = destinyData.destinyBattle}
	local destinyBattleRequest = DestinyBattleRequest.new(params, rpc.SendingPriority.kHigh)
	destinyBattleRequest:addEventListener(RequestNotifyEnum.DestinyBattleSucceed, gotoBattleSuccess)
	destinyBattleRequest:addEventListener(RequestNotifyEnum.DestinyBattleFailed, gotoBattleFail)
	destinyBattleRequest:start()
end