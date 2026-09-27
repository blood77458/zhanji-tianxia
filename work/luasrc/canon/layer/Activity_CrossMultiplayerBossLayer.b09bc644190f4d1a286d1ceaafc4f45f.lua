require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.manager.BagCalcManager"
require "hecore.ui.TableView"
require "canon.models.PackageModel"
require "canon.customUI.CdLabelComponent"
require "canon.request.RefreshCrossBossBattlePhaseRequest"
require "canon.request.ChallengeCrossBossRequest"
require "canon.panel.CrossBossInspirePanel"
require "canon.panel.CrossMultiplayerRankRewardInfoPanel"
require "canon.panel.HeroViewPanel"
require "canon.panel.CrossBossInfoPanel"
require "canon.request.GainCrossBossRewardRequest"
require "canon.panel.CrossMultiplayerGetRankRewardPanel"
require "canon.request.GetCrossBossRankInfoRequest"
require "canon.panel.CrossBossRankInfoPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_CrossMultiplayerBossLayer = class(Layer)

local SELF = nil

function Activity_CrossMultiplayerBossLayer:ctor()
  self.container = nil
  self.builders = {}
  SELF = self
end

function Activity_CrossMultiplayerBossLayer:create( container , extraArgs)
	CrossWorldBossManager.setIsInCrossBossLayer(true)
  local s = Activity_CrossMultiplayerBossLayer.new()
  s.container = container
  s.extraArgs = extraArgs
  s.version = s.extraArgs.crossVersion
  s:initLayer()
  
  return s
end

function Activity_CrossMultiplayerBossLayer:enable(curTimeStamp)
	gameInitData = DataManager.getGameInitData()
    local isEnable = gameInitData.crossBossActivityStatus and MaintenanceManager.isActivityOpen(CrossWorldBossManager.getCrossBossSettingConfig().featureNameReward)
    return isEnable
    -- return true
end 

function Activity_CrossMultiplayerBossLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_CrossMultiplayerBossLayer:dispose()
	CrossWorldBossManager.setIsInCrossBossLayer(false)
	Activity_CrossMultiplayerBossLayer.super.dispose(self)
  if self.updateTriggerFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTriggerFunc )
  end
  if self.onCrossDayUpdateFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.onCrossDayUpdateFunc )
  end

  if self.cdLabelComponent then
    self.cdLabelComponent:stop()
  end

end

function Activity_CrossMultiplayerBossLayer:getBossCurrentHp()
  local hp = self.battlePhaseMini.hp
  if self.battlePhaseMini and self.battlePhaseMini.combos then
    for k,v in pairs(self.battlePhaseMini.combos) do
      hp = hp + v.hurt
    end
  end
  return hp
end

function Activity_CrossMultiplayerBossLayer:getRank()
  return self.battlePhaseMini.ranks
end

function Activity_CrossMultiplayerBossLayer:changeLayerByStatus()
  if self.builders then
    for k,v in pairs(self.builders) do
      v:removeFromParentAndCleanup(true)
      v = nil
    end
    self.cardParticle = nil
  end

  if self.heroAtlas and self.heroAtlas.refCocosObj then
  	self.heroAtlas.refCocosObj:removeFromParentAndCleanup(true)
  	self.heroAtlas = nil
  end
  if self.inspireAtlas and self.inspireAtlas.refCocosObj then
  	self.inspireAtlas.refCocosObj:removeFromParentAndCleanup(true)
  	-- self.inspireAtlas:removeFromParentAndCleanup(true)
  	self.inspireAtlas = nil
  end

  if self.updateTriggerFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTriggerFunc )
    self.updateTriggerFunc = nil
  end

  if self.onCrossDayUpdateFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.onCrossDayUpdateFunc )
    self.onCrossDayUpdateFunc = nil
  end

  if self.cdLabelComponent then
    self.cdLabelComponent:stop()
  end

  if g_homeInfo and g_homeInfo.crossBossEnablePhase then
  	  if self.extraArgs and self.extraArgs.phaseType then
		  g_homeInfo.crossBossEnablePhase = self.extraArgs.phaseType
		end
	end
	if g_homeInfo then
		if self.extraArgs.phaseType == 2 then
			if self.extraArgs and self.extraArgs.rewardPhase then
				g_homeInfo.crossBossReward = self.extraArgs.rewardPhase.canReward
			end
		end
	end

  self.curretnStage = self.extraArgs.phaseType

  if DataManager.getCurrUser().level < CrossWorldBossManager.getCrossBossSettingConfig().unlockLevel then
  	self:initLVNotEnough()
  	return
  end
  
  if self.extraArgs.phaseType == 0 then
    self:initPrepare()
  elseif self.extraArgs.phaseType == 1 then
    self:initBattle()
  elseif self.extraArgs.phaseType == 2 then
    self:initResult()
  end

  self.container:resetTipInfoForActivity("Activity_CrossBoss")

  local endTime = CrossWorldBossManager.getEndTimeByCurrentStage( self.curretnStage , self.version)

  self:cdFuncByEndTime(endTime)
end

function Activity_CrossMultiplayerBossLayer:cdFuncByEndTime(endTime)
  local function onTimeComplete()
    self:getCrossBossInfo()
  end

  if self.cdLabelComponent then
    self.cdLabelComponent:stop()
  end
  self.cdLabelComponent = CdLabelComponent:create()
  if self.curretnStage == 0 then
  	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		-- print(formatedTimeStr)
		self.cdTxt:setString(formatedTimeStr)--{num1}:{num2}:{num3}后可加入军团
	end
  	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)
  else
  	self.cdLabelComponent:setCallback(nil, onTimeComplete)
  end

  self.cdLabelComponent:setTargetTime(endTime + 5)--往后偏移5秒，防止前端刷新了，后端还没刷新
  self.cdLabelComponent:start()
end

