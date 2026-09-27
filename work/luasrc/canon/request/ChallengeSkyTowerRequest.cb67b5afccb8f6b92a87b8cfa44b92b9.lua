require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ChallengeSkyTowerRequest = class(BaseRequest)

function ChallengeSkyTowerRequest:ctor()
  self.endpoint = METHOD_CHALLENGESKYTOWER
end

function ChallengeSkyTowerRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeSkyTowerSucceed, data))
end

function ChallengeSkyTowerRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeSkyTowerFailed, error))
end