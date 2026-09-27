-- UnionColosseumBattleResultPopPanel.lua
-- 2014-6-9 zheng.che
-- 军团斗兽场战场结算UI

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击确定
local function onConfirmClick(evt)
	print("onConfirmClick")
	--确定后跳转到军团斗兽场
	UnionManager.gotoUnionColosseumScene()
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionColosseumBattleResultPopPanel = class(Layer)

function UnionColosseumBattleResultPopPanel:ctor()
	self.container = nil
end

function UnionColosseumBattleResultPopPanel:create(container, tosendData)
	local s = UnionColosseumBattleResultPopPanel.new()
	s:initLayer(container, tosendData)
	return s
end

function UnionColosseumBattleResultPopPanel:initLayer(container, tosendData)
	UnionColosseumBattleResultPopPanel.super.initLayer(self)
    
	self.container = container
	self.tosendData = tosendData
	print("self.tosendData = " .. tostringRich(self.tosendData))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("battleResult_colosseum_over") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_result_message1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_contend_damage"))--造成伤害：
	self.panelUI:getChildByName("txt_result_message2"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_card_exp_obtain_txt"))--获得武将经验
	self.panelUI:getChildByName("txt_bossdamege4"):getChildByName("txt"):setString(self.tosendData.totalDamage)--$总伤害
	self.panelUI:getChildByName("txt_bossdamege5"):getChildByName("txt"):setString(self.tosendData.generalExp)--$武将经验

	--按钮
	local confirmButton = Button:create(self.panelUI:getChildByName("battleResult_btn_long_yellow"))
	self.panelUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(Localization:getInstance():getText("yes"))--确定
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function UnionColosseumBattleResultPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	UnionColosseumBattleResultPopPanel.super.dispose(self)
end

function UnionColosseumBattleResultPopPanel:setTableViewsEnabled(v)
end