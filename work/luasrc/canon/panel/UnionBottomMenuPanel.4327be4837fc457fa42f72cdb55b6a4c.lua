--
-- UnionBottomMenuPanel.lua
-- Author: zheng.che
-- Date: 2014-03-14 17:01:18
-- 军团底部菜单
--

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.UnionChatContainerPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 848
local table_posX = 12
local table_posY = 115
local item_width = 692
local item_height = 183

--点击管理
local function onManageBtnlick(evt)
	--print("onManageBtnlick")
	local scene = Director:mgr():run()

	local panel = UnionManageMenuPanel:create(scene)
	scene.targetInfoPanel = panel
	PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false , scene)
end

--点击成员
local function onMemberBtnlick(evt)
	--print("onMemberBtnlick")
	UnionManager.gotoUnionMemberScene(UnionMemberListTagEnum.MEMBER_LIST)
end

--点击聊天
local function onChatBtnlick(evt)
	--print("onChatBtnlick")
  --[[
	local scene = Director:mgr():run()
  local chatPanel = UnionChatContainerPanel:create(scene)
  scene:addChild(chatPanel)
  chatPanel:scaleIn()
  ]]
  local scene = Director:mgr():run()
  local chatPanel = UnionChatContainerPanel:create(scene)
  PopoutManager:sharedManager():popout(chatPanel, kPopoutDir.kScale, true, false , scene)

  evt.context.chatBtn:setShined(ChatManager.hasUnreadChat())
end

--点击动态
local function onNewsBtnlick(evt)
	--print("onNewsBtnlick")
	local scene = Director:mgr():run()
	UnionManager.gotoUnionInfomationScene()
end

--点击返回
local function onBackBtnlick(evt)
	--print("onBackBtnlick")

	--先取消侦听 再退出
	NotificationManager:removeEventListener("SYSTEM_BACK_KEY_CLICK", evt.context.onSystemBackClick)

	local scene = Director:mgr():run()
	scene:back()
end

UnionBottomMenuPanel = class(Layer)

function UnionBottomMenuPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionBottomMenuPanel.create( container )
	local s = UnionBottomMenuPanel.new()
	s:initLayer(container)
	return s
end

function UnionBottomMenuPanel:initLayer(container)
	UnionBottomMenuPanel.super.initLayer(self)
	self.container = container
	self.dataList = {}

	local function refreshSelf()
		--按钮闪烁
		self.chatBtn:setShined(ChatManager.hasUnreadChat())

		local leftX = self.manageBtnDisplay:getPositionX()
		local len = self.backBtnDisplay:getPositionX() - leftX
		if not UnionManager.canManageUnion() then
			--不能管理军团 隐藏管理按钮
			self.manageBtnDisplay:setVisible(false)

			self.memberBtnDisplay:setPositionX(leftX)
			self.chatBtnDisplay:setPositionX(leftX + len/3)
			self.newsBtnDisplay:setPositionX(leftX + len*2/3)
		else
			--正常显示位置
			self.manageBtnDisplay:setVisible(true)

			self.manageBtnDisplay:setPositionX(leftX)
			self.memberBtnDisplay:setPositionX(leftX + len/4)
			self.chatBtnDisplay:setPositionX(leftX + len*2/4)
			self.newsBtnDisplay:setPositionX(leftX + len*3/4)
		end

		--管理按钮闪烁
		if UnionManager.canAccessApplier(false) then
			if UnionManager.getApplierNum() > 0 then
				--有申请者
				self.manageBtn:setShined(true)
			else
				--无申请者
				self.manageBtn:setShined(false)
			end
		else
			self.manageBtn:setShined(false)
		end
	end
	self.refreshSelf = refreshSelf

	--接收到新聊天消息
	local function refreshChatShine(evt)
		self.refreshSelf()
	end
	self.refreshChatShine = refreshChatShine

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	self.builder.useArtLabelTTF = true
	self.panelUi = self.builder:build("layer/shouye_home_menu_bottom")

	self:addChild(self.panelUi)

	self.manageBtnDisplay = self.panelUi:getChildByName("btn_home_manage")
	self.manageBtn = Button:create(self.manageBtnDisplay)
	self.manageBtn:addEventListener(Events.kStart, onManageBtnlick, self)
	
	self.memberBtnDisplay = self.panelUi:getChildByName("btn_home_member")
	self.memberBtn = Button:create(self.memberBtnDisplay)
	self.memberBtn:addEventListener(Events.kStart, onMemberBtnlick, self)
	
	self.chatBtnDisplay = self.panelUi:getChildByName("btn_home_chat")
	self.chatBtn = Button:create(self.chatBtnDisplay)
	self.chatBtn:addEventListener(Events.kStart, onChatBtnlick, self)
	
	self.newsBtnDisplay = self.panelUi:getChildByName("btn_home_news")
	self.newsBtn = Button:create(self.newsBtnDisplay)
	self.newsBtn:addEventListener(Events.kStart, onNewsBtnlick, self)
	
	self.backBtnDisplay = self.panelUi:getChildByName("btn_home_back")
	self.backBtn = Button:create(self.backBtnDisplay)
	self.backBtn:addEventListener(Events.kStart, onBackBtnlick, self)

	--事件接收
	NotificationManager:addEventListener(ChatManager.CHAT_MESSAGE_SHOWED,self.refreshChatShine, self)
	NotificationManager:addEventListener(ChatManager.CHAT_TAG_VIEWED,self.refreshChatShine, self)
	--职位更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.TITLE_UPDATE, self.refreshSelf, self)
	--军团申请者列表更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf, self)

	--注册系统返回按钮
	
	self.onSystemBackClick = function()
		--registerBackKey("uniontBaseUIBackBt", self.backBtn)
		onBackBtnlick({context = self})
	end

	self.onActionFinished = function()
		NotificationManager:addEventListener("SYSTEM_BACK_KEY_CLICK", self.onSystemBackClick)
	end

	
	NotificationManager:addEventListener("enterActionFinished", self.onActionFinished)


	self.refreshSelf()

	--其他初始化信息获得
	if UnionManager.canAccessApplier(false) then
		--刷新申请者列表
		UnionGetApplierListRequest.sendRequest(UnionGetApplierListRequest.onSucceedDefault, UnionGetApplierListRequest.onFailedDefault)
	end
end

function UnionBottomMenuPanel:dispose()
	--unregisterBackKey("uniontBaseUIBackBt")
	NotificationManager:removeEventListener("SYSTEM_BACK_KEY_CLICK", self.onSystemBackClick)
	NotificationManager:removeEventListener("enterActionFinished", self.onActionFinished)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.TITLE_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf)
	
	NotificationManager:removeEventListener(ChatManager.CHAT_MESSAGE_SHOWED, self.refreshChatShine)
	NotificationManager:removeEventListener(ChatManager.CHAT_TAG_VIEWED, self.refreshChatShine)

	UnionBottomMenuPanel.super.dispose(self)
end