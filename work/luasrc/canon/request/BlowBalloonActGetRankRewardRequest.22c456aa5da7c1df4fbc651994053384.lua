require "canon.request.BaseRequest"

BlowBalloonActGetRankRewardRequest = class(BaseRequest)

function BlowBalloonActGetRankRewardRequest:ctor()
    self.endpoint = "gainBalloonRankReward"
end

function BlowBalloonActGetRankRewardRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetRankRewardRequestSucceed,data))
end

function BlowBalloonActGetRankRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.BlowBalloonActGetRankRewardRequestFailed,error))
end