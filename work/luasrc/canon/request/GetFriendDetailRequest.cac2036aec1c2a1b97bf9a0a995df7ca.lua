--------------------------------------------------------------------------------
-- GetFriendDetailRequest.lua - 获取好友的详情
-- author: xiaojie.bai
-- date: 2013-08-20 13:56
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetFriendDetailRequest = class(BaseRequest)

function GetFriendDetailRequest:ctor()
  self.endpoint = METHOD_GETFRIENDDETAIL
end

function GetFriendDetailRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetFriendDetailSucceed, data))
end

function GetFriendDetailRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetFriendDetailFailed, error))
end