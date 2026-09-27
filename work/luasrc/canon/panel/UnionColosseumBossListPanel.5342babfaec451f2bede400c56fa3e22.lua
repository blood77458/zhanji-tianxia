--
-- UnionColosseumBossListPanel.lua
-- Author: zheng.che
-- Date: 2014-05-27 15:56:13
-- 军团斗兽场场景内的列表
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableTouchEnabled(evt.data == nil)
end

------------------------------------------------------------------------------------------------------

UnionColosseumBossListPanel = class(Layer)

function UnionColosseumBossListPanel:ctor()
	self.container = nil
	self.sourceDisplay = nil
end

function UnionColosseumBossListPanel:create( container, sourceDisplay )
	local s = UnionColosseumBossListPanel.new()
	s:initLayer(container, sourceDisplay)
	return s
end

function UnionColosseumBossListPanel:initLayer(container, sourceDisplay)
	--keepOffset 保持位置不变
	local function refreshSelf(keepOffset)
		if keepOffset == nil then
			--一般来说 只有第一次调用这个函数的情况 keepOffset是false
			keepOffset = true
		end

		--对显示内容排序
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end

		local tempList = UnionManager.getColosseumBossConfigList()
		--print("tempList = " .. tostringRich(tempList))

		for _, v in ipairs(tempList) do
			table.insert(self.dataList, v)
		end
		local function sortFunc(a, b)
			--未分配在前
			if not UnionManager.getColosseumMonsterRewardDistributed() then
				--有未分配的
				if UnionManager.getColosseumMonsterMetaId() == a.id then
					--a未分配 a在前
					return true
				end
				if UnionManager.getColosseumMonsterMetaId() == b.id then
					--b未分配 a在后
					return false
				end
			end
			--id小的在前
			return a.id < b.id
		end
		table.sort(self.dataList, sortFunc)
		if SystemManager.debug then
			print("self.dataList = " .. tostringRich(self.dataList))
		end

		--self.listTableView.tableViewRenderer.list = self.dataList

		--print("self.listTableView.tableViewRenderer.list = " .. tostringRich(self.listTableView.tableViewRenderer.list))

		-- --刷新每一条的状态
		-- for k, v in ipairs(self.dataList) do
		-- 	print("k1 = " .. k)
		-- 	local newCell = self.listTableView:cellAtIndex(k-1)
		-- 	if not newCell then
		-- 		return
		-- 	end
		-- 	print("k = " .. k)
		-- 	self.listTableView.tableViewRenderer:setData(newCell, k-1)
		-- end

		if keepOffset then
			--保持列表位置
			local tableOffset = self.listTableView:getContentOffset()
			self.listTableView:reloadData()
			self.listTableView:setContentOffset(tableOffset, true)
		else
			self.listTableView:reloadData()
		end

		--print("self.listTableView.tableViewRenderer.list = " .. tostringRich(self.listTableView.tableViewRenderer.list))
	end
	self.refreshSelf = refreshSelf

	UnionColosseumBossListPanel.super.initLayer(self)

	self.container = container
	self.sourceDisplay = sourceDisplay
	self.dataList = {}

	self.listTableView = self:createListTableView()
	--self.listTableView:reloadData()
	self:addChild(self.listTableView)

	--各种事件
	--军团斗兽场数据更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf, self)
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	self.refreshSelf(false)
end

function UnionColosseumBossListPanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {{-10, {-12}}, {-30, {-33, -34}}}
	local aListPanel = self
	local UnionColosseumBossListTableViewRenderer = class(TableViewRenderer)
	function UnionColosseumBossListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionColosseumBossListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("colosseum_monster_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		--不会变化的文本
		aCell:getChildByName("state_challenge_1"):getChildByName("txt_guild_51"):getChildByName("txt"):setString(getTextByKey("union_monster_reward_remind_txt"))--挑战奖励：
		aCell:getChildByName("state_challenge_1"):getChildByName("btn_the_receive"):getChildByName("txt"):setString(getTextByKey("union_monster_summon_button"))--召唤
		aCell:getChildByName("state_challenge_2"):getChildByName("txt_guild_55"):getChildByName("txt"):setString(getTextByKey("union_monster_unlock_remind1"))--斗兽场
		aCell:getChildByName("state_challenge_2"):getChildByName("txt_guild_53"):getChildByName("txt"):setString(getTextByKey("union_monster_unlock_remind2"))--级解锁
		aCell:getChildByName("state_challenge_3"):getChildByName("txt_guild_51"):getChildByName("txt"):setString(getTextByKey("union_monster_reward_get_remind"))--获得奖励
		aCell:getChildByName("state_challenge_3"):getChildByName("btn_distribution"):getChildByName("txt"):setString(getTextByKey("union_monster_reward_distribution_button"))--分配
		aCell:getChildByName("state_challenge_3"):getChildByName("btn_rank"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_button"))--排名


		--资源标签
		----------------------------------------------------------------------------------待召唤状态
		local aSummonStateDisplay = aCell:getChildByName("state_challenge_1")
		aSummonStateDisplay:setTag(-10)
    	--召唤按钮
		local aSummonBtnDisplay = aSummonStateDisplay:getChildByName("btn_the_receive")
		aSummonBtnDisplay:setTag(-12)
    	--召唤按钮的背景
		local aSummonBtnBgDisplay = aSummonStateDisplay:getChildByName("bg_guild_fight_name2")
		aSummonBtnBgDisplay:setTag(-13)
    
		----------------------------------------------------------------------------------需解锁状态
		local aLockStateDisplay = aCell:getChildByName("state_challenge_2")
		aLockStateDisplay:setTag(-20)
    	--解锁需要等级数字
		local aNeedLevelLabel = aLockStateDisplay:getChildByName("txt_guild_52")
		aNeedLevelLabel:setTag(-21)
		aNeedLevelLabel = aNeedLevelLabel:getChildByName("txt")
		aNeedLevelLabel:setTag(-21)
    
		----------------------------------------------------------------------------------待分配状态
		local aDivideStateDisplay = aCell:getChildByName("state_challenge_3")
		aDivideStateDisplay:setTag(-30)
    	--获得奖励角标数字
		local aGetRewardNumDisplay = aDivideStateDisplay:getChildByName("num")
		aGetRewardNumDisplay:setTag(-31)
		aGetRewardNumLabel = aGetRewardNumDisplay:getChildByName("txt")
		aGetRewardNumLabel:setTag(-31)
		aGetRewardBg2 = aGetRewardNumDisplay:getChildByName("icn_tixing_kong")--两位数以下的背景
		aGetRewardBg2:setTag(-32)
		aGetRewardBg3 = aGetRewardNumDisplay:getChildByName("tips_big")--三位数的背景
		aGetRewardBg3:setTag(-33)
		--已击杀标志
		local aKilledDisplay = aDivideStateDisplay:getChildByName("lbl_die")
		aKilledDisplay:setTag(-32)
		--分配按钮
		local aDivideBtnDisplay = aDivideStateDisplay:getChildByName("btn_distribution")
		aDivideBtnDisplay:setTag(-33)
		--排行按钮
		local aRankBtnDisplay = aDivideStateDisplay:getChildByName("btn_rank")
		aRankBtnDisplay:setTag(-34)
		--已逃跑标志
		local aEscapedDisplay = aDivideStateDisplay:getChildByName("lbl_escape")
		aEscapedDisplay:setTag(-36)
		--未分配美术字
		local aDivideTxtDisplay = aDivideStateDisplay:getChildByName("lbl_undistributed")
		aDivideTxtDisplay:setTag(-37)
    
		----------------------------------------------------------------------------------

		--显示boss形象和名称
		local bossDataList = UnionManager.getColosseumBossConfigList()
		for k, bossConfigData in ipairs(bossDataList) do
			--boss形象
			local bossDisplay = aCell:getChildByName("icon_monster_" .. bossConfigData.cardPic)
			if bossDisplay then
				bossDisplay:setTag(-100 - k)
			else
				print("军团斗兽场美术资源缺少boss图片的层名! target = " .. "icon_monster_" .. bossConfigData.cardPic)
			end

			--boss名称
			local bossNameDisplay = aCell:getChildByName("lbl_monster_" .. bossConfigData.cardPic)
			if bossNameDisplay then
				bossNameDisplay:setTag(-200 - k)
			else
				print("军团斗兽场美术资源缺少boss名称的层名! target = " .. "lbl_monster_" .. bossConfigData.cardPic)
			end

			--boss奖励宝箱 - 待分配状态
			local bossRewardIconDisplay = aSummonStateDisplay:getChildByName("icon_monster_treasure_" .. bossConfigData.cardPic)
			if bossRewardIconDisplay then
				bossRewardIconDisplay:setTag(-300 - k)
			else
				print("军团斗兽场美术资源缺少boss奖励图标的层名(待分配状态)! target = " .. "icon_monster_treasure_" .. bossConfigData.cardPic)
			end

			--boss奖励宝箱 - 等待召唤状态
			local bossRewardIconDisplay = aDivideStateDisplay:getChildByName("icon_monster_treasure_" .. bossConfigData.cardPic)
			if bossRewardIconDisplay then
				bossRewardIconDisplay:setTag(-300 - k)
			else
				print("军团斗兽场美术资源缺少boss奖励图标的层名(等待召唤状态)! target = " .. "icon_monster_treasure_" .. bossConfigData.cardPic)
			end
		end
	end

	function UnionColosseumBossListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		local aSummonStateDisplay = aCell:getChildByTag(-10)
		local aLockStateDisplay = aCell:getChildByTag(-20)
		local aDivideStateDisplay = aCell:getChildByTag(-30)


		local currentLevel = UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM)
		if currentLevel < aData.unlockLevel then
			--等级不够
			aSummonStateDisplay:setVisible(false)
			aDivideStateDisplay:setVisible(false)

			aLockStateDisplay:setVisible(true)

			--显示需要等级
			local aNeedLevelLabel = aLockStateDisplay:getChildByTag(-21):getChildByTag(-21)
			setNodeText(aNeedLevelLabel, aData.unlockLevel or "")
		else
			--等级够
			aLockStateDisplay:setVisible(false)

			if (not UnionManager.getColosseumMonsterRewardDistributed()) and (UnionManager.getColosseumMonsterMetaId() == aData.id) then
				--未分配 等待分配
				aSummonStateDisplay:setVisible(false)
				aDivideStateDisplay:setVisible(true)

				--显示奖励物品
				local rewardNum = UnionManager.getColosseumMonsterRewardAmount()
				setNodeText(aDivideStateDisplay:getChildByTag(-31):getChildByTag(-31), rewardNum)
				if rewardNum < 100 then
					--两位数
					aDivideStateDisplay:getChildByTag(-31):getChildByTag(-32):setVisible(true)
					aDivideStateDisplay:getChildByTag(-31):getChildByTag(-33):setVisible(false)
				else
					--三位数
					aDivideStateDisplay:getChildByTag(-31):getChildByTag(-32):setVisible(false)
					aDivideStateDisplay:getChildByTag(-31):getChildByTag(-33):setVisible(true)
				end

				--逃走/击杀状态
				local aKilledDisplay = aDivideStateDisplay:getChildByTag(-32)
				local aEscapedDisplay = aDivideStateDisplay:getChildByTag(-36)
				if UnionManager.getColosseumMonsterCurrentHp() <= 0 then
					--已击杀
					aKilledDisplay:setVisible(true)
					aEscapedDisplay:setVisible(false)
				else
					--逃跑了
					aKilledDisplay:setVisible(false)
					aEscapedDisplay:setVisible(true)
				end

				--显示奖励物品icon
				local bossDataList = UnionManager.getColosseumBossConfigList()
				for k, bossConfigData in ipairs(bossDataList) do
					local showThisBoss = (bossConfigData.id == aData.id)

					local bossDisplay = aDivideStateDisplay:getChildByTag(-300 - k)
					if bossDisplay then
						bossDisplay:setVisible(showThisBoss)
					end
				end

				local aDivideBtnDisplay = aDivideStateDisplay:getChildByTag(-33)
				local aDivideTxtDisplay = aDivideStateDisplay:getChildByTag(-37)
				if UnionManager.colosseumCanSeeAllocateBtn() then
					--按钮可见 文字不可见
					aDivideBtnDisplay:setVisible(true)
					aDivideTxtDisplay:setVisible(false)
				else
					--只看到文字 没有按钮
					aDivideBtnDisplay:setVisible(false)
					aDivideTxtDisplay:setVisible(true)
				end
			else
				--已分配 可以召唤
				aSummonStateDisplay:setVisible(true)
				aDivideStateDisplay:setVisible(false)

				--召唤按钮状态
				local aSummonBtnDisplay = aSummonStateDisplay:getChildByTag(-12)
				local aSummonBtnBgDisplay = aSummonStateDisplay:getChildByTag(-13)
				if UnionManager.colosseumCanSeeSummonBtn() then
					--可见
					aSummonBtnDisplay:setVisible(true)
					aSummonBtnBgDisplay:setVisible(true)
				else
					--不可见
					aSummonBtnDisplay:setVisible(false)
					aSummonBtnBgDisplay:setVisible(false)
				end

				--显示奖励物品icon
				local bossDataList = UnionManager.getColosseumBossConfigList()
				for k, bossConfigData in ipairs(bossDataList) do
					local showThisBoss = (bossConfigData.id == aData.id)

					local bossDisplay = aSummonStateDisplay:getChildByTag(-300 - k)
					if bossDisplay then
						bossDisplay:setVisible(showThisBoss)
					end
				end

			end
		end

		--显示boss形象和名称
		local bossDataList = UnionManager.getColosseumBossConfigList()
		for k, bossConfigData in ipairs(bossDataList) do
			local showThisBoss = (bossConfigData.id == aData.id)

			local bossDisplay = aCell:getChildByTag(-100 - k)
			if bossDisplay then
				bossDisplay:setVisible(showThisBoss)
			end

			local bossNameDisplay = aCell:getChildByTag(-200 - k)
			if bossNameDisplay then
				bossNameDisplay:setVisible(showThisBoss)
			end
		end
	end

	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local aData = self.dataList[aIndex]

		local newCell = self.listTableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)

		local btnDisplay
		local exchangeDisplay
		local exchangeSize
		local posInCell

		local currentLevel = UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM)
		if currentLevel < aData.unlockLevel then
			--等级不够
			--木有需要点击的地方
		else
			--等级够
			if (not UnionManager.getColosseumMonsterRewardDistributed()) and (UnionManager.getColosseumMonsterMetaId() == aData.id) then
				--未分配 等待分配
				btnDisplay = aCell:getChildByTag(-30):getChildByTag(-33)
				--exchangeDisplay = btnDisplay:getChildByTag(-12)
				exchangeSize = HeDisplayUtil:getNodeGroupBounds(btnDisplay, nil, kHitAreaObjectTag).size
				posInCell = btnDisplay:getParent():convertToNodeSpace(evt.globalPosition)
				-- print("posInCellXY = " .. tostringRich({posInCell.x, posInCell.y}))
				-- print("exchangeSize = " .. tostringRich({exchangeSize.width, exchangeSize.height}))
				-- print("btnDisplayXY = " .. tostringRich({btnDisplay:getPositionX(), btnDisplay:getPositionY()}))
				if posInCell.x > btnDisplay:getPositionX() and
				posInCell.x < (btnDisplay:getPositionX() + exchangeSize.width) and
				posInCell.y > (btnDisplay:getPositionY() - exchangeSize.height) and
				posInCell.y < btnDisplay:getPositionY() then
					--print("分配按钮! aData = " .. tostringRich(aData))
					if UnionManager.colosseumCanSeeAllocateBtn() then
						--有权限
						local function onStartAllocationSucceed(onStartAllocationSucceedEvent)
							--默认处理 写入数据
							UnionColosseumStartAllocationRequest.onSucceedDefault(onStartAllocationSucceedEvent)

							local function onSucceed(requestEvent)
								--默认处理 写入数据
								UnionGetMemberListRequest.onSucceedDefault(requestEvent)
								--显示分配二级
								local scene = Director:mgr():run()
								scene.targetInfoPanel = UnionColosseumDistributionPopPanel:create(scene)
								PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
							end
							--请求刷新成员列表
							UnionGetMemberListRequest.sendRequest(onSucceed, UnionGetMemberListRequest.onFailedDefault)
						end
						--请求开始分配
						UnionColosseumStartAllocationRequest.sendRequest(onStartAllocationSucceed, UnionColosseumStartAllocationRequest.onFailedDefault)
					end
				end

				btnDisplay = aCell:getChildByTag(-30):getChildByTag(-34)
				exchangeSize = HeDisplayUtil:getNodeGroupBounds(btnDisplay, nil, kHitAreaObjectTag).size
				posInCell = btnDisplay:getParent():convertToNodeSpace(evt.globalPosition)
				if posInCell.x > btnDisplay:getPositionX() and
				posInCell.x < (btnDisplay:getPositionX() + exchangeSize.width) and
				posInCell.y > (btnDisplay:getPositionY() - exchangeSize.height) and
				posInCell.y < btnDisplay:getPositionY() then
					--print("排行按钮! aData = " .. tostringRich(aData))
					local function onSucceed(requestEvent)
						--默认处理
						UnionColosseumGetRankRequest.onSucceedDefault(requestEvent)

						--弹出窗口
						local scene = Director:mgr():run()
						scene.targetInfoPanel = UnionColosseumRankPopPanel:create(scene)
						PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
					end
					UnionColosseumGetRankRequest.sendRequest(onSucceed, UnionColosseumGetRankRequest.onFailedDefault)
				end

				btnDisplay = aCell:getChildByTag(-30):getChildByTag(-301)
				exchangeSize = HeDisplayUtil:getNodeGroupBounds(btnDisplay, nil, kHitAreaObjectTag).size
				posInCell = btnDisplay:getParent():convertToNodeSpace(evt.globalPosition)
				if posInCell.x > btnDisplay:getPositionX() and
				posInCell.x < (btnDisplay:getPositionX() + exchangeSize.width) and
				posInCell.y > (btnDisplay:getPositionY() - exchangeSize.height) and
				posInCell.y < btnDisplay:getPositionY() then
					--print("待分配奖励图标! aData = " .. tostringRich(aData))
					local rewardData = UnionManager.getBossRewardData(aData.id)
					CanonGoodIcon.popoutGoodPanel(rewardData.itemType, rewardData.metaId)
				end
			else
				--已分配 可以召唤
				btnDisplay = aCell:getChildByTag(-10):getChildByTag(-12)
				exchangeSize = HeDisplayUtil:getNodeGroupBounds(btnDisplay, nil, kHitAreaObjectTag).size
				posInCell = btnDisplay:getParent():convertToNodeSpace(evt.globalPosition)
				if posInCell.x > btnDisplay:getPositionX() and
				posInCell.x < (btnDisplay:getPositionX() + exchangeSize.width) and
				posInCell.y > (btnDisplay:getPositionY() - exchangeSize.height) and
				posInCell.y < btnDisplay:getPositionY() then
					--print("召唤按钮! aData = " .. tostringRich(aData))
					if UnionManager.colosseumCanSummon(true) then
						local scene = Director:mgr():run()
						scene.targetInfoPanel = UnionColosseumSummonSelectPopPanel:create(scene, aData)
						PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
					end
				end

				btnDisplay = aCell:getChildByTag(-10):getChildByTag(-301)
				exchangeSize = HeDisplayUtil:getNodeGroupBounds(btnDisplay, nil, kHitAreaObjectTag).size
				posInCell = btnDisplay:getParent():convertToNodeSpace(evt.globalPosition)
				if posInCell.x > btnDisplay:getPositionX() and
				posInCell.x < (btnDisplay:getPositionX() + exchangeSize.width) and
				posInCell.y > (btnDisplay:getPositionY() - exchangeSize.height) and
				posInCell.y < btnDisplay:getPositionY() then
					--print("宝箱奖励图标! aData = " .. tostringRich(aData))
					local rewardData = UnionManager.getBossRewardData(aData.id)
					CanonGoodIcon.popoutGoodPanel(rewardData.itemType, rewardData.metaId)
				end
			end
		end
	end

	local tableViewSizes = getTableViewSizes(self.sourceDisplay)
	local renderer = UnionColosseumBossListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	--aTableView:setDirection(kCCScrollViewDirectionHorizontal)
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY + 3))--+3修正 因为美术资源摆的位置没有问题 这里可能是tableview的最终结果有偏差 待验证 2014-6-13
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

function UnionColosseumBossListPanel:dispose()
	UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf)
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	UnionColosseumBossListPanel.super.dispose(self)
end

function UnionColosseumBossListPanel:panelEnter(callback)
	--print("UnionColosseumBossListPanel:panelEnter")
	ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function UnionColosseumBossListPanel:panelExit(callback)
	--print("UnionColosseumBossListPanel:panelExit")
	UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf)--为解决退出时没有切出动画问题 提前清除侦听
	ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--外界控制触摸是否开启
function UnionColosseumBossListPanel:setTableViewTouched(enabled)
	if enabled then
		--如果试图开启 再判断其他开启条件
		enabled = (UiStackManager.getCurrentFocus() == nil)
	end
	self:setTableTouchEnabled(enabled)
end

--设置触摸是否开启
function UnionColosseumBossListPanel:setTableTouchEnabled(enabled)
	--print("enabled = " .. tostringRich(enabled))
	self.listTableView:setTouchEnabled(enabled)
end