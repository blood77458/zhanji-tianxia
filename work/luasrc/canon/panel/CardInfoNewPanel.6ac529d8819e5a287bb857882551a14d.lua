require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"
require "canon.request.LockCardRequest"
require "canon.panel.CardSelectPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function setTextByTag( cell, tagList, str)
	local txt = cell
	for _, aTag in ipairs(tagList) do
		txt = txt:getChildByTag(aTag)
	end
	setNodeText(txt, str)
end

local function setNodeVisibleByTag(cell, tagList, visible)
	local txt = cell
	for _, aTag in ipairs(tagList) do
		txt = txt:getChildByTag(aTag)
	end
	txt:setVisible(visible)
end

local function inArea(posX, posY, rect)
	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
		return true
	end
	return false
end

local function getCardInfoFromInitData(cardId)
  local gameInitData = DataManager.getGameInitData()
  local aCard = {}    
  for _, temp in ipairs(gameInitData.sharkCards.sharkCards) do
    if cardId == temp.cardId then
      aCard = temp
      break
      end
  end
  return aCard
end

--
-- IntroductionTabView
--

IntroductionTabView = class(Layer)

function IntroductionTabView:ctor()
    self.parentView = nil
end

function IntroductionTabView:create(aParentView)
    local s = IntroductionTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function IntroductionTabView:setTableViewTouchEnable( enable )
	if self.aPanel then
		self.aPanel:setScrollViewTouchEnable(enable)
	end 
end

function IntroductionTabView:initLayer()
	IntroductionTabView.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	builder.useArtLabelTTF = true
	
    self.panelUI = builder:build("popup_details_card_01")
    self:addChild(self.panelUI)
    local cardMeta = MetaManager.card_meta[self.parentView.metaId]
	local desc = Localization:getInstance():getText(cardMeta.desc)
	self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(desc)
	local aDescArea = self.panelUI:getChildByName("txt_10"):getChildByName("txt")
	self.aPanel = CardDescPanel:create(
		self.parentView.metaId,
		{height=300, width=550},
		ccc3(255,255,255),
		self.parentView.cardId,
		false,--true
		true
	)
	self.aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y)
	self.panelUI:getChildByName("txt_10"):addChild(self.aPanel)
	aDescArea:setVisible(false)
	-- self.panelUI:getChildByName("pattern_cardInfor_line2"):setVisible(false)

	local lockBtnDisplay = self.panelUI:getChildByName("btn_the_choose2")
	self:refreshLockState(true)
	local function lockBtnSelected( evt )
		local aCardData = getCardInfoFromInitData(self.parentView.cardId)
		local function succeedCallback(event)
			LockCardRequest.onSucceedDefault(event)
			self:refreshLockState()
		end
		LockCardRequest.sendRequest(succeedCallback, LockCardRequest.onFailedDefault, {methodType = aCardData.lock and 2 or 1, cardId = self.parentView.cardId})
	end
	local lockBtn = Button:create(lockBtnDisplay)
	lockBtn:addEventListener(Events.kStart ,lockBtnSelected , self)

	local changeBtnDisplay = self.panelUI:getChildByName("btn_the_choose")
	local cardQueue = CommonManager:getEffectCardQueue()
	local cardIds = {}
	for aKey, aCardId  in pairs(cardQueue) do
		cardIds[aCardId] = aKey
	end
	--阵容状态（不可卖出）
	local queueList = {}
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
	local function changeBtnSelected( evt )
		PopoutManager:sharedManager():pullin(self.parentView, kPopoutDir.kScale )
		if self.parentView.enterScene == "MatrixScene" then
			if type(self.parentView.container.changeMatrixCard) == "function" then
				self.parentView.container:changeMatrixCard(self.parentView.cardId)
			end
		else
			CardQueueScene.changeCard( self.parentView.cardId , self.parentView.container)
		end
	end
	local function sellBtnSelected( evt )
		local aCardData = getCardInfoFromInitData(self.parentView.cardId)
		if aCardData.lock then
			SuspensionLabel:showContent(self.parentView.container, Localization:getInstance():getText("card_lockedTips_sell"))
			return
		end
		local aPanel = ItemSellMessageBoxPanel:create( self.parentView.container , {cardData={self.parentView.cardId}}, self.parentView , self.parentView.newIndex)
		self.parentView.container:addChild(aPanel)
		aPanel:scaleIn()
	end
	if (cardIds[self.parentView.cardId]) then
		if self.parentView.forceShowSell then
			changeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))
			changeBtnDisplay:getChildByName("btn"):setVisible(false)
			changeBtnDisplay:getChildByName("btn_disable"):setVisible(true)
		else
			changeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_ChangeBtn"))
			changeBtnDisplay:getChildByName("btn"):setVisible(true)
			changeBtnDisplay:getChildByName("btn_disable"):setVisible(false)
			local changeBtn = Button:create(changeBtnDisplay)
			changeBtn:addEventListener(Events.kStart ,changeBtnSelected , self)
		end
	else
		--在其他阵容存在不能卖
		changeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))
		if queueList[self.parentView.cardId] == true then
			changeBtnDisplay:getChildByName("btn"):setVisible(false)
			changeBtnDisplay:getChildByName("btn_disable"):setVisible(true)
		else

			changeBtnDisplay:getChildByName("btn"):setVisible(true)
			changeBtnDisplay:getChildByName("btn_disable"):setVisible(false)
			local changeBtn = Button:create(changeBtnDisplay)
			changeBtn:addEventListener(Events.kStart ,sellBtnSelected , self)
		end
		--end by l1ghtsaber (以下原版)
		-- changeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))
		-- changeBtnDisplay:getChildByName("btn"):setVisible(true)
		-- changeBtnDisplay:getChildByName("btn_disable"):setVisible(false)
		-- local changeBtn = Button:create(changeBtnDisplay)
		-- changeBtn:addEventListener(Events.kStart ,sellBtnSelected , self)
	end
	
	
end

function IntroductionTabView:refreshLockState(notRefreshContainer)
	local aCardData = getCardInfoFromInitData(self.parentView.cardId)
	local lockBtnDisplay = self.panelUI:getChildByName("btn_the_choose2")
	if not aCardData.lock then
		lockBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_lockBtn"))
	else
		lockBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_unlockBtn"))
	end
	self.parentView:refreshCardLockState(aCardData.lock, notRefreshContainer)
end

--
-- StrengthenTabView
--

local CARD_MINRARE = 1
local CARD_MAXRARE = 7
local SUGGESTION_RARE = 3

local StrengthenTypeEnum = {
	card = 1,
	exp = 2,
}

StrengthenTabView = class(Layer)

function StrengthenTabView:ctor()
    self.parentView = nil
    self.panelUI = nil

    self.table_meta_info = nil
    self.strengthenCardData = nil
    self.selectMatterCard = {}
 	self.curSelectCardExp = 0
	self.resultLevel = 0
	self.oldLevel = 0
	self.tableView = nil

    self.enhanceButton = nil
end

function StrengthenTabView:create(aParentView)
    local s = StrengthenTabView.new()
    s.parentView = aParentView
 	
    s:initLayer()
    return s
end

function StrengthenTabView:initLayer()
	StrengthenTabView.super.initLayer(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	self.builder.useArtLabelTTF = true

	self:changePanel(StrengthenTypeEnum.card)
end

function StrengthenTabView:changePanel(aPanelType)
	if self.panelUI then
		self.panelUI:removeFromParentAndCleanup(true)
		self.panelUI = nil
	end
	if aPanelType == StrengthenTypeEnum.card then
		self:addCardStrengthenPanel()
	elseif aPanelType == StrengthenTypeEnum.exp then
		self:addExpStrengthenPanel()
	end
end

function StrengthenTabView:setTableViewTouchEnable(isEnable)
	if self.tableView then
		self.tableView:setTouchEnabled(isEnable)
	end
end

function StrengthenTabView:addCardStrengthenPanel()
	self.panelUI = self.builder:build("popup_details_card_02")
	self.panelUI:getChildByName("friend_btn_cardnew"):setVisible(false)
	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false) --一键完美才用的问号按钮
    self:addChild(self.panelUI)

    self.selectMatterCard = {}
 	self.curSelectCardExp = 0
	self.resultLevel = 0
	self.oldLevel = 0
	self.tableView = nil

	local table_temp_view = self.panelUI:getChildByName("details_card_list")
	table_temp_view:setVisible(false)
	if not self.table_meta_info then
		self.table_meta_info = getTableViewSizes(table_temp_view)
		self.table_meta_info.table_height = self.table_meta_info.table_height
		self.table_meta_info.table_posY = self.table_meta_info.table_posY --+ 20
	end
	--if not self.strengthenCardData then
		self.strengthenCardData = self:getMatterCardData()
	--end

	self.infoPanel = self.panelUI:getChildByName("detailscard_getall_bottom")
	self.infoPanel:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("cardInfo_EnhanceBtn"))
	self.infoPanel:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey(MetaManager.card_meta[self.parentView.containerData.metaId].name))
	self.infoPanel:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("cardEnhance_CoinConsume"))
	self.infoPanel:getChildByName("txt_16"):setVisible(false)
	self.infoPanel:getChildByName("txt_17"):setVisible(false)
	self.infoPanel:getChildByName("icon_silverCoin2"):setVisible(false)
	self.infoPanel:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips1"))
	self.infoPanel:getChildByName("txt_9"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips2"))
	self.infoPanel:getChildByName("txt_11"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips5"))

	self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"):getChildByName("txt_btn_friend_ChangeBtn"):setString(getTextByKey("cardEnhance_useExpBtn"))
	local function onClickExp()
		self:changePanel(StrengthenTypeEnum.exp)
	end
	self.expButton = Button:create(self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"))
	self.expButton:addEventListener(Events.kStart, onClickExp)

	self.panelUI:getChildByName("btn_chr3"):getChildByName("txt"):setString(getTextByKey("cardInfo_EnhanceBtn"))
	local function onClickEnhance()
		local function setPanelTouchEnabled()
			if self.tableView then
				self.tableView:setTouchEnabled(true)
			end
		end
		local function setPanelTouchDisabled()
			if self.tableView then
				self.tableView:setTouchEnabled(false)
			end
		end

		local function confirmCompose()
			local slaveIds = {}
			local function onFlashAnimationEnd(event)
				if self.flashFinish then
					self.flashFinish:unregisterEndAnimationScriptHandler()
					self.parentView.container:removeChild(self.flashFinish_co)
				end
				self:enableUserInterface()
				self:updateAfterCompose(slaveIds)
				if Get_ShareData("New_User_Guide_Running") == 1 then
					Set_ShareData( "CardMergeFinished", 1 )
				end
			end
			
			local function CardComposeFailed(params)
				if params.data == 710512 then
					setPanelTouchDisabled()
					local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCoinLimit, {panelCloseAction = setPanelTouchEnabled})
					self.parentView.container:addChild(aPanel)
					aPanel:scaleIn()
				end
			end
			
	        local function CardComposeCallback(params)
	        	self:disableUserInterface()
				g_previousBattleCount = CommonManager:getLocalPlayerStrength()
				local dirtyCardIds = {}
				table.insert(dirtyCardIds, self.parentView.cardId)
				for key, _ in pairs(self.selectMatterCard) do
					table.insert(dirtyCardIds, key)
				end
				
				CommonManager:setCardNeedUpdate(dirtyCardIds)
				   
	            --动画
				CanonPlayEffect("music/sfx_card_compound.wav")
				self.flashFinish = FlashSprite:create("EVO2/FZZZ_EXX")   
				self.flashFinish:setLoop(false)
	              --换牌
	            local newMetaId = CommonManager:changeAvatarByCardInfo( params.data.sharkCard )
	            --HeMemDataHolder:setInteger( "CardCompose_NewMetaId",newMetaId )
	            local masterCardId = self.parentView.cardId
	            --[[local result = CommonManager:getCardPropertiesWithCardId(masterCardId)
	            local aCard = getCardInfoFromInitData(masterCardId)
				result.exp = aCard.exp]]
	            --HeMemDataHolder:setString( "CardCompose_oldSharkCard",table.serialize(result) )
	            --HeMemDataHolder:setString( "CardCompose_newSharkCard",table.serialize(params.data.sharkCard) )
	            local card1_spf = getCardSpriteFrame(newMetaId)  
	            self.flashFinish:addChangeInstance("card1", card1_spf)
				local tmeta = MetaManager.card_meta[tonumber(newMetaId)]
				local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
				self.flashFinish:addChangeInstance("countrycircle1", countrySpriteFrame)
				local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
				self.flashFinish:addChangeInstance("cardBorder1", boardSpriteFrame)
				local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
				self.flashFinish:addChangeInstance("cardBg1", cardBgSpriteFrame)
				
				self.flashFinish:changeAnimation(2)
				--self.flashFinish:setPosition(-10,40)
				self.flashFinish:registerEndAnimationScriptHandler(onFlashAnimationEnd)
				self.flashFinish_co = CocosObject.new(self.flashFinish)
				self.parentView.container:addChild(self.flashFinish_co)     
				
				local cardData = DataManager.getCardsData()
				local toremoveKeys = {}
				for k,card in ipairs(cardData)
				do
					if card.cardId == masterCardId then
						cardData[k] = params.data.sharkCard
						--如果是阵列中的卡牌，就清空g_previousBonusTable
						local queueData = {}
						local matrixCardData = CommonManager:getMatrixCardData()
						for k,v in ipairs(matrixCardData) do 
							if not queueData[v] then
								queueData[v] = k + 100
							end
						end
						if queueData[card.cardId] and queueData[card.cardId] > 100 then
							g_previousBonusTable = nil;
						end
					else
						for key, mCard in pairs(slaveIds)
						do
							if card.cardId == mCard then
								table.insert(toremoveKeys, k)
								break;
							end
						end
					end
				end
				for i = #toremoveKeys, 1, -1
				do
					table.remove(cardData, toremoveKeys[i])
				end
				DataManager.setCardsData(cardData)
				local rewardTable = {}
				table.insert(rewardTable, {itemType = ResourceEnum.COIN, amount = -self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise})
				RewardManager:getReward(rewardTable)
	        end
	        --[[local cardData = DataManager.getCardsData()
			for key ,data in pairs(cardData) do
				CommonManager:getBackpackCardPropertiesWithSharkCard( data )
			end]]
			for key, _ in pairs(self.selectMatterCard) do
				table.insert(slaveIds, key)
			end
	        local params={masterId=self.parentView.cardId, slaveIds=slaveIds}
	        local request = CardComposeRequest.new( params, rpc.SendingPriority.kHigh )
	        request:addEventListener( RequestNotifyEnum.CardComposeSucceed, CardComposeCallback )
	        request:addEventListener( RequestNotifyEnum.CardComposeFailed, CardComposeFailed )
	        request:start()
		end
		local function continueFunction()
			for k, v in pairs(self.selectMatterCard)
			do
				if MetaManager.card_meta[v].evolutionLevel > 1 then
					setPanelTouchDisabled()
					local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCardComposeRareCardWarning, {panelCloseAction = setPanelTouchEnabled, continueFunction = confirmCompose, warningMessage = getTextByKey("cardEnhanceSelect_evolvedTips")})
					self.parentView.container:addChild(aPanel)
					aPanel:scaleIn()
					return false
				end
			end
			confirmCompose()
		end
		
		if tonumber(DataManager.getCurrUser().coins) < tonumber(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise) then
			setPanelTouchDisabled()
			local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCoinLimit, {panelCloseAction = setPanelTouchEnabled})
			self.parentView.container:addChild(aPanel)
			aPanel:scaleIn()
			return false
		else
			for k, v in pairs(self.selectMatterCard)
			do
				if MetaManager.card_meta[v].rare >= SUGGESTION_RARE then
					setPanelTouchDisabled()
					local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCardComposeRareCardWarning, {continueFunction = continueFunction, panelCloseAction = setPanelTouchEnabled})
					self.parentView.container:addChild(aPanel)
					aPanel:scaleIn()
					return false
				end
			end
			continueFunction()
		end
	end
	self.enhanceButton = Button:create(self.panelUI:getChildByName("btn_chr3"))
	self.enhanceButton:addEventListener(Events.kStart, onClickEnhance)

	self:getComposeExp(0)
