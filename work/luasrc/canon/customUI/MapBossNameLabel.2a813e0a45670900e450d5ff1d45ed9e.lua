require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.display.Sprite"
require "hecore.display.Layer"
require "hecore.display.TextField"
require "canon.utils.StringUtil"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local word_scale = 1.2
local word_space = 10
local fade_duration = 0.5

--
-- MapBossNameLabel
--

MapBossNameLabel = class()

function MapBossNameLabel:showContent(aContainer, aContent, aPosX, aPosY)
  local aInstance = MapBossNameLabel.new(aContainer, aContent)
  aInstance.contentLayer:setPosition(ccp(aPosX - aInstance.totalWidth / 2.0, aPosY - aInstance.totalHeight / 2.0))
  aContainer:addChild(aInstance.contentLayer)
  for i, aCharLabel in ipairs(aInstance.labelList) do
    aCharLabel:setOpacity(0)
    aCharLabel:runAction(CCFadeIn:create(fade_duration))
  end
  return aInstance
end

function MapBossNameLabel:ctor(aContainer, aContent)
  self.labelList = {}
  self.totalWidth = 0
  self.totalHeight = 0
  local charList = StringUtil.splitChineseEnglish(aContent)
  for _, aChar in ipairs(charList) do
    local aCharLabel = BitmapText:create(aChar, "common/card_name.fnt")
    aCharLabel:setScale(word_scale)
    table.insert(self.labelList, aCharLabel)
    self.totalWidth = self.totalWidth + aCharLabel:getContentSize().width * word_scale + 4
    local aHeight = aCharLabel:getContentSize().height * word_scale
    if self.totalHeight < aHeight then
      self.totalHeight = aHeight
    end
  end
  self.totalWidth = self.totalWidth + word_space * (#self.labelList - 1)
  self.contentLayer = Layer:create()
  self.contentLayer:setContentSize(CCSizeMake(self.totalWidth, self.totalHeight))
  
  local aBasePosX = 0
  for i, aCharLabel in ipairs(self.labelList) do
    local aContentSize = aCharLabel:getContentSize()
    aCharLabel:setAnchorPoint(ccp(0, 0.5))
    aCharLabel:setPosition(ccp(aBasePosX, self.totalHeight / 2.0))
    self.contentLayer:addChild(aCharLabel)
    aBasePosX = aBasePosX + aContentSize.width * word_scale + word_space
  end
end

function MapBossNameLabel:doDisappearAction()
  
  local function removeContentLayer()
    self.contentLayer:removeFromParentAndCleanup(true)
  end
  
  for i, aCharLabel in ipairs(self.labelList) do
    local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(fade_duration))
    if i == #self.labelList then
      arr:addObject(CCCallFunc:create(removeContentLayer))
      aCharLabel:runAction(CCSequence:create(arr))
    else
      aCharLabel:runAction(CCSequence:create(arr))
    end
    
  end
end