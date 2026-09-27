require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.features.unionPk.panel.UnionBattleSettlementPopPanel"

UnionBattleScene = class(Scene)
local visibleSize = CCSizeMake(720, 1280)--CCDirector:sharedDirector():getVisibleSize()
local SELF = nil

local battleFlashTable = {"battle/CardbattleXX3", "battle/Cardbattle_lasthit", "battle/hero_buff", 
"battle/Cardbattle_normal", "battle/Cardbattle_blade", "battle/Cardbattle_spear", "battle/Cardbattle_hammer", "battle/Cardbattle_bow"
}

SINGLEBATTLEWINTYPE = table.const {
	SELF_WIN = 0,
	SELF_BIG_WIN = 1,
	ENEMY_WIN = 2,
	ENEMY_BIG_WIN = 3,
}

local addedBattleFlashTable = {}
local totalEventCount = 0
local eventNumCount = 0

local nameLabelPosX = 130

local hpBarResPath = "battle/unionBattleRes/bg_guildPK_full_blood.png"

function UnionBattleScene:ctor()
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


function UnionBattleScene:create(data , argv)
	-- g_isInBattleScene = true;
	CanonPlayBackgroundMusic("music/m_battle.mp3", true,true)
	local scene = UnionBattleScene.new()
	scene.data = data
	scene.argv = argv
	-- local f = assert(io.open("d:/Unionbattle.txt", 'w'))
 -- f:write(table.serialize(data))
 -- f:close()
	scene:initScene()
	return scene
end

local onFlashEvent = nil;

function getBattleCardWithIndex( index )
	if SELF.unionCardIninDataList[index].unionBattleCardInitDatas == nil or #SELF.unionCardIninDataList[index].unionBattleCardInitDatas == 0 then
		return nil
	end
	return SELF.unionCardIninDataList[index].unionBattleCardInitDatas[1].cardInitData
end

function getWaitCardWithIndex( index )
	if SELF.unionCardIninDataList[index].unionBattleCardInitDatas == nil or #SELF.unionCardIninDataList[index].unionBattleCardInitDatas <= 1 then
		return nil
	end
	return SELF.unionCardIninDataList[index].unionBattleCardInitDatas[2].cardInitData
end

local function setToPlayEffectWithIndex(eventFlowTable , index)
	if not SELF.toPlayEffectTable[index] then
		SELF.toPlayEffectTable[index] = {}
	end
	table.insert(SELF.toPlayEffectTable[index], eventFlowTable)
end

local function showResultPanel()
	local scene = Director:mgr():run()
	local data,detailData = UnionBattleSettlementPopPanel.FormatData(SELF.data)
	local aMyGuildPanel =  nil
	if detailData.available then
		aMyGuildPanel = UnionBattleSettlementPopPanel:create(scene,data,detailData)
	else
		aMyGuildPanel = UnionBattleSettlementMiniPopPanel:create(scene,data)
	end

	local whetherWin = detailData.isAttWin
	SimpleAudioEngine:sharedEngine():stopBackgroundMusic()
	if whetherWin then
		SELF.effectId = CanonPlayEffect("music/m_win.wav")
	else
		SELF.effectId = CanonPlayEffect("music/m_lose.wav")
	end

	scene:addChild(aMyGuildPanel)
	aMyGuildPanel:scaleIn()
end

local function onSingleBattleEnd( anim )
	if eventNumCount == totalEventCount then
		changeBattleBetweenRound(true)
		return
	end
	SELF.finishedPlayerNum = SELF.finishedPlayerNum + 1
	if SELF.finishedPlayerNum >= SELF.totalBattleNum then
		SELF.finishedPlayerNum = 0 
		SELF.totalBattleNum = 0
		changeBattleBetweenRound()
	end
end

function removeUnionCardIninDataListHeadPlayerWithIndex(index)
	if SELF.unionCardIninDataList[index].unionBattleCardInitDatas == nil or #SELF.unionCardIninDataList[index].unionBattleCardInitDatas == 0 then
		return
	end 
	table.remove(SELF.unionCardIninDataList[index].unionBattleCardInitDatas , 1)
end

