-- UnionPKMyRewardPopPanel.lua
-- zhehua.ou
-- 2014-9-16
-- 军团战 我的奖励

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	if evt.context.tableView then
		evt.context.tableView:setTouchEnabled(evt.data == evt.context)
	end
end

------------------------------------------------------------------------------------------------------

UnionPKMyRewardPopPanel = class(Layer)

function UnionPKMyRewardPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionPKMyRewardPopPanel:create( container  )
	local s = UnionPKMyRewardPopPanel.new()
	s.container = container
	s:initLayer()
	return s
end

function UnionPKMyRewardPopPanel:initLayer()
	UnionPKMyRewardPopPanel.super.initLayer(self)

	self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_settlement_award")
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
      	self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )

	local yesBtnDisplay = self.panelUI:getChildByName("btn_yellow_queding")
    local yseBtn = Button:create(yesBtnDisplay)
    yseBtn:addEventListener( Events.kStart, closeBtnAction, self )
	yesBtnDisplay:getChildByName("txt"):setString(getTextByKey("yes"))

	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_reward"))
	self.panelUI:getChildByName("settlement_award_list"):setVisible(false)
	self.tempLayer:setScale(0.1)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
end


function UnionPKMyRewardPopPanel:getDataList()
	local cityHash = UnionPkData.getDefenceCityIdsHash()
	self.cityArr = {}
	for k,v in pairs(cityHash) do
		table.insert(self.cityArr, k)
	end

	local DataList = {}
	for i=1,UnionPkConsts.REWARD_MAX_COUNT do
		local data = {}
		local rewards , titleStr = self:getRewards(i)
		---------------------------------------------
		-- if i == 1 or i == 4 then
		-- 	rewards = {400207,400209,400207}
		-- elseif i == 2 or i == 5  then
		--     -- rewards = {}
		--     rewards = {19001}
		-- elseif i == 3 or i == 6  then
		-- 	rewards = {400209,400207,400207}
		-- end
		---------------------------------------------
		if #rewards > 0 then
			data.index = i

			-- 奖励去重，加数量
			data.rewards = {}
			for i=1,#rewards do
				if i == 1 then
					table.insert(data.rewards, {id = rewards[i] , count = 1})
				else
					local hasSame = false
					for j=1,#data.rewards do
						if rewards[i] == data.rewards[j].id then
							hasSame = true
							data.rewards[j].count = data.rewards[j].count + 1
							break
						end
					end
					if not hasSame then
						table.insert(data.rewards, {id = rewards[i] , count = 1})
					end
				end
			end

			data.titleStr = titleStr
			data.enable = UnionPkCheck.canGetReward(i)
			table.insert(DataList, data)
		end
	end

	return DataList
end

function UnionPKMyRewardPopPanel:getRewards(index)
	local rewards = {}
	local titleStr = ""
	
	if index == UnionPkConsts.REWARD_DAILY then
		local cityNameArr = {}
		for i,v in ipairs(self.cityArr) do
			local reward = UnionPkConfig.getMyHistoryTitleDailyRewardByCityId(tonumber(v))
			local cityName = UnionPkUtils.getCityNameById(tonumber(v))
			if reward ~= -1 then
			    table.insert(rewards, reward)
			    table.insert(cityNameArr, cityName)
			end
		end
		local cityNameStr = ""
		for i,v in ipairs(cityNameArr) do
			if i > 1 then
				cityNameStr = cityNameStr.."、"..v
			else
				cityNameStr = cityNameStr..v
			end
		end
		titleStr = getTextByKey("UnionWar_reward_daily2",{num1 = cityNameStr})
	elseif index == UnionPkConsts.REWARD_IN then
		--modified by zheng.che @ 2014-10-31 这里需要判断是否参与过军团战
		if UnionPkCheck.hasAttendUnionPk() then
			--参与过军团
			local reward = UnionPkConfig.joinWarReward()
			if reward ~= -1 then
				table.insert(rewards, reward)
			end
		end
		titleStr = getTextByKey("UnionWar_reward_partake")
	elseif index == UnionPkConsts.REWARD_CAPTRUE then
		for i,v in ipairs(UnionPkData.getUnionWinNumList()) do
			local reward = UnionPkConfig.getMyHistoryTitleDefenceRewardByCityId(tonumber(v.cityId))
			if reward ~= -1 then
				local winTime = v.winNum
				for i=1,winTime do
					table.insert(rewards, reward)
				end
			end
		end
		titleStr = getTextByKey("UnionWar_reward_occupy")
	elseif index == UnionPkConsts.REWARD_BATTLE then
		if UnionPkCheck.isMemberApplied() then
			local reward = UnionPkConfig.inBattleReward()
			if reward ~= -1 then
				table.insert(rewards, reward)
			end
			titleStr = getTextByKey("UnionWar_reward_attend")
		end
	end
	return rewards , titleStr
