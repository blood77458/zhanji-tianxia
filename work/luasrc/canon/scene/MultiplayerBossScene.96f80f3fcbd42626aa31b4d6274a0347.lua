require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.panel.MBBossListPanel"
require "canon.panel.MBRecordListPanel"
require "canon.request.GetMultiplayerBossRankRequest"
require "canon.request.GainMultiplayerBossParticipationRewardRequest"
require "canon.panel.MBRankListPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

MultiplayerBossTagEnum = {
  BossList = 1,
  ChallengeRecord = 2,
  Leaderboard = 3,
}

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

--
-- MultiplayerBossScene
--

local function checkTopButtonSelected(evt)
  print("checkTopButtonSelected")
  if evt.context.selectedPanel.checkTopButtonSelected then
    evt.context.selectedPanel:checkTopButtonSelected()
  end
end

local function stageButtonSelected(evt)
  evt.context:replaceScene(CityMainScene)
end

local function bossButtonSelected(evt)
  evt.context:changeToTap(MultiplayerBossTagEnum.BossList)
end

local function recordButtonSelected(evt)
  evt.context:changeToTap(MultiplayerBossTagEnum.ChallengeRecord)
end

local function rankButtonSelected(evt)
  evt.context:changeToTap(MultiplayerBossTagEnum.Leaderboard)
end

