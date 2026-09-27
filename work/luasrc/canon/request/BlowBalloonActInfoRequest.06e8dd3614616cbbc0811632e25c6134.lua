require "canon.request.BaseRequest"

BlowBalloonActInfoRequest = class(BaseRequest)

function BlowBalloonActInfoRequest:ctor()
    self.endpoint = "getActivityBalloonInfo"
end

function BlowBalloonActInfoRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActInfoRequestSucceed,data))
end

function BlowBalloonActInfoRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActInfoRequestFailed,error))
end