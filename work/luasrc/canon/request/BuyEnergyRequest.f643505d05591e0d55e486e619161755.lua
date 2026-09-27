require "canon.request.BaseRequest"

--
-- BuyEnergyRequest
--

BuyEnergyRequest = class(BaseRequest)

function BuyEnergyRequest:ctor(params, priority)
    self.endpoint = "buyEnergy"
end

function BuyEnergyRequest:onSuccess(data)
  --print("buyChallengeNum success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyEnergySucceed, data))
end

function BuyEnergyRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyEnergyFailed, error))
end