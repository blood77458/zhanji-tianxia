require "canon.request.BaseRequest"

BlowBalloonActGetEnegyRequest = class(BaseRequest)

function BlowBalloonActGetEnegyRequest:ctor()
    self.endpoint = "chargeBalloon"
end

function BlowBalloonActGetEnegyRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetEnegyRequestSucceed,data))
end

function BlowBalloonActGetEnegyRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetEnegyRequestFailed,error))
end