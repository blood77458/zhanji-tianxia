require "canon.request.BaseRequest"

SkyTowerSkipGainAddRequest = class(BaseRequest)

function SkyTowerSkipGainAddRequest:ctor()
    self.endpoint = "gainSkipBattleAddition"
end

function SkyTowerSkipGainAddRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipGainAddSucceed,data))
end

function SkyTowerSkipGainAddRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipGainAddFailed,error))
end