--------------------------------------------------------------------------------
-- PKGainPkBuffRequest.lua - 比武请求武神祝福 
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKGainPkBuffRequest = class(BaseRequest)

function PKGainPkBuffRequest:ctor()
	self.endpoint = "gainPkBuff"
end

function PKGainPkBuffRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGainPkBuffSucceed, data))
end

function PKGainPkBuffRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGainPkBuffFailed, error))
end
