require "canon.request.BaseRequest"

--
-- GainMultiplayerBossRankRewardRequest
--

GainMultiplayerBossRankRewardRequest = class(BaseRequest)

function GainMultiplayerBossRankRewardRequest:ctor(params, priority)
    self.endpoint = "gainMultiplayerBossRankReward"
end

function GainMultiplayerBossRankRewardRequest:onSuccess(data)
  --print("gainMultiplayerBossRankReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMultiplayerBossRankRewardSucceed, data))
end

function GainMultiplayerBossRankRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMultiplayerBossRankRewardFailed, {retCode = error}))
end