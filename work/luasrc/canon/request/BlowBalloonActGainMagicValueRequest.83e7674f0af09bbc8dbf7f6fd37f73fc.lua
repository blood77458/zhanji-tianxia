require "canon.request.BaseRequest"

BlowBalloonActGainMagicValueRequest = class(BaseRequest)

function BlowBalloonActGainMagicValueRequest:ctor()
    self.endpoint = "gainBalloonPoint"
end

function BlowBalloonActGainMagicValueRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGainMagicValueRequestSucceed,data))
end

function BlowBalloonActGainMagicValueRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGainMagicValueRequestFailed,error))
end