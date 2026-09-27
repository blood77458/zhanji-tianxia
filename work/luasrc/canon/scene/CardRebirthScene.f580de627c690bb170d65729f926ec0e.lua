require "canon.request.ItemRebirthRequest"
require "canon.request.ItemSacrificeRequest"
require "canon.request.SplitCardRequest"
require "canon.scene.PracticeSelectScene"
require "canon.features.treasureSystem.TreasureSystem"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local lastTab = nil

local function getRecordTableLen(recordTable, maxLen)
	local result = 0
	for i = 1, maxLen do
		if recordTable[i] then
			result = result + 1
		end
	end
	return result
end

CardRebirthScene = class(BaseUIScene)

function CardRebirthScene:ctor()
	self.title = getTextByKey("home_sacrificeBtn")
	self.mainUI = {}
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.tabButton = {}
	self.picCard = {}
	self.picInfo = {}
end

function CardRebirthScene:create(argv)
	local scene = CardRebirthScene.new()
	scene.argv = argv
	scene:initScene()
	return scene
end

function CardRebirthScene:onInit()
	BaseUIScene.initBackGround(self)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/the_practice.json")
	self.uiBuilder.useArtLabelTTF = true
	self.topMenu = self.uiBuilder:build("bg_background")
	self:addChild(self.topMenu)

	local tabButton = {"btn_thepractice", "btn_rebirth", "btn_rebirth2"}
	local tabTextChildName = {"txt_thepractice", "txt_thepractice", "txt"}
	local tabTextKey = {"home_sacrificeBtn", "rebirth_rebirthTab", "cardSplit_title"}
	local tabPage = {"rebirth_smelting", "rebirth_combination", "rebirth_break"}
	local cardIcon = {"stove_combination", "stove_combination", "stove_combination"}
	local runButton = {"thepractice_btn_go", "btn_go", "btn_go"}
	for i = 1, 3 do
		local tab = self.topMenu:getChildByName(tabButton[i])
		tab:getChildByName(tabTextChildName[i]):setString(getTextByKey(tabTextKey[i]))
		self.tabPicActive[i] = tab:getChildByName("btn")
		self.tabPicInActive[i] = tab:getChildByName("disable")
		self.tabButton[i] = Button:create(tab)
		local function onClick()
			if i == 3 then
				if DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().cardResolveUnlockLevel then
					SuspensionLabel:showContent(self, Localization:getInstance():getText("cardSplit_prompt", {num = MetaManager.getGameSettingConfig().cardResolveUnlockLevel}))
					return
				end
			end
			self.cardData = nil
			self:showTab(i)
		end
		self.tabButton[i]:addEventListener(Events.kStart, onClick)
		self.tabButton[i]:setEnable(i ~= 1)
		self.tabPicActive[i]:setVisible(i == 1)
		self.tabPicInActive[i]:setVisible(i ~= 1)

		self.mainUI[i] = self.uiBuilder:build(tabPage[i])
		self:addChild(self.mainUI[i])

		if i == 1 then
			self.picCard[i] = {}
			for j = 1, 5 do
				self.mainUI[i]:getChildByName("lbl_thePractice_forFirst"..j):setVisible(false)

				self.picCard[i][j] = self.mainUI[i]:getChildByName(cardIcon[i] .. j)
				local btnCard = Button:create(self.picCard[i][j])
				local function onClickCard(e)
					self:onClickSelectForPractice(e.context)
				end
				btnCard:addEventListener(Events.kStart, onClickCard, j)
				self.picInfo[j] = self.mainUI[i]:getChildByName("angle_level" .. j)
			end
		else
			self.picCard[i] = self.mainUI[i]:getChildByName(cardIcon[i])
			local btnCard = Button:create(self.picCard[i])
			local function onClickCard()
				if self.rebirthSwitch == TreasureSystemConsts.RebirthSwitch_Card or self.currentTab == 3 then
					self:onClickSelectCard()
				else
					self:onClickSelectTreasure()
				end
			end
			btnCard:addEventListener(Events.kStart, onClickCard)
		end
		
		local picRun = self.mainUI[i]:getChildByName(runButton[i])
		if i == 1 then
			local function onClickRun()
				self:runSacrifice()
			end
      		self.sacrificeButton = Button:create(picRun)
			self.sacrificeButton:addEventListener(Events.kStart, onClickRun)
		elseif i == 2 then
			local function onClickRun()
				if not self.cardData.avatarMetaId then
					self:runRebirthWithTreasure()
				else
					self:runRebirth()
				end
			end
      		self.rebirthButton = Button:create(picRun)
			self.rebirthButton:addEventListener(Events.kStart, onClickRun)
		else
			local function onClickRun()
				self:runBreak()
			end
      		self.breakButton = Button:create(picRun)
			self.breakButton:addEventListener(Events.kStart, onClickRun)
		end
		self.mainUI[i]:getChildByName("common_reward_item"):setVisible(false)
	end

	self.flashPosList = {}
	self.flashPosList[1] = ccp(0,0)
	local aBaseUI = self.mainUI[1]:getChildByName("stove_combination1")
	for i = 2, 5 do
		local aUI = self.mainUI[1]:getChildByName("stove_combination" .. i)
		self.flashPosList[i] = ccp(aUI:getPositionX() - aBaseUI:getPositionX(), aUI:getPositionY() - aBaseUI:getPositionY())
	end

	local btnShop = Button:create(self.mainUI[1]:getChildByName("icon_shopmysterious"))
	local function onClickShop()
		self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_SecretShop", enterScene = "CardRebirthScene", returnScene = "CardRebirthScene"})
	end
	btnShop:addEventListener(Events.kStart, onClickShop)
	local btnEnchant = Button:create(self.mainUI[1]:getChildByName("icon_enchant"))
	local function onClickEnchant()
		self:replaceScene(BackpackScene, {params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}})
	end
	btnEnchant:addEventListener(Events.kStart, onClickEnchant)
	local btnCardRecommend = Button:create(self.mainUI[1]:getChildByName("btn_smelting_recommended_1"))
	local function onClickCardRecommend()
		local allPracticeCardData = PracticeSelectScene.getParcticeCardData()
		local aNum = #allPracticeCardData
		if aNum == 0 then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("sacrifice_tips1"))
			return
		end
		if aNum > 5 then
			aNum = 5
		end
		self.cardData = {dataType = "card", data = {}}
		for i = 1, aNum do
			self.cardData.data[i] = allPracticeCardData[i]
		end
		self:refreshCard()
		self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc"))
	end
	btnCardRecommend:addEventListener(Events.kStart, onClickCardRecommend)
	local btnEquipRecommend = Button:create(self.mainUI[1]:getChildByName("btn_smelting_recommended_2"))
	local function onClickEquipRecommend()
		local allPracticeEquipData = PracticeSelectScene.getPracticeEquipData()
		local aNum = #allPracticeEquipData
		if aNum == 0 then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("sacrifice_tips"))
			return
		end
		if aNum > 5 then
			aNum = 5
		end
		self.cardData = {dataType = "equip", data = {}}
		for i = 1, aNum do
			self.cardData.data[i] = allPracticeEquipData[i]
		end
		self:refreshCard()
		self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc2"))
	end
	btnEquipRecommend:addEventListener(Events.kStart, onClickEquipRecommend)

	local btnTreasureRecommend = Button:create(self.mainUI[1]:getChildByName("btn_smelting_recommended_3"))
	local function onClickTreasureRecommend()
		if not TreasureManager.isUserLevelEnough() then
			local aContent = Localization:getInstance():getText("Treasure_text_37" , {num = TreasureManager.getTreasureUserLevel()})
 			SuspensionLabel:showContent(self, aContent)
 			return
		end
		local allPracticeTreasureData = PracticeSelectScene.getPracticeTreasureData()
		local aNum = #allPracticeTreasureData
		if aNum == 0 then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("Treasure_tips_1"))
			return
		end
		if aNum > 5 then
			aNum = 5
		end
		self.cardData = {dataType = "treasure", data = {}}
		for i = 1, aNum do
			self.cardData.data[i] = allPracticeTreasureData[i]
		end
		self:refreshCard()
		self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("Treasure_text_5"))
	end
	btnTreasureRecommend:addEventListener(Events.kStart, onClickTreasureRecommend)

	self.mainUI[1]:getChildByName("txt_thepractice2"):getChildByName("txt"):setString(getTextByKey("sacrifice_preview"))
	self.mainUI[1]:getChildByName("btn_smelting_recommended_1"):getChildByName("txt"):setString(getTextByKey("sacrifice_title"))
	self.mainUI[1]:getChildByName("btn_smelting_recommended_2"):getChildByName("txt"):setString(getTextByKey("sacrifice_title1"))
	self.mainUI[1]:getChildByName("btn_smelting_recommended_3"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_11"))
	self.mainUI[2]:getChildByName("txt_rebirth1"):getChildByName("txt"):setString(getTextByKey("rebirth_cost"))
	self.mainUI[2]:getChildByName("txt_rebirth3"):getChildByName("txt"):setString(getTextByKey("rebirth_preview"))
	self.mainUI[2]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("rebirth_desc"))
	self.mainUI[3]:getChildByName("txt_rebirth1"):getChildByName("txt"):setString(getTextByKey("cardSplit_cost"))
	self.mainUI[3]:getChildByName("txt_rebirth3"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips1"))
	self.mainUI[3]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips2"))

	--重生界面switch按钮
	self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("gallery_cardTab"))
	self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_4"))
	self.rebirthSwitch = TreasureSystemConsts.RebirthSwitch_Card;
	local btnRebirthSwitch = Button:create(self.mainUI[2]:getChildByName("ResetSwitch"))
	local function onClickSwitch()
		if not TreasureManager.isUserLevelEnough() then
			local aContent = Localization:getInstance():getText("Treasure_text_37" , {num = TreasureManager.getTreasureUserLevel()})
 			SuspensionLabel:showContent(self, aContent)
 			return
		end
		if self.rebirthSwitch == TreasureSystemConsts.RebirthSwitch_Card then
			self.rebirthSwitch = TreasureSystemConsts.RebirthSwitch_Treasure
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch1"):setVisible(false)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch2"):setVisible(true)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_2"):setVisible(true)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_1"):setVisible(false)

			self.mainUI[2]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("Treasure_text_22"))
		else
			self.rebirthSwitch = TreasureSystemConsts.RebirthSwitch_Card
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch1"):setVisible(true)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch2"):setVisible(false)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_2"):setVisible(false)
			self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_1"):setVisible(true)

			self.mainUI[2]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("rebirth_desc"))
		end
	end
	btnRebirthSwitch:addEventListener(Events.kStart, onClickSwitch)
	
	--分解界面添加跳转炼魂按钮
	local gotoSoulBtn = Button:create(self.mainUI[3]:getChildByName("icon_soul"))
	local function onGotoSoulBtnClick(e)
		self:replaceScene(FragmentScene)
	end
	gotoSoulBtn:addEventListener(Events.kStart, onGotoSoulBtnClick)

    --从背包进入
    if self.argv and self.argv.enterScene=="PracticeSelectScene" then
    	self.cardData = self.argv.params
    elseif self.argv and self.argv.enterScene=="BackpackScene" and self.argv.params then
		for i,v in ipairs(DataManager.getCardsData()) do
			if v.cardId == self.argv.params.cardId then
				self.cardData = v
				break
			end
		end
		self.rebirthSwitch = TreasureSystemConsts.RebirthSwitch_Card
	elseif self.argv and self.argv.enterScene=="TreasureBackpackScene" and self.argv.params then
		self.cardData = self.argv.params
		self.rebirthSwitch = TreasureSystemConsts.RebirthSwitch_Treasure
	elseif self.argv and self.argv.params and self.argv.params.showPanelIndex then
		lastTab = self.argv.params.showPanelIndex
	else
		lastTab = nil
    end

    if self.rebirthSwitch == TreasureSystemConsts.RebirthSwitch_Card then
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch1"):setVisible(true)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch2"):setVisible(false)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_2"):setVisible(false)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_1"):setVisible(true)

		self.mainUI[2]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("rebirth_desc"))
	else
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch1"):setVisible(false)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("ResetSwitch2"):setVisible(true)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_2"):setVisible(true)
		self.mainUI[2]:getChildByName("ResetSwitch"):getChildByName("txt_1"):setVisible(false)

		self.mainUI[2]:getChildByName("txt_rebirth4"):getChildByName("txt"):setString(getTextByKey("Treasure_text_22"))
	end

	self.currentTab = 0

	BaseUIScene.onInit(self)
