require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.GainLevelRaceRewardsRequest"
require "canon.panel.ActivityInfoPanel"
require "canon.panel.RewardReviewPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_LevelRaceLayer
--

local function existIntInRewardTable(aTable, aInt)
  for _, v in ipairs(aTable) do
    if v.level == aInt then
      return true
    end
  end
  return false
end

Activity_LevelRaceLayer = class(Layer)
function Activity_LevelRaceLayer:ctor()
    self.container = nil
    self.extraArgs = nil
    self.rankViewList = nil
end

function Activity_LevelRaceLayer:create( container, extraArgs )
    local s = Activity_LevelRaceLayer.new()
    self.container = container
    self.extraArgs = extraArgs
    self.rankViewList = {}
    s:initLayer()
    return s
end

function Activity_LevelRaceLayer:initLayer()
    Activity_LevelRaceLayer.super.initLayer(self)
    
    local rewardType
    local defaultRewardType
    for _, aDisplayType in pairs(DataManager.GameMetaData.activityLevelRaceConfig.displayTypes) do
      if aDisplayType.id == DataManager.getServerid() then
        rewardType = aDisplayType.type
      end
      if aDisplayType.id == 0 then
        defaultRewardType = aDisplayType.type
      end
    end
    if not rewardType then
      rewardType = defaultRewardType
    end
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
    local activityUIName
    if rewardType == 0 then
      activityUIName = "launch_activity5"
    elseif rewardType == 1 then
      activityUIName = "launch_activity2"
    end
    --print(activityUIName)
    --print(DataManager.getServerid())
    self.mainUI = self.builder:build(activityUIName)
    self:addChild(self.mainUI)
    if activityUIName == "launch_activity5" then
      self.mainUI:getChildByName("txt_la_o"):setVisible(false)
      self.mainUI:getChildByName("txt_la_o2"):setVisible(false)
    end
    
    local titleLabel = self.mainUI:getChildByName("txt_activity_title"):getChildByName("txt")
    if DataManager.GameMetaData.activityLevelRaceConfig.winnerNickname == "0" then
      titleLabel:setString(Localization:getInstance():getText(string.format("activity_levelRace_txt1_type%d", rewardType)))
    else
      titleLabel:setString(Localization:getInstance():getText("activity_levelRace_result", {playername = DataManager.GameMetaData.activityLevelRaceConfig.winnerNickname}))
    end
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      
      local activityTimeInfo = MaintenanceManager:getStartAndEndTime("activityLevelRace")
      local activityGainRewardTimeInfo = MaintenanceManager:getStartAndEndTime("activityLevelRaceGainReward")
      local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText(string.format("activity_levelRace_help_type%d", rewardType), {year1 = activityTimeInfo[1].year, month1 = activityTimeInfo[1].month, day1 = activityTimeInfo[1].day, time1 = activityTimeInfo[1].time, year2 = activityTimeInfo[2].year, month2 = activityTimeInfo[2].month, day2 = activityTimeInfo[2].day, time2 = activityTimeInfo[2].time, year3 = activityGainRewardTimeInfo[2].year, month3 = activityGainRewardTimeInfo[2].month, day3 = activityGainRewardTimeInfo[2].day, time3 = activityGainRewardTimeInfo[2].time}))--
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end
    self.mainUI:getChildByName("txt_activity_helpinfo"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    local rewardLabel1 = self.mainUI:getChildByName("txt_newyear_reward_time1")
    rewardLabel1:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel1:getChildByName("txt"):getDimensions().height))
    rewardLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime"))
    local rewardLabel1_1 = self.mainUI:getChildByName("txt_newyear_reward_time1_1")
    local aNewPosX = rewardLabel1:getPosition().x + rewardLabel1:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel1_1:setPositionX(aNewPosX)
    local rewardLabel2 = self.mainUI:getChildByName("txt_newyear_reward_time2")
    rewardLabel2:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel2:getChildByName("txt"):getDimensions().height))
    rewardLabel2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown1"))
    local rewardLabel2_1 = self.mainUI:getChildByName("txt_newyear_reward_time2_1")
    aNewPosX = rewardLabel2:getPosition().x + rewardLabel2:getChildByName("txt"):getTexture():getContentSize().width
    rewardLabel2_1:setPositionX(aNewPosX)
    rewardLabel2_1:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel2_1:getChildByName("txt"):getDimensions().height))
    local rewardLabel2_2 = self.mainUI:getChildByName("txt_owurida")
    rewardLabel2_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown3"))
    local rewardLabel3_1 = self.mainUI:getChildByName("txt_wonreward_over")
    rewardLabel3_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_timeOver"))
    local rewardLabel3_2 = self.mainUI:getChildByName("txt_activity_getreward_time")
    rewardLabel3_2:getChildByName("txt"):setDimensions(CCSizeMake(0,rewardLabel3_2:getChildByName("txt"):getDimensions().height))
    rewardLabel3_2:getChildByName("txt"):setString(Localization:getInstance():getText("activity_reward_endTime"))
    local rewardLabel3_3 = self.mainUI:getChildByName("txt_newyear_reward_time1_2")
    rewardLabel3_3:setPositionX(rewardLabel3_2:getPosition().x + rewardLabel3_2:getChildByName("txt"):getTexture():getContentSize().width)
    local ruleLabel = self.mainUI:getChildByName("txt_activity_rule")
    
    local function refreshSelf()
      local whetherPassedActivityTime, leftActivityTimeStamp, endMonth, endDay, endHour, endYear = MaintenanceManager.isActivityAlreadyClose("activityLevelRace")
      local whetherPassedGainRewardTime, leftGainRewardTimeStamp, gainEndMonth, gainEndDay, gainEndHour, gainEndYear = MaintenanceManager.isActivityAlreadyClose("activityLevelRaceGainReward")
      if whetherPassedActivityTime then
        rewardLabel1:setVisible(false)
        rewardLabel1_1:setVisible(false)
        rewardLabel2:setVisible(false)
        rewardLabel2_1:setVisible(false)
        rewardLabel2_2:setVisible(false)
        rewardLabel3_1:setVisible(true)
        rewardLabel3_2:setVisible(true)
        rewardLabel3_3:setVisible(true)
        rewardLabel3_3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = gainEndYear, month = gainEndMonth, day = gainEndDay, hour = gainEndHour}))
        local hour = 0
        local min = 0
        if not whetherPassedGainRewardTime then
          hour = math.modf(leftGainRewardTimeStamp / 3600)
          min = math.modf(math.mod(leftGainRewardTimeStamp, 3600) / 60)
        end
        ruleLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activity_reward_countdown", {hour = hour, min = min}))
        
        if self.checkActivityPassedEntry then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
          self.checkActivityPassedEntry = nil
        end
      else
        rewardLabel1:setVisible(true)
        rewardLabel1_1:setVisible(true)
        rewardLabel2:setVisible(true)
        rewardLabel2_1:setVisible(true)
        rewardLabel2_2:setVisible(true)
        rewardLabel3_1:setVisible(false)
        rewardLabel3_2:setVisible(false)
        rewardLabel3_3:setVisible(false)
        ruleLabel:getChildByName("txt"):setString(Localization:getInstance():getText(string.format("activity_levelRace_txt2_type%d", rewardType)))
        ruleLabel:getChildByName("txt"):setDimensions(CCSizeMake(ruleLabel:getChildByName("txt"):getDimensions().width,0))
        rewardLabel1_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_endTime_time", {year = endYear, month = endMonth, day = endDay, hour = endHour}))
        rewardLabel2_1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_countdown2", {hour = math.modf(leftActivityTimeStamp / 3600), min = math.modf(math.mod(leftActivityTimeStamp, 3600) / 60)}))
        local aPosX = rewardLabel2:getPosition().x + rewardLabel2:getChildByName("txt"):getTexture():getContentSize().width + rewardLabel2_1:getChildByName("txt"):getTexture():getContentSize().width
        rewardLabel2_2:setPositionX(aPosX)
        
        if not self.checkActivityPassedEntry then
          self.checkActivityPassedEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshSelf,15,false)
        end
      end
    end
    
    refreshSelf()
    
    self.mainUI:getChildByName("txt_ranking_list_title"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_ranking_title"))
    
    self:resetExtraArgs(self.extraArgs)
    
    local levelRewardConfigs = DataManager.GameMetaData.activityLevelRaceConfig.levelRewardItems
    
    local gainReward
    
    local levelList = {levelRewardConfigs[1].level, levelRewardConfigs[2].level}
    local function firstRewardButtonSelected(evt)
      gainReward(levelList[1])
    end
    local firstRewardButton = Button:create(self.mainUI:getChildByName("btn_lv20get"))
    firstRewardButton:addEventListener(Events.kStart,firstRewardButtonSelected, self)
    local function secondRewardButtonSelected(evt)
      gainReward(levelList[2])
    end
    local secondRewardButton = Button:create(self.mainUI:getChildByName("btn_lv40get"))
    secondRewardButton:addEventListener(Events.kStart,secondRewardButtonSelected, self)
    
    local function refreshButtons()
      
      local sharkActivity = DataManager.getGameInitData().sharkActivity
      sharkActivity = sharkActivity or {}
      local gainedRewards = sharkActivity.levelRaceRewards or {}
      local lrUserLevel
      if not sharkActivity.lrUserLevel then
        if MaintenanceManager.isActivityOpen("activityLevelRace") and (not MaintenanceManager.isActivityAlreadyClose("activityLevelRace")) then
          lrUserLevel = DataManager.getGameInitData().sharkUser.level
        else
          lrUserLevel = 0
        end
      else
        lrUserLevel = sharkActivity.lrUserLevel
      end
      
      local firstRewardButtonDisplay = self.mainUI:getChildByName("btn_lv20get")
      local firstRewardLabel = firstRewardButtonDisplay:getChildByName("txt")
      if lrUserLevel < levelList[1] then
        firstRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn_lv20"))
        firstRewardButtonDisplay:getChildByName("btn_yellow_long"):setVisible(false)
        firstRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        firstRewardButton:setEnable(false)
      elseif not existIntInRewardTable(gainedRewards, levelList[1]) then
        firstRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        firstRewardButtonDisplay:getChildByName("btn_yellow_long"):setVisible(true)
        firstRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
        firstRewardButton:setEnable(true)
      else
        firstRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
        firstRewardButtonDisplay:getChildByName("btn_yellow_long"):setVisible(false)
        firstRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        firstRewardButton:setEnable(false)
      end
      
      local secondRewardButtonDisplay = self.mainUI:getChildByName("btn_lv40get")
      local secondRewardLabel = secondRewardButtonDisplay:getChildByName("txt")
      if lrUserLevel < levelList[2] then
        secondRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn_lv40"))
        secondRewardButtonDisplay:getChildByName("btn_green_long"):setVisible(false)
        secondRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        secondRewardButton:setEnable(false)
      elseif not existIntInRewardTable(gainedRewards, levelList[2]) then
        secondRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn"))
        secondRewardButtonDisplay:getChildByName("btn_green_long"):setVisible(true)
        secondRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
        secondRewardButton:setEnable(true)
      else
        secondRewardLabel:setString(Localization:getInstance():getText("activity_claimRewardBtn_claimed"))
        secondRewardButtonDisplay:getChildByName("btn_green_long"):setVisible(false)
        secondRewardButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        secondRewardButton:setEnable(false)
      end
    end
    
    gainReward = function(aLevel)
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function gainLevelRaceRewardsSucceed(event)
        RewardManager:getReward(event.data.rewards)
        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkActivity = gameInitData.sharkActivity or {}
        if not gameInitData.sharkActivity.levelRaceRewards then
          gameInitData.sharkActivity.levelRaceRewards = {}
        end
        table.insert(gameInitData.sharkActivity.levelRaceRewards, {level = aLevel, gainRewardTime = TimeUtil.getServerTimeSeconds()})
        DataManager.setGameInitData(gameInitData)
        refreshButtons()
        self.container:resetTipInfoForActivity("Activity_LevelRace")
        
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, event.data.rewards )
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
      end 
      local function gainLevelRaceRewardsFailed(event)
        if event.data.retCode == 714401 then  --activity closed
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
      local params = {level = aLevel}
      local request = GainLevelRaceRewardsRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainLevelRaceRewardsSucceed, gainLevelRaceRewardsSucceed)
      request:addEventListener(RequestNotifyEnum.GainLevelRaceRewardsFailed, gainLevelRaceRewardsFailed)
      request:start()
    end
    
    refreshButtons()
    
    local function showRewardPanel(rewardList)
      local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = Localization:getInstance():getText("activity_levelRace_rewardTitle")} )
      self.container:addChild(aRewardPanel)
      aRewardPanel:scaleIn()
    end
    
    local function reward1BtnSelected(evt)
      local rewardList = MetaManager.getRewardInfoByID(levelRewardConfigs[1].rewardPackageId)
      rewardList = rewardList or {}
      showRewardPanel(rewardList)
    end
    local reward1BtnDisplay = self.mainUI:getChildByName("icon_prop_1")
    local reward1Btn = Button:create(reward1BtnDisplay)
    reward1Btn:addEventListener(Events.kStart, reward1BtnSelected, self)
    
    local function reward2BtnSelected(evt)
      local rewardList = MetaManager.getRewardInfoByID(levelRewardConfigs[2].rewardPackageId)
      rewardList = rewardList or {}
      showRewardPanel(rewardList)
    end
    local reward2BtnDisplay = self.mainUI:getChildByName("icon_prop_2")
    local reward2Btn = Button:create(reward2BtnDisplay)
    reward2Btn:addEventListener(Events.kStart, reward2BtnSelected, self)
