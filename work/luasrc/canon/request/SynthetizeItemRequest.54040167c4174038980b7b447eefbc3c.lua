require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SynthetizeItemRequest = class(BaseRequest)

function SynthetizeItemRequest:ctor()
  self.endpoint = METHOD_SYNTHETIZEITEM
end

function SynthetizeItemRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SynthetizeItemSucceed, data))
end

function SynthetizeItemRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SynthetizeItemFailed, error))
end