end

function CardRebirthScene:back()
	if self.argv and self.argv.returnScene == "ActivityPanelScene" then
		self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_SecretShop"})
	elseif self.argv and self.argv.returnScene == "Activity_ExchangeDailyLayer" then
		self:replaceScene(ActivityPanelScene,{selectPanelName = "Activity_ExchangeDaily"})
	else
		self:replaceScene(MainMenuScene)
	end
end

function CardRebirthScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function CardRebirthScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CardRebirthScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:setPositionX(self.topMenu:getPositionX() - visibleSize.width)
	self.topMenu:runAction(CCSequence:create(arr))
	local tab = lastTab or 1
	self.mainUI[tab]:setPositionX(-visibleSize.width)
	self.mainUI[tab]:runAction(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
	self:showTab(tab)

	if tab == 1 then
		if (not self.cardData) or  (getRecordTableLen(self.cardData.data, 5) == 0) then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc1"))
		elseif self.cardData.dataType == "card" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc"))
		elseif self.cardData.dataType == "equip" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc2"))
		elseif self.cardData.dataType == "treasure" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("Treasure_text_5"))
		end
	end
end

function CardRebirthScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	if (tonumber(Get_ShareData( "Sacrifice_Guide_Running")) ~= 1) and (not IsGuideExecuted(GuideConfig.kSacrifice)) then
		Set_ShareData( "Sacrifice_Guide_Running", 1 );	--设置一个标志，用于在背包中使用假数据
  		ExeNewGuide( GuideConfig.kSacrifice )	--执行祭练附灵的引导
  	end