local function playBattleFlashWithIndex(index)
	--print("playBattleFlash")
	if not SELF.self_attack_flash_co[index] or not SELF.enemy_attack_flash_co[index] or not SELF.battle_flash_co[index] then
		return 
	end
	SELF.self_attack_flash_co[index]:setVisible(false)
	SELF.enemy_attack_flash_co[index]:setVisible(false)
	SELF.battle_flash_co[index]:setVisible(false)
	SELF.self_attack_flash[index]:setIsRun(false)
	SELF.enemy_attack_flash[index]:setIsRun(false)
	SELF.battle_flash[index]:setIsRun(false)
  --[[
  if SELF.enterType == BattleEnterEnum.kActivityContend and #SELF.unionFightEventFlowTable == 0 then
    SELF:showBattleResultPanel()
    return
  end
  ]]
  	local minIndex 
  	for i=1,#SELF.fightPlayers do
  		if SELF.fightPlayers[i] == true then
  			minIndex = i
  		end
  	end
	if  #SELF.unionFightEventFlowTable[1][index] == 0 then
		local function playLastHitAnim( id , weapon )
			SELF.battle_flash[index]:setIsRun(true)
			SELF.battle_flash[index]:changeAnimation(id)
			SELF.battle_flash_co[index]:setVisible(true)
			if index == minIndex then
				CanonPlayEffect(weapon)
			end
		end

		local function winningStreakFunc( index, isWin )
			local oneRound = SELF.unionBattleRounds[1]
			local winNums = string.split(oneRound.winNum , ',')

			if isWin then
				for i=1,4 do
					if SELF.enemyHpPB[index][i] then
						SELF.enemyHpPB[index][i]:getChildByTag(100):setVisible(false)
					end
					if SELF.selfHpPB[index][i] and SELF.selfHpPB[index][i]:getChildByTag(100) and SELF.selfHpPB[index][i]:getChildByTag(100).setString then
						SELF.selfHpPB[index][i]:getChildByTag(100):setString(winNums[index].."/"..getUnionBattleCardInitData(index).winLimit)
					end
				end
			else
				for i=1,4 do
					if SELF.selfHpPB[index][i] then
						SELF.selfHpPB[index][i]:getChildByTag(100):setVisible(false)
					end
					if SELF.enemyHpPB[index][i] and SELF.enemyHpPB[index][i]:getChildByTag(100) and SELF.enemyHpPB[index][i]:getChildByTag(100).setString then
						SELF.enemyHpPB[index][i]:getChildByTag(100):setString(winNums[index + 3].."/"..getUnionBattleCardInitData(index + 3).winLimit)
					end
				end
			end	
		end

		if SELF.selfHp[index] <= 0 then
			playLastHitAnim(30 , "music/sfx_attack_final.wav")
			if getWaitCardWithIndex(index) then
				table.insert(SELF.enterBattleFieldPlayers , index)
			end
			table.insert(SELF.deadPlayers , index)
			winningStreakFunc(index , false)
			removeUnionCardIninDataListHeadPlayerWithIndex(index)

			SELF.selfUnionPlayers = SELF.selfUnionPlayers - 1
			SELF.selfUnionLabel:setText(SELF.selfUnionName.." "..(SELF.selfUnionPlayers.."/"..SELF.selfUnionTotalPlayers))
			SELF.selfUnionLabel:construct()

			SELF.winNum[index + 3] = SELF.winNum[index + 3] + 1
			SELF.winNum[index] = 0

		elseif SELF.enemyHp[index] <= 0 then
			playLastHitAnim(28 , "music/sfx_attack_final.wav")
			if getWaitCardWithIndex(index + 3) then
				table.insert(SELF.enterBattleFieldPlayers , index + 3)
			end
			table.insert(SELF.deadPlayers , index + 3)
			winningStreakFunc(index , true)
			removeUnionCardIninDataListHeadPlayerWithIndex(index + 3)

			SELF.enemyUnionPlayers = SELF.enemyUnionPlayers - 1
			SELF.enemyUnionLabel:setText(SELF.enemyUnionName.." "..(SELF.enemyUnionPlayers.."/"..SELF.enemyUnionTotalPlayers))
			SELF.enemyUnionLabel:construct()

			SELF.winNum[index] = SELF.winNum[index] + 1
			SELF.winNum[index + 3] = 0
		else
			if getWaitCardWithIndex(index) then
				table.insert(SELF.enterBattleFieldPlayers , index)
			end
			table.insert(SELF.leavePlayers , index)
			winningStreakFunc(index , false)
			removeUnionCardIninDataListHeadPlayerWithIndex(index)

			-- SELF.selfUnionPlayers = SELF.selfUnionPlayers - 1
			-- SELF.selfUnionLabel:setText(SELF.selfUnionName.." "..(SELF.selfUnionPlayers.."/"..SELF.selfUnionTotalPlayers))
			-- SELF.selfUnionLabel:construct()

			onSingleBattleEnd()

			SELF.winNum[index + 3] = SELF.winNum[index + 3] + 1
			SELF.winNum[index] = 0
		end
		return
	else
		local fightEvent = SELF.unionFightEventFlowTable[1][index][1]
		table.remove(SELF.unionFightEventFlowTable[1][index] , 1)
		-- eventNumCount = eventNumCount + 1

		local function playBattleAnim( id , weapon)
			-- body
			SELF.self_attack_flash_co[index]:setVisible(true)
			SELF.self_attack_flash[index]:setIsRun(true)
			SELF.self_attack_flash[index]:changeAnimation(id)
			if index == minIndex then
				CanonPlayEffect(weapon)
			end
			-- CanonPlayEffect(weapon)
		end

		local function playBattleAnimEnemy( id , weapon )
			-- body
			SELF.enemy_attack_flash_co[index]:setVisible(true)
			SELF.enemy_attack_flash[index]:setIsRun(true)
			SELF.enemy_attack_flash[index]:changeAnimation(id)
			if index == minIndex then
				CanonPlayEffect(weapon)
			end
			-- CanonPlayEffect(weapon)
		end

		if fightEvent.actionType == ActionTypeEnum.ACTION_SELF then
			setToPlayEffectWithIndex({fightEvent} , index)
			if fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then

				playBattleAnim(SELF.selfFlashIndex[index] + 36, self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_MISS then

				playBattleAnim(SELF.selfFlashIndex[index] + 9 , self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then

				playBattleAnim(SELF.selfFlashIndex[index] + 18 , self_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
				playBattleAnim(27 , self_weapon_atk_effect)
			else

				playBattleAnim(SELF.selfFlashIndex[index]  , self_weapon_atk_effect)
			end
		else
			setToPlayEffectWithIndex({fightEvent} , index)
			if fightEvent.eventType == EVENTTYPE.ATTACK_CRIT then

				playBattleAnimEnemy(SELF.enemyFlashIndex[index] + 36 , enemy_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_MISS then

				playBattleAnimEnemy(SELF.enemyFlashIndex[index] + 9 , enemy_weapon_atk_effect)
	-- 			ATTACK_COUNTER = 3,--反击
	-- ATTACK_BLOCK = 4--格挡
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_BLOCK then

				playBattleAnimEnemy(SELF.enemyFlashIndex[index] + 18 , enemy_weapon_atk_effect)
			elseif fightEvent.eventType == EVENTTYPE.ATTACK_COUNTER then
				playBattleAnimEnemy(28 , enemy_weapon_atk_effect)
			else
				-- SELF.enemy_attack_flash_co:setVisible(true)
				-- SELF.enemy_attack_flash:setIsRun(true)
				-- SELF.enemy_attack_flash:changeAnimation(SELF.enemyFlashIndex)
				-- CanonPlayEffect(enemy_weapon_atk_effect)
				playBattleAnimEnemy(SELF.enemyFlashIndex[index]  , enemy_weapon_atk_effect)
			end
		end

	end

end

local function changeEnemyhp( index )
	local mainData = getBattleCardWithIndex(index + 3)
	if not mainData then
		SELF.enemyHp[index] = nil
		return
	end
	local isEnemyLeaveBattle = false
	for k,v in pairs(SELF.enterBattleFieldPlayers) do
		if v == index + 3 then
			isEnemyLeaveBattle = true
		end
	end
	if isEnemyLeaveBattle or SELF.enemyHp[index] == nil then
		SELF.enemyHp[index] = tonumber(mainData.hp)
	end
	SELF.enemyMaxHp[index] = tonumber(mainData.hp) 
	if SELF.enemyHpPB[index][4] then
		SELF.enemyHpPB[index][4]:setPercentage(SELF.enemyHp[index] /SELF.enemyMaxHp[index] * 100 )
	end
	
end

local function changeSelfHp( index )
	local mainData = getBattleCardWithIndex(index)
	if not mainData then
		SELF.selfHp[index] = nil
		return
	end
	local isSelfLeaveBattle = false
	for k,v in pairs(SELF.enterBattleFieldPlayers) do
		if v == index then
			isSelfLeaveBattle = true
		end
	end

	if isSelfLeaveBattle or SELF.selfHp[index] == nil then
		SELF.selfHp[index] = tonumber(mainData.hp) 
	end
	SELF.selfMaxHp[index] = tonumber(mainData.hp) 
	
	if SELF.selfHpPB[index][4] then
		SELF.selfHpPB[index][4]:setPercentage(SELF.selfHp[index] /SELF.selfMaxHp[index] * 100 )
	end
end

function UnionBattleScene:addSingleRoundBattleFlash(firstBattle)
	if not firstBattle then
		for index=1,3 do
			for i=1,3 do
				self.selfHpPB[index][i] = nil
				self.enemyHpPB[index][i] = nil
			end
		end
		
		for i=1,6 do
			-- if useAnim then
				self:addWaitPlayerWithAnim(i)
			-- else
			-- 	self:addWaitPlayerWithIndex(i)
			-- end

			self:addInBattlePlayerWithIndex(i)
		end
	end

	for i=1,3 do
		changeSelfHp(i)
		changeEnemyhp(i)
		self.fightPlayers[i] = false
		self:addBattleFlashWithIndex(i)
	end

	for i=1,3 do
		if not self.fightPlayers[i] then
			if self.inBattlePlayers[i] then
				self.inBattlePlayers[i]:setVisible(true)
			end
			if self.inBattlePlayers[i + 3] then
				self.inBattlePlayers[i + 3]:setVisible(true)
			end
		else
			if self.inBattlePlayers[i] then
				self.inBattlePlayers[i]:setVisible(false)
			end
			if self.inBattlePlayers[i + 3] then
				self.inBattlePlayers[i + 3]:setVisible(false)
			end
		end
	end

	for i=1,3 do
		playBattleFlashWithIndex(i)
	end
end

local enterBattleFieldPlayersNum = 0

function enterBattleField( index )
	if not SELF.waitPlayers[index] then
		enterBattleFieldPlayersNum  = enterBattleFieldPlayersNum + 1
		return 
	end
	local card = SELF.waitPlayers[index]
	local function actionFinished()
		enterBattleFieldPlayersNum  = enterBattleFieldPlayersNum + 1
		SELF.inBattlePlayers[index] = SELF.waitPlayers[index]
		SELF.waitPlayers[index] = nil
		if index <= 3 then
			SELF.selfHpPB[index][4] = SELF.waitHpPB[index]
			SELF.waitHpPB[index] = nil
		else
			SELF.enemyHpPB[index - 3][4] = SELF.waitHpPB[index]
			SELF.waitHpPB[index] = nil
		end

		if enterBattleFieldPlayersNum == #SELF.enterBattleFieldPlayers then
			enterBattleFieldPlayersNum = 0
			
			for i=1,3 do
				SELF:setFlashVisiable(i , true)
			end
			
			SELF:addSingleRoundBattleFlash(false)
			SELF.enterBattleFieldPlayers = {}
		end
	end
	local move 
	if card:getPositionY() > 1280 / 2 then
		move = -313.1
	else
		move = 313.1
	end
	local arr = CCArray:create()
  	arr:addObject(CCMoveBy:create(0.3, ccp(0, move)))
  	arr:addObject(CCCallFunc:create(actionFinished))
  	card:runAction(CCSequence:create(arr))
end

function afterMoveBattleLine( oneRoundData )
	if #SELF.enterBattleFieldPlayers == 0 then
		for i=1,3 do
			SELF:setFlashVisiable(i , true)
		end
		
		SELF:addSingleRoundBattleFlash(false)
	else
		for k,v in pairs(SELF.enterBattleFieldPlayers) do
			enterBattleField(v)
		end
	end
end

function moveBattleLine( from , to , oneRoundData , isFirstBattle)
	local function firstBattleAfterMove()
		for i=1,3 do
			changeSelfHp(i)
			changeEnemyhp(i)
			SELF.fightPlayers[i] = false
			SELF:addBattleFlashWithIndex(i)
		end

		for i=1,3 do
			if not SELF.fightPlayers[i] then
				if SELF.inBattlePlayers[i] then
					SELF.inBattlePlayers[i]:setVisible(true)
				end
				if SELF.inBattlePlayers[i + 3] then
					SELF.inBattlePlayers[i + 3]:setVisible(true)
				end
			else
				if SELF.inBattlePlayers[i] then
					SELF.inBattlePlayers[i]:setVisible(false)
				end
				if SELF.inBattlePlayers[i + 3] then
					SELF.inBattlePlayers[i + 3]:setVisible(false)
				end
			end
		end

		for i=1,3 do
			playBattleFlashWithIndex(i)
		end
	end
	if SELF.waitPlayers[from] then
		local card = SELF.waitPlayers[from]
		local function actionFinished()
			SELF.waitPlayers[to] = SELF.waitPlayers[from]
			SELF.waitPlayers[from] = nil

			SELF.selfHp[to] = SELF.selfHp[from]
			SELF.selfHp[from] = nil
			SELF.selfHpPB[to] = SELF.selfHpPB[from]
			SELF.selfHpPB[from] = {}
			SELF.winNum[to] = SELF.winNum[from]
			SELF.winNum[from] = 0
			for k,v in pairs(SELF.enterBattleFieldPlayers) do
				if v == from then
					SELF.enterBattleFieldPlayers[k] = to
				end
			end
			if isFirstBattle then
				firstBattleAfterMove()
			else
				afterMoveBattleLine(oneRoundData)
			end

		end

		local endPosX =  (125.5 + ((to - 1) % 3) * 235)

		local arr = CCArray:create()
	  	arr:addObject(CCMoveTo:create(0.3, ccp(endPosX, card:getPositionY())))
	  	arr:addObject(CCCallFunc:create(actionFinished))
	  	card:runAction(CCSequence:create(arr))

	  	if SELF.inBattlePlayers[from] then
			local card = SELF.inBattlePlayers[from]
			local endPosX =  (125.5 + ((to - 1) % 3) * 235)
			local arr = CCArray:create()
		  	arr:addObject(CCMoveTo:create(0.3, ccp(endPosX, card:getPositionY())))
		  	-- arr:addObject(CCCallFunc:create(actionFinished))
		  	card:runAction(CCSequence:create(arr))
		  	SELF.inBattlePlayers[to] = SELF.inBattlePlayers[from]
			SELF.inBattlePlayers[from] = nil
			return
		end
	end

	if SELF.inBattlePlayers[from] then
		local card = SELF.inBattlePlayers[from]
		local function actionFinished()
			SELF.inBattlePlayers[to] = SELF.inBattlePlayers[from]
			SELF.inBattlePlayers[from] = nil
			SELF.selfHp[to] = SELF.selfHp[from]
			SELF.selfHp[from] = nil
			SELF.selfHpPB[to] = SELF.selfHpPB[from]
			SELF.selfHpPB[from] = {}
			SELF.winNum[to] = SELF.winNum[from]
			SELF.winNum[from] = 0
			for k,v in pairs(SELF.enterBattleFieldPlayers) do
				if v == from then
					SELF.enterBattleFieldPlayers[k] = to
				end
			end
			
			if isFirstBattle then
				firstBattleAfterMove()
			else
				afterMoveBattleLine(oneRoundData)
			end
		end

		local endPosX =  (125.5 + ((to - 1) % 3) * 235)

		local arr = CCArray:create()
	  	arr:addObject(CCMoveTo:create(0.3, ccp(endPosX, card:getPositionY())))
	  	arr:addObject(CCCallFunc:create(actionFinished))
	  	card:runAction(CCSequence:create(arr))
	end
end

local function changeBuff(id , isSelf)
	local unionWarBuff = UnionPkConfig.getSettingConfig().unionWarBuffMetas
	local name = {"attBuff" , "defBuff" , "hpBuff"}	
	if isSelf then
		for k,v in pairs(SELF.selfAttrIncreaseValue) do
			SELF.selfAttrIncreaseValue[k] = SELF.selfAttrIncreaseValue[k] + getFloatNumber(unionWarBuff[id][name[k]]) * 100
			SELF.selfAttrValueLabel[k]:setString("+"..SELF.selfAttrIncreaseValue[k].."%")
		end
	else
		for k,v in pairs(SELF.enemyAttrIncreaseValue) do
			SELF.enemyAttrIncreaseValue[k] = SELF.enemyAttrIncreaseValue[k] + getFloatNumber(unionWarBuff[id][name[k]]) * 100
			SELF.enemyAttrValueLabel[k]:setString("+"..SELF.enemyAttrIncreaseValue[k].."%")
		end
	end
end 

function afterLeaveBattleField()
	table.remove(SELF.unionBattleRounds , 1)
	local oneRoundData = SELF.unionBattleRounds[1]
	table.remove(SELF.unionFightEventFlowTable , 1)

	local function changeLine()
		if oneRoundData.changePosition ~= nil then
			local changePosition = string.split(oneRoundData.changePosition , ',')
			local from = tonumber(changePosition[1])
			local to = tonumber(changePosition[2])
			SELF.unionCardIninDataList[to] = SELF.unionCardIninDataList[from]
			SELF.unionCardIninDataList[from] = {}
			moveBattleLine(from , to , oneRoundData)
		else
			afterMoveBattleLine(oneRoundData)
		end
	end

	local buffids = string.split(oneRoundData.buffId , ',')
	local function playBuffFlash( index )
		for i=index,6 do
			if tonumber(buffids[i]) ~= 0 then
				local fspt = FlashSprite:create("battle/popo_up_word")
				fspt:setLoop(false)
				fspt:changeAnimation(i + 7)
				local fspt_co = CocosObject.new(fspt)
				local function onBattleFlashAnimationEnd(anim)
					fspt:unregisterEndAnimationScriptHandler()
					SELF:removeChild(fspt_co)
					--Set_ShareData( "Cloud_Finished", 1 )
					SELF.fspt = nil;
					local isSelf 
					if i > 3 then
						isSelf = false
					else
						isSelf = true
					end
					changeBuff(tonumber(buffids[i]) , isSelf)
					playBuffFlash(i + 1)
				end
				SELF.fspt = fspt
				fspt:registerEndAnimationScriptHandler(onBattleFlashAnimationEnd)
				fspt_co:setZOrder(100)
				SELF:addChild(fspt_co)
				return
			end
		end
		changeLine()
	end
	playBuffFlash(1)

end

local leaveBattleFieldPlayersNum = 0

function leaveBattleField( index ,isLastRound)
	if not SELF.inBattlePlayers[index] then
		return 
	end

	local card = SELF.inBattlePlayers[index]

	local function actionFinished()
		leaveBattleFieldPlayersNum = leaveBattleFieldPlayersNum + 1
		
		if leaveBattleFieldPlayersNum == #SELF.leavePlayers then
			SELF.leavePlayers = {}
			leaveBattleFieldPlayersNum = 0
			if card then
				card:removeFromParentAndCleanup(true)
				card = nil
			end
			if isLastRound then
				if SELF.argv.battleType == UnionBattleType.kUnionPk then
					showResultPanel()
				elseif SELF.argv.battleType == UnionBattleType.kGVGBattle then
					CrossUnionPk.popBattleResultPanel(SELF.argv.enterType, SELF.data.sharkUnionBattlefieldReport, SELF.data.currPoints, SELF.data.changePoints)
				end
				
			else
				SELF.inBattlePlayers[index] = nil
				afterLeaveBattleField()
			end
		end
	end
	local move 
	if card:getPositionY() > 1280 / 2 then
		move = 1280 / 2
	else
		move = -1280 / 2
	end
	local arr = CCArray:create()
  	arr:addObject(CCMoveBy:create(0.3, ccp(0, move)))
  	arr:addObject(CCCallFunc:create(actionFinished))
  	card:runAction(CCSequence:create(arr))
end

function getUnionBattleCardInitData( index )
	if SELF.unionCardIninDataList[index].unionBattleCardInitDatas == nil or #SELF.unionCardIninDataList[index].unionBattleCardInitDatas == 0 then
		return nil
	end
	return SELF.unionCardIninDataList[index].unionBattleCardInitDatas[1]
end

function getUnionWaitBattleCardInitData( index )
	if SELF.unionCardIninDataList[index].unionBattleCardInitDatas == nil or #SELF.unionCardIninDataList[index].unionBattleCardInitDatas <= 1 then
		return nil
	end
	return SELF.unionCardIninDataList[index].unionBattleCardInitDatas[2]
end

function changeBattleBetweenRound(isLastRound)
	local oneRound = SELF.unionBattleRounds[1]
	local winNums = SELF.winNum

	for i=1,3 do
		SELF:setFlashVisiable(i , false)
		SELF:removeFlashWithIndex(i)
	end

	for k,v in pairs(SELF.deadPlayers) do
		SELF.inBattlePlayers[v]:removeFromParentAndCleanup(true)
		SELF.inBattlePlayers[v] = nil
	end
	SELF.deadPlayers = {}
	for k,v in pairs(winNums) do
		if getUnionBattleCardInitData(k) then
			local winLimit = getUnionBattleCardInitData(k).winLimit
			if winLimit and tonumber(v) >= winLimit then
				if getWaitCardWithIndex(k) then
					table.insert(SELF.enterBattleFieldPlayers , k)
				end
				-- table.insert(SELF.enterBattleFieldPlayers , k)
				table.insert(SELF.leavePlayers , k)
				removeUnionCardIninDataListHeadPlayerWithIndex(k)
				SELF.winNum[k] = 0
			end
		end
	end
	if isLastRound then
		if SELF.data.sharkUnionBattlefieldReport.warWin then
			local i = 1 
			while i <= #SELF.leavePlayers do
				if SELF.leavePlayers[i] <= 3 then
					table.remove(SELF.leavePlayers , i)
				else
					i = i + 1
				end
			end
		else
			local i = 1 
			while i <= #SELF.leavePlayers do
				if SELF.leavePlayers[i] > 3 then
					table.remove(SELF.leavePlayers , i)
				else
					i = i + 1
				end
			end
		end
	end

	for k,v in pairs(SELF.leavePlayers) do
		if v <= 3 then
			SELF.selfUnionPlayers = SELF.selfUnionPlayers - 1
		else
			SELF.enemyUnionPlayers = SELF.enemyUnionPlayers - 1
		end
	end

	SELF.selfUnionLabel:setText(SELF.selfUnionName.." "..(SELF.selfUnionPlayers.."/"..SELF.selfUnionTotalPlayers))
	SELF.selfUnionLabel:construct()
	SELF.enemyUnionLabel:setText(SELF.enemyUnionName.." "..(SELF.enemyUnionPlayers.."/"..SELF.enemyUnionTotalPlayers))
	SELF.enemyUnionLabel:construct()

	if #SELF.leavePlayers ~= 0 then
		for k,v in pairs(SELF.leavePlayers) do
			leaveBattleField(v ,isLastRound)
		end
	else
		if isLastRound then
			if SELF.argv.battleType == UnionBattleType.kUnionPk then
				showResultPanel()
			elseif SELF.argv.battleType == UnionBattleType.kGVGBattle then
				CrossUnionPk.popBattleResultPanel(SELF.argv.enterType, SELF.data.sharkUnionBattlefieldReport, SELF.data.currPoints, SELF.data.changePoints)
			end
		else
			afterLeaveBattleField()
		end
	end

end

local function onAttackFlashFinishWithIndex1(anim)
	--print("attackover")
	if SELF.gameEnd then
		do return end
	end
	playBattleFlashWithIndex(1)
end

local function onAttackFlashFinishWithIndex2(anim)
	--print("attackover")
	if SELF.gameEnd then
		do return end
	end
	playBattleFlashWithIndex(2)
end

local function onAttackFlashFinishWithIndex3(anim)
	--print("attackover")
	if SELF.gameEnd then
		do return end
	end
	playBattleFlashWithIndex(3)
end

function getBattlePlayersWeaponInfoWithIndex(index)
	if getBattleCardWithIndex( index ) == nil then
		return {}
	end
	-- if #SELF.unionCardIninDataList[index] == 0 or SELF.unionCardIninDataList[index].unionBattleCardInitDatas[1] == nil then
	-- 	print("哎哟我操！！！？？？")
	-- 	return {}
	-- end
	local sharkEquips =  SELF.unionCardIninDataList[index].unionBattleCardInitDatas[1].cardInitData.sharkEquips

	for equipkey,equipvalue in pairs(sharkEquips)
	do
		local equipMeta = MetaManager.equip_meta[equipvalue.metaId]
		if equipMeta.position == 1 then
			return equipMeta
			-- self.enemyWeaponInfo[index] = equipMeta
			-- break;
		end
	end

	return {}
end

function getAllBattlePlayersWeaponInfo()
	SELF.WeaponInfo = {}
	for i=1,6 do
		SELF.WeaponInfo[i] = getBattlePlayersWeaponInfoWithIndex(i)
	end
end

local function playAttriChangeEffectWithIndex(eventFlow , index)
	
	local totalEffectSelf = 0
	local totalEffectEnemy = 0
	local curEffectSelfIndex = 1
	local curEffectEnemyIndex = 1
	
	local function doEventInfo(k, v)

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

		elseif v.effectId == EFFECTTYPE.HP_DEC or v.eventType == EVENTTYPE.ATTACK or v.eventType == EVENTTYPE.ATTACK_BLOCK or v.eventType == EVENTTYPE.ATTACK_COUNTER then
			--effect = FlashSprite:create("battle/Def")
			color = NumberColorEnum.red
			number = -v.changedValue
			if v.posId < 10000 then
				SELF.selfHp[index] = SELF.selfHp[index] - v.changedValue
				if SELF.selfHp[index] < 0 then
					SELF.selfHp[index] = 0
				end
				for i=1,#SELF.selfHpPB[index] do
					SELF.selfHpPB[index][i]:setPercentage(SELF.selfHp[index] / SELF.selfMaxHp[index] * 100)
				end
				-- SELF.selfHpPB[index]:runAction(CCProgressTo:create(0.1, SELF.selfHp[index] / SELF.selfMaxHp[index] * 100))
			else
				SELF.enemyHp[index] = SELF.enemyHp[index] - v.changedValue
				if SELF.enemyHp[index] < 0 then
					SELF.enemyHp[index] = 0
				end
				for i=1,#SELF.enemyHpPB[index] do
					SELF.enemyHpPB[index][i]:setPercentage(SELF.enemyHp[index] / SELF.enemyMaxHp[index] * 100)
				end
				-- SELF.enemyHpPB[index]:runAction(CCProgressTo:create(0.1, SELF.enemyHp[index] / SELF.enemyMaxHp[index] * 100))
			end
		elseif v.eventType == EVENTTYPE.ATTACK_CRIT then
			color = NumberColorEnum.critical
			number = -v.changedValue
			if v.posId < 10000 then
				SELF.selfHp[index] = SELF.selfHp[index] - v.changedValue
				if SELF.selfHp[index] < 0 then
					SELF.selfHp[index] = 0
				end
				for i=1,#SELF.selfHpPB[index] do
					SELF.selfHpPB[index][i]:setPercentage(SELF.selfHp[index] / SELF.selfMaxHp[index] * 100)
				end
				-- SELF.selfHpPB[index]:runAction(CCProgressTo:create(0.1, SELF.selfHp[index] / SELF.selfMaxHp[index] * 100))
			else
				SELF.enemyHp[index] = SELF.enemyHp[index] - v.changedValue
				if SELF.enemyHp[index] < 0 then
					SELF.enemyHp[index] = 0
				end
				for i=1,#SELF.enemyHpPB[index] do
					SELF.enemyHpPB[index][i]:setPercentage(SELF.enemyHp[index] / SELF.enemyMaxHp[index] * 100)
				end
				-- SELF.enemyHpPB[index]:runAction(CCProgressTo:create(0.1, SELF.enemyHp[index] / SELF.enemyMaxHp[index] * 100))
			end

		else
			--donothing
		end
		if effect or color then
			local cardNum 
			local moveByPos
			local effectAnimation = 0
			local unionBattleCardPos 
			if v.posId < 10000 then
				cardNum = SELF.selfCardNum
				moveByPos = ccp(0, -50)
				unionBattleCardPos = ccp((-114 + (index - 1) * 235 + 360 * 0.65) , 473.6)
			else
				cardNum = SELF.enemyCardNum
				moveByPos = ccp(0, 50)
				unionBattleCardPos = ccp((-114 + (index - 1) * 235 + 360 * 0.65) , 806.4)
			end
			local configData = getConfigData(v.posId, cardNum)
			
			local mainAttriPath, updownPath
			local txtMovePos
			local mainSkillPixielX = 0
			
			--to do, bug for xiao wangzi
			effect = nil
			
			if effect then
				moveByPos = ccp(0, 50)
				effect:changeAnimation(effectAnimation)
				effect:setLoop(false)
				effect:setPosition( configData.pos_x + mainSkillPixielX, configData.pos_y )
				local effect_co = CocosObject.new(effect)
				table.insert(SELF.effectFlash[index][#SELF.effectFlash[index]], effect_co)
				SELF:addChild(effect_co)
			end
			
			local numberEffect = nil

			if v.eventType == EVENTTYPE.SELF_SKILL or v.eventType == EVENTTYPE.MAIN_SKILL then
				local scaleFactor = 0.4
				numberEffect = createNumberEffect(number, unionBattleCardPos.x, unionBattleCardPos.y, color, true, 4 * scaleFactor, false, 2 * scaleFactor, moveByPos, true)
			else
				numberEffect = createNumberEffect(number, unionBattleCardPos.x, unionBattleCardPos.y, color, true, 4, false, 2, moveByPos, true)
			end

			-- local numberEffect = createNumberEffect(number, configData.pos_x + mainSkillPixielX, configData.pos_y + 20, color, true, 4, false, 2, moveByPos, true)
			table.insert(SELF.effectFlash[index][#SELF.effectFlash[index]], numberEffect)
			SELF:addChild(numberEffect)
		end
	end

	for k,v in pairs(eventFlow) do
		if type(v) == "table" then
			doEventInfo(k,v)
		end
	end

end

local function removeLastFlashEffectWithIndex1()
	local index = 1
	if type (SELF.effectFlash[index]) == "table" and #SELF.effectFlash[index] > 0 then
		for k,v in pairs(SELF.effectFlash[index][1])
		do
			SELF:removeChild(v)
		end
		table.remove(SELF.effectFlash[index], 1)
	end
end

local function removeLastFlashEffectWithIndex2()
	local index = 3
	if type (SELF.effectFlash[index]) == "table" and #SELF.effectFlash[index] > 0 then
		for k,v in pairs(SELF.effectFlash[index][1])
		do
			SELF:removeChild(v)
		end
		table.remove(SELF.effectFlash[index], 1)
	end
end

local function removeLastFlashEffectWithIndex3()
	local index = 3
	if type (SELF.effectFlash[index]) == "table" and #SELF.effectFlash[index] > 0 then
		for k,v in pairs(SELF.effectFlash[index][1])
		do
			SELF:removeChild(v)
		end
		table.remove(SELF.effectFlash[index], 1)
	end
end

local function playNextEffectWithIndex(index)
	if type(SELF.toPlayEffectTable[index]) == "table" and #SELF.toPlayEffectTable[index] > 0 then
		table.insert(SELF.effectFlash[index], {})
		-- for k,v in pairs(SELF.toPlayEffectTable[1])
		do
			playAttriChangeEffectWithIndex(SELF.toPlayEffectTable[index][1] , index)
		end
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(1))
		if index == 1 then
			actionArray:addObject(CCCallFuncN:create(removeLastFlashEffectWithIndex1))
		elseif index == 2 then
			actionArray:addObject(CCCallFuncN:create(removeLastFlashEffectWithIndex2))
		elseif index == 3 then
			actionArray:addObject(CCCallFuncN:create(removeLastFlashEffectWithIndex3))
		end
		-- actionArray:addObject(CCCallFuncN:create(removeLastFlashEffectWithIndex1))
		SELF:runAction(CCSequence:create(actionArray))
		table.remove(SELF.toPlayEffectTable[index], 1)
	end
end

onFlashEvent =  function(eventName)
	--print(eventName)

	local index = tonumber(string.sub(eventName , -1 , -1))

	if SELF.gameEnd then
		do return end
	end
	if eventName == "lastHit" then
		CanonPlayEffect("music/sfx_card_broken.wav")
	elseif eventName == "singleBattleEndEnemyDie"..index then
		for i=1,#SELF.enemyHpPB[index] do
			SELF.enemyHpPB[index][i]:setVisible(false)
		end
	elseif eventName == "singleBattleEndSelfDie"..index then
		for i=1,#SELF.selfHpPB[index] do
			SELF.selfHpPB[index][i]:setVisible(false)
		end
	end

	if eventName == "self_attack"..index or 
	eventName == "self_attack_miss"..index or 
	eventName == "self_attack_block"..index or 
	eventName == "self_attack_crit"..index or 
	eventName == "self_attack_counter"..index then
	eventNumCount = eventNumCount + 1
end

	if eventName == "enemy_attack"..index or 
	eventName == "enemy_attack_miss"..index or 
	eventName == "enemy_attack_block"..index or 
	eventName == "enemy_attack_crit"..index or 
	eventName == "enemy_attack_counter"..index then
	eventNumCount = eventNumCount + 1
end
	playNextEffectWithIndex(index)

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

function getNewCardMeta( cardInfo )
	local uid = cardInfo.uid
	local newMeta = CommonManager:getSelfAvatarMetaByUid( uid )
	if not newMeta then
		newMeta = cardInfo.metaId
	end
	return newMeta
end

function UnionBattleScene:addInBattlePlayerWithIndex( index , firstBattle )
	if not getBattleCardWithIndex(index) or self.inBattlePlayers[index] then
		return
	end

	local cardInfo = getBattleCardWithIndex(index)
	local card = getBigCanonCardForUnionBattle(getNewCardMeta(cardInfo))
	local posX , posY
	local hpPos
	local enemyHpPB
	local newIndex
	if index <= 3 then
		posY = 1280 - 767.4
		hpPos = -(225 + 15.5)
		hpBP = self.selfHpPB
		newIndex = index
	else
		posY = 767.4
		hpPos = (225 + 15.5)
		hpBP = self.enemyHpPB
		newIndex = index - 3
	end
	posX = (125.5 + ((index - 1) % 3) * 235) , 224
	card:setPosition(ccp(posX , posY))
	card:setScale(0.52)
	card:setVisible(false)
	if firstBattle then
		card:setVisible(true)
	end
	card:setZOrder(0)
	self:addChild(card)

	if hpBP[newIndex][4] then
		hpBP[newIndex][4]:removeFromParentAndCleanup(true)
		hpBP[newIndex][4] = nil
	end
	hpBP[newIndex][4] = CCProgressTimer:create(CCSprite:create(hpBarResPath))
	hpBP[newIndex][4]:setPosition(ccp(0, hpPos))
	hpBP[newIndex][4]:setType(kCCProgressTimerTypeBar);
	hpBP[newIndex][4]:setMidpoint(ccp(0,0))
	hpBP[newIndex][4]:setBarChangeRate(ccp(1, 0))
	hpBP[newIndex][4]:setPercentage(99.9)
	hpBP[newIndex][4]:setScale(320/257)
	local nickName = getUnionBattleCardInitData(index).nickName
	if nickName == nil then
		local cityId = UnionPkData.getBattleCityId()
		nickName = UnionPkUtils.getCityCardNpcNameById(cityId)
	end
	local aLabel = CCLabelTTF:create(tostring(nickName), "Helvetica", 28)
	aLabel:setAnchorPoint(ccp(0.5,0.5))
    aLabel:setPosition(nameLabelPosX, 14)
    hpBP[newIndex][4]:addChild(aLabel)

    local streakLabel = CCLabelTTF:create("0/"..getUnionBattleCardInitData(index).winLimit, "Helvetica", 28)
    streakLabel:setAnchorPoint(ccp(0.5,0.5))
    if index <= 3 then
    	streakLabel:setPosition(nameLabelPosX, -34)
    else
    	streakLabel:setPosition(nameLabelPosX, 54)
    end
    
    streakLabel:setTag(100)
    hpBP[newIndex][4]:addChild(streakLabel)
	-- hpBP[newIndex][4]:setScaleX(1.0)
	card:addChild(CocosObject.new(hpBP[newIndex][4]))
	self.inBattlePlayers[index] = card
end

function UnionBattleScene:addWaitPlayerWithIndex( index )
	if not getWaitCardWithIndex(index) or self.waitPlayers[index] then
		return
	end
	local cardInfo = getWaitCardWithIndex(index)
	local card = getBigCanonCardForUnionBattle(getNewCardMeta(cardInfo))
	local posX , posY
	local hpPos
	if index <= 3 then
		hpPos = -(225 + 15.5)
		posY = 1280 - 1080.5
	else
		hpPos = (225 + 15.5)
		posY = 1080.5
	end
	posX = (125.5 + ((index - 1) % 3) * 235) , 224
	card:setPosition(ccp(posX , posY))
	card:setScale(0.52)
	card:setZOrder(0)
	-- card:setVisible(false)
	self:addChild(card)
	-- table.insert(self.waitPlayers , card)
	if self.waitHpPB[index] then
		self.waitHpPB[index]:removeFromParentAndCleanup(true)
		self.waitHpPB[index] = nil
	end
	self.waitHpPB[index] = CCProgressTimer:create(CCSprite:create(hpBarResPath))
	self.waitHpPB[index]:setPosition(ccp(0, hpPos))
	self.waitHpPB[index]:setType(kCCProgressTimerTypeBar);
	self.waitHpPB[index]:setMidpoint(ccp(0,0))
	self.waitHpPB[index]:setBarChangeRate(ccp(1, 0))
	self.waitHpPB[index]:setPercentage(99.9)
	self.waitHpPB[index]:setScale(320/257)
	local nickName = getUnionWaitBattleCardInitData(index).nickName
	if nickName == nil then
		local cityId = UnionPkData.getBattleCityId()
		nickName = UnionPkUtils.getCityCardNpcNameById(cityId)
	end
	local aLabel = CCLabelTTF:create(tostring(nickName), "Helvetica", 28)
	aLabel:setAnchorPoint(ccp(0.5,0.5))
    aLabel:setPosition(nameLabelPosX, 14)
    self.waitHpPB[index]:addChild(aLabel)
    local streakLabel = CCLabelTTF:create("", "Helvetica", 28)
    streakLabel:setAnchorPoint(ccp(0.5,0.5))
    if index <= 3 then
    	streakLabel:setPosition(nameLabelPosX, -34)
    else
    	streakLabel:setPosition(nameLabelPosX, 54)
    end
    streakLabel:setTag(100)
    self.waitHpPB[index]:addChild(streakLabel)
	-- self.waitHpPB[index]:setScaleX(1.0)
	card:addChild(CocosObject.new(self.waitHpPB[index]))
	self.waitPlayers[index] = card
end

function UnionBattleScene:addWaitPlayerWithAnim( index )
	if not getWaitCardWithIndex(index) or self.waitPlayers[index] then
		return
	end
	local cardInfo = getWaitCardWithIndex(index)
	local card = getBigCanonCardForUnionBattle(getNewCardMeta(cardInfo))
	local posX , posY
	local dis = 200
	local hpPos
	if index <= 3 then
		dis = -dis
		hpPos = -(225 + 15.5)
		posY = 1280 - 1080.5 + dis
	else
		hpPos = (225 + 15.5)
		posY = 1080.5 + dis
	end
	posX = (125.5 + ((index - 1) % 3) * 235) , 224
	card:setPosition(ccp(posX , posY))

	local arr = CCArray:create()
  	arr:addObject(CCMoveBy:create(0.3, ccp(0, -dis)))
  	-- arr:addObject(CCCallFunc:create(actionFinished))
  	card:runAction(CCSequence:create(arr))

	card:setScale(0.52)
	if self.waitHpPB[index] then
		self.waitHpPB[index]:removeFromParentAndCleanup(true)
		self.waitHpPB[index] = nil
	end
	self.waitHpPB[index] = CCProgressTimer:create(CCSprite:create(hpBarResPath))
	self.waitHpPB[index]:setPosition(ccp(0, hpPos))
	self.waitHpPB[index]:setType(kCCProgressTimerTypeBar);
	self.waitHpPB[index]:setMidpoint(ccp(0,0))
	self.waitHpPB[index]:setBarChangeRate(ccp(1, 0))
	self.waitHpPB[index]:setPercentage(99.9)
	self.waitHpPB[index]:setScale(320/257)
	-- self.waitHpPB[index]:setScaleX(1.0)
	local nickName = getUnionWaitBattleCardInitData(index).nickName
	if nickName == nil then
		local cityId = UnionPkData.getBattleCityId()
		nickName = UnionPkUtils.getCityCardNpcNameById(cityId)
	end
	local aLabel = CCLabelTTF:create(tostring(nickName), "Helvetica", 28)
	aLabel:setAnchorPoint(ccp(0.5,0.5))
    aLabel:setPosition(nameLabelPosX, 14)
    self.waitHpPB[index]:addChild(aLabel)

    local streakLabel = CCLabelTTF:create("", "Helvetica", 28)
    streakLabel:setAnchorPoint(ccp(0.5,0.5))
    if index <= 3 then
    	streakLabel:setPosition(nameLabelPosX, -34)
    else
    	streakLabel:setPosition(nameLabelPosX, 54)
    end
    streakLabel:setTag(100)
    self.waitHpPB[index]:addChild(streakLabel)

	card:addChild(CocosObject.new(self.waitHpPB[index]))
	card:setZOrder(0)
	self:addChild(card)
	-- table.insert(self.waitPlayers , card)
	self.waitPlayers[index] = card
end

function UnionBattleScene:addBattleFlashWithIndex( index )
	if not getBattleCardWithIndex(index) or not getBattleCardWithIndex(index + 3) then
		return
	end
	self.fightPlayers[index] = true
	self.totalBattleNum = self.totalBattleNum + 1
	local emptySpriteFrame = createSpriteFrame("pic/empty.png")
	
	local function changeFlashCard(posId, metaId, amount, flash , HpBarIndex)
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

		local oneRound = self.unionBattleRounds[1]
		local winNums = string.split(oneRound.winNum , ',')

		if cardConfigData.card == "card1M" then
			self.selfHpPB[index][HpBarIndex] = CCProgressTimer:create(CCSprite:create(hpBarResPath))
			self.selfHpPB[index][HpBarIndex]:setPosition(ccp(100, 100))
			self.selfHpPB[index][HpBarIndex]:setType(kCCProgressTimerTypeBar);
			self.selfHpPB[index][HpBarIndex]:setMidpoint(ccp(0,0))
			self.selfHpPB[index][HpBarIndex]:setBarChangeRate(ccp(1, 0))
			self.selfHpPB[index][HpBarIndex]:setPercentage(self.selfHp[index] / self.selfMaxHp[index] * 100)
			self.selfHpPB[index][HpBarIndex]:setScaleX(1.0)
			local nickName = getUnionBattleCardInitData(index).nickName
			local aLabel = CCLabelTTF:create(tostring(nickName), "Helvetica", 28)
			aLabel:setAnchorPoint(ccp(0.5,0.5))
		    aLabel:setPosition(nameLabelPosX, 14)
		    self.selfHpPB[index][HpBarIndex]:addChild(aLabel)

		    local selfWinNum = tonumber(self.winNum[index])
		    -- if selfWinNum ~= 0 then
		    -- 	selfWinNum = selfWinNum - 1
		    -- end

		    local streakLabel = CCLabelTTF:create( selfWinNum.. "/" .. getUnionBattleCardInitData(index).winLimit, "Helvetica", 28)
		    streakLabel:setAnchorPoint(ccp(0.5,0.5))
		    streakLabel:setPosition(nameLabelPosX, -34)
		    streakLabel:setTag(100)
		    self.selfHpPB[index][HpBarIndex]:addChild(streakLabel)
			-- self:addChild(CocosObject.new(self.selfHpPB))

			flash:addUnionBattleInstance(cardConfigData.card.."_HpBar" , self.selfHpPB[index][HpBarIndex])
		elseif cardConfigData.card == "card2M" then
			self.enemyHpPB[index][HpBarIndex] = CCProgressTimer:create(CCSprite:create(hpBarResPath))
			self.enemyHpPB[index][HpBarIndex]:setPosition(ccp(100, 100))
			self.enemyHpPB[index][HpBarIndex]:setType(kCCProgressTimerTypeBar);
			self.enemyHpPB[index][HpBarIndex]:setMidpoint(ccp(0,0))
			self.enemyHpPB[index][HpBarIndex]:setBarChangeRate(ccp(1, 0))
			self.enemyHpPB[index][HpBarIndex]:setPercentage(self.enemyHp[index] / self.enemyMaxHp[index] * 100)
			self.enemyHpPB[index][HpBarIndex]:setScaleX(1.0)
			local nickName = getUnionBattleCardInitData(index + 3).nickName
			if nickName == nil then
				local cityId = UnionPkData.getBattleCityId()
				nickName = UnionPkUtils.getCityCardNpcNameById(cityId)
			end
			local aLabel = CCLabelTTF:create(tostring(nickName), "Helvetica", 28)
			aLabel:setAnchorPoint(ccp(0.5,0.5))
		    aLabel:setPosition(nameLabelPosX, 14)
		    self.enemyHpPB[index][HpBarIndex]:addChild(aLabel)

		    local enemyWinNum = tonumber(self.winNum[index + 3])
		    -- if enemyWinNum ~= 0 then
		    -- 	enemyWinNum = enemyWinNum - 1
		    -- end

		    local streakLabel = CCLabelTTF:create(enemyWinNum .. "/" .. getUnionBattleCardInitData(index + 3).winLimit, "Helvetica", 28)
		    streakLabel:setAnchorPoint(ccp(0.5,0.5))
		    streakLabel:setPosition(nameLabelPosX, 54)
		    streakLabel:setTag(100)
		    self.enemyHpPB[index][HpBarIndex]:addChild(streakLabel)

			flash:addUnionBattleInstance(cardConfigData.card.."_HpBar" , self.enemyHpPB[index][HpBarIndex])
		end
	end

	getAllBattlePlayersWeaponInfo()

	local selfMainData = getBattleCardWithIndex(index)
	local enemyMainData = getBattleCardWithIndex(index + 3)
	local cardNum = 1

	-- self.selfHp[index] = tonumber(selfMainData.hp) 
	-- self.selfMaxHp[index] = tonumber(selfMainData.hp) 
	-- self.enemyHp[index] = tonumber(enemyMainData.hp)
	-- self.enemyMaxHp[index] = tonumber(enemyMainData.hp) 

	--替换武将头像
	if DataManager.getCurrUser().uid == selfMainData.uid then
		local mainAvatarMetaId = CommonManager:getSelfAvatarMetaByCardId(selfMainData.cardId)
		if mainAvatarMetaId ~= 0 then
			selfMainData.metaId = mainAvatarMetaId
		end
	end

	--替换武将头像
	if DataManager.getCurrUser().uid == enemyMainData.uid then
		local mainAvatarMetaId = CommonManager:getSelfAvatarMetaByCardId(enemyMainData.cardId)
		if mainAvatarMetaId ~= 0 then
			enemyMainData.metaId = mainAvatarMetaId
		end
	end

	local selfAttackFlashName, selfFlashIndex = getSelfAttackFlash(self.WeaponInfo[index])
	self.selfFlashIndex[index] = selfFlashIndex
	self.self_attack_flash[index] = FlashSprite:create(selfAttackFlashName)
	if not addedBattleFlashTable[selfAttackFlashName] then
		self.self_attack_flash[index]:retain();
		addedBattleFlashTable[selfAttackFlashName] = true;
	end
	changeFlashCard(selfMainData.posId, selfMainData.metaId, cardNum, self.self_attack_flash[index] , 1)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, cardNum, self.self_attack_flash[index], 1)
	self.self_attack_flash[index]:changeAnimation(self.selfFlashIndex[index])
	self.self_attack_flash[index]:setLoop(false)
	self.self_attack_flash[index]:setIsRun(false)
	
	self.self_attack_flash[index]:registerFlashScriptHandler(onFlashEvent)
	self.self_attack_flash[index]:addFrameEvent("self_attack"..index, self.selfFlashIndex[index], 10)
	self.self_attack_flash[index]:addFrameEvent("self_attack_miss"..index, self.selfFlashIndex[index] + 9, 10)
	self.self_attack_flash[index]:addFrameEvent("self_attack_block"..index, self.selfFlashIndex[index] + 18, 6)
	self.self_attack_flash[index]:addFrameEvent("self_attack_crit"..index, self.selfFlashIndex[index] + 36, 6)
	self.self_attack_flash[index]:addFrameEvent("self_attack_counter"..index, 27, 8)


	local enemyAttackFlashName, enemyFlashIndex = getEnemyAttackFlash(self.WeaponInfo[index + 3])
	self.enemyFlashIndex[index] = enemyFlashIndex
	self.enemy_attack_flash[index] = FlashSprite:create(enemyAttackFlashName)
	if not addedBattleFlashTable[enemyAttackFlashName] then
		self.enemy_attack_flash[index]:retain();
		addedBattleFlashTable[enemyAttackFlashName] = true;
	end
	changeFlashCard(selfMainData.posId, selfMainData.metaId, cardNum, self.enemy_attack_flash[index], 2)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, cardNum, self.enemy_attack_flash[index], 2)
	self.enemy_attack_flash[index]:changeAnimation(self.enemyFlashIndex[index])
	self.enemy_attack_flash[index]:setLoop(false)
	self.enemy_attack_flash[index]:setIsRun(false)
	
	self.enemy_attack_flash[index]:registerFlashScriptHandler(onFlashEvent)
	self.enemy_attack_flash[index]:addFrameEvent("enemy_attack"..index, self.enemyFlashIndex[index], 10)
	self.enemy_attack_flash[index]:addFrameEvent("enemy_attack_miss"..index, self.enemyFlashIndex[index] + 9, 10)
	self.enemy_attack_flash[index]:addFrameEvent("enemy_attack_block"..index, self.enemyFlashIndex[index] + 18, 6)
	self.enemy_attack_flash[index]:addFrameEvent("enemy_attack_crit"..index, self.enemyFlashIndex[index] + 36, 6)
	self.enemy_attack_flash[index]:addFrameEvent("enemy_attack_counter"..index, 28, 8)

	self.self_attack_flash[index]:setScale(0.65)
	self.self_attack_flash[index]:setPosition((-114 + (index - 1) * 235) , 224)
	self.enemy_attack_flash[index]:setScale(0.65)
	self.enemy_attack_flash[index]:setPosition((-114 + (index - 1) * 235) , 224)
	if index == 1 then
		self.self_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex1)
		self.enemy_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex1)
	elseif index == 2 then
		self.self_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex2)
		self.enemy_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex2)
	elseif index == 3 then	
		self.self_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex3)
		self.enemy_attack_flash[index]:registerEndAnimationScriptHandler(onAttackFlashFinishWithIndex3)
	end

	self.self_attack_flash_co[index] = CocosObject.new(self.self_attack_flash[index])
	self:addChild(self.self_attack_flash_co[index])
	self.self_attack_flash_co[index]:setVisible(false)
	self.enemy_attack_flash_co[index] = CocosObject.new(self.enemy_attack_flash[index])
	self:addChild(self.enemy_attack_flash_co[index])
	self.enemy_attack_flash_co[index]:setVisible(false)

	self.battle_flash[index] = FlashSprite:create("battle/CardbattleXX3")

	changeFlashCard(selfMainData.posId, selfMainData.metaId, cardNum, self.battle_flash[index], 3)
	changeFlashCard(enemyMainData.posId, enemyMainData.metaId, cardNum, self.battle_flash[index], 3)

	self.battle_flash[index]:registerEndAnimationScriptHandler(onSingleBattleEnd)
	self.battle_flash[index]:registerFlashScriptHandler(onFlashEvent)
	self.battle_flash[index]:addFrameEvent("singleBattleEndEnemyDie"..index, 28, 17)
	self.battle_flash[index]:addFrameEvent("singleBattleEndSelfDie"..index, 30, 19)
		
	self.battle_flash[index]:changeAnimation(28)
	self.battle_flash[index]:setLoop(false)

	self.battle_flash[index]:setScale(0.65)
	self.battle_flash[index]:setPosition((-114 + (index - 1) * 235) , 224)

	self.battle_flash_co[index] = CocosObject.new(self.battle_flash[index])
	self:addChild(self.battle_flash_co[index])
	self.battle_flash_co[index]:setVisible(false)
