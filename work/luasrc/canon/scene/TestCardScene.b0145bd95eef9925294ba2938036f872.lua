require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.MainMenuScene"
require "canon.scene.BaseUIScene"
require "canon.customUI.CanonCard"
require "canon.customUI.CanonItem"
require "canon.canonUtils"




TestCardScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function TestCardScene:ctor()
  
end

function TestCardScene:create()
  local s = TestCardScene.new()
  s:initScene()
  return s
end


function TestCardScene:onInit()
	
	--CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
	local builder = LayoutBuilder:createWithContentsOfFile("temp/testCardScene.json")
	local asdf = builder:build("testMc")
	self:addChild(asdf)
	
	  
end


