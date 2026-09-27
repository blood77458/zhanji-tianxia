require "canon.request.BaseRequest"

--
-- BuyMissionCompleteCountRequest
--

BuyMissionCompleteCountRequest = class(BaseRequest)

function BuyMissionCompleteCountRequest:ctor(params, priority)
    self.endpoint = "buyMissionCompleteCount"
end

function BuyMissionCompleteCountRequest:onSuccess(data)
  --print("buyMissionCompleteCount success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyMissionCompleteCountSucceed, data))
end

function BuyMissionCompleteCountRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyMissionCompleteCountFailed, {retCode = error}))
end