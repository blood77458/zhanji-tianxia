-- Activity_DoubleRewardLayer.lua
-- 2014-10-13
-- zheng.che
-- 多倍奖励活动

--多倍相关修改(搜索用)关键字 -> DOUBLE_REWARD_MODIFY

require "canon.request.GainPraiseRewardRequest"
require "canon.request.GetRecordPraiseIdRequest"
require "canon.luajava.CanonEnvInjector"
require "canon.customUI.CanonGoodIcon"

--点击闯关
local function onBtn1(evt)
	local self = evt.context
	local argv = {enterScene="Activity_DoubleRewardLayer",returnScene="Activity_DoubleRewardLayer",params={notReset=false}}
	self.container:replaceScene(CityMainScene, argv)
end
--点击过关斩将
local function onBtn2(evt)
	local self = evt.context
	self.container:replaceScene(ChallengeEntersScene)
end
--点击武道会
local function onBtn3(evt)
	local self = evt.context
	self.container:replaceScene(CompeteScene)
end
--点击抢夺神兽碎片
local function onBtn4(evt)
	local self = evt.context

	if DataManager.getCurrUser().level < MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel then
		SuspensionLabel:showContent(self.container, Localization:getInstance():getText("module_needLevel", {num = MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel}))
		do return end
	end

	local function doPrerationSucceed(fragmentsInfo)
		local argv = {enterScene="Activity_DoubleRewardLayer",returnScene="Activity_DoubleRewardLayer",params={fragmentsInfo=fragmentsInfo}}
		self.container:replaceScene(BeastScene, argv)
	end
	BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed)
end
--点击竞技场战斗
local function onBtn5(evt)
	local self = evt.context
	self.container:replaceToArena()
end

--点击图鉴
local function onBtn6(evt)
	local self = evt.context
	local argv = {enterScene="Activity_DoubleRewardLayer",returnScene="Activity_DoubleRewardLayer", params = {ignoreAction = true , secretaryTips = 0,CellNum = 3}}
    Director:sharedDirector():replaceScene(AchievementScene:create(argv))
end


---------------------------------------------------------------------------------------------------------

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_DoubleRewardLayer = class(Layer)

---------------------------------------------------------------------------------------------------------

--配置编号定义
Activity_DoubleRewardLayer.MOUDLE_CHAPTERS 	= 1--闯关
Activity_DoubleRewardLayer.MOUDLE_EILTE 	= 2--过关斩将
Activity_DoubleRewardLayer.MOUDLE_PK 		= 3--武道会
Activity_DoubleRewardLayer.MOUDLE_BEAST 	= 4--神兽碎片
Activity_DoubleRewardLayer.MOUDLE_ARENA 	= 5--竞技场

--是否进入过当前界面
local _hasEnterd = false

---------------------------------------------------------------------------------------------------------

function Activity_DoubleRewardLayer:ctor()
  self.container = nil
end

function Activity_DoubleRewardLayer:create( container )
  self.container = container
  local s = Activity_DoubleRewardLayer.new()
  s:initLayer()
  return s
end

function Activity_DoubleRewardLayer:enable()
	if not DataManager.GameMetaData.multiplicityRewardConfig then
		print("multiplicityRewardConfig is nil")
	return false
	end
	--print("Activity_DoubleRewardLayer.getFeatureName() = " .. tostringRich(Activity_DoubleRewardLayer.getFeatureName()))
	local isEnable = MaintenanceManager.isActivityOpen(Activity_DoubleRewardLayer.getFeatureName())
	if SystemManager.debug then
		print("Activity_DoubleRewardLayer isEnable = " .. tostringRich(isEnable))
	end
	return isEnable
end 

function Activity_DoubleRewardLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_DoubleRewardLayer:dispose()
  Activity_DoubleRewardLayer.super.dispose(self)
end

