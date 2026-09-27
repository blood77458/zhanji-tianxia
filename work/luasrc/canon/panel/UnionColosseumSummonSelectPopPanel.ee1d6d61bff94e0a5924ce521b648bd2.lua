--UnionColosseumSummonSelectPopPanel.lua
--zheng.che 2014-6-6
--军团斗兽场选择召唤类型窗口

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
	print("onClose")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击至尊召唤
local function onGoldClick(evt)
	print("onGoldClick")
	local self = evt.context
	if CanonGoodIcon.getResourceNum(ResourceEnum.GEMS) >= UnionManager.getRewardDoubleGemCost() then
		--钱够
		UnionColosseumSummonRequest.sendRequest(self.monsterData.id, UnionManager.SUMMON_DOUBLE, UnionColosseumSummonRequest.onSucceedDefault, UnionColosseumSummonRequest.onFailedDefault)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	else
		--不够 请充值
		local scene = Director:mgr():run()
		local function replaceSceneFunc()
		end
		local aPanel = AssistantMessageBoxPanel:create( scene, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = replaceSceneFunc} )
		scene:addChild(aPanel)
		aPanel:scaleIn()
	end
end

--点击普通召唤
local function onNormalClick(evt)
	print("onNormalClick")
	local self = evt.context
	UnionColosseumSummonRequest.sendRequest(self.monsterData.id, UnionManager.SUMMON_NORMAL, UnionColosseumSummonRequest.onSucceedDefault, UnionColosseumSummonRequest.onFailedDefault)
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionColosseumSummonSelectPopPanel = class(Layer)

function UnionColosseumSummonSelectPopPanel:ctor()
	self.container = nil
	self.monsterData = nil
end

function UnionColosseumSummonSelectPopPanel:create( container, monsterData)
	local s = UnionColosseumSummonSelectPopPanel.new()
	s:initLayer(container, monsterData)
	return s
end

function UnionColosseumSummonSelectPopPanel:initLayer(container, monsterData)
	UnionColosseumSummonSelectPopPanel.super.initLayer(self)
    
	self.container = container
	self.monsterData = monsterData

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_colosseum_model") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_guild_72"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_reward_double_remind"))--奖励翻倍
	self.panelUI:getChildByName("txt_guild_71"):getChildByName("txt"):setString(UnionManager.getRewardDoubleGemCost())--$翻倍所需金币

	--描边
	local infoLabelFlash = self.panelUI:getChildByName("txt_modelchoose_guild_info"):getChildByName("txt")
	infoLabelFlash:setString(getTextByKey("union_monster_summon_type_remind"))--团长！请选择召唤模式
	infoLabelFlash:setColor(ccc3(255, 255, 110))
	infoLabelFlash:setAroundColor(ccc3(50, 10, 10))

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local goldButton = Button:create(self.panelUI:getChildByName("btn_goldcreate"))
	self.panelUI:getChildByName("btn_goldcreate"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_summon_button2"))--至尊
	goldButton:addEventListener(Events.kStart,onGoldClick, self)

	local normalButton = Button:create(self.panelUI:getChildByName("btn_slivercreate"))
	self.panelUI:getChildByName("btn_slivercreate"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_summon_button"))--召唤
	normalButton:addEventListener(Events.kStart,onNormalClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)
end

function UnionColosseumSummonSelectPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	UnionColosseumSummonSelectPopPanel.super.dispose(self)
end

function UnionColosseumSummonSelectPopPanel:setTableViewsEnabled(v)
end