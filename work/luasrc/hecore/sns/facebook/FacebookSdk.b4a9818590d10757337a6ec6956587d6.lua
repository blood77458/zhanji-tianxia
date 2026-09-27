FacebookSdk = {}

if __ANDROID then
	FacebookSdk.instance = require "hecore.sns.facebook.FacebookAndroid"
end

if __IOS then
	FacebookSdk.instance = require "hecore.sns.facebook.FacebookIOS"    
end

function FacebookSdk:init() 
	self.instance:init()
end

function FacebookSdk:login(callback)
  return self.instance:login(callback)
end
function FacebookSdk:logout()
    return self.instance:logout()
end
function FacebookSdk:getAccessToken()
    return self.instance:getAccessToken()
end
function FacebookSdk:isLogin()
    return self.instance:isLogin()
end

function FacebookSdk:userInfo( callback )
    return self.instance:userInfo( callback )
end

function FacebookSdk:getAppFriends( callback )
    return self.instance:getAppFriends( callback )
end

function FacebookSdk:hasPermission( callback, permission )
    return self.instance:hasPermission( callback, permission )
end

function FacebookSdk:getUserLocation(callback,params)
    return self.instance:getUserLocation( callback ,params)
end

function FacebookSdk:invite(callback,params)
    return self.instance:invite(callback,params)
end

function FacebookSdk:sendRequest(callback,params)
    return self.instance:sendRequest(callback,params)
end
--待定
function FacebookSdk:reciveRequest()
end
--待定
function FacebookSdk:getRequestString()
end

function FacebookSdk:presendBrag(callback,params)
    return self.instance:presendBrag(callback,params)
end

function FacebookSdk:presendFeed(callback,params)
    return self.instance:presendFeed(callback,params)
end

function FacebookSdk:publishStory(callback,params)
    self.instance:publishStory(callback,params)
end
