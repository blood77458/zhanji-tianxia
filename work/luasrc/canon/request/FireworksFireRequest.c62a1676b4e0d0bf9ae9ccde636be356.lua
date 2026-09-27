--------------------------------------------------------------------------------
-- FireworksFireRequest.lua - 向玩家发送免费礼物
-- author: xiaojie.bai
-- date: 2013-08-26 14:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

FireworksFireRequest = class(BaseRequest)

function FireworksFireRequest:ctor()
  self.endpoint = "setoffFireworks"
end

function FireworksFireRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FireworksFireSucceed, data))
end

function FireworksFireRequest:onError( error )
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.FireworksFireFailed, error))
end