require "canon.request.BaseRequest"

--
-- TriggerCardEventRequest
--

TriggerCardEventRequest = class(BaseRequest)

function TriggerCardEventRequest:ctor(params, priority)
  self.endpoint = "triggerCardEvent"
  self.delayLoading = true
  self.showLoading = true
  self.enableTouch = true
end

function TriggerCardEventRequest:onSuccess(data)
  --print("triggerCardEvent success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerCardSucceed, data))
end

function TriggerCardEventRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end