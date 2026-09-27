--------------------------------------------------------------------------------
-- TestCanonCardScene.lua - 测试CanonCard的Scene
-- author: xiaojie.bai
-- date: 2013-08-28 20:50
--------------------------------------------------------------------------------
require "canon.scene.BaseUIScene"

require "canon.customUI.CanonCard"
require "canon.canonUtils"

TestCanonCardScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function TestCanonCardScene:ctor()
	self.title = "CanonCard测试"
end

function TestCanonCardScene:create()
  local scene = TestCanonCardScene.new()
  scene:initScene()
  return scene
end

function TestCanonCardScene:back()
  self:replaceScene(MainMenuScene)
end

function TestCanonCardScene:onInit()
	BaseUIScene.initBackGround(self)

  -- local cardMetaId = 101125; -- rare = 2
  local cardMetaId = 101025; -- rare = 3
  -- local cardMetaId = 101117; -- rare = 6

  local bigCanonCardWithInfo = getBigCanonCardWithInfoByMetaId(cardMetaId)
  bigCanonCardWithInfo:setPosition(ccp(200, 800))
  bigCanonCardWithInfo:setHp(888888)
  bigCanonCardWithInfo:setAtk(888888)
  bigCanonCardWithInfo:setDef(888888)
  bigCanonCardWithInfo:setLevel(89)

  local bigCanonCardNoInfo = getBigCanonCardNoInfoByMetaId(cardMetaId)
  bigCanonCardNoInfo:setPosition(ccp(200, 340))

  local smallCanonCardWithLevel = getSmallCanonCardWithLevelByMetaId(cardMetaId)
  smallCanonCardWithLevel:setPosition(ccp(600, 280))
  smallCanonCardWithLevel:setLevel(122)

  local smallCanonCardWithProp = getSmallCanonCardWithPropByMetaId(cardMetaId)
  smallCanonCardWithProp:setPosition(ccp(600, 540))
  smallCanonCardWithProp:setHp(888888)
  smallCanonCardWithProp:setAtk(888888)
  smallCanonCardWithProp:setDef(888888)

  local smallCanonCardNoInfo = getSmallCanonCardNoInfoByMetaId(cardMetaId)
  smallCanonCardNoInfo:setPosition(ccp(600, 800))

  self:addChild(bigCanonCardWithInfo)
  self:addChild(bigCanonCardNoInfo)
  self:addChild(smallCanonCardWithLevel)
  self:addChild(smallCanonCardWithProp)
  self:addChild(smallCanonCardNoInfo)

	BaseUIScene.onInit(self)
end

function TestCanonCardScene:dispose()
  Scene.dispose(self)
end

function TestCanonCardScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function TestCanonCardScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function TestCanonCardScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
end

function TestCanonCardScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function TestCanonCardScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function TestCanonCardScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function TestCanonCardScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
end

function TestCanonCardScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end