end

local function realignUnionFightEventFlow()
	-- print(SELF.data.sharkUnionBattlefieldReport.unionBattleRounds.unionBattleEventFlow.eventFlow)
	SELF.unionFightEventFlowTable = {}
	for k,v in pairs(SELF.data.sharkUnionBattlefieldReport.unionBattleRounds) do
		local singleRoundEventFlowTable = {}
		for i=1,#v.unionBattleEventFlow do
			local unionBattleEventFlow = v.unionBattleEventFlow[i]
			local singlePlayerEventFlowTable = {}
			for j=1,#unionBattleEventFlow.eventFlow do
				local event = unionBattleEventFlow.eventFlow[j]
				local fightEvent = {}
				fightEvent.eventType = event.eventType
				fightEvent.round = event.round
				fightEvent.actionType = event.actionType
				if event.battleCardActs then
					fightEvent.posId = event.battleCardActs[1].posId
					fightEvent.skillId = event.battleCardActs[1].skillId
					fightEvent.effectId = event.battleCardActs[1].effectId
					fightEvent.changedValue = event.battleCardActs[1].changedValue
				end
				totalEventCount = totalEventCount + 1
				table.insert(singlePlayerEventFlowTable , fightEvent)
			end
			singleRoundEventFlowTable[v.unionBattleEventFlow[i].teamId] = singlePlayerEventFlowTable
			-- table.insert(singleRoundEventFlowTable , singlePlayerEventFlowTable)
		end
		table.insert(SELF.unionFightEventFlowTable , singleRoundEventFlowTable)
	end
	-- print(table.tostring(SELF.unionFightEventFlowTable))
