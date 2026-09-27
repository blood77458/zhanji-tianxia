require "canon.request.BaseRequest"

--
-- ActiveRewardRequest
--

ActiveRewardRequest = class(BaseRequest)

function ActiveRewardRequest:ctor(params, priority)
    self.endpoint = "gainActiveReward"
end

function ActiveRewardRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ActiveRewardSucceed, data))
end

function ActiveRewardRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ActiveRewardFailed, {retCode = error}))
end