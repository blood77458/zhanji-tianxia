require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

BatchSelectSpiritPanel = class(Layer)

function BatchSelectSpiritPanel:ctor()
	self.container = nil
	self.selectIds = {
	[1] = false,
	[2] = false,
	[3] = false,
}
end

function BatchSelectSpiritPanel:create( container , extraParams)
	self.container = container
  	self.extraParams = extraParams
	local s = BatchSelectSpiritPanel.new()
	s:initLayer()
	return s
end

function BatchSelectSpiritPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	BatchSelectSpiritPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/elesoul.json")
	self.ui = builder:build("popup_select_key")
  	self:addChild(self.ui)
		
		-- 关闭Panel事件
	local function onClosePanel(evt)
	    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	    self.container:setTableViewsEnabled(true)
    end

    self.ui:getChildByName("txt_key_title"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_batchTitle"))

    -- 关闭按钮
    local closeButtonDisplay = self.ui:getChildByName("btn_close")
    local closeButton = Button:create(closeButtonDisplay)
    closeButton:addEventListener(Events.kStart, onClosePanel, self)

    local spiritRare = SpiritManager.getSpiritRare( self.container.spirit )

    local function onSelect( evt )
		self.selectId = evt.context
		if spiritRare < self.selectId then
			SuspensionLabel:showContent(self, getTextByKey("spirit_highRarity_tips"))
			return
		end

		if self.selectIds[self.selectId] then
			self.ui:getChildByName("btn_key_combine"..self.selectId):getChildByName("icon_m_check1"):getChildByName("btn_selected_all"):setVisible(false)
			self.ui:getChildByName("btn_key_combine"..self.selectId):getChildByName("icon_m_check1"):getChildByName("btn_not_selected_all"):setVisible(true)
			-- self.ui:getChildByName("icon_m_check"..self.selectId):getChildByName("btn_selected_all"):setVisible(false)
			-- self.ui:getChildByName("icon_m_check"..self.selectId):getChildByName("btn_not_selected_all"):setVisible(true)
			self.selectIds[self.selectId] = false
		else
			self.ui:getChildByName("btn_key_combine"..self.selectId):getChildByName("icon_m_check1"):getChildByName("btn_selected_all"):setVisible(true)
			self.ui:getChildByName("btn_key_combine"..self.selectId):getChildByName("icon_m_check1"):getChildByName("btn_not_selected_all"):setVisible(false)
			
			-- self.ui:getChildByName("icon_m_check"..self.selectId):getChildByName("btn_selected_all"):setVisible(true)
			-- self.ui:getChildByName("icon_m_check"..self.selectId):getChildByName("btn_not_selected_all"):setVisible(false)
			self.selectIds[self.selectId] = true
		end
	end

	for i=1,3 do
		local btn = Button:create(self.ui:getChildByName("btn_key_combine"..i))
		btn:addEventListener(Events.kStart, onSelect , i)
		btn.noTouchEffect = true
		self.ui:getChildByName("btn_key_combine"..i):getChildByName("txt_key1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_batchTxt"..i))
		self.ui:getChildByName("btn_key_combine"..i):getChildByName("icon_m_check1"):getChildByName("btn_selected_all"):setVisible(false)
		self.ui:getChildByName("btn_key_combine"..i):getChildByName("icon_m_check1"):getChildByName("btn_not_selected_all"):setVisible(true)
			
		-- self.ui:getChildByName("txt_key"..i):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_batchTxt"..i))
		-- self.ui:getChildByName("icon_m_check"..i):getChildByName("btn_selected_all"):setVisible(false)
		-- self.ui:getChildByName("icon_m_check"..i):getChildByName("btn_not_selected_all"):setVisible(true)
	end

	local function onConform( evt )
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	    self.container:setTableViewsEnabled(true)
	    self.container:batchSelectSpirits(self.selectIds)
	end

	local comformBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain4"))
	comformBtn:addEventListener(Events.kStart, onConform)

	self.ui:getChildByName("formation_btn_change_captain4"):getChildByName("txt"):setString(getTextByKey("yes"))
end