function Activity_CrossMultiplayerBossLayer:initLVNotEnough()
	local siRenBg = self.builder:build("Siren_1")
	self:addChild(siRenBg)
	table.insert(self.builders , siRenBg)
	local godWillAll = self.builder:build("Part_Siren1_godWill")
	self:addChild(godWillAll)
	table.insert(self.builders , godWillAll)
	local combination = self.builder:build("event_form_combination_Siren")
	self:addChild(combination)
	table.insert(self.builders , combination)

	
 	siRenBg:getChildByName("full"):setVisible(false)

	local witch = CrossWorldBossManager.getWitchByType( 1 )
	local witchMeta = witch.cardMetaId
	self.witchBG = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(witchMeta))
	self.witchBG:setAnchorPoint(siRenBg:getChildByName("full"):getAnchorPoint())
	self.witchBG:setScale(1.36)
	self.witchBG:setPosition(ccp(siRenBg:getChildByName("full"):getPositionX() , siRenBg:getChildByName("full"):getPositionY()))
	siRenBg:addChild(self.witchBG)

	local godHeros

	if self.curretnStage == 0 or self.curretnStage == 1 then
		godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version)
	else
		godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version + 1)
	end

  
  for i=1,#godHeros do
    local godWill = godWillAll:getChildByName("normal_card_small_name_godWill"..i)
    local sourceDisplay = godWill:getChildByName("normal_card_small")
    local heroIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, godHeros[i].metaId, 1, {sourceDisplay = sourceDisplay , showInCenter = true})
    local heroName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, godHeros[i].metaId, 0, {withoutAmount  = true})
    godWill:getChildByName("txt_Siren_34"):getChildByName("txt"):setString(heroName)
    godWill:addChildAt(heroIcon,1)
    if not godHeros[i].isActive then
      local backLayer = LayerColor:create()
      backLayer:setColor(ccc3( 10, 10, 10 ))
      backLayer.blackLayerColor = ccc3( 0, 0, 0 )
      backLayer.originalColor = ccc3( 10, 10, 10 )
      backLayer.refCocosObj:setOpacity( 200 )
      local length = 134
      backLayer:setContentSize(CCSizeMake( length, length ))
      backLayer:setPosition(ccp(-length / 2, -length / 2))
      heroIcon:addChild(backLayer)
    end
    if self.curretnStage == 0 or self.curretnStage == 1 then
    	if (self.version%4) + 1 == i then
	    	self:addParticle(heroIcon)
	    end
    else
    	if ((self.version + 1)%4) + 1 == i then
	    	self:addParticle(heroIcon)
	    end
    end
    
    godWill:getChildByName("normal_card_small"):removeFromParentAndCleanup(true)
    local function onClickHeroIcon( evt )
      CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, godHeros[evt.context].metaId)
    end
    local btn = Button:create(heroIcon)
    btn:addEventListener( Events.kStart, onClickHeroIcon, i )
  end

  godWillAll:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroBuff"))
  godWillAll:getChildByName("txt_7"):getChildByName("txt"):setString(CrossWorldBossManager.getGodHerosIncreaseValue(self.version).."%")
  godWillAll:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("crossBoss_currHero"))
  if self.curretnStage == 2 then
  	godWillAll:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("crossBoss_nextHero"))
  end
  -- godWillAll:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("crossBoss_beginCountdown"))
  self.cdTxt = godWillAll:getChildByName("txt_1"):getChildByName("txt")


  local function onClickReview( evt )
    self.container:setTableViewsEnabled(false)
  	local aInfoPanel = CrossMultiplayerRankRewardInfoPanel:create(self.container,self.version)
  	self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local rewardReviewBtn = Button:create(combination:getChildByName("icon_Rankings_reward"))
  rewardReviewBtn:addEventListener( Events.kStart, onClickReview )




  local function onClickInfo( evt )
  	local normalHeros = CrossWorldBossManager.getNormalHeros( self.version )
  	local specialHero = CrossWorldBossManager.getSpecialHero( self.version )
  	local text2 = CanonGoodIcon.getGoodName(ResourceEnum.CARD, specialHero.metaId, 0, {withoutAmount  = true})
  	local text3 = ""
  	for k,v in pairs(normalHeros) do
  		text3 = text3 .. CanonGoodIcon.getGoodName(ResourceEnum.CARD, v.metaId, 0, {withoutAmount  = true}) .. " "
  	end

  	local witch = CrossWorldBossManager.getWitchByType( 1 )
  	local witchMeta = witch.cardMetaId

  	local godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version)
  	local time1 = CrossWorldBossManager.getBattleBeginTimeTxt(self.version)
  	local time2 = CrossWorldBossManager.getBattleEndTimeTxt( self.version )
  	local time3 = CrossWorldBossManager.getRewardEndTimeTxt( self.version )
  	local content1 = Localization:getInstance():getText("crossBoss_explainInfo_1" , {time1 = time1 , time2 = time2 , time3 = time3 , text1 = "s" , text2 =text2 , text3 = text3})
    local content2 = Localization:getInstance():getText("crossBoss_explainInfo_2")
    local content3 = Localization:getInstance():getText("crossBoss_explainInfo_3")
    local content4 = Localization:getInstance():getText("crossBoss_explainInfo_4")
  	local aInfoPanel = CrossBossInfoPanel:create(self.container, {content1 = content1, content2 = content2,content3 = content3, content4 = content4, cardIdList = {godHeros[1].metaId,
godHeros[2].metaId,
godHeros[3].metaId,
godHeros[4].metaId,},cardIdList2 = {witchMeta}} , self.version)
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end

  -- local rewardReviewBtn = Button:create(combination:getChildByName("sky_btn_qa"))
  -- rewardReviewBtn:addEventListener( Events.kStart, onClickInfo )

  combination:getChildByName("sky_btn_qa"):setVisible(false)
  combination:getChildByName("txt_06"):setVisible(true)
  combination:getChildByName("txt_06"):getChildByName("txt"):setString(getTextByKey("crossBoss_levelTips", {num1 = CrossWorldBossManager.getCrossBossSettingConfig().unlockLevel}))
  -- local serverIds = self.extraArgs.preparePhase.serverIds
end

function Activity_CrossMultiplayerBossLayer:addParticle(cardCell)
  if self.cardParticle ~= nil then
    self.cardParticle:removeFromParentAndCleanup(true)
  end
  self.cardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
  self.cardParticle:setPositionType(kCCPositionTypeRelative)
  self.cardParticle:setPosition(ccp(-67,67))
  cardCell:addChild(CocosObject.new(self.cardParticle), 1000)
  local particleMoveArray = CCArray:create()
  local particleMoveTime = 0.4
  particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(134, 0)))
  particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -134)))
  particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-134, 0)))
  particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 134)))
  self.cardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
end

