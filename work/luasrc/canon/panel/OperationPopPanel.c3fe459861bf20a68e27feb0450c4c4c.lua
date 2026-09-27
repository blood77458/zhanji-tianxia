--
-- OperationPopPanel.lua
-- Author: zheng.che
-- Date: 2014-03-24 10:03:23
-- 菜单选项窗口
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--按钮间距
local btnDistance = 0
--大背景最小高度
local bigBGMinHeight = 0
--小背景最小高度
local smallBGMinHeight = 0
--原始y坐标
local orginPanelY = 0
local orginCloudY = 0

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	--print("onClose")--testPrint
	--self:dismiss()
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

OperationPopPanel = class(Layer)

function OperationPopPanel:ctor()
	self.container = nil
	self.content = nil
	self.btns = {}
end

function OperationPopPanel:create( container, btnInfoList )
	local s = OperationPopPanel.new()
	s:initLayer(container, btnInfoList)
	return s
end

function OperationPopPanel:initLayer(container, btnInfoList)
	OperationPopPanel.super.initLayer(self)
    
	self.container = container
	self.btnInfoList = btnInfoList

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_list") 

	self:addChild(self.panelUI)

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)

	local btnDisplay1 = self.panelUI:getChildByName("btn_guild_option1")
	local btnDisplay2 = self.panelUI:getChildByName("btn_guild_option2")

	local y1 = btnDisplay1:getPositionY()
	local y2 = btnDisplay2:getPositionY()
	btnDistance = y1 - y2

	local bigBG = self.panelUI:getChildByName("Transparent_yellow_light9_pic")
	bigBGMinHeight = bigBG:getContentSize().height - btnDistance * 2

	local smallBG = self.panelUI:getChildByName("battleResult_new_red_bg9_pic")
	smallBGMinHeight = smallBG:getContentSize().height - btnDistance * 2

	orginPanelY = self.panelUI:getPositionY()
	orginCloudY = self.panelUI:getChildByName("frame_cloud"):getPositionY()
	--隐藏标记用按钮
	btnDisplay1:setVisible(false)
	btnDisplay2:setVisible(false)

	if self.btnInfoList then
		for k, v in ipairs(self.btnInfoList) do
			local tempBtnDisplay = builder:build("btn/btn_guild_option") 

			tempBtnDisplay:getChildByName("txt"):setString(v.text)

			--设置按钮位置
			tempBtnDisplay:setPositionX(btnDisplay1:getPositionX())
			tempBtnDisplay:setPositionY(btnDisplay1:getPositionY() - (k-1)*btnDistance)

			local tempBtn = CanonButton:create(tempBtnDisplay)
			tempBtn:addEventListener(Events.kStart, v.callback, v.context)
			tempBtn:addEventListener(Events.kStart, onClose, self)

			if v.disenabled then
				tempBtnDisplay:getChildByName("btn"):setVisible(false)
				tempBtn:setEnable(false)
			end

			self.panelUI:addChild(tempBtnDisplay)
			table.insert(self.btns, tempBtn)
		end
		self:refreshBackgroundByCount(#self.btnInfoList)
	end

end

function OperationPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	if self.btns then
		for k, v in ipairs(self.btns) do
			v:dispose()
		end
	end

	OperationPopPanel.super.dispose(self)
end

function OperationPopPanel:setTableViewsEnabled(v)
end

function OperationPopPanel:refreshBackgroundByCount(count)
	local btnTotalHeight = count * btnDistance

	local bigBG = self.panelUI:getChildByName("Transparent_yellow_light9_pic")
	
	bigBG:setContentSize(CCSize(bigBG:getContentSize().width, bigBGMinHeight + btnTotalHeight))

	local smallBG = self.panelUI:getChildByName("battleResult_new_red_bg9_pic")
	smallBG:setContentSize(CCSize(smallBG:getContentSize().width, smallBGMinHeight + btnTotalHeight))
	
	self.panelUI:getChildByName("frame_cloud"):setPositionY(orginCloudY - (count-2)*btnDistance)
	self.panelUI:setPositionY(orginPanelY + (count-2)*btnDistance/2)
end