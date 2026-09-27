require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.panel.RemindingUserGetXiaoyuBigRewardPanel"
require "canon.panel.GachaXiaoyuPointsRankRewardPanel"
require "canon.panel.GachaXiaoyuRankRewardPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_GachaXiaoyuLayer
--小玉嫁到
--by dc
--
local myGachaXiaoyuPoint = 0
local hasEnterGachaXiaoyu = false
Activity_GachaXiaoyuLayer = class(Layer)
function Activity_GachaXiaoyuLayer:ctor()
    self.container = nil
end

function Activity_GachaXiaoyuLayer:create( container, extraArgs )
    local s = Activity_GachaXiaoyuLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

--通过礼包id获得奖励物品的信息
function Activity_GachaXiaoyuLayer.getRewardInfo(rewardPackageId)
  local packageRewardList = MetaManager.getRewardInfoByID(rewardPackageId) or {}
  return packageRewardList[1]
end

function Activity_GachaXiaoyuLayer.getMyPoints()
	return myGachaXiaoyuPoint or 0
end

function Activity_GachaXiaoyuLayer.reseEnterGachaXiaoyu()
	hasEnterGachaXiaoyu = false
end

function Activity_GachaXiaoyuLayer:initLayer()
    Activity_GachaXiaoyuLayer.super.initLayer(self)
    
	hasEnterGachaXiaoyu = true
	
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
	self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("launch_activity_cross_gacha")
    self:addChild(self.mainUI)
    
    
	self.GachaXiaoyuConfig = MetaManager.game_meta.activityGachaXiaoyuConfig
	local activityTimeInfo = MaintenanceManager:getStartAndEndTime("activityGachaXiaoyu")
	local activityGachaMathTimeInfo = MaintenanceManager:getStartAndEndTime("activityGachaXiaoyuPoints")
    local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime("activityGachaXiaoyuGainReward")
	
	--init UI
	self.activityTimeLabel = self.mainUI:getChildByName("txt_2"):getChildByName("txt")
	self.activityTimeDetailLabel = self.mainUI:getChildByName("txt_1"):getChildByName("txt")
	self.activityRemainLabel = self.mainUI:getChildByName("txt_4"):getChildByName("txt")
	self.activityRemainDetailLabel = self.mainUI:getChildByName("txt_3"):getChildByName("txt")
	
	self.activityTimeLabel:setColor(ccc3(0,0,0))
	self.activityTimeLabel:setAroundColor(ccc3(255,255,255))
	self.activityTimeDetailLabel:setColor(ccc3(255,0,0))
	self.activityTimeDetailLabel:setAroundColor(ccc3(255,255,255))
	self.activityRemainLabel:setColor(ccc3(0,0,0))
	self.activityRemainLabel:setAroundColor(ccc3(255,255,255))
	self.activityRemainDetailLabel:setColor(ccc3(255,0,0))
	self.activityRemainDetailLabel:setAroundColor(ccc3(255,255,255))
	
	self.mainUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("activity_points1"))
	self.mainUI:getChildByName("txt_13"):setString(getTextByKey("activity_rankListTitle"))
	self.mainUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("activity_rank1"))
	
	self.mainUI:getChildByName("list"):setVisible(false)
		
	local crossGachaRankRewards = self.GachaXiaoyuConfig.crossGachaRankRewards
	local iconDisplayNames = {"normal_card_small2", "normal_card_small1", "normal_card_small3"}
    local infoDisplayNames = {"txt_la3", "txt_la1", "txt_la5"}
    local nameDisplayNames = {"txt_la4", "txt_la2", "txt_la6"}
	local rankRewardName = {}
	for i=1,3 do
	--排名奖励描述文本
		local rankMax = crossGachaRankRewards[i].rankMax
		local rankMin = crossGachaRankRewards[i].rankMin
		local rankName = "" .. rankMax
		if rankMin == rankMax then
			rankName = "" .. rankMin
		end
		self.mainUI:getChildByName(infoDisplayNames[i]):getChildByName("txt"):setString(getTextByKey("activity_rankinRewardsDes",{num = rankName}))
	--排名奖励图标
		local rewardInfo = Activity_GachaXiaoyuLayer.getRewardInfo(crossGachaRankRewards[i].rewardPackageId)
		local rewardItem = self.mainUI:getChildByName(iconDisplayNames[i])
		local itemIcon = CanonGoodIcon.createGoodIcon(rewardInfo.itemType, rewardInfo.metaId, 0, nil)
		
		itemIcon:setPosition(ccp(rewardItem:getPositionX(), rewardItem:getPositionY()))
		self.mainUI:addChild(itemIcon)	
		rewardItem:setVisible(false)
	--排名奖励名称
		rankRewardName[i] = CanonGoodIcon.getGoodNameByPackageRewardInfo(rewardInfo, {withoutAmount = true})
		self.mainUI:getChildByName(nameDisplayNames[i]):getChildByName("txt"):setString(rankRewardName[i] )
	--奖励详细按钮
		local function onDetailBtnClick(data)
			CanonGoodIcon.popoutGoodPanel(rewardInfo.itemType, rewardInfo.metaId)
		end
		local detailButton = Button:create(itemIcon)
		detailButton:addEventListener(Events.kStart, onDetailBtnClick, rewardInfo)
	end
	
    
    local function infoButtonSelected(evt)
	self.container:setTableViewsEnabled(false)
      
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText("activity_describe", {
	  year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time,
	  year3 = activityGachaMathTimeInfo[1].year,
	  month3 = activityGachaMathTimeInfo[1].month,
	  day3 = activityGachaMathTimeInfo[1].day,
	  time3 = activityGachaMathTimeInfo[1].time,
	  year4 = activityGachaMathTimeInfo[2].year,
	  month4 = activityGachaMathTimeInfo[2].month,
	  day4 = activityGachaMathTimeInfo[2].day,
	  time4 = activityGachaMathTimeInfo[2].time,
	  year5 = activityGainRewardTimeInfo[1].year, month5 = activityGainRewardTimeInfo[1].month, day5 = activityGainRewardTimeInfo[1].day, time5 = activityGainRewardTimeInfo[1].time, year6 = activityGainRewardTimeInfo[2].year, month6 = activityGainRewardTimeInfo[2].month, day6 = activityGainRewardTimeInfo[2].day, time6 = activityGainRewardTimeInfo[2].time,
	  
																														  num1 = self.GachaXiaoyuConfig.commonGachaPoints, 
																														  num2 = self.GachaXiaoyuConfig.commonTenPoints, 
																														  num3 = self.GachaXiaoyuConfig.ultimatedGachaPoints, 
																														  num4 = self.GachaXiaoyuConfig.ultimatedTenPoints, 
																														  num5 = self.GachaXiaoyuConfig.activityGachaPoints, 
																														  num6 = self.GachaXiaoyuConfig.advancedGachaPoints, 
																														  name1 = rankRewardName[1] , 
																														  name2 = rankRewardName[2] , 
																														  name3 = rankRewardName[3] , 
																														  rankNum = self.GachaXiaoyuConfig.rankingNum
																																	  }))
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
	


    refreshSelf  = function()
		local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose("activityGachaXiaoyuPoints")
		if not whetherPassedActivityTime then
			--抽卡积分比赛阶段
			self.GachaOrRankBtnTxt:setString(getTextByKey("activity_GachaButton"))
			
			self.activityTimeLabel:setVisible(true)
			self.activityTimeDetailLabel:setVisible(true)
			self.activityRemainLabel:setVisible(true)
			self.activityRemainDetailLabel:setVisible(true)
			
			self.activityTimeLabel:setString(getTextByKey("activity_GachaTime1"))
			self.activityTimeDetailLabel:setString(getTextByKey("activity_GachaTime2",{year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time}))
			self.activityRemainLabel:setString(getTextByKey("activity_remainingTime1"))
			self.activityRemainDetailLabel:setString(getTextByKey("activity_countdown2", {hour = math.modf(leftActivityTimeStamp / 3600), min = math.modf(math.mod(leftActivityTimeStamp, 3600) / 60)}))
		else
			--排名奖励阶段
			if self.existInRank then
			else
				self.GachaOrRankBtnDisplay:getChildByName("normal"):setVisible(false)
				self.gachaOrRankBtn:setEnable(false) 
			end
			self.GachaOrRankBtnTxt:setString(getTextByKey("activity_rankinButton"))
			
			if self.extraArgs.crossGachaUserInfo.gainedRankReward or self.extraArgs.crossGachaUserInfo.gainedMysteriousReward then
				--已领取奖励
				self.GachaOrRankBtnDisplay:getChildByName("normal"):setVisible(false)
				self.gachaOrRankBtn:setEnable(false) 
				self.GachaOrRankBtnTxt:setString(getTextByKey("activity_receivedButton"))
			end
			
			if not self.extraArgs.crossGachaUserInfo.gainedMysteriousReward  and self.firstUserServerId and self.firstUserServerId == self.myServerId  then
				self.GachaOrRankBtnDisplay:getChildByName("normal"):setVisible(true)
				self.gachaOrRankBtn:setEnable(true) 
				self.GachaOrRankBtnTxt:setString(getTextByKey("activity_rankinButton"))
			end
			
			self.activityRemainLabel:setVisible(false)
			self.activityRemainDetailLabel:setVisible(false)
			
			self.activityTimeLabel:setString(getTextByKey("activity_rewardsTime1"))
			self.activityTimeDetailLabel:setString(getTextByKey("activity_GachaTime2",{year1 = activityGainRewardTimeInfo[1].year, month1 = activityGainRewardTimeInfo[1].month, day1 = activityGainRewardTimeInfo[1].day, time1 = activityGainRewardTimeInfo[1].time, year2 = activityGainRewardTimeInfo[2].year, month2 = activityGainRewardTimeInfo[2].month, day2 = activityGainRewardTimeInfo[2].day, time2 = activityGainRewardTimeInfo[2].time}))
			
			if self.checkActivityPassedEntry then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
				self.checkActivityPassedEntry = nil
			end
		end
    end
--积分奖励按钮
    local function onPointsBtnClick(evt)
      self.container:setTableViewsEnabled(false)
      self.aInfoPanel = GachaXiaoyuPointsRankRewardPanel:create(self.container, self.extraArgs, refreshSelf )
      self.container:addChild(self.aInfoPanel)
      self.aInfoPanel:scaleIn()
    end
	self.mainUI:getChildByName("btn_yellow_long_1"):getChildByName("txt"):setString(getTextByKey("activity_pointsButton"))
    local pointsBtn = Button:create(self.mainUI:getChildByName("btn_yellow_long_1"))
    pointsBtn:addEventListener(Events.kStart,onPointsBtnClick, self)
	
--去求将 and 排名奖励按钮
	local function onGachaOrRankBtnClick(evt)
		if MaintenanceManager.isActivityOpen("activityGachaXiaoyuPoints") then
			--抽卡积分比赛阶段
			self.container:replaceScene(GachaScene, {returnScene = "Activity_GachaXiaoyuLayer"})
		else
			--排名奖励阶段
			--
			if BagCalcManager.isFull() then
				--背包已满
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				-- SuspensionLabel:showContent(self, aContent)
				NewPackageFullPanel:show()
				return
			end
			
			--成功
			local function onSucceed(event)
				--print("gain返回成功信息 = " .. table.tostring(event))
				--奖励物品
				--玩家点击确定获取
				local function onGet()
					self.container:setTableViewsEnabled(true)
					self.GachaOrRankBtnDisplay:getChildByName("normal"):setVisible(false)
					self.gachaOrRankBtn:setEnable(false) 
					self.GachaOrRankBtnTxt:setString(getTextByKey("activity_receivedButton"))
				end
				
				RewardManager:getReward(event.data.rankRewards)
				RewardManager:getReward(event.data.mysteriousRewards)
				
				local gameInitData = DataManager:getGameInitData()
				gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedMysteriousReward = true
				gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedRankReward = true
				DataManager.setGameInitData(gameInitData)

				--这两个值不设置会导致刷新有问题
				self.extraArgs.crossGachaUserInfo.gainedRankReward = true
				self.extraArgs.crossGachaUserInfo.gainedMysteriousReward = true
				
  
				--显示获得的奖励
				self.container:setTableViewsEnabled(false)
				if (event.data.mysteriousRewards == nil or #event.data.mysteriousRewards == 0) then
					--不在第一名所在区的玩家领取奖励，不含神秘奖励
					local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = event.data.rankRewards, rewardTitle = Localization:getInstance():getText("worldBoss_claimReward_txt"), callback = onGet} )
					self.container:addChild(aRewardPanel)
					aRewardPanel:scaleIn()
				else
					--在第一名所在区的玩家领取奖励，含神秘奖励
					self.targetRewardPanel = GachaXiaoyuRankRewardPanel:create( self.container, event.data ,onGet)
					PopoutManager:sharedManager():popout(self.targetRewardPanel, kPopoutDir.kScale, true, false ,self) 
				end
				
			end 
	
			--发送指令
			CrossGachaGainRankRewardRequest.sendRequest(onSucceed, CrossGachaGainRankRewardRequest.onFailedDefault)
			--
		end
    end
	self.GachaOrRankBtnTxt = self.mainUI:getChildByName("btn_yellow_long_2"):getChildByName("txt")
	self.GachaOrRankBtnDisplay = self.mainUI:getChildByName("btn_yellow_long_2")
    self.gachaOrRankBtn = Button:create(self.GachaOrRankBtnDisplay)
    self.gachaOrRankBtn:addEventListener(Events.kStart,onGachaOrRankBtnClick, self)
    self.myServerId = string.sub(DataManager.getCurrUser().uid,string.len(DataManager.getCurrUser().uid)-3)
	--refreshSelf()
    self.refreshSelf = refreshSelf
		
	if not self.checkActivityPassedEntry then
		self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,15,false)
	end
	
	self.firstUserServerId = nil
	self:resetExtraArgs(self.extraArgs)
	--提醒玩家领取神秘大奖
	
	if MaintenanceManager.isActivityOpen("activityGachaXiaoyuGainReward") and not self.extraArgs.crossGachaUserInfo.gainedMysteriousReward  and self.firstUserServerId and self.firstUserServerId == self.myServerId  then
		local firstUserNickName = self.firstUserNickName
		RemindingUserGetXiaoyuBigRewardPanel:show(firstUserNickName,nil)
	end
end

function Activity_GachaXiaoyuLayer:resetExtraArgs(extraArgs)
  self.extraArgs = extraArgs
  self.existInRank = false
  local aRank
  myGachaXiaoyuPoint = extraArgs.crossGachaUserInfo.point
  Activity_GachaXiaoyuLayer.setGachaPoint(myGachaXiaoyuPoint)
  for k, v in ipairs(self.extraArgs.crossGachaRanks or {}) do
	if k == 1 then
		self.firstUserServerId = string.sub(v.uid,string.len(v.uid)-3)
		self.firstUserNickName = v.nickname
	end
    if tonumber(v.uid, 10) == tonumber(DataManager.getCurrUser().uid, 10) then
      self.existInRank = true
      aRank = k
    end
    v.rank = k
  end
  
  if self.existInRank then
    self.mainUI:getChildByName("txt_12"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_rank2", {num = aRank}))
  else
    self.mainUI:getChildByName("txt_12"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_outOfRank"))
  end
  self.mainUI:getChildByName("txt_8"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_points2", {num = myGachaXiaoyuPoint}))
  
  if not self.rankTableView then
    self.rankTableView = self:createRankTableView()
    self.mainUI:addChild(self.rankTableView)
  end
  self.rankTableView:reloadData()
  
  self.refreshSelf()
end

local table_width = 620
local table_height = 160
local table_posX = 40
local table_posY = 120
local item_width = 600
local item_height = 30

function Activity_GachaXiaoyuLayer:createRankTableView()
  local cellTag = 1024
  local buttonTag = {}
  local aPanel = self
  local RankTableViewRenderer = class(TableViewRenderer)
  function RankTableViewRenderer:ctor(width, height)
    self.list = aPanel.extraArgs.crossGachaRanks or {}
  end
  function RankTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    local aCell = builder:build("list/activity_xiaoyujiadao_1_list")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    
    local aNumLabel = aCell:getChildByName("txt_1")
    aNumLabel:setTag(-10)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
    
    local aNameLabel = aCell:getChildByName("txt_2")
    aNameLabel:setTag(-11)
    aNameLabel = aNameLabel:getChildByName("txt")
    aNameLabel:setTag(-10)
    
    local aScoreLabel = aCell:getChildByName("txt_3")
    aScoreLabel:setTag(-12)
    aScoreLabel = aScoreLabel:getChildByName("txt")
    aScoreLabel:setTag(-10)
  end
  function RankTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    
    local aNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
    setNodeText(aNumLabel, getTextByKey("activity_rank2",{ num = string.format("%d", self.list[index + 1].rank)}))
    
    local aNameLabel = aCell:getChildByTag(-11):getChildByTag(-10)
	local serverArea = getServerIdFromUid(self.list[index + 1].uid)
    setNodeText(aNameLabel, self.list[index + 1].nickname .. "(" ..getTextByKey("activity_area",{name = serverArea}).. ")")
    
    local aScoreLabel = aCell:getChildByTag(-12):getChildByTag(-10)
    setNodeText(aScoreLabel, Localization:getInstance():getText("activity_gachaPoints_point", {num = self.list[index + 1].point}))
  end
  
  local renderer = RankTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function Activity_GachaXiaoyuLayer:enable()
	--return true 
	local serverOpen = false
	local serverId = DataManager.getServerid()
	if MetaManager.game_meta.activityGachaXiaoyuConfig and MetaManager.game_meta.activityGachaXiaoyuConfig.crossGachaServerGroups then
		for k,v in pairs(MetaManager.game_meta.activityGachaXiaoyuConfig.crossGachaServerGroups) do 
			local serverList = v.serverIds
			local serverInGroup = false
			for ck,cv in pairs(serverList) do
				if cv == serverId then
					serverOpen = true 
					break
				end
			end
			if serverOpen then
				break
			end
		end
	end
    local isEnable = serverOpen and MaintenanceManager.isActivityOpen("activityGachaXiaoyu")
    return isEnable
end 

function Activity_GachaXiaoyuLayer:setTouchEnabled(isEnable)
  if self.rankTableView then
    self.rankTableView:setTouchEnabled(isEnable)
  end
end

function Activity_GachaXiaoyuLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_GachaXiaoyuLayer.super.dispose(self)
end

function Activity_GachaXiaoyuLayer.getTipNum()
  if not Activity_GachaXiaoyuLayer.enable() then
    return 0
  end
  
  local aTipNum = 0
  
  if not hasEnterGachaXiaoyu then
	--aTipNum = 1
	--未进入过小玉嫁到界面
	--return aTipNum
  end
  
  local gameInitData = DataManager.getGameInitData()
  gameInitData.sharkActivityExtend = gameInitData.sharkActivityExtend or {}
  local myUid = DataManager.getCurrUser().uid
  local myServerId = string.sub(myUid,string.len(myUid)-3)
  local myPoint = gameInitData.sharkActivityExtend.crossGachaUserInfo and gameInitData.sharkActivityExtend.crossGachaUserInfo.point or 0
  local pointList = DataManager.GameMetaData.activityGachaXiaoyuConfig.crossGachaPointRewards or {}
  for k,v in ipairs(pointList) do
    if myPoint >= v.pointMin then
      if not Activity_GachaXiaoyuLayer.checkGained(v.id) then
        aTipNum =  1
		-- 有积分奖励未领取
		return aTipNum
      end
    end
  end
  --commented out by jet
  --local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose("activityGachaXiaoyu")
  if MaintenanceManager.isActivityOpen("activityGachaXiaoyuGainReward") then
    
    if gameInitData.sharkActivityExtend.crossGachaUserInfo and gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedRankReward then
	  if not gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedRankReward then
		local crossGachaRanks = gameInitData.crossGachaRanks or {}
		for k,v in pairs(crossGachaRanks) do 
			if k == 1 then
				local firstUserServerId = string.sub(v.uid,string.len(v.uid)-3)
				if myServerId == firstUserServerId then
					aTipNum = 1
					--排名奖励阶段，排名第一玩家同区玩家未领取排名奖励
					return aTipNum
				end
			end
			if v.uid == myUid then
				aTipNum = 1
				--排名奖励阶段，进入排名且未领取排名奖励
				return aTipNum
			end
		end
	  end
    end
    return aTipNum
  end
  return aTipNum
end

----
--以下为数据读取操作----------------------------------------------------

--获取小玉嫁到活动的玩家信息包
function Activity_GachaXiaoyuLayer.getGachaXiaoyuPointsInfo()
  local gameInitData = DataManager:getGameInitData()

  if not gameInitData.sharkActivityExtend then
    --没有总活动信息 创建一个
    gameInitData.sharkActivityExtend = {}
    DataManager.setGameInitData(gameInitData)
  end

  if not gameInitData.sharkActivityExtend.crossGachaUserInfo then
    --没有此活动信息 进行初始化工作
    gameInitData.sharkActivityExtend.crossGachaUserInfo = {}
	gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedMysteriousReward = false
    gameInitData.sharkActivityExtend.crossGachaUserInfo.point = 0
    gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedRankReward = false
    gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedPointRewardIds = {}
    DataManager.setGameInitData(gameInitData)
  end

  return gameInitData.sharkActivityExtend.crossGachaUserInfo
end

--得到所有已领取过的id列表
function Activity_GachaXiaoyuLayer.getGainedList()
  return Activity_GachaXiaoyuLayer.getGachaXiaoyuPointsInfo().gainedPointRewardIds
end

--检查该id是否已领取
function Activity_GachaXiaoyuLayer.checkGained(id)
  local gainedList = Activity_GachaXiaoyuLayer.getGainedList()
  for k,v in ipairs(gainedList) do
    --print("v.id = " .. v.id .. ", id = " .. id)
    if v == id then
      return true
    end
  end
  return false
end

--查询是否能够领奖
function Activity_GachaXiaoyuLayer:checkCanGain(aData)
  if Activity_GachaXiaoyuLayer.checkGained(aData.id) then
    return false
  end
  if Activity_GachaXiaoyuLayer.getGachaXiaoyuPointsInfo().point < aData.pointMin then
    return false
  end
  return true
end

--以下为数据写入操作----------------------------------------------------

--已获取列表里插入一个新的id
function Activity_GachaXiaoyuLayer.setGainedToList(id)
  local gainedList = Activity_GachaXiaoyuLayer.getGainedList()
  table.insert(gainedList, id)

  local gameInitData = DataManager:getGameInitData()
  gameInitData.sharkActivityExtend.crossGachaUserInfo.gainedPointRewardIds = gainedList
  DataManager.setGameInitData(gameInitData)
end

--重写Gacha后的分值
function Activity_GachaXiaoyuLayer.setGachaPoint(point)
	--预防空表
	Activity_GachaXiaoyuLayer.getGachaXiaoyuPointsInfo()
	
	local gameInitData = DataManager:getGameInitData()
	gameInitData.sharkActivityExtend.crossGachaUserInfo.point = point 
	DataManager.setGameInitData(gameInitData)
end