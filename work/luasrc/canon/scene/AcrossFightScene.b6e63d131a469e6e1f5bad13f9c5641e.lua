require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.request.GetCrossPkInfoRequest"
require "canon.request.GetCrossPkReportRequest"
require "canon.manager.AcrossFightManager"
require "canon.panel.AcrossFixturesPanel"
require "canon.panel.AcrossScheduleTablePanel"
require "canon.panel.AcrossGuessPanel"
require "canon.panel.AcrossRewardPanel"
require "canon.panel.AcrossTop4Panel"
require "canon.panel.AcrossUserDetailPanel"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local AcrossFightTabEnum = {
  reward = 1,
  fixtures = 2,
  topFour = 3,
  scheduleTable = 4,
  guess = 5,
}

local AcrossFightTabTitleDic = {
  [AcrossFightTabEnum.reward] = Localization:getInstance():getText("cross_reward_title"),
  [AcrossFightTabEnum.fixtures] = Localization:getInstance():getText("cross_race_title"),
  [AcrossFightTabEnum.topFour] = Localization:getInstance():getText("cross_race_title1"),
  [AcrossFightTabEnum.scheduleTable] = Localization:getInstance():getText("cross_list_title"),
  [AcrossFightTabEnum.guess] = Localization:getInstance():getText("cross_guess_title"),
}

local AcrossFightPanelDic = {
  [AcrossFightTabEnum.reward] = AcrossRewardPanel,
  [AcrossFightTabEnum.fixtures] = AcrossFixturesPanel,
  [AcrossFightTabEnum.topFour] = AcrossTop4Panel,
  [AcrossFightTabEnum.scheduleTable] = AcrossScheduleTablePanel,
  [AcrossFightTabEnum.guess] = AcrossGuessPanel,
}

local function fixturesTabSelected(evt)
  evt.context:tabSelected(AcrossFightTabEnum.fixtures)
end

local function scheduleTableTabSelected(evt)
  evt.context:tabSelected(AcrossFightTabEnum.scheduleTable)
end

local function guessTabSelected(evt)
  evt.context:tabSelected(AcrossFightTabEnum.guess)
end

local function topFourTabSelected(evt)
  evt.context:tabSelected(AcrossFightTabEnum.topFour)
end

local function rewardTabSelected(evt)
  evt.context:tabSelected(AcrossFightTabEnum.reward)
end

local tabListenerDic = {
  [AcrossFightTabEnum.reward] = rewardTabSelected,
  [AcrossFightTabEnum.fixtures] = fixturesTabSelected,
  [AcrossFightTabEnum.topFour] = topFourTabSelected,
  [AcrossFightTabEnum.scheduleTable] = scheduleTableTabSelected,
  [AcrossFightTabEnum.guess] = guessTabSelected,
}

--
--AcrossFightScene
--

AcrossFightScene = class(BaseUIScene)

function AcrossFightScene:ctor()
	self.curSceneEnum = SceneEnum.AcrossFightScene
end

function AcrossFightScene:create(argv)
  local s = AcrossFightScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s:initScene()
  return s
end