local function getRewardButtonSelected(evt)
  local aScene = evt.context
  
  if BagCalcManager.isFull() then
    local aContent = Localization:getInstance():getText("bagFull_move")
    -- SuspensionLabel:showContent(aScene, aContent)
    NewPackageFullPanel:show()
    return
  end
  
  local function gainMultiplayerBossParticipationRewardSucceed(event)
    RewardManager:getReward(event.data.rewards)
    local aRewardPanel = RewardReviewPanel:create( aScene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activityNian_popup_rankRewardTitle"), rewardSubTitle = Localization:getInstance():getText("reward_rewardClaimed")} )
    aScene:addChild(aRewardPanel)
    aRewardPanel:scaleIn()
    aScene:participationRewardGained()
  end 
  local function gainMultiplayerBossParticipationRewardFailed(event)
    if event.data.retCode == 714520 then  --activity closed
      local function closeCanonMessageBox()
        aScene:replaceScene(MainMenuScene)
      end
      local text = Localization:getInstance():getText("activityNian_rewardList_notInTime")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 714527 then  --gained already
      local function closeCanonMessageBox()
        aScene:participationRewardGained()
      end
      local text = Localization:getInstance():getText("activityNian_rewardList_noReward")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  local params = {bossKey = aScene.rewardBossIdList}
  local request = GainMultiplayerBossParticipationRewardRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener( RequestNotifyEnum.GainMultiplayerBossParticipationRewardSucceed, gainMultiplayerBossParticipationRewardSucceed )
  request:addEventListener( RequestNotifyEnum.GainMultiplayerBossParticipationRewardFailed, gainMultiplayerBossParticipationRewardFailed )
  request:start()
end

local function checkSelfButtonSelected(evt)
  print("checkSelfButtonSelected")
  if evt.context.selectedPanel.checkSelfButtonSelected then
    evt.context.selectedPanel:checkSelfButtonSelected()
  end
end

MultiplayerBossScene = class(BaseUIScene)

function MultiplayerBossScene:ctor()
	self.curSceneEnum = SceneEnum.MultiplayerBossScene
end

function MultiplayerBossScene:create(argv)
  local s = MultiplayerBossScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
	self.selectedTag = self.argv.params.selectedTag or MultiplayerBossTagEnum.BossList
  self.bossInfo = self.argv.params.data
  s:initScene()
  return s
end

function MultiplayerBossScene:onInit()
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  self.title = Localization:getInstance():getText("title_activityNian")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
  local ui = builder:build("monster_nian_table_title")
  self:addChild(ui)
  
  self.uiGroup1 = ui:getChildByName("btn_select_boss_now")
  self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianListTab"))
  self.bossButton = Button:create(self.uiGroup1)
  self.bossButton:addEventListener(Events.kStart, bossButtonSelected, self)
  self.uiGroup2 = ui:getChildByName("btn_select_challenge_record")
  self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardListTab"))
  self.recordButton = Button:create(self.uiGroup2)
  self.recordButton:addEventListener(Events.kStart, recordButtonSelected, self)
  self.uiGroup3 = ui:getChildByName("btn_select_ranking")
  self.uiGroup3:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rankingTab"))
  self.rankButton = Button:create(self.uiGroup3)
  self.rankButton:addEventListener(Events.kStart, rankButtonSelected, self)
  self.uiGroup4 = ui:getChildByName("txt_nian_16")
  self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
  self.uiGroup4:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_myNianHorn", {num = self.bossInfo.point}))
  self.uiGroup5 = ui:getChildByName("txt_nian_17")
  self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
  self.uiGroup5:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_myRank", {rank = ((self.bossInfo.rank == 0) and Localization:getInstance():getText("activityNian_outOfRank") or self.bossInfo.rank)}))
  self.uiGroup6 = ui:getChildByName("txt_nian_15")
  self.uiGroup6:setPositionX(self.uiGroup6:getPositionX() - visibleSize.width)
  self.uiGroup6:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_haveReward"))
  self.uiGroup7 = ui:getChildByName("btn_get_allreward")
  self.uiGroup7:setPositionX(self.uiGroup7:getPositionX() - visibleSize.width)
  self.getRewardButton = Button:create(self.uiGroup7)
  self.uiGroup8 = ui:getChildByName("select_level_panel1")
  self.uiGroup8:setPositionX(self.uiGroup8:getPositionX() - visibleSize.width)
  
  self.uiGroup10 = ui:getChildByName("btn_jumptotop")
  self.uiGroup10:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_jumpToTopBtn"))
  self.uiGroup10:setPositionX(self.uiGroup10:getPositionX() - visibleSize.width)
  self.checkTopButton = Button:create(self.uiGroup10)
  self.checkTopButton:addEventListener(Events.kStart, checkTopButtonSelected, self)
  self.uiGroup11 = ui:getChildByName("txt_empty")
  self.uiGroup11:setPositionX(self.uiGroup11:getPositionX() - visibleSize.width)
  self.uiGroup12 = ui:getChildByName("btn_gostage")
  self.uiGroup12:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianList_goBtn"))
  self.uiGroup12:setPositionX(self.uiGroup12:getPositionX() - visibleSize.width)
  self.stageButton = Button:create(self.uiGroup12)
  self.stageButton:addEventListener(Events.kStart, stageButtonSelected, self)
  
  self.uiGroup13 = ui:getChildByName("bj_rob_red")
  self.uiGroup13:setPositionX(self.uiGroup13:getPositionX() - visibleSize.width)
  
  self.uiGroup9 = ui:getChildByName("bg_inventory_red")
  self.groupList = {}
  table.insert(self.groupList, self.uiGroup1)
  table.insert(self.groupList, self.uiGroup2)
  table.insert(self.groupList, self.uiGroup3)
  table.insert(self.groupList, self.uiGroup4)
  table.insert(self.groupList, self.uiGroup5)
  table.insert(self.groupList, self.uiGroup6)
  table.insert(self.groupList, self.uiGroup7)
  table.insert(self.groupList, self.uiGroup8)
  table.insert(self.groupList, self.uiGroup10)
  table.insert(self.groupList, self.uiGroup11)
  table.insert(self.groupList, self.uiGroup12)
  table.insert(self.groupList, self.uiGroup13)
  
  self.selectedPanel = nil
  self.panelList = {}
  
  --self.bossInfo.activeBossInfo = self.bossInfo.activeBossInfo or {{id = 1, level = 1, leftHp = 100, triggerSecond = 10, triggerUid = 0, nickName = "jet1", gainReward = false}, {id = 2, level = 2, leftHp = 100, triggerSecond = 100, triggerUid = 0, nickName = "jet2", gainReward = false}, {id = 3, level = 3, leftHp = 100, triggerSecond = 150, triggerUid = 0, nickName = "jet3", gainReward = false}, {id = 4, level = 4, leftHp = 100, triggerSecond = 200, triggerUid = 0, nickName = "jet4", gainReward = false}, {id = 5, level = 5, leftHp = 100, triggerSecond = 250, triggerUid = 0, nickName = "jet5", gainReward = false}, {id = 6, level = 6, leftHp = 100, triggerSecond = 300, triggerUid = 0, nickName = "jet6", gainReward = false}, {id = 7, level = 7, leftHp = 100, triggerSecond = 350, triggerUid = 0, nickName = "jet7", gainReward = false}, {id = 8, level = 8, leftHp = 100, triggerSecond = 400, triggerUid = 0, nickName = "jet8", gainReward = false}}
  --self.bossInfo.bossChallengeRecord = self.bossInfo.bossChallengeRecord or {{id = 1, level = 1, leftHp = 100, triggerSecond = 50, triggerUid = 0, nickName = "jet1", gainReward = true}, {id = 2, level = 2, leftHp = 100, triggerSecond = 100, triggerUid = 0, nickName = "jet2", gainReward = true}, {id = 3, level = 3, leftHp = 100, triggerSecond = 150, triggerUid = 0, nickName = "jet3", gainReward = true}, {id = 4, level = 4, leftHp = 100, triggerSecond = 200, triggerUid = 0, nickName = "jet4", gainReward = true}, {id = 5, level = 5, leftHp = 100, triggerSecond = 250, triggerUid = 0, nickName = "jet5", gainReward = true}, {id = 6, level = 6, leftHp = 100, triggerSecond = 300, triggerUid = 0, nickName = "jet6", gainReward = true}, {id = 7, level = 7, leftHp = 100, triggerSecond = 350, triggerUid = 0, nickName = "jet7", gainReward = true}, {id = 8, level = 8, leftHp = 100, triggerSecond = 400, triggerUid = 0, nickName = "jet8", gainReward = true}}
  table.sort(self.bossInfo.activeBossInfo, function(a, b)
      return a.triggerSecond > b.triggerSecond
    end
  )
  
  for _, aBossInfo in ipairs(self.bossInfo.activeBossInfo) do
    aBossInfo.leftTime = aBossInfo.triggerSecond + DataManager.GameMetaData.activityMultiplayerBossConfig.escapeTime - TimeUtil.getServerTimeSeconds()
    if aBossInfo.leftTime < 0 then
      aBossInfo.leftTime = 0
    end
  end
  
  self.rewardBossIdList = {}
  for _, aRecordInfo in ipairs(self.bossInfo.bossChallengeRecord) do
    if not aRecordInfo.gainReward and (aRecordInfo.leftHp <= 0) then
      table.insert(self.rewardBossIdList, {bossId = aRecordInfo.id, triggerUid = aRecordInfo.triggerUid})
    end
  end
  
  self:changeToTap(self.selectedTag)
  
  local function checkBossLeftTime()
    for k, aBossInfo in ipairs(self.bossInfo.activeBossInfo) do
      aBossInfo.leftTime = aBossInfo.triggerSecond + DataManager.GameMetaData.activityMultiplayerBossConfig.escapeTime - TimeUtil.getServerTimeSeconds()
      if aBossInfo.leftTime < 0 then
        aBossInfo.leftTime = 0
      end
      if self.panelList["bossPanel"] then
        local aCell = self.panelList["bossPanel"].bossListTableView:cellAtIndex(k - 1)
        if aCell then
          local lua_cell = aCell:getChildByTag(1024)
          local aTimeLabel = lua_cell:getChildByTag(-13)
          local aLeftTime = self.bossInfo.activeBossInfo[k].leftTime
          local hour = math.modf(aLeftTime / 3600)
          local min = math.modf(math.mod(aLeftTime, 3600) / 60)
          local sec = math.mod(math.mod(aLeftTime, 3600), 60)
          setNodeText(aTimeLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_time", {num = string.format("%02d:%02d:%02d", hour, min, sec)}))
        end
      end
    end
  end
  self.time_script_handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkBossLeftTime,1,false)
  
  BaseUIScene.onInit(self)
end

function MultiplayerBossScene:hasUngainedReward()
  if self.bossInfo.bossChallengeRecord then
    for _, aRecord in ipairs(self.bossInfo.bossChallengeRecord) do
      if (not aRecord.gainReward) and (aRecord.leftHp <= 0) then
        return true
      end
    end
  end
  return false
end

function MultiplayerBossScene:changeToTap(aTapType)
  local function addNewPanel()
    if self.selectedTag == MultiplayerBossTagEnum.BossList then
      self.uiGroup1:getChildByName("btn"):setVisible(true)
      self.uiGroup1:getChildByName("disable"):setVisible(false)
      self.bossButton:setEnable(false)
      self.uiGroup2:getChildByName("btn"):setVisible(false)
      self.uiGroup2:getChildByName("disable"):setVisible(true)
      self.recordButton:setEnable(true)
      self.uiGroup3:getChildByName("btn"):setVisible(false)
      self.uiGroup3:getChildByName("disable"):setVisible(true)
      self.rankButton:setEnable(true)
      if not self.panelList["bossPanel"] then
        self.panelList["bossPanel"] = MBBossListPanel:create(self, self.bossInfo.activeBossInfo)
      end
      self.selectedPanel = self.panelList["bossPanel"]
    elseif self.selectedTag == MultiplayerBossTagEnum.ChallengeRecord then
      self.uiGroup1:getChildByName("btn"):setVisible(false)
      self.uiGroup1:getChildByName("disable"):setVisible(true)
      self.bossButton:setEnable(true)
      self.uiGroup2:getChildByName("btn"):setVisible(true)
      self.uiGroup2:getChildByName("disable"):setVisible(false)
      self.recordButton:setEnable(false)
      self.uiGroup3:getChildByName("btn"):setVisible(false)
      self.uiGroup3:getChildByName("disable"):setVisible(true)
      self.rankButton:setEnable(true)
      if not self.panelList["recordPanel"] then
        self.panelList["recordPanel"] = MBRecordListPanel:create(self, self.bossInfo.bossChallengeRecord)
      end
      self.selectedPanel = self.panelList["recordPanel"]
    elseif self.selectedTag == MultiplayerBossTagEnum.Leaderboard then
      self.uiGroup1:getChildByName("btn"):setVisible(false)
      self.uiGroup1:getChildByName("disable"):setVisible(true)
      self.bossButton:setEnable(true)
      self.uiGroup2:getChildByName("btn"):setVisible(false)
      self.uiGroup2:getChildByName("disable"):setVisible(true)
      self.recordButton:setEnable(true)
      self.uiGroup3:getChildByName("btn"):setVisible(true)
      self.uiGroup3:getChildByName("disable"):setVisible(false)
      self.rankButton:setEnable(false)
      self.panelList["rankPanel"] = MBRankListPanel:create(self, self.rankList, self.showMe, self.rankMax)
      self.selectedPanel = self.panelList["rankPanel"]
    end
    self:addChildAt(self.selectedPanel, 2)
  end
  
  local startSceneViewExit
  local startSceneViewEnter
  local panelExitFinished
  local panelEnterFinished
  local function startPanelExit()
    self:disableUserInterface()
    self.selectedPanel:panelExit(panelExitFinished)
    startSceneViewExit()
  end
  
  local function startPanelEnter()
    self:disableUserInterface()
    self.selectedPanel:panelEnter(panelEnterFinished)
    startSceneViewEnter()
  end
  
  panelEnterFinished = function()
    self:enableUserInterface()
  end
  
  panelExitFinished = function()
    self:enableUserInterface()
    self:removeChild(self.selectedPanel, false)
    addNewPanel()
    startPanelEnter()
  end
  
  startSceneViewEnter = function()
    if self.selectedTag == MultiplayerBossTagEnum.BossList then
      self:refreshBossPanelTitle()
    elseif self.selectedTag == MultiplayerBossTagEnum.ChallengeRecord then
      self:refreshRecordPanelTitle()
    elseif self.selectedTag == MultiplayerBossTagEnum.Leaderboard then
      self:refreshRankPanelTitle()
    end
    self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup7:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup8:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup10:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup11:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    self.uiGroup12:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  end
  
  startSceneViewExit = function()
    self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup7:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup8:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup10:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup11:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    self.uiGroup12:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  end
  
  self.selectedTag = aTapType
  
  local function startChange()
    if self.selectedPanel then
      startPanelExit()
    else
      addNewPanel()
      startPanelEnter()
    end
  end
  
  if self.selectedTag == MultiplayerBossTagEnum.Leaderboard then
    local function onRequestCompleted(aList, showMe, rankMax)
      print("onRequestCompleted: " .. table.tostring(aList))
      self.rankList = aList
      self.showMe = showMe
      self.rankMax = rankMax
      startChange()
    end 

    MBRankListPanel:requestRanksBetween(0, 0, onRequestCompleted, self.bossInfo.point)
  else
    startChange()
  end
end

function MultiplayerBossScene:disableUserInterface()
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.targetInfoPanel = self.tempLayer
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(false)
  end
end

function MultiplayerBossScene:enableUserInterface()
  self.tempLayer:removeFromParentAndCleanup(true)
  self.targetInfoPanel = nil
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(true)
  end
end

function MultiplayerBossScene:setTableViewsEnabledInner(aEnabled)
  print("MultiplayerBossScene:setTableViewsEnabledInner: " .. tostring(aEnabled))
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(aEnabled)
  end
end
--[[
--新加 被popoutmanager调用 by czh
function MultiplayerBossScene:setTableViewsEnabled(aEnabled)
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(aEnabled)
  end
end]]

function MultiplayerBossScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function MultiplayerBossScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function MultiplayerBossScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, aGroup in ipairs(self.groupList) do
    aGroup:setPositionX(aGroup:getPositionX() - visibleSize.width)
    aGroup:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  end
  
  self.uiGroup9:setPositionX(self.uiGroup9:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup9:runAction(CCSequence:create(arr))
end

function MultiplayerBossScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function MultiplayerBossScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MultiplayerBossScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function MultiplayerBossScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, aGroup in ipairs(self.groupList) do
    aGroup:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  end
  self.selectedPanel:panelExit()
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup9:runAction(CCSequence:create(arr))
end

function MultiplayerBossScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function MultiplayerBossScene:back()
  if self.argv.returnScene == "ActivityPanelScene" then
    self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_MultiplayerBoss"})
  elseif self.argv.returnScene == "MainMenuScene" then
    self:replaceScene(MainMenuScene)
  else
    self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_MultiplayerBoss"})
  end
end

function MultiplayerBossScene:dispose()
  if self.time_script_handler then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.time_script_handler)
    self.time_script_handler = nil
  end
  MultiplayerBossScene.super.dispose(self)
end

function MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
  local function getMultiplayserBossInfoSucceed(event)
    if successCallback then
      print(table.tostring(event.data))
			successCallback(event.data)
		end
  end 
  local function getMultiplayserBossInfoFailed(event)
    if failureCallback then
			failureCallback(event.data)
		end
  end
  local function sendGetMultiplayerBossInfoRequest()
    local params = {}
    local request = GetMultiplayserBossInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.GetMultiplayserBossInfoSucceed, getMultiplayserBossInfoSucceed )
    request:addEventListener( RequestNotifyEnum.GetMultiplayserBossInfoFailed, getMultiplayserBossInfoFailed )
    request:start()
  end
  
  sendGetMultiplayerBossInfoRequest()
