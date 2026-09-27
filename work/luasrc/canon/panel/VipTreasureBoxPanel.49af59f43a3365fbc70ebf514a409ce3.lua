require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.models.RewardManager"
require "canon.scene.BeastScene"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

VipTreasureBoxPanel = class(Layer)

function VipTreasureBoxPanel:ctor()
	self.container = nil
end

function VipTreasureBoxPanel:create( container , datas)
	self.container = container
	self.datas = datas
	local s = VipTreasureBoxPanel.new()
	s:initLayer()
	return s
end

function VipTreasureBoxPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	VipTreasureBoxPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/shop_new.json")
	self.panelUI = builder:build("shop_popup_vipmarket")
	
	self.panelUI:getChildByName("txt_reward_com"):getChildByName("txt_reward_com"):setString(getTextByKey("shop_boxPopupText"))
	self.panelUI:getChildByName("btn_buy_moneyver"):getChildByName("txt_sure"):setString(getTextByKey("yes"))
	self.panelUI:getChildByName("reward_item"):setVisible(false)
	
	local tableDatas = {}
	local tableData = {}
	for k,data in ipairs(self.datas) do
		table.insert(tableData, data)
		if k % 3 == 0 then
			table.insert(tableDatas, tableData)
			tableData = {}
		end
	end
	
	if next(tableData) ~= nil then
		table.insert(tableDatas, tableData)
	end
	
	self.panelUI:addChild(self:createTableView(tableDatas))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_buy_moneyver"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local bt_panel_close1 = Button:create(self.panelUI:getChildByName("shop_btn_close"))
	bt_panel_close1:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
end

local TABLEVIEW_CELL_TAG = -1001

local ITEM_FIRST_TAG = 1001

function VipTreasureBoxPanel:createTableView(data)
	local VipTreasureBoxRenderer = class(TableViewRenderer)
	function VipTreasureBoxRenderer:ctor(width, height)
		self.list = data
	end
	
	function VipTreasureBoxRenderer:buildCell(container)
		local cell = Layer:create()
		cell:changeWidthAndHeight(self.width, self.height)	
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
	end
	
	function VipTreasureBoxRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		
		local dataInfo = data[index + 1]
		
		for i = 1, 3 do
			if cell:getChildByTag(ITEM_FIRST_TAG + i - 1) then
				cell:removeChildByTag(ITEM_FIRST_TAG + i - 1, true)
			end
		end
		
		for k, v in ipairs(dataInfo) do 
			local row = (k - 1) % 3 - 1
			local boxDataItem
			local nameText = ""
			local showAmount = true
			local params = {scales = {130 / 144,130 / 144}}
			boxDataItem = CanonGoodIcon.createGoodIcon(v.dataType, v.metaId, v.amount, params) 
			nameText = CanonGoodIcon.getGoodName(v.dataType, v.metaId, v.amount, nil)
			-- if v.dataType == ResourceEnum.COIN then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem.icon =  Sprite:create("common/CoinIcon_Mission.png")
			-- 	boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
			-- 	boxDataItem:setQuality(1, false)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = getTextByKey("resource_silverCoin")
			-- elseif v.dataType == ResourceEnum.GEMS then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem.icon =  Sprite:create("common/GemIcon_Mission.png")
			-- 	boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
			-- 	boxDataItem:setQuality(1, false)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = getTextByKey("resource_goldCoin")
			-- elseif v.dataType == ResourceEnum.CARD then
			-- 	boxDataItem = getHeadIconCanonCardByMetaId(v.metaId)
			-- 	nameText = getTextByKey(MetaManager.card_meta[v.metaId].name)
			-- elseif v.dataType == ResourceEnum.EQUIP then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem:loadByMetaId(v.metaId)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = getTextByKey(MetaManager.equip_meta[v.metaId].name)
			-- elseif v.dataType == ResourceEnum.PROP then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem:loadByMetaId(v.metaId)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = getTextByKey(MetaManager.prop_meta[v.metaId].name)
			-- elseif v.dataType == ResourceEnum.FRIENDPOINT then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem.icon =  Sprite:create("common/FriendpointIcon_Mission.png")
			-- 	boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
			-- 	boxDataItem:setQuality(1, false)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = getTextByKey("resource_friendshipPoint")
			-- elseif v.dataType == ResourceEnum.BEAST_FRAGMENT then
			-- 	boxDataItem = CanonItem:create()
			-- 	boxDataItem.icon =  Sprite:create("#" .. MetaManager.beast_fragment[v.metaId].icon .. ".png")
			-- 	boxDataItem.icon:setScale(130 / boxDataItem.icon:getContentSize().width)
			-- 	--boxDataItem:setQuality(1, false)
			-- 	boxDataItem:addChild(boxDataItem.icon)
			-- 	boxDataItem:setScale(130 / 144)
			-- 	nameText = BeastScene.getBeastFragmentNameByData(v)
			-- 	showAmount = false
			-- end
			
			-- local amount = tonumber(v.amount)
			-- if not amount then
			-- 	amount = 1
			-- end
			
			-- local showText
			-- if showAmount then
			-- 	showText = nameText .. "x" .. amount
			-- else
			-- 	showText = nameText
			-- end
			local amountText = ArtTextField:create(nameText, nil, 25)
			amountText:setAnchorPoint(ccp(0.5, 1))
			amountText:setPosition(ccp(0, -80))
			amountText:setColor(ccc3(255, 255, 255))
			boxDataItem:addChild(amountText)
			boxDataItem:setPosition(ccp(310 + row * 200, self.height / 2 + 15))
			boxDataItem:setTag(ITEM_FIRST_TAG + k - 1)
			cell:addChild(boxDataItem.refCocosObj, 999)
			boxDataItem:dispose();
		end
	end
	
  local renderer = VipTreasureBoxRenderer.new(620, 170)
  local list = TableView:create(renderer, 620, 270, TABLEVIEW_CELL_TAG, {})
	
  list:setPosition(ccp(50, 470))
  return list
end
