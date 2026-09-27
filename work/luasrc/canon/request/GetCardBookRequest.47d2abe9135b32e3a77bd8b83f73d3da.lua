--------------------------------------------------------------------------------
-- GetCardBookRequest.lua - get cards illustrated info requeset
-- author: dang chao
-- date: 2013-09-18
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetCardBookRequest = class(BaseRequest)

function GetCardBookRequest:ctor(params, priority)
	self.endpoint = "getCardBook"
	self.data = nil
	self.params = params
end

function GetCardBookRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetCardBookSucceed , data ) )
end

function GetCardBookRequest:onError(error)
  BaseRequest.onError(self, error)
end