end

function UnionBattleScene:setFlashVisiable( index , visiable )
	if self.battle_flash_co[index] then
		self.battle_flash_co[index]:setVisible(visiable)
	end

	if self.self_attack_flash_co[index] then
		self.self_attack_flash_co[index]:setVisible(visiable)
	end

	if self.enemy_attack_flash_co[index] then
		self.enemy_attack_flash_co[index]:setVisible(visiable)
	end

	if self.inBattlePlayers[index] then
		self.inBattlePlayers[index]:setVisible(not visiable)
		self.inBattlePlayers[index]:setZOrder(0)
	end
	if self.inBattlePlayers[index + 3] then
		self.inBattlePlayers[index + 3]:setVisible(not visiable)
		self.inBattlePlayers[index + 3]:setZOrder(0)
	end
	if self.waitPlayers[index] then
		self.waitPlayers[index]:setZOrder(0)
	end
	if self.waitPlayers[index + 3] then
		self.waitPlayers[index + 3]:setZOrder(0)
	end
end

function UnionBattleScene:removeFlashWithIndex( index )
	if not self.self_attack_flash_co[index] or not self.enemy_attack_flash_co[index] or not self.battle_flash_co[index] then
		return 
	end
	self.battle_flash_co[index]:removeFromParentAndCleanup(true)
	self.self_attack_flash_co[index]:removeFromParentAndCleanup(true)
	self.enemy_attack_flash_co[index]:removeFromParentAndCleanup(true)
	self.battle_flash_co[index] = nil
	self.self_attack_flash_co[index] = nil
	self.enemy_attack_flash_co[index] = nil
