
QzoneSdk = {
  
}

if __ANDROID then
QzoneSdk.instance = require("hecore.sns.qzone.QzoneAndroid")
end

function QzoneSdk:init()
  if self.instance == nil then
    return false
  end
  return self.instance:init()
end

function QzoneSdk:login(callback)
  return self.instance:login(callback)
end

function QzoneSdk:isLogin()
  return self.instance:isLogin()
end

function QzoneSdk:logout()
  return self.instance:logout()
end

function QzoneSdk:setOpenId(openId)
  self.instance:setOpenId(openId)
end

function QzoneSdk:setAccessToken(accessToken,expiresIn)
  self.instance:setAccessToken(accessToken,expiresIn)
end

function QzoneSdk:invite(callback,params)
  self.instance:invite(callback,params)
end

function QzoneSdk:sendStory(callback,params)
  self.instance:sendStory(callback,params)
end

function QzoneSdk:getAppFriends(callback)
  self.instance:getAppFriends(callback)
end

function QzoneSdk:getUserInfo(callback)
  self.instance:getUserInfo(callback)
end

function QzoneSdk:addTopic(callback,params)
  self.instance:addTopic(callback,params)
end

function QzoneSdk:ask(callback,params)
  self.instance:ask(callback,params)
end

function QzoneSdk:reAuth(callback,scope)
  self.instance:reAuth(callback,scope)
end

function QzoneSdk:gift(callback,params)
  self.instance:gift(callback,params)
end

function QzoneSdk:challenge(callback,params)
  self.instance:challenge(callback,params)
end

function QzoneSdk:brag(callback,params)
  self.instance:brag(callback,params)
end

function QzoneSdk:shareToQQ(callback,params)
  self.instance:shareToQQ(callback,params)
end
