
require "canon.request.BaseRequest"

GainRechargeReward = class(BaseRequest)

function GainRechargeReward:ctor()
    self.endpoint = "gainAccumulateRechargeReward"
end

function GainRechargeReward:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainRechargeRewardSucceed,data))
end

function GainRechargeReward:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainRechargeRewardFailed,error))
end