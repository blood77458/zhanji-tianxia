require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GainYesterdayAdditionRequest = class(BaseRequest)

function GainYesterdayAdditionRequest:ctor()
  self.endpoint = METHOD_GAINYESTERDAYADDITION
end

function GainYesterdayAdditionRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainYesterdayAdditionSucceed, data))
end

function GainYesterdayAdditionRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainYesterdayAdditionFailed, error))
end