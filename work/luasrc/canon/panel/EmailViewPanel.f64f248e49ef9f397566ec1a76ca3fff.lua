require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.request.DeleteSysEmailRequest"
require "canon.request.DeleteSysNoticeRequest"
require "canon.request.DeleteUserEmailRequest"
require "canon.request.GainSysEmailRewardRequest"
require "canon.utils.StringUtil"
require "canon.panel.EmailWritePanel"
require "hecore.display.CocosObject"
require "hecore.display.Director"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

EmailViewPanel = class(Layer)

function EmailViewPanel:ctor()
end

function EmailViewPanel:create(container, uiBuilder, type, index, onRead, onDelete, onReply)
	local panel = EmailViewPanel.new()
	panel.container = container
	panel.uiBuilder = uiBuilder or LayoutBuilder:createWithContentsOfFile("scene/email_all_new.json")
	panel.mailType = type
	panel.mailIndex = index
	panel.onRead = onRead
	panel.onDelete = onDelete
	panel.onReply = onReply

	panel:initLayer()
	return panel
end

function EmailViewPanel:initLayer()
	EmailViewPanel.super.initLayer(self)

	local function onCloseClick()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end
	local function onPrevClick()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		local panel = EmailViewPanel:create(self.container, self.uiBuilder, self.mailType, self.mailIndex+1, self.onRead, self.onDelete, self.onReply)
		PopoutManager:sharedManager():popout(panel, nil, true, false, self.container)
	end
	local function onNextClick()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		local panel = EmailViewPanel:create(self.container, self.uiBuilder, self.mailType, self.mailIndex-1, self.onRead, self.onDelete, self.onReply)
		PopoutManager:sharedManager():popout(panel, nil, true, false, self.container)
	end
	local function onDelClick()
		local function onDeleteFinish()
			print("onDeleteFinish! ")
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			if self.onDelete then
				self.onDelete()
			end
		end
		if self.mailType == 1 then
			local mailData = DataManager.GetUserEmailsData.sysEmails[self.mailIndex]
			if mailData == nil then
				return
			end

			local reward = false
			local targetEmailId = 0
			if mailData.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
				--普通系统邮件
				targetEmailId = mailData.sysEmailMetaId
				if targetEmailId == nil then
					return
				end
				if not mailData.gainedReward then
					for i,v in ipairs(DataManager.GetUserEmailsData.sysEmailMeta) do
						if v.id == targetEmailId then
							reward = v.containReward
							break
						end
					end
				end
			else
				--奖励邮件
				if not reward and not mailData.gainedReward then
					reward = true
				end
				targetEmailId = mailData.rewardEmailId
			end

			local function commitDelete()
				if mailData.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
					--普通系统邮件
					local deleteRequest = DeleteSysEmailRequest.new({sysEmailMetaId = targetEmailId}, rpc.SendingPriority.kHigh)
					deleteRequest:addEventListener(RequestNotifyEnum.DeleteSysEmailSucceed, onDeleteFinish)
					deleteRequest:start()
				else
					--奖励邮件
					EmailBatchDeleteRewardEmailRequest.sendRequest({targetEmailId}, onDeleteFinish, EmailBatchDeleteRewardEmailRequest.onFailedDefault)
				end
			end
			if reward then
				--"删除此邮件后将无法领取邮件内的奖励，是否要删除此邮件？"
				CanonMessageBox:Show(getTextByKey("mail_reward_deleteConfirm"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
			else
				--"确定要删除此邮件吗？删除的邮件将不可恢复"
				CanonMessageBox:Show(getTextByKey("mail_confirmDelete"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
			end
		elseif self.mailType == 2 then
			local mailData = DataManager.GetUserEmailsData.sysNotices[self.mailIndex]
			if mailData == nil or mailData.sysNoticeId == nil then
				return
			end
			local function commitDelete()
				local deleteRequest = DeleteSysNoticeRequest.new({sysNoticeId = mailData.sysNoticeId}, rpc.SendingPriority.kHigh)
				deleteRequest:addEventListener(RequestNotifyEnum.DeleteSysNoticeSucceed, onDeleteFinish)
				deleteRequest:start()
			end
			--"确定要删除此邮件吗？删除的邮件将不可恢复"
			CanonMessageBox:Show(getTextByKey("mail_confirmDelete"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
		elseif self.mailType == 3 then
			local mailData = DataManager.GetUserEmailsData.userEmails[self.mailIndex]
			if mailData == nil or mailData.userEmailId == nil then
				return
			end
			local function commitDelete()
				local deleteRequest = DeleteUserEmailRequest.new({userEmailId = mailData.userEmailId}, rpc.SendingPriority.kHigh)
				deleteRequest:addEventListener(RequestNotifyEnum.DeleteUserEmailSucceed, onDeleteFinish)
				deleteRequest:start()
			end
			--"确定要删除此邮件吗？删除的邮件将不可恢复"
			CanonMessageBox:Show(getTextByKey("mail_confirmDelete"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
		end
	end
	local function onGetRewardClick()
		local mailData = DataManager.GetUserEmailsData.sysEmails[self.mailIndex]
		if mailData == nil or mailData.gainedReward then
			return
		end
		local function onSucceed(e)
			print("onSucceed! e = " .. tostringRich(e))
			mailData.gainedReward = true
			self.mainUI:getChildByName("email_control_gainreward_and_del"):setVisible(false)
			self.mainUI:getChildByName("email_btn_panel_email_del"):setVisible(true)
			function onRewardClose() -- setTableViewsEnabled计数bug
				self.container.targetInfoPanel = self
				self.container:setTableViewsEnabled(true)
			end
			local rewardPanel = GetRewardInfoPanel:create(self.container, e.data.rewards, onRewardClose)
			PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self.container)
			RewardManager:getReward(e.data.rewards)
		end
		local function onFailed(e)
			if e.data == 712605 then --"System notification contains no reward: {0:serverId}, {1:sysEmailId}"
				CanonMessageBox:Show(getTextByKey("mail_mailContainsNoReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) --"此邮件不包含奖励，无法领取。"
			elseif e.data == 712606 then --"Already gined system notification reward: {0:uid}, {1:serverId}, {1:sysEmailId}"
				CanonMessageBox:Show(getTextByKey("mail_rewardAlreadyClaimed"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) --"此邮件所包含的奖励已被领取。"
			elseif e.data == 712607 then --"System notification reward is not active: {0:serverId}, {1:sysEmailId}, {2:currSecond}"
				CanonMessageBox:Show(getTextByKey("mail_mailIsExpired"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) --"此邮件已经过期，无法领取奖励。"
			elseif e.data == 712608 then --"System notification reward has been deleted by user: {0:uid}, {1:serverId}, {2:sysEmailId}"
				CanonMessageBox:Show(getTextByKey("mail_mailIsDeleted"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) --"此邮件已被删除，无法领取奖励。"
			elseif e.data == 710516 then
				NewPackageFullPanel:show()
				-- CanonMessageBox:Show(getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) --"您的背包已满，请清理背包。"
			else
				CanonMessageBox:showCommUnHandleErrorBox( e.data )
			end
		end
		if mailData.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
			--普通系统邮件
			local request = GainSysEmailRewardRequest.new({sysEmailId = mailData.sysEmailMetaId}, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.GainSysEmailRewardSucceed, onSucceed)
			request:addEventListener(RequestNotifyEnum.GainSysEmailRewardFailed, onFailed)
			request:start()
		else
			--奖励邮件
			EmailGainRewardEmailRewardRequest.sendRequest(mailData.rewardEmailId, onSucceed, EmailGainRewardEmailRewardRequest.onFailedDefault)
		end
	end
	local function onReplyClick()
		local mailData = DataManager.GetUserEmailsData.userEmails[self.mailIndex]
		if mailData == nil then
			return
		end
		local panel = EmailWritePanel:create(self.container, self.uiBuilder, mailData.senderName, mailData.senderUid, true, self.onReply)
		PopoutManager:sharedManager():popout(panel, nil, true, false, self.container)
	end

	local enablePrev = false
	local mailText = ""
	local timeText = nil
	if self.mailType == 1 then
		local titleText = ""
		local containReward = false

		self.mainUI = self.uiBuilder:build("panel/email_pane_show_sys_email")
		self:addChild(self.mainUI)

		local mailData = DataManager.GetUserEmailsData.sysEmails[self.mailIndex]
		if mailData == nil then
			return
		end
		enablePrev = DataManager.GetUserEmailsData.sysEmails[self.mailIndex + 1] ~= nil

		--modified by zheng.che @ 2014-6-16
		if mailData.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
			--普通系统邮件
			local mailMeta = nil
			for i,v in ipairs(DataManager.GetUserEmailsData.sysEmailMeta) do
				if v.id == mailData.sysEmailMetaId then
					mailMeta = v
					break
				end
			end
			if mailMeta == nil then
				return
			end
			titleText = mailMeta.titleText
			mailText = mailMeta.contentText
			containReward = mailMeta.containReward
		else
			--奖励邮件
			titleText = mailData.title
			mailText = mailData.content
			containReward = true--奖励邮件一定包含奖励内容
		end

		if containReward and not mailData.gainedReward then
			self.mainUI:getChildByName("email_btn_panel_email_del"):setVisible(false)

			local picDel = self.mainUI:getChildByName("email_control_gainreward_and_del"):getChildByName("email_btn_panel_email_del")
			picDel:getChildByName("txt_panel_email_del"):getChildByName("txt"):setString(getTextByKey("mail_deleteBtn"))
			local btnDel = Button:create(picDel)
			btnDel:addEventListener(Events.kStart, onDelClick)
			local picGet = self.mainUI:getChildByName("email_control_gainreward_and_del"):getChildByName("email_btn_panel_gain_reward")
			picGet:getChildByName("email_txt_panel_email_gain_reward"):getChildByName("txt"):setString(getTextByKey("mail_claimRewardBtn"))
			local btnGet = Button:create(picGet)
			btnGet:addEventListener(Events.kStart, onGetRewardClick)
		else
			self.mainUI:getChildByName("email_control_gainreward_and_del"):setVisible(false)
		end

		self.mainUI:getChildByName("email_txt_panel_email_title"):getChildByName("txt"):setString(titleText)
	elseif self.mailType == 2 then
		self.mainUI = self.uiBuilder:build("panel/email_pane_show_sys_email")
		self:addChild(self.mainUI)

		self.mainUI:getChildByName("email_control_gainreward_and_del"):setVisible(false)

		local mailData = DataManager.GetUserEmailsData.sysNotices[self.mailIndex]
		if mailData == nil then
			return
		end
		enablePrev = DataManager.GetUserEmailsData.sysNotices[self.mailIndex + 1] ~= nil
		local jsonData = table.deserialize(mailData.detail)
		local mailTitle = ""
		if mailData.type == 1 then
			mailTitle = Localization:getInstance():getText("SystemMailType1_title")
			mailText = Localization:getInstance():getText("SystemMailType1_txt", {playername = jsonData.nickName})
		elseif mailData.type == 2 then
			mailTitle = Localization:getInstance():getText("SystemMailType2_title", {playername=jsonData.nickName})
			for i,v in pairs(MetaManager.beast_fragment) do
				if v.id == jsonData.fragmentId then
					fragmentName = v.readName
					mailText = Localization:getInstance():getText("SystemMailType2_txt", {playername = jsonData.nickName, beastname = "", fragmentname = v.readName})
				end
			end
		elseif mailData.type == 3 then
			mailTitle = Localization:getInstance():getText("SystemMailType3_title", {playername=jsonData.nickName})
			mailText = Localization:getInstance():getText("SystemMailType3_txt", {playername=jsonData.nickName})
		elseif mailData.type == 4 then
			mailTitle = jsonData.title or ""
			mailText = jsonData.content or ""
		elseif mailData.type == 5 then
			mailTitle = Localization:getInstance():getText("pk_mail_title", {num1=jsonData.nickName})
			if tonumber(jsonData.loseScore) > 0 then
				mailText = Localization:getInstance():getText("pk_mail_lose", {num1=jsonData.nickName, num2=jsonData.loseScore})
			else
				mailText = Localization:getInstance():getText("pk_mail_lose1", {num1=jsonData.nickName})
			end
		elseif mailData.type == 6 then
			--军团被踢 {title:xxx, nickname:xxx, unionName:xxx}
			mailTitle = Localization:getInstance():getText("SystemMailType5_title")--你被踢出军团
			local titleName = UnionManager.getTitleName(tonumber(jsonData.title))
			mailText = Localization:getInstance():getText("SystemMailType5_txt", {career=titleName, name=jsonData.nickname, unionName=jsonData.unionName})--【{career}】【{name}】将你踢出【{unionName}】军团
		elseif mailData.type == 7 then
			mailTitle = Localization:getInstance():getText("SystemMailType7_title")--新的小伙伴
			mailText = Localization:getInstance():getText("SystemMailType7_txt", {playername=jsonData.nickName}) --{playername}通过了你的申请，你们现在已经是好友了。
		elseif mailData.type == 8 then
			mailTitle = Localization:getInstance():getText("rename_friendMailTitle")--改名啦,发给朋友
			mailText = Localization:getInstance():getText("rename_friendMail", {playername1=jsonData.oldNickName , num1 = jsonData.year, num2 = jsonData.month, num3 =  jsonData.day,playername2 = jsonData.newNickName}) 
		elseif mailData.type == 9 then
			mailTitle = Localization:getInstance():getText("rename_guildMailTitle")--改名啦，发给军团
			mailText = Localization:getInstance():getText("rename_guildMail", {playername1=jsonData.oldNickName , num1 = jsonData.year, num2 = jsonData.month, num3 =  jsonData.day,playername2 = jsonData.newNickName})
		elseif mailData.type == 11 then
			mailTitle = Localization:getInstance():getText("WGVG_LetterTittle02")--跨服军团战小组赛结果
			local rankTxt = CrossUnionPkUtils.getTeamStageNameByScore(jsonData.points)--要改成文字版比如谋士
			local itemTxt = CanonGoodIcon.getGoodName(ResourceEnum.PROP, jsonData.propId, 1, nil)
			mailText = Localization:getInstance():getText("WGVG_Letter02", {number1=jsonData.points, team=rankTxt, beg=itemTxt})--恭喜您在跨服军团战小组赛得到了积分{number1}达到了分段{team}获得了礼包{beg}
		elseif mailData.type == 12 then
			mailTitle = Localization:getInstance():getText("WGVG_LetterTittle01")--跨服军团战阵容变动
			mailText = Localization:getInstance():getText("WGVG_Letter01", {name=jsonData.name})--{name}已经离开了您的军团，请及时进行阵容调整。
		end
		self.mainUI:getChildByName("email_txt_panel_email_title"):getChildByName("txt"):setString(mailTitle)
	elseif self.mailType == 3 then
		self.mainUI = self.uiBuilder:build("panel/email_panel_show_user_email")
		self:addChild(self.mainUI)

		local picReply = self.mainUI:getChildByName("email_btn_panel_email_reply")
		picReply:getChildByName("txt_panel_email_reply"):getChildByName("txt"):setString(getTextByKey("mail_returnBtn"))  --"回复"
		local btnReply = Button:create(picReply)
		btnReply:addEventListener(Events.kStart, onReplyClick)

		local mailData = DataManager.GetUserEmailsData.userEmails[self.mailIndex]
		if mailData == nil then
			return
		end
		enablePrev = DataManager.GetUserEmailsData.userEmails[self.mailIndex + 1] ~= nil
		self.mainUI:getChildByName("email_txt_panel_email_title"):getChildByName("txt"):setString(mailData.senderName)
		mailText = mailData.content
		timeText = getTextByKey("mail_timeShow") .. EmailScene.getEmailTimeText(mailData.sendTime)
	end

	local margin = 10
	local bilibili = 1.10 --调整设备和模拟器尺寸差
	local textBK = self.mainUI:getChildByName("yellowGray9_pic")
	local textWidth = textBK:getContentSize().width - 2*margin
	local textHeight = textBK:getContentSize().height - 2*margin
	local textTop = textBK:getPositionY() - margin
	local textLeft = textBK:getPositionX() + margin
	if timeText then
		local text = TextField:create(timeText, nil, 27, nil, kCCTextAlignmentCenter)
		text:setColor(ccc3(255, 255, 255))
		text:setAnchorPoint(ccp(0.5, 0))
		text:setPosition(ccp(textLeft + textWidth/2, textTop - textHeight))
		self.mainUI:addChild(text)
		if text:getTexture() then
			textHeight = textHeight - text:getTexture():getContentSize().height
		end
	end
	local content = string.gsub(mailText, "\\n", "\n")
	local text = TextField:create(content, nil, 27, CCSizeMake(textWidth, 0))
	text:setColor(ccc3(255, 255, 255))
	text:setAnchorPoint(ccp(0, 0))
	local textContentHeight = text:getTexture() and text:getTexture():getContentSize().height or 0
	if textContentHeight <= textHeight then
		text:setPosition(ccp(textLeft, textTop-textContentHeight * bilibili))
		self.mainUI:addChild(text)
	else
		local scroll = ScrollView:create(textWidth, textHeight)
		scroll:setPosition(ccp(margin, textBK:getContentSize().height - textHeight - margin))
		scroll:setDirection(kCCScrollViewDirectionVertical)
		textBK:addChild(scroll)
		scroll:addChild(text)
		scroll:setContentSize(CCSizeMake(textWidth, textContentHeight * bilibili))
		scroll:setContentOffset(ccp(0, textHeight-textContentHeight * bilibili), false)
	end

	if enablePrev then
		local picPrev = self.mainUI:getChildByName("email_btn_zuofan")
		local btnPrev = Button:create(picPrev)
		btnPrev:addEventListener(Events.kStart, onPrevClick)
		self.mainUI:getChildByName("email_btn_zuofan_disable"):setVisible(false)
	else
		self.mainUI:getChildByName("email_btn_zuofan"):setVisible(false)
	end
	if self.mailIndex > 1 then
		local picNext = self.mainUI:getChildByName("email_btn_youfan")
		local btnNext = Button:create(picNext)
		btnNext:addEventListener(Events.kStart, onNextClick)
		self.mainUI:getChildByName("email_btn_youfan_disable"):setVisible(false)
	else
		self.mainUI:getChildByName("email_btn_youfan"):setVisible(false)
	end

	local picDel = self.mainUI:getChildByName("email_btn_panel_email_del")
	picDel:getChildByName("txt_panel_email_del"):getChildByName("txt"):setString(getTextByKey("mail_deleteBtn"))
	local btnDel = Button:create(picDel)
	btnDel:addEventListener(Events.kStart, onDelClick)

	local picClose = self.mainUI:getChildByName("common_btn_close")
	local btnClose = Button:create(picClose)
	btnClose:addEventListener(Events.kStart, onCloseClick)

	if self.onRead then
		self.onRead(self.mailType, self.mailIndex)
	end
end
