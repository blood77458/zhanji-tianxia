--
-- UnionApplierListPanel.lua
-- Author: zheng.che
-- Date: 2014-03-21 11:51:23
-- 申请者列表
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.UnionApplyRequest"
require "canon.request.UnionCancelApplyRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 714
local table_height = 908
local table_posX = 3
local table_posY = 115
local item_width = 714
local item_height = 221

UnionApplierListPanel = class(Layer)

function UnionApplierListPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionApplierListPanel:create( container, tagIndex )
	local s = UnionApplierListPanel.new()
	s:initLayer(container, tagIndex)
	return s
end

function UnionApplierListPanel:initLayer(container, tagIndex)
	local function refreshSelf()
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end

		local tempList = self.container.selectedApplierList
		--print("self.container.selectedApplierList = " .. table.tostring(self.container.selectedApplierList))

		for _, v in ipairs(tempList) do
			table.insert(self.dataList, v)
		end

		--对显示内容排序
		local function sortFunc(a, b)
			--申请时间 早的在前
			return b.applyTime < a.applyTime
		end
		table.sort(self.dataList, sortFunc)

		self.listTableView:reloadData()
	end
	self.refreshSelf = refreshSelf

	UnionApplierListPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = {}

	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)

	self.refreshSelf()
end

function UnionApplierListPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {-51, -52}
	local aListPanel = self
	local UnionListTableViewRenderer = class(TableViewRenderer)
	function UnionListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild_mem_list_examine")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		aCell:getChildByName("txt_guild_15_1"):getChildByName("txt"):setString(Localization:getInstance():getText("union_arena_rank_text"))--竞技场排名：
		aCell:getChildByName("txt_guild_15_2"):getChildByName("txt"):setString(Localization:getInstance():getText("union_fight_num_text"))--战斗力：
		aCell:getChildByName("btn_accept"):getChildByName("txt"):setString(Localization:getInstance():getText("union_examine_accept"))--接受
		aCell:getChildByName("btn_refuse"):getChildByName("txt"):setString(Localization:getInstance():getText("union_examine_refuse"))--拒绝

		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)
    
		local aNameLabel = aCell:getChildByName("txt_guild_member_name_l")
		aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-11)
    
		local aLevelLabel = aCell:getChildByName("txt_guild_14")
		aLevelLabel:setTag(-12)
		aLevelLabel = aLevelLabel:getChildByName("txt")
		aLevelLabel:setTag(-12)
    
		local aArenaRankLabel = aCell:getChildByName("txt_guild_16_1")
		aArenaRankLabel:setTag(-13)
		aArenaRankLabel = aArenaRankLabel:getChildByName("txt")
		aArenaRankLabel:setTag(-13)
    
		local aPowerLabel = aCell:getChildByName("txt_guild_16_2")
		aPowerLabel:setTag(-14)
		aPowerLabel = aPowerLabel:getChildByName("txt")
		aPowerLabel:setTag(-14)

		--同意按钮
		local aAcceptBtnDisplay = aCell:getChildByName("btn_accept")
		aAcceptBtnDisplay:setTag(-51)
		aAcceptBtnDisplay:getChildByName("btn"):setTag(-11)

		--拒绝按钮
		local aRejectBtnDisplay = aCell:getChildByName("btn_refuse")
		aRejectBtnDisplay:setTag(-52)
		aRejectBtnDisplay:getChildByName("btn"):setTag(-11)
	end

	function UnionListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		local aCardDisplay = aCell:getChildByTag(-10)

		local oldIcon = aCell:getChildByTag(-200)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, aData.mainCardMetaId, 1, params)
		aCell:addChild(icon.refCocosObj, 10)
		if icon then
			icon:setTag(-200)
			icon:dispose()
		end
    
		local aNameLabel = aCell:getChildByTag(-11)
		setNodeText(aNameLabel:getChildByTag(-11), aData.nickName or "")
    
		local aLevelLabel = aCell:getChildByTag(-12)
		setNodeText(aLevelLabel:getChildByTag(-12), aData.level or "")

		local aArenaRankLabel = aCell:getChildByTag(-13)
		if tonumber(aData.arenaRank) == -1 then
			--未上榜
			setNodeText(aArenaRankLabel:getChildByTag(-13), Localization:getInstance():getText("activityNian_outOfRank"))
		else
			setNodeText(aArenaRankLabel:getChildByTag(-13), aData.arenaRank or "")
		end

		local aPowerLabel = aCell:getChildByTag(-14)
		setNodeText(aPowerLabel:getChildByTag(-14), aData.fightCapacity or "")
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]

		local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-51)
		local exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			self:accept(aData)
		end

		buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-52)
		exchangeDisplay = buttonDisplay:getChildByTag(-11)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			self:reject(aData)
		end
	end

	local renderer = UnionListTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	--aTableView:setDirection(kCCScrollViewDirectionHorizontal)
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

function UnionApplierListPanel:dispose()
  UnionApplierListPanel.super.dispose(self)
end

function UnionApplierListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function UnionApplierListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function UnionApplierListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end

--同意
function UnionApplierListPanel:accept(aData)
	local function onSucceed(applierUid, event)
		--默认处理
		UnionAcceptRequest.onSucceedDefault(applierUid, event)

		--从列表中清除申请者
		self:delectApplier(applierUid)
		self.refreshSelf()
	end
	UnionAcceptRequest.sendRequest(aData.uid, onSucceed, UnionAcceptRequest.onFailedDefault)
end

--拒绝
function UnionApplierListPanel:reject(aData)
	local function onSucceed(applierUid, event)
		--默认处理
		UnionRejectRequest.onSucceedDefault(applierUid, event)

		--从列表中清除申请者
		self:delectApplier(applierUid)
		self.refreshSelf()
	end
	UnionRejectRequest.sendRequest(aData.uid, onSucceed, UnionRejectRequest.onFailedDefault)
end

--清除申请者
function UnionApplierListPanel:delectApplier(applierUid)
	local tempList = self.container.selectedApplierList
	for k, v in ipairs(tempList) do
		if v.uid == applierUid then
			table.remove(tempList, k)
		end
	end

	self.container.onDelectApplier()
end