end

function UnionBattleScene:firstBattle()
	local oneRoundData = SELF.unionBattleRounds[1]

	local function changeLine(  )
		if oneRoundData.changePosition ~= nil then
			local changePosition = string.split(oneRoundData.changePosition , ',')
			local from = tonumber(changePosition[1])
			local to = tonumber(changePosition[2])
			SELF.unionCardIninDataList[to] = SELF.unionCardIninDataList[from]
			SELF.unionCardIninDataList[from] = {}
			moveBattleLine(from , to , oneRoundData)
		else
			afterMoveBattleLine(oneRoundData)
		end
	end

	local buffids = string.split(oneRoundData.buffId , ',')
	local function playBuffFlash( index )
		for i=index,6 do
			if tonumber(buffids[i]) ~= 0 then
				local fspt = FlashSprite:create("battle/popo_up_word")
				fspt:setLoop(false)
				fspt:changeAnimation(i + 7)
				local fspt_co = CocosObject.new(fspt)
				local function onBattleFlashAnimationEnd(anim)
					fspt:unregisterEndAnimationScriptHandler()
					SELF:removeChild(fspt_co)
					--Set_ShareData( "Cloud_Finished", 1 )
					SELF.fspt = nil;
					local isSelf 
					if i > 3 then
						isSelf = false
					else
						isSelf = true
					end
					changeBuff(tonumber(buffids[i]) , isSelf)
					playBuffFlash(i + 1)
				end
				SELF.fspt = fspt
				fspt:registerEndAnimationScriptHandler(onBattleFlashAnimationEnd)
				fspt_co:setZOrder(100)
				SELF:addChild(fspt_co)
				return
			end
		end
		changeLine()
	end
	playBuffFlash(1)

	-- if oneRoundData.changePosition ~= nil then
	-- 	local changePosition = string.split(oneRoundData.changePosition , ',')
	-- 	local from = tonumber(changePosition[1])
	-- 	local to = tonumber(changePosition[2])
	-- 	SELF.unionCardIninDataList[to] = SELF.unionCardIninDataList[from]
	-- 	SELF.unionCardIninDataList[from] = {}
	-- 	moveBattleLine(from , to , oneRoundData , true)
	-- else
	-- 	self:addSingleRoundBattleFlash(true)
	-- end
