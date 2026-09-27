--------------------------------------------------------------------------------
-- SendAllFreeGiftRequest.lua - 向玩家发送免费礼物
-- author: xiaojie.bai
-- date: 2013-08-26 14:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SendAllFreeGiftRequest = class(BaseRequest)

function SendAllFreeGiftRequest:ctor()
  self.endpoint = METHOD_SENDALLFREEGIFT
end

function SendAllFreeGiftRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendAllFreeGiftSucceed, data))
end

function SendAllFreeGiftRequest:onError( error )
  --BaseRequest.onError(self, error)
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendAllFreeGiftFailed, error))
end