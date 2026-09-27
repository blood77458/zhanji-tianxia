--------------------------------------------------------------------------------
-- ResetEliteRequest.lua - 重置精英关卡信息
-- author: xiaojie.bai
-- date: 2013-09-26 20:26
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ResetEliteRequest = class(BaseRequest)

function ResetEliteRequest:ctor()
  self.endpoint = METHOD_RESETELITE
end

function ResetEliteRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetEliteSucceed, data))
end

function ResetEliteRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetEliteFailed, error))
end