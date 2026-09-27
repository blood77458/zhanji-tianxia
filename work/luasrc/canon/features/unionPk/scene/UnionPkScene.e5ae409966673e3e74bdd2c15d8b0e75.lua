-- UnionPkScene.lua
-- zheng.che
-- 2014-7-24
-- 军团战场景

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 按钮点击
-------------------------------------------------------------------------------


--点击返回
local function onBackBtnClick(evt)
	local self = evt.context
	self:back()
end

--点击问号
local function onQaBtnClick(evt)
	local self = evt.context

	local lastestStartTime = UnionPkUtils.findLatestBeginTime()

	local function getStartAndEndTime(timeConsts)
		local TimeMeta = UnionPkConfig.getLevelTimeMeta(timeConsts)
		local StartTime = lastestStartTime + TimeMeta.warBeginTime * 60
		local EndTime = StartTime + TimeMeta.warContinueTime * 60

		local StartTimeStr = TimeUtil.formatDate(StartTime, "UnionWar_sign_time3")
		local EndTimeStr = TimeUtil.formatDate(EndTime, "UnionWar_sign_time3")
		return StartTimeStr , EndTimeStr
	end

    local timeTable = {}
    timeTable["time1"] , _ = getStartAndEndTime(UnionPkConsts.TIME_SELECT)
    timeTable["time2"] , timeTable["time3"] = getStartAndEndTime(UnionPkConsts.TIME_SELECTING)
    timeTable["time4"] , timeTable["time5"] = getStartAndEndTime(UnionPkConsts.TIME_MEMBER_APPLY)
    timeTable["time6"] , timeTable["time7"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND1_FORM)
    --timeTable["time8"] , timeTable["time9"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND1_BUFF)
    timeTable["time10"] , timeTable["time11"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND1_FIGHT)
    _ , timeTable["time12"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND1_FIGHT)
    timeTable["time13"] , timeTable["time14"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND2_FORM)
    --timeTable["time15"] , timeTable["time16"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND2_BUFF)
    timeTable["time17"] , timeTable["time18"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND2_FIGHT)
    _ , timeTable["time19"] = getStartAndEndTime(UnionPkConsts.TIME_ROUND2_FIGHT)
    timeTable["time20"] , timeTable["time21"] = getStartAndEndTime(UnionPkConsts.TIME_REWARD)
    _ , timeTable["time22"] = getStartAndEndTime(UnionPkConsts.TIME_REWARD)

    local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("UnionWar_npc_name7",timeTable))
    self:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
end

local function onMyGuildBtn(evt)
	local scene = evt.context

	local function onAfterSucceed(evt)
		local data = evt.data.battleCityIds or {}
		-- 假数据
		-- data = {6,9}
		local aMyGuildPanel = UnionPKMyGuildPopPanel:create(scene , data)
		scene:addChild(aMyGuildPanel)
		aMyGuildPanel:scaleIn()
	end
	UnionPKGetMyGuildInfoRequest.sendRequestDefalut(onAfterSucceed)
end

local function onMyRewardBtn(evt)
	local scene = evt.context
	local aMyGuildPanel = UnionPKMyRewardPopPanel:create(scene)
	scene:addChild(aMyGuildPanel)
	aMyGuildPanel:scaleIn()
end

local moveTimes = 0
--点击城池(按下)
local function onCityBtnBegin(evt)
	--print("onCityBtnBegin")
	moveTimes = 0
end

--点击城池(移动)
local function onCityBtnMove(evt)
	--print("onCityBtnMove")
	moveTimes = moveTimes + 1
end

--点击城池
local function onCityBtnClick(evt)
	--print("onCityBtnClick")
	if (moveTimes <= 10) then
		local cityId = evt.context
		UnionPkScene.showCityInfo(cityId)
	end
end


-------------------------------------------------------------------------------
-- 事件侦听
-------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

--时间段更新事件
local function onTimelevelUpdate(evt)
	local self = evt.context
	local function onAfterSucceed(evt)
		self.refreshSelf()
	end
	UnionPkGetCityListRequest.sendRequestDefalut(onAfterSucceed)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionPkScene = class(BaseUIScene)

