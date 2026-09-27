require "canon.request.BaseRequest"

--
-- GainGoldGodRewardsRequest
--

GainGoldGodRewardsRequest = class(BaseRequest)

function GainGoldGodRewardsRequest:ctor(params, priority)
    self.endpoint = "gainGoldGodRewards"
end

function GainGoldGodRewardsRequest:onSuccess(data)
  --print("gainGoldGodRewards success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainGoldGodRewardsSucceed, data))
end

function GainGoldGodRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainGoldGodRewardsFailed, {retCode = error}))
end