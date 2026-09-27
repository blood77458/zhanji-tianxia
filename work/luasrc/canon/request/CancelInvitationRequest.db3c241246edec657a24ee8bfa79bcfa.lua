CancelInvitationRequest = class(BaseRequest)

--------------------------------------------------------------------------------
-- CancelInvitationRequest.lua - 接受玩家的添加好友邀请
-- author: xiaojie.bai
-- date: 2013-08-20 19:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

CancelInvitationRequest = class(BaseRequest)

function CancelInvitationRequest:ctor()
  self.endpoint = METHOD_CANCELINVITATION
end

function CancelInvitationRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.CancelInvitationSucceed, data))
end

function CancelInvitationRequest:onError( error )
  BaseRequest.onError(self, error)
end