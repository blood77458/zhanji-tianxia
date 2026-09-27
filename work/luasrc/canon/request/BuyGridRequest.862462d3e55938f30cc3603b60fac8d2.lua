require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

BuyGridRequest = class(BaseRequest)

function BuyGridRequest:ctor()
  self.endpoint = METHOD_BUYGRID
end

function BuyGridRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyGridSucceed, data))
end

function BuyGridRequest:onError( error )
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyGridFailed, error))
end