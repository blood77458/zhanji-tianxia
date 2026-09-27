require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.models.PackageModel"
require "canon.customUI.CdLabelComponent"
require "canon.request.GainInviteRewardRequest"
require "canon.request.GainInvitedRewardRequest"
require "canon.request.GetInvitationInfoRequest"
require "canon.data.AccountPlatformLogin"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_InvitationCodeLayer = class(Layer)

function Activity_InvitationCodeLayer:ctor()
  self.container = nil
end

function Activity_InvitationCodeLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  local s = Activity_InvitationCodeLayer.new()
  s:initLayer()
  return s
end

function Activity_InvitationCodeLayer:enable(curTimeStamp)

    local isEnable = MaintenanceManager.isActivityOpen("activityInvitationCode")
    return isEnable
    -- return true
end 

function Activity_InvitationCodeLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_InvitationCodeLayer:dispose()

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end
	Activity_InvitationCodeLayer.super.dispose(self)
end

function Activity_InvitationCodeLayer:initLayer()
    Activity_InvitationCodeLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/invite_code.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("invite_code")
	self:addChild(self.mainUI)

	--初始化数据
	selectedText = ""

	--输入文本
	local function onTextInputEvent( evt )
		selectedText = self.editInputLabel:getText() 
		--print("selectedText = " .. selectedText)
		if selectedText == "" then
			self.mainUI:getChildByName("txt_invtecode1"):getChildByName("txt"):setString(Localization:getInstance():getText("invited_entranceSec"))--输入6位以内的名称
		else
			self.mainUI:getChildByName("txt_invtecode1"):getChildByName("txt"):setString(selectedText)
		end
		-- self.mainUI:getChildByName("txt_invtecode1"):getChildByName("txt"):setString(selectedText)
	end
	local inputBackground = self.mainUI:getChildByName("bg_guild_name")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 327, height = 49}
	local inputPos = inputBackground:getPosition()
	self.inputSprite = Scale9Sprite:create("common/button.png")
	self.inputSprite:setAnchorPoint(ccp(0, 1))
	self.inputSprite:setOpacity(0)
	self.editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height), self.inputSprite)
	self.editInputLabel:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
	self.editInputLabel.refCocosObj:setInputFlag( -100 ) -- 隐藏
	self.editInputLabel:setReturnType(kKeyboardReturnTypeDone)
	self.editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	
	if __IOS then
		self.editInputLabel:setPlaceHolder(Localization:getInstance():getText("invited_entranceSec"))
		self.mainUI:getChildByName("txt_invtecode1"):setVisible(false)
	end
	self.mainUI:addChild(self.editInputLabel)
	self.mainUI:getChildByName("txt_invtecode1"):setZOrder(1001)
	self.mainUI:getChildByName("txt_invtecode1"):getChildByName("txt"):setString(selectedText)--输入6位以内的名称

	self.mainUI:getChildByName("txt_invtecode6"):getChildByName("txt"):setString(getTextByKey("invitation_code"))
	self.mainUI:getChildByName("txt_invtecode7"):getChildByName("txt"):setString(getTextByKey("invitation_inviteNum1"))
	self.mainUI:getChildByName("txt_invtecode8"):getChildByName("txt"):setString(getTextByKey("invitation_inviteNum2"))
	-- self.mainUI:getChildByName("btn_the_receive"):getChildByName("txt"):setString(getTextByKey("skyTower_rewardBtn"))
	local infoLabelFlash10 = self.mainUI:getChildByName("btn_the_receive"):getChildByName("txt")
	infoLabelFlash10:setString(getTextByKey("skyTower_rewardBtn"))
	infoLabelFlash10:setColor(ccc3(255,255,255))
	infoLabelFlash10:setAroundColor(ccc3(0, 0, 0))
	self.mainUI:getChildByName("btn_submit"):getChildByName("txt"):setString(getTextByKey("invited_entranceBtn"))
	self.mainUI:getChildByName("txt_invitecode2"):getChildByName("txt"):setString(getTextByKey("invitation_rewards1"))
	self.mainUI:getChildByName("txt_invitecode3"):getChildByName("txt"):setString(getTextByKey("invitation_rewards2"))
	self.mainUI:getChildByName("txt_invite18"):getChildByName("txt"):setString(getTextByKey("invitation_rewards3"))
	self.mainUI:getChildByName("txt_invite_code20"):getChildByName("txt"):setString(getTextByKey("invited_entranceInvited"))
	local invitePlayers = self.extraArgs[1].invitePlayerNum
	if invitePlayers > 30 then
		invitePlayers = 30
	end
	self.mainUI:getChildByName("txt_invitecode4"):getChildByName("txt"):setString((invitePlayers - self.extraArgs[1].gainedInviteRewardNum))
	self.mainUI:getChildByName("txt_invteclode9"):getChildByName("txt"):setString(self.extraArgs[1].invitePlayerNum)
	self.mainUI:getChildByName("txt_invtecode1"):getChildByName("txt"):setString(Localization:getInstance():getText("invited_entranceSec"))

	--描边字体begin
	local infoLabelFlash = self.mainUI:getChildByName("txt_invtecode10"):getChildByName("txt")
	local inviteCode = DataManager.getGameInitData().invitationCode
	infoLabelFlash:setString(inviteCode)
	infoLabelFlash:setColor(ccc3(255, 231, 158))
	infoLabelFlash:setAroundColor(ccc3(205, 134, 10))
	local infoLabelFlash6 = self.mainUI:getChildByName("txt_invirecode11"):getChildByName("txt")
	infoLabelFlash6:setString(getTextByKey("invitationSec7"))
	infoLabelFlash6:setColor(ccc3(255, 231, 158))
	infoLabelFlash6:setAroundColor(ccc3(205, 134, 10))
	local infoLabelFlash7 = self.mainUI:getChildByName("txt_invirecode11_2"):getChildByName("txt")
	infoLabelFlash7:setString(getTextByKey("invitationSec7"))
	infoLabelFlash7:setColor(ccc3(255, 231, 158))
	infoLabelFlash7:setAroundColor(ccc3(205, 134, 10))

	local infoLabelFlash1 = self.mainUI:getChildByName("txt_invitecode16"):getChildByName("txt")
	infoLabelFlash1:setString(getTextByKey("invitationSec1"))
	infoLabelFlash1:setColor(ccc3(255,255,255))
	infoLabelFlash1:setAroundColor(ccc3(0, 0, 0))
	local infoLabelFlash2 = self.mainUI:getChildByName("txt_invitecode17"):getChildByName("txt")
	infoLabelFlash2:setString(getTextByKey("invitationSec2"))
	infoLabelFlash2:setColor(ccc3(255,255,255))
	infoLabelFlash2:setAroundColor(ccc3(0, 0, 0))
	local infoLabelFlash3 = self.mainUI:getChildByName("txt_invitecode13"):getChildByName("txt")
	infoLabelFlash3:setString(getTextByKey("invitationSec3"))
	infoLabelFlash3:setColor(ccc3(255,255,255))
	infoLabelFlash3:setAroundColor(ccc3(0, 0, 0))
	local infoLabelFlash4 = self.mainUI:getChildByName("txt_invitecode12"):getChildByName("txt")
	infoLabelFlash4:setString(getTextByKey("invitationSec4"))
	infoLabelFlash4:setColor(ccc3(255,255,255))
	infoLabelFlash4:setAroundColor(ccc3(0, 0, 0))
	local infoLabelFlash5 = self.mainUI:getChildByName("txt_invtecode5"):getChildByName("txt")
	infoLabelFlash5:setString(getTextByKey("invitationSec5"))
	infoLabelFlash5:setColor(ccc3(0, 0, 0))
	infoLabelFlash5:setAroundColor(ccc3(205, 134, 10))

	local infoLabelFlash8 = self.mainUI:getChildByName("txt_invitecode15"):getChildByName("txt")
	infoLabelFlash8:setString(getTextByKey("invitationSec8"))
	infoLabelFlash8:setColor(ccc3(200, 0, 0))
	infoLabelFlash8:setAroundColor(ccc3(205, 134, 10))
	local infoLabelFlash9 = self.mainUI:getChildByName("txt_invitecode14"):getChildByName("txt")
	infoLabelFlash9:setString(getTextByKey("invitationSec8"))
	infoLabelFlash9:setColor(ccc3(200, 0, 0))
	infoLabelFlash9:setAroundColor(ccc3(205, 134, 10))
	--end

	local function onClickRewardButton( )
		local function gainInviteRewardSucceed( response )
			print(table.tostring(response))
			local function onGet(  )
				RewardManager:getReward(response.data.rewards)
				self.mainUI:getChildByName("txt_invitecode4"):getChildByName("txt"):setString(0)
				self.rewardButton:setVisible(false)
			end
			local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = response.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()

	        local gameInit = DataManager.getGameInitData()
	        if gameInit.sharkAccountInvitation == nil then
	        	gameInit.sharkAccountInvitation = {}
	        	gameInit.sharkAccountInvitation.invitePlayerNum = 0
	        	gameInit.sharkAccountInvitation.gainedInviteRewardNum = 0
	        	gameInit.sharkAccountInvitation.hasInvited = false
	        end
	        gameInit.sharkAccountInvitation.gainedInviteRewardNum = gameInit.sharkAccountInvitation.invitePlayerNum
	        DataManager.setGameInitData(gameInit)
	        self.container:resetTipInfoForActivity("Activity_InvitationCode")
		end
		local function gainInviteRewardFailed( response )
			if response.data == 710516 then
				NewPackageFullPanel:show()
				-- CanonMessageBox:Show( getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			end
			-- elseif response.data.retCode == 716810 then
			-- 	CanonMessageBox:Show( getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		end
		if BagCalcManager.isFull() then
	        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
	        -- SuspensionLabel:showContent(self.container, aContent)
	        NewPackageFullPanel:show()
	        return
	    end
		GainInviteRewardRequest.sendRequest(nil , gainInviteRewardSucceed , gainInviteRewardFailed)
	end

	self.rewardButton = Button:create(self.mainUI:getChildByName("btn_the_receive"))
	self.rewardButton:addEventListener(Events.kStart,onClickRewardButton)

	if (self.extraArgs[1].invitePlayerNum - self.extraArgs[1].gainedInviteRewardNum) <= 0 or self.extraArgs[1].gainedInviteRewardNum == 30 then
		self.rewardButton:setVisible(false)
	end

	local function onClickSubmitButton(  )
		local function gainInvitedRewardSucceed( response )
			print(table.tostring(response))
			local function onGet(  )
				RewardManager:getReward(response.data.rewards)
			end
			local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = response.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()
			self.submitButton:setVisible(false)
		    self.mainUI:getChildByName("bg_guild_name"):setVisible(false)
		    self.mainUI:getChildByName("bg_guild_name2"):setVisible(false)
		    self.mainUI:getChildByName("txt_invtecode1"):setVisible(false)
		    self.mainUI:getChildByName("txt_invite_code20"):setVisible(true)
	        -- self.inputSprite.refCocosObj:setVisible(false)
	        self.editInputLabel:removeFromParentAndCleanup(true)

	        local gameInit = DataManager.getGameInitData()
	        if gameInit.sharkAccountInvitation == nil then
	        	gameInit.sharkAccountInvitation = {}
	        	gameInit.sharkAccountInvitation.invitePlayerNum = 0
	        	gameInit.sharkAccountInvitation.gainedInviteRewardNum = 0
	        	gameInit.sharkAccountInvitation.hasInvited = false
	        end
	        gameInit.sharkAccountInvitation.hasInvited = false
	        DataManager.setGameInitData(gameInit)
	        self.container:resetTipInfoForActivity("Activity_InvitationCode")
		end
		local function gainInvitedRewardFailed( response )
			print(table.tostring(response))
			if response.data == 716813 then
				CanonMessageBox:Show( getTextByKey("invitation_errorCode"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			elseif response.data == 716810 then
				CanonMessageBox:Show( getTextByKey("invitation_errorDeviceInvited"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			elseif response.data == 716811 then
				CanonMessageBox:Show( getTextByKey("invitation_errorAccountInvited"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			-- elseif response.data.retCode == 716811 then
			-- 	CanonMessageBox:Show( getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			end
		end
		if string.len(selectedText) ~= 6 then
			SuspensionLabel:showContent(self, getTextByKey("invitation_errorCode"))
			return
		elseif string.lower(selectedText) == string.lower(DataManager.getGameInitData().invitationCode) then
			CanonMessageBox:Show( getTextByKey("invitation_errorSelf"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			return
		else
			-- if BagCalcManager.isFull() then
		 --        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
		 --        SuspensionLabel:showContent(self.container, aContent)
		 --        return
		 --    end
		 -- local deviceTest = "hahahaha4"--getDeviceId()
			local param = {invitationCode = selectedText , deviceId = getDeviceId()}
			GainInvitedRewardRequest.sendRequest(param , gainInvitedRewardSucceed , gainInvitedRewardFailed)
		end

	end
	self.submitButton = Button:create(self.mainUI:getChildByName("btn_submit"))
	self.submitButton:addEventListener(Events.kStart,onClickSubmitButton)

	if self.extraArgs[1].hasInvited or self.extraArgs[2] then
		self.submitButton:setVisible(false)
	    self.mainUI:getChildByName("bg_guild_name"):setVisible(false)
	    self.mainUI:getChildByName("bg_guild_name2"):setVisible(false)
	    self.mainUI:getChildByName("txt_invtecode1"):setVisible(false)
	    self.editInputLabel:removeFromParentAndCleanup(true)
	else
		self.mainUI:getChildByName("txt_invite_code20"):setVisible(false)
	end
end

function Activity_InvitationCodeLayer.getTipNum()
  if not Activity_InvitationCodeLayer.enable() then
    return 0
  end

  local gameInit = DataManager.getGameInitData()

  if gameInit.sharkAccountInvitation == nil then
  	return 1 , true
  else
  	if gameInit.sharkAccountInvitation.invitePlayerNum > gameInit.sharkAccountInvitation.gainedInviteRewardNum then
  		if gameInit.sharkAccountInvitation.hasInvited then
  			if gameInit.sharkAccountInvitation.invitePlayerNum > 30 then
  				return 0 , false
  			end
  			return 1, false
		else
			if gameInit.sharkAccountInvitation.invitePlayerNum > 30 then
  				return 0 , true
  			end
			return 1, true
  		end
  	else
  		if gameInit.sharkAccountInvitation.hasInvited then
  			return 0, false
		else
			return 0, true
  		end
  	end

  end

end