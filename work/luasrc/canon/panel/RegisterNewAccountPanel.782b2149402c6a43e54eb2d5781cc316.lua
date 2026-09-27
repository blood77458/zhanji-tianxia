require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

RegisterNewAccountPanel = class(Layer)

function RegisterNewAccountPanel:ctor()
	self.callback = nil
end

function RegisterNewAccountPanel:create(onRegisterSucceed, onRegisterClosed)
	local s = RegisterNewAccountPanel.new()
	s:initLayer(onRegisterSucceed, onRegisterClosed)
	return s
end


function RegisterNewAccountPanel:initLayer(onRegisterSucceed, onRegisterClosed)
	RegisterNewAccountPanel.super.initLayer(self)

	self.callback = onRegisterSucceed

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("login_reg_account")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_login_long"):getChildByName("txt"):setString(getTextByKey("login_account_num"))
	self.panelUI:getChildByName("txt_login_long2"):getChildByName("txt"):setString(getTextByKey("login_account_password"))
	self.panelUI:getChildByName("txt_login_long3"):getChildByName("txt"):setString(getTextByKey("login_register_put"))
	self.panelUI:getChildByName("txt_login_long4"):getChildByName("txt"):setString(getTextByKey("login_register_email"))

	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)

	local scale9SpriteRes = UI_RES_PATH.."/login_new/other2_gray9_panel.png"

	local pos = self.panelUI:getChildByName("other2_gray9_panel"):getPosition()
	local size = self.panelUI:getChildByName("other2_gray9_panel"):getContentSize()
	local scale9 = Scale9Sprite:create(scale9SpriteRes)
	local newAccountBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	newAccountBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(newAccountBox)
	newAccountBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	newAccountBox:setPlaceHolder(getTextByKey("login_account_num2"))

	pos = self.panelUI:getChildByName("other2_gray9_panel2"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel2"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local passwordBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	passwordBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(passwordBox)
	passwordBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	passwordBox:setPlaceHolder(getTextByKey("login_account_password2"))
	passwordBox:setInputFlag(kEditBoxInputFlagPassword)
	secureTextInput(passwordBox)

	pos = self.panelUI:getChildByName("other2_gray9_panel3"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel3"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local passwordConfirmBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	passwordConfirmBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(passwordConfirmBox)
	passwordConfirmBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	passwordConfirmBox:setPlaceHolder(getTextByKey("login_register_put2"))
	passwordConfirmBox:setInputFlag(kEditBoxInputFlagPassword)
	secureTextInput(passwordConfirmBox)

	pos = self.panelUI:getChildByName("other2_gray9_panel4"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel4"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local emailBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	emailBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(emailBox)
	emailBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	emailBox:setPlaceHolder(getTextByKey("login_register_email2"))

	local function onErrorConfirmed()
		newAccountBox:setEnabled(true)
		passwordBox:setEnabled(true)
		passwordConfirmBox:setEnabled(true)
		emailBox:setEnabled(true)
	end

	local function showErrorBox(key)
		newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)
		passwordConfirmBox:setEnabled(false)
		emailBox:setEnabled(false)

		showLoginErrorBox(key, onErrorConfirmed)
	end


	local function onRegisterClicked()
		local account = newAccountBox:getText()
		local password = passwordBox:getText()
		local passwordConfirm = passwordConfirmBox:getText()
		local email = emailBox:getText()

		if account == "" or password == "" or passwordConfirm == "" then
			showErrorBox(getTextByKey("login_wrong_account3"))
			return
		end

		local accountFormat = checkUsernameFormat(account)
		if accountFormat ~= 1 then
			showErrorBox(getTextByKey("login_wrong_register1"))
			return
		end
		local passwordFormat = checkPasswordAndConfirm(password, passwordConfirm)
		if passwordFormat == -1 then
			showErrorBox(getTextByKey("login_wrong_password1"))
			return
		elseif passwordFormat == -2 then
			showErrorBox(getTextByKey("login_wrong_password2"))
			return
		end
		local emailFormat = checkEmailFormat(email)
		if emailFormat ~= 1 then
			showErrorBox(getTextByKey("login_wrong_mail"))
			return
		end

		local url = DataManager.SystemConfig.RegisterAccountUrl
		local requestParam = {}
		requestParam.account = account
		requestParam.password = HeMathUtils:md5(password)
		if email and email ~= "" then
			requestParam.email = email
		end

		local function showRegisterError( errorCode )
			if not errorCode then
				showErrorBox(getTextByKey("popup_networkError"))
			elseif errorCode == -5 then
				showErrorBox(getTextByKey("login_wrong_register"))
			end
		end

		local function onRegisterResponse( response )
			if response.httpCode ~= 200 then
				showRegisterError()
				return
			end
			if response.errorCode ~= 0 then
				showRegisterError()
				return
			end
			if not response.body or response.body == "" then
				showRegisterError()
				return
			end
			local returnCode = table.deserialize(response.body)
			if returnCode.code == 1 then
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
				self.callback(account, password)
			else
				showRegisterError(returnCode.code)
			end
		end

		doHttpRequest(url, requestParam, onRegisterResponse, true, true)
	end

	local registerBtnNode = self.panelUI:getChildByName("btn_reg_in")
	registerBtnNode:getChildByName("txt"):setString(getTextByKey("login_register_login"))
	local registerBtn = Button:create(registerBtnNode)
	registerBtn:addEventListener( Events.kStart, onRegisterClicked, self )

	local function onCloseClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		onRegisterClosed()
	end

	local closeBtnNode = self.panelUI:getChildByName("btn_close")
	local closeBtn = Button:create(closeBtnNode)
	closeBtn:addEventListener( Events.kStart, onCloseClicked, self )
end