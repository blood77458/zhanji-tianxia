require "canon.request.BaseRequest"

--
-- GetLevelRaceInfoRequest
--

GetLevelRaceInfoRequest = class(BaseRequest)

function GetLevelRaceInfoRequest:ctor(params, priority)
    self.endpoint = "getLevelRaceInfo"
end

function GetLevelRaceInfoRequest:onSuccess(data)
  --print("getLevelRaceInfo success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetLevelRaceInfoSucceed, data))
end

function GetLevelRaceInfoRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetLevelRaceInfoFailed, {retCode = error}))
end