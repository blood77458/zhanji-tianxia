--------------------------------------------------------------------------------
-- SellEquipsRequest.lua - 出售装备的请求
-- author: fangzhou.long
-- date: 2013-08-22
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SellEquipsRequest = class(BaseRequest)

function SellEquipsRequest:ctor(params, priority)
	self.endpoint = "sellEquips"
	self.data = nil
	self.params = params
end

function SellEquipsRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SellEquipsSucceed , data ) )
end

function SellEquipsRequest:onError(error)
  BaseRequest.onError(self, error)
end
