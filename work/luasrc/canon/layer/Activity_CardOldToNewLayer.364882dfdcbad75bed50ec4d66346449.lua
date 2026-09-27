-- Activity_CardOldToNewLayer.lua
-- 2014-11-5
-- zheng.che
-- 卡牌以旧换新活动

require "canon.scene.CardOldToNewExchangeScene"
require "canon.panel.BatchSelectItemPanel"
require "canon.request.CardOldToNewExchangeRequest"
require "canon.customUI.CanonFullCard"
require "canon.customUI.ListView"
require "canon.customUI.PageListView"


--焦点变化事件
local function onFocusChanged(evt)
	local self = evt.context
	self:setTableViewTouched(evt.data == nil)
end

---------------------------------------------------------------------------------------------------------

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_CardOldToNewLayer = class(Layer)

---------------------------------------------------------------------------------------------------------

--是否进入过当前界面
local _hasEnterd = false
--兑换配置信息
local _cardExchangeMetaHash = nil--以hash表形式存储列表配置
--当前玩家的兑换信息
local _exchangeInfoHash = nil

---------------------------------------------------------------------------------------------------------

function Activity_CardOldToNewLayer:ctor()
  self.container = nil
end

function Activity_CardOldToNewLayer:create( container )
  self.container = container
  local s = Activity_CardOldToNewLayer.new()
  s:initLayer()
  return s
end

function Activity_CardOldToNewLayer:enable()
	--print("Activity_CardOldToNewLayer.getFeatureName() = " .. tostringRich(Activity_CardOldToNewLayer.getFeatureName()))
	local isEnable = MaintenanceManager.isActivityOpen(Activity_CardOldToNewLayer.getFeatureName())
	if SystemManager.debug then
		print("Activity_CardOldToNewLayer isEnable = " .. tostringRich(isEnable))
	end
	return isEnable
end 

function Activity_CardOldToNewLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_CardOldToNewLayer:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	Activity_CardOldToNewLayer.super.dispose(self)
end

function Activity_CardOldToNewLayer:initLayer()
    Activity_CardOldToNewLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/oldChangeNew.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("activity_oldChangeNew_vice")
	self:addChild(self.mainUI)

	--更改角标条件
	_hasEnterd = true

	--获得活动时间
	local timeTable = MaintenanceManager:getStartAndEndTime(Activity_CardOldToNewLayer.getFeatureName())

	--固定文字
	self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("cardExchange_duration"))--本期活动时间:
	self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("cardExchange_time", {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day}))--{month1}月{day1}日—{month2}月{day2}日

	--描边
	self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setColor(ccc3(22, 22, 22))
	self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))
	self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
	self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))

	--显示列表
	self.dataList = Activity_CardOldToNewLayer.getCardExchangeMetaList()
	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)
	self.listTableView:reloadData()

	--更新角标数
	self.container:resetTipInfoForActivity("Activity_CardExchange")

	--加侦听
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	if SystemManager.debug then
		print("Activity_CardOldToNewLayer.getMetas() = " .. tostringRich(Activity_CardOldToNewLayer.getMetas()))
		print("Activity_CardOldToNewLayer.getCardExchengeInfoHash() = " .. tostringRich(Activity_CardOldToNewLayer.getCardExchengeInfoHash()))
	end
end

--设置触摸是否开启
function Activity_CardOldToNewLayer:setTableViewTouched(enabled)
	self.listTableView:setTouchEnabled(enabled)
end

--------------------------------------------------------------------------------------------------------------------------------------tableview