end

function StrengthenTabView:addExpStrengthenPanel()
	self.tableView = nil

	self.panelUI = self.builder:build("popup_details_card_06")
    self:addChild(self.panelUI)

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("cardEnhance_expOwned"))
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelPreview1"))
    self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelPreview2"))
    self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelUp"))

    local function onClickLevelChange(evt)
    	self.currentTargetLevel = self.currentTargetLevel + evt.context
    	if self.currentTargetLevel > self.maxLevel then
    		self.currentTargetLevel = self.maxLevel
    	end
    	if self.currentTargetLevel < self.parentView.level then
    		self.currentTargetLevel = self.parentView.level
    	end
    	self:updateExpStrengthen()
    end
    local minusOneDisplay = self.panelUI:getChildByName("btn_other_upgrade1")
    minusOneDisplay:getChildByName("txt"):setString("-1")
    self.minusOneBtn = Button:create(minusOneDisplay)
    self.minusOneBtn:addEventListener(Events.kStart, onClickLevelChange, -1)
    local minusTenDisplay = self.panelUI:getChildByName("btn_other_upgrade2")
    minusTenDisplay:getChildByName("txt"):setString("-10")
    self.minusTenBtn = Button:create(minusTenDisplay)
    self.minusTenBtn:addEventListener(Events.kStart, onClickLevelChange, -10)
    local addOneDisplay = self.panelUI:getChildByName("btn_other_upgrade3")
    addOneDisplay:getChildByName("txt"):setString("+1")
    self.addOneBtn = Button:create(addOneDisplay)
    self.addOneBtn:addEventListener(Events.kStart, onClickLevelChange, 1)
    local addTenDisplay = self.panelUI:getChildByName("btn_other_upgrade4")
    addTenDisplay:getChildByName("txt"):setString("+10")
    self.addTenBtn = Button:create(addTenDisplay)
    self.addTenBtn:addEventListener(Events.kStart, onClickLevelChange, 10)

    self.panelUI:getChildByName("txt_17"):getChildByName("txt"):setString(getTextByKey("cardEnhance_CoinConsume"))

    self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"):getChildByName("txt_btn_friend_ChangeBtn"):setString(getTextByKey("cardEnhance_useCardBtn"))
	local function onClickCard()
		self:changePanel(StrengthenTypeEnum.card)
	end
	local cardButton = Button:create(self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"))
	cardButton:addEventListener(Events.kStart, onClickCard)

	self.panelUI:getChildByName("btn_chr3"):getChildByName("txt"):setString(getTextByKey("cardInfo_EnhanceBtn"))
	local function onClickEnhance()
		if CanonGoodIcon.getResourceNum(ResourceEnum.COIN) < self.needCoin then
			local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCoinLimit)
			self.parentView.container:addChild(aPanel)
			aPanel:scaleIn()
			return
		end
		local function onFlashAnimationEnd(event)
			if self.flashFinish then
				self.flashFinish:unregisterEndAnimationScriptHandler()
				self.parentView.container:removeChild(self.flashFinish_co)
			end
			self:enableUserInterface()
			
			local aNewData = getCardInfoFromInitData(self.parentView.cardId)
			self.parentView:refreshCardInfoForStrengthen({showAdditional = false, newLevel = aNewData.level})
			self:updateExpStrengthen(true)
			--FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
			DataManager.fightCapacityMaybeUpdated()
		end
		
	    local function CardComposeCallback(evt)
	    	self:disableUserInterface()
	    	g_previousBattleCount = CommonManager:getLocalPlayerStrength()
			local dirtyCardIds = {}
			table.insert(dirtyCardIds, self.parentView.cardId)
			CommonManager:setCardNeedUpdate(dirtyCardIds)
			
	        --动画
			CanonPlayEffect("music/sfx_card_compound.wav")
			self.flashFinish = FlashSprite:create("EVO2/FZZZ_EXX")   
			self.flashFinish:setLoop(false)
	          --换牌
	        local newMetaId = CommonManager:changeAvatarByCardInfo( evt.data.sharkCard )          
	        local masterCardId = self.parentView.cardId
	        local card1_spf = getCardSpriteFrame(newMetaId)  
	        self.flashFinish:addChangeInstance("card1", card1_spf)
			local tmeta = MetaManager.card_meta[tonumber(newMetaId)]
			local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
			self.flashFinish:addChangeInstance("countrycircle1", countrySpriteFrame)
			local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
			self.flashFinish:addChangeInstance("cardBorder1", boardSpriteFrame)
			local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
			self.flashFinish:addChangeInstance("cardBg1", cardBgSpriteFrame)
			
			self.flashFinish:changeAnimation(2)
			--curContext.flashFinish:setPosition(-10,40)
			self.flashFinish:registerEndAnimationScriptHandler(onFlashAnimationEnd)
			self.flashFinish_co = CocosObject.new(self.flashFinish)
			self.parentView.container:addChild(self.flashFinish_co)     
	    end  

		local function onSucceed(evt)
			--先走动画
			CardComposeCallback(evt)
			HeMemDataHolder:setInteger("CardCompose_MainCardId", self.parentView.cardId)
			--后重置数据
			UpgradeCardByGeneralExpRequest.onSucceedDefault(evt)
		end
		UpgradeCardByGeneralExpRequest.sendRequest(getCardInfoFromInitData(self.parentView.cardId), self.currentTargetLevel, onSucceed, UpgradeCardByGeneralExpRequest.onFailedDefault)
	end
	self.enhanceButton = Button:create(self.panelUI:getChildByName("btn_chr3"))
	self.enhanceButton:addEventListener(Events.kStart, onClickEnhance)

	self:updateExpStrengthen(true)

	self.parentView:refreshCardInfoForStrengthen({notRefreshContainer = true})
end

function StrengthenTabView:updateExpStrengthen(resetTargetLevel)
	local currentExp = CanonGoodIcon.getResourceNum(ResourceEnum.GENERALEXP)
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString("" .. currentExp)
	self.maxLevel = MetaManager.card_evolve[MetaManager.card_meta[self.parentView.containerData.metaId].evolutionLevel].maxCardLevel
	local totalExp = currentExp + self.parentView.exp + MetaManager.card_level[self.parentView.level].totalExp --可以支配的总经验 = 已有经验 + 主卡经验(=卡牌总经验+当前经验)
    for index,v in ipairs(MetaManager.card_level) do
    	if v.level < self.maxLevel then
	        if index==#MetaManager.card_level and totalExp>v.totalExp then 
				self.maxLevel = v.level
	            break
	        end
	        if totalExp>=v.totalExp and totalExp<MetaManager.card_level[index+1].totalExp then 
	            self.maxLevel = v.level
	            break        
	        end
	    end
    end
    if resetTargetLevel then
    	self.currentTargetLevel = self.maxLevel
    end
    if self.currentTargetLevel >= self.maxLevel then
    	self.addOneBtn:setEnable(false)
    	self.addOneBtn.display:getChildByName("normal"):setVisible(false)
    	self.addTenBtn:setEnable(false)
    	self.addTenBtn.display:getChildByName("normal"):setVisible(false)
    else
    	self.addOneBtn:setEnable(true)
    	self.addOneBtn.display:getChildByName("normal"):setVisible(true)
    	self.addTenBtn:setEnable(true)
    	self.addTenBtn.display:getChildByName("normal"):setVisible(true)
    end
    if self.currentTargetLevel <= self.parentView.level then
    	self.minusOneBtn:setEnable(false)
    	self.minusOneBtn.display:getChildByName("normal"):setVisible(false)
    	self.minusTenBtn:setEnable(false)
    	self.minusTenBtn.display:getChildByName("normal"):setVisible(false)
    else
    	self.minusOneBtn:setEnable(true)
    	self.minusOneBtn.display:getChildByName("normal"):setVisible(true)
    	self.minusTenBtn:setEnable(true)
    	self.minusTenBtn.display:getChildByName("normal"):setVisible(true)
    end

    self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString("" .. self.maxLevel)
    self.panelUI:getChildByName("txt_other_upgrade3"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelUp2", {num = self.currentTargetLevel}))
    if self.currentTargetLevel <= self.parentView.level then
    	self.needCoin = 0
    else
    	self.needCoin = CardComposeScene.getNeedCoinByTargetLevel({level = self.parentView.level, exp = self.parentView.exp}, self.currentTargetLevel)
    end
    self.panelUI:getChildByName("txt_16"):getChildByName("txt"):setString("" .. self.needCoin)
    if self.needCoin > CanonGoodIcon.getResourceNum(ResourceEnum.COIN) then
    	self.panelUI:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(217, 0, 0))
    else
    	self.panelUI:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
    end
    if self.currentTargetLevel <= self.parentView.level then
    	self.enhanceButton:setEnable(false)
    	self.enhanceButton.display:getChildByName("btn"):setVisible(false)
    else
    	self.enhanceButton:setEnable(true)
    	self.enhanceButton.display:getChildByName("btn"):setVisible(true)
    end
end

function StrengthenTabView:updateAfterCompose(slaveIds)
	AttributeChangePanel:show(g_previousBattleCount, CommonManager:getLocalPlayerStrength(), self.parentView.container)
	--FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
	DataManager.fightCapacityMaybeUpdated()

	for i = #self.strengthenCardData, 1, -1 do
		self.strengthenCardData[i] = nil
	end
	local aNewDataList = self:getMatterCardData()
	for _, aNewData in ipairs(aNewDataList) do
		table.insert(self.strengthenCardData, aNewData)
	end
    self.tableView:reloadData()
    self.selectMatterCard = {}
 	self.curSelectCardExp = 0
	self.resultLevel = 0
	self.oldLevel = 0
	self:refreshInfoPanel(slaveIds, nil)
end

function StrengthenTabView:disableUserInterface()
	self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self.parentView.container:addChild(self.tempLayer)
    if self.tableView then
		self.tableView:setTouchEnabled(false)
	end
end

function StrengthenTabView:enableUserInterface()
	if self.tempLayer then
    	self.tempLayer:removeFromParentAndCleanup(true)
    end
    if self.tableView then
		self.tableView:setTouchEnabled(true)
	end
end

function StrengthenTabView:getComposeExp(changedExp)
	local mainCardId = self.parentView.cardId
	
  	local needUpgradeCoin = 0
  	local ret = {newLevel=nil,upgradeCoin=nil}
  	local aCard = getCardInfoFromInitData(mainCardId)
  	self.oldLevel = aCard.level
  	local aCardLevelConfig = MetaManager.card_level[aCard.level]
  	local mainCardExp = aCardLevelConfig.totalExp + aCard.exp
	
  	self.curSelectCardExp = self.curSelectCardExp + changedExp
  	local resultAllExp = mainCardExp + self.curSelectCardExp
	local cardMaxLevel = MetaManager.card_evolve[MetaManager.card_meta[aCard.metaId].evolutionLevel].maxCardLevel
  	for index,v in ipairs(MetaManager.card_level) do
    	if index==#MetaManager.card_level and resultAllExp>=v.totalExp then 
			ret.newLevel = v.level
      		break
    	end
    	if resultAllExp>=v.totalExp and resultAllExp<MetaManager.card_level[index+1].totalExp then 
      		ret.newLevel = v.level
      		break        
    	end
  	end    
  	if not ret.newLevel then
  		ret.newLevel = 1
  	end 
	if ret.newLevel > cardMaxLevel then
		ret.newLevel = cardMaxLevel
	end
	self.resultLevel = ret.newLevel
	self:refreshInfoPanel(nil, true, true)
end

