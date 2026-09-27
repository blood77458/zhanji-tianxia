--------------------------------------------------------------------------------
-- ConfigScene.lua - 设置界面
-- author: fangzhou.long & xiaojie.bai
-- date: 2013-10-08 21:00
--------------------------------------------------------------------------------
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.scene.CharacterSelectScene"
require "canon.panel.CanonMessageBox"
require "canon.luajava.CanonEnvInjector"
require "canon.data.MetaManager"
require "canon.data.DataManager"
require "canon.request.ExchangeGiftBagRequest"
require "canon.request.EmailChangeRequest"
require "canon.panel.AccountEmailMakeSurePanel"
require "canon.panel.AccountEmailChangePanel"

local EXCHANGE_CODE_LENGTH = 9
local EXCHANGE_CODE_LENGTH2 = 12

ConfigScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function ConfigScene:ctor()
	self.title = getTextByKey("option_title")
end

function ConfigScene:create()
  local s = ConfigScene.new()
  s:initScene()
  
  return s
end

function ConfigScene:passwordClick()
  self:replaceScene(MainMenuScene)
end

function ConfigScene:back()
  self:replaceScene(MainMenuScene)
end

local DataNumber2FuncEnum = {
	USERMANAGE = 1,
	MUSICCONTROL = 2,
	ANNOUNCEMENT = 3,
	HELP = 4,
	CONTACT = 5,
	TOUCHEFFECTCONTROL = 6,
}

function ConfigScene:saveDebug()
	--写入debug状态 下次进入游戏后开启debug模式
	local user_path = HeResPathUtils:getUserDataPath()
	local file = io.open(user_path.."/debug.txt","w")
	file:write("debug")
	file:close()
	
	local pos = self.mainUI:getPosition()
	self.mainUI:setPosition(ccp(pos.x - 200, pos.y))

	--开启debug模式
	SystemManager.startDebug()
end

