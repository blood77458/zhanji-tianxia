require "canon.request.BaseRequest"

--
-- GainFortuneRewardsRequest
--

GainFortuneRewardsRequest = class(BaseRequest)

function GainFortuneRewardsRequest:ctor(params, priority)
    self.endpoint = "gainFortuneRewards"
end

function GainFortuneRewardsRequest:onSuccess(data)
  --print("gainFortuneRewards success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainFortuneRewardsSucceed, data))
end

function GainFortuneRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainFortuneRewardsFailed, {retCode = error}))
end