--
-- UnionMemberListScene.lua
-- Author: zheng.che
-- Date: 2014-03-21 10:54:12
-- 军团成员列表场景
--
require "canon.panel.UnionApplierListPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

UnionMemberListTagEnum = {
  MEMBER_LIST = 1,
  APPLIER_LIST = 2,
  TARGET_LIST = 3,
}

local enter_animation_duration = 0.3

-------------------------------------------------------------------------------
-- 内部可用函数
-------------------------------------------------------------------------------

--点击成员列表
local function memberListTabButtonSelected(evt)
	local container = evt.context
	--成员列表
	local function onSucceed(requestEvent)
		--默认处理
		UnionGetMemberListRequest.onSucceedDefault(requestEvent)

		container:gotoMemberList()
	end

	UnionGetMemberListRequest.sendRequest(onSucceed, UnionGetMemberListRequest.onFailedDefault)

	--点成员的时候也要刷一下申请者列表
	if UnionManager.canAccessApplier(false) then
		--刷新申请者列表
		UnionGetApplierListRequest.sendRequest(UnionGetApplierListRequest.onSucceedDefault, UnionGetApplierListRequest.onFailedDefault)
	end
end

--点击申请者列表
local function applyerListTabButtonSelected(evt)
	local container = evt.context
	local function onSucceed(requestEvent)
		--默认处理
		UnionGetApplierListRequest.onSucceedDefault(requestEvent)

		container:gotoApplierList(requestEvent.data.sharkUnionAppliers or {})
	end
	UnionGetApplierListRequest.sendRequest(onSucceed, UnionGetApplierListRequest.onFailedDefault)
end

--点击返回
local function onBackBtnClick(evt)
	evt.context:back()
end

--点击全部拒绝
local function onRejectAllBtnClick(evt)
	local self = evt.context
	if self.selectedApplierList and (#self.selectedApplierList>=1) then
		--有数据
		
		local function onSucceed(requestEvent)
			--默认处理
			UnionRejectAllRequest.onSucceedDefault(requestEvent)

			--清空申请者数组
			self.selectedApplierList = {}
			self.tabChangeComponent.currentSelectedPanel.refreshSelf()
			self.refreshSelf()
		end
		UnionRejectAllRequest.sendRequest(onSucceed, UnionRejectAllRequest.onFailedDefault)
	end
end

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionMemberListScene = class(BaseUIScene)

function UnionMemberListScene:ctor()
end

-- self.argv.params.targetTabName 若非nil 将指定tab按钮文字 (将导致只出现一个按钮, 并且无切换功能)
-- self.argv.params.list 若非nil 将指定为显示的成员列表
function UnionMemberListScene:create(argv)
	local s = UnionMemberListScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionMemberListScene

  --当前显示中的列表内容(注意: 子panel可能读取)
  s.selectedApplierList = {}
  s:initScene()
  return s
end

function UnionMemberListScene:onInit()
	BaseUIScene.initBackGround(self)

	local function refreshSelf()
		self.ui:getChildByName("btn_refuseall"):getChildByName("btn"):setVisible(false)

		if self.argv.params.targetTabName == nil then
			--更新标签页显示状态
			if UnionManager.canAccessApplier(false) then
				self.uiGroup2:setVisible(true)
			else
				self.uiGroup2:setVisible(false)
			end

			--更新全部拒绝按钮是否置灰状态
			if self.selectedApplierList and (#self.selectedApplierList>=1) then
				--有数据
				self.ui:getChildByName("btn_refuseall"):getChildByName("btn"):setVisible(true)
				self.rejectAllBtn:setEnable(true)
			else
				self.rejectAllBtn:setEnable(false)
			end

			--更新角标
			if UnionManager.canAccessApplier(false) then
				--可以看到申请者列表 因此也可以看到申请数量角标
				self.tabButton2:setNum(UnionManager.getApplierNum())
			else
				self.tabButton2:setNum(0)
			end
		end
	end
	self.refreshSelf = refreshSelf

	local function onDelectApplier()
		--子面板点击拒绝成功后调用
		self.refreshSelf()
	end
	self.onDelectApplier = onDelectApplier

	--用于生成新panle
	local function onCreatePanel(aIndex)
		--这里的3个列表效果一样 只有内容不同
		if aIndex == UnionMemberListTagEnum.MEMBER_LIST then
			self.ui:getChildByName("btn_refuseall"):setVisible(false)
			self.ui:getChildByName("alpha_gray9_panel"):setVisible(true)
			self.ui:getChildByName("alpha_gray9_panel_examine"):setVisible(false)
			return UnionMemberListPanel:create(self, aIndex, nil)
		elseif aIndex == UnionMemberListTagEnum.APPLIER_LIST then
			self.ui:getChildByName("alpha_gray9_panel"):setVisible(false)
			self.ui:getChildByName("alpha_gray9_panel_examine"):setVisible(true)
			return UnionApplierListPanel:create(self, aIndex)
		elseif aIndex == UnionMemberListTagEnum.TARGET_LIST then
			self.ui:getChildByName("btn_refuseall"):setVisible(false)
			self.ui:getChildByName("alpha_gray9_panel"):setVisible(true)
			self.ui:getChildByName("alpha_gray9_panel_examine"):setVisible(false)
			return UnionMemberListPanel:create(self, aIndex, self.argv.params.list)
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("guild_mem_list_title")
	self:addChild(ui)
	self.ui = ui

	--静态文本

	--分页组件
	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)

	if self.argv.params.targetTabName == nil then
		--tab按钮
		self.uiGroup1 = ui:getChildByName("btn_guild_list")
		self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("union_members_label_name"))--军团成员
		self.tabButton1 = CanonButton:create(self.uiGroup1)
		self.tabButton1:addEventListener(Events.kStart, memberListTabButtonSelected, self)
		self.tabChangeComponent:addTab(self.tabButton1)

		self.uiGroup2 = ui:getChildByName("btn_guild_list2")
		self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("union_examine_label_name"))--审核
		self.tabButton2 = CanonButton:create(self.uiGroup2)
		self.tabButton2:addEventListener(Events.kStart, applyerListTabButtonSelected, self)
		self.tabChangeComponent:addTab(self.tabButton2)
	else
		--只显示一个tab 并且直接进入此tab
		ui:getChildByName("btn_guild_list2"):setVisible(false)

		self.uiGroup1 = ui:getChildByName("btn_guild_list")
		self.uiGroup1:getChildByName("txt"):setString(self.argv.params.targetTabName)--[]
		self.tabChangeComponent:addTab(self.tabButton1)
		self.tabChangeComponent:changeToPanelByIndex(UnionMemberListTagEnum.TARGET_LIST)
	end

	--其他按钮
	self.uiGroup3 = ui:getChildByName("r_click")
	self.backBtn = Button:create(self.uiGroup3)
	self.backBtn:addEventListener(Events.kStart, onBackBtnClick, self)

	self.uiGroup4 = ui:getChildByName("btn_refuseall")
	self.uiGroup4:getChildByName("txt"):setString(Localization:getInstance():getText("union_examine_refuse_all"))--全部拒绝
	self.rejectAllBtn = Button:create(self.uiGroup4)
	self.rejectAllBtn:addEventListener(Events.kStart, onRejectAllBtnClick, self)

	--侦听焦点变化
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	self.ui:getChildByName("alpha_gray9_panel"):setVisible(false)
	self.ui:getChildByName("alpha_gray9_panel_examine"):setVisible(false)
	self.ui:getChildByName("btn_refuseall"):setVisible(false)

	--初始显示内容移动到进场动画结束的地方了(nodeAnimationFinished)

	--职位更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.TITLE_UPDATE, self.refreshSelf, self)
	--军团申请者列表更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf, self)


	self.refreshSelf()

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	if self.argv.params.targetTabName == nil then
		--这个需要在普通模式进行
		if UnionManager.canAccessApplier(false) then
			--刷新成员列表
			UnionGetApplierListRequest.sendRequest(UnionGetApplierListRequest.onSucceedDefault, UnionGetApplierListRequest.onFailedDefault)
		end
	end
