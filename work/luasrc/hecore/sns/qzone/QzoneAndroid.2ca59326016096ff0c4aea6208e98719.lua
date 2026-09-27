require "hecore.sns.SnsCallbackEvent"
require "hecore.utils"
require "hecore.luaJavaConvert"

QzoneAndroid = {}

local proxy = nil

local function buildError(errorCode,extra)
  return { errorCode = errorCode, msg = extra }
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


function QzoneAndroid:init()
  if not proxy then
    proxy = luajava.newInstance("com.happyelements.android.sns.qzone.QzoneSdk",StartupConfig:getInstance():getQzoneAppId())
  end
  return true
end

function QzoneAndroid:setOpenId(openId)
  proxy:setOpenId(openId)
end

function QzoneAndroid:setAccessToken(accessToken,expiresIn)
  proxy:setAccessToken(accessToken,expiresIn)
end


function QzoneAndroid:login(callback)
  local resultParser = function(result)
    local tResult = luaJavaConvert.map2Table(result)
    return tResult
  end
  loginCallback = buildCallback(callback,resultParser)
  proxy:login(loginCallback)
end

function QzoneAndroid:logout()
  proxy:logout()
end

function QzoneAndroid:isLogin()
  return proxy:isLogin()
end

function QzoneAndroid:invite(callback,params)
  if params.picurl == nil  then 
    callback(SnsCallbackEvent.onError, buildError(-1,"invite params invalid,picurl can not be nil!") )
    return
  end
  
  if params.desc == nil then
    callback(SnsCallbackEvent.onError,buildError(-1,"invite params invalid,desc can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)
  proxy:invite( buildCallback(callback,nil), map)
end

function QzoneAndroid:sendStory(callback,params)
  if params.title == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"sendStory params invalid,title can not be nil!") )
    return
  end
  
  if params.pics == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"sendStory params invalid,pics can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)
  proxy:sendStory( buildCallback(callback,nil), map)
end

function QzoneAndroid:getAppFriends(callback)
  local friendsCallback = buildCallback(callback,nil)
  proxy:getAppFriends(friendsCallback)
end

function QzoneAndroid:getUserInfo(callback)
  local resultParser = function(result)
    local tResult = luaJavaConvert.map2Table(result)
    return tResult
  end
  local userInfoCallback = buildCallback(callback,resultParser)
  proxy:getSimpleUserInfo(userInfoCallback)
end

function QzoneAndroid:addTopic(callback,params)
  if params.con == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"addTopic params invalid,con can not be nil!") )
    return
  end

  local map = luaJavaConvert.table2Map(params)
  
  local resultParser = function(result)
    local tResult = luaJavaConvert.map2Table(result)
    return tResult
  end
  
  local topicCallback = buildCallback(callback,resultParser)
  proxy:addTopic(topicCallback,map)
end

function QzoneAndroid:ask(callback,params)
  if params.receiver == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"ask params invalid,receiver can not be nil!") )
    return
  end

  if params.title == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"ask params invalid,title can not be nil!") )
    return
  end
  
  if params.msg == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"ask params invalid,msg can not be nil!") )
    return
  end
  
  if params.img == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"ask params invalid,img can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)
  
  local askCallback = buildCallback(callback,nil)
  proxy:ask(askCallback,map)
end

function QzoneAndroid:reAuth(callback,scope)
  local reAuthCallback = buildCallback(callback,nil)
  proxy:reAuth(reAuthCallback,scope)
end

function QzoneAndroid:gift(callback,params)
  if params.receiver == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"gift params invalid,receiver can not be nil!") )
    return
  end

  if params.title == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"gift params invalid,title can not be nil!") )
    return
  end
  
  if params.msg == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"gift params invalid,msg can not be nil!") )
    return
  end
  
  if params.img == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"gift params invalid,img can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)

  local giftCallback = buildCallback(callback,nil)
  proxy:gift(giftCallback,map)
end

function QzoneAndroid:challenge(callback,params)
  if params.receiver == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"challenge params invalid,receiver can not be nil!") )
    return
  end

  if params.msg == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"challenge params invalid,msg can not be nil!") )
    return
  end
  
  if params.img == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"challenge params invalid,img can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)

  local challengeCallback = buildCallback(callback,nil)
  proxy:challenge(challengeCallback,map)
end

function QzoneAndroid:brag(callback,params)
  if params.receiver == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"brag params invalid,receiver can not be nil!") )
    return
  end

  if params.msg == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"brag params invalid,msg can not be nil!") )
    return
  end
  
  if params.img == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"brag params invalid,img can not be nil!") )
    return
  end
  
  local map = luaJavaConvert.table2Map(params)

  local bragCallback = buildCallback(callback,nil)
  proxy:brag(bragCallback,map)
end

function QzoneAndroid:shareToQQ(callback,params)
  if params.targetUrl == nil then 
    callback(SnsCallbackEvent.onError, buildError(-1,"shareToQQ params invalid,targetUrl can not be nil!") )
    return
  end

  local map = luaJavaConvert.table2Map(params)

  local shareToQQCallback = buildCallback(callback,nil)
  proxy:shareToQQ(shareToQQCallback,map)
end

return QzoneAndroid
