--------------------------------------------------------------------------------
-- CanonEnvInjector.lua - andriod平台设置系统环境信息(userId)
-- author: xiaojie.bai
-- date: 2013-10-23 11:00
--------------------------------------------------------------------------------
local CanonEnvInjectorAndroid = {}

function CanonEnvInjectorAndroid:init()
  he_log_info("CanonEnvInjectorAndroid:init()")
  self.instance = luajava.bindClass("com.happyelements.arda.CanonEnvInjector"):getInstance()
  
  he_log_info("CanonEnvInjectorAndroid:init() succ")
end

function CanonEnvInjectorAndroid:setGspGameUserId(uid)
  if(not self.instance) then
    self:init()
  end
  he_log_info("setGspGameUserId:" .. uid)
  self.instance:setGspGameUserId(uid)
end

------
-- show custom dialog
------
function CanonEnvInjectorAndroid:callJira()
  if(not self.instance) then
    self:init()
  end

  self.instance:callJira()
end

function CanonEnvInjectorAndroid:getAndroidPackageName()
  if(not self.instance) then
    self:init()
  end
  
  return self.instance:getCurPackageName()
end

function CanonEnvInjectorAndroid:isNetworkAvailable()
  if(not self.instance) then
    self:init()
  end
  
  return self.instance:isNetworkAvailable()
end

function CanonEnvInjectorAndroid:getStrMd5(oldStr)
  if(not self.instance) then
    self:init()
  end
  
  return self.instance:getStrMd5(oldStr)
end

function CanonEnvInjectorAndroid:openURL( url )
  -- body
  if(not self.instance) then
    self:init()
  end
  self.instance:openURL(url)
end

function CanonEnvInjectorAndroid:copyStringToClipboard(str)
  if(not self.instance) then
    self:init()
  end
  self.instance:copyStringToClipboard(str)
end

function CanonEnvInjectorAndroid:registerLocalNotification(notiId, notiType, notiWday, notiHour, notiMin,timeFromNow,timeZone,notiText,isCancelNoti)
  if(not self.instance) then
    self:init()
  end
  self.instance:registerLocalNotification(notiId, notiType, notiWday, notiHour, notiMin,timeFromNow,timeZone,notiText,isCancelNoti)
end

function CanonEnvInjectorAndroid:judgeCurAndroidMobileProvider()
  if(not self.instance) then
    self:init()
  end  
  return self.instance:judgeCurAndroidMobileProvider()
end

function CanonEnvInjectorAndroid:isAndroidEmulator()
  if(not self.instance) then
    self:init()
  end
  if self.instance:isAndroidEmulator() then
	return "1"
  else
	return "0"
  end
end

local CanonEnvInjectorIOS = {}

function CanonEnvInjectorIOS:isNetworkAvailable()
  return true
end

CanonEnvInjector = nil

if __ANDROID then
  CanonEnvInjector = CanonEnvInjectorAndroid
elseif __IOS then
  CanonEnvInjector = CanonEnvInjectorIOS
else
  CanonEnvInjector = {}
end