function Activity_CrossMultiplayerBossLayer:initPrepare()
	local siRenBg = self.builder:build("Siren_1")
	self:addChild(siRenBg)
	table.insert(self.builders , siRenBg)
	local godWillAll = self.builder:build("Part_Siren1_godWill")
	self:addChild(godWillAll)
	table.insert(self.builders , godWillAll)
	local combination = self.builder:build("event_form_combination_Siren")
	self:addChild(combination)
	table.insert(self.builders , combination)

 	siRenBg:getChildByName("full"):setVisible(false)

	local witch = CrossWorldBossManager.getWitchByType( 1 )
	local witchMeta = witch.cardMetaId
	self.witchBG = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(witchMeta))
	self.witchBG:setAnchorPoint(siRenBg:getChildByName("full"):getAnchorPoint())
	self.witchBG:setScale(1.36)
	self.witchBG:setPosition(ccp(siRenBg:getChildByName("full"):getPositionX() , siRenBg:getChildByName("full"):getPositionY()))
	siRenBg:addChild(self.witchBG)

	local serverIds = self.extraArgs.preparePhase.serverIds
	local serverTxt = ""
	for k,v in pairs(serverIds) do
		serverTxt = serverTxt.. tostring(v)..getTextByKey("crossBoss_serverSuffix")
		if k ~= #serverIds then
			serverTxt = serverTxt.."、"
		end
	end

	combination:getChildByName("txt_06"):getChildByName("txt"):setString(getTextByKey("crossBoss_serverGroup")..serverTxt)

  local godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version)
  for i=1,#godHeros do
    local godWill = godWillAll:getChildByName("normal_card_small_name_godWill"..i)
    local sourceDisplay = godWill:getChildByName("normal_card_small")
    local heroIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, godHeros[i].metaId, 1, {sourceDisplay = sourceDisplay , showInCenter = true})
    local heroName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, godHeros[i].metaId, 0, {withoutAmount  = true})
    godWill:getChildByName("txt_Siren_34"):getChildByName("txt"):setString(heroName)
    godWill:addChildAt(heroIcon,1)
    if not godHeros[i].isActive then
      local backLayer = LayerColor:create()
      backLayer:setColor(ccc3( 10, 10, 10 ))
      backLayer.blackLayerColor = ccc3( 0, 0, 0 )
      backLayer.originalColor = ccc3( 10, 10, 10 )
      backLayer.refCocosObj:setOpacity( 200 )
      local length = 134
      backLayer:setContentSize(CCSizeMake( length, length ))
      backLayer:setPosition(ccp(-length / 2, -length / 2))
      heroIcon:addChild(backLayer)
    end
    if (self.version%4) + 1 == i then
    	self:addParticle(heroIcon)
    end
    godWill:getChildByName("normal_card_small"):removeFromParentAndCleanup(true)
    local function onClickHeroIcon( evt )
      CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, godHeros[evt.context].metaId)
    end
    local btn = Button:create(heroIcon)
    btn:addEventListener( Events.kStart, onClickHeroIcon, i )
  end

  godWillAll:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroBuff"))
  godWillAll:getChildByName("txt_7"):getChildByName("txt"):setString(CrossWorldBossManager.getGodHerosIncreaseValue(self.version).."%")
  godWillAll:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("crossBoss_currHero"))
  godWillAll:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("crossBoss_beginCountdown"))
  self.cdTxt = godWillAll:getChildByName("txt_1"):getChildByName("txt")


  local function onClickReview( evt )
    self.container:setTableViewsEnabled(false)
  	local aInfoPanel = CrossMultiplayerRankRewardInfoPanel:create(self.container,self.version)
  	self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local rewardReviewBtn = Button:create(combination:getChildByName("icon_Rankings_reward"))
  rewardReviewBtn:addEventListener( Events.kStart, onClickReview )

  local function onClickInfo( evt )
  	local normalHeros = CrossWorldBossManager.getNormalHeros( self.version )
  	local specialHero = CrossWorldBossManager.getSpecialHero( self.version )
  	local text2 = CanonGoodIcon.getGoodName(ResourceEnum.CARD, specialHero.metaId, 0, {withoutAmount  = true})
  	local text3 = ""
  	for k,v in pairs(normalHeros) do
  		text3 = text3 .. CanonGoodIcon.getGoodName(ResourceEnum.CARD, v.metaId, 0, {withoutAmount  = true}) .. " "
  	end

  	local witch = CrossWorldBossManager.getWitchByType( 1 )
  	local witchMeta = witch.cardMetaId

  	local godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version)
  	local time1 = CrossWorldBossManager.getPrepareEndTimeTxt(self.version)
  	local time2 = CrossWorldBossManager.getBattleEndTimeTxt( self.version )
  	local time3 = CrossWorldBossManager.getRewardEndTimeTxt( self.version )
  	local content1 = Localization:getInstance():getText("crossBoss_explainInfo_1" , {time1 = time1 , time2 = time2 , time3 = time3 , text1 = serverTxt , text2 =text3 , text3 = text2})
    local content2 = Localization:getInstance():getText("crossBoss_explainInfo_2")
    local content3 = Localization:getInstance():getText("crossBoss_explainInfo_3")
    local content4 = Localization:getInstance():getText("crossBoss_explainInfo_4")
  	local aInfoPanel = CrossBossInfoPanel:create(self.container, {content1 = content1, content2 = content2,content3 = content3, content4 = content4, cardIdList = {godHeros[1].metaId,
godHeros[2].metaId,
godHeros[3].metaId,
godHeros[4].metaId,},cardIdList2 = {witchMeta}} , self.version)
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end

  local rewardReviewBtn = Button:create(combination:getChildByName("sky_btn_qa"))
  rewardReviewBtn:addEventListener( Events.kStart, onClickInfo )


  -- local serverIds = self.extraArgs.preparePhase.serverIds
end

local onFlashEvent = nil;

-- local damageBG = nil
local attNum = 0
local attName = ""
local serverSuffix = 0

onFlashEvent =  function(eventName)
  --print(eventName)
  if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
  if eventName == "attack" then

    -- attNumSprite = createNumberEffect(attNum , 350,500 , NumberColorEnum.critical, false, 4, true, 2, false, true)
    -- local selfNameLabel = CCLabelTTF:create("丁元带着绿帽子", "AAA", 45)
    -- selfNameLabel:setPosition(ccp(350,550))
    -- SELF:addChild(CocosObject.new(selfNameLabel))

    -- SELF:addChild(attNumSprite)
    SELF:changeBossHP()

    local damageBG = SELF.builder:build("playername_damage")
    local attNumSprite = CCLabelAtlas:create(tostring(attNum), "battle/pic/number_Critcal.png", 25, 41, 46)
    attNumSprite:setScale(1.5)
	attNumSprite:setPosition( ccp(damageBG:getChildByName("icon_gold"):getPositionX(), damageBG:getChildByName("icon_gold"):getPositionY()) )
	attNumSprite:setAnchorPoint( ccp(0.5, 0.5) )
	damageBG:addChild(CocosObject.new(attNumSprite))
	damageBG:getChildByName("icon_gold"):setVisible(false)
	damageBG:setPosition(ccp(190,550))
	damageBG:getChildByName("txt"):getChildByName("txt"):setString(attName)
	damageBG:getChildByName("txt_Siren_04"):getChildByName("txt"):setString(getTextByKey("crossBoss_serverSuffix"))
	damageBG:getChildByName("txt_Siren_03"):getChildByName("txt"):setString(serverSuffix)

	local function AnimEnd()
		damageBG:removeFromParentAndCleanup(true)
	end

	local animArray = CCArray:create()
	animArray:addObject(CCScaleTo:create(0.2, 1))
	animArray:addObject(CCFadeOut:create(0.5))
	animArray:addObject(CCCallFunc:create(AnimEnd))
	local anim = CCSequence:create(animArray)
	damageBG:runAction(anim)
	damageBG:runAction(CCFadeIn:create(0.2))

	SELF:addChild(damageBG)

  end
end

function Activity_CrossMultiplayerBossLayer:refreshBattle()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
  local ranks = self:getRank()

  if self.challengeInfo == nil then
  	return
  end

  for i=1,#ranks do
    local integral = self.challengeInfo:getChildByName("txt_integral"..i)
    -- for j=1,3 do
    --   if i == j then
    --     integral:getChildByName("icon_paiming"..j):setVisible(true)
    --   else
    --     integral:getChildByName("icon_paiming"..j):setVisible(false)
    --   end
    -- end
    integral:getChildByName("txt_Siren_03"):getChildByName("txt"):setString(ranks[i].serverId)
    integral:getChildByName("txt_Siren_05"):getChildByName("txt"):setString(ranks[i].nickName)
    integral:getChildByName("txt_Siren_07"):getChildByName("txt"):setString(ranks[i].score)
    integral:getChildByName("txt_Siren_04"):getChildByName("txt"):setString(getTextByKey("crossBoss_serverSuffix"))
    integral:getChildByName("txt_Siren_06"):getChildByName("txt"):setString(getTextByKey("pk_session_points"))
  end


