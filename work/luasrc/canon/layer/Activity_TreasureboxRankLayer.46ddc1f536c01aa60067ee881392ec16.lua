--
-- Activity_TreasureboxRankLayer.lua
-- Author: zheng.che
-- Date: 2014-02-27 11:05:53
--
require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.TreasureboxRankRewardRequest"
require "canon.panel.TreasureboxRankRewardPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
--自己的积分(不一定为显示值)
local _myPoints = 0


Activity_TreasureboxRankLayer = class(Layer)
function Activity_TreasureboxRankLayer:ctor()
    self.container = nil
end

function Activity_TreasureboxRankLayer:create( container, extraArgs )
    local s = Activity_TreasureboxRankLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    --print("self.extraArgs = " .. table.tostring(self.extraArgs))

    _myPoints = self.extraArgs.myPoints

    s:initLayer()
    return s
end

function Activity_TreasureboxRankLayer:initLayer()
  Activity_TreasureboxRankLayer.super.initLayer(self)

  Activity_TreasureboxRankLayer.recheckFeatureBeginState()--先校验数据是否可用
    
	local featureNameAB = DataManager.GameMetaData.activityTreasureboxPointsConfig.featureNameTreasureboxPoints
	local featureNameBC = DataManager.GameMetaData.activityTreasureboxPointsConfig.featureNameGainReward
	local featureNameAC = DataManager.GameMetaData.activityTreasureboxPointsConfig.featureNamePanel
  local activityTimeInfo = MaintenanceManager:getStartAndEndTime(featureNameAB)
  local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime(featureNameBC)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.mainUI = self.builder:build("launch_activity7")
    self:addChild(self.mainUI)
    self.builder.useArtLabelTTF = true
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      local RewardMetas = Activity_TreasureboxRankLayer.getRankRewardMetas()
      -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~Reward = "..tostringRich(RewardMetas))
      local RewardNameList = {}
      for i=1,3 do
        local reward = MetaManager.getRewardInfoByID(RewardMetas[i].rewardPackageId)
        local rewardsName = CanonGoodIcon.getGoodName(reward[1].itemType, reward[1].metaId, reward[1].amount,{withoutAmount = true})
        -- print("~~~~~~~~~~~~~~~~~~~~~~~~~rewardsName = "..tostringRich(rewardsName))
        table.insert(RewardNameList,rewardsName)
      end
      
      
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText("activity-treasurebox-txt", {year1 = activityTimeInfo[1].year, 
                                                                                                                                  month1 = activityTimeInfo[1].month, 
                                                                                                                                  day1 = activityTimeInfo[1].day, 
                                                                                                                                  time1 = activityTimeInfo[1].time, 
                                                                                                                                  year2 = activityTimeInfo[2].year, 
                                                                                                                                  month2 = activityTimeInfo[2].month, 
                                                                                                                                  day2 = activityTimeInfo[2].day, 
                                                                                                                                  time2 = activityTimeInfo[2].time, 
                                                                                                                                  year3 = activityGainRewardTimeInfo[1].year, 
                                                                                                                                  month3 = activityGainRewardTimeInfo[1].month, 
                                                                                                                                  day3 = activityGainRewardTimeInfo[1].day, 
                                                                                                                                  time3 = activityGainRewardTimeInfo[1].time, 
                                                                                                                                  year4 = activityGainRewardTimeInfo[2].year, 
                                                                                                                                  month4 = activityGainRewardTimeInfo[2].month, 
                                                                                                                                  day4 = activityGainRewardTimeInfo[2].day, 
                                                                                                                                  time4 = activityGainRewardTimeInfo[2].time, 
                                                                                                                                  name1 = RewardNameList[1],
                                                                                                                                  name2 = RewardNameList[2],
                                                                                                                                  name3 = RewardNameList[3],
                                                                                                                                  }))
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_activity_helpinfo"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    --print("开宝箱配置 = " .. table.tostring(DataManager.GameMetaData.activityTreasureboxPointsConfig))
    local iconDisplayNames = {"normal_card_small2", "normal_card_small1", "normal_card_small3"}
    local infoDisplayNames = {"txt_la3", "txt_la1", "txt_la5"}
    local nameDisplayNames = {"txt_la4", "txt_la2", "txt_la6"}
    local rankRewards = DataManager.GameMetaData.activityTreasureboxPointsConfig.rankRewardMetas
    for k,v in ipairs(rankRewards) do
    	if k <= 3 then
        local rewardInfo = Activity_TreasureboxRankLayer.getRewardInfo(v.rewardPackageId)
    		if rewardInfo then

	    		local iconDisplay = self.mainUI:getChildByName(iconDisplayNames[k])
	    		local infoDisplay = self.mainUI:getChildByName(infoDisplayNames[k])
	    		local nameDisplay = self.mainUI:getChildByName(nameDisplayNames[k])


  				iconDisplay:setVisible(false)
  				local equipIcon = CanonItem:create()
  				equipIcon:loadByMetaId(rewardInfo.metaId, false, true)
  				equipIcon:setPosition(ccp(iconDisplay:getPositionX(), iconDisplay:getPositionY()))
  				--equipIcon:setScale(0.8)
  				self.mainUI:addChild(equipIcon)

          if v.rankMax == 1 then
            --第一名
            infoDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-give1", {num1 = v.rankMax}))
          else
            infoDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-give", {num1 = v.rankMax}))
          end
  				nameDisplay:getChildByName("txt"):setString(Localization:getInstance():getText(MetaManager.equip_meta[rewardInfo.metaId].name))
  			end
    	end
    end

    --这几个不显示 不需要
    --活动还剩
    self.mainUI:getChildByName("txt_newyear_reward_time2"):setVisible(false)
    --[xx小时xx分]
    self.mainUI:getChildByName("txt_newyear_reward_time2_1"):setVisible(false)
    --结束
    self.mainUI:getChildByName("txt_owurida"):setVisible(false)
    
    --活动时间
    local rewardLabel1_1 = self.mainUI:getChildByName("txt_newyear_reward_time1")
    rewardLabel1_1:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_1:getChildByName("txt"):getDimensions().height))
    rewardLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-time2"))
    local rewardLabel1_2 = self.mainUI:getChildByName("txt_newyear_reward_time1_1")
    local aNewPosX = rewardLabel1_1:getPosition().x + rewardLabel1_1:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_2:setPositionX(aNewPosX)

    -- local rewardLabel1_3 = self.mainUI:getChildByName("txt_newyear_reward_time2")
    -- rewardLabel1_3:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_3:getChildByName("txt"):getDimensions().height))
    -- rewardLabel1_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown1"))
    -- local rewardLabel1_4 = self.mainUI:getChildByName("txt_newyear_reward_time2_1")
    -- aNewPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width
    -- rewardLabel1_4:setPositionX(aNewPosX)
    -- rewardLabel1_4:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_4:getChildByName("txt"):getDimensions().height))
    -- local rewardLabel1_5 = self.mainUI:getChildByName("txt_owurida")
    -- rewardLabel1_5:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown3"))

    local rewardLabel2_1 = self.mainUI:getChildByName("txt_wonreward_over")
    rewardLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-over"))
    local rewardLabel2_2 = self.mainUI:getChildByName("txt_activity_getreward_time")
    rewardLabel2_2:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel2_2:getChildByName("txt"):getDimensions().height))
    rewardLabel2_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-time4"))
    local rewardLabel2_3 = self.mainUI:getChildByName("txt_newyear_reward_time1_2")
    aNewPosX = rewardLabel2_2:getPosition().x + rewardLabel2_2:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel2_3:setPositionX(aNewPosX)
    
    local refreshSelf
    
    local showRewardListButtonDisplay = self.mainUI:getChildByName("btn_togacha")
    showRewardListButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-reward"))

    local function onDataRefresh()
      refreshSelf()
      self.container:resetTipInfoForActivity("Activity_Treasurebox")
    end

    local function showRewardListButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      self.aInfoPanel = TreasureboxRankRewardPanel:create(self.container, self.extraArgs, onDataRefresh)
      self.container:addChild(self.aInfoPanel)
      self.aInfoPanel:scaleIn()
    end
    local gachaButton = Button:create(showRewardListButtonDisplay)
    gachaButton:addEventListener(Events.kStart,showRewardListButtonSelected, self)

    local buyButtonDisplay = self.mainUI:getChildByName("btn_togacha_r")
    buyButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-buy"))
    local function buyButtonSelected(evt)
      Director:mgr():run():replaceScene(ShopScene, {enterScene="Activity_TreasureboxRankLayer",returnScene="Activity_TreasureboxRankLayer", params = {tabIndex = TABLEVIEW_TAB_INDEX.VIP_SHOP}})
    end
    local buyButton = Button:create(buyButtonDisplay)
    buyButton:addEventListener(Events.kStart,buyButtonSelected, self)

    local gainButtonDisplay = self.mainUI:getChildByName("btn_getreward")
    self.gainButtonDisplay = gainButtonDisplay
    local function gainButtonSelected(evt)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function onSucceed(event)
        --print("onSucceed! event = " .. table.tostring(event))
        RewardManager:getReward(event.data.rewards)
        Activity_TreasureboxRankLayer.setRankRewardGained()

        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_Treasurebox")
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, event.data.rewards )
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
      end 
      TreasureboxRankRewardRequest.sendRequest(onSucceed, TreasureboxRankRewardRequest.onFailedDefault)
    end
    local gainButton = Button:create(gainButtonDisplay)
    gainButton:addEventListener(Events.kStart,gainButtonSelected, self)
    self.gainButton = gainButton

    --定期重新获取排名信息
    local function reloadRankData()
      local function getTreasureInfoSucceed(event)
        --print("getTreasureInfoSucceed1! ")

        for i = #self.rankList, 1, -1 do
          table.remove(self.rankList, i)
        end
        for _, v in ipairs(event.data.treasureboxPointsRanks) do
          table.insert(self.rankList, v)
        end

        self:resetExtraArgs(event.data)
      end
      TreasureboxPointsInfoGetRequest.sendRequest(true, getTreasureInfoSucceed, TreasureboxPointsInfoGetRequest.onFailedDefault)
    end
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose(featureNameAB)
      local whetherPassedGainRewardTime, leftGainRewardTimeStamp, gainEndMonth, gainEndDay, gainEndHour, gainEndYear = MaintenanceManager.isActivityAlreadyClose(featureNameBC)
      if whetherPassedActivityTime then
        rewardLabel1_1:setVisible(false)
        rewardLabel1_2:setVisible(false)
        -- rewardLabel1_3:setVisible(false)
        -- rewardLabel1_5:setVisible(false)
        -- rewardLabel1_4:setVisible(false)
        rewardLabel2_1:setVisible(true)
        rewardLabel2_2:setVisible(true)
        rewardLabel2_3:setVisible(true)
        rewardLabel2_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-time5", {num1 = activityGainRewardTimeInfo[2].year, num2 = activityGainRewardTimeInfo[2].month, num3 = activityGainRewardTimeInfo[2].day, num4 = activityGainRewardTimeInfo[2].time}))
        
        -- gachaButton:setEnable(false)
        buyButtonDisplay:setVisible(false)
        if Activity_TreasureboxRankLayer.getTreasureboxPointsInfo().gainedRankReward then
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-got"))--已领取
          gainButton:setEnable(false)
        elseif not self.existInRank then
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-rank"))
          gainButton:setEnable(false)
        else
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(true)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-rank"))
          gainButton:setEnable(true)
        end
        
        if self.checkActivityPassedEntry then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
          self.checkActivityPassedEntry = nil
        end
      else
        rewardLabel1_1:setVisible(true)
        rewardLabel1_2:setVisible(true)
        -- rewardLabel1_3:setVisible(true)
        -- rewardLabel1_4:setVisible(true)
        -- rewardLabel1_5:setVisible(true)
        rewardLabel2_1:setVisible(false)
        rewardLabel2_2:setVisible(false)
        rewardLabel2_3:setVisible(false)
        rewardLabel1_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-time3", {num1 = activityTimeInfo[1].month, num2 = activityTimeInfo[1].day, num3 = activityTimeInfo[1].time, num4 = activityTimeInfo[2].month, num5 = activityTimeInfo[2].day, num6 = activityTimeInfo[2].time}))
        -- rewardLabel1_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown2", {hour = math.modf(leftActivityTimeStamp / 3600), min = math.modf(math.mod(leftActivityTimeStamp, 3600) / 60)}))
        -- local aPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width + rewardLabel1_4:getChildByName("txt"):getTexture():getContentSize().width
        -- rewardLabel1_5:setPositionX(aPosX)
        
        -- gachaButton:setEnable(true)
        buyButtonDisplay:setVisible(true)
        gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
        gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-rank"))
        gainButton:setEnable(false)
        
        if not self.checkActivityPassedEntry then
          self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(reloadRankData,15,false)
        end
      end

      

      if Activity_TreasureboxRankLayer.havePointReward() then
        --有可以领的积分奖
        if not self.rewardParticle then
          --显示粒子效果
          self.rewardParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(showRewardListButtonDisplay:getPositionX(), showRewardListButtonDisplay:getPositionY()), 1, 1000, self.mainUI)
          self.rewardParticle.refCocosObj:setPositionType(kCCPositionTypeRelative);
          local contentSize = showRewardListButtonDisplay:getChildByName("btn_yellow_long"):getContentSize()
          local width = showRewardListButtonDisplay:getChildByName("btn_yellow_long"):getScaleX() * contentSize.width
          local height = showRewardListButtonDisplay:getChildByName("btn_yellow_long"):getScaleY() * contentSize.height
          ParticleManager.moveParticle(self.rewardParticle, 1, {ccp(width, 0), ccp(0, -height), ccp(-width, 0), ccp(0, height)})
        end
      else
        --删除粒子效果
        if self.rewardParticle then --删除粒子效果
          self.rewardParticle:removeFromParentAndCleanup(true)
        end
      end
    end
    
    self.refreshSelf = refreshSelf
    
    self.rankList = self.extraArgs.treasureboxPointsRanks or {}
    self:resetExtraArgs(self.extraArgs)
    
    self.mainUI:getChildByName("txt_wonreward_score_rank_title"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_gachaPoints_ranking"))
    
end

function Activity_TreasureboxRankLayer:resetExtraArgs(extraArgs)
  self.extraArgs = extraArgs
  self.existInRank = false
  local aRank
  for k, v in ipairs(self.extraArgs.treasureboxPointsRanks or {}) do
    if tonumber(v.uid, 10) == tonumber(DataManager.getCurrUser().uid, 10) then
      self.existInRank = true
      aRank = k
    end
    v.rank = k
  end
  if self.existInRank then
    self.mainUI:getChildByName("txt_activity_playerrank_self2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-rank2") .. aRank)
  else
    self.mainUI:getChildByName("txt_activity_playerrank_self2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-rank2") .. Localization:getInstance():getText("activity-treasurebox-nolist"))
  end
  self.mainUI:getChildByName("txt_activity_playerscore_self"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-treasurebox-points") .. self.extraArgs.myPoints)
  
  if not self.rankTableView then
    self.rankTableView = self:createRankTableView()
    self.mainUI:addChild(self.rankTableView)
  end
  self.rankTableView:reloadData()
  self.refreshSelf()
end

local table_width = 600--498
local table_height = 223--225
local table_posX = 111
local table_posY = 140--143
local item_width = 498
local item_height = 30

function Activity_TreasureboxRankLayer:createRankTableView()
  local cellTag = 1024
  local buttonTag = {}
  local aPanel = self
  local RankTableViewRenderer = class(TableViewRenderer)
  function RankTableViewRenderer:ctor(width, height)
    self.list = aPanel.rankList or {}
  end
  function RankTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    local aCell = builder:build("txt/txt_combine2")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("txt_activity_playerrank_r"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_rankTxt1"))
    aCell:getChildByName("txt_activity_playerrank3_r"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_rankTxt2"))
    
    local aNumLabel = aCell:getChildByName("txt_activity_playerrank2_r")
    aNumLabel:setTag(-10)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
    
    local aNameLabel = aCell:getChildByName("txt_activity_playername_r")
    aNameLabel:setTag(-11)
    aNameLabel = aNameLabel:getChildByName("txt")
    aNameLabel:setTag(-10)
    
    local aScoreLabel = aCell:getChildByName("txt_activity_playerscore_r")
    aScoreLabel:setTag(-12)
    aScoreLabel = aScoreLabel:getChildByName("txt")
    aScoreLabel:setTag(-10)
  end
  function RankTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    
    local aNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
    setNodeText(aNumLabel, string.format("%d", self.list[index + 1].rank))
    
    local aNameLabel = aCell:getChildByTag(-11):getChildByTag(-10)
    setNodeText(aNameLabel, self.list[index + 1].nickName)
    
    local aScoreLabel = aCell:getChildByTag(-12):getChildByTag(-10)
    setNodeText(aScoreLabel, Localization:getInstance():getText("activity_gachaPoints_point", {num = self.list[index + 1].points}))
  end
  local renderer = RankTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function Activity_TreasureboxRankLayer:enable()
  if not DataManager.GameMetaData.activityTreasureboxPointsConfig then
    return false
  end
  local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityTreasureboxPointsConfig.featureNamePanel)
  return isEnable
end 

function Activity_TreasureboxRankLayer:setTouchEnabled(isEnable)
  if self.rankTableView then
    self.rankTableView:setTouchEnabled(isEnable)
  end
end

function Activity_TreasureboxRankLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_TreasureboxRankLayer.super.dispose(self)
end

------------------------------------------------------------------------------------------------------------------------------------------
--静态函数
------------------------------------------------------------------------------------------------------------------------------------------

--检查该id是否已领取
function Activity_TreasureboxRankLayer.checkGained(id)
  local gainedList = Activity_TreasureboxRankLayer.getGainedList()
  for k,v in ipairs(gainedList) do
    --print("v.id = " .. v.id .. ", id = " .. id)
    if v == id then
      return true
    end
  end
  return false
end

--查询是否能够领奖
function Activity_TreasureboxRankLayer:checkCanGain(aData)
  if Activity_TreasureboxRankLayer.checkGained(aData.id) then
    return false
  end
  if Activity_TreasureboxRankLayer.getMyPoints() < aData.pointMin then
    return false
  end
  return true
end

--通过礼包id获得奖励物品的信息
function Activity_TreasureboxRankLayer.getRewardInfo(rewardPackageId)
  local packageRewardList = MetaManager.getRewardInfoByID(rewardPackageId) or {}
  return packageRewardList[1]
end

--查询是否有能领的积分奖励
function Activity_TreasureboxRankLayer.havePointReward()
  local dataList = {}
  if not DataManager.GameMetaData.activityTreasureboxPointsConfig then
    return false
  end
  dataList = DataManager.GameMetaData.activityTreasureboxPointsConfig.pointRewardMetas or {}
  for k,v in ipairs(dataList) do
    if Activity_TreasureboxRankLayer:checkCanGain(v) then
      return true
    end
  end
  return false
end

--获得配置
function Activity_TreasureboxRankLayer.getMetas()
  return DataManager.GameMetaData.activityTreasureboxPointsConfig
end

--获得活动开关名称
function Activity_TreasureboxRankLayer.getRankRewardMetas()
  local metas = Activity_TreasureboxRankLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  return metas.rankRewardMetas
end

--校验活动是否开启
function Activity_TreasureboxRankLayer.recheckFeatureBeginState()
  local featureNameAC = DataManager.GameMetaData.activityTreasureboxPointsConfig.featureNamePanel
  local activityBeginTime = MaintenanceManager:getStartAndEndTime(featureNameAC)[1].activityBeginTimeStamp
  local serverBeginTime = Activity_TreasureboxRankLayer.getTreasureboxPointsInfo().featureBeginSeconds

  --(不允许上传)测试: 版本号不一致时是否清零
  --serverBeginTime = 0

  -- print("开宝箱活动信息: " .. table.tostring(DataManager:getGameInitData().sharkActivity.treasureboxPointsInfo))
  -- print("配置的活动开始时间: " .. activityBeginTime)

  if activityBeginTime ~= serverBeginTime then
    --活动时间和server传来的标示时间不符 认为server数据无效 清空
    --print("清空!")

    local gameInitData = DataManager:getGameInitData()

    if not gameInitData.sharkActivity then
      --没有总活动信息 创建一个
      gameInitData.sharkActivity = {}
      DataManager.setGameInitData(gameInitData)
    end

    if not gameInitData.sharkActivity.treasureboxPointsInfo then
      --没有此活动信息 进行初始化工作
      gameInitData.sharkActivity.treasureboxPointsInfo = {}
    end

    --正式开始清空
    gameInitData.sharkActivity.treasureboxPointsInfo.featureBeginSeconds = activityBeginTime
    gameInitData.sharkActivity.treasureboxPointsInfo.point = 0
    gameInitData.sharkActivity.treasureboxPointsInfo.gainedRankReward = false
    gameInitData.sharkActivity.treasureboxPointsInfo.gainedPointRewards = {}
    DataManager.setGameInitData(gameInitData)
  end
end

--以下为数据读取操作----------------------------------------------------

--获取开宝箱活动的玩家信息包 禁止自行获取 都要经过这个接口
function Activity_TreasureboxRankLayer.getTreasureboxPointsInfo()
  local gameInitData = DataManager:getGameInitData()

  if not gameInitData.sharkActivity then
    --没有总活动信息 创建一个
    gameInitData.sharkActivity = {}
    DataManager.setGameInitData(gameInitData)
  end

  if not gameInitData.sharkActivity.treasureboxPointsInfo then
    --没有此活动信息 进行初始化工作
    gameInitData.sharkActivity.treasureboxPointsInfo = {}
    gameInitData.sharkActivity.treasureboxPointsInfo.featureBeginSeconds = 0
    gameInitData.sharkActivity.treasureboxPointsInfo.point = 0
    gameInitData.sharkActivity.treasureboxPointsInfo.gainedRankReward = false
    gameInitData.sharkActivity.treasureboxPointsInfo.gainedPointRewards = {}
    DataManager.setGameInitData(gameInitData)
  end

  return gameInitData.sharkActivity.treasureboxPointsInfo
end

--得到所有已领取过的id列表
function Activity_TreasureboxRankLayer.getGainedList()
  return Activity_TreasureboxRankLayer.getTreasureboxPointsInfo().gainedPointRewards
end

--得到自己当前积分
function Activity_TreasureboxRankLayer.getMyPoints()
  return _myPoints
end

--以下为数据写入操作----------------------------------------------------

--已获取列表里插入一个新的id
function Activity_TreasureboxRankLayer.setGainedToList(id)
  local gainedList = Activity_TreasureboxRankLayer.getGainedList()
  table.insert(gainedList, id)

  local gameInitData = DataManager:getGameInitData()
  gameInitData.sharkActivity.treasureboxPointsInfo.gainedPointRewards = gainedList
  DataManager.setGameInitData(gameInitData)
end

--设置已经领取过排名奖励
function Activity_TreasureboxRankLayer.setRankRewardGained()
  Activity_TreasureboxRankLayer.getTreasureboxPointsInfo()--用于保证有值

  local gameInitData = DataManager:getGameInitData()
  gameInitData.sharkActivity.treasureboxPointsInfo.gainedRankReward = true
  DataManager.setGameInitData(gameInitData)
end

function Activity_TreasureboxRankLayer.getTipNum()
  if not Activity_TreasureboxRankLayer.enable() then
    return 0
  end
  
  local aTipNum = 0
  local dataList = DataManager.GameMetaData.activityTreasureboxPointsConfig.pointRewardMetas or {}
  local sharkActivity = DataManager.getSharkActivity()
  local aPoint = sharkActivity.treasureboxPointsInfo and sharkActivity.treasureboxPointsInfo.point or 0
  for k,v in ipairs(dataList) do
    if aPoint >= v.pointMin then
      if not Activity_TreasureboxRankLayer.checkGained(v.id) then
        aTipNum = aTipNum + 1
      end
    end
  end
  local rankRewardGained = sharkActivity.treasureboxPointsInfo and sharkActivity.treasureboxPointsInfo.gainedRankReward or false
  if not rankRewardGained then
    local homeInfo = ActivityPanelScene.getStatusInfo()
    if homeInfo.treasureBoxRankRewardStatus then
      aTipNum = aTipNum + 1
    end
  end
  
  return aTipNum
end