end

function CardRebirthScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:runAction(CCSequence:create(arr))
	self.mainUI[self.currentTab]:runAction(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	self.currentTab = 0
end

function CardRebirthScene:setTableViewsEnabledInner(v)
	if self.listView then
		self.listView:setTouchEnabled(v)
	end
end

function CardRebirthScene:showTab(tabIndex)
	self.currentTab = tabIndex
	self:refreshCard()
	for i = 1, 3 do
		self.mainUI[i]:setVisible(i == tabIndex)
		self.tabPicActive[i]:setVisible(i == tabIndex)
		self.tabPicInActive[i]:setVisible(i ~= tabIndex)
		self.tabButton[i]:setEnable(i ~= tabIndex)
	end
	lastTab = nil
end

function CardRebirthScene:onClickSelectForPractice(aIndex)
	if self.cardData and self.cardData.data and self.cardData.data[aIndex] then
		self.cardData.data[aIndex] = nil
		self:refreshCard()
		if (not self.cardData) or  (getRecordTableLen(self.cardData.data, 5) == 0) then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc1"))
		elseif self.cardData.dataType == "card" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc"))
		elseif self.cardData.dataType == "equip" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("sacrifice_desc2"))
		elseif self.cardData.dataType == "treasure" then
			self.mainUI[1]:getChildByName("txt_thepractice1"):getChildByName("txt"):setString(getTextByKey("Treasure_text_5"))
		end
	else
		self:replaceScene(PracticeSelectScene, {practiceData = self.cardData})
	end
end

function CardRebirthScene:onClickSelectTreasure(e)
	local function filterCardFunc( treasureList )
		local result = {}
		for _, v in pairs (treasureList) do
			if v.cardId == 0 and v.level > 1 then
				table.insert(result , v)
			end
		end
			--宝物阵容状态
		local queueList = {}
		local gameData = DataManager.getGameInitData()
		for BattleArrayId = 1,3 do
			local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
			for k,v in pairs(quedata) do
				queueList[v.treasureId] = true
			end	
		end
		for i = #result,1,-1 do
			if queueList[result[i].treasureId] == true then
				table.remove(result , i)
			end
		end	
		
		return result
	end

	local argv = {enterScene="CardRebirthScene",returnScene="CardRebirthScene",params={
		filterFunc = filterCardFunc,
	}}
	lastTab = self.currentTab
	self:replaceScene( TreasureBackpackScene , argv)
end

function CardRebirthScene:onClickSelectCard(e)
	local currentTab = self.currentTab
	local function filterCardFunc( cardList )
		local queueList = {}
		for k,v in pairs(CommonManager.getQueueData()) do
			queueList[v] = true
		end
		for k,v in pairs(CommonManager:getMatrixCardData()) do
			queueList[v] = true
		end
		--阵容状态（不可重生和分解）
		local gameData = DataManager.getGameInitData()
		for BattleArrayId = 1,3 do
			local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
			local matdata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices and 
							gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices or {} 			
			for k,v in pairs(quedata) do
				if v.cardId then queueList[v.cardId] = true end
			end
			for k,v in pairs(matdata) do
				if not v.sharkMatrixGrids then v.sharkMatrixGrids = {} end				
				for _,value in pairs(v.sharkMatrixGrids) do
					if value.cardId then queueList[value.cardId] = true end
				end		
			end			
		end
		--end by l1ghtsaber
		local result = {}
		local filterOriginCard = currentTab == 1
		for k,card in pairs(cardList) do
			if (not card.lock) and (not queueList[card.cardId]) then
				if ((currentTab == 1) and (MetaManager.card_meta[card.metaId].astralEssence > 0)) or (currentTab == 2) then
					local origin = true
					if card.level > 1 or card.exp > 0 or card.usedPotential > 0 then
						origin = false
					elseif card.cardSkills then
						for i,v in ipairs(card.cardSkills) do
							if v.skillId and MetaManager.skill_meta[v.skillId] and MetaManager.skill_meta[v.skillId].level > 1 then
								origin = false
								break
							end
						end
					end
					if origin == filterOriginCard then
						table.insert(result, card)
					end
				elseif currentTab == 3 then
					if (MetaManager.card_meta[card.metaId].evolutionLevel > 1) and (MetaManager.card_meta[card.metaId].rare > MetaManager.game_meta.gameSettingConfig.cardResolveCardLevel) 
						or (card.metaId == 106011 or card.metaId == 106021 or card.metaId == 106031) then
						--新需要 小玉可拆解 所以用metaid找出小玉卡牌
						table.insert(result, card)
					end
				end
			end
		end
		return result
	end
	local argv = {enterScene="CardRebirthScene",returnScene="CardRebirthScene",params={
		cardType="mainCard",filter=BACKPACK_FILTER.CARD,filterFunc = filterCardFunc, sortOrder = SORT_ORDER.DESC,sortIndex = 2, isCardTrain = false, selectedTab = currentTab
	}}
	lastTab = self.currentTab
	self:replaceScene( BackpackScene , argv)
end

function CardRebirthScene:addParticle(cardCell)
  if self.cardParticle ~= nil then
    self.cardParticle:removeFromParentAndCleanup(true)
    self.cardParticle = nil
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

