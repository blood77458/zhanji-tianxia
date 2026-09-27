--------------------------------------------------------------------------------
-- StoryReviewScene.lua - 精英关卡界面: 动态显示所有精英关卡状态，购买挑战次数，发起挑战
-- author: xiaojie.bai
-- date: 2013-09-26 10:40
--------------------------------------------------------------------------------

require "canon.scene.BaseUIScene"

require "canon.models.EliteManager"
require "canon.models.CalculationManager"
require "canon.models.RewardManager"
require "canon.canonUtils"
require "canon.utils.ViewControlUtil"
require "canon.utils.IdUtil"

require "canon.panel.CanonMessageBox"
require "canon.panel.AssistantMessageBoxPanel"
require "canon.manager.BagCalcManager"
require "canon.manager.DailyDataManager"

require "canon.data.MetaManager"

require "canon.panel.StoryReviewMainPanel"
require "canon.panel.StoryReviewActivityPanel"


StoryReviewScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function StoryReviewScene:ctor()
  self.title = getTextByKey("storyReview_title")
  self.argv = nil
  
  self.mainUI = nil
end

function StoryReviewScene:create(argv)
  local scene = StoryReviewScene.new()
  
  if(argv) then
    scene.argv = argv
  else 
    scene.argv = {enterScene = nil, returnScene = nil, params = {}}
  end
  
  if argv and argv.beginPanelIndex then
    scene.beginPanelIndex = argv.beginPanelIndex
  else
    scene.beginPanelIndex = 0
  end
  
  scene.currentPanel = nil

  scene:initScene()
  return scene
end

function StoryReviewScene:back()
  if self.currentPanel.PanelType == 0 then
    self:replaceScene(CityMainScene)
  elseif self.currentPanel.PanelType == 2 and self.argv.returnScene == "MerryChristmasScene" then
    local argv = {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",params={}}
    self:replaceScene(MerryChristmasScene:create(argv))
  else
    self.isChangeingScene = false
    self:switchPanel(0)
  end
end

function StoryReviewScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  self.mainUI = builder:build("elite_page_elite_list")
  self:addChild(self.mainUI)
  
  self.panelLayer = Layer:create()
  self.panelLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.panelLayer)

  self:switchPanel(self.beginPanelIndex)

	BaseUIScene.onInit(self)
end

function StoryReviewScene:switchPanel(panelIndex)
  local function createPanel()
    if panelIndex == 1 then
      self.currentPanel = StoryReviewMainPanel:create(self)
      self.currentPanel.PanelType = 1
    elseif panelIndex == 2 then
      self.currentPanel = StoryReviewActivityPanel:create(self)
      self.currentPanel.PanelType = 2
    else
      self.currentPanel = self:createSwitchLayer()
      self.currentPanel.PanelType = 0
    end

    self.panelLayer:addChild(self.currentPanel)
    self.currentPanel:doEnterAnimation()
  end

  if self.currentPanel then
    local function callBack()
      self.panelLayer:removeChild(self.currentPanel, true)
      createPanel()
    end
    self.currentPanel:doExitAnimation(callBack)
  else
    createPanel()
  end
end


function StoryReviewScene:dispose()
  StoryReviewScene.super.dispose(self)
end

function StoryReviewScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function StoryReviewScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function StoryReviewScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  self:nodeAnimationFinished()
end

function StoryReviewScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function StoryReviewScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function StoryReviewScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  self:nodeAnimationFinished()
end


--------------------------------------------------------------------------------
-- author: zhehua.ou
-- date: 2014-11-28 20:14
--------------------------------------------------------------------------------
function StoryReviewScene:createSwitchLayer()
  local StoryReviewSwitchPanel = class(Layer)

  function StoryReviewSwitchPanel:ctor()
    self.container = nil
  end

  function StoryReviewSwitchPanel:create(contianer)
    local layer = StoryReviewSwitchPanel.new()
    layer.contianer = contianer
    layer:initLayer()
    return layer
  end

  function StoryReviewSwitchPanel:initLayer()
    StoryReviewSwitchPanel.super.initLayer(self)

    local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
    self.mainUI = builder:build("Review_Plot")
    self:addChild(self.mainUI)

    local function onStoryBtn(evt)
      self.contianer:switchPanel(evt.target.type)
    end

    local mainStoryBtn = Button:create(self.mainUI:getChildByName("btn_mainStory"))
    mainStoryBtn:addEventListener(Events.kStart, onStoryBtn, self)
    mainStoryBtn.type = 1
    self.mainUI:getChildByName("btn_mainStory"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("eventChristmas_other3"))
    local mainStoryBtnEnable = CityMainScene.CheckMainStoryReviewBtnEnable()
    self.mainUI:getChildByName("btn_mainStory"):getChildByName("normal"):setVisible(mainStoryBtnEnable)
    mainStoryBtn:setEnable(mainStoryBtnEnable)

    local activityStoryBtn = Button:create(self.mainUI:getChildByName("btn_activitieStory"))
    activityStoryBtn:addEventListener(Events.kStart, onStoryBtn, self)
    activityStoryBtn.type = 2
    self.mainUI:getChildByName("btn_activitieStory"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("eventChristmas_other4"))
    local activityStoryBtnEnable = CityMainScene.CheckActivityStoryReviewBtnEnable()
    self.mainUI:getChildByName("btn_activitieStory"):getChildByName("normal"):setVisible(activityStoryBtnEnable)
    activityStoryBtn:setEnable(activityStoryBtnEnable)
  end

  function StoryReviewSwitchPanel:dispose()
    StoryReviewSwitchPanel.super.dispose(self)
  end

  function StoryReviewSwitchPanel:doEnterAnimation()
    local RunningScene = Director:sharedDirector():getRunningScene()
    RunningScene:setTouchEnabled(false)

    self:startEnterAnimation()
  end

  function StoryReviewSwitchPanel:startEnterAnimation()
    local function enterActionFinished()
      local RunningScene = Director:sharedDirector():getRunningScene()
      RunningScene:setTouchEnabled(true)
    end

    local function getCCSequence()
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(enterActionFinished))
      return CCSequence:create(arr)
    end

    self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
    self.mainUI:runAction(getCCSequence())
  end

  function StoryReviewSwitchPanel:doExitAnimation(callBackFunc)
    local RunningScene = Director:sharedDirector():getRunningScene()
    RunningScene:setTouchEnabled(false)
    self:startExitAnimation(callBackFunc)
  end

  function StoryReviewSwitchPanel:startExitAnimation(callBackFunc)
    local function exitActionFinished()
      local RunningScene = Director:sharedDirector():getRunningScene()
      RunningScene:setTouchEnabled(true)

      if callBackFunc then
        callBackFunc()
      end
    end

    local function getCCSequence()
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(exitActionFinished))
      
      return CCSequence:create(arr)
    end
    
    self.mainUI:runAction(getCCSequence())
  end
  
  local layer = StoryReviewSwitchPanel:create(self)
  return layer
end