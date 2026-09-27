require "canon.request.BaseRequest"

--
-- GetMultiplayerBossRankRequest
--

GetMultiplayerBossRankRequest = class(BaseRequest)

function GetMultiplayerBossRankRequest:ctor(params, priority)
    self.endpoint = "getMultiplayerBossRank"
end

function GetMultiplayerBossRankRequest:onSuccess(data)
  --print("getMultiplayerBossRank success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossRankSucceed, data))
end

function GetMultiplayerBossRankRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossRankFailed, {retCode = error}))
end