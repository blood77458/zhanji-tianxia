require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

AvoidBattle = class(BaseRequest)

function AvoidBattle:ctor()
  self.endpoint = METHOD_AVOIDBATTLE
end

function AvoidBattle:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AvoidBattleSucceed, data))
end

function AvoidBattle:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.AvoidBattleFailed, error))
end