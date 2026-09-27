require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

AdjustBeast = class(BaseRequest)

function AdjustBeast:ctor()
  self.endpoint = METHOD_ADJUSTBEAST
end

function AdjustBeast:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AdjustBeastSucceed, data))
end

function AdjustBeast:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.AdjustBeastFailed, error))
end