

require "canon.scene.BaseUIScene"
require "canon.scene.TestBattleScene"
require "canon.panel.InspirePanel"
require "canon.panel.WorldBossRewardPanel"



WorldBossScene = class(BaseUIScene)
WorldBossScene.worldBossInfo = nil
WorldBossScene.lastFightAnimTime = nil
g_WorldBossScene = nil
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3


function WorldBossScene:ctor()
	-- self.argv = argv
	self.title = getTextByKey("worldBoss_title")
	g_WorldBossScene = self
end


function WorldBossScene:create( argv )
    local s = WorldBossScene.new()
    s.argv = argv
    s:initScene()
    return s    
end

function WorldBossScene:onInspire(evt)
	if WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition >= self.worldBossConfig.inspireLimit then
		SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
	else
		self.targetInspirePanel = InspirePanel:create( self )
		PopoutManager:sharedManager():popout(self.targetInspirePanel, kPopoutDir.kScale, true, false ,self) 
	end
end

function WorldBossScene:setWorldBossPicture(bossUI, ui5)
	--设置世界Boss图片
	local bossPic = MetaManager.getWorldBossLevelMeta(WorldBossScene.worldBossInfo.worldBossMonster.level).cardPic
	bossPic = "pic/" .. bossPic .. ".png"
	local cardDisplay = Sprite:create(bossPic)
	bossUI:getChildByName("boss_temporary"):removeChildren(true)
	cardDisplay:setPosition(ccp(60, 0))
	cardDisplay:setScale(0.9)
	if ui5 then
		cardDisplay:setPosition(ccp(60, -50))
	end
	bossUI:getChildByName("boss_temporary"):addChild(cardDisplay)
	
	bossUI:getChildByName("nicebg"):removeChildren(true)
	local spt = Sprite:create("pic/nicebg.png")
	spt:setScaleY(1.3)
	spt:setScaleX(1.9)
	spt:setPosition(ccp(360, -325))
	if ui5 then
		spt:setScaleY(1.4)
		spt:setPosition(ccp(360, -290))
	end
	bossUI:getChildByName("nicebg"):addChild(spt)
end

function WorldBossScene:showPrepearBattleUI()
	self.curUIState = "prepear"
	self.boss3ReadyFight:setVisible(false)
	self.boss2PrepareFight:setVisible(true)
	self:setWorldBossPicture(self.boss2PrepareFight)

	local aNewLabel = ArtLabelTTF:create(tostring(WorldBossScene.worldBossInfo.worldBossMonster.level), true)
	aNewLabel:setCenterColor(ccc3(255,236,60))
	aNewLabel:setAroundColor(ccc3(96,37,8))
	aNewLabel:setSize(35)
	aNewLabel:construct()
	aNewLabel:setPosition(ccp(60,11))
	self.boss2PrepareFight:getChildByName("lbl_LV"):addChild(CocosObject.new(aNewLabel))

	local function updateTime()
		self.curTime = self.curTime + 1
		if self.worldbossMiddayOpen and self.curTime >= self.wordbossTimeInfo.prepareTime1 and self.curTime < self.wordbossTimeInfo.worldBossTime1 then
			local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime1 - self.curTime)
			self.boss2PrepareFight:getChildByName("txt_timecd"):getChildByName("txt"):setString(leftTimeString)
		elseif self.curTime >= self.wordbossTimeInfo.prepareTime and self.curTime < self.wordbossTimeInfo.worldBossTime then
			local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime - self.curTime)
			self.boss2PrepareFight:getChildByName("txt_timecd"):getChildByName("txt"):setString(leftTimeString)
		else
			self.battleCoolTime = self.curTime
		    self:showBattleUI()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTimeFunc )
			self.updateTimeFunc = nil
		end
	end

	local function onInspireClick(evt)
		self:onInspire()
	end

	--准备击杀Boss 可以用鼓舞，但还不能击杀
	self.boss2PrepareFight:getChildByName("boss_btn_inspire"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspireBtn"))   --设置鼓舞按钮文字
	local inspire = Button:create( self.boss2PrepareFight:getChildByName("boss_btn_inspire"))
	inspire:addEventListener( Events.kStart, onInspireClick ,self)

	local pos = self.boss2PrepareFight:getChildByName("txt_inspire_info"):getPosition()
	self.boss2PrepareFight:getChildByName("txt_inspire_info"):setPosition(ccp( pos.x + 80, pos.y - 5) )
	self.boss2PrepareFight:getChildByName("txt_inspire_info"):getChildByName("txt"):setDimensions(CCSizeMake(0,0))
	
	if WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition > 0.0001 then
		local inspire = math.floor( (WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition + 0.0001) * 100 )
		self.boss2PrepareFight:getChildByName("txt_inspire_info"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspire_boost") .. inspire .. "%")
	else
		self.boss2PrepareFight:getChildByName("txt_inspire_info"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspireTips"))  --设置鼓舞士气可以加成属性文字
	end
	
	self.boss2PrepareFight:getChildByName("txt_tobattlestart"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))	--设置距离战斗开始还有：文字

	updateTime()
	self.updateTimeFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateTime, 1, false )
end


--更新战斗界面，Boss随时掉血显示
function WorldBossScene:upateBossBlood(bossLeftHp)
	local enemyHPPercentage = WorldBossScene.worldBossInfo.worldBossMonster.leftHp / WorldBossScene.worldBossInfo.worldBossMonster.totalHp * 100
	if bossLeftHp then
		enemyHPPercentage = bossLeftHp / WorldBossScene.worldBossInfo.worldBossMonster.totalHp * 100
	end
	
	if enemyHPPercentage > 99.99 then
		enemyHPPercentage = 99.99
	end
	self.enemyHpPB:setPercentage(enemyHPPercentage)

	if self.boss3ReadyFight then
	      local bloodString = "" .. WorldBossScene.worldBossInfo.worldBossMonster.leftHp .. " / " .. WorldBossScene.worldBossInfo.worldBossMonster.totalHp
	      if bossLeftHp then
				local bloodString = "" .. bossLeftHp .. " / " .. WorldBossScene.worldBossInfo.worldBossMonster.totalHp
		  end
	      self.boss3ReadyFight:getChildByName("txt_bossBlood"):getChildByName("txt"):setString(bloodString)
	 end
end

function WorldBossScene:changeFlashCard(metaId)
	local cardMeta = MetaManager.card_meta[tonumber(metaId)]
	local cardSpf = getCardSpriteFrame(metaId)
	local cardBoardSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[cardMeta.rare])
	local cardBgSpf = getCardBackGroundSpriteFrameByMeta(cardMeta)
	local cardBallSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryIcon_" .. cardMeta.country .. ".png")
	local cardBallbgSpf = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. cardMeta.country .. ".png")
	self.fightFlash:addChangeInstance("card2M", cardSpf)
	self.fightFlash:addChangeInstance("cardBg2M", cardBgSpf)
	self.fightFlash:addChangeInstance("cardBorder2M", cardBoardSpf)
	self.fightFlash:addChangeInstance("card2Mball", cardBallSpf)
	self.fightFlash:addChangeInstance("card2Mballbg", cardBallbgSpf)
