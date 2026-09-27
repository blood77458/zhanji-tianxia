--
-- UnionMemberListPanel.lua
-- Author: zheng.che
-- Date: 2014-03-24 18:31:48
-- 军团成员列表页
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.UnionApplyRequest"
require "canon.request.UnionCancelApplyRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 714
local table_height = 958
local table_posX = 6
local table_posY = 125
local item_width = 714
local item_height = 271

UnionMemberListPanel = class(Layer)

function UnionMemberListPanel:ctor()
	self.container = nil
	self.dataList = nil
	self.targetMemberList = nil
end

-- targetMemberList 外部指定要显示的成员列表
function UnionMemberListPanel:create( container, tagIndex, targetMemberList )
	local s = UnionMemberListPanel.new()
	s:initLayer(container, tagIndex, targetMemberList)
	return s
end

function UnionMemberListPanel:initLayer(container, tagIndex, targetMemberList)
	self.targetMemberList = targetMemberList

	local function refreshSelf()
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end

		local tempList
		if self.targetMemberList then
			--需要显示指定的内容
			tempList = self.targetMemberList
		else
			--默认显示好友列表
			tempList = UnionManager.getMembers()
		end

		for _, v in ipairs(tempList) do
			table.insert(self.dataList, v)
		end

		--对显示内容排序
		local function sortFunc(a, b)
			local aIsMe = (a.uid == DataManager.getGameInitData().sharkUser.uid)
			local bIsMe = (b.uid == DataManager.getGameInitData().sharkUser.uid)
			if aIsMe then
				return true
			end
			if bIsMe then
				return false
			end
			return b.hisContribute < a.hisContribute
		end
		table.sort(self.dataList, sortFunc)

		if UnionManager.isTransfering() then
			self.cdLabelComponent:setTargetTime(UnionManager.getUnionTransferTime() + 1)--结束后要刷新
			self.cdLabelComponent:start()
		end

		self.listTableView:reloadData()
	end
	self.refreshSelf = refreshSelf

	UnionMemberListPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = {}

	self.listTableView = self:createListTableView()
	self:addChild(self.listTableView)

	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)

		local currentMembers = UnionManager.getMembers()
		for k, v in ipairs(currentMembers) do
			local newCell = self.listTableView:cellAtIndex(k-1)
			if not newCell then
				return
			end
			local aCell = newCell:getChildByTag(1024)
			local aData = v
			local aChangingLabel = aCell:getChildByTag(-18)
			local aChangingTimeLabel = aCell:getChildByTag(-19)
			local buttonDisplay = aCell:getChildByTag(-51)
			local isMe = (aData.uid == DataManager.getGameInitData().sharkUser.uid)
			if isMe and (tonumber(aData.title) == UnionManager.TITLE_MANAGER) then
				--军团长
				buttonDisplay:setVisible(false)
				if UnionManager.isTransfering() then
					aChangingLabel:setVisible(true)
					aChangingTimeLabel:setVisible(true)
					local remainedSec = UnionManager.getUnionTransferTime() - TimeUtil.getServerTimeSeconds()
					local formatedTimeStr = TimeUtil.formatTime(remainedSec)
					setNodeText(aChangingLabel:getChildByTag(-18), Localization:getInstance():getText("union_player_button_change_major_remind1"))--军团长转让:
					setNodeText(aChangingTimeLabel:getChildByTag(-19), formatedTimeStr)--$军团长转让时间
				else
					aChangingLabel:setVisible(false)
					aChangingTimeLabel:setVisible(false)
				end
			else
				aChangingLabel:setVisible(false)
				aChangingTimeLabel:setVisible(false)
				buttonDisplay:setVisible(true)
			end
		end
	end
	self.onTimeTick = onTimeTick

	function onTimeComplete()
		--在tick已经处理过了
		--self.refreshSelf()
		UnionGetMyDataRequest.sendRequest(UnionGetMyDataRequest.onSucceedDefault, UnionGetMyDataRequest.onFailedDefault) --刷新玩家当前的信息(更新职位信息)
		UnionGetMemberListRequest.sendRequest(UnionGetMemberListRequest.onSucceedDefault, UnionGetMemberListRequest.onFailedDefault) --刷新玩家列表
	end
	self.onTimeComplete = onTimeComplete

	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)

	--成员列表更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.EVENT_MEMBERS_UPDATE, self.refreshSelf, self)

	self.refreshSelf()
end