end

function Activity_CrossMultiplayerBossLayer:refreshCrossBossBattlePhase()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
  if self.combos and #self.combos > 0 then
    return 
  end
  if self.challengeInfo == nil then
  	return
  end
  local function successCallback(data)
    if tonumber(data.data.miniInfo.hp) <= 0 then
      self:getCrossBossInfo()
    else
      self.battlePhaseMini = data.data.miniInfo
      self.combos = self.battlePhaseMini.combos
      self:playOtherPlayerFlash()
      self:refreshBattle()
    end
  end

  local function failureCallback(data)
    
  end
  RefreshCrossBossBattlePhaseRequest.sendRequest({} ,successCallback , failureCallback)
end

function Activity_CrossMultiplayerBossLayer:getCrossBossInfo()
    local function successCallback(data)
      self.extraArgs = data.data
      self.version = self.extraArgs.crossVersion
      self:changeLayerByStatus()
      -- local crossBossBattlePhase = self.extraArgs.battlePhase
      -- self.battlePhaseMini = crossBossBattlePhase.battlePhaseMini
      -- self.combos = self.battlePhaseMini.combos
    end

    local function failureCallback(data)
      
    end
  GetCrossBossInfoRequest.sendRequest( {} ,successCallback , failureCallback)
end

function Activity_CrossMultiplayerBossLayer:refreshChallengeBtn()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
	if self.challengeInfo == nil then
		return
	end
  self.challengeType = 0

  local cost , times = CrossWorldBossManager.getChallengeCostAndTimes()
  if cost == 0 then
    self.challengeType = 0
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("icon_gold"):setVisible(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_01"):setVisible(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_02"):setVisible(true)

  else
    self.challengeType = 1
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("icon_gold"):setVisible(true)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_01"):setVisible(true)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_02"):setVisible(false)
  end

  self.cost = cost

  if self.cost > 0 then
  	self.challengeInfo:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossBoss_extraBattleTimes")..":"..times)
  else
  	self.challengeInfo:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossBoss_freeBattleTimes")..":"..times)
  end
  
  self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_01"):getChildByName("txt"):setString(self.cost.." "..getTextByKey("crossBoss_textBattle"))
  self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("arena_challengeBtn"))

  if times == 0 then
    self.challengeBtn:setEnable(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("icon_gold"):setVisible(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_01"):setVisible(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_02"):setVisible(true)
    self.challengeInfo:getChildByName("txt_1"):getChildByName("txt"):setVisible(false)
    self.challengeInfo:getChildByName("btn_green_go_01"):getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("crossBoss_finishBattle"))
  end
end

function Activity_CrossMultiplayerBossLayer:updateShowBattleState()
	
end

function Activity_CrossMultiplayerBossLayer:refreshHeroBtn()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
	if self.challengeInfo == nil then
		return
	end
	if self.heroAtlas ~= nil and self.heroAtlas.refCocosObj then
		self.heroAtlas.refCocosObj:removeFromParentAndCleanup(true)
		self.heroAtlas = nil
	end
	local heroIncrease = CrossWorldBossManager.getGodHerosIncreaseValue(self.version)
	local heroAtlas = CCLabelAtlas:create(tostring(heroIncrease), "number/goldNum.png", 19.2, 23, 48)
	heroAtlas:setPosition(ccp(self.heroView:getChildByName("icon_gold"):getPositionX() , self.heroView:getChildByName("icon_gold"):getPositionY()))	
	heroAtlas:setAnchorPoint(ccp(0.5,0.5))
	self.heroAtlas = CocosObject.new(heroAtlas)
	self.heroView:addChild(self.heroAtlas)
	self.heroView:getChildByName("icon_gold"):setVisible(false)
end

function Activity_CrossMultiplayerBossLayer:refreshInspireBtn()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
	if self.challengeInfo == nil then
		return
	end
	if self.inspireAtlas ~= nil and self.inspireAtlas.refCocosObj then
		self.inspireAtlas.refCocosObj:removeFromParentAndCleanup(true)
		self.inspireAtlas = nil
	end
	local heroIncrease = CrossWorldBossManager.getInsprieValue()
	local inspireAtlas = CCLabelAtlas:create(tostring(heroIncrease), "number/silverNum.png", 19.2, 23, 48)
	inspireAtlas:setPosition(ccp(self.inspire:getChildByName("icon_gold"):getPositionX() , self.inspire:getChildByName("icon_gold"):getPositionY()))	
	inspireAtlas:setAnchorPoint(ccp(0.5,0.5))
	self.inspireAtlas = CocosObject.new(inspireAtlas)
	self.inspire:addChild(CocosObject.new(inspireAtlas))
	self.inspire:getChildByName("icon_gold"):setVisible(false)
end

