--------------------------------------------------------------------------------
-- SellCardsRequest.lua - 出售装备的请求
-- author: fangzhou.long
-- date: 2013-08-22
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SellCardsRequest = class(BaseRequest)

function SellCardsRequest:ctor(params, priority)
	self.endpoint = "sellCards"
	self.data = nil
	self.params = params
end

function SellCardsRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SellCardsSucceed , data ) )
end

function SellCardsRequest:onError(error)
  BaseRequest.onError(self, error)
end
