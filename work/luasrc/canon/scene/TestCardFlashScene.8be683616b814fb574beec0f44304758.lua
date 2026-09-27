require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.customUI/CanonCard"

TestCardFlashScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function TestCardFlashScene:ctor()  
end

function TestCardFlashScene:create()
  local s = TestCardFlashScene.new()
  s:initScene()
  return s
end


function TestCardFlashScene:onInit()
	 local fspt = FlashSprite:create("flash/cardCombine")
	 fspt:changeAnimation(0)
	 self:addChild(CocosObject.new(fspt))
end

function TestCardFlashScene:dispose()
  Scene.dispose(self)
end

