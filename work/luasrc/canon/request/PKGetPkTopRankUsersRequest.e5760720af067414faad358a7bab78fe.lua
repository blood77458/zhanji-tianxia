--------------------------------------------------------------------------------
-- PKGetPkTopRankUsersRequest.lua - 比武请求排名信息
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKGetPkTopRankUsersRequest = class(BaseRequest)

function PKGetPkTopRankUsersRequest:ctor()
	self.endpoint = "getPkTopRankUsers"
end

function PKGetPkTopRankUsersRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkTopRankUsersSucceed, data))
end

function PKGetPkTopRankUsersRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGetPkTopRankUsersFailed, error))
end
