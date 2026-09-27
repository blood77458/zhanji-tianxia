--------------------------------------------------------------------------------
-- SetupEquipRequest.lua - 更换装备的请求
-- author: fangzhou.long
-- date: 2013-08-22
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SetupEquipRequest = class(BaseRequest)

function SetupEquipRequest:ctor(params, priority)
	self.endpoint = "setupEquip"
	self.data = nil
	self.params = params
end

function SetupEquipRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SetupEquipSucceed , data ) )
end

function SetupEquipRequest:onError(error)
  BaseRequest.onError(self, error)
end
