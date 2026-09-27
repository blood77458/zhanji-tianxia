require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

AccountPasswordBackPanel = class(Layer)

function AccountPasswordBackPanel:ctor()
	self.callback = nil
	self.account = ""
end

function AccountPasswordBackPanel:create(account,callback)
	local s = AccountPasswordBackPanel.new()
	s:initLayer(account, callback)
	return s
end

function AccountPasswordBackPanel:initLayer(account, callback)
	AccountPasswordBackPanel.super.initLayer(self)

	self.callback = callback

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.panelUI = builder:build("password_back")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_info_txt1"):setVisible(false)
	self.panelUI:getChildByName("txt_info_txt2"):setVisible(false)
	self.panelUI:getChildByName("sky_btn_qa"):setVisible(false)
	self.panelUI:getChildByName("txt_login_short2"):setVisible(false)
	
	self.panelUI:getChildByName("txt_login_short"):getChildByName("txt"):setString(getTextByKey("login_account_num"))
	self.panelUI:getChildByName("txt_login_long"):getChildByName("txt"):setString(getTextByKey("login_mail_mailbox"))
	self.panelUI:getChildByName("txt_login_prompt_2"):getChildByName("txt"):setString(getTextByKey("login_mail_text"))
	
		
	local scale9SpriteRes = "pic/empty.png"
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
	local emailBox = TextInput:create(CCSizeMake(size.width, size.height), scale9)
	emailBox:setReturnType(kKeyboardReturnTypeDone)
	emailBox:setPlaceHolder(getTextByKey("login_mail_mailbox1"))
	self:addChild(emailBox)
	emailBox:setPosition(ccp(pos.x + size.width/2, pos.y - size.height/2))

	if account then
		newAccountBox:setText(account)
	end

	local function onErrorConfirmed()
		newAccountBox:setEnabled(true)
		emailBox:setEnabled(true)
	end

	local function showErrorBox(key)
		newAccountBox:setEnabled(false)
		emailBox:setEnabled(false)

		showLoginErrorBox(key, onErrorConfirmed)
	end
	
	local function onPassbackBtnClicked()		
		local account = newAccountBox:getText()
		local email = emailBox:getText()

		if account == "" then
			showErrorBox(getTextByKey("login_mail_error1"))
			return
		end
		if email == "" then
			showErrorBox(getTextByKey("login_mail_error2"))
			return
		end
		
		if checkUsernameFormat(account) == -1 then
			showErrorBox(getTextByKey("login_wrong_register1"))
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
			elseif errorId == -3 or errorId == -5 or errorId == -6 then
				key = getTextByKey("login_mail_error4")
			else

			end
			showErrorBox(key)
		end

		local function onResetPassword( response )
			--local tstr = table.serialize(response)
            --he_log_info("+++++++++++++++++++++++++++password to email Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
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
				CanonMessageBox.showText( ShowButtonType.ID_OK, getTextByKey("login_mail_text1"), nil, 
										{
									text = getTextByKey("yes"),
									callbackFunc = function()
										--PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
										newAccountBox:setEnabled(true)
										emailBox:setEnabled(true)
									end
								} ,nil)
			else
				showNetErrorBox(retCode.code)
			end
		end
		newAccountBox:setEnabled(false)
		emailBox:setEnabled(false)
		resetkPassword(account, email, onResetPassword)
	end

	local passbackBtnNode = self.panelUI:getChildByName("but_determine")
	passbackBtnNode:getChildByName("txt"):setString(getTextByKey("login_mail_password"))
	local passbackBtn = Button:create(passbackBtnNode)
	passbackBtn:addEventListener( Events.kStart, onPassbackBtnClicked, self )

	local function onCloseClicked()
		if self.callback then
			self.callback()
		end
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end

	local closeBtnNode = self.panelUI:getChildByName("btn_close")
	local closeBtn = Button:create(closeBtnNode)
	closeBtn:addEventListener( Events.kStart, onCloseClicked, self )
end