function Activity_CrossMultiplayerBossLayer:initBattle()
  -- self.witchBG:setVisible(false)
  local crossBossBattlePhase = self.extraArgs.battlePhase
  CrossWorldBossManager.setInsprieValue(crossBossBattlePhase.inspireAddition)
  self.battlePhaseMini = crossBossBattlePhase.battlePhaseMini
  self.combos = self.battlePhaseMini.combos
  self.bossType = crossBossBattlePhase.bossType
  self.maxHp = crossBossBattlePhase.maxHp
  --test
  local witch = CrossWorldBossManager.getWitchByType( self.bossType )
  local witchMeta = witch.cardMetaId
  local scoreCoef = witch.scoreCoef
  local bg = self.builder:build("Siren_1")
  self:addChild(bg)
  table.insert(self.builders , bg)
  bg:getChildByName("full"):setVisible(false)
  self.witchSprite = getFullCardSpriteFrame(witchMeta)
  -- self.witchSprite:setPosition(ccp(bg:getChildByName("full"):getPositionX() , bg:getChildByName("full"):getPositionY()))
  -- bg:addChild(self.witchSprite)

  --boss
  local fspt = FlashSprite:create("EVO2/crossBoss")
  fspt:addChangeInstance("bossM", self.witchSprite)
  fspt:changeAnimation(3)
  fspt:setLoop(false)
  -- local full = self.bg:getChildByName("full")
  -- fspt:setPosition(full:getPositionX(), full:getPositionY())
  local fspt_co = CocosObject.new(fspt)
  local function onCloudFlashAnimationEnd(anim)
    -- fspt:unregisterEndAnimationScriptHandler()
    -- self:removeChild(fspt_co)
    --Set_ShareData( "Cloud_Finished", 1 )
    -- self.fspt = nil;
    self:playOtherPlayerFlash()
    -- self.fspt:changeAnimation(math.random(3) - 1)

    if self.isBossKilled then
      local function successCallback(data)
        self.extraArgs = data.data
        self:changeLayerByStatus()
        -- local crossBossBattlePhase = self.extraArgs.battlePhase
        -- self.battlePhaseMini = crossBossBattlePhase.battlePhaseMini
        -- self.combos = self.battlePhaseMini.combos
      end

      local function failureCallback(data)
        
      end
    GetCrossBossInfoRequest.sendRequest( {} ,successCallback , failureCallback)
    end
  end
  self.fspt = fspt
  fspt:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
  self.fspt:registerFlashScriptHandler(onFlashEvent)
  self.fspt:addFrameEvent("attack", 0, 26)
  self.fspt:addFrameEvent("attack", 1, 26)
  self.fspt:addFrameEvent("attack", 2, 26)
  self.fspt:setVisible(false)
  bg:addChild(fspt_co)

  local challengeInfo = self.builder:build("Part_Siren1_challenge")
  self.challengeInfo = challengeInfo
  self:addChild(challengeInfo)
  table.insert(self.builders , challengeInfo)
  local ranks = self:getRank()

  for i=1,3 do
	  	local integral = challengeInfo:getChildByName("txt_integral"..i)
	    for j=1,3 do
	      if i == j then
	        integral:getChildByName("icon_paiming"..j):setVisible(true)
	      else
	        integral:getChildByName("icon_paiming"..j):setVisible(false)
	      end
	    end
	end

  for i=1,#ranks do
    local integral = challengeInfo:getChildByName("txt_integral"..i)
    integral:getChildByName("txt_Siren_03"):getChildByName("txt"):setString(ranks[i].serverId)
    integral:getChildByName("txt_Siren_03"):getChildByName("txt"):setColor(ccc3(51, 255, 255))
    integral:getChildByName("txt_Siren_03"):getChildByName("txt"):setAroundColor(ccc3(71, 15, 15))

    integral:getChildByName("txt_Siren_05"):getChildByName("txt"):setString(ranks[i].nickName)
    integral:getChildByName("txt_Siren_05"):getChildByName("txt"):setColor(ccc3(255, 255, 51))
    integral:getChildByName("txt_Siren_05"):getChildByName("txt"):setAroundColor(ccc3(71, 15, 15))

    integral:getChildByName("txt_Siren_07"):getChildByName("txt"):setString(ranks[i].score)
    integral:getChildByName("txt_Siren_07"):getChildByName("txt"):setColor(ccc3(22, 229, 0))
    integral:getChildByName("txt_Siren_07"):getChildByName("txt"):setAroundColor(ccc3(71, 15, 15))

    integral:getChildByName("txt_Siren_04"):getChildByName("txt"):setString(getTextByKey("crossBoss_serverSuffix"))
    integral:getChildByName("txt_Siren_04"):getChildByName("txt"):setColor(ccc3(255, 255, 51))
    integral:getChildByName("txt_Siren_04"):getChildByName("txt"):setAroundColor(ccc3(71, 15, 15))

    integral:getChildByName("txt_Siren_06"):getChildByName("txt"):setString(getTextByKey("pk_session_points"))
    integral:getChildByName("txt_Siren_06"):getChildByName("txt"):setColor(ccc3(255, 255, 51))
    integral:getChildByName("txt_Siren_06"):getChildByName("txt"):setAroundColor(ccc3(71, 15, 15))

  end

  challengeInfo:getChildByName("txt_Siren_07"):getChildByName("txt"):setString(crossBossBattlePhase.score)
  local rankTxt = ""
  if crossBossBattlePhase.rank > CrossWorldBossManager.getCrossBossSettingConfig().rankingCalcNum or crossBossBattlePhase.rank == 0 then
  	rankTxt = CrossWorldBossManager.getCrossBossSettingConfig().rankingCalcNum..getTextByKey("crossBoss_myRankSuffix")
  else
  	rankTxt = crossBossBattlePhase.rank
  end
  challengeInfo:getChildByName("txt_Siren_09"):getChildByName("txt"):setString(rankTxt)
  challengeInfo:getChildByName("txt_Siren_08"):getChildByName("txt"):setString(getTextByKey("crossBoss_myRank"))
  challengeInfo:getChildByName("txt_Siren_13"):getChildByName("txt"):setString(getTextByKey("crossBoss_myScore"))

  challengeInfo:getChildByName("txt_Siren_12"):getChildByName("txt"):setString(getTextByKey("crossBoss_scoreCoef")..":"..witch.scoreCoef)

  if self.bossType == 1 then
  	challengeInfo:getChildByName("txt_Siren_12"):getChildByName("txt"):setVisible(false)
  else
  	local initScore = CrossWorldBossManager.getWitchByType( 1 ).scoreCoef

  	local finalScore = math.modf(((witch.scoreCoef - initScore) / initScore) * 100)
  	challengeInfo:getChildByName("txt_Siren_12"):getChildByName("txt"):setVisible(true)
  	challengeInfo:getChildByName("txt_Siren_12"):getChildByName("txt"):setString(getTextByKey("crossBoss_scoreCoef")..":"..finalScore .. "%")
  end

  self.hpBar = ProgressBar:create(challengeInfo:getChildByName("xue"))
  self.bossCurrentHP = self:getBossCurrentHp()
  self.hpBar:setPercentage((self.bossCurrentHP / self.maxHp) * 100)
  self.hpTxt = challengeInfo:getChildByName("txt_xueliang"):getChildByName("txt")
  self.hpTxt:setString(self.bossCurrentHP.."/"..self.maxHp)

  challengeInfo:getChildByName("halfblack3_l"):setVisible(false)
  challengeInfo:getChildByName("halfblack3_r"):setVisible(false)

  
  challengeInfo:getChildByName("txt_Siren_10"):getChildByName("txt"):setString(getTextByKey("crossBoss_battleTime"))
  local battleTimeTxt = CrossWorldBossManager.getPrepareEndTimeTxt( self.version ).."——"..CrossWorldBossManager.getBattleEndTimeTxt( self.version )
  challengeInfo:getChildByName("txt_Siren_11"):getChildByName("txt"):setString(battleTimeTxt)

  local function onChallenge(evt)
  	local nowGems = CalculationManager.calcComplex_getGemsNow()
  	if nowGems < self.cost then
  		local function onReplaceScene()
            -- self.container:setTableViewsEnabled(true)
            -- self.container.targetInfoPanel = nil
            -- PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end
		local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
		self.container:addChild(aPanel)
		aPanel:scaleIn()
  		return
  	end
    local function successCallback(data)
      local crossTimes = DailyDataManager.getCrossBossTimes()
      DailyDataManager.setCrossBossTimes(crossTimes + 1)
      if self.challengeType == 1 then
        --扣除金币
        RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.cost}})
      end
      data.data.type = self.bossType
      data.data.bossHpMax = self.maxHp
      Director:sharedDirector():replaceScene(BattleScene:create(data.data, BattleBackType.kActivityCrossBoss, BattleEnterEnum.kActivityCrossBoss))
    end

    local function failureCallback(data)
      if data.retCode == 716941 then
      	self:getCrossBossInfo()
      elseif data.retCode == 716953 then
     --  	local aContent = "免费次数还没用完"
    	-- SuspensionLabel:showContent(Director:mgr():run(), aContent)
      	self:getCrossBossInfo()
  	  elseif data.retCode == 716955 then
  	  	local aContent = getTextByKey("crossBoss_errorCodeBattleEnd")
  	  	SuspensionLabel:showContent(Director:mgr():run(), aContent)
  	  	self:getCrossBossInfo()
  	  else
  	  	self:getCrossBossInfo()
      end
    end
    local param = {type = self.challengeType , bossType = self.bossType}
    ChallengeCrossBossRequest.sendRequest(param , successCallback , failureCallback)
  end

  self.challengeBtn = Button:create(challengeInfo:getChildByName("btn_green_go_01") , true)
  self.challengeBtn:addEventListener( Events.kStart,onChallenge ,self)

  local function onInspire(evt)
	if CrossWorldBossManager.getInsprieValue() >= CrossWorldBossManager.getCrossBossSettingConfig().inspireLimit then
		SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
	else
		self.targetInspirePanel = CrossBossInspirePanel:create( self )
		PopoutManager:sharedManager():popout(self.targetInspirePanel, kPopoutDir.kScale, true, false ,self.container) 
	end
  end

  self.inspire = challengeInfo:getChildByName("btn_encouraging_2")
  local inspireBtn = Button:create(challengeInfo:getChildByName("btn_encouraging_2"))
  inspireBtn:addEventListener( Events.kStart,onInspire ,self)

  local function onHeroView(evt)
	local targetInspirePanel = HeroViewPanel:create( self )
	PopoutManager:sharedManager():popout(targetInspirePanel, kPopoutDir.kScale, true, false ,self.container) 
  end

  self.heroView = challengeInfo:getChildByName("btn_encouraging_1")
  local inspireBtn = Button:create(challengeInfo:getChildByName("btn_encouraging_1"))
  inspireBtn:addEventListener( Events.kStart,onHeroView ,self)

  if self.battlePhaseMini.wake == false then
    if self.bossType == 2 or self.bossType == 3 then
      --boss觉醒就清空挑战次数
      DailyDataManager.setCrossBossTimes(0)
    end
  end

  self:refreshChallengeBtn()
  self:refreshHeroBtn()
  self:refreshInspireBtn()


  if self.battlePhaseMini.wake == false then
    if self.bossType == 3 then
      self:showWitchCrazyFlash()
    elseif self.bossType == 2 then
      self:showWitchWakeFlash()
    else
      self.fspt:setVisible(true)
      self:playOtherPlayerFlash()
    end
  else
    self.fspt:setVisible(true)
    self:playOtherPlayerFlash()
  end

  local function updateTriggerFightAnim()
    self:refreshCrossBossBattlePhase()
  end

  self.updateTriggerFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateTriggerFightAnim, CrossWorldBossManager.getCrossBossSettingConfig().battleReportSleepTime, false )

      --定期更新时间
  local function timeTick(ee)
    --print("定期更新时间: " .. self.currentTime)
     -- print("定期更新时间2: " .. TimeUtil.getServerTimeSeconds())
    -- print("标准时间:"..TimeUtil.formatTime(TimeUtil.getServerTimeSeconds()))
    local b = TimeUtil.whetherSwitchDay(self.currentTime)

    if b then
      self.currentTime = TimeUtil.getServerTimeSeconds()
      self:getCrossBossInfo()
    end
  end

  self.currentTime = TimeUtil.getServerTimeSeconds()
  self.onCrossDayUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(timeTick,15,false);

  


  local function onClickRanks( evt )
  	local function successCallback(data)
      local rankInfoPanel = CrossBossRankInfoPanel:create(self, {ranks = data.data.ranks})
	  PopoutManager:sharedManager():popout(rankInfoPanel, kPopoutDir.kScale, true, false, self.container)
      end

    local function failureCallback(data)
      
    end
  	GetCrossBossRankInfoRequest.sendRequest(nil , successCallback,failureCallback)
  end

  local rankBtn = Button:create(challengeInfo:getChildByName("icon_integra"))
  rankBtn:addEventListener( Events.kStart,onClickRanks ,self)

  local function onClickReview( evt )
    self.container:setTableViewsEnabled(false)
  	local aInfoPanel = CrossMultiplayerRankRewardInfoPanel:create(self.container,self.version)
  	self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local rewardReviewBtn = Button:create(challengeInfo:getChildByName("icon_Rankings_reward"))
  rewardReviewBtn:addEventListener( Events.kStart, onClickReview )
  
