--卡牌进化

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.scene.BackpackScene"
require "canon.customUI/CanonCard"
require "canon.request.CardEvolutionRequest"
require "canon.data.MetaManager"
require "canon.models.CommonManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
CardEvolutionScene = class(BaseUIScene)

function CardEvolutionScene:ctor( )
    self.title  = getTextByKey("cardEvolve_Title")
    self.mainUI = nil
    self.ruleInfo   = nil
    self.previewInfo = nil
    self.mCard = nil
    self.sCard = nil
    self.mCardMetaId = nil
    self.sCardMetaId = nil
    self.getReady = nil
    self.flashMov = nil
end

function CardEvolutionScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    local s = CardEvolutionScene.new()
    s:initScene()
    return s
end

function CardEvolutionScene:showRuleInfo()
    self.ruleInfo:setVisible(true)
    self.previewInfo:setVisible(false)

end

function CardEvolutionScene:showPreviewInfo()
	self.ruleInfo:setVisible(false)
	self.previewInfo:setVisible(true)
end

function CardEvolutionScene:onInit()
	local gameInitData = DataManager.getGameInitData()
	BaseUIScene.initBackGround(self)
	
	local bg = Sprite:create("pic/nicebg.png")
	bg:setScale(2)
	local winSize = CCDirector:sharedDirector():getWinSize()
	bg:setPosition(ccp(winSize.width / 2 , winSize.height / 2 - 25))
	self:addChild(bg)
	
	-- local builder = LayoutBuilder:createWithContentsOfFile("common_sxm/canon_sxm.json")
	local builder = LayoutBuilder:createWithContentsOfFile("scene/card_new.json")
	builder.useArtLabelTTF = true
    self.mainUI = builder:build("card_cardEvolve")
	
	local function changeRotatedR(bgR, num)
		bgR.refCocosObj:setAnchorPoint(ccp(0.5, 0.5))
		local contentSize = bgR.refCocosObj:getContentSize()
		local curPosX,curPosY = bgR.refCocosObj:getPosition()
		if num == 2 then
			bgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY - contentSize.height / 2))
		elseif num == 3 then
			bgR:setPosition(ccp(curPosX + contentSize.width / 2 , curPosY + contentSize.height / 2))
		elseif num == 4 then
			bgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY + contentSize.height / 2))
		end
	end
	
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_2"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_3"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_4"), 4)
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_2"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_3"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_4"), 4)
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_3"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_2"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_L"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_4"),4 )
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_3"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_2"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_R"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_4"), 4)
	
    print(table.tostring(self.argv))
    if self.argv.enterScene=="CardInfoPanel" then
        HeMemDataHolder:setInteger("CardEvolution_m", self.argv.params.metaId)
        HeMemDataHolder:setInteger("CardId_m", self.argv.params.cardId)
    end
    if self.argv.enterScene=="BackpackScene" and self.argv.params.cardType=="master" then
		local previousId = HeMemDataHolder:getInteger("CardEvolution_m")
		if previousId ~= self.argv.params.metaId then
			HeMemDataHolder:deleteByKey("CardEvolution_s")
			HeMemDataHolder:deleteByKey("CardId_s")
		end
        HeMemDataHolder:setInteger("CardEvolution_m", self.argv.params.metaId)
        HeMemDataHolder:setInteger("CardId_m", self.argv.params.cardId)
    end
    if self.argv.enterScene=="BackpackScene" and self.argv.params.cardType=="slave" then
        HeMemDataHolder:setInteger("CardEvolution_s", self.argv.params.metaId)
        HeMemDataHolder:setInteger("CardId_s", self.argv.params.cardId)
    end 

	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString("0/0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_add_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_add_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_add_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString("0/0")
	self.mainUI:getChildByName("card_txt_equip_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(getTextByKey("cardEvolve_CoinConsume"))
	self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString("0")
	self.mainUI:getChildByName("card_txt_equip_CoinConsume"):setVisible(false)
	self.mainUI:getChildByName("card_icon_sliver_coin"):setVisible(false)
	self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(false)
	
	self.mainUI:getChildByName("card_add_R"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_1").refCocosObj:getTexture():setAliasTexParameters();
	
	self.mainUI:getChildByName("card_txt_maincard"):getChildByName("txt"):setString(getTextByKey("cardEvolve_mainCard"))
	self.mainUI:getChildByName("card_txt_subcard "):getChildByName("txt"):setString(getTextByKey("cardEvolve_materialCard"))
	
	local mResult;
    self.mCardMetaId = HeMemDataHolder:getInteger("CardEvolution_m")
	local masterCardId = HeMemDataHolder:getInteger("CardId_m")
	local cardStillExist = false
	local cardData = DataManager.getCardsData()
	for _, temp in ipairs(cardData) do
		if masterCardId == temp.cardId then
			cardStillExist = true
			break
		end
	end
	if masterCardId <= 0 or not cardStillExist then
		print("only metaId no cardId")
		self.mCardMetaId = 0
		HeMemDataHolder:deleteByKey("CardId_m")
		HeMemDataHolder:deleteByKey("CardEvolution_m")
	end
    if self.mCardMetaId >0 then 
        self.mCard = getBigCanonCardNoInfoByMetaId(tonumber(self.mCardMetaId))
        local aCard = MetaManager.card_meta[tonumber(self.mCardMetaId)]
        self.mCard:setPosition( ccp(self.mainUI:getChildByName("card_add_L"):getPositionX(),self.mainUI:getChildByName("card_add_L"):getPositionY()) )
        self:addChild(self.mCard)   
        self.mainUI:getChildByName("card_add_L"):setVisible(false)      
		local masterCardId = HeMemDataHolder:getInteger("CardId_m")
		mResult = CommonManager:getCardPropertiesWithCardId(masterCardId) 
		local maxCardLevel = MetaManager.card_evolve[aCard.evolutionLevel].maxCardLevel
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString("" .. mResult.level)
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_l"):getChildByName("font"):setString("/" .. maxCardLevel)
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_num"):getChildByName("font"):setString(tostring(mResult.att))
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_num"):getChildByName("font"):setString(tostring(mResult.def))
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_num"):getChildByName("font"):setString(tostring(mResult.hp))
	end
	
    self.sCardMetaId = HeMemDataHolder:getInteger("CardEvolution_s")
	local slaveCardId = HeMemDataHolder:getInteger("CardId_s")
	local cardStillExist = false
	local cardData = DataManager.getCardsData()
	for _, temp in ipairs(cardData) do
		if slaveCardId == temp.cardId then
			cardStillExist = true
			break
		end
	end
	if slaveCardId <= 0 or not cardStillExist then
		print("only metaId no cardId")
		self.sCardMetaId = 0
		HeMemDataHolder:deleteByKey("CardId_s")
		HeMemDataHolder:deleteByKey("CardEvolution_s")
	end
    if self.sCardMetaId>0 then 
        self.sCard = getBigCanonCardNoInfoByMetaId(tonumber(self.sCardMetaId))
		local mCardMeta = MetaManager.card_meta[tonumber(self.mCardMetaId)]
        local aCard = MetaManager.card_meta[tonumber(self.sCardMetaId)]
        self.sCard:setPosition( ccp(self.mainUI:getChildByName("card_add_R"):getPositionX(),self.mainUI:getChildByName("card_add_L"):getPositionY() ) )
        self:addChild(self.sCard)  
        self.mainUI:getChildByName("card_add_R"):setVisible(false)
        local evolvePrice = MetaManager.card_evolve[mCardMeta.evolutionLevel + 1].evolvePrice
		self.evolvePrice = evolvePrice
		self.leftCoin = tonumber(gameInitData.sharkUser.coins - self.evolvePrice)
		self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString("" .. evolvePrice)
		if self.leftCoin < 0 then
			self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(255, 0, 0))
		end
		self.mainUI:getChildByName("card_txt_equip_CoinConsume"):setVisible(true)
		self.mainUI:getChildByName("card_icon_sliver_coin"):setVisible(true)
		self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(true)
		local masterCardId = HeMemDataHolder:getInteger("CardId_m")
		local cardInfo = {}
		for _, temp in ipairs(DataManager.getGameInitData().sharkCards.sharkCards) do
			if masterCardId == temp.cardId then
				cardInfo = temp
			end
        end
		cardInfo.metaId = mCardMeta.evolutionCardId
		local nextCardMeta = MetaManager.card_meta[tonumber(cardInfo.metaId)]
		cardInfo.attEvolveValue = cardInfo.attEvolveValue + nextCardMeta.reviseATT * MetaManager.card_rare[nextCardMeta.rare].basicAttack * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseAttack *  MetaManager.card_evolve[aCard.evolutionLevel].bonusCoefficient
		cardInfo.defEvolveValue = cardInfo.defEvolveValue + nextCardMeta.reviseDEF * MetaManager.card_rare[nextCardMeta.rare].basicDefence * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseDefence *  MetaManager.card_evolve[aCard.evolutionLevel].bonusCoefficient
		cardInfo.hpEvolveValue = cardInfo.hpEvolveValue + nextCardMeta.reviseHP * MetaManager.card_rare[nextCardMeta.rare].basicHP * MetaManager.card_evolve[nextCardMeta.evolutionLevel].reviseHp *  MetaManager.card_evolve[aCard.evolutionLevel].bonusCoefficient
		local newResult = CommonManager:getCardPropertiesWithSharkCard(cardInfo)
		local maxCardLevel = MetaManager.card_evolve[nextCardMeta.evolutionLevel].maxCardLevel
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString("" .. newResult.level)
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_r"):getChildByName("font"):setString("/" .. maxCardLevel)
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_add_num"):getChildByName("font"):setString(tostring(newResult.att))--("+" .. tostring(newResult.att - mResult.att))
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_add_num"):getChildByName("font"):setString(tostring(newResult.def))--("+" .. tostring(newResult.def - mResult.def))
		self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_add_num"):getChildByName("font"):setString(tostring(newResult.hp))--("+" .. tostring(newResult.hp - mResult.hp))
	end
	
	self.levelL = self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L")
	self.levelR = self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R")
	self.levelL:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelL:getChildByName("font"):getDimensions().height))
	self.levelR:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelR:getChildByName("font"):getDimensions().height))
	self.levelMaxL = self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_l")
	self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_r"):setVisible(false)
	self.levelMaxR = self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_r")
	--self.levelMaxR:getChildByName("font"):setColor(ccc3(0, 102, 0))
	self.levelMaxL:setPosition(ccp(self.levelL:getPositionX() + self.levelL:getChildByName("font"):getContentSize().width + 3, self.levelMaxL:getPositionY()))
	self.levelMaxR:setPosition(ccp(self.levelR:getPositionX() + self.levelR:getChildByName("font"):getContentSize().width + 3, self.levelMaxR:getPositionY()))
	local maxR = TextField:create(self.levelMaxR:getChildByName("font"):getString(), self.levelMaxR:getChildByName("font"):getFontName(), 
	self.levelMaxR:getChildByName("font"):getFontSize(), self.levelMaxR:getChildByName("font"):getDimensions(), 
	tonumber(self.levelMaxR:getChildByName("font"):getHorizontalAlignment()), tonumber(self.levelMaxR:getChildByName("font"):getVerticalAlignment()))
	maxR:setPositionXY(self.levelMaxR:getPositionX(), self.levelMaxR:getPositionY())
	maxR:setAnchorPoint(ccp(0, 1))
	maxR:setColor(ccc3(34, 199, 103)) 
	self.mainUI:getChildByName("card_cardEvolve_preview"):addChild(maxR)
	
    
    --规则
    self.mainUI:getChildByName("card_cardEvolve_rule"):getChildByName("txt_cardEvolve_RuleText1"):getChildByName("txt_cardEvolve_RuleText1"):setString(getTextByKey("cardEvolve_RuleText1"))
    self.mainUI:getChildByName("card_cardEvolve_rule"):getChildByName("txt_cardEvolve_RuleText2"):getChildByName("txt_cardEvolve_RuleText1"):setString(getTextByKey("cardEvolve_RuleText2"))
    self.mainUI:getChildByName("card_cardEvolve_rule"):getChildByName("txt_cardEvolve_RuleText3"):getChildByName("txt_cardEvolve_RuleText1"):setString(getTextByKey("cardEvolve_RuleText3"))
    self.mainUI:getChildByName("card_cardEvolve_rule"):getChildByName("txt_cardEvolve_RuleText4"):getChildByName("txt_cardEvolve_RuleText1"):setString(getTextByKey("cardEvolve_RuleText4"))
	self.mainUI:getChildByName("card_cardEvolve_rule"):getChildByName("txt_cardEvolve_RuleText4"):setVisible(false)
    --
    self.mainUI:getChildByName("card_btn_cardEvolve_EvolveBtn"):getChildByName("txt_cardEvolve_EvolveBtn"):setString(getTextByKey("cardEvolve_EvolveBtn"))
    
    self.previewInfo = self.mainUI:getChildByName("card_cardEvolve_preview") 
    self.ruleInfo    = self.mainUI:getChildByName("card_cardEvolve_rule")    
    self.previewInfo:setVisible(false)
    self.ruleInfo:setVisible(false)
	
    
    --增加卡牌
    local function onClickAddMaster(e)
		local function checkHasMaterial(cardList, selectCard)
			local hasMaterial = false
			local masterCardId = selectCard.cardId
			local queueData = CommonManager.getQueueData()
			for k, v in pairs(CommonManager:getMatrixCardData()) do
				table.insert(queueData, v)
			end
            for k,card in pairs(cardList) do
                local masterCardGroupId = MetaManager.card_meta[selectCard.metaId].cardGroupId
                local slaveCardGroupId  = MetaManager.card_meta[card.metaId].cardGroupId
                
                local masterEvolutionLevel = MetaManager.card_meta[selectCard.metaId].evolutionLevel
                local slaveEvolutionLevel  = MetaManager.card_meta[card.metaId].evolutionLevel
                local maxCardLevel = MetaManager.card_evolve[slaveEvolutionLevel].maxCardLevel

				--检验是否万能转生卡
				local cardGroupId = MetaManager.card_meta[card.metaId].cardGroupId
				local cardType = ItemManager.getCardTypeByGroupId(cardGroupId)
				local cardTypeCanSelect = false
				if cardType == ItemManager.CARD_TYPE_BRON then
					--是万能转生卡
					--验证星级是否匹配
					local masterCardRare = MetaManager.card_meta[selectCard.metaId].rare
					local slaveCardRare  = MetaManager.card_meta[card.metaId].rare
					if masterCardRare == slaveCardRare then
						cardTypeCanSelect = true
					end
				end

                if ((tonumber(masterCardGroupId) == tonumber(slaveCardGroupId)) and        --cardGroupId相同
                   (tonumber(masterEvolutionLevel) >= tonumber(slaveEvolutionLevel)) and--化等级低于或等于主卡牌
				   (tonumber(masterCardId) ~= tonumber(card.cardId))) or -- not masterCard
				   (cardTypeCanSelect) then --(或)是万能转生卡
				    local inQueue = false;
				    for _,value in pairs(queueData)
					do
						if tonumber(value) == tonumber(card.cardId) then
							inQueue = true;
							break;
						end
					end
					if not inQueue then
						hasMaterial = true
						break;
					end
                end
            end
			return hasMaterial;
		end
	
		--过滤主卡牌
        local function filterMasterCardFunc( cardList )
            local result = {}
            for k,card in pairs(cardList) do
				local maxEvolveLevel = MetaManager.card_meta[card.metaId].maxEvolvedLevel
                local evolutionLevel = MetaManager.card_meta[card.metaId].evolutionLevel
                local evolveNeedLevel = MetaManager.card_evolve[evolutionLevel].evolveNeedLevel
                if --[[tonumber(card.level) >= tonumber(evolveNeedLevel) and --]]evolutionLevel < maxEvolveLevel then 
					if tonumber(card.level) >= tonumber(evolveNeedLevel) then
						card.levelEnough = true
					else
						card.levelEnough = false
					end

					if ItemManager.checkCardTypeCanEvolve(card.metaId) then
						--卡牌类型允许作为主卡牌转生 add by czh @ 2014-8-15 16:46:09
						card.needLevel = tonumber(evolveNeedLevel)
						card.hasMaterial = checkHasMaterial(cardList, card)
	                    table.insert(result,card)
					end
                end
            end
            return result
        end    
		self.notDeleteCardInfo = true
        local argv = {enterScene="CardEvolutionScene",returnScene="CardEvolutionScene",params={cardType="master",filter=BACKPACK_FILTER.CARD,filterFunc = filterMasterCardFunc, preReturnScene = self.argv.returnScene, isCardTrain = false}}
        self:replaceScene( BackpackScene , argv)        
    end
    local function onClickAddSlave(e)
        --add:副卡牌必须满级，且不在队列中
        --add:副卡牌可以选择同星级的万能转生卡 2014-8-15
        local function filterSlaveCardFunc(cardList)
            local result = {}
            if tonumber(self.mCardMetaId) <=0 then  --没有选主卡
                return result
            end
			
			local masterCardId = HeMemDataHolder:getInteger("CardId_m")
			local queueData = CommonManager.getQueueData()
			for k, v in pairs(CommonManager:getMatrixCardData()) do
				table.insert(queueData, v)
			end
            for k,card in pairs(cardList) do
                print(table.tostring(card))
                local masterCardGroupId = MetaManager.card_meta[self.mCardMetaId].cardGroupId
                local slaveCardGroupId  = MetaManager.card_meta[card.metaId].cardGroupId
                
                local masterEvolutionLevel = MetaManager.card_meta[self.mCardMetaId].evolutionLevel
                local slaveEvolutionLevel  = MetaManager.card_meta[card.metaId].evolutionLevel
                local maxCardLevel = MetaManager.card_evolve[slaveEvolutionLevel].maxCardLevel

				--检验是否万能转生卡
				local cardGroupId = MetaManager.card_meta[card.metaId].cardGroupId
				local cardType = ItemManager.getCardTypeByGroupId(cardGroupId)
				local cardTypeCanSelect = false
				if cardType == ItemManager.CARD_TYPE_BRON then
					--是万能转生卡
					--验证星级是否匹配
					local masterCardRare = MetaManager.card_meta[self.mCardMetaId].rare--这里要用当前选择的卡牌做对比
					local slaveCardRare  = MetaManager.card_meta[card.metaId].rare
					if masterCardRare == slaveCardRare then
						cardTypeCanSelect = true
					end
				end

                if ((tonumber(masterCardGroupId) == tonumber(slaveCardGroupId)) and        --cardGroupId相同
                   (tonumber(masterEvolutionLevel) >= tonumber(slaveEvolutionLevel)) and--化等级低于或等于主卡牌
				   (tonumber(masterCardId) ~= tonumber(card.cardId))) or -- not masterCard
				   (cardTypeCanSelect) then --(或)是万能转生卡
				    local inQueue = false;
				    for _,value in pairs(queueData)
					do
						if tonumber(value) == tonumber(card.cardId) then
							inQueue = true;
							break;
						end
					end
					if not inQueue then
						table.insert(result,card)
					end
                end
            end
            return result
        end
		self.notDeleteCardInfo = true
        local argv = {enterScene="CardEvolutionScene",returnScene="CardEvolutionScene",params={cardType="slave",filter=BACKPACK_FILTER.CARD,filterFunc = filterSlaveCardFunc, preReturnScene = self.argv.returnScene, isCardTrain = false}}
        self:replaceScene( BackpackScene, argv)        
    end        
	
	self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_R"):getChildByName("txt_cardEvolve_chooseCard"):setString(getTextByKey("cardEvolve_SelectCard"))
	self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_L"):getChildByName("txt_cardEvolve_chooseCard"):setString(getTextByKey("cardEvolve_SelectCard"))
	
	local addCardTextButton_master = Button:create(self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_L"))
	addCardTextButton_master:addEventListener(Events.kStart, onClickAddMaster, self)
    
    local addCardBtn_master = Button:create(self.mainUI:getChildByName("card_add_L")) --第1张
    addCardBtn_master:addEventListener(Events.kStart, onClickAddMaster, self)
    
	
	if self.mCardMetaId>0 then
		local addCardTextButton_slave = Button:create(self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_R"))
		addCardTextButton_slave:addEventListener(Events.kStart, onClickAddSlave, self)
		local addCardBtn_slave = Button:create(self.mainUI:getChildByName("card_add_R")) --第2张
		addCardBtn_slave:addEventListener(Events.kStart, onClickAddSlave, self)
	else
		self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_R"):setVisible(false)
		self.mainUI:getChildByName("card_add_R"):getChildByName("card_btn_add"):setVisible(false)
	end

    local function onClickStartEvolution(e)
		if self.waitResponse then
			do return end
		end
        if self.getReady==true then
            local masterId= HeMemDataHolder:getInteger("CardId_m")
            local slaveId = HeMemDataHolder:getInteger("CardId_s")
            print(masterId,slaveId)
			
			local function CardEvolutionFailed(params)
				self.targetInfoPanel = self.prePanel
				self:setTouchEnabled(true)
				self.waitResponse = false;
				if params.data == 710512 then
					self.targetInfoPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit, {setTargetInfoPanelNil = true})
					self:addChild(self.targetInfoPanel)
					self.targetInfoPanel:scaleIn()
				end
			end
			
            local function CardEvolutionCallback(e)
				g_previousBattleCount = CommonManager:getLocalPlayerStrength()
				local dirtyCardIds = {}
				table.insert(dirtyCardIds, HeMemDataHolder:getInteger("CardId_m"))
				table.insert(dirtyCardIds, HeMemDataHolder:getInteger("CardId_s"))
				CommonManager:setCardNeedUpdate(dirtyCardIds)
				
				self.waitResponse = false;
                --动画播放完成
                local function onFlashAnimationEnd(e)
                    --CCMessageBox("Evolution Flash Animation End!","Canon")
                    --self.mCard:setVisible(true)
                    --self.sCard:setVisible(true)   
                    --self.flashMov:removeFromParentAndCleanup(true)
                    --self.mainUI:getChildByName("card_add_R"):setVisible(true)   
                    --self.mainUI:getChildByName("card_add_L"):setVisible(true)   
					--[[self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString("0/0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_add_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_add_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_add_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_num"):getChildByName("font"):setString("0")
					self.mainUI:getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString("0/0")
					self.mainUI:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString("0")
					self:showRuleInfo()--]]
					if self.flashMov then
						self.flashMov:unregisterEndAnimationScriptHandler()
					end
					local argv = {enterScene="CardEvolutionScene",returnScene="CardEvolutionScene",params={preReturnScene = self.argv.returnScene,}}
					self:replaceScene( CardEvolveResultScene , argv)
					      
                end         
				CanonPlayEffect("music/sfx_card_evolve.wav")
				self.mainUI:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
                --CCMessageBox("Card Evolution Complete...","Canon")
				self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_R"):setVisible(false)
				self.mainUI:getChildByName("card_btn_cardEvolve_chooseCard_L"):setVisible(false)
                self.flashMov = FlashSprite:create("EVO2/FZZZZ2")         
				local card1_spf = getCardSpriteFrame(self.mCardMetaId)  
                self.flashMov:addChangeInstance("card1", card1_spf)
				local tmeta = MetaManager.card_meta[tonumber(self.mCardMetaId)]
				local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
				self.flashMov:addChangeInstance("cardcountry1", countrySpriteFrame)
				local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
				self.flashMov:addChangeInstance("cardBorder1", boardSpriteFrame)
				local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
				self.flashMov:addChangeInstance("cardBg1", cardBgSpriteFrame)
				local card2_spf = getCardSpriteFrame(self.sCardMetaId)  
                self.flashMov:addChangeInstance("card2", card2_spf)
				local tmeta = MetaManager.card_meta[tonumber(self.sCardMetaId)]
				local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
				self.flashMov:addChangeInstance("cardcountry2", countrySpriteFrame)
				local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
				self.flashMov:addChangeInstance("cardBorder2", boardSpriteFrame)
				local card3_spf = getCardSpriteFrame(MetaManager.card_meta[tonumber(self.mCardMetaId)].evolutionCardId)  
				local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
				self.flashMov:addChangeInstance("cardBg2", cardBgSpriteFrame)
                self.flashMov:addChangeInstance("card3", card3_spf)
				local tmeta = MetaManager.card_meta[tonumber(MetaManager.card_meta[tonumber(self.mCardMetaId)].evolutionCardId)]
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
                self:addChild(CocosObject.new(self.flashMov))    
                self.mCard:setVisible(false)
                self.sCard:setVisible(false)   
				
				local oldMetaId = HeMemDataHolder:getInteger("CardEvolution_m")
				HeMemDataHolder:setInteger( "CardEvolve_OldMetaId",oldMetaId )
				local newMetaId = e.data.sharkCard.metaId                
				HeMemDataHolder:setInteger( "CardEvolve_NewMetaId",newMetaId )
				local result = CommonManager:getCardPropertiesWithCardId(HeMemDataHolder:getInteger("CardId_m"))
				HeMemDataHolder:setString( "CardEvolve_oldSharkCard",table.serialize(result) )
				local newResult = e.data.sharkCard
				HeMemDataHolder:setString( "CardEvolve_newSharkCard",table.serialize(newResult) )

				HeMemDataHolder:deleteByKey("CardEvolution_m")
				HeMemDataHolder:deleteByKey("CardEvolution_s")
				HeMemDataHolder:deleteByKey("CardId_m")
				HeMemDataHolder:deleteByKey("CardId_s")   
				
				local cardData = DataManager.getCardsData()
				local toremoveKeys = {}
				for k,card in ipairs(cardData)
				do
					if card.cardId == masterId then
						cardData[k] = e.data.sharkCard
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
            --发送请求
			self.waitResponse = true
			self:setTouchEnabled(false)
			self.prePanel = self.targetInfoPanel
			self.targetInfoPanel = true
            local params={masterId=masterId,slaveId=slaveId}
            local request = CardEvolutionRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.CardEvolutionSucceed, CardEvolutionCallback )
            request:addEventListener( RequestNotifyEnum.CardEvolutionFailed, CardEvolutionFailed )
            request:start()              
        else
            --CCMessageBox("Choose your cards first!","Canon Tips")
        end
    end
    local btStartEvolution = Button:create(self.mainUI:getChildByName("card_btn_cardEvolve_EvolveBtn"))
    btStartEvolution:addEventListener(Events.kStart, onClickStartEvolution, self)   
   
    
    if self.mCardMetaId > 0 and self.sCardMetaId > 0 and self.leftCoin >= 0 then
		btStartEvolution:setEnable(true)
		self.mainUI:getChildByName("card_btn_cardEvolve_EvolveBtn"):getChildByName("btn"):setVisible(true)
	else
		btStartEvolution:setEnable(false)
		self.mainUI:getChildByName("card_btn_cardEvolve_EvolveBtn"):getChildByName("btn"):setVisible(false)
		--[[for k,v in pairs(self.mainUI:getChildByName("card_btn_cardEvolve_EvolveBtn").list)
		do
			if v.refCocosObj.setColor then
				v.refCocosObj:setColor(ccc3(200, 200, 200))
			end
		end--]]
	end	
   
   
    self:showRuleInfo()
	if self.sCardMetaId>0 then 
		self:showPreviewInfo();	
	end
    if HeMemDataHolder:getInteger("CardEvolution_m")>0 and HeMemDataHolder:getInteger("CardEvolution_s")>0 then
        self:showPreviewInfo()
        self.getReady = true
    end    
    self:addChild(self.mainUI)  
	
    --[[local layerSize = self.mainUI:getChildByName("card_cardEvolve_rule"):getGroupBounds().size
    local layerPosition = self.mainUI:getChildByName("card_cardEvolve_rule"):getPosition()
    local curX = nil
    local curY = nil    
    local function onTouchRuleInfo(eventType, pos)
        if eventType == "began" then
            curX = pos[1]
            curY = pos[2]
        end
        if eventType == "ended" and pos[2]>layerPosition.y-layerSize.height and pos[2]<layerPosition.y then
            offestX = pos[1] - curX
            offestY = pos[2] - curY    
            if offestX > 200 then
                self:showRuleInfo()
            end
            if offestX < -200 then
                self:showPreviewInfo()
            end
        end        
    end

    local layer = MultiTouchLayer:create(layerSize.width,layerSize.height)
    layer:setPosition(ccp(layerPosition.x,layerPosition.y))
    layer:registerScriptTouchHandler(onTouchRuleInfo,true)
    self:addChild(layer)--]]
    
	BaseUIScene.onInit(self)
