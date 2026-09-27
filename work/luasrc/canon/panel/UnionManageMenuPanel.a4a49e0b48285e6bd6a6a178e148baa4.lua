--
-- UnionManageMenuPanel.lua
-- Author: zheng.che
-- Date: 2014-03-24 15:39:06
-- 管理菜单
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击军团宣言
local function onChangeDeclarationBtnCLick(evt)
	scene = Director:mgr():run()
	scene.targetInfoPanel = UnionChangeDeclarationPopPanel:create(evt.context)
	PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)

	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击成员审核
local function onAppliersBtnCLick(evt)
	UnionManager.gotoUnionMemberScene(UnionMemberListTagEnum.APPLIER_LIST)

	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击解散军团/撤销解散
local function onDissolveBtnCLick(evt)
	local self = evt.context
	if UnionManager.isDissolving() then
		--当前解散中
		function onDissoveSucceed(event)
			UnionCancelDissolveRequest.onSucceedDefault(event)
			self.refreshSelf()
		end
		UnionCancelDissolveRequest.sendRequest(onDissoveSucceed, UnionCancelDissolveRequest.onFailedDefault)
	else
		--当前不在解散中
		if UnionManager.canDissolveUnion(true) then
			--可以解散
			function onConfirm()
				function onCancelDissoveSucceed(event)
					UnionDissolveRequest.onSucceedDefault(event)
					self.refreshSelf()
				end
				UnionDissolveRequest.sendRequest(onCancelDissoveSucceed, UnionDissolveRequest.onFailedDefault)
			end
			CanonMessageBox:Show(getTextByKey("union_dissolve_remind_final"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要解散军团吗？军团解散后将被清除
		end
	end

end
------------------------------------------------------------------------------------------------------

UnionManageMenuPanel = class(Layer)

function UnionManageMenuPanel:ctor()
	self.container = nil
end

function UnionManageMenuPanel:create( container )
	local s = UnionManageMenuPanel.new()
	s:initLayer(container)
	return s
end

function UnionManageMenuPanel:initLayer(container)
	UnionManageMenuPanel.super.initLayer(self)
    
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_list_other") 

	self:addChild(self.panelUI)

	function refreshSelf()
		if UnionManager.isDissolving() then
			--解散中
			self.panelUI:getChildByName("btn_guild_option3"):getChildByName("txt"):setString(Localization:getInstance():getText("union_dissolve_give_up_button"))--撤销解散军团

			self.panelUI:getChildByName("txt_guild_36"):setVisible(true)

			self.cdLabelComponent:setTargetTime(UnionManager.getMyDissolvedSeconds())
			self.cdLabelComponent:start()
		else
			--不在解散中
			self.panelUI:getChildByName("btn_guild_option3"):getChildByName("txt"):setString(Localization:getInstance():getText("union_dissolve_button"))--解散军团

			self.panelUI:getChildByName("txt_guild_36"):setVisible(false)

			self.cdLabelComponent:stop()
		end

		--更新角标
		if UnionManager.canAccessApplier(false) then
			--可以看到申请者列表 因此也可以看到申请数量角标
			self.btn2:setNum(UnionManager.getApplierNum())
		else
			self.btn2:setNum(0)
		end
	end
	self.refreshSelf = refreshSelf

	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		self.panelUI:getChildByName("txt_guild_36"):getChildByName("txt"):setString(Localization:getInstance():getText("union_dissolve_last_time_remind", {num = formatedTimeStr}))--{num1}:{num2}:{num3}后军团解散
	end
	self.onTimeTick = onTimeTick

	function onTimeComplete()
		self.refreshSelf()
		UnionManager.gotoUnionListScene()--直接回军团列表场景
	end
	self.onTimeComplete = onTimeComplete

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local btnDisplay1 = self.panelUI:getChildByName("btn_guild_option1")
	btnDisplay1:getChildByName("txt"):setString(Localization:getInstance():getText("union_declaration_text_key"))--军团宣言
	local btn1 = CanonButton:create(btnDisplay1)
	btn1:addEventListener(Events.kStart, onChangeDeclarationBtnCLick, self)

	local btnDisplay2 = self.panelUI:getChildByName("btn_guild_option2")
	btnDisplay2:getChildByName("txt"):setString(Localization:getInstance():getText("union_player_enter_examine_button"))--成员审核
	self.btn2 = CanonButton:create(btnDisplay2)
	self.btn2:addEventListener(Events.kStart, onAppliersBtnCLick, self)

	local btnDisplay3 = self.panelUI:getChildByName("btn_guild_option3")
	local btn3 = CanonButton:create(btnDisplay3)
	btn3:addEventListener(Events.kStart, onDissolveBtnCLick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
	--军团申请者列表更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf, self)

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)

	self.refreshSelf()

	if UnionManager.canAccessApplier(false) then
		--刷新申请者列表
		UnionGetApplierListRequest.sendRequest(UnionGetApplierListRequest.onSucceedDefault, UnionGetApplierListRequest.onFailedDefault)
	end
end

function UnionManageMenuPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf)

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	UnionManageMenuPanel.super.dispose(self)
end

function UnionManageMenuPanel:setTableViewsEnabled(v)
end