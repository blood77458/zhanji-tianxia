require "canon.request.GainChargeMoneyRewardRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_ChargeRewardLayer = class(Layer)

local cardPropId

function Activity_ChargeRewardLayer.getCurrentChargeLevel()
	local curChargeLevel = 0
	local rewardList = DataManager.getGainedChargeMoneyRewardlist()
	for k,data in pairs(rewardList) do
		if tonumber(data) > curChargeLevel then
			curChargeLevel = tonumber(data)
		end
 	end
	return curChargeLevel
end

function Activity_ChargeRewardLayer.getEnableChargeLevel()
	local chargeGems = tonumber(DataManager.getCurrUser().rechargeGems)
	local enableChargeLevel = 0
	for k,data in ipairs(MetaManager.charge_money_reward) do
		if chargeGems >= data.requireGold and enableChargeLevel < data.id then
			enableChargeLevel = data.id
		end
	end
	return enableChargeLevel
end

function Activity_ChargeRewardLayer:ctor()
  self.container = nil
end

function Activity_ChargeRewardLayer:create( container )
  self.container = container
  local s = Activity_ChargeRewardLayer.new()
  s:initLayer()
  return s
end

function Activity_ChargeRewardLayer:panelDismiss()
  self.container.targetInfoPanel = nil
end

function Activity_ChargeRewardLayer:enable(chargeLevel)
	local isEnable = false
        chargeLevel = chargeLevel or Activity_ChargeRewardLayer.getCurrentChargeLevel()
	if MetaManager.charge_money_reward[chargeLevel + 1] then
		isEnable = true
	end
  return isEnable
end