function StrengthenTabView:refreshInfoPanel(slaveIds, noReload, notRefreshContainer)
	self.infoPanel:getChildByName("txt_7"):getChildByName("txt"):setString(tostring(math.floor(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise)))
	if tonumber(DataManager.getCurrUser().coins) < tonumber(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise) then
		self.infoPanel:getChildByName("txt_7"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
	else
		self.infoPanel:getChildByName("txt_7"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
	end
	self.infoPanel:getChildByName("txt_12"):getChildByName("txt"):setString(tostring(table.size(self.selectMatterCard)))
	local expText = ""
	if self.curSelectCardExp >= 100000000 then
		expText = Localization:getInstance():getText("cardEnhanceSelect_resultTips_yi", {num = tostring(math.floor(self.curSelectCardExp / 100000000))})
	elseif self.curSelectCardExp >= 1000000 then
		expText = Localization:getInstance():getText("cardEnhanceSelect_resultTips_wan", {num = tostring(math.floor(self.curSelectCardExp / 10000))})
	else
		expText = tostring(math.floor(self.curSelectCardExp))
	end
	self.infoPanel:getChildByName("txt_13"):getChildByName("txt"):setString(expText)
	if self.resultLevel <= self.oldLevel then
		self.infoPanel:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips3"))
		self.infoPanel:getChildByName("txt_14"):setVisible(false)
		self.infoPanel:getChildByName("txt_11"):setVisible(false)
	else
		self.infoPanel:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips4"))
		self.infoPanel:getChildByName("txt_14"):getChildByName("txt"):setString(tostring(self.resultLevel))
		self.infoPanel:getChildByName("txt_14"):setVisible(true)
		self.infoPanel:getChildByName("txt_11"):setVisible(true)
	end
	local selectCard = (table.size(self.selectMatterCard) > 0)
	self.enhanceButton:setEnable(selectCard)
	self.enhanceButton.display:getChildByName("btn"):setVisible(selectCard)

	self.parentView:refreshCardInfoForStrengthen({showAdditional = (self.oldLevel < self.resultLevel), newLevel = self.resultLevel, slaveIds = slaveIds, notRefreshContainer = notRefreshContainer})

	local cardMeta = MetaManager.card_meta[self.parentView.containerData.metaId]
	local cardEvolveConfig = MetaManager.card_evolve[cardMeta.evolutionLevel]
	if self.parentView.level >= cardEvolveConfig.maxCardLevel then
		if self.tableView then
			self.tableView:removeFromParentAndCleanup(true)
			self.tableView = nil
		end
		self.panelUI:getChildByName("txt_activity_3_5"):setVisible(true)
		self.panelUI:getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(getTextByKey("cardEnhanceResult_maxLevel"))
	elseif not ItemManager.checkCardTypeCanUpgrade(self.parentView.containerData.metaId) then
		--不允许强化的卡牌 add by zheng.che @ 2014-8-25

		--不显示列表
		if self.tableView then
			self.tableView:removeFromParentAndCleanup(true)
			self.tableView = nil
		end

		--不显示下边的各种文本 只留底框
		self.infoPanel:getChildByName("txt_4"):setVisible(false)
		self.infoPanel:getChildByName("txt_5"):setVisible(false)
		self.infoPanel:getChildByName("txt_6"):setVisible(false)
		self.infoPanel:getChildByName("icon_silverCoin"):setVisible(false)
		self.infoPanel:getChildByName("txt_7"):setVisible(false)
		self.infoPanel:getChildByName("txt_8"):setVisible(false)
		self.infoPanel:getChildByName("txt_12"):setVisible(false)
		self.infoPanel:getChildByName("txt_9"):setVisible(false)
		self.infoPanel:getChildByName("txt_13"):setVisible(false)
		self.infoPanel:getChildByName("txt_10"):setVisible(false)
		self.infoPanel:getChildByName("txt_14"):setVisible(false)
		self.infoPanel:getChildByName("txt_11"):setVisible(false)

		self.infoPanel:getChildByName("txt_17"):setVisible(false)
		self.infoPanel:getChildByName("icon_silverCoin2"):setVisible(false)
		self.infoPanel:getChildByName("txt_16"):setVisible(false)

		--按钮置灰
    	self.expButton:setEnable(false)
    	self.expButton.display:getChildByName("btn"):setVisible(false)

		self.panelUI:getChildByName("txt_activity_3_5"):setVisible(true)
		self.panelUI:getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(getTextByKey("cardEnhanceLimited"))--此武将不能进行强化
	else
	    if #self.strengthenCardData == 0 then
	    	if self.tableView then
				self.tableView:removeFromParentAndCleanup(true)
				self.tableView = nil
			end
			self.panelUI:getChildByName("txt_activity_3_5"):setVisible(true)
	    	self.panelUI:getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(getTextByKey("cardEnhance_NoCardTxt"))
	    else
	    	if not self.tableView then
	    		self.tableView = self:createTableView(self.strengthenCardData)
				self.panelUI:addChild(self.tableView)
	    	end
	    	if not noReload then
		    	self.tableView:reloadData()
		    end
			self.panelUI:getChildByName("txt_activity_3_5"):setVisible(false)
		end
	end
end

function StrengthenTabView:getMatterCardData()
	local cardData = DataManager.getCardsData()
	local matterCardData = {}
	local queueData = CommonManager.getQueueData()
	for k, v in pairs(CommonManager:getMatrixCardData()) do
		table.insert(queueData, v)
	end
	local mainCardId = self.parentView.cardId
	local masterCardGroupId = MetaManager.card_meta[self.parentView.metaId].cardGroupId
	--阵容状态（不可强化）
	local queueList = {}
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
	for k,card in pairs(cardData) do
		if not card.lock then
			local found = false
			local slaveCardGroupId  = MetaManager.card_meta[card.metaId].cardGroupId
			if masterCardGroupId == slaveCardGroupId then
				found = true
			elseif mainCardId == card.cardId then
				found = true
			else
				for _,value in pairs(queueData)
				do
					if tonumber(value) == card.cardId then
						found = true
						break
					end
				end
			end

			if not ItemManager.checkCardTypeCanUseToUpgrade(card.metaId) then
				--卡牌类型不允许作为强化材料 add by czh @ 2014-8-27
				found = true
			end

			if queueList[card.cardId] == true then found = true end --阵容中的不能强化 add by l1ghtsaber

			if not found then
				table.insert(matterCardData,card)
			end
		end
	end
	
	local result = {}
	local strengthenCardData = {}
	local changeExp = 0
	for i = CARD_MINRARE, CARD_MAXRARE do
		table.insert(strengthenCardData, {rare = i, cardTable = {}, curPage = 1})
	end
	for key ,data in pairs(matterCardData) do
		local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCardWithoutCardProperties( data )--CommonManager:getBackpackCardPropertiesWithSharkCard( data )
		data.resultExp   = math.floor(cardStatus.resultExp)
		data.price = cardStatus.price
		data.rare = MetaManager.card_meta[data.metaId].rare
		data.cardName = MetaManager.card_meta[data.metaId].name
		data.cardSelect = (self.selectMatterCard[data.cardId] ~= nil)
		if self.selectMatterCard[data.cardId] ~= nil then
			changeExp = changeExp + data.resultExp
		end
		if data.rare and tonumber(data.rare) <= CARD_MAXRARE and tonumber(data.rare) >= CARD_MINRARE then
			table.insert(strengthenCardData[tonumber(data.rare)].cardTable, data)
		end
	end
	
	for key ,data in pairs(strengthenCardData) do
		if table.getn(data.cardTable) > 0 then
			table.insert(result, data)
		end
	end
	
	local function isCowCard( aCardData )
		local aCardMeta = MetaManager.card_meta[aCardData.metaId]
		if (aCardMeta.cardGroupId == 495) or (aCardMeta.cardGroupId == 496) or (aCardMeta.cardGroupId == 497) then
			return true
		end
		return false
	end

	local function cardSortFunc(a, b)
		if isCowCard(a) and (not isCowCard(b)) then
			return true
		elseif (not isCowCard(a)) and isCowCard(b) then
			return false
		else
			if a.resultExp == b.resultExp then
				return a.metaId < b.metaId
			else
				return a.resultExp > b.resultExp
			end
		end
	end
	
	for key, data in pairs(result) do
		table.sort(data.cardTable, cardSortFunc)
	end
	return result
end

function StrengthenTabView:createTableView(data)
	local cellTag = 1024
	local CardStrenthenRenderer = class(TableViewRenderer)
	local SELF = self
	function CardStrenthenRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function CardStrenthenRenderer:buildCell(container)
		local cell = self.builder:build("list/skillup_detailscard_list")
		cell:setTag(cellTag)
		container:addChild(cell)
		
		cell:getChildByName("skillup_item1"):setTag(-10)
		cell:getChildByName("skillup_item1"):setVisible(false)
		cell:getChildByName("txt_2"):setTag(-11)
		cell:getChildByName("txt_2"):getChildByName("txt"):setTag(-10)
		cell:getChildByName("txt_3"):setTag(-12)
		cell:getChildByName("txt_3"):getChildByName("txt"):setTag(-10) 
		cell:getChildByName("skillup_btn_pgdown"):setTag(-13)
		cell:getChildByName("skillup_btn_pgdown"):getChildByName("btn_d_many"):setTag(-10)
		cell:getChildByName("skillup_btn_pgdown"):getChildByName("txt"):setString(getTextByKey("skill_pageDownBtn"))
		cell:getChildByName("skillup_btn_pgup"):setTag(-14)
		cell:getChildByName("skillup_btn_pgup"):getChildByName("btn_d_many"):setTag(-10)
		cell:getChildByName("skillup_btn_pgup"):getChildByName("txt"):setString(getTextByKey("skill_pageUpBtn"))
		cell:getChildByName("email_control_all_select"):setTag(-15)
		cell:getChildByName("email_control_all_select"):getChildByName("txt_select_all"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_selectAll"))
		cell:getChildByName("email_control_all_select"):getChildByName("btn_selected_all"):setTag(-10)
		cell:getChildByName("txt_15"):setVisible(false)
		cell:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("cardEnhance_noCardText"))
		
		for i = 1, 8 do
			local item = self.builder:build("skillup_item")
			item:setTag(-20 - (i - 1))
			item:setPositionXY(self.width / 2 + 154 * ((i - 1) % 4 - 2) + 12, cell:getChildByName("skillup_item1"):getPositionY() - 148 * math.floor((i - 1) / 4))
			item:getChildByName("skillup_icon_selected"):setTag(-10)
			item:getChildByName("reward_item"):setTag(-11)
			item:getChildByName("reward_item"):getChildByName("txt_item_name"):setTag(-10)
			item:getChildByName("reward_item"):getChildByName("txt_item_name"):getChildByName("txt"):setTag(-10)
			item:getChildByName("reward_item"):getChildByName("normal_card_small"):setVisible(false)
			item:getChildByName("reward_item"):getChildByName("normal_card_small"):setTag(-11)
			item:getChildByName("lv_txt"):setTag(-12)
			item:getChildByName("lv_txt"):getChildByName("txt"):setTag(-10)
			cell:addChild(item)
		end

	end

	function CardStrenthenRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, cellTag)
		local cardInfo = data[index + 1]
		
		setTextByTag(cell, {-11, -10}, getTextByKey("cardEnhanceSelect_star" .. cardInfo.rare))
		
		local allSelect = true		
		for i = 1, 8 do
			local item = cell:getChildByTag(-20 - (i - 1))
			local curCardInfo = cardInfo.cardTable[(cardInfo.curPage - 1) * 8 + i]
			if curCardInfo then
				if (not curCardInfo.cardSelect) and (not curCardInfo.lock) then
					allSelect = false
				end
				item:setVisible(true)
				if item:getChildByTag(-20) then
					item:removeChildByTag(-20, true)
				end
				local newMetaId =CommonManager:changeAvatarByCardInfo( curCardInfo )
				local perfectType = 0
				local cardMeta = MetaManager.card_meta[curCardInfo.metaId]
				if CommonManager:checkIsCardPerfect(curCardInfo) then
					if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
						perfectType = CardPerfectEnum.goldLeft
					else
						perfectType = CardPerfectEnum.silverLeft
					end
				end
				local cardIcon = getHeadIconCanonCardByMetaId(newMetaId, curCardInfo.lock ,perfectType)
				cardIcon:setScale(0.85)
				cardIcon:setTag(-20)
				local aPosx = item:getChildByTag(-11):getPositionX() + item:getChildByTag(-11):getChildByTag(-11):getPositionX()
				local aPosy = item:getChildByTag(-11):getPositionY() + item:getChildByTag(-11):getChildByTag(-11):getPositionX()
				cardIcon:setPositionXY(item:getChildByTag(-11):getChildByTag(-11):getPositionX(), item:getChildByTag(-11):getChildByTag(-11):getPositionY())
				item:getChildByTag(-11):addChild(cardIcon.refCocosObj, item:getChildByTag(-11):getChildByTag(-11):getZOrder())	
				cardIcon:dispose()
				
				setTextByTag(item , {-12, -10}, "LV." .. tostring(curCardInfo.level))
				setTextByTag(item , {-11, -10, -10}, getTextByKey(curCardInfo.cardName))
				setNodeVisibleByTag(item ,{-10}, curCardInfo.cardSelect)
			else
				item:setVisible(false)
			end
		end
		setNodeVisibleByTag(cell, {-15, -10}, allSelect)
		local maxPage = math.floor((table.getn(cardInfo.cardTable) - 1) / 8 + 1)
		setTextByTag(cell, {-12, -10}, getTextByKey("skill_pageNum") .. tostring(cardInfo.curPage) .. "/" .. tostring(maxPage))
		setNodeVisibleByTag(cell, {-13, -10}, cardInfo.curPage < maxPage)
		setNodeVisibleByTag(cell, {-14, -10}, cardInfo.curPage > 1)
	end
	
	local renderer = CardStrenthenRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
	local buttonTag = {-13, -14}
    local list = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag)
    local function reloadTableData()
    	local originalOffsetY = self.tableView:getContentOffset().y
		self.tableView:reloadData()
		self.tableView:setContentOffset(ccp(0, originalOffsetY), false)
    end
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(cellTag)
		local curTabIndex = evt.context
		local aData = data[evt.data + 1]
		
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		
		local itemPosX, itemPosY
		local itemRect = {}
		itemPosX , itemPosY = selectedCell:getChildByTag(-15):getPosition()
		itemRect.width = 110
		itemRect.height = 50
		itemRect.x = itemPosX
		itemRect.y = itemPosY - itemRect.height
		
		if inArea(posInCell.x, posInCell.y, itemRect) then --allselect
			local tosetSelect = not selectedCell:getChildByTag(-15):getChildByTag(-10):isVisible()
			selectedCell:getChildByTag(-15):getChildByTag(-10):setVisible(tosetSelect)
			local changeExp = 0
			local changePrice = 0
			for i = 1, 8 do
				local cardInfo = aData.cardTable[(aData.curPage - 1) * 8 + i]
				if cardInfo and not cardInfo.lock then
					if cardInfo.cardSelect ~= tosetSelect then
						if tosetSelect then
							self.selectMatterCard[cardInfo.cardId] = cardInfo.metaId
							changeExp = changeExp + cardInfo.resultExp
							changePrice = changePrice + cardInfo.price
						else
							self.selectMatterCard[cardInfo.cardId] = nil
							changeExp = changeExp - cardInfo.resultExp
							changePrice = changePrice - cardInfo.price
						end
						cardInfo.cardSelect = tosetSelect
					end
				end
			end
			self:getComposeExp(changeExp)
			--self.tableView:updateCellAtIndex(evt.data)
			reloadTableData()
		else
			itemRect = {}
			itemPosX , itemPosY = selectedCell:getChildByTag(-14):getPosition()
			itemRect.width = selectedCell:getChildByTag(-14):getChildByTag(-10):getContentSize().width
			itemRect.height = selectedCell:getChildByTag(-14):getChildByTag(-10):getContentSize().height
			itemRect.x = itemPosX
			itemRect.y = itemPosY - itemRect.height
			if inArea(posInCell.x, posInCell.y, itemRect) then --previousPage
				if selectedCell:getChildByTag(-14):getChildByTag(-10):isVisible() then
					aData.curPage = aData.curPage - 1
					--self.tableView:updateCellAtIndex(evt.data)
					reloadTableData()
				end
			else
				itemRect = {}
				itemPosX , itemPosY = selectedCell:getChildByTag(-13):getPosition()
				itemRect.width = selectedCell:getChildByTag(-13):getChildByTag(-10):getContentSize().width
				itemRect.height = selectedCell:getChildByTag(-13):getChildByTag(-10):getContentSize().height
				itemRect.x = itemPosX
				itemRect.y = itemPosY - itemRect.height
				if inArea(posInCell.x, posInCell.y, itemRect) then --nextPage
					if selectedCell:getChildByTag(-13):getChildByTag(-10):isVisible() then
						aData.curPage = aData.curPage + 1
						--self.tableView:updateCellAtIndex(evt.data)
						reloadTableData()
					end
				else
					for i = 1, 8 do
						itemPosX, itemPosY = selectedCell:getChildByTag(-20 - (i - 1)):getPosition()
						itemRect = {}
						itemRect.width = 131
						itemRect.height = 138
						itemRect.x = itemPosX
						itemRect.y = itemPosY-- - itemRect.height
						
						if inArea(posInCell.x, posInCell.y, itemRect) then
							local cardInfo = aData.cardTable[(aData.curPage - 1) * 8 + i]
							if cardInfo then
								if cardInfo.lock then
									SuspensionLabel:showContent(self.parentView.container, Localization:getInstance():getText("card_lockedTips_enhance"))
								else
									local tosetSelect = not cardInfo.cardSelect
									local changeExp = 0
									local changePrice = 0
									if tosetSelect then
										self.selectMatterCard[cardInfo.cardId] = cardInfo.metaId
										changeExp = changeExp + cardInfo.resultExp
										changePrice = changePrice + cardInfo.price
									else
										self.selectMatterCard[cardInfo.cardId] = nil
										changeExp = changeExp - cardInfo.resultExp
										changePrice = changePrice - cardInfo.price
									end
									cardInfo.cardSelect = tosetSelect
									self:getComposeExp(changeExp)
									--self.tableView:updateCellAtIndex(evt.data)
									reloadTableData()
								end
							end
							break
						end
					end
				end
			end
		end
		
		
	end

    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
    list:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
    return list