function CardRebirthScene:refreshCard()
	if not self.mainUI[self.currentTab] then
		return
	end
	local reward = {}
	--如果有粒子先移除！
	self.alreadyAddPartice = false
	if self.cardParticle ~= nil then
		self.cardParticle:removeFromParentAndCleanup(true)
		self.cardParticle = nil
	end
	if self.iconCard then
		if self.iconCard.refCocosObj then
			self.iconCard:removeFromParentAndCleanup(true)
		else
			for _, aIconCard in pairs(self.iconCard) do
				aIconCard:removeFromParentAndCleanup(true)
			end
		end
		self.iconCard = nil
	end
	for _, aPicInfo in pairs(self.picInfo) do
		aPicInfo:setVisible(false)
	end
  local aCurrentButton
  if self.currentTab == 1 then
    aCurrentButton = self.sacrificeButton

  	for i=1,5 do
		self.mainUI[self.currentTab]:getChildByName("lbl_thePractice_forFirst"..i):setVisible(false)
	end
  elseif self.currentTab == 2 then
    aCurrentButton = self.rebirthButton
   else
   	aCurrentButton = self.breakButton
  end
	if self.cardData then
		local function addDataIcon(aIcon, aParent)
			local size = aParent:getGroupBounds().size
			aIcon:setPosition(ccp(size.width/2 + 3, -size.height/2 - 3))
			aParent:addChild(aIcon)
		end
		if self.currentTab == 1 then
			self.iconCard = {}
			for aIndex, aData in pairs(self.cardData.data) do
				self.picInfo[aIndex]:setVisible(true)
				if self.cardData.dataType == "card" then
					self.iconCard[aIndex] = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo(aData))
					self.picInfo[aIndex]:getChildByName("txt_name"):setVisible(false)
					self.picInfo[aIndex]:getChildByName("q_transparent20_gray9_pic"):setVisible(false)
					self.picInfo[aIndex]:getChildByName("txt_level"):getChildByName("txt"):setString("lv" .. aData.level)
				elseif self.cardData.dataType == "equip" then
					self.iconCard[aIndex] = CanonItem:create()
					self.iconCard[aIndex]:loadByMetaId(aData.metaId)
					self.iconCard[aIndex]:setScale(0.9)
					self.picInfo[aIndex]:getChildByName("txt_name"):setVisible(true)
					self.picInfo[aIndex]:getChildByName("q_transparent20_gray9_pic"):setVisible(true)
					self.picInfo[aIndex]:getChildByName("txt_level"):getChildByName("txt"):setString("lv" .. aData.level)
					self.picInfo[aIndex]:getChildByName("txt_name"):getChildByName("txt"):setString(getTextByKey(MetaManager.equip_meta[aData.metaId].name))
				elseif self.cardData.dataType == "treasure" then
					self.iconCard[aIndex] = CanonItem:create()
					self.iconCard[aIndex]:loadByMetaId(aData.metaId)
					self.iconCard[aIndex]:setScale(0.9)
	  	
					if TreasureSystemCheck.CheckIsDayFirstRebirth() and not self.alreadyAddPartice and MetaManager.treasure_meta[aData.metaId].rare < 3 then
						self.alreadyAddPartice = true
						self:addParticle(self.iconCard[aIndex])
						self.mainUI[self.currentTab]:getChildByName("lbl_thePractice_forFirst"..aIndex):setVisible(true)
					end
			
					self.picInfo[aIndex]:getChildByName("txt_name"):setVisible(true)
					self.picInfo[aIndex]:getChildByName("q_transparent20_gray9_pic"):setVisible(true)
					self.picInfo[aIndex]:getChildByName("txt_level"):getChildByName("txt"):setString("lv" .. aData.level)
					self.picInfo[aIndex]:getChildByName("txt_name"):getChildByName("txt"):setString(getTextByKey(MetaManager.treasure_meta[aData.metaId].name))
				end
				local picCard = self.picCard[self.currentTab][aIndex]
				addDataIcon(self.iconCard[aIndex], picCard)
			end
		elseif self.currentTab == 2 then
			if not self.cardData.avatarMetaId then
				self.iconCard = CanonItem:create()
				self.iconCard:loadByMetaId(self.cardData.metaId)
				self.iconCard:setScale(0.9)
				local picCard = self.picCard[self.currentTab]
				addDataIcon(self.iconCard, picCard)
			else
				self.iconCard = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( self.cardData ))
				local picCard = self.picCard[self.currentTab]
				addDataIcon(self.iconCard, picCard)
			end
		else
			self.iconCard = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( self.cardData ))
			local picCard = self.picCard[self.currentTab]
			addDataIcon(self.iconCard, picCard)
		end
		
		if self.currentTab == 1 then
			reward = self:getSacrificeReward(self.cardData)
		elseif self.currentTab == 2 then
			if not self.cardData.avatarMetaId then
				reward = self:getRebirthRewardWithTreasure(self.cardData)
			else
				reward = self:getRebirthReward(self.cardData)
			end
		else
			reward = self:getBreakReward(self.cardData)
		end
		if self.currentTab ~= 1 then
			if self.currentTab == 2 and not self.cardData.avatarMetaId then
				self.mainUI[self.currentTab]:getChildByName("txt_reward1"):getChildByName("txt"):setString(getTextByKey(MetaManager.treasure_meta[self.cardData.metaId].name))
			else
				self.mainUI[self.currentTab]:getChildByName("txt_reward1"):getChildByName("txt"):setString(getTextByKey(MetaManager.card_meta[self.cardData.metaId].name))
			end
			
    	end
	    aCurrentButton:setEnable(true)
	    aCurrentButton.display:getChildByName("txt"):setVisible(true)
	    aCurrentButton.display:getChildByName("btn_go_bg"):setVisible(true)
	    aCurrentButton.display:getChildByName("txt_inactive"):setVisible(false)
	    aCurrentButton.display:getChildByName("btn_go_inactive"):setVisible(false)
	    if self.currentTab == 3 then
	    	self.mainUI[3]:getChildByName("txt_rebirth4"):setVisible(false)
			if self.cardResolveConfig.isXiaoyu then
				self.mainUI[3]:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips10", {num = self.cardResolveConfig.resolveNum}))
				self.mainUI[3]:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips12"))
			else
				self.mainUI[3]:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips5", {num = self.cardResolveConfig.resolveNum}))
				self.mainUI[3]:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("cardSplit_tips6"))
			end
		end
	else
		if self.currentTab ~= 1 then
			self.mainUI[self.currentTab]:getChildByName("txt_reward1"):getChildByName("txt"):setString("")
    	end
	    aCurrentButton:setEnable(false)
	    aCurrentButton.display:getChildByName("txt"):setVisible(false)
	    aCurrentButton.display:getChildByName("btn_go_bg"):setVisible(false)
	    aCurrentButton.display:getChildByName("txt_inactive"):setVisible(true)
	    aCurrentButton.display:getChildByName("btn_go_inactive"):setVisible(true)

	    if self.currentTab == 3 then
	    	self.mainUI[3]:getChildByName("txt_01"):setVisible(false)
	    	self.mainUI[3]:getChildByName("txt_02"):setVisible(false)
	    	self.mainUI[3]:getChildByName("txt_rebirth4"):setVisible(true)
	    end
	end
	if self.listView then
		self.listView:removeFromParentAndCleanup(true)
		self.listView = nil
	end
	
	if #reward == 0 then
		self.mainUI[self.currentTab]:getChildByName("common_reward_item"):setVisible(false)
	else
		self.mainUI[self.currentTab]:getChildByName("common_reward_item"):setVisible(false)
		RewardListViewRender = class(TableViewRenderer)
		function RewardListViewRender:ctor()
			self.list = {}
		end
		function RewardListViewRender:buildCell(container)
			local cell = self.container.uiBuilder:build("sb/common_reward_item")
			cell:setPosition(ccp(0, 138))
			cell:getChildByName("common_normal_card_small_sb"):setVisible(false)
			cell:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setHorizontalAlignment(kCCTextAlignmentCenter)
			local tagTree = {common_normal_card_small_sb = 101, common_txt_item_quantity = {102, txt_item_quantity=201}, common_txt_item_name = {103, txt_item_name=201}, bg_small_number = 104, txt_level = {105, txt = 201}}
			setCCNodeTagTree(cell, tagTree)
			cell:setTag(111)
			container:addChild(cell)
		end
		function RewardListViewRender:setData(rawCocosObj, index)
			local cell = rawCocosObj:getChildByTag(111)
			local oldIcon = cell:getChildByTag(110)
			if oldIcon then
				cell:removeChild(oldIcon, true)
			end
			local item = reward[index+1]
			if item then
				local icon = CanonGoodIcon.createGoodIconByPackageRewardInfo(item, {sourceDisplay=cell:getChildByTag(101), container = cell, zindex = 1})
				if icon  then
					icon:setTag(110)
				end
		        if math.modf(item.amount/100000000) > 0 then
		          setNodeText(cell:getChildByTag(102):getChildByTag(201), "" .. item.amount)
		        else
		          setNodeText(cell:getChildByTag(102):getChildByTag(201), "x" .. item.amount)
		        end
				setNodeText(cell:getChildByTag(103):getChildByTag(201), CanonGoodIcon.getGoodNameByPackageRewardInfo(item, {withoutAmount = true}))
				if item.extraParams and item.extraParams.showCardLevel then
					cell:getChildByTag(104):setVisible(true)
					cell:getChildByTag(105):setVisible(true)
					setNodeText(cell:getChildByTag(105):getChildByTag(201), "Lv." .. item.extraParams.cardLevel)
				else
					cell:getChildByTag(104):setVisible(false)
					cell:getChildByTag(105):setVisible(false)
				end
			end
		end
		local render = RewardListViewRender.new(130, 138)
		render.container = self
		render.list = reward
		self.listView = TableView:create(render, 646, 138, 111)
		self.listView:setPosition(ccp(37, 210))
		self.listView:setDirection(kCCScrollViewDirectionHorizontal)
		self.mainUI[self.currentTab]:addChildAt(self.listView, 1)
		self.listView:reloadData()
	end
	
	if self.currentTab == 2 then
		if self.cardData then
			if not self.cardData.avatarMetaId then
				local cost = MetaManager.treasure_star[MetaManager.treasure_meta[self.cardData.metaId].rare].rebirthCost
				self.mainUI[2]:getChildByName("txt_rebirth2"):getChildByName("txt"):setString(tostring(cost))
			else
				local cost = MetaManager.card_rare[MetaManager.card_meta[self.cardData.metaId].rare].rebirthCost
				self.mainUI[2]:getChildByName("txt_rebirth2"):getChildByName("txt"):setString(tostring(cost))
			end
			
		else
			self.mainUI[2]:getChildByName("txt_rebirth2"):getChildByName("txt"):setString("0")
		end
	elseif self.currentTab == 3 then
		if self.cardData then
			local cost = self.cardResolveConfig.goldConsume
			self.mainUI[3]:getChildByName("txt_rebirth2"):getChildByName("txt"):setString(tostring(cost))
		else
			self.mainUI[3]:getChildByName("txt_rebirth2"):getChildByName("txt"):setString("0")
		end
	end
	
	if self.currentTab ~= 3 then
		local arrow = {self.mainUI[self.currentTab]:getChildByName("icon_sliding_l"), self.mainUI[self.currentTab]:getChildByName("icon_sliding_r")}
		if #reward > 5 then
			for i,v in ipairs(arrow) do
				v:setVisible(true)
				v:setOpacity(0)
				local fadein = CCFadeIn:create(0.6)
				v:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(fadein, fadein:reverse())))
			end
		else
			for i,v in ipairs(arrow) do
				v:setVisible(false)
			end
		end
	end
