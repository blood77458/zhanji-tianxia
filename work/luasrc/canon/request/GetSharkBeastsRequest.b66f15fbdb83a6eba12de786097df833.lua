require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetSharkBeastsRequest = class(BaseRequest)

function GetSharkBeastsRequest:ctor()
  self.endpoint = METHOD_GETSHARKBEASTS
end

function GetSharkBeastsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSharkBeastsSucceed, data))
end

function GetSharkBeastsRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSharkBeastsFailed, error))
end