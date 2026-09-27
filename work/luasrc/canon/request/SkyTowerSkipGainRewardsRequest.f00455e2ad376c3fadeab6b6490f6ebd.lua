require "canon.request.BaseRequest"

SkyTowerSkipGainRewardsRequest = class(BaseRequest)

function SkyTowerSkipGainRewardsRequest:ctor()
    self.endpoint = "gainSkipBattleRewards"
end

function SkyTowerSkipGainRewardsRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipGainRewardsSucceed,data))
end

function SkyTowerSkipGainRewardsRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SkyTowerSkipGainRewardsFailed,error))
end