end

function CardRebirthScene:getBreakReward(card)
	local reward = {}
	if (card.metaId == 106011 or card.metaId == 106021 or card.metaId == 106031) then
		--新需要 小玉可拆解 所以用metaid找出小玉卡牌 单独的分解配置表
		for k,v in pairs(MetaManager.card_resolve_setting) do
			if v.cardId == card.metaId  then
				self.cardResolveConfig = {goldConsume = v.itemNum1,isXiaoyu = true,resolveNum = v.itemNum2,metaId = v.itemId2}
				table.insert(reward, {itemType = ResourceEnum.CARD_FRAGMENT, metaId = v.itemId2, amount = v.itemNum2})
			end
		end
		return reward
	end
	local aCardCoef
	local intValue
	local fractionValue
	local function searchResolveConfig(aValue)
		intValue, fractionValue = math.modf(aValue / MetaManager.card_meta[card.metaId].reviseATT)
		aCardCoef = intValue + ((fractionValue >= 0.5) and 1 or 0)
		local cardEvolveLevel = MetaManager.card_meta[self.cardData.metaId].evolutionLevel
		for _, aCardResolveConfig in pairs(MetaManager.card_resolve) do
			if (aCardResolveConfig.cardCoef == aCardCoef) and (aCardResolveConfig.cardOrder == cardEvolveLevel) then
				return aCardResolveConfig
			end
		end
		return nil
	end
	self.cardResolveConfig = searchResolveConfig(card.attEvolveValue)
	if not self.cardResolveConfig then
		self.cardResolveConfig = searchResolveConfig(card.attEvolveValue + 1)
	end
	
	if self.cardResolveConfig.silverBack > 0 then
		table.insert(reward, {itemType = ResourceEnum.COIN, metaId = 0, amount = self.cardResolveConfig.silverBack})
	end
	if self.cardResolveConfig.expBack > 0 then
		table.insert(reward, {itemType = ResourceEnum.GENERALEXP, metaId = 0, amount = self.cardResolveConfig.expBack})
	end
	self.newCardMetaId = math.modf(card.metaId / 10) * 10 + 1
	table.insert(reward, {itemType = ResourceEnum.CARD, metaId = self.newCardMetaId, amount = self.cardResolveConfig.resolveNum - 1, extraParams = {showCardLevel = true, cardLevel = 1}})
	table.insert(reward, {itemType = ResourceEnum.CARD, metaId = self.newCardMetaId, amount = 1, extraParams = {showCardLevel = true, cardLevel = card.level}})
	return reward
end

function CardRebirthScene:getRebirthRewardWithTreasure( treasure )
	local reward = {}
	local coin = 0
	local lv = treasure.level
	for i=1,lv-1 do
		coin = coin + MetaManager.treasure_strengthen[i].treasureUpCoin
	end
	if coin > 0 then
		coin = coin * TreasureSystemConfig.getTreasureSettingConfig().treasureRenascence / 100
		table.insert(reward, 1, {itemType = ResourceEnum.COIN, metaId = 0, amount = coin})
	end
	return reward
