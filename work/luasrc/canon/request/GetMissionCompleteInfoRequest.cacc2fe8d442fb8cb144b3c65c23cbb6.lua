require "canon.request.BaseRequest"

--
-- GetMissionCompleteInfoRequest
--

GetMissionCompleteInfoRequest = class(BaseRequest)

function GetMissionCompleteInfoRequest:ctor(params, priority)
    self.endpoint = "getMissionCompleteInfo"
end

function GetMissionCompleteInfoRequest:onSuccess(data)
  --print("getMissionCompleteInfo success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMissionCompleteInfoSucceed, data))
end

function GetMissionCompleteInfoRequest:onError(error)
  BaseRequest.onError(self, error)
end