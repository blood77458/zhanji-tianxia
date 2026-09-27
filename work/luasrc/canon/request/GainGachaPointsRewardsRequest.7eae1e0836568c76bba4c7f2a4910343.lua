require "canon.request.BaseRequest"

--
-- GainGachaPointsRewardsRequest
--

GainGachaPointsRewardsRequest = class(BaseRequest)

function GainGachaPointsRewardsRequest:ctor(params, priority)
    self.endpoint = "gainGachaPointsRewards"
end

function GainGachaPointsRewardsRequest:onSuccess(data)
  --print("gainGachaPointsRewards success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainGachaPointsRewardsSucceed, data))
end

function GainGachaPointsRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainGachaPointsRewardsFailed, {retCode = error}))
end