end


function WorldBossScene:fightBoss(fightType)
      self.fightBossTarget = true
	local function onChallengeWorldBossSuccess(response)
		if fightType == 1 then
			RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -self.worldBossConfig.reviveCost})
		elseif fightType == 2 then
			RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -self.worldBossConfig.rebornCost})
		end
		print( "onChallengeWorldBossSuccess" )
		local params = {
			battleData = response.data,
			bossHpMax = WorldBossScene.worldBossInfo.worldBossMonster.totalHp,
			bossHp = WorldBossScene.worldBossInfo.worldBossMonster.leftHp,
		}
		response.data.bossHpMax = WorldBossScene.worldBossInfo.worldBossMonster.totalHp
		response.data.bossHp = WorldBossScene.worldBossInfo.worldBossMonster.leftHp
		Director:sharedDirector():replaceScene(BattleScene:create(response.data, BattleBackType.kWorldBossScene, BattleEnterEnum.kWorldBossScene))
	end
	local function onChallengeWorldBossFailed(response)
		 if response.data == 714310 then
		 	local function onGetWorldBossInfo(response)
		 			WorldBossScene.worldBossInfo = response.data
					WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
					WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
					if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 then
						self.bossKilled = true
					end
                    self:showResultUI()
            end
			
            local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
            request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
            request:start()	
		 end
	end
	local params = {battleType = fightType}
	local request = ChallengeWorldBossRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener( RequestNotifyEnum.challengeWorldBossSuccessd, onChallengeWorldBossSuccess )
	request:addEventListener( RequestNotifyEnum.challengeWorldBossFailed, onChallengeWorldBossFailed )
	request:start()
end

function WorldBossScene:showFightImmediately( ) --可以鼓舞，加开战, 欲火
	self.boss3ReadyFight:getChildByName("btn_revivenow"):setVisible(false)
	self.boss3ReadyFight:getChildByName("btn_fight"):setVisible(true)
	self.boss3ReadyFight:getChildByName("txt_bossdamege3"):setVisible(false)
	self.boss3ReadyFight:getChildByName("txt_bosscountdown"):setVisible(false)

	local function onClickFight(evt) --挑战按钮
		print("on  fight btn click")
		self:fightBoss(0) --直接打Boss
	end

	self.boss3ReadyFight:getChildByName("btn_fight"):getChildByName("txt"):setString(getTextByKey("worldBoss_challengeBtn"))
	local fightBtn = Button:create( self.boss3ReadyFight:getChildByName("btn_fight"))
	fightBtn:addEventListener( Events.kStart,onClickFight ,self)	

		--浴火重生
	local function onClickFireRevive(evt)
		print("on onClickFireRevive click")
		local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
		if  not VipManager.isOwnPriv(vipLevel, 15) then
			local requireVipLevel = VipManager.getStartUpVipLevel(15)
			self.targetInfoPanel = VipWarningPanel:create( self, requireVipLevel)
	        PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
			
		elseif CalculationManager.calcComplex_getGemsNow() < self.worldBossConfig.rebornCost then
			--SuspensionLabel:showContent(self, "没有足够的金币了")
			local function onReplaceScene()
				--[[self:setTableViewsEnabled(true)
				self.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )--]]
			end
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:fightBoss(2) --重生打Boss
		end
	end

	local reviveBorn = "" .. self.worldBossConfig.rebornCost .. "    " .. getTextByKey("worldBoss_rebornBtn")
	self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("txt"):setString(reviveBorn)
	local reviveBtn2 = Button:create( self.boss3ReadyFight:getChildByName("btn_renascence"))
	reviveBtn2:addEventListener( Events.kStart,onClickFireRevive ,self)
end