end

function CardRebirthScene:getRebirthReward(card)
	local reward = {}
	local coin = 0
	local rewardExp = MetaManager.card_level[card.level].totalExp + card.exp
	if rewardExp > 0 then
		local totalExp = MetaManager.card_level[card.level].totalExp + card.exp
		table.insert(reward, {itemType = ResourceEnum.GENERALEXP, metaId = 0, amount = totalExp})
		coin = coin + totalExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise
	end
	local soulStone = math.floor(card.usedPotential * MetaManager.getGameSettingConfig().rebirthConfig.rebirthSoulstoneReturnRate)
	if soulStone > 0 then
		table.insert(reward, {itemType = ResourceEnum.PROP, metaId = MetaManager.getCardTrainConfig().pydMetaId, amount = soulStone})
	end

	if not self.bookTable then
		self.bookTable = {}
		for k,v in pairs(MetaManager.prop_meta) do
			if v.effectType == 8 and v.effectValue <= MetaManager.getGameSettingConfig().rebirthConfig.rebirthSkillBookMaxValue then
				table.insert(self.bookTable, v)
			end
		end
		local function bookSort(a, b)
			return a.effectValue > b.effectValue
		end
		table.sort(self.bookTable, bookSort)
	end
	local bookNum = {}
	for i,v in ipairs(card.cardSkills) do
		local skillMeta = MetaManager.skill_meta[v.skillId]
		if skillMeta.level > 1 then
			local skillNum = 0
			for iskill, vskill in pairs(MetaManager.skill_meta) do
				if vskill.skillGroupId == skillMeta.skillGroupId and vskill.level < skillMeta.level then
					coin = coin + vskill.coin
					local needValue = math.floor(vskill.upgradeValue * MetaManager.getGameSettingConfig().rebirthConfig.rebirthSkillBookReturnRate)
					for i,v in ipairs(self.bookTable) do
						if needValue >= v.effectValue then
							local num = math.floor(needValue / v.effectValue)
							needValue = needValue - num * v.effectValue
							bookNum[i] = (bookNum[i] or 0) + num
						end
					end
					skillNum = skillNum + 1
					if skillNum >= skillMeta.level-1 then
						break;
					end
				end
			end
		end
	end
	for i,v in ipairs(self.bookTable) do
		if bookNum[i] then
			table.insert(reward, {itemType = ResourceEnum.PROP, metaId = v.id, amount = bookNum[i]})
		end
	end
	if coin > 0 then
		table.insert(reward, 1, {itemType = ResourceEnum.COIN, metaId = 0, amount = coin})
	end
	return reward
end

local function addProp(propTable, propId, propAmount)
	if propAmount == 0 then
		return
	end
	local existed = false
	for _, aProp in ipairs(propTable) do
		if aProp.propId == propId then
			aProp.propAmount = aProp.propAmount + propAmount
			existed = true
			break
		end
	end
	if not existed then
		table.insert(propTable, {propId = propId, propAmount = propAmount})
	end
end

local scaleCoefficient = 1000

function CardRebirthScene:getSacrificeReward(card)
	local result
	if self.cardData.dataType == "card" then
		local astralEssenceNum = 0
		for aIndex, aData in pairs(self.cardData.data) do
			astralEssenceNum = astralEssenceNum + MetaManager.card_meta[aData.metaId].astralEssence
		end
		if astralEssenceNum > 0 then
			result = {{itemType = ResourceEnum.ASTRALESSENCE, metaId = 0, amount = astralEssenceNum}}
		else
			result = {}
		end
	elseif self.cardData.dataType == "equip" then
		local propTable = {}
		local totalCoin = 0
		local equipSpiritNum = 0
		local gameSettingConfig = MetaManager.game_meta.gameSettingConfig
		for aIndex, aData in pairs(self.cardData.data) do
			local aCoin1 = 0
			for i = 1, aData.level - 1 do
				local aNewCoin = math.floor(MetaManager.equip_meta[aData.metaId].coinConsumeCoe * MetaManager.equip_level[i].upgradeCoinBase)
				--print(i .. "__" .. aNewCoin)
				aCoin1 = aCoin1 + aNewCoin
			end
			local aCoin2 = 0
			local aValue1 = math.modf(aData.metaId / 10)
			local aValue2 = math.mod(aData.metaId, 10)
			for i = 1, aValue2 - 1 do
				local aEquipEvolveConfig = MetaManager.equip_evolve[aValue1 * 10 + i]
				aCoin2 = aCoin2 + aEquipEvolveConfig.coins
				addProp(propTable, aEquipEvolveConfig.propId1, aEquipEvolveConfig.propAmount1)
				for j = 2, 5 do
					addProp(propTable, aEquipEvolveConfig["propId" .. j], math.floor(aEquipEvolveConfig["propAmount" .. j] * gameSettingConfig.equipSpiritMaterial / scaleCoefficient))
				end
			end
			local aCoin = math.floor((aCoin1 + aCoin2) * gameSettingConfig.equipSpiritSilver / scaleCoefficient)
			totalCoin = totalCoin + aCoin
			local baseSpiritNum = 0
			for _, aEquipSpiritValueConfig in pairs(MetaManager.equip_spirit_value) do
				if (aEquipSpiritValueConfig.equipRolex == MetaManager.equip_meta[aData.metaId].quality) and (MetaManager.equip_meta[aData.metaId].position == aEquipSpiritValueConfig.itemPosition) then
					baseSpiritNum = aEquipSpiritValueConfig.spiritValue
					break
				end
			end
			--[[
			print(table.tostring(aData))
			print(aData.enchantNum)
			]]
			local aSpiritNum = baseSpiritNum + math.floor(aData.enchantNum * gameSettingConfig.equipSpiritValue / scaleCoefficient)
			equipSpiritNum = equipSpiritNum + aSpiritNum
		end
		result = {}
		if equipSpiritNum > 0 then
			table.insert(result, {itemType = ResourceEnum.ENCHANT_POINT, metaId = 0, amount = equipSpiritNum})
		end
		if totalCoin > 0 then
			table.insert(result, {itemType = ResourceEnum.COIN, metaId = 0, amount = totalCoin})
		end
		for _, aProp in ipairs(propTable) do
			table.insert(result, {itemType = ResourceEnum.PROP, metaId = aProp.propId, amount = aProp.propAmount})
		end
	elseif self.cardData.dataType == "treasure" then
		local astralEssenceNum = 0
		local isFirst = TreasureSystemCheck.CheckIsDayFirstRebirth()
		for aIndex, aData in pairs(self.cardData.data) do
			if isFirst and MetaManager.treasure_meta[aData.metaId].rare < 3 then
				astralEssenceNum = astralEssenceNum + MetaManager.treasure_meta[aData.metaId].astralEssence * 2
				isFirst = false
			else
				astralEssenceNum = astralEssenceNum + MetaManager.treasure_meta[aData.metaId].astralEssence
			end
		end
		if astralEssenceNum > 0 then
			result = {{itemType = ResourceEnum.TREASURE_FRAGMENT, metaId = 0, amount = astralEssenceNum}}
		else
			result = {}
		end
	end
	return result