function Activity_CardOldToNewLayer:createListTableView()
	local cellTag = 1024
	local buttonTag = {-100, -13}
	local aListPanel = self
	local cardOldNewListTableViewRenderer = class(TableViewRenderer)
	function cardOldNewListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function cardOldNewListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/oldChangeNew.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/oldChangeNew_01_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		aCell:getChildByName("btn"):getChildByName("txt_propInfo_useBtn"):setString(getTextByKey("cardExchange_exchange"))--兑换
		aCell:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("cardExchange_txt1"))--可兑换数量:
		
		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)

		local aNameLabel = aCell:getChildByName("txt_01")
		aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-11)

		local aExchangeNumLabel = aCell:getChildByName("txt_03")
		aExchangeNumLabel:setTag(-12)
		aExchangeNumLabel = aExchangeNumLabel:getChildByName("txt")
		aExchangeNumLabel:setTag(-11)

		local aExchangeBtn = aCell:getChildByName("btn")
		aExchangeBtn:setTag(-13)
		aExchangeBtn = aExchangeBtn:getChildByName("normal")
		aExchangeBtn:setTag(-11)
	end

	function cardOldNewListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		--
		local aCardDisplay = aCell:getChildByTag(-10)
		local aNameLabel = aCell:getChildByTag(-11)
		local aExchangeNumLabel = aCell:getChildByTag(-12)
		local aExchangeBtn = aCell:getChildByTag(-13)


		--显示头像
		local oldIcon = aCell:getChildByTag(-100)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, aData.cardId, 0, params)
		aCell:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
		if icon then
			icon:setTag(-100)
			icon:dispose()
		end

		local cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, aData.cardId, 0, {withoutAmount = true})
		setNodeText(aNameLabel:getChildByTag(-11), cardName or "")

		local currentExchangeNum = Activity_CardOldToNewLayer.getCurrentExchangeNum(aData.id)--当前兑换数量
		setNodeText(aExchangeNumLabel:getChildByTag(-11), currentExchangeNum .. "/" .. aData.exchangeNum)

		--按钮的状态
		if Activity_CardOldToNewLayer.canEnterScene(aData) then
			--可以点击
			aExchangeBtn:getChildByTag(-11):setVisible(true)
			aExchangeBtn.ignoreTouch = false
		else
			--不可点击
			aExchangeBtn:getChildByTag(-11):setVisible(false)
			aExchangeBtn.ignoreTouch = true
		end
	end

	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local aData = self.dataList[aIndex]

		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)

		local posInCell = aCell:convertToNodeSpace(evt.globalPosition)

		local cardDisplay = aCell:getChildByTag(-10)
		exchangeDisplay = cardDisplay
		exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
		-- print("posInCell.x = " .. posInCell.x)
		-- print("posInCell.y = " .. posInCell.y)
		-- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
		-- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
		-- print("exchangeSize.width = " .. exchangeSize.width)
		-- print("exchangeSize.height = " .. exchangeSize.height)
		if posInCell.x > (cardDisplay:getPositionX()) and
		posInCell.x < (cardDisplay:getPositionX() + exchangeSize.width) and
		posInCell.y > (cardDisplay:getPositionY() - exchangeSize.height) and
		posInCell.y < (cardDisplay:getPositionY()) then
			--点击头像
			Activity_CardOldToNewLayer.openCard(aData.cardId)
			return
		end

		local aExchangeBtn = aCell:getChildByTag(-13)
		exchangeDisplay = aExchangeBtn
		exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
		-- print("posInCell.x = " .. posInCell.x)
		-- print("posInCell.y = " .. posInCell.y)
		-- print("aExchangeBtn:getPositionX() = " .. aExchangeBtn:getPositionX())
		-- print("aExchangeBtn:getPositionY() = " .. aExchangeBtn:getPositionY())
		-- print("exchangeSize.width = " .. exchangeSize.width)
		-- print("exchangeSize.height = " .. exchangeSize.height)
		if posInCell.x > (aExchangeBtn:getPositionX()) and
		posInCell.x < (aExchangeBtn:getPositionX() + exchangeSize.width) and
		posInCell.y > (aExchangeBtn:getPositionY() - exchangeSize.height) and
		posInCell.y < (aExchangeBtn:getPositionY()) then
			--点击按钮
			if Activity_CardOldToNewLayer.canEnterScene(aData) then
				Activity_CardOldToNewLayer.gotoScene(aData)
			end
			return
		end
	end

	local tableViewSizes = getTableViewSizes(self.mainUI:getChildByName("table_oldChangeNew_list"))
	self.mainUI:getChildByName("table_oldChangeNew_list"):setVisible(false)
	--print("tableViewSizes = " .. tostringRich(tableViewSizes))
	local renderer = cardOldNewListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

