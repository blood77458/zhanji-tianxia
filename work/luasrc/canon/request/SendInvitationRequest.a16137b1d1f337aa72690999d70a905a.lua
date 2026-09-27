--------------------------------------------------------------------------------
-- SendInvitationRequest.lua - 发送邀请
-- author: xiaojie.bai
-- date: 2013-08-21 15:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SendInvitationRequest = class(BaseRequest)

function SendInvitationRequest:ctor()
  self.endpoint = METHOD_SENDINVITATION
end

function SendInvitationRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendInvitationSucceed, data))
end

function SendInvitationRequest:onError( error )
  --BaseRequest.onError(self, error)
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendInvitationFailed, error))
end