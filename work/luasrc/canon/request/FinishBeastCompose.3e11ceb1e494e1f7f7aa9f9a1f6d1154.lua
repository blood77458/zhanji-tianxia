require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

FinishBeastCompose = class(BaseRequest)

function FinishBeastCompose:ctor()
  self.endpoint = METHOD_FINISHBEASTCOMPOSE
end

function FinishBeastCompose:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FinishBeastComposeSucceed, data))
end

function FinishBeastCompose:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FinishBeastComposeFailed, error))
end