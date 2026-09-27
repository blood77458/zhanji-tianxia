require "canon.request.BaseRequest"

--
-- TriggerExpEventRequest
--

TriggerExpEventRequest = class(BaseRequest)

function TriggerExpEventRequest:ctor(params, priority)
    self.endpoint = "triggerExpEvent"
    self.delayLoading = true
    self.showLoading = true
    self.enableTouch = true
end

function TriggerExpEventRequest:onSuccess(data)
  --print("triggerExpEvent success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerExpSucceed, data))
end

function TriggerExpEventRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end