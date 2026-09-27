-- PhoneChargeGainPopPanel.lua
-- 2014-7-10
-- zheng.che
-- 获取话费

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

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
	--print("onClose")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击确定
local function onConfirmClick(evt)
	--print("onConfirmClick")
	local self = evt.context

	local scene = Director:mgr():run()
	scene.targetInfoPanel = PhoneChargeChangePhoneNumberPopPanel:create(scene, true)--确认后回到此画面
    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)

	onClose(evt)
end

--点击确定
local function onGainClick(evt)
	--print("onGainClick")
	local self = evt.context
	PhoneChargeGainRequest.sendRequestDefalut(Activity_PhoneChargeLayer.getBindPhoneNumber(), 1)--固定是1

	onClose(evt)
end
------------------------------------------------------------------------------------------------------

PhoneChargeGainPopPanel = class(Layer)

function PhoneChargeGainPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function PhoneChargeGainPopPanel:create( container )
	local s = PhoneChargeGainPopPanel.new()
	s:initLayer(container)
	return s
end

function PhoneChargeGainPopPanel:initLayer(container)
	PhoneChargeGainPopPanel.super.initLayer(self)
    
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_chr3")

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_pchr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_chargeSuccess_txt1", {num = Activity_PhoneChargeLayer.getPhoneMoneyLeft()}))--您已经获得了{num}元话费
	self.panelUI:getChildByName("txt_pchr"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_chargeSuccess_txt2"))--您的话费将被充入以下号码：
	self.panelUI:getChildByName("txt_pchr3"):getChildByName("txt"):setString(Activity_PhoneChargeLayer.getBindPhoneNumber())--[]

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("btn_chr1"))
	self.panelUI:getChildByName("btn_chr1"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_changeNumber"))--更改号码
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	local gainButton = Button:create(self.panelUI:getChildByName("btn_chr2"))
	self.panelUI:getChildByName("btn_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定
	gainButton:addEventListener(Events.kStart,onGainClick, self)
	
	--初始化数据

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function PhoneChargeGainPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	PhoneChargeGainPopPanel.super.dispose(self)
end

function PhoneChargeGainPopPanel:setTableViewsEnabled(v)
end