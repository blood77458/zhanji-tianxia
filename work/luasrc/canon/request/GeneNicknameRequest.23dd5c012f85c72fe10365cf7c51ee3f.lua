--------------------------------------------------------------------------------
-- GeneNicknameRequest.lua - 获取好友的详情
-- author: xiaojie.bai
-- date: 2013-11-07 15:40
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GeneNicknameRequest = class(BaseRequest)

function GeneNicknameRequest:ctor()
  self.endpoint = METHOD_GENENICKNAME
end

function GeneNicknameRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GeneNicknameSucceed, data))
end

function GeneNicknameRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GeneNicknameFailed, error))
end