require "canon.request.BaseRequest"

--
-- GetMultiplayerBossLeftHpRequest
--

GetMultiplayerBossLeftHpRequest = class(BaseRequest)

function GetMultiplayerBossLeftHpRequest:ctor(params, priority)
    self.endpoint = "getMultiplayerBossLeftHp"
end

function GetMultiplayerBossLeftHpRequest:onSuccess(data)
  --print("getMultiplayerBossLeftHp success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossLeftHpSucceed, data))
end

function GetMultiplayerBossLeftHpRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossLeftHpFailed, {retCode = error}))
end