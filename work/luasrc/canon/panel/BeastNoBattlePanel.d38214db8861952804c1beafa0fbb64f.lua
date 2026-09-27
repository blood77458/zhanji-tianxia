require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.BeastSureUsePeaceCardPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function getPeaceCardInfo()
	local function getPeaceCardTableByInfo(metaId, cost)
		local cardTable = {}
		cardTable.metaId = metaId
		cardTable.cost = cost
		cardTable.amount = 0
		for k,item in pairs(DataManager.getPropsData()) do
			if tonumber(item.metaId) == tonumber(metaId) then 
				cardTable.amount = tonumber(item.amount)
				break;
			end
		end
		cardTable.name = getTextByKey(MetaManager.prop_meta[metaId].name)
		cardTable.duration = MetaManager.prop_meta[metaId].effectValue
		return cardTable
	end
	
	local peaceCardInfo = {}
	peaceCardInfo.normalCard = getPeaceCardTableByInfo(MetaManager.game_meta.gameSettingConfig.beastConfig.normalPeaceCardMetaId, MetaManager.game_meta.gameSettingConfig.beastConfig.normalPeaceCardCoinCost)
	peaceCardInfo.magnateCard = getPeaceCardTableByInfo(MetaManager.game_meta.gameSettingConfig.beastConfig.goldPeaceCardMetaId, MetaManager.game_meta.gameSettingConfig.beastConfig.goldPeaceCardGemCost)

	return peaceCardInfo
end

BeastNoBattlePanel = class(Layer)

function BeastNoBattlePanel:ctor()
	self.container = nil
end

function BeastNoBattlePanel:create( container)
	self.container = container
	
	local s = BeastNoBattlePanel.new()
	s:initLayer()
	return s
end

