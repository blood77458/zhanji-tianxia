require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

require "canon.request.SkyTowerSkipGainAddRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function onGainFloorAdditionSucceed(evt)
	local self = evt.context
	self.container.waitRequest = false

	-- buff
	local buffData = self.attrTable[self.selectIndex]
	self.sharkSkyTowerData.currStatus.currUsedStars = self.sharkSkyTowerData.currStatus.currUsedStars + self.newBabelSetting[self.buffStarKeyTable[self.selectIndex + 1]]
	self.sharkSkyTowerData.currStatus[buffData.buffType] = self.sharkSkyTowerData.currStatus[buffData.buffType] + buffData.value
	if not self.sharkSkyTowerData.currStatus.gainFloorBuff then
		self.sharkSkyTowerData.currStatus.gainFloorBuff = {}
	end
	table.insert(self.sharkSkyTowerData.currStatus.gainFloorBuff, self.currentAdditionFloor + 1)
	DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)

	-- 星
	local targetFloor = DataManager.getSharkSkyTowerNeedAddFloor()
	local nextAdditonFloor = targetFloor
	if targetFloor == 0 then
		nextAdditonFloor = self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor
		self.sharkSkyTowerData.currStatus.currFloor = self.sharkSkyTowerData.sharkSkyTower.maxBigWinFloor
	end
	local skipFloorNum = nextAdditonFloor - self.currentAdditionFloor
	-- 3 代表最高难度 和 不掉血过关
	local starGained = 3 * 3 * skipFloorNum
	self.sharkSkyTowerData.currStatus.currTotalStars  = self.sharkSkyTowerData.currStatus.currTotalStars + starGained
	DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)

	-- 再看看有没有 , 没有窗口就关掉 , 去领奖
	if targetFloor == 0 then
		self:onClosePanel()
	else
		self.currentAdditionFloor = targetFloor
		self:setData()
	end
end

local function onGainFloorAdditionFailed(evt)
	local self = evt.context
	self.container.waitRequest = false
	if evt.data == 713507 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_buffAddition1"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713508 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713509 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_buffAddition3"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713510 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_transInformation"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713511 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_buffAddition4"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713515 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_starNotEnough"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713516 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_buffAdded"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif evt.data == 713523 then
		self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_reward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(evt.data)
	end
end

------------------------------------------------

NewBabelSkipFloorBuffPanel = class(Layer)

function NewBabelSkipFloorBuffPanel:ctor()
	self.container = nil
	self.currentAdditionFloor = nil
end

function NewBabelSkipFloorBuffPanel:create( container, sharkSkyTowerData, callback )
	local s = NewBabelSkipFloorBuffPanel.new()
	s.container = container
	s.preTargetInfoPanel = s.container.targetInfoPanel
	s.sharkSkyTowerData = sharkSkyTowerData
	s.callback = callback
	s:initLayer()
	return s
end

function NewBabelSkipFloorBuffPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelSkipFloorBuffPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_buff2")
	
	self.panelUI:getChildByName("txt_buff1"):getChildByName("txt"):setString(getTextByKey("skyTower_chooseBuffTitle"))
	self.panelUI:getChildByName("txt_buff7"):getChildByName("txt"):setString(getTextByKey("skyTower_totalStars"))
	self.panelUI:getChildByName("txt_buff8"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
	self.panelUI:getChildByName("txt_towerBabel_14"):getChildByName("txt"):setString(getTextByKey("skyTower_opponent"))
	self.panelUI:getChildByName("txt_towerBabel_13"):getChildByName("txt"):setString(getTextByKey("skyTower_self"))
	self.panelUI:getChildByName("txt_buff6"):getChildByName("txt"):setString(getTextByKey("skyTower_buyBuff"))
	
	self.buffStarKeyTable = {"lowBuffStar", "midBuffStar", "highBuffStar"}
	self.newBabelSetting = MetaManager.getNewBabelSettings()

	local function onClickBuff(evt)
		if self.container.waitRequest or evt.target.enable == false then
			return
		end
		self.container.waitRequest = true
		self.selectIndex = evt.target.index

		local request = SkyTowerSkipGainAddRequest.new( {floorId = self.currentAdditionFloor + 1 , type = evt.target.index}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.SkyTowerSkipGainAddSucceed, onGainFloorAdditionSucceed , self)
		request:addEventListener( RequestNotifyEnum.SkyTowerSkipGainAddFailed, onGainFloorAdditionFailed , self)
		request:start()
	end

	local indexMap = {}
	indexMap[1] = 1
	indexMap[2] = 3
	indexMap[3] = 2
	self.buttonArr = {}
	for i = 1, 3 do
		local index = indexMap[i]
		self.buttonArr[index] = Button:create(self.panelUI:getChildByName("btn_buff_chose" .. index))
		self.buttonArr[index].index = index - 1
		self.buttonArr[index]:addEventListener( Events.kStart, onClickBuff, self )
	end

	self.realBuffSpriteArr = {}
	--动态刷新
	self:setData()

	self:addChild(self.panelUI)
end

function NewBabelSkipFloorBuffPanel:setData()
	self.panelUI:getChildByName("txt_towerBabel_buff7_1"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars))
	self.panelUI:getChildByName("txt_towerBabel_buff7_2"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars))
	self.panelUI:getChildByName("txt_towerBabel_buff_a2"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyAtkDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_a1"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyDefDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_d2"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfAtkBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d1"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfDefBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d0"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfHpBuff) * 100) .. "%")

	self.currentAdditionFloor =  DataManager.getSharkSkyTowerNeedAddFloor()
	
	self.panelUI:getChildByName("txt_buff6_1"):getChildByName("txt"):setString(getTextByKey("skyTower_passFloor", {num = self.currentAdditionFloor}))

	-- 没有窗口就关掉 ，去领奖
	if self.currentAdditionFloor == 0 then
		self:onClosePanel()
		return
	end

	-- 弹窗设置
	local buffCalcNum = ((((self.sharkSkyTowerData.currStatus.climbTimes * self.newBabelSetting.challengeTimeHashPrime) % self.newBabelSetting.hashModPrime 
	+ (self.currentAdditionFloor + 1) * self.newBabelSetting.floorHashPrime) % self.newBabelSetting.hashModPrime
	+ self.sharkSkyTowerData.currStatus.days * self.newBabelSetting.dateHashPrime ) % self.newBabelSetting.hashModPrime
	+ self.sharkSkyTowerData.sharkSkyTower.uid * self.newBabelSetting.userIdHashPrime ) % self.newBabelSetting.hashModPrime

	local buffMeta = MetaManager.sky_tower_buff[MetaManager.random_number_table[buffCalcNum % table.getn(MetaManager.random_number_table) + 1] % 100]
	self.attrTable = {}
	
	local indexMap = {}
	indexMap[1] = 1
	indexMap[2] = 3
	indexMap[3] = 2
	for i = 1, 3 do
		local index = indexMap[i]
		local button = self.buttonArr[index]
		
		local stars = self.newBabelSetting[self.buffStarKeyTable[index]]
		button.display:getChildByName("txt"):setString(Localization:getInstance():getText("skyTower_buyBuffBtn", {num = tostring(stars)}))
		
		if self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars < stars then
			button:setEnable(false)
			button.display:getChildByName("btn"):setVisible(false)
		else
			button:setEnable(true)
			button.display:getChildByName("btn"):setVisible(true)
		end
		
		local buffType = buffMeta["buffType" .. index]
		local buffSpriteName
		self.attrTable[index - 1] = {}
		local text = ""
		if buffType == 1 then--add atk
			self.attrTable[index - 1].value = math.floor(getFloatNumber(self.newBabelSetting.atkBuffCoef) * 100 * stars) / 100
			text = getTextByKey("attr_Attack") .. "+" .. tostring(self.attrTable[index - 1].value * 100) .. "%"
			self.attrTable[index - 1].buffType = "selfAtkBuff"
			buffSpriteName = "Item/Picture/attack_up.png"
		elseif buffType == 2 then--add def
			self.attrTable[index - 1].value = math.floor(getFloatNumber(self.newBabelSetting.defBuffCoef) * 100 * stars) / 100
			text = getTextByKey("attr_Defense") .. "+" .. tostring(self.attrTable[index - 1].value * 100) .. "%"
			self.attrTable[index - 1].buffType = "selfDefBuff"
			buffSpriteName = "Item/Picture/defense_up.png"
		elseif buffType == 3 then--reduce atk
			self.attrTable[index - 1].value = math.floor(MetaManager.sky_tower_level[self.sharkSkyTowerData.currStatus.currFloor + 1].atkDebuffCoef * stars)
			text = getTextByKey("attr_Attack") .. tostring(-self.attrTable[index - 1].value)
			self.attrTable[index - 1].buffType = "enemyAtkDebuff"
			buffSpriteName = "Item/Picture/attack_down.png"
		elseif buffType == 4 then--reduce def
			self.attrTable[index - 1].value = math.floor(MetaManager.sky_tower_level[self.sharkSkyTowerData.currStatus.currFloor + 1].defDebuffCoef * stars)
			text = getTextByKey("attr_Defense") .. tostring(-self.attrTable[index - 1].value)
			self.attrTable[index - 1].buffType = "enemyDefDebuff"
			buffSpriteName = "Item/Picture/defense_down.png"
		elseif buffType == 5 then--add hp
			self.attrTable[index - 1].value = math.floor(getFloatNumber(self.newBabelSetting.hpBuffCoef) * 100 * stars) / 100
			text = getTextByKey("attr_HP") .. "+" .. tostring(self.attrTable[index - 1].value * 100) .. "%"
			self.attrTable[index - 1].buffType = "selfHpBuff"
			buffSpriteName = "Item/Picture/hp_up.png"
		end

		self.panelUI:getChildByName("txt_buff5_" .. i):getChildByName("txt"):setString(text)
		local fakeBuffSprite = self.panelUI:getChildByName("normal_card_small" .. i)
		fakeBuffSprite:setVisible(false)

		if self.realBuffSpriteArr[i] then
			self.realBuffSpriteArr[i]:removeFromParentAndCleanup(true)
		end

		self.realBuffSpriteArr[i] = Sprite:create(buffSpriteName)
		self.realBuffSpriteArr[i]:setPositionXY(fakeBuffSprite:getPositionX(), fakeBuffSprite:getPositionY())
		self.panelUI:addChildAt(self.realBuffSpriteArr[i], fakeBuffSprite:getZOrder() + 1)
	end
end

function NewBabelSkipFloorBuffPanel:onClosePanel()
	self.container:setTableViewsEnabled(true)
	self.container.targetInfoPanel = self.preTargetInfoPanel
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	if self.callback then
		self.callback()
	end
end