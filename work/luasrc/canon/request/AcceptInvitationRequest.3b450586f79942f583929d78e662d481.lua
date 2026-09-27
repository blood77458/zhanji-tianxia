--------------------------------------------------------------------------------
-- AcceptInvitationRequest.lua - 接受玩家的添加好友邀请
-- author: xiaojie.bai
-- date: 2013-08-20 19:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

AcceptInvitationRequest = class(BaseRequest)

function AcceptInvitationRequest:ctor()
  self.endpoint = METHOD_ACCEPTINVITATION
end

function AcceptInvitationRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AcceptInvitationSucceed, data))
end

function AcceptInvitationRequest:onError( error )
  --BaseRequest.onError(self, error)
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AcceptInvitationFailed, error))
end