function Activity_ChargeRewardLayer:initLayer()
  Activity_ChargeRewardLayer.super.initLayer(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/firstCharge.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("firstCharge")
	
	local bgPosX, bgPosY = self.mainUI:getChildByName("bg_inventory_red"):getPositionX(), self.mainUI:getChildByName("bg_inventory_red"):getPositionY()
	local bgSprite = Sprite:create("pic/nicebg.png")
	bgSprite:setAnchorPoint(ccp(0, 1))
	bgSprite:setPositionXY(bgPosX, bgPosY)
	bgSprite:setScaleX(720 / bgSprite:getContentSize().width)
	bgSprite:setScaleY(1.49)
	self.mainUI:addChildAt(bgSprite, self.mainUI:getChildByName("bg_inventory_red"):getZOrder() + 1)
	
	local bg2Sprite = Sprite:create("pic/gacha_bg_3.png")
	bg2Sprite:setAnchorPoint(ccp(0.5, 1))
	bg2Sprite:setPositionXY(360, bgPosY - 132.25)
	bg2Sprite:setScaleY(1.13)
	self.mainUI:addChildAt(bg2Sprite, bgSprite:getZOrder() + 1)
	
	self.mainUI:getChildByName("charge_reward_item"):setVisible(false)
	self.mainUI:getChildByName("number_simple"):setVisible(false)
	self.mainUI:getChildByName("btn_getreward"):getChildByName("txt"):setString(getTextByKey("chargeMoney_get_reward"))
	self.mainUI:getChildByName("txt_charge_info2"):getChildByName("txt"):setString(getTextByKey("chargeMoney_doubleGoldTip"))
	
	local highLight = self.mainUI:getChildByName("btn_gocharge"):getChildByName("common_btn_light")
	local actionArray = CCArray:create()
	actionArray:addObject(CCFadeOut:create(0.5))
	actionArray:addObject(CCFadeIn:create(0.5))
	highLight:runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
	
	local shineSprite = self.mainUI:getChildByName("lighting")
	
	local epclipLayer = CCClippingNode:create();
	local epclipLayer_co = CocosObject.new(epclipLayer)
	epclipLayer_co:setPositionXY(shineSprite:getPositionX() + shineSprite:getContentSize().width * shineSprite:getScaleX()  / 2, shineSprite:getPositionY() - shineSprite:getContentSize().height * shineSprite:getScaleY())
	epclipLayer_co:setAnchorPoint(ccp(0.5, 0.5))
	local epstencil = CCSprite:create(UI_RES_PATH.."/firstCharge/lighting.png")
	epstencil:setScaleY(0.73 * shineSprite:getScaleY())
	epstencil:setScaleX(shineSprite:getScaleX())
	epstencil:setAnchorPoint(ccp(0.5, 0))
	epclipLayer:setStencil(epstencil)
	
	local addShine = Sprite:create(UI_RES_PATH.."/firstCharge/lighting.png")
	addShine:setAnchorPoint(ccp(0.5, 0.5))
	addShine:setScaleY(shineSprite:getScaleY())
	addShine:setScaleX(shineSprite:getScaleX())
	addShine:setPositionY(addShine:getContentSize().height / 2 )
	addShine:runAction(CCRepeatForever:create(CCRotateBy:create(5, 360)))
	epclipLayer_co:addChild(addShine)
	
	shineSprite:setVisible(false)
	self.mainUI:addChildAt(epclipLayer_co, shineSprite:getZOrder())
	
	local posX,posY = self.mainUI:getChildByName("number_simple"):getPositionX(), self.mainUI:getChildByName("number_simple"):getPositionY()
	self.goldCost = CCLabelAtlas:create("", "pic/number_vip.png", 22, 41, 48)
	self.goldCost:setScale(1.25)
	self.goldCost:setAnchorPoint(ccp(0.5, 0.5))
	local numberLabel_co = CocosObject.new(self.goldCost)
	numberLabel_co:setPositionXY(posX, posY )
	self.mainUI:addChild(numberLabel_co)
	
	self.chargeLevel = Activity_ChargeRewardLayer.getCurrentChargeLevel()
	
	local function onClickCharge(evt)
		self.container:replaceScene(ShopScene, {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",selectPanelName="Activity_ChargeReward", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
	end	
	
	local chargeBtn = Button:create(self.mainUI:getChildByName("btn_gocharge"))
	chargeBtn:addEventListener(Events.kStart, onClickCharge)
	
	local function onGetRewardFinish()
		local function changeLayer()
			self:refreshLayer()
			self.container:resetTipInfoForActivity("Activity_ChargeReward")
		end
		
		local function enableTouch()
			self.container:setTouchEnabled(true)
			self.container:setHeadTableViewEnable(true)
		end
		
		if self:enable() then
			self.container:setTouchEnabled(false)
			self.container:setHeadTableViewEnable(false)
			local actionArray = CCArray:create()
			actionArray:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width , 0)))
			actionArray:addObject(CCCallFuncN:create(changeLayer))
			actionArray:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width , 0)))
			actionArray:addObject(CCCallFuncN:create(enableTouch))
			self.mainUI:runAction(CCSequence:create(actionArray))
			--facebook share get recharge reward info
			FacebookShareManager.facebookShareRecharge()
		else
			self.container:replaceScene(MainMenuScene)
		end		
	end
	
	local function onGetRewardSucceed(evt)
		self.waitRequest = false
		RewardManager:getReward(evt.data.rewards)
		self.container.targetInfoPanel = GetRewardInfoPanel:create( self.container, evt.data.rewards, onGetRewardFinish)
		PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
		local rewardList = DataManager.getGainedChargeMoneyRewardlist()
		table.insert(rewardList, self.chargeLevel + 1)
		DataManager.setGainedChargeMoneyRewardlist(rewardList)
		self.chargeLevel = Activity_ChargeRewardLayer.getCurrentChargeLevel()
	end
	
	local function onGetRewardFailed(evt)
		self.waitRequest = false
		if evt.data == 716120 then
			local aContent = Localization:getInstance():getText("chargeMoney_noReward")
			local function closeCanonMessageBox()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		elseif evt.data == 716121 then
			local aContent = Localization:getInstance():getText("chargeMoney_wrongRewardId")
			local function closeCanonMessageBox()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		elseif evt.data == 710516 then
			local aContent = Localization:getInstance():getText("shop_inventoryFull")
			local function closeCanonMessageBox()
			end
			self.container.targetInfoPanel = NewPackageFullPanel:show()
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function sendGetRewardRequest()
		if self.waitRequest then
			do return end
		end
		self.waitRequest = true
		local request = GainChargeMoneyRewardRequest.new( {id = self.chargeLevel + 1}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GainChargeMoneyRewardSucceed, onGetRewardSucceed)
		request:addEventListener( RequestNotifyEnum.GainChargeMoneyRewardFailed, onGetRewardFailed)
		request:start()
	end
	
	local function onClickGetReward(evt)
		sendGetRewardRequest()
	end	
	
	local getRewardBtn = Button:create(self.mainUI:getChildByName("btn_getreward"))
	getRewardBtn:addEventListener(Events.kStart, onClickGetReward)
	self.getRewardBtn = getRewardBtn
	
	self:addChild(self.mainUI)
	
	self:refreshLayer()
end

