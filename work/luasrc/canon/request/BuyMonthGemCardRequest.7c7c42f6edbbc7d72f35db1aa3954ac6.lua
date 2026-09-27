require "canon.request.BaseRequest"

--
-- BuyMonthGemCardRequest
--

BuyMonthGemCardRequest = class(BaseRequest)

function BuyMonthGemCardRequest:ctor(params, priority)
    self.endpoint = "buyMonthGemCard"
end

function BuyMonthGemCardRequest:onSuccess(data)
  --print("buyMonthGemCard success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyMonthGemCardSucceed, data))
end

function BuyMonthGemCardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyMonthGemCardFailed, {retCode = error}))
end