end

function MultiplayerBossScene:refreshBossPanelTitle()
  self.uiGroup4:setVisible(false)
  self.uiGroup5:setVisible(false)
  self.uiGroup6:setVisible(false)
  self.uiGroup7:setVisible(false)
  self.getRewardButton:removeEventListener(Events.kStart, getRewardButtonSelected)
  self.getRewardButton:removeEventListener(Events.kStart, checkSelfButtonSelected)
  self.getRewardButton:setEnable(false)
  self.uiGroup8:setVisible(false)
  self.uiGroup10:setVisible(false)
  self.checkTopButton:setEnable(false)
  if #self.bossInfo.activeBossInfo == 0 then
    self.uiGroup11:setVisible(true)
    local whetherPassedActivityTime = MaintenanceManager.isActivityAlreadyClose(DataManager.GameMetaData.activityMultiplayerBossConfig.rankingFeatureName)
    if whetherPassedActivityTime then
      self.uiGroup11:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianList_timeOver"))
      self.uiGroup12:setVisible(false)
      self.stageButton:setEnable(false)
    else
      self.uiGroup11:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_nianList_emptyTxt"))
      self.uiGroup12:setVisible(true)
      self.stageButton:setEnable(true)
    end
    
  else
    self.uiGroup11:setVisible(false)
    self.uiGroup12:setVisible(false)
    self.stageButton:setEnable(false)
  end
