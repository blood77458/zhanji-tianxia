--------------------------------------------------------------------------------
-- SendAllInvitationsRequest.lua - 发送全部邀请
-- author: xiaojie.bai
-- date: 2013-08-21 15:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SendAllInvitationsRequest = class(BaseRequest)

function SendAllInvitationsRequest:ctor()
  self.endpoint = METHOD_SENDALLINVITATIONS
end

function SendAllInvitationsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendAllInvitationsSucceed, data))
end

function SendAllInvitationsRequest:onError( error )
  BaseRequest.onError(self, error)
end