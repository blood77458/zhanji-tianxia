require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.AccountPasswordBackPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

AccountLoginPanel = class(Layer)

function AccountLoginPanel:ctor()
	self.callback = nil
	self.password = ""
end

function AccountLoginPanel:create(account, password, onLoginClick)
	local s = AccountLoginPanel.new()
	s:initLayer(account, password, onLoginClick)
	return s
end

function AccountLoginPanel:initLayer(account, password, onLoginClick)
	AccountLoginPanel.super.initLayer(self)

	self.callback = onLoginClick

	local card = Sprite:create("card/card/yuji_5/full.png")
	card:setScale(1.5)
	card:setPosition(ccp(300, 800))
	card.refCocosObj:setFlipX(true)

	self:addChild(card)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("new_login")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_login_short"):getChildByName("txt"):setString(getTextByKey("login_account_num"))
	self.panelUI:getChildByName("txt_login_short2"):getChildByName("txt"):setString(getTextByKey("login_account_password"))

	local scale9SpriteRes = "pic/empty.png"

	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)

	local pos = self.panelUI:getChildByName("other2_gray9_panel"):getPosition()
	local size = self.panelUI:getChildByName("other2_gray9_panel"):getContentSize()
	local scale9 = Scale9Sprite:create(scale9SpriteRes)
	local newAccountBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	newAccountBox:setReturnType(kKeyboardReturnTypeDone)
	self:addChild(newAccountBox)
	newAccountBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	newAccountBox:setPlaceHolder(getTextByKey("login_account_num2"))
	newAccountBox:setMaxLength(15)

	pos = self.panelUI:getChildByName("other2_gray9_panel2"):getPosition()
	size = self.panelUI:getChildByName("other2_gray9_panel2"):getContentSize()
	scale9 = Scale9Sprite:create(scale9SpriteRes)
	local passwordBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	passwordBox:setReturnType(kKeyboardReturnTypeDone)
	passwordBox:setInputFlag(kEditBoxInputFlagPassword)
	passwordBox:setPlaceHolder(getTextByKey("login_account_password2"))
	self:addChild(passwordBox)
	passwordBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))
	passwordBox:setMaxLength(15)
	secureTextInput(passwordBox)

	if account then
		newAccountBox:setText(account)
	end
	if password then
		passwordBox:setText(password)
	end

	local function onErrorConfirmed()
		newAccountBox:setEnabled(true)
		passwordBox:setEnabled(true)
	end

	local function showErrorBox(key)
		newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)

		showLoginErrorBox(key, onErrorConfirmed)
	end

	local function onLoginClicked()		
		local account = newAccountBox:getText()
		local password = passwordBox:getText()

		if account == "" or password == "" then
			showErrorBox(getTextByKey("login_wrong_account3"))
			return
		end
		
		if checkUsernameFormat(account) == -1 then
			showErrorBox(getTextByKey("login_wrong_register1"))
			return
		end
		if checkPasswordFormat(password) ~= 1 then
			showErrorBox(getTextByKey("login_wrong_password1"))
			return
		end


		if checkAccountInTwinList(account) then
			showErrorBox(getTextByKey("login_same_text"))
			return
		end

		local function showNetErrorBox(errorId)
			local key = getTextByKey("popup_networkError")
			if errorId == -4 then
				key = getTextByKey("login_wrong_none")
			elseif errorId == -5 then
				key = getTextByKey("login_wrong_account")
			elseif errorId == -6 then
				key = getTextByKey("login_wrong_register3")
			end
			showErrorBox(key)
		end

		local function onAccountChecked( response )
			--local tstr = table.serialize(response)
        --he_log_info("+++++++++++++++++++++++++++login account Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
			if response.httpCode ~= 200 or response.errorCode ~= 0 then
				showNetErrorBox()
				return
			end
			if not response.body or response.body == "" then
				showNetErrorBox()
				return
			end
			local retCode = table.deserialize(response.body)
			if retCode.code == 1 then
				setAccountHasBindEmail(retCode.email)
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
				self.callback(retCode.token, account, password)
			else
				showNetErrorBox(retCode.code)
			end
		end

		checkAccount(account, HeMathUtils:md5(password), onAccountChecked)
	end

	local loginBtnNode = self.panelUI:getChildByName("but_determine")
	loginBtnNode:getChildByName("txt"):setString(getTextByKey("login_title1"))
	local loginBtn = Button:create(loginBtnNode)
	loginBtn:addEventListener( Events.kStart, onLoginClicked, self )

	local function onRegisterClicked()
		require "canon.panel.RegisterNewAccountPanel"

	    local function onRegisterSucceed(account, password)
			newAccountBox:setText(account)
			passwordBox:setText(password)

			onLoginClicked()
	    end

	    local function onRegisterClosed()
	    	newAccountBox:setEnabled(true)
			passwordBox:setEnabled(true)
	    end

	 	newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)   
	    local registerPanel = RegisterNewAccountPanel:create(onRegisterSucceed, onRegisterClosed)
	    PopoutManager:sharedManager():popout(registerPanel , kPopoutDir.kScale, true, false ,self)
	end

	local registerBtnNode = self.panelUI:getChildByName("btn_reg")
	registerBtnNode:getChildByName("txt"):setString(getTextByKey("login_register_title"))
	local registerBtn = Button:create(registerBtnNode)
	registerBtn:addEventListener( Events.kStart, onRegisterClicked, self )

	local function onModidyPasswordClicked( evt )
		require "canon.panel.ModifyPasswordPanel"

		local function onModifySucceed( account, password )
			newAccountBox:setText(account)
			passwordBox:setText(password)

			--onLoginClicked()
		end

		local function onModifyClosed()
	    	newAccountBox:setEnabled(true)
			passwordBox:setEnabled(true)
		end

		newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)
		local modifyPanel = ModifyPasswordPanel:create(account, onModifySucceed, onModifyClosed)
		PopoutManager:sharedManager():popout(modifyPanel , kPopoutDir.kScale, true, false ,self)
	end

	local modifyBtnNode = self.panelUI:getChildByName("btn_change_password")
	modifyBtnNode:getChildByName("txt"):setString(getTextByKey("login_password_title"))
	local modifyBtn = Button:create(modifyBtnNode)
	modifyBtn:addEventListener(Events.kStart, onModidyPasswordClicked, self)
	
	--密码找回
	local function onPasswordBackBtnClicked()
		local function onPassbackClosed()
	    	newAccountBox:setEnabled(true)
			passwordBox:setEnabled(true)
		end
		newAccountBox:setEnabled(false)
		passwordBox:setEnabled(false)
		local account = newAccountBox:getText()
		local loginPanel = AccountPasswordBackPanel:create(account,onPassbackClosed)
		PopoutManager:sharedManager():popout(loginPanel , kPopoutDir.kScale, true, false ,self) 
	end

	local passwordBackBtnNode = self.panelUI:getChildByName("but_determine2")
	passwordBackBtnNode:getChildByName("txt"):setString(getTextByKey("login_mail_password"))
	local passwordBackBtn = Button:create(passwordBackBtnNode)
	passwordBackBtn:addEventListener( Events.kStart, onPasswordBackBtnClicked, self )

	local function onCloseClicked()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end

	local closeBtnNode = self.panelUI:getChildByName("btn_close")
	local closeBtn = Button:create(closeBtnNode)
	closeBtn:addEventListener( Events.kStart, onCloseClicked, self )
end