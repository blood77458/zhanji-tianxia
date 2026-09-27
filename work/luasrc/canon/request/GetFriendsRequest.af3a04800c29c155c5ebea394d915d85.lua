--------------------------------------------------------------------------------
-- GetFriendsRequest.lua - 获取当前玩家的好友信息
-- author: xiaojie.bai
-- date: 2013-07-30 11:00
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetFriendsRequest = class(BaseRequest)

function GetFriendsRequest:ctor()
  self.endpoint = METHOD_GETFRIENDS
end

function GetFriendsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetFriendsSucceed, data))
end

function GetFriendsRequest:onError( error )
  BaseRequest.onError(self, error)
end