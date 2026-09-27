require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ModifyPasswordPanel = class(Layer)

function ModifyPasswordPanel:ctor()
	self.callback = nil
end

function ModifyPasswordPanel:create(account, onModifySucceed, onModifyClosed)
	local s = ModifyPasswordPanel.new()
	s:initLayer(account, onModifySucceed, onModifyClosed)
	return s
end

function ModifyPasswordPanel:initLayer(account, onModifySucceed, onModifyClosed)
	ModifyPasswordPanel.super.initLayer(self)

	self.callback = onModifySucceed

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("login_modify_password")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_login_long"):getChildByName("txt"):setString(getTextByKey("login_account_num"))
	self.panelUI:getChildByName("txt_login_long2"):getChildByName("txt"):setString(getTextByKey("login_password_old"))
	self.panelUI:getChildByName("txt_login_long3"):getChildByName("txt"):setString(getTextByKey("login_password_new"))
	self.panelUI:getChildByName("txt_login_long4"):getChildByName("txt"):setString(getTextByKey("login_password_new2"))

	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)

	local scale9SpriteRes = UI_RES_PATH.."/login_new/other2_gray9_panel.png"

	local pos = self.panelUI:getChildByName("other2_gray9_panel"):getPosition()
	local size = self.panelUI:getChildByName("other2_gray9_panel"):getContentSize()
	local scale9 = Scale9Sprite:create(scale9SpriteRes)
	local newAccountBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	newAccountBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(newAccountBox)
	newAccountBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	newAccountBox:setText(account)
	newAccountBox:setPlaceHolder(getTextByKey("login_account_num2"))

	pos = self.panelUI:getChildByName("other2_gray9_panel2"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel2"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local passwordBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	passwordBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(passwordBox)
	passwordBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	passwordBox:setPlaceHolder(getTextByKey("login_password_putold"))
	passwordBox:setInputFlag(kEditBoxInputFlagPassword)
	secureTextInput(passwordBox)

	pos = self.panelUI:getChildByName("other2_gray9_panel3"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel3"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local newPasswordBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	newPasswordBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(newPasswordBox)
	newPasswordBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	newPasswordBox:setPlaceHolder(getTextByKey("login_password_putnew"))
	newPasswordBox:setInputFlag(kEditBoxInputFlagPassword)
	secureTextInput(newPasswordBox)

	pos = self.panelUI:getChildByName("other2_gray9_panel4"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel4"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local passwordConfirmBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	passwordConfirmBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(passwordConfirmBox)
	passwordConfirmBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	passwordConfirmBox:setPlaceHolder(getTextByKey("login_password_putnew2"))
	passwordConfirmBox:setInputFlag(kEditBoxInputFlagPassword)
	secureTextInput(passwordConfirmBox)

	local function onErrorConfirmed()
		newAccountBox:setEnabled(true)
		passwordBox:setEnabled(true)
		newPasswordBox:setEnabled(true)
		passwordConfirmBox:setEnabled(true)
	end

	local function showErrorBox(key)
		newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)
		newPasswordBox:setEnabled(false)
		passwordConfirmBox:setEnabled(false)

		showLoginErrorBox(key, onErrorConfirmed)
	end

	local function onModifyClicked()
		local account = newAccountBox:getText()
		if checkUsernameFormat(account) ~= 1 then
			showErrorBox(getTextByKey("login_wrong_register1"))
			return
		end
		local oldPassword = passwordBox:getText()
		if checkPasswordFormat(oldPassword) ~= 1 then
			showErrorBox(getTextByKey("login_wrong_password1"))
			return
		end
		local newPassword = newPasswordBox:getText()
		local newPasswordConfirm = passwordConfirmBox:getText()
		local passwordFormat = checkPasswordAndConfirm(newPassword, newPasswordConfirm)
		if passwordFormat == -1 then
			showErrorBox(getTextByKey("login_wrong_password1"))
			return
		elseif passwordFormat == -2 then
			showErrorBox(getTextByKey("login_wrong_password2"))
			return
		end

		local url = DataManager.SystemConfig.ModifyPasswordUrl

		local params = {}
		params.account = account
		params.oldPassword = HeMathUtils:md5(oldPassword)
		params.newPassword = HeMathUtils:md5(newPassword)
		params.seconds = TimeUtil.getServerTimeSeconds()
		params.sk = HeMathUtils:md5(account..params.oldPassword..params.newPassword..params.seconds)

		local function showNetErrorBox(errorId)
			local key = ""
			if errorId == -4 then
				key = getTextByKey("login_wrong_none")
			elseif errorId == -5 then
				key = getTextByKey("login_wrong_password")
			elseif errorId == -6 then
				key = getTextByKey("login_wrong_register3")
			else
				key = getTextByKey("popup_networkError")
			end
			showErrorBox(key)
		end

		local function getModifyResponse( response )
			if response.httpCode ~= 200 then
				showNetErrorBox()
				return
			end
			local rTable = table.deserialize(response.body)

			if rTable.code ~= 1 then
				showNetErrorBox(rTable.code)
			else
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
				self.callback(account, newPassword)
			end
		end

		doHttpRequest(url, params, getModifyResponse, true, true)
	end

	local modifyBtnNode = self.panelUI:getChildByName("btn_reg_in")
	modifyBtnNode:getChildByName("txt"):setString(getTextByKey("login_password_title"))
	local modifyBtn = Button:create(modifyBtnNode)
	modifyBtn:addEventListener( Events.kStart, onModifyClicked, self )

	local function onCloseClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		onModifyClosed()
	end

	local closeBtnNode = self.panelUI:getChildByName("btn_close")
	local closeBtn = Button:create(closeBtnNode)
	closeBtn:addEventListener( Events.kStart, onCloseClicked, self )
end