--------------------------------------------------------------------------------------------------------------------------------------static

function Activity_CardOldToNewLayer.clear()
	_hasEnterd = false
	_cardExchangeMetaHash = nil
	_exchangeInfoHash = nil
end

function Activity_CardOldToNewLayer.getTipNum()
	if not Activity_CardOldToNewLayer:enable() then
		--活动未开启
		return 0
	end
	
	local metaList = Activity_CardOldToNewLayer.getCardExchangeMetaList()
	for i, v in ipairs(metaList) do
		local currentExchangeNum = Activity_CardOldToNewLayer.getCurrentExchangeNum(v.id)--当前兑换数量
		if currentExchangeNum < v.exchangeNum then
			--还有没兑换的
			if not _hasEnterd then
				--没有进入过界面
				return 1
			end
		end
	end
	return 0
end

--获得配置
function Activity_CardOldToNewLayer.getMetas()
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~"..tostringRich(DataManager.GameMetaData.activityCardExchangeConfig))
	return DataManager.GameMetaData.activityCardExchangeConfig
end

--获得活动开关名称
function Activity_CardOldToNewLayer.getFeatureName()
	local metas = Activity_CardOldToNewLayer.getMetas()

	if SystemManager.debug then
		DebugManager.assert(metas ~= nil, "Activity_CardOldToNewLayer 无法获得featureName! ")
	end

	if not metas then
		--防崩
		return "nullName"
	end
	return metas.featureName
end

--同系列材料卡牌星灵系数
function Activity_CardOldToNewLayer.getOldCardRatio()
	local metas = Activity_CardOldToNewLayer.getMetas()
	if not metas then
		return 1
	end
	return metas.oldCardRatio
end

--兑换卡牌所需星灵系数
function Activity_CardOldToNewLayer.getNewCardRatio()
	local metas = Activity_CardOldToNewLayer.getMetas()

	if not metas then
		return 1
	end
	return metas.newCardRatio
end

--六星卡牌消耗星灵
function Activity_CardOldToNewLayer.getSixCost()
	local metas = Activity_CardOldToNewLayer.getMetas()
	if not metas then
		return 1
	end
	return metas.sixCost
end

--可兑换卡牌配置 list
function Activity_CardOldToNewLayer.getCardExchangeMetaList()
	local metas = Activity_CardOldToNewLayer.getMetas()
	if not metas then
		return {}
	end
	return metas.cardExchangeMeta
end

--查找获得卡牌具体配置
-- <bean desc="兑换信息配置">
-- 	<property code="id" type="int" desc="配置序列" />
-- 	<property code="cardId" type="int" desc="兑换卡牌metaId" />
-- 	<property code="secretNum" type="int" desc="需要星灵数量" />
-- 	<property code="exchangeNum" type="int" desc="卡牌兑换上限" />
-- </bean>
function Activity_CardOldToNewLayer.getCardExchangeMetaById(exchangeId)
	local cardExchangeMetaList = Activity_CardOldToNewLayer.getCardExchangeMetaList()
	if not cardExchangeMetaList then
		return {}
	end

	if not _cardExchangeMetaHash then
		--array转hash 只转一次
		_cardExchangeMetaHash = {}
		for i, v in ipairs(cardExchangeMetaList) do
			local meta = cardExchangeMetaList[i]

			_cardExchangeMetaHash[meta.id] = meta
		end
	end

	local result = _cardExchangeMetaHash[exchangeId]
	if SystemManager.debug then
		DebugManager.assert(result ~= nil, "Activity_CardOldToNewLayer 没有这个兑换卡牌! exchangeId = " .. tostringRich(exchangeId))
	end
	
	return result
end

------------------------------------------

