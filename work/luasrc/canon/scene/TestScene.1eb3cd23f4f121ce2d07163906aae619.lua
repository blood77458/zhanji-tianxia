require "hecore.display.CocosObject"
require "hecore.display.Director"


TestScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function TestScene:ctor()
	self.title = "测试Scene"
end

function TestScene:create()
  local s = TestScene.new()
  s:initScene()
  return s
end



function TestScene:onInit()
	Scene.onInit(self)
end

function TestScene:dispose()
  TestScene.super.dispose(self)
end

