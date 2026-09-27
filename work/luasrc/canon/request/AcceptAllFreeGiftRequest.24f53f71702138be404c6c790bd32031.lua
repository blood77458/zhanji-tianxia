--------------------------------------------------------------------------------
-- SendAllFreeGiftRequest.lua - 向玩家发送免费礼物
-- author: xiaojie.bai
-- date: 2013-08-26 14:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

AcceptAllFreeGiftRequest = class(BaseRequest)

function AcceptAllFreeGiftRequest:ctor()
  self.endpoint = METHOD_ACCEPTALLFREEGIFT
end

function AcceptAllFreeGiftRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.AcceptAllFreeGiftSucceed, data))
end

function AcceptAllFreeGiftRequest:onError( error )
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.AcceptAllFreeGiftFailed, error))
end