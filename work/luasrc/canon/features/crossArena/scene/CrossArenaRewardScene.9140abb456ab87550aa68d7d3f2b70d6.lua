require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"
require "canon.customUI.CdLabelComponent"
require "canon.features.crossArena.manager.CrossArenaManager"

require "canon.features.crossArena.layer.CrossArenaChanllengeLayer"
require "canon.features.crossArena.request.GetCrossPvpInfoRequest"

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

CrossArenaRewardScene = class(BaseUIScene)

CrossArenaRewardScene.TAB_REWARD     = 1--领奖
CrossArenaRewardScene.TAB_RANK       = 2--排行

local visibleSize = CCSizeMake(720, 1280)

-------------------------------------------------------------------------------
-- 按钮事件
-------------------------------------------------------------------------------


local function onBtnRewardClick(evt)
    local function onAfterSucceed(e)
    if e.data.phaseIndex == 0 then--战斗阶段
      CrossArena.gotoCrossPvpScene(nil, nil)
    elseif e.data.phaseIndex == 1 then--领奖阶段
      evt.context.tabChangeComponent:changeToPanelByIndex(CrossArenaRewardScene.TAB_REWARD)
    end
  end
  GetCrossPvpInfoRequest.sendRequestDefalut(onAfterSucceed)
  
end

local function onBtnRankClick(evt)
  if evt.context.tabChangeComponent:canChangeTo(CrossArenaRewardScene.TAB_RANK) then
    --允许切换
    local function onAfterSucceed(requestEvt)
      evt.context.tabChangeComponent:changeToPanelByIndex(CrossArenaRewardScene.TAB_RANK)
    end
    CrossPvpGetRankInfoRequest.sendRequestDefalut(onAfterSucceed)
  end
end

-------------------------------------------------------------------------------
-- 成员函数
-------------------------------------------------------------------------------

function CrossArenaRewardScene:ctor()
  self.title = getTextByKey("crossArena_Title")

  self.selectedPanelIdx = 0 
  self.selectedPanel = nil
end

function CrossArenaRewardScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
    
  local scene = CrossArenaRewardScene.new()
    
  scene:initScene()
  return scene
end

function CrossArenaRewardScene:onInit() 
  BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  self.targetInfoPanel = nil

  self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("cross_Arena_title")
  self:addChild(self.mainUI)

  self.borderCast = self.builder:build("crossArena_general_radio")
  self.borderCast:setZOrder(1001)
  self:addChild(self.borderCast)

  self.reportLabel = self.borderCast:getChildByName("txt_jj_45"):getChildByName("txt")
  self.originalPosX = self.reportLabel:getPositionX() + visibleSize.width
  self.reportLabel:setString(CrossArenaManager:getLastString() or "")
  
  BaseUIScene.onInit(self)

  local function onTimeComplete()
    --跳转到新一轮战斗界面
    CrossArena.gotoCrossPvpScene(nil, nil)
  end
  
  self.cdLabelComponent = CdLabelComponent:create()
  self.cdLabelComponent:setCallback(nil, onTimeComplete)
  local endTime = CrossArenaManager.getRewardEndTime()
  self.cdLabelComponent:setTargetTime(endTime + 5)--往后偏移5秒，防止前端刷新了，后端还没刷新
  self.cdLabelComponent:start()


  --生成新panle
  local function onCreatePanel(aIndex)
    local layer
    if aIndex == CrossArenaRewardScene.TAB_REWARD then
      layer = CrossArenaRewardLayer:create(self)
      -- return CrossArenaRewardLayer:create(self)
    elseif aIndex == CrossArenaRewardScene.TAB_RANK then
      layer = CrossArenaRankLayer:create(self, CrossArena.SCENE_REWARD_INDEX, aIndex)
      -- return CrossArenaRankLayer:create(self)
    end
    -- print("无效的panle编号! aIndex = " .. aIndex)
    layer:setZOrder(1000)
    return layer
  end
  self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)

  --设置tab
  self.btnRewardDisplay = self.mainUI:getChildByName("btn_across_fight_1")
  self.btnRewardDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_Title5"))--领奖
  self.btnReward = CanonButton:create(self.btnRewardDisplay)
  self.btnReward:addEventListener(Events.kStart, onBtnRewardClick, self)
  self.tabChangeComponent:addTab(self.btnReward)

  self.btnRankDisplay = self.mainUI:getChildByName("btn_across_fight_2")
  self.btnRankDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("crossArena_Title2"))--排行
  self.btnRank = CanonButton:create(self.btnRankDisplay)
  self.btnRank:addEventListener(Events.kStart, onBtnRankClick, self)
  self.tabChangeComponent:addTab(self.btnRank)

  self.mainUI:getChildByName("btn_across_fight_4"):setVisible(false)
  self.mainUI:getChildByName("btn_across_fight_3"):setVisible(false)
 
  --设定初始显示的页面
  self.tabChangeComponent:changeToPanelByIndex(self.argv.params.panelIndex)
