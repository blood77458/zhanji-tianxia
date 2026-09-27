--
-- UnionColosseumScene.lua
-- Author: zheng.che
-- Date: 2014-05-26 18:41:06
-- 军团斗兽场建筑
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

UnionInfoTagEnum = {
  INFO_PANEL = 1,
  LIST_PANEL = 2,
}

local enter_animation_duration = 0.3

-------------------------------------------------------------------------------
-- 内部可用函数
-------------------------------------------------------------------------------

--点击返回
local function onBackBtnClick(evt)
	evt.context:back()
end

--焦点变化事件
local function onFocusChanged(evt)
	--print("onFocusChanged! evt.data == nil = " .. tostring(evt.data == nil))
	evt.context:setTableViewsEnabled(evt.data == nil)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionColosseumScene = class(BaseUIScene)

function UnionColosseumScene:ctor()
end

function UnionColosseumScene:create(argv)
	local s = UnionColosseumScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionColosseumScene

  s:initScene()
  return s
end

function UnionColosseumScene:onInit()
	BaseUIScene.initBackGround(self)

	--用于生成新panle
	local function onCreatePanel(aIndex)
		--这里的3个列表效果一样 只有内容不同
		if aIndex == UnionInfoTagEnum.INFO_PANEL then
			return UnionColosseumBossInfoPanel:create(self, self.ui:getChildByName("colosseum_challenge"))
		elseif aIndex == UnionInfoTagEnum.LIST_PANEL then
			return UnionColosseumBossListPanel:create(self, self.ui:getChildByName("table_challenge_list"))
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end

	local function refreshSelf()
		self.ui:getChildByName("guild_colosseuml_title"):getChildByName("txt_guild_21"):getChildByName("txt"):setString(UnionManager.getMyHistoryContribute())--[个人总贡献]
		self.ui:getChildByName("guild_colosseuml_title"):getChildByName("txt_guild_21_2"):getChildByName("txt"):setString(tostring(CalculationManager.calcComplex_getGemsNow()))--[金币]
		self.ui:getChildByName("guild_colosseuml_title"):getChildByName("txt_guild_22"):getChildByName("txt"):setString(tostring(DataManager.getCurrUser().coins))--[银币]
		self.ui:getChildByName("txt_guild_21_2"):getChildByName("txt"):setString(tostring(UnionManager.summonLeftTimes()))--[本周可召唤次数]

		if UnionManager.isInBossAttackState() then
			--boss存在
			self.tabChangeComponent:changeToPanelByIndex(UnionInfoTagEnum.INFO_PANEL)
		else
			--目前没有boss
			self.tabChangeComponent:changeToPanelByIndex(UnionInfoTagEnum.LIST_PANEL)
		end
	end
	self.refreshSelf = refreshSelf

	--目标时间到
	local function onCdComplete()
		--重置召唤次数
		UnionManager.setWeekCallNum(0)
		--重置倒计时
		self.cdLabelComponent:setTargetTime(UnionManager.getColosseumNextRefreshTimestamp())
		self.cdLabelComponent:start()
		--刷新显示
		self.refreshSelf()
	end
	self.onCdComplete = onCdComplete

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("colosseum_common")
	self:addChild(ui)
	self.ui = ui

	--默认子面板内容隐藏
	self.ui:getChildByName("colosseum_challenge"):setVisible(false)
	self.ui:getChildByName("table_challenge_list"):setVisible(false)

	--静态文本
	self.ui:getChildByName("txt_guild43"):getChildByName("txt"):setString(getTextByKey("union_monster_summon_building_upgrade_remind", {num1 = UnionManager.getUnionMonsterRefreshDay(), num2 = TimeUtil.formatTimeWithHM(UnionManager.getUnionMonsterRefreshHour()*3600)}))--每周{num1}的{num2}刷新次数，升级斗兽场可增加次数
	self.ui:getChildByName("guild_colosseuml_title"):getChildByName("txt_guild_54"):getChildByName("txt"):setString(UnionManager.getBuildingName(UnionManager.UNION_BUILDING_COLOSSEUM))--[等级]
	self.ui:getChildByName("guild_colosseuml_title"):getChildByName("txt_guild_20"):getChildByName("txt"):setString(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM))--军团斗兽场
	self.ui:getChildByName("txt_guild_21_1"):getChildByName("txt"):setString(tostring(UnionManager.getUnionWealth()))--[军团财富]
	if UnionManager.isBuildingMaxLevel(UnionManager.UNION_BUILDING_COLOSSEUM) then
		--已满级
		self.ui:getChildByName("lbl_guild_build_max"):setVisible(true)
		self.ui:getChildByName("lbl_guild2"):setVisible(false)
		self.ui:getChildByName("txt_guild_21_3"):setVisible(false)
	else
		--未达到满级
		self.ui:getChildByName("lbl_guild_build_max"):setVisible(false)
		self.ui:getChildByName("lbl_guild2"):setVisible(true)
		self.ui:getChildByName("txt_guild_21_3"):setVisible(true)
		self.ui:getChildByName("txt_guild_21_3"):getChildByName("txt"):setString(UnionManager.getBuildingUpgradeCost(UnionManager.UNION_BUILDING_COLOSSEUM))--[升级所需财富]
	end

	--其他按钮
	self.uiGroup3 = ui:getChildByName("guild_colosseuml_title"):getChildByName("r_click")
	self.backBtn = Button:create(self.uiGroup3)
	self.backBtn:addEventListener(Events.kStart, onBackBtnClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	self.tabChangeComponent = TabPanelChangeComponent.new(self.ui, onCreatePanel, nil, nil, nil)--容器选用self.ui 这样就不会层级过高了

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(nil, self.onTimeComplete)
	self.cdLabelComponent:setTargetTime(UnionManager.getColosseumNextRefreshTimestamp())
	self.cdLabelComponent:start()

	--设定时间说明
	local isEnable, isOpenTime = MaintenanceManager.isActivityOpen(UnionManager.getUnionMonsterSummonFeatureName())
	if not isOpenTime then
		--召唤时间不满足 显示说明
		self.ui:getChildByName("txt_guild_74"):getChildByName("txt"):setVisible(true)
		local timeTable = MaintenanceManager:getStartAndEndHourMinOfOneDay(UnionManager.getUnionMonsterSummonFeatureName())
		local startTime = TimeUtil.formatTimeWithHM(timeTable.beginHour * 3600 + timeTable.beginMin * 60)
		local endTime = TimeUtil.formatTimeWithHM(timeTable.endHour * 3600 + timeTable.endMin * 60)
		self.ui:getChildByName("txt_guild_74"):getChildByName("txt"):setString(getTextByKey("union_monster_summon_condition_times_remind", {num1 = startTime, num2 = endTime}))--每天{num1}至{num2}之间可以召唤怪兽
	else
		--可以召唤 不显示说明
		self.ui:getChildByName("txt_guild_74"):getChildByName("txt"):setVisible(false)
	end

	--调用父类接口
	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	--各种事件
	--军团斗兽场数据更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf, self)

	self.refreshSelf()
