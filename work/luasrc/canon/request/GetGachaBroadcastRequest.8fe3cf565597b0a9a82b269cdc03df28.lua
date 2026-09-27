require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetGachaBroadcastRequest = class(BaseRequest)

function GetGachaBroadcastRequest:ctor()
  self.endpoint = METHOD_GETGACHABROADCAST
end

function GetGachaBroadcastRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetGachaBroadcastSucceed, data))
end

function GetGachaBroadcastRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetGachaBroadcastFailed, error))
end	