function Activity_ChargeRewardLayer.createRewardLayer(chargeLevel, color)
	local rewardsLayer = Layer:create()
	
	local function addRewardParticle(boxDataItem, width)
		local rewardParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(-width / 2, width / 2), 1, nil, boxDataItem.sprite)
		rewardParticle.refCocosObj:setStartColor(ccc4f(255, 0, 255, 0))
		rewardParticle.refCocosObj:setEndColor(ccc4f(255, 0, 255, 0))
		rewardParticle.refCocosObj:setStartSize(40)
		rewardParticle.refCocosObj:setPositionType(kCCPositionTypeRelative);
		local particleMoveArray = CCArray:create()
    local particleMoveTime = 0.4
    particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(width, 0)))
    particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -width)))
    particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-width, 0)))
    particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, width)))
    rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
	end
	
	local itemTable = {}
	if chargeLevel == 0 then
		local boxDataItem = {}
		boxDataItem.sprite = CanonItem:create()
		boxDataItem.sprite.icon =  Sprite:create("pic/activityIcons/shouchong.png")
		boxDataItem.sprite.icon:setScale(144 / boxDataItem.sprite.icon:getContentSize().width)
		boxDataItem.sprite:addChild(boxDataItem.sprite.icon)
		local doubleSprite = Sprite:create("pic/icon_double.png")
		doubleSprite:setAnchorPoint(ccp(0, 1))
		doubleSprite:setPositionXY(-72, 72)
		boxDataItem.sprite:addChild(doubleSprite)
		boxDataItem.sprite:setScale(130 / 144)
		boxDataItem.text = getTextByKey("chargeMoney_doubleGold")
		addRewardParticle(boxDataItem, 144)
		table.insert(itemTable, boxDataItem)
	end
	
	cardPropId = nil
	
	local rewardMeta = MetaManager.charge_money_reward[chargeLevel + 1]
	for i = 1, 4 do
		local propType = rewardMeta["rewardType" .. i]
		local propId = rewardMeta["rewardId" .. i]
		local propAmount = rewardMeta["rewardAmount" .. i]
		local boxDataItem = {}
		if propType == ResourceEnum.COIN then
			boxDataItem.sprite = CanonItem:create()
			boxDataItem.sprite.icon =  Sprite:create("common/CoinIcon_Mission.png")
			boxDataItem.sprite.icon:setScale(130 / boxDataItem.sprite.icon:getContentSize().width)
			boxDataItem.sprite:setQuality(1, false)
			boxDataItem.sprite:setScale(130 / 144)
			boxDataItem.text = getTextByKey("resource_silverCoin") .. "x" .. propAmount
		elseif propType == ResourceEnum.GEMS then
			boxDataItem.sprite = CanonItem:create()
			boxDataItem.sprite.icon =  Sprite:create("common/GemIcon_Mission.png")
			boxDataItem.sprite.icon:setScale(130 / boxDataItem.sprite.icon:getContentSize().width)
			boxDataItem.sprite:setQuality(1, false)
			boxDataItem.sprite:setScale(130 / 144)
			boxDataItem.text = getTextByKey("resource_goldCoin") .. "x" .. propAmount
		elseif propType == ResourceEnum.CARD then
			if not cardPropId then
				cardPropId = propId
			end
			boxDataItem.sprite = getHeadIconCanonCardByMetaId(propId)
			boxDataItem.text = getTextByKey(MetaManager.card_meta[propId].name)
			boxDataItem.isCard = true
			addRewardParticle(boxDataItem, 130)
		elseif propType == ResourceEnum.EQUIP then
			boxDataItem.sprite = CanonItem:create()
			boxDataItem.sprite:loadByMetaId(propId)
			boxDataItem.sprite:setScale(130 / 144)
			boxDataItem.text = getTextByKey(MetaManager.equip_meta[propId].name)
			addRewardParticle(boxDataItem, 144)
		elseif propType == ResourceEnum.PROP then
			boxDataItem.sprite = CanonItem:create()
			boxDataItem.sprite:loadByMetaId(propId)
			boxDataItem.sprite:setScale(130 / 144)
			boxDataItem.text = getTextByKey(MetaManager.prop_meta[propId].name) .. "x" .. propAmount
		elseif propType == ResourceEnum.FRIENDPOINT then
			boxDataItem.sprite = CanonItem:create()
			boxDataItem.sprite.icon =  Sprite:create("common/FriendpointIcon_Mission.png")
			boxDataItem.sprite.icon:setScale(130 / boxDataItem.sprite.icon:getContentSize().width)
			boxDataItem.sprite:setQuality(1, false)
			boxDataItem.sprite:setScale(130 / 144)
			boxDataItem.text = getTextByKey("resource_friendshipPoint") .. "x" .. propAmount
		else
			boxDataItem = nil;
		end
		if boxDataItem then
			table.insert(itemTable, boxDataItem)
		end
	end
	
	for k,data in ipairs(itemTable) do
		local textLabel = TextField:create(data.text, nil, 25)
		textLabel:setAnchorPoint(ccp(0.5, 1))
		textLabel:setPosition(ccp(0, -80))
		if data.isCard then
			textLabel:setScale(130 / 144)
			textLabel:setPositionY(-80 * 130 / 144)
		end
		textLabel:setColor(ccc3(151, 45, 5))
		if color then
			textLabel:setColor(color)
		end
		data.sprite:addChild(textLabel)
		data.sprite:setPositionX(170 * (k - 1))
		rewardsLayer:addChild(data.sprite)
	end
	return rewardsLayer
