-- Activity_FountainLayer.lua
-- 2015-1-13
-- zheng.che
-- 许愿池活动面板

require "canon.request.FountainWishRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()


--许愿按钮
local function onBtn1(evt)
	local self = evt.context

	if Activity_FountainLayer.canGain(true) then
		local function onAfterSucceed(requestEvt)
			--显示动画
			local colorLayer = LayerColor:create()
			colorLayer:setOpacity(kDarkOpacity)
			colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
			self:addChild(colorLayer, 100)
			local fspt = FlashSprite:create("EVO2/activity_fountian")
			fspt:changeAnimation(0)
			fspt:setLoop(false)
			self.fspt_co = CocosObject.new(fspt)
			--禁用点击
			self.container.targetInfoPanel = colorLayer
			self.container:setTableViewsEnabled(false)

			local function animationEnd(anim)
				--结束动画
				fspt:unregisterEndAnimationScriptHandler()
				self:removeChild(self.fspt_co)
				self:removeChild(colorLayer)
				--启用点击
				self.container.targetInfoPanel = nil
				self.container:setTableViewsEnabled(true)

				--播放获得银币提示动画
				local amount = requestEvt.data.coins
				local multipleStr = nil
				if requestEvt.data.multiple > 1 then
					multipleStr = "x" .. requestEvt.data.multiple
				end
				MapEventLabel:showContent(self.container, "#sliver_coin.png", string.format("/%d", amount), visibleSize.width/2, visibleSize.height/2, multipleStr)

				--更新角标数
				self.container:resetTipInfoForActivity("Activity_FountainWish")

				self.refreshSelf()
			end
			fspt:registerEndAnimationScriptHandler(animationEnd)
			self:addChild(self.fspt_co)
		end
		FountainWishRequest.sendRequestDefalut(onAfterSucceed)
	end
end
--询问按钮
local function onBtn2(evt)
	local self = evt.context
	--主公每天都可以前来许愿池，许愿获得大量银币。\n
	--主公每天有两次免费许愿的机会，之后可以使用金币继续许愿。\n
	--许愿次数越多，主公获得的银币越多。许愿时有一定概率暴击，此时主公可以获得翻倍、乃至更多的银币哦~\n
	--第一次获得：银币x{num1}\n
	--第二次获得：银币x{num2}\n第三次获得：银币x{num3}\n
	--第四次获得：银币x{num4}\n
	--第五次获得：银币x{num5}\n
	--第六次获得：银币x{num6}\n
	--第七次获得：银币x{num7}\n
	--第八次获得：银币x{num8}\n
	--第九次获得：银币x{num9}\n
	--第十次获得：银币x{num10}
	local coinConfigs = Activity_FountainLayer.getSilverCoins()
	local argHash = {}
	for i, v in ipairs(coinConfigs) do
		argHash["num"..i] = v.silverCoins
	end
	local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("activity_fountainWish_help",argHash))--主公每天都可以前来许愿池，许愿获得大量银币哦~\n主公每天有两次免费许愿的机会，之后可以使用金币继续许愿。
	self.container:addChild(aInfoPanel)
	aInfoPanel:scaleIn()

	self.container:setTableViewsEnabled(false)
end

--跨天事件
local function onPassDay(evt)
	local self = evt.context

	--清除当日许愿次数
	DailyDataManager.setWishings(0)

	self.refreshSelf()
end

---------------------------------------------------------------------------------------------------------
Activity_FountainLayer = class(Layer)

--vip等级对应许愿总次数的哈希表 若vip0则对应免费次数
local _vipHash = nil

---------------------------------------------------------------------------------------------------------

function Activity_FountainLayer:ctor()
  self.container = nil
end

function Activity_FountainLayer:create( container )
  self.container = container
  local s = Activity_FountainLayer.new()
  s:initLayer()
  return s
end

