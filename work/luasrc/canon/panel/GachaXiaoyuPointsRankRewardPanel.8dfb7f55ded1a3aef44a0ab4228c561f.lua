--
-- GachaXiaoyuPointsRankRewardPanel.lua
-- Author: dc
-- Date: 2015-01-14 
--

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.customUI.CanonGoodIcon"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 610
local table_height = 468
local table_posX = 45
local table_posY = 325
local item_width = 600
local item_height = 100

GachaXiaoyuPointsRankRewardPanel = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTableViewsEnabled(evt.data == evt.context)
end

function GachaXiaoyuPointsRankRewardPanel:ctor()
    self.container = nil
    self.dataList = nil
end

function GachaXiaoyuPointsRankRewardPanel:create( container, extraArgs, onDataRefreshCallback )
    local s = GachaXiaoyuPointsRankRewardPanel.new()
	self.container = container
    self.extraArgs = extraArgs
    self.onDataRefreshCallback = onDataRefreshCallback
    s:initLayer()
    return s
end

function GachaXiaoyuPointsRankRewardPanel:scaleIn()
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
		self.tempLayer.touchEnabled = true
		self.tempLayer.touchChildren = true
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))

	UiStackManager.push(self)
	
end

function GachaXiaoyuPointsRankRewardPanel:dismiss()
	UiStackManager.remove(self)
	self.container.targetInfoPanel = nil
	self:removeFromParentAndCleanup(true)
	self.container:setTableViewsEnabled(true)
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
end