end

--
-- CultivateTabView
--
local multi_train_num = 10

CultivateTabView = class(Layer)

function CultivateTabView:ctor()
    self.parentView = nil
    self.trainLvlBtn = {}
    self.trainActnBtn = {}
    self.trainStatus = false
    self.trainConfig = nil
    self.soulStone = nil
    self.trainLevelSelected = 1
    self.desStrList = {}
    self.cardOriginalProperties = {}
    self.nowPotential = 0
    self.additionalLabelList = {}
end

function CultivateTabView:create(aParentView)
    local s = CultivateTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function CultivateTabView:initLayer()
	CultivateTabView.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	builder.useArtLabelTTF = true
	
    self.panelUI = builder:build("popup_details_card_04")
    self:addChild(self.panelUI)

    self:initStaticUI()

    self.trainConfig = MetaManager.getCardTrainConfig()
    self.soulStone = CommonManager.getSubTableByKey(
		DataManager.getPropsData(),
		{name = "metaId", value = self.trainConfig.pydMetaId}
	)
	if not self.soulStone then
		self.soulStone = {amount = 0, metaId = self.trainConfig.pydMetaId}
	end
	self.cardOriginalProperties = CommonManager:getSimpleCardProperties(self.parentView.cardId)
    local aCardMetaConfig = MetaManager.card_meta[self.parentView.metaId]
    local aCardRareConfig = MetaManager.card_rare[aCardMetaConfig.rare]
    local aCardData = getCardInfoFromInitData(self.parentView.cardId)
    self.nowPotential = aCardRareConfig.addPotential * self.parentView.level - aCardData.usedPotential
	self.desStrList = {
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost , min=self.trainConfig.normalTrainFloor , max=self.trainConfig.normalTrainCeil}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost , min=self.trainConfig.specialTrainFloor , max=self.trainConfig.specialTrainCeil}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost*multi_train_num , min=self.trainConfig.normalTrainFloor*multi_train_num , max=self.trainConfig.normalTrainCeil*multi_train_num}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost*multi_train_num , min=self.trainConfig.specialTrainFloor*multi_train_num , max=self.trainConfig.specialTrainCeil*multi_train_num})}
    table.insert(self.additionalLabelList, self.panelUI:getChildByName("card_lbl_parameter_add_atk"))
    table.insert(self.additionalLabelList, self.panelUI:getChildByName("card_lbl_parameter_add_def"))
    table.insert(self.additionalLabelList, self.panelUI:getChildByName("card_lbl_parameter_add_hp"))
    table.insert(self.additionalLabelList, self.panelUI:getChildByName("card_lbl_parameter_add_pp"))

    self:updateStatusForUnsavedTrain()

    self:refreshInfoPanel(true)

end

function CultivateTabView:updateStatusForUnsavedTrain()
	local unsavedInfo = CardTrainingScene.getUnsavedTrainInfo()
	if unsavedInfo.trainValueSaved or unsavedInfo.trainCardId == 0 then
		return
	end
	local cardsData = DataManager.getCardsData()
    local isFind = false
    for key ,data in pairs(cardsData) do
      if unsavedInfo.trainCardId == data.cardId then
        isFind = true
      end
    end

    if not isFind then
      return
    end

    self.trainStatus = true

	self.labelTable = {}
	self.labelTable.atk = unsavedInfo.unsavedAttTrainValue
	if self.labelTable.atk > 0 then
		self.fireOnIcon = 1
	end
	self.labelTable.def = unsavedInfo.unsavedDefTrainValue
	if self.labelTable.def > 0 then
		self.fireOnIcon = 2
	end
	self.labelTable.hp = unsavedInfo.unsavedHpTrainValue
	if self.labelTable.hp > 0 then
		self.fireOnIcon = 3
	end
end

function CultivateTabView:initStaticUI()
  local nameStr = "card_btn_cardTrain_level"
  local cardTrainConfig = MetaManager.getCardTrainConfig()
  local trainCost = cardTrainConfig.ybCost
  local trainLvlDisplays = {}
  table.insert(trainLvlDisplays, self.panelUI:getChildByName(nameStr .. "low"))
  table.insert(trainLvlDisplays, self.panelUI:getChildByName(nameStr .. "mid"))
  table.insert(trainLvlDisplays, self.panelUI:getChildByName(nameStr .. "lowmany"))
  table.insert(trainLvlDisplays, self.panelUI:getChildByName(nameStr .. "midmany"))
  trainLvlDisplays[1]:getChildByName("txt_cardTrain_levellow"):setString(Localization:getInstance():getText("cardTrain_levellow"))
  trainLvlDisplays[2]:getChildByName("txt_cardTrain_levelmid_L"):setString(Localization:getInstance():getText("cardTrain_levelmid"))
  trainLvlDisplays[2]:getChildByName("txt_cardTrain_levelmid_R"):setString(trainCost .. "")
  trainLvlDisplays[3]:getChildByName("txt_cardTrain_levellowmany"):setString(Localization:getInstance():getText("cardTrain_levellowmany",{num=multi_train_num}))
  trainLvlDisplays[4]:getChildByName("txt_cardTrain_levelmidmany_L"):setString(Localization:getInstance():getText("cardTrain_levelmidmany",{num=multi_train_num}))
  trainLvlDisplays[4]:getChildByName("txt_cardTrain_levelmidmany_R"):setString((trainCost * multi_train_num) .. "")
  local function onClickTrainLvlBtn(evt)
  	self.trainLevelSelected = evt.context
  	self:refreshTrainLvlBtnStatus()
  end
  for key, value in ipairs(trainLvlDisplays) do
    local aButton = Button:create(value)
    aButton:addEventListener(Events.kStart, onClickTrainLvlBtn, key)
    table.insert(self.trainLvlBtn, aButton)
  end

  self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_train_soulStone"))
  self.panelUI:getChildByName("txt_7"):getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_train_potential"))

  local trainActnDisplays = {}
  table.insert(trainActnDisplays, self.panelUI:getChildByName("card_btn_cardTrain_retryBtn"))
  table.insert(trainActnDisplays, self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"))
  table.insert(trainActnDisplays, self.panelUI:getChildByName("card_btn_cardTrain_abandonBtn"))
  trainActnDisplays[1]:getChildByName("txt"):setString(Localization:getInstance():getText("cardTrain_retryBtn"))
  trainActnDisplays[3]:getChildByName("txt"):setString(Localization:getInstance():getText("cardTrain_abandonBtn"))
  local function onClickTrainActnBtn(evt)
    local function panelCallback(params)
    	self:trainCard( params )
    end
    self.trainOpt = {
      cardId = self.parentView.cardId,
      special = (self.trainLevelSelected == 2 or self.trainLevelSelected == 4),
      trainTimes = (self.trainLevelSelected == 3 or self.trainLevelSelected == 4) and 10 or 1,
      callback = panelCallback
    }
    if (evt.context==1) then
      --重试
      if ((self.nowPotential <= 0) and ((self.trainLevelSelected==2) or (self.trainLevelSelected==4)) and CardTrainingScene.canShowAssistantPanel()) then
          local aPanel = AssistantMessageBoxPanel:create( self.parentView.container, AsMessageBoxType.notEnoughPotential, self.trainOpt )
          self.parentView.container:addChild(aPanel)
          aPanel:scaleIn()
      else
          self:trainCard( self.trainOpt )
      end
        
      self.labelTable = {
        ["cap"] = -2,
      }
    elseif (evt.context == 2) then
      if (self.trainStatus) then
        --保存
		g_previousBattleCount = CommonManager:getLocalPlayerStrength()
        self.trainStatus = false
        self:saveCardTrain( self.trainOpt )
      else
        --开始培养
        if ((self.nowPotential <= 0) and ((self.trainLevelSelected==2) or (self.trainLevelSelected==4)) and CardTrainingScene.canShowAssistantPanel()) then
          local aPanel = AssistantMessageBoxPanel:create( self.parentView.container, AsMessageBoxType.notEnoughPotential, self.trainOpt )
          self.parentView.container:addChild(aPanel)
          aPanel:scaleIn()
        else
          self:trainCard( self.trainOpt )
        end
      end
    else
      --放弃
      self:giveUpCardTrain( self.trainOpt )
    end
  end
  for key, value in ipairs(trainActnDisplays) do
    local aButton = Button:create(value)
    aButton:addEventListener(Events.kStart, onClickTrainActnBtn, key)
    table.insert(self.trainActnBtn, aButton)
  end
end

function CultivateTabView:refreshInfoPanel(notRefreshContainer)
  self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(math.floor(self.cardOriginalProperties.att))
  self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(math.floor(self.cardOriginalProperties.def))
  self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(math.floor(self.cardOriginalProperties.hp))
  
  self:refreshTrainAdditionalStatus(notRefreshContainer)

  self:refreshTrainLvlBtnStatus()

  self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(tostring(self.nowPotential))

  self:refreshTrainActnBtnStatus()

  --add by zheng.che @ 2014-8-25
  if not ItemManager.checkCardTypeCanTrain(self.parentView.metaId) then
  	--不允许培养的卡牌
  	--不显示各种说明文本
  	self.panelUI:getChildByName("txt_4"):setVisible(false)
  	self.panelUI:getChildByName("halfblack_combination"):setVisible(false)
  	self.panelUI:getChildByName("txt_7"):setVisible(false)
  	self.panelUI:getChildByName("txt_8"):setVisible(false)
  	self.panelUI:getChildByName("card_lbl_parameter_add_pp"):setVisible(false)
  	self.panelUI:getChildByName("txt_5"):setVisible(false)
  	self.panelUI:getChildByName("Prop_huni0_calnar"):setVisible(false)
  	self.panelUI:getChildByName("txt_6"):setVisible(false)

  	--按钮禁用
  	self.trainActnBtn[2]:setEnable(false)
    self.trainActnBtn[2].display:getChildByName("btn"):setVisible(false)

  	--显示无法培养提示文本和背景
  	-- self.panelUI:getChildByName("yellow9_panel"):setVisible(true)
  	self.panelUI:getChildByName("txt_activity_3_5"):setVisible(true)
  	self.panelUI:getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(Localization:getInstance():getText("cardTrainLimited"))--此武将不能进行培养

  	--
  	-- self.panelUI:getChildByName("yellow9_panel").touchEnabled = true
  	self.panelUI:getChildByName("txt_activity_3_5").touchEnabled = true
  else
  	--允许培养
  	-- self.panelUI:getChildByName("yellow9_panel"):setVisible(false)
  	self.panelUI:getChildByName("txt_activity_3_5"):setVisible(false)

  	--
  	-- self.panelUI:getChildByName("yellow9_panel").touchEnabled = false
  	self.panelUI:getChildByName("txt_activity_3_5").touchEnabled = false
  end
end

function CultivateTabView:refreshTrainLvlBtnStatus()
	for key, value in ipairs(self.trainLvlBtn) do
	  	if key == self.trainLevelSelected then
	  		value.display:getChildByName("bg_cardTraining_optionSelected"):setVisible(true)
	  		value:setEnable(false)
	  	else
	  		value.display:getChildByName("bg_cardTraining_optionSelected"):setVisible(false)
	  		value:setEnable(true)
	  	end
	end
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(self.desStrList[self.trainLevelSelected])
end

function CultivateTabView:refreshTrainAdditionalStatus(notRefreshContainer)
  local numTable = nil
  if self.trainStatus then
  	numTable = {
      self.labelTable.atk and self.labelTable.atk or 0,
      self.labelTable.def and self.labelTable.def or 0,
      self.labelTable.hp and self.labelTable.hp or 0,
  	}
  	numTable[4] = -(numTable[1] + numTable[2] + numTable[3])
  	for key, aNumber in ipairs( numTable ) do
      if (aNumber==0) then
	  	self.additionalLabelList[key]:setVisible(false)
      else
	  	local sprite = self.additionalLabelList[key]
      	if (aNumber>0) then
          self.additionalLabelList[key] = createNumberEffect(aNumber, sprite:getPosition().x, sprite:getPosition().y, NumberColorEnum.green, true, 1.2, true)
      	else
          self.additionalLabelList[key] = createNumberEffect(aNumber, sprite:getPosition().x, sprite:getPosition().y, NumberColorEnum.red, true, 1.2, true)
      	end
	  	sprite:setVisible(false)
      end
	  self.panelUI:addChild(self.additionalLabelList[key])
  	end
  else
  	for _, aAdditionalLabel in ipairs(self.additionalLabelList) do
  		aAdditionalLabel:setVisible(false)
  	end
  end
  self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(tostring(self.soulStone.amount))

  --numTable[4] = false
  self.parentView:refreshCardInfoForTrain(numTable, notRefreshContainer)
end

function CultivateTabView:refreshTrainActnBtnStatus()
  if self.trainStatus then
  	self.trainActnBtn[1].display:setVisible(true)
  	self.trainActnBtn[1]:setEnable(true)
  	self.trainActnBtn[2].display:getChildByName("txt_btn_friend_ChangeBtn"):setString(Localization:getInstance():getText("cardTrain_saveBtn"))
  	self.trainActnBtn[3].display:setVisible(true)
  	self.trainActnBtn[3]:setEnable(true)
  else
  	self.trainActnBtn[1].display:setVisible(false)
  	self.trainActnBtn[1]:setEnable(false)
  	self.trainActnBtn[2].display:getChildByName("txt_btn_friend_ChangeBtn"):setString(Localization:getInstance():getText("cardTrain_Btn"))
  	self.trainActnBtn[3].display:setVisible(false)
  	self.trainActnBtn[3]:setEnable(false)
  end
end

function CultivateTabView:trainCard( trainOpts )
  local function closeParentPanel()
  	PopoutManager:sharedManager():pullin(self.parentView, kPopoutDir.kScale )
  end
  --金币检查
  if (trainOpts.special) then
    local gemsNow = CalculationManager.calcComplex_getGemsNow()
    if (gemsNow < trainOpts.trainTimes * self.trainConfig.ybCost) then
      local aPanel = AssistantMessageBoxPanel:create( self.parentView.container, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = closeParentPanel} )
      self.parentView.container:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
  end
  
  --物品数量检查
  if (self.soulStone.amount < (trainOpts.trainTimes * self.trainConfig.pydCost) ) then
    local aPanel = AssistantMessageBoxPanel:create( self.parentView.container, AsMessageBoxType.notEnoughSoulStone, nil, {onReplaceSceneFunc = closeParentPanel} )
    self.parentView.container:addChild(aPanel)
    aPanel:scaleIn()
    return
  end
  
  local function afterTrainCard(event)
    self.labelTable = {}
    for key, value in pairs(event.data) do
      if (key=="attTrainValue") then
        self.labelTable.atk = value
		if (value>0) then
			self.fireOnIcon = 1
		end
      elseif (key=="defTrainValue") then
        self.labelTable.def = value
		if (value>0) then
			self.fireOnIcon = 2
		end
      elseif (key=="hpTrainValue") then
        self.labelTable.hp = value
		if (value>0) then
			self.fireOnIcon = 3
		end
      end
    end
	self.soulStone.amount = self.soulStone.amount - trainOpts.trainTimes * self.trainConfig.pydCost
	local negativeReward = {
		{	itemType = ResourceEnum.GEMS,
			amount = (trainOpts.special) and (-1 * trainOpts.trainTimes * self.trainConfig.ybCost) or 0,
		},
		{	itemType = ResourceEnum.PROP,
			metaId = self.trainConfig.pydMetaId,
			amount = (-1 * trainOpts.trainTimes * self.trainConfig.pydCost)
		}
	}
	RewardManager:getReward(negativeReward)
	
    self.trainStatus = true
    local GameInitData = DataManager.getGameInitData()
    GameInitData.sharkCards["trainCardId"] = trainOpts.cardId
    GameInitData.sharkCards["trainValueSaved"] = false
    GameInitData.sharkCards["unsavedAttTrainValue"] = event.data.attTrainValue
    GameInitData.sharkCards["unsavedDefTrainValue"] = event.data.defTrainValue
    GameInitData.sharkCards["unsavedHpTrainValue"] = event.data.hpTrainValue
    DataManager.setGameInitData(GameInitData)
    
    self:refreshTrainAdditionalStatus(true)
    self:refreshTrainActnBtnStatus()
  end
  
  --构造请求
  local request = CardTrainingRequest.new( trainOpts, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.TrainCardSucceed, afterTrainCard )
  --发送请求
  request:start()
