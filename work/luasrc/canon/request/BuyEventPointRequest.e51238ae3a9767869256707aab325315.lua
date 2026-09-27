require "canon.request.BaseRequest"

--
-- BuyEventPointRequest
--

BuyEventPointRequest = class(BaseRequest)

function BuyEventPointRequest:ctor(params, priority)
    self.endpoint = "buyEventPoint"
end

function BuyEventPointRequest:onSuccess(data)
  --print("buyChallengeNum success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyEventPointSucceed, data))
end

function BuyEventPointRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyEventPointFailed, error))
end