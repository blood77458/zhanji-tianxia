require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

require "canon.request.GainFloorAdditionRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewBabelFloorBuffPanel = class(Layer)

function NewBabelFloorBuffPanel:ctor()
	self.container = nil
end

function NewBabelFloorBuffPanel:create( container, sharkSkyTowerData, callback)
	self.container = container
	self.preTargetInfoPanel = self.container.targetInfoPanel
	self.sharkSkyTowerData = sharkSkyTowerData
	self.callback = callback
	
	local s = NewBabelFloorBuffPanel.new()
	s:initLayer()
	return s
end

function NewBabelFloorBuffPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelFloorBuffPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_buff2")
	
	self.panelUI:getChildByName("txt_buff1"):getChildByName("txt"):setString(getTextByKey("skyTower_chooseBuffTitle"))
	self.panelUI:getChildByName("txt_buff7"):getChildByName("txt"):setString(getTextByKey("skyTower_totalStars"))
	self.panelUI:getChildByName("txt_buff8"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
	self.panelUI:getChildByName("txt_towerBabel_buff7_1"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars))
	self.panelUI:getChildByName("txt_towerBabel_buff7_2"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars))
	self.panelUI:getChildByName("txt_towerBabel_buff_a2"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyAtkDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_a1"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyDefDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_d2"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfAtkBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d1"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfDefBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d0"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfHpBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_14"):getChildByName("txt"):setString(getTextByKey("skyTower_opponent"))
	self.panelUI:getChildByName("txt_towerBabel_13"):getChildByName("txt"):setString(getTextByKey("skyTower_self"))
	self.panelUI:getChildByName("txt_buff6"):getChildByName("txt"):setString(getTextByKey("skyTower_buyBuff"))
	self.panelUI:getChildByName("txt_buff6_1"):getChildByName("txt"):setString(getTextByKey("skyTower_passFloor", {num = self.sharkSkyTowerData.currStatus.currFloor}))

	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = self.preTargetInfoPanel
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		if self.callback then
			self.callback()
		end
	end	 
	
	local buffStarKeyTable = {"lowBuffStar", "midBuffStar", "highBuffStar"}
	local newBabelSetting = MetaManager.getNewBabelSettings()
	
	local function onGainFloorAdditionSucceed(evt)
		self.container.waitRequest = false
		local buffData = self.attrTable[self.selectIndex]
		self.sharkSkyTowerData.currStatus.currUsedStars = self.sharkSkyTowerData.currStatus.currUsedStars + newBabelSetting[buffStarKeyTable[self.selectIndex + 1]]
		self.sharkSkyTowerData.currStatus[buffData.buffType] = self.sharkSkyTowerData.currStatus[buffData.buffType] + buffData.value
		if not self.sharkSkyTowerData.currStatus.gainFloorBuff then
			self.sharkSkyTowerData.currStatus.gainFloorBuff = {}
		end
		table.insert(self.sharkSkyTowerData.currStatus.gainFloorBuff, self.sharkSkyTowerData.currStatus.currFloor + 1)
		DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)
		onClosePanel()
	end
	
	local function onGainFloorAdditionFailed(evt)
		self.container.waitRequest = false
		if evt.data == 713508 then
			local function closeCanonMessageBox()
				self.container:sendGetSkyTowerInfoRequest()
				onClosePanel()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713515 then
			local function closeCanonMessageBox()
				self.container:sendGetSkyTowerInfoRequest()
				onClosePanel()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_starNotEnough"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713516 then
			local function closeCanonMessageBox()
				self.container:sendGetSkyTowerInfoRequest()
				onClosePanel()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_buffAdded"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function onClickBuff(evt)
		if self.container.waitRequest then
			do return end
		end
		self.container.waitRequest = true
		self.selectIndex = evt.context
		print("####################"..evt.context)
		--onGainFloorAdditionSucceed()
		--do return end
		local request = GainFloorAdditionRequest.new( {type = evt.context}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GainFloorAdditionSucceed, onGainFloorAdditionSucceed )
		request:addEventListener( RequestNotifyEnum.GainFloorAdditionFailed, onGainFloorAdditionFailed )
		request:start()
	end
	
	local buffCalcNum = ((((self.sharkSkyTowerData.currStatus.climbTimes * newBabelSetting.challengeTimeHashPrime) % newBabelSetting.hashModPrime 
	+ (self.sharkSkyTowerData.currStatus.currFloor + 1) * newBabelSetting.floorHashPrime) % newBabelSetting.hashModPrime
	+ self.sharkSkyTowerData.currStatus.days * newBabelSetting.dateHashPrime ) % newBabelSetting.hashModPrime
	+ self.sharkSkyTowerData.sharkSkyTower.uid * newBabelSetting.userIdHashPrime ) % newBabelSetting.hashModPrime
	local buffMeta = MetaManager.sky_tower_buff[MetaManager.random_number_table[buffCalcNum % table.getn(MetaManager.random_number_table) + 1] % 100]
	self.attrTable = {}
	
	local indexMap = {}
	indexMap[1] = 1
	indexMap[2] = 3
	indexMap[3] = 2
	for i = 1, 3 do
		local index = indexMap[i]
		local button = Button:create(self.panelUI:getChildByName("btn_buff_chose" .. index))
		button:addEventListener( Events.kStart, onClickBuff, (index - 1) )  
		local stars = newBabelSetting[buffStarKeyTable[index]]
		button.display:getChildByName("txt"):setString(Localization:getInstance():getText("skyTower_buyBuffBtn", {num = tostring(stars)}))
		
		if self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars < stars then
			button:setEnable(false)
			button.display:getChildByName("btn"):setVisible(false)
		end
		
		local buffType = buffMeta["buffType" .. index]
		local buffSpriteName
		self.attrTable[index - 1] = {}
		local text = ""
		if buffType == 1 then--add atk
			self.attrTable[index - 1].value = math.floor(getFloatNumber(newBabelSetting.atkBuffCoef) * 100 * stars) / 100
			text = getTextByKey("attr_Attack") .. "+" .. tostring(self.attrTable[index - 1].value * 100) .. "%"
			self.attrTable[index - 1].buffType = "selfAtkBuff"
			buffSpriteName = "Item/Picture/attack_up.png"
		elseif buffType == 2 then--add def
			self.attrTable[index - 1].value = math.floor(getFloatNumber(newBabelSetting.defBuffCoef) * 100 * stars) / 100
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
			self.attrTable[index - 1].value = math.floor(getFloatNumber(newBabelSetting.hpBuffCoef) * 100 * stars) / 100
			text = getTextByKey("attr_HP") .. "+" .. tostring(self.attrTable[index - 1].value * 100) .. "%"
			self.attrTable[index - 1].buffType = "selfHpBuff"
			buffSpriteName = "Item/Picture/hp_up.png"
		end
		self.panelUI:getChildByName("txt_buff5_" .. i):getChildByName("txt"):setString(text)
		local fakeBuffSprite = self.panelUI:getChildByName("normal_card_small" .. i)
		fakeBuffSprite:setVisible(false)
		local realBuffSprite = Sprite:create(buffSpriteName)
		realBuffSprite:setPositionXY(fakeBuffSprite:getPositionX(), fakeBuffSprite:getPositionY())
		self.panelUI:addChildAt(realBuffSprite, fakeBuffSprite:getZOrder() + 1)
	end

	self:addChild(self.panelUI)
	
end


