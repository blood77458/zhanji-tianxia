require "canon.request.BaseRequest"

--
-- GetMultiplayerBossDamageRequest
--

GetMultiplayerBossDamageRequest = class(BaseRequest)

function GetMultiplayerBossDamageRequest:ctor(params, priority)
    self.endpoint = "getMultiplayerBossDamage"
end

function GetMultiplayerBossDamageRequest:onSuccess(data)
  --print("getMultiplayerBossDamage success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossDamageSucceed, data))
end

function GetMultiplayerBossDamageRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayerBossDamageFailed, {retCode = error}))
end