function BeastNoBattlePanel:initLayer()	
	self.container:setTableViewsEnabled(false)
	BeastNoBattlePanel.super.initLayer(self)
	
	self.peaceCardInfo = getPeaceCardInfo()
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
	self.panelUI = builder:build("rob_popup_usetoken")
	
	self.panelUI:getChildByName("btn_use_token"):getChildByName("txt"):setString(getTextByKey("beastPeace_useBtn"))
	self.panelUI:getChildByName("txt_usetoken_title"):getChildByName("txt"):setString(getTextByKey("beast_peaceBtn"))
	self.panelUI:getChildByName("btn_normal_pay"):getChildByName("txt"):setString(tostring(self.peaceCardInfo.normalCard.cost))
	self.panelUI:getChildByName("btn_normal_pay"):getChildByName("txt2"):setString(getTextByKey("beastPeace_useBtn"))
	self.panelUI:getChildByName("btn_magnate_pay"):getChildByName("txt"):setString(tostring(self.peaceCardInfo.magnateCard.cost))
	self.panelUI:getChildByName("btn_magnate_pay"):getChildByName("txt2"):setString(getTextByKey("beastPeace_useBtn"))
	self.panelUI:getChildByName("normal_token"):getChildByName("txt_normal_token"):getChildByName("txt"):setString(self.peaceCardInfo.normalCard.name)
	self.panelUI:getChildByName("normal_token"):getChildByName("rob_txt_token_figure"):getChildByName("txt"):setString("x" .. self.peaceCardInfo.normalCard.amount)
	self.panelUI:getChildByName("magnate_token"):getChildByName("txt_magnate_token"):getChildByName("txt"):setString(self.peaceCardInfo.magnateCard.name)
	self.panelUI:getChildByName("magnate_token"):getChildByName("rob_txt_token_figure"):getChildByName("txt"):setString("x" .. self.peaceCardInfo.magnateCard.amount)
	self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):setVisible(false)
	local itemPos = self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):getPosition() 
	local itemContentSize = self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):getContentSize()
	local scaleX = self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):getScaleX()
	local scaleY = self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):getScaleY()
	local canonItem = CanonItem:create()
	canonItem:loadByMetaId(self.peaceCardInfo.normalCard.metaId)
	canonItem:setPositionXY(itemPos.x + itemContentSize.width / 2 * scaleX, itemPos.y - scaleY * itemContentSize.height / 2)
	self.panelUI:getChildByName("normal_token"):addChildAt(canonItem, self.panelUI:getChildByName("normal_token"):getChildByName("normal_card_small"):getZOrder())
	self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):setVisible(false)
	local itemPos = self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):getPosition()
	local itemContentSize = self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):getContentSize()
	local scaleX = self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):getScaleX()
	local scaleY = self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):getScaleY()
	local canonItem = CanonItem:create()
	canonItem:loadByMetaId(self.peaceCardInfo.magnateCard.metaId)
	canonItem:setPositionXY(itemPos.x + itemContentSize.width / 2 * scaleX, itemPos.y - scaleY * itemContentSize.height / 2)
	self.panelUI:getChildByName("magnate_token"):addChildAt(canonItem, self.panelUI:getChildByName("magnate_token"):getChildByName("normal_card_small"):getZOrder())
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local function onNormalClick(evt)
		self:showToken(true)
	end
	
	local bt_normal = Button:create(self.panelUI:getChildByName("normal_token"))
	bt_normal:addEventListener(Events.kStart, onNormalClick)
	
	local function onMagnateClick(evt)
		self:showToken(false)
	end
	
	local bt_magnate = Button:create(self.panelUI:getChildByName("magnate_token"))
	bt_magnate:addEventListener(Events.kStart, onMagnateClick)
	
	local function showAlreadyUsePanel()
		local function closeCanonMessageBox()
		end
		self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastRob_alreadyInPeace"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
	end
	
	local function onUsePeaceCardSuccess(evt)
		self.waitRequest = false
		local itemData = DataManager.getPropsData()
		local metaId
		local duration
		if self.isNormal then
			metaId = self.peaceCardInfo.normalCard.metaId
			self.peaceCardInfo.normalCard.amount = self.peaceCardInfo.normalCard.amount - 1
			duration = self.peaceCardInfo.normalCard.duration
		else
			metaId = self.peaceCardInfo.magnateCard.metaId
			self.peaceCardInfo.magnateCard.amount = self.peaceCardInfo.magnateCard.amount - 1
			duration = self.peaceCardInfo.magnateCard.duration
		end
		for k,v in pairs(itemData) do
			if v.metaId == metaId then
				v.amount = v.amount - 1
				break;
			end
		end
		DataManager.setPropsData(itemData)
		self:showButton()
		self.container:getNoBattleTimeInfo(duration)
		onClosePanel()
	end
	
	local function onUsePeaceCardFailed(evt)
		self.waitRequest = false
		if evt.data == 716021 then
			showAlreadyUsePanel()
			if type(self.container.regetFragmentInfo) == "function" then
				self.container:regetFragmentInfo()
			end
		elseif evt.data == 710512 then
			self:showNoCoinPanel()
		elseif evt.data == 710513 then
			self:showNoGoldPanel()
		--[[elseif evt.data == 716010 then
			local function closeCanonMessageBox()
				if type(self.container.regetFragmentInfo) == "function" then
					self.container:regetFragmentInfo()
				end
			end
			self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("notEnoughFragments"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)--]]
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function sendUsePeaceCardRequest()
		if self.waitRequest then
			do return end
		end
		
		self.waitRequest = true;
		local propMetaId
		if self.isNormal then
			propMetaId = self.peaceCardInfo.normalCard.metaId
		else
			propMetaId = self.peaceCardInfo.magnateCard.metaId
		end
		
		local request = AvoidBattle.new( {propMetaId = propMetaId, useMoney = false}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.AvoidBattleSucceed, onUsePeaceCardSuccess )
		request:addEventListener( RequestNotifyEnum.AvoidBattleFailed, onUsePeaceCardFailed )
		request:start()
	end
	
	local function onUseClick(evt)
		if self.container.noBattleTimeLeft > 0 then
			showAlreadyUsePanel()
		else
			sendUsePeaceCardRequest()
		end
	end
	
	local bt_use = Button:create(self.panelUI:getChildByName("btn_use_token"))
	bt_use:addEventListener(Events.kStart, onUseClick)
	self.bt_use = bt_use
	
	local function onBuyAndUsePeaceCardSuccess(evt)
		self.waitRequest = false
		local costTable = {}
		local duration 
		if self.isNormal then
			costTable.amount = tostring(-self.peaceCardInfo.normalCard.cost)
			costTable.itemType = 1
			duration = self.peaceCardInfo.normalCard.duration
		else
			costTable.amount = tostring(-self.peaceCardInfo.magnateCard.cost)
			costTable.itemType = 2
			duration = self.peaceCardInfo.magnateCard.duration
		end
		RewardManager:getReward({costTable})
		self.container:getNoBattleTimeInfo(duration)
		onClosePanel()
	end
	
	local function sendBuyAndUsePeaceCard()
		if self.waitRequest then
			do return end
		end
		
		local propMetaId
		if self.isNormal then
			propMetaId = self.peaceCardInfo.normalCard.metaId
			if tonumber(DataManager.getCurrUser().coins) < self.peaceCardInfo.normalCard.cost then
				self:showNoCoinPanel()
				do return end
			end
		else
			propMetaId = self.peaceCardInfo.magnateCard.metaId
			if CalculationManager.calcComplex_getGemsNow() < self.peaceCardInfo.magnateCard.cost then
				self:showNoGoldPanel()
				do return end
			end
		end
		
		self.waitRequest = true;
		
		local request = AvoidBattle.new( {propMetaId = propMetaId, useMoney = true}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.AvoidBattleSucceed, onBuyAndUsePeaceCardSuccess )
		request:addEventListener( RequestNotifyEnum.AvoidBattleFailed, onUsePeaceCardFailed )
		request:start()
	end
	
	local function onNormalPayClick(evt)
		if self.container.noBattleTimeLeft > 0 then
			showAlreadyUsePanel()
		elseif tonumber(DataManager.getCurrUser().coins) < self.peaceCardInfo.normalCard.cost then
			self:showNoCoinPanel()
		else
			self.container.targetInfoPanel = BeastSureUsePeaceCardPanel:create(self.container, self.peaceCardInfo.normalCard, true, sendBuyAndUsePeaceCard)
			PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
		end
	end
	
	local bt_normalpay = Button:create(self.panelUI:getChildByName("btn_normal_pay"))
	bt_normalpay:addEventListener(Events.kStart, onNormalPayClick)
	self.bt_normalpay = bt_normalpay
	
	local function onMagnatePayClick(evt)
		if self.container.noBattleTimeLeft > 0 then
			showAlreadyUsePanel()
		elseif CalculationManager.calcComplex_getGemsNow() < self.peaceCardInfo.magnateCard.cost then
			self:showNoGoldPanel()
		else
			self.container.targetInfoPanel = BeastSureUsePeaceCardPanel:create(self.container, self.peaceCardInfo.magnateCard, false, sendBuyAndUsePeaceCard)
			PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
		end
	end
	
	local bt_magnatepay = Button:create(self.panelUI:getChildByName("btn_magnate_pay"))
	bt_magnatepay:addEventListener(Events.kStart, onMagnatePayClick)
	self.bt_magnatepay = bt_magnatepay
	
	self:showToken(true)
	
	self:addChild(self.panelUI)