end
function CardRebirthScene:runBreak()
	if not self.cardData then
		return
	end
	if BagCalcManager.isFull() and not self.cardResolveConfig.isXiaoyu then
		NewPackageFullPanel:show()
		return
	end
	local gems = CalculationManager.calcComplex_getGemsNow()
	local needGems = self.cardResolveConfig.goldConsume
	if gems < needGems then
		local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
		self:addChild(aPanel)
		aPanel:scaleIn()
		return
	end
	local cardData = self.cardData
	local cardMeta = MetaManager.card_meta[cardData.metaId]
	local function onClickOK()
		local function splitCardSucceed(e)
			if e and e.data and e.data.rewards then
				local title = getTextByKey("cardSplit_tips4", {num = getTextByKey(cardMeta.name)})
				local text = getTextByKey("rebirth_success_text")
				local tempRewards = {}
				for _, aReward in ipairs(e.data.rewards) do
					table.insert(tempRewards, aReward)
				end
				if not self.cardResolveConfig.isXiaoyu then
					local aNewCard = {}
					aNewCard.itemType = ResourceEnum.CARD
					aNewCard.metaId = self.newCardMetaId
					aNewCard.amount = 1
					aNewCard.level = cardData.level
					table.insert(tempRewards, aNewCard)
				end
				local rewardPanel = GetRewardInfoPanel:create(self, tempRewards, nil, {titleText = title, openText = text, showCardLevel = true})
				PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
				RewardManager:getReward(e.data.rewards)
			end
			RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -needGems}})
			local GameData = DataManager.getGameInitData()
			for k,v in pairs(GameData.sharkCards.sharkCards) do
				if v.cardId == cardData.cardId then
					if self.cardResolveConfig.isXiaoyu then
						--小玉分解出魂 不是 卡牌，所以直接把原卡牌干掉
						table.remove(GameData.sharkCards.sharkCards,k)
					else
						v.metaId = self.newCardMetaId
					end
					
					break
				end
			end
						
			DataManager.setGameInitData(GameData)
			CommonManager:setCardNeedUpdate({cardData.cardId})
			self.cardData = nil
			self:refreshCard()
		end
		local function splitCardFailed(e)
			if e.data == 716932 then
				local aContent = Localization:getInstance():getText("cardSplit_error1")
     			SuspensionLabel:showContent(self, aContent)
				return
			end
			local function closeCanonMessageBox()
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = SplitCardRequest.new({cardId = self.cardData.cardId}, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.SplitCardSucceed, splitCardSucceed)
		request:addEventListener(RequestNotifyEnum.SplitCardFailed, splitCardFailed)
		request:start()
	end
	local messageText
	if self.cardResolveConfig.isXiaoyu then
		messageText = getTextByKey("cardSplit_tips11", {num1 = needGems, name1 = getTextByKey(cardMeta.name), num2 = self.cardResolveConfig.resolveNum, name2 = CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, self.cardResolveConfig.metaId, 1, {withoutAmount = true})})
	else
		messageText = getTextByKey("cardSplit_tips3", {num1 = needGems, num2 = getTextByKey(cardMeta.name), num3 = self.cardResolveConfig.resolveNum, num4 = getTextByKey(MetaManager.card_meta[self.newCardMetaId].name)})
	end
	self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, messageText, {text = getTextByKey("cardSplit_button"), callbackFunc = onClickOK})
end

function CardRebirthScene:runRebirthWithTreasure()
	if not self.cardData then
		return
	end
	local gems = CalculationManager.calcComplex_getGemsNow()
	local needGems = MetaManager.treasure_star[MetaManager.treasure_meta[self.cardData.metaId].rare].rebirthCost
	if gems < needGems then
		local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
		self:addChild(aPanel)
		aPanel:scaleIn()
		return
	end

	local function onClickOK()
		local function onRebirthSucceed(e)
			if e and e.data and e.data.rewards then
				local title = getTextByKey("Treasure_text_27")
				local text = getTextByKey("rebirth_success_text")
				local rewardPanel = GetRewardInfoPanel:create(self, e.data.rewards, nil, {titleText = title, openText = text})
				PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
				RewardManager:getReward(e.data.rewards)
			end
			RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -needGems}})
			local GameData = DataManager.getGameInitData()
			for k,v in pairs(GameData.sharkTreasures.sharkTreasures) do
				if v.treasureId == self.cardData.treasureId then
						v.level = 1
						-- v.exp = 0
						-- v.addPotential = 0
						-- v.addGemPotential = 0
						-- v.usedPotential = 0
					break
				end
			end
			DataManager.setGameInitData(GameData)
			-- CommonManager:setCardNeedUpdate({cardData.cardId})
			self.cardData = nil
			self:refreshCard()
		end

		SplitTreasureRequest.sendRequestDefalut(self.cardData.treasureId ,onRebirthSucceed)
	end
	local messageText = getTextByKey("Treasure_text_24", {num = needGems})
	self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, messageText, {text = getTextByKey("rebirth_rebirthTab"), callbackFunc = onClickOK})
end

function CardRebirthScene:runRebirth()
	if not self.cardData then
		return
	end
	local cardData = self.cardData
	local cardMeta = MetaManager.card_meta[cardData.metaId]
	if BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		return
	end
	local gems = CalculationManager.calcComplex_getGemsNow()
	local needGems = MetaManager.card_rare[cardMeta.rare].rebirthCost
	if gems < needGems then
		local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
		self:addChild(aPanel)
		aPanel:scaleIn()
		return
	end
	local function onClickOK()
		local function onRebirthSucceed(e)
			if e and e.data and e.data.rewards then
				local title = getTextByKey("rebirth_success_title", {cardname = getTextByKey(cardMeta.name)})
				local text = getTextByKey("rebirth_success_text")
				local rewardPanel = GetRewardInfoPanel:create(self, e.data.rewards, nil, {titleText = title, openText = text})
				PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
				RewardManager:getReward(e.data.rewards)
			end
			RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -needGems}})
			local GameData = DataManager.getGameInitData()
			for k,v in pairs(GameData.sharkCards.sharkCards) do
				if v.cardId == cardData.cardId then
						v.level = 1
						v.exp = 0
						v.usedPotential = 0
						v.attTrainValue = 0
						v.defTrainValue = 0
						v.hpTrainValue = 0
						v.cardSkills = generateCard(0, v.metaId, 1, 0).cardSkills
					break
				end
			end
			DataManager.setGameInitData(GameData)
			CommonManager:setCardNeedUpdate({cardData.cardId})
			self.cardData = nil
			self:refreshCard()
		end
		local function onRebirthFailed(e)
			local function closeCanonMessageBox()
			end
			if e.data == 710516 then
				NewPackageFullPanel:show()
				return
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = ItemRebirthRequest.new({resourceType = ResourceEnum.CARD, resourceId = cardData.cardId}, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.ItemRebirthSucceed, onRebirthSucceed)
		request:addEventListener(RequestNotifyEnum.ItemRebirthFailed, onRebirthFailed)
		request:start()
	end
	local messageText = getTextByKey("rebirth_confirmText", {num = needGems, cardname = getTextByKey(cardMeta.name)})
	self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, messageText, {text = getTextByKey("rebirth_rebirthTab"), callbackFunc = onClickOK})