function WorldBossScene:showFightCoolDown( ) --战斗冷却时间，可以鼓舞，复活，欲火
	self.boss3ReadyFight:getChildByName("btn_fight"):setVisible(false)
	self.boss3ReadyFight:getChildByName("btn_revivenow"):setVisible(true)

		--浴火重生
	local function onClickFireRevive(evt)
		print("on onClickFireRevive click")
		local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
		if  not VipManager.isOwnPriv(vipLevel, 15) then
			local requireVipLevel = VipManager.getStartUpVipLevel(15)
			self.targetInfoPanel = VipWarningPanel:create( self, requireVipLevel)
	        PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
			
		elseif CalculationManager.calcComplex_getGemsNow() < self.worldBossConfig.rebornCost then
			--SuspensionLabel:showContent(self, "没有足够的金币了")
			local function onReplaceScene()
				--[[self:setTableViewsEnabled(true)
				self.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )--]]
			end
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:fightBoss(2) --重生打Boss
		end
	end

	local reviveBorn = "" .. self.worldBossConfig.rebornCost .. "    " .. getTextByKey("worldBoss_rebornBtn")
	self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("txt"):setString(reviveBorn)
	local reviveBtn2 = Button:create( self.boss3ReadyFight:getChildByName("btn_renascence"))
	reviveBtn2:addEventListener( Events.kStart,onClickFireRevive ,self)
	if self.curTime < self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown then
		local lastTime = self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown - self.curTime
		self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("txt"):setString(reviveBorn..lastTime)
		self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("normal"):setVisible(false)
		reviveBtn2:setEnable(false)
	end

	local function onClickRevive(evt)
		print("on revive click")
		local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
		if  not VipManager.isOwnPriv(vipLevel, 14) then
			local requireVipLevel = VipManager.getStartUpVipLevel(14)
			self.targetInfoPanel = VipWarningPanel:create( self, requireVipLevel)
		    PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
		elseif CalculationManager.calcComplex_getGemsNow() < self.worldBossConfig.reviveCost then
			--SuspensionLabel:showContent(self, "没有足够的金币了")
			local function onReplaceScene()
				--[[self:setTableViewsEnabled(true)
				self.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )--]]
			end
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:fightBoss(1) --重生打Boss
		end
	end
	
	local reviveCost = "" .. self.worldBossConfig.reviveCost .. "    " .. getTextByKey("worldBoss_reviveBtn")
	self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("txt"):setString(reviveCost)
	local reviveBtn = Button:create( self.boss3ReadyFight:getChildByName("btn_revivenow"))
	reviveBtn:addEventListener( Events.kStart,onClickRevive ,self)
	if self.curTime < self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown then
		local lastTime = self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown - self.curTime
		self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("txt"):setString(reviveCost..lastTime)
		self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("normal"):setVisible(false)
		reviveBtn:setEnable(false)
	end

	local function updateFightTime()
		self.curTime = self.curTime + 1
		if self.curTime < self.battleCoolTime then
			local leftFightTimeString = TimeUtil.formatTimeWithoutHour(self.battleCoolTime - self.curTime)
			self.boss3ReadyFight:getChildByName("txt_bosscountdown"):getChildByName("txt"):setString(leftFightTimeString) --设置剩余时间
		else
			self:showFightImmediately()
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateFightTimeFunc )
			self.updateFightTimeFunc = nil
		end

		-- self.argv.tickTime = self.argv.tickTime + 1
		if self.curTime < self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown then
			local lastTime = self.battleCoolTime - self.worldBossConfig.battleCooldown + self.worldBossConfig.reviveCooldown - self.curTime
			self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("txt"):setString(reviveCost..lastTime)
			reviveBtn:setEnable(false)
			self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("normal"):setVisible(false)

			self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("txt"):setString(reviveBorn..lastTime)
			reviveBtn2:setEnable(false)
			self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("normal"):setVisible(false)
		else
			local reviveCost = "" .. self.worldBossConfig.reviveCost .. "    " .. getTextByKey("worldBoss_reviveBtn")
			self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("txt"):setString(reviveCost)
			reviveBtn:setEnable(true)
			self.boss3ReadyFight:getChildByName("btn_revivenow"):getChildByName("normal"):setVisible(true)

			local reviveBorn = "" .. self.worldBossConfig.rebornCost .. "    " .. getTextByKey("worldBoss_rebornBtn")
			self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("txt"):setString(reviveBorn)
			reviveBtn2:setEnable(true)
			self.boss3ReadyFight:getChildByName("btn_renascence"):getChildByName("normal"):setVisible(true)
		end
	end

	--设置倒计时时间
	self.boss3ReadyFight:getChildByName("txt_bossdamege3"):getChildByName("txt"):setString(getTextByKey("worldBoss_inCooldown")) --设置，队伍修整中，剩余时间
	local leftFightTimeString = TimeUtil.formatTimeWithoutHour(self.battleCoolTime - self.curTime)
	local pos = self.boss3ReadyFight:getChildByName("txt_bosscountdown"):getPosition()
	self.boss3ReadyFight:getChildByName("txt_bosscountdown"):setPosition(ccp( pos.x + 20, pos.y))
	self.boss3ReadyFight:getChildByName("txt_bosscountdown"):getChildByName("txt"):setString(leftFightTimeString) --设置剩余时间
	self.updateFightTimeFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateFightTime, 1, false )
	
	--ToDo cool down time
end

function WorldBossScene:playOtherPlayerHurtBossAnim(animData)
	self.curAnimData = animData
	local newMeta = CommonManager:getSelfAvatarMetaByUid( self.curAnimData.uid )
    if not newMeta then
        newMeta = self.curAnimData.mainCardMetaId
    end
	self:changeFlashCard(newMeta)
	local fightPosition = math.random(3) - 1
	self.fightFlash:changeAnimation(fightPosition)
	self.fightAnimPlaying = true
end

function WorldBossScene:getNextFightAnimData(changeData)
	local minTimeRecords = nil
	for k,v in pairs(WorldBossScene.worldBossInfo.worldBossRecords) do
		if v.challengeTime > WorldBossScene.lastFightAnimTime then	      
			if minTimeRecords == nil then
				minTimeRecords = v
			else
			
				if v.challengeTime < minTimeRecords.challengeTime then
					minTimeRecords = v
				end
			end
		end
	end
	if minTimeRecords ~= nil then
		if changeData then
			WorldBossScene.lastFightAnimTime = minTimeRecords.challengeTime
			minTimeRecords.challengeTime = 0
		end
	end
	return minTimeRecords
end

function WorldBossScene:sendGetWorldBossInfoRequest()
	if not self.lastGetInfoRequestFinished then
		do return end
	end

	local curTime = TimeUtil.getServerTimeSeconds()
	if (curTime - self.lastGetBossInfoTime) < 10 then
		do return end
	end

	local function onGetWorldBossInfo(response)
		WorldBossScene.worldBossInfo = response.data
		WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
		WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
		if self.fightBossTarget then
	            do return end
	      end
		self.lastGetInfoRequestFinished = true
		self.lastGetBossInfoTime = TimeUtil.getServerTimeSeconds()
		
		if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.triggerFightAnimFunc )
			self.triggerFightAnimFunc = nil
			self.bossKilled = true
			self:showResultUI()
		end
	end

	local function onGetWorldBossFailed(response)
		self.lastGetInfoRequestFinished = true
	end
	local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
	request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
	request:addEventListener( RequestNotifyEnum.getWorldBossInfoFailed, onGetWorldBossFailed )
	request:start()	
	self.lastGetInfoRequestFinished = false
end