function UnionPkScene:ctor()
end

function UnionPkScene:create(argv)
	local s = UnionPkScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionPkScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end

function UnionPkScene:onInit()
	BaseUIScene.initBackGround(self)

	self.cityDisplaysDic = {}
	
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("guildPK_main")
	self.tempLayer:addChild(ui)
	self.ui = ui

	--刷新自身
	function refreshSelf()
		self.currentTimeLevel = UnionPkData.getCurrTimeLevel()

		--检查奖励按钮是否可见
		if UnionPkCheck.canSeeRewardFormBtn(self.currentTimeLevel) then
			self.myRewardBtn:setVisible(true)
			self.myRewardBtn:setEnable(true)

			--更新角标数
			self.myRewardBtn:setNum(UnionPkUtils.findRewardNum())
		else
			self.myRewardBtn:setVisible(false)
			self.myRewardBtn:setEnable(false)
		end

		--检查我的军团按钮是否可见
		if UnionPkCheck.canSeeMyUnionBtn(self.currentTimeLevel) then
			self.myGuildBtn:setVisible(true)
			self.myGuildBtn:setEnable(true)
		else
			self.myGuildBtn:setVisible(false)
			self.myGuildBtn:setEnable(false)
		end

		--检查本轮财富是否可见
		if UnionPkCheck.canSeeWealthTxt(self.currentTimeLevel) then
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("txt_guild_21"):setVisible(true)
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("lbl_the_bianconeri_wealth"):setVisible(true)
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("halfblack2"):setVisible(true)
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("txt_guild_21"):getChildByName("txt"):setString(UnionPkData.getRoundWealth())--[军团本轮财富]
		else
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("txt_guild_21"):setVisible(false)
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("lbl_the_bianconeri_wealth"):setVisible(false)
			self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("halfblack2"):setVisible(false)
		end

		--更新城池信息
		for k,v in pairs(self.cityDisplaysDic) do
			--print("k = " .. tostringRich(k))
			--print("v = " .. tostringRich(v))
			UnionPkScene.updateCityDisplay(self, v, k)
		end

		-------------------------------------------------------------
		local function setSecondTipShow( isShow )
			self.ui:getChildByName("txt_2"):setVisible(isShow)
			self.ui:getChildByName("halfblack3"):setVisible(isShow)
		end
		local lastestStartTime = UnionPkUtils.findLatestBeginTime()
		if self.currentTimeLevel == UnionPkConsts.TIME_SELECT then
			setSecondTipShow(false)
			--报名阶段
			local selectTimeMeta = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_SELECT)
			local selectStartTime = lastestStartTime + selectTimeMeta.warBeginTime * 60
			local selectEndTime = selectStartTime + selectTimeMeta.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(selectStartTime, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(selectEndTime, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_txt1") .. selectTimeStr)--城池报名阶段：

		elseif self.currentTimeLevel == UnionPkConsts.TIME_SELECTING then
			setSecondTipShow(false)
			--等待竞标结果阶段
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_txt2"))--此时为竞标结果统计阶段，请等待竞标结果
		elseif self.currentTimeLevel == UnionPkConsts.TIME_MEMBER_APPLY then
			setSecondTipShow(true)
			--团员参与阶段
			local timeMeta = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_MEMBER_APPLY)
			local startTime = lastestStartTime + timeMeta.warBeginTime * 60
			local endTime = startTime + timeMeta.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_txt3") .. selectTimeStr)--城池报名阶段：

			local timeMeta1 = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_ROUND1_FORM)
			local startTime1 = lastestStartTime + timeMeta1.warBeginTime * 60
			local endTime1 = startTime1 + timeMeta1.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime1, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime1, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time1") .. selectTimeStr)--第一场团战调整阵型时间：

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FORM then
			setSecondTipShow(false)
			--第一轮调整阵型
			local timeMeta1 = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_ROUND1_FORM)
			local startTime1 = lastestStartTime + timeMeta1.warBeginTime * 60
			local endTime1 = startTime1 + timeMeta1.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime1, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime1, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time1") .. selectTimeStr)--第一场团战调整阵型时间：

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND1_FIGHT then
			setSecondTipShow(true)
			--第一轮等待结果
			self.ui:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_txt4"))--团战统计时间，请等待团战结果

			local timeMeta1 = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_ROUND2_FORM)
			local startTime1 = lastestStartTime + timeMeta1.warBeginTime * 60
			local endTime1 = startTime1 + timeMeta1.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime1, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime1, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time3") .. selectTimeStr)--第二场团战调整阵型时间：

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FORM then
			setSecondTipShow(false)
			--第二轮调整阵型
			local timeMeta1 = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_ROUND2_FORM)
			local startTime1 = lastestStartTime + timeMeta1.warBeginTime * 60
			local endTime1 = startTime1 + timeMeta1.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime1, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime1, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time3") .. selectTimeStr)--第二场团战调整阵型时间：

		elseif self.currentTimeLevel == UnionPkConsts.TIME_ROUND2_FIGHT then
			setSecondTipShow(false)
			--第二轮等待结果
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_time_txt4"))--团战统计时间，请等待团战结果

		elseif self.currentTimeLevel == UnionPkConsts.TIME_REWARD then
			setSecondTipShow(false)
			--领奖阶段
			local timeMeta = UnionPkConfig.getLevelTimeMeta(UnionPkConsts.TIME_REWARD)
			local startTime = lastestStartTime + timeMeta.warBeginTime * 60
			local endTime = startTime + timeMeta.warContinueTime * 60

			local selectTimeStr = TimeUtil.formatDate(startTime, "UnionWar_sign_time3") .. "-" .. TimeUtil.formatDate(endTime, "UnionWar_sign_time3")
			self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_supple_time7") .. selectTimeStr)--奖励领取时间：

		else
			--均非也
			if SystemManager.debug then
				DebugManager.addError("非法时间段! 编号: " .. tostringRich(self.currentTimeLevel))
			end
		end
	end
	self.refreshSelf = refreshSelf

	--每秒tick
	local function onTick()
		local tempTimeLevel = UnionPkData.getCurrTimeLevel()
		if tempTimeLevel ~= self.currentTimeLevel then
			self.currentTimeLevel = tempTimeLevel
			--通知更新
			UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_TIMELEVEL_PASSED))
		end

		--测试用计时显示 现在代码已经支持debug开关 所以此段允许上传到dev
		if self.ui:getChildByName("txt_debug") then
			if SystemManager.debug then
				self.ui:getChildByName("txt_debug"):setVisible(true)
				local currTime = TimeUtil.getServerTimeSeconds()
				local debugTimeStr = TimeUtil.formatDate(currTime)
				self.ui:getChildByName("txt_debug"):getChildByName("txt"):setString(debugTimeStr)
			else
				self.ui:getChildByName("txt_debug"):setVisible(false)
			end
		end
	end
	self.onTick = onTick

	--静态文本

	--按钮
	local backButton = Button:create(self.ui:getChildByName("guildPK_colosseuml_title"):getChildByName("r_click"))
	backButton:addEventListener(Events.kStart, onBackBtnClick, self)

	local qaButton = Button:create(self.ui:getChildByName("sky_btn_qa"))
	qaButton:addEventListener(Events.kStart, onQaBtnClick, self)

	local moveDisplay = self.ui:getChildByName("guildPK_map_canmove")
	local scrollViewSize = moveDisplay:getGroupBounds(self.ui).size

	self.myGuildBtn = Button:create(self.ui:getChildByName("icon_myguild"))
	self.myGuildBtn:addEventListener(Events.kStart, onMyGuildBtn, self)

	self.myRewardBtn = CanonButton:create(self.ui:getChildByName("btn_reward"))
	self.myRewardBtn:addEventListener(Events.kStart, onMyRewardBtn, self)

	--大城池显示处理
	-- for i=1, UnionPkConsts.bigCityNum do
	-- 	local cityId = UnionPkConsts.bigCityStartNum + i - 1
	-- print("111cityId = " .. tostringRich(cityId))
	-- 	UnionPkScene.setCityDisplay(self, moveDisplay:getChildByName("city_big"), cityId)
	-- end
	UnionPkScene.setCityDisplay(self, moveDisplay:getChildByName("city_big"), UnionPkConsts.bigCityStartNum)

	--中城池显示处理
	for i=1, UnionPkConsts.midCityNum do
		local cityId = UnionPkConsts.midCityStartNum + i - 1
		UnionPkScene.setCityDisplay(self, moveDisplay:getChildByName("city_medium" .. i), cityId)
	end


	--滚动区域处理
	local groupDisplaySize = moveDisplay:getChildByName("list_guildPK_main_semless"):getChildByName("guildPK_main_semless"):getGroupBounds().size
	moveDisplay:getChildByName("list_guildPK_main_semless"):removeFromParentAndCleanup(true)
	local zOrder = moveDisplay:getZOrder()
	local bigAndSmallCitysDisplaySize = moveDisplay:getGroupBounds(self.ui).size

	local smallCityCount = UnionPkData.getSmallCityNum()--小城池总数
	if smallCityCount <= 0 then
		--没有小城池
		local groupDisplay = builder:build("list/list_guildPK_main_semless")
		groupDisplay:setPositionY(-bigAndSmallCitysDisplaySize.height)
		moveDisplay:addChild(groupDisplay)

		for j=1,UnionPkConsts.smallCityUiGroupNum do
			local cityDisplay = groupDisplay:getChildByName("city_samll" .. j)
			cityDisplay:setVisible(false)
		end
	else
		--有小城池
		local maxCityId = smallCityCount + UnionPkConsts.smallCityStartNum - 1--可出现的最大id
		local groupCount = math.ceil(smallCityCount / UnionPkConsts.smallCityUiGroupNum)
		for i=1,groupCount do
			local groupDisplay = builder:build("list/list_guildPK_main_semless")
			groupDisplay:setPositionY(-bigAndSmallCitysDisplaySize.height - (i-1)*groupDisplaySize.height)
			moveDisplay:addChild(groupDisplay)

			for j=1,UnionPkConsts.smallCityUiGroupNum do
				local cityId = (i-1) * UnionPkConsts.smallCityUiGroupNum + j + UnionPkConsts.smallCityStartNum - 1

				local groupCityId = j
				local cityDisplay = groupDisplay:getChildByName("city_samll" .. groupCityId)

				if cityId <= maxCityId then
					UnionPkScene.setCityDisplay(self, cityDisplay, cityId)
				else
					cityDisplay:setVisible(false)
				end
			end
		end
	end

	local contentSize = moveDisplay:getGroupBounds().size
	local contentHeight = contentSize.height
	--print("contentHeight = " .. tostringRich(contentHeight))


	local scroll_width = scrollViewSize.width
	local scroll_height = scrollViewSize.height
	local scroll_posX = moveDisplay:getPositionX()
	local scroll_posY = moveDisplay:getPositionY() - scroll_height + 1--整体上移一点
	local scroll_startPosY = scroll_height - contentSize.height
	--print("scroll_startPosY = " .. tostringRich(scroll_startPosY))

	self.scrollView = ScrollView:create(scroll_width, scroll_height)

    self.scrollView:setPosition(ccp(scroll_posX, scroll_posY))
    --self.scrollView:setPosition(ccp(scroll_posX, 113))
    self.scrollView:setDirection(kCCScrollViewDirectionVertical)
    self.scrollView:setBounceable(false)--禁止拉出最大范围
    self.ui:addChildAt(self.scrollView, zOrder)

	--print("scroll_height = " .. tostringRich(scroll_height))
	--print("contentHeight = " .. tostringRich(contentHeight))
	self.scrollView:setContentSize(CCSizeMake(scroll_width, contentHeight))

    moveDisplay:removeFromParentAndCleanup(false)
	moveDisplay:setPosition(ccp(0, contentSize.height))
    self.scrollView:addChild(moveDisplay)
    self.scrollView:setContentOffset(ccp(0, scroll_startPosY), false)

    self.scrollView:adjustHitArea()

    --print("moveDisplay:getPositionY() = " .. tostringRich(moveDisplay:getPositionY()))
    --print("self.scrollView:getPositionY() = " .. tostringRich(self.scrollView:getPositionY()))

	local qaButton = Button:create(self.ui:getChildByName("sky_btn_qa"))
	qaButton:addEventListener(Events.kStart, onCityClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_REWARD_UPDATE, self.refreshSelf)


	--定期计时
	self.tickEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.onTick, 1, false)--间隔1s

	self.refreshSelf()

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	--其他初始化操作
end

