--------------------------------------------------------------------------------
-- PKGetPkFoesRequest.lua - 比武请求仇人列表 
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKGetPkFoesRequest = class(BaseRequest)

function PKGetPkFoesRequest:ctor()
	self.endpoint = "getPkFoes"
end

function PKGetPkFoesRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkFoesSucceed, data))
end

function PKGetPkFoesRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkFoesFailed, error))
end
