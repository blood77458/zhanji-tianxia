--------------------------------------------------------------------------------
-- EmailScene.lua - 邮件界面
-- author: litong.sun
-- date: 2014-02-17
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.panel.EmailViewPanel"
require "canon.request.DeleteSysEmailRequest"
require "canon.request.DeleteSysNoticeRequest"
require "canon.request.DeleteUserEmailRequest"
require "canon.request.GetUserEmailsRequest"
require "canon.request.ReadSysEmailRequest"
require "canon.request.ReadSysNoticeRequest"
require "canon.request.ReadUserEmailRequest"
require "canon.scene.BaseUIScene"
require "canon.utils.StringUtil"
require "canon.utils.ViewControlUtil"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.PopoutManager"
require "hecore.ui.TableView"
require "canon.request.EmailBatchDeleteRewardEmailRequest"
require "canon.request.EmailBatchDeleteSysEmailRequest"
require "canon.request.EmailBatchDeleteSysNoticeRequest"
require "canon.request.EmailBatchDeleteUserEmailRequest"
require "canon.request.EmailGainRewardEmailRewardRequest"
require "canon.request.EmailReadRewardEmailRequest"
require "canon.features.crossUnionPk.manager.CrossUnionPkUtils"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function setCCNodeTagTree(node, tagTree)
	if type(tagTree) == "number" then
		node:setTag(tagTree)
		return
	end
	if tagTree[1] then
		node:setTag(tagTree[1])
	end
	for k,v in pairs(tagTree) do
		if type(k) == "string" then
			local child = node:getChildByName(k)
			if child then
				setCCNodeTagTree(child, v)
			end
		end
	end
end

EmailScene = class(BaseUIScene)

-----------------------------------------------------------------------------------------------------------枚举

EmailScene.MAIL_TYPE_USER 		= 1--玩家邮件
EmailScene.MAIL_TYPE_SYSEMAIL 	= 2--通知
EmailScene.MAIL_TYPE_SYSNOTICE 	= 3--系统消息
EmailScene.MAIL_TYPE_REWARD 	= 4--奖励邮件

-----------------------------------------------------------------------------------------------------------类函数

function EmailScene:ctor()
	self.title = getTextByKey("mail_title")
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.currentTab = 0
	self.selectList = {}
end

function EmailScene:create(argv)
	local scene = EmailScene.new()
	scene:initScene()
	scene.argv = argv or {returnScene = nil}
	return scene
end

