require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ResetClimbTowerRequest = class(BaseRequest)

function ResetClimbTowerRequest:ctor()
  self.endpoint = METHOD_RESETCLIMBTOWERDATA
end

function ResetClimbTowerRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetClimbTowerSucceed, data))
end

function ResetClimbTowerRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetClimbTowerFailed, error))
end