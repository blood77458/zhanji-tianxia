require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

AccountEmailMakeSurePanel = class(Layer)

function AccountEmailMakeSurePanel:ctor()
	self.yesCallback = nil
	self.noCallback = nil
	self.email = ""
end

function AccountEmailMakeSurePanel:create(email,yesCallback, noCallback)
	local s = AccountEmailMakeSurePanel.new()
	s:initLayer(email, yesCallback, noCallback)
	return s
end

function AccountEmailMakeSurePanel:initLayer(email, yesCallback, noCallback)
	AccountEmailMakeSurePanel.super.initLayer(self)

	self.yesCallback = yesCallback
	self.noCallback = noCallback
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("popup_bindingEmail_prompt")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("login_mail_binding"))
	self.panelUI:getChildByName("txt_02"):getChildByName("txt"):setString(email)
	self.panelUI:getChildByName("txt_03"):getChildByName("txt"):setString(getTextByKey("login_mail_binding1"))
	
	local function onMakeSureBtnClicked()
		if self.yesCallback then
			self.yesCallback()
		end
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end
	local yesBtnNode = self.panelUI:getChildByName("btn_cancel")
	yesBtnNode:getChildByName("txt"):setString(getTextByKey("yes"))
	local yesBtn = Button:create(yesBtnNode)
	yesBtn:addEventListener( Events.kStart, onMakeSureBtnClicked, self )

	local function onCloseClicked()
		if self.noCallback then
			self.noCallback()
		end
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end

	local noBtnNode = self.panelUI:getChildByName("btn_determine")
	noBtnNode:getChildByName("txt"):setString(getTextByKey("cancel"))
	local noBtn = Button:create(noBtnNode)
	noBtn:addEventListener( Events.kStart, onCloseClicked, self )
end