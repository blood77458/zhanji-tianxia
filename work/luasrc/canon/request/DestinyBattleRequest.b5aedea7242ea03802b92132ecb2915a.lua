
require "canon.request.BaseRequest"

DestinyBattleRequest = class(BaseRequest)

function DestinyBattleRequest:ctor()
    self.endpoint = "destinyBattle"
end

function DestinyBattleRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.DestinyBattleSucceed,data))    
end

function DestinyBattleRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.DestinyBattleFailed,error))    
end