end

function UnionBattleScene:initUI(  )
	local bgSprite = Sprite:create("battle/unionBattleRes/bg_guildpk.png")
	bgSprite:setAnchorPoint(ccp(0,0))
	-- bgSprite:setPosition(ccp(360,640))
	self:addChild(bgSprite)

	local selfAttIcon = Sprite:create("battle/unionBattleRes/lbl_attack.png")
	selfAttIcon:setPosition(ccp(44.5 , 17.5))
	self:addChild(selfAttIcon)
	local enemyAttIcon = Sprite:create("battle/unionBattleRes/lbl_defensive.png")
	enemyAttIcon:setPosition(ccp(44.5 , 1255.5))
	self:addChild(enemyAttIcon)

	local attriPath = {"battle/unionBattleRes/icon_atk.png" , "battle/unionBattleRes/icon_def.png" , "battle/unionBattleRes/icon_hp.png"}
	local attriPosX = {388,504,620.5}
	local attriPosY = {21.5 , 1257.5}

	for i=1,3 do
		for j=1,2 do
			local icon = Sprite:create(attriPath[i])
			icon:setPosition(ccp(attriPosX[i] , attriPosY[j]))
			self:addChild(icon)
			if j == 1 then
				self.selfAttrValueLabel[i] = CCLabelTTF:create("+"..self.selfAttrIncreaseValue[i].."%", "Helvetica", 24)
			    self.selfAttrValueLabel[i]:setPosition(attriPosX[i] + 19 , attriPosY[j])
			    self:addChild(CocosObject.new(self.selfAttrValueLabel[i]))
			    self.selfAttrValueLabel[i]:setAnchorPoint(ccp(0, 0.5))
			else
				self.enemyAttrValueLabel[i] = CCLabelTTF:create("+"..self.enemyAttrIncreaseValue[i].."%", "Helvetica", 24)
			    self.enemyAttrValueLabel[i]:setPosition(attriPosX[i] + 19 , attriPosY[j])
			    self:addChild(CocosObject.new(self.enemyAttrValueLabel[i]))
			    self.enemyAttrValueLabel[i]:setAnchorPoint(ccp(0, 0.5))
			end
		end
	end

	self.selfUnionName = tostring(self.data.sharkUnionBattlefieldReport.attackUnionName)
	self.enemyUnionName = tostring(self.data.sharkUnionBattlefieldReport.defenseUnionName)

	if self.data.sharkUnionBattlefieldReport.defenseUnionName == nil or self.data.sharkUnionBattlefieldReport.defenseUnionName == "" then
		local cityId = UnionPkData.getBattleCityId()
		self.enemyUnionName = UnionPkUtils.getCityNpcNameById(cityId)
	end

	self.selfUnionTotalPlayers = 0
	self.selfUnionPlayers = 0
	self.enemyUnionPlayers = 0
	self.enemyUnionTotalPlayers = 0
	for index=1,3 do
		if self.unionCardIninDataList[index].unionBattleCardInitDatas ~= nil then
			self.selfUnionTotalPlayers = self.selfUnionTotalPlayers + #self.unionCardIninDataList[index].unionBattleCardInitDatas
		end
		if self.unionCardIninDataList[index + 3].unionBattleCardInitDatas ~= nil then
			self.enemyUnionTotalPlayers = self.enemyUnionTotalPlayers + #self.unionCardIninDataList[index + 3].unionBattleCardInitDatas
		end
	end
	self.selfUnionPlayers = self.selfUnionTotalPlayers
	self.enemyUnionPlayers = self.enemyUnionTotalPlayers

	self.selfUnionLabel = ArtLabelTTF:create(self.selfUnionName.." "..(self.selfUnionTotalPlayers.."/"..self.selfUnionTotalPlayers),nil,30)
	self.selfUnionLabel:setCenterColor(ccc3(255,252,0))
	self.selfUnionLabel:setAroundColor(ccc3(99,0,0))
	self.selfUnionLabel:setTextAnchorPoint(ccp(0,0.5))
	self.selfUnionLabel:setPosition(82,selfAttIcon:getPositionY())
	self.selfUnionLabel:construct()
	self:addChild(CocosObject.new(self.selfUnionLabel))

	self.enemyUnionLabel = ArtLabelTTF:create(self.enemyUnionName.." "..(self.enemyUnionTotalPlayers.."/"..self.enemyUnionTotalPlayers),nil,30)
	self.enemyUnionLabel:setCenterColor(ccc3(0,255,252))
	self.enemyUnionLabel:setAroundColor(ccc3(99,0,0))
	self.enemyUnionLabel:setTextAnchorPoint(ccp(0,0.5))
	self.enemyUnionLabel:setPosition(82,enemyAttIcon:getPositionY())
	self.enemyUnionLabel:construct()
	self:addChild(CocosObject.new(self.enemyUnionLabel))
