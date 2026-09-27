require "canon.request.BaseRequest"

BlowBalloonActGetMagicRewardRequest = class(BaseRequest)

function BlowBalloonActGetMagicRewardRequest:ctor()
    self.endpoint = "gainBalloonPointReward"
end

function BlowBalloonActGetMagicRewardRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestSucceed,data))
end

function BlowBalloonActGetMagicRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetMagicRewardRequestFailed,error))
end