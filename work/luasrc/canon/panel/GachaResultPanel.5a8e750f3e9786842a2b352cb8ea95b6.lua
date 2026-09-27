require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.panel.GachaCardInfoPanel"
require "hecore.display.CocosObject"
require "hecore.display.Director"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

GachaResultPanel = class(Layer)

function GachaResultPanel:ctor()
	self.enableClick = true
end

function GachaResultPanel:create(container, rewards, costAmount, costType, gachaType, gachaTimes, gachaFunc, nextTimes, gachaPointAdded, gachaRpAdded)
	local panel = GachaResultPanel.new()
	panel.container = container
	panel.rewards = rewards --所有奖励
	panel.costAmount = costAmount --单次消耗
	panel.costType = costType --消耗类型
	panel.gachaType = gachaType --求将类型
	panel.gachaTimes = gachaTimes --求将次数
	panel.gachaFunc = gachaFunc --下次求将回调函数
	panel.nextTimes = nextTimes --下次求将次数
	panel.gachaPointAdded = gachaPointAdded or 0 --获得积分
	panel.gachaRpAdded = gachaRpAdded --获得人品

	panel:initLayer()
	return panel
end

function GachaResultPanel:initLayer()
	GachaResultPanel.super.initLayer(self)

	local bgLayer = LayerColor:create()
	bgLayer:setColor(ccc3( 0, 0, 0 ))
	bgLayer.refCocosObj:setOpacity( 150 )
	bgLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
	self:addChild(bgLayer)
	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/GachaResult_new.json")
	self.uiBuilder.useArtLabelTTF = true
	self.mainUI = self.uiBuilder:build(self.gachaType == 3 and "GachaResult_event" or "GachaResult")
	self:addChild(self.mainUI)

	local offset_y = 0
	self.mainUI:getChildByName("txt_up"):getChildByName("txt"):setString(getTextByKey("gachaResult_txt")) --"您本次求将获得以下武将"
	if self.gachaPointAdded > 0 then
		local str = getTextByKey( "gachaResult_getPointsTips", {num = self.gachaPointAdded} )
		local aNewLabel = ArtLabelTTF:create(str, true)
		aNewLabel:setCenterColor(ccc3(255,236,60))
		aNewLabel:setAroundColor(ccc3(96,37,8))
		aNewLabel:setSize(25)
		aNewLabel:construct()
		aNewLabel:setPosition(ccp(350, 425))
		self.mainUI:addChild(CocosObject.new(aNewLabel))
		offset_y = self.gachaType == 3 and -18 or -12
	end
	local bottomTxt = self.mainUI:getChildByName("txt_buttom")
	bottomTxt:setPositionY(bottomTxt:getPositionY() + offset_y)
	bottomTxt:getChildByName("txt"):setString(getTextByKey("gachaResult_oneTimeTips")) --"点击武将可以查看详细信息"

	if self.gachaType == 3 then
		offset_y = 0
		local rpValue = 0
		local rpTimes = 0
		local rpInfo = DataManager.getGameInitData().sharkGachaInfo
		if rpInfo then
			rpValue = rpInfo.rpValue
			rpTimes = rpInfo.rpGachaTimes
		end
		local nextRp = 0
		if MetaManager.rp_gacha then
			for i,v in ipairs(MetaManager.rp_gacha) do
				if v.rpGachaTimesMin <= rpTimes and (v.rpGachaTimesMax >= rpTimes or v.rpGachaTimesMax < 0) then
					nextRp = v.rpPointsNeeded
					break
				end
			end
		end
		local textRp1 = self.mainUI:getChildByName("txt_new_gacha1")
		textRp1:setPositionY(textRp1:getPositionY() + offset_y)
		textRp1:getChildByName("txt"):setVerticalAlignment(kCCVerticalTextAlignmentBottom)
		if rpValue >= nextRp then
			textRp1:getChildByName("txt"):setString(getTextByKey("gachaResult_rp_text", {num=self.gachaRpAdded}) .. "\n" .. getTextByKey("gacha_rpFull_text"))
		else
			textRp1:getChildByName("txt"):setString(getTextByKey("gachaResult_rp_text", {num=self.gachaRpAdded}) .. "\n" .. getTextByKey("gacha_rpNotFull_text"))
		end
		local textRp2 = self.mainUI:getChildByName("txt_new_gacha2")
		textRp2:setPositionY(textRp2:getPositionY() + offset_y)
		textRp2:getChildByName("txt"):setString(rpValue .. "/" .. nextRp)
		local bar = self.mainUI:getChildByName("new_gacha_bar_cb")
		bar:setPositionY(bar:getPositionY() + offset_y)
		local progress = ProgressBar:create(bar:getChildByName("new_gacha_bar"))
		if nextRp > 0 then
			progress:setPercentage(math.min(100, 100 * rpValue / nextRp))
		end
	end

	local picOK = self.mainUI:getChildByName("btn_sure")
	picOK:setPositionY(picOK:getPositionY() + offset_y)
    picOK:getChildByName("txt"):setString(getTextByKey("yes")) --"确定"
	local function onOKClick()
		if self.enableClick then
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			
			--facebook share card
			if FacebookShareManager.isOpenFacebookShareFunc() then
				local star5card = FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR5CARD)
				local star6card = FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR6CARD)
				if star5card or star6card then
					for k,v in pairs(self.rewards) do 
						if v.itemType == RewardTypeEnum.kCard then -- card type is 5
							if star6card and MetaManager.card_meta[v.metaId].rare == 6 then
								FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR6CARD)
								return
							elseif star5card and MetaManager.card_meta[v.metaId].rare == 5 then
								FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR5CARD)
								return
							end
						end
					end
				end
			end
			
		end
	end
	local btnOK = Button:create(picOK)
    btnOK:addEventListener(Events.kStart, onOKClick)
	local picNext = self.mainUI:getChildByName("btn_moreplz")
	picNext:setPositionY(picNext:getPositionY() + offset_y)
	if self.nextTimes == 10 then
		picNext:getChildByName("txt"):setString(getTextByKey("gachaResult_tenTimesBtn")) --"再求十次"
	else
		if self.gachaType == 5 then
			picNext:getChildByName("txt"):setString(getTextByKey("gachaResult_activity_oneTimeBtn")) --"再次参观"
		else
			picNext:getChildByName( "txt" ):setString( getTextByKey("gachaResult_oneTimeBtn") ) --"再次求将"
		end
	end
	local function onNextClick()
		if self.enableClick then
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			if self.gachaFunc then
				self.gachaFunc(self.gachaType, self.nextTimes)
			end
		end
	end
	local btnNext = Button:create(picNext)
    btnNext:addEventListener(Events.kStart, onNextClick)
	local picNoCoin = self.mainUI:getChildByName("btn_moreplz_nocoin")
	if self.gachaType == 5 then
		picNoCoin:getChildByName("txt"):setString(getTextByKey("gachaResult_activity_oneTimeBtn")) --"再次参观"
	else
		picNoCoin:getChildByName("txt"):setString(getTextByKey("gachaResult_oneTimeBtn")) --"再次求将"
	end
	local btnNoCoin = Button:create(picNoCoin)
    btnNoCoin:addEventListener(Events.kStart, onNextClick)

	local txtCostAmount = picNext:getChildByName("txt_font")
	local costString = tostring(self.costAmount * self.nextTimes)
	txtCostAmount:setString(costString)
	if string.len(costString) > 3 then --TODO
		txtCostAmount:setPositionY(txtCostAmount:getPositionY() - 1)
		txtCostAmount:setFontSize(txtCostAmount:getFontSize() - 7)
	end
	picNext:getChildByName("icon_gold"):setVisible(self.costType == ResourceEnum.GEMS)
	picNext:getChildByName("gacha_icon_haoyou_sb"):setVisible(self.costType ~= ResourceEnum.GEMS)
	picNext:setVisible(self.costType == ResourceEnum.GEMS or self.costType == ResourceEnum.FRIENDPOINT)
	picNoCoin:setVisible(self.costType ~= ResourceEnum.GEMS and self.costType ~= ResourceEnum.FRIENDPOINT)
	if self.nextTimes == 0 then
		picNext:setVisible(false)
		picNoCoin:setVisible(false)
		picOK:setPositionX(235)
	end

	local function creataCardButton(buttonItem, cardData)
		local function onCardClick()
			if self.enableClick then
				local cardPanel = GachaCardInfoPanel:create(self.container, cardData)
				PopoutManager:sharedManager():popout(cardPanel, kPopoutDir.kScale, false, false, self.container)
			end
		end
		self.mainUI:addChild(buttonItem)
		local button = Button:create(buttonItem)
		button:addEventListener(Events.kStart, onCardClick)
	end
	local function getCardData(cardId)
		for k,v in pairs(DataManager.getCardsData()) do
			if tonumber(v.cardId) == cardId then
				return v
			end
		end
	end
	if self.gachaTimes == 1 then
		local cardReward = nil
		for k,v in pairs(self.rewards) do
			if v.itemType == ResourceEnum.CARD then
				cardReward = v
			end
		end
		if cardReward then
			local cardData = getCardData(cardReward.id)
			if cardData then
				local item = getBigCanonCardWithInfoByMetaId(cardReward.metaId)
				local status = CommonManager:getCardPropertiesWithSharkCard(cardData)
				item:setAtk(math.floor(status.att))
				item:setDef(math.floor(status.def))
				item:setHp(math.floor(status.hp))
				item:setLevel(cardData.level)
				item:setPosition(ccp(visibleSize.width/2, 700))
				creataCardButton(item, cardData)
			end
		end
	else
		local cardRewards = {}
		for k,v in pairs(self.rewards) do
			if v.itemType == ResourceEnum.CARD then
				table.insert(cardRewards, v)
			end
		end
		local textHeight = 23
		local width = 131
		local height = 131 + textHeight + 2
		for i,v in ipairs(cardRewards) do
			local item = getHeadIconCanonCardByMetaId( v.metaId )
			local line = math.floor((i - 1) / 4)
			local row = (i - 1) % 4
			local meta = MetaManager.card_meta[v.metaId]
			local txtName = TextField:create(getTextByKey(meta.name))
			txtName:setFontSize(textHeight)
			txtName:setDimensions(CCSizeMake(width, textHeight+5))
			txtName:setHorizontalAlignment(kCCTextAlignmentCenter)
			txtName:setAnchorPoint(ccp(0.5, 0.5))
			txtName:setPosition(ccp(0, 0-height/2-3));
			item:addChild(txtName)
			item:setPosition(ccp(145 + row * (width + 10), 865 - line * (height + 10)))
			creataCardButton(item, getCardData(v.id))
		end
	end
end
