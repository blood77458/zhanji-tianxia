require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.ProgressBar"
require "canon.canonUtils"
require "canon.manager.DcManager"
require "canon.script_and_guide.NewUserGuide"

local function IsDeviceHighCapacityMem()
	if __ANDROID then
		local ram = MetaInfo:getInstance():getTotalMemory()
		if ram >= 1024 then
			return true
		else
			return false
		end
	else
		return true
	end
end

local _isDeviceHighCapacityMem = IsDeviceHighCapacityMem()

LoadingScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function LoadingScene:ctor()
	if _isDeviceHighCapacityMem then
		CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888);
	else
		CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA4444);
	end
end

function LoadingScene:create()
  local s = LoadingScene.new()
  s:initScene()
  return s
end

local sfxSoundList = {
	"sfx_skile_card.wav",
	"sfx_monster_across.wav",
	"sfx_money_possess.wav",
	"sfx_exp_possess.wav",
	"sfx_exp_lvup.wav",
	"sfx_engly_lvup.wav",
	"sfx_day_login.wav",
	"sfx_chests_open.wav",
	"sfx_card_possess2.wav",
	"sfx_card_possess.wav",
	"sfx_card_evolve.wav",
	"sfx_card_compound.wav",
	"sfx_card_broken.wav",
	"sfx_button_confirm.wav",
	"sfx_button_cancel.wav",
	"sfx_boss_across.wav",
	"sfx_attack_sword.wav",
	"sfx_attack_spear.wav",
	"sfx_attack_hammer.wav",
	"sfx_attack_final.wav",
	"sfx_attack_bow.wav",
	"sfx_amer_sale.wav",
	"sfx_amer_evolve.wav"
}


function LoadingScene:loadItem()
	local step = self.loadingStep
	if step <= #self.LoadPngList then
		local name = self.LoadPngList[step]["png"]
		if not self.isLoadingPng then
			PngLoadingMgr:getInstance():loadPng(name)
		end
	elseif step <= (#self.LoadPngList + #self.LoadPlistList) then
		local name = self.LoadPlistList[step - #self.LoadPngList]["plist"]
		PlistResMgr:getInstance():loadPlist(name)
		self.loadingStep = self.loadingStep + 1
	else
		local name = self.LoadFlashList[step - #self.LoadPngList - #self.LoadPlistList]["flash"]
		FlashCacheMgr:getInstance():createItem(name)
		self.loadingStep = self.loadingStep + 1
	end
end

local kGuangX = 0
local kGuangY = 170

function LoadingScene:onUpdate(dt)
	local function onFlashAnimationEnd(anim)
		he_log_info( "************ ************")
		he_log_info("onFlashAnimationEnd")
		he_log_info( "************ ************" )
		self.CGAniminationFinish = true
	end
	
	if self.CGAniminationFinish then
		if self.loadState == 1 then
			self.loadState = 2
			DcManager.sendLoadingActivity(40, ((os.time() - g_startTime )*1000) )
		end
	end
	
  
  if self.loadState == 0 then
		-- if isWdjAndroid() or isDKAndroid() or is91Android() then
			-- self.loginBG = CCSprite:create("loading/loginBG_zhanji.png")
		-- else
			self.loginBG = CCSprite:create("loading/loginBG.png")
		-- end
  		self.loginBG:setAnchorPoint( ccp(0.0, 0.0) )
  		self.Co_loginBG = CocosObject.new(self.loginBG)
  		self:addChild(self.Co_loginBG)

  		self.sptBG = CCSprite:create("loading/dibian.png")
  		self.sptBG:setPosition(ccp(visibleSize.width/2,kGuangY))
  		--self.sptBG:setScaleX(720/40)
  		self.Co_sptBG = CocosObject.new(self.sptBG)
  		self:addChild(self.Co_sptBG)
		
		self.loadingStep = 1
		self.spt = CCProgressTimer:create(CCSprite:create("loading/jindutiao.png"))
		self.spt:setPosition(ccp(visibleSize.width/2,kGuangY))
		self.spt:setType(kCCProgressTimerTypeBar);
		self.spt:setMidpoint(ccp(0,0))
		self.spt:setBarChangeRate(ccp(1, 0))
		self.spt:setPercentage(0)
		self:addChild(CocosObject.new(self.spt))
		self.loadState = 1
		
		local particle = CCParticleSystemQuad:create("effect/fx_flower.plist")
		particle:setPosition(ccp(360, 800))
		self:addChild(CocosObject.new(particle))
		DcManager.sendLoadingActivity(20, ((os.time() - g_startTime )*1000) )
		
		
		require "canon.data.ThirdPlatformLogin"
		require "canon.scene.LoginScene"

		g_loadSceneCombine = true
		CanonPlayBackgroundMusic("music/m_title.mp3", true)
		DcManager.sendLoadingActivity(30, ((os.time() - g_startTime )*1000) )
		self.animationEnd = false
	elseif self.loadState == 1 then

	elseif self.loadState == 2 then
		--self.loadingStep = self.loadingStep + 1
		self:loadItem(self.loadingStep)
		progress = self.loadingStep * 100 / self.MaxLoadCount;
		self.spt:setPercentage(progress)
		--self.guang:setPosition( ccp(kGuangX + progress*7.2, kGuangY) )
		if self.loadingStep > self.MaxLoadCount then
			--for index = 1, #sfxSoundList do
			--	local name = "music/" .. sfxSoundList[index]
			--	SimpleAudioEngine:sharedEngine():preloadEffect(name)
			--end
			DcManager.sendLoadingActivity(50, ((os.time() - g_startTime )*1000) )
		    require "canon.GlobalScene"
			require "canon.data.ThirdPlatformLogin"
			if nil == loginScene then
				require "canon.scene.LoginScene"
			end
			
			local loginScene = LoginScene:create()
			Director:sharedDirector():replaceScene( loginScene )
		end
	end
end


function LoadingScene:Terminate_RunningGuide()
  if _G.Global_Guide_Already then
    Terminate_New_User_Guide()
    Terminate_All_ShowDialogBoxes()
    _G.Global_Guide_Already = nil
  end
end


local notificationList = {
	[1] = {id = 1, notiType = 1, hour = 12, minute = 0, text = getTextByKey("notificationSec1")},--吃桃1
	[2] = {id = 2, notiType = 1, hour = 18, minute = 0, text = getTextByKey("notificationSec1")},--吃桃2
	[3] = {id = 3, notiType = 1, hour = 19, minute = 55, text = getTextByKey("notificationSec2")},--抢亲
	[4] = {id = 4, notiType = 1, hour = 21, minute = 45, text = getTextByKey("notificationSec3")},--竞技场
	[5] = {id = 5, notiType = 2, time = 0, text = getTextByKey("notificationSec4")},--体力
	[6] = {id = 6, notiType = 2, time = 0, text = getTextByKey("notificationSec5")},--精力
	[7] = {id = 7, notiType = 3, time = 0, text = getTextByKey("notificationSec6")},--7天不玩提醒
	[8] = {id = 8, notiType = 4, notiWday = 2, hour = 13, minute = 0, text = getTextByKey("activity_mondayreward_notice1")}, --周一礼包
}

---the local notification count of ios is limited to 64, 
---so remember to cancel the notification of same id before add a new one
function cancelIosLocalNotification(id)
	local app = UIApplication:sharedApplication()
	local registerdNotifications = app:scheduledLocalNotifications()
	for i,v in ipairs(registerdNotifications) do
		local userInfo = v:userInfo()
		if userInfo and v:userInfo()["notifyId"] == tostring(id) then
			app:cancelLocalNotification(v)
			break
		end
	end
end

function getIosLocalNotification(id)
	local app = UIApplication:sharedApplication()
	local registerdNotifications = app:scheduledLocalNotifications()
	for i,v in ipairs(registerdNotifications) do
		local userInfo = v:userInfo()
		if userInfo and v:userInfo()["notifyId"] == tostring(id) then
			return v
		end
	end
	return nil
end

function registerIosLocalNotification(id, timeFromNow)
	local notiInfo = notificationList[id]
	if notiInfo.notiType == 1 then
    	local dateTable = os.date("*t", os.time())
   	    
	    iosLocalNotification:registerIosLocalNotification_notiType_timeFromNow_year_month_day_hour_minute_text(
	    	id,
	    	notiInfo.notiType,
	    	timeFromNow,
	    	dateTable.year,
	    	dateTable.month,
	    	dateTable.day,
	    	notiInfo.hour,
	    	notiInfo.minute,
	    	notiInfo.text
	    	)
	elseif notiInfo.notiType == 2 then
		iosLocalNotification:registerIosLocalNotification_notiType_timeFromNow_year_month_day_hour_minute_text(
			id,
	    	notiInfo.notiType,
	    	timeFromNow,
	    	0,
	    	0,
	    	0,
	    	0,
	    	0,
	    	notiInfo.text
	    	)
	elseif notiInfo.notiType == 3 then
	    local dateTable = os.date("*t", os.time() + 7*24*3600)
   	    iosLocalNotification:registerIosLocalNotification_notiType_timeFromNow_year_month_day_hour_minute_text(
   	    	id,
	    	notiInfo.notiType,
	    	timeFromNow,
	    	dateTable.year,
	    	dateTable.month,
	    	dateTable.day,
	    	20,
	    	0,
	    	notiInfo.text
	    	)
	elseif notiInfo.notiType == 4 then
		local curTime = os.time()
	    local dateTable = os.date("*t", curTime)
		--wday:sunday is 1,monday is 2...
		local wday = dateTable.wday
		local difday = (7 - (wday - notiInfo.notiWday)) % 7;
		local setTime = curTime + difday * 24 * 60 *60
		local setData = os.date("*t", setTime)
   	    iosLocalNotification:registerIosLocalNotification_notiType_timeFromNow_year_month_day_hour_minute_text(
   	    	id,
	    	notiInfo.notiType,
	    	timeFromNow,
	    	setData.year,
	    	setData.month,
	    	setData.day,
	    	notiInfo.hour,
	    	notiInfo.minute,
	    	notiInfo.text
	    	)
	end
end

function cancelAndroidLocalNotification(id)
    registerAndroidLocalNotification(id, nil,true)
end

function registerAndroidLocalNotification(id, timeFromNow, isCancelNoti)
    local notiInfo = notificationList[id]
	local notiWday = 2
    local notiHour = 0
    local notiMin = 0
    local timeZone = "Asia/Shanghai"
    local notiText = notiInfo.text
    if isCancelNoti == nil then
        isCancelNoti = false
    end

    local sysTimeZone = MetaInfo:getInstance():getTimeZone()
	if notiInfo.notiWday then
        notiWday = notiInfo.notiWday
    end
	
    if notiInfo.hour then
        notiHour = notiInfo.hour + (tonumber(sysTimeZone) - 8) --beijing is +8 timezone
    end
    
    if notiInfo.minute then
        notiMin = notiInfo.minute
    end
    
    --恢复时间单位为秒
    if timeFromNow == nil then
        timeFromNow = -1
        if id == 7 then
            timeFromNow = 7 * 24 * 3600
        end
    end
    CanonEnvInjector:registerLocalNotification(id, notiInfo.notiType, notiWday, notiHour, notiMin,timeFromNow,timeZone,notiText,isCancelNoti)
end

function cancelLocalNotification(id)
    if __IOS then
        cancelIosLocalNotification(id)
    elseif __ANDROID then
        cancelAndroidLocalNotification(id)
    end
end

function registerLocalNotification(id, timeFromNow)
    if __IOS then
        registerIosLocalNotification(id, timeFromNow)
    elseif __ANDROID then
        registerAndroidLocalNotification(id, timeFromNow)
    end
end

function LoadingScene:onInit()
  self:Terminate_RunningGuide() --如果正在运行新手引导，则要先将新手引导停止
  
	HeGameDefault:setFpsValue(30)
	self.CGAniminationFinish = true
	DcManager.sendLoadingActivity(10, ((os.time() - g_startTime )*1000) )
	local resCacheString = CCString:createWithContentsOfFile("resCache.txt");
	local _json = require("cjson")
	local resCacheTable = _json.decode(resCacheString:getCString())
	self.LoadPngList = resCacheTable["png"]
	self.LoadPlistList = resCacheTable["plist"]
	self.LoadFlashList = resCacheTable["flash"]
	self.MaxLoadCount = (#self.LoadPngList + #self.LoadPlistList + #self.LoadFlashList)

	self.loadState = 0
	
    if isAnzhiAndroid() then
		local s = Sprite:create("anzhi_logo.jpg")
		s:setPosition(ccp(visibleSize.width/2, visibleSize.height/2))
        self:addChild(s)
    else
        local bg = Sprite:create("logoBg.png")
        bg:setScale(10)
        bg:setPosition(ccp(visibleSize.width/2, visibleSize.height/2))
        self:addChild( bg)
	
        if isUCAndroid() then
        --add uc logo
            local uclog = Sprite:create("uc_logo.png")
            uclog:setAnchorPoint(ccp(1,1))
            uclog:setPosition(ccp(visibleSize.width, visibleSize.height))
            self:addChild( uclog)
        end
        local s
		--if isWdjAndroid() or isDKAndroid() or is91Android() then
		--	s = Sprite:create("logo_zhanji.png")
		--else
			s = Sprite:create("logo.png")
		--end
        s:setPosition(ccp(visibleSize.width/2-20, visibleSize.height/2+100))
        self:addChild(s)
    end
	
	
	function onPngLoadingFinish(name)
		if self.loadState == 2 then
			if self.loadingStep == (#self.LoadPngList) then
				  PngLoadingMgr:getInstance():unregisterEndLoadingScriptHandler()
			end
			self.loadingStep = self.loadingStep + 1
			self.isLoadingPng = false
		end
	end
	self.isLoadingPng = false;
	PngLoadingMgr:getInstance():registerEndLoadingScriptHandler(onPngLoadingFinish)

	--if __IOS then
		for i = 1, 4 do
			cancelLocalNotification(i)
			registerLocalNotification(i)
		end
		for i = 5, 6 do
			cancelLocalNotification(i)
		end
		cancelLocalNotification(7)
		registerLocalNotification(7)
		
		cancelLocalNotification(8)
		registerLocalNotification(8)
	--end
end
