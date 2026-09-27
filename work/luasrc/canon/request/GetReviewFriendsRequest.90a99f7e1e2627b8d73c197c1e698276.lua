--------------------------------------------------------------------------------
-- GetReviewFriendsRequest.lua - 获取等待玩家审核的用户请求列表
-- author: xiaojie.bai
-- date: 2013-08-19 16:47
--------------------------------------------------------------------------------

GetReviewFriendsRequest = class

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetReviewFriendsRequest = class(BaseRequest)

function GetReviewFriendsRequest:ctor()
  self.endpoint = METHOD_GETREVIEWFRIENDS
end

function GetReviewFriendsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetReviewFriendsSucceed, data))
end

function GetReviewFriendsRequest:onError( error )
  BaseRequest.onError(self, error)
end