end

function MultiplayerBossScene:refreshRecordPanelTitle()
  self.uiGroup4:setVisible(false)
  self.uiGroup5:setVisible(false)
  self.uiGroup7:setVisible(true)
  self.uiGroup7:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_claimBtn"))
  self.getRewardButton:removeEventListener(Events.kStart, checkSelfButtonSelected)
  self.getRewardButton:addEventListener(Events.kStart, getRewardButtonSelected, self)
  if self:hasUngainedReward() then
    self.uiGroup6:setVisible(true)
    self.uiGroup7:getChildByName("btn"):setVisible(true)
    self.uiGroup7:getChildByName("btn_inactive"):setVisible(false)
    self.getRewardButton:setEnable(true)
  else
    self.uiGroup6:setVisible(false)
    self.uiGroup7:getChildByName("btn"):setVisible(false)
    self.uiGroup7:getChildByName("btn_inactive"):setVisible(true)
    self.getRewardButton:setEnable(false)
  end
  self.uiGroup8:setVisible(true)
  self.uiGroup10:setVisible(false)
  self.checkTopButton:setEnable(false)
  if #self.bossInfo.bossChallengeRecord == 0 then
    self.uiGroup11:setVisible(true)
    self.uiGroup11:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_emptyTxt"))
  else
    self.uiGroup11:setVisible(false)
  end
  self.uiGroup12:setVisible(false)
  self.stageButton:setEnable(false)
