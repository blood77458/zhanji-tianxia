require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GainRankRewardsRequest = class(BaseRequest)

function GainRankRewardsRequest:ctor()
  self.endpoint = METHOD_GAINRANKREWARDS
end

function GainRankRewardsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainRankRewardsSucceed, data))
end

function GainRankRewardsRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainRankRewardsFailed, error))
end