--获得当前的兑换信息 hash
-- <bean desc="卡牌兑换信息">
-- 	<property code="shopId" type="int" desc="卡牌兑换标示" />
-- 	<property code="exchangeNum" type="int" desc="已兑换次数" />
-- </bean>
function Activity_CardOldToNewLayer.getCardExchengeInfoHash()
	if not _exchangeInfoHash then
		local gameInitData = DataManager.getGameInitData()
		if not gameInitData.sharkActivity then
			--这时候还没有数据
			return {}
		end

		local cardEchangeInfoList = gameInitData.sharkActivity.cardExchangeInfo or {}
		_exchangeInfoHash = {}
		for i, v in ipairs(cardEchangeInfoList) do
			_exchangeInfoHash[v.shopId] = v
		end
	end
	return _exchangeInfoHash
end

--增加已经兑换的数量
function Activity_CardOldToNewLayer.addCurrentExchangeNum(exchangeId)
	local hash = Activity_CardOldToNewLayer.getCardExchengeInfoHash()
	if hash[exchangeId] == nil then
		hash[exchangeId] = {shopId = exchangeId, exchangeNum = 0}
	end
	hash[exchangeId].exchangeNum = hash[exchangeId].exchangeNum + 1
end

--获得已经兑换的数量
function Activity_CardOldToNewLayer.getCurrentExchangeNum(exchangeId)
	local hash = Activity_CardOldToNewLayer.getCardExchengeInfoHash()
	if hash[exchangeId] == nil then
		return 0
	end
	return hash[exchangeId].exchangeNum
end

------------------------------------------

--弹出卡牌信息
function Activity_CardOldToNewLayer.openCard(cardMetaId)
	--print("cardMetaId = " .. tostringRich(cardMetaId))
	CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, cardMetaId)
end

--进入兑换场景
--exchangeId 兑换编号
function Activity_CardOldToNewLayer.gotoScene(aData)
	local argv = {}
	argv.params = {}
	argv.params.exchangeId = aData.id
	argv.params.specialExchange = aData.specialExchange
	argv.params.layer = Activity_CardOldToNewLayer
	Director:sharedDirector():replaceScene(CardOldToNewExchangeScene:create(argv))
end

------------------------------------------

-- 查询是否能进入场景
-- aData 配置数据
function Activity_CardOldToNewLayer.canEnterScene(aData)
	local currentExchangeNum = Activity_CardOldToNewLayer.getCurrentExchangeNum(aData.id)--当前兑换数量
	if currentExchangeNum >= aData.exchangeNum then
		return false
	end
	return true
end


-- <bean desc="玩家的卡牌信息">
-- 	<property code="cardId" type="int" desc="卡牌id" />
-- 	<property code="metaId" type="int" desc="卡牌配置id" />
-- 	<property code="level" type="int" desc="卡牌等级" />
-- 	<property code="exp" type="int" desc="卡牌经验" />
-- 	<property code="usedPotential" type="int" desc="用掉的潜力值" />
-- 	<property code="attTrainValue" type="int" desc="培养得来的攻击属性增量" />
-- 	<property code="defTrainValue" type="int" desc="培养得来的防御属性增量" />
-- 	<property code="hpTrainValue" type="int" desc="培养得来的血量属性增量" />
-- 	<property code="attEvolveValue" type="int" desc="进阶获得的血量属性增量" />
-- 	<property code="defEvolveValue" type="int" desc="进阶获得的血量属性增量" />
-- 	<property code="hpEvolveValue" type="int" desc="进阶获得的血量属性增量" />
-- 	<list code="equipIds" type="int" desc="已安装的装备列表"/>
-- 	<list code="cardSkills" ref="CardSkill" desc="卡牌拥有的技能" />
-- 	<list code="cardSpirits" ref="CardSpirits" desc="已装备的元神列表"/>
-- 	<property code="lock" type="boolean" desc="是否锁定" />
-- 	<property code="avatarMetaId" type="int" desc="武将头像metaId" />
-- </bean>