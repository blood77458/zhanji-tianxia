require "canon.request.BaseRequest"

--
-- QuickUpgradeEquipRequest
--

QuickUpgradeEquipRequest = class(BaseRequest)

function QuickUpgradeEquipRequest:ctor(params, priority)
    self.endpoint = "quickUpgradeEquip"
end

function QuickUpgradeEquipRequest:onSuccess(data)
  print("quickUpgradeEquip success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.QuickUpgradeEquipSucceed, data))
end

function QuickUpgradeEquipRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.QuickUpgradeEquipFailed, {retCode = error}))
end