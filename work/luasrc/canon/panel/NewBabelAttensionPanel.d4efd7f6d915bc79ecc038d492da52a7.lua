require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewBabelAttensionPanel = class(Layer)

function NewBabelAttensionPanel:ctor()
	self.container = nil
end

function NewBabelAttensionPanel:create( container)
	self.container = container
	self.preTargetInfoPanel = self.container.targetInfoPanel
	
	local s = NewBabelAttensionPanel.new()
	s:initLayer()
	return s
end

function NewBabelAttensionPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelAttensionPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_towerBabel_rule")
	
	self.panelUI:getChildByName("txt_towerBabel_rule_title"):getChildByName("txt"):setString(getTextByKey("babel_ruleTitle"))
	local text = "\n"
	for i = 1, 4 do
		text = text .. getTextByKey("babel_ruleTxt" .. i) .. "\n"
	end
	self.panelUI:getChildByName("txt_towerBabel_rule"):getChildByName("txt"):setString(text)
	self.panelUI:getChildByName("btn_do_close"):getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("close"))
	
	local offset = 180
	local textBk = self.panelUI:getChildByName("white9_panel")
	textBk:setScaleY((textBk:getScaleY() * textBk:getContentSize().height + offset) / textBk:getContentSize().height)
	local panelBk = self.panelUI:getChildByName("new_green_bg9")
	panelBk:setScaleY((panelBk:getScaleY() * panelBk:getContentSize().height + offset) / panelBk:getContentSize().height)
	self.panelUI:getChildByName("huawen_fish_scales_L"):setPositionY(self.panelUI:getChildByName("huawen_fish_scales_L"):getPositionY() - offset)
	self.panelUI:getChildByName("huawen_fish_scales_R"):setPositionY(self.panelUI:getChildByName("huawen_fish_scales_R"):getPositionY() - offset)
	self.panelUI:getChildByName("btn_do_close"):setPositionY(self.panelUI:getChildByName("btn_do_close"):getPositionY() - offset)
	self.panelUI:getChildByName("bg_decoration_loose"):setPositionY(self.panelUI:getChildByName("bg_decoration_loose"):getPositionY() - offset)
	
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


