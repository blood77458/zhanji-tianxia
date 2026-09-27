require "canon.request.BaseRequest"

--
-- TriggerEmptyEventRequest
--

TriggerEmptyEventRequest = class(BaseRequest)

function TriggerEmptyEventRequest:ctor(params, priority)
    self.endpoint = "triggerEmptyEvent"
    self.delayLoading = true
    self.showLoading = true
    self.enableTouch = true
end

function TriggerEmptyEventRequest:onSuccess(data)
  --print("triggerEmptyEvent success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerEmptySucceed, data))
end

function TriggerEmptyEventRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end