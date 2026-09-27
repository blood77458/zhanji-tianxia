--
-- UnionNewsListPanel.lua
-- Author: zheng.che
-- Date: 2014-04-03 15:49:34
-- 军团动态列表
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 714
local table_height = 998
local table_posX = 6
local table_posY = 125
local item_width = 714
local item_height = 231

UnionNewsListPanel = class(Layer)

function UnionNewsListPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionNewsListPanel:create( container, tagIndex )
	local s = UnionNewsListPanel.new()
	s:initLayer(container, tagIndex)
	return s
end

function UnionNewsListPanel:initLayer(container, tagIndex)
	local function refreshSelf()
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end

		local tempList = UnionManager.getNewses()

		for _, v in ipairs(tempList) do
			table.insert(self.dataList, v)
		end

		self.listTableView:reloadData()
	end
	self.refreshSelf = refreshSelf

	UnionNewsListPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = {}

	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)

	self.refreshSelf()
end

function UnionNewsListPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {-19}
	local aListPanel = self
	local UnionNewsListTableViewRenderer = class(TableViewRenderer)
	function UnionNewsListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionNewsListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild_general")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本

		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)
    
		local aNameLabel = aCell:getChildByName("txt_guild_member_name")
		aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-11)
    
		local aLevelLabel = aCell:getChildByName("txt_guild_14")
		aLevelLabel:setTag(-12)
		aLevelLabel = aLevelLabel:getChildByName("txt")
		aLevelLabel:setTag(-11)
    
		local aTimeLabel = aCell:getChildByName("txt_general_time")
		aTimeLabel:setTag(-13)
		aTimeLabel = aTimeLabel:getChildByName("txt")
		aTimeLabel:setTag(-11)
    
		local aInfoLabel = aCell:getChildByName("txt_general_info")
		aInfoLabel:setTag(-14)
		aInfoLabel = aInfoLabel:getChildByName("txt")
		aInfoLabel:setTag(-11)
    
		local aCityNameLabel = aCell:getChildByName("txt_1")
		aCityNameLabel:setTag(-15)
		aCityNameLabel = aCityNameLabel:getChildByName("txt")
		aCityNameLabel:setTag(-11)
    
		local aLineUpLabel = aCell:getChildByName("txt_2")
		aLineUpLabel:setTag(-16)
		aLineUpLabel = aLineUpLabel:getChildByName("txt")
		aLineUpLabel:setTag(-11)
    
		local aLineDownLabel = aCell:getChildByName("txt_3")
		aLineDownLabel:setTag(-17)
		aLineDownLabel = aLineDownLabel:getChildByName("txt")
		aLineDownLabel:setTag(-11)
    
		local aLineCenterLabel = aCell:getChildByName("txt_4")
		aLineCenterLabel:setTag(-18)
		aLineCenterLabel = aLineCenterLabel:getChildByName("txt")
		aLineCenterLabel:setTag(-11)
    
		local aToMemberBtn = aCell:getChildByName("btn")
		aToMemberBtn:setTag(-19)
		aToMemberBtn:getChildByName("txt"):setString(getTextByKey("UnionWar_optimize_person"))-- 报名成员列表
		aToMemberBtn = aToMemberBtn:getChildByName("btn")
		aToMemberBtn:setTag(-11)

		local aLvIcon = aCell:getChildByName("icon_lv")
		aLvIcon:setTag(-20)
	end

	function UnionNewsListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		local aCardDisplay = aCell:getChildByTag(-10)
		local aNameLabel = aCell:getChildByTag(-11)
		local aLevelLabel = aCell:getChildByTag(-12)
		local aTimeLabel = aCell:getChildByTag(-13)
		local aInfoLabel = aCell:getChildByTag(-14)
		local aCityNameLabel = aCell:getChildByTag(-15)
		local aLineUpLabel = aCell:getChildByTag(-16)
		local aLineDownLabel = aCell:getChildByTag(-17)
		local aLineCenterLabel = aCell:getChildByTag(-18)
		local aToMemberBtn = aCell:getChildByTag(-19)
		local aLvIcon = aCell:getChildByTag(-20)

		aCardDisplay:setVisible(false)
		aNameLabel:setVisible(false)
		aLevelLabel:setVisible(false)
		aTimeLabel:setVisible(false)
		aInfoLabel:setVisible(false)
		aCityNameLabel:setVisible(false)
		aLineUpLabel:setVisible(false)
		aLineDownLabel:setVisible(false)
		aLineCenterLabel:setVisible(false)
		aToMemberBtn:setVisible(false)
		aLvIcon:setVisible(false)

		if aData.newsType == UnionManager.NEWS_TYPE_NORMAL then
			--普通动态
			aCardDisplay:setVisible(true)
			aNameLabel:setVisible(true)
			aLevelLabel:setVisible(true)
			aTimeLabel:setVisible(true)
			aInfoLabel:setVisible(true)
			aLvIcon:setVisible(true)

			local oldIcon = aCell:getChildByTag(-200)
			if oldIcon then
				oldIcon:removeFromParentAndCleanup(true)
			end
			local params = {}
			params.sourceDisplay = aCardDisplay
			params.showInCenter = true
			local newMeta = CommonManager:getSelfAvatarMetaByUid( aData.senderUid )
		    if not newMeta then
		        newMeta = aData.mainCardId
		    end
			local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 1, params)
			aCell:addChild(icon.refCocosObj, 10)
			if icon then
				icon:setTag(-200)
				icon:dispose()
			end

			setNodeText(aNameLabel:getChildByTag(-11), aData.senderNickname or "")
			setNodeText(aLevelLabel:getChildByTag(-11), aData.senderLevel or "")
			setNodeText(aTimeLabel:getChildByTag(-11), TimeUtil.formatDate(aData.createTime) or "")
			setNodeText(aInfoLabel:getChildByTag(-11), UnionManager.getNewsStr(aData.type, aData.detail) or "")

		elseif aData.newsType == UnionManager.NEWS_TYPE_PK then
			--军团战

			--显示军团默认图标
			local oldIcon = aCell:getChildByTag(-200)
			if oldIcon then
				oldIcon:removeFromParentAndCleanup(true)
			end
			local params = {}
			params.sourceDisplay = aCardDisplay
			params.showInCenter = true
			local icon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.UNION, 0, 0, params)
			aCell:addChild(icon.refCocosObj, 10)
			if icon then
				icon:setTag(-200)
				icon:dispose()
			end

			local _json = require("cjson")
			local detailData = _json.decode(aData.detail)
			--print("detailData = " .. tostringRich(detailData))

			if aData.type == UnionPkConsts.WAR_NEWS_TYPE_PREPARE then
				--准备信息
				
				detailData.ownCityIds = detailData.ownCityIds:split(",")--后端这里用的不是数组 所以加个转换
				local ownCityNames = {}
				for i, v in ipairs(detailData.ownCityIds) do
					table.insert(ownCityNames, UnionPkUtils.getCityNameById(tonumber(v)))
				end

				detailData.challengeCityIds = detailData.challengeCityIds:split(",")--后端这里用的不是数组 所以加个转换
				local challengeCityNames = {}
				for i, v in ipairs(detailData.challengeCityIds) do
					table.insert(challengeCityNames, UnionPkUtils.getCityNameById(tonumber(v)))
				end

				if #ownCityNames > 0 then
					--有占领城池
					aLineUpLabel:setVisible(true)
					local cityNames = table.join(ownCityNames, " ")--间隔用空格
					setNodeText(aLineUpLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_sign") .. cityNames )--军团战已经占领城池：[城池名称列表]

					if #challengeCityNames > 0 then
						--有报名城池
						aLineDownLabel:setVisible(true)
						local cityNames = table.join(challengeCityNames, " ")--间隔用空格
						setNodeText(aLineDownLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_sign1") .. cityNames )--军团战已经报名城池：[城池名称列表]
					end
				else
					--无占领城池
					--肯定有报名城池
					aLineUpLabel:setVisible(true)
					local cityNames = table.join(challengeCityNames, " ")--间隔用空格
					setNodeText(aLineUpLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_sign1") .. cityNames )--军团战已经报名城池：[城池名称列表]
				end

			elseif aData.type == UnionPkConsts.WAR_NEWS_TYPE_DEFENSE then
				--守城信息
				aCityNameLabel:setVisible(true)
				aLineCenterLabel:setVisible(true)
				aToMemberBtn:setVisible(true)

				local cityName = UnionPkUtils.getCityNameById(tonumber(detailData.ownCityId))
				setNodeText(aCityNameLabel:getChildByTag(-11), cityName)--[城市名称]
				setNodeText(aLineCenterLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_defend", {num1 = cityName}) )--我方军团将于{num1}进行防御，可以进行参战

			elseif aData.type == UnionPkConsts.WAR_NEWS_TYPE_BID then
				--竞标成功信息
				aCityNameLabel:setVisible(true)
				aLineCenterLabel:setVisible(true)
				aToMemberBtn:setVisible(true)

				local cityName = UnionPkUtils.getCityNameById(tonumber(detailData.bidCityId))
				setNodeText(aCityNameLabel:getChildByTag(-11), cityName)--[城市名称]
				setNodeText(aLineCenterLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_defend1", {num1 = cityName}) )--我方军团于{num1}竞标成功，可以进行参战

			elseif aData.type == UnionPkConsts.WAR_NEWS_TYPE_OCCUPY then
				--占领信息
				aCityNameLabel:setVisible(true)
				aLineCenterLabel:setVisible(true)

				local cityName = UnionPkUtils.getCityNameById(tonumber(detailData.ownCityId))
				setNodeText(aCityNameLabel:getChildByTag(-11), cityName)--[城市名称]
				setNodeText(aLineCenterLabel:getChildByTag(-11), getTextByKey("UnionWar_optimize_battle", {num1 = cityName}) )--我方军团成功占领{num1}
			end
		end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]

		local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-19)
		if buttonDisplay:isVisible() == true then
			--按钮已显示
			local btnBgDisplay = buttonDisplay:getChildByTag(-11)
			if posInCell.x > buttonDisplay:getPositionX() and
			posInCell.x < (buttonDisplay:getPositionX() + btnBgDisplay:getContentSize().width) and
			posInCell.y > (buttonDisplay:getPositionY() - btnBgDisplay:getContentSize().height) and
			posInCell.y < buttonDisplay:getPositionY() then
				--点击按钮
				if aData.type == UnionPkConsts.WAR_NEWS_TYPE_DEFENSE then
					--守城信息
					local _json = require("cjson")
					local detailData = _json.decode(aData.detail)
					local cityId = tonumber(detailData.ownCityId)
					UnionPK.gotoUnionMemberSceneWithCityMembers(cityId)
				elseif aData.type == UnionPkConsts.WAR_NEWS_TYPE_BID then
					--竞标成功信息
					local _json = require("cjson")
					local detailData = _json.decode(aData.detail)
					local cityId = tonumber(detailData.bidCityId)
					UnionPK.gotoUnionMemberSceneWithCityMembers(cityId)
				end
			end
		end

	end

	local renderer = UnionNewsListTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	--aTableView:setDirection(kCCScrollViewDirectionHorizontal)
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

function UnionNewsListPanel:dispose()
	UnionNewsListPanel.super.dispose(self)
end

function UnionNewsListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function UnionNewsListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function UnionNewsListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end