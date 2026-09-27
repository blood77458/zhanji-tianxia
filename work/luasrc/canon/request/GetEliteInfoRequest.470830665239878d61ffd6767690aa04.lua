--------------------------------------------------------------------------------
-- GetEliteInfoRequest.lua - 获取精英关卡信息
-- author: xiaojie.bai
-- date: 2013-09-26 19:56
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetEliteInfoRequest = class(BaseRequest)

function GetEliteInfoRequest:ctor()
  self.endpoint = METHOD_GETELITEINFO
end

function GetEliteInfoRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetEliteInfoSucceed, data))
end

function GetEliteInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetEliteInfoFailed, error))
end