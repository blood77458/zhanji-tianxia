--------------------------------------------------------------------------------
-- SellPropsRequest.lua - 出售道具的请求
-- author: fangzhou.long
-- date: 2013-08-22
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SellPropsRequest = class(BaseRequest)

function SellPropsRequest:ctor(params, priority)
	self.endpoint = "sellProps"
	self.data = nil
	self.params = params
	print(table.tostring(params))
end

function SellPropsRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SellPropSucceed , data ) )
end

function SellPropsRequest:onError(error)
  BaseRequest.onError(self, error)
end
