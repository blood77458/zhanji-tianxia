require "canon.request.BaseRequest"

--
-- GetAccumulateGemsRequest
--

GetAccumulateGemsRequest = class(BaseRequest)

function GetAccumulateGemsRequest:ctor(params, priority)
    self.endpoint = "getAccumulateGems"
end

function GetAccumulateGemsRequest:onSuccess(data)
  --print("getArenaMatchedPlayers success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetAccumulateGemsSucceed, data))
end

function GetAccumulateGemsRequest:onError(error)
  BaseRequest.onError(self, error)
end