end

function CultivateTabView:giveUpCardTrain( params, noRefresh )
  local function afterGiveUPTrain(event)
    self.trainStatus = false
    local GameInitData = DataManager.getGameInitData()
    GameInitData.sharkCards["trainValueSaved"] = true
    DataManager.setGameInitData(GameInitData)
	if ( not noRefresh) then
		self:refreshTrainAdditionalStatus(true)
    	self:refreshTrainActnBtnStatus()
	end

	self.parentView:judgeForceClose()
  end
  
  --构造请求
  local request = GiveUpCardTrainRequest.new( params, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.GiveUpCardTrainSucceed, afterGiveUPTrain )
  --发送请求
  request:start()
end

function CultivateTabView:saveCardTrain( params )
  local function afterSaveTrain(event)
	--self:playFireOnIcon(self.fireOnIcon)
	local aCardMetaConfig = MetaManager.card_meta[self.parentView.metaId]
    local aCardRareConfig = MetaManager.card_rare[aCardMetaConfig.rare]
    self.nowPotential = aCardRareConfig.addPotential * self.parentView.level - event.data.sharkCard.usedPotential
	
	local CardsData = DataManager.getCardsData()
	for key,aCard in pairs(CardsData) do
		if (aCard.cardId == event.data.sharkCard.cardId) then
			CardsData[key] = event.data.sharkCard
      --如果是阵列中的卡牌，就清空g_previousBonusTable
      local queueData = {}
      local matrixCardData = CommonManager:getMatrixCardData()
      for k,v in ipairs(matrixCardData) do 
        if not queueData[v] then
          queueData[v] = k + 100
        end
      end
      if queueData[aCard.cardId] and queueData[aCard.cardId] > 100 then
        g_previousBonusTable = nil;
      end

			break
		end
	end
	DataManager.setCardsData(CardsData)
	local GameInitData = DataManager.getGameInitData()
	GameInitData.sharkCards["trainValueSaved"] = true
	DataManager.setGameInitData(GameInitData)
	self.cardOriginalProperties = CommonManager:getSimpleCardProperties(self.parentView.cardId)
	self:refreshInfoPanel()
	--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
	DataManager.fightCapacityMaybeUpdated()

	self.parentView:judgeForceClose()
  end
  
  --构造请求
  local request = SaveCardTrainRequest.new( params, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.SaveCardTrainSucceed, afterSaveTrain )
  --发送请求
  request:start()
end

--
-- MetempsychosisTabView
--

MetempsychosisTabView = class(Layer)

function MetempsychosisTabView:ctor()
    self.parentView = nil
    self.builder = nil
    self.table_meta_info = nil
    self.strengthenCardData = nil
    self.bottomPanelView = nil
    self.allSelectButton = nil
    self.panelView = nil
    self.tipView = nil
    self.cardTempView = nil
    self.cardButtons = {}
    self.pageUpButton = nil
    self.pageDownButton = nil
    self.evolveButton = nil
    self.evolvePrice = 0
end

function MetempsychosisTabView:create(aParentView)
    local s = MetempsychosisTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function MetempsychosisTabView:initLayer()
	MetempsychosisTabView.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	self.builder = builder
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_details_card_02")
    self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"):setVisible(false)
    self.panelUI:getChildByName("btn_chr3"):setVisible(false)
	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)--一键完美才用的问号按钮
    self:addChild(self.panelUI)

    local table_temp_view = self.panelUI:getChildByName("details_card_list")
	table_temp_view:setVisible(false)
	local table_meta_info = getTableViewSizes(table_temp_view)
	self.table_meta_info = table_meta_info
	self.table_meta_info.table_posY = self.table_meta_info.table_posY-- + 20
	self.matterCardData = self:getMatterCardData()

	self.tipView = self.panelUI:getChildByName("txt_activity_3_5")

	self.panelView = builder:build("list/skillup_detailscard_list_2")
	self.panelView:setPositionXY(table_meta_info.table_posX, table_meta_info.table_posY)
	self:addChild(self.panelView)

	self.panelView:getChildByName("email_control_all_select"):setVisible(false)
	self.panelView:getChildByName("txt_15"):setVisible(false)
	self.panelView:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("cardEvolve_CardText1"))
	self.panelView:getChildByName("txt_2"):setVisible(false)
	self.cardTempView = self.panelView:getChildByName("skillup_item1")
	self.cardTempView:setVisible(false)

	local pageUpDisplay = self.panelView:getChildByName("skillup_btn_pgup")
	pageUpDisplay:getChildByName("txt"):setString(getTextByKey("skill_pageUpBtn"))
	local function onClickpageUp(evt)
		self.matterCardData.curPage = self.matterCardData.curPage - 1
		self:refreshInfoPanel()
	end
	self.pageUpButton = Button:create(pageUpDisplay)
	self.pageUpButton:addEventListener(Events.kStart, onClickpageUp)
	local pageDownDisplay = self.panelView:getChildByName("skillup_btn_pgdown")
	pageDownDisplay:getChildByName("txt"):setString(getTextByKey("skill_pageDownBtn"))
	local function onClickpageDown(evt)
		self.matterCardData.curPage = self.matterCardData.curPage + 1
		self:refreshInfoPanel()
	end
	self.pageDownButton = Button:create(pageDownDisplay)
	self.pageDownButton:addEventListener(Events.kStart, onClickpageDown)

	self.bottomPanelView = self.panelUI:getChildByName("detailscard_getall_bottom")
	self.bottomPanelView:getChildByName("txt_4"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_5"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_6"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_7"):setVisible(false)
	self.bottomPanelView:getChildByName("icon_silverCoin"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_8"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_12"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_9"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_13"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_10"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_14"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_11"):setVisible(false)
	self.bottomPanelView:getChildByName("txt_17"):getChildByName("txt"):setString(getTextByKey("cardEvolve_CoinConsume"))

	local function onClickEvolve(evt)
		if tonumber(DataManager.getCurrUser().coins) < self.evolvePrice then
			local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCoinLimit)
			self.parentView.container:addChild(aPanel)
			aPanel:scaleIn()
			return
		end
		local slaveCard = self.matterCardData.cardTable[self.matterCardData.selectCardIndex]
		local masterId= self.parentView.cardId
        local slaveId = slaveCard.cardId
		local function CardEvolutionFailed(params)
			if params.data == 710512 then
				local aPanel = MessageBoxPanel:create(self.parentView.container, MessageBoxType.kCoinLimit)
				self.parentView.container:addChild(aPanel)
				aPanel:scaleIn()
			else
				CanonMessageBox:showCommUnHandleErrorBox(params.data)
			end
		end
        local function CardEvolutionCallback(e)
			g_previousBattleCount = CommonManager:getLocalPlayerStrength()
			local dirtyCardIds = {}
			table.insert(dirtyCardIds, masterId)
			table.insert(dirtyCardIds, slaveId)
			CommonManager:setCardNeedUpdate(dirtyCardIds)
			local tempLayer = Layer:create()
			tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
			self:addChild(tempLayer)
            local function onFlashAnimationEnd(evt)
				if self.flashMov then
					self.flashMov:unregisterEndAnimationScriptHandler()
				end
				self.flashMov_cocos:removeFromParentAndCleanup(true)
				tempLayer:removeFromParentAndCleanup(true)
				self.parentView:refreshCardInfoForEvolve({sharkCard = e.data.sharkCard, slaveCard = slaveCard})
				self.matterCardData = self:getMatterCardData()
				self:refreshInfoPanel()
				--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
				DataManager.fightCapacityMaybeUpdated()
				Set_ShareData( "CardJJFinished", 1 )
				
				--facebook share card evolusion
				if FacebookShareManager.isOpenFacebookShareFunc() then
					local evolutedCardMetaId = e.data.sharkCard.metaId
					local evolutedCardInfo = MetaManager.card_meta[evolutedCardMetaId]
					local evolutedCardRare = evolutedCardInfo.rare
					local evolutedCardCurEvoLevel = evolutedCardInfo.evolutionLevel
					local evolutedCardMaxEvoLevel = evolutedCardInfo.maxEvolvedLevel
					if evolutedCardRare == 5 then
						--五星卡牌进阶分享
						if FacebookShareManager.facebookShareCardEvolusion(FacebookCardEvolutionShareID.STAR5CARD_FIRST_EVO_SHAREID) then
							--第一次进阶分享
						elseif evolutedCardCurEvoLevel == evolutedCardMaxEvoLevel then
							--Max进阶分享
							FacebookShareManager.facebookShareCardEvolusion(FacebookCardEvolutionShareID.STAR5CARD_MAX_EVO_SHAREID)
						end
					elseif evolutedCardRare == 6 then
						--六星卡牌进阶分享
						if FacebookShareManager.facebookShareCardEvolusion(FacebookCardEvolutionShareID.STAR6CARD_FIRST_EVO_SHAREID) then
							--第一次进阶分享
						elseif evolutedCardCurEvoLevel == evolutedCardMaxEvoLevel then
							--Max进阶分享
							FacebookShareManager.facebookShareCardEvolusion(FacebookCardEvolutionShareID.STAR6CARD_MAX_EVO_SHAREID)
						end
					end
				end
            end         
			CanonPlayEffect("music/sfx_card_evolve.wav")
            self.flashMov = FlashSprite:create("EVO2/FZZZZ2")   
			local card1_spf = getCardSpriteFrame(self.parentView.metaId)  
            self.flashMov:addChangeInstance("card1", card1_spf)
			local tmeta = MetaManager.card_meta[tonumber(self.parentView.metaId)]
			local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
			self.flashMov:addChangeInstance("cardcountry1", countrySpriteFrame)
			local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
			self.flashMov:addChangeInstance("cardBorder1", boardSpriteFrame)
			local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
			self.flashMov:addChangeInstance("cardBg1", cardBgSpriteFrame)
			local card2_spf = getCardSpriteFrame(slaveCard.metaId)  
            self.flashMov:addChangeInstance("card2", card2_spf)
			local tmeta = MetaManager.card_meta[tonumber(slaveCard.metaId)]
			local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
			self.flashMov:addChangeInstance("cardcountry2", countrySpriteFrame)
			local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
			self.flashMov:addChangeInstance("cardBorder2", boardSpriteFrame)
			local card3_spf = getCardSpriteFrame(MetaManager.card_meta[tonumber(self.parentView.containerData.metaId)].evolutionCardId)  
			local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
			self.flashMov:addChangeInstance("cardBg2", cardBgSpriteFrame)
            self.flashMov:addChangeInstance("card3", card3_spf)
			local tmeta = MetaManager.card_meta[tonumber(MetaManager.card_meta[tonumber(self.parentView.containerData.metaId)].evolutionCardId)]
			local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
			self.flashMov:addChangeInstance("cardcountry3", countrySpriteFrame)
			local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
			self.flashMov:addChangeInstance("cardBorder3", boardSpriteFrame)
			local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
			self.flashMov:addChangeInstance("cardBg3", cardBgSpriteFrame)
            --self.flashMov:registerFlashScriptHandler(onFlashEvent)   
			self.flashMov:changeAnimation(0)	
			self.flashMov:setLoop(false)
            self.flashMov:registerEndAnimationScriptHandler(onFlashAnimationEnd)
            self.flashMov_cocos = CocosObject.new(self.flashMov)
            self:addChild(self.flashMov_cocos)  
			
			local cardData = DataManager.getCardsData()
			local toremoveKeys = {}
			for k,card in ipairs(cardData)
			do
				if card.cardId == masterId then
					cardData[k] = e.data.sharkCard
					cardData[k].avatarMetaId = 0
				elseif card.cardId == slaveId then
					table.insert(toremoveKeys, k)
				end
			end
			for i = #toremoveKeys, 1, -1
			do
				table.remove(cardData, toremoveKeys[i])
			end
			DataManager.setCardsData(cardData)
			local rewardTable = {}
			table.insert(rewardTable, {itemType = ResourceEnum.COIN, amount = -self.evolvePrice})
			RewardManager:getReward(rewardTable)
			end
        local params={masterId=masterId,slaveId=slaveId}
        local request = CardEvolutionRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.CardEvolutionSucceed, CardEvolutionCallback )
        request:addEventListener( RequestNotifyEnum.CardEvolutionFailed, CardEvolutionFailed )
        request:start()
	end
	local evolveBtnDisplay = self.panelUI:getChildByName("friend_btn_cardnew")
	evolveBtnDisplay:getChildByName("txt_btn_friend_ChangeBtn"):setString(getTextByKey("cardEvolve_EvolveBtn"))
	self.evolveButton = Button:create(evolveBtnDisplay)
	self.evolveButton:addEventListener(Events.kStart, onClickEvolve)

	self:refreshInfoPanel()
