require "canon.request.BaseRequest"

--
-- GainRankFirstRewardRequest
--

GainRankFirstRewardRequest = class(BaseRequest)

function GainRankFirstRewardRequest:ctor(params, priority)
    self.endpoint = "gainRankFirstReward"
end

function GainRankFirstRewardRequest:onSuccess(data)
  --print("gainRankFirstReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainRankFirstRewardSucceed, data))
end

function GainRankFirstRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainRankFirstRewardFailed, {retCode = error}))
end