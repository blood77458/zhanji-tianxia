require "canon.request.BaseRequest"

--
-- ChallengeArenaRequest
--

ChallengeArenaRequest = class(BaseRequest)

function ChallengeArenaRequest:ctor(params, priority)
    self.endpoint = "challengeArena"
end

function ChallengeArenaRequest:onSuccess(data)
  --print("challengeArena success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeArenaSucceed, data))
end

function ChallengeArenaRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeArenaFailed, {retCode = error}))
end