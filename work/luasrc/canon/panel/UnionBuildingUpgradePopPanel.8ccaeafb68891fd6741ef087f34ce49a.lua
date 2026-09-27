--
-- UnionBuildingUpgradePopPanel.lua
-- Author: zheng.che
-- Date: 2014-03-27 16:11:27
-- 建筑升级界面
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local selectedText = ""

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
	print("onClose")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击确定
local function onConfirmClick(evt)
	print("onConfirmClick")
	local self = evt.context

	
	local function onSucceed(buildingId, requestEvent)
		--默认处理
		UnionBuildingUpgradeRequest.onSucceedDefault(buildingId, requestEvent)

		--成功后再关闭
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end

	UnionBuildingUpgradeRequest.sendRequest(self.buildingId, onSucceed, UnionBuildingUpgradeRequest.onFailedDefault)

	-- function onConfirm()
	-- end
	-- CanonMessageBox:Show(getTextByKey("union_building_upgrade_content", {num1 = UnionManager.getBuildingUpgradeCost(self.buildingId), name = UnionManager.getBuildingName(self.buildingId), num2 = UnionManager.getBuildingLevel(self.buildingId)+1}), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要花费{num1}军团财富将{name}升级到{num2}级吗？
end

--点击取消
local function onCancelClick(evt)
	print("onCancelClick")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionBuildingUpgradePopPanel = class(Layer)

function UnionBuildingUpgradePopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionBuildingUpgradePopPanel:create( container, buildingId )
	local s = UnionBuildingUpgradePopPanel.new()
	s:initLayer(container, buildingId)
	return s
end

function UnionBuildingUpgradePopPanel:initLayer(container, buildingId)
	UnionBuildingUpgradePopPanel.super.initLayer(self)
    
	self.container = container
	self.buildingId = buildingId

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_upgrade") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_announcement_title"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_upgrade_title", {name = UnionManager.getBuildingName(self.buildingId)}))--升级{name}
	self.panelUI:getChildByName("txt_upgrade_info"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_upgrade_content", {num1 = UnionManager.getBuildingUpgradeCost(self.buildingId), name = UnionManager.getBuildingName(self.buildingId), num2 = UnionManager.getBuildingLevel(self.buildingId)+1}))--你确认要花费{num1}军团财富将{name}升级到{num2}级吗？
	self.panelUI:getChildByName("txt_guild_41"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_upgrade_need_wealth_text"))--升级所需：
	self.panelUI:getChildByName("txt_guild_41_2"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_upgrade_own_wealth_text"))--已有财富：
	self.panelUI:getChildByName("txt_guild_gold"):getChildByName("txt"):setString(UnionManager.getBuildingUpgradeCost(self.buildingId))--$升级所需
	self.panelUI:getChildByName("txt_guild_gold_2"):getChildByName("txt"):setString(UnionManager.getUnionWealth())--$当前财富

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("btn_sure"))
	self.panelUI:getChildByName("btn_sure"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	local cancelButton = Button:create(self.panelUI:getChildByName("btn_cancel"))
	self.panelUI:getChildByName("btn_cancel"):getChildByName("txt"):setString(Localization:getInstance():getText("cancel"))--取消
	cancelButton:addEventListener(Events.kStart,onCancelClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function UnionBuildingUpgradePopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	UnionBuildingUpgradePopPanel.super.dispose(self)
end

function UnionBuildingUpgradePopPanel:setTableViewsEnabled(v)
end