end


function UnionBattleScene:onInit()
	--整理数据
	totalEventCount = 0
	self.unionCardIninDataList = self.data.sharkUnionBattlefieldReport.unionBattleCardDatas
	self.unionBattleRounds = self.data.sharkUnionBattlefieldReport.unionBattleRounds
	realignUnionFightEventFlow()

	self.finishedPlayerNum = 0
	self.totalBattleNum = 0
	self.inBattlePlayers = {}
	self.waitPlayers = {}
	self.enterBattleFieldPlayers = {}
	self.deadPlayers = {}
	self.leavePlayers = {}
	self.fightPlayers = {}

	self.selfFlashIndex = {}
	self.self_attack_flash = {}
	self.self_attack_flash_co = {}
	self.enemyFlashIndex = {}
	self.enemy_attack_flash = {}
	self.enemy_attack_flash_co = {}
	self.toPlayEffectTable = {}
	self.selfHp = {}
	self.enemyHp= {}
	self.selfMaxHp = {}
	self.enemyMaxHp= {}
	self.effectFlash = {}

	self.winNum = {0,0,0,0,0,0}

	local attGemInspireNum = self.data.sharkUnionBattlefieldReport.attGemInspireNum or 0
	local defGemInspireNum = self.data.sharkUnionBattlefieldReport.defGemInspireNum or 0

	self.selfAttrIncreaseValue = {getFloatNumber(UnionPkConfig.goldBuff()) * attGemInspireNum,0,0}
	self.enemyAttrIncreaseValue = {getFloatNumber(UnionPkConfig.goldBuff()) * defGemInspireNum,0,0}
	self.selfAttrValueLabel = {}
	self.enemyAttrValueLabel = {}

	self.selfHpPB = {}
	self.enemyHpPB = {}
	self.selfWinningStreak = {}
	self.enemyWinningStreak = {}
	for i=1,3 do
		self.selfHpPB[i] = {}
		self.enemyHpPB[i] = {}
		self.selfWinningStreak[i] = {}
		self.enemyWinningStreak[i] = {}
	end

	self.waitHpPB = {}
	for i=1,3 do
		self.effectFlash[i] = {}
	end

	self.battle_flash = {}
	self.battle_flash_co = {}

	enterBattleFieldPlayersNum = 0
	leaveBattleFieldPlayersNum = 0
	eventNumCount = 0

	self:initUI()

	for index=1,3 do
		for i=1,3 do
			self.selfHpPB[index][i] = nil
			self.enemyHpPB[index][i] = nil
		end
	end
	
	for i=1,6 do
		self:addWaitPlayerWithIndex(i)
		self:addInBattlePlayerWithIndex(i , true)
	end

	
	--云雾动画
	local fspt = FlashSprite:create("map/others/flashPack/Cloud")
	fspt:changeAnimation(1)
	fspt:setLoop(false)
	local fspt_co = CocosObject.new(fspt)
	local function onCloudFlashAnimationEnd(anim)
		fspt:unregisterEndAnimationScriptHandler()
		self:removeChild(fspt_co)
		--Set_ShareData( "Cloud_Finished", 1 )
		self.fspt = nil;
		local unionWordFspt = FlashSprite:create("battle/UnionBattleWord")
		unionWordFspt:changeAnimation(0)
		unionWordFspt:setLoop(false)
		local unionWordFspt_co = CocosObject.new(unionWordFspt)
		local function onUnionWordFlashAnimationEnd(anim)
			unionWordFspt:unregisterEndAnimationScriptHandler()
			self:removeChild(unionWordFspt_co)
			--Set_ShareData( "Cloud_Finished", 1 )
			self.unionWordFspt = nil;
			--播放单挑结算动画
			local isSelf 
			local buffID
			local fspt2 = FlashSprite:create("battle/popo_up_word")
			if self.argv.winLevel == SINGLEBATTLEWINTYPE.SELF_WIN then
				fspt2:changeAnimation(4)
				isSelf = true
				buffID = 1
			elseif self.argv.winLevel == SINGLEBATTLEWINTYPE.SELF_BIG_WIN then
				fspt2:changeAnimation(6)
				isSelf = true
				buffID = 2
			elseif self.argv.winLevel == SINGLEBATTLEWINTYPE.ENEMY_WIN then
				fspt2:changeAnimation(5)
				isSelf = false
				buffID = 1
			elseif self.argv.winLevel == SINGLEBATTLEWINTYPE.ENEMY_BIG_WIN then
				fspt2:changeAnimation(7)
				isSelf = false
				buffID = 2
			end
			fspt2:setLoop(false)
			local fspt2_co = CocosObject.new(fspt2)
			local function onBattleFlashAnimationEnd(anim)
				fspt2:unregisterEndAnimationScriptHandler()
				self:removeChild(fspt2_co)
				--Set_ShareData( "Cloud_Finished", 1 )
				self.fspt2 = nil;
				changeBuff(buffID , isSelf)
				self:firstBattle()
			end
			self.fspt2 = fspt2
			fspt2:registerEndAnimationScriptHandler(onBattleFlashAnimationEnd)
			self:addChild(fspt2_co)
		end
		self.unionWordFspt = unionWordFspt
		unionWordFspt:registerEndAnimationScriptHandler(onUnionWordFlashAnimationEnd)
		self:addChild(unionWordFspt_co)
	end
	self.fspt = fspt
	fspt:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
	self:addChild(fspt_co)

	local function addSkipButtonInBattle()
		local skipSprite = Sprite:create("battle/pic/skip_active.png")
		skipSprite:setAnchorPoint(ccp(1, 0))
		skipSprite:setPosition(ccp(720, 0))
		self:addChild(skipSprite)
		self.skipButtonSprite = skipSprite
		
		local function onSkipClick( evt )
			Director:sharedDirector():replaceScene( MainMenuScene:create() )
		end
		
		local skipButton = Button:create(skipSprite)
		skipButton:addEventListener( Events.kStart, onSkipClick )
		self.skipButton = skipButton
	end

	-- addSkipButtonInBattle()
end