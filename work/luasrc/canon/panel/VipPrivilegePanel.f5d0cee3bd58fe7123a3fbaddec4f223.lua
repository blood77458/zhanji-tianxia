require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local innerInfoTable = {}
local maxLevel = 0
for k,v in pairs(MetaManager.vip_setting) do
	if maxLevel < v.level then
		maxLevel = v.level
	end
end
local UP_HEIGHT = 68
local MIDDLE_HEIGHT = 26
local BOTTOM_HEIGHT = 14

local function setCocosObjectFilterLeft(obj)
	obj.isFilterLeftObject = true
	if type(obj.list) == "table" then
		for k, v in pairs(obj.list) do
			setCocosObjectFilterLeft(v)
		end
	end
end

local function setButtonInFilter(button)
	--setCocosObjectFilterLeft(button.display)
end

local function setButtonEnable(button , value)
	if button then
		button:setEnable(value)
		button:setVisible(value)
		local isInArea = (button.display:getPositionX() >= 0)
		if value ~= isInArea then
			if isInArea then
				button.display:setPositionX(button.display:getPositionX() - 720)
			else
				button.display:setPositionX(button.display:getPositionX() + 720)
			end
		end
	end
end

local function closePrivilegeItem(container,level, noreset)
	innerInfoTable[level].isShow = false
	setButtonEnable(innerInfoTable[level].detailShowTextButton, false)
	setButtonEnable(innerInfoTable[level + 1].touchShowTextButton, true)
	innerInfoTable[level].layer:setPositionY(innerInfoTable[level].layer:getPositionY() - innerInfoTable[level].textHeight)
	container.layerHeight = container.layerHeight - innerInfoTable[level].textHeight
	container.clipLayer:setContentSize(CCSizeMake(visibleSize.width, container.layerHeight))
	local newPosY = container.clipLayer:getPositionY() + innerInfoTable[level].textHeight
	if not noreset and newPosY > 0 then
		newPosY = 0
	end
	container.clipLayer:setPositionY(newPosY)
end

VipPrivilegePanel = class(Layer)

local function getNextLevelPosY(level)
	local posY = (maxLevel - level) * (BOTTOM_HEIGHT + MIDDLE_HEIGHT + UP_HEIGHT)
	for i = level + 1 , #innerInfoTable do
		if innerInfoTable[i] and innerInfoTable[i].isShow then
			posY = posY + innerInfoTable[i].textHeight
		end
	end
	return -posY
end

local function getTransferredPositionY(posY, textHeight, level)
	local newPosY = posY - textHeight
	local nextLevelPosY = getNextLevelPosY(level)
	if newPosY < nextLevelPosY then
		newPosY = nextLevelPosY
	end
	
	local thisLevelPosY = nextLevelPosY - (BOTTOM_HEIGHT + MIDDLE_HEIGHT + UP_HEIGHT) - textHeight
	if thisLevelPosY < newPosY - 550 then
		newPosY = thisLevelPosY + 550
	end
	
	if newPosY > 0 then
		newPosY = 0
	end
	return newPosY
end

function VipPrivilegePanel:ctor()
	self.container = nil
	self.layerHeight = 0
	self.previousPosY = 0
end

function VipPrivilegePanel:create( container , vipInfo)
	self.container = container
	self.vipInfo = vipInfo
	self.getVIPdataFunc = ShopScene.getVipTreasureBoxDatas
	local s = VipPrivilegePanel.new()
	s:initLayer()
	return s
end

