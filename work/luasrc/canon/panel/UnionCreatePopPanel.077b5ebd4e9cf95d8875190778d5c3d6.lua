--
-- UnionCreatePopPanel.lua
-- Author: zheng.che
-- Date: 2014-03-13 15:32:32
-- 创建军团面板
--
require "canon.request.UnionCreateRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local selectedText = ""

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionCreatePopPanel = class(Layer)

function UnionCreatePopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionCreatePopPanel:create( container )
	local s = UnionCreatePopPanel.new()
	s:initLayer(container)
	return s
end

function UnionCreatePopPanel:initLayer(container)
	UnionCreatePopPanel.super.initLayer(self)

	--创建成功
	function onCreateSuccess(costType, unionName, event)
		--print("军团创建成功! event = " .. table.tostring(event))
		UnionCreateRequest.onSucceedDefault(costType, unionName, event)
		--self:dismiss()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end

	--点击关闭
	local function onClose(evt)
		--print("onClose")--testPrint
		--self:dismiss()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	--点击金币创建
	local function onGoldCreate(evt)
		--print("onGoldCreate")--testPrint
		if UnionManager.canCreateUnion(selectedText, ResourceEnum.GEMS, true) then
			--发送指令
			UnionCreateRequest.sendRequest(ResourceEnum.GEMS, selectedText, onCreateSuccess, UnionCreateRequest.onFailedDefault)
		end
	end
	--点击银币创建
	local function onSilverCreate(evt)
		--print("onSilverCreate")--testPrint
		if UnionManager.canCreateUnion(selectedText, ResourceEnum.COIN, true) then
			--发送指令
			UnionCreateRequest.sendRequest(ResourceEnum.COIN, selectedText, onCreateSuccess, UnionCreateRequest.onFailedDefault)
		end
	end
    
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_create_guild") 

	self:addChild(self.panelUI)

	self.panelUI:getChildByName("login_bg_guide_win").touchEnabled = false
	--固定文字
	self.panelUI:getChildByName("txt_createguild"):getChildByName("txt"):setString(Localization:getInstance():getText("union_creat_button"))--创建军团
	self.panelUI:getChildByName("btn_goldcreate"):getChildByName("txt"):setString(Localization:getInstance():getText("union_creat_button_by_gem"))--金币创建
	self.panelUI:getChildByName("btn_slivercreate"):getChildByName("txt"):setString(Localization:getInstance():getText("union_creat_button_by_coin"))--银币创建
	self.panelUI:getChildByName("txt_guild6"):getChildByName("txt"):setString(UnionManager.getCreateCostNum(ResourceEnum.GEMS))--$所需金币数量
	self.panelUI:getChildByName("txt_guild6_1"):getChildByName("txt"):setString(UnionManager.getCreateCostNum(ResourceEnum.COIN))--$所需银币数量

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local goldButton = Button:create(self.panelUI:getChildByName("btn_goldcreate"))
	goldButton:addEventListener(Events.kStart,onGoldCreate, self)

	local silverButton = Button:create(self.panelUI:getChildByName("btn_slivercreate"))
	silverButton:addEventListener(Events.kStart,onSilverCreate, self)

	--描边
	local infoLabelFlash = self.panelUI:getChildByName("txt_create_guild_info"):getChildByName("txt")
	infoLabelFlash:setString(getTextByKey("union_creat_remind"))
	infoLabelFlash:setColor(ccc3(255, 255, 110))
	infoLabelFlash:setAroundColor(ccc3(50, 10, 10))

	--初始化数据
	selectedText = ""

	--输入文本
	local function onTextInputEvent( evt )
		selectedText = self.editInputLabel:getText() 
		--print("selectedText = " .. selectedText)
		if selectedText == "" then
			self.panelUI:getChildByName("txt_guild7"):getChildByName("txt"):setString(Localization:getInstance():getText("union_creat_name_input_default"))--输入6位以内的名称
		else
			self.panelUI:getChildByName("txt_guild7"):getChildByName("txt"):setString(selectedText)
		end
	end
	local inputBackground = self.panelUI:getChildByName("bg_guild_name")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 327, height = 49}
	local inputPos = inputBackground:getPosition()
	local inputSprite = Scale9Sprite:create("common/button.png")
	inputSprite:setAnchorPoint(ccp(0, 1))
	inputSprite:setOpacity(0)--隐藏九宫格
	self.editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height), inputSprite)
	self.editInputLabel:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
	self.editInputLabel.refCocosObj:setInputFlag( -100 ) -- 隐藏
	self.editInputLabel:setReturnType(kKeyboardReturnTypeDone)
	self.editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	
	if __IOS then
		self.editInputLabel:setPlaceHolder(getTextByKey("union_creat_name_input_default"))
		self.panelUI:getChildByName("txt_guild7"):getChildByName("txt"):setVisible(false)
	end

	self.panelUI:addChild(self.editInputLabel)
	self.panelUI:getChildByName("txt_guild7"):setZOrder(1001)
	self.panelUI:getChildByName("txt_guild7"):getChildByName("txt"):setString(Localization:getInstance():getText("union_creat_name_input_default"))--输入6位以内的名称

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function UnionCreatePopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionCreatePopPanel.super.dispose(self)
end

function UnionCreatePopPanel:setTableViewsEnabled(v)
	self.editInputLabel:setEnabled(v)
end