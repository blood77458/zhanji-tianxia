require "canon.request.BaseRequest"

--
-- TriggerRandomEventRequest
--

TriggerRandomEventRequest = class(BaseRequest)

function TriggerRandomEventRequest:ctor(params, priority)
    self.endpoint = "triggerRandomEvent"
    self.delayLoading = true
    self.showLoading = true
    self.enableTouch = true
end

function TriggerRandomEventRequest:onSuccess(data)
  --print("triggerRandomEvent success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerRandomSucceed, data))
end

function TriggerRandomEventRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end