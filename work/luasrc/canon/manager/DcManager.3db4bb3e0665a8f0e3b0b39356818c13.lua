--------------------------------------------------------------------------------
-- DcManager.lua -- 打点管理器
-- author: Jiang Yize
-- date: 2013-11-04
--------------------------------------------------------------------------------

DcManager = {}
local _userId = 12345
local _timeStamp = nil

local function isNewUser_DC()
  if CCUserDefault:sharedUserDefault():getIntegerForKey("isNewUser") == 0 then
    CCUserDefault:sharedUserDefault():setIntegerForKey("isNewUser", 1)
    return true
  else
    return false
  end
end

-- 3号点：新手引导完成
function DcManager.sendTutorialFinishActivity()
	local pixelStr = "" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
  HeDCLog:getInstance():send(3, {clientpixel = pixelStr})
end

-- 15号点：新手引导转化
-- paramStep：新手引导步数
function DcManager.sendTutorialStepActivity(paramStep)
	 local pixelStr = "" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
  local dict = {
	clientpixel = pixelStr,
    step = paramStep
  }
  HeDCLog:getInstance():send(15, dict)
end

-- 104号点：心跳在线
function DcManager.sendUserOnlineActivity(ee)
	local pixelStr = "" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
  local dict = {
	clientpixel = pixelStr,
    uniqid = MetaInfo:getInstance():getUdid(),
    networktype = "" .. MetaInfo:getInstance():getSimNetworkType(),
  }
  HeDCLog:getInstance():send(104, dict)
end

-- 打开104号点
function DcManager.openUserOnlineActivity()
  if not DcManager.onUserOnlineFunc then --心跳在线打点计时器
    DcManager.sendUserOnlineActivity()
    DcManager.onUserOnlineFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(DcManager.sendUserOnlineActivity, 300, false)
  end
end
function DcManager.closeUserOnlineActivity()
  if DcManager.onUserOnlineFunc then --移除心跳在线打点计时器
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(DcManager.onUserOnlineFunc)
    DcManager.onUserOnlineFunc = nil
  end
end

-- 5号点：加载转化
function DcManager.sendLoadingActivity(loadStep, timeMs, extraArg)
  if _timeStamp == nil then
    _timeStamp = MetaInfo:getInstance():getBeijingTimeStr()
  end

	g_viral_id = tostring(_userId) .."_".. _timeStamp

    local pixelStr = "" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
	local dict = {
		viral_id = g_viral_id ,
		install_key = MetaInfo:getInstance():getInstallKey(),
		step = loadStep,
		clientpixel = pixelStr,
		is_new = (isNewUser_DC() and 1 or 0),
		interval = timeMs
	}
  if extraArg ~= nil then
    for k,v in pairs(extraArg) do
      dict[k] = v
    end
  end

	HeDCLog:getInstance():send(5, dict)
end
-- 6号点：加载转化
function DcManager.sendOfficialPromoteInfo(uid, channelId, platform)
  local dict = {
    udid = MetaInfo:getInstance():getUdid(),
    _user_id = uid,
    install_key = MetaInfo:getInstance():getInstallKey(),
    channel_id = channelId,
    mac = MetaInfo:getInstance():getMacAddress(),
    serial_number = MetaInfo:getInstance():getSerialNumber(),
    android_id = MetaInfo:getInstance():getUdid(),
    platform = platform,
  }

  HeDCLog:getInstance():send(6, dict)
end
function DcManager.initDCPlatformInfo()
  require "canon.data.ThirdPlatformLogin"

  HeDCLog:getInstance():setStore(getPlatFormIgnoreDevice())
  HeDCLog:getInstance():setPlatform(getPlatFormIgnoreDevice())
end

function DcManager.setUserId( userId )
  _userId = userId
  HeGameDefault:setUserId(tostring(userId))
  --HeDCLog:getInstance():setUserID(tostring(userId)) -- HeGameDefault:setUserId会调用dc setuserid
end

function DcManager.refreshVipLevel()
  HeDCLog:getInstance():setVipLevel(tostring(DataManager.getCurrUser().vipLevel))
end

function DcManager.initDCServerInfo(server)
  HeDCLog:getInstance():setPartition("0")
  HeDCLog:getInstance():setServer(tostring(server))
end

-- 101号点：跨服军团战点击入口按钮
function DcManager.sendDCActionInfo(serverId,uid,level,time,des,detail)
  local pixelStr = "" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
  local dict = {
  time = time,
  clientpixel = pixelStr,
  timeZone=MetaInfo:getInstance():getTimeZone(),
  location=MetaInfo:getInstance():getCountry(),
  gameVersion=MetaInfo:getInstance():getApkVersion(),
  udid=MetaInfo:getInstance():getUdid(),
  clientType=MetaInfo:getInstance():getDeviceModel(),
  clientVersion=MetaInfo:getInstance():getOsVersion(),
  platform = getPlatFormIgnoreDevice(),
  server = serverId,
  _user_id = uid,
  level = level,
  idfa=PlatformMgr:getInstance():getIDFA(),
  ios_udid=PlatformMgr:getInstance():getDeviceId(),
  serial_number=MetaInfo:getInstance():getSerialNumber(),
  android_id= MetaInfo:getInstance():getUdid(),
  ip=MetaInfo:getInstance():getIpAddress(),
  language=MetaInfo:getInstance():getLanguage(),
  category = des,
  sub_category = detail,
  }
  HeDCLog:getInstance():send(101, dict)
end