end

function CardEvolutionScene:createInfoView()

end

function CardEvolutionScene:dispose()
	if not self.notDeleteCardInfo then
		HeMemDataHolder:deleteByKey("CardEvolution_s")
		HeMemDataHolder:deleteByKey("CardId_s")
	end
	CardEvolutionScene.super.dispose(self)
end

function CardEvolutionScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CardEvolutionScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function CardEvolutionScene:startEnterAnimation()
    BaseUIScene.startEnterAnimation(self)
    local function enterActionFinished()
    self:nodeAnimationFinished()
    end
    self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
    if self.mCard then 
      self.mCard:setPositionX(self.mCard:getPositionX() - visibleSize.width)
      self.mCard:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))    
    end
    if self.sCard then
      self.sCard:setPositionX(self.sCard:getPositionX() - visibleSize.width)
      self.sCard:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))  
    end
end

function CardEvolutionScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  if self.mCardMetaId >0 then 
--	ExeNewGuide(GuideConfig.kCardEvolution2) --Not Run Here
  else
--	ExeNewGuide(GuideConfig.kCardEvolution) --Not Run Here
  end
end

function CardEvolutionScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CardEvolutionScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CardEvolutionScene:startExitAnimation()
    BaseUIScene.startExitAnimation(self)
    local function enterActionFinished()
    self:nodeAnimationFinished()
    end
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
    if self.mCard then
        self.mCard:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0))) 
    end
    if self.sCard then
        self.sCard:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    end
end

function CardEvolutionScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CardEvolutionScene:back() 
	if self.argv.returnScene == "BackpackScene" then 
        self:replaceScene(BackpackScene)
	elseif self.argv.returnScene == "CardQueueScene" then
		self:replaceScene(CardQueueScene, {enterScene="CardEvolutionScene"})
	elseif (self.argv.returnScene == "MatrixScene") then
		self:replaceScene(MatrixScene)
  else
    self:replaceScene(MainMenuScene)
  end 
end