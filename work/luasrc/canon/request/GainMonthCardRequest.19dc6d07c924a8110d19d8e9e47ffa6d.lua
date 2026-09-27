require "canon.request.BaseRequest"

--
-- GainMonthCardRequest
--

GainMonthCardRequest = class(BaseRequest)

function GainMonthCardRequest:ctor(params, priority)
    self.endpoint = "gainedMonthGemCardReward"
end

function GainMonthCardRequest:onSuccess(data)
  --print("gainedMonthGemCardReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMonthCardSucceed, data))
end

function GainMonthCardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainMonthCardFailed, {retCode = error}))
end