end

-----------------------------------------------内部接口------------------------------------------------------------

-----------------------------------------------外部接口------------------------------------------------------------

function UnionColosseumScene:setTableViewsEnabled(enabled)
	if self.tabChangeComponent and self.tabChangeComponent.currentSelectedPanel then
		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
	end
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionColosseumScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionColosseumScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionColosseumScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function UnionColosseumScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionColosseumScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionColosseumScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function UnionColosseumScene:startExitAnimation()
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

function UnionColosseumScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景接口------------------------------------------------------------

-- 退出到外层
function UnionColosseumScene:back()
	if UnionManager.isInUnion() then
		UnionManager.gotoUnionScene()
	else
		self:replaceScene(MainMenuScene)
	end
end

function UnionColosseumScene:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf)

	if self.tabChangeComponent then
		self.tabChangeComponent:dispose()
		self.tabChangeComponent = nil
	end

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	UnionColosseumScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------
function UnionColosseumScene.getBuildingTipNum()
	--当前有已召唤的怪兽，或者未分配的奖励时，建筑带角标提示
	if UnionManager.isInBossAttackState() then
		--boss袭来中
		return 1
	end
	if not UnionManager.getColosseumMonsterRewardDistributed() then
		--未分配
		return 1
	end
	return 0
end