--------------------------------------------------------------------------------
-- GetFriends.lua - 获取当前玩家的好友信息
-- author: xiaojie.bai
-- date: 2013-07-30 11:00
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetInvitationFriendsRequest = class(BaseRequest)

function GetInvitationFriendsRequest:ctor()
  self.endpoint = METHOD_GETINVITATIONFRIENDS
end

function GetInvitationFriendsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetInvitationFriendsSucceed, data))
end

function GetInvitationFriendsRequest:onError( error )
  BaseRequest.onError(self, error)
end