end

function MetempsychosisTabView:getMatterCardData()
	local result = {cardTable = {}, curPage = 1, maxPage = 0, selectCardIndex = 0}
	local queueData = CommonManager.getQueueData()
	for k, v in pairs(CommonManager:getMatrixCardData()) do
		table.insert(queueData, v)
	end
	local cardList = DataManager.getCardsData()
	--阵容状态（不可转生）
	local queueList = {}
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
	--end by l1ghtsaber 2
    for k,card in pairs(cardList) do
    	if not card.lock then
	        local masterCardGroupId = MetaManager.card_meta[self.parentView.containerData.metaId].cardGroupId
	        local slaveCardGroupId  = MetaManager.card_meta[card.metaId].cardGroupId
	        local masterEvolutionLevel = MetaManager.card_meta[self.parentView.containerData.metaId].evolutionLevel
	        local slaveEvolutionLevel  = MetaManager.card_meta[card.metaId].evolutionLevel



			--检验是否万能转生卡
			local isBronCard = false
			local cardType = ItemManager.getCardTypeByMetaId(card.metaId)
			if cardType == ItemManager.CARD_TYPE_BRON then
				--是万能转生卡
				--验证星级是否匹配
				local masterCardRare = MetaManager.card_meta[self.parentView.containerData.metaId].rare
				local slaveCardRare  = MetaManager.card_meta[card.metaId].rare
				if masterCardRare == slaveCardRare then
					isBronCard = true
				end
			end

	        if ((tonumber(masterCardGroupId) == tonumber(slaveCardGroupId)) and        --cardGroupId相同
	           (tonumber(masterEvolutionLevel) >= tonumber(slaveEvolutionLevel)) and--化等级低于或等于主卡牌
			   (tonumber(self.parentView.cardId) ~= tonumber(card.cardId))) or -- not masterCard
			   (isBronCard) then --(或)是万能转生卡

			    local inQueue = false
			    for _,value in pairs(queueData) do
					if tonumber(value) == tonumber(card.cardId) then
						inQueue = true
						break
					end
				end

				if queueList[card.cardId] == true then inQueue = true end --add by l1ghtsaber 2 

				if not inQueue then
					--local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCard( card )
					--[[
					card.resultExp   = math.floor(cardStatus.resultExp)
					card.price = cardStatus.price
					card.rare = MetaManager.card_meta[card.metaId].rare]]
					card.cardName = MetaManager.card_meta[card.metaId].name
					table.insert(result.cardTable,card)
				end
	        end
	    end
    end
    result.maxPage = math.floor((table.getn(result.cardTable) - 1) / 8 + 1)
    return result
end

function MetempsychosisTabView:refreshInfoPanel()
	local aCardMetaConfig = MetaManager.card_meta[self.parentView.containerData.metaId]
	local function onClickCardButton(evt)
		if self.matterCardData.cardTable[evt.context].lock then
			SuspensionLabel:showContent(self.parentView.container, Localization:getInstance():getText("card_lockedTips_evolve"))
			return
		end
		if self.matterCardData.selectCardIndex == evt.context then
			self.cardButtons[math.mod(self.matterCardData.selectCardIndex - 1, 8) + 1].display:getChildByName("skillup_icon_selected"):setVisible(false)
			self.matterCardData.selectCardIndex = 0
		else
			if self.matterCardData.selectCardIndex > (self.matterCardData.curPage - 1) * 8 and 
				self.matterCardData.selectCardIndex <= self.matterCardData.curPage * 8 then
				self.cardButtons[math.mod(self.matterCardData.selectCardIndex - 1, 8) + 1].display:getChildByName("skillup_icon_selected"):setVisible(false)
			end
			self.matterCardData.selectCardIndex = evt.context
			self.cardButtons[math.mod(self.matterCardData.selectCardIndex - 1, 8) + 1].display:getChildByName("skillup_icon_selected"):setVisible(true)
		end
		if self.matterCardData.selectCardIndex == 0 then
			self.evolvePrice = 0
			self.evolveButton.display:getChildByName("btn"):setVisible(false)
			self.evolveButton:setEnable(false)
			self.parentView:refreshCardInfoForEvolve({})
		else
			self.evolvePrice = MetaManager.card_evolve[aCardMetaConfig.evolutionLevel + 1].evolvePrice
			self.evolveButton.display:getChildByName("btn"):setVisible(true)
			self.evolveButton:setEnable(true)
			self.parentView:refreshCardInfoForEvolve({slaveCard = self.matterCardData.cardTable[self.matterCardData.selectCardIndex]})
		end
		self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setString("" .. self.evolvePrice)
		if self.evolvePrice > tonumber(DataManager.getCurrUser().coins) then
			self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
		else
			self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
		end
	end
	
	local aCardEvolveConfig = MetaManager.card_evolve[aCardMetaConfig.evolutionLevel]
	if not ItemManager.checkCardTypeCanEvolve(self.parentView.metaId) then
		--不允许进化的卡牌 add by zheng.che @ 2014-8-25
		--不显示界面
		self.panelView:setVisible(false)

		--不显示下边的各种文本 只留底框
		self.bottomPanelView:getChildByName("txt_17"):setVisible(false)
		self.bottomPanelView:getChildByName("icon_silverCoin2"):setVisible(false)
		self.bottomPanelView:getChildByName("txt_16"):setVisible(false)

		self.tipView:setVisible(true)
		self.tipView:getChildByName("txt"):setString(getTextByKey("cardEvolveLimited"))--此武将不能进行转生。
		self.evolvePrice = 0
    elseif aCardMetaConfig.evolutionLevel >= aCardMetaConfig.maxEvolvedLevel then 
    	self.panelView:setVisible(false)
		self.tipView:setVisible(true)
		self.tipView:getChildByName("txt"):setString(getTextByKey("cardEvolveResult_maxLevel"))
		self.evolvePrice = 0
	elseif tonumber(self.parentView.level) < tonumber(aCardEvolveConfig.evolveNeedLevel) then
		self.panelView:setVisible(false)
		self.tipView:setVisible(true)
		self.tipView:getChildByName("txt"):setString(getTextByKey("cardEvolve_levelTip", {lv = tonumber(aCardEvolveConfig.evolveNeedLevel)}))
		self.evolvePrice = 0
	elseif #self.matterCardData.cardTable == 0 then
		self.panelView:setVisible(false)
		self.tipView:setVisible(true)
		self.tipView:getChildByName("txt"):setString(getTextByKey("cardEvolve_NoCardTxt"))
		self.evolvePrice = 0
	else
		self.panelView:setVisible(true)
		self.tipView:setVisible(false)
		local cellIndexDownLimit = (self.matterCardData.curPage - 1) * 8 + 1
		local cellIndexUpLimit = (self.matterCardData.curPage * 8 <= #self.matterCardData.cardTable) and self.matterCardData.curPage * 8 or #self.matterCardData.cardTable
		for i = #self.cardButtons, 1, -1 do
			self.cardButtons[i].display:removeFromParentAndCleanup(true)
			self.cardButtons[i] = nil
		end
		for i = cellIndexDownLimit, cellIndexUpLimit do
			local item = self.builder:build("skillup_item")
			item:setPositionXY(self.table_meta_info.item_width / 2 + 154 * ((i - 1) % 4 - 2) + 12, self.cardTempView:getPositionY() - 148 * math.floor((math.mod(i-1,8)+1 - 1) / 4))
			self.panelView:addChildAt(item, 6)
			local aCardData = self.matterCardData.cardTable[i]
			local newMetaId =CommonManager:changeAvatarByCardInfo( aCardData )
			local perfectType = 0
			local cardMeta = MetaManager.card_meta[aCardData.metaId]
			if CommonManager:checkIsCardPerfect(aCardData) then
				if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
					perfectType = CardPerfectEnum.goldLeft
				else
					perfectType = CardPerfectEnum.silverLeft
				end
			end
			local cardIcon = getHeadIconCanonCardByMetaId(newMetaId, aCardData.lock,perfectType)
			cardIcon:setScale(0.85)
			item:getChildByName("reward_item"):getChildByName("normal_card_small"):setVisible(false)
			local aPosX = item:getChildByName("reward_item"):getChildByName("normal_card_small"):getPositionX()
			local aPosY = item:getChildByName("reward_item"):getChildByName("normal_card_small"):getPositionY()
			cardIcon:setPositionXY(aPosX, aPosY)
			item:getChildByName("reward_item"):addChild(cardIcon)
			item:getChildByName("lv_txt"):getChildByName("txt"):setString("LV." .. aCardData.level)
			item:getChildByName("reward_item"):getChildByName("txt_item_name"):getChildByName("txt"):setString(getTextByKey(MetaManager.card_meta[aCardData.metaId].name))
			local aCardButton = Button:create(item)
			aCardButton:addEventListener(Events.kStart, onClickCardButton, i)
			table.insert(self.cardButtons, aCardButton)
			if i == self.matterCardData.selectCardIndex then
				item:getChildByName("skillup_icon_selected"):setVisible(true)
			else
				item:getChildByName("skillup_icon_selected"):setVisible(false)
			end
		end
		if self.matterCardData.curPage > 1 then
			self.pageUpButton:setEnable(true)
			self.pageUpButton.display:getChildByName("btn_d_many"):setVisible(true)
		else
			self.pageUpButton:setEnable(false)
			self.pageUpButton.display:getChildByName("btn_d_many"):setVisible(false)
		end
		if self.matterCardData.curPage < self.matterCardData.maxPage then
			self.pageDownButton:setEnable(true)
			self.pageDownButton.display:getChildByName("btn_d_many"):setVisible(true)
		else
			self.pageDownButton:setEnable(false)
			self.pageDownButton.display:getChildByName("btn_d_many"):setVisible(false)
		end
		self.panelView:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("skill_pageNum") .. tostring(self.matterCardData.curPage) .. "/" .. tostring(self.matterCardData.maxPage))
		if self.matterCardData.selectCardIndex == 0 then
			self.evolvePrice = 0
		else
			self.evolvePrice = MetaManager.card_evolve[aCardMetaConfig.evolutionLevel + 1].evolvePrice
		end
	end
	self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setString("" .. self.evolvePrice)
	if self.evolvePrice > tonumber(DataManager.getCurrUser().coins) then
		self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
	else
		self.bottomPanelView:getChildByName("txt_16"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
	end
	if self.evolvePrice == 0 then
		self.evolveButton.display:getChildByName("btn"):setVisible(false)
		self.evolveButton:setEnable(false)
		self.parentView:refreshCardInfoForEvolve({})
	else
		self.evolveButton.display:getChildByName("btn"):setVisible(true)
		self.evolveButton:setEnable(true)
		self.parentView:refreshCardInfoForEvolve({slaveCard = self.matterCardData.cardTable[self.matterCardData.selectCardIndex]})
	end
	
end

--
-- SkillTabView
--

SkillTabView = class(Layer)

function SkillTabView:ctor()
    self.parentView = nil
    self.panelUI = nil
    self.skillDataList = nil
    self.hasMainSkill = false
    self.hasSkill = false
end

function SkillTabView:create(aParentView)
    local s = SkillTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function SkillTabView:initLayer()
	SkillTabView.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	self.builder = builder
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_details_card_05")
    self:addChild(self.panelUI)

    self.skillDataList = self.parentView.containerData.cardSkills
    for _, aSkillData in pairs(self.skillDataList) do
    	if aSkillData.skillType == 2 then
    		self.hasMainSkill = true
    		break
    	end
    end
    self.hasSkill = (#self.skillDataList > 0)
    self:refreshInfoPanel()
end

function SkillTabView:refreshInfoPanel()
	local function upgradeSkill( evt )
		local aSkillData = evt.context
		if self.parentView.level < aSkillData.skillLevel * 10 then
			SuspensionLabel:showContent(self.parentView.container, getTextByKey("skill_skillUpgradeLevelLimit") .. aSkillData.skillLevel * 10)
			return
		end
		local newScene = SkillUpgradeScene:create( self.parentView.cardId, aSkillData.skillId, aSkillData.skillName, aSkillData.skillLevel, aSkillData.skillLevel+1, aSkillData.maxLevel, self.parentView.container.curSceneEnum, true )
    	Director:sharedDirector():replaceScene( newScene )
	end

	local function updateSkillView(skillView, aSkillData)
		local aSkillMeta = MetaManager.skill_meta[aSkillData.skillId]
		skillView:getChildByName("txt_2"):getChildByName("txt"):setString(Localization:getInstance():getText(aSkillMeta.name))
		skillView:getChildByName("txt_3"):getChildByName("txt"):setString(tostring(aSkillMeta.level))
		local skillFigure = CanonItem:create()
	    skillFigure:loadByMetaId(aSkillMeta["id"])
		local position = skillView:getChildByName("card_normal_card_small_sb"):getPosition()
		skillFigure:setPosition(ccp(position.x,position.y))
		skillView:addChild(skillFigure)
	  	skillView:getChildByName("card_normal_card_small_sb"):setVisible( false )
		local skillStatus = aSkillMeta.statusIdList:split("|") --当前级别
		local numTable = {}
		for i=1,#skillStatus do
		    if (skillStatus[i]~="0") then
		      	local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
		      	numTable["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
		    else
		      	numTable["num"..i] = nil
		    end
	  	end
	  	print("~~~~~~~~~~~~~~aSkillMeta.desc = "..tostring(aSkillMeta.desc))
		skillView:getChildByName("txt_5"):getChildByName("txt"):setString(Localization:getInstance():getText( aSkillMeta.desc,numTable ))
		local nextLevelTipLabel = skillView:getChildByName("txt_7")
		local nextLevelPic = skillView:getChildByName("card_icon_lv_no_sb2")
		local nextLevelNumLabel = skillView:getChildByName("txt_4")
		local nextLevelDesLabel = skillView:getChildByName("txt_6")
		local upgradeBtnDisplay = skillView:getChildByName("btn_the_choose")
		local maxLevel = SkillEvolveScene.getMaxLv(aSkillMeta.skillGroupId)
  		local whetherLevelMax = ( aSkillMeta.level >= maxLevel )
  		if whetherLevelMax then
  			upgradeBtnDisplay:setVisible(false)
  			nextLevelTipLabel:setVisible(false)
  			nextLevelPic:setVisible(false)
  			nextLevelNumLabel:setVisible(false)
  			nextLevelDesLabel:getChildByName("txt"):setString(getTextByKey("skillEnhance_Tips"))
  		else
  			nextLevelTipLabel:setVisible(true)
  			nextLevelTipLabel:getChildByName("txt"):setString(getTextByKey( "skill_nextLevelText" ))
  			nextLevelPic:setVisible(true)
  			nextLevelNumLabel:setVisible(true)
  			nextLevelNumLabel:getChildByName("txt"):setString(tonumber(aSkillMeta.level + 1))
  			local nextSkillMeta
  			for _, temp in pairs(MetaManager.skill_meta) do
  				if (temp.skillGroupId == aSkillMeta.skillGroupId) and (temp.level == (aSkillMeta.level + 1)) then
  					nextSkillMeta = temp
  					break
  				end
  			end
		    local skillStatus2 = nextSkillMeta.statusIdList:split("|")
		    local numTable2 = {}
		    for i=1,#skillStatus2 do
		      if (skillStatus2[i]~="0") then
		        local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus2[i])]
		        numTable2["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
		      else
		        numTable2["num"..i] = nil
		      end
		    end
  			nextLevelDesLabel:getChildByName("txt"):setString(Localization:getInstance():getText( nextSkillMeta.desc, numTable2 ))
  			upgradeBtnDisplay:setVisible(true)
  			upgradeBtnDisplay:getChildByName("txt"):setString(getTextByKey("skill_EnhanceBtn"))
  			local upgradeButton = Button:create(upgradeBtnDisplay)
  			local btnArgs = {skillId = aSkillData.skillId, skillName = getTextByKey(aSkillMeta.name), skillLevel = aSkillMeta.level, maxLevel = maxLevel}
			upgradeButton:addEventListener(Events.kStart, upgradeSkill, btnArgs)
  		end
	end

	if self.hasMainSkill then
		self.panelUI:getChildByName("skills2_list"):setVisible(false)
		self.panelUI:getChildByName("skills3_list"):setVisible(false)
		self.panelUI:getChildByName("list"):setVisible(true)
		self.panelUI:getChildByName("list2"):setVisible(true)
		local aMainSkillData
		local aNormalSkillData
		for _, aSkillData in pairs(self.skillDataList) do
	    	if aSkillData.skillType == 1 then
	    		aNormalSkillData = aSkillData
	    	end
	    	if aSkillData.skillType == 2 then
	    		aMainSkillData = aSkillData
	    	end
	    end
	    local mainSkillView = self.panelUI:getChildByName("list")
		mainSkillView:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("skillInfo_MainCardSkill"))
		updateSkillView(mainSkillView, aMainSkillData)
		local normalSkillView = self.panelUI:getChildByName("list2")
		normalSkillView:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("skillInfo_CardSkill"))
		updateSkillView(normalSkillView, aNormalSkillData)
	elseif self.hasSkill then
		self.panelUI:getChildByName("skills2_list"):setVisible(true)
		self.panelUI:getChildByName("skills3_list"):setVisible(false)
		self.panelUI:getChildByName("list"):setVisible(false)
		self.panelUI:getChildByName("list2"):setVisible(false)
		local skillView = self.panelUI:getChildByName("skills2_list")
		skillView:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("skillInfo_CardSkill"))
		local aNormalSkillData
		for _, aSkillData in pairs(self.skillDataList) do
	    	if aSkillData.skillType == 1 then
	    		aNormalSkillData = aSkillData
	    		break
	    	end
	    end
		updateSkillView(skillView, aNormalSkillData)
	else
		self.panelUI:getChildByName("skills2_list"):setVisible(false)
		self.panelUI:getChildByName("skills3_list"):setVisible(true)
		self.panelUI:getChildByName("list"):setVisible(false)
		self.panelUI:getChildByName("list2"):setVisible(false)
		self.panelUI:getChildByName("skills3_list"):getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(getTextByKey("cardDetail_noSkill"))
	end
