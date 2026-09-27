require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

AccountEmailChangePanel = class(Layer)

function AccountEmailChangePanel:ctor()
	self.callback = nil
end

function AccountEmailChangePanel:create(callback)
	local s = AccountEmailChangePanel.new()
	s:initLayer( callback)
	return s
end

function AccountEmailChangePanel:initLayer( callback)
	AccountEmailChangePanel.super.initLayer(self)

	self.callback = callback

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("login_modify_bindingEmail")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)
	
	self.panelUI:getChildByName("txt_login_long"):getChildByName("txt"):setString(getTextByKey("login_mail_old1"))
	self.panelUI:getChildByName("txt_login_long2"):getChildByName("txt"):setString(getTextByKey("login_mail_new1"))
	
		
	local scale9SpriteRes = "pic/empty.png"
	local pos = self.panelUI:getChildByName("other2_gray9_panel"):getPosition()
	local size = self.panelUI:getChildByName("other2_gray9_panel"):getContentSize()
	local scale9 = Scale9Sprite:create(scale9SpriteRes)
	
	local oldEmailBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	oldEmailBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(oldEmailBox)
	oldEmailBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	oldEmailBox:setPlaceHolder(getTextByKey("login_mail_old"))

	pos = self.panelUI:getChildByName("other2_gray9_panel2"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel2"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local newEmailBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	newEmailBox:setReturnType(kKeyboardReturnTypeDone)
	newEmailBox:setPlaceHolder(getTextByKey("login_mail_new"))
	self:addChild(newEmailBox)
	newEmailBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))

	local function onErrorConfirmed()
		oldEmailBox:setEnabled(true)
		newEmailBox:setEnabled(true)
	end

	local function showErrorBox(key)
		oldEmailBox:setEnabled(false)
		newEmailBox:setEnabled(false)

		showLoginErrorBox(key, onErrorConfirmed)
	end
	
	local function onOkBtnClicked()		
		local oldEmail = oldEmailBox:getText()
		local newEmail = newEmailBox:getText()

		if oldEmail == "" then
			showErrorBox(getTextByKey("login_mail_error7"))
			return
		end
		if newEmail == "" then
			showErrorBox(getTextByKey("login_mail_error8"))
			return
		end
		
		if oldEmail == newEmail then
			showErrorBox(getTextByKey("login_mail_error9"))
			return
		end
		
		local oldEmailFormat = checkEmailFormat(oldEmail)
		if oldEmailFormat ~= 1 then
			showErrorBox(getTextByKey("login_mail_error5"))
			return
		end
		
		local newEmailFormat = checkEmailFormat(newEmail)
		if newEmailFormat ~= 1 then
			showErrorBox(getTextByKey("login_mail_error6"))
			return
		end
		
		local function makeSureChangeEmail()
			setOldEmail(oldEmail)
			setNewEmail(newEmail)
			if self.callback then
				self.callback()
			end
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		end
		
		local function noSureChangeEmail()
			oldEmailBox:setEnabled(true)
			newEmailBox:setEnabled(true)
		end
		
		oldEmailBox:setEnabled(false)
		newEmailBox:setEnabled(false)
		local loginPanel = AccountEmailMakeSurePanel:create(newEmail,makeSureChangeEmail,noSureChangeEmail)
		PopoutManager:sharedManager():popout(loginPanel , kPopoutDir.kScale, true, false ,self)
	end

	local okBtnNode = self.panelUI:getChildByName("btn_reg_in")
	okBtnNode:getChildByName("txt"):setString(getTextByKey("login_mail_new2"))
	local okBtn = Button:create(okBtnNode)
	okBtn:addEventListener( Events.kStart, onOkBtnClicked, self )

	local function onCloseClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end

	local closeBtnNode = self.panelUI:getChildByName("btn_close")
	local closeBtn = Button:create(closeBtnNode)
	closeBtn:addEventListener( Events.kStart, onCloseClicked, self )
end