function EmailScene:onInit()
	BaseUIScene.initBackGround(self)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/email_all_new.json")
	self.uiBuilder.useArtLabelTTF = true
	self.mainUI = self.uiBuilder:build("scene/email_main_scene")
	self:addChild(self.mainUI)

	self.btnSelectAll = self.mainUI:getChildByName("email_control_all_select")
	self.btnSelectAll:getChildByName("txt_select_all"):getChildByName("txt"):setString(getTextByKey("mail_selectAllBtn")) --"全选"
	self.btnSelectAll:getChildByName("btn_selected_all"):setVisible(false)
	self.btnSelectAll:getChildByName("btn_not_selected_all"):setVisible(true)
	self.btnSelectAll.selected = false
    local btnSelAll = Button:create(self.btnSelectAll)
	local function onClickSelectAll()
		self:setSelectAllState(not self.btnSelectAll.selected, true)
	end
	btnSelAll:addEventListener(Events.kStart, onClickSelectAll)

	local txtFull = self.mainUI:getChildByName("email_txt_emailbox_full")
    txtFull:getChildByName("txt"):setString(getTextByKey("mail_fullText")) --"您的收件箱已满，请尽快清理"
	txtFull:setVisible(false)
	self.mainUI:getChildByName("email_sys_reminder"):setVisible(false)
	self.mainUI:getChildByName("email_notice_reminder"):setVisible(false)
	self.mainUI:getChildByName("email_other_reminder"):setVisible(false)

	self.picBatchDel = self.mainUI:getChildByName("email_btn_delete_many")
	self.picBatchDel:getChildByName("txt_delete_many"):getChildByName("txt"):setString(getTextByKey("mail_batchDeleteBtn")) --"批量删除"
	local btnBatchDel = Button:create(self.picBatchDel)
	local function onBatchDelClick()
		if not self.switchTab then
			self:setBatchDeleteState(true, true)
		end
	end
	btnBatchDel:addEventListener(Events.kStart, onBatchDelClick, SELF)
	self.picBatchDelDisable = self.mainUI:getChildByName("email_btn_delete_many_disable")
	self.picBatchDelDisable:getChildByName("txt_delete_many"):getChildByName("txt"):setString(getTextByKey("mail_batchDeleteBtn")) --"批量删除"
	self.picBatchDelDisable:setVisible(false)

	self.picDel = self.mainUI:getChildByName("email_btn_run_del_many")
	self.picDel:getChildByName("txt_run_del_many"):getChildByName("txt"):setString(getTextByKey("mail_deleteBtn")) --"删除"
	local btnDel = Button:create(self.picDel)
	local function onDelClick()
		if self.switchTab then
			return
		end
		local count = 0
		local reward = false
		if self.currentTab == 1 then
			for i,v in ipairs(DataManager.GetUserEmailsData.sysEmails) do
				if v.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
					--普通系统邮件
					if self.selectList[i] and v.sysEmailMetaId then
						count = count + 1
						if not reward and not v.gainedReward then
							for i,meta in ipairs(DataManager.GetUserEmailsData.sysEmailMeta) do
								if meta.id == v.sysEmailMetaId then
									reward = meta.containReward
									break
								end
							end
						end
					end
				else
					--奖励邮件
					if self.selectList[i] then
						count = count + 1
						if not reward and not v.gainedReward then
							reward = true
						end
					end
				end
			end
		elseif self.currentTab == 2 then
			for i,v in ipairs(DataManager.GetUserEmailsData.sysNotices) do
				if self.selectList[i] and v.sysNoticeId then
					count = count + 1
				end
			end
		elseif self.currentTab == 3 then
			for i,v in ipairs(DataManager.GetUserEmailsData.userEmails) do
				if self.selectList[i] and v.userEmailId then
					count = count + 1
				end
			end
		end
		local function commitDelete()
			--modified by zheng.che @ 2014-6-17
			local function onDeleteOver()
				count = 0
				if count == 0 then
					local function refreshView()
						self.selectList = {}
						self.listView:reloadData()
						self:refreshEmailCount()
					end
					self:refreshEmailData(refreshView)
					self:setSelectAllState(false, false)
					SuspensionLabel:showContent(self.container, getTextByKey("mail_deleteSuccess")) --"邮件删除成功！"
				end
			end
			if self.currentTab == 1 then
				local sysList = {}
				local rewardList = {}

				for i,v in ipairs(DataManager.GetUserEmailsData.sysEmails) do
					if self.selectList[i] then
						if v.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
							--普通系统邮件
							table.insert(sysList, v.sysEmailMetaId)
						else
							--奖励邮件
							table.insert(rewardList, v.rewardEmailId)
						end
					end
				end

				if #sysList > 0 and #rewardList > 0 then
					--两种都有
					EmailBatchDeleteSysEmailRequest.sendRequest(sysList, EmailBatchDeleteSysEmailRequest.onSucceedDefault, EmailBatchDeleteSysEmailRequest.onFailedDefault)
					EmailBatchDeleteRewardEmailRequest.sendRequest(rewardList, onDeleteOver, EmailBatchDeleteRewardEmailRequest.onFailedDefault)
				elseif #sysList > 0 then
					EmailBatchDeleteSysEmailRequest.sendRequest(sysList, onDeleteOver, EmailBatchDeleteSysEmailRequest.onFailedDefault)
				elseif #rewardList > 0 then
					EmailBatchDeleteRewardEmailRequest.sendRequest(rewardList, onDeleteOver, EmailBatchDeleteRewardEmailRequest.onFailedDefault)
				end
			elseif self.currentTab == 2 then
				local mailList = {}
				for i,v in ipairs(DataManager.GetUserEmailsData.sysNotices) do
					if self.selectList[i] and v.sysNoticeId then
						table.insert(mailList, v.sysNoticeId)
					end
				end
				EmailBatchDeleteSysNoticeRequest.sendRequest(mailList, onDeleteOver, EmailBatchDeleteSysNoticeRequest.onFailedDefault)
			elseif self.currentTab == 3 then
				local mailList = {}
				for i,v in ipairs(DataManager.GetUserEmailsData.userEmails) do
					if self.selectList[i] and v.userEmailId then
						table.insert(mailList, v.userEmailId)
					end
				end
				EmailBatchDeleteUserEmailRequest.sendRequest(mailList, onDeleteOver, EmailBatchDeleteUserEmailRequest.onFailedDefault)
			end
		end
		if count == 0 then
			CanonMessageBox:Show(getTextByKey("mail_noMailSelected"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 35)
		else
			if reward then
				CanonMessageBox:Show(getTextByKey("mail_reward_batchDeleteConfirm"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
			else
				CanonMessageBox:Show(getTextByKey("mail_confirmBatchDelete"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, commitDelete)
			end
		end
	end
	btnDel:addEventListener(Events.kStart, onDelClick)
	local picDelDisable = self.mainUI:getChildByName("email_btn_run_del_many_disable")
	picDelDisable:getChildByName("txt_run_del_many"):getChildByName("txt"):setString(getTextByKey("mail_deleteBtn")) --"删除"
	picDelDisable:setVisible(false)

	local tabPicActive = {"email_btn_sys_inactive", "email_btn_notice_inactive", "email_btn_user_inactive"}--"email_btn_sys_active", "email_btn_notice_active", "email_btn_user_active"
	local tabPicInActive = {"email_btn_sys_active", "email_btn_notice_active", "email_btn_user_active"}--"email_btn_sys_inactive", "email_btn_notice_inactive", "email_btn_user_inactive"
	local tabTextActive = {"txt_system_email_inactive", "txt_notice_email_inactive", "txt_other_email_inactive"}--"txt_system_email_active", "txt_notice_email_active", "txt_other_email_active"
	local tabTextInActive = {"txt_system_email_active", "txt_notice_email_active", "txt_other_email_active"}--"txt_system_email_inactive", "txt_notice_email_inactive", "txt_other_email_inactive"
	local tabTextKey = {"mail_systemMailTab", "mail_systemMessageTab", "mail_userMailTab"}
	for i=1,3 do
		self.tabPicActive[i] = self.mainUI:getChildByName(tabPicActive[i])
		self.tabPicActive[i]:getChildByName(tabTextActive[i]):getChildByName("txt"):setString(getTextByKey(tabTextKey[i]))
		self.tabPicInActive[i] = self.mainUI:getChildByName(tabPicInActive[i])
		self.tabPicInActive[i]:getChildByName(tabTextInActive[i]):getChildByName("txt"):setString(getTextByKey(tabTextKey[i]))

		local button = Button:create(self.tabPicInActive[i])
		local function onClickButton()
			if not self.switchTab then
				self:showTab(i)
			end
		end
		button:addEventListener(Events.kStart, onClickButton)
	end

	self.mainUI:getChildByName("email_sys_reminder"):setVisible(false)
	self.mainUI:getChildByName("email_notice_reminder"):setVisible(false)
	self.mainUI:getChildByName("email_other_reminder"):setVisible(false)

	BaseUIScene.onInit(self)
end

function EmailScene:back()
	if self.batchDelete then
		self:setBatchDeleteState(false, true)
		self.isChangeingScene = false
	else
		self:replaceScene(MainMenuScene)
	end
end

function EmailScene:setTableViewsEnabledInner(v)
	if self.listView then
		self.listView:setTouchEnabled(v)
	end
end

function EmailScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function EmailScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function EmailScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	self:nodeAnimationFinished()
end

function EmailScene:sufEnterAnimation()
	local function onRefreshDataFinished()
		local finishOnce = false
		local function nodeActionFinished()
			if finishOnce then
				BaseUIScene.sufEnterAnimation(self)
			else
				finishOnce = true
			end
		end
		local arr = CCArray:create()
		arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
		arr:addObject(CCCallFunc:create(nodeActionFinished))
		self.mainUI:runAction(CCSequence:create(arr))
		self:showTab(1, nodeActionFinished)
	end
	self:refreshEmailData(onRefreshDataFinished)
end

function EmailScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local finishOnce = self.switchTab
	local function nodeActionFinished()
    self:nodeAnimationFinished()
    --[[
		if finishOnce then
			self:nodeAnimationFinished()
		else
			finishOnce = true
		end]]
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))
  local animationItems = ViewControlUtil.generateAnimatedCells(self.listView)
  local aDuration
  if #animationItems == 1 then
    aDuration = 0.3 - 0.15
  else
    aDuration = (0.3 - 0.15) / (#animationItems - 1)
  end
  for aIndex, aCell in ipairs(animationItems) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(0.15, ccp(-visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
	--self:runListExitAnimation(nodeActionFinished)
	self.currentTab = 0
end

function EmailScene:showTab(tabIndex, callback)
	if tabIndex == self.currentTab or tabIndex < 1 or tabIndex > 3 then
		return
	end
	self.switchTab = true
	local function currentTabFinished()
		self.currentTab = tabIndex
		for i = 1, 3 do
			self.tabPicActive[i]:setVisible(i == tabIndex)
			self.tabPicInActive[i]:setVisible(i ~= tabIndex)
		end
		self.batchDelete = false
		self:refreshList()
		self:setBatchDeleteState(false, false)
		local function onEnterFinished()
			self.switchTab = false
			if callback then
				callback()
			end
		end
		self:runListEnterAnimation(onEnterFinished)
	end
	if self.currentTab > 0 and self.currentTab <= 3 then
		self:runListExitAnimation(currentTabFinished)
	else
		currentTabFinished()
	end
end

function EmailScene:runListEnterAnimation(callback)
	local animationItems = ViewControlUtil.generateAnimatedCells(self.listView)
	if #animationItems > 0 then
		for i,v in ipairs(animationItems) do
			v:setPositionX(v:getPositionX() - visibleSize.width)
			local arr = CCArray:create()
			arr:addObject(CCDelayTime:create(0.05*(i-1)))
			arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
			if i == #animationItems and callback then
				arr:addObject(CCCallFunc:create(callback))
			end
			v:runAction(CCSequence:create(arr))
		end
	elseif callback then
		callback()
	end
end

function EmailScene:runListExitAnimation(callback)
	local animationItems = ViewControlUtil.generateAnimatedCells(self.listView)
	if #animationItems > 0 then
		for i,v in ipairs(animationItems) do
			local arr = CCArray:create()
			arr:addObject(CCDelayTime:create(0.05*(i-1)))
			arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
			if i == #animationItems and callback then
				arr:addObject(CCCallFunc:create(callback))
			end
			v:runAction(CCSequence:create(arr))
		end
	elseif callback then
		callback()
	end
end

function EmailScene:setBatchDeleteState(state, refreshList)
	local function changeState()
		self.batchDelete = state
		self.selectList = {}
		self:setSelectAllState(false, false)
		self.btnSelectAll:setVisible(state)
		self.picBatchDel:setVisible(not state and #self.listView.tableViewRenderer.list > 0)
		self.picBatchDelDisable:setVisible(not state and not (#self.listView.tableViewRenderer.list > 0))
		self.picDel:setVisible(state)
	end
	if refreshList and self.currentTab > 0 and self.currentTab <= 3 then
		self.switchTab = true
		local function onEnterFinished()
			self.switchTab = false
		end
		local function listExitFinished()
			changeState()
			self:refreshList()
			self:runListEnterAnimation(onEnterFinished)
		end
		self:runListExitAnimation(listExitFinished)
	else
		changeState()
	end
end

function EmailScene:setSelectAllState(state, refreshList)
	self.btnSelectAll.selected = state
	self.btnSelectAll:getChildByName("btn_selected_all"):setVisible(state)
	self.btnSelectAll:getChildByName("btn_not_selected_all"):setVisible(not state)
	if refreshList then
		if state then
			for i = 0, #self.listView.tableViewRenderer.list do
				self.selectList[i] = true
			end
		else
			self.selectList = {}
		end
		self.listView:reloadData()
	end
end

function EmailScene:refreshEmailCount()
	local list = {DataManager.GetUserEmailsData.sysEmails or {}, DataManager.GetUserEmailsData.sysNotices or {}, DataManager.GetUserEmailsData.userEmails or {}}
	local unread = {0,0,0}
	local reminder = {"email_sys_reminder", "email_notice_reminder", "email_other_reminder"}
	for ilist,vlist in ipairs(list) do
		local unread = 0
		for i, v in ipairs(vlist) do
			if not v.read then
				unread = unread + 1
			end
		end
		if unread > 0 then
			self.mainUI:getChildByName(reminder[ilist]):setVisible(true)
			self.mainUI:getChildByName(reminder[ilist]):getChildByName("txt_email_reminder"):getChildByName("txt"):setString(tostring(unread))
		else
			self.mainUI:getChildByName(reminder[ilist]):setVisible(false)
		end
		if ilist == self.currentTab then
			local maxNumber = {nil,50,100}
			self.mainUI:getChildByName("email_txt_emailbox_full"):setVisible(maxNumber[ilist] and #vlist >= maxNumber[ilist])
			if not self.batchDelete then
				self.picBatchDel:setVisible(#vlist > 0)
				self.picBatchDelDisable:setVisible(#vlist <= 0)
			end
		end
	end
end

function EmailScene:refreshEmailData(callback)
	local function onGetMailsSuccess(e)
		if e then
			--print("e = " .. tostringRich(e))
			DataManager.GetUserEmailsData = e.data

			--modified by zheng.che @ 2014-6-16
			local sysEmails = DataManager.GetUserEmailsData.sysEmails or {}
			--给原系统邮件添加时间标记 用于排序
			for k, mailData in ipairs(sysEmails) do
				mailData.mailType = EmailScene.MAIL_TYPE_SYSEMAIL
			end

			local rewardEmails = DataManager.GetUserEmailsData.rewardEmails or {}
			for k, mailData in ipairs(rewardEmails) do
				mailData.mailType = EmailScene.MAIL_TYPE_REWARD
			end

			local tab1List = table.union(sysEmails, rewardEmails)
			--此处要加排序
			local function sortFunc(a, b)
				--时间戳小的在前
				return a.receiveSeconds < b.receiveSeconds
			end
			--print("tab1List = " .. tostringRich(tab1List))
			table.sort(tab1List, sortFunc)

			--print("tab1List = " .. tostringRich(tab1List))
			DataManager.GetUserEmailsData.sysEmails = tab1List
			for _, aSysEmail in ipairs(DataManager.GetUserEmailsData.sysEmails) do
				if aSysEmail.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
					--普通系统邮件
					local mailMeta = nil
					for i,v in ipairs(DataManager.GetUserEmailsData.sysEmailMeta) do
						if v.id == aSysEmail.sysEmailMetaId then
							mailMeta = v
							break
						end
					end
					if mailMeta then
						mailMeta.contentText = string.gsub(mailMeta.contentText, "^%s*(.-)%s*", "%1")
					end
				else
					--奖励邮件
					aSysEmail.content = string.gsub(aSysEmail.content, "^%s*(.-)%s*", "%1")
				end
			end

			if self.listView then
				if self.currentTab == 1 then
					self.listView.tableViewRenderer.list = DataManager.GetUserEmailsData.sysEmails or {}
				elseif self.currentTab == 2 then
					self.listView.tableViewRenderer.list = DataManager.GetUserEmailsData.sysNotices or {}
				elseif self.currentTab == 3 then
					self.listView.tableViewRenderer.list = DataManager.GetUserEmailsData.userEmails or {}
				end
			end
		end
		if callback then
			callback()
		end
	end
	DataManager.GetUserEmailsData = nil
	local userEmailRequest = GetUserEmailsRequest.new({}, rpc.SendingPriority.kHigh)
	userEmailRequest:addEventListener(RequestNotifyEnum.GetUserEmailsSucceed, onGetMailsSuccess)
	userEmailRequest:start()
end

function EmailScene:refreshList()
	if self.listView then
		self:removeChild(self.listView)
		self.listView = nil
	end

	local maxCharPerLine = 20 -- 一行最多20个汉字
	local mailItemTag = 100
	EmailListViewRender = class(TableViewRenderer)
	function EmailListViewRender:ctor()
		self.list = {}
	end
	function EmailListViewRender:buildCell(container)
		local mailItem = nil
		if self.container.currentTab == 1 or self.container.currentTab == 2 then
			if self.container.batchDelete then
				mailItem = self.container.uiBuilder:build("list_item/email_del_sys_email_list_item")
				mailItem:getChildByName("email_control_select"):getChildByName("email_checked_sb"):setVisible(false)
				local tagTree = {email_list_item_sel_background = 104, email_control_select = {105, email_checked_sb = 201, email_no_checked_sb = 202}}
				setCCNodeTagTree(mailItem, tagTree)
			else
				mailItem = self.container.uiBuilder:build("list_item/email_show_sys_email_list_item")
				mailItem:getChildByName("email_btn_view_email"):getChildByName("txt_view_email"):getChildByName("txt"):setString(getTextByKey("mail_viewBtn"))
				mailItem:getChildByName("email_btn_view_email"):setTag(105)
			end
			local tagTree = {email_txt_list_item_sys_email_title = {101, txt=201}, email_txt_list_item_user_email_time = {102, txt=201}, email_icn_tixing_sb = 103}
			setCCNodeTagTree(mailItem, tagTree)
		else
			if self.container.batchDelete then
				mailItem = self.container.uiBuilder:build("list_item/email_del_user_email_list_item")
				mailItem:getChildByName("email_control_select"):getChildByName("email_checked_sb"):setVisible(false)
				local tagTree = {email_list_item_sel_background = 104, email_control_select = {105, email_checked_sb = 201, email_no_checked_sb = 202}}
				setCCNodeTagTree(mailItem, tagTree)
			else
				mailItem = self.container.uiBuilder:build("list_item/email_show_user_email_list_item")
				mailItem:getChildByName("email_btn_view_email"):getChildByName("txt_view_email"):getChildByName("txt"):setString(getTextByKey("mail_viewBtn"))
				mailItem:getChildByName("email_btn_view_email"):setTag(105)
			end
			local tagTree = {email_txt_list_item_user_email_title_R = {101, txt=201}, email_txt_list_item_user_email_time = {102, txt=201}, email_icn_tixing_sb=103}
			setCCNodeTagTree(mailItem, tagTree)
			mailItem:getChildByName("email_txt_list_item_user_email_title_L"):getChildByName("txt"):setString(getTextByKey("mail_userMailTitle1"))
			mailItem:getChildByName("email_txt_list_item_user_email_title_R"):getChildByName("txt"):setString(getTextByKey("mail_userMailTitle2"))
			local mailTitle = TextField:create("txt", nil, 32)
			mailTitle:setColor(ccc3(153, 51, 0))
			mailTitle:setAnchorPoint(ccp(0, 1))
			mailTitle:setPosition(ccp(120, -3))
			mailTitle:setTag(111)
			mailItem:addChild(mailTitle)
		end
		local mailText = TextField:create("txt", nil, 24, CCSizeMake(24*maxCharPerLine, 0))
        mailText:setColor(ccc3(0, 0, 0))
        mailText:setAnchorPoint(ccp(0, 1))
        mailText:setPosition(ccp(25, -52))
		mailText:setTag(110)
        mailItem:addChild(mailText)
        mailItem:getChildByName("email_list_item_sel_background"):setVisible(false)
        mailItem:setPosition(ccp(8, 160))
		mailItem:setTag(mailItemTag)
        container:addChild(mailItem)
	end
	function EmailListViewRender:setData(rawCocosObj, index)
		local mailItem = self:getChildByTag(rawCocosObj, mailItemTag)
		if self.container.currentTab == 1 then
			local titleText = ""
			local mailText = ""

			local mailIndex = #DataManager.GetUserEmailsData.sysEmails - index
			local mailData = DataManager.GetUserEmailsData.sysEmails[mailIndex]
			if mailData == nil then
				return
			end

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
			else
				--奖励邮件
				titleText = mailData.title
				mailText = mailData.content
			end

			setNodeText(mailItem:getChildByTag(101):getChildByTag(201), titleText)

			local beginTimeStr = TimeUtil.formatDate(mailData.receiveSeconds)
			setNodeText(mailItem:getChildByTag(102):getChildByTag(201), beginTimeStr)

			mailItem:getChildByTag(103):setVisible(not mailData.read)

			if #mailText > maxCharPerLine*3*2 then
				mailText = StringUtil.truncateUtf8String(mailText, maxCharPerLine*3*2) .. "..."
			end
			if self.container.batchDelete then
				setNodeText(mailItem:getChildByTag(110), mailText)
				mailItem:getChildByTag(104):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(201):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(202):setVisible(not self.container.selectList[mailIndex])
			else
				setNodeText(mailItem:getChildByTag(110), mailText)
			end
		elseif self.container.currentTab == 2 then
			local mailIndex = #DataManager.GetUserEmailsData.sysNotices - index
			local mailData = DataManager.GetUserEmailsData.sysNotices[mailIndex]
			if mailData == nil then
				return
			end
			--print("mailData = " .. tostringRich(mailData))
			local jsonData = table.deserialize(mailData.detail)
			local mailTitle = ""
			local mailText = ""
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
			setNodeText(mailItem:getChildByTag(101):getChildByTag(201), mailTitle)
			setNodeText(mailItem:getChildByTag(102):getChildByTag(201), EmailScene.getEmailTimeText(mailData.receiveTime))
			mailItem:getChildByTag(103):setVisible(not mailData.read)
			if #mailText > maxCharPerLine*3*2 then
				mailText = StringUtil.truncateUtf8String(mailText, maxCharPerLine*3*2) .. "..."
			end
			setNodeText(mailItem:getChildByTag(110), mailText)
			if self.container.batchDelete then
				mailItem:getChildByTag(104):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(201):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(202):setVisible(not self.container.selectList[mailIndex])
			end
		elseif self.container.currentTab == 3 then
			local mailIndex = #DataManager.GetUserEmailsData.userEmails - index
			local mailData = DataManager.GetUserEmailsData.userEmails[mailIndex]
			local textTitle = mailItem:getChildByTag(111)
			setNodeText(textTitle, mailData.senderName)
			setNodeText(mailItem:getChildByTag(110), mailData.content)
			mailItem:getChildByTag(101):getChildByTag(201):setPositionX(textTitle:getPositionX() + textTitle:getTextureRect().size.width - 207.4)
			setNodeText(mailItem:getChildByTag(102):getChildByTag(201), EmailScene.getEmailTimeText(mailData.sendTime))
			mailItem:getChildByTag(103):setVisible(not mailData.read)
			if self.container.batchDelete then
				mailItem:getChildByTag(104):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(201):setVisible(self.container.selectList[mailIndex])
				mailItem:getChildByTag(105):getChildByTag(202):setVisible(not self.container.selectList[mailIndex])
			end
		end
	end
	local function onListItemTouch(e)
		print("e.data = " .. tostringRich(e.data))
		if self.switchTab then
			return
		end
		local list = self.listView.tableViewRenderer.list
		local index = #list - e.data
		local mailItem = self.listView:cellAtIndex(e.data):getChildByTag(mailItemTag)
		if self.batchDelete then
			self.selectList[index] = not self.selectList[index]
			mailItem:getChildByTag(104):setVisible(self.selectList[index])
			mailItem:getChildByTag(105):getChildByTag(201):setVisible(self.selectList[index])
			mailItem:getChildByTag(105):getChildByTag(202):setVisible(not self.selectList[index])
			local selectAll = true
			for i = 1, #list do
				if not self.selectList[i] then
					selectAll = false
					break
				end
			end
			self:setSelectAllState(selectAll, false)
		else
			local function onRead(mailType, mailIndex)
				if mailType == 1 then
					--modified by zheng.che @ 2014-6-17
					local mailData = DataManager.GetUserEmailsData.sysEmails[mailIndex]

					if mailData.mailType == EmailScene.MAIL_TYPE_SYSEMAIL then
						--普通系统邮件
						if mailData and not mailData.read and mailData.sysEmailMetaId then
							local readRequest = ReadSysEmailRequest.new({sysEmailMetaId = mailData.sysEmailMetaId}, rpc.SendingPriority.kHigh)
							readRequest:start()
							mailData.read = true
						end
					else
						--奖励邮件
						EmailReadRewardEmailRequest.sendRequest(mailData.rewardEmailId, EmailReadRewardEmailRequest.onSucceedDefault, EmailReadRewardEmailRequest.onFailedDefault)
						mailData.read = true
					end
				elseif mailType == 2 then
					local mailData = DataManager.GetUserEmailsData.sysNotices[mailIndex]
					if mailData and not mailData.read and mailData.sysNoticeId then
						local readRequest = ReadSysNoticeRequest.new({sysNoticeId = mailData.sysNoticeId}, rpc.SendingPriority.kHigh)
						readRequest:start()
						mailData.read = true
					end
					local readRequest = Read
				elseif mailType == 3 then
					local mailData = DataManager.GetUserEmailsData.userEmails[mailIndex]
					if mailData and not mailData.read and mailData.userEmailId then
						local readRequest = ReadUserEmailRequest.new({userEmailId = mailData.userEmailId}, rpc.SendingPriority.kHigh)
						readRequest:start()
						mailData.read = true
					end
				end
				if mailType == self.currentTab and self.listView then
					local mailItem = self.listView:cellAtIndex(#self.listView.tableViewRenderer.list - mailIndex)
					if mailItem then
						mailItem:getChildByTag(mailItemTag):getChildByTag(103):setVisible(false)
					end
				end
				self:refreshEmailCount()
			end
			local function refresh()
				local function refreshView()
					self.listView:reloadData()
					self:refreshEmailCount()
				end
				self:refreshEmailData(refreshView)
			end
			local panel = EmailViewPanel:create(self, self.uiBuilder, self.currentTab, index, onRead, refresh, refresh)
			PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false, self)
		end
	end
	local render = EmailListViewRender.new(720, 170)
	render.container = self
	self.listView = TableView:create(render, 720, 740, mailItemTag, 105, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))
	self.listView:setPosition(ccp(0, 125))
	self.listView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch, self)
	self.listView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end
	self:addChild(self.listView)
	if self.currentTab == 1 then
		render.list = DataManager.GetUserEmailsData.sysEmails or {}
	elseif self.currentTab == 2 then
		render.list = DataManager.GetUserEmailsData.sysNotices or {}
	elseif self.currentTab == 3 then
		render.list = DataManager.GetUserEmailsData.userEmails or {}
	end
	self.listView:reloadData()
	self:refreshEmailCount()
end

function EmailScene.getEmailTimeText(time) -- static
	local diff = TimeUtil.getServerTimeSeconds() - time
	if diff >= 7*24*3600 or diff < 0 then
		local date = os.date("*t", time)
		return string.format("%.2d/%.2d %.2d:%.2d", date.month, date.day, date.hour, date.min)
	elseif diff < 60 then
		return getTextByKey("mail_timeSec", {sec = string.format("%d", diff)}) --"{sec}秒前"
	elseif diff < 3600 then
		return getTextByKey("mail_timeMin", {min = string.format("%d", math.floor(diff/60))}) --"{min}分钟前"
	elseif diff < 24*3600 then
		return getTextByKey("mail_timeHr", {hr = string.format("%d", math.floor(diff/3600))}) --"{hr}小时前"
	else
		return getTextByKey("mail_timeDay", {day = string.format("%d", math.floor(diff/(24*3600)))}) --"{day}天前"
	end
end
