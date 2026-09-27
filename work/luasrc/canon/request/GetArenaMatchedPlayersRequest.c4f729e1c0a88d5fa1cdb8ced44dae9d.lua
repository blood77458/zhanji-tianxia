require "canon.request.BaseRequest"

--
-- GetArenaMatchedPlayersRequest
--

GetArenaMatchedPlayersRequest = class(BaseRequest)

function GetArenaMatchedPlayersRequest:ctor(params, priority)
    self.endpoint = "getArenaMatchedPlayers"
end

function GetArenaMatchedPlayersRequest:onSuccess(data)
  --print("getArenaMatchedPlayers success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetArenaMatchedPlayersSucceed, data))
end

function GetArenaMatchedPlayersRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetArenaMatchedPlayersFailed, {retCode = error}))
end