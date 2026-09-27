-- MerryChristmasScene
--
-- 圣诞节活动场景
-- Luoyang.yi

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.data.MetaManager"
require "canon.panel.MerryChristmasChallengePanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

MerryChristmasScene = class(BaseUIScene)
function MerryChristmasScene:ctor()
	self.curSceneEnum = SceneEnum.MerryChristmasScene
end

function MerryChristmasScene:create(argv)
  local s = MerryChristmasScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s:initScene()
  return s
end

--返回按钮(上层回调此函数)
function MerryChristmasScene:back()
  if self.argv and self.argv.returnScene == "ActivityPanelScene" then
    self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_MerryChristmas"})    
  else
    self:replaceScene(MainMenuScene)
  end
end

--初始化圣诞节场景
function MerryChristmasScene:onInit()
	BaseUIScene.initBackGround(self)  
  --活动标题
  self.title = getTextByKey("eventChristmas_other2")

  local panel = MerryChristmasChallengePanel:create(self)
  self:addChild(panel)

  BaseUIScene.onInit(self)
end


-- function MerryChristmasScene:setTableViewsEnabledInner(aEnabled)
--   print("MerryChristmasScene:setTableViewsEnabledInner: " .. tostring(aEnabled))
--   if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
--     self.selectedPanel:setTableViewTouched(aEnabled)
--   end
-- end


--新加 被popoutmanager调用 by czh
function MerryChristmasScene:setTableViewsEnabled(aEnabled)
  if (type(self.selectedPanel) == "table") and (type(self.selectedPanel.setTableViewTouched) == "function") then
    self.selectedPanel:setTableViewTouched(aEnabled)
  end
end

function MerryChristmasScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end


function MerryChristmasScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end


function MerryChristmasScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  -- local function enterActionFinished()
  self:nodeAnimationFinished()
  -- end
end


function MerryChristmasScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function MerryChristmasScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MerryChristmasScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function MerryChristmasScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  -- local function enterActionFinished()
    self:nodeAnimationFinished()
  -- end

  --如果需要动画则直接按照下面的方式
  
  -- for _, aGroup in ipairs(self.groupList) do
  --   aGroup:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  -- end
  -- self.selectedPanel:panelExit()
  -- local arr = CCArray:create()
  -- arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  -- arr:addObject(CCCallFunc:create(enterActionFinished))
  -- self.uiGroup9:runAction(CCSequence:create(arr))

end


-- function MerryChristmasScene:sufExitAnimation()
--   BaseUIScene.sufExitAnimation(self)
-- end


-- function MerryChristmasScene:back()
--   print('[MerryChristmasScene:back]')
--   if self.argv.returnScene == "ActivityPanelScene" then
--     self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_MultiplayerBoss"})
--   elseif self.argv.returnScene == "MainMenuScene" then
--     self:replaceScene(MainMenuScene)
--   else
--     self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_MultiplayerBoss"})
--   end
-- end

function MerryChristmasScene:dispose()
  if self.time_script_handler then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.time_script_handler)
    self.time_script_handler = nil
  end
  MerryChristmasScene.super.dispose(self)
end