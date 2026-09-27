--
-- UnionListPanel.lua
-- Author: zheng.che
-- Date: 2014-03-17 15:20:07
-- 军团列表panel
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
local table_posY = 125
local item_width = 714
local item_height = 221

UnionListPanel = class(Layer)

function UnionListPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionListPanel:create( container, tagIndex )
	local s = UnionListPanel.new()
	s:initLayer(container, tagIndex)
	return s
end

function UnionListPanel:initLayer(container, tagIndex)
	local function refreshSelf(keepOffset)
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end

		local tempList = self.container.selectedDataList
		--print("self.container.selectedDataList = " .. table.tostring(self.container.selectedDataList))

		for _, v in ipairs(tempList) do
			table.insert(self.dataList, v)
		end

		if keepOffset then
			--保持列表位置
			local tableOffset = self.listTableView:getContentOffset()
			self.listTableView:reloadData()
			self.listTableView:setContentOffset(tableOffset, true)
		else
			self.listTableView:reloadData()
		end
		
		self.container.refreshSelf()
	end
	self.refreshSelf = refreshSelf

	UnionListPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = {}

	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)

	self.refreshSelf(false)
end

function UnionListPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {-51}
	local aListPanel = self
	local UnionListTableViewRenderer = class(TableViewRenderer)
	function UnionListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		aCell:getChildByName("txt_guild9"):getChildByName("txt"):setString(Localization:getInstance():getText("union_major_text_key"))--军团长
		aCell:getChildByName("txt_guild10"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_num_text_key"))--成员

		local aCardDisplay = aCell:getChildByName("icon_number_bg")
		aCardDisplay:setTag(-10)
    
		local aUnionNameLabel = aCell:getChildByName("txt_guild_name")
		aUnionNameLabel:setTag(-11)
		aUnionNameLabel = aUnionNameLabel:getChildByName("txt")
		aUnionNameLabel:setTag(-11)
    
		local aUnionLevelLabel = aCell:getChildByName("txt_guild8")
		aUnionLevelLabel:setTag(-12)
		aUnionLevelLabel = aUnionLevelLabel:getChildByName("txt")
		aUnionLevelLabel:setTag(-12)
    
		local aLeaderNickLabel = aCell:getChildByName("txt_guild11")
		aLeaderNickLabel:setTag(-13)
		aLeaderNickLabel = aLeaderNickLabel:getChildByName("txt")
		aLeaderNickLabel:setTag(-13)
    
		local aLeaderLevelLabel = aCell:getChildByName("txt_guild8_1")
		aLeaderLevelLabel:setTag(-14)
		aLeaderLevelLabel = aLeaderLevelLabel:getChildByName("txt")
		aLeaderLevelLabel:setTag(-14)
		--描边
		aLeaderLevelLabel:setColor(ccc3(255, 198, 2))
		aLeaderLevelLabel:setAroundColor(ccc3(50, 10, 10))
    
		local aMemberNumLabel = aCell:getChildByName("txt_guild12")
		aMemberNumLabel:setTag(-15)
		aMemberNumLabel = aMemberNumLabel:getChildByName("txt")
		aMemberNumLabel:setTag(-15)
    
		local aUnionDeclarationLabel = aCell:getChildByName("txt_guild13")
		aUnionDeclarationLabel:setTag(-16)
		aUnionDeclarationLabel = aUnionDeclarationLabel:getChildByName("txt")
		aUnionDeclarationLabel:setTag(-16)

		--军团排名圆圈
		local aRing1 = aCell:getChildByName("flower_guild_ranking_1")
		aRing1:setTag(-17)
		local aRing2 = aCell:getChildByName("flower_guild_ranking_2")
		aRing2:setTag(-18)
		local aRing3 = aCell:getChildByName("flower_guild_ranking_3")
		aRing3:setTag(-19)

		--军团排名背景
		local aBg1 = aCell:getChildByName("bg_hall_guild_1")
		aBg1:setTag(-20)
		local aBg2 = aCell:getChildByName("bg_hall_guild_2")
		aBg2:setTag(-21)
		local aBg3 = aCell:getChildByName("bg_hall_guild_3")
		aBg3:setTag(-22)

		--申请/取消申请按钮
		local aCombineBtnDisplay = aCell:getChildByName("btn_apply")
		aCombineBtnDisplay:setTag(-51)
		aCombineBtnDisplay:getChildByName("txt"):setTag(-51)
		aCombineBtnDisplay:getChildByName("btn"):setTag(-52)
		aCombineBtnDisplay:getChildByName("btn_inactive"):setTag(-53)
	end

	function UnionListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))

		--没有排名的特殊情况 一般不会出现
		if aData.rank == -1 then
			aData.rank = 999
		end

		local numberLabel = aCell:getChildByTag(-41)
		if numberLabel then
			numberLabel:removeFromParentAndCleanup(true)
		end
		local aCardDisplay = aCell:getChildByTag(-10)
		local cardSize = HeDisplayUtil:getNodeGroupBounds(aCardDisplay, nil, kHitAreaObjectTag).size
		numberLabel = CCLabelAtlas:create(tostring(aData.rank), "pic/guildrank_number.png", 35, 43, 48)
		--numberLabel:setScale(1.25)
		numberLabel:setAnchorPoint(ccp(0.5, 0.5))
		numberLabel:setPosition(ccp(aCardDisplay:getPositionX() + cardSize.width/2, aCardDisplay:getPositionY() - cardSize.height/2))
		aCell:addChild(numberLabel, 11)
		--self.nextNumberLabel = numberLabel
		numberLabel:setTag(-41)
    
		local aUnionNameLabel = aCell:getChildByTag(-11)
		setNodeText(aUnionNameLabel:getChildByTag(-11), aData.name or "")
    
		local aUnionLevelLabel = aCell:getChildByTag(-12)
		setNodeText(aUnionLevelLabel:getChildByTag(-12), aData.level or "")

		local aLeaderNickLabel = aCell:getChildByTag(-13)
		setNodeText(aLeaderNickLabel:getChildByTag(-13), aData.managerName or "")

		local aLeaderLevelLabel = aCell:getChildByTag(-14):getChildByTag(-14)
		setNodeText(aLeaderLevelLabel, aData.managerLevel or "")

		local aMemberNumLabel = aCell:getChildByTag(-15)
		setNodeText(aMemberNumLabel:getChildByTag(-15), aData.memberNum .. "/" .. UnionManager.getMaxMemberCountByUnionLevel(aData.level))

		local aUnionDeclarationLabel = aCell:getChildByTag(-16)
		setNodeText(aUnionDeclarationLabel:getChildByTag(-16), aData.declaration or "")

		--排名显示
		local aRing1 = aCell:getChildByTag(-17)
		local aRing2 = aCell:getChildByTag(-18)
		local aRing3 = aCell:getChildByTag(-19)
		local aBg1 = aCell:getChildByTag(-20)
		local aBg2 = aCell:getChildByTag(-21)
		local aBg3 = aCell:getChildByTag(-22)
		if tonumber(aData.rank) == 1 then
			aRing1:setVisible(true)
			aRing2:setVisible(false)
			aRing3:setVisible(false)
			aBg1:setVisible(true)
			aBg2:setVisible(false)
			aBg3:setVisible(false)
			aCardDisplay:setVisible(false)
		elseif tonumber(aData.rank) == 2 then
			aRing1:setVisible(false)
			aRing2:setVisible(true)
			aRing3:setVisible(false)
			aBg1:setVisible(false)
			aBg2:setVisible(true)
			aBg3:setVisible(false)
			aCardDisplay:setVisible(false)
		elseif tonumber(aData.rank) == 3 then
			aRing1:setVisible(false)
			aRing2:setVisible(false)
			aRing3:setVisible(true)
			aBg1:setVisible(false)
			aBg2:setVisible(false)
			aBg3:setVisible(true)
			aCardDisplay:setVisible(false)
		else
			aRing1:setVisible(false)
			aRing2:setVisible(false)
			aRing3:setVisible(false)
			aBg1:setVisible(false)
			aBg2:setVisible(false)
			aBg3:setVisible(false)
			aCardDisplay:setVisible(true)
		end

		local aApplyBtn = aCell:getChildByTag(-51)
		if UnionManager.isInUnion() then
			--已经入团 不显示按钮
			aApplyBtn:setVisible(false)
		else
			--不在军团 显示按钮
			aApplyBtn:setVisible(true)
			if UnionManager.isAppliedThisUnion(aData.unionId) then
				--已经申请此军团
				setNodeText(aApplyBtn:getChildByTag(-51), Localization:getInstance():getText("union_apply_button_give_up"))--取消申请
			else
				--未申请此军团
				setNodeText(aApplyBtn:getChildByTag(-51), Localization:getInstance():getText("union_apply_button"))--申请
			end
		end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]

		local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-51)
		local exchangeDisplay = buttonDisplay:getChildByTag(-52)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			if not UnionManager.isInUnion() then
				--不在军团才能点
				if not UnionManager.isAppliedThisUnion(aData.unionId) then
					--未申请此军团
					if UnionManager.canJoinUnion(aData, true) then
						self:join(aData)
					end
				else
					--已经申请此军团
					self:unJoin(aData)
				end
			end
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

	--拉伸导致获取靠前排名信息
	function onDragUp()
		if self.tagIndex == UnionListTagEnum.UNION_LIST then
			local topRank = self:findTopRank()
			if topRank == 1 then
				--已经是首位 不允许朝上拉
				return
			end
			topRank = topRank - 20
			if topRank < 1 then
				topRank = 1
			end
			local function onSucceed(startNum, amount, requestEvent)
				--默认处理
				UnionGetUnionListRequest.onSucceedDefault(startNum, amount, requestEvent)

				if requestEvent.data.sharkUnionWrappers and (#requestEvent.data.sharkUnionWrappers>=1) then
					self.container.selectedDataList = requestEvent.data.sharkUnionWrappers or {}
					self.refreshSelf(false)

					self.listTableView:gotoBottom()--拉伸至底部
				end
				self:setTableViewTouched(true)--重新赋予可触摸状态
			end
			UnionGetUnionListRequest.sendRequest(topRank, 20, onSucceed, UnionGetUnionListRequest.onFailedDefault)
			self:setTableViewTouched(false)--用于取消触摸状态
		end
	end
	--拉伸导致获取靠后排名信息
	function onDragDown()
		if self.tagIndex == UnionListTagEnum.UNION_LIST then
			local topRank = self:findTailRank()
			topRank = topRank + 1
			local function onSucceed(startNum, amount, requestEvent)
				--默认处理
				UnionGetUnionListRequest.onSucceedDefault(startNum, amount, requestEvent)

				if requestEvent.data.sharkUnionWrappers and (#requestEvent.data.sharkUnionWrappers>=1) then
					self.container.selectedDataList = requestEvent.data.sharkUnionWrappers or {}
					self.refreshSelf(false)
				else
					--刷不出来的情况 还原之前的位置状态
					self.listTableView:gotoBottom()--拉伸至底部
				end
				self:setTableViewTouched(true)--重新赋予可触摸状态
			end
			UnionGetUnionListRequest.sendRequest(topRank, 20, onSucceed, UnionGetUnionListRequest.onFailedDefault)
			self:setTableViewTouched(false)--用于取消触摸状态
		end
	end
	aTableView:setDragable(onDragUp, onDragDown, item_height)

	return aTableView
end

function UnionListPanel:dispose()
  UnionListPanel.super.dispose(self)
end

function UnionListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function UnionListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function UnionListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end

--申请加入军团
function UnionListPanel:join(aData)
	local function onSucceed(unionData, event)
		--默认处理
		UnionApplyRequest.onSucceedDefault(unionData, event)

		if self.tagIndex == UnionListTagEnum.UNION_LIST then
			--在军团列表页需要保持滚动位置
			self.refreshSelf(true)
		else
			--在申请表里直接重置
			self.refreshSelf(false)
		end
	end
	UnionApplyRequest.sendRequest(aData, onSucceed, UnionApplyRequest.onFailedDefault)
end

--取消申请
function UnionListPanel:unJoin(aData)
	local function onSucceed(unionId, event)
		--默认处理
		UnionCancelApplyRequest.onSucceedDefault(unionId, event)

		if self.tagIndex == UnionListTagEnum.UNION_LIST then
			--在军团列表页需要保持滚动位置
			self.refreshSelf(true)
		else
			--在申请表里直接重置
			self.refreshSelf(false)
		end
	end
	UnionCancelApplyRequest.sendRequest(aData.unionId, onSucceed, UnionCancelApplyRequest.onFailedDefault)
end

function UnionListPanel:findTopRank()
	local tmpList = self.container.selectedDataList
	if (not tmpList) or (#tmpList <= 0) then
		return 1
	end
	local topData = tmpList[1]
	return topData.rank
end

function UnionListPanel:findTailRank()
	local tmpList = self.container.selectedDataList
	if (not tmpList) or (#tmpList <= 0) then
		return 1
	end
	local topData = tmpList[#tmpList]
	return topData.rank
end