function VipPrivilegePanel:initLayer()
	VipPrivilegePanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/shop_new.json")
	self.builder = builder
	self.panelUI = builder:build("shop_popup_vipprivilege")
	--[[for k, data in pairs(self.panelUI.list) do
		if data.name ~= "shop_btn_close" then
			data.notAffectTouchEvent = true
		end
	end--]]

	if self.vipInfo.level < 15 then
		maxLevel = 15
	elseif self.vipInfo.level == 15 then
		maxLevel = 16
	elseif self.vipInfo.level == 16 then
		maxLevel = 17
	end

	self.panelUI:getChildByName("txt_exp_font"):getChildByName("txt"):setString(tostring(self.vipInfo.levelupCurGold) .. "/" .. tostring(self.vipInfo.levelupTotalGold))
	local progressBar = ProgressBar:create(self.panelUI:getChildByName("vip_boost"):getChildByName("vip_boost_sb"))
	local percentage = 0
	if self.vipInfo.levelupTotalGold > 0 then
		percentage = self.vipInfo.levelupCurGold / self.vipInfo.levelupTotalGold * 100
	end
	if percentage > 100 then
		percentage = 100
	end
	progressBar:setPercentage(percentage)
	self.progressBar = progressBar
	
	local vipText = ""
	local showLevel = self.vipInfo.level
	
	local vipPos = self.panelUI:getChildByName("shop_icon_common_vip_ing"):getPosition()
	local vipContentSize = self.panelUI:getChildByName("shop_icon_common_vip_ing"):getContentSize()
	
	local numberLabel = CCLabelAtlas:create(tonumber(showLevel), "pic/number_vip.png", 22, 41, 48)
	numberLabel:setScale(1.25)
	numberLabel:setAnchorPoint(ccp(0, 0.5))
	numberLabel:setPosition(ccp(vipPos.x + vipContentSize.width, vipPos.y - vipContentSize.height /2))
	local numberLabel_co = CocosObject.new(numberLabel)
	self.panelUI:addChild(numberLabel_co)
	self.numberLabel = numberLabel
	
	if self.vipInfo.isMaxLevel then
		vipText = getTextByKey("shop_vipPrivilege_levelMax")
		self.panelUI:getChildByName("shop_icon_common_vip_ing2"):setVisible(false)
	else
		vipText = Localization:getInstance():getText("shop_vipPrivilege_vipLevel", {num = self.vipInfo.levelupTotalGold - self.vipInfo.levelupCurGold, viplevel = "" })	
		local vipPos = self.panelUI:getChildByName("shop_icon_common_vip_ing2"):getPosition()
		local vipContentSize = self.panelUI:getChildByName("shop_icon_common_vip_ing2"):getContentSize()
		
		local numberLabel = CCLabelAtlas:create(tonumber(showLevel + 1), "pic/number_vip.png", 22, 41, 48)
		numberLabel:setScale(1.25)
		numberLabel:setAnchorPoint(ccp(0, 0.5))
		numberLabel:setPosition(ccp(vipPos.x + vipContentSize.width, vipPos.y - vipContentSize.height /2))
		local numberLabel_co = CocosObject.new(numberLabel)
		self.panelUI:addChild(numberLabel_co)
		self.nextNumberLabel = numberLabel
	end
	
	self.panelUI:getChildByName("shop_vipprivilege_info_list"):setVisible(false)
	
	self:addPrivilegeInfoLayer()
		
	self.panelUI:getChildByName("txt_viprechargemore"):getChildByName("txt"):setString(vipText)
	
	local function onClosePanel(evt)
		self.container.filterObject = false
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("shop_btn_close"))
	setButtonInFilter(bt_panel_close)
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
end

