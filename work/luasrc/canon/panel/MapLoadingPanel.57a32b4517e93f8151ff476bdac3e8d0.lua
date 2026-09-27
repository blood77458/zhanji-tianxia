require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "hecore.display.Sprite"
require "hecore.ui.ProgressBar"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()


--
-- MapLoadingPanel
--

MapLoadingPanel = class(Layer)

function MapLoadingPanel:show(container, endPoint)
  local aLoadingPanel = MapLoadingPanel:create(container, endPoint)
  container:addChild(aLoadingPanel)
  return aLoadingPanel
end

function MapLoadingPanel:ctor()
  self.container = nil
  self.endPoint = nil
  self.currentPoint = 0
  self.progress = nil
end

function MapLoadingPanel:create(container, endPoint)
  local s = MapLoadingPanel.new()
  s:initLayer(container, endPoint)
  return s
end

function MapLoadingPanel:initLayer(container, endPoint)
  MapLoadingPanel.super.initLayer(self)
  self.container = container
  self.endPoint = endPoint
  --self.container.targetInfoPanel = self
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(75)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  local sprite = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_playerExp_sb.png")
  sprite:setPosition(ccp(visibleSize.width / 2.0 - sprite:getContentSize().width / 2.0, visibleSize.height / 2.0))
  sprite:setAnchorPoint(ccp(0, 0.5))
  self.progress = ProgressBar:create(sprite) 
  self.progress:setPercentage(self.currentPoint * 100 / self.endPoint)
  self:addChild(sprite)
end

function MapLoadingPanel:loadTo(nextPoint, duration)
  self.currentPoint = nextPoint
  self.progress:progressTo(self.currentPoint * 100 / self.endPoint, duration)
end

function MapLoadingPanel:stop()
  self.progress:stopProgress()
end

