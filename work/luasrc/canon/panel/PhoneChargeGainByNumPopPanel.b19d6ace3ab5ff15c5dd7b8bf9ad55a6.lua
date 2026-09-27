-- PhoneChargeGainByNumPopPanel.lua
-- 2014-7-10
-- zheng.che
-- 获取话费(通过设定手机号码)

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
	local selectedText = self.editInputLabel:getText() 
	if Activity_PhoneChargeLayer.isPhoneNumber(selectedText, true) then
		PhoneChargeGainRequest.sendRequestDefalut(selectedText, 1)--固定是1(全款)
		
		onClose(evt)
	end
end
------------------------------------------------------------------------------------------------------

PhoneChargeGainByNumPopPanel = class(Layer)

function PhoneChargeGainByNumPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function PhoneChargeGainByNumPopPanel:create( container )
	local s = PhoneChargeGainByNumPopPanel.new()
	s:initLayer(container)
	return s
end

function PhoneChargeGainByNumPopPanel:initLayer(container)
	PhoneChargeGainByNumPopPanel.super.initLayer(self)
    
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_chr2")

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_pchr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_chargeSuccess_txt1", {num = Activity_PhoneChargeLayer.getPhoneMoneyLeft()}))--您已经获得了{num}元话费
	self.panelUI:getChildByName("txt_pchr"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_chargeSuccess_title"))--请输入要充值的手机号码

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("btn_chr1"))
	self.panelUI:getChildByName("btn_chr1"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_popup_bindBtn"))--绑定
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)
	
	--初始化数据

	--输入文本
	local function onTextInputEvent( evt )
		local selectedText = self.editInputLabel:getText() 
		--print("selectedText = " .. selectedText)
		if selectedText == "" then
			self.panelUI:getChildByName("txt_telnum"):getChildByName("txt"):setString("")
		else
			self.panelUI:getChildByName("txt_telnum"):getChildByName("txt"):setString(selectedText)
		end
	end
	local inputBackground = self.panelUI:getChildByName("other2_gray9_panel2")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 420, height = 57}
	local inputPos = inputBackground:getPosition()
	local inputSprite = Scale9Sprite:create("common/button.png")
	inputSprite:setAnchorPoint(ccp(0, 1))
	inputSprite:setOpacity(0)--隐藏九宫格
	self.editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height), inputSprite)
	self.editInputLabel:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
	self.editInputLabel.refCocosObj:setInputFlag( -100 ) -- 隐藏
	self.editInputLabel:setReturnType(kKeyboardReturnTypeDone)
	self.editInputLabel:setText(UnionManager.getUnionDeclaration())--显示当前的宣言内容
	self.editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	self.editInputLabel:setPlaceHolder("")
	if __IOS then
		self.panelUI:getChildByName("txt_telnum"):getChildByName("txt"):setVisible(false)
	end
	self.panelUI:addChild(self.editInputLabel)
	self.panelUI:getChildByName("txt_telnum"):setZOrder(1001)
	self.panelUI:getChildByName("txt_telnum"):getChildByName("txt"):setString("")
	--self.panelUI:getChildByName("txt_telnum"):setPosition(ccp(self.panelUI:getChildByName("txt_telnum"):getPositionX(), self.panelUI:getChildByName("txt_telnum"):getPositionY()))

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function PhoneChargeGainByNumPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	PhoneChargeGainByNumPopPanel.super.dispose(self)
end

function PhoneChargeGainByNumPopPanel:setTableViewsEnabled(v)
	self.editInputLabel:setEnabled(v)
end