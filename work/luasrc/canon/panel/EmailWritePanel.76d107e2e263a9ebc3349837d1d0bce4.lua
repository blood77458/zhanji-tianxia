require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.request.SendUserEmailRequest"
require "canon.utils.StringUtil"
require "hecore.display.CocosObject"
require "hecore.display.Director"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

EmailWritePanel = class(Layer)

function EmailWritePanel:ctor()
end

function EmailWritePanel:create(container, uiBuilder, targetName, targetUid, isReply, onSend)
	local panel = EmailWritePanel.new()
	panel.container = container
	panel.uiBuilder = uiBuilder or LayoutBuilder:createWithContentsOfFile("scene/email_all_new.json")
	panel.targetName = targetName
	panel.targetUid = targetUid
	panel.isReply = isReply
	panel.onSend = onSend

	panel:initLayer()
	return panel
end

function EmailWritePanel:initLayer()
	EmailWritePanel.super.initLayer(self)
	
	self.mainUI = self.uiBuilder:build("panel/email_panel_reply_email")
	self:addChild(self.mainUI)
	
	local function onSendClick()
		self.editBox:setVisible(false)
		
		local nZh, nEn = StringUtil.calcChineseEnglishNum(self.mailContent)
		if nZh*2 + nEn > 100 then
			function onClick()
				self.editBox:setVisible(true)
			end
			CanonMessageBox:Show(getTextByKey("mail_maxTextTips"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 35, onClick) --"邮件内容最多不能超过50字"
		elseif nZh + nEn < 1 then
			SuspensionLabel:showContent(self.container, getTextByKey("mail_isBlank"))
			self.editBox:setVisible(true)
		else
			local function onSendFinish(e)
				local reward = false
				if e.data.rewards then
					RewardManager:getReward(e.data.rewards)
					for k,v in pairs(e.data.rewards) do
						if v.itemType == ResourceEnum.FRIENDPOINT then
							--"发送成功，获得{num}点友情点奖励。"
							SuspensionLabel:showContent(self.container, Localization:getInstance():getText("mail_sendSuccess_friendshipPoint", {num = tonumber(v.amount)}))
							reward = true
							break
						end
					end
				end
				if not reward then
					SuspensionLabel:showContent(self.container, getTextByKey("mail_sendSuccess")) --"邮件发送成功！"
				end
				self:closePanel()
				if self.onSend then
					self.onSend()
				end
			end
			local params = {content = self.mailContent, receiveUid = self.targetUid}
			local request = SendUserEmailRequest.new(params, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.SendUserEmailSucceed, onSendFinish)
			request:start()
		end
	end
	local picSend = self.mainUI:getChildByName("email_btn_panel_email_send")
	picSend:getChildByName("txt_panel_email_send"):getChildByName("txt"):setString( getTextByKey("mail_sendBtn"))  --"发送"
	local btnSend = Button:create(picSend)
	btnSend:addEventListener(Events.kStart, onSendClick)
	
	local function onCloseClick()
		self:closePanel()
	end
	local picReturn = self.mainUI:getChildByName("email_btn_panel_email_return")
	picReturn:getChildByName("txt_panel_email_return"):getChildByName("txt"):setString(getTextByKey("mail_backBtn"))  --"返回"
	local btnReturn = Button:create(picReturn)
	btnReturn:addEventListener(Events.kStart, onCloseClick)
	local picClose = self.mainUI:getChildByName("common_btn_close")
	local btnClose = Button:create(picClose)
	btnClose:addEventListener(Events.kStart, onCloseClick)
	
	self.mainUI:getChildByName("email_txt_panel_send_char_num_limit"):getChildByName("txt"):setString(getTextByKey("mail_maxTextTips")) --"邮件内容最多不能超过50字"
	self.mainUI:getChildByName("email_txt_panel_email_send_to"):getChildByName("txt"):setString(getTextByKey("mail_to"))  --"发送至："
	if self.isReply then
		self.mainUI:getChildByName("email_txt_panel_email_title"):getChildByName("txt"):setString(getTextByKey("mail_returnTitle"))  --"回复邮件"
	else
		self.mainUI:getChildByName("email_txt_panel_email_title"):getChildByName("txt"):setString(getTextByKey("mail_messageTitle"))  --"发送邮件")
	end
	
	self.mailContent = getTextByKey("mail_defaultMessage")
	local maxCharPerLine = 17
	local textPic = self.mainUI:getChildByName("yellowGray9_pic")
	local editText = TextField:create(self.mailContent, nil, 27, CCSizeMake(27*maxCharPerLine, 0))
	editText:setColor(ccc3(0, 0, 0))
	editText:setAnchorPoint(ccp(0, 1))
	local editTextY = 350
	editText:setPosition(ccp(15, editTextY))
	textPic:addChild(editText)
	if __IOS then
		editText:setVisible(false)
	end
	local function onTextInputChange()
		self.mailContent = self.editBox:getText()
		editText:setString(self.mailContent)
		if __ANDROID then
			editText:setPositionY(editTextY - editText:getContentSize().height/10)
		end
	end
	local inputSprite = Scale9Sprite:create("emailnew/button_clear.png")
	self.editBox = TextInput:create(CCSizeMake(486, 400), inputSprite)
	self.editBox:setFontColor(ccc3(0, 0, 0))
	self.editBox.refCocosObj:setInputFlag(-100)
	self.editBox:setPosition(ccp(visibleSize.width/2, 650))
	self.editBox:setReturnType(kKeyboardReturnTypeDone)
	self.editBox:addEventListener(kTextInputEvents.kChanged, onTextInputChange)
	self.editBox:setText(self.mailContent)
	self.mainUI:addChild(self.editBox)
	
	local textName = TextField:create(self.targetName, nil, 35)
	textName:setColor(ccc3(153, 51, 0))
	textName:setAnchorPoint(ccp(0, 0))
	textName:setPosition(ccp(115+110, 443+405))
	self.mainUI:addChild(textName)
end

-- 因为BaseUIScene:setTableViewsEnabled内部有计数，而PopoutManager只在所有弹出面板都关闭后调用一次setTableViewsEnabled(true)，因此先在这里修正
function EmailWritePanel:closePanel()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	if self.container.targetInfoPanel then
		self.container:setTableViewsEnabled(true)
	end
end
