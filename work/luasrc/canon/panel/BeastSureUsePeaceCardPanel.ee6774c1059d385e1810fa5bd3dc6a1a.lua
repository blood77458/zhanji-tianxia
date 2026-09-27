require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

BeastSureUsePeaceCardPanel = class(Layer)

function BeastSureUsePeaceCardPanel:ctor()
	self.container = nil
end

function BeastSureUsePeaceCardPanel:create( container, peaceCardInfo, isNormal, confirmCallback)
	self.container = container
	self.isNormal = isNormal
	self.cost = peaceCardInfo.cost
	self.name = peaceCardInfo.name
	self.confirmCallback = confirmCallback
	local s = BeastSureUsePeaceCardPanel.new()
	s:initLayer()
	return s
end

function BeastSureUsePeaceCardPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	BeastSureUsePeaceCardPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	if self.isNormal then
		self.panelUI = builder:build("common_popup_buyItem_silver")
	else
		self.panelUI = builder:build("common_popup_buyItem_gold")
	end
	
	self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("beast_peaceConfirm1"))
		self.panelUI:getChildByName("common_txt_sellItem_price_num"):getChildByName("font"):setString(tostring(self.cost))
		local text = Localization:getInstance():getText("beast_peaceConfirm2", {propname = self.name})
		self.panelUI:getChildByName("common_txt_buyItem2"):getChildByName("txt_sellItem_equip"):setString(text)
		self.panelUI:getChildByName("common_txt_buyItem3"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("beast_peaceConfirm3"))
		self.panelUI:getChildByName("common_btn_sellItem_yes"):getChildByName("txt_yes"):setString(getTextByKey("yes"))
		self.panelUI:getChildByName("common_btn_sellItem_no"):getChildByName("txt_cancel"):setString(getTextByKey("cancel"))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_sellItem_no"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local function onOKClick(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		if self.confirmCallback then
			self.confirmCallback()
		end
	end
	
	local bt_panel_ok = Button:create(self.panelUI:getChildByName("common_btn_sellItem_yes"))
	bt_panel_ok:addEventListener(Events.kStart, onOKClick)

	self:addChild(self.panelUI)
end
