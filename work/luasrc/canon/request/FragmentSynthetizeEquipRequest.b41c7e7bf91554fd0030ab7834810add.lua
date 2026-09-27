--
-- FragmentSynthetizeEquipRequest 武器碎片合成
-- Author: czh
-- Date: 2014-02-17 21:20:16
--
require "canon.request.BaseRequest"

FragmentSynthetizeEquipRequest = class(BaseRequest)

function FragmentSynthetizeEquipRequest:ctor()
  self.endpoint = "synthetizeEquip"
end

function FragmentSynthetizeEquipRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeEquipSucceed, data))
end

function FragmentSynthetizeEquipRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeEquipFailed, error))
end