end

function MultiplayerBossScene:refreshRankPanelTitle()
  self.uiGroup4:setVisible(false)
  self.uiGroup5:setVisible(false)
  self.uiGroup6:setVisible(false)
  self.uiGroup7:setVisible(true)
  self.uiGroup7:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_jumpToSelfBtn"))
  self.uiGroup7:getChildByName("btn"):setVisible(true)
  self.uiGroup7:getChildByName("btn_inactive"):setVisible(false)
  self.getRewardButton:removeEventListener(Events.kStart, getRewardButtonSelected)
  self.getRewardButton:addEventListener(Events.kStart, checkSelfButtonSelected, self)
  self.getRewardButton:setEnable(true)
  self.uiGroup8:setVisible(true)
  
  self.uiGroup10:setVisible(true)
  self.checkTopButton:setEnable(true)
  self.uiGroup11:setVisible(false)
  self.uiGroup12:setVisible(false)
  self.stageButton:setEnable(false)

  self.selectedPanel = self.panelList["rankPanel"]
end

function MultiplayerBossScene:participationRewardGained()
  self.panelList["recordPanel"]:rewardGained()
  self:refreshRecordPanelTitle()
end

function MultiplayerBossScene.getTipInfo(callback)
  if (not Activity_MultiplayerBossLayer) or (not Activity_MultiplayerBossLayer:enable()) then
    callback(false, 0)
    return
  end
  local function getMultiplayserBossInfoSucceed(event)
    local hasUnDefeatedBoss = false
    local ungainedRewardNum = 0
    if event.data.activeBossInfo and (#event.data.activeBossInfo > 0) then
      hasUnDefeatedBoss = true
    end
		if type(event.data.bossChallengeRecord) == "table" then
			for _, aRecord in ipairs(event.data.bossChallengeRecord) do
				if not aRecord.gainReward and (aRecord.leftHp <= 0) then
					ungainedRewardNum = ungainedRewardNum + 1
				end
			end
		end
    local rankFeatureStatus = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityMultiplayerBossConfig.rankingFeatureName)
    local rewardFeatureStatus = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityMultiplayerBossConfig.rewardFeatureName)
    if not rankFeatureStatus and rewardFeatureStatus then
      if (event.data.rank > 0) and (not event.data.gainedRankReward) then
        ungainedRewardNum = ungainedRewardNum + 1
      end
    end
    callback(hasUnDefeatedBoss, ungainedRewardNum)
  end 
  local function getMultiplayserBossInfoFailed(event)
    callback(false, 0)
  end
  local function sendGetMultiplayerBossInfoRequest()
    local params = {}
    local request = GetMultiplayserBossInfoRequest.new(params, rpc.SendingPriority.kHigh, true)
    request:addEventListener( RequestNotifyEnum.GetMultiplayserBossInfoSucceed, getMultiplayserBossInfoSucceed )
    request:addEventListener( RequestNotifyEnum.GetMultiplayserBossInfoFailed, getMultiplayserBossInfoFailed )
    request:start()
  end
  
  sendGetMultiplayerBossInfoRequest()
end