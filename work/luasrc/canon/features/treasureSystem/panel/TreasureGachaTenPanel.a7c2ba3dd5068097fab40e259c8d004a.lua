--------------------------------------------------------------------------------
-- TreasureGachaOnePanel.lua
-- author: l1ghtsaber
-- date: 2015-8-7
--------------------------------------------------------------------------------
require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.panel.GachaCardInfoPanel"
require "hecore.display.CocosObject"
require "hecore.display.Director"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

TreasureGachaTenPanel = class(Layer)

function TreasureGachaTenPanel:ctor()
	self.enableClick = true
	self.nextTimes = 10
	self.cost = tonumber(DataManager.GameMetaData.treasureGachaConfig.gachaNode.requisites[1].amount) * 10
end

function TreasureGachaTenPanel:create(container, rewards, gachaFunc)
	local panel = TreasureGachaTenPanel.new()
	panel.container = container
	panel.rewards = rewards --所有奖励
	panel.gachaFunc = gachaFunc

	panel:initLayer()
	return panel
end

function TreasureGachaTenPanel:initLayer()
	TreasureGachaTenPanel.super.initLayer(self)

	local bgLayer = LayerColor:create()
	bgLayer:setColor(ccc3( 0, 0, 0 ))
	bgLayer.refCocosObj:setOpacity( 150 )
	bgLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
	self:addChild(bgLayer)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/GachaResult_new.json")
	self.uiBuilder.useArtLabelTTF = true
	self.mainUI = self.uiBuilder:build("GachaResult")
	self:addChild(self.mainUI)

	self.mainUI:getChildByName("txt_up"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_1"))
	self.mainUI:getChildByName("txt_buttom"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_2"))
	self.mainUI:getChildByName("btn_moreplz_nocoin"):setVisible(false)
	self.mainUI:getChildByName("btn_sure"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_3"))
	self.mainUI:getChildByName("btn_moreplz"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_5"))
	self.mainUI:getChildByName("btn_moreplz"):getChildByName("txt_font"):setString(self.cost.."")
	local function onClosePanel(evt)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end
	local closeButton = Button:create(self.mainUI:getChildByName("btn_sure"))
	closeButton:addEventListener(Events.kStart, onClosePanel)

	local function onRecry(evt)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if self.gachaFunc then
			self.gachaFunc(self.cost, self.nextTimes)
		end
	end
	local recryButton = Button:create(self.mainUI:getChildByName("btn_moreplz"))
	recryButton:addEventListener(Events.kStart, onRecry)

	local function createTreasureButton(buttonItem, treasureInfo)
		if treasureInfo == {} then return end
		local function onTreasureClick()
			if self.enableClick then
				local evt = {
					context = {
						container = self,
						treasureId = treasureInfo.treasureId
					}
				}
				TreasureSystem.PopTreasureGachaInfoPanel( evt )
				-- 弹出详情
			end
		end
		self.mainUI:addChild(buttonItem)
		local button = Button:create(buttonItem)
		button:addEventListener(Events.kStart, onTreasureClick)
		local strName = TreasureManager.getTreasureName( treasureInfo )
		local text = TextField:create(
			strName,
			"Helvetica",
			21,
			CCSizeMake(240, 24),
			kCCTextAlignmentCenter
		)
		text:setPosition(ccp(buttonItem:getPosition().x,buttonItem:getPosition().y-80))
		self.mainUI:addChild(text)
	end

	local treasureReward = {}
	for k,v in pairs(self.rewards) do
		if v.itemType == ResourceEnum.TREASURE then
			table.insert(treasureReward,v)
		end
	end
	local posx = {
		[0] = 575,
		[1] = 140,
		[2] = 285,
		[3] = 430
	}
	local posy = {
		[0] = 860,
		[1] = 690,
		[2] = 520
	}
	if #treasureReward > 0 then 
		for i,value in pairs(treasureReward) do 
			local item = CanonGoodIcon.createGoodIcon(ResourceEnum.TREASURE, value.metaId, 1)
			item:setPosition(ccp(posx[i % 4],posy[math.modf((i - 1) / 4)]))
			local treasureInfo = {}
			for k,v in pairs(DataManager.getTreasuresData()) do
				if v.treasureId == value.id then
					treasureInfo = v
					break
				end
			end
			createTreasureButton(item, treasureInfo)
		end
	end
end
