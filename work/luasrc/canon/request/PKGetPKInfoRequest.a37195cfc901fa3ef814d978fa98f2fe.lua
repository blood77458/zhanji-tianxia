--------------------------------------------------------------------------------
-- PKGetPKInfoRequest.lua - 比武请求基础信息
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKGetPKInfoRequest = class(BaseRequest)

function PKGetPKInfoRequest:ctor()
	self.endpoint = "getPkInfo"
end

function PKGetPKInfoRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkInfoSucceed, data))
end

function PKGetPKInfoRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkInfoFailed, error))
end
