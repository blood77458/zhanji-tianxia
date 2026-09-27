--------------------------------------------------------------------------------
-- RefuseAllInvitationsRequest.lua - 拒绝所有玩家的好友邀请
-- author: xiaojie.bai
-- date: 2013-08-21 10:42
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

RefuseAllInvitationsRequest = class(BaseRequest)

function RefuseAllInvitationsRequest:ctor()
  self.endpoint = METHOD_REFUSEALLINVITATIONS
end

function RefuseAllInvitationsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.RefuseAllInvitationsSucceed, data))
end

function RefuseAllInvitationsRequest:onError( error )
  BaseRequest.onError(self, error)
end