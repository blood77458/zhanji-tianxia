require "canon.request.BaseRequest"

--
-- UpgradeEquipRequest
--

UpgradeEquipRequest = class(BaseRequest)

function UpgradeEquipRequest:ctor(params, priority)
    self.endpoint = "upgradeEquip"
end

function UpgradeEquipRequest:onSuccess(data)
  --print("upgradeEquip success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeEquipSucceed, data))
end

function UpgradeEquipRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeEquipFailed, {retCode = error}))
end