end

function Activity_CrossMultiplayerBossLayer:changeBossHP()
	if CrossWorldBossManager.getIsInCrossBossLayer() == false then
		return
	end
  self.bossCurrentHP = self.bossCurrentHP - self.curCombo.hurt
  if self.hpTxt.refCocosObj then
  	self.hpTxt:setString(self.bossCurrentHP.."/"..self.maxHp)
  end
  
  self.hpBar:setPercentage((self.bossCurrentHP / self.maxHp) * 100)
  if self.bossCurrentHP <= 0 then
    self.isBossKilled = true
  end
end

function Activity_CrossMultiplayerBossLayer:playOtherPlayerFlash()
  if self.combos and #self.combos > 0 then
    self.curCombo = table.remove(self.combos , 1)
    attNum = self.curCombo.hurt
    attName = self.curCombo.nickName
    serverSuffix = self.curCombo.uid % 10000
    self:changeFlashCard(self.curCombo.metaId)
    self.fspt:changeAnimation(math.random(3) - 1)
    return true
  end
  return false
end

function Activity_CrossMultiplayerBossLayer:changeFlashCard(metaId)
  local cardMeta = MetaManager.card_meta[tonumber(metaId)]
  local cardSpf = getCardSpriteFrame(metaId)
  local cardBoardSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[cardMeta.rare])
  local cardBgSpf = getCardBackGroundSpriteFrameByMeta(cardMeta)
  local cardBallSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryIcon_" .. cardMeta.country .. ".png")
  local cardBallbgSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. cardMeta.country .. ".png")
  self.fspt:addChangeInstance("card2M", cardSpf)
  self.fspt:addChangeInstance("cardBg2M", cardBgSpf)
  self.fspt:addChangeInstance("cardBorder2M", cardBoardSpf)
  self.fspt:addChangeInstance("card2Mball", cardBallSpf)
  self.fspt:addChangeInstance("card2Mballbg", cardBallbgSpf)
end

function Activity_CrossMultiplayerBossLayer:getBossStatus()
  local crossBossRewardPhase = self.extraArgs.rewardPhase
  local bossStatus = crossBossRewardPhase.bossStatus
  local isKill = math.modf(bossStatus / 10)
  local bossType = bossStatus - isKill*10
  return isKill , bossType
end