end






tabTypeEnum = {
	introduction = 1,
	strengthen = 2,
	cultivate = 3,
	metempsychosis = 4,
	skill = 5,
}

local tabViewList = {
	IntroductionTabView,
	StrengthenTabView,
	CultivateTabView,
	MetempsychosisTabView,
	SkillTabView,
}

--
-- CardInfoNewPanel
--

CardInfoNewPanel = class(Layer)

function CardInfoNewPanel:ctor()
    self.container = nil
    self.metaId = nil
    self.cardFigure = nil
end

function CardInfoNewPanel:create( container , forceShowSell , index, extraArgs)
	self.forceShowSell = forceShowSell
    self.container = container
    self.containerData = self.container._data
	self.cardId = self.containerData.cardId
    self.metaId = CommonManager:changeAvatarByCardInfo( self.containerData )
    self.level = self.containerData.level
    self.exp = self.containerData.exp
    self.newIndex = index
    self.extraArgs = extraArgs or {}
	if (container.title == getTextByKey("formation_title")) then
		self.enterScene = "CardQueueScene"
		self.returnScene = "CardQueueScene"
	elseif (container.title == getTextByKey("matrix_enter")) then
		self.enterScene = "MatrixScene"
		self.returnScene = "MatrixScene"
	else
		self.enterScene = "BackpackScene"
		self.returnScene = "BackpackScene"
	end
    local s = CardInfoNewPanel.new()
    s:initLayer()
    return s
end

function CardInfoNewPanel:initLayer()
	CardInfoNewPanel.super.initLayer(self)
	self.container:setTableViewsEnabled(false)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_details_card")
    self:addChild(self.panelUI)

    self.panelUI:getChildByName("txt_distribution"):getChildByName("txt"):setString(Localization:getInstance():getText("cardInfo_Title"))

    local function onClosePanel(evt)
    	local function closeAction()
    		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	        self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
    	end
    	if not self:judgeTrainSavedOrNot(closeAction) then
    		return
    	end
        closeAction()
    end 
    local bt_panel_close = Button:create(self.panelUI:getChildByName("login_btn_close"))
    bt_panel_close:addEventListener(Events.kStart, onClosePanel)
    self:addChild(self.panelUI)

    self.onClickScope = function( event )
    	local function onGetCardBookSucceed(e)
    		local ownedCard = {}
			if e.data.sharkCardBook and e.data.sharkCardBook.cardMetaIds then
				for k,v in pairs(e.data.sharkCardBook.cardMetaIds) do
					if math.modf(self.metaId / 10) == math.modf(v / 10) then
						table.insert(ownedCard , v)
					end
				end
			end

			local function sortFunc( a , b )
				return a < b
			end
			table.sort(ownedCard , sortFunc)

			local function checkUserSameCardPic( a , b )
				local figureIdA = MetaManager.card_meta[a].figureId
				local figureIdB = MetaManager.card_meta[b].figureId
				if figureIdA == figureIdB then
					return true
				end
				return false
			end

			local i = 1
			while i <= #ownedCard do
				if ownedCard[i + 1] == nil then
					break
				end
				if checkUserSameCardPic(ownedCard[i] ,ownedCard[i + 1]) then
					table.remove(ownedCard , i)
				else
					i = i + 1
				end
			end

			local aPanel = CardSelectPanel:create( self.container , self , ownedCard)
			self.container.targetInfoPanel = aPanel
			PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false ,self.container)
    	end
		local request = GetCardBookRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GetCardBookSucceed, onGetCardBookSucceed)
		request:start()
	end
	local aScopeButton = Button:create(self.panelUI:getChildByName("icon_brush"))
	aScopeButton:addEventListener(Events.kStart, self.onClickScope, self)
	
	self.levelLabel = self.panelUI:getChildByName("txt_1")
    self.levelLabel1 = self.panelUI:getChildByName("card_icon_arrow_green_sb1")
    self.levelLabel2 = self.panelUI:getChildByName("txt_12")
    local sprite = Sprite:create(UI_RES_PATH.."/details_card/skillEnhance_expbar.png")
	local exp_pic = self.panelUI:getChildByName("expbar")
	sprite:setPosition(ccp(exp_pic:getPosition().x, exp_pic:getPosition().y))
	sprite:setAnchorPoint(exp_pic:getAnchorPoint())
	exp_pic:setVisible(false)--隐藏原进度条
	self.progress = ProgressBar:create(sprite) 
	self.panelUI:addChild(sprite)

	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("cardInfo_maxLevel"))
	self.levelUpLimit = self.panelUI:getChildByName("txt_10")
    self.levelUpLimit1 = self.panelUI:getChildByName("card_icon_arrow_green_sb2")
    self.levelUpLimit2 = self.panelUI:getChildByName("txt_7")

	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("cardInfo_EvolveLevel"))
	self.levelEvolveLabel = self.panelUI:getChildByName("txt_6")
    self.levelEvolveLabel1 = self.panelUI:getChildByName("card_icon_arrow_green_sb3")
    self.levelEvolveLabel2 = self.panelUI:getChildByName("txt_8")

    local function miaobian(label)
    	label:getChildByName("txt"):setColor(ccc3(89, 188, 62))
		label:getChildByName("txt"):setAroundColor(ccc3(0, 0, 0))
    end
    

	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("cardInfo_Leadership"))
	self.leadPointLabel = self.panelUI:getChildByName("txt_11")

	self.attLabel = self.panelUI:getChildByName("txt_5")
    self.defLabel = self.panelUI:getChildByName("txt_13")
    self.hpLabel = self.panelUI:getChildByName("txt_14")
    self.attLabel1 = self.panelUI:getChildByName("txt_9")
    self.defLabel1 = self.panelUI:getChildByName("txt_15")
    self.hpLabel1 = self.panelUI:getChildByName("txt_16")
    
    miaobian(self.attLabel1)
    miaobian(self.defLabel1)
    miaobian(self.hpLabel1)
    
    local tabUI = self.panelUI:getChildByName("details_card_title")
    local function onClickTab( e )
    	if (e.context.tabIndex == tabTypeEnum.cultivate) and (DataManager.getCurrUser().level < 19) then
    		SuspensionLabel:showContent(self.container, Localization:getInstance():getText("cardInfo_TrainLocked"))
    		return
    	end
    	local function changeAction()
    		if self:judgeForceClose() then
    			return
    		end
    		self:changeToTab(e.context.tabIndex)
    	end
    	if not self:judgeTrainSavedOrNot(changeAction) then
    		return
    	end
    	changeAction()
   	end
   	self.tabButtonList = {}
   	self.tabSelectedStateList = {}
   	self.tabUnselectedStateList = {}
   	local introductionTab = tabUI:getChildByName("btn_details_card_introductiontothecard")
    local aIntroductionButton = Button:create(introductionTab)	--简介
	aIntroductionButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.introduction})
	table.insert(self.tabButtonList, aIntroductionButton)
	table.insert(self.tabSelectedStateList, {introductionTab:getChildByName("lbl_in_introductiontothecard"), introductionTab:getChildByName("btn_details_card_active")})
	table.insert(self.tabUnselectedStateList, {introductionTab:getChildByName("lbl_introductiontothecard"), introductionTab:getChildByName("btn_details_card_inactive")})
	local strengthenTab = tabUI:getChildByName("btn_details_card_strengthen")
	local aStrengthenButton = Button:create(strengthenTab)				--强化
	aStrengthenButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.strengthen})
	table.insert(self.tabButtonList, aStrengthenButton)
	table.insert(self.tabSelectedStateList, {strengthenTab:getChildByName("lbl_in_strengthen"), strengthenTab:getChildByName("btn_details_card_active")})
	table.insert(self.tabUnselectedStateList, {strengthenTab:getChildByName("lbl_strengthen"), strengthenTab:getChildByName("btn_details_card_inactive")})
	local cultivateTab = tabUI:getChildByName("btn_details_card_cultivate")
	local aCultivateButton = Button:create(cultivateTab)					--培养
	aCultivateButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.cultivate})
	table.insert(self.tabButtonList, aCultivateButton)
	table.insert(self.tabSelectedStateList, {cultivateTab:getChildByName("lbl_in_cultivate"), cultivateTab:getChildByName("btn_details_card_active")})
	table.insert(self.tabUnselectedStateList, {cultivateTab:getChildByName("lbl_cultivate"), cultivateTab:getChildByName("btn_details_card_inactive")})
	local metempsychosisTab = tabUI:getChildByName("btn_details_card_metempsychosis")
	local aMetempsychosisButton = Button:create(metempsychosisTab)		--转生
	aMetempsychosisButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.metempsychosis})
	table.insert(self.tabButtonList, aMetempsychosisButton)
	table.insert(self.tabSelectedStateList, {metempsychosisTab:getChildByName("lbl_in_metempsychosis"), metempsychosisTab:getChildByName("btn_details_card_active")})
	table.insert(self.tabUnselectedStateList, {metempsychosisTab:getChildByName("lbl_metempsychosis"), metempsychosisTab:getChildByName("btn_details_card_inactive")})
	local skillTab = tabUI:getChildByName("btn_details_card_skills")
	local aSkillButton = Button:create(skillTab)							--技能
	aSkillButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.skill})
	table.insert(self.tabButtonList, aSkillButton)
	table.insert(self.tabSelectedStateList, {skillTab:getChildByName("lbl_in_skills"), skillTab:getChildByName("btn_details_card_active")})
	table.insert(self.tabUnselectedStateList, {skillTab:getChildByName("lbl_skills"), skillTab:getChildByName("btn_details_card_inactive")})

	local aCardData = getCardInfoFromInitData(self.cardId)
	self:refreshCardLockState(aCardData.lock , true)

	self.panelUI:getChildByName("icon_crown_gold"):setVisible(false)
	self.panelUI:getChildByName("icon_crown_silver"):setVisible(false)
	self.panelUI:getChildByName("txt_perfect"):setVisible(false)
	local cardMeta = MetaManager.card_meta[aCardData.metaId]
	if CommonManager:checkIsCardPerfect(aCardData) then
		if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
			self.panelUI:getChildByName("icon_crown_gold"):setVisible(true)
			self.panelUI:getChildByName("icon_crown_silver"):setVisible(false)
			self.panelUI:getChildByName("txt_perfect"):getChildByName("txt"):setString(getTextByKey("option_perfect"))
			self.panelUI:getChildByName("txt_perfect"):setVisible(true)
		else
			self.panelUI:getChildByName("icon_crown_gold"):setVisible(false)
			self.panelUI:getChildByName("icon_crown_silver"):setVisible(true)
			self.panelUI:getChildByName("txt_perfect"):getChildByName("txt"):setString(getTextByKey("option_perfect"))
			self.panelUI:getChildByName("txt_perfect"):setVisible(false)
		end
	end

	self:refreshCardOriginalInfo()

	self.currentTabView = nil
	self.currentTabType = nil
	local aTabType = self.extraArgs.tabType or tabTypeEnum.introduction
	self:changeToTab(aTabType)