function Activity_FountainLayer:enable()
	if not DataManager.GameMetaData.activityFountainWishConfig then
		print("activityFountainWishConfig is nil")
		return false
	end

	local myLevel = DataManager.getCurrUser().level or 1
	local needLevel = Activity_FountainLayer.getRequiredLevel()

	local config = Activity_FountainLayer.getConfig()
	--print("config = " .. tostringRich(config))

	if myLevel < needLevel then
		--等级不足 提示
		if SystemManager.debug then
			print("Activity_FountainLayer:enable is false! DataManager.getCurrUser().level = " .. tostringRich(DataManager.getCurrUser().level))
		end
		return false
	end

	--print("Activity_FountainLayer.getFeatureName() = " .. tostringRich(Activity_FountainLayer.getFeatureName()))
	local isEnable = MaintenanceManager.isActivityOpen(Activity_FountainLayer.getFeatureName())
	if SystemManager.debug then
		print("Activity_FountainLayer isEnable = " .. tostringRich(isEnable))
	end
	return isEnable
end 

function Activity_FountainLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_FountainLayer:initLayer()
    Activity_FountainLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity_fountain")
	self:addChild(self.mainUI)

	local function refreshSelf()
		self.mainUI:getChildByName("txt_1"):setVisible(false)
		self.mainUI:getChildByName("txt_2"):setVisible(false)
		self.mainUI:getChildByName("txt_3"):setVisible(false)
		self.mainUI:getChildByName("txt_4"):setVisible(false)
		self.gainBtn:setEnable(false)
		self.gainBtn.display:getChildByName("txt"):setVisible(false)
		self.gainBtn.display:getChildByName("txt_money_cost"):setVisible(false)
		self.gainBtn.display:getChildByName("icon_gold"):setVisible(false)

		local todayTimes = DailyDataManager.getWishings()--今日许愿次数
		local freeTimes = Activity_FountainLayer.getFreeTimes()--免费次数
		local myTotalTimes = Activity_FountainLayer.getMaxTimes()--当前玩家vip总次数

		-- print("todayTimes = " .. tostringRich(todayTimes))
		-- print("freeTimes = " .. tostringRich(freeTimes))
		-- print("myTotalTimes = " .. tostringRich(myTotalTimes))

		if todayTimes < freeTimes then
			--还有免费
			self.mainUI:getChildByName("txt_1"):setVisible(true)
			self.mainUI:getChildByName("txt_2"):setVisible(true)
			self.mainUI:getChildByName("txt_3"):setVisible(true)
			self.gainBtn:setEnable(true)
			self.gainBtn.display:getChildByName("txt"):setVisible(true)

			self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("activity_fountainWish_freeTimes"))--今日还可以免费许愿
			self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(freeTimes - todayTimes)--[许愿次数]

			self.gainBtn.display:getChildByName("txt"):setString(getTextByKey("activity_fountainWish_freeWish"))--免费许愿
		else
			--免费没了
			if todayTimes < myTotalTimes then
				--还有vip次数
				self.mainUI:getChildByName("txt_1"):setVisible(true)
				self.mainUI:getChildByName("txt_2"):setVisible(true)
				self.mainUI:getChildByName("txt_3"):setVisible(true)
				self.gainBtn:setEnable(true)
				self.gainBtn.display:getChildByName("txt_money_cost"):setVisible(true)
				self.gainBtn.display:getChildByName("icon_gold"):setVisible(true)

				self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("activity_fountainWish_vipTimes"))--今日还可以金币许愿
				self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(myTotalTimes - todayTimes)--[还可许愿次数]


				local needGold = Activity_FountainLayer.getCost(todayTimes + 1)--下一次许愿所需金币数量
				self.gainBtn.display:getChildByName("txt_money_cost"):getChildByName("txt"):setString("" .. needGold .. getTextByKey("activity_fountainWish_wish"))--[金币数量]许愿
			else
				--vip次数没了 或者压根没有vip
				self.mainUI:getChildByName("txt_4"):setVisible(true)
			self.gainBtn.display:getChildByName("txt"):setVisible(true)
			self.gainBtn.display:getChildByName("txt"):setString(getTextByKey("activity_fountainWish_wish"))--许愿
			end
		end
	end
	self.refreshSelf = refreshSelf

	--获得活动时间
	local timeTable = MaintenanceManager:getStartAndEndTime(Activity_FountainLayer.getFeatureName())

	--固定文字
	self.mainUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("activity_fountainWish_times"))--次
	self.mainUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("activity_fountainWish_finish"))--今日许愿次数已用完

	--描边
	self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setColor(ccc3(0, 255, 0))

	--按钮
	self.gainBtn = Button:create(self.mainUI:getChildByName("btn"), true)--获取银币按钮
	self.qaBtn = Button:create(self.mainUI:getChildByName("sky_btn_qa"))--询问按钮

	self.gainBtn:addEventListener(Events.kStart, onBtn1, self)
	self.qaBtn:addEventListener(Events.kStart, onBtn2, self)

	--加侦听
	NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

	--更新
	self.refreshSelf()