function GachaXiaoyuPointsRankRewardPanel:initLayer()
	GachaXiaoyuPointsRankRewardPanel.super.initLayer(self)
    
    self.container.targetInfoPanel = self

	local function refreshSelf()
		--排序
		local function sortFunc(a, b)
			--未领取在先
			local gainedA = Activity_GachaXiaoyuLayer.checkGained(a.id)
			local gainedB = Activity_GachaXiaoyuLayer.checkGained(b.id)
			if gainedA ~= gainedB then
				return not gainedA
			end

			--能领取在先
			local canGainA = Activity_GachaXiaoyuLayer:checkCanGain(a)
			local canGainB = Activity_GachaXiaoyuLayer:checkCanGain(b)
			if canGainA ~= canGainB then
				return canGainA
			end

			--metaId升序
			return (a.id < b.id)
		end
		table.sort(self.dataList, sortFunc)

		self.listTableView:reloadData()
	end
	self.refreshSelf = refreshSelf

	--点击确认
	local function onClose(evt)
		self:dismiss()
	end

	-- 背景层，用于缩放
	self.colorLayer = LayerColor:create()
	self.colorLayer:setOpacity(kDarkOpacity)
	self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.colorLayer)
	--
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
	--
	self.tempLayer:setScale(0.1)
  
	local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
	self.panelUI = builder:build("popup_launch_activity7") 
	self.tempLayer:addChild(self.panelUI)

	GachaXiaoyuPointsRankRewardPanel.super.initLayer(self)
	if not DataManager.GameMetaData.activityGachaXiaoyuConfig then
		self.dataList = {}
	else
		self.dataList = DataManager.GameMetaData.activityGachaXiaoyuConfig.crossGachaPointRewards or {}
	end

	--print("self.dataList = " .. table.tostring(self.dataList))

	self.listTableView = self:createListTableView()
	self.panelUI:addChild(self.listTableView)


	local featureNameBC = DataManager.GameMetaData.activityGachaXiaoyuConfig.featureNameReward


	self.panelUI:getChildByName("txt_activity_info1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_gachaXiaoyu_title"))
	self.panelUI:getChildByName("txt_la3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pointsRewardsDes"))
	self.panelUI:getChildByName("txt_la9"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-points"))
	self.panelUI:getChildByName("txt_la10"):getChildByName("txt"):setString(Activity_GachaXiaoyuLayer.getMyPoints())
	self.panelUI:getChildByName("txt_la4"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pointsEndingTime1"))
	local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime(featureNameBC)
	self.panelUI:getChildByName("txt_la5"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pointsEndingTime2", {year = activityGainRewardTimeInfo[2].year,month = activityGainRewardTimeInfo[2].month, day = activityGainRewardTimeInfo[2].day, time = activityGainRewardTimeInfo[2].time}))

	--确认按钮
	local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	self.refreshSelf()
end

function GachaXiaoyuPointsRankRewardPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {-31}
	local aListPanel = self
	local EquipFragmentListTableViewRenderer = class(TableViewRenderer)
	function EquipFragmentListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function EquipFragmentListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/list_launch_activity7_reward")
		aCell:setScaleX(0.95)
		aCell:setPositionX(30)
		container:addChild(aCell)
		aCell:setTag(cellTag)

		aCell:getChildByName("normal_card_small"):setVisible(false)

		--图标
		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)
		aCardDisplay:setVisible(false)

		local aCurrentNumLabel = aCell:getChildByName("txt_la7")
		aCurrentNumLabel:setTag(-11)
		aCurrentNumLabel = aCurrentNumLabel:getChildByName("txt")
		aCurrentNumLabel:setTag(-11)

		--达到...分 文本
		local aCollectInfo1 = aCell:getChildByName("txt_la6")
		aCollectInfo1:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-points1"))
		aCollectInfo1:setTag(-12)
		local aCollectInfo2 = aCell:getChildByName("txt_la8")
		aCollectInfo2:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-points2"))
		aCollectInfo2:setTag(-13)

		--按钮
		local aGainBtnDisplay = aCell:getChildByName("btn_getit")
		aGainBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_combineBtn"))
		aGainBtnDisplay:setTag(-31)
		aGainBtnDisplay:getChildByName("txt"):setTag(-31)
		aGainBtnDisplay:getChildByName("normal"):setTag(-32)
	end

	function EquipFragmentListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		-- local rewardInfo = Activity_GachaXiaoyuLayer.getRewardInfo(aData.rewardPackageId)
		-- --print("rewardInfo = " .. table.tostring(rewardInfo))
		-- --local equipMetaId = 213085
		-- local equipMetaId = rewardInfo.metaId

		local originalIcon_co = aCell:getChildByTag(-20)
		if originalIcon_co then
			originalIcon_co:removeFromParentAndCleanup(true)
		end

		local aCardDisplay =  aCell:getChildByTag(-10)

		local params = {}
		params.sourceDisplay = aCardDisplay
		params.isShowStar = true--显示稀有度星星
		params.container = aCell
		params.zindex = 10
		params.showAmount = true
		
		--local icon = CanonGoodIcon.createFirstGoodIconByPackageReward(aData.rewardPackageId, params)

		local packageRewardInfo = CanonGoodIcon.getRewardInfo(aData.rewardPackageId)
		local icon = CanonGoodIcon.createGoodIcon(packageRewardInfo.itemType, packageRewardInfo.metaId, packageRewardInfo.amount, params)
		if icon then
			icon:setTag(-20)
			icon:dispose()
		end


		local aCurrentNumLabel = aCell:getChildByTag(-11)
		setNodeText(aCurrentNumLabel:getChildByTag(-11), aData.pointMin)

		if  Activity_GachaXiaoyuLayer.checkGained(aData.id) then
			--已经领取
			setNodeText(aCell:getChildByTag(-31):getChildByTag(-31), Localization:getInstance():getText("activity-treasurebox-got"))
			aCell:getChildByTag(-31):getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-31).ignoreTouch = true
		else
			--未领取
			setNodeText(aCell:getChildByTag(-31):getChildByTag(-31), Localization:getInstance():getText("activity-treasurebox-get"))
			if Activity_GachaXiaoyuLayer.getMyPoints() < aData.pointMin then
				--不够
				aCell:getChildByTag(-31):getChildByTag(-32):setVisible(false)
				aCell:getChildByTag(-31).ignoreTouch = true
			else
				--足够
				aCell:getChildByTag(-31):getChildByTag(-32):setVisible(true)
				aCell:getChildByTag(-31).ignoreTouch = false
			end
		end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

		local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-31)
		local exchangeDisplay = buttonDisplay:getChildByTag(-32)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			-- print("onListItemTouch btnClicked")
			if Activity_GachaXiaoyuLayer:checkCanGain(self.dataList[aIndex]) then
				self:gain(self.dataList[aIndex])
			end
		end

		local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20)
		local cardSize = HeDisplayUtil:getNodeGroupBounds(cardDisplay, nil, kHitAreaObjectTag).size
		exchangeDisplay = cardDisplay
		-- print("posInCell.x = " .. posInCell.x)
		-- print("posInCell.y = " .. posInCell.y)
		-- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
		-- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
		--print("HeDisplayUtil:getNodeGroupBounds(cardDisplay, nil, kHitAreaObjectTag).size.width = " .. HeDisplayUtil:getNodeGroupBounds(cardDisplay, nil, kHitAreaObjectTag).size.width)
		if posInCell.x > (cardDisplay:getPositionX() - 52) and
		posInCell.x < (cardDisplay:getPositionX() + 52) and
		posInCell.y > (cardDisplay:getPositionY() - 52) and
		posInCell.y < (cardDisplay:getPositionY() + 52) then
			--点击按钮
			-- print("onListItemTouch cardClicked")
			self:openGood(self.dataList[aIndex])
		end
	end

	local renderer = EquipFragmentListTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	--aTableView:setDirection(kCCScrollViewDirectionHorizontal)
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))
	return aTableView
