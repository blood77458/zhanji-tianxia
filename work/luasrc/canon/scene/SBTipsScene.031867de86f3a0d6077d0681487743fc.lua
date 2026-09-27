require "canon.scene.DynamicUpdateScene"
--
-- SBTipsScene
--
SBTipsScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SBTipsScene:ctor()
	
end

function SBTipsScene:create()
  local s = SBTipsScene.new()
  s:initScene()
  return s
end

function SBTipsScene:onInit()
	local s = Sprite:create("pic/SBTips.png")
	s:setPosition(ccp(visibleSize.width/2, visibleSize.height/2))
	self:addChild(s)

	local aScheduler
	local function callback()
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(aScheduler)
		if StartupConfig:getInstance():isLocalDevelopMode() then
			he_log_info("+++++++++++++++++++++++++++Local Develop is True++++++++++++++++++++++++++++++++")
			require "canon.scene.LoadingScene"
			local loadingScene = LoadingScene:create()
			Director:sharedDirector():replaceScene( loadingScene )
		else
			he_log_info("***************************Local Develop is false********************************")
			local loadingScene = DynamicUpdateScene:create()
			Director:sharedDirector():replaceScene( loadingScene )
		end
	end
	aScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(callback, 3, false)
end