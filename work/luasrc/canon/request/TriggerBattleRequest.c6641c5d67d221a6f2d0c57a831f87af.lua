require "canon.request.BaseRequest"

TriggerBattleRequest = class(BaseRequest)

function TriggerBattleRequest:ctor(params, priority)
  self.endpoint = "triggerBattleEvent"
  self.delayLoading = true
  self.showLoading = true
  self.enableTouch = true
end

function TriggerBattleRequest:onSuccess(data)
  --he_log_info("TriggerBattleRequest success " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.TriggerBattleSucceed,data))
end

function TriggerBattleRequest:onError(error)
	--BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.MapEventFailed, {retCode = error}))
end

