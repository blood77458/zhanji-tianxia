require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

StartComposeBeast = class(BaseRequest)

function StartComposeBeast:ctor()
  self.endpoint = METHOD_STARTCOMPOSEBEAST
end

function StartComposeBeast:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.StartComposeBeastSucceed, data))
end

function StartComposeBeast:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.StartComposeBeastFailed, error))
end