end

function GachaXiaoyuPointsRankRewardPanel:dispose()
	GachaXiaoyuPointsRankRewardPanel.super.dispose(self)
end

function GachaXiaoyuPointsRankRewardPanel:panelEnter(callback)
	ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function GachaXiaoyuPointsRankRewardPanel:panelExit(callback)
	ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function GachaXiaoyuPointsRankRewardPanel:setTableViewsEnabled(enabled)
	self.listTableView:setTouchEnabled(enabled)
end



--领奖
function GachaXiaoyuPointsRankRewardPanel:gain(aData)

	--成功
	local function onSucceed(event)
		--print("gain返回成功信息 = " .. table.tostring(event))
		--奖励物品
		--玩家点击确定获取
		local function onGet()
			--体现获得的奖励
			RewardManager:getReward(event.data.rewards)
			self:setTableViewsEnabled(true)

			if self.onDataRefreshCallback then
				self.onDataRefreshCallback()
			end
		end

		--显示获得的奖励
		--local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity-sworn-reward2"), callback = onGet} )
		self:setTableViewsEnabled(false)
		local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
		self.container:addChild(aRewardPanel)
		aRewardPanel:scaleIn()


		--更新物品数据
		Activity_GachaXiaoyuLayer.setGainedToList(aData.id)
		--print("Activity_GachaXiaoyuLayer.getTreasureboxPointsInfo().gainedPointRewards = " .. table.tostring(Activity_GachaXiaoyuLayer.getTreasureboxPointsInfo().gainedPointRewards))

		--进行刷新
		self.refreshSelf()
	end 

  ----------------------------------------gain
	if BagCalcManager.isFull() then
		--背包已满
		local aContent = Localization:getInstance():getText("shop_inventoryFull")
		-- SuspensionLabel:showContent(self, aContent)
		NewPackageFullPanel:show()
		return
	end

	--发送指令
	CrossGachaGainPointRewardRequest.sendRequest(aData.id, onSucceed, CrossGachaGainPointRewardRequest.onFailedDefault)
end

--弹出物品信息
function GachaXiaoyuPointsRankRewardPanel:openGood(aData)
	function onInfoClose()
		self:setTableViewTouched(true)
	end
	local packageRewardInfo = CanonGoodIcon.getRewardInfo(aData.rewardPackageId)
	CanonGoodIcon.popoutGoodPanel(packageRewardInfo.itemType, packageRewardInfo.metaId)

	self:setTableViewTouched(false)
end

--设置触摸是否开启
function GachaXiaoyuPointsRankRewardPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end