function Activity_DoubleRewardLayer:initLayer()
    Activity_DoubleRewardLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/task_activity.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("task_rewardx2")
	self:addChild(self.mainUI)

	--更改角标条件
	_hasEnterd = true
	--更新角标数
	self.container:resetTipInfoForActivity("Activity_DoubleSilver")

	--获得活动时间
	local timeTable = MaintenanceManager:getStartAndEndTime(Activity_DoubleRewardLayer.getFeatureName());

	--固定文字
	self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("activity_doublereward_txt1"))--点击下方图标立即前往
	self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("activity_doublereward_time", {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day}))--活动时间：{month1}月{day1}日—{month2}月{day2}日

	--按钮
	self.btn1 = Button:create(self.mainUI:getChildByName("bg_daily_achievement_task_tocon"))--闯关
	self.btn2 = Button:create(self.mainUI:getChildByName("bg_achievement_task_elite"))--过关斩将
	self.btn3 = Button:create(self.mainUI:getChildByName("bg_rewardx2_task_pk"))--武道会
	self.btn4 = Button:create(self.mainUI:getChildByName("bg_rewardx2_task_debris"))--抢夺神兽碎片
	self.btn5 = Button:create(self.mainUI:getChildByName("bg_rewardx2_task_competitive"))--竞技场战斗
    self.btn6 = Button:create(self.mainUI:getChildByName("bg_rewardx2_task_collectCard"))--图鉴
	self.btn1:addEventListener(Events.kStart, onBtn1, self)
	self.btn2:addEventListener(Events.kStart, onBtn2, self)
	self.btn3:addEventListener(Events.kStart, onBtn3, self)
	self.btn4:addEventListener(Events.kStart, onBtn4, self)
	self.btn5:addEventListener(Events.kStart, onBtn5, self)
	self.btn6:addEventListener(Events.kStart, onBtn6, self)
end

----------------------------------------------------------------------------------------------------------------------------

function Activity_DoubleRewardLayer.clear()
	_hasEnterd = false
end

function Activity_DoubleRewardLayer.getTipNum()
	if not Activity_DoubleRewardLayer:enable() then
		--活动未开启
		return 0
	end

	if _hasEnterd then
		--打开过界面
		return 0
	end
	return 1
end

--获得配置
function Activity_DoubleRewardLayer.getMetas()
	--print("metas = " .. tostringRich(metas))
	return DataManager.GameMetaData.multiplicityRewardConfig
end

--获得活动开关名称
function Activity_DoubleRewardLayer.getFeatureName()
	local metas = Activity_DoubleRewardLayer.getMetas()
	if not metas then
		--防崩
		return ""
	end
	return metas.featureName
end

--获得多倍奖励配置 list
-- <bean desc="多倍奖励活动配置">
-- 	<property code="silverType" type="int" desc="模块类型" />
-- 	<property code="silverMultiple" type="float" desc="倍数" />
-- 	<property code="resourceType" type="int" desc="影响属性" />
-- 	<property code="open" type="int" desc="是否开启" />
-- </bean>
function Activity_DoubleRewardLayer.getDoubleSilversList()
	local metas = Activity_DoubleRewardLayer.getMetas()
	--print("metas = " .. tostringRich(metas))
	if not metas then
		--防崩
		return {}
	end
	return metas.doubleSilvers or {}
end

--获得奖励倍数
--metaId 模块类型id
function Activity_DoubleRewardLayer.getRewardMultipleById(typeId)
	--print("getRewardMultipleById! typeId = " .. tostringRich(typeId))
	local doubleMetaList = Activity_DoubleRewardLayer.getDoubleSilversList()
	for k,v in ipairs(doubleMetaList) do
		if v.silverType == typeId then
			return getFloatNumber(v.silverMultiple)
		end
	end
	return 0
end

--获得奖励属性类型
--metaId 模块类型id
function Activity_DoubleRewardLayer.getRewardItemTypeById(typeId)
	--print("getRewardMultipleById! typeId = " .. tostringRich(typeId))
	local doubleMetaList = Activity_DoubleRewardLayer.getDoubleSilversList()
	for k,v in ipairs(doubleMetaList) do
		if v.silverType == typeId then
			return v.resourceType
		end
	end
	return ResourceEnum.COIN
end

--获得奖励是否开启
--metaId 模块类型id
function Activity_DoubleRewardLayer.getRewardEnableById(typeId)
	if not Activity_DoubleRewardLayer:enable() then
		return false
	end

	--print("getRewardEnableById! typeId = " .. tostringRich(typeId))
	local doubleMetaList = Activity_DoubleRewardLayer.getDoubleSilversList()
	--print("getRewardEnableById! doubleMetaList = " .. tostringRich(doubleMetaList))
	for k,v in ipairs(doubleMetaList) do
		if v.silverType == typeId then
			--print("return! v.open = " .. tostringRich(v.open))
			return (v.open == 1)
		end
	end
	return false
end