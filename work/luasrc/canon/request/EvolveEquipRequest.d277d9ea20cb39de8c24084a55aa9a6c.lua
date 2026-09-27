require "canon.request.BaseRequest"

--
-- EvolveEquipRequest
--

EvolveEquipRequest = class(BaseRequest)

function EvolveEquipRequest:ctor(params, priority)
    self.endpoint = "evolveEquip"
end

function EvolveEquipRequest:onSuccess(data)
  --print("evolveEquip success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.EvolveEquipSucceed, data))
end

function EvolveEquipRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.EvolveEquipFailed, {retCode = error}))
end