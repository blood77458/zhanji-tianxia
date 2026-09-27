require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

GachaBoxAttensionPanel = class(Layer)

function GachaBoxAttensionPanel:ctor()
	self.container = nil
end

function GachaBoxAttensionPanel:create( container)
	self.container = container
	self.preTargetInfoPanel = self.container.targetInfoPanel
	
	local s = GachaBoxAttensionPanel.new()
	s:initLayer()
	return s
end

function GachaBoxAttensionPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	GachaBoxAttensionPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_towerBabel_rule")
	
	self.panelUI:getChildByName("txt_towerBabel_rule_title"):getChildByName("txt"):setString(getTextByKey("boxGacha_popup_rule_title"))
	local text = "\n" --?????,????
	for i = 1, 3 do
		text = text .. getTextByKey("boxGacha_popup_rule_text" .. i) .. "\n"
	end
	self.panelUI:getChildByName("txt_towerBabel_rule"):setTouchEnabled(false)
	self.panelUI:getChildByName("txt_towerBabel_rule"):getChildByName("txt"):setString(text)
	self.panelUI:getChildByName("btn_do_close"):getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("close"))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = self.preTargetInfoPanel
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close_sb"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_do_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
	
end


