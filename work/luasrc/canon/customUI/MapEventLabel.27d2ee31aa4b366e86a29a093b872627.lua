require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.display.Sprite"
require "hecore.display.Layer"
require "hecore.display.TextField"

local map_event_label_z_order = 10001
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- MapEventLabel
--

MapEventLabel = class()

--DOUBLE_REWARD_MODIFY
--doubleRewardStr 多倍奖励文本框内容
function MapEventLabel:showContent(aContainer, aTitleImageName, aContent, aPosX, aPosY, doubleRewardStr)
  local aTitle = Sprite:create(aTitleImageName)
  local aTitleHeight = aTitle:getContentSize().height
  local aTitleWidth = aTitle:getContentSize().width
  local aTotalWidth = aTitleWidth
  
  local aNumberLabel_co = CCLabelAtlas:create(aContent, "map/others/sliver_font.png", 60, 72, 47)
  local aNumberLabel = CocosObject.new(aNumberLabel_co)
  local aNumberHeight = 72
  local aNumberWidth = 60 * string.len(aContent)
  aTotalWidth = aTotalWidth + 20 + aNumberWidth
  
  local result = Layer:create()
  result:setContentSize(CCSizeMake(aTotalWidth, aTitleHeight))
  --result:setAnchorPoint(ccp(0.5, 0))
  
  aTitle:setAnchorPoint(ccp(0.5, 0.5))
  aTitle:setPosition(ccp(aTitleWidth / 2.0, aTitleHeight / 2.0))
  result:addChild(aTitle)
  aTitle:setOpacity(0)
  
  aNumberLabel:setAnchorPoint(ccp(0.5, 0.5))
  aNumberLabel:setPosition(ccp(aTotalWidth - aNumberWidth / 2.0, aTitleHeight / 2.0))
  result:addChild(aNumberLabel)
  aNumberLabel:setOpacity(0)

  --DOUBLE_REWARD_MODIFY
  if doubleRewardStr then
    local doubleLabel_co = CCLabelBMFont:create(doubleRewardStr, "pic/fnt/multiple_text.fnt")
    local doubleLabel = CocosObject.new(doubleLabel_co)
    doubleLabel:setAnchorPoint(ccp(1, 0))
    doubleLabel:setPosition(ccp(aNumberLabel:getPositionX() + (aNumberWidth + 115)/2, aNumberLabel:getPositionY() - 36))
    result:addChild(doubleLabel)
  end
  
  result:setPosition(ccp(aPosX - aTotalWidth / 2.0, aPosY - aTitleHeight / 2.0))
  aContainer:addChildAt(result, map_event_label_z_order)
  
  local function exitActionFinished()
    if (type(result) == "table") and (type(result.parent) == "table") and result.parent.refCocosObj and result.refCocosObj then
      result:removeFromParentAndCleanup(true)
    end
  end
  local arr1 = CCArray:create()
  arr1:addObject(CCMoveBy:create(0.3, ccp(0, 100)))
  arr1:addObject(CCDelayTime:create(0.5))
  arr1:addObject(CCMoveBy:create(0.3, ccp(0, 100)))
  arr1:addObject(CCCallFunc:create(exitActionFinished))
  result:runAction(CCSequence:create(arr1))
  
  
  local arr2 = CCArray:create()
  arr2:addObject(CCFadeIn:create(0.3))
  arr2:addObject(CCDelayTime:create(0.5))
  arr2:addObject(CCFadeOut:create(0.3))
  aTitle:runAction(CCSequence:create(arr2))
  
  arr2 = CCArray:create()
  arr2:addObject(CCFadeIn:create(0.3))
  arr2:addObject(CCDelayTime:create(0.5))
  arr2:addObject(CCFadeOut:create(0.3))
  aNumberLabel:runAction(CCSequence:create(arr2))
end