function ConfigScene:onInit()
	self.password = {}
	self.password[1] = "music"
	self.password[2] = "music"
	self.password[3] = "music"
	self.password[4] = "music"
	self.password[5] = "music"
	self.password[6] = "info"
	self.password[7] = "info"
	self.password[8] = "info"
	self.password[9] = "info"
	self.password[10] = "info"
	
	self.passwordIndex = 1
	self.passwordClick = function()
		print("******** password Click ***********" .. self.passwordIndex)
		if self.password[self.passwordIndex] == "info" then
			self.passwordIndex = self.passwordIndex + 1
		else
			self.passwordIndex = 1
		end
		
		if self.passwordIndex > 8 then
			self:saveDebug()
			self.passwordIndex = 1
		end
	end

	BaseUIScene.initBackGround(self)
	
	self.mainUI = Layer:create()
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/option_new.json")
	local aEntry = builder:build("option")
	local startPosition = aEntry:getPosition()
	self.mainUI:setPosition(ccp(startPosition.x, startPosition.y))
	
	local bg = builder:build("bg_inventorg")
	self.mainUI:addChild(bg)
	
	local counter = 60
	local counterInterval = 120
	local curAccountEmailStatus = getCurAccountEmailStatus()
	he_log_info("+++++++++++++++++++++++++++curAccountEmailStatus = " .. curAccountEmailStatus)
	if curAccountEmailStatus == CurAccountEmailStatus.BindedEmail or curAccountEmailStatus == CurAccountEmailStatus.NoBindEmail then
		counter = 95
		counterInterval = 105
	end
	local entryListData = {
		[DataNumber2FuncEnum.USERMANAGE] = {title = getTextByKey("option_userManagement"), button = getTextByKey("option_viewBtn"), entry = nil},
		[DataNumber2FuncEnum.MUSICCONTROL] = {title = getTextByKey("option_music"), button = getTextByKey("option_on"), entry = nil},
		[DataNumber2FuncEnum.ANNOUNCEMENT] = {title = getTextByKey("option_notice"), button = getTextByKey("option_viewBtn"), entry = nil},
		[DataNumber2FuncEnum.HELP] = {title = getTextByKey("option_help"), button = getTextByKey("option_viewBtn"), entry = nil},
		[DataNumber2FuncEnum.CONTACT] = {title = getTextByKey("option_contact"), button = getTextByKey("option_viewBtn"), entry = nil},
		[DataNumber2FuncEnum.TOUCHEFFECTCONTROL] = {title = getTextByKey("option_touchLight"), button = getTextByKey("option_off"), entry = nil},
	}
  
  local FLAG_MUSIC_DEFAULT = 0
  local FLAG_MUSIC_ON = 1
  local FLAG_MUSIC_OFF = 2
  local FLAG_TOUCHEFFECT_DEFAULT = 0
  local FLAG_TOUCHEFFECT_ON = 1
  local FLAG_TOUCHEFFECT_OFF = 2
  local KEY_OPTION_MUSIC = "music_option"
  local KEY_OPTION_TOUCHEFFECT = "toucheffect_option"
	local callbackFuncs = {
		[DataNumber2FuncEnum.USERMANAGE] = function ()
			self:replaceScene(CharacterSelectScene)
		end,
		[DataNumber2FuncEnum.MUSICCONTROL] = function ()
			local musicFlag = CCUserDefault:sharedUserDefault():getIntegerForKey(KEY_OPTION_MUSIC)
			if musicFlag == FLAG_MUSIC_DEFAULT or musicFlag == FLAG_MUSIC_ON then --not set or music on
				SimpleAudioEngine:sharedEngine():stopAllEffects()
				SimpleAudioEngine:sharedEngine():stopBackgroundMusic()
        
				CCUserDefault:sharedUserDefault():setIntegerForKey(KEY_OPTION_MUSIC, FLAG_MUSIC_OFF)
				self.musicBtnTxt:setString(getTextByKey("option_off"))
			elseif musicFlag == FLAG_MUSIC_OFF then --music off
				CCUserDefault:sharedUserDefault():setIntegerForKey("music_option", FLAG_MUSIC_ON)
				CanonPlayBackgroundMusic("music/background.mp3", true, true)
				self.musicBtnTxt:setString(getTextByKey("option_on"))
			end
			
			print("******** music Click ***********" .. self.passwordIndex)
			if self.password[self.passwordIndex] == "music" then
				self.passwordIndex = self.passwordIndex + 1
			else
				self.passwordIndex = 1
			end
			
			if self.passwordIndex > 8 then
				self:saveDebug()
				self.passwordIndex = 1
			end
			
		end,
		-- touch effect control
		[DataNumber2FuncEnum.TOUCHEFFECTCONTROL] = function ()
			local touchEffectFlag = CCUserDefault:sharedUserDefault():getIntegerForKey(KEY_OPTION_TOUCHEFFECT)
			if touchEffectFlag == FLAG_TOUCHEFFECT_DEFAULT or touchEffectFlag == FLAG_TOUCHEFFECT_OFF then --not set or toucheffect on
				CCUserDefault:sharedUserDefault():setIntegerForKey(KEY_OPTION_TOUCHEFFECT, FLAG_TOUCHEFFECT_ON)
				self.touchEffectBtnTxt:setString(getTextByKey("option_on"))
			elseif touchEffectFlag == FLAG_TOUCHEFFECT_ON then --toucheffect off
				CCUserDefault:sharedUserDefault():setIntegerForKey(KEY_OPTION_TOUCHEFFECT, FLAG_TOUCHEFFECT_OFF)
				self.touchEffectBtnTxt:setString(getTextByKey("option_off"))
			end
		end,
		--
		[DataNumber2FuncEnum.ANNOUNCEMENT] = function ()
			local announcementData = nil 
      
			local function getAnnouncementInfoFinish(responseData)
				announcementData = responseData.data.announcementItemMetas
				if announcementData and table.maxn(announcementData) > 0 then
					self.targetInfoPanel = AnnouncementPanel:create(self, announcementData, ShowPanelType.ShowAnnounce, nil)
					PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
				else
					CanonMessageBox.showText(ShowButtonType.ID_OK, getTextByKey("option_noNotice"))
				end
			end
      
			local params = {}
			local request = GetAnnouncementInfoRequest.new(params, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.GetAnnouncementInfoSucceed, getAnnouncementInfoFinish)
			request:start()       
		end,
    -- 帮助按钮
    [DataNumber2FuncEnum.HELP] = function ()
      helpData = MetaManager.getHelpInfo()
      if helpData then
        self.targetInfoPanel = AnnouncementPanel:create(self, helpData, ShowPanelType.ShowHelp, nil)
        PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
      end
    end,
		[DataNumber2FuncEnum.CONTACT] = function()
			if __ANDROID then
				CanonEnvInjector:callJira()
			elseif __IOS then
				PlatformMgr:getInstance():showJiraDialog()
			else
				local function gameInitResponse( e )
          DataManager.GameInitData = e.data
				end

				local gameInitRequest = GameInitRequest.new( nil ,rpc.SendingPriority.kNormal )
				gameInitRequest:addEventListener( RequestNotifyEnum.GameInitSucceed, gameInitResponse )
				gameInitRequest:start()
			end
		end,
	}

	local musicFlag = CCUserDefault:sharedUserDefault():getIntegerForKey(KEY_OPTION_MUSIC)
	local touchEffectFlag = CCUserDefault:sharedUserDefault():getIntegerForKey(KEY_OPTION_TOUCHEFFECT)
	for key, value in ipairs(entryListData) do
		local aEntry = builder:build("option")
		aEntry:setPosition(ccp(0, counter))
		counter = counter - counterInterval
		
		aEntry:getChildByName("txt_listname"):getChildByName("txt"):setString(value.title)
		aEntry:getChildByName("btn_option"):getChildByName("txt"):setString(value.button)
	
		if key == DataNumber2FuncEnum.MUSICCONTROL then 
			self.musicBtnTxt = aEntry:getChildByName("btn_option"):getChildByName("txt")
			if musicFlag == FLAG_MUSIC_DEFAULT or musicFlag == FLAG_MUSIC_ON then --not set or music on
				self.musicBtnTxt:setString(getTextByKey("option_on"))
			else
				self.musicBtnTxt:setString(getTextByKey("option_off"))
			end
		elseif key == DataNumber2FuncEnum.TOUCHEFFECTCONTROL then 
			self.touchEffectBtnTxt = aEntry:getChildByName("btn_option"):getChildByName("txt")
			if touchEffectFlag == FLAG_TOUCHEFFECT_DEFAULT or touchEffectFlag == FLAG_TOUCHEFFECT_OFF then --not set or toucheffect on
				self.touchEffectBtnTxt:setString(getTextByKey("option_off"))
			else
				self.touchEffectBtnTxt:setString(getTextByKey("option_on"))
			end
		end
		
		local btn = Button:create(aEntry:getChildByName("btn_option"))
		btn:addEventListener( Events.kStart, callbackFuncs[key], self )
		entryListData[key].entry = aEntry
		
		self.mainUI:addChild(aEntry)
	end
  
  -- 生成兑换UI
  self.optionCodeUI = builder:build("option_code")
  self.optionCodeUI:setPosition(ccp(0, counter))
  self.optionCodeUI:getChildByName("txt_listname"):getChildByName("txt"):setString(getTextByKey("option_presentExchangeTitle"))
  self.optionCodeUI:getChildByName("btn_option"):getChildByName("txt"):setString(getTextByKey("option_presentExchangeBtn"))
  
  --bind/change email ui
  counter = counter - counterInterval
  local function onClickChangeEmail(evt)
	-- 请求成功
	local function EmailChangeSuccess(responseData)
	  if curAccountEmailStatus == CurAccountEmailStatus.BindedEmail then
		SuspensionLabel:showContent(self, getTextByKey("login_mail_success1"))
	  elseif curAccountEmailStatus == CurAccountEmailStatus.NoBindEmail then
		SuspensionLabel:showContent(self, getTextByKey("login_mail_success"))
		self.emailUI:getChildByName("txt_listname"):setVisible(false)
		self.emailUI:getChildByName("option_inputEmail"):setVisible(false)
		self.txtEmailInput:setVisible(false)
		self.txtEmailInput:setEnabled(false)
		curAccountEmailStatus = CurAccountEmailStatus.BindedEmail
		setAccountHasBindEmail(true)
		self.emailUI:getChildByName("txt"):setVisible(true)
		self.emailUI:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("login_mail_mailbox4"))
		self.emailUI:getChildByName("btn_option"):getChildByName("txt"):setString(getTextByKey("login_mail_exchange"))
	  end
	  
	  self.btnChangeEmail:setEnable(true)
	end
	-- 请求失败
	local function EmailChangeFailed(evt)
	  local errorCode = tonumber(evt.data.retCode)
	  if 710060 == errorCode or 710069 == errorCode then
		CanonMessageBox:Show(getTextByKey("login_wrong_none"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
	  elseif 710095 == errorCode then
		CanonMessageBox:Show(getTextByKey("login_mail_error5"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
	  else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	  end
	  self.btnChangeEmail:setEnable(true)
	end
		
	local function sendChangeEmailRequest()
		-- 发送请求
		local oldEmail = ""
		local newEmail = ""
		local params = {}
		if curAccountEmailStatus == CurAccountEmailStatus.BindedEmail then
			oldEmail = getOldEmail()
			newEmail = getNewEmail()
			params = {oldEmail = oldEmail,newEmail = newEmail}
		elseif curAccountEmailStatus == CurAccountEmailStatus.NoBindEmail then
			newEmail = getNewEmail()--self.txtEmailInput:getText()
			params = {newEmail = newEmail}
		end
		self.btnChangeEmail:setEnable(false)
		
		local request = EmailChangeRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.EmailChangeSucceed, EmailChangeSuccess)
		request:addEventListener(RequestNotifyEnum.EmailChangeFailed, EmailChangeFailed)
		request:start()
	end
		
	if curAccountEmailStatus == CurAccountEmailStatus.BindedEmail then
		local aPanel = AccountEmailChangePanel:create(sendChangeEmailRequest)
		PopoutManager:sharedManager():popout(aPanel , kPopoutDir.kScale, true, false ,self)
	elseif curAccountEmailStatus == CurAccountEmailStatus.NoBindEmail then
		local email = self.txtEmailInput:getText()
		local emailFormat = checkEmailFormat(email)
		if email == "" then
			SuspensionLabel:showContent(self, getTextByKey("login_mail_error2"))
			return
		end
		if emailFormat ~= 1 then
			SuspensionLabel:showContent(self, getTextByKey("login_wrong_mail"))
			return
		end
		setNewEmail(email)
		local aPanel = AccountEmailMakeSurePanel:create(email,sendChangeEmailRequest)
		PopoutManager:sharedManager():popout(aPanel , kPopoutDir.kScale, true, false ,self) 
	end
	--
	
  end
  if curAccountEmailStatus == CurAccountEmailStatus.BindedEmail then
	self.emailUI = builder:build("option_emailAddress")
	self.emailUI:setPosition(ccp(0, counter))
	self.emailUI:getChildByName("txt_listname"):setVisible(false)
	self.emailUI:getChildByName("option_inputEmail"):setVisible(false)
	self.emailUI:getChildByName("btn_replace"):setVisible(false)
	self.emailUI:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("login_mail_mailbox4"))
	self.emailUI:getChildByName("btn_option"):getChildByName("txt"):setString(getTextByKey("login_mail_exchange"))
	self.btnChangeEmail = Button:create(self.emailUI:getChildByName("btn_option"))
	self.btnChangeEmail:addEventListener(Events.kStart, onClickChangeEmail, self)
	self.mainUI:addChild(self.emailUI)
  elseif curAccountEmailStatus == CurAccountEmailStatus.NoBindEmail then
	self.emailUI = builder:build("option_emailAddress")
	self.emailUI:setPosition(ccp(0, counter))
	self.emailUI:getChildByName("txt_listname"):getChildByName("txt"):setString(getTextByKey("login_mail_mailbox3"))
	self.emailUI:getChildByName("btn_replace"):setVisible(false)
	self.emailUI:getChildByName("txt"):setVisible(false)
	self.emailUI:getChildByName("btn_option"):getChildByName("txt"):setString(getTextByKey("yes"))
	self.btnChangeEmail = Button:create(self.emailUI:getChildByName("btn_option"))
	self.btnChangeEmail:addEventListener(Events.kStart, onClickChangeEmail, self)
	self.mainUI:addChild(self.emailUI)
	
	--
	-- 文本框修改
	local function onInputChanged() 
		local email = self.txtEmailInput:getText()
		self.newEmailTxt:setString(email)
	end

	self.newEmailTxt = self.emailUI:getChildByName("option_inputEmail"):getChildByName("txt"):getChildByName("txt")
	self.newEmailTxt:setString(getTextByKey("login_mail_mailbox2"))
	local txtCodeSize = self.emailUI:getChildByName("option_inputEmail"):getChildByName("option_txt_area"):getBounds().size
	local txtCodePos = self.emailUI:getChildByName("option_inputEmail"):getPosition()
	local codeUIPos = self.emailUI:getPosition()
	local inputSprite = Scale9Sprite:create("common/button.png")
	inputSprite:setAnchorPoint(ccp(0, 1))
	self.txtEmailInput = TextInput:create(CCSizeMake(txtCodeSize.width, txtCodeSize.height), inputSprite)
	self.txtEmailInput:setPosition(ccp(txtCodePos.x + txtCodeSize.width / 2, txtCodePos.y - txtCodeSize.height / 2))
	self.txtEmailInput.refCocosObj:setInputFlag(-100)
	self.txtEmailInput:addEventListener(kTextInputEvents.kChanged, onInputChanged)
	self.txtEmailInput:setReturnType(kKeyboardReturnTypeDone)
	self.emailUI:getChildByName("option_inputEmail"):setZOrder(1001)
	self.emailUI:getChildByName("option_inputEmail"):getChildByName("option_txt_area"):setVisible(false)
	if __IOS then
		self.txtEmailInput:setPosition(ccp(codeUIPos.x + txtCodePos.x + txtCodeSize.width / 2, codeUIPos.y + txtCodePos.y - txtCodeSize.height / 2))
		self.mainUI:addChildAt(self.txtEmailInput, 1005)
	else
		self.emailUI:addChild(self.txtEmailInput)
	end
  end
  
  -- 文本框修改时间
  local function onInputChanged() 
    local code = self.txtCodeInput:getText()
    self.txtCode:setString(code)
  end

  self.txtCode = self.optionCodeUI:getChildByName("option_inputcode"):getChildByName("txt_code"):getChildByName("txt")
  self.txtCode:setString("")
  local txtCodeSize = self.optionCodeUI:getChildByName("option_inputcode"):getChildByName("option_txt_area"):getBounds().size
  local txtCodePos = self.optionCodeUI:getChildByName("option_inputcode"):getPosition()
  local codeUIPos = self.optionCodeUI:getPosition()
  local inputSprite = Scale9Sprite:create("common/button.png")
  inputSprite:setAnchorPoint(ccp(0, 1))
  self.txtCodeInput = TextInput:create(CCSizeMake(txtCodeSize.width, txtCodeSize.height), inputSprite)
  self.txtCodeInput:setPosition(ccp(txtCodePos.x + txtCodeSize.width / 2, txtCodePos.y - txtCodeSize.height / 2))
  self.txtCodeInput.refCocosObj:setInputFlag(-100)
  self.txtCodeInput:addEventListener(kTextInputEvents.kChanged, onInputChanged)
  self.txtCodeInput:setReturnType(kKeyboardReturnTypeDone)
  self.optionCodeUI:getChildByName("option_inputcode"):setZOrder(1001)
  self.optionCodeUI:getChildByName("option_inputcode"):getChildByName("option_txt_area"):setVisible(false)
  if __IOS then
  	self.txtCodeInput:setPosition(ccp(codeUIPos.x + txtCodePos.x + txtCodeSize.width / 2, codeUIPos.y + txtCodePos.y - txtCodeSize.height / 2))
 	self.mainUI:addChildAt(self.txtCodeInput, 1005)
  else
  	self.optionCodeUI:addChild(self.txtCodeInput)
  end

  local function onClickExchange(evt) 
    -- 请求成功
    local function exchangeGiftBagFinish(responseData)
      SuspensionLabel:showContent(self, getTextByKey("option_presentExchangeSucceed"))
      RewardManager:getReward(responseData.data.rewards)
      DataManager.setExchangeGiftBagInfo(responseData.data.exchangeGiftBagInfo)
      self.txtCode:setString("")
      self.btnExchange:setEnable(true)
    end
    -- 请求失败
    local function exchangeGiftBagFailed(evt)
      local errorCode = tonumber(evt.data)
      if CommErrorCodes.EXCHANGE_GIFT_BAG_HAS_GET_REWARD.code == errorCode then
        SuspensionLabel:showContent(self, getTextByKey("option_presentExchangeDialog1"))
      elseif CommErrorCodes.EXCHANGE_GIFT_BAG_INVALID_ACTIVATION_CODE.code == errorCode or
        CommErrorCodes.EXCHANGE_GIFT_BAG_ACTIVATION_HAS_USED.code == errorCode or
        CommErrorCodes.EXCHANGE_GIFT_BAG_ACTIVATION_CODE_NOT_EXIST.code == errorCode or
        CommErrorCodes.ACTIVATION_CODE_META_NOT_CONFIGED.code == errorCode or
        CommErrorCodes.ACTIVATION_CODE_ITEM_NOT_CONFIGED.code == errorCode then
        SuspensionLabel:showContent(self, getTextByKey("option_presentExchangeDialog2"))
      elseif CommErrorCodes.EXCHANGE_GIFT_BAG_NOT_IN_ACTIVITY_TIME.code == errorCode then
        SuspensionLabel:showContent(self, getTextByKey("option_presentExchangeDialog3"))
      end
      self.btnExchange:setEnable(true)
    end
    
    local code = self.txtCodeInput:getText()
    -- 检验兑换码是否合法
    if (not code) or code == "" or (string.len(code) ~= EXCHANGE_CODE_LENGTH and string.len(code) ~= EXCHANGE_CODE_LENGTH2) then
      SuspensionLabel:showContent(self, getTextByKey("option_presentExchangeDialog2"))
      return
    end
    
    -- 发送请求
    self.btnExchange:setEnable(false)
    local params = {activationCode = self.txtCodeInput:getText()}
    local request = ExchangeGiftBagRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.ExchangeGiftBagSucceed, exchangeGiftBagFinish)
    request:addEventListener(RequestNotifyEnum.ExchangeGiftBagFailed, exchangeGiftBagFailed)
    request:start()
  end
  
  -- 生成兑换按钮
  self.btnExchange = Button:create(self.optionCodeUI:getChildByName("btn_option"))
  self.btnExchange:addEventListener(Events.kStart, onClickExchange, self)
  self.mainUI:addChild(self.optionCodeUI)
	
  if __IOS then
  	if isInAppleReview() then
  		self.optionCodeUI:setVisible(false)
  		self.txtCodeInput:removeFromParentAndCleanup(true)
  	end
  end
  --设置界面不显示鱼的推广码
  --[[
  if __IOS or __MAC then
	  local gameInitData = DataManager.getGameInitData()
	  if gameInitData.fishInviteCode ~= nil then
		local HostingCode = ArtLabelTTF:create(getTextByKey("invitationCode") .. ": " .. gameInitData.fishInviteCode,true)
		HostingCode:setSize(30)
		HostingCode:construct()
		HostingCode:setPosition(ccp(visibleSize.width/2,950))
		self.mainUI:addChild(CocosObject.new(HostingCode))
	  end
  end 
  --]]

	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
end

function ConfigScene:dispose()
  ConfigScene.super.dispose(self)
end

function ConfigScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ConfigScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function ConfigScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() + visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function ConfigScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function ConfigScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ConfigScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function ConfigScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function ConfigScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end
