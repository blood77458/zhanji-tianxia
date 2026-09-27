require "canon.request.BaseRequest"

--
-- TriggerCoinEventRequest
--

TriggerCoinEventRequest = class(BaseRequest)

function TriggerCoinEventRequest:ctor(params, priority)
  self.endpoint = "triggerCoinEvent"
  self.delayLoading = true
  self.showLoading = true
  self.enableTouch = true
end

function TriggerCoinEventRequest:onSuccess(data)
  --print("triggerCoinEvent success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerCoinSucceed, data))
end

function TriggerCoinEventRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end