end

local rank_view_total_height = 190
local rank_view_start_y = 587
local rank_view_start_x = 10
local rank_view_second_x = 370

function Activity_LevelRaceLayer:resetExtraArgs(extraArgs)
  self.extraArgs = extraArgs or {}
  for k, v in pairs(self.rankViewList) do
    self.rankViewList[k]:removeFromParentAndCleanup(true)
		self.rankViewList[k] = nil
	end

  for k, v in ipairs(self.extraArgs) do
    local aRankView = self.builder:build("txt/txt_combine")
    aRankView:getChildByName("txt_activity_playerrank"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_rankTxt1"))
    aRankView:getChildByName("txt_activity_playerrank2"):getChildByName("txt"):setString(string.format("%d", k))
    aRankView:getChildByName("txt_activity_playerrank3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_rankTxt2"))
    aRankView:getChildByName("txt_activity_playername"):getChildByName("txt"):setString(v.nickName)
    aRankView:getChildByName("txt_activity_playerlv"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_ranking_level", {level = v.level}))
    aRankView:setPositionX((k <= 5) and rank_view_start_x or rank_view_second_x)
    aRankView:setPositionY(rank_view_start_y - rank_view_total_height / 5 * (math.mod(k-1, 5)))
    self.mainUI:addChild(aRankView)
    table.insert(self.rankViewList, aRankView)
  end
end

function Activity_LevelRaceLayer:enable()
    local isEnable = MaintenanceManager.isActivityOpen("activityLevelRacePanel")
    return isEnable
end 

function Activity_LevelRaceLayer:dispose()
  if self.checkActivityPassedEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkActivityPassedEntry)
    self.checkActivityPassedEntry = nil
  end
  Activity_LevelRaceLayer.super.dispose(self)
end

function Activity_LevelRaceLayer.getTipNum()
  if not Activity_LevelRaceLayer.enable() then
    return 0
  end
  
  local aTipNum = 0
  local sharkActivity = DataManager.getSharkActivity()
  sharkActivity = sharkActivity or {}
  local gainedRewards = sharkActivity.levelRaceRewards or {}
  local lrUserLevel
  if not sharkActivity.lrUserLevel then
    if MaintenanceManager.isActivityOpen("activityLevelRace") and (not MaintenanceManager.isActivityAlreadyClose("activityLevelRace")) then
      lrUserLevel = DataManager.getCurrUser().level
    else
      lrUserLevel = 0
    end
  else
    lrUserLevel = sharkActivity.lrUserLevel
  end
  local levelRewardConfigs = DataManager.GameMetaData.activityLevelRaceConfig.levelRewardItems
  for _, aRewardConfig in pairs(levelRewardConfigs) do
    if (lrUserLevel >= aRewardConfig.level) and (not existIntInRewardTable(gainedRewards, aRewardConfig.level)) then
      aTipNum = aTipNum + 1
    end
  end
  return aTipNum
end

