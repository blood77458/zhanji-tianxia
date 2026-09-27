require "canon.request.BaseRequest"

--
-- GainMultiplayerBossParticipationRewardRequest
--

GainMultiplayerBossParticipationRewardRequest = class(BaseRequest)

function GainMultiplayerBossParticipationRewardRequest:ctor(params, priority)
    self.endpoint = "gainMultiplayerBossParticipationReward"
end

function GainMultiplayerBossParticipationRewardRequest:onSuccess(data)
  --print("gainMultiplayerBossParticipationReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMultiplayerBossParticipationRewardSucceed, data))
end

function GainMultiplayerBossParticipationRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMultiplayerBossParticipationRewardFailed, {retCode = error}))
end