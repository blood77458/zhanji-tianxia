require "canon.request.BaseRequest"

BlowBalloonActBuyEnegyRequest = class(BaseRequest)

function BlowBalloonActBuyEnegyRequest:ctor()
    self.endpoint = "buyEnergyStone"
end

function BlowBalloonActBuyEnegyRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActBuyEnegyRequestSucceed,data))
end

function BlowBalloonActBuyEnegyRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActBuyEnegyRequestFailed,error))
end