-----------------------------------------------内部接口------------------------------------------------------------

-----------------------------------------------外部接口------------------------------------------------------------

function UnionPkScene:setTableViewsEnabled(enabled)
	self.scrollView:setTouchEnabled(enabled)
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionPkScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionPkScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/m_unionPk.mp3", true)
end

function UnionPkScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	--云雾动画
	local fspt = FlashSprite:create("map/others/flashPack/Cloud")
	fspt:changeAnimation(0)
	fspt:setLoop(false)
	local fspt_co = CocosObject.new(fspt)
	local function onCloudFlashAnimationEnd(anim)
		fspt:unregisterEndAnimationScriptHandler()
		self:removeChild(fspt_co)
		--Set_ShareData( "Cloud_Finished", 1 )
		self.fspt = nil;
	end
	self.fspt = fspt
	fspt:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
	self:addChild(fspt_co)

	--放大的动画 动画过程禁止操作
	self.tempLayer:setScale(0.5)
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
		self.tempLayer.touchEnabled = true
		self.tempLayer.touchChildren = true
		enterActionFinished()
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))
end

function UnionPkScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionPkScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionPkScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function UnionPkScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function UnionPkScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function UnionPkScene:back()
	UnionManager.gotoUnionScene()
