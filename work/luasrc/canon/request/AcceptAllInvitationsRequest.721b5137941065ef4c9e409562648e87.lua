--------------------------------------------------------------------------------
-- AcceptAllInvitationsRequest.lua - 接受所有玩家的好友邀请
-- author: xiaojie.bai
-- date: 2013-08-21 10:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

AcceptAllInvitationsRequest = class(BaseRequest)

function AcceptAllInvitationsRequest:ctor()
  self.endpoint = METHOD_ACCEPTALLINVITATIONS
end

function AcceptAllInvitationsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AcceptAllInvitationsSucceed, data))
end

function AcceptAllInvitationsRequest:onError( error )
  BaseRequest.onError(self, error)
end