end

function Activity_ChargeRewardLayer:refreshLayer()
	self.mainUI:getChildByName("common_guide_other"):setVisible(false)
	self.mainUI:getChildByName("txt_qbd"):getChildByName("txt"):setString(getTextByKey(MetaManager.charge_money_reward[self.chargeLevel + 1].describe))
	self.mainUI:getChildByName("txt_charge_4"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part_end_common"))
	
	if self.chargeLevel == 0 then
		self.mainUI:getChildByName("txt_charge_1"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part1_first"))
		self.mainUI:getChildByName("txt_charge_2"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part2_first"))
		self.mainUI:getChildByName("txt_charge_3"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part3_first"))
		self.mainUI:getChildByName("btn_gocharge"):getChildByName("txt"):setString(getTextByKey("chargeMoney_go_little"))
		self.mainUI:getChildByName("txt_nowrecharging"):setVisible(false)
		self.mainUI:getChildByName("txt_charge_info2"):setVisible(true)
	else
		self.mainUI:getChildByName("txt_nowrecharging"):setVisible(true)
		self.mainUI:getChildByName("txt_charge_info2"):setVisible(false)
		self.mainUI:getChildByName("txt_charge_1"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part1_not_first"))
		self.mainUI:getChildByName("txt_charge_2"):getChildByName("txt"):setString(tostring(MetaManager.charge_money_reward[self.chargeLevel + 1].requireGold))
		self.mainUI:getChildByName("txt_charge_3"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec_part2_not_first"))
		self.mainUI:getChildByName("btn_gocharge"):getChildByName("txt"):setString(getTextByKey("chargeMoney_go"))
		self.mainUI:getChildByName("txt_nowrecharging"):getChildByName("txt"):setString(getTextByKey("chargeMoney_progress") .. ":" .. DataManager.getCurrUser().rechargeGems)
	end
	
	local getRewardButtonEnable = tonumber(DataManager.getCurrUser().rechargeGems) >= tonumber(MetaManager.charge_money_reward[self.chargeLevel + 1].requireGold)
	self.mainUI:getChildByName("btn_getreward"):getChildByName("btn_long_blue"):setVisible(getRewardButtonEnable)
	self.getRewardBtn:setEnable(getRewardButtonEnable)
	
	self.goldCost:setString(tostring(MetaManager.charge_money_reward[self.chargeLevel + 1].worthGold))
	
	if self.rewardsLayer then
		self.rewardsLayer:removeFromParentAndCleanup(true)
	end
	
	self.rewardsLayer = Activity_ChargeRewardLayer.createRewardLayer(self.chargeLevel)
	
	self.rewardsLayer:setPositionXY(self.mainUI:getChildByName("charge_reward_item"):getPositionX() + 50, self.mainUI:getChildByName("charge_reward_item"):getPositionY() - 60)
	self.mainUI:addChild(self.rewardsLayer)
	
	if self.bgHero then
		self.bgHero:removeFromParentAndCleanup(true)
	end
	
	local heroPosX, heroPosY = self.mainUI:getChildByName("common_guide_other"):getPositionX(), self.mainUI:getChildByName("common_guide_other"):getPositionY()
	local heroSize = self.mainUI:getChildByName("common_guide_other"):getContentSize()
	
	self.bgHero = Sprite:createWithSpriteFrame(getHalfWideCardSpriteFrame(MetaManager.charge_money_reward[self.chargeLevel + 1].backgroundCardId))
	self.bgHero:setAnchorPoint(ccp(0.5, 0.5))
	self.bgHero:setPositionXY(heroPosX - heroSize.width / 2, heroPosY - heroSize.height / 2)
	self.mainUI:addChildAt(self.bgHero, self.mainUI:getChildByName("common_guide_other"):getZOrder())
end

function Activity_ChargeRewardLayer:startEnterAnimation_Run()
end 

function Activity_ChargeRewardLayer:startExitAnimation_Run()
end

function Activity_ChargeRewardLayer.shouldShowParticle()
  return true
end

function Activity_ChargeRewardLayer.getTipNum()
  local chargeLevel = Activity_ChargeRewardLayer.getCurrentChargeLevel()
  if not Activity_ChargeRewardLayer.enable(chargeLevel) then
    return 0
  end
  
  local aParticleStatus
  local aTipNum = 0
  local aConfig = MetaManager.charge_money_reward[chargeLevel + 1]
  if aConfig then
    aParticleStatus = true
  end
  
  while aConfig and (aConfig.requireGold <= tonumber(DataManager.getCurrUser().rechargeGems)) do
    aTipNum = aTipNum + 1
    chargeLevel = chargeLevel + 1
    aConfig = MetaManager.charge_money_reward[chargeLevel + 1]
  end
  return aTipNum, aParticleStatus
end
