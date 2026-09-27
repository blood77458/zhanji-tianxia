-- CrossArenaScoreLayer.lua
-- 2015-3-9
-- l1ghtsaber
-- 跨服PVP活跃积分领奖页

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function onPassDay( evt ) --跨天重置
	local self = evt.context
	if self.mainUI.list == nil then--如果跨天并且进入领奖阶段，这个layer释放了，就return
	    return
	end
	local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
    pvpDailyInfo.activeScore = 0
    pvpDailyInfo.activeRewards = {}
    DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)

	-- CrossArenaManager.setMyActiveScore( 0 )
	-- CrossArenaManager.setMyActiveRewards( {} ) 
	if type(self.refreshSelf) == "function" then self.refreshSelf() end
end

CrossArenaScoreLayer = class(Layer)

function CrossArenaScoreLayer:ctor()
	self.container = nil
end

function CrossArenaScoreLayer:create( container , extraArgs)
	self.container = container
	self.extraArgs = extraArgs
	self.iconpool = {}
	local s = CrossArenaScoreLayer.new()
	s:initLayer()
	return s
end

function CrossArenaScoreLayer:panelDismiss()
	self.container.targetInfoPanel = nil
end

function CrossArenaScoreLayer:initLayer()
	local baseFig = 5 --基数
	local totalCnt = 4 --框数
	local iconCnt = 3 --奖品数
	local arrNum = {} --基数拓展
	for i = 1,totalCnt do 
		arrNum[i] = baseFig * i 
	end 
	CrossArenaScoreLayer.super.initLayer(self)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("table_crossArena_hyjf")
	self:addChild(self.mainUI)
	self.mainUI:getChildByName("other_gray9_panel"):setVisible(false)
	local nowScore = DailyDataManager.getCrossPvpDailyData().activeScore --当前活跃积分
	self.mainUI:getChildByName("txt_jj_9"):getChildByName("txt"):setString(getTextByKey("crossArena_currActiveScore"))
	self.mainUI:getChildByName("txt_jj_11"):getChildByName("txt"):setString(getTextByKey("crossArena_activeScoreExplain1"))
	self.mainUI:getChildByName("txt_jj_12"):getChildByName("txt"):setString(getTextByKey("crossArena_activeScoreExplain3"))
	self.mainUI:getChildByName("txt_jj_13"):getChildByName("txt"):setString(getTextByKey("crossArena_activeScoreExplain2"))
	local exList = {}
	exList[1] = self.mainUI:getChildByName("list_jf_1")
	exList[2] = self.mainUI:getChildByName("list_jf_2")
	exList[3] = self.mainUI:getChildByName("list_jf_3")
	exList[4] = self.mainUI:getChildByName("list_jf_4")

	local activeRewards = MetaManager.game_meta.crossArenaRewardConfig.activeRewards
	--print(tostringRich(activeRewards))
	local function initListUI( list, num ) --不变的UI
		list:getChildByName("table_lbl_5"):setVisible(false)
		list:getChildByName("table_lbl_10"):setVisible(false)
		list:getChildByName("table_lbl_15"):setVisible(false)
		list:getChildByName("table_lbl_20"):setVisible(false)
		if num == 1 then list:getChildByName("table_lbl_5"):setVisible(true) 
		elseif num == 2 then list:getChildByName("table_lbl_10"):setVisible(true) 
		elseif num == 3 then list:getChildByName("table_lbl_15"):setVisible(true) 
		elseif num == 4 then list:getChildByName("table_lbl_20"):setVisible(true) 
		end

		list:getChildByName("txt_jj_14"):getChildByName("txt"):setString(getTextByKey("crossArena_Title4"))
	end

	local function onClickList( evt ) --领取奖励
		if BagCalcManager.isFull() then 
			NewPackageFullPanel:show()
			return 
		end
		local activeId = evt.context
		local function afterCrossPvpActiveRewardRequest()
			if type(self.refreshSelf) == "function" then self.refreshSelf() end
		end
		CrossPvpActiveRewardRequest.sendRequestDefalut(activeId,afterCrossPvpActiveRewardRequest)
		
	end

	local listBtn = {}
	for i = 1,totalCnt do 
		local list = exList[i]
		initListUI(list,i) 
		local btnDisplay = list:getChildByName("btn_blue_short_two")
		listBtn[i] = Button:create(btnDisplay)
		listBtn[i]:addEventListener(Events.kStart, onClickList, i)
	end

	local function refreshListUI() --刷新list状态
		local rewardsArr = CrossArenaManager.getMyActiveRewards()
		local isfinished = {false,false,false,false} --是否已领取
		for k,v in pairs(rewardsArr) do 
			if v then isfinished[v] = true end
		end

		for i = 1,totalCnt do 
			local list = exList[i]
			local isinwork = false
			if nowScore >= arrNum[i] then 
				isinwork = true
			end

			list:getChildByName("other_gray9_panel"):setVisible(false)
			list:getChildByName("other_gray9_panel").touchEnabled = false

			if isinwork then --可领取
				-- list:getChildByName("other_gray9_panel"):setVisible(false)
				-- list:getChildByName("other_gray9_panel").touchEnabled = false
				list:getChildByName("btn_blue_short_two"):setVisible(true)
				list:getChildByName("txt_jj_18"):setVisible(false)
				list:getChildByName("txt_jj_19"):setVisible(false)
				
				list:getChildByName("txt_jj_18"):getChildByName("txt"):setColor(ccc3( 0, 0, 0 ))
				list:getChildByName("txt_jj_19"):getChildByName("txt"):setColor(ccc3( 0, 0, 0 ))
				if not isfinished[i] then --领取
					list:getChildByName("btn_blue_short_two"):getChildByName("txt"):setString(getTextByKey("crossArena_gainActiveReward1"))
					list:getChildByName("btn_blue_short_two"):getChildByName("normal"):setVisible(true)
					listBtn[i]:setEnable(true)
				else --已领取
					list:getChildByName("btn_blue_short_two"):getChildByName("txt"):setString(getTextByKey("crossArena_gainActiveReward2"))
					list:getChildByName("btn_blue_short_two"):getChildByName("normal"):setVisible(false)
					listBtn[i]:setEnable(false)
				end
			else --不可领取，置灰
				-- list:getChildByName("other_gray9_panel"):setVisible(true)
				-- list:getChildByName("other_gray9_panel").touchEnabled = true
				list:getChildByName("btn_blue_short_two"):setVisible(false)
				local exStr = getTextByKey("crossArena_gainActiveReward3",{num = arrNum[i]})
				-- local poia,poib = string.find(exStr,"{num}")
				-- exStr = string.sub(exStr,1,poia-1)..arrNum[i]..string.sub(exStr,poib+1,-1)
				list:getChildByName("txt_jj_18"):getChildByName("txt"):setString(exStr)
				list:getChildByName("txt_jj_19"):getChildByName("txt"):setString(getTextByKey("crossArena_gainActiveReward4"))
				list:getChildByName("txt_jj_18"):getChildByName("txt"):setColor(ccc3( 255, 0, 0 ))
				list:getChildByName("txt_jj_19"):getChildByName("txt"):setColor(ccc3( 255, 0, 0 ))
				list:getChildByName("txt_jj_18"):setVisible(true)
				list:getChildByName("txt_jj_19"):setVisible(true)
				listBtn[i]:setEnable(false)
			end	
		end	
	end

	local function refreshRewardUI() --刷新奖励icon
		if not self.iconpool then self.iconpool = {} end
		for k,v in ipairs(self.iconpool) do 
			exList[v.id]:removeChild(v.feature)
			v.feature:dispose()
		end
		table.removeAll(self.iconpool)

		for i = 1,totalCnt do 
			local list = exList[i]
			local proDisplays = {}
			proDisplays[1] = list:getChildByName("card_normal_card_small_1")
			proDisplays[2] = list:getChildByName("card_normal_card_small_2")
			proDisplays[3] = list:getChildByName("card_normal_card_small_3")
			local proTexts = {}
			proTexts[1] = list:getChildByName("txt_1")
			proTexts[2] = list:getChildByName("txt_2")
			proTexts[3] = list:getChildByName("txt_3")	
			local reward = activeRewards[i].rewards
			for j = 1,iconCnt do 
				if reward[j] then 
					local str = CanonGoodIcon.getGoodName(reward[j].itemType, reward[j].metaId, reward[j].amount)
					proTexts[j]:getChildByName("txt"):setString(str)
					local params = {}
					params.sourceDisplay = proDisplays[j]
					params.showInCenter = false
					local icon = CanonGoodIcon.createGoodIcon(reward[j].itemType, reward[j].metaId, 0, params)
					list:addChildAt(icon,proTexts[j]:getZOrder())
					local icons = {feature = icon,id = i}
					table.insert(self.iconpool,icons)
					proDisplays[j]:setVisible(false) 
					proTexts[j]:setVisible(true)
				else
					proDisplays[j]:setVisible(false) 
					proTexts[j]:setVisible(false)
				end
			end
		end
	end

	self.refreshSelf = function()
		nowScore = DailyDataManager.getCrossPvpDailyData().activeScore
		self.mainUI:getChildByName("txt_jj_10"):getChildByName("txt"):setString(""..nowScore)
		refreshListUI()
	end

	NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self) --跨天监听

	self.refreshSelf()
	refreshRewardUI()
end

function CrossArenaScoreLayer:dispose()
	NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
	table.removeAll(self.iconpool)
	CrossArenaScoreLayer.super.dispose(self)
end