end

function UnionPkScene:dispose()
	--print("UnionPkScene:dispose")
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_REWARD_UPDATE, self.refreshSelf)

	if self.tickEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
	end

	UnionPkScene.super.dispose(self)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 自有逻辑
-------------------------------------------------------------------------------

--显示城池具体信息
function UnionPkScene.showCityInfo(cityId)
	UnionPK.showCityInfoPanel(cityId)
end

--显示城池具体信息
function UnionPkScene.setCityDisplay(self, cityDisplay, cityId)
	local cityButton = Button:create(cityDisplay)
	--cityButton.noTouchEffect = true
	cityDisplay:addEventListener(DisplayEvents.kTouchBegin, onCityBtnBegin, cityId)
	cityDisplay:addEventListener(DisplayEvents.kTouchMove, onCityBtnMove, cityId)
	cityButton:addEventListener(Events.kStart, onCityBtnClick, cityId)

	local cityName = UnionPkUtils.getCityNameById(cityId)
	cityDisplay:getChildByName("txt_guild_pk_21"):getChildByName("txt"):setString(cityName)

	UnionPkScene.updateCityDisplay(self, cityDisplay, cityId)

	self.cityDisplaysDic[cityId] = cityDisplay
end

--更新城池显示信息
function UnionPkScene.updateCityDisplay(self, cityDisplay, cityId)
	--处理防守标识
	if UnionPkData.cityIsInMyDefence(cityId) then
		cityDisplay:getChildByName("icon_guildpk_thewar"):setVisible(true)
	else
		cityDisplay:getChildByName("icon_guildpk_thewar"):setVisible(false)
	end

	--处理报名城池标识
	if UnionPkCityData.isMyChallengCityById(cityId) then
		cityDisplay:getChildByName("bg_flags"):setVisible(true)
	else
		cityDisplay:getChildByName("bg_flags"):setVisible(false)
	end

	--处理正在战斗的标识
	if UnionPkData.checkIsFightingCityId(cityId) then
		cityDisplay:getChildByName("icon_fighting"):setVisible(true)
	else
		cityDisplay:getChildByName("icon_fighting"):setVisible(false)
	end
end