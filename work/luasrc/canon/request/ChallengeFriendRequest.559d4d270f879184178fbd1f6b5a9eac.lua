--------------------------------------------------------------------------------
-- ChallengeFriendRequest.lua - 与好友切磋请求
-- author: xiaojie.bai
-- date: 2013-09-10 15:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ChallengeFriendRequest = class(BaseRequest)

function ChallengeFriendRequest:ctor()
  self.endpoint = METHOD_CHALLENGEFRIEND
end

function ChallengeFriendRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeFriendSucceed, data))
end

function ChallengeFriendRequest:onError( error )
  --he_log_warn(self.endpoint .. " fail: " .. table.serialize(error))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeFriendFailed, error))
end