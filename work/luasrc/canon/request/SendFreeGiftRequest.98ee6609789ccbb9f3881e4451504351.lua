--------------------------------------------------------------------------------
-- SendFreeGiftRequest.lua - 向玩家发送免费礼物
-- author: xiaojie.bai
-- date: 2013-08-26 14:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SendFreeGiftRequest = class(BaseRequest)

function SendFreeGiftRequest:ctor()
  self.endpoint = METHOD_SENDFREEGIFT
end

function SendFreeGiftRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendFreeGiftSucceed, data))
end

function SendFreeGiftRequest:onError( error )
  --he_log_error(self.endpoint .. " fail: " .. table.serialize(error))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendFreeGiftFailed, error))
end