end

function BeastNoBattlePanel:showToken(isNormal)
	if self.isNormal == isNormal then
		do return end
	end
	self.isNormal = isNormal
	self.panelUI:getChildByName("normal_token"):getChildByName("normal_token_select"):setVisible(isNormal)
	self.panelUI:getChildByName("magnate_token"):getChildByName("magnate_token_select"):setVisible(not isNormal)
	self.panelUI:getChildByName("select_triangle_l"):setVisible(isNormal)
	self.panelUI:getChildByName("select_triangle_r"):setVisible(not isNormal)
	local text
	if isNormal then
		text = getTextByKey("beastPeace_normalDesc")
	else
		text = getTextByKey("beastPeace_goldDesc")
	end
	self.panelUI:getChildByName("txt_token_info"):getChildByName("txt"):setString(text)
	self:showButton()
end

function BeastNoBattlePanel:showButton()
	local function setNotAffectTouchEvent(obj, notAffectTouchEvent)
		obj.notAffectTouchEvent = notAffectTouchEvent
		if type(obj.list) == "table" then
			for k,v in pairs(obj.list) do
				setNotAffectTouchEvent(v)
			end
		end
	end
	
	self.panelUI:getChildByName("btn_use_token"):setVisible(false)
	self.panelUI:getChildByName("btn_normal_pay"):setVisible(false)
	self.panelUI:getChildByName("btn_magnate_pay"):setVisible(false)
	setNotAffectTouchEvent(self.panelUI:getChildByName("btn_use_token"), true)
	setNotAffectTouchEvent(self.panelUI:getChildByName("btn_normal_pay"), true)
	setNotAffectTouchEvent(self.panelUI:getChildByName("btn_magnate_pay"), true)
	self.bt_use:setEnable(false)
	self.bt_normalpay:setEnable(false)
	self.bt_magnatepay:setEnable(false)
	if self.isNormal then
		if self.peaceCardInfo.normalCard.amount > 0 then
			self.panelUI:getChildByName("btn_use_token"):setVisible(true)
			self.bt_use:setEnable(true)
			setNotAffectTouchEvent(self.panelUI:getChildByName("btn_use_token"), false)
		else
			self.panelUI:getChildByName("btn_normal_pay"):setVisible(true)
			self.bt_normalpay:setEnable(true)
			setNotAffectTouchEvent(self.panelUI:getChildByName("btn_normal_pay"), false)
		end
	else
		if self.peaceCardInfo.magnateCard.amount > 0 then
			self.panelUI:getChildByName("btn_use_token"):setVisible(true)
			setNotAffectTouchEvent(self.panelUI:getChildByName("btn_use_token"), false)
			self.bt_use:setEnable(true)
		else
			self.panelUI:getChildByName("btn_magnate_pay"):setVisible(true)
			self.bt_magnatepay:setEnable(true)
			setNotAffectTouchEvent(self.panelUI:getChildByName("btn_magnate_pay"), false)
		end
	end
end

function BeastNoBattlePanel:showNoCoinPanel()
	local function onReplaceScene()
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	self.container.targetInfoPanel = MessageBoxPanel:create(self.container, MessageBoxType.kCoinLimit, {onReplaceSceneFunc = onReplaceScene})
	self.container:addChild(self.container.targetInfoPanel)
	self.container.targetInfoPanel:scaleIn()
end

function BeastNoBattlePanel:showNoGoldPanel()
	local function onReplaceScene()
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
	self.container:addChild(aPanel)
	aPanel:scaleIn()
end