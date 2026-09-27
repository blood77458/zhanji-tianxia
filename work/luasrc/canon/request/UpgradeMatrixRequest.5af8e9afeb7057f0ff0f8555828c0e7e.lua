require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

UpgradeMatrixRequest = class(BaseRequest)

function UpgradeMatrixRequest:ctor()
  self.endpoint = METHOD_UPGRADEMATRIX
end

function UpgradeMatrixRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeMatrixSucceed, data))
end

function UpgradeMatrixRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeMatrixFailed, error))
end