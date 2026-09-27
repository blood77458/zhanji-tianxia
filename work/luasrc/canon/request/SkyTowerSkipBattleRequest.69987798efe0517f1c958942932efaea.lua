require "canon.request.BaseRequest"

SkyTowerSkipBattleRequest = class(BaseRequest)

function SkyTowerSkipBattleRequest:ctor()
    self.endpoint = "skipSkyTowerBattle"
end

function SkyTowerSkipBattleRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipBattleSucceed,data))
end

function SkyTowerSkipBattleRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipBattleFailed,error))
end