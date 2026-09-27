--------------------------------------------------------------------------------
-- PKChallengePkUserRequest.lua - 比武请求挑战 
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKChallengePkUserRequest = class(BaseRequest)

function PKChallengePkUserRequest:ctor()
	self.endpoint = "challengePkUser"
end

function PKChallengePkUserRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKChallengePkUserSucceed, data))
end

function PKChallengePkUserRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKChallengePkUserFailed, error))
end
