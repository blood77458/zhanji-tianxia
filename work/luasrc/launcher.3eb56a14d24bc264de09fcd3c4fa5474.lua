require "hecore.utils"
require "hecore.ResourceLoader"
g_startTime = os.time()
g_locationId = 1--此版本对应的地区编号 如: 大陆, 台湾 定义详见 ConstManager add by zheng.che @ 2015-1-12
ResourceLoader.init()

--require "canon.scene.LoadingScene"
require "canon.scene.DynamicUpdateScene"
--require "canon.scene.LoginScene"
--[[
--for testing
require "canon.scene.TestBattleScene"
require "canon.scene.TestCardFlashScene"
require "canon.scene.TestCardScene"

local scene = TestBattleScene:create()
local scene = TestCardFlashScene:create()
local scene = TestCardScene:create()
local loadingScene = LoadingScene:create()
loadingScene:setTargetScene(scene)
]]

--[[
local Loading = Scene:create()
local Login = LoginScene:create()
local loadingSprite = Sprite:create("cover.png")
loadingSprite:setPosition(ccp(CCDirector:sharedDirector():getVisibleSize().width/2,CCDirector:sharedDirector():getVisibleSize().height/2))
loadingSprite:setScale(2)
local act = CCFadeIn:create(0.1)
local function loadingFinish()
    Director:sharedDirector():replaceScene(Login)
end
local array = CCArray:create()
array:addObject(act)
array:addObject(CCDelayTime:create(2))
array:addObject(CCCallFunc:create(loadingFinish))
Loading:addChild(loadingSprite)
loadingSprite:runAction(CCSequence:create(array))

--]]

function IsDiaosiDevice()
	local gaofushuai = true
	local ram = MetaInfo:getInstance():getTotalMemory()
	local screenWidth = MetaInfo:getInstance():getResolutionWidth()
	local screenHeight = MetaInfo:getInstance():getResolutionHeight()
	local area = screenWidth*screenHeight
	if area < 432000 then
		gaofushuai = false
	end
	
	if ram <= 512 then
		gaofushuai = false
	end
	
	return not gaofushuai
end

function CanonPlayEffect(effect)
	local effectId = -1
	local musicFlag = CCUserDefault:sharedUserDefault():getIntegerForKey("music_option")
	if musicFlag == 0 or musicFlag == 1 then
		effectId = SimpleAudioEngine:sharedEngine():playEffect(effect)
	end
	return effectId
end

local function restartApp()
  print("restartApp!!!!!")
  local mainActivityClass = luajava.bindClass("com.happyelements.arda.MainActivity")  
  local activity = mainActivityClass.mainActivity
  local intent = luajava.newInstance("android.content.Intent",activity, mainActivityClass);
              
  local requestId = 123456;
  local pendingIntentClass = luajava.bindClass("android.app.PendingIntent") 
  local pi = pendingIntentClass:getActivity(activity, requestId,    
    intent, pendingIntentClass.FLAG_CANCEL_CURRENT);
  local mgr = activity:getSystemService("alarm");
  local RTC=1
  mgr:set(RTC, os.time()*1000 + 500, pi);
  os.exit()
end


g_isRetryShowing = 0

if jit and jit.off then
	--he_log_debug("jit off")
	jit.off() 
end

require "canon.manager.DcManager"
DcManager.initDCPlatformInfo()

--[[
if StartupConfig:getInstance():isLocalDevelopMode() then
	he_log_info("+++++++++++++++++++++++++++Local Develop is True++++++++++++++++++++++++++++++++")
	require "canon.scene.LoadingScene"
	local loadingScene = LoadingScene:create()
		Director:sharedDirector():runWithScene( loadingScene )
else
	he_log_info("***************************Local Develop is false********************************")
	local loadingScene = DynamicUpdateScene:create()
		Director:sharedDirector():runWithScene( loadingScene )
end
]]

require "canon.scene.SBTipsScene"
local loadingScene = SBTipsScene:create()
Director:sharedDirector():runWithScene( loadingScene )