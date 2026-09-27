--
-- UnionChangeDeclarationPopPanel.lua
-- Author: zheng.che
-- Date: 2014-03-28 19:10:11
-- 改宣言窗口
--
require "canon.request.UnionCreateRequest"

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
	if UnionManager.canChangeDeclaration(selectedText, true) then
		local function onSucceed(declarationMsg, requestEvent)
			UnionChangeDeclarationRequest.onSucceedDefault(declarationMsg, requestEvent)

			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end
		UnionChangeDeclarationRequest.sendRequest(selectedText, onSucceed, UnionChangeDeclarationRequest.onFailedDefault)
	end
end

--点击取消
local function onCancelClick(evt)
	--print("onCancelClick")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionChangeDeclarationPopPanel = class(Layer)

function UnionChangeDeclarationPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionChangeDeclarationPopPanel:create( container )
	local s = UnionChangeDeclarationPopPanel.new()
	s:initLayer(container)
	return s
end

function UnionChangeDeclarationPopPanel:initLayer(container)
	UnionChangeDeclarationPopPanel.super.initLayer(self)
    
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_announcement") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_announcement_title"):getChildByName("txt"):setString(Localization:getInstance():getText("union_declaration_text_key"))--军团宣言
	self.panelUI:getChildByName("txt_vip_chat"):getChildByName("txt"):setString(Localization:getInstance():getText("union_declaration_max_remind"))--最多输入20个汉字

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("btn_sure"))
	self.panelUI:getChildByName("btn_sure"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	local cancelButton = Button:create(self.panelUI:getChildByName("btn_cancel"))
	self.panelUI:getChildByName("btn_cancel"):getChildByName("txt"):setString(Localization:getInstance():getText("cancel"))--取消
	cancelButton:addEventListener(Events.kStart,onCancelClick, self)
	
	--初始化数据

	--输入文本
	local function onTextInputEvent( evt )
		local selectedText = self.editInputLabel:getText() 
		--print("selectedText = " .. selectedText)
		if selectedText == "" then
			self.panelUI:getChildByName("txt_guild_announcement"):getChildByName("txt"):setString(Localization:getInstance():getText("union_declaration_input_default"))--点击此处输入宣言
		else
			self.panelUI:getChildByName("txt_guild_announcement"):getChildByName("txt"):setString(selectedText)
		end
	end
	local inputBackground = self.panelUI:getChildByName("alpha_white9_panelin3")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 460, height = 231}
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
	if __IOS then
		self.editInputLabel:setPlaceHolder(getTextByKey("union_declaration_input_default"))--默认文字是ios才需要显示的内容
		self.panelUI:getChildByName("txt_guild_announcement"):getChildByName("txt"):setVisible(false)
	end
	self.panelUI:addChild(self.editInputLabel)
	self.panelUI:getChildByName("txt_guild_announcement"):setZOrder(1001)
	self.panelUI:getChildByName("txt_guild_announcement"):getChildByName("txt"):setString(Localization:getInstance():getText("union_declaration_input_default"))--点击此处输入宣言
	self.panelUI:getChildByName("txt_guild_announcement"):setPosition(ccp(self.panelUI:getChildByName("txt_guild_announcement"):getPositionX(), self.panelUI:getChildByName("txt_guild_announcement"):getPositionY() - 24))

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function UnionChangeDeclarationPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionChangeDeclarationPopPanel.super.dispose(self)
end

function UnionChangeDeclarationPopPanel:setTableViewsEnabled(v)
	self.editInputLabel:setEnabled(v)
end