function UnionMemberListPanel:createListTableView()
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
		local aCell = builder:build("list_guild_mem_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		aCell:getChildByName("txt_guild_15_1"):getChildByName("txt"):setString(Localization:getInstance():getText("union_arena_rank_text"))--竞技场排名：
		aCell:getChildByName("txt_guild_15_2"):getChildByName("txt"):setString(Localization:getInstance():getText("union_fight_num_text"))--战斗力：
		aCell:getChildByName("txt_guild_15_3"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_contribute_all_text"))--个人总贡献：
		aCell:getChildByName("btn_guildoption"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_affairs_button"))--军务

		local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-10)
    
		local aNameLabel = aCell:getChildByName("txt_guild_member_name")
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
    
		local aContributeLabel = aCell:getChildByName("txt_guild_16_3")
		aContributeLabel:setTag(-15)
		aContributeLabel = aContributeLabel:getChildByName("txt")
		aContributeLabel:setTag(-15)
    
		local aContributeInfoLabel = aCell:getChildByName("txt_guild_18")
		aContributeInfoLabel:setTag(-16)
		aContributeInfoLabel = aContributeInfoLabel:getChildByName("txt")
		aContributeInfoLabel:setTag(-16)
    
		local aLineInfoLabel = aCell:getChildByName("txt_guild_17")
		aLineInfoLabel:setTag(-17)
		aLineInfoLabel = aLineInfoLabel:getChildByName("txt")
		aLineInfoLabel:setTag(-17)

		local aChangingLabel = aCell:getChildByName("txt_guild_changing1")
		aChangingLabel:setTag(-18)
		aChangingLabel = aChangingLabel:getChildByName("txt")
		aChangingLabel:setTag(-18)

		local aChangingTimeLabel = aCell:getChildByName("txt_guild_changing2")
		aChangingTimeLabel:setTag(-19)
		aChangingTimeLabel = aChangingTimeLabel:getChildByName("txt")
		aChangingTimeLabel:setTag(-19)
    
    	--等级标记
		aCell:getChildByName("lbl_1st"):setTag(-31)--军团长
		aCell:getChildByName("lbl_2rd"):setTag(-32)--副团长
		aCell:getChildByName("lbl_elite"):setTag(-33)--精英团员
		aCell:getChildByName("lbl_mem"):setTag(-34)--成员

		--军务按钮
		local aAcceptBtnDisplay = aCell:getChildByName("btn_guildoption")
		aAcceptBtnDisplay:setTag(-51)
		aAcceptBtnDisplay:getChildByName("btn"):setTag(-11)
	end

	function UnionListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		-- print("aData = " .. table.tostring(aData))

		local aCardDisplay = aCell:getChildByTag(-10)

		local oldIcon = aCell:getChildByTag(-200)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		local newMeta = CommonManager:getSelfAvatarMetaByUid( aData.uid )
	    if not newMeta then
	        newMeta = aData.mainCardId
	    end
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMeta, 1, params)
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

		local aContributeLabel = aCell:getChildByTag(-15)
		setNodeText(aContributeLabel:getChildByTag(-15), aData.hisContribute or "")

		--等级标记
		if tonumber(aData.title) == UnionManager.TITLE_MANAGER then
			aCell:getChildByTag(-31):setVisible(true)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(false)
		elseif tonumber(aData.title) == UnionManager.TITLE_VICE_MANAGER then
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(true)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(false)
		elseif tonumber(aData.title) == UnionManager.TITLE_ELITE_MEMBER then
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(true)
			aCell:getChildByTag(-34):setVisible(false)
		else
			aCell:getChildByTag(-31):setVisible(false)
			aCell:getChildByTag(-32):setVisible(false)
			aCell:getChildByTag(-33):setVisible(false)
			aCell:getChildByTag(-34):setVisible(true)
		end

		--显示军务按钮 或者显示倒计时
		local aChangingLabel = aCell:getChildByTag(-18)
		local aChangingTimeLabel = aCell:getChildByTag(-19)
		local buttonDisplay = aCell:getChildByTag(-51)
		local isMe = (aData.uid == DataManager.getGameInitData().sharkUser.uid)
		if isMe and (tonumber(aData.title) == UnionManager.TITLE_MANAGER) then
			--军团长
			buttonDisplay:setVisible(false)
			if UnionManager.isTransfering() then
				aChangingLabel:setVisible(true)
				aChangingTimeLabel:setVisible(true)
				local remainedSec = UnionManager.getUnionTransferTime() - TimeUtil.getServerTimeSeconds()
				local formatedTimeStr = TimeUtil.formatTime(remainedSec)
				setNodeText(aChangingLabel:getChildByTag(-18), Localization:getInstance():getText("union_player_button_change_major_remind1"))--军团长转让:
				setNodeText(aChangingTimeLabel:getChildByTag(-19), formatedTimeStr)--$军团长转让时间
			else
				aChangingLabel:setVisible(false)
				aChangingTimeLabel:setVisible(false)
			end
		else
			aChangingLabel:setVisible(false)
			aChangingTimeLabel:setVisible(false)
			buttonDisplay:setVisible(true)
		end

		--显示离线时间
		local aLineInfoLabel = aCell:getChildByTag(-17)
		local offLineSec = 0
		if not aData.online then
			--当前不在线才有偏差时间
			offLineSec = TimeUtil.getServerTimeSeconds() - aData.lastestActiveSeconds
		end
		local hours = TimeUtil.getHoursBySec(offLineSec)
		if hours <= 0 then
			--不到1小时
			aLineInfoLabel:setVisible(false)
		else
			--超过1小时
			aLineInfoLabel:setVisible(true)
			local days = TimeUtil.getPasseddDaysToNow(aData.lastestActiveSeconds)
			if days <= 0 then
				--不到1天
				setNodeText(aLineInfoLabel:getChildByTag(-17), Localization:getInstance():getText("union_player_login_remind3", {num = hours}))--{num}小时未登陆
			else
				--超过1天
				if days <= 7 then
					--不到7天
					setNodeText(aLineInfoLabel:getChildByTag(-17), Localization:getInstance():getText("union_player_login_remind2", {num = days}))--{num}天未登陆
				else
					--超过7天
					setNodeText(aLineInfoLabel:getChildByTag(-17), Localization:getInstance():getText("union_player_login_remind1"))--7天以上未登陆
				end
			end
		end

		--显示建设时间
		local aContributeInfoLabel = aCell:getChildByTag(-16)
		local daysBuild = TimeUtil.getPasseddDaysToNow(aData.lastestConstructSeconds)
		if aData.lastestConstructType == UnionManager.BUILD_NONE then
			--压根没有建设过 就当他多了一天没建设
			daysBuild = daysBuild + 1
		end
		if daysBuild <= 0 then
			--当天
			if UnionManager.isSilverBuild(aData.lastestConstructType) then
				--银币建设
				setNodeText(aContributeInfoLabel:getChildByTag(-16), Localization:getInstance():getText("union_player_contribute_remind2"))--今日银币建设
			else
				--金币
				local cost = UnionManager.getBuildCostNum(aData.lastestConstructType)
				setNodeText(aContributeInfoLabel:getChildByTag(-16), Localization:getInstance():getText("union_player_contribute_remind1", {num = cost}))--今日{num}金币建设
			end
		else
			if daysBuild <= 7 then
				--7天以内
				setNodeText(aContributeInfoLabel:getChildByTag(-16), Localization:getInstance():getText("union_player_contribute_remind3", {num = daysBuild}))--{num}天未建设
			else
				--超过7天
				setNodeText(aContributeInfoLabel:getChildByTag(-16), Localization:getInstance():getText("union_player_contribute_remind4"))--7天以上未建设
			end
		end
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
			--print("onListItemTouch")
			if self:canOpenMenu(aData) then
				self:openOperationMenu(aData)
			end
		else
			--按钮以外区域 显示成员具体的信息
			if self:canShowTeamInfo(aData) then
				self:showTeamInfo(aData)
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

	return aTableView
end

function UnionMemberListPanel:dispose()
	UnionManager.eventDispatcher:removeEventListener(UnionManager.EVENT_MEMBERS_UPDATE, self.refreshSelf)

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	self.dataList = nil
	self.targetMemberList = nil

	UnionMemberListPanel.super.dispose(self)
end

function UnionMemberListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function UnionMemberListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function UnionMemberListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end

--能否打开军务菜单
function UnionMemberListPanel:canOpenMenu(aData)
	local isMe = (aData.uid == DataManager.getGameInitData().sharkUser.uid)
	if isMe and (tonumber(aData.title) == UnionManager.TITLE_MANAGER) then
		--军团长点自己
		return false
	end

	return true
end

--打开军务操作菜单
function UnionMemberListPanel:openOperationMenu(aData)
	--先要知道是否是好友
	local function searchUserByNicknameCallback(event) 
		--print("searchUserByNicknameCallback! event = " .. table.tostring(event))
		if event.data.sharkFriendDetail then
			local isFriend = event.data.sharkFriendDetail.friend
			local invitationSent = event.data.sharkFriendDetail.invitationSent
			UnionManager.popMemberOperationMenu(self.dataList, aData, isFriend, invitationSent)
		else
			--特殊情况 没有这个人的数据 认为不是好友
			UnionManager.popMemberOperationMenu(self.dataList, aData, false, false)
		end
	end
	local params = {nickName = aData.nickName}
	local searchUserByNicknameRequest = SearchUserByNicknameRequest.new(params, rpc.SendingPriority.kHigh)
	searchUserByNicknameRequest:addEventListener(RequestNotifyEnum.SearchUserByNicknameSucceed, searchUserByNicknameCallback)
	searchUserByNicknameRequest:start()
end

--能否显示玩家阵容
function UnionMemberListPanel:canShowTeamInfo(aData)
	local isMe = (aData.uid == DataManager.getGameInitData().sharkUser.uid)
	if isMe then
		--点自己
		return false
	end

	return true
end

--显示玩家阵容
function UnionMemberListPanel:showTeamInfo(aData)
	params = {
	playerUid = aData.uid,
	}
	local function onGetPlayerTeamInfoCallback( evt )
		--print("self.container.curSceneEnum = " .. self.container.curSceneEnum)
		local argv = {
			enterScene = self.container.curSceneEnum,
			returnScene = self.container.curSceneEnum,
			params = {
				playerUid = aData.uid,
				playerTeamData = evt.data,
			},
		}
		self.container:replaceScene( CardQueueScene, argv )
	end

	local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
	getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
	getPlayerTeamInfoRequest:start()
end