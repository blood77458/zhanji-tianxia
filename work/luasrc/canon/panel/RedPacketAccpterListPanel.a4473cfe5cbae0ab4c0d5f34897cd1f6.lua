require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

RedPacketAccpterListPanel = class(Layer)

local scroll_width = 577
local scroll_height = 349--420
local scroll_posX = 95
local scroll_posY = 500--430
local scroll_startPosY = 349--410

local card_scale = 0.75
local first_position_x = 80
local card_height = 108

function RedPacketAccpterListPanel:ctor()
	self.container = nil
end

function RedPacketAccpterListPanel:create( container  , argvs)
	local s = RedPacketAccpterListPanel.new()
	s.argvs = argvs
	s.container = container
	s:initLayer()
	return s
end

function RedPacketAccpterListPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	RedPacketAccpterListPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_redEnvelope")

	local aStringList = {}
	for k,v in pairs(self.argvs.accepterList) do
		local str
		if v.acceptErrorcode == 1 then
			str = v.acceptName .. getTextByKey("redBag009")
		elseif v.acceptErrorcode == 2 then
			str = v.acceptName .. getTextByKey("redBag010")
		elseif v.acceptErrorcode == 3 then
			str = v.acceptName..getTextByKey("redBag006")
		elseif v.acceptErrorcode == 4 then
			str = v.acceptName..getTextByKey("redBag007")
		elseif v.acceptErrorcode == 5 then
			local num = string.split(v.extend , "|")
			str = getTextByKey("redBag008" , {name = v.acceptName , number1 = num[2] , numer2 = num[2] - num[1] , name1 = v.acceptName})
		elseif v.acceptErrorcode == 6 then
			str = v.acceptName..getTextByKey("redBag011")
		end
		table.insert(aStringList , str)
	end

	local aStartPosY = scroll_startPosY
    -- local aStringList = self.contentList.content1:split("\\n")
    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.panelUI:addChildAt(aScrollView, 6)
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(255,255,255))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end

    aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))

		-- 关闭Panel事件
	local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		-- self:dismissSelf()
		if type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
	end

    local closeLayerBtn = Button:create(self.panelUI:getChildByName("common_btn_center"))
    closeLayerBtn:addEventListener(Events.kStart, onClosePanel )

    self.panelUI:getChildByName("common_btn_center"):getChildByName("txt_center"):setString(getTextByKey("yes"))
    self.panelUI:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("redBag014"))
	
	self:addChild(self.panelUI)
end
