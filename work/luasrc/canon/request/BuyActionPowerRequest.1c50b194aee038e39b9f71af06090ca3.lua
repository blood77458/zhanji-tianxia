require "canon.request.BaseRequest"

--
-- BuyActionPowerRequest
--

BuyActionPowerRequest = class(BaseRequest)

function BuyActionPowerRequest:ctor(params, priority)
    self.endpoint = "buyActionPower"
end

function BuyActionPowerRequest:onSuccess(data)
  --print("buyActionPower success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyActionPowerSucceed, data))
end

function BuyActionPowerRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyActionPowerFailed, {retCode = error}))
end