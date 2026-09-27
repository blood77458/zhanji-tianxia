-- CrossUnionPkKnockoutScene.lua
-- 2015-4-14
-- zheng.che
-- 跨服gvg 淘汰赛场景

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local selectedText = ""

--滚动区域上方留白空间
local _scrollUpGap = 20
--滚动区域下方留白空间
local _scrollDownGap = 10
--滚动元素之间留白
local _scrollItemGap = 20

--对抗信息区域上方留白空间
local _againstUpGap = 110
--对抗信息区域下方留白空间
local _againstDownGap = 0
--对抗信息元素之间留白
local _againstItemGap = 10

--ABCDEFGH标志的层名
local _teamLableNames = {}
_teamLableNames[1] = "lbl_Gvg_A"
_teamLableNames[2] = "lbl_Gvg_B"
_teamLableNames[3] = "lbl_Gvg_C"
_teamLableNames[4] = "lbl_Gvg_D"
_teamLableNames[5] = "lbl_Gvg_E"
_teamLableNames[6] = "lbl_Gvg_F"
_teamLableNames[7] = "lbl_Gvg_G"
_teamLableNames[8] = "lbl_Gvg_H"

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
	local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("WGVG_Detail44"))
	self:addChild(aInfoPanel)
	aInfoPanel:scaleIn()
end

local moveTimes = 0
--按下
local function onBtnBegin(evt)
	--print("onBtnBegin")
	moveTimes = 0
end

--移动
local function onBtnMove(evt)
	--print("onBtnMove")
	moveTimes = moveTimes + 1
end

--点击查看录像
local function onVideoBtnClick(evt)
	if (moveTimes <= 10) then
		local reportId = evt.context.id
		local knockoutType = evt.context.knockoutType
		CrossUnionPkGetBattleReportRequest.sendRequestDefalut(reportId, true, knockoutType)
	end
end


-------------------------------------------------------------------------------
-- 事件侦听
-------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

CrossUnionPkKnockoutScene = class(BaseUIScene)

function CrossUnionPkKnockoutScene:ctor()
end

-- knockoutInfo 后端提供的排位赛数据 -> CrossUnionPkGetKnockoutInfoRequest
function CrossUnionPkKnockoutScene:create(knockoutInfo)
	local s = CrossUnionPkKnockoutScene.new()

	s.knockoutInfo = knockoutInfo

	s.curSceneEnum = SceneEnum.CrossUnionPkKnockoutScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end

function CrossUnionPkKnockoutScene:onInit()
	BaseUIScene.initBackGround(self)

	local scroll_width
	local scroll_height
	local scroll_posX
	local scroll_posY
	local scroll_startPosY
	
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("endbattle/GvG_endbattle")
	self.tempLayer:addChild(ui)
	self.ui = ui

	--添加标题区域
	local titleUI = builder:build("Gvg_colosseuml_title")
	self:addChild(titleUI)
	self.titleUI = titleUI
	self.titleUI:setPositionY(visibleSize.height-35)
	self:addChild(titleUI)

	--隐藏不必要的内容
	self.titleUI:getChildByName("icon_Gvg_ranking"):setVisible(false)

	--状态栏区域
	local stateTitleDisplay = self.titleUI:getChildByName("bg_Gvg_title")

	--刷新自身
	local function refreshSelf()
		--初始化数据
		--总高度
		local totalHeight = 0
		--当前所处的时间区间
		local currentTimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()

		--先清空
		if self.scrollContainer then
			self.scrollContainer:removeFromParentAndCleanup(true)
			self.scrollContainer = nil
		end

		--滚动内容
		self.scrollContainer = CanonItem:create()
		self.scrollView:addChild(self.scrollContainer)

		--显示军团信息
		-- data = <bean desc="军团标识">
		-- 	<property code="serverId" type="int" desc="服务器id" />
		-- 	<property code="unionId" type="int" desc="军团id" />
		-- 	<property code="unionName" type="string" desc="军团名称" />
		-- </bean>
		local function setGuildData(display, data)
			display:getChildByName("txt_Gvg_15"):getChildByName("txt"):setString(CrossUnionPkUtils.getLocationStrById(data.serverId) or "")--{num}区
			display:getChildByName("txt_Gvg_16"):getChildByName("txt"):setString(data.unionName or "")--[军团名]
		end

		--向滚动列表里添加显示的战况内容
		local function addMatch(knockoutType, againstList)
			local groupDisplay = builder:build("endbattle/title_against")
			self.scrollContainer:addChild(groupDisplay)

			local groupSize = groupDisplay:getChildByName("white9_panel"):getPreferredSize()
			--print("groupSize.height = " .. tostringRich(groupSize.height))--663

			--显示标题
			groupDisplay:getChildByName("lbl_Gvg_00"):setVisible(false)
			groupDisplay:getChildByName("lbl_Gvg_01"):setVisible(false)
			groupDisplay:getChildByName("lbl_Gvg_02"):setVisible(false)
			groupDisplay:getChildByName("lbl_Gvg_07"):setVisible(false)
			groupDisplay:getChildByName("lbl_Gvg_06"):setVisible(false)
			if knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_16 then
				--16
				groupDisplay:getChildByName("lbl_Gvg_02"):setVisible(true)
			elseif knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_8 then
				--8
				groupDisplay:getChildByName("lbl_Gvg_01"):setVisible(true)
			elseif knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_4 then
				--4
				groupDisplay:getChildByName("lbl_Gvg_00"):setVisible(true)
			elseif knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD then
				--季军赛
				groupDisplay:getChildByName("lbl_Gvg_07"):setVisible(true)
			elseif knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION then
				--冠军赛
				groupDisplay:getChildByName("lbl_Gvg_06"):setVisible(true)
			end

			--添加对抗内容
			local againstSize = {height = 200}--给个默认值 防止信息错误情况崩溃
			-- v = <bean desc="跨服gvg战斗结果信息">
			-- 	<property code="id" type="int" desc="用于获取战报的id" />
			-- 	<property code="attUnion" ref="UnionIdentification" desc="进攻军团" />
			-- 	<property code="defUnion" ref="UnionIdentification" desc="防守军团" />
			-- 	<property code="win" type="boolean" desc="是否取胜" />
			-- </bean>
			for i, v in ipairs(againstList) do
				local againstDisplay = builder:build("endbattle/list_Gvg_against")
				againstSize = againstDisplay:getChildByName("yellow9_panel"):getPreferredSize()
				againstDisplay:setPositionX(5)
				againstDisplay:setPositionY(groupSize.height - _againstUpGap - (i-1) * (againstSize.height + _againstItemGap))
				--againstDisplay:setPositionY(_againstDownGap + (i+1) * (againstSize.height + _againstItemGap))
				--print("againstSize.height = " .. tostringRich(againstSize.height))
				--print("againstDisplay:getPositionY() = " .. tostringRich(againstDisplay:getPositionY()))
				groupDisplay:addChild(againstDisplay)

				--显示数据
				setGuildData(againstDisplay:getChildByName("Gvg_CorporationName"), v.attUnion)
				setGuildData(againstDisplay:getChildByName("Gvg_CorporationName2"), v.defUnion)

				--显示组名
				for k=1,8,1 do
					--print("_teamLableNames[k] = " .. tostringRich(_teamLableNames[k]))
					againstDisplay:getChildByName(_teamLableNames[k]):setVisible(false)
				end
				againstDisplay:getChildByName(_teamLableNames[i]):setVisible(true)

				--显示vs或者对抗查询按钮
				againstDisplay:getChildByName("icon_VV"):setVisible(false)
				againstDisplay:getChildByName("icon_fight_sv"):setVisible(false)

				againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming1"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming2"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming3"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("signInIcon_victory_f"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("signInIcon_negative_f"):setVisible(false)

				againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming1"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming2"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming3"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("signInIcon_victory_f"):setVisible(false)
				againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("signInIcon_negative_f"):setVisible(false)
				if CrossUnionPkCheck.isKnockoutMatching(currentTimeLevel, knockoutType) then
					--还没打完
					--显示vs标识
					againstDisplay:getChildByName("icon_fight_sv"):setVisible(true)
				else
					--已结束
					--显示录像按钮
					againstDisplay:getChildByName("icon_VV"):setVisible(true)

					--录像按钮处理
					local videoDisplay = againstDisplay:getChildByName("icon_VV")
					videoDisplay:addEventListener(DisplayEvents.kTouchBegin, onBtnBegin, cityId)
					videoDisplay:addEventListener(DisplayEvents.kTouchMove, onBtnMove, cityId)
					local videoButton = Button:create(videoDisplay)
					videoButton:addEventListener(Events.kStart, onVideoBtnClick, {id = v.id, knockoutType = knockoutType})

					--显示胜负
					againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("signInIcon_victory_f"):setVisible(v.win)
					againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("signInIcon_negative_f"):setVisible(not v.win)
					againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("signInIcon_victory_f"):setVisible(not v.win)
					againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("signInIcon_negative_f"):setVisible(v.win)

					--如果排名靠前 显示前三名图标
					if knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD then
						--季军赛结束 显示第三名图标
						againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming3"):setVisible(v.win)
						againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming3"):setVisible(not v.win)
					elseif knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION then
						--冠军赛结束 显示第一名和第二名图标
						againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming1"):setVisible(v.win)
						againstDisplay:getChildByName("Gvg_CorporationName"):getChildByName("icn_paiming2"):setVisible(not v.win)
						againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming1"):setVisible(not v.win)
						againstDisplay:getChildByName("Gvg_CorporationName2"):getChildByName("icn_paiming2"):setVisible(v.win)
					end
				end
			end

			local knockoutHegiht = _againstUpGap + #againstList*(againstSize.height + _againstItemGap) + _againstDownGap
			groupDisplay:getChildByName("white9_panel"):setPreferredSize(CCSizeMake(groupSize.width, knockoutHegiht))

			--print("knockoutHegiht = " .. tostringRich(knockoutHegiht))--663
			groupDisplay:setPositionY(totalHeight - (groupSize.height - knockoutHegiht))
			--print("groupDisplay:getPositionY() = " .. tostringRich(groupDisplay:getPositionY()))
			totalHeight = totalHeight + knockoutHegiht + _scrollItemGap
			--print("totalHeight = " .. tostringRich(totalHeight))
			--print("-----------------------------")
		end

		totalHeight = _scrollDownGap
		if currentTimeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 then
			--已到达16强角逐阶段
			addMatch(CrossUnionPkConsts.KNOCKOUT_TYPE_16, self.knockoutInfo.sixteen)
		end
		if currentTimeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8 then
			--已到达8强角逐阶段
			addMatch(CrossUnionPkConsts.KNOCKOUT_TYPE_8, self.knockoutInfo.eight)
		end
		if currentTimeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4 then
			--已到达4强角逐阶段
			addMatch(CrossUnionPkConsts.KNOCKOUT_TYPE_4, self.knockoutInfo.four)
		end
		if currentTimeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD then
			--已到季军赛角逐阶段
			addMatch(CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD, {self.knockoutInfo.thirdPlaceBattle})
			addMatch(CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION, {self.knockoutInfo.championBattle})
		end

		--设定滚动区域大小
		local contentSize = self.scrollContainer:getGroupBounds().size
		--print("contentSize.height = " .. tostringRich(contentSize.height))--
		self.scrollView:setContentSize(CCSizeMake(scroll_width, contentSize.height + _scrollUpGap))
		self.scrollView:setContentOffset(ccp(0, scroll_height - contentSize.height), false)
		self.scrollView:adjustHitArea()

		--是否倒计时处理
		stateTitleDisplay:getChildByName("txt_Gvg_10"):setVisible(false)
		stateTitleDisplay:getChildByName("txt_Gvg_09"):setVisible(false)
		stateTitleDisplay:getChildByName("txt_Gvg_22"):setVisible(false)
		stateTitleDisplay:getChildByName("txt_Gvg_21"):setVisible(false)
		stateTitleDisplay:getChildByName("txt_Gvg_08"):setVisible(false)
		if (currentTimeLevel <= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION) then
			--未全部结束 显示倒计时
			local nextTimeLevel = CrossUnionPkUtils.findNextTimeLevel(currentTimeLevel)--获得逻辑上下一段编号
			local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(nextTimeLevel)
			self.cdLabelComponent:setTargetTime(startTime + 1)--结束后要刷新 +1为了防止前后端时间差出问题
			self.cdLabelComponent:start()

			stateTitleDisplay:getChildByName("txt_Gvg_21"):setVisible(true)
			stateTitleDisplay:getChildByName("txt_Gvg_22"):setVisible(true)
			local battleName = CrossUnionPkUtils.getKnockoutNameByType(currentTimeLevel)
			stateTitleDisplay:getChildByName("txt_Gvg_21"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail30", {name=battleName}) .. " ")--距离{name}战斗还有
		else
			--不显示倒计时
			stateTitleDisplay:getChildByName("txt_Gvg_08"):setVisible(true)
			stateTitleDisplay:getChildByName("txt_Gvg_08"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail51"))--战斗结束
			self.cdLabelComponent:stop()
		end
	end
	self.refreshSelf = refreshSelf

	--每秒tick
	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		stateTitleDisplay:getChildByName("txt_Gvg_22"):getChildByName("txt"):setString(formatedTimeStr)
	end
	self.onTimeTick = onTimeTick

	--计时结束
	function onTimeComplete()
		local function onAfterSuccessed(evt)
			--更新数据
			self.knockoutInfo = evt.data
			self.refreshSelf()
		end
		CrossUnionPkGetKnockoutInfoRequest.sendRequestDefalut(onAfterSuccessed)
	end
	self.onTimeComplete = onTimeComplete

	--静态文本

	--按钮
	local backButton = Button:create(self.titleUI:getChildByName("r_click"))
	backButton:addEventListener(Events.kStart, onBackBtnClick, self)

	local qaButton = Button:create(self.titleUI:getChildByName("sky_btn_qa"))
	qaButton:addEventListener(Events.kStart, onQaBtnClick, self)

	---------------------------------------------------------------------------------------------------------滚动区域
	local shapeDisplay = self.ui:getChildByName("alpha_gray9_panel2")
	local scrollViewSize = shapeDisplay:getGroupBounds(self.ui).size

	local contentSize = shapeDisplay:getGroupBounds().size
	local contentHeight = contentSize.height
	--print("contentHeight = " .. tostringRich(contentHeight))

	scroll_width = scrollViewSize.width
	scroll_height = scrollViewSize.height
	scroll_posX = shapeDisplay:getPositionX()
	scroll_posY = shapeDisplay:getPositionY() - scroll_height + 1--整体上移一点
	scroll_startPosY = scroll_height - contentSize.height
	--print("scroll_height = " .. tostringRich(scroll_height))--953.8

	self.scrollView = ScrollView:create(scroll_width, scroll_height)

    self.scrollView:setPosition(ccp(scroll_posX, scroll_posY))
    --self.scrollView:setPosition(ccp(scroll_posX, 113))
    self.scrollView:setDirection(kCCScrollViewDirectionVertical)
    self.scrollView:setBounceable(false)--禁止拉出最大范围
    self.ui:addChild(self.scrollView)

    --print("shapeDisplay:getPositionY() = " .. tostringRich(shapeDisplay:getPositionY()))
    --print("self.scrollView:getPositionY() = " .. tostringRich(self.scrollView:getPositionY()))

    --不需要显示金币银币
    self.titleUI:getChildByName("icon_gold"):setVisible(false)
    self.titleUI:getChildByName("txt_Gvg_10_2"):setVisible(false)
    self.titleUI:getChildByName("icon_silverCoin"):setVisible(false)
    self.titleUI:getChildByName("txt_Gvg_10"):setVisible(false)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:addEventListener(UnionPkConsts.UNIONPK_REWARD_UPDATE, self.refreshSelf)


	--倒计时
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)

	self.refreshSelf()

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	--其他初始化操作
end

-----------------------------------------------内部接口------------------------------------------------------------

-----------------------------------------------外部接口------------------------------------------------------------

function CrossUnionPkKnockoutScene:setTableViewsEnabled(enabled)
	self.scrollView:setTouchEnabled(enabled)
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function CrossUnionPkKnockoutScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function CrossUnionPkKnockoutScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/m_unionPk.mp3", true)
end

function CrossUnionPkKnockoutScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))


	local aHeight = self.titleUI:getGroupBounds().size.height

	self.titleUI:setPositionY(self.titleUI:getPositionY() + aHeight)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.titleUI:runAction(CCSequence:create(arr))
end

function CrossUnionPkKnockoutScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CrossUnionPkKnockoutScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CrossUnionPkKnockoutScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function CrossUnionPkKnockoutScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))

	local aHeight = self.titleUI:getGroupBounds().size.height
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.titleUI:runAction(CCSequence:create(arr))
end

function CrossUnionPkKnockoutScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function CrossUnionPkKnockoutScene:back()
	CrossUnionPk.gotoCrossLoginUnionPkScene()
end

function CrossUnionPkKnockoutScene:dispose()
	--print("CrossUnionPkKnockoutScene:dispose")
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionPkConsts.UNIONPK_REWARD_UPDATE, self.refreshSelf)

	if self.cdLabelComponent then
		self.cdLabelComponent:stop()
		self.cdLabelComponent = nil
	end

	CrossUnionPkKnockoutScene.super.dispose(self)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 自有逻辑
-------------------------------------------------------------------------------