end

function UnionPKMyRewardPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionPKMyRewardPopPanel.super.dispose(self)
end

function UnionPKMyRewardPopPanel:scaleIn()
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
	  self.tempLayer.touchEnabled = true
	  self.tempLayer.touchChildren = true

	  self.tableView = self:createTableView()
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))

	UiStackManager.push(self)
end

function UnionPKMyRewardPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end


function UnionPKMyRewardPopPanel:createTableView(display)
    local cellTag = 1024

    local UnionPKMyRewardRenderer = class(TableViewRenderer)

    function UnionPKMyRewardRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function UnionPKMyRewardRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
        local aCell = builder:build("list/settlement_award_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        --标题
        aCell:getChildByName("txt_1"):setTag(-11)
        aCell:getChildByName("txt_1"):getChildByName("txt"):setTag(-10)

        --奖励图标
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_1"):setTag(-21)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_1"):getChildByName("normal_card_small"):setTag(-10)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_1"):getChildByName("txt"):setTag(-12)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_1"):getChildByName("txt"):getChildByName("txt"):setTag(-10)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_2"):setTag(-22)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_2"):getChildByName("normal_card_small"):setTag(-10)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_2"):getChildByName("txt"):setTag(-12)
		aCell:getChildByName("guildPK_bank_item_fdrmation_2_2"):getChildByName("txt"):getChildByName("txt"):setTag(-10)

		--领取按钮
        aCell:getChildByName("btn"):getChildByName("txt_propInfo_useBtn"):setString(getTextByKey("achieve_task_get"))
        aCell:getChildByName("btn"):setTag(-31)
        aCell:getChildByName("btn"):getChildByName("normal"):setTag(-10)
    end

    function UnionPKMyRewardRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]
		
        --标题
		setNodeText(aCell:getChildByTag(-11):getChildByTag(-10),data.titleStr)

		--奖励图标
		for i=1,2 do
        	aCell:getChildByTag(-20-i):removeChildByTag(-11, true)
	        if data.rewards[i] ~= nil then
	        	local params = {}
				params.sourceDisplay = aCell:getChildByTag(-20-i):getChildByTag(-10)
				params.showInCenter = true

				local rewardId = nil
				local itemIcon = nil

				itemIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.PROP, data.rewards[i].id, 1, params)
				local itemNameAndCount = CanonGoodIcon.getGoodName(ResourceEnum.PROP, data.rewards[i].id, data.rewards[i].count)
				setNodeText(aCell:getChildByTag(-20-i):getChildByTag(-12):getChildByTag(-10), itemNameAndCount)

				local propMeta = MetaManager.prop_meta[data.rewards[i].id]
				if SystemManager.debug then
					DebugManager.assert(propMeta ~= nil, "没有这个礼包道具! propId = " .. tostringRich(propId))
				end
				rewardId = propMeta.effectValue

				itemIcon.touchEnabled = false
	    		itemIcon.touchChildren = false
		        itemIcon:setTag(-11)
		        aCell:getChildByTag(-20-i):addChild(itemIcon.refCocosObj)
		        aCell:getChildByTag(-20-i).rewardId = rewardId
		        aCell:getChildByTag(-20-i):setVisible(true)
		    else
		    	aCell:getChildByTag(-20-i).rewardId = nil
		    	aCell:getChildByTag(-20-i):setVisible(false)
		    end
		end

		--领取按钮
		aCell:getChildByTag(-31):getChildByTag(-10):setVisible(data.enable)
    end

    local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("settlement_award_list"))

    local tableData = self:getDataList() or {}

    local renderer = UnionPKMyRewardRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {-21,-22,-31}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    local function onListItemTouch( evt )
        local aIndex = evt.data + 1
        local newCell = evt.target:cellAtIndex(aIndex - 1)
        local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

        --奖励图标
        for i=1,2 do
        	local itemDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20-i)
	        if posInCell.x > (itemDisplay:getPositionX() - 70) and
	            posInCell.x < (itemDisplay:getPositionX() + 70) and
	            posInCell.y > (itemDisplay:getPositionY() - 70) and
	            posInCell.y < (itemDisplay:getPositionY() + 70) then

	            local rewardId = itemDisplay.rewardId
	            if rewardId then
	                local scene = Director:mgr():run()
	                local function callback()
	                	self.tableView:setTouchEnabled(true)
	                end
	                self.tableView:setTouchEnabled(false)
					local rewardList = MetaManager.getRewardInfoByID(rewardId) or {}
					local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = rewardList, rewardTitle = getTextByKey("pk_reward_title") , callback = callback} )
					scene:addChild(aRewardPanel)
					aRewardPanel:scaleIn()
				else
					print("rewardId is nil")
	            end
        	end
        end
        local btnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-31)
        if posInCell.x > (btnDisplay:getPositionX()) and
            posInCell.x < (btnDisplay:getPositionX() + 168) and
            posInCell.y > (btnDisplay:getPositionY() - 66) and
            posInCell.y < (btnDisplay:getPositionY()) then

            local data = evt.target.tableViewRenderer.list[aIndex]
            if data.enable then
            	-- 判断背包是否满
            	if BagCalcManager.isFull() then
				    self.container.targetInfoPanel = NewPackageFullPanel:show()
				    return
				end

				local index = data.index
				local function onAfterSucceed(e)
		   	    	RewardManager:getReward(e.data.rewards)

					if index == UnionPkConsts.REWARD_DAILY then		
						DailyDataManager.setDailyDataGainUnionWarDailyReward(true)
					elseif index == UnionPkConsts.REWARD_IN then
						UnionManager.setGainUnionWarPlayReward(true)
					elseif index == UnionPkConsts.REWARD_CAPTRUE then
				    	UnionManager.setGainUnionWarOccupyReward(true)
				    elseif index == UnionPkConsts.REWARD_BATTLE then
				    	UnionManager.setGainUnionWarInBattleReward(true)
					end

					-- 按钮变黑
					evt.target.tableViewRenderer.list[aIndex].enable = false
					btnDisplay:getChildByTag(-10):setVisible(false)

					local function callback()
	                	self.tableView:setTouchEnabled(true)
	                end
	                self.tableView:setTouchEnabled(false)
			        local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = e.data.rewards, rewardTitle = Localization:getInstance():getText("activityNian_popup_rankRewardTitle") , callback = callback} )
			        self.container:addChild(aRewardPanel)
			        aRewardPanel:scaleIn()

			        --通知更新角标数 add by zheng.che @ 2014-12-15
			        UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_REWARD_UPDATE))
				end
				UnionPkGainUnionBattleRewardRequest.sendRequestDefalut(index, onAfterSucceed)
            end
        end
    end
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

    self.panelUI:addChild(aTableView)

    return aTableView
end