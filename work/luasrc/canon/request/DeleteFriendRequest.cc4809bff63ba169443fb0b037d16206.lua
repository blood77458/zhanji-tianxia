--------------------------------------------------------------------------------
-- DeleteFriendRequest.lua - 接受玩家的添加好友邀请
-- author: xiaojie.bai
-- date: 2013-08-22 9:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

DeleteFriendRequest = class(BaseRequest)

function DeleteFriendRequest:ctor()
  self.endpoint = METHOD_DELETEFRIEND
end

function DeleteFriendRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.DeleteFriendSucceed, data))
end

function DeleteFriendRequest:onError( error )
  BaseRequest.onError(self, error)
end