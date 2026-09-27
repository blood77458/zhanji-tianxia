--------------------------------------------------------------------------------
-- RefuseInvitationRequest.lua - 拒绝玩家的添加好友邀请
-- author: xiaojie.bai
-- date: 2013-08-20 19:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

RefuseInvitationRequest = class(BaseRequest)

function RefuseInvitationRequest:ctor()
  self.endpoint = METHOD_REFUSEINVITATION
end

function RefuseInvitationRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.RefuseInvitationSucceed, data))
end

function RefuseInvitationRequest:onError( error )
  BaseRequest.onError(self, error)
end