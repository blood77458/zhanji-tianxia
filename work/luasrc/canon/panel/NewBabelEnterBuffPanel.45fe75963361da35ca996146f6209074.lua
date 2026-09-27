require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

require "canon.request.GainYesterdayAdditionRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewBabelEnterBuffPanel = class(Layer)

function NewBabelEnterBuffPanel:ctor()
	self.container = nil
end

function NewBabelEnterBuffPanel:create( container, sharkSkyTowerData, callback)
	self.container = container
	self.preTargetInfoPanel = self.container.targetInfoPanel
	self.sharkSkyTowerData = sharkSkyTowerData
	self.callback = callback
	
	local s = NewBabelEnterBuffPanel.new()
	s:initLayer()
	return s
end

function NewBabelEnterBuffPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelEnterBuffPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_buff1")	
	
	-- self.panelUI:getChildByName("txt_towerBabel_buff_a2"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyAtkDebuff))
	-- self.panelUI:getChildByName("txt_towerBabel_buff_a1"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyDefDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_d2"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfAtkBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d1"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfDefBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d0"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfHpBuff) * 100) .. "%")
	-- self.panelUI:getChildByName("txt_towerBabel_14"):getChildByName("txt"):setString(getTextByKey("skyTower_opponent"))
	-- self.panelUI:getChildByName("txt_towerBabel_13"):getChildByName("txt"):setString(getTextByKey("skyTower_self"))
	self.panelUI:getChildByName("txt_buff1"):getChildByName("txt"):setString(getTextByKey("skyTower_chooseBuffTitle"))
	self.panelUI:getChildByName("txt_buff2"):getChildByName("txt"):setString(getTextByKey("skyTower_yesterdayRecord"))
	self.panelUI:getChildByName("txt_buff3"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.pastStatus.maxTotalStars))
	self.panelUI:getChildByName("txt_buff4"):getChildByName("txt"):setString(getTextByKey("skyTower_chooseBuffTxt"))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = self.preTargetInfoPanel
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		if self.callback then
			self.callback()
		end
	end
	
	local bufTextTable = {"attr_Attack", "attr_Defense" , "attr_HP"}
	self.attributeAmount = math.floor(self.sharkSkyTowerData.pastStatus.maxTotalStars * getFloatNumber(MetaManager.getNewBabelSettings().startBuffConvertCoef) * 100)
	
	if MetaManager.getNewBabelSettings().startBuffMin then
		local minAmount = math.floor(getFloatNumber(MetaManager.getNewBabelSettings().startBuffMin) * 100)
		if minAmount > self.attributeAmount then
			self.attributeAmount = minAmount
		end
	end
	
	if MetaManager.getNewBabelSettings().startBuffMax then
		local maxAmount = math.floor(getFloatNumber(MetaManager.getNewBabelSettings().startBuffMax) * 100)
		if maxAmount < self.attributeAmount then
			self.attributeAmount = maxAmount
		end
	end
	
	self.attributeType = "selfAtkBuff"
	
	local function onGainYesterdayAdditionSucceed(evt)
		self.container.waitRequest = false
		self.sharkSkyTowerData.currStatus[self.attributeType] = self.sharkSkyTowerData.currStatus[self.attributeType] + self.attributeAmount / 100
		if not self.sharkSkyTowerData.currStatus.gainFloorBuff then
			self.sharkSkyTowerData.currStatus.gainFloorBuff = {}
		end
		table.insert(self.sharkSkyTowerData.currStatus.gainFloorBuff, 0)
		DataManager.setSharkSkyTowerData(self.sharkSkyTowerData)
		onClosePanel()
	end
	
	local function onGainYesterdayAdditionFailed(evt)
		self.container.waitRequest = false
		if evt.data == 713504 then
			local function closeCanonMessageBox()
				self.container:sendGetSkyTowerInfoRequest()
				onClosePanel()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_inRanking"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713505 then
			local function closeCanonMessageBox()
				self.container:sendGetSkyTowerInfoRequest()
				onClosePanel()
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("skyTower_error_dataDesync"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 713517 then
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
		
		if evt.context == 1 then
			self.attributeType = "selfDefBuff"
		elseif evt.context == 2 then
			self.attributeType = "selfHpBuff"
		end
		
		print("啦啦啦"..evt.context)
		--onGainYesterdayAdditionSucceed()
		--do return end
		local request = GainYesterdayAdditionRequest.new( {type = evt.context}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GainYesterdayAdditionSucceed, onGainYesterdayAdditionSucceed )
		request:addEventListener( RequestNotifyEnum.GainYesterdayAdditionFailed, onGainYesterdayAdditionFailed )
		request:start()
	end
	
	local buffNameTable = {"attack_up.png", "defense_up.png" , "hp_up.png"}
	for i = 1, 3 do
		local button = Button:create(self.panelUI:getChildByName("btn_buff_chose" .. i))
		button:addEventListener( Events.kStart, onClickBuff, (i - 1) )  
		button.display:getChildByName("txt"):setString(getTextByKey("skyTower_chooseBuffBtn"))
		self.panelUI:getChildByName("txt_buff5_" .. i):getChildByName("txt"):setString(getTextByKey(bufTextTable[i]) .. "+" .. tostring(self.attributeAmount) .. "%")
		local fakeBuffSprite = self.panelUI:getChildByName("normal_card_small" .. i)
		fakeBuffSprite:setVisible(false)
		local realBuffSprite = Sprite:create("Item/Picture/"..buffNameTable[i])
		realBuffSprite:setPositionXY(fakeBuffSprite:getPositionX(), fakeBuffSprite:getPositionY())
		self.panelUI:addChildAt(realBuffSprite, fakeBuffSprite:getZOrder() + 1)
	end

	self:addChild(self.panelUI)
	
end


