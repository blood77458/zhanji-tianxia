require "canon.request.BaseRequest"

--
-- GainNewYearRewardsRequest
--

GainNewYearRewardsRequest = class(BaseRequest)

function GainNewYearRewardsRequest:ctor(params, priority)
    self.endpoint = "gainNewYearRewards"
end

function GainNewYearRewardsRequest:onSuccess(data)
  --print("gainNewYearRewards success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainNewYearRewardsSucceed, data))
end

function GainNewYearRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainNewYearRewardsFailed, {retCode = error}))
end