end

function Activity_FountainLayer:dispose()
	NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)

	Activity_FountainLayer.super.dispose(self)
end

----------------------------------------------------------------------------------------------------------------------------静态函数

function Activity_FountainLayer.clear()
	_vipHash = nil
end

function Activity_FountainLayer.getTipNum()
	if not Activity_FountainLayer:enable() then
		--活动未开启
		return 0
	end

	local todayTimes = DailyDataManager.getWishings()--今日许愿次数
	local freeTimes = Activity_FountainLayer.getFreeTimes()--免费次数

	if todayTimes >= freeTimes then
		--免费次数已用完
		return 0
	end

	return freeTimes - todayTimes
end

-----------------------------------静态配置-----------------------------------------

--获得vip等级对应最大许愿次数的配置
function Activity_FountainLayer.getVipHash()
	if not _vipHash then
		_vipHash = {}
		local metas = MetaManager.activity_fountainwish_fountainmax
		for i, v in ipairs(metas) do
			for k = v.vipLevelMin, v.vipLevelMax, 1 do
				_vipHash[k] = v.foutainMax
			end
		end
	end
	return _vipHash
end

--获得当前玩家的最大许愿次数
function Activity_FountainLayer.getMaxTimes()
	local myVip = tonumber(DataManager.getCurrUser().vipLevel)
	if myVip < 1 then
		--没有vip 免费次数
		return Activity_FountainLayer.getFreeTimes()
	end

	local hash = Activity_FountainLayer.getVipHash()
	local reslut = hash[myVip]
	return reslut
end

--获得某次消耗金币
function Activity_FountainLayer.getCost(times)
	local metas = MetaManager.activity_fountainwish_gold
	local meta = metas[times]
	return meta.gold
end

-----------------------------------后端配置-----------------------------------------

--获得配置
function Activity_FountainLayer.getConfig()
	local config = DataManager.GameMetaData.activityFountainWishConfig
	return config
end

--获得免费次数
function Activity_FountainLayer.getFreeTimes()
	local config = Activity_FountainLayer.getConfig()
	return config.freeNum
end

--获得活动开关名称
function Activity_FountainLayer.getFeatureName()
	local config = Activity_FountainLayer.getConfig()
	return config.featureName
end

--获得每次奖励银币数量列表 list
-- <bean desc="许愿池银币配置">
-- 	<property code="fountainNum" type="int" desc="许愿次数"/>
-- 	<property code="silverCoins" type="int" desc="银币基数"/>
-- </bean>
function Activity_FountainLayer.getSilverCoins()
	local config = Activity_FountainLayer.getConfig()
	return config.silverCoins
end

--获得等级限制
function Activity_FountainLayer.getRequiredLevel()
	local config = Activity_FountainLayer.getConfig()
	return config.requiredLevel
end

-----------------------------------其他接口-----------------------------------------

function Activity_FountainLayer.canGain(withAlert)
	local currentGold = CanonGoodIcon.getResourceNum(ResourceEnum.GEMS)
	local todayTimes = DailyDataManager.getWishings()--今日许愿次数
	local needGold = Activity_FountainLayer.getCost(todayTimes + 1)--下一次许愿所需金币数量
	if currentGold < needGold then
		--金币不足
		if withAlert then
			local scene = Director:mgr():run()
			local aPanel = AssistantMessageBoxPanel:create(scene, AsMessageBoxType.addCoin, nil)
			scene:addChild(aPanel)
			aPanel:scaleIn()
		end
		return false
	end

	return true
end