function WorldBossScene:sendGetWorldBossInfoWhenWaitingCalculateRequest()
	if not self.lastGetInfoRequestFinished then
		do return end
	end

	local curTime = TimeUtil.getServerTimeSeconds()
	if (curTime - self.lastGetBossInfoTime) < 10 then
		do return end
	end

	local function onGetWorldBossInfo(response)
		WorldBossScene.worldBossInfo = response.data
		WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
		WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)

		self.lastGetInfoRequestFinished = true
		self.lastGetBossInfoTime = TimeUtil.getServerTimeSeconds()
		
		if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.waitCalculateFunc )
			self.waitCalculateFunc = nil
			self.bossKilled = true
			self:showResultUI()
		end
	end

	local function onGetWorldBossFailed(response)
		self.lastGetInfoRequestFinished = true
	end
	local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
	request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
	request:addEventListener( RequestNotifyEnum.getWorldBossInfoFailed, onGetWorldBossFailed )
	request:start()	
	self.lastGetInfoRequestFinished = false
end

function WorldBossScene:updateShowBattleState()
		if self.curUIState ~= "battle" then
			return
		end
		
		if not g_WorldBossScene then
			return
		end

		if WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage <= 0 then
			self.boss3ReadyFight:getChildByName("txt_bossdamege1"):setVisible(false)
		else
			local outRank = DataManager.GameMetaData.activityWorldBossConfig.rankingRange
			if WorldBossScene.worldBossInfo.rank < 0 or WorldBossScene.worldBossInfo.rank > outRank then
				local hurtBossString = getTextByKey("worldBoss_damageOufOfRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..outRank})
				self.boss3ReadyFight:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
			else
				local hurtBossString = getTextByKey("worldBoss_damageInRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..WorldBossScene.worldBossInfo.rank})
				self.boss3ReadyFight:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
			end
		end	
			
		self.boss3ReadyFight:getChildByName("txt_bossother1"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspire_boost"))
		local inspire = math.floor( (WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition + 0.0001) * 100 )

		self.boss3ReadyFight:getChildByName("txt_boss_rankfont2"):getChildByName("txt"):setString("" .. inspire .. "%")
		self.boss3ReadyFight:getChildByName("txt_bossother3"):getChildByName("txt"):setString(getTextByKey("worldBoss_reviveBtn"))
		self.boss3ReadyFight:getChildByName("txt_bossother2"):getChildByName("txt"):setString(getTextByKey("worldBoss_extraBoost"))

		inspire = math.floor( self.worldBossConfig.rebornBuff * 100 )
		self.boss3ReadyFight:getChildByName("txt_boss_rankfont3"):getChildByName("txt"):setString("" .. inspire .. "%")
		local topRankName = ""
		if #WorldBossScene.worldBossInfo.worldBossRanks > 0 then
			topRankName = WorldBossScene.worldBossInfo.worldBossRanks[1].nickName
		end
		self.boss3ReadyFight:getChildByName("txt_bossdamege"):getChildByName("txt"):setString(getTextByKey("worldBoss_rankingTitle")..topRankName)
		
		for i=1, 10 do
			local rankData = WorldBossScene.worldBossInfo.worldBossRanks[i]
			if rankData ~= nil  then
				self.rank_item_array[i]:getChildByName("txt_boss_playername"):getChildByName("txt"):setString(rankData.nickName)
				self.rank_item_array[i]:getChildByName("txt_boss_damege"):getChildByName("txt"):setString("" .. rankData.totalDamage)
			else
				self.rank_item_array[i]:getChildByName("txt_boss_playername"):setVisible(false)
				self.rank_item_array[i]:getChildByName("txt_boss_damege"):setVisible(false)
			end
		end

end

function WorldBossScene:showCalculateResultUI()
	self.boss2PrepareFight:setVisible(false)
	self.boss3ReadyFight:setVisible(true)

	self.boss3ReadyFight:getChildByName("boss_temporary"):removeChildren(true)
	-- self.fightAnimPlaying = false
	self.lastGetInfoRequestFinished = true
	self.lastGetBossInfoTime = TimeUtil.getServerTimeSeconds()
	self.fightBossTarget = false

	--Boss等级
	local aNewLabel = ArtLabelTTF:create(tostring(WorldBossScene.worldBossInfo.worldBossMonster.level), true)
	aNewLabel:setCenterColor(ccc3(255,236,60))
	aNewLabel:setAroundColor(ccc3(96,37,8))
	aNewLabel:setSize(35)
	aNewLabel:construct()
	aNewLabel:setPosition(ccp(74,11))
	self.boss3ReadyFight:getChildByName("lbl_LV"):addChild(CocosObject.new(aNewLabel))
	
	local hpBarBg = Sprite:create("battle/pic/xuecao.png")
	hpBarBg:setPosition(ccp(visibleSize.width/2, 1000))
	hpBarBg:setScaleX(0.6)
	self.boss3ReadyFight:addChild(hpBarBg)

	if WorldBossScene.worldBossInfo.worldBossMonster.leftHp > WorldBossScene.worldBossInfo.worldBossMonster.totalHp then
	      --CCMessageBox("boss totalHp:" .. WorldBossScene.worldBossInfo.worldBossMonster.totalHp .. " and cur Hp:" .. WorldBossScene.worldBossInfo.worldBossMonster.leftHp, "Canon")
		WorldBossScene.worldBossInfo.worldBossMonster.totalHp = WorldBossScene.worldBossInfo.worldBossMonster.leftHp + 1000
	end

	local enemyHPPercentage = WorldBossScene.worldBossInfo.worldBossMonster.leftHp / WorldBossScene.worldBossInfo.worldBossMonster.totalHp * 100
	if enemyHPPercentage > 99.99 then
		enemyHPPercentage = 99.99
	end

	self.enemyHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
	self.enemyHpPB:setPosition(ccp(visibleSize.width/2, 1000))
	self.enemyHpPB:setType(kCCProgressTimerTypeBar);
	self.enemyHpPB:setMidpoint(ccp(1,1))
	self.enemyHpPB:setBarChangeRate(ccp(1, 0))
	self.enemyHpPB:setPercentage(enemyHPPercentage)
	self.enemyHpPB:setScaleX(0.6)
	self.boss3ReadyFight:addChild(CocosObject.new(self.enemyHpPB))

	self:upateBossBlood()

	if WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage <= 0 then
		self.boss3ReadyFight:getChildByName("txt_bossdamege1"):setVisible(false)
	else
		local outRank = DataManager.GameMetaData.activityWorldBossConfig.rankingRange
		if WorldBossScene.worldBossInfo.rank < 0 or WorldBossScene.worldBossInfo.rank > outRank then
			local hurtBossString = getTextByKey("worldBoss_damageOufOfRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..outRank})
			self.boss3ReadyFight:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
		else
			local hurtBossString = getTextByKey("worldBoss_damageInRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..WorldBossScene.worldBossInfo.rank})
			self.boss3ReadyFight:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
		end
	end	

	self.boss3ReadyFight:getChildByName("nicebg"):removeChildren(true)
	local spt = Sprite:create("pic/nicebg.png")
	spt:setScaleY(1.4)
	spt:setScaleX(1.9)
	spt:setPosition(ccp(360, -310))
	self.boss3ReadyFight:getChildByName("nicebg"):addChild(spt)

	self.boss3ReadyFight:getChildByName("txt_boos3_1"):getChildByName("txt"):setString(getTextByKey("worldBoss_rankProcessText"))

	self.fightFlash = FlashSprite:create("EVO2/boss_raid")
	self.curFightIndex = 1
	local bossPic = MetaManager.getWorldBossLevelMeta(WorldBossScene.worldBossInfo.worldBossMonster.level).cardPic
	bossPic = "pic/" .. bossPic .. ".png"
	local cardSpriteFrame = createSpriteFrame(bossPic)
	self.fightFlash:addChangeInstance("boss", cardSpriteFrame)
	self.fightFlash:setLoop(false)
	self.fightFlash:changeAnimation(3)
	-- self.fightFlash:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	-- self.fightAnimPlaying = true
	self.fightFlash:setPosition(-280, -950)
	local flash_co = CocosObject.new(self.fightFlash)
	self.boss3ReadyFight:getChildByName("boss_temporary"):addChild(flash_co)

	local function updateTriggerFightAnim()
		self:sendGetWorldBossInfoWhenWaitingCalculateRequest()
	end
	-- self.fightAnimPlaying = false
	self.waitCalculateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateTriggerFightAnim, 1, false )

	if self.updateTimeFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTimeFunc )
		self.updateTimeFunc = nil
	end

	if self.updateFightTimeFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateFightTimeFunc )
		self.updateFightTimeFunc = nil
	end

	if self.triggerFightAnimFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.triggerFightAnimFunc )
		self.triggerFightAnimFunc = nil
	end

	self:showServerCalculateRankUI(true)

	if self.rank_item_array and #self.rank_item_array ~= 0 then
		for i=1,#self.rank_item_array do
			self.rank_item_array[i]:setVisible(false)
		end
	end
end

function WorldBossScene:showBattleUI()
	self.curUIState = "battle"

	self.boss2PrepareFight:setVisible(false)
	self.boss3ReadyFight:setVisible(true)

	self.boss3ReadyFight:getChildByName("boss_temporary"):removeChildren(true)

	self.fightAnimPlaying = false
	self.lastGetInfoRequestFinished = true
	self.lastGetBossInfoTime = 0
	self.fightBossTarget = false

	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
	self.rank_item_array = {}
	for i=1,5 do
		local rank_item = builder:build("boss_damage_rank")
		rank_item:getChildByName("txt_boss_di"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt1"))
		rank_item:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString("" .. i )
		
		local pos = rank_item:getChildByName("txt_boss_rankfont"):getPosition()
		rank_item:getChildByName("txt_boss_rankfont"):setPosition( ccp(pos.x + 5, pos.y) )
		rank_item:getChildByName("txt_boss_ming"):getChildByName("txt"):setString( getTextByKey("activity_rankTxt2"))
		
		local pos = rank_item:getChildByName("txt_boss_playername"):getPosition()
		rank_item:getChildByName("txt_boss_playername"):setPosition(ccp( pos.x - 90, pos.y ))
		
		local pos = rank_item:getChildByName("txt_boss_damege"):getPosition()
		rank_item:getChildByName("txt_boss_damege"):setPosition(ccp( pos.x - 170, pos.y ))
		
		rank_item:setPosition(ccp( 50, 310 -(i*30)))
		self.boss3ReadyFight:addChild(rank_item)
		self.rank_item_array[i] = rank_item
	end

	for i=6,10 do
		local rank_item = builder:build("boss_damage_rank")
		rank_item:getChildByName("txt_boss_di"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt1"))
		rank_item:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString("" .. i )
		if i < 10 then
			local pos = rank_item:getChildByName("txt_boss_rankfont"):getPosition()
			rank_item:getChildByName("txt_boss_rankfont"):setPosition( ccp(pos.x + 5, pos.y) )
		end
		rank_item:getChildByName("txt_boss_ming"):getChildByName("txt"):setString( getTextByKey("activity_rankTxt2"))
		
		local pos = rank_item:getChildByName("txt_boss_playername"):getPosition()
		rank_item:getChildByName("txt_boss_playername"):setPosition(ccp( pos.x - 90, pos.y ))
		
		local pos = rank_item:getChildByName("txt_boss_damege"):getPosition()
		rank_item:getChildByName("txt_boss_damege"):setPosition(ccp( pos.x - 145, pos.y ))
		
		rank_item:setPosition(ccp( 370, 310 -((i-5)*30)))
		self.boss3ReadyFight:addChild(rank_item)
		self.rank_item_array[i] = rank_item
	end

	--Boss等级
	local aNewLabel = ArtLabelTTF:create(tostring(WorldBossScene.worldBossInfo.worldBossMonster.level), true)
	aNewLabel:setCenterColor(ccc3(255,236,60))
	aNewLabel:setAroundColor(ccc3(96,37,8))
	aNewLabel:setSize(35)
	aNewLabel:construct()
	aNewLabel:setPosition(ccp(74,11))
	self.boss3ReadyFight:getChildByName("lbl_LV"):addChild(CocosObject.new(aNewLabel))
	
	local hpBarBg = Sprite:create("battle/pic/xuecao.png")
	hpBarBg:setPosition(ccp(visibleSize.width/2, 970))
	hpBarBg:setScaleX(0.6)
	self.boss3ReadyFight:addChild(hpBarBg)

	if WorldBossScene.worldBossInfo.worldBossMonster.leftHp > WorldBossScene.worldBossInfo.worldBossMonster.totalHp then
	      --CCMessageBox("boss totalHp:" .. WorldBossScene.worldBossInfo.worldBossMonster.totalHp .. " and cur Hp:" .. WorldBossScene.worldBossInfo.worldBossMonster.leftHp, "Canon")
		WorldBossScene.worldBossInfo.worldBossMonster.totalHp = WorldBossScene.worldBossInfo.worldBossMonster.leftHp + 1000
	end

	local enemyHPPercentage = WorldBossScene.worldBossInfo.worldBossMonster.leftHp / WorldBossScene.worldBossInfo.worldBossMonster.totalHp * 100
	if enemyHPPercentage > 99.99 then
		enemyHPPercentage = 99.99
	end

	self.enemyHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
	self.enemyHpPB:setPosition(ccp(visibleSize.width/2, 970))
	self.enemyHpPB:setType(kCCProgressTimerTypeBar);
	self.enemyHpPB:setMidpoint(ccp(1,1))
	self.enemyHpPB:setBarChangeRate(ccp(1, 0))
	self.enemyHpPB:setPercentage(enemyHPPercentage)
	self.enemyHpPB:setScaleX(0.6)
	self.boss3ReadyFight:addChild(CocosObject.new(self.enemyHpPB))

	--获取之前Boss被攻击的血量
--	local function getLastShowTimeBossHp()
--		for k,v in pairs(WorldBossScene.worldBossInfo.worldBossRecords) do
--			if v.challengeTime >= WorldBossScene.lastFightAnimTime then
--				WorldBossScene.worldBossInfo.worldBossMonster.leftHp = v.monsterLeftHp
--				break
--			end
--		end
--	end


	-- local pos = self.boss3ReadyFight:getChildByName("lbl_Boss"):getPosition()
	-- self.boss3ReadyFight:getChildByName("lbl_Boss"):setPosition(ccp(pos.x, pos.y -10))

	-- local pos = self.boss3ReadyFight:getChildByName("lbl_LV"):getPosition()
	-- self.boss3ReadyFight:getChildByName("lbl_LV"):setPosition(ccp(pos.x, pos.y -9))
	
	--self.boss3ReadyFight:getChildByName("txt_bossBlood"):removeChildren(true)
	--self.bossBloodArtTextField = ArtTextField:create("" , nil, 25)
	--self.bossBloodArtTextField:setPosition(ccp(150, -18))
	--self.boss3ReadyFight:getChildByName("txt_bossBlood"):addChild(self.bossBloodArtTextField)
	
	
	local animData = self:getNextFightAnimData(false)
	if animData then
		self:upateBossBlood(tonumber( animData.monsterLeftHp + animData.damage))
	else
		self:upateBossBlood()
	end

	local function onFlashAnimationEnd(anim)
		if not g_WorldBossScene then
			return
		end
		print("on FlashAnimation end")
		self.fightAnimPlaying = false
		WorldBossScene.worldBossInfo.worldBossMonster.leftHp =  tonumber( self.curAnimData.monsterLeftHp)
		self:upateBossBlood()
	end
	
	self.fightFlash = FlashSprite:create("EVO2/boss_raid")
	self.curFightIndex = 1
	local bossPic = MetaManager.getWorldBossLevelMeta(WorldBossScene.worldBossInfo.worldBossMonster.level).cardPic
	bossPic = "pic/" .. bossPic .. ".png"
	local cardSpriteFrame = createSpriteFrame(bossPic)
	self.fightFlash:addChangeInstance("boss", cardSpriteFrame)
	self.fightFlash:setLoop(false)
	self.fightFlash:changeAnimation(3)
	self.fightFlash:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	self.fightAnimPlaying = true
	self.fightFlash:setPosition(-280, -950)
	local flash_co = CocosObject.new(self.fightFlash)
	self.boss3ReadyFight:getChildByName("boss_temporary"):addChild(flash_co)
	
	self.boss3ReadyFight:getChildByName("nicebg"):removeChildren(true)
	local spt = Sprite:create("pic/nicebg.png")
	spt:setScaleY(1.4)
	spt:setScaleX(1.9)
	spt:setPosition(ccp(360, -310))
	self.boss3ReadyFight:getChildByName("nicebg"):addChild(spt)

	local function updateTriggerFightAnim()
		if not self.fightAnimPlaying then
			local animData = self:getNextFightAnimData(true)
			if animData then
				self:playOtherPlayerHurtBossAnim(animData)
			end
			self:sendGetWorldBossInfoRequest()
		end

		self.curTime = TimeUtil.getServerTimeSeconds()
		if (self.curTime > self.wordbossTimeInfo.finishTime) or (self.worldbossMiddayOpen and self.curTime > self.wordbossTimeInfo.finishTime1 and self.curTime < self.wordbossTimeInfo.separationTime) then
			self:showResultUI()
		end
	end
	self.fightAnimPlaying = false
	self.triggerFightAnimFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateTriggerFightAnim, 1, false )

	local function onInspireClick(evt)
		self:onInspire()
	end
	self.boss3ReadyFight:getChildByName("boss_btn_inspire2"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspireBtn"))
	local inspireBtn = Button:create( self.boss3ReadyFight:getChildByName("boss_btn_inspire2"))
	inspireBtn:addEventListener( Events.kStart,onInspireClick ,self)
	
	self.boss3ReadyFight:getChildByName("txt_boos3_1"):getChildByName("txt"):setString(getTextByKey("worldBoss_rankProcessText"))
	
	self:updateShowBattleState()
	
	if self.curTime < self.battleCoolTime then 
		self:showServerCalculateRankUI(false)
		self:showFightCoolDown()
	else
		self:showServerCalculateRankUI(false)
		self:showFightImmediately()
	end

	if self.bossKilled and self:isServerCalRank() then
		self.boss3ReadyFight:getChildByName("txt_bossdamege3"):setVisible(false)
		self.boss3ReadyFight:getChildByName("txt_bosscountdown"):setVisible(false)
	end

end

function WorldBossScene:showKilledUI(  )
	if self.targetInfoPanel then
		PopoutManager:sharedManager():pullin(self.targetInfoPanel, kPopoutDir.kScale )
		self.targetInfoPanel = nil
		if self.mainActorPanel then
			self.mainActorPanel = nil 
		end
	end
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
    self.boss4UI = builder:build("boss4")
	self:addChild(self.boss4UI)

	local lastShowPlayerName = "小菜花"
	if WorldBossScene.worldBossInfo.worldBossMonster.lastShotNickName then
		lastShowPlayerName = WorldBossScene.worldBossInfo.worldBossMonster.lastShotNickName
	end
	self.boss4UI:getChildByName("txt_bossbei"):getChildByName("txt"):setString(getTextByKey("worldBoss_resultKill", {playername = lastShowPlayerName}))

	local rewardName = getTextByKey(WorldBossScene.worldBossInfo.worldBossMonster.normalTextKey)
	self.boss4UI:getChildByName("txt_bosskill"):getChildByName("txt"):setString(getTextByKey("worldBoss_resultReward", {name = rewardName}))
	self.boss4UI:getChildByName("txt_bossdamege"):getChildByName("txt"):setString(getTextByKey("worldBoss_rankingTitle") ..  WorldBossScene.worldBossInfo.worldBossRanks[1].nickName)

	for  k, v in pairs(WorldBossScene.worldBossInfo.worldBossRanks) do
		local item = builder:build("boss_rank_item")
		item:getChildByName("txt_boss_di"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt1"))
		if k < 10 then
			local pos = item:getChildByName("txt_boss_rankfont"):getPosition()
			item:getChildByName("txt_boss_rankfont"):setPosition( ccp( pos.x + 5, pos.y) )
		end
		item:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString(""..k)
		item:getChildByName("txt_boss_ming"):getChildByName("txt"):setString(getTextByKey("activity_rankTxt2"))
		item:getChildByName("txt_boss_playername"):getChildByName("txt"):setString(v.nickName)
		item:getChildByName("txt_boss_playerdamege"):getChildByName("txt"):setString("" .. v.totalDamage)
		item:setPosition(ccp(50, 400 - k*50))
		self.boss4UI:addChild(item)
	end	

	self.boss4UI:getChildByName("txt_bossdamege1"):getChildByName("txt"):setDimensions( CCSizeMake(0, 0))
	self.boss4UI:getChildByName("txt_bossdamege_font"):setVisible(false)
	self.boss4UI:getChildByName("txt_bossdamege2"):setVisible(false)
	self.boss4UI:getChildByName("txt_bossrank_font"):setVisible(false)
	self.boss4UI:getChildByName("txt_bossrank1"):setVisible(false)
	
	
	local outRank = DataManager.GameMetaData.activityWorldBossConfig.rankingRange
	if WorldBossScene.worldBossInfo.rank < 0 or WorldBossScene.worldBossInfo.rank > outRank then
		local hurtBossString = getTextByKey("worldBoss_damageOufOfRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..outRank})
		self.boss4UI:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
	else
		local hurtBossString = getTextByKey("worldBoss_damageInRank", {num = "".. WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage, rank = ""..WorldBossScene.worldBossInfo.rank})
		self.boss4UI:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(hurtBossString)
	end

	local function onClickGetReward(evt)
		if BagCalcManager.isFull() then
    		local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
    		-- SuspensionLabel:showContent(self, aContent)
    		NewPackageFullPanel:show()
    	else
			local function onGainWorldBossRewards(response)
				print( "gainWorldBossRewards" )
				self.rewardData = response.data
				self.targetRewardPanel = WorldBossRewardPanel:create( self )
				PopoutManager:sharedManager():popout(self.targetRewardPanel, kPopoutDir.kScale, true, false ,self) 
			end
			
			local function onGainWorldBossRewardsFailed(response)
				print( "gainWorldBossRewards" )
				if response.data == 714322 then
					local function closeCanonMessageBox()
						self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_WorldBoss"})
					end
					local separationHourTimeStr = self.wordbossTimeInfo.separationHour..":00"
					local text = Localization:getInstance():getText("worldBoss_error_txt", {num1 = separationHourTimeStr})
					CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
				end
			end
			
			local request = GainWorldBossRewardsRequest.new(nil, rpc.SendingPriority.kHigh)
			request:addEventListener( RequestNotifyEnum.gainWorldBossRewardsSuccessd, onGainWorldBossRewards )
			request:addEventListener( RequestNotifyEnum.gainWorldBossRewardsFailed, onGainWorldBossRewardsFailed )
			request:start()
			self.boss4UI:getChildByName("btn_getreward"):setVisible(false)
		end
	end
	self.boss4UI:getChildByName("btn_getreward"):getChildByName("txt"):setString(getTextByKey("reward_claimBtn"))
	local btn = Button:create( self.boss4UI:getChildByName("btn_getreward"))
	btn:addEventListener( Events.kStart,onClickGetReward ,self)

	if WorldBossScene.worldBossInfo.worldBossUserStatus.gainChallengeReward then
		self.boss4UI:getChildByName("btn_getreward"):setVisible(false)
	end
	
	if not WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage or WorldBossScene.worldBossInfo.worldBossUserStatus.totalDamage <= 0 then
		self.boss4UI:getChildByName("btn_getreward"):setVisible(false)
	end

end

function WorldBossScene:showFaildUI(  )
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
    self.boss5UI = builder:build("boss5")
	self:addChild(self.boss5UI)
	self:setWorldBossPicture(self.boss5UI, true)
	self.boss5UI:getChildByName("txt_bossNotKilled"):getChildByName("txt"):setString(getTextByKey("worldBoss_resultFailure"))
end

function WorldBossScene:showServerCalculateRankUI( flag )
	self.boss3ReadyFight:getChildByName("txt_bossdamege"):setVisible(not flag)
	-- self.boss3ReadyFight:getChildByName("pattern_cardTraining_line"):setVisible(not flag)
	-- self.boss3ReadyFight:getChildByName("pattern_formation_line"):setVisible(not flag)
	-- self.boss3ReadyFight:getChildByName("pattern_formation_line2"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("boss_btn_inspire2"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("btn_fight"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("btn_renascence"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("txt_bossother1"):setVisible(not flag)

	self.boss3ReadyFight:getChildByName("txt_boss_rankfont2"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("txt_boss_rankfont3"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("txt_bossother2"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("txt_bossother3"):setVisible(not flag)

	self.boss3ReadyFight:getChildByName("btn_revivenow"):setVisible(not flag)

	self.boss3ReadyFight:getChildByName("txt_bossdamege3"):setVisible(not flag)
	self.boss3ReadyFight:getChildByName("txt_bosscountdown"):setVisible(not flag)

	self.boss3ReadyFight:getChildByName("txt_boos3_1"):setVisible(flag)
end

function WorldBossScene:showResultUI()
	self.curUIState = "result"
	self.boss2PrepareFight:setVisible(false)
	self.boss3ReadyFight:setVisible(false)
	
	if self.bossKilled then
		if self:isServerCalRank() then
			self:showCalculateResultUI()
	 		self:showServerCalculateRankUI(true)
	 	else
	 		self:showKilledUI()
	 	end
	else
		self:showFaildUI()
	end
end


function WorldBossScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
    self.boss2PrepareFight = builder:build("boss2")
	self:addChild(self.boss2PrepareFight)
	
	builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
	builder.useArtLabelTTF = true
    self.boss3ReadyFight = builder:build("boss3")
	self:addChild(self.boss3ReadyFight)
	builder.useArtLabelTTF = false
	
	--相关的各种数据
	--WorldBossScene.worldBossInfo = WorldBossScene.worldBossInfo
	--self.worldBossUserStatus = WorldBossScene.worldBossInfo.worldBossUserStatus
	self.worldBossConfig = DataManager.GameMetaData.activityWorldBossConfig
	
	local pos = self.boss3ReadyFight:getChildByName("lbl_Boss"):getPosition()
	self.boss3ReadyFight:getChildByName("lbl_Boss"):setPosition(ccp(pos.x, pos.y -10))

	local pos = self.boss3ReadyFight:getChildByName("lbl_LV"):getPosition()
	self.boss3ReadyFight:getChildByName("lbl_LV"):setPosition(ccp(pos.x, pos.y -9))
	
	self.curTime = TimeUtil.getServerTimeSeconds()
	
	self.wordbossTimeInfo = Activity_WorldBossLayer.getWorldBossTime()
	self.worldbossMiddayOpen = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName2)
	
	self.battleCoolTime = WorldBossScene.worldBossInfo.worldBossUserStatus.challengeTime + self.worldBossConfig.battleCooldown
	
	if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 then
		self.bossKilled = true
	else
		self.bossKilled = false
	end
	
	self.curUIState = "none" 
	if (self.worldbossMiddayOpen and self.curTime >= self.wordbossTimeInfo.prepareTime1 and self.curTime < self.wordbossTimeInfo.worldBossTime1) or (self.curTime >= self.wordbossTimeInfo.prepareTime and self.curTime < self.wordbossTimeInfo.worldBossTime)  then 
		--准备击杀Boss的时间
		self:showPrepearBattleUI()
		
	else
		if self.bossKilled or self.curTime > self.wordbossTimeInfo.finishTime or (self.worldbossMiddayOpen and self.curTime > self.wordbossTimeInfo.finishTime1 and self.curTime < self.wordbossTimeInfo.separationTime) then 
			--Boss 被杀或者过了击杀Boss的时间
			self:showResultUI()
		else 
			--正是可以杀Boss的时候
			self:showBattleUI()
		end
	end
	
	BaseUIScene.onInit(self)
end

function WorldBossScene:isServerCalRank()
	local serverTime = TimeUtil.getServerTimeSeconds()
	local worldBossDieTime = WorldBossScene.worldBossInfo.worldBossMonster.challengeTime
	if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 and (serverTime - worldBossDieTime) <= DataManager.GameMetaData.activityWorldBossConfig.rankProcessTime then
		return true
	end
	return false
end

function WorldBossScene:back()
	self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_WorldBoss"})
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function WorldBossScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
-- 进入场景动画的预处理
----------------------------------------
function WorldBossScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

----------------------------------------
-- 进入场景动画
----------------------------------------
function WorldBossScene:startEnterAnimation()
	  BaseUIScene.startEnterAnimation(self)
	  local regCallFunc = false
	  function doEnterAnimation( disPobject )
	  		if not disPobject then
	  			do return end
	  		end
	  		local function enterActionFinished()
			    self:nodeAnimationFinished()
			end
			disPobject:setPositionX(disPobject:getPositionX() - visibleSize.width)
			local arr = CCArray:create()
			arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
			if not regCallFunc and disPobject:isVisible()  then
				arr:addObject(CCCallFunc:create(enterActionFinished))
				regCallFunc = true
			end
			disPobject:runAction(CCSequence:create(arr))
	  end
	  doEnterAnimation(self.boss2PrepareFight)
	  doEnterAnimation(self.boss3ReadyFight)
	  doEnterAnimation(self.boss4UI)
	  doEnterAnimation(self.boss5UI)
end


function WorldBossScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function WorldBossScene:doExitAnimation()
   self:preExitAnimation()
   self:startExitAnimation()
end

----------------------------------------
-- 退出场景动画的预处理
----------------------------------------
function WorldBossScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
-- 退出场景的动画
----------------------------------------
function WorldBossScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  	 local regCallFunc = false
	  function doEnterAnimation( disPobject )
	  		if not disPobject then
	  			do return end
	  		end
	  		local function enterActionFinished()
			    self:nodeAnimationFinished()
			end
			local arr = CCArray:create()
			arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))

			if not regCallFunc and disPobject:isVisible()  then
				arr:addObject(CCCallFunc:create(enterActionFinished))
				regCallFunc = true
			end
			disPobject:runAction(CCSequence:create(arr))
	  end
	  doEnterAnimation(self.boss2PrepareFight)
	  doEnterAnimation(self.boss3ReadyFight)
	  doEnterAnimation(self.boss4UI)
	  doEnterAnimation(self.boss5UI)


end

----------------------------------------
-- 退出场景动画的后处理
----------------------------------------
function WorldBossScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function WorldBossScene:dispose()
	if self.updateTimeFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTimeFunc )
	end

	if self.updateFightTimeFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateFightTimeFunc )
	end

	if self.triggerFightAnimFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.triggerFightAnimFunc )
	end

	if self.waitCalculateFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.waitCalculateFunc )
	end
	g_WorldBossScene = nil
	WorldBossScene.super.dispose(self)
end
