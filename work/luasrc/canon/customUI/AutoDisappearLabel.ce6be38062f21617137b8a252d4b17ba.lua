require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "hecore.display.TextField"

local auto_disappear_label_z_order = 10001
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- AutoDisappearLabel
--

AutoDisappearLabel = class()

function AutoDisappearLabel:showContent(aContainer, aContent, aPosition)
  local aLabel = TextField:create(aContent, "Helvetica", 35, CCSizeMake(0,0), kCCTextAlignmentCenter)
  aLabel:setPosition(aPosition)
  aLabel:setOpacity(0)
  aContainer:addChildAt(aLabel, auto_disappear_label_z_order)
  local function exitActionFinished()
    if (type(aLabel) == "table") and (type(aLabel.parent) == "table") and aLabel.parent.refCocosObj and aLabel.refCocosObj then
      aLabel:removeFromParentAndCleanup(true)
    end
  end
  local arr = CCArray:create()
  arr:addObject(CCFadeIn:create(0.3))
  --arr:addObject(CCDelayTime:create(0.1))
  arr:addObject(CCFadeOut:create(0.3))
  arr:addObject(CCCallFunc:create(exitActionFinished))
  aLabel:runAction(CCSequence:create(arr))
  
  arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(0, 50)))
  --arr:addObject(CCDelayTime:create(0.1))
  arr:addObject(CCMoveBy:create(0.3, ccp(0, 50)))
  aLabel:runAction(CCSequence:create(arr))
end