function Activity_CrossMultiplayerBossLayer:initResult()
  -- if self.updateTriggerFunc then
  --   CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTriggerFunc )
  -- end
  -- self.witchBG:setVisible(false)
  local crossBossRewardPhase = self.extraArgs.rewardPhase
  local isKill , bossType = self:getBossStatus()

  local endUI = self.builder:build("Siren_end")
  self:addChild(endUI)
  table.insert(self.builders , endUI)
  local witchType
    if bossType == 1 then
      witchType = getTextByKey("crossBoss_normalBoss")
    elseif bossType == 2 then
      witchType = getTextByKey("crossBoss_awakenBoss")
    elseif bossType == 3 then
      witchType = getTextByKey("crossBoss_rampageBoss")
    end
  -- if isKill == 1 then--现在是所有情况都显示排名
    -- local endUI = self.builder:build("Siren_end")
    -- self:addChild(endUI)
    -- table.insert(self.builders , endUI)

    endUI:getChildByName("txt_Siren_20"):getChildByName("txt"):setString(getTextByKey("crossBoss_finalScoreRank"))

    -- for  k, v in pairs(crossBossRewardPhase.ranks) do
    --   local item = self.builder:build("list/Srien_rank_list")
      -- item:getChildByName("txt_boss_di"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt1"))
      -- if k < 10 then
      --   local pos = item:getChildByName("txt_boss_rankfont"):getPosition()
      --   item:getChildByName("txt_boss_rankfont"):setPosition( ccp( pos.x + 5, pos.y) )
      -- end
      -- item:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString(""..k)
      -- item:getChildByName("txt_boss_ming"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt2"))
      -- item:getChildByName("txt_boss_playername"):getChildByName("txt"):setString(v.nickName)
      -- item:getChildByName("txt_boss_damege"):getChildByName("txt"):setString(getTextByKey("crossBoss_score").."" .. v.score)
      -- item:getChildByName("txt_1"):getChildByName("txt"):setString("" .. v.serverId .. getTextByKey("crossBoss_serverSuffix"))
    --   item:setAnchorPoint( ccp(0.5, 0.5) )
      
    --   item:setPosition(ccp(67, 1280 - 542 - k*40))
    --   endUI:addChild(item)
    -- end 

    --改成tableview
    local tableView = self:createTableView(endUI:getChildByName("table_Srien_ranking_list") , crossBossRewardPhase.ranks)
    endUI:addChild(tableView)

    endUI:getChildByName("txt_Siren_21"):getChildByName("txt"):setString(getTextByKey("crossBoss_activityWinTips_1" , { type1= witchType}))
    endUI:getChildByName("txt_04"):getChildByName("txt"):setString(getTextByKey("crossBoss_activityWinTips_2"))
    
    local rankTxt = ""
	  if crossBossRewardPhase.rank > CrossWorldBossManager.getCrossBossSettingConfig().rankingCalcNum or crossBossRewardPhase.rank == 0 then
	  	rankTxt = CrossWorldBossManager.getCrossBossSettingConfig().rankingCalcNum..getTextByKey("crossBoss_myRankSuffix")
	  else
	  	rankTxt = getTextByKey("activity_rankTxt1").. crossBossRewardPhase.rank..getTextByKey("activity_rankTxt2")
	  end
    endUI:getChildByName("txt_Siren_22"):getChildByName("txt"):setString(getTextByKey("crossBoss_finalMyInfo", {num1 = crossBossRewardPhase.score, num2 = rankTxt}))
    -- endUI:getChildByName("txt_Siren_23"):getChildByName("txt"):setString(rankTxt)
  -- else
  --   endUI:getChildByName("bg_boss_win_list_Srien"):setVisible(false)
  --   endUI:getChildByName("table_Srien_ranking_list"):setVisible(false)
    
  --   endUI:getChildByName("txt_sameName_05"):setVisible(true)
  --   endUI:getChildByName("txt_sameName_05"):getChildByName("txt"):setString(getTextByKey("crossBoss_activityLoseTips", {text1 = witchType}) )
  -- end
   endUI:getChildByName("halfblack3_l"):setVisible(false)
   endUI:getChildByName("halfblack3_r"):setVisible(false)
  if isKill ~= 1 then
    endUI:getChildByName("txt_Siren_21"):getChildByName("txt"):setString(getTextByKey("crossBoss_activityLoseTips" , {text1 = witchType}))
  end

  endUI:getChildByName("txt_Siren_18"):getChildByName("txt"):setString(getTextByKey("crossBoss_nextHero"))

  local godHeros = CrossWorldBossManager.getGodHerosByVersion(self.version + 1)
  --godHeros[1].isActive = true
  for i=1,#godHeros do
    local godWill = endUI:getChildByName("normal_card_small_name_godWill"..i)
    local sourceDisplay = godWill:getChildByName("normal_card_small")
    local heroIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, godHeros[i].metaId, 1, {sourceDisplay = sourceDisplay , showInCenter = true})
    local heroName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, godHeros[i].metaId, 0, {withoutAmount  = true})
    godWill:getChildByName("txt_Siren_34"):getChildByName("txt"):setString(heroName)
    godWill:addChildAt(heroIcon,1)
    if not godHeros[i].isActive then
      local backLayer = LayerColor:create()
      backLayer:setColor(ccc3( 10, 10, 10 ))
      backLayer.blackLayerColor = ccc3( 0, 0, 0 )
      backLayer.originalColor = ccc3( 10, 10, 10 )
      backLayer.refCocosObj:setOpacity( 200 )
      local length = 134
      backLayer:setContentSize(CCSizeMake( length, length ))
      backLayer:setPosition(ccp(-length / 2, -length / 2))
      heroIcon:addChild(backLayer)
    end
    if ((self.version + 1)%4) + 1 == i then
    	self:addParticle(heroIcon)
    end
    godWill:getChildByName("normal_card_small"):removeFromParentAndCleanup(true)
    local function onClickHeroIcon( evt )
      CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, godHeros[evt.context].metaId)
    end
    local btn = Button:create(heroIcon)
    btn:addEventListener( Events.kStart, onClickHeroIcon, i )
  end

  local function onReward( evt )
  	if BagCalcManager.isFull() then
	    NewPackageFullPanel:show()
	    return
	end
  	local function successCallback(data)
	    self.container:setTableViewsEnabled(false)
	  	local aInfoPanel = CrossMultiplayerGetRankRewardPanel:create(self.container,data.data)
	  	self.container:addChild(aInfoPanel)
	    aInfoPanel:scaleIn()
	    self.rewardBtn:setEnable(false)
	    if g_homeInfo and g_homeInfo.crossBossReward then
	  		g_homeInfo.crossBossReward = false
	  	end
	  	self.container:resetTipInfoForActivity("Activity_CrossBoss")
	  end

	  local function failureCallback(data)
	    if data.retCode == 716947 then
	    	local aContent = getTextByKey("crossBoss_errorCodeNotRewardTime")
	    	SuspensionLabel:showContent(Director:mgr():run(), aContent)
	      	self:getCrossBossInfo()
	    end
	  end
    GainCrossBossRewardRequest.sendRequest(nil ,successCallback , failureCallback )
  end

  endUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("crossBoss_gainReward"))
  self.rewardBtn = Button:create(endUI:getChildByName("btn_battle_start") , true)
  self.rewardBtn:addEventListener(Events.kStart,onReward ,self)

  if not crossBossRewardPhase.canReward then
    self.rewardBtn:setEnable(false)
  end

  endUI:getChildByName("txt_Siren_10"):getChildByName("txt"):setString(getTextByKey("crossBoss_rewardCutOffTime_1"))
  endUI:getChildByName("txt_Siren_11"):getChildByName("txt"):setString(CrossWorldBossManager.getRewardEndTimeTxt( self.version ))
  endUI:getChildByName("txt_Siren_15"):getChildByName("txt"):setString(getTextByKey("crossBoss_rewardCutOffTime_2"))
end

