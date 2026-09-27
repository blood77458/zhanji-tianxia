require "canon.request.BaseRequest"

--
-- GetGachaPointsInfoRequest
--

GetGachaPointsInfoRequest = class(BaseRequest)

function GetGachaPointsInfoRequest:ctor(params, priority)
    self.endpoint = "getGachaPointsInfo"
end

function GetGachaPointsInfoRequest:onSuccess(data)
  --print("getGachaPointsInfo success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetGachaPointsInfoSucceed, data))
end

function GetGachaPointsInfoRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetGachaPointsInfoFailed, {retCode = error}))
end