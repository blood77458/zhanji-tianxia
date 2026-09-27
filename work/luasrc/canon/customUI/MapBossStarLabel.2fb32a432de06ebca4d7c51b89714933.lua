require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.display.Sprite"
require "hecore.display.Layer"
require "hecore.display.TextField"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local star_scale = 2
local star_space = 10
local star_action_gap_interval = 0.1
local star_animation_duration = 0.2

--
-- MapBossStarLabel
--

MapBossStarLabel = class()

function MapBossStarLabel:showContent(aContainer, aStarNum, aPosX, aPosY)
  assert(aStarNum ~= 0, "star num should not be 0!")
  local aInstance = MapBossStarLabel.new(aContainer, aStarNum)
  aInstance.contentLayer:setPosition(ccp(aPosX - aInstance.totalWidth / 2.0, aPosY - aInstance.totalHeight / 2.0))
  aContainer:addChild(aInstance.contentLayer)
  aInstance:doAppearAction()
  return aInstance
end

function MapBossStarLabel:ctor(aContainer, aStarNum)
  self.starList = {}
  self.starWhiteList = {}
  self.totalWidth = 0
  self.totalHeight = nil
  for i = 1, aStarNum do
    local aStar = Sprite:create("#card_xing.png")
    aStar:setAnchorPoint(ccp(0, 0.5))
    local aStarWhite = Sprite:create("#card_white.png")
    aStarWhite:setAnchorPoint(ccp(0, 0))
    aStarWhite:setPosition(ccp(0, 0))
    aStarWhite.name = "starWhite"
    aStar:addChild(aStarWhite)
    aStar:setScale(star_scale)
    table.insert(self.starWhiteList, aStarWhite)
    table.insert(self.starList, aStar)
    self.totalWidth = self.totalWidth + aStar:getContentSize().width * star_scale
    if not self.totalHeight then
      self.totalHeight = aStar:getContentSize().height * star_scale
    end
  end
  self.totalWidth = self.totalWidth + star_space * (#self.starList - 1)
  self.contentLayer = Layer:create()
  self.contentLayer:setContentSize(CCSizeMake(self.totalWidth, self.totalHeight))
  
  local aBasePosX = 0
  for i, aStar in ipairs(self.starList) do
    local aContentSize = aStar:getContentSize()
    aStar:setPosition(ccp(aBasePosX, self.totalHeight / 2.0))
    self.contentLayer:addChild(aStar)
    aBasePosX = aBasePosX + aContentSize.width * star_scale + star_space
  end
end

function MapBossStarLabel:doAppearAction()
  for i, aStar in ipairs(self.starList) do
    local function showStar()
      aStar:setVisible(true)
      local aStarWhite = self.starWhiteList[i]
      aStarWhite:runAction(CCFadeOut:create(star_animation_duration))
    end
    
    aStar:setVisible(false)
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(star_action_gap_interval * (i - 1)))
    arr:addObject(CCCallFunc:create(showStar))
    aStar:runAction(CCSequence:create(arr))
  end
end

function MapBossStarLabel:doDisappearAction()
  
  local function removeContentLayer()
    self.contentLayer:removeFromParentAndCleanup(true)
  end
  
  for i, aStar in ipairs(self.starList) do
    local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(star_animation_duration))
    if i == #self.starList then
      arr:addObject(CCCallFunc:create(removeContentLayer))
      aStar:runAction(CCSequence:create(arr))
    else
      aStar:runAction(CCSequence:create(arr))
    end
  end
end