function Activity_CrossMultiplayerBossLayer:createTableView(display , dataList)
    local cellTag = 1024

    local CrossMultiplayerBossRenderer = class(TableViewRenderer)

    function CrossMultiplayerBossRenderer:ctor(width , height )
        self.width = width
        self.height = height
        self.list = dataList or {}
    end

    function CrossMultiplayerBossRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
        local aCell = builder:build("list/Srien_rank_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)

        aCell:getChildByName("txt_boss_di"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt1"))
        -- if k < 10 then
        --   local pos = aCell:getChildByName("txt_boss_rankfont"):getPosition()
        --   aCell:getChildByName("txt_boss_rankfont"):setPosition( ccp( pos.x + 5, pos.y) )
        -- end
        -- aCell:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString(""..k)
        aCell:getChildByName("txt_boss_ming"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt2"))
        -- aCell:getChildByName("txt_boss_playername"):getChildByName("txt"):setString(v.nickName)
        -- aCell:getChildByName("txt_boss_damege"):getChildByName("txt"):setString(getTextByKey("crossBoss_score").."" .. v.score)
        -- aCell:getChildByName("txt_1"):getChildByName("txt"):setString("" .. v.serverId .. getTextByKey("crossBoss_serverSuffix"))
    end

    function CrossMultiplayerBossRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local aData = self.list[index + 1]

        if index + 1 < 10 then
          local pos = self:getChildByNames(aCell, "txt_boss_rankfont"):getPositionX()
          self:getChildByNames(aCell, "txt_boss_rankfont"):setPositionX( pos + 5 )
        end

        self:setTxtByNames(aCell, "txt_boss_rankfont/txt", ""..(index + 1))
        self:setTxtByNames(aCell, "txt_boss_playername/txt", aData.nickName)
        self:setTxtByNames(aCell, "txt_boss_damege/txt", getTextByKey("crossBoss_score").."" .. aData.score)
        self:setTxtByNames(aCell, "txt_1/txt", "" .. aData.serverId .. getTextByKey("crossBoss_serverSuffix"))
    end

    local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    local aCell = builder:build("list/Srien_rank_list")

    local tableViewSizes = getTableViewSizes(display)
    display:setVisible(false)

    self.renderer = CrossMultiplayerBossRenderer.new(674.95, 31)
    self.renderer:scanTags(aCell)
    local aTableView = TableView:create(self.renderer, 674.95, 214.45, cellTag, nil, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
    -- aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
    -- self.mainUI:addChild(aTableView)
    return aTableView
end

function Activity_CrossMultiplayerBossLayer:showWitchWakeFlash()
  local witch = CrossWorldBossManager.getWitchByType( 1 )
  local witchWake = CrossWorldBossManager.getWitchByType( 2 )
  local fsptWake = FlashSprite:create("EVO2/witchWake")
  -- local bossPic = MetaManager.getWorldBossLevelMeta(1).cardPic
  -- bossPic = "full.png"
  local cardSpriteFrame = getFullCardSpriteFrame(witch.cardMetaId)
  fsptWake:addChangeInstance("boss1", cardSpriteFrame)
  local cardSpriteFrame2 = getFullCardSpriteFrame(witchWake.cardMetaId)
  fsptWake:addChangeInstance("boss2", cardSpriteFrame2)
  
  fsptWake:setLoop(false)
  local fsptWake_co = CocosObject.new(fsptWake)
  local function onCloudFlashAnimationEnd(anim)
    fsptWake:unregisterEndAnimationScriptHandler()
    self:removeChild(fsptWake_co)
    self.fsptWake = nil;
    self.fspt:setVisible(true)
    self:playOtherPlayerFlash()
  end
  self.fsptWake = fsptWake
  fsptWake:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
  self:addChild(fsptWake_co)

  fsptWake:changeAnimation(0)
end

function Activity_CrossMultiplayerBossLayer:showWitchCrazyFlash()
  local witch = CrossWorldBossManager.getWitchByType( 1 )
  local witchWake = CrossWorldBossManager.getWitchByType( 3 )
  local fsptCrazy = FlashSprite:create("EVO2/witchCrazy")
  -- local bossPic = MetaManager.getWorldBossLevelMeta(1).cardPic
  -- bossPic = "full.png"
  local cardSpriteFrame = getFullCardSpriteFrame(witch.cardMetaId)
  fsptCrazy:addChangeInstance("boss1", cardSpriteFrame)
  local cardSpriteFrame2 = getFullCardSpriteFrame(witchWake.cardMetaId)
  fsptCrazy:addChangeInstance("boss2", cardSpriteFrame2)
  
  fsptCrazy:setLoop(false)
  local fsptCrazy_co = CocosObject.new(fsptCrazy)
  local function onCloudFlashAnimationEnd(anim)
    fsptCrazy:unregisterEndAnimationScriptHandler()
    self:removeChild(fsptCrazy_co)
    self.fsptCrazy = nil;
    self.fspt:setVisible(true)
    self:playOtherPlayerFlash()
    -- self.fspt:changeAnimation(1)
  end
  self.fsptCrazy = fsptCrazy
  fsptCrazy:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
  self:addChild(fsptCrazy_co)

  fsptCrazy:changeAnimation(0)
end

function Activity_CrossMultiplayerBossLayer:initLayer()
    Activity_CrossMultiplayerBossLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    self.builder.useArtLabelTTF = true
	-- self.bg = self.builder:build("Siren_1")
	-- self:addChild(self.bg)

 -- 	self.bg:getChildByName("full"):setVisible(false)

	-- local witch = CrossWorldBossManager.getWitchByType( 1 )
	-- local witchMeta = witch.cardMetaId
	-- self.witchBG = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(witchMeta))
	-- self.witchBG:setAnchorPoint(self.bg:getChildByName("full"):getAnchorPoint())
	-- self.witchBG:setScale(1.36)
	-- self.witchBG:setPosition(ccp(self.bg:getChildByName("full"):getPositionX() , self.bg:getChildByName("full"):getPositionY()))
	-- self.bg:addChild(self.witchBG)

	self.isBossKilled = false

  self:changeLayerByStatus()

end

function Activity_CrossMultiplayerBossLayer.getTipNum()
  if not Activity_CrossMultiplayerBossLayer.enable() then
    return 0
  end

  if DataManager.getCurrUser().level < CrossWorldBossManager.getCrossBossSettingConfig().unlockLevel then
  	return 0
  end

  if g_homeInfo and g_homeInfo.crossBossEnablePhase == 1 then
  	-- local isEnable = MaintenanceManager.isActivityOpen(CrossWorldBossManager.getCrossBossSettingConfig().featureNameBattle)
	  -- if not isEnable then
	  -- 	return 0
	  -- else
	  	local cost , times = CrossWorldBossManager.getChallengeCostAndTimes()
		if cost == 0 then
		  	return times
		end
		-- return 0
	 --  end
  end

  if g_homeInfo and g_homeInfo.crossBossEnablePhase == 2 then 
  	-- local isEnable2 = MaintenanceManager.isActivityOpen(CrossWorldBossManager.getCrossBossSettingConfig().featureNameReward)
	  -- if not isEnable2 then
	  -- 	return 0
	  -- else
	  	if g_homeInfo and g_homeInfo.crossBossReward then
	  		return 1 
	  	end
	  	-- return 0
	  -- end
  end
  

  return 0
end