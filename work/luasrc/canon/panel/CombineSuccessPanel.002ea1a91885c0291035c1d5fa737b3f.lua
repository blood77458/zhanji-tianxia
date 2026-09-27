require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CombineSuccessPanel = class(Layer)

function CombineSuccessPanel:ctor()
	self.container = nil
end

function CombineSuccessPanel:create( container, addNodeReplaceWithName, combineData)
	self.container = container
	self.addNodeReplaceWithName = addNodeReplaceWithName
	self.combineData = combineData
	
	local s = CombineSuccessPanel.new()
	s:initLayer()
	return s
end

function CombineSuccessPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	CombineSuccessPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/book_combine.json")
	self.panelUI = builder:build("popup_book_combine_result")

	self.panelUI:getChildByName("txt_reward_com"):getChildByName("txt_reward_com"):setString(getTextByKey("synthetize_popup_success"))
	self.panelUI:getChildByName("button_long_blue"):getChildByName("txt_sure"):setString(getTextByKey("yes"))
	
	local combineSprite = self.panelUI:getChildByName("reward_item")
	combineSprite:getChildByName("normal_card_small"):setVisible(false)
	self.addNodeReplaceWithName(combineSprite, "normal_card_small", getCanonItemByMetaId(self.combineData.productId), "realInfo")
	combineSprite:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(getTextByKey(MetaManager.prop_meta[self.combineData.productId].name))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("button_long_blue"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	
	self:addChild(self.panelUI)
	self:addChild(tableView)

end