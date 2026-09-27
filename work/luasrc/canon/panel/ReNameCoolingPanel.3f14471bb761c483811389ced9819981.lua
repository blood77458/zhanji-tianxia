require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ReNameInputPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ReNameCoolingPanel = class(Layer)

function ReNameCoolingPanel:ctor()
	self.container = nil
end

function ReNameCoolingPanel:create( container )
	self.container = container
	local s = ReNameCoolingPanel.new()
	s:initLayer()
	return s
end

function ReNameCoolingPanel:refreshCoolingTime()
	local renameNextTime = CalculationManager.calcComplex_getRenameCoolingTime()
	self.panelUI:getChildByName("common_txt_changename_cooling_3"):getChildByName("txt"):setString(renameNextTime)
end

function ReNameCoolingPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	ReNameCoolingPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_change_name_cooling")

	self.panelUI:getChildByName("common_txt_changename_cooling_1"):getChildByName("txt"):setString(getTextByKey("rename_CDing1"))
	self.panelUI:getChildByName("common_txt_changename_cooling_2"):getChildByName("txt"):setString(getTextByKey("rename_CDing3"))
	self.panelUI:getChildByName("common_btn_sellItem_yes"):getChildByName("txt_yes"):setString(getTextByKey("yes"))
	self:refreshCoolingTime()

	local function refreshFunc()
		self:refreshCoolingTime()
	end

	self.onUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshFunc,1,false);


	-- 关闭Panel事件
	local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
	end

	-- 关闭按钮
	local closeButtonDisplay = self.panelUI:getChildByName("common_btn_sellItem_yes")
	local closeButton = Button:create(closeButtonDisplay)
	closeButton:addEventListener(Events.kStart, onClosePanel, self)
	
	self:addChild(self.panelUI)
end

function ReNameCoolingPanel:dispose()
	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateFunc)
end