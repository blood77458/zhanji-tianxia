require "canon.request.BaseRequest"

--
-- ClearMissionRequest
--

ClearMissionRequest = class(BaseRequest)

function ClearMissionRequest:ctor(params, priority)
    self.endpoint = "clearMission"
end

function ClearMissionRequest:onSuccess(data)
  --print("clearMission success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ClearMissionSucceed, data))
end

function ClearMissionRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ClearMissionFailed, {retCode = error}))
end