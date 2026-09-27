require "canon.request.BaseRequest"

--
-- GetBuyMonthCardResultRequest
--

GetBuyMonthCardResultRequest = class(BaseRequest)

function GetBuyMonthCardResultRequest:ctor(params, priority)
    self.endpoint = "getBuyMonthGemCardResult"
end

function GetBuyMonthCardResultRequest:onSuccess(data)
  --print("getBuyMonthGemCardResult success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetBuyMonthCardResultSucceed, data))
end

function GetBuyMonthCardResultRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetBuyMonthCardResultFailed, {retCode = error}))
end