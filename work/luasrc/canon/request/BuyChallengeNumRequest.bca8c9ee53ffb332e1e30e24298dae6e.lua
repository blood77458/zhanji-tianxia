require "canon.request.BaseRequest"

--
-- BuyChallengeNumRequest
--

BuyChallengeNumRequest = class(BaseRequest)

function BuyChallengeNumRequest:ctor(params, priority)
    self.endpoint = "buyChallengeNum"
end

function BuyChallengeNumRequest:onSuccess(data)
  --print("buyChallengeNum success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyChallengeNumSucceed, data))
end

function BuyChallengeNumRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyChallengeNumFailed, {retCode = error}))
end