end

function CrossArenaRewardScene:onUpdate(dt)
  dt = 0.016
  
  if CrossArenaManager._shouldStayInArena and (CrossArenaManager._durationInArena > 5.8) then
      return
  end
  
  if CrossArenaManager._durationInArena < 0 then
    if #CrossArenaManager._crossPVPReports > 0 then
      CrossArenaManager._lastString = CrossArenaManager.popoutReport()
    else
      CrossArenaManager._lastString = ""
    end
    --CrossArenaManager._lastString = "GHHHHHG"
    self.reportLabel:setString(CrossArenaManager._lastString)
    CrossArenaManager._durationInArena = 0
  end
  
  CrossArenaManager._durationInArena = CrossArenaManager._durationInArena + dt
  
  if CrossArenaManager._durationInArena <= 0.8 then
    self.reportLabel:setPositionX(CrossArenaManager._lastPosX - visibleSize.width / 0.8 * dt)
    CrossArenaManager._lastPosX = CrossArenaManager._lastPosX - visibleSize.width / 0.8 * dt
  elseif CrossArenaManager._durationInArena <= 5.8 then
    self.reportLabel:setPositionX(self.originalPosX - visibleSize.width)
    CrossArenaManager._lastPosX = self.originalPosX - visibleSize.width
  elseif (CrossArenaManager._durationInArena > 5.8) and (CrossArenaManager._durationInArena <= 6.6) then
    self.reportLabel:setPositionX(CrossArenaManager._lastPosX - visibleSize.width / 0.8 * dt)
    CrossArenaManager._lastPosX = CrossArenaManager._lastPosX - visibleSize.width / 0.8 * dt
  elseif CrossArenaManager._durationInArena <= 7.1 then
    self.reportLabel:setPositionX(self.originalPosX - visibleSize.width * 2)
    CrossArenaManager._lastPosX = self.originalPosX - visibleSize.width * 2
  elseif CrossArenaManager._durationInArena > 7.1 then
    self.reportLabel:setPositionX(self.originalPosX)
    CrossArenaManager._lastPosX = self.originalPosX
    CrossArenaManager._durationInArena = -1
  end
end


function CrossArenaRewardScene:dispose()  
  BaseUIScene.dispose(self)
  if self.cdLabelComponent then
    self.cdLabelComponent:stop()
  end
  self.tabChangeComponent:dispose()
  self.tabChangeComponent = nil
end

function CrossArenaRewardScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CrossArenaRewardScene:preEnterAnimation()
  CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function CrossArenaRewardScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function CrossArenaRewardScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function CrossArenaRewardScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CrossArenaRewardScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CrossArenaRewardScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr)) 

  --同时当前选择页也退出动画 并行进行
  self.tabChangeComponent:startPanelExit(nil)
end

function CrossArenaRewardScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CrossArenaRewardScene:back()
  self.ignoreAction = false
  self:replaceScene(CompeteScene)
end