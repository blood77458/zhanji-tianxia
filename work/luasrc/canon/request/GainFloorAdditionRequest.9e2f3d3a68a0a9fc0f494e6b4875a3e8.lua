require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GainFloorAdditionRequest = class(BaseRequest)

function GainFloorAdditionRequest:ctor()
  self.endpoint = METHOD_GAINFLOORADDITION
end

function GainFloorAdditionRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainFloorAdditionSucceed, data))
end

function GainFloorAdditionRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainFloorAdditionFailed, error))
end