-- Activity_ConsumeRewardsLayer.lua
-- 2015-1-13
-- zheng.che
-- 多重好礼/充值换孙坚活动面板

require "canon.request.ConsumeRewardGetInfoRequest"
require "canon.request.ConsumeRewardGainRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--去充值按钮
local function onBtn1(evt)
	local self = evt.context

	self.container:replaceScene(ShopScene, {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",selectPanelName="Activity_ConsumeRewards", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
end

--询问按钮
local function onBtn2(evt)
	local self = evt.context

	local timeStrTable = {}
	local rewardConfigList = Activity_ConsumeRewardsLayer.getRewardList()

	--充值期间
	local timeTableRecharge = MaintenanceManager:getStartAndEndTime(Activity_ConsumeRewardsLayer.getRechargeFeatureName())
	timeStrTable.year1 = timeTableRecharge[1].year
	timeStrTable.month1 = timeTableRecharge[1].month
	timeStrTable.day1 = timeTableRecharge[1].day
	timeStrTable.time1 = timeTableRecharge[1].time

	timeStrTable.year2 = timeTableRecharge[2].year
	timeStrTable.month2 = timeTableRecharge[2].month
	timeStrTable.day2 = timeTableRecharge[2].day
	timeStrTable.time2 = timeTableRecharge[2].time

	--完整活动期间(用来得到总截止时间)
	local timeTable = MaintenanceManager:getStartAndEndTime(Activity_ConsumeRewardsLayer.getFeatureName())
	timeStrTable.year3 = timeTable[2].year
	timeStrTable.month3 = timeTable[2].month
	timeStrTable.day3 = timeTable[2].day
	timeStrTable.time3 = timeTable[2].time

	for i, v in ipairs(rewardConfigList) do
		timeStrTable["num"..i] = v.requiredGold
		timeStrTable["names"..i] = CanonGoodIcon.getGoodNamesStrByRewards(v.rewards, getTextByKey("activity_consumeRewards_dot"), nil)--、
	end
	--活动时间：{year1}年{month1}月{day1}日{time1}——{year2}年{month2}月{day2}日\n
	--领奖截止时间：{year3}年{month3}月{day3}日{time3}\n
	--活动期间，只要主公充值累积达到一定金额，就可以领取丰厚的奖励哦~\n
	--充值{num1}金币可获得：{names1}\n
	--充值{num2}金币可获得：{names2}\n
	--充值{num3}金币可获得：{names3}\n
	--充值{num4}金币可获得：{names4}\n
	--充值{num5}金币可获得：{names5}\n
	--充值{num6}金币可获得：{names6}
	local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("activity_consumeRewards_help",timeStrTable))--主公每天都可以前来许愿池，许愿获得大量银币哦~\n主公每天有两次免费许愿的机会，之后可以使用金币继续许愿。
	self.container:addChild(aInfoPanel)
	aInfoPanel:scaleIn()

	self.container:setTableViewsEnabled(false)
end

---------------------------------------------------------------------------------------------------------

Activity_ConsumeRewardsLayer = class(Layer)

--是否停留在此界面直到活动已结束
Activity_ConsumeRewardsLayer.timeIsOver = false

---------------------------------------------------------------------------------------------------------

function Activity_ConsumeRewardsLayer:ctor()
  self.container = nil
end

function Activity_ConsumeRewardsLayer:create( container )
  self.container = container
  local s = Activity_ConsumeRewardsLayer.new()
  s:initLayer()
  return s
end

function Activity_ConsumeRewardsLayer:enable()
	if not Activity_ConsumeRewardsLayer.getConfig() then
		print("activityConsumeRewardConfig is nil")
		return false
	end
	--print("Activity_ConsumeRewardsLayer.getFeatureName() = " .. tostringRich(Activity_ConsumeRewardsLayer.getFeatureName()))
	local isEnable = MaintenanceManager.isActivityOpen(Activity_ConsumeRewardsLayer.getFeatureName())
	if SystemManager.debug then
		print("Activity_ConsumeRewardsLayer isEnable = " .. tostringRich(isEnable))
	end
	return isEnable
end 

function Activity_ConsumeRewardsLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_ConsumeRewardsLayer:initLayer()
    Activity_ConsumeRewardsLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity12")
	self:addChild(self.mainUI)

	-----------------------------------------------------------------------------刷新操作

	--刷新自身显示
	local function refreshSelf()
		self.listView:refresh()
	end
	self.refreshSelf = refreshSelf

	-----------------------------------------------------------------------------列表小格操作

	--点击里面的按钮
	local function onClickCellBtn(evt)
		local cell = evt.context
		if cell.data then
			local function onAfterSucceed(requestEvent)
				--更新角标数
				self.container:resetTipInfoForActivity("Activity_ConsumeRewards")
				--刷新显示
				self.refreshSelf()
			end
			ConsumeRewardGainRequest.sendRequestDefalut(cell.data.id, onAfterSucceed)
		end
	end

	--点击里面的图标
	local function onClickCellIcon(evt)
		local cell = evt.context
		--显示获得的奖励
	    local scene = Director:mgr():run()
		local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = cell.data.rewards, rewardTitle = getTextByKey("activity_day_text5")} )--礼包
		scene:addChild(aRewardPanel)
		aRewardPanel:scaleIn()
	end

	--显示小格
	-- cell.displayInited 表示显示组件已初始化
	function onCellDataSet(cell)
		if cell.display and cell.data then
			if not cell.displayInited then
				--固定内容
				cell.display:getChildByName("txt_chargeto1_s"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_charging1"))--充值
				cell.display:getChildByName("txt_chargeto3_s"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_charging3"))--金币
				cell.display:getChildByName("txt_chargeto_s"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_charging4"))--可领取

				cell.display:getChildByName("txt_chargeto2_s"):getChildByName("txt"):setString(cell.data.requiredGold)--[所需金币数量]

				--设置可见性
				for i = 1, 100, 1 do
					if not cell.display:getChildByName("icon_prop_" .. i) then
						break
					end

					cell.display:getChildByName("icon_prop_" .. i):setVisible(false)

					local btnIndex = math.floor((i-1)/2) + 1
					cell.display:getChildByName("btn_c" .. btnIndex .. "get"):setVisible(false)
				end

				local useIconDisplay = cell.display:getChildByName("icon_prop_" .. cell.data.id)--要显示的物品图标
				useIconDisplay:setVisible(true)
				local useBtnIndex = math.floor((cell.data.id-1)/2) + 1
				local useBtnDisplay = cell.display:getChildByName("btn_c" .. useBtnIndex .. "get")--要显示的按钮资源
				useBtnDisplay:setVisible(true)

				--领奖按钮
				cell.btnGain = Button:create(useBtnDisplay, true)
				cell.btnGain:addEventListener(Events.kStart, onClickCellBtn, cell)

				--图标按钮
				cell.btnIcon = Button:create(useIconDisplay)
				cell.btnIcon:addEventListener(Events.kStart, onClickCellIcon, cell)

				--设定为已初始化
				cell.displayInited = true
			end

			--随数据变化内容...

			if Activity_ConsumeRewardsLayer.checkGainedId(cell.data.id) then
				--已经领取过了
				cell.btnGain.display:getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_got"))--已领取
				cell.btnGain:setEnable(false)
			else
				--还没领取过
				if Activity_ConsumeRewardsLayer.isTimeInRange() then
					--在时间段内
					if Activity_ConsumeRewardsLayer.canGain(cell.data) then
						--可领取
						cell.btnGain:setEnable(true)
						cell.btnGain.display:getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_getting"))--领取奖励
					else
						--不可领取
						cell.btnGain:setEnable(false)
						cell.btnGain.display:getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_lack"))--未达成
					end
				else
					--已经超时
					cell.btnGain:setEnable(false)
					cell.btnGain.display:getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_getting"))--领取奖励
				end
			end
		end
	end

	--清除小格
	function onCellDataRemove(cell)
	end

	-----------------------------------------------------------------------------倒计时操作

	-- --倒计时每秒调用
	-- function onTimeTick(remainedSec)
	-- 	--更新计时文本
	-- 	local hh, mm, ss = TimeUtil.getHourMinSec(remainedSec)
	-- 	self.mainUI:getChildByName("txt_newyear_reward_time2_1"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_remainingtime2", {hour = hh, min = mm}))--{hour}时{min}分
	-- end
	-- self.onTimeTick = onTimeTick
	local resetUIInRewardTime
	--倒计时结束
	function onTimeComplete()
		--Activity_ConsumeRewardsLayer.timeIsOver = true
		if self.cdLabelComponent then
			self.cdLabelComponent:dispose()
			self.cdLabelComponent = nil
		end
		resetUIInRewardTime()
		self.refreshSelf()
	end
	function onTimeComplete2()
		Activity_ConsumeRewardsLayer.timeIsOver = true
		self.refreshSelf()
	end
	self.onTimeComplete = onTimeComplete

	local function resetUIInRechargeTime()
		--获得活动时间
		local timeTable = MaintenanceManager:getStartAndEndTime(Activity_ConsumeRewardsLayer.getRechargeFeatureName())
		local timeStrTable = {}
		timeStrTable.year = timeTable[2].year
		timeStrTable.month = timeTable[2].month
		timeStrTable.day = timeTable[2].day
		timeStrTable.hour = timeTable[2].time:split(":")[1]
		self.mainUI:getChildByName("txt_newyear_reward_time1"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_endingtime1"))--活动截止时间：
		self.mainUI:getChildByName("txt_newyear_reward_time1_1"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_endingtime2", timeStrTable))--{year}年{month}月{day}日{hour}时
		--倒计时组件
		self.cdLabelComponent = CdLabelComponent:create()
		self.cdLabelComponent:setCallback(nil, onTimeComplete)
		--开始倒计时
		self.cdLabelComponent:setTargetTime(timeTable[2].activityEndTimeStamp)
		self.cdLabelComponent:start()

		self.mainUI:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_deposit"))--去充值
		self.chargeBtn = Button:create(self.mainUI:getChildByName("btn"))--去充值
		self.chargeBtn:addEventListener(Events.kStart, onBtn1, self)

		self.mainUI:getChildByName("txt_wonreward_over2"):setVisible(false)
	end

	resetUIInRewardTime = function()
		--获得领奖时间
		local timeTable = MaintenanceManager:getStartAndEndTime(Activity_ConsumeRewardsLayer.getFeatureName())
		local timeStrTable = {}
		timeStrTable.year = timeTable[2].year
		timeStrTable.month = timeTable[2].month
		timeStrTable.day = timeTable[2].day
		timeStrTable.hour = timeTable[2].time:split(":")[1]
		self.mainUI:getChildByName("txt_newyear_reward_time1"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_rewardtime1"))--领奖截止时间：
		self.mainUI:getChildByName("txt_newyear_reward_time1_1"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_rewardtime2", timeStrTable))--{year}年{month}月{day}日{hour}时
		--倒计时组件
		self.cdLabelComponent = CdLabelComponent:create()
		self.cdLabelComponent:setCallback(nil, onTimeComplete2)
		--开始倒计时
		self.cdLabelComponent:setTargetTime(timeTable[2].activityEndTimeStamp)
		self.cdLabelComponent:start()
		self.mainUI:getChildByName("btn"):removeFromParentAndCleanup(true)

		self.mainUI:getChildByName("txt_newyear_reward_time2"):setVisible(false)
		self.mainUI:getChildByName("txt_newyear_reward_time2_1"):setVisible(false)
		self.mainUI:getChildByName("txt_owurida"):setVisible(false)
		self.mainUI:getChildByName("txt_wonreward_over2"):setVisible(true)
		self.mainUI:getChildByName("txt_wonreward_over2"):getChildByName("txt"):setString(getTextByKey("activity_timeOver"))
	end

	--固定文字
	if MaintenanceManager.isActivityOpen(Activity_ConsumeRewardsLayer.getRechargeFeatureName()) then
		resetUIInRechargeTime()
	else
		resetUIInRewardTime()
	end
	
	self.mainUI:getChildByName("txt_newyear_reward_time2"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_coins1"))--已充值
	local showNum = CanonGoodIcon.formatNumByMax(Activity_ConsumeRewardsLayer.getRecharges(), 99999)--最多5位数
	self.mainUI:getChildByName("txt_newyear_reward_time2_1"):getChildByName("txt"):setString(showNum)--[活动期间充值金币数]
	self.mainUI:getChildByName("txt_owurida"):getChildByName("txt"):setString(getTextByKey("activity_consumeRewards_charging3"))--金币

	--按钮
	self.qaBtn = Button:create(self.mainUI:getChildByName("sky_btn_qa"))--询问按钮

	self.qaBtn:addEventListener(Events.kStart, onBtn2, self)

	--列表组件
	self.listView = ListView:create(onCellDataSet, onCellDataRemove, nil, nil)
	self.listView:setDisplay(self.mainUI, "LA_reward_leve")
	--显示列表
	self.listView:setDataList(Activity_ConsumeRewardsLayer.getRewardList())

	--加侦听

	--重置时间已过状态
  	Activity_ConsumeRewardsLayer.timeIsOver = false

	--更新
	self.refreshSelf()
end

function Activity_ConsumeRewardsLayer:dispose()
	--销毁列表组件
	if self.listView then
		self.listView:dispose()
	end
	
	--移除侦听

	--销毁倒计时组件
	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	Activity_ConsumeRewardsLayer.super.dispose(self)
end

----------------------------------------------------------------------------------------------------------------------------静态


-----------------------------------静态变量-----------------------------------------

--活动期间充值金币
local _recharges = 0
--已领取礼品id
local _gainedIds = {}

-----------------------------------数据读取/设置-----------------------------------------

function Activity_ConsumeRewardsLayer.setRecharges(v)
	_recharges = v
end

function Activity_ConsumeRewardsLayer.getRecharges()
	return _recharges
end

function Activity_ConsumeRewardsLayer.setGainedIds(v)
	_gainedIds = v
end

--增加一个已领取id
function Activity_ConsumeRewardsLayer.addGainedId(id)
	table.insert(_gainedIds, id)
end

--查询某id是否为已领取
function Activity_ConsumeRewardsLayer.checkGainedId(id)
	return table.indexOf(_gainedIds, id) ~= nil
end

-----------------------------------系统函数-----------------------------------------

function Activity_ConsumeRewardsLayer.clear()
	_recharges = 0
	_gainedIds = {}
end

function Activity_ConsumeRewardsLayer.getTipNum()
	if not Activity_ConsumeRewardsLayer:enable() then
		--活动未开启
		return 0
	end

	return Activity_ConsumeRewardsLayer.canGainRewardNum()
end

-----------------------------------自用函数-----------------------------------------

--查询是否在活动时间段内
function Activity_ConsumeRewardsLayer.isTimeInRange()
	if Activity_ConsumeRewardsLayer.timeIsOver then
		--时间过了
		return false
	end

	return true
end

--查询能否领奖
function Activity_ConsumeRewardsLayer.canGain(configData)
	if not Activity_ConsumeRewardsLayer.isTimeInRange() then
		--时间过了
		return false
	end

	if Activity_ConsumeRewardsLayer.checkGainedId(configData.id) then
		--已获取
		return false
	end

	local needRecharges = configData.requiredGold
	if Activity_ConsumeRewardsLayer.getRecharges() < needRecharges then
		--期间充值金币不足
		return false
	end

	return true
end

--能领取的奖励数量
function Activity_ConsumeRewardsLayer.canGainRewardNum()
	local result = 0
	local rewardConfigList = Activity_ConsumeRewardsLayer.getRewardList()
	for i, v in ipairs(rewardConfigList) do
		if Activity_ConsumeRewardsLayer.canGain(v) then
			result = result + 1
		end
	end
	return result
end

-----------------------------------静态配置-----------------------------------------

-----------------------------------后端配置-----------------------------------------

--获得配置
function Activity_ConsumeRewardsLayer.getConfig()
	local config = DataManager.GameMetaData.activityConsumeRewardConfig
	-- if SystemManager.debug then
	-- 	print("DataManager.GameMetaData = " .. table.tostring(DataManager.GameMetaData, nil, nil, 1))
	-- 	print("config = " .. tostringRich(config))
	-- end
	return config
end

--获得奖励预览内容
-- <bean desc="多重好礼礼品配置">
-- 	<property code="id" type="int" desc="奖励Id"/>
-- 	<property code="requiredGold" type="int" desc="领取条件"/>
-- 	<list code="rewards" ref="Reward" desc="奖励内容"/>
-- </bean>
function Activity_ConsumeRewardsLayer.getRewardList()
	local config = Activity_ConsumeRewardsLayer.getConfig()
	return config.consumeRewards
end

--获得活动开关名称
function Activity_ConsumeRewardsLayer.getFeatureName()
	local config = Activity_ConsumeRewardsLayer.getConfig()
	return config.featureName
end

--获得充值开关名称
function Activity_ConsumeRewardsLayer.getRechargeFeatureName()
	local config = Activity_ConsumeRewardsLayer.getConfig()
	return config.featureNameCharging
end