end

function CardInfoNewPanel:judgeForceClose()
	if not self.extraArgs.forceClose then
		return
	end

	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    self.container:setTableViewsEnabled(true)
	self.container.targetInfoPanel = nil
	return true
end

function CardInfoNewPanel:judgeTrainSavedOrNot(callback)
	if self.currentTabType ~= tabTypeEnum.cultivate then
		return true
	end
	if not CardTrainingScene.getUnsavedCardId() then
		return true
	end
	local trainOpt = self.currentTabView.trainOpt
	if not trainOpt then
		trainOpt = {cardId = self.cardId}
	end
	local function confirmQuit()
		local function afterGiveUPTrain(event)
		    local GameInitData = DataManager.getGameInitData()
		    GameInitData.sharkCards["trainValueSaved"] = true
		    DataManager.setGameInitData(GameInitData)
		    if callback then
		    	callback()
		    end
		end
		local request = GiveUpCardTrainRequest.new( trainOpt, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GiveUpCardTrainSucceed, afterGiveUPTrain )
		request:start()
	end
	local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.giveUp, trainOpt, {inCardInfoNewPanel = true, onReplaceSceneFunc = confirmQuit} )
	self.container:addChild(aPanel)
	aPanel:scaleIn()
	return false
end

function CardInfoNewPanel:changeToTab(tabType)
	self.currentTabType = tabType

	if self.currentTabType == tabTypeEnum.introduction then
		self.levelLabel1:setVisible(false)
		self.levelLabel2:setVisible(false)
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	elseif self.currentTabType == tabTypeEnum.strengthen then
		self.levelLabel1:setVisible(false)
		self.levelLabel2:setVisible(false)
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	elseif self.currentTabType == tabTypeEnum.cultivate then
		self.levelLabel1:setVisible(false)
		self.levelLabel2:setVisible(false)
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	elseif self.currentTabType == tabTypeEnum.metempsychosis then
		self.levelLabel1:setVisible(false)
		self.levelLabel2:setVisible(false)
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	elseif self.currentTabType == tabTypeEnum.skill then
		self.levelLabel1:setVisible(false)
		self.levelLabel2:setVisible(false)
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	end

	for i = 1, 5 do
		if i == self.currentTabType then
			self.tabButtonList[i]:setEnable(false)
			self.tabSelectedStateList[i][1]:setVisible(true)
			self.tabSelectedStateList[i][2]:setVisible(true)
			self.tabUnselectedStateList[i][1]:setVisible(false)
			self.tabUnselectedStateList[i][2]:setVisible(false)
		else
			self.tabButtonList[i]:setEnable(true)
			self.tabSelectedStateList[i][1]:setVisible(false)
			self.tabSelectedStateList[i][2]:setVisible(false)
			self.tabUnselectedStateList[i][1]:setVisible(true)
			self.tabUnselectedStateList[i][2]:setVisible(true)
		end
	end
	if self.currentTabView then
		self.currentTabView:removeFromParentAndCleanup(true)
	end
	self.currentTabView = tabViewList[self.currentTabType]:create(self)
	self:addChild(self.currentTabView)
end

function CardInfoNewPanel:refreshCardOriginalInfo()
	if (not self.container.playerTeamData) then
		self.cardStatus = CommonManager:getCardPropertiesWithSharkCard(self.containerData)
	else
		self.cardStatus = CommonManager:getCardPropertiesWithSharkCard(
			self.containerData,
			CommonManager.getQueueData(self.container.playerTeamData.mainCardId , self.container.playerTeamData.additionalCardIds),
			nil,
			self.container.playerTeamData.sharkCards,
			self.container.playerTeamData.sharkEquips,
			CommonManager:getMatrixCardData({self.container.playerTeamData.sharkMatrices.sharkMatrices}),
			self.container.playerTeamData.sharkMatrices.sharkMatrices,
			self.container.playerTeamData.sharkBeasts,
			self.container.playerTeamData.sharkSpirits
		)
	end
	local cardMeta = MetaManager.card_meta[self.containerData.metaId]
	local cardEvolveConfig = MetaManager.card_evolve[cardMeta.evolutionLevel]

	self.panelUI:getChildByName("icon_crown_gold"):setVisible(false)
	self.panelUI:getChildByName("icon_crown_silver"):setVisible(false)
	self.panelUI:getChildByName("txt_perfect"):setVisible(false)
	if CommonManager:checkIsCardPerfect(self.containerData) then
		if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
			self.panelUI:getChildByName("icon_crown_gold"):setVisible(true)
			self.panelUI:getChildByName("icon_crown_silver"):setVisible(false)
			self.panelUI:getChildByName("txt_perfect"):getChildByName("txt"):setString(getTextByKey("option_perfect"))
			self.panelUI:getChildByName("txt_perfect"):setVisible(true)
		else
			self.panelUI:getChildByName("icon_crown_gold"):setVisible(false)
			self.panelUI:getChildByName("icon_crown_silver"):setVisible(true)
			self.panelUI:getChildByName("txt_perfect"):getChildByName("txt"):setString(getTextByKey("option_perfect"))
			self.panelUI:getChildByName("txt_perfect"):setVisible(false)
		end
	end

	if self.cardFigure then
		self.cardFigure:removeFromParentAndCleanup(true)
	end
	self.cardFigure = getBigCanonCardWithInfoByMetaId(self.metaId)
    self.cardFigure:setAtk(math.floor(self.cardStatus.att))
    self.cardFigure:setDef(math.floor(self.cardStatus.def))
    self.cardFigure:setHp(math.floor(self.cardStatus.hp))

    local oldName = getTextByKey(MetaManager.card_meta[self.containerData.metaId].name)
    self.cardFigure:setName(oldName)

    self.cardFigure:setLevel(self.level)
    local cardLevelMeta = MetaManager.card_level[self.level]
    self.cardFigure:setScale(0.8)
    self.panelUI:getChildByName("card_normal_card_small_sb"):setVisible(false)
	local card_position = self.panelUI:getChildByName("card_normal_card_small_sb"):getPosition()
    self.cardFigure:setPosition(ccp(card_position.x,card_position.y))
    self.panelUI:addChildAt(self.cardFigure, 10)
    local aCardIconButton = Button:create(self.cardFigure)
	aCardIconButton:addEventListener(Events.kStart, self.onClickScope, self)

	self.levelLabel:getChildByName("txt"):setString(self.level)
	self.progress:setPercentage(self.exp * 100 / cardLevelMeta.exp)
	self.levelUpLimit:getChildByName("txt"):setString("" .. cardEvolveConfig.maxCardLevel)
	self.levelEvolveLabel:getChildByName("txt"):setString(cardMeta.evolutionLevel  .. "/" .. cardMeta.maxEvolvedLevel) --进化等级
	self.leadPointLabel:getChildByName("txt"):setString(cardMeta.leadPoint) --统御力
    self.attLabel:getChildByName("txt"):setString(math.floor(self.cardStatus.att)) --攻击
    self.defLabel:getChildByName("txt"):setString(math.floor(self.cardStatus.def)) --防御
    self.hpLabel:getChildByName("txt"):setString(math.floor(self.cardStatus.hp)) --血
end

function CardInfoNewPanel:refreshCardInfoForStrengthen(params)
	if not params.notRefreshContainer then
		self.container:refreshUIForPanelInfo(self.cardId, {slaveIds = params.slaveIds})
		self.containerData = self.container:getPanelInfoData(self.cardId)
		self.level = self.containerData.level
	    self.exp = self.containerData.exp
	    self:refreshCardOriginalInfo()
	end
    if params.showAdditional then
    	self.levelLabel1:setVisible(true)
    	self.levelLabel2:setVisible(true)
    	self.levelLabel2:getChildByName("txt"):setString(params.newLevel)
    	local aCloneData = table.clone(self.containerData, true)
        aCloneData.level = params.newLevel
        local newProperties = CommonManager:getCardPropertiesWithSharkCard(aCloneData)
    	self.attLabel1:setVisible(true)
    	self.attLabel1:getChildByName("txt"):setString("+" .. (math.floor(newProperties.att) - self.cardStatus.att)) --攻击
    	self.defLabel1:setVisible(true)
    	self.defLabel1:getChildByName("txt"):setString("+" .. (math.floor(newProperties.def) - self.cardStatus.def)) --防御
    	self.hpLabel1:setVisible(true)
    	self.hpLabel1:getChildByName("txt"):setString("+" .. (math.floor(newProperties.hp) - self.cardStatus.hp)) --血
    else
    	self.levelLabel1:setVisible(false)
    	self.levelLabel2:setVisible(false)
    	self.attLabel1:setVisible(false)
    	self.defLabel1:setVisible(false)
    	self.hpLabel1:setVisible(false)
    end
end

function CardInfoNewPanel:refreshCardInfoForTrain(params, notRefreshContainer)
	if params then
		local aCloneData = table.clone(self.containerData, true)
		aCloneData.attTrainValue = aCloneData.attTrainValue + params[1]
		aCloneData.defTrainValue = aCloneData.defTrainValue + params[2]
		aCloneData.hpTrainValue = aCloneData.hpTrainValue + params[3]
		local newProperties = CommonManager:getCardPropertiesWithSharkCard(aCloneData)
		local additionalAtt = math.floor(newProperties.att) - math.floor(self.cardStatus.att)
		local additionalDef = math.floor(newProperties.def) - math.floor(self.cardStatus.def)
		local additionalHp = math.floor(newProperties.hp) - math.floor(self.cardStatus.hp)
		if additionalAtt == 0 then
			self.attLabel1:setVisible(false)
		else
			self.attLabel1:setVisible(true)
			if additionalAtt > 0 then
				self.attLabel1:getChildByName("txt"):setString("+" .. additionalAtt)
			else
				self.attLabel1:getChildByName("txt"):setString("-" .. -additionalAtt)
			end
		end
		if additionalDef == 0 then
			self.defLabel1:setVisible(false)
		else
			self.defLabel1:setVisible(true)
			if additionalDef > 0 then
				self.defLabel1:getChildByName("txt"):setString("+" .. additionalDef)
			else
				self.defLabel1:getChildByName("txt"):setString("-" .. -additionalDef)
			end
		end
		if additionalHp == 0 then
			self.hpLabel1:setVisible(false)
		else
			self.hpLabel1:setVisible(true)
			if additionalHp > 0 then
				self.hpLabel1:getChildByName("txt"):setString("+" .. additionalHp)
			else
				self.hpLabel1:getChildByName("txt"):setString("-" .. -additionalHp)
			end
		end
	else
		self.attLabel1:setVisible(false)
    	self.defLabel1:setVisible(false)
    	self.hpLabel1:setVisible(false)
    	if not notRefreshContainer then
    		self.container:refreshUIForPanelInfo(self.cardId)
			self.containerData = self.container:getPanelInfoData(self.cardId)
			self:refreshCardOriginalInfo()
    	end
	end
end

function CardInfoNewPanel:refreshCardInfoForEvolve(params)
	if params.sharkCard then
		self.container:refreshUIForPanelInfo(self.cardId, {slaveIds = {params.slaveCard.cardId}})
		self.containerData = self.container:getPanelInfoData(self.cardId)

		self.metaId = CommonManager:changeAvatarByCardInfo( params.sharkCard )
		self.level = self.containerData.level
	    self.exp = self.containerData.exp
	    self:refreshCardOriginalInfo()
	    self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	elseif params.slaveCard then
		local cardInfo
		local sharkCards = DataManager.getCardsData()
		for _, temp in ipairs(sharkCards) do
			if self.cardId == temp.cardId then
				cardInfo = temp
				break
			end
        end
        local mCardMeta = MetaManager.card_meta[tonumber(self.containerData.metaId)]
        local sCardMeta = MetaManager.card_meta[tonumber(params.slaveCard.metaId)]
		cardInfo.metaId = mCardMeta.evolutionCardId
		local nextCardMeta = MetaManager.card_meta[tonumber(cardInfo.metaId)]
		cardInfo.attEvolveValue = cardInfo.attEvolveValue + nextCardMeta.reviseATT * MetaManager.card_rare[nextCardMeta.rare].basicAttack * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseAttack *  MetaManager.card_evolve[sCardMeta.evolutionLevel].bonusCoefficient
		cardInfo.defEvolveValue = cardInfo.defEvolveValue + nextCardMeta.reviseDEF * MetaManager.card_rare[nextCardMeta.rare].basicDefence * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseDefence *  MetaManager.card_evolve[sCardMeta.evolutionLevel].bonusCoefficient
		cardInfo.hpEvolveValue = cardInfo.hpEvolveValue + nextCardMeta.reviseHP * MetaManager.card_rare[nextCardMeta.rare].basicHP * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseHp *  MetaManager.card_evolve[sCardMeta.evolutionLevel].bonusCoefficient
		local newResult = CommonManager:getCardPropertiesWithSharkCard(cardInfo)
		local newMaxCardLevel = MetaManager.card_evolve[nextCardMeta.evolutionLevel].maxCardLevel
		if MetaManager.card_evolve[mCardMeta.evolutionLevel].maxCardLevel < newMaxCardLevel then
			self.levelUpLimit1:setVisible(true)
			self.levelUpLimit2:setVisible(true)
			self.levelUpLimit2:getChildByName("txt"):setString(tostring(newMaxCardLevel))
		else
			self.levelUpLimit1:setVisible(false)
			self.levelUpLimit2:setVisible(false)
		end
		self.levelEvolveLabel1:setVisible(true)
		self.levelEvolveLabel2:setVisible(true)
		self.levelEvolveLabel2:getChildByName("txt"):setString(nextCardMeta.evolutionLevel  .. "/" .. nextCardMeta.maxEvolvedLevel)
		self.attLabel1:setVisible(true)
		self.attLabel1:getChildByName("txt"):setString("+" .. (newResult.att - self.cardStatus.att))
		self.defLabel1:setVisible(true)
		self.defLabel1:getChildByName("txt"):setString("+" .. (newResult.def - self.cardStatus.def))
		self.hpLabel1:setVisible(true)
		self.hpLabel1:getChildByName("txt"):setString("+" .. (newResult.hp - self.cardStatus.hp))
	else
		self.levelUpLimit1:setVisible(false)
		self.levelUpLimit2:setVisible(false)
		self.levelEvolveLabel1:setVisible(false)
		self.levelEvolveLabel2:setVisible(false)
		self.attLabel1:setVisible(false)
		self.defLabel1:setVisible(false)
		self.hpLabel1:setVisible(false)
	end
end

function CardInfoNewPanel:refreshCardLockState(locked, notRefreshContainer)
	local lockStateDisplay = self.panelUI:getChildByName("icon_lock_big")
	if locked then
		lockStateDisplay:setVisible(true)
	else
		lockStateDisplay:setVisible(false)
	end
	if not notRefreshContainer then
		self.container:refreshUIForPanelInfo(self.cardId)
	end
end
