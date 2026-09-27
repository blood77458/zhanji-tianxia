require "canon.request.BaseRequest"

--
-- GainLevelRaceRewardsRequest
--

GainLevelRaceRewardsRequest = class(BaseRequest)

function GainLevelRaceRewardsRequest:ctor(params, priority)
    self.endpoint = "gainLevelRaceRewards"
end

function GainLevelRaceRewardsRequest:onSuccess(data)
  --print("gainLevelRaceRewards success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainLevelRaceRewardsSucceed, data))
end

function GainLevelRaceRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainLevelRaceRewardsFailed, {retCode = error}))
end