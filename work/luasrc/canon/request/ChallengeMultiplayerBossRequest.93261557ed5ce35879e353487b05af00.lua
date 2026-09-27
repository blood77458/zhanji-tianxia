require "canon.request.BaseRequest"

--
-- ChallengeMultiplayerBossRequest
--

ChallengeMultiplayerBossRequest = class(BaseRequest)

function ChallengeMultiplayerBossRequest:ctor(params, priority)
    self.endpoint = "challengeMultiplayerBoss"
end

function ChallengeMultiplayerBossRequest:onSuccess(data)
  --print("challengeMultiplayerBoss success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeMultiplayerBossSucceed, data))
end

function ChallengeMultiplayerBossRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeMultiplayerBossFailed, {retCode = error}))
end