end

local sacrifice_reward_order = {[6] = 1, [5] = 2, [18] = 3, [17] = 4, [26] = 5, [22] = 6, [1] = 7, [7] = 8}
function CardRebirthScene:runSacrifice()
	if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
		local reward = self:getSacrificeReward(self.cardData)
		local title = getTextByKey("sacrifice_success_title")
		local text = getTextByKey("exchange_text1")
		local rewardPanel = GetRewardInfoPanel:create(self, reward, nil, {titleText = title, openText = text})
		PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
		self.cardData = nil
		self:refreshCard()
		return
	end
	if (not self.cardData) or (getRecordTableLen(self.cardData.data, 5) == 0) then
		SuspensionLabel:showContent(self, Localization:getInstance():getText("sacrifice_tips2"))
		return
	end
	if BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		return
	end
	local function onClickOK()
		local function onSacrificeSucceed(e)
			local function flashPlayFinished()
				if e and e.data and e.data.rewards then
					local title = getTextByKey("sacrifice_success_title")
					local text = getTextByKey("exchange_text1")
					local function sortFunc( a , b )
						return sacrifice_reward_order[a.itemType] < sacrifice_reward_order[b.itemType]
					end
					table.sort( e.data.rewards,sortFunc )
					local rewardPanel = GetRewardInfoPanel:create(self, e.data.rewards, nil, {titleText = title, openText = text})
					PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
					RewardManager:getReward(e.data.rewards)
				end
				local GameData = DataManager.getGameInitData()
				if self.cardData.dataType == "card" then
					local tempCards = {}
					for k,v in pairs(GameData.sharkCards.sharkCards) do
						local existed = false
						for _, aData in pairs(self.cardData.data) do
							if v.cardId == aData.cardId then
								existed = true
								break
							end
						end
						if not existed then
							table.insert(tempCards, v)
						end
					end
					GameData.sharkCards.sharkCards = tempCards
				elseif self.cardData.dataType == "equip" then
					local tempEquips = {}
					for k,v in pairs(GameData.sharkEquips.sharkEquips) do
						local existed = false
						for _, aData in pairs(self.cardData.data) do
							if v.equipId == aData.equipId then
								existed = true
								break
							end
						end
						if not existed then
							table.insert(tempEquips, v)
						end
					end
					GameData.sharkEquips.sharkEquips = tempEquips
				elseif self.cardData.dataType == "treasure" then
					local tempTreasures = {}
					for k,v in pairs(GameData.sharkTreasures.sharkTreasures) do
						local existed = false
						for _, aData in pairs(self.cardData.data) do
							if v.treasureId == aData.treasureId then
								existed = true
								break
							end
						end
						if not existed then
							table.insert(tempTreasures, v)
						end
					end
					GameData.sharkTreasures.sharkTreasures = tempTreasures
				end
				DataManager.setGameInitData(GameData)

				local function checkFirstTreasureRebirth()
					for _, aData in pairs(self.cardData.data) do
						if MetaManager.treasure_meta[aData.metaId].rare < 3 then
							return true
						end
					end
					return false
				end

				if self.cardData.dataType == "treasure" and checkFirstTreasureRebirth() then
					DailyDataManager.setTreasureSacrificeTimes(DailyDataManager.getTreasureSacrificeTimes() + 1)
				end
				self.cardData = nil
				self:refreshCard()
			end
			local aTempLayer = Layer:create()
		    aTempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
		    self:addChild(aTempLayer)
		    self.listView:setTouchEnabled(false)
		    local aFlag = getRecordTableLen(self.cardData.data, 5)
			for i = 1, 5 do
				if self.cardData.data[i] then
					local fspt = FlashSprite:create("EVO2/sacrifice")
				    fspt:changeAnimation(0)
				    fspt:setLoop(false)
				    local fspt_co = CocosObject.new(fspt)
				    fspt:setPosition(self.flashPosList[i].x, self.flashPosList[i].y)
				    self:addChild(fspt_co)
				    local function flashEnd(anim)
					    fspt:unregisterEndAnimationScriptHandler()
					    aFlag = aFlag - 1
					    if aFlag == 0 then
					    	aTempLayer:removeFromParentAndCleanup(true)
					    	self.listView:setTouchEnabled(true)
					    	flashPlayFinished()
					    end
					end
					fspt:registerEndAnimationScriptHandler(flashEnd)
				end
			end
		end
		local function onSacrificeFailed(e)
			local function closeCanonMessageBox()
			end
			if e.data == 710516 then
				NewPackageFullPanel:show()
				return
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local resourceType
		local idName
		if self.cardData.dataType == "card" then
			resourceType = ResourceEnum.CARD
			idName = "cardId"
		elseif self.cardData.dataType == "equip" then
			resourceType = ResourceEnum.EQUIP
			idName = "equipId"
		elseif self.cardData.dataType == "treasure" then
			resourceType = ResourceEnum.TREASURE
			idName = "treasureId"
		end
		local idList = {}
		for _, aData in pairs(self.cardData.data) do
			table.insert(idList, aData[idName])
		end
		--print(table.tostring(idList))
		local request = ItemSacrificeRequest.new({resourceType = resourceType, resourceIds = idList}, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.ItemSacrificeSucceed, onSacrificeSucceed)
		request:addEventListener(RequestNotifyEnum.ItemSacrificeFailed, onSacrificeFailed)
		request:start()
	end
	for _, aData in pairs(self.cardData.data) do
		if self.cardData.dataType == "card" then
			if MetaManager.card_meta[aData.metaId].rare >= 5 then
				self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("sacrifice_tips5"), {text = getTextByKey("yes"), callbackFunc = onClickOK})
				return
			end
		elseif self.cardData.dataType == "equip" then
			if MetaManager.equip_meta[aData.metaId].quality >= 5 then
				self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("sacrifice_tips4"), {text = getTextByKey("yes"), callbackFunc = onClickOK})
				return
			end
		elseif self.cardData.dataType == "treasure" then
			if MetaManager.treasure_meta[aData.metaId].rare >= 3 then
				self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("Treasure_text_25"), {text = getTextByKey("yes"), callbackFunc = onClickOK})
				return
			end
		end
	end
	onClickOK()
end