end

-----------------------------------------------内部接口------------------------------------------------------------

--显示成员列表
function UnionMemberListScene:gotoMemberList(dataList)
	self.tabChangeComponent:changeToPanelByIndex(UnionMemberListTagEnum.MEMBER_LIST)
end

--显示申请者列表
function UnionMemberListScene:gotoApplierList(dataList)
	self.selectedApplierList = dataList
	self.tabChangeComponent:changeToPanelByIndex(UnionMemberListTagEnum.APPLIER_LIST)

	self.ui:getChildByName("btn_refuseall"):setVisible(true)
	self.refreshSelf()
end

-----------------------------------------------外部接口------------------------------------------------------------

function UnionMemberListScene:setTableViewsEnabled(enabled)
	if self.tabChangeComponent.currentSelectedPanel then
		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
	end
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionMemberListScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionMemberListScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionMemberListScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()

		if self.argv.params.targetTabName == nil then
			--正常进入
			--设定初始显示的页面
			if self.argv.params.pageIndex == UnionMemberListTagEnum.APPLIER_LIST then
				self:gotoApplierList(self.argv.params.list)
			else
				self:gotoMemberList(self.argv.params.list)
			end
		else
			--指定内容进入
		end
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function UnionMemberListScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionMemberListScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionMemberListScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)

	--开始退出时加处理
	self.ui:getChildByName("alpha_gray9_panel"):setVisible(false)
	self.ui:getChildByName("alpha_gray9_panel_examine"):setVisible(false)
end

function UnionMemberListScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))

	--同时当前选择页也退出动画 并行进行
	self.tabChangeComponent:startPanelExit(nil)
end

function UnionMemberListScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function UnionMemberListScene:back()
	UnionManager.gotoUnionScene()
end

function UnionMemberListScene:dispose()
	--清除侦听
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.TITLE_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf)

	--清除不在显示列表的组件
	self.tabChangeComponent:dispose()
	self.tabChangeComponent = nil

	UnionMemberListScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------