function AcrossFightScene:onInit()
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)
  
  self.title = Localization:getInstance():getText("cross_server_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.bgUI = builder:build("bg_event_game")
  self:addChild(self.bgUI)
  self.tabUI = builder:build("across_fight_title")
  
  --self.tabUI:setZOrder(5)
  --self.tabUI:setZOrder(5)
  --self.tabUI:setZOrder(5)
  
  self.tabTypeList = self.getTabTypeList()
  self.tabViewList = {}
  self.tabButtons = {}
  self.selectTab = nil
  self.selectedPanel = nil
  self:changeToPanel(self.tabTypeList[1])
  
  local function baseuiAddedCallback()
    self:addChild(self.tabUI)
  end
  BaseUIScene.onInit(self, nil, {baseuiAddedCallback = baseuiAddedCallback})
end

function AcrossFightScene:getTabTypeList()
  local result = {}
  local tabType = AcrossFightManager.getAcrossFightTabType()
  if tabType == 1 then   --参赛人员确定之后，4强产生之前
    table.insert(result, AcrossFightTabEnum.fixtures)
    table.insert(result, AcrossFightTabEnum.scheduleTable)
    table.insert(result, AcrossFightTabEnum.guess)
  elseif tabType == 2 then   --4强产生之后，能够领取奖励之前
    table.insert(result, AcrossFightTabEnum.fixtures)
    table.insert(result, AcrossFightTabEnum.topFour)
    table.insert(result, AcrossFightTabEnum.scheduleTable)
    table.insert(result, AcrossFightTabEnum.guess)
  elseif tabType == 3 then   --能领取奖励之后，过了领取奖励时间之前
    table.insert(result, AcrossFightTabEnum.reward)
    table.insert(result, AcrossFightTabEnum.fixtures)
    table.insert(result, AcrossFightTabEnum.topFour)
    --table.insert(result, AcrossFightTabEnum.scheduleTable) --新需求这种情况下显示竞猜界面，不显示赛程页签，by dc
	table.insert(result, AcrossFightTabEnum.guess)
  else            --跨服武道会时间结束
    
  end
  return result
end

function AcrossFightScene:changeToPanel(aTab)
  if self.selectTab == aTab then
    return
  end
  
  local function addNewPanel()
    self.selectedPanel = AcrossFightPanelDic[self.selectTab]:create(self)
    self:addChildAt(self.selectedPanel, 2)
  end
  local startPanelExit
  local panelExitFinished
  local startPanelEnter
  local panelEnterFinished
  startPanelExit = function()
    self:disableUserInterface()
    self.selectedPanel:panelExit(panelExitFinished)
  end
  panelExitFinished = function()
    self:enableUserInterface()
    self.selectedPanel:removeFromParentAndCleanup(true)
    addNewPanel()
    startPanelEnter()
  end
  startPanelEnter = function()
    self.tabViewList = self:getTabViewList()
    self:refreshTabView()
    for aIndex, aTabButton in pairs(self.tabButtons) do
      aTabButton:dispose()
      self.tabButtons[aIndex] = nil
    end
    for aIndex, aTabView in pairs(self.tabViewList) do
      if aIndex ~= self.selectTab then
        local aTabButton = Button:create(aTabView)
        aTabButton:addEventListener(Events.kStart, tabListenerDic[aIndex], self)
        self.tabButtons[aIndex] = aTabButton
      end
    end
    self:disableUserInterface()
    self.selectedPanel:panelEnter(panelEnterFinished)
  end
  
  panelEnterFinished = function()
    self:enableUserInterface()
  end
  
  local function startChange()
    if self.selectedPanel then
      startPanelExit()
    else
      addNewPanel()
      startPanelEnter()
    end
  end
  self.selectTab = aTab
  startChange()
end

function AcrossFightScene:getTabViewList()
  local result = {}
  local tabNum = #self.tabTypeList
  for i = 1, 4 do
    local aTabView
    local aTabTextView
    if i == 1 then
      aTabView = self.tabUI:getChildByName("btn_across_fight_event_game")
      --aTabTextView = aTabView:getChildByName("txt")
    elseif i == 2 then
      aTabView = self.tabUI:getChildByName("btn_across_fight_formt_game")
      --aTabTextView = aTabView:getChildByName("txt")
    elseif i == 3 then
      aTabView = self.tabUI:getChildByName("btn_across_fight_quiz_game")
      --aTabTextView = aTabView:getChildByName("txt")
    elseif i == 4 then
      aTabView = self.tabUI:getChildByName("btn_across_fight_award")
      --aTabTextView = aTabView:getChildByName("txt")
    end
    if i <= tabNum then
      aTabView:setVisible(true)
      --aTabTextView:setString(AcrossFightTabTitleDic[self.tabTypeList[i]])
      result[self.tabTypeList[i]] = aTabView
    else
      aTabView:setVisible(false)
    end
  end
  return result
end

function AcrossFightScene:refreshTabView()
  for aIndex, aTabView in pairs(self.tabViewList) do
    aTabView:getChildByName("txt"):setString(AcrossFightTabTitleDic[aIndex])
    if aIndex == self.selectTab then
      aTabView:getChildByName("btn"):setVisible(true)
      aTabView:getChildByName("disable"):setVisible(false)
    else
      aTabView:getChildByName("btn"):setVisible(false)
      aTabView:getChildByName("disable"):setVisible(true)
    end
  end
  self:refreshTabTag()
end

function AcrossFightScene:refreshTabTag()
  for aIndex, aTabView in pairs(self.tabViewList) do
    if aIndex == AcrossFightTabEnum.reward or aIndex == AcrossFightTabEnum.guess then
      local aTipNum
      if aIndex == AcrossFightTabEnum.reward then
        aTipNum = AcrossFightManager.getRewardTipNum()
      else
        aTipNum = AcrossFightManager.getGuessTipNum()
      end
      if aTipNum > 0 then
        aTabView:getChildByName("friend_tips_friend_RequestSentTag"):setVisible(true)
        aTabView:getChildByName("friend_tips_friend_RequestSentTag_num"):setVisible(true)
        aTabView:getChildByName("friend_tips_friend_RequestSentTag_num"):getChildByName("font"):setString(tostring(aTipNum))
      else
        aTabView:getChildByName("friend_tips_friend_RequestSentTag"):setVisible(false)
        aTabView:getChildByName("friend_tips_friend_RequestSentTag_num"):setVisible(false)
      end
    else
      aTabView:getChildByName("friend_tips_friend_RequestSentTag"):setVisible(false)
      aTabView:getChildByName("friend_tips_friend_RequestSentTag_num"):setVisible(false)
    end
  end
end

function AcrossFightScene:tabSelected(aTab)
  self.tabTypeList = self.getTabTypeList()
  if #self.tabTypeList == 0 then
    self:replaceScene(MainMenuScene)
    return
  end
  
  local function changePanel()
    local aTrueTab = aTab
    if not table.indexOf(self.tabTypeList, aTrueTab) then
      aTrueTab = self.tabTypeList[1]
    end
    if aTrueTab == AcrossFightTabEnum.fixtures or 
      aTab == AcrossFightTabEnum.scheduleTable or 
      aTab == AcrossFightTabEnum.topFour or 
      aTab == AcrossFightTabEnum.reward or 
      aTab == AcrossFightTabEnum.guess then
      local function onSucceed(requestEvent)
        GetCrossPkInfoRequest.onSucceedDefault(requestEvent)
        self:changeToPanel(aTrueTab)
      end
      GetCrossPkInfoRequest.sendRequest(onSucceed, GetCrossPkInfoRequest.onFailedDefault)
    else
      self:changeToPanel(aTrueTab)
    end
  end
  
  changePanel()
  
  --[[
  local function changePanel()
    if not table.indexOf(self.tabTypeList, aTab) then
      self:changeToPanel(self.tabTypeList[1])
    else
      self:changeToPanel(aTab)
    end
  end
  
  if aTab == AcrossFightTabEnum.fixtures or aTab == AcrossFightTabEnum.scheduleTable or aTab == AcrossFightTabEnum.topFour then
    local function onSucceed(requestEvent)
      GetCrossPkInfoRequest.onSucceedDefault(requestEvent)
      changePanel()
    end
    GetCrossPkInfoRequest.sendRequest(onSucceed, GetCrossPkInfoRequest.onFailedDefault)
  else
    changePanel()
  end
  ]]
end

function AcrossFightScene:disableUserInterface()
  if self.tempLayer then
    return
  end
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.targetInfoPanel = self.tempLayer
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(false)
  end
end

function AcrossFightScene:enableUserInterface()
  if not self.tempLayer then
    return
  end
  self.tempLayer:removeFromParentAndCleanup(true)
  self.tempLayer = nil
  self.targetInfoPanel = nil
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(true)
  end
end

function AcrossFightScene:setTableViewsEnabledInner(isEnable)
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(isEnable)
  end
end

function AcrossFightScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function AcrossFightScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function AcrossFightScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.bgUI:setPositionX(self.bgUI:getPositionX() - visibleSize.width)
  self.bgUI:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  self.tabUI:setPositionX(self.tabUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.tabUI:runAction(CCSequence:create(arr))
end

function AcrossFightScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  
end

function AcrossFightScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function AcrossFightScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function AcrossFightScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.bgUI:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.tabUI:runAction(CCSequence:create(arr))
  
  if self.selectedPanel then
    self.selectedPanel:panelExit(nil)
  end
end

function AcrossFightScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function AcrossFightScene:back()
  self:replaceScene(CompeteScene)
end

function AcrossFightScene.enterScene(successCallback)
  local function onSucceed(requestEvent)
		GetCrossPkInfoRequest.onSucceedDefault(requestEvent)
    if successCallback then
      successCallback()
    end
	end

	GetCrossPkInfoRequest.sendRequest(onSucceed, GetCrossPkInfoRequest.onFailedDefault)
end