function VipPrivilegePanel:addPrivilegeInfo(textLayer, level, vipPrivilegeText)
	local bg = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
	bg:setAnchorPoint(ccp(0, 1))
	bg:setPositionXY(-textLayer:getContentSize().width / 2, 0)
	textLayer:addChild(bg)
	bg:setVisible(false)
	
	local showBg = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
	showBg:setAnchorPoint(ccp(0, 1))
	textLayer.refCocosObj:addChild(showBg.refCocosObj)
	bg:setPositionY(MIDDLE_HEIGHT / 2)
	showBg:setPositionY(MIDDLE_HEIGHT / 2)
	
	local textLabel = TextField:create(vipPrivilegeText, "Arial", 26, CCSizeMake(500, 0))
	textLabel:setAnchorPoint(ccp(0.5, 1))
	textLabel:setPositionXY(textLayer:getContentSize().width / 2, MIDDLE_HEIGHT / 2)
	textLayer.refCocosObj:addChild(textLabel.refCocosObj)
	textLabel:setColor(ccc3(0, 0, 0))	

	local describeLabel = TextField:create( Localization:getInstance():getText("shop_vipPrivilege_pack", {viplevel = "VIP" .. level})	, "Arial", 26, CCSizeMake(500, 0))
	describeLabel:setAnchorPoint(ccp(0.5, 1))
	textLayer.refCocosObj:addChild(describeLabel.refCocosObj)
	describeLabel:setColor(ccc3(0, 0, 0))
			
	local vipTreasureMetaId
	for k,data in pairs(MetaManager.shop_meta) do
		if data.lifePurchaseLimit == 1 then
			local levels = string.split(data.requireVipLevel, ',');
			local needVipLevel = 99
			for key, tlevel in ipairs(levels) do
				local curLevel = tonumber(tlevel)
				if curLevel < needVipLevel then
					needVipLevel = curLevel
				end
			end
			if needVipLevel == level then
				vipTreasureMetaId = data.metaId
				break
			end
		end
	end
	innerInfoTable[level].textHeight = MIDDLE_HEIGHT + textLabel:getContentSize().height + describeLabel:getContentSize().height
	local boxDataItemTable = {}
	if vipTreasureMetaId then
		local boxdatas = self.getVIPdataFunc({metaId = vipTreasureMetaId})
		for k, v in ipairs(boxdatas) do
			local boxDataItem
			local nameText = ""
			local showAmount = true
			local itemScale = 130 / 144
			if v.dataType == ResourceEnum.COIN then
				boxDataItem = CanonItem:create()
				boxDataItem.icon =  Sprite:create("common/CoinIcon_Mission.png")
				boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
				boxDataItem:setQuality(1, false)
				nameText = getTextByKey("resource_silverCoin")
			elseif v.dataType == ResourceEnum.GEMS then
				boxDataItem = CanonItem:create()
				boxDataItem.icon =  Sprite:create("common/GemIcon_Mission.png")
				boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
				boxDataItem:setQuality(1, false)
				nameText = getTextByKey("resource_goldCoin")
			elseif v.dataType == ResourceEnum.CARD then
				boxDataItem = getHeadIconCanonCardByMetaId(v.metaId)
				itemScale = 1
				nameText = getTextByKey(MetaManager.card_meta[v.metaId].name)
			elseif v.dataType == ResourceEnum.EQUIP then
				boxDataItem = CanonItem:create()
				boxDataItem:loadByMetaId(v.metaId)
				nameText = getTextByKey(MetaManager.equip_meta[v.metaId].name)
			elseif v.dataType == ResourceEnum.PROP then
				boxDataItem = CanonItem:create()
				boxDataItem:loadByMetaId(v.metaId)
				nameText = getTextByKey(MetaManager.prop_meta[v.metaId].name)
			elseif v.dataType == ResourceEnum.FRIENDPOINT then
				boxDataItem = CanonItem:create()
				boxDataItem.icon =  Sprite:create("common/FriendpointIcon_Mission.png")
				boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
				boxDataItem:setQuality(1, false)
				nameText = getTextByKey("resource_friendshipPoint")
			elseif v.dataType == ResourceEnum.BEAST_FRAGMENT then
				boxDataItem = CanonItem:create()
				boxDataItem.icon =  Sprite:create("#" .. MetaManager.beast_fragment[v.metaId].icon .. ".png")
				boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
				--boxDataItem:setQuality(1, false)
				boxDataItem:addChild(boxDataItem.icon)
				nameText = BeastScene.getBeastFragmentNameByData(v)
				showAmount = false
			end
			boxDataItem:setScale(itemScale)
			local amount = tonumber(v.amount)
			if not amount then
				amount = 1
			end
			local showText
			if showAmount then
				showText = nameText .. "x" .. amount
			else
				showText = nameText
			end
			local amountText = ArtTextField:create(showText, nil, 25 * 130 / 144 / itemScale)
			amountText:setAnchorPoint(ccp(0.5, 1))
			amountText:setPosition(ccp(0, -80 * 130 / 144 / itemScale))
			amountText:setColor(ccc3(255, 255, 255))
			--amountText:setColor(ccc3(151, 45, 5))
			boxDataItem:addChild(amountText)
			local row = (k - 1) % 3
			local line = math.floor((k - 1) / 3)
			boxDataItem:setAnchorPoint(ccp(0.5 , 1))
			textLayer.refCocosObj:addChild(boxDataItem.refCocosObj)
			boxDataItemTable[k] = boxDataItem
		end
		innerInfoTable[level].textHeight = innerInfoTable[level].textHeight + math.ceil(#boxdatas / 3) * 200
	end
	bg:setScaleY((MIDDLE_HEIGHT / 2 + innerInfoTable[level].textHeight) / MIDDLE_HEIGHT)
	showBg:setScaleY((MIDDLE_HEIGHT / 2 + innerInfoTable[level].textHeight) / MIDDLE_HEIGHT)
	textLabel:setPositionY(- MIDDLE_HEIGHT / 2)
	describeLabel:setPositionXY(textLabel:getPositionX(), textLabel:getPositionY() - textLabel:getContentSize().height)
	for k, data in ipairs(boxDataItemTable) do
		local row = (k - 1) % 3
		local line = math.floor((k - 1) / 3)
		data:setPosition(ccp(describeLabel:getPositionX() + (row - 1) * 150, describeLabel:getPositionY() - (describeLabel:getContentSize().height + (line + 0.5) * 200)))
		data:dispose()
	end
	showBg:dispose()
	textLabel:dispose()
	describeLabel:dispose()
end

function VipPrivilegePanel:getClipLayer(level)
	local clipLayer
	local clipLayer_co
	if level > maxLevel then
		clipLayer = CCLayer:create()
		clipLayer_co = CocosObject.new(clipLayer)
		innerInfoTable[level] = {} 
		innerInfoTable[level].layer = Layer:create()
		innerInfoTable[level].isShow = false
		innerInfoTable[level].textHeight = 0
		innerInfoTable[level].touchShowText = nil;
		innerInfoTable[level].detailShowText = nil;
		
		local bottomLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_downbg.png")
		bottomLayer:setAnchorPoint(ccp(0.5, 0))
		bottomLayer:setPositionX(visibleSize.width  / 2)
		innerInfoTable[level].layer.refCocosObj:addChild(bottomLayer.refCocosObj)
		bottomLayer:dispose()
		
		local textLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
		textLayer:setAnchorPoint(ccp(0.5, 0))
		textLayer:setPositionXY(visibleSize.width  / 2, BOTTOM_HEIGHT)
		--innerInfoTable[level].layer:addChild(textLayer)
		local bg = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
		bg:setAnchorPoint(ccp(0, 1))
		bg:setPositionXY(-textLayer:getContentSize().width / 2, 0)
		textLayer:addChild(bg)
		bg:setVisible(false)
		
		local textLabel = TextField:create(getTextByKey("shop_vipPrivilege_touch"), "Arial", 26)
		textLabel:setPositionXY(textLayer:getContentSize().width  / 2, MIDDLE_HEIGHT / 2)
		textLabel:setColor(ccc3(0, 255, 0))
		textLayer.refCocosObj:addChild(textLabel.refCocosObj)
		textLabel:dispose()
		
		innerInfoTable[level].touchShowText = textLayer
		
		--[[local stencil = CCSprite:create("pic/none.png")
		stencil:setScaleX(visibleSize.width / stencil:getContentSize().width)
		stencil:setScaleY(visibleSize.height / stencil:getContentSize().height)
		stencil:setAnchorPoint(ccp(0.5, 1))
		stencil:setPosition(ccp(visibleSize.width / 2, 0))
		--clipLayer:setInverted(true)
		stencil:setVisible(false)
		--clipLayer:setStencil(stencil)		--]]
		
		local nextClipLayer,nextClipLayer_co = self:getClipLayer(level - 1)
		nextClipLayer_co:setAnchorPoint(ccp(0.5, 0))
		nextClipLayer_co:setPositionY(BOTTOM_HEIGHT)
		innerInfoTable[level].layer:addChild(nextClipLayer_co)
		innerInfoTable[level].layer:addChild(innerInfoTable[level].touchShowText)
		innerInfoTable[level].layer:setAnchorPoint(ccp(0.5, 0))
		clipLayer_co:addChild(innerInfoTable[level].layer)
		
	else
		if level == 1 then
			clipLayer = CCLayer:create()
			clipLayer_co = CocosObject.new(clipLayer)
			innerInfoTable[level] = {} 
			innerInfoTable[level].layer = Layer:create()
			innerInfoTable[level].isShow = false
			innerInfoTable[level].textHeight = 0
			innerInfoTable[level].touchShowText = nil;
			innerInfoTable[level].detailShowText = nil;
			
			local textLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
			textLayer:setAnchorPoint(ccp(0.5, 1))
			local vipPrivilegeTextTable = VipPrivilegeManager.getVipPrivilegeTextTable(level)
			--textLayer:setScaleY(#vipPrivilegeTextTable + 1)
			textLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT)
			innerInfoTable[level].layer:addChild(textLayer)
			--innerInfoTable[level].textHeight = MIDDLE_HEIGHT * #vipPrivilegeTextTable
			innerInfoTable[level].detailShowText = textLayer
			
			local vipPrivilegeText = ""
			for k,v in ipairs(vipPrivilegeTextTable) do
				vipPrivilegeText = vipPrivilegeText .. k .. "." .. v
				if k ~= #vipPrivilegeTextTable then
					vipPrivilegeText = vipPrivilegeText .. "\n"
				end
			end
			
			self:addPrivilegeInfo(textLayer, level, vipPrivilegeText)			
			
			local upLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_upbg.png")
			upLayer:setAnchorPoint(ccp(0.5, 0))
			upLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT)
			innerInfoTable[level].layer.refCocosObj:addChild(upLayer.refCocosObj)
			
			
			local vipSprite = Sprite:create(UI_RES_PATH.."/shop_new/shop_icon_common_vip.png")
			vipSprite:setPositionXY(120, UP_HEIGHT / 2)
			upLayer.refCocosObj:addChild(vipSprite.refCocosObj)
			vipSprite:dispose()
			
			local numberLabel = CCLabelAtlas:create(tostring(level), "pic/number_vip.png", 22, 41, 48)
			numberLabel:setScale(1.25)
			numberLabel:setAnchorPoint(ccp(0, 0.5))
			numberLabel:setPosition(ccp(170, UP_HEIGHT / 2))
			upLayer.refCocosObj:addChild(numberLabel)
			upLayer:dispose()
			
			innerInfoTable[level].layer:setAnchorPoint(ccp(0.5, 0))
			clipLayer_co:addChild(innerInfoTable[level].layer)
		else
			clipLayer = CCLayer:create()
			clipLayer_co = CocosObject.new(clipLayer)
			innerInfoTable[level] = {} 
			innerInfoTable[level].layer = Layer:create()
			innerInfoTable[level].isShow = false
			innerInfoTable[level].textHeight = 0
			innerInfoTable[level].touchShowText = nil;
			innerInfoTable[level].detailShowText = nil;
			
			local textLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
			textLayer:setAnchorPoint(ccp(0.5, 1))
			local vipPrivilegeTextTable = VipPrivilegeManager.getVipPrivilegeTextTable(level)
			--textLayer:setScaleY(#vipPrivilegeTextTable + 1)
			textLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT)
			innerInfoTable[level].layer:addChild(textLayer)
			--innerInfoTable[level].textHeight = MIDDLE_HEIGHT * #vipPrivilegeTextTable
			innerInfoTable[level].detailShowText = textLayer
			
			local vipPrivilegeText = ""
			for k,v in ipairs(vipPrivilegeTextTable) do
				vipPrivilegeText = vipPrivilegeText .. k .. "." .. v
				if k ~= #vipPrivilegeTextTable then
					vipPrivilegeText = vipPrivilegeText .. "\n"
				end
			end
			
			self:addPrivilegeInfo(textLayer, level, vipPrivilegeText)			
			
			innerInfoTable[level].detailShowText = textLayer
			
			local upLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_upbg.png")
			upLayer:setAnchorPoint(ccp(0.5, 0))
			upLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT)
			innerInfoTable[level].layer.refCocosObj:addChild(upLayer.refCocosObj)
			
			local vipSprite = Sprite:create(UI_RES_PATH.."/shop_new/shop_icon_common_vip.png")
			vipSprite:setPositionXY(120, UP_HEIGHT / 2)
			upLayer.refCocosObj:addChild(vipSprite.refCocosObj)
			vipSprite:dispose()
			
			local numberLabel = CCLabelAtlas:create(tostring(level), "pic/number_vip.png", 22, 41, 48)
			numberLabel:setScale(1.25)
			numberLabel:setAnchorPoint(ccp(0, 0.5))
			numberLabel:setPosition(ccp(170, UP_HEIGHT / 2))
			upLayer.refCocosObj:addChild(numberLabel)
			upLayer:dispose()
			
			local bottomLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_downbg.png")
			bottomLayer:setAnchorPoint(ccp(0.5, 0))
			bottomLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT + UP_HEIGHT)
			innerInfoTable[level].layer.refCocosObj:addChild(bottomLayer.refCocosObj)
			bottomLayer:dispose()
			
			local textLayer = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
			textLayer:setAnchorPoint(ccp(0.5, 0))
			textLayer:setPositionXY(visibleSize.width  / 2, MIDDLE_HEIGHT + UP_HEIGHT + BOTTOM_HEIGHT)
			
			local bg = Sprite:create(UI_RES_PATH.."/shop_new/shop_vipprivilege_middlebg.png")
			bg:setAnchorPoint(ccp(0, 1))
			bg:setPositionXY(-textLayer:getContentSize().width / 2, 0)
			textLayer:addChild(bg)
			bg:setVisible(false)
			
			local textLabel = TextField:create(getTextByKey("shop_vipPrivilege_touch"), "Arial", 26)
			textLabel:setColor(ccc3(0, 255, 0))
			textLabel:setPositionXY(textLayer:getContentSize().width / 2, MIDDLE_HEIGHT / 2)
			textLayer.refCocosObj:addChild(textLabel.refCocosObj)
			textLabel:dispose()
			--innerInfoTable[level].layer:addChild(textLayer)
			
			innerInfoTable[level].touchShowText = textLayer
			
			--[[local stencil = CCSprite:create("pic/none.png")
			stencil:setScaleX(visibleSize.width / stencil:getContentSize().width)
			stencil:setScaleY(visibleSize.height / stencil:getContentSize().height)
			stencil:setAnchorPoint(ccp(0.5, 1))
			stencil:setPosition(ccp(visibleSize.width / 2, 0))
			--clipLayer:setInverted(true)
			stencil:setVisible(false)
			--clipLayer:setStencil(stencil)--]]
			
			local nextClipLayer,nextClipLayer_co = self:getClipLayer(level - 1)
			nextClipLayer_co:setAnchorPoint(ccp(0.5, 0))
			nextClipLayer_co:setPositionY(MIDDLE_HEIGHT + UP_HEIGHT + BOTTOM_HEIGHT)
			innerInfoTable[level].layer:addChild(nextClipLayer_co)
			innerInfoTable[level].layer:addChild(innerInfoTable[level].detailShowText)
			innerInfoTable[level].layer:addChild(innerInfoTable[level].touchShowText)
			
			innerInfoTable[level].layer:setAnchorPoint(ccp(0.5, 0))
			clipLayer_co:addChild(innerInfoTable[level].layer)
		end
	end
	
	local function onClickExtendBegin(evt)
		self.previousPosY = self.clipLayer:getPositionY()
	end
	
	local function onClickExtend(evt)
		if math.abs(self.previousPosY - self.clipLayer:getPositionY()) > 10 then
			do return end
		end
		local level = evt.context
		setButtonEnable(innerInfoTable[level].touchShowTextButton, false)
		setButtonEnable(innerInfoTable[level - 1].detailShowTextButton, true)
		for i = 1 , #innerInfoTable do
			if innerInfoTable[i] and innerInfoTable[i].isShow then
				closePrivilegeItem(self, i, true)
			end
		end
		innerInfoTable[level - 1].isShow = true
		innerInfoTable[level - 1].layer:setPositionY(innerInfoTable[level - 1].layer:getPositionY() + innerInfoTable[level - 1].textHeight)
		self.layerHeight = self.layerHeight + innerInfoTable[level - 1].textHeight
		self.clipLayer:setContentSize(CCSizeMake(visibleSize.width, self.layerHeight))
		self.clipLayer:setPositionY(getTransferredPositionY(self.clipLayer:getPositionY() , innerInfoTable[level - 1].textHeight, level - 1))
	end
	
	local function onClickCloseBegin(evt)
		self.previousPosY = self.clipLayer:getPositionY()
	end
	
	local function onClickClose(evt)
		if math.abs(self.previousPosY - self.clipLayer:getPositionY()) > 10 then
			do return end
		end
		closePrivilegeItem(self, evt.context)
		
	end
	
	
	if innerInfoTable[level].touchShowText then
		local button = Button:create(innerInfoTable[level].touchShowText)
		button.noTouchEffect = true
		setButtonInFilter(button)
		innerInfoTable[level].touchShowTextButton = button
		setButtonEnable(button, true)
		button:addEventListener( Events.kStartClickBegin, onClickExtendBegin , level)
		button:addEventListener( Events.kStart, onClickExtend , level)
	end
	
	if innerInfoTable[level].detailShowText then
		local button = Button:create(innerInfoTable[level].detailShowText)
		button.noTouchEffect = true
		setButtonInFilter(button)
		innerInfoTable[level].detailShowTextButton = button
		setButtonEnable(button, false)
		button:addEventListener( Events.kStartClickBegin, onClickCloseBegin , level)
		button:addEventListener( Events.kStart, onClickClose , level)
	end
	
	return clipLayer, clipLayer_co
end

function VipPrivilegePanel:addPrivilegeInfoLayer()
	local scrollView = CCScrollView:create()
	local scrollView_co = CocosObject.new(scrollView)
	scrollView:setViewSize(CCSizeMake(visibleSize.width, 550))
	scrollView:setDirection(kCCScrollViewDirectionVertical)
	
	local clipLayer, clipLayer_co = self:getClipLayer(maxLevel + 1)
	self.layerHeight = (UP_HEIGHT + MIDDLE_HEIGHT + BOTTOM_HEIGHT) * (maxLevel)
	
	clipLayer:setContentSize(CCSizeMake(visibleSize.width, self.layerHeight))
	self.clipLayer = clipLayer
	local level = self.vipInfo.level
	if level <= 0 then
		level = 1
	end
	local clipLayerPosY = -self.layerHeight + 550
	clipLayer:setPosition(ccp(0, clipLayerPosY))
	
	local clipLayerPosY = self.clipLayer:getPositionY()
	clipLayerPosY = clipLayerPosY + (UP_HEIGHT + MIDDLE_HEIGHT + BOTTOM_HEIGHT) * (level - 1)
	if clipLayerPosY > 0 then
		clipLayerPosY = 0
	end
	self.clipLayer:setPositionY(clipLayerPosY)
	setButtonEnable(innerInfoTable[level + 1].touchShowTextButton, false)
	setButtonEnable(innerInfoTable[level].detailShowTextButton, true)
	innerInfoTable[level].isShow = true
	innerInfoTable[level].layer:setPositionY(innerInfoTable[level].layer:getPositionY() + innerInfoTable[level].textHeight)
	self.layerHeight = self.layerHeight + innerInfoTable[level].textHeight
	self.clipLayer:setContentSize(CCSizeMake(visibleSize.width, self.layerHeight))
	self.clipLayer:setPositionY(getTransferredPositionY(self.clipLayer:getPositionY() , innerInfoTable[level].textHeight, level))		
	
	scrollView:setContainer(clipLayer)
	scrollView:setPosition(ccp(0, 290))
	scrollView:setBounceable(false)
	local zOrder = self.panelUI:getChildByName("shop_btn_close"):getZOrder()
	self.panelUI:addChildAt(scrollView_co, zOrder)
	table.insert(scrollView_co.list, #scrollView_co.list+1, clipLayer_co);
	clipLayer_co.parent = scrollView_co;
end

function VipPrivilegePanel:refreshPanel(vipInfo)
	self.container.filterObject = true
	self.vipInfo = vipInfo
	self.container:setTableViewsEnabled(false)
	
	self.panelUI:getChildByName("txt_exp_font"):getChildByName("txt"):setString(tostring(self.vipInfo.levelupCurGold) .. "/" .. tostring(self.vipInfo.levelupTotalGold))
	local percentage = 0
	if self.vipInfo.levelupTotalGold > 0 then
		percentage = self.vipInfo.levelupCurGold / self.vipInfo.levelupTotalGold * 100
	end
	if percentage > 100 then
		percentage = 100
	end
	self.progressBar:setPercentage(percentage)
	
	local vipText = ""
	local showLevel = self.vipInfo.level
	
	self.numberLabel:setString(tonumber(showLevel))
	
	
	if self.vipInfo.isMaxLevel then
		vipText = getTextByKey("shop_vipPrivilege_levelMax")
		self.panelUI:getChildByName("shop_icon_common_vip_ing2"):setVisible(false)
	else
		self.panelUI:getChildByName("shop_icon_common_vip_ing2"):setVisible(true)
		vipText = Localization:getInstance():getText("shop_vipPrivilege_vipLevel", {num = self.vipInfo.levelupTotalGold - self.vipInfo.levelupCurGold, viplevel = "" })	

		self.nextNumberLabel:setString(tonumber(showLevel + 1))
	end
	
	
	for i = 1 , #innerInfoTable do
		if innerInfoTable[i] and innerInfoTable[i].isShow then
			closePrivilegeItem(self, i, true)
		end
	end
	
	self.layerHeight = (UP_HEIGHT + MIDDLE_HEIGHT + BOTTOM_HEIGHT) * (maxLevel)
	self.clipLayer:setContentSize(CCSizeMake(visibleSize.width, self.layerHeight))
	local level = self.vipInfo.level
	if level <= 0 then
		level = 1
	end
	local clipLayerPosY = -self.layerHeight + 550
	self.clipLayer:setPosition(ccp(0, clipLayerPosY))
	
	local clipLayerPosY = self.clipLayer:getPositionY()
	clipLayerPosY = clipLayerPosY + (UP_HEIGHT + MIDDLE_HEIGHT + BOTTOM_HEIGHT) * (level - 1)
	if clipLayerPosY > 0 then
		clipLayerPosY = 0
	end
	self.clipLayer:setPositionY(clipLayerPosY)
	for k, innerInfo in pairs(innerInfoTable) do
		setButtonEnable(innerInfo.touchShowTextButton, true)
		setButtonEnable(innerInfo.detailShowTextButton, false)
		innerInfo.isShow = false
	end
	setButtonEnable(innerInfoTable[level + 1].touchShowTextButton, false)
	setButtonEnable(innerInfoTable[level].detailShowTextButton, true)
	innerInfoTable[level].isShow = true
	innerInfoTable[level].layer:setPositionY(innerInfoTable[level].layer:getPositionY() + innerInfoTable[level].textHeight)
	self.layerHeight = self.layerHeight + innerInfoTable[level].textHeight
	self.clipLayer:setContentSize(CCSizeMake(visibleSize.width, self.layerHeight))
	self.clipLayer:setPositionY(getTransferredPositionY(self.clipLayer:getPositionY() , innerInfoTable[level].textHeight, level))		
		
	self.panelUI:getChildByName("txt_viprechargemore"):getChildByName("txt"):setString(vipText)
	
end