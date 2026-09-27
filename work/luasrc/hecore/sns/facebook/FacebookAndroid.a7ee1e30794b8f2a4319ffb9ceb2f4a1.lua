require "hecore.sns.SnsCallbackEvent"
require "hecore.utils"
require "hecore.luaJavaConvert"

FacebookAndroid = {}

local proxy = nil
local simplejson = require("hecore.simplejson")

local function buildError(errorCode,extra)
  return { errorCode = errorCode, msg = extra }
end

local function defaultResultParser(result)
  local tResult = luaJavaConvert.map2Table(result)
  return tResult
end

local function convertUserMap2Table(user)
  return luaJavaConvert.map2Table(user)
end

local function convertUserList2Table(users)
  local result = {}
    local ite = list:iterator()
    while ite:hasNext() do
      local v = ite:next()
      result[#result + 1] = _convertValue(v)
    end
    return result
end
    
local function buildCallback(callback,resultParser)
  
  local function onError(errorCode,extra)
    callback( SnsCallbackEvent.onError, buildError(errorCode,extra) )
  end

  local function onCancel()
    callback(SnsCallbackEvent.onCancel)
  end
  
  local function onSuccess(result)
    local tResult = nil
    if resultParser ~= nil then
      tResult = resultParser(result)
    end
    callback(SnsCallbackEvent.onSuccess,tResult or result)
  end
      
  return luajava.createProxy("com.happyelements.android.InvokeCallback",{
    onSuccess = onSuccess,
    onError = onError,
    onCancel = onCancel
  })
end

function FacebookAndroid:init(callback) 
  
  local initResultParser = function(result)
    he_log_info("------initResultParser---------")
    local tResult = luaJavaConvert.map2Table(result)
    return tResult
  end
    
  local initCallback = buildCallback(callback,initResultParser)
  if not proxy then
    proxy = luajava.newInstance("com.happyelements.android.sns.facebook.FacebookSDK","369628473180052",initCallback)
  else
    proxy:initSession(initCallback)
  end
  return true
end

function FacebookAndroid:login(callback)
  local loginCallback = buildCallback(callback,defaultResultParser)
  proxy:login(loginCallback)
end

function FacebookAndroid:isLogin()
  return proxy:isLogin()
end

function FacebookAndroid:isSessionStateLoaded()
  return proxy:isSessionStateLoaded()
end

function FacebookAndroid:getAccessToken()
  return proxy:getAccessToken()
end

function FacebookAndroid:logout( )
  proxy:logout()
  return true
end

--TODO no need callback
function FacebookAndroid:hasPermission(callback, permission)
  return proxy:hasPermission(permission)
end

function FacebookAndroid:userInfo(callback)
  local function userInfoParser(result)
    -- decode result is table
    return simplejson.decode(result)
  end
  local userInfoCallback = buildCallback(callback,userInfoParser)
  proxy:userInfo(userInfoCallback)
end

function FacebookAndroid:getAppFriends(callback)
  local function friendsParser(result)
    local tResult = {result = simplejson.decode(result)}
    return tResult
  end
  local friendsCallback = buildCallback(callback,friendsParser)
  proxy:getAppFriends(friendsCallback)
end 

function FacebookAndroid:getUserLocation(callback)
  local locationCallback = buildCallback(callback,defaultResultParser)
  proxy:getAppFriends(locationCallback)
end 

function FacebookAndroid:invite(callback,params)
  local inviteCallback = buildCallback(callback,defaultResultParser)
  local map = luaJavaConvert.table2Map(params)
  proxy:sendRequest(map,inviteCallback)
end

function FacebookAndroid:sendRequest(callback,params)
  local requestCallback = buildCallback(callback,defaultResultParser)
  local map = luaJavaConvert.table2Map(params)
  proxy:sendRequest(map,requestCallback)
end

function FacebookAndroid:presendBrag(callback,params)
  local presendBragCallback = buildCallback(callback,defaultResultParser)
  local map = luaJavaConvert.table2Map(params)
  proxy:brag(map,presendBragCallback)
end

function FacebookAndroid:presendFeed(callback,params)
  local presendFeedCallback = buildCallback(callback,defaultResultParser)
  local map = luaJavaConvert.table2Map(params)
  proxy:feed(map,presendFeedCallback)
end

function FacebookAndroid:publishStory(callback,params)
  local storyCallback = buildCallback(callback,defaultResultParser)
  local map = luaJavaConvert.table2Map(params)
  proxy:publishStory(map,storyCallback)
end

return FacebookAndroid