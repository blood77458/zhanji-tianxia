GetRecommendedFriendsRequest = class(BaseRequest)
--------------------------------------------------------------------------------
-- GetRecommendedFriendsRequest.lua - 获取推荐好友信息
-- author: xiaojie.bai
-- date: 2013-08-21 10:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetRecommendedFriendsRequest = class(BaseRequest)

function GetRecommendedFriendsRequest:ctor()
  self.endpoint = METHOD_GETRECOMMENDEDFRIENDS
end

function GetRecommendedFriendsRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetRecommendedFriendsSucceed, data))
end

function GetRecommendedFriendsRequest:onError( error )
  BaseRequest.onError(self, error)
end