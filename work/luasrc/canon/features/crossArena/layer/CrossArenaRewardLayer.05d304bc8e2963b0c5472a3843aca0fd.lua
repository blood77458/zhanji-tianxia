-- CrossArenaRewardLayer.lua
-- 2015-3-10
-- zheng,che
-- 跨服pvp领奖界面

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--获取奖励
local function onGainClick(evt)
	local self = evt.context

	if CrossArenaCheck.canGainRankReward(true) then
		--允许领取
		local function onAfterSucceed(evt)
			self.refreshSelf()
		end
		CrossPvpGainBattleRewardRequest.sendRequestDefalut(CrossArenaConsts.REWARD_TYPE_RANK, onAfterSucceed)
	end
end

--奖励预览
local function onPerviewClick(evt)
	local self = evt.context

  	local aInfoPanel = CrossArenaRewardReviewPanel:create(self.container)
  	self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
end

--冠军福利
local function onTopGainClick(evt)
	local self = evt.context

	if CrossArenaCheck.canGainTopReward(true) then
		--允许领取
		local function onAfterSucceed(evt)
			self.refreshSelf()
		end
		CrossPvpGainBattleRewardRequest.sendRequestDefalut(CrossArenaConsts.REWARD_TYPE_SERVER, onAfterSucceed)
	end
end

---------------------------------------------------------------------------------------------------------

CrossArenaRewardLayer = class(Layer)

function CrossArenaRewardLayer:ctor()
	self.container = nil
end

function CrossArenaRewardLayer:create( container , extraArgs)
	self.container = container
	self.extraArgs = extraArgs
	local s = CrossArenaRewardLayer.new()
	s:initLayer()
	return s
end

function CrossArenaRewardLayer:panelDismiss()
	self.container.targetInfoPanel = nil
end

function CrossArenaRewardLayer:initLayer()
	CrossArenaRewardLayer.super.initLayer(self)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("table_crossArena_jj")
	self:addChild(self.mainUI)

	local function refreshSelf()
		--检查奖励领取状态
		if CrossArenaManager.canGainRankReward() then
			--可以领取
			self.mainUI:getChildByName("bg_group_l"):setVisible(true)
			self.mainUI:getChildByName("bg_group_r"):setVisible(true)
			if not CrossArenaManager.isGainedRankReward() then
				--还没领取
				self.gainBtn:setEnable(true)
				self.gainBtn:setVisible(true)
				self.mainUI:getChildByName("lbl_crossArena_05"):setVisible(false)
			else
				--已领取
				self.gainBtn:setEnable(false)
				self.gainBtn:setVisible(false)
				self.mainUI:getChildByName("lbl_crossArena_05"):setVisible(true)
			end
		else
			--不可领取
			self.gainBtn:setEnable(false)
			self.gainBtn:setVisible(false)
			self.mainUI:getChildByName("lbl_crossArena_05"):setVisible(false)
			self.mainUI:getChildByName("bg_group_l"):setVisible(false)
			self.mainUI:getChildByName("bg_group_r"):setVisible(false)
		end

		--检查冠军奖领取状态
		if CrossArenaManager.canGainServerReward() then
			--可以领取
			if not CrossArenaManager.isGainedServerReward() then
				--还没领取
				self.topGainBtn:setEnable(true)
				self.topGainBtn:setVisible(true)
			else
				--已领取
				self.topGainBtn:setEnable(false)
				self.topGainBtn:setVisible(false)
			end
		else
			--不可领取
			self.topGainBtn:setEnable(false)
			self.topGainBtn:setVisible(false)
		end
	end
	self.refreshSelf = refreshSelf

	--倒计时tick
	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		self.mainUI:getChildByName("txt_jj_2"):getChildByName("txt"):setString(formatedTimeStr)
	end
	self.onTimeTick = onTimeTick

	--显示小格
	-- cell.displayInited 表示显示组件已初始化
	function onCellDataSet(cell)
		-- <bean desc="排行榜信息">
		-- 	<property code="rank" type="int" desc="排名" />
		-- 	<property code="battleScore" type="int" desc="天梯积分" />
		-- 	<property code="metaId" type="int" desc="主卡牌ID" />
		-- 	<property code="nickName" type="string" desc="昵称" />
		-- 	<property code="level" type="int" desc="等级" />
		-- 	<property code="server" type="int" desc="服务器" />
		-- 	<property code="unionName" type="string" desc="军团名称" />
		-- 	<property code="combat" type="int" desc="战斗力" />
		-- </bean>
		if cell.display and cell.data then
			if not cell.displayInited then
				--固定不会更改的静态内容
				cell.display:getChildByName("txt_jj_3"):getChildByName("txt"):setString(CrossArenaUtils.getLocationStrById(cell.data.server))--[]
				cell.display:getChildByName("txt_jj_4"):getChildByName("txt"):setString(cell.data.nickName)--[]
				cell.display:getChildByName("txt_jj_5"):getChildByName("txt"):setString(cell.data.unionName or "")--[]

				cell.display:getChildByName("lbl_1st_jj"):setVisible(false)
				cell.display:getChildByName("lbl_2nd_jj"):setVisible(false)
				cell.display:getChildByName("lbl_3rd_jj"):setVisible(false)
				if cell.data.rank == 1 then
					cell.display:getChildByName("lbl_1st_jj"):setVisible(true)
				elseif cell.data.rank == 2 then
					cell.display:getChildByName("lbl_2nd_jj"):setVisible(true)
				elseif cell.data.rank == 3 then
					cell.display:getChildByName("lbl_3rd_jj"):setVisible(true)
				end

				--显示卡牌大图
				if cell.display.cardIcon then
					cell.display.cardIcon:removeFromParentAndCleanup(true)
				end
				local aCardDisplay = cell.display:getChildByName("half_2")
				aCardDisplay:setVisible(false)
				local params = {}
				params.sourceDisplay = aCardDisplay
				params.scales = {0.7, 0.7}
				params.showInCenter = true

				local metaId = CommonManager:getSelfAvatarMetaByUid( cell.data.uid )
				if not metaId then
					metaId = cell.data.metaId
				end

				cell.display.cardIcon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_HALF, metaId, 0, params)
				cell.display.cardIcon:setPositionY(cell.display.cardIcon:getPositionY() - 150)
				cell.display:addChildAt(cell.display.cardIcon, aCardDisplay:getZOrder())

				local image = getFullCardSpriteFrame(cell.data.metaId)
				cell.display:addChild(image)


				--设定为已初始化
				cell.displayInited = true
			end

			--随数据变化内容...
		end
	end

	--清除小格
	function onCellDataRemove(cell)
	end

	--不会变的文本
	self.mainUI:getChildByName("btn_yellow_long_jj"):getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_gainBattleReward"))--领取奖励
	self.mainUI:getChildByName("txt_jj_1"):getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_rewardStageText", {num1 = ""}))--本届跨服竞技已结束，距离下次开启还有
	--self.mainUI:getChildByName("xxx"):getChildByName("txt"):setString(Localization:getInstance():getText("xxx"))--xxx

	--按钮
	--获取奖励
	self.gainBtn = Button:create(self.mainUI:getChildByName("btn_yellow_long_jj"))
	self.gainBtn:addEventListener(Events.kStart, onGainClick, self)
	--奖励预览
	self.perviewBtn = Button:create(self.mainUI:getChildByName("icon_reward_tab_jj"))
	self.perviewBtn:addEventListener(Events.kStart, onPerviewClick, self)
	--冠军福利
	self.topGainBtn = Button:create(self.mainUI:getChildByName("btn_welfare"))
	self.topGainBtn:addEventListener(Events.kStart, onTopGainClick, self)

	--显示默认时间(00:00:00)
	self.mainUI:getChildByName("txt_jj_2"):getChildByName("txt"):setString(TimeUtil.formatTime(0))

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, nil)
	if SystemManager.debug then
		print("xxxxxTimeUtil.getServerTimeSeconds() = " .. tostringRich(TimeUtil.getServerTimeSeconds()))
		print("CrossArenaManager.getRewardEndTime() = " .. tostringRich(CrossArenaManager.getRewardEndTime()))
	end
	self.cdLabelComponent:setTargetTime(CrossArenaManager.getRewardEndTime())
	self.cdLabelComponent:start()

	--列表组件
	self.listView = ListView:create(onCellDataSet, onCellDataRemove, nil, nil)
	self.listView:setDisplay(self.mainUI, "bg_jj_3_")
	--显示列表
	self.listView:setDataList(CrossArenaManager.getTop3Ranks())

	self.refreshSelf()
end

function CrossArenaRewardLayer:dispose()
	--销毁列表组件
	if self.listView then
		self.listView:dispose()
	end

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	CrossArenaRewardLayer.super.dispose(self)
end

----------------------------------------------------------------------
-- 列表操作
----------------------------------------------------------------------

----------------------------------------------------------------------
-- 切页动作
----------------------------------------------------------------------

-- 进入页面
function CrossArenaRankLayer:panelEnter(callback)
	if self.listTableView then
		ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
	else
	    if callback then
		    callback()
		end
	end
end

-- 退出页面
function CrossArenaRankLayer:panelExit(callback)
	if self.listTableView then
		ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
	else
	    if callback then
		    callback()
		end
	end
end

--设置触摸是否开启
function CrossArenaRankLayer:setTableViewTouched(enabled)
	if self.listTableView then
		self.listTableView:setTouchEnabled(enabled)
	end
end