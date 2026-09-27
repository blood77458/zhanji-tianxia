require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainGachaPointsRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_GachaPointsLayer
--

Activity_GachaPointsLayer = class(Layer)
function Activity_GachaPointsLayer:ctor()
    self.container = nil
end

function Activity_GachaPointsLayer:create( container, extraArgs )
    local s = Activity_GachaPointsLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_GachaPointsLayer:initLayer()
    Activity_GachaPointsLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.mainUI = self.builder:build("launch_activity3")
    self:addChild(self.mainUI)
    self.builder.useArtLabelTTF = true
    --[[
    local function showCardInfo(starNum)
      local metaId
      if starNum == 4 then
        metaId = 104071
      elseif starNum == 5 then
        metaId = 104061
      elseif starNum == 6 then
        metaId = 104001
      end
      local function After_CardInfoPanel_Finished()
      end
      self.container._data = {metaId = metaId, level = 1, exp = 0}
      PopoutManager:sharedManager():popout(EggNewCardInfoPanel:create( After_CardInfoPanel_Finished, self.container ), kPopoutDir.kScale, false, false ,self.container) 
    end
    
    local function fourStarButtonSelected(evt)
      showCardInfo(4)
    end
    local fourStarButton = Button:create(self.mainUI:getChildByName("launch_activity_20up"):getChildByName("launch_activity_10up_sb"))
    fourStarButton:addEventListener(Events.kStart, fourStarButtonSelected, self)
    local function fiveStarButtonSelected(evt)
      showCardInfo(5)
    end
    local fiveStarButton = Button:create(self.mainUI:getChildByName("launch_activity_10up"):getChildByName("launch_activity_20up_sb"))
    fiveStarButton:addEventListener(Events.kStart, fiveStarButtonSelected, self)
    local function sixStarButtonSelected(evt)
      showCardInfo(6)
    end
    local sixStarButton = Button:create(self.mainUI:getChildByName("launch_activity_1st"):getChildByName("launch_activity_1st_sb"))
    sixStarButton:addEventListener(Events.kStart, sixStarButtonSelected, self)
    ]]
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      
      local activityTimeInfo = MaintenanceManager:getStartAndEndTime("activityGachaPoints")
      local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime("activityGachaPointsGainReward")
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText("activity_gachaPoints_help", {year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time, year3 = activityGainRewardTimeInfo[2].year, month3 = activityGainRewardTimeInfo[2].month, day3 = activityGainRewardTimeInfo[2].day, time3 = activityGainRewardTimeInfo[2].time}))
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_activity_helpinfo"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    local rewardLabel1_1 = self.mainUI:getChildByName("txt_newyear_reward_time1")
    rewardLabel1_1:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_1:getChildByName("txt"):getDimensions().height))
    rewardLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime"))
    local rewardLabel1_2 = self.mainUI:getChildByName("txt_newyear_reward_time1_1")
    local aNewPosX = rewardLabel1_1:getPosition().x + rewardLabel1_1:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_2:setPositionX(aNewPosX)
    local rewardLabel1_3 = self.mainUI:getChildByName("txt_newyear_reward_time2")
    rewardLabel1_3:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_3:getChildByName("txt"):getDimensions().height))
    rewardLabel1_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown1"))
    local rewardLabel1_4 = self.mainUI:getChildByName("txt_newyear_reward_time2_1")
    aNewPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_4:setPositionX(aNewPosX)
    rewardLabel1_4:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1_4:getChildByName("txt"):getDimensions().height))
    local rewardLabel1_5 = self.mainUI:getChildByName("txt_owurida")
    rewardLabel1_5:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown3"))
    local rewardLabel2_1 = self.mainUI:getChildByName("txt_wonreward_over")
    rewardLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_timeOver"))
    local rewardLabel2_2 = self.mainUI:getChildByName("txt_activity_getreward_time")
    rewardLabel2_2:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel2_2:getChildByName("txt"):getDimensions().height))
    rewardLabel2_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_reward_endTime"))
    local rewardLabel2_3 = self.mainUI:getChildByName("txt_newyear_reward_time1_2")
    aNewPosX = rewardLabel2_2:getPosition().x + rewardLabel2_2:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel2_3:setPositionX(aNewPosX)
    
    local refreshSelf
    
    local gachaButtonDisplay = self.mainUI:getChildByName("btn_togacha")
    gachaButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("home_gachaBtn"))
    local function gachaButtonSelected(evt)
		self.container:replaceScene(GachaScene, {returnScene = "Activity_GachaPointsLayer"})
    end
    local gachaButton = Button:create(gachaButtonDisplay)
    gachaButton:addEventListener(Events.kStart,gachaButtonSelected, self)
    local gainButtonDisplay = self.mainUI:getChildByName("btn_getreward")
    self.gainButtonDisplay = gainButtonDisplay
    local function gainButtonSelected(evt)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function gainGachaPointsRewardsSucceed(event)
        RewardManager:getReward(event.data.rewards)
        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkActivity = gameInitData.sharkActivity or {}
        gameInitData.sharkActivity.gpGainedReward = true
        DataManager.setGameInitData(gameInitData)
        refreshSelf()
        self.container:resetTipInfoForActivity("Activity_GachaPoints")
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, event.data.rewards )
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
      end 
      local function gainGachaPointsRewardsFailed(event)
        if event.data.retCode == 714431 then  --activity closed
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_error_expired")
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {}
      local request = GainGachaPointsRewardsRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainGachaPointsRewardsSucceed, gainGachaPointsRewardsSucceed)
      request:addEventListener(RequestNotifyEnum.GainGachaPointsRewardsFailed, gainGachaPointsRewardsFailed)
      request:start()
    end
    local gainButton = Button:create(gainButtonDisplay)
    gainButton:addEventListener(Events.kStart,gainButtonSelected, self)
    self.gainButton = gainButton
    
    refreshSelf = function()
      local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose("activityGachaPoints")
      local whetherPassedGainRewardTime, leftGainRewardTimeStamp, gainEndMonth, gainEndDay, gainEndHour, gainEndYear = MaintenanceManager.isActivityAlreadyClose("activityGachaPointsGainReward")
      if whetherPassedActivityTime then
        rewardLabel1_1:setVisible(false)
        rewardLabel1_2:setVisible(false)
        rewardLabel1_3:setVisible(false)
        rewardLabel1_4:setVisible(false)
        rewardLabel1_5:setVisible(false)
        rewardLabel2_1:setVisible(true)
        rewardLabel2_2:setVisible(true)
        rewardLabel2_3:setVisible(true)
        rewardLabel2_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = gainEndYear, month = gainEndMonth, day = gainEndDay, hour = gainEndHour}))
        
        gachaButton:setEnable(false)
        gachaButtonDisplay:setVisible(false)
        if DataManager.getGameInitData().sharkActivity and DataManager.getGameInitData().sharkActivity.gpGainedReward then
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
          gainButton:setEnable(false)
        elseif not self.existInRank then
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
          gainButton:setEnable(false)
        else
          gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(true)
          gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
          gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
          gainButton:setEnable(true)
        end
        
        if self.checkActivityPassedEntry then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
          self.checkActivityPassedEntry = nil
        end
      else
        rewardLabel1_1:setVisible(true)
        rewardLabel1_2:setVisible(true)
        rewardLabel1_3:setVisible(true)
        rewardLabel1_4:setVisible(true)
        rewardLabel1_5:setVisible(true)
        rewardLabel2_1:setVisible(false)
        rewardLabel2_2:setVisible(false)
        rewardLabel2_3:setVisible(false)
        rewardLabel1_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = activityEndYear, month = activityEndMonth, day = activityEndDay, hour = activityEndHour}))
        rewardLabel1_4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown2", {hour = math.modf(leftActivityTimeStamp / 3600), min = math.modf(math.mod(leftActivityTimeStamp, 3600) / 60)}))
        local aPosX = rewardLabel1_3:getPosition().x + rewardLabel1_3:getChildByName("txt"):getTexture():getContentSize().width + rewardLabel1_4:getChildByName("txt"):getTexture():getContentSize().width
        rewardLabel1_5:setPositionX(aPosX)
        
        gachaButton:setEnable(true)
        gachaButtonDisplay:setVisible(true)
        gainButtonDisplay:getChildByName("btn_long_blue"):setVisible(false)
        gainButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        gainButton:setEnable(false)
        
        if not self.checkActivityPassedEntry then
          self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,15,false)
        end
      end
    end
    
    self.refreshSelf = refreshSelf
    
    self:resetExtraArgs(self.extraArgs)
    
    self.mainUI:getChildByName("txt_wonreward_score_rank_title"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_gachaPoints_ranking"))
    
end

function Activity_GachaPointsLayer:resetExtraArgs(extraArgs)
  self.extraArgs = extraArgs
  self.existInRank = false
  local aRank
  for k, v in ipairs(self.extraArgs.gachaPointsRanks or {}) do
    if tonumber(v.uid, 10) == tonumber(DataManager.getCurrUser().uid, 10) then
      self.existInRank = true
      aRank = k
    end
    v.rank = k
  end
  if self.existInRank then
    self.mainUI:getChildByName("txt_activity_playerrank_self"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_gachaPoints_yourRank", {num = aRank}))
  else
    self.mainUI:getChildByName("txt_activity_playerrank_self"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_outOfRank"))
  end
  self.mainUI:getChildByName("txt_activity_playerscore_self"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_gachaPoints_yourPoint", {num = self.extraArgs.myPoints}))
  
  if not self.rankTableView then
    self.rankTableView = self:createRankTableView()
    self.mainUI:addChild(self.rankTableView)
  end
  self.rankTableView:reloadData()
  self.refreshSelf()
end

local table_width = 498
local table_height = 225
local table_posX = 111
local table_posY = 143
local item_width = 498
local item_height = 30

function Activity_GachaPointsLayer:createRankTableView()
  local cellTag = 1024
  local buttonTag = {}
  local aPanel = self
  local RankTableViewRenderer = class(TableViewRenderer)
  function RankTableViewRenderer:ctor(width, height)
    self.list = aPanel.extraArgs.gachaPointsRanks or {}
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

function Activity_GachaPointsLayer:enable()
    local isEnable = MaintenanceManager.isActivityOpen("activityGachaPointsPanel")
    return isEnable
end 

function Activity_GachaPointsLayer:setTouchEnabled(isEnable)
  if self.rankTableView then
    self.rankTableView:setTouchEnabled(isEnable)
  end
end

function Activity_GachaPointsLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_GachaPointsLayer.super.dispose(self)
end

function Activity_GachaPointsLayer.getTipNum()
  if not Activity_GachaPointsLayer.enable() then
    return 0
  end
  local whetherPassedActivityTime, leftActivityTimeStamp, activityEndMonth, activityEndDay, activityEndHour, activityEndYear = MaintenanceManager.isActivityAlreadyClose("activityGachaPoints")
  if whetherPassedActivityTime and MaintenanceManager.isActivityOpen("activityGachaPointsGainReward") then
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkActivity = gameInitData.sharkActivity or {}
    if gameInitData.sharkActivity.gpGainedReward then
      return 0
    end
    local homeInfo = ActivityPanelScene.getStatusInfo()
    if homeInfo.gachaPointRewardStatus then
      return 1
    else
      return 0
    end
  end
  return 0
end