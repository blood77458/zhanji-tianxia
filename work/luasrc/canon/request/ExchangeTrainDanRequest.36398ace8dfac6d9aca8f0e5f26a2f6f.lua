require "canon.request.BaseRequest"

--
-- ExchangeTrainDanRequest
--

ExchangeTrainDanRequest = class(BaseRequest)

function ExchangeTrainDanRequest:ctor(params, priority)
    self.endpoint = "exchangeTrainDanByArenaScore"
end

function ExchangeTrainDanRequest:onSuccess(data)
  --print("exchangeTrainDanByArenaScore success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ExchangeTrainDanSucceed, data))